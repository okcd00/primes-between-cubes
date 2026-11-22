"""Fail closed: only the three allowed Lean axioms may appear."""
import pathlib
import re
import sys

data = pathlib.Path(sys.argv[1]).read_text()
allowed = {"propext", "Classical.choice", "Quot.sound"}
decls = (
    "riemannHypothesis",
    "CubePrime.primeBetweenCubes",
    "CubePrime.primeStrictlyBetweenConsecutiveCubes",
)
for name in decls:
    line = re.findall(rf"(?m)^'{re.escape(name)}' depends on axioms: \[([^\]]*)\]$", data)
    if len(line) != 1:
        sys.exit(f"missing or ambiguous axiom report for {name}")
    actual = set(map(str.strip, line[0].split(",")))
    if not actual or not actual <= allowed:
        sys.exit(f"unexpected axioms for {name}: {actual - allowed}")
    print(f"PASS {name}: {', '.join(sorted(actual))}")
