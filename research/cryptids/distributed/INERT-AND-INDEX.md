# Inert declaration replay and disk-backed dependency selection

Two **different stages** are measured. Neither is a completed RH verifier or a claim about verifier asymptotics on the RH archive.

## Replay after typed boundary discharge

Two genuine finite cube proof exports supply [1,257) and [257,513). A tiny consumer uses explicitly typed proof boundaries, exported as placeholders. The executable pilot parses each inert export to structural Lean declarations; the local numeric IDs never cross files. Each placeholder must resolve to an earlier theorem of exactly the same structural signature, directly used in the consumer proof. Transparent definitions are not substituted. Duplicate declarations must match structurally; unsafe, partial, and unexpected axioms are rejected.

The pilot compares the exact selected target and its statement-dependency closure against a separately produced challenge. Allowed standard axioms and their relevant declaration closure are compared to the operator's pinned Lean Init both before and after replay. None of the challenge's proof or placeholder axioms is replayed. The union is replayed to a **fresh Lean 4.33.1 kernel environment** and the resulting kernel declaration is inspected. Its proof artifact input is NDJSON, not worker .olean files.

The real 512-interval run discharged both boundaries, replayed 7,556 declarations, and returned 0. Observed wall time was 56 s and peak child RSS about 1.06 GiB. This is a single run with other local proof jobs; do not interpret it as a general speedup. The tiny regression suite rejects a missing predecessor, a substituted axiom, a wrong boundary type, a wrong root proposition, a counterfeit permitted axiom signature, an altered core dependency, an altered transparent definition, and an ill-typed theorem body.

The pilot deliberately accepts only a few small exports and builds the whole merged declaration environment in RAM. It is not an independent kernel (it calls the official Lean kernel), not a general verifier for hostile or arbitrary-format exports, and not a drop-in substitute for Comparator. Keep the checker build's LEAN_PATH isolated from worker artifacts, and audit the exact trusted compiler, Init and challenge. Unsupported format details and projection/literal-specific dependency semantics still need an external checker rather than an assumption of coverage.

## External-memory index

`slice-index.py` takes one canonical NDJSON stream. It indexes file byte offsets and numeric/semantic lookup keys in SQLite, not entire parsed JSON objects. It traverses only the requested targets' dependency closure; both the visited set and worklist are disk-backed. One inductive record is atomic; quotient records are retained together, and `Nat`/string literal dependencies are conservatively included. Selected records are written in original order with IDs unchanged. For a reused index, a streaming SHA-256 scan checks that the source bytes are the same before accepting cached offsets. Do not run two queries concurrently against the same experimental database.

On 546,817 records (28.8 MB, real selected export of both group proofs and their join), the in-memory Python reference used 609,992 KiB RSS and took 8.53 s. The fresh SQLite path used 22,144 KiB RSS, 13.54 s, and 28.83 MB of index disk. Both emitted the same bytes, also byte-for-byte equal to lean4export's standalone group-000 export. A reused index answering the *same target* took 10.40 s. A much smaller target `CubePrime.Pratt.splice` queried with that same existing index took 0.36 s and retained 0.94 MB; that sparse-ID selection also replayed in the stock Lean kernel (599 declarations). These are single-run process observations with filesystem caching and concurrent unrelated work, not total machine RAM or RH timings.

**Finding:** about **28× less process RSS for the index stage**, at the price of extra disk and a slower first full-size query. In this workload the large group retained 98.5% of input bytes, so selecting it alone barely prunes that shared closure. The small splice target is not a proxy for RH. The final Lean replay still retains a full environment. Fewer B-tree lookups, batched frontier operations, and dropping only checked opaque proof bodies behind validated interfaces are the next candidates for actual end-to-end savings.

With input size B, N records, selected V records and E relevant edges, this prototype trades an eager decoded copy for a bounded SQLite page cache and current record/working rows. Initial scan is linear in B plus B-tree inserts; traversing selected records has lookup/I/O overhead on V+E, conservatively logarithmic per lookup. The metadata database costs O(N+V) rows plus name storage and the output costs its retained bytes. Reuse saves JSON indexing but still hashes O(B) bytes before traversing. It does not reduce the kernel proof-complexity bound.

## Reproduce

Use the trusted [lean4export checkout](https://github.com/leanprover/lean4export/tree/15f6055e299ad5b89345e533cc2192f4cc00f659) with Lean 4.33.1 on PATH; build `lake --no-cache build` and `lake --no-cache build +Export.Parse:olean` in that checkout. The tiny replay suite is:

```sh
bash research/cryptids/distributed/test-inert-replay.sh "$LEAN_BIN" "$EXPORTER_CHECKOUT"
```

For the genuine pilot, prepare both proof shards using the existing [worker instructions](README.md). Export `FinitePratt.Group000 -- CubePrime.Pratt.group_000` and `FinitePratt.Group001 -- CubePrime.Pratt.group_001` from their respective verified local worker paths. Separately compile `JoinBoundary.lean` and `PilotChallenge.lean` with only the verified PrattCore and Mathlib paths, never importing the group proof modules. Export each of those modules with the selector `-- CubePrime.Pratt.pilotFinitePrefix`. Then run with **only the trusted exporter library and Lean stdlib** on the replay program's search path:

```bash
D=research/cryptids/distributed
LEAN_PATH="$EXPORTER_CHECKOUT/.lake/build/lib/lean" \
  "$LEAN_BIN/lean" -j1 --run "$D/ReplaySlices.lean" cube \
  PilotChallenge.ndjson Group000.ndjson Group001.ndjson JoinBoundary.ndjson
```

For the index benchmark, export `JoinFirstTwo -- CubePrime.Pratt.group_000 CubePrime.Pratt.group_001 CubePrime.Pratt.pilotFinitePrefix` from the verified native pilot join. Compare the memory reference with:

```bash
python3 "$D/slice-index.py" disk union.ndjson group.ndjson CubePrime.Pratt.group_000 --db offsets.sqlite
python3 "$D/slice-index.py" disk --reuse --db offsets.sqlite -- union.ndjson splice.ndjson CubePrime.Pratt.splice
```

Measurements and hashes are in [the pilot record](inert-pilot/observations.json). The repository carries source and small records, not the full generated exports.
