# Native runner → independent export handoff

This supplements, not replaces, the pinned offline verifier. It does not assert
that the native run or any full-provider check has passed.

* Wait for the actual internal runner at `b62a2fb90f3736f56d1d2fc5aeef27e4f47ce1c8`
  to finish with `mode=--run`, `native_composition=PASS`, all three native axiom
  lines and `exit=0`. Do not export from a live run or use the temporary typed bridge.
* The native module produced by that runner is **CubeWithoutHypotheses** under
  `RUN_DIR/cube/.lake/build/lib/lean`, not the earlier separately described
  CubeNativeHybrid. The actual `Main.olean` is in `RUN_DIR/rh/.lake/build/lib/lean`.
  Preserve the successful tree, exact toolchain, Mathlib pin, source fingerprint,
  and both search-path components. Do not replace `lake env` with only the RH
  object directory: the dependency object paths still matter.
* Use an already prepared Lean4Export executable built from
  `15f6055e299ad5b89345e533cc2192f4cc00f659` with the exact native Lean 4.33.1.
  Keep the work and exported artifacts local. Check available disk and memory
  before attempting the export: the complete native object closure is not a
  small file, and this recipe has not established its resource requirements.

In a fresh, private output directory on the intended disk, using absolute paths
`RUN_DIR`, `LEAN_BIN`, `EXPORTER`, `OUT` and `VERIFY_DIR`:

```bash
set -euo pipefail
unset LEAN_PATH LEAN_SRC_PATH
export PATH="$LEAN_BIN:$PATH" LEAN_ABORT_ON_PANIC=1
ulimit -c 0
test -s "$RUN_DIR/rh/.lake/build/lib/lean/Main.olean"
test -s "$RUN_DIR/cube/.lake/build/lib/lean/CubeWithoutHypotheses.olean"
cd "$RUN_DIR/cube"
test ! -e "$OUT/final.ndjson"
tmp=$(mktemp "$OUT/.final.ndjson.XXXXXX")
"$LEAN_BIN/lake" env bash -c 'LEAN_PATH="$1:$LEAN_PATH" exec "$2" CubeWithoutHypotheses -- CubePrime.primeBetweenCubes CubePrime.primeStrictlyBetweenConsecutiveCubes riemannHypothesis' _ \
  "$RUN_DIR/rh/.lake/build/lib/lean" "$EXPORTER" > "$tmp" 2> "$OUT/final-export.stderr"
python3 -B "$VERIFY_DIR/audit_export_roles.py" final "$tmp"
# Publish the local filename only after export and role audit; no overwrite.
ln -- "$tmp" "$OUT/final.ndjson"
unlink -- "$tmp"
sha256sum "$OUT/final.ndjson"
```

After that, run the pinned `verify-offline.sh match-final` with the exact isolated
challenge. Keep the separate genuine MIT-provider `discharge` check. Neither
export exit, name-role audit nor hash establishes statement equality or verifies
proofs. Do not use `--ignore-missing`, `--trusted`, or an old or partial export.
If export fails, preserve only the local diagnostic needed and do not pass the
temporary file to the checker as the final solution.

## Measured check of the export mechanics

On the genuine finite provider in the same Lean toolchain and exporter pin,
a correct export with the extra library prepended **inside** Lake reproduced the
existing 29,701,616 bytes, SHA-256
`e6634e81f1d1f90aefef32659c1f8af2ec9cad465874814be4d0105c10461d09`.
The saved local cache required its already-present package override; the native
runner's normal Git checkouts are not expected to need that workaround.
A split path without Lake's Mathlib dependencies rejected the import.
Appending one nonexistent root to the valid request produced a panic on stderr
but exited **0** by default and emitted a byte-identical valid prefix. With
`LEAN_ABORT_ON_PANIC=1` the same request exited **134** and still wrote that
prefix; the successful request remained byte-identical with the setting enabled.
Thus exit handling, temporary output and exact required-root checks are all useful.
These measurements are for the finite fixture, not for the native cube or RH export.
