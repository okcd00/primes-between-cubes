# Adaptive shared-order experiment

This is a candidate replacement for the **finite** certificate layer, not a
proof of RH and not an unconditional cube-prime claim.

Start with the original shared root R=16,777,259 and preserve its 54,844
witnesses. For each uncovered interval, bucket n by floor(log2 n). For bucket
j, try the first five odd primes above the integer square root of
(2^(j+1))^3, skipping R. For each such root, search the open cube interval
for p=kR+1 with even k and check the same exact modular-order predicates.
All evidence remains untrusted until the stock kernel validates it.

The exact arithmetic run found a usable (p, v, R) for all 65,534 n; there
are only 41 distinct roots, proved together from 77 Lucas certificates.
One root per bucket left 228 intervals; four left only n=4; five were
enough. The n=4 tuple includes p=83, v=4, R=41, and the wrong neighboring
interval was rejected in a kernel control. The canonical ascending JSON
lines [n,p,v,R] have SHA-256
`846850f65b67ab03d5d1b2bbfe3a2dd5dc31c1ff0a6a09d59320c4078781119c`.

`AdaptiveCore.lean` certifies a root table with the checked Lucas fold once,
then applies the previously checked shared-order soundness lemma at each
tuple's root. Every row is validated with two strict bounds and a membership
check. The root table, missing-root and wrong-interval controls, and
Group023 compiled with the stock 4.33.1 kernel. The full replay below
is now separate verified evidence.

## Reproduce in the same prepared cube project

Copy `AdaptiveCore.lean` and `AdaptiveNegative.lean` into the prepared cube
project (where `PrattCore.lean` and checked `PrattCore.olean` and
`OneFactorCore.olean` are available). Pass the exact pinned `LEAN_BIN` and
`LEAN_PATH` and use this folder's `check_adaptive.sh`. The Python scripts
locate the existing `shared-order/render_one_factor.py` beside this folder.
For a clean assessment, use a fresh output project. It requires `flock`
to prevent concurrent runs in the same build. To reproduce the arithmetic-only
sweep explicitly use `python3 -B sweep.py --roots-per-bucket 5`. The aggregate
runner is finite-only; compile and audit `FullCubesConditionalAdaptive.lean`
separately to establish the full conditional implication. The script regenerates
the deterministic Lean source and compares it with any existing source tree;
local cache markers do not attest a remote kernel run.

```bash
# One-shard diagnostic, no aggregate:
CUBE_ADAPTIVE_DIAGNOSTIC_GROUP=Group023 bash /path/to/adaptive-order/check_adaptive.sh
# Full finite experiment:
bash /path/to/adaptive-order/check_adaptive.sh
```

For the exact same 256 intervals `5889 <= n < 6145`, a local observation
(with a second process running an unrelated comparison) was 34.450 s /
3,206,896 KiB / 8,386,336 olean bytes for Lucas and 2.157 s / 2,192,880 KiB /
1,009,016 olean bytes for adaptive. The common adaptive root-table object
is 115,448 bytes, excluded from the per-group times/bytes. Results are
one-observation matched statements, different witnesses, not independent
kernel measurements or whole-range speedup. Prior art remains the same:
large-factor progressions and Pocklington certificates are not new here.

## Completed stock-kernel result

All 256 groups of the new adaptive finite route compiled; no legacy Lucas
witness group was imported. The run was interrupted after Group249 by
a workspace restart then resumed from matching source and byte receipts.
The aggregate `CubePrime.Adaptive.finite_cube_range` was actually built and
passed with exactly `propext, Classical.choice, Quot.sound`; generated
`All.lean` SHA-256 is
`5aa1ae87ee608f9cc7531b8ac9f558101ca59248fc8797571d38c0246740d00d`.
The separate wrapper `FullCubesConditionalAdaptive.lean` also compiled,
with the same three axioms and explicit RH premise. The exact expanded
conditional wrapper compiled, too. `ConditionalExactChallenge.lean`
comes from a separate Mathlib-only project, and `AdaptiveExactSolution.lean`
is the actual provider. They are for an independent conditional comparison,
not an unconditional theorem. This checkpoint does not claim the independent
comparison or the actual upstream RH integration has passed.
