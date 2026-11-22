#!/usr/bin/env python3
"""Generate an exact, stock-kernel shared-order certificate pilot."""
import argparse
from math import gcd
from pathlib import Path

ROOT = 16_777_259
SIEVE = (3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43)


def witness(n):
    lo, hi = n**3, (n + 1)**3
    k = (lo - 1) // ROOT + 1
    for k in range(k + k % 2, (hi - 2) // ROOT + 1, 2):
        p = k * ROOT + 1
        if p >= ROOT**2 or any(p % q == 0 for q in SIEVE if q < p):
            continue
        v = pow(2, k, p)
        if v > 1 and pow(v, ROOT, p) == 1 and gcd(v - 1, p) == 1:
            assert lo < p < hi
            return p, v
    return None


def factor(n):
    q = 2
    while q * q <= n:
        e = 0
        while n % q == 0:
            n //= q
            e += 1
        if e:
            yield q, e
        q += 1
    if n > 1:
        yield n, 1


def root_certs(p, out):
    if p == 2 or p in out:
        return
    fs = list(factor(p - 1))
    for q, _ in fs:
        root_certs(q, out)
    a = next(a for a in range(2, p) if pow(a, p - 1, p) == 1 and
             all(pow(a, (p - 1) // q, p) != 1 for q, _ in fs))
    out[p] = (a, fs)


def render(first, end):
    items = [(n, witness(n)) for n in range(first, end)]
    missing = [n for n, w in items if w is None]
    if missing:
        raise ValueError(f"shard requires fallback for {len(missing)} intervals")
    cs = {}
    root_certs(ROOT, cs)
    vals = ",\n    ".join(f"⟨{p}, {a}, {fs}⟩" for p, (a, fs) in sorted(cs.items()))
    lines = [
        "import OneFactorCore",
        "namespace CubePrime.OneFactor",
        "set_option maxRecDepth 8192",
        "set_option maxHeartbeats 0",
        f"theorem root_is_prime : Nat.Prime {ROOT} := by",
        f"  exact knownPrimeOK_sound (r := {ROOT}) (certs := [\n    {vals}]) (by decide +kernel)",
    ]
    groups = []
    for i in range(0, len(items), 64):
        group = items[i:i+64]
        lo, hi = group[0][0], group[-1][0] + 1
        name = f"part_{lo}"
        groups.append(name)
        pairs = ",\n  ".join(str(w) for _, w in group)
        lines.extend([
            f"private def data_{lo} : List (ℕ × ℕ) := [\n  {pairs}]",
            f"theorem {name} (n : ℕ) (hlo : {lo} ≤ n) (hhi : n < {hi}) : Pratt.CubeAt n := by",
            f"  exact checkRun_sound (r := {ROOT}) (start := {lo}) (ps := data_{lo})",
            "    root_is_prime (by decide +kernel) n hlo hhi",
        ])
    while len(groups) > 1:
        groups = [f"(Pratt.splice {groups[i]} {groups[i+1]})" if i+1 < len(groups)
                  else groups[i] for i in range(0, len(groups), 2)]
    lines.append(f"theorem shard : ∀ n : ℕ, {first} ≤ n → n < {end} → Pratt.CubeAt n :=\n  {groups[0]}")
    lines.extend(["#print axioms shard", "end CubePrime.OneFactor", ""])
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("first", type=int)
    ap.add_argument("end", type=int)
    ap.add_argument("output", type=Path)
    a = ap.parse_args()
    if not 1 <= a.first < a.end <= 65535:
        ap.error("require 1 <= first < end <= 65535")
    a.output.write_text(render(a.first, a.end), encoding="utf-8")


if __name__ == "__main__":
    main()
