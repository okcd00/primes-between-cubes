#!/usr/bin/env python3
"""Generate finite-range source modules joined by a balanced range proof."""
import argparse
import json
from pathlib import Path
from render_pratt_batches import render


def combine(names):
    if len(names) == 1:
        return names[0]
    k = len(names)//2
    return f"(splice {combine(names[:k])} {combine(names[k:])})"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("data", type=Path)
    ap.add_argument("dest", type=Path)
    ap.add_argument("--batch-size", type=int, default=64)
    ap.add_argument("--batches-per-group", type=int, default=16)
    args = ap.parse_args()
    if args.batch_size < 1 or args.batches_per_group < 1:
        ap.error("positive group and batch sizes required")
    data = json.loads(args.data.read_text())
    ply = args.batch_size
    stride = ply * args.batches_per_group
    end = data["last_n"] + 1
    records = {p: (a, f) for p,a,f in data["certificates"]}
    args.dest.mkdir(exist_ok=False)
    all_names = []
    imports = []
    for group, start in enumerate(range(1, end, stride)):
        stop = min(start+stride, end)
        name = f"group_{group:03d}"
        mod = f"Group{group:03d}"
        all_names.append(name)
        imports.append(f"import FinitePratt.{mod}")
        text = "import PrattCore\n\nnamespace CubePrime.Pratt\nset_option maxRecDepth 8192\nset_option maxHeartbeats 0\n"
        parts = []
        for s in range(start, stop, ply):
            text += render(s, data["witnesses"][s-1:min(s+ply, stop)-1], records)
            parts.append(f"batch_{s}")
        text += f"\ntheorem {name} : ∀ n : ℕ, {start} ≤ n → n < {stop} → CubeAt n :=\n  {combine(parts)}\n"
        text += "end CubePrime.Pratt\n"
        (args.dest / f"{mod}.lean").write_text(text)
    result = "\n".join(imports) + "\n\nnamespace CubePrime.Pratt\n"
    result += "set_option maxRecDepth 8192\n"
    result += f"theorem finite_cube_range : ∀ n : ℕ, 1 ≤ n → n < {end} → CubeAt n :=\n  {combine(all_names)}\n"
    result += "#print axioms finite_cube_range\nend CubePrime.Pratt\n"
    (args.dest / "All.lean").write_text(result)
    print(f"{len(all_names)} group modules; {end-1} witnesses")


if __name__ == "__main__":
    main()
