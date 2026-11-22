#!/usr/bin/env bash
set -euo pipefail
trap 'echo ADAPTIVE_EXIT=$?' EXIT
here=$(cd "$(dirname "$0")" && pwd)
export LEAN_BIN=${LEAN_BIN:-lean}
: "${LEAN_PATH:?provide the prepared common-stack search path}"
[[ "$("$LEAN_BIN" --version)" == *"version 4.33.1,"*"819816b2e0a3bf405af45ae5c7af2491d8f5bee6"* ]]
command -v flock >/dev/null || { echo "Linux flock is required for a shared output directory." >&2; exit 64; }
exec 9> .adaptive-run.lock
flock -n 9 || { echo "Another adaptive run owns this output directory." >&2; exit 66; }
lib=.lake/build/lib/lean
temp=$(mktemp -d "./.adaptive-render-XXXXXX")
trap 'rc=$?; rm -rf -- "$temp"; echo ADAPTIVE_EXIT=$rc; exit "$rc"' EXIT
python3 -B "$here/render_adaptive.py" --output "$temp/FiniteAdaptive"
if [[ -d FiniteAdaptive ]]; then diff -qr "$temp/FiniteAdaptive" FiniteAdaptive
else mv "$temp/FiniteAdaptive" FiniteAdaptive; fi
mkdir -p "$lib/FiniteAdaptive" adaptive-order/receipts
[[ "$(find FiniteAdaptive -maxdepth 1 -name 'Group*.lean' |wc -l)" == 256 ]]
"$LEAN_BIN" -j1 -o "$lib/AdaptiveCore.olean" AdaptiveCore.lean
"$LEAN_BIN" -j1 -o "$lib/FiniteAdaptive/Root.olean" FiniteAdaptive/Root.lean
"$LEAN_BIN" -j1 AdaptiveNegative.lean
common=$(sha256sum "$lib/AdaptiveCore.olean" "$lib/OneFactorCore.olean" "$lib/PrattCore.olean" \
  "$lib/FiniteAdaptive/Root.olean" lean-toolchain lake-manifest.json | sha256sum | cut -d ' ' -f1)
groups=(FiniteAdaptive/Group*.lean)
if [[ -n "${CUBE_ADAPTIVE_DIAGNOSTIC_GROUP:-}" ]]; then
  [[ "$CUBE_ADAPTIVE_DIAGNOSTIC_GROUP" =~ ^Group[0-9]{3}$ ]]
  groups=("FiniteAdaptive/$CUBE_ADAPTIVE_DIAGNOSTIC_GROUP.lean")
  [[ -s "${groups[0]}" ]]
fi
for f in "${groups[@]}"; do
  n=${f##*/}; n=${n%.lean}
  obj="$lib/FiniteAdaptive/$n.olean"
  done_file="adaptive-order/receipts/$n.passed"
  input="$common $(sha256sum "$f" | cut -d ' ' -f1)"
  if [[ -s "$done_file" && -s "$obj" && "$(cat "$done_file")" == "$input $(sha256sum "$obj" | cut -d ' ' -f1)" ]]; then
      continue
  fi
  "$LEAN_BIN" -j1 -o "$obj" "$f" > "adaptive-order/receipts/$n.log" 2>&1
  printf '%s %s\n' "$input" "$(sha256sum "$obj" | cut -d ' ' -f1)" > "$done_file"
  echo "Accepted $n"
done
if [[ -n "${CUBE_ADAPTIVE_DIAGNOSTIC_GROUP:-}" ]]; then
  echo "Checked only $CUBE_ADAPTIVE_DIAGNOSTIC_GROUP; no aggregate requested."
else
  "$LEAN_BIN" -j1 -o "$lib/FiniteAdaptive/All.olean" FiniteAdaptive/All.lean | tee adaptive-order/aggregate.log
  grep -Fx "'CubePrime.Adaptive.finite_cube_range' depends on axioms: [propext, Classical.choice, Quot.sound]" adaptive-order/aggregate.log
fi
