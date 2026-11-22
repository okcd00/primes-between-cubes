#!/usr/bin/env python3
"""Check candidate witnesses with exact integers, outside the Lean kernel."""
import argparse
import json
import math
from pathlib import Path


def verify(data):
    if data["format"] != "cube-pratt-v1" or data["first_n"] != 1:
        raise ValueError("wrong certificate format or start")
    end = data["last_n"]
    if not 1 <= end <= 65_534 or len(data["witnesses"]) != end:
        raise ValueError("wrong witness range")
    previous = 2
    proved = {2}
    for p, base, factors in data["certificates"]:
        if p <= previous or not 2 <= base < p or not factors:
            raise ValueError(f"bad certificate header: {p}")
        if (any(q not in proved or e < 1 for q, e in factors)
                or math.prod(q**e for q, e in factors) != p - 1):
            raise ValueError(f"bad factorization: {p}")
        if pow(base, p-1, p) != 1 or any(pow(base, (p-1)//q, p) == 1 for q, _ in factors):
            raise ValueError(f"failed Lucas test: {p}")
        proved.add(p)
        previous = p
    for n, p in enumerate(data["witnesses"], 1):
        if p not in proved or not n**3 < p < (n+1)**3:
            raise ValueError(f"bad witness: n={n}, p={p}")
    return end, len(proved)-1


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    args = ap.parse_args()
    with args.source.open() as fd:
        n, count = verify(json.load(fd))
    print(f"{n} strict cube intervals; {count} exact nonbase primality certificates")
