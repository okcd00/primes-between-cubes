#!/usr/bin/env python3
"""Render all required factor dependencies and witness proofs as Lean source."""
import argparse
import json
from pathlib import Path


def build_batch(witnesses, records):
    needed = set()

    def add(p):
        if p == 2 or p in needed:
            return
        a, factors = records[p]
        for q, _ in factors:
            add(q)
        needed.add(p)
    for p in witnesses:
        add(p)
    return sorted(needed)


def render(start, ps, records):
    head = f"batch_{start}"
    rows = []
    for p in build_batch(ps, records):
        a, factors = records[p]
        qstr = ", ".join(f"({q}, {e})" for q, e in factors)
        rows.append(f"  ⟨{p}, {a}, [{qstr}]⟩")
    return f"""
private def ps_{head} : List ℕ := {ps}
private def cs_{head} : List Cert := [
{',\n'.join(rows)}
]

theorem {head} (n : ℕ) (hlo : {start} ≤ n) (hhi : n < {start + len(ps)}) :
    ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 := by
  apply checkBatch_sound (ps := ps_{head}) (certs := cs_{head}) (by decide +kernel) n hlo
  exact hhi
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("data", type=Path)
    ap.add_argument("dest", type=Path)
    ap.add_argument("--start", type=int, default=1)
    ap.add_argument("--count", type=int, default=64)
    ap.add_argument("--batch-size", type=int, default=64)
    args = ap.parse_args()
    data = json.loads(args.data.read_text())
    end = args.start + args.count
    if not 1 <= args.start < end <= data["last_n"]+1 or args.batch_size <= 0:
        ap.error("invalid range")
    records = {p: (a, f) for p, a, f in data["certificates"]}
    output = """import PrattCore

namespace CubePrime.Pratt
set_option maxRecDepth 8192
set_option maxHeartbeats 0
"""
    for start in range(args.start, end, args.batch_size):
        ps = data["witnesses"][start-1:min(start+args.batch_size, end)-1]
        output += render(start, ps, records)
    output += f"\n#print axioms batch_{args.start}\nend CubePrime.Pratt\n"
    with args.dest.open("x") as f:
        f.write(output)


if __name__ == "__main__":
    main()
