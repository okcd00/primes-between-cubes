# Shared-order certificates for cube-prime verification

This is a finite-range verifier experiment, not a new primality criterion or an RH proof.
Use the same pinned Lean 4.33.1 and Mathlib as the
[common-stack cube route](https://github.com/okcd00/primes-between-cubes/tree/d872d5a3f4831a8971b0683489b7177e809e5743/research/cryptids).
Copy the files from this directory into the prepared project that already contains
`PrattCore.lean`, its checked object, and the pinned baseline candidate JSON.
The original finite renderer at 64 witnesses per batch and **four** batches per group
has 256 groups. Keep its output separate from this alternative.

## What the kernel checks

For each candidate integer `p`, take a residue `v`, a shared prime `R`, and check
`1 < p < R^2`, `1 <= v`, `v^R = 1 mod p` and `gcd(v-1,p) = 1`.
If `p` were composite, at the smallest prime divisor `q` the order of the
residue would be exactly `R`: its order divides `R` and it is not one.
Thus `R | (q-1)` and `p >= q^2 > R^2`, a contradiction.
The generator searches primes of the form `k*R+1` and computes the candidate
residue `v = 2^k mod p`. Neither the progression nor that derivation of the
residue needs to be trusted or repeated by the kernel. The actual order test
checks one modular exponentiation; the same Lean proof of primality for `R`
is reused. A fallback uses the original Lucas certificates. The checker
verifies the strict cube endpoints on both branches and uses `decide +kernel`
throughout, not `native_decide`.

The exact Python sweep with `R=16777259` found 54,844 of 65,534 intervals
(83.69%), with no misses for `39897 <= n < 65535`. The canonical JSON
mapping in ascending n (compact separators) has SHA-256
`75f603ee03e18d29b181f42b46e128cc5ef2cfbba97f2710a56293f557abbb38`.
No claim is made that the bound or progression strategy is new. Compare
[Johnston–Sorenson–Thomas–Webster, §2](https://arxiv.org/html/2601.15564v2#S2)
on large-factor progressions and [PrimeCert](https://github.com/b-mehta/PrimeCert)
on formal Pocklington testing; neither was used by the checker here.

## Matched upper-shard pilot

Both proofs establish the same exact proposition for **254** integers,
`65281 <= n < 65535`. They use different prime witnesses and the same pinned
toolchain, batch cap of 64, one `lean -j1` process at a time, and an already
compiled generic checker. The shared proof also checks the concrete root once
inside its measured module. Negative controls reject a wrong residue, a wrong
interval, a missing root certificate and a size-bound violation.

| Method | Wall time, trial 1 / 2 (s) | Peak child RSS (KiB), trial 1 / 2 | Lean source bytes | .olean bytes |
| --- | ---: | ---: | ---: | ---: |
| Lucas baseline | 46.348 / 46.874 | 3,701,904 / 3,701,828 | 86,504 | 10,562,912 |
| Shared order | 2.052 / 2.136 | 2,226,588 / 2,226,792 | 11,463 | 731,744 |

Measured with wait4 on the same cloud machine, alternating order. A third
baseline run overlapped the start of the separate full replay; it is excluded
from the table. This is a matched **compilation** result on the upper shard,
not cold dependency build time, independent inert replay, or all-range
speedup. The newer mixed-mode core object is 409,672 bytes (one-time reusable
overhead); no .olean files or witness archives are committed here.

To reproduce the two methods on that shard, with `LEAN_PATH` from the prepared
project and `LEAN_BIN` set to the pinned executable:

```sh
mkdir -p .lake/build/lib/lean bench
"$LEAN_BIN" -j1 -o .lake/build/lib/lean/OneFactorCore.olean OneFactorCore.lean
"$LEAN_BIN" -j1 OneFactorNegative.lean
python3 -B render_one_factor.py 65281 65535 OneFactorPilot.lean
python3 -B bench_one_factor.py OneFactorPilot.lean bench/shared.olean
python3 -B bench_one_factor.py FinitePratt/Group255.lean bench/base.olean
```

The optional `run_hybrid.sh 0` prepares all 256 hybrid groups from the verified
baseline JSON; with a nonzero prefix, only earlier *already checked* baseline
groups are reused. Keep old files in place so the baseline can be replayed
independently. A nonzero prefix is not a fresh replay. Resource limits on
closures involving RH are distinct from finite certification.

## Resumed finite-range result

A resumed replay used checked baseline groups 000–101 and newly kernel-checked
all 154 remaining groups (39,378 shared witnesses and 44 Lucas fallbacks). The
aggregate `CubePrime.OneFactor.finite_cube_range` compiled with exactly
`propext, Classical.choice, Quot.sound`, establishing the finite statement for
all `1 <= n < 65535`. Its generated `All.lean` had SHA-256
`580ec68b9ac559d4a8b24926c382d4d709e9c11be3a04422eebdaa84501ecf01`.
This is not a fresh all-hybrid replay; the proposed conditional wrapper and
the external RH integration have separate acceptance gates.

The updated runner verifies the Lean executable/version and available shared-library
digest, re-generates and compares all source bytes from the pinned JSON, and binds
resume receipts to compiled group byte hashes plus the root and core object/manifest
hashes. Prefix groups remain legacy local checkpoints with source-only receipts,
and neither set of receipts independently attests the entire imported environment.
For a clean audit choose prefix 0 and a fresh build directory with prepared pinned
dependencies. `CUBE_DIAGNOSTIC_GROUP=Group255` runs only that group, not the aggregate;
it was used for the successful digest/resume and tainted-receipt rebuild controls.
See [independent comparison](./INDEPENDENT-COMPARE.md) for the separate inert-kernel
result on both providers (and for the larger shared-order export).
