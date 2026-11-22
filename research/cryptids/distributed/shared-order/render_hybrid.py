#!/usr/bin/env python3
"""Render optional hybrid replacements for the 256-group finite replay."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from render_one_factor import ROOT, root_certs, witness

EXPECTED = "fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d"


def fmt_cert(rows):
    return ", ".join(f"⟨{p}, {a}, {list(map(tuple, fs))}⟩" for p, a, fs in rows)


def splice(names):
    while len(names) > 1:
        names = [f"(splice {names[i]} {names[i+1]})" if i+1 < len(names)
                 else names[i] for i in range(0,len(names),2)]
    return names[0]


def write(file, lines):
    file.write_text("\n".join(lines)+"\n",encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lucas_json",type=Path)
    ap.add_argument("--from-group",type=int,default=0)
    ap.add_argument("--output",type=Path,default=Path("FiniteHybrid"))
    args = ap.parse_args()
    out = args.output
    if not 0 <= args.from_group < 256:
        ap.error("from-group must be 0-255; earlier groups use the stock 256-group renderer")
    raw = args.lucas_json.read_bytes()
    if sha256(raw).hexdigest() != EXPECTED:
        raise ValueError("wrong baseline input")
    data = json.loads(raw)
    by_p = {p:(p,a,fs) for p,a,fs in data["certificates"]}
    out.mkdir()
    rc = {}
    root_certs(ROOT,rc)
    write(out/"Root.lean",["import OneFactorCore","namespace CubePrime.OneFactor",
         "set_option maxRecDepth 8192",
         f"theorem sharedRoot : Nat.Prime {ROOT} := ",
         f"  knownPrimeOK_sound (certs := [{fmt_cert((p,a,fs) for p,(a,fs) in sorted(rc.items()))}]) (by decide +kernel)",
         "#print axioms sharedRoot","end CubePrime.OneFactor"])
    mods, names = [], []
    total_fast = total_fallback = 0
    for group in range(256):
        name = f"Group{group:03d}"
        if group < args.from_group:
            mods.append(f"FinitePratt.{name}")
            names.append(f"group_{group:03d}")
            continue
        lo, hi = group*256+1, min((group+1)*256+1,65535)
        lines = ["import FiniteHybrid.Root", "namespace CubePrime.OneFactor",
                 "open CubePrime.Pratt", "set_option maxRecDepth 8192", "set_option maxHeartbeats 0"]
        parts = []
        for b in range(lo,hi,64):
            e = min(b+64,hi)
            needed, rows = {}, []
            def include(p):
                if p == 2 or p in needed: return
                row = by_p[p]
                for q,_ in row[2]: include(q)
                needed[p] = row
            for n in range(b,e):
                w = witness(n)
                if w is not None:
                    p,v = w
                    rows.append(f"({p}, some {v})")
                    total_fast += 1
                else:
                    p = data["witnesses"][n-1]
                    include(p)
                    rows.append(f"({p}, none)")
                    total_fallback += 1
            parts.append(f"block_{b}")
            lines += [
                f"private def data_{b} : List (ℕ × Option ℕ) := [{', '.join(rows)}]",
                f"private def cert_{b} : List Cert := [{fmt_cert(v for _,v in sorted(needed.items()))}]",
                f"private theorem block_{b} (n : ℕ) (hlo : {b} ≤ n) (hhi : n < {e}) : CubeAt n :=",
                f"  checkHybridBatch_sound (start := {b}) (certs := cert_{b}) (ps := data_{b})",
                f"    sharedRoot (by decide +kernel) n hlo hhi",
            ]
        theorem = f"hybrid_{group:03d}"
        lines += [f"theorem {theorem} : ∀ n : ℕ, {lo} ≤ n → n < {hi} → CubeAt n :=",
                  "  " + splice(parts), "end CubePrime.OneFactor"]
        write(out/f"{name}.lean",lines)
        mods.append(f"FiniteHybrid.{name}")
        names.append(theorem)
    write(out/"All.lean",[*(f"import {mod}" for mod in mods),
          "namespace CubePrime.OneFactor", "open CubePrime.Pratt", "set_option maxRecDepth 8192",
          "theorem finite_cube_range : ∀ n : ℕ, 1 ≤ n → n < 65535 → CubeAt n :=",
          "  " + splice(names), "#print axioms finite_cube_range","end CubePrime.OneFactor"])
    print(f"shared={total_fast} fallback={total_fallback} baseline_prefix_groups={args.from_group}")


if __name__ == "__main__":
    main()
