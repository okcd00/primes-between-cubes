# Research branch: coarser explicit zero counts

This is not the paper's formal proof. Keep the Dudek–HSW dependency marked open on `main`.
The two arithmetic inequalities in `research/JensenNumerics.lean` can be checked with:

```sh
lake env lean research/JensenNumerics.lean
```

Use the toolchain and Mathlib revision in the repository manifest. Both implications require
`m ≥ 1/4` and `u ≥ 3`, and both use only the standard Lean axioms. They bound the expression
from Hubbard's `LeanLab.PNTPort.ZetaZeros.fz_count` when the normalization coefficient is
proved separately. They do not count any zeta zeros on their own. In particular, they neither
imply `HSWN70` nor permit substituting a weaker estimate in Hubbard's existing Theorem 2 proof.

## Next candidate

A direct global Jensen argument for the scaled entire xi function avoids piecing together local
windows and separately accounting for low ordinates. Set
`F(s) = 1 + s(s-1) Λ₀(s)`, with the pole-removed completed zeta from Mathlib. Away from the
two poles, it equals `s(s-1) Λ(s)`; for nontrivial zeta zeros it has the same multiplicity.
At the center 2 its value is `2 ζ(2)/π > 1/2`. For `T ≥ 4`, the disk of radius `5T/4` centered
at 2 contains the nontrivial zeros of ordinate at most T in absolute value. The proposed outer
radius is `2T`.

The missing bound is a quantitative estimate of the Mellin representation of Λ₀.
For `t ≥ 1`, the theta tail is bounded by `4 exp(-t)` by comparing its positive terms with a
geometric series. For `|s-2| ≤ 2T` both Mellin powers on `[1,∞)` are bounded by
`t^⌈T⌉`, so the factorial integral is a candidate exact majorant. This remains a proof sketch.
Even if formalized, the resulting count needs a separate smoothed prime-interval argument and
finite-range verification before any claim about all cubes. The upstream RH toolchain connection
also remains open.
