#!/usr/bin/env python3
"""Streaming no-extra-axiom audit for these specific Lean4Export roles.
This is not a declaration/kernel checker. Unchanged verifier remains required.
"""
import argparse
import json
from pathlib import Path

CORE = {"propext", "Classical.choice", "Quot.sound"}
TARGET = {"CubePrime.primeBetweenCubes", "CubePrime.primeStrictlyBetweenConsecutiveCubes"}
EXPECTED = {
    "bridge": (CORE | {"riemannHypothesis"}, TARGET),
    "exact-challenge": (TARGET | {"propext"}, set()),
    "final": (CORE, TARGET | {"riemannHypothesis"}),
}

def audit(path, role):
    known = {0:""}
    ax, found = set(), set()
    with path.open(encoding="utf-8") as fd:
        meta = json.loads(next(fd))["meta"]
        if meta["lean"]["githash"] != "eb6cafb7290e8bd5f2937522d8d804f58f02bafc":
            raise ValueError("unexpected Lean pin")
        for line in fd:
            record = json.loads(line)
            if "in" in record:
                i = record["in"]
                key = "str" if "str" in record else "num"
                part = record[key]
                prefix = known[part["pre"]]
                name = str(part["str" if key == "str" else "i"])
                known[i] = prefix + "." + name if prefix else name
            elif "axiom" in record:
                name = known[record["axiom"]["name"]]
                if name in ax:
                    raise ValueError("duplicate axiom " + name)
                ax.add(name)
            elif "thm" in record:
                name = known[record["thm"]["name"]]
                if name in {"riemannHypothesis"} | TARGET:
                    found.add(name)
    want_ax, want_thm = EXPECTED[role]
    if ax != want_ax or found != want_thm:
        raise ValueError(f"{role}: axioms {sorted(ax)}, central theorem names {sorted(found)}")
    print(f"{role}: axioms {sorted(ax)}, checked theorem-name roles {sorted(found)}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("role", choices=EXPECTED)
    ap.add_argument("input", type=Path)
    a = ap.parse_args()
    audit(a.input, a.role)
