#!/usr/bin/env bash
# Reproduce an import trust boundary, not a Lean kernel bug.
# The substituted import declares an axiom intentionally; never part of the cube proof.
set -euo pipefail
[[ $# == 2 ]] || { echo 'usage: check-import-boundary.sh LEAN_433_BIN LEAN4EXPORT' >&2; exit 2; }
b=$(realpath "$1")
ex=$(realpath "$2")
unset LEAN_PATH LEAN_SRC_PATH
export PATH="$b:$PATH"
[[ $("$b/lean" --version) == *819816b2e0a3bf405af45ae5c7af2491d8f5bee6* ]]
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cd "$temp"
mkdir good alternate dependent
printf 'theorem trustedInput : True := True.intro\n' > good/ChunkA.lean
printf 'axiom trustedInput : True\n' > alternate/ChunkA.lean
printf 'import ChunkA\ntheorem output : True := trustedInput\n' > dependent/ChunkB.lean
printf 'import ChunkB\n#print axioms output\n' > RootAudit.lean
printf 'import ChunkA\n#print axioms trustedInput\n' > DirectAudit.lean
(cd good; lean -j1 -o ChunkA.olean ChunkA.lean)
(cd alternate; lean -j1 -o ChunkA.olean ChunkA.lean)
(cd dependent; LEAN_PATH="$temp/good" lean -j1 -o ChunkB.olean ChunkB.lean)
for a in good alternate; do
  export LEAN_PATH="$temp/dependent:$temp/$a"
  leanchecker -v ChunkB > "$a.replay.log"
  lean -j1 RootAudit.lean > "$a.root.log"
  lean -j1 DirectAudit.lean > "$a.direct.log"
  "$ex" ChunkB -- output > "$a.export"
done
cmp good.root.log alternate.root.log
grep -F 'trustedInput' alternate.direct.log >/dev/null
python3 -I - good.export alternate.export <<'PY2'
import json, sys
def owned(path):
    with open(path) as f:
        records = [json.loads(line) for line in f]
    names = {n["in"]: n["str"]["str"] for n in records if "in" in n and "str" in n}
    return [(kind, names.get(c["name"])) for row in records
            for kind in ("axiom", "thm") if (c := row.get(kind)) is not None]
g, a = map(owned, sys.argv[1:])
assert ("thm", "trustedInput") in g and ("axiom", "trustedInput") in a
assert ("thm", "output") in g and ("thm", "output") in a
print("NEGATIVE_CONTROL_PASS: rebound import accepted by stock module replay; "
      "fresh inert closure exposes the disallowed axiom")
PY2
