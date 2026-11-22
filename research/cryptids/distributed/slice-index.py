#!/usr/bin/env python3
"""External-memory closure selection for pinned lean4export 3.1.0 (not a checker).

Indices are kept per export. Retained records keep their original sparse IDs;
the pinned Lean parser accepts them. Inert output still needs kernel replay.
"""
import argparse
from collections import deque
import hashlib
import json
from pathlib import Path
import resource
import sqlite3
import time

PIN = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6"
QUOT = ("Eq", "Quot", "Quot.mk", "Quot.lift", "Quot.ind")
DECL = {"axiom", "def", "thm", "opaque", "quot", "inductive"}

def require(b, msg):
    if not b:
        raise ValueError(msg)

def name_code(parts):
    return json.dumps(parts, ensure_ascii=True, separators=(",", ":"))

def tag(d):
    roles = [t for t in ("in", "il", "ie") if t in d]
    if roles:
        require(len(roles) == 1 and len(d) == 2, "invalid primitive")
        ix = roles[0]
        k = next(x for x in d if x != ix)
        return ix, k, d[k]
    require(len(d) == 1 and next(iter(d)) in DECL, "invalid declaration")
    k, value = next(iter(d.items()))
    return "decl", k, value

def fields(kind, value):
    # Atomic ownership: a whole inductive record includes every member.
    return (value["types"] + value["ctors"] + value["recs"]) if kind == "inductive" else [value]

def deps(d):
    role, kind, x = tag(d)
    if role == "in":
        yield "in", x["pre"]
    elif role == "il":
        if kind == "param": yield "in", x
        elif kind == "succ": yield "il", x
        elif kind in ("max", "imax"): yield from (("il", y) for y in x)
        else: raise ValueError("unknown level tag")
    elif role == "ie":
        if kind == "sort": yield "il", x
        elif kind == "const":
            yield "in", x["name"]
            yield "decl", x["name"]
            yield from (("il", y) for y in x["us"])
        elif kind == "proj":
            yield "in", x["typeName"]
            yield "decl", x["typeName"]
            yield "ie", x["struct"]
        elif kind == "app":
            yield "ie", x["fn"]
            yield "ie", x["arg"]
        elif kind in ("lam", "forallE", "letE"):
            yield "in", x["name"]
            for k in ("type", "body", "value"):
                if k in x: yield "ie", x[k]
        elif kind == "mdata": yield "ie", x["expr"]
        elif kind == "natVal": yield "declByName", "Nat"
        elif kind == "strVal":
            yield "declByName", "Char.ofNat"
            yield "declByName", "String.ofList"
        elif kind != "bvar": raise ValueError("unknown expression tag")
    elif role == "decl":
        if kind == "quot":
            yield from (("declByName", name) for name in QUOT)
        for y in fields(kind, x):
            yield "in", y["name"]
            yield "ie", y["type"]
            yield from (("in", z) for z in y["levelParams"])
            if "value" in y: yield "ie", y["value"]
            for f in ("all", "ctors"):
                for z in y.get(f, []):
                    yield "in", z
                    yield "decl", z
            if "induct" in y:
                yield "in", y["induct"]
                yield "decl", y["induct"]
            for rule in y.get("rules", []):
                yield "in", rule["ctor"]
                yield "decl", rule["ctor"]
                yield "ie", rule["rhs"]

class Memory:
    def __init__(self):
        self.records, self.keys, self.names = {}, {}, {0: []}
        self.by_parts, self.seen, self.queue = {name_code([]): 0}, set(), deque()
    def record(self, i, n, raw, d):
        self.records[i] = (n, raw, d)
    def put(self, k, i, off):
        require((k,i) not in self.keys, "duplicate key")
        self.keys[k,i] = off
    def get(self,k,i):
        return self.keys[k,i]
    def add_name(self,i,pre,f):
        a=self.names[pre]+[f]; c=name_code(a)
        require(c not in self.by_parts and i not in self.names, "duplicate name")
        self.names[i]=a; self.by_parts[c]=i
    def name(self,x):
        return self.by_parts[name_code(x.split("."))]
    def pick(self,off):
        if off not in self.seen:
            self.seen.add(off); self.queue.append(off)
    def pop(self):
        return self.queue.popleft() if self.queue else None
    def data(self, off, src):
        return self.records[off][2]
    def chosen(self):
        return ((i,self.records[i][0]) for i in sorted(self.seen))
    def sync(self):
        pass

class Disk:
    def __init__(self, db, reuse):
        require(db.exists() == reuse, "index existence does not match --reuse")
        self.db=sqlite3.connect(db)
        self.db.executescript("pragma cache_size=-8192; pragma temp_store=FILE; pragma journal_mode=OFF;")
        if reuse:
            return
        self.db.executescript("""
        create table source(provenance text primary key, value text not null);
        create table offsets(i integer primary key,n integer not null);
        create table keys(k text,i integer,o integer,primary key(k,i)) without rowid;
        create table names(i integer primary key,p text unique not null);
        create table selected(i integer primary key);
        create table frontier(seq integer primary key,i integer);
        insert into names values(0,'[]');
        """)
    def record(self, i, n, raw, d):
        self.db.execute("insert into offsets values(?,?)",(i,n))
    def put(self,k,i,off):
        self.db.execute("insert into keys values(?,?,?)",(k,i,off))
    def get(self,k,i):
        r=self.db.execute("select o from keys where k=? and i=?",(k,i)).fetchone()
        if r is None: raise KeyError((k,i))
        return r[0]
    def add_name(self,i,pre,f):
        p=self.db.execute("select p from names where i=?",(pre,)).fetchone()
        if p is None: raise KeyError(("parent name",pre))
        self.db.execute("insert into names values(?,?)",(i,name_code(json.loads(p[0])+[f])))
    def name(self,x):
        z=self.db.execute("select i from names where p=?",(name_code(x.split(".")),)).fetchone()
        if z is None: raise KeyError(("name",x))
        return z[0]
    def pick(self,off):
        c=self.db.execute("insert or ignore into selected values(?)",(off,))
        if c.rowcount: self.db.execute("insert into frontier(i) values(?)",(off,))
    def pop(self):
        r=self.db.execute("select seq,i from frontier order by seq desc limit 1").fetchone()
        if r is None: return None
        self.db.execute("delete from frontier where seq=?",(r[0],))
        return r[1]
    def data(self,off,src):
        src.seek(off); return json.loads(src.readline())
    def provenance(self, checksum=None, count=None):
        if checksum is not None:
            self.db.executemany("insert into source values (?,?)", (("sha256",checksum),("count",str(count))))
        else:
            return dict(self.db.execute("select provenance,value from source"))
    def clear_selection(self):
        self.db.executescript("delete from selected; delete from frontier;")
    def chosen(self):
        return self.db.execute("select s.i,o.n from selected s join offsets o on s.i=o.i order by s.i")
    def sync(self):
        self.db.commit()

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("mode",choices=("memory","disk"))
    p.add_argument("input",type=Path); p.add_argument("output",type=Path)
    p.add_argument("roots",nargs="+")
    p.add_argument("--db",type=Path)
    p.add_argument("--reuse",action="store_true")
    a=p.parse_args()
    require((a.mode=="disk")==bool(a.db), "disk mode requires --db")
    require(not a.reuse or a.mode == "disk", "--reuse requires disk mode")
    require(not a.output.exists(), "refusing to overwrite output")
    started=time.monotonic()
    idx=Disk(a.db,a.reuse) if a.db else Memory()
    recs=0
    with a.input.open("rb") as src:
        header=src.readline()
        meta=json.loads(header)["meta"]
        require(meta["format"]["version"]=="3.1.0" and meta["lean"]["githash"]==PIN
                and meta["exporter"]=={"name":"lean4export","version":"3.1.0"}, "wrong export format")
        if a.reuse:
            h=hashlib.sha256(header)
            for piece in iter(lambda: src.read(1024*1024),b""): h.update(piece)
            provenance=idx.provenance()
            require(provenance.get("sha256")==h.hexdigest(), "index belongs to different input bytes")
            recs=int(provenance["count"])
            idx.clear_selection()
        else:
            h=hashlib.sha256(header)
            off=src.tell()
            for raw in src:
                h.update(raw)
                d=json.loads(raw); r,k,x=tag(d)
                idx.record(off,len(raw),raw,d)
                if r=="in":
                    require(k in ("str","num"),"invalid name")
                    idx.add_name(d[r],x["pre"],x["str"] if k=="str" else x["i"])
                    idx.put(r,d[r],off)
                elif r=="decl":
                    for owner in fields(k,x): idx.put(r,owner["name"],off)
                else: idx.put(r,d[r],off)
                off+=len(raw)
                recs+=1
            idx.sync()
            if a.mode=="disk":
                idx.provenance(h.hexdigest(),recs)
                idx.sync()
        indexed=time.monotonic()
        for name in a.roots: idx.pick(idx.get("decl",idx.name(name)))
        while (off:=idx.pop()) is not None:
            for kind,arg in deps(idx.data(off,src)):
                if kind=="declByName": kind,arg="decl",idx.name(arg)
                if arg==0 and kind in ("in","il"): continue
                idx.pick(idx.get(kind,arg))
        idx.sync()
        picked=0
        with a.output.open("xb") as dst:
            dst.write(header)
            for off,n in idx.chosen():
                src.seek(off); dst.write(src.read(n)); picked+=1
    print(json.dumps({"mode":a.mode,"reused_index":a.reuse,"records_indexed":recs,"records_retained":picked,
                      "input_bytes":a.input.stat().st_size,"retained_bytes":a.output.stat().st_size,
                      "db_bytes":a.db.stat().st_size if a.db else 0,
                      "index_seconds":round(indexed-started,3),"wall_seconds":round(time.monotonic()-started,3),
                      "peak_rss_kib":resource.getrusage(resource.RUSAGE_SELF).ru_maxrss},sort_keys=True))

if __name__=="__main__":
    main()
