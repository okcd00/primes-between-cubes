# Lean 4.33.1 compatibility checkpoint

This is the **cube side only** on the exact Lean and Mathlib versions of the recent
RH proof. No RH archive or unpublished proof source is copied or imported here.

- Lean `4.33.1`, commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
- Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`, the RH archive's pin.
- Cryptids `3647718b5df22e1a61462dec0376bd204526285a`, copied only into the
  replay directory from an existing public upstream checkout.

```sh
bash research/cryptids/backport433/replay-433.sh /path/to/cryptids
```

Set `CUBE_MATHLIB_PACKAGES` to reuse already prepared packages at the exact
versions in this lock. The replay imports the five minimal Cryptids modules,
then audits the large-range theorem and the finite checker and negative controls.
The compatibility patch retains the original theorem statements. It isolates
three small Mathlib shims (iterated digamma recurrence, zeta logarithmic derivative, and
two improper-integral scaling lemmas) and adjusts tactics for older APIs.
The borrowed source preserves Apache-2.0 attribution. See `MATHLIB-LICENSE`.

The large range is `n ≥ 65535`, with the same strict natural endpoint statement
and the same three standard Lean axioms as the 4.35.0-rc3 proof. It still takes
ordinary RH as a parameter. The generic finite verifier and negative controls
pass, but the full finite replay and the actual integration of the RH proof
must be audited separately. This does not constitute final acceptance.
