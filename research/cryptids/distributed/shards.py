#!/usr/bin/env python3
"""Deterministic recoverable shards for the finite cube interval, not for RH."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import subprocess
import sys
import tempfile
import time

DATA = "fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d"
LEAN = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6"
MATHLIB = "0df444a360eaa60ab8c11dca51a86af692955474"
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}
COUNT = 256
STRIDE = 256
END = 65535
FINITE = Path(__file__).resolve().parent.parent / "finite"

def digest(p):
    with p.open("rb") as handle:
        h = hashlib.sha256()
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
        return h.hexdigest()

def payload(d):
    return (json.dumps(d, sort_keys=True, indent=2, ensure_ascii=True) + "\n").encode()

def sha(bytes_):
    return hashlib.sha256(bytes_).hexdigest()

def write(p, d):
    p.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=p.parent, delete=False) as f:
        f.write(payload(d))
    os.replace(f.name, p)

def read(p):
    return json.loads(p.read_text())

def require(ok, why):
    if not ok:
        raise ValueError(why)

def group(grp):
    return f"Group{grp:03d}"

def row(i, source):
    start = 1 + i * STRIDE
    return {"id": i, "start": start, "stop_exclusive": min(start + STRIDE, END),
            "source_sha256": digest(source / "FinitePratt" / (group(i) + ".lean"))}

def manifest(candidate, out):
    require(digest(candidate) == DATA, "candidate data hash mismatch")
    out.parent.mkdir(parents=True, exist_ok=True)
    # Always render into an isolated directory first; don't accept arbitrary Lean source in a handoff.
    temp = Path(tempfile.mkdtemp(prefix="layout.", dir=out.parent))
    try:
        subprocess.run([sys.executable, "-B", str(FINITE / "render_pratt_range.py"),
                        str(candidate), str(temp / "FinitePratt"), "--batches-per-group", "4"], check=True)
        core_sources = {name: digest(FINITE / name) for name in
                        ("PrattCore.lean", "render_pratt_range.py", "render_pratt_batches.py")}
        compat = FINITE.parent / "backport433"
        core_sources.update({name: digest(compat / name) for name in
                             ("cube-433.patch", "lake-manifest.json", "lean-toolchain")})
        core = (FINITE / "PrattCore.lean").read_bytes()
        stub = b"\nimport Mathlib.Tactic\n"
        require(core.count(stub) == 1, "unexpected PrattCore import")
        materialized_core = sha(core.replace(stub, b"\nimport Mathlib.Tactic.Ring\n"))
        doc = {"materialized_core_sha256": materialized_core, "schema": "cube-finite-plan-v1", "data_sha256": DATA, "lean_commit": LEAN,
               "mathlib_commit": MATHLIB, "layout": "64 witnesses per batch, 4 batches per module",
               "core_source_sha256": core_sources, "join_sha256": digest(temp / "FinitePratt" / "All.lean"),
               "groups": [row(i, temp) for i in range(COUNT)]}
        write(temp / "plan.json", doc)
        if out.exists():
            require(payload(read(out / "plan.json")) == payload(doc), "existing layout plan differs")
            require(all(row(i, out) == doc["groups"][i] for i in range(COUNT)), "existing files differ")
            require(digest(out / "FinitePratt" / "All.lean") == doc["join_sha256"], "existing join differs")
        else:
            temp.rename(out)
        print("plan_sha256=" + sha(payload(doc)))
    finally:
        # This is exclusively the newly created renderer scratch directory.
        if temp.exists():
            for p in (temp / "FinitePratt").glob("*.lean"):
                p.unlink()
            if (temp / "FinitePratt").exists():
                (temp / "FinitePratt").rmdir()
            if (temp / "plan.json").exists():
                (temp / "plan.json").unlink()
            temp.rmdir()

def load_plan(root):
    d = read(root / "plan.json")
    require(d.get("schema") == "cube-finite-plan-v1" and d.get("data_sha256") == DATA and
            d.get("lean_commit") == LEAN and d.get("mathlib_commit") == MATHLIB and
            len(d.get("groups", [])) == COUNT, "incompatible plan")
    return d

def read_entry(plan, root, i):
    require(0 <= i < COUNT, "invalid group id")
    actual = row(i, root)
    require(actual == plan["groups"][i], "group source/range mismatch")
    return actual

def proc(cmd, *, cwd, env, log):
    started = time.monotonic()
    with log.open("wb") as f:
        child = subprocess.run(cmd, cwd=cwd, env=env, stdout=f, stderr=subprocess.STDOUT)
    require(child.returncode == 0, f"exit status {child.returncode}; see {log.name}")
    return round(time.monotonic() - started, 3)

def axioms(text, theorem):
    entries = re.findall(rf"'{re.escape(theorem)}' depends on axioms: \[([^\]]+)\]", text, flags=re.S)
    require(len(entries) == 1, "missing or ambiguous axiom report")
    found = set(x.strip() for x in entries[0].split(","))
    require(found and found <= ALLOWED, "nonstandard axioms found: " + repr(found - ALLOWED))
    return sorted(found)

def worker(root, cube, bin_dir, out, ids, overrides):
    plan = load_plan(root)
    env = os.environ.copy()
    env.pop("LEAN_PATH", None)
    env.pop("LEAN_SRC_PATH", None)
    env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")
    env["LEAN_ABORT_ON_PANIC"] = "1"
    lean, lake = (str(bin_dir / t) for t in ("lean", "lake"))
    require((bin_dir.parent / "lib/lean/Init.olean").is_file(), "use a real Lean toolchain")
    version = subprocess.check_output([lean, "--version"], env=env, text=True)
    require("version 4.33.1," in version and LEAN in version, "wrong Lean")
    rev = subprocess.check_output(["git", "-C", str(cube / ".lake/packages/mathlib"), "rev-parse", "HEAD"],
                                  text=True).strip()
    require(rev == MATHLIB, "wrong Mathlib pin")
    require(not subprocess.check_output(["git", "-C", str(cube / ".lake/packages/mathlib"),
                                         "status", "--porcelain", "--untracked-files=no"]),
            "Mathlib source is dirty")
    require(digest(cube / "PrattCore.lean") == plan["materialized_core_sha256"],
            "PrattCore does not match checked source")
    manifest_hash = digest(cube / "lake-manifest.json")
    require(manifest_hash == plan["core_source_sha256"]["lake-manifest.json"], "wrong Lake manifest")
    lake_cmd = [lake, "--no-cache", *([f"--packages={overrides}"] if overrides else [])]
    sp = subprocess.check_output([*lake_cmd, "env", "printenv", "LEAN_PATH"], cwd=cube,
                                 env=env, text=True).strip()
    require(bool(sp), "missing Lean search path")
    # Put the worker's freshly compiled files first. Source imports are limited to trusted built dependencies.
    env["LEAN_PATH"] = str(out / "lib") + os.pathsep + sp
    for folder in ("logs", "receipts", "lib/FinitePratt"):
        (out / folder).mkdir(parents=True, exist_ok=True)
    core_out = out / "lib/PrattCore.olean"
    core_log = out / "logs/PrattCore-build.log"
    proc([lean, "-j1", f"--root={cube}", "-o", str(core_out), str(cube / "PrattCore.lean")],
         cwd=cube, env=env, log=core_log)
    core_axioms = axioms(core_log.read_text(), "CubePrime.Pratt.checkBatch_sound")
    plan_hash = sha(payload(plan))
    for i in ids:
        spec = read_entry(plan, root, i)
        name = group(i)
        pre_max = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
        artifact = out / "lib/FinitePratt" / (name + ".olean")
        compile_secs = proc([lean, "-j1", f"--root={root}", "-o", str(artifact),
                             str(root / "FinitePratt" / (name + ".lean"))],
                            cwd=cube, env=env, log=out / "logs" / (name + "-build.log"))
        # Record compiler resource observation before running the separate audit process.
        rss_max = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
        audit = out / (name + "Audit.lean")
        theorem = f"CubePrime.Pratt.group_{i:03d}"
        audit.write_text(f"import FinitePratt.{name}\n#print axioms {theorem}\n")
        audit_log = out / "logs" / (name + "-axioms.log")
        proc([lean, "-j1", str(audit)], cwd=out, env=env, log=audit_log)
        receipt = {"schema": "cube-finite-receipt-v1", "plan_sha256": plan_hash,
                   "group": spec, "pratt_olean_sha256": digest(core_out), "pratt_axioms": core_axioms, "compile_seconds": compile_secs, "group_olean_bytes": artifact.stat().st_size,
                   "group_olean_sha256": digest(artifact), "axioms": axioms(audit_log.read_text(), theorem),
                   "max_child_rss_kib_cumulative": rss_max, "prior_child_rss_kib_cumulative": pre_max,
                   "replayed_in_kernel_as_source": True}
        write(out / "receipts" / (name + ".json"), receipt)
        print(f"group {i:03d}: checked, {compile_secs}s, cumulative child peak {rss_max} KiB", flush=True)

def coverage(root, receipts):
    plan = load_plan(root)
    h = sha(payload(plan))
    seen = set()
    for r in receipts:
        x = read(r)
        i = x.get("group", {}).get("id")
        require(type(i) is int and 0 <= i < COUNT and i not in seen, "invalid or duplicate group id")
        require(x.get("schema") == "cube-finite-receipt-v1" and x.get("plan_sha256") == h
                and x.get("group") == read_entry(plan, root, i)
                and x.get("replayed_in_kernel_as_source") is True
                and x.get("axioms") and set(x["axioms"]) <= ALLOWED
                and x.get("pratt_axioms") and set(x["pratt_axioms"]) <= ALLOWED,
                "receipt pins, bounds, or axiom reports do not match")
        seen.add(i)
    intervals = [plan["groups"][i] for i in sorted(seen)]
    count = sum(r["stop_exclusive"] - r["start"] for r in intervals)
    print(json.dumps({"groups_reported": len(seen), "intervals_reported": count,
                      "groups_expected": COUNT, "range_complete_advisory": len(seen) == COUNT,
                      "kernel_join_run": False, "receipts_are_proofs": False}, sort_keys=True))

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="command", required=True)
    p = sub.add_parser("plan"); p.add_argument("candidate", type=Path); p.add_argument("layout", type=Path)
    p = sub.add_parser("work")
    for name in ("layout", "cube", "lean_bin", "out"):
        p.add_argument(name, type=Path)
    p.add_argument("--groups", required=True, nargs="+", type=int)
    p.add_argument("--packages-override", type=Path)
    p = sub.add_parser("coverage"); p.add_argument("layout", type=Path); p.add_argument("receipts", nargs="+", type=Path)
    a = ap.parse_args()
    try:
        if a.command == "plan":
            manifest(a.candidate.resolve(), a.layout.resolve())
        elif a.command == "work":
            require(len(set(a.groups)) == len(a.groups), "duplicate group IDs")
            worker(a.layout.resolve(), a.cube.resolve(), a.lean_bin.resolve(), a.out.resolve(), a.groups,
                   a.packages_override.resolve() if a.packages_override else None)
        else:
            coverage(a.layout.resolve(), a.receipts)
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as e:
        ap.exit(2, f"{e}\n")

if __name__ == "__main__":
    main()
