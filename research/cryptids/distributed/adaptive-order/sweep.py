#!/usr/bin/env python3
"""Exploratory generator only; successful candidates still need kernel checking."""
import argparse
import hashlib
import json
import sys
from collections import Counter
from math import gcd, isqrt
from pathlib import Path
from time import monotonic

here = Path(__file__).resolve().parent
for candidate in (here, here.parent, here.parent/"shared-order"):
    if (candidate/"render_one_factor.py").is_file():
        sys.path.insert(0,str(candidate))
        break
from render_one_factor import ROOT, SIEVE, witness

def prime(p):
    return p >= 2 and all(p % q for q in range(2, isqrt(p) + 1))

def roots(j, count):
    m = 1 << (j + 1)
    start = isqrt(m**3) + 1
    out = []
    for x in range(start | 1, start + 10**6, 2):
        if x != ROOT and prime(x):
            out.append(x)
            if len(out) == count:
                return out
    raise RuntimeError(f"no prime roots in bucket {j}")

def witness_with_root(n, r):
    lo, hi = n**3, (n+1)**3
    kmin = (lo-1)//r + 1
    for k in range(kmin + kmin%2, (hi-2)//r + 1, 2):
        p = k*r + 1
        if p >= r**2 or any(p != q and p%q == 0 for q in SIEVE):
            continue
        v = pow(2,k,p)
        if v > 1 and pow(v,r,p) == 1 and gcd(v-1,p) == 1:
            return p,v,r
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--roots-per-bucket",type=int,default=4)
    a = ap.parse_args()
    assert a.roots_per_bucket > 0
    start = monotonic()
    table = [roots(i,a.roots_per_bucket) for i in range(16)]
    used = Counter()
    bucket_coverage = [[] for _ in range(16)]
    extra, misses, first_hit = [], [], 0
    digest = hashlib.sha256()
    for n in range(1,65535):
        i = n.bit_length() - 1
        w = witness(n)
        if w:
            pair = (*w,ROOT)
            first_hit += 1
        else:
            pair = None
            for r in table[i]:
                if pair := witness_with_root(n,r):
                    break
        if pair is None:
            misses.append(n)
            continue
        p,v,r = pair
        assert n**3 < p < (n+1)**3
        assert 1 < v < p < r**2 and pow(v,r,p)==1 and gcd(v-1,p)==1
        used[r] += 1
        if r != ROOT:
            extra.append(n)
            bucket_coverage[i].append(n)
        digest.update(json.dumps([n,p,v,r],separators=(",",":")).encode()+b"\n")
    result = dict(first_hit=first_hit, adaptive_extra=len(extra), fallback=len(misses),
        roots_used=len(used), fallback_n=misses, roots_searched=table,
        new_hits_by_bucket=[len(x) for x in bucket_coverage], root_usage=dict(sorted(used.items())),
        candidate_sha256=digest.hexdigest(), generator_seconds=round(monotonic()-start,3))
    print(json.dumps(result,sort_keys=True))

if __name__ == "__main__":
    main()
