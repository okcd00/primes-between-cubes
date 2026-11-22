# Independent two-export discharge and a theorem-reduction counterexample

These are checked experiments on the **finite 1,024-interval prefix**, not on RH or the final cube-prime theorem.

## Two-export check

Build [con-leche](https://github.com/leanprover/con-leche/tree/5dc36dc15b7bee891a02406b78a8ac816a47baad) at that exact commit with Lean 4.36.0 (611c117bfaf7b7ae1cfcf246ce6fba31e8f509e9): `lake --no-cache build con-leche`. The exports here used Lean 4.33.1 and [lean4export](https://github.com/leanprover/lean4export/tree/15f6055e299ad5b89345e533cc2192f4cc00f659). The pinned checker is the one used in the [published independent checks of the RH export](https://math.mit.edu/~drew/grh/). Neither its typed-boundary protocol nor its resumable module scheduler is a new method of this project.

Run the small smoke test:

```bash
bash test-con-leche-bridge.sh "$LEAN_433_BIN" "$LEAN4EXPORT" "$CON_LECHE"
```

The independent checker accepted a matching separately exported proof. It rejected a changed definition in the hole's statement closure despite the same named type, an extra unsupplied hole, and an ill-typed mutated proof body.

For the genuine experiment, generate the first group using the original finite renderer layout (16 batches of 64, covering `1 ≤ n < 1025`), compile `PrattCore` and `FinitePratt.Group000` against the pinned Mathlib, and compile `FiniteConsumer1024.lean` separately without importing that group. The provider's generated Lean source SHA-256 was `d98623e9aadd1626776771e5f56dff7702222d38b02bb3010c35c7d9e5e638df`. Use the same prepared Lake search path and the exact module roots:

```sh
lean4export FinitePratt.Group000 -- CubePrime.Pratt.group_000 > FiniteProvider.ndjson
lean4export FiniteConsumer1024 -- CubePrime.Pratt.independentPrefix > FiniteConsumer.ndjson
con-leche --verified --jobs=1 --compare FiniteConsumer.ndjson FiniteProvider.ndjson
```

Actual result: the checker rechecked 6,927 provider and 380 consumer declarations and discharged exactly `CubePrime.Pratt.group_000`, with exit 0. Both files were separately scanned: the provider contains exactly `Classical.choice, Quot.sound, propext` as axiom declarations; the consumer contains only the one temporary hole and `propext`. Wall time was 62.95 s, with 567,344 KiB peak child RSS (0.54 GiB) on one worker while other local builds were running. No comparisons of checker performance or extrapolations to upstream are claimed.

| Input | Bytes | SHA-256 |
| --- | ---: | --- |
| `FiniteProvider.ndjson` | 29,701,616 | `e6634e81f1d1f90aefef32659c1f8af2ec9cad465874814be4d0105c10461d09` |
| `FiniteConsumer.ndjson` | 774,350 | `a3d1a22adfb86b6eedcf32d4dc6f6c54b0b2944df3092a609cc7f2ef644f56dc` |

The scoped next experiment is to export the actual cube bridge with exactly one boundary, `riemannHypothesis : RiemannHypothesis`, and independently run it against the checksum-pinned full upstream export. Check both final cube statements against the independently prepared challenge, the actual provider, and the permitted axiom closure. This avoids renumbering or rewriting the full upstream export; it **does not** avoid reading and checking it, lower the parse/verification working set by itself, or establish native stock Lean acceptance.

## A constraint on reducing replay memory

Run `bash test-theorem-reduction.sh "$LEAN_433_BIN"`. This calls the **stock** Lean 4.33.1 kernel with a raw theorem whose proof uses reduction of an `Acc.rec` through an earlier theorem. The original compiled with no axioms. Replacing that earlier theorem with a same-type axiom made the actual kernel reject the later proof, so retaining only the old theorem's interface is not a semantics-preserving optimisation for this toolchain. The ordinary elaborator can already refuse to unfold this proof; the test deliberately calls the kernel to isolate its conversion behavior.

The pinned con-leche revision also rejected the **unchanged genuine** older export of this special fixture at theorem `bodyMatters`. This does not refute its published RH results or the genuine finite check above; it is direct evidence that it is not a drop-in acceptor of every old proof using theorem reduction.

The [Lean change](https://github.com/leanprover/lean4/pull/14896) that makes theorem bodies opaque at kernel level is coupled to a [proposition elimination compatibility fix](https://github.com/leanprover/lean4/pull/14925). For stock 4.33.1, investigate sizing and demand paging while keeping theorem bodies **available**. An opaque-checker experiment must identify its changed conversion semantics, recheck the exact resulting proofs, and include proposition-elimination controls. Do not discard all old theorem bodies based on proof irrelevance alone.
