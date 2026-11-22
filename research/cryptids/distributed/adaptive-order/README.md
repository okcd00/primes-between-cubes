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
Group023 have actually compiled with the stock 4.33.1 kernel. At the time
of these pilot notes, the full clean all-adaptive group job was still running;
do not confuse generated data or group counts with aggregate success.

## Reproduce in the same prepared cube project

Copy `AdaptiveCore.lean` and `AdaptiveNegative.lean` into the prepared cube
project (where `PrattCore.lean` and checked `PrattCore.olean` and
`OneFactorCore.olean` are available). Pass the exact pinned `LEAN_BIN` and
`LEAN_PATH` and use this folder's `check_adaptive.sh`. The Python scripts
locate the existing `shared-order/render_one_factor.py` beside this folder.
For a clean assessment, use a fresh output project. The script regenerates
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
