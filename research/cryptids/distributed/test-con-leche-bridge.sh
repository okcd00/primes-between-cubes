#!/usr/bin/env bash
# Two-export typed-boundary smoke test using the same pinned release as the RH verifier.
set -euo pipefail
[[ $# == 3 ]] || { echo 'usage: test-con-leche-bridge.sh LEAN_433_BIN LEAN4EXPORT CON_LECHE' >&2; exit 2; }
bin=$(realpath "$1")
exporter=$(realpath "$2")
checker=$(realpath "$3")
unset LEAN_PATH LEAN_SRC_PATH
export PATH="$bin:$PATH" LEAN_ABORT_ON_PANIC=1
[[ $(lean --version) == *819816b2e0a3bf405af45ae5c7af2491d8f5bee6* ]]
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cd "$temp"
cat > Provider.lean <<'LEAN'
def BridgePilot.meaning : Prop := True
theorem BridgePilot.assumption : BridgePilot.meaning := True.intro
LEAN
cat > Consumer.lean <<'LEAN'
def BridgePilot.meaning : Prop := True
axiom BridgePilot.assumption : BridgePilot.meaning
theorem BridgePilot.final : BridgePilot.meaning := BridgePilot.assumption
LEAN
cat > Wrong.lean <<'LEAN'
def BridgePilot.meaning : Prop := True ∧ True
theorem BridgePilot.assumption : BridgePilot.meaning := ⟨True.intro, True.intro⟩
LEAN
cat > Extra.lean <<'LEAN'
def BridgePilot.meaning : Prop := True
axiom BridgePilot.assumption : BridgePilot.meaning
axiom BridgePilot.extra : BridgePilot.meaning
theorem BridgePilot.final : BridgePilot.meaning ∧ BridgePilot.meaning :=
  ⟨BridgePilot.assumption, BridgePilot.extra⟩
LEAN
for p in Provider Consumer Wrong Extra; do
  lean -j1 -o "$p.olean" "$p.lean"
  case $p in Consumer|Extra) target=final;; *) target=assumption;; esac
  LEAN_PATH="$temp" "$exporter" "$p" -- "BridgePilot.$target" > "$p.ndjson"
done
python3 -I - <<'PY'
import json
with open("Provider.ndjson") as f:
    rows = [json.loads(line) for line in f]
d = next(r["thm"] for r in reversed(rows) if "thm" in r)
d["value"] = d["type"]
with open("ProviderIllTyped.ndjson","w") as f:
    for r in rows: print(json.dumps(r,separators=(",",":")),file=f)
PY
compare() { "$checker" --verified --jobs=1 --compare "$@"; }
reject() {
  local text=$1
  shift
  if compare "$@" > reject.log 2>&1; then echo 'unexpected acceptance'; exit 1; fi
  grep -F "$text" reject.log
}
compare Consumer.ndjson Provider.ndjson > good.log 2>&1
grep -F '1 axioms justified' good.log
grep -F 'BridgePilot.assumption justified by the solution' good.log
reject 'its type reads BridgePilot.meaning, which the solution does not declare alike' Consumer.ndjson Wrong.ndjson
reject 'the solution has no constant BridgePilot.extra' Extra.ndjson Provider.ndjson
reject 'type mismatch in theorem BridgePilot.assumption' Consumer.ndjson ProviderIllTyped.ndjson
