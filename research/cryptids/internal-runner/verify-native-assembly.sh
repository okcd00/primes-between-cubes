#!/usr/bin/env bash
# Requires a prepared RH checkout and completed exact-same-version cube build.
# Run only inside a disposable, isolated environment. No downloads in this script.
set -euo pipefail
readonly rh_pin=58afe6f4b8167e8945f7c82954b0fc477541f9d0
readonly mathlib_pin=0df444a360eaa60ab8c11dca51a86af692955474
readonly lean_pin=819816b2e0a3bf405af45ae5c7af2491d8f5bee6
unset LEAN_PATH LEAN_SRC_PATH
here=$(cd "$(dirname "$0")" && pwd)
rh=$(realpath "${1:?usage: verify-native-assembly.sh RH-checkout cube-build-directory}")
cube=$(realpath "${2:?need completed cube build directory}")
test "$(git -C "$rh" rev-parse HEAD)" = "$rh_pin"
for root in "$rh" "$cube"; do
  test "$(git -C "$root/.lake/packages/mathlib" rev-parse HEAD)" = "$mathlib_pin"
  test -z "$(git -C "$root/.lake/packages/mathlib" status --porcelain --untracked-files=no)"
  v=$(cd "$root"; lake env lean --version)
  [[ "$v" == *"version 4.33.1,"*"$lean_pin"* ]]
done
test -z "$(git -C "$rh" status --porcelain --untracked-files=normal -- src lakefile.toml lake-manifest.json lean-toolchain)"
test -f "$rh/.lake/build/lib/lean/Main.olean"
test ! -e "$cube/.lake/build/lib/lean/Main.olean"
test ! -e "$rh/.lake/build/lib/lean/FullCubesConditional.olean"
test -f "$cube/.lake/build/lib/lean/FinitePratt/All.olean"
export LEAN_ABORT_ON_PANIC=1
cd "$cube"
lake env lean -j1 -o .lake/build/lib/lean/FullCubesConditional.olean FullCubesConditional.lean
lake env bash -c 'LEAN_PATH="$1:$LEAN_PATH" lean -j1 --tstack=400000 --root="$2" -o "$3" "$2/CubeWithoutHypotheses.lean"' _ \
  "$rh/.lake/build/lib/lean" "$here" "$cube/.lake/build/lib/lean/CubeWithoutHypotheses.olean" \
  2>&1 | tee cube-native-axioms.log
python3 "$here/audit-axioms.py" cube-native-axioms.log
