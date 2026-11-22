# Verification record

## Checked

- **Mathematical argument.** The statement for all positive integers was already derived from RH by Caldwell–Cheng, Lemma 5. This note gives a different short exposition using Dudek, Theorem 2. The mathematical reviewer checked the threshold, both strict endpoints, and the references. The v2 reference title was corrected after review.
- **New Lean bridge.** The primary run and two independent reviewer runs exited 0 with Lean 4.35.0-rc3 and Mathlib `c55e6e786f49471c72fbddbec5415808896aec1e`. `CubePrime.from_short_interval` takes `ShortIntervalBound` as an explicit premise. It proves the exact strict inequalities for all positive natural numbers. The only axioms reported for the implication were `propext`, `Classical.choice`, and `Quot.sound`.
- **Finite check.** Lean certifies 62 literal witnesses for `1 ≤ n ≤ 62`, using `norm_num` for primality and `decide` for both bounds. Independent exact trial division also verified all 62 literals. For `n ≥ 63`, set `m = n+1 ≥ 64`; no certificate or computation is needed for that range.
- **Upstream RH.** The community mirror at `58afe6f4b8167e8945f7c82954b0fc477541f9d0` declares `riemannHypothesis : RiemannHypothesis` in `src/Main.lean` with Lean 4.33.1. This record relies on the [published independent checks](https://math.mit.edu/~drew/grh/), not a local replay of the upstream RH artifact.

## Open dependency

[Hubbard’s Lean proof at `93b86c05bb441be2ac0b3f06cc4c8624f8e8d0eb`](https://github.com/sthubbar/goldbach-lean/blob/93b86c05bb441be2ac0b3f06cc4c8624f8e8d0eb/entries/dudek2014/LeanLab/Dudek2014/SigmaHSWDownstream.lean) contains `theorem2_of_RH_hsw`. In addition to RH it needs `HSWN70 gZ`, an explicit two-part bound on counts of zeta-zero ordinates with multiplicity. In traditional mathematics the input is available from [Hasanalizade–Shen–Wong, Corollary 1.2](https://arxiv.org/abs/2107.06506). Treating the paper citation as an axiom, adding it as a premise, or reporting only the axiom list of an implication would not close the requested Lean proof.

The analytic reviewer inspected the following routes; none directly proves the needed explicit bound:

- `PalomarArchive/anthropics--zeta-23-lean--94784dd69547` at `cec57f919ccf34e5fa5372b4ba332f7c848bbb6e`: verified asymptotic and local bounds, not the explicit HSW constants.
- `smmercuri/zeta` at `34037d5a7662e2eb6e970bfb22299c84e45ed5d9`: exact counting identity in terms of an argument function, not the required pointwise estimate for it.
- Alpöge’s mirror: a qualitative local count with an existential constant is not the explicit HSW bound.

A complete route must either formalize and port the missing explicit input, or prove an alternative sufficient interval theorem and match its constants with verified finite coverage. The upstream RH theorem, analytic step and cube bridge must be checked in a compatible environment. Before final acceptance, require the exact conclusion `∀ n : ℕ, 1 ≤ n → CubePrime.PrimeBetweenCubes n` with **no** unproved mathematical argument, a clean kernel run, an axiom audit, and a separate reviewer rerun on the exact commit.
