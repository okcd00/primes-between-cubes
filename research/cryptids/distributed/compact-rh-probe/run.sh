#!/usr/bin/env bash
# Run only the isolated compact-RH comparison; never read or alter the live v2 build tree.
set -Eeuo pipefail
umask 077
export LC_ALL=C
pin=5dc36dc15b7bee891a02406b78a8ac816a47baad
provider_sha=ab7b4223b9bd748a1aa68bdb63afb6d6264121fc834aadba7ba3d3796c32115b
old_sha=bd484ac9886a96f26b1d9a7a59ebd45b7a70d102c015d4f31f9302bbdd6ab2b9
new_sha=20eb99a04b40f6afe1b44931e7ee82b15208542517dc588ace9634acffc41694
bridge_sha=c062651bcb32445417250d8e342a11e78e76722b917730c993fa384a30a7aa23
die() { printf '%s\n' "$*" >&2; exit 64; }
[[ $# == 1 ]] || die 'Usage: CON_LECHE_SOURCE=/clean/pinned/checkout bash run.sh /fresh/result-directory'
: "${CON_LECHE_SOURCE:?set to the separate checkout of the built checker}"
src=$(realpath -e -- "$CON_LECHE_SOURCE")
[[ "$(git -C "$src" rev-parse HEAD)" == "$pin" ]] || die "Expected checker source $pin"
git -C "$src" diff --quiet HEAD -- || die 'Checker checkout has tracked changes'
checker="$src/.lake/build/bin/con-leche"
[[ -x "$checker" ]] || die 'Missing pinned built checker'
for cmd in curl zstd sha256sum stat timeout nice awk grep sort realpath df; do
  command -v "$cmd" >/dev/null || die "Missing executable: $cmd"
done

mkdir -- "$1" || die 'Use a fresh result directory'
out=$(realpath -e -- "$1")
summary=$out/summary.txt
record() { printf '%s\n' "$*" | tee -a "$summary"; }
step=preflight
tmp=
finish() {
  local rc=$?
  if [[ -n "$tmp" ]]; then rm -f -- "$tmp" || :; fi
  record "stage=$step exit=$rc"
}
trap finish EXIT
jobs=${RH_CHECK_JOBS:-2}
[[ "$jobs" =~ ^[1-4]$ ]] || die 'RH_CHECK_JOBS must be 1–4'
record 'compact_commit=72fead102f663d5c7a407964a13dc0cf9d977207'
record "checker_commit=$pin"
record "checker_sha256=$(sha256sum < "$checker" | cut -d' ' -f1)"
record "jobs=$jobs"
record "free_kib=$(df -Pk -- "$out" | awk 'END {print $4}')"
minfree=16777216
(( $(df -Pk -- "$out" | awk 'END {print $4}') >= minfree )) || die 'Need at least 16 GiB free on the output filesystem'
memory_guard() {
  local avail
  avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  record "host_mem_available_kib=$avail"
  [[ "$avail" =~ ^[0-9]+$ ]] && (( avail >= 50331648 )) ||
     die 'Need at least 48 GiB currently available; do not compete with the existing run'
  # Also check finite ancestor limits for the current cgroup on standard cgroup v2 mounts.
  local p max cur
  p=$(awk -F: '$1=="0" && $2=="" {print $3}' /proc/self/cgroup)
  if [[ "$p" == /* && "$p" != *..* ]]; then
    p=/sys/fs/cgroup${p%/}
    while [[ "$p" == /sys/fs/cgroup* ]]; do
      if [[ -r "$p/memory.max" && -r "$p/memory.current" ]]; then
        read -r max < "$p/memory.max"
        read -r cur < "$p/memory.current"
        if [[ "$max" =~ ^[0-9]+$ && "$cur" =~ ^[0-9]+$ ]]; then
          (( max - cur >= 51539607552 )) || die 'Cgroup has less than 48 GiB remaining'
        fi
      fi
      [[ "$p" != /sys/fs/cgroup ]] || break
      p=${p%/*}
    done
  fi
}
memory_guard
stage_file() {
  local name=$1 url=$2 bytes=$3 sha=$4 staged=${5:-} actual
  tmp=$out/.$name.partial
  if [[ -n "$staged" ]]; then
    cp --reflink=auto -- "$staged" "$tmp"
  else
    curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' \
      --connect-timeout 20 --max-time 3600 --max-filesize 1073741824 -- "$url" |
      nice -n 10 zstd -q -d -c --long=30 -M1536MB | head -c "$((bytes + 1))" > "$tmp"
  fi
  [[ "$(stat -c %s -- "$tmp")" == "$bytes" ]] || die "Unexpected byte length: $name"
  actual=$(sha256sum < "$tmp" | cut -d' ' -f1)
  [[ "$actual" == "$sha" ]] || die "SHA-256 mismatch: $name"
  mv -T -- "$tmp" "$out/$name"
  tmp=
  record "${name}_sha256=$sha"
}
roots=$'LFunction_eq_zero_re\nLFunction_eq_zero_re_of_isPrimitive\nLFunction_ne_zero_of_half_lt_re\nriemannHypothesis\nriemannZeta_eq_zero_re'
compare() {
  local label=$1 challenge=$2 expected=$3 rc got
  memory_guard
  set +e
  local -a timer=()
  local started=$SECONDS
  if [[ -x /usr/bin/time ]]; then
    timer=(/usr/bin/time -f 'elapsed_seconds=%e peak_rss_kib=%M' -o "$out/$label.time")
  fi
  "${timer[@]}" timeout --kill-after=60s 3h nice -n 10 "$checker" \
    --verified --jobs="$jobs" --progress=60s --compare "$challenge" "$out/compact.ndjson" > "$out/$label.log" 2>&1
  rc=$?
  set -e
  record "${label}_checker_exit=$rc"
  record "${label}_wall_seconds=$((SECONDS - started))"
  if [[ -s "$out/$label.time" ]]; then
    grep -E '^elapsed_seconds=' "$out/$label.time" >> "$summary" || :
  fi
  if (( rc != 0 )); then
    # Full checker output stays local; take at most the first substantive error.
    grep -m1 -E '^con-leche: (invalid|unsupported|error):' "$out/$label.log" |
      cut -c1-420 >> "$summary" || :
    return 1
  fi
  got=$(sed -nE 's/^con-leche: (axiom|theorem) ([^ ]+) justified by the solution$/\2/p' "$out/$label.log" | sort)
  if [[ "$got" != "$expected" ]] ||
     ! grep -Eq '^con-leche: accepted .*\(--verified\)$' "$out/$label.log"; then
    record "${label}_evidence=UNEXPECTED"
    return 1
  fi
  while IFS= read -r root; do record "${label}_justified=$root"; done <<< "$got"
}
step=stage_provider
stage_file compact.ndjson https://math.mit.edu/~drew/shortgrh/compact-solution.ndjson.zst 5172274528 "$provider_sha" "${RH_COMPACT_UNPACKED:-}"
step=stage_old_challenge
if [[ -n ${RH_PINNED_CUBE_BRIDGE:-} ]]; then
  stage_file old.ndjson '' 568203380 "$bridge_sha" "$RH_PINNED_CUBE_BRIDGE"
  want=riemannHypothesis
  record 'old_challenge=exact_pinned_cube_bridge'
else
  stage_file old.ndjson https://math.mit.edu/~drew/grh/challenge.ndjson.zst 350862311 "$old_sha" "${RH_OLD_UNPACKED:-}"
  want=$roots
  record 'old_challenge=MIT_original_five_roots'
fi
step=compare_old
if compare old "$out/old.ndjson" "$want"; then
  record 'cross_version_comparison=PASS'
  record 'native_cube_composition=NOT_RUN'
  record 'exact_final_cube_replay=NOT_RUN'
  step=done
  exit 0
fi
record 'cross_version_comparison=NOT_ACCEPTED'
record 'native_cube_composition=NOT_RUN'
record 'exact_final_cube_replay=NOT_RUN'
# Use the new proof's own published challenge as a control. A failure at a
# different old root, a timeout, or a resource failure does not refute old RH.
step=stage_new_control
stage_file new.ndjson https://math.mit.edu/~drew/shortgrh/challenge.ndjson.zst 354827875 "$new_sha" "${RH_NEW_UNPACKED:-}"
step=compare_new_control
if compare new_control "$out/new.ndjson" "$roots"; then
  record 'same_version_control=PASS'
  exit 3
fi
record 'same_version_control=NOT_ACCEPTED'
exit 4
