#!/usr/bin/env bash
# Does not download, install, upload or use trusted mode.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
usage() {
  cat >&2 <<'USAGE'
Usage: verify-offline.sh {preflight|discharge|match-final} FILE EXPECTED_CONTEXT OUT
  preflight / discharge: FILE=bridge.ndjson EXPECTED_CONTEXT=MIT solution.ndjson
  match-final: FILE=final.ndjson EXPECTED_CONTEXT=isolated challenge.ndjson
Requires CON_LECHE_SOURCE (exact existing checkout and its built executable).
Set CUBE_VERIFY_JOBS to a small positive worker count; default one.
Input files stay local; paste only OUT/summary.txt.
USAGE
}
[[ $# -eq 4 ]] || { usage; exit 64; }
mode=$1
cube=$(realpath -e "$2")
context=$(realpath -e "$3")
out_parent=$(dirname "$4")
[[ -d "$out_parent" ]] || { echo "Output parent missing" >&2; exit 64; }
out=$(realpath -m "$4")
[[ "$mode" =~ ^(preflight|discharge|match-final)$ ]] || { usage; exit 64; }
[[ -f "$cube" && -s "$cube" && -f "$context" && -s "$context" ]] ||
  { echo "Inputs must be nonempty regular files" >&2; exit 64; }
[[ "$cube" != "$context" ]] || { echo "Inputs must be distinct" >&2; exit 64; }
: "${CON_LECHE_SOURCE:?provide the existing pinned checker checkout}"
src=$(realpath -e "$CON_LECHE_SOURCE")
pin=5dc36dc15b7bee891a02406b78a8ac816a47baad
[[ "$(git -C "$src" rev-parse HEAD)" == "$pin" ]] || { echo "Wrong checker pin" >&2; exit 65; }
git -C "$src" diff --quiet HEAD -- || { echo "Checker checkout has tracked changes" >&2; exit 65; }
checker="$src/.lake/build/bin/con-leche"
[[ -x "$checker" ]] || { echo "Missing built checker" >&2; exit 65; }
jobs=${CUBE_VERIFY_JOBS:-1}
[[ "$jobs" =~ ^[1-9][0-9]{0,2}$ ]] || { echo "Invalid worker count" >&2; exit 64; }

mkdir -- "$out" || { echo "Output directory must be new" >&2; exit 64; }
summary="$out/summary.txt"
report() { printf '%s\n' "$*" >> "$summary"; }
step=init
finish() {
  rc=$?
  report "mode=$mode step=$step exit=$rc"
}
trap finish EXIT
report "checker_source=$pin"
report "checker_binary_sha256=$(sha256sum "$checker" | cut -d ' ' -f1)"
report "jobs=$jobs"
report "input_bytes=$(stat -c '%s' "$cube")"
report "context_bytes=$(stat -c '%s' "$context")"
stamp() { stat -c '%d|%i|%s|%y|%z' -- "$1"; }
cube_before=$(stamp "$cube")
context_before=$(stamp "$context")

case "$mode" in
  preflight|discharge)
    step=pin_inputs
    [[ "$(stat -c '%s' "$context")" == 61570595788 ]] ||
      { echo "Wrong full MIT export byte length (compressed files are not accepted)" >&2; exit 66; }
    [[ "$(stat -c '%s' "$cube")" == 568203380 ]] || { echo "Wrong bridge size" >&2; exit 66; }
    h=$(sha256sum "$cube" | cut -d ' ' -f1)
    [[ "$h" == c062651bcb32445417250d8e342a11e78e76722b917730c993fa384a30a7aa23 ]] ||
      { echo "Wrong bridge digest" >&2; exit 66; }
    report "bridge_sha256=$h"
    step=check_provider_sha256
    h=$(sha256sum "$context" | cut -d ' ' -f1)
    [[ "$h" == 5ea74b912147c5c93cc2b6d70cc727cf908df2f62ac6a20480a3fa02f6be244e ]] ||
      { echo "Wrong MIT export digest" >&2; exit 66; }
    report "provider_sha256=$h"
    step=audit_bridge
    python3 -B "$here/audit_export_roles.py" bridge "$cube" >> "$summary"
    if [[ "$mode" == preflight ]]; then step=preflight_only_no_replay; exit 0; fi
    challenge=$cube; solution=$context
    wanted='con-leche: axiom riemannHypothesis justified by the solution'
    ;;
  match-final)
    step=pin_exact_challenge
    h=$(sha256sum "$context" | cut -d ' ' -f1)
    [[ "$h" == 2c1dbb56f2c18a63b8f57e1cd010b0a2d140642299b0bda7249de6cdddd8aad4 ]] ||
      { echo "Wrong isolated challenge digest" >&2; exit 66; }
    report "isolated_challenge_sha256=$h"
    report "candidate_final_sha256=$(sha256sum "$cube" | cut -d ' ' -f1)"
    step=audit_no_extra_axioms
    python3 -B "$here/audit_export_roles.py" exact-challenge "$context" >> "$summary"
    python3 -B "$here/audit_export_roles.py" final "$cube" >> "$summary"
    challenge=$context; solution=$cube
    wanted=$'con-leche: axiom CubePrime.primeBetweenCubes justified by the solution\ncon-leche: axiom CubePrime.primeStrictlyBetweenConsecutiveCubes justified by the solution'
    ;;
esac
step=verified_compare
"$checker" --verified --jobs="$jobs" --progress=60s --compare "$challenge" "$solution" > "$out/checker.log" 2>&1
step=unchanged_input_check
[[ "$(stamp "$cube")" == "$cube_before" && "$(stamp "$context")" == "$context_before" ]] ||
  { echo "An input changed during checking" >&2; exit 67; }
step=audit_enumerated_targets
got=$(grep -E '^con-leche: .* justified by the solution$' "$out/checker.log" | LC_ALL=C sort)
[[ "$got" == "$wanted" ]] || { echo "Unexpected comparison targets" >&2; exit 67; }
grep -E '^con-leche: accepted .*\(--verified\)$' "$out/checker.log" |
  sed -E 's/by the solution .* \(([0-9]+ declarations accepted)\)/by the solution (\1)/' >> "$summary"
printf '%s\n' "$got" >> "$summary"
step=compare_passed
