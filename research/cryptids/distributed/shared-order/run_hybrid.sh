#!/usr/bin/env bash
# Use from a prepared Lean project with PrattCore already compiled. Path must
# resolve only the pinned Mathlib and this build's output directories.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
prefix=${1:-0}
[[ "$prefix" =~ ^(0|[1-9][0-9]{0,2})$ && "$prefix" -lt 256 ]]
: "${LEAN_PATH:?set LEAN_PATH from the prepared, pinned project}"
export LEAN_BIN=${LEAN_BIN:-lean}
lib=.lake/build/lib/lean
mkdir -p "$lib/FiniteHybrid" hybrid-logs
for ((g=0;g<prefix;g++)); do
  grp=$(printf 'Group%03d' "$g")
  [[ -s "$lib/FinitePratt/$grp.olean" ]] ||
    { echo "Missing baseline group $grp; rerun with prefix 0 or build checked baseline." >&2; exit 1; }
  # A precompiled olean is only a checkpoint; use prefix 0 for a fresh replay.
done
if [[ ! -d FiniteHybrid ]]; then
  python3 -B "$script_dir/render_hybrid.py" finite-full-candidates.json --from-group "$prefix"
fi
[[ "$(find FiniteHybrid -maxdepth 1 -name 'Group*.lean' | wc -l)" -eq $((256-prefix)) ]]
for ((g=0;g<256;g++)); do
  grp=$(printf 'Group%03d' "$g")
  if ((g < prefix)); then grep -qx "import FinitePratt.$grp" FiniteHybrid/All.lean
  else grep -qx "import FiniteHybrid.$grp" FiniteHybrid/All.lean; fi
done
"$LEAN_BIN" -j1 -o "$lib/OneFactorCore.olean" "$script_dir/OneFactorCore.lean"
"$LEAN_BIN" -j1 -o "$lib/FiniteHybrid/Root.olean" FiniteHybrid/Root.lean
"$LEAN_BIN" -j1 "$script_dir/OneFactorNegative.lean"
export HYBRID_FINGERPRINT
HYBRID_FINGERPRINT=$(sha256sum "$script_dir/OneFactorCore.lean" FiniteHybrid/Root.lean PrattCore.lean lake-manifest.json lean-toolchain | sha256sum | cut -d " " -f1)
printf '%s\0' FiniteHybrid/Group*.lean |
  xargs -0 -P "${CUBE_JOBS:-1}" -I '{}' bash -c '
    f=$1; name=${f##*/}; name=${name%.lean}
    key="$HYBRID_FINGERPRINT $(sha256sum "$f" | cut -d " " -f 1)"
    obj=".lake/build/lib/lean/FiniteHybrid/$name.olean"
    receipt="hybrid-logs/$name.passed"
    if [[ -s "$receipt" && -s "$obj" && "$(cat "$receipt")" == "$key" ]]; then exit 0; fi
    "$LEAN_BIN" -j1 -o "$obj" "$f" > "hybrid-logs/$name.log" 2>&1 &&
      printf "%s\n" "$key" > "$receipt"
  ' -- '{}'
"$LEAN_BIN" -j1 -o "$lib/FiniteHybrid/All.olean" FiniteHybrid/All.lean
