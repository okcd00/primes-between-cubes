# Compact RH provider: isolated comparison

This experiment checks the independently published compact provider with
con-leche in verified mode. It does not build RH from source, change the
existing v2 run, combine Lean object files across toolchains, or claim either
final cube theorem has passed. Keep the old run and all its files untouched.
Use a separate writable directory and separate checker checkout on Linux.

## Operator

1. Verify that the old job is still in its low-load phase. Do not start if it
   has entered a heavy phase. Check the current machine's CPU and RAM usage.
2. Reuse a built, clean con-leche checkout at
   [5dc36dc15b7bee891a02406b78a8ac816a47baad](https://github.com/leanprover/con-leche/tree/5dc36dc15b7bee891a02406b78a8ac816a47baad).
   If unavailable, prepare that checkout and build its `con-leche` target
   with its pinned Lean 4.36.0, in an isolated directory. Do not upgrade the
   default toolchain or reuse the live project's package/build directories.
3. In a separate region of disk (16 GiB free minimum), run:
   ```bash
   CON_LECHE_SOURCE=/absolute/path/to/pinned/con-leche RH_CHECK_JOBS=2 \
     bash research/cryptids/distributed/compact-rh-probe/run.sh /absolute/new/result-dir
   ```
   The directory must not exist, but its parent must already exist. The script
   fetches only the published MIT exports over HTTPS, checks the full unpacked
   byte sizes and SHA-256 hashes, and runs the pinned checker at reduced CPU
   priority with two workers by default (one to four allowed), three hours
   maximum per comparison. It checks available RAM before each comparison.
   If the original workload starts its heavy phase, stop this probe, not the
   original. Do not post proofs, full logs, environment details, or internal
   paths publicly. Return only the short `summary.txt` privately.

`RH_PINNED_CUBE_BRIDGE` may point to the *already available*, exact
568,203,380-byte v2 typed bridge export; its known hash is required. Do not
rebuild this bridge merely to start the probe. Otherwise the script uses MIT's
published original Lean 4.33.1 five-root challenge, which includes ordinary
`riemannHypothesis`. An optional `RH_COMPACT_UNPACKED`, `RH_OLD_UNPACKED`
or `RH_NEW_UNPACKED` can supply the corresponding existing uncompressed
artifact instead of downloading; size and hash checks are unchanged.

## Reading the result

- Exit 0: verified comparison passed for every expected root of the selected
  challenge. The five-root challenge is not the exact cube consumer or native
  composition. The optional pinned cube bridge is the exact conditional
  consumer with only the RH hole to justify.
- Exit 3: the old comparison was not accepted, but the new proof's same-version
  five-root control passed. Read the first error; no conclusion about ordinary
  RH compatibility follows from a failure at another root or from resource or
  tooling limits.
- Exit 4: neither comparison passed. No incompatibility claim follows without
  checking the error. An earlier failure is recorded by stage and exit status.
- Native composition and exact final cube replay are separate gates, not
  performed by this script. Do not combine the result with an unrelated built
  artifact or change acceptance criteria.

Artifact provenance: [original challenge](https://math.mit.edu/~drew/grh/#downloads)
and [compact solution/own challenge](https://math.mit.edu/~drew/shortgrh/#downloads).
