# Primes between consecutive cubes

For every positive integer `n`, there is a prime strictly between `n³` and `(n+1)³`. This is a classical consequence of the ordinary Riemann hypothesis, not a new number-theoretic theorem.

- [Two-page note](paper/primes-between-cubes.pdf) · [LaTeX source](paper/primes-between-cubes.tex)
- [Lean reduction and finite certificates](CubeBridge.lean)
- [Verification record and remaining dependency](verification/README.md)

**Status: unconditional v2 verification is pending.** The early two-page note on this branch checks a reduction from Dudek’s short-interval bound and 62 finite cases. The v1 release separately verifies the full-range theorem with ordinary RH as an explicit premise.

## Proof development: verified checkpoints and open gates

This repository is public to show the development and verification process. The entries below are milestones, not a v2 release.

| Checkpoint | Status |
| --- | --- |
| [Early note: Dudek reduction and 62 Lean-checked finite cases](paper/primes-between-cubes.pdf) | Checked with an explicit short-interval premise. |
| [v1 release: full-range theorem conditional on ordinary RH](https://github.com/okcd00/primes-between-cubes/releases/tag/v1) | Both statements passed stock Lean and independent con-leche replay. The finite range covers 65,534 checked intervals. |
| [Cryptids route: all positive integers](https://github.com/okcd00/primes-between-cubes/blob/b349053b2678be0f4fdf9ddb5e13bf63ff8f6c3b/research/cryptids/distributed/typed-rh-bridge/README.md) | The analytic bound and finite certificates were checked; ordinary RH remains an explicit premise. |
| [Independent statement challenge and typed RH bridge](https://github.com/okcd00/primes-between-cubes/tree/b349053b2678be0f4fdf9ddb5e13bf63ff8f6c3b/research/cryptids/distributed/typed-rh-bridge) | The two target statements and a bridge with one temporary RH axiom were exported separately. The standalone statement challenge was regenerated twice with byte-identical output. This does not discharge the axiom. |
| [Unconditional Lean acceptance](https://github.com/okcd00/primes-between-cubes/blob/d8ce662a1a105b0d8a8d3220b1df1f3e6af80900/research/cryptids/distributed/typed-rh-bridge/NATIVE_EXPORT_HANDOFF.md) | Pending: compose with the pinned Lean RH theorem, independently replay the exact final export and match both target statements, then review the proof source and manuscript for the same revision. |

## Reproduce the checked part

With [elan](https://github.com/leanprover/elan) and the pinned toolchain:

```sh
lake exe cache get CubeBridge.lean
lake env lean CubeBridge.lean
python3 verification/check_witnesses.py
```

The expected axiom report for **the implication** is `[propext, Classical.choice, Quot.sound]`. Its short-interval premise is an argument, not an axiom, and therefore does not appear in that audit. The source of the RH proof is [Alpöge’s announcement](https://alpo.ge/remark.pdf); the proof is [independently verified](https://leanprover-community.github.io/blog/posts/riemann-hypothesis/) and its theorem is [pinned here](https://github.com/leanprover-community/riemann-hypothesis/blob/58afe6f4b8167e8945f7c82954b0fc477541f9d0/src/Main.lean).
