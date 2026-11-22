#!/usr/bin/env python3
"""Scratch-file-backed selection of a lean4export dependency closure.

This is an untrusted optimizer: the output must be replayed by a kernel.
No opaque theorem body is dropped; use dependency rules in slice_index.
"""
import argparse
from array import array
from collections import deque
import hashlib
import importlib.util
import json
import mmap
import os
from pathlib import Path
import resource
import tempfile
import time
base_path = Path(__file__).with_name("slice-index.py")
base_spec = importlib.util.spec_from_file_location("cube_slice_index", base_path)
base = importlib.util.module_from_spec(base_spec)
base_spec.loader.exec_module(base)
PIN, QUOT, deps, fields, require, tag = base.PIN, base.QUOT, base.deps, base.fields, base.require, base.tag

# Limits prevent a malformed sparse identifier exhausting local disk.
MAX_INDEX = (1 << 32)-2
RESERVED_NAMES = (*QUOT, "Nat", "Char.ofNat", "String.ofList")


class Flat:
    def __init__(self, path, kind):
        self.file = path.open("x+b")
        self.kind = kind
        self.unit = array(kind).itemsize
        self.map = None
        self.cap = 0
        self.max_used = 0

    def _ensure(self, i):
        if not 0 <= i <= MAX_INDEX:
            raise ValueError(f"invalid or too large identifier {i}")
        self.max_used = max(self.max_used, i)
        if self.cap > i:
            return
        wanted = max(8192, self.cap * 2, i+1)
        wanted = min(wanted, MAX_INDEX+1)
        if self.map is not None:
            self.map.resize(self.unit * wanted)
            self.view = memoryview(self.map).cast(self.kind)
        else:
            self.file.truncate(self.unit * wanted)
            self.map = mmap.mmap(self.file.fileno(), 0, access=mmap.ACCESS_WRITE)
            self.view = memoryview(self.map).cast(self.kind)
        self.cap = wanted

    def get(self, i):
        if not 0 <= i < self.cap:
            raise ValueError(f"missing id {i}")
        x = self.view[i]
        if not x:
            raise ValueError(f"missing id {i}")
        return x

    def put(self, i, value):
        if i >= self.cap and self.map is not None:
            self.view.release()
        self._ensure(i)
        if self.view[i]:
            raise ValueError(f"duplicate id {i}")
        self.view[i] = value

    def discard_pages(self):
        # Shared dirty pages remain backed by the file even when unmapped.
        if self.map is not None and hasattr(self.map, "madvise"):
            self.map.madvise(mmap.MADV_DONTNEED)

    def close(self):
        if self.map is not None:
            self.view.release()
            self.map.close()
        self.file.close()


def prune(source, dest, root_names, scratch):
    start = time.monotonic()
    h = hashlib.sha256()
    # Only track target-name prefixes, not strings for every one of the
    # potentially millions of irrelevant names.
    targets = {tuple(n.split(".")) for n in set(root_names) | set(RESERVED_NAMES)}
    prefixes = {p[:i] for p in targets for i in range(1,len(p)+1)}
    prefix_by_id = {0: ()}
    prefix_ids = {():0}
    count = picked = 0
    db_bytes = 0
    with tempfile.TemporaryDirectory(prefix="flat-index-",dir=scratch) as tmp, source.open("rb") as src:
        maps = {k:Flat(Path(tmp)/k, "I") for k in ("in", "il", "ie", "decl")}
        offsets = Flat(Path(tmp)/"off", "Q")
        try:
            header = src.readline()
            meta = json.loads(header)["meta"]
            require(meta["format"]["version"]=="3.1.0" and meta["lean"]["githash"]==PIN
                    and meta["exporter"]=={"name":"lean4export","version":"3.1.0"}, "wrong export format")
            h.update(header)
            off = len(header)
            for raw in src:
                count += 1
                h.update(raw)
                d = json.loads(raw)
                role, kind, x = tag(d)
                offsets.put(count, off)
                if role == "in":
                    require(kind in ("str","num"),"invalid name")
                    i = d[role]
                    if x["pre"] in prefix_by_id:
                        p = prefix_by_id[x["pre"]] + (x["str" if kind == "str" else "i"],)
                        if p in prefixes:
                            require(p not in prefix_ids,"duplicate root or reserved-name prefix")
                            prefix_ids[p] = i
                            prefix_by_id[i] = p
                    maps[role].put(i,count)
                elif role == "decl":
                    for owner in fields(kind,x):
                        maps[role].put(owner["name"],count)
                else:
                    maps[role].put(d[role],count)
                off += len(raw)
                if count % 1_048_576 == 0:
                    offsets.discard_pages()
                    for m in maps.values(): m.discard_pages()
            indexed = time.monotonic()
            db_bytes = sum(m.cap*m.unit for m in (*maps.values(),offsets))
            pending = deque()
            selectfile = Path(tmp)/"seen"
            with selectfile.open("x+b") as visited:
                seen_n = count//8+1
                visited.truncate(seen_n)
                db_bytes += seen_n
                with mmap.mmap(visited.fileno(),0,access=mmap.ACCESS_WRITE) as seen:
                    def pick(i):
                        mask = 1 << (i % 8)
                        bucket = i//8
                        if not seen[bucket] & mask:
                            seen[bucket] |= mask
                            pending.append(i)
                    def nindex(name):
                        return prefix_ids[tuple(name.split("."))]
                    for name in root_names:
                        pick(maps["decl"].get(nindex(name)))
                    while pending:
                        i = pending.popleft()
                        src.seek(offsets.get(i))
                        for k,a in deps(json.loads(src.readline())):
                            if k == "declByName": k,a = "decl",nindex(a)
                            if a == 0 and k in ("in","il"): continue
                            pick(maps[k].get(a))
                    # Emit in source order, with exactly the original record bytes.
                    # One forward read, no seeks for large retained closures.
                    with tempfile.NamedTemporaryFile(
                        dir=dest.parent, prefix=f".{dest.name}.", suffix=".tmp"
                    ) as dst:
                        verified = hashlib.sha256()
                        src.seek(0)
                        hdr = src.readline()
                        verified.update(hdr)
                        dst.write(hdr)
                        for i,raw in enumerate(src,1):
                            verified.update(raw)
                            if i > count:
                                raise ValueError("source mutated during selection")
                            if seen[i//8] & (1 << (i%8)):
                                dst.write(raw)
                                picked += 1
                        if verified.digest() != h.digest():
                            raise ValueError("source mutated during selection")
                        dst.flush()
                        os.link(dst.name, dest)  # atomic publication, no replacement
        finally:
            for m in (*maps.values(),offsets): m.close()
    print(json.dumps(dict(mode="mmap",records_indexed=count,records_retained=picked,
        source_sha256=h.hexdigest(),input_bytes=source.stat().st_size,retained_bytes=dest.stat().st_size,
        index_bytes=db_bytes,index_seconds=round(indexed-start,3),wall_seconds=round(time.monotonic()-start,3),
        peak_rss_kib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss),sort_keys=True))


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("input",type=Path)
    p.add_argument("output",type=Path)
    p.add_argument("roots",nargs="+")
    p.add_argument("--scratch",type=Path,default=Path("."))
    a=p.parse_args()
    require(not a.output.exists(),"refusing to overwrite output")
    prune(a.input,a.output,a.roots,a.scratch)


if __name__=="__main__":
    main()
