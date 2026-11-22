"""Audit the bridge's literal finite witnesses without Lean or floating point."""
from math import isqrt
from pathlib import Path
import re

source = (Path(__file__).resolve().parents[1] / "CubeBridge.lean").read_text()
witnesses = [int(p) for p in re.findall(r"exact ⟨(\d+), by norm_num, by decide, by decide⟩", source)]
if len(witnesses) != 62:
    raise SystemExit(f"expected 62 witnesses, got {len(witnesses)}")
for n, p in enumerate(witnesses, 1):
    if not n**3 < p < (n + 1)**3 or p < 2 or any(p % d == 0 for d in range(2, isqrt(p) + 1)):
        raise SystemExit(f"invalid witness for n={n}: {p}")
print(f"{len(witnesses)} prime witnesses verified by trial division and strict integer bounds")
