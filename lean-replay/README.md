# Replay companion: conditional primes between consecutive cubes

This companion reproduces the RH-conditional theorem in Dian Chen's article.
It does not contain or check a proof of RH. The large range uses the ordinary
Riemann hypothesis as a premise; the finite range is unconditional.

## Stock Lean replay (Linux)

Install Lean 4.33.1 (release commit 819816b2e0a3bf405af45ae5c7af2491d8f5bee6),
including Lake, and have Python 3, Git, Bash, and flock available. Work in a
fresh extracted directory. Mathlib and other dependencies are resolved using
the included lake-manifest.json. Allow several GiB for dependency objects and
certificates; the runner uses one Lean process at a time.

    bash replay.sh

The runner obtains pinned dependency caches, compiles the narrow analytic
backport, generates 65,534 exact witnesses, and checks 256 finite groups with
Lean kernel reduction. Expected generator checksum:
846850f65b67ab03d5d1b2bbfe3a2dd5dc31c1ff0a6a09d59320c4078781119c.
It composes and audits both conditional formulations. The final line is
STOCK_LEAN_CONDITIONAL_OK. A smoke run (bash replay.sh --one-group) checks
the large branch and one finite group, not the all-range result. Start from
a fresh directory for a clean replay. Group receipts support local run
continuation; they do not authenticate binaries from another machine.
For an offline replay, CUBE_PREPARED_DEPS can provide the colon-separated
absolute search paths for the verified pinned dependency objects; no local
project objects should be on those paths.

## Independent exact-statement replay

Build lean4export at 15f6055e299ad5b89345e533cc2192f4cc00f659 with Lean 4.33.1.
Build con-leche from revision 5dc36dc15b7bee891a02406b78a8ac816a47baad with
its project toolchain (Lean 4.36.0). Use absolute executable paths:

    bash independent-compare.sh /path/to/lean4export /path/to/con-leche

The two inert exports total roughly 0.9 GB. The independent checker matches
both conditional statements against a separate challenge that imports only
Mathlib; the challenge's two axiom declarations are specifications, not
proofs. Neither is imported by the solution. Expected terminal status
INDEPENDENT_CONDITIONAL_OK.

## Upstream attributions

Cryptids (3647718b5df22e1a61462dec0376bd204526285a) supplies the Apache-2.0
analytic inputs with compatibility edits. Mathlib is pinned to
0df444a360eaa60ab8c11dca51a86af692955474; compatibility files preserve the
applicable notices. The pointwise and Pratt fragments are adapted from Steve
Hubbard's GoldbachLean (93b86c05bb441be2ac0b3f06cc4c8624f8e8d0eb). Upstream
licenses and notices are included. No third-party proof of RH, precompiled
object, or private experimental artifact is included.
