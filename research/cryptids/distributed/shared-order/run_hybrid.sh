#!/usr/bin/env bash
# Run from a prepared project. See README for baseline provenance boundaries.
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
prefix=${1:-0}
[[ "$prefix" =~ ^(0|[1-9][0-9]{0,2})$ && "$prefix" -lt 256 ]]
: "${LEAN_PATH:?set LEAN_PATH from the prepared pinned project}"
export LEAN_BIN=${LEAN_BIN:-lean}
lean_exe=$(command -v "$LEAN_BIN")
lean_info=$("$lean_exe" --version)
[[ "$lean_info" == *"version 4.33.1"* && "$lean_info" == *"819816b2e0a3"* ]]
lib=.lake/build/lib/lean
mkdir -p "$lib/FiniteHybrid" hybrid-logs
digest() { sha256sum "$1" | cut -d ' ' -f 1; }
baseline_key=$(sha256sum PrattCore.lean lake-manifest.json lean-toolchain | sha256sum | cut -d ' ' -f1)
for ((g=0;g<prefix;g++)); do
  grp=$(printf 'Group%03d' "$g")
  src="FinitePratt/$grp.lean"
  [[ -s "$lib/FinitePratt/$grp.olean" && -s "finite-kernel-logs/$grp.passed" &&
     "$(cat "finite-kernel-logs/$grp.passed")" == "$baseline_key $(digest "$src")" ]] ||
    { echo "Missing baseline checkpoint and matching source receipt for $grp; use prefix 0 for a fresh replay." >&2; exit 1; }
done
temp=$(mktemp -d "./.cubes-hybrid-render-XXXXXX")
trap 'rm -rf -- "$temp"' EXIT
python3 -B "$script_dir/render_hybrid.py" finite-full-candidates.json --from-group "$prefix" --output "$temp/FiniteHybrid"
if [[ -d FiniteHybrid ]]; then
  diff -qr -- "$temp/FiniteHybrid" FiniteHybrid
else
  mv -- "$temp/FiniteHybrid" FiniteHybrid
fi
"$LEAN_BIN" -j1 -o "$lib/OneFactorCore.olean" "$script_dir/OneFactorCore.lean"
"$LEAN_BIN" -j1 -o "$lib/FiniteHybrid/Root.olean" FiniteHybrid/Root.lean
"$LEAN_BIN" -j1 "$script_dir/OneFactorNegative.lean"
export HYBRID_FINGERPRINT
HYBRID_FINGERPRINT=$(
  {
    printf 'hybrid-v2\n%s\n' "$lean_info"
    for p in "$lean_exe" "$(dirname "$lean_exe")/../lib/lean/libleanshared.so" \
      "$script_dir/OneFactorCore.lean" "$lib/OneFactorCore.olean" FiniteHybrid/Root.lean \
      "$lib/FiniteHybrid/Root.olean" PrattCore.lean "$lib/PrattCore.olean" lake-manifest.json lean-toolchain; do
      if [[ -f "$p" ]]; then digest "$p"; else printf 'missing\n'; fi
    done
  } | sha256sum | cut -d ' ' -f 1
)
shopt -s nullglob
groups=(FiniteHybrid/Group*.lean)
if [[ -n "${CUBE_DIAGNOSTIC_GROUP:-}" ]]; then
  [[ "$CUBE_DIAGNOSTIC_GROUP" =~ ^Group[0-9]{3}$ ]]
  groups=("FiniteHybrid/$CUBE_DIAGNOSTIC_GROUP.lean")
  [[ -s "${groups[0]}" ]]
fi
printf '%s\0' "${groups[@]}" |
  xargs -0 -P "${CUBE_JOBS:-1}" -I '{}' bash -c '
    set -euo pipefail
    f=$1; name=${f##*/}; name=${name%.lean}
    key="$HYBRID_FINGERPRINT $(sha256sum "$f" | cut -d " " -f 1)"
    obj=".lake/build/lib/lean/FiniteHybrid/$name.olean"
    receipt="hybrid-logs/$name.passed"
    digest() { sha256sum "$1" | cut -d " " -f 1; }
    if [[ -s "$receipt" && -s "$obj" && "$(cat "$receipt")" == "$key $(digest "$obj")" ]]; then exit 0; fi
    "$LEAN_BIN" -j1 -o "$obj" "$f" > "hybrid-logs/$name.log" 2>&1
    printf "%s %s\n" "$key" "$(digest "$obj")" > "$receipt.tmp"
    mv -f -- "$receipt.tmp" "$receipt"
  ' -- '{}'
if [[ -n "${CUBE_DIAGNOSTIC_GROUP:-}" ]]; then
  echo "Checked only $CUBE_DIAGNOSTIC_GROUP; no aggregate requested."
else
  "$LEAN_BIN" -j1 -o "$lib/FiniteHybrid/All.olean" FiniteHybrid/All.lean
fi
