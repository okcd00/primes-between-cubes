# v1: a Lean formalization of primes between consecutive cubes, conditional on RH

Dian Chen. This private release freezes the first manuscript and reproducibility package. The mathematical implication is known: Caldwell and Cheng proved it in 2005 (Lemma 5). The contribution here is an explicit proof in Lean 4 with a cutoff at n = 65,535 and a shared-order witness checker for all 65,534 lower intervals.

**Statement:** Assuming the ordinary Riemann hypothesis, for every integer n >= 1 there exists a prime p with n^3 < p < (n+1)^3. The RH premise remains explicit; this release does not prove RH or the unconditional cube theorem.

## Release downloads

See the [v1 Release](https://github.com/okcd00/primes-between-cubes/releases/tag/v1) for the PDF, the arXiv TeX archive including the source-only Lean companion, and the standalone Lean replay archive. Follow the companion's README to rebuild. No external RH provider, compiled Lean objects, or private v2 draft is included. This GitHub Release does not submit the work to arXiv.

## Verification

The conditional theorem and the expanded equivalent statement passed Lean 4.33.1 (819816b2e0a3bf405af45ae5c7af2491d8f5bee6), Mathlib 0df444a360eaa60ab8c11dca51a86af692955474, and independent con-leche 5dc36dc15b7bee891a02406b78a8ac816a47baad. The native axiom audits yielded only propext, Classical.choice and Quot.sound; RH is an explicit assumption. No unconditional v2 result is asserted.

The witness generator uses 41 auxiliary primes to check 65,534 witnesses. The canonical witness stream has SHA-256 846850f65b67ab03d5d1b2bbfe3a2dd5dc31c1ff0a6a09d59320c4078781119c.

Preparation of code, certificates/replay scripts, and the manuscript used OpenAI Dot; see the disclosure in the manuscript.
