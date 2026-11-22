# Limited-resource proof sharding pilot

This is an engineering experiment for **the finite part**, not a claim of a new prime theorem, a new Lean kernel, or a completed RH proof split. The private Git branch transports source identities and progress receipts. An accepted receipt is never a proof or authority to execute/import a remote binary.

## Protocol

1. **Plan.** Start from the exact witness/certificate JSON SHA-256; regenerate the Lean source via the pinned renderer. The deterministic plan binds Lean, Mathlib, checker sources, every exact half-open interval, the source hash for each shard, and the final join source. There are 256 planned groups, each covering at most 256 intervals, with a total intended range `1 ≤ n < 65535`.
2. **Workers.** Each worker uses a pinned Mathlib dependency build from the same source, rebuilds the exact patched PrattCore, and compiles selected group sources using Lean's `decide +kernel` certificates. It writes local logs, measured compiler wall time and cumulative child peak RSS, source/transport identities and an axiom report. Receipts describe what ran; a worker can lie about them. The Mathlib binaries supplied by the operator are trusted inputs to this pilot, not independently checked by it.
3. **Collect versus join.** The collector checks group boundaries, plan/hash and axiom policy, rejects duplicates and inconsistent receipts, and reports advisory coverage. A separate native join imports **locally rebuilt** shard artifacts, with transport hashes recorded. It uses one physical module-prefix directory (simply stacking independent `FinitePratt` folders on `LEAN_PATH` does not work). The main proof still requires a theorem joined over all shards and independent replay of the final closure. Do not import user-supplied `.olean` objects based on a receipt.

## Reproduce the two-worker pilot

From the repository root, in a clean proof environment with the pinned Lean 4.33.1 toolchain:

```bash
I=research/cryptids/internal-runner
D=research/cryptids/distributed
RUN_DIR=/absolute/path/to/a/work-directory
export RUN_DIR LEAN_BIN
bash "$I/run.sh" --prepare-shards
python3 "$D/shards.py" plan "$RUN_DIR/cube/finite-full-candidates.json" "$RUN_DIR/layout"
python3 "$D/shards.py" work "$RUN_DIR/layout" "$RUN_DIR/cube" "$LEAN_BIN" "$RUN_DIR/worker-0" --groups 0
python3 "$D/shards.py" work "$RUN_DIR/layout" "$RUN_DIR/cube" "$LEAN_BIN" "$RUN_DIR/worker-1" --groups 1
python3 "$D/shards.py" coverage "$RUN_DIR/layout" "$RUN_DIR"/worker-?/receipts/*.json
bash "$D/join-pilot.sh" "$LEAN_BIN" "$RUN_DIR/cube" "$RUN_DIR/worker-0" "$RUN_DIR/worker-1" "$RUN_DIR/joined"
```

Set `LEAN_BIN` to the installed toolchain before running these commands. The two workers can be independently scheduled, but the join command here is a **same-host diagnostic for code you actually rebuilt**, not a remote-binary verifier. To reproduce a trust-boundary negative control, use `check-import-boundary.sh LEAN_433_BIN LEAN4EXPORT` with lean4export v4.33.0 built on 4.33.1.

## Observed, not extrapolated

The two worker directories were run on one 9.7 GiB Linux host, with concurrent unrelated proof builds. Each compiled one group. Their actual join proved `∀ n, 1 ≤ n → n < 513 → CubeAt n`; the axiom list contains only the three standard entries. The highest child RSS recorded by the two worker processes was about 2.00 and 2.15 GiB respectively (cumulative across child processes, not a whole-host or whole-range measurement). For these two shards, the compressed sources were 7.5 and 9.6 kB, versus 0.99 and 1.21 MB for compressed `.olean` objects. Rebuilding locally is an explicit compute-for-transfer tradeoff, not a speedup result. The [pilot data](pilot/) records exact sizes, checksums, and the two portable Lean source shards; binaries were not uploaded.

A deliberate negative control rebuilt an imported proposition as an axiomatic constant of the same name and type. The stock module replay still accepted the dependent declaration and its cached root axiom print was unchanged. Exporting the actual root closure to inert NDJSON and freshly inventorying its declaration tags did reveal the substituted axiom. This is a test of the documented **import trust boundary**, not a claim of an unsound Lean kernel. SHA hashes preserve the identity of chosen bytes; the semantic checks on those bytes still have to be performed.

## RH layer: what remains

Stock module replay already exists, and [the published independent RH verification](https://math.mit.edu/~drew/grh/) already ran it in parallel over every upstream module. It does not eliminate a worker's need to load that module's entire import graph. [Validation guidance](https://lean-lang.org/doc/reference/latest/ValidatingProofs/) and [leanvfy](https://github.com/theproofnetwork/leanvfy) also predate this pilot. The potentially useful contribution is the measured protocol and its failure controls on this derived proof, not being first to use modular replay or Git receipts.

A genuine lower-memory RH split would need to extract a declaration DAG from **types and bodies** of the exact named root, keep inductive families and recursors atomic, and preserve transparent definitions. Only opaque proof constants can be treated as typed boundary obligations. Each obligation must be discharged by an actually replayed, exact-type predecessor, with no cycles, duplicate ownership, wrong definition body, or residual nonstandard axioms. Independently created lean4export files have local numeric IDs and cannot simply be concatenated. Size and memory of that route are not measured; no RH or analytic acceptance is inferred from this finite pilot.

See [inert declaration replay and external-memory indexing](INERT-AND-INDEX.md) for the next experiment.
