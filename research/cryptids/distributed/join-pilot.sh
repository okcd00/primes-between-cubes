#!/usr/bin/env bash
# Diagnostic join for locally rebuilt/trusted pilot worker outputs only.
# Git receipts by themselves do not authorize importing remote .olean files.
set -euo pipefail
unset LEAN_PATH LEAN_SRC_PATH
[[ $# == 5 || $# == 6 ]] ||
  { echo 'usage: join-pilot.sh LEAN_BIN CUBE_DIR WORKER0 WORKER1 NEW_OUT_DIR [PACKAGE_OVERRIDE]' >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
bin=$(realpath "$1")
cube=$(realpath "$2")
a=$(realpath "$3")
b=$(realpath "$4")
out=$(realpath -m "$5")
args=(--no-cache)
if [[ $# == 6 ]]; then args+=("--packages=$(realpath "$6")"); fi
export PATH="$bin:$PATH"
[[ $("$bin/lean" --version) == *819816b2e0a3bf405af45ae5c7af2491d8f5bee6* ]]
test "$(git -C "$cube/.lake/packages/mathlib" rev-parse HEAD)" = 0df444a360eaa60ab8c11dca51a86af692955474
sp=$(cd "$cube"; "$bin/lake" "${args[@]}" env printenv LEAN_PATH)
mkdir "$out"
mkdir -p "$out/lib/FinitePratt"
# Lean resolves a module namespace under the first directory containing its
# prefix. Stage disjoint modules into one FinitePratt directory, not two roots.
cmp "$a/lib/PrattCore.olean" "$b/lib/PrattCore.olean"
cp "$a/lib/PrattCore.olean" "$out/lib/"
for k in 0 1; do
  worker=$a; [[ $k == 0 ]] || worker=$b
  name="Group00$k"
  dest="$out/lib/FinitePratt/$name.olean"
  cp "$worker/lib/FinitePratt/$name.olean" "$dest"
  python3 - "$worker/receipts/$name.json" "$dest" "$out/lib/PrattCore.olean" <<'PY2'
import hashlib, json, sys
with open(sys.argv[1]) as f:
    receipt = json.load(f)
for key, p in zip(("group_olean_sha256", "pratt_olean_sha256"), sys.argv[2:]):
    with open(p, "rb") as f:
        assert hashlib.sha256(f.read()).hexdigest() == receipt[key], f"local handoff mismatch: {key}"
PY2
done
# Do not permit the primary build's own groups to satisfy a missing pilot input.
IFS=: read -ra seen <<< "$sp"
safe="$out/lib"
for p in "${seen[@]}"; do
  [[ -n $p && "$p" != "$cube/.lake/build/lib/lean" && "$p" != .lake/build/lib/lean ]] || continue
  safe="$safe:$p"
done
cd "$out"
LEAN_PATH="$safe" "$bin/lean" -j1 --root="$here" -o "$out/lib/JoinFirstTwo.olean" "$here/JoinFirstTwo.lean" |
  tee "$out/axioms.log"
grep -F "'CubePrime.Pratt.pilotFinitePrefix' depends on axioms:" "$out/axioms.log"
python3 -I -B - "$out/axioms.log" <<'PY2'
import re, sys
m = re.findall(r"'CubePrime.Pratt.pilotFinitePrefix' depends on axioms: \[([^\]]+)\]",
               open(sys.argv[1]).read())
assert len(m) == 1 and set(s.strip() for s in m[0].split(",")) <= {"Classical.choice", "Quot.sound", "propext"}
PY2
