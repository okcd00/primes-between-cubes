#!/usr/bin/env python3
"""Propose cube witnesses and full Lucas (Pratt) certificate records.

No output of this script is treated as a proof: every exact equation and
primality dependency is intended to be checked again by a Lean verifier.
"""
import argparse
import json
import math
from pathlib import Path
import sympy


def make(limit):
    records = {}

    def certify(p):
        if p == 2 or p in records:
            return
        factors = sorted((int(q), int(e)) for q, e in sympy.factorint(p - 1).items())
        if math.prod(q**e for q, e in factors) != p - 1:
            raise ValueError(f"incorrect factorization of {p - 1}")
        if not all(2 <= q < p and e > 0 for q, e in factors):
            raise ValueError(f"nondecreasing dependency at {p}")
        for q, _ in factors:
            certify(q)
        a = next(a for a in range(2, p)
                 if pow(a, p - 1, p) == 1
                 and all(pow(a, (p - 1) // q, p) != 1 for q, _ in factors))
        records[p] = [a, factors]

    witnesses = []
    for n in range(1, limit + 1):
        p = int(sympy.nextprime(n**3))
        if not n**3 < p < (n+1)**3:
            raise ValueError(f"no witness for {n}")
        certify(p)
        witnesses.append(p)

    known = {2}
    for p in sorted(records):
        a, factors = records[p]
        if not all(q in known for q, _ in factors):
            raise ValueError(f"certificate dependency order at {p}")
        assert math.prod(q**e for q, e in factors) == p - 1
        assert pow(a, p - 1, p) == 1 and all(pow(a, (p - 1)//q, p) != 1 for q, _ in factors)
        known.add(p)
    if not all(p in known for p in witnesses):
        raise ValueError("uncertified witnesses")
    return {"format": "cube-pratt-v1", "first_n": 1, "last_n": limit,
            "witnesses": witnesses, "certificates": [[p, *records[p]] for p in sorted(records)]}


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=65_534)
    ap.add_argument("destination", type=Path)
    args = ap.parse_args()
    if not 1 <= args.limit <= 65_534:
        ap.error("limit must be in 1..65534")
    out = make(args.limit)
    with args.destination.open("x") as file:
        json.dump(out, file, separators=(",", ":"))
        file.write("\n")
    print(f"{len(out['witnesses'])} witnesses; {len(out['certificates'])} certificates")
