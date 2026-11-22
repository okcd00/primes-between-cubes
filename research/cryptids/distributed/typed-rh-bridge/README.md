# Checked conditional theorem and separate RH consumer

On Lean 4.33.1 commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`, with
Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`, the analytic closure
rebuilt through all 3,684 jobs and the resumed hybrid finite aggregate passed.
The actual `../shared-order/FullCubesConditionalHybrid.lean` source had SHA-256
`24ba56505680583c312a927aa05d633d90037f2f69c776a0596b8fb8bc2a0645`.
It compiled with exit 0 to establish `CubePrime.primeBetweenCubes_of_RH`
for all positive natural numbers, with ordinary RH an explicit premise
and only `propext, Classical.choice, Quot.sound` as Lean axioms.

## Already run

Use the standalone Mathlib-only `IsolatedExactChallenge.lean` and the separate
`CubeBridge.lean` (which imports the checked conditional theorem). Compile
them separately against the common stack. Export with Lean4Export
`15f6055e299ad5b89345e533cc2192f4cc00f659` and the pinned Lean binary in PATH:

```bash
lean4export IsolatedExactChallenge -- CubePrime.primeBetweenCubes CubePrime.primeStrictlyBetweenConsecutiveCubes > challenge.ndjson
lean4export CubeBridge -- CubePrime.primeBetweenCubes CubePrime.primeStrictlyBetweenConsecutiveCubes riemannHypothesis > bridge.ndjson
python3 audit_export_roles.py exact-challenge challenge.ndjson
python3 audit_export_roles.py bridge bridge.ndjson
```

Actual outcome: the two bridge theorem bodies compiled with exactly one
temporary nonstandard axiom, `riemannHypothesis`, besides the standard
three. The complete bridge export was audited at 568,203,380 bytes,
SHA-256 `c062651bcb32445417250d8e342a11e78e76722b917730c993fa384a30a7aa23`;
the independently compiled challenge was 774,695 bytes,
`2c1dbb56f2c18a63b8f57e1cd010b0a2d140642299b0bda7249de6cdddd8aad4`.
The bridge exporter peak monitored RSS was 4,428,248 KiB; low virtual
address-space limits can prevent mappings even when the real RSS would fit.
Neither inert artifact is checked into the repository.

## Not yet run: do not treat the bridge as a solution

With the actual [MIT verification export](https://math.mit.edu/~drew/grh/)
(checksum `5ea74b912147c5c93cc2b6d70cc727cf908df2f62ac6a20480a3fa02f6be244e`),
an eligible verifier must run the exact verified two-export comparison
`con-leche --verified --jobs=1 --compare bridge.ndjson solution.ndjson`
(version `5dc36dc15b7bee891a02406b78a8ac816a47baad`).
This must check the actual provider and justify exactly the single RH axiom.
Checking the bridge's axiom list locally does not discharge that premise.

The native solution is `CubeNativeHybrid.lean`, with the real `Main`
import instead of an axiom. It must be built against the same pinned library;
both exact target declarations and RH must pass the three-axiom audit.
Then export all three roots and require both independent exact goal matches
against the isolated challenge and real kernel checks. These are separate
gates from the successful conditional build and typed consumer export.
