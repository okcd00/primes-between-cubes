#!/usr/bin/env bash
# Does not download, install, upload or use trusted mode.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
usage() {
  cat >&2 <<'USAGE'
Usage: verify-final.sh FINAL_NDJSON EXACT_CHALLENGE_435_NDJSON NEW_OUTPUT_DIR
Requires CON_LECHE_SOURCE (exact existing checkout and its built executable).
Set CUBE_VERIFY_JOBS to a small positive worker count; default one.
Input files stay local; paste only OUT/summary.txt.
USAGE
}
[[ $# -eq 3 ]] || { usage; exit 64; }
mode=match-final-435
cube=$(realpath -e "$1")
context=$(realpath -e "$2")
out_parent=$(dirname "$3")
[[ -d "$out_parent" ]] || { echo "Output parent missing" >&2; exit 64; }
out=$(realpath -m "$3")
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


step=pin_exact_challenge
h=$(sha256sum "$context" | cut -d ' ' -f1)
[[ "$h" == 75a70364fb0d9026f3220cf0ebae361cefb2df217f82a0cbd3279407d6728968 ]] ||
  { echo "Wrong isolated challenge digest" >&2; exit 66; }
report "isolated_challenge_sha256=$h"
report "candidate_final_sha256=$(sha256sum "$cube" | cut -d ' ' -f1)"
step=audit_no_extra_axioms
python3 -B "$here/audit_export_roles.py" exact-challenge "$context" >> "$summary"
python3 -B "$here/audit_export_roles.py" final "$cube" >> "$summary"
challenge=$context; solution=$cube
wanted=$'con-leche: axiom CubePrime.primeBetweenCubes justified by the solution\ncon-leche: axiom CubePrime.primeStrictlyBetweenConsecutiveCubes justified by the solution'
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
