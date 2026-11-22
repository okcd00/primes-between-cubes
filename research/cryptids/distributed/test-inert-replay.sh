#!/usr/bin/env bash
# Tiny deterministic regression suite. No .olean worker inputs to the replay stage.
set -euo pipefail
[[ $# == 2 ]] || { echo 'usage: test-inert-replay.sh LEAN_433_BIN LEAN4EXPORT_CHECKOUT' >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
bin=$(realpath "$1")
exportdir=$(realpath "$2")
ex="$exportdir/.lake/build/bin/lean4export"
export PATH="$bin:$PATH" LEAN_NUM_THREADS=1 LEAN_ABORT_ON_PANIC=1
unset LEAN_PATH LEAN_SRC_PATH
[[ $(lean --version) == *819816b2e0a3bf405af45ae5c7af2491d8f5bee6* ]]
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cd "$temp"
cat > Producer.lean <<'LEAN'
theorem SlicePilot.input : True := True.intro
LEAN
cat > Consumer.lean <<'LEAN'
axiom SlicePilot.input : True
theorem SlicePilot.output : True := SlicePilot.input
LEAN
cat > Challenge.lean <<'LEAN'
theorem SlicePilot.output : True := by sorry
LEAN
cat > WrongRoot.lean <<'LEAN'
axiom SlicePilot.input : True
theorem SlicePilot.output : True ∧ True := ⟨SlicePilot.input, SlicePilot.input⟩
LEAN
cat > WrongBoundary.lean <<'LEAN'
axiom SlicePilot.input : False
theorem SlicePilot.output : True := SlicePilot.input.elim
LEAN
cat > AxiomProducer.lean <<'LEAN'
axiom SlicePilot.input : True
LEAN
cat > ChoiceProducer.lean <<'LEAN'
theorem SlicePilot.input : True := Classical.choice ⟨True.intro⟩
LEAN
cat > DefinitionProducer.lean <<'LEAN'
def SlicePilot.marker : Prop := True
theorem SlicePilot.input : SlicePilot.marker := True.intro
LEAN
cat > DefinitionConsumer.lean <<'LEAN'
def SlicePilot.marker : Prop := False
axiom SlicePilot.input : SlicePilot.marker
theorem SlicePilot.output : SlicePilot.marker := SlicePilot.input
LEAN
for f in Producer Consumer Challenge WrongRoot WrongBoundary AxiomProducer ChoiceProducer DefinitionProducer DefinitionConsumer; do
  lean -j1 -o "$f.olean" "$f.lean"
  case $f in
    *Producer) t=input;;
    *) t=output;;
  esac
  LEAN_PATH="$temp" "$ex" "$f" -- "SlicePilot.$t" > "$f.ndjson"
done
python3 -I - <<'PY'
import json
data=[json.loads(line) for line in open("Producer.ndjson")]
thm=next(row["thm"] for row in reversed(data) if "thm" in row)
newname=max(row["in"] for row in data if "in" in row)+1
add=[{"in":newname,"str":{"pre":0,"str":"propext"}},
     {"axiom":{"name":newname,"type":thm["type"],"levelParams":[],"isUnsafe":False}}]
with open("ForgedCore.ndjson","w") as f:
    for r in data+add: print(json.dumps(r),file=f)
# Preserve the exact signature but replace its proof by the proposition itself.
thm["value"]=thm["type"]
with open("IllTypedBody.ndjson","w") as f:
    for r in data: print(json.dumps(r),file=f)
data=[json.loads(line) for line in open("ChoiceProducer.ndjson")]
nonempty=next(r["in"] for r in data if r.get("str",{}).get("str")=="Nonempty" and r["str"]["pre"]==0)
ind=next(i for r in data if "inductive" in r for i in r["inductive"]["types"] if i["name"]==nonempty)
ind["isReflexive"]=not ind["isReflexive"]
with open("WrongCoreDependency.ndjson","w") as f:
    for r in data: print(json.dumps(r),file=f)
PY
replay() {
  LEAN_PATH="$exportdir/.lake/build/lib/lean" lean -j1 --run "$here/ReplaySlices.lean" tiny Challenge.ndjson "$@"
}
reject() {
  local tag=$1 pattern=$2
  shift 2
  if replay "$@" > "$tag.log" 2>&1; then echo "unexpected acceptance: $tag"; exit 1; fi
  grep -F "$pattern" "$tag.log" >/dev/null || { cat "$tag.log"; exit 1; }
  printf 'REJECTED %s\n' "$tag"
}
replay Producer.ndjson Consumer.ndjson
reject missing 'missing theorem predecessor' Consumer.ndjson
reject substituted 'unapproved axiom' AxiomProducer.ndjson Consumer.ndjson
reject wrong_type 'boundary type mismatch' Producer.ndjson WrongBoundary.ndjson
reject wrong_root 'root statement mismatch' Producer.ndjson WrongRoot.ndjson
reject wrong_type_under_allowed_name 'wrong type or declaration kind for trusted core axiom' ForgedCore.ndjson Consumer.ndjson
reject wrong_core_dependency 'trusted core dependency mismatch: Nonempty' WrongCoreDependency.ndjson Consumer.ndjson
reject wrong_definition_body 'conflicting declaration: SlicePilot.marker' DefinitionProducer.ndjson DefinitionConsumer.ndjson
reject ill_typed_proof_body "while replaying declaration 'SlicePilot.input'" IllTypedBody.ndjson Consumer.ndjson
