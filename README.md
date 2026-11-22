# Primes between consecutive cubes

For every positive integer `n`, there is a prime strictly between `n³` and `(n+1)³`. This is a classical consequence of the ordinary Riemann hypothesis, not a new number-theoretic theorem.

- [Two-page note](paper/primes-between-cubes.pdf) · [LaTeX source](paper/primes-between-cubes.tex)
- [Lean reduction and finite certificates](CubeBridge.lean)
- [Verification record and remaining dependency](verification/README.md)

**Status: not ready for end-to-end Lean acceptance.** Lean checks the reduction from Dudek’s short-interval bound and all 62 finite cases. No check has yet established the full implication chain from the recent Lean RH proof with no remaining mathematical premise.

## Reproduce the checked part

With [elan](https://github.com/leanprover/elan) and the pinned toolchain:

```sh
lake exe cache get CubeBridge.lean
lake env lean CubeBridge.lean
python3 verification/check_witnesses.py
```

The expected axiom report for **the implication** is `[propext, Classical.choice, Quot.sound]`. Its short-interval premise is an argument, not an axiom, and therefore does not appear in that audit. The source of the RH proof is [Alpöge’s announcement](https://alpo.ge/remark.pdf); the proof is [independently verified](https://leanprover-community.github.io/blog/posts/riemann-hypothesis/) and its theorem is [pinned here](https://github.com/leanprover-community/riemann-hypothesis/blob/58afe6f4b8167e8945f7c82954b0fc477541f9d0/src/Main.lean).
