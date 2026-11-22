#!/usr/bin/env bash
# Source-only, pinned Linux build. No sudo, credential handling, upload or non-Git downloads.
set -euo pipefail
unset LEAN_PATH LEAN_SRC_PATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export GIT_TERMINAL_PROMPT=0 LAKE_ARTIFACT_CACHE=false MATHLIB_NO_CACHE_ON_UPDATE=1
export LEAN_ABORT_ON_PANIC=1 PYTHONNOUSERSITE=1
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src=$(cd "$here/.." && pwd)
readonly LEAN_SHA=819816b2e0a3bf405af45ae5c7af2491d8f5bee6
readonly MATH_SHA=0df444a360eaa60ab8c11dca51a86af692955474
readonly RH_SHA=58afe6f4b8167e8945f7c82954b0fc477541f9d0
readonly CRYPT_SHA=3647718b5df22e1a61462dec0376bd204526285a
readonly SYMPY_SHA=16fa855354eb7bcabd3fe10993841e03b1382692
readonly MPMATH_SHA=b5c04506ef0cd4a1f1213f8389ee21c9c3551582
readonly WIDGETS_SHA=4be2e3d5087eeb272cf5a8853b8f9dd025ef5957
readonly DATA_SHA=fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d

case ${1:---run} in
  --probe) exec bash "$here/host-probe.sh";;
  --run|--cube-only);;
  *) printf 'Usage: bash run.sh [--probe|--run|--cube-only]\n' >&2; exit 2;;
esac
mode=${1:---run}
if [[ ${RUN_DIR:-} == /* ]]; then run_root=$RUN_DIR;
else run_root="$PWD/${RUN_DIR:-.cube-internal-run}"; fi
mkdir -p "$run_root/logs"
run_root=$(realpath "$run_root")
summary="$run_root/summary.txt"
lock="$run_root/.run-lock"
if ! command -v flock >/dev/null; then echo 'flock is required (usually provided by util-linux)' >&2; exit 2; fi
exec 9>"$lock"
flock -n 9 || { echo 'Another run is using this directory.' >&2; exit 2; }
printf 'CUBE_INTERNAL_RUN_V1\nmode=%s\n' "$mode" > "$summary"
stage=preflight
finish() {
  local rc=$?
  trap - EXIT
  {
    printf 'exit=%s\n' "$rc"
    if [[ $rc != 0 ]]; then printf 'stopped_at=%s\n' "$stage"; fi
    printf '%s\n' 'independent_export_replay=NOT_RUN'
  } >> "$summary"
  printf '\n--- Paste only this summary ---\n'
  cat "$summary"
  printf '%s\n' '--- End summary ---'
  exit "$rc"
}
trap finish EXIT
note() { printf '%s\n' "$*" | tee -a "$summary"; }
fail() { note "preflight_reason=$1"; exit 2; }
step() {
  stage=$1
  shift
  printf 'Running %s (details stay in local logs)\n' "$stage"
  local rc
  set +e
  (set -e; "$@") > "$run_root/logs/$stage.log" 2>&1
  rc=$?
  set -e
  if [[ $rc != 0 ]]; then
    note "$stage=FAIL"
    if [[ $stage == cube_finite ]]; then
      local count
      count=$(find "$cube/finite-kernel-logs" -maxdepth 1 -name 'Group*.passed' 2>/dev/null | wc -l)
      note "finite_groups_marked=$count/64"
    fi
    exit "$rc"
  fi
  note "$stage=PASS"
}
[[ $(uname -s) == Linux ]] || fail needs_linux
for t in git python3 sha256sum xargs realpath find getconf df awk flock grep make sort cut sed wc; do
  command -v "$t" >/dev/null || fail "missing_$t"
done
# The operator supplies a real, already installed Lean toolchain directory.
# Resolve binaries only within this explicit directory, so an elan shim cannot download.
[[ -n ${LEAN_BIN:-} ]] || fail set_LEAN_BIN_to_installed_toolchain_bin
toolbin=$(realpath "$LEAN_BIN")
[[ -x "$toolbin/lean" && -x "$toolbin/lake" ]] || fail lean_or_lake_not_executable
[[ $(basename "$(realpath "$toolbin/lean")") != elan ]] || fail use_real_toolchain_not_elan
[[ ! -e "$toolbin/elan" || ! "$toolbin/lean" -ef "$toolbin/elan" ]] || fail use_real_toolchain_not_elan
[[ -r "$toolbin/../lib/lean/Init.olean" ]] || fail missing_installed_toolchain_libraries
v=$(cd "$run_root"; "$toolbin/lean" --version 2>/dev/null) || fail lean_version_failed
[[ "$v" == *"version 4.33.1,"*"$LEAN_SHA"* ]] || fail wrong_lean_toolchain
export PATH="$toolbin:$PATH"
# Fail closed on any unanticipated npm invocation, even if npm is installed.
mkdir -p "$run_root/git-only-bin"
cat > "$run_root/git-only-bin/npm" <<'SH'
#!/bin/sh
printf '%s\n' 'Blocked unexpected registry tooling in Git-only run (npm).' >&2
exit 86
SH
chmod 700 "$run_root/git-only-bin/npm"
export PATH="$toolbin:$run_root/git-only-bin:$PATH"
note "lean=4.33.1:$LEAN_SHA"
note "mathlib=$MATH_SHA"
note "rh_source=$RH_SHA"
note "cryptids=$CRYPT_SHA"
cpu=$(getconf _NPROCESSORS_ONLN)
jobs=${CUBE_JOBS:-$((cpu < 6 ? cpu : 6))}
[[ "$jobs" =~ ^[1-9][0-9]*$ && $jobs -le "$cpu" && $jobs -le 32 ]] || fail invalid_CUBE_JOBS
export CUBE_JOBS=$jobs
if [[ $mode == --run ]]; then
  mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  if [[ -r /sys/fs/cgroup/memory.max ]]; then
    read -r memory_limit < /sys/fs/cgroup/memory.max
    if [[ "$memory_limit" =~ ^[0-9]+$ && $((memory_limit / 1024)) -lt $mem_kb ]]; then
      mem_kb=$((memory_limit / 1024))
    fi
  fi
  free_kb=$(df -Pk "$run_root" | awk 'NR==2{print $4}')
  [[ $mem_kb -ge $((60*1024*1024)) ]] || fail native_needs_about_64_GiB_RAM
  # Check free disk at the start; same-host resumes already consumed workspace disk.
  if [[ ! -f "$run_root/.started-native" ]]; then
    [[ $free_kb -ge $((145*1000*1000)) ]] || fail native_needs_about_150_GB_free_disk
    touch "$run_root/.started-native"
  fi
fi

# Git dependencies may be supplied by the operator's usual Git mirroring config.
# Each fresh checkout is detached at an immutable commit in this run directory.
get_repo() {
  local dest=$1 url=$2 sha=$3
  [[ ! -L "$dest" ]] || { echo 'Unexpected checkout symlink.' >&2; return 1; }
  if [[ ! -d "$dest/.git" ]]; then git init -q "$dest"; fi
  if ! git -C "$dest" cat-file -e "$sha^{commit}" 2>/dev/null; then
    git -C "$dest" fetch --no-tags --depth=1 "$url" "$sha"
  fi
  if [[ -n $(git -C "$dest" status --porcelain --untracked-files=normal) ]]; then
    echo 'Unexpected changes in dependency checkout (ignored build outputs are fine).' >&2
    return 1
  fi
  git -C "$dest" -c advice.detachedHead=false checkout -q --detach "$sha"
  [[ $(git -C "$dest" rev-parse HEAD) == "$sha" ]]
}
crypt="$run_root/cryptids"
cube="$run_root/cube"
rh="$run_root/rh"
sym="$run_root/sympy"
mp="$run_root/mpmath"
fetch_cube() {
  get_repo "$crypt" https://github.com/google-deepmind/cryptids.git "$CRYPT_SHA"
  get_repo "$sym" https://github.com/sympy/sympy.git "$SYMPY_SHA"
  get_repo "$mp" https://github.com/mpmath/mpmath.git "$MPMATH_SHA"
}
step cube_git fetch_cube

materialize() {
  local name f
  cd "$src"
  local fingerprint
  fingerprint=$(LC_ALL=C find ./*.lean backport433 finite internal-runner -maxdepth 2 -type f \( -name '*.lean' -o -name '*.py' -o -name '*.sh' -o -name '*.patch' -o -name 'lakefile.toml' -o -name 'lake-manifest.json' -o -name lean-toolchain \) -print0 |
    LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -d ' ' -f1)
  if [[ -f "$cube/.source-fingerprint" ]]; then
    [[ $(cat "$cube/.source-fingerprint") == "$fingerprint" ]] || {
      echo 'Source changed. Preserve the old run and use a new RUN_DIR.' >&2; return 1;
    }
    return 0
  fi
  [[ ! -e "$cube" || -f "$cube/.preparing" ]] || {
    echo 'Existing cube directory without marker; use a new RUN_DIR.' >&2; return 1;
  }
  mkdir -p "$cube"
  touch "$cube/.preparing"
  git init -q "$cube" # Isolate patch paths even when RUN_DIR is inside the calling repo.
  for name in Schmidt VonMangoldtCount WeightedStieltjes DigammaBinet HorizontalBounds; do
    f="Cryptids/Semantics/Riemann/$name.lean"
    mkdir -p "$cube/$(dirname "$f")"
    git -C "$crypt" show "$CRYPT_SHA:$f" > "$cube/$f"
  done
  git -C "$crypt" show "$CRYPT_SHA:LICENSE" > "$cube/CRYPTIDS-LICENSE"
  cp "$src/"*.lean "$src/"HUBBARD-{LICENSE,NOTICE} "$cube/"
  cp -r "$src/backport433/Compat" "$cube/"
  cp "$src/backport433/"{lean-toolchain,lakefile.toml,lake-manifest.json,MATHLIB-LICENSE} "$cube/"
  cp "$src/finite/"*.py "$cube/"
  mkdir -p "$cube/finite"
  cp "$src/finite/"{PrattCore,PrattNegativeControl,FullCubesConditional}.lean "$cube/finite/"
  cd "$cube"
  git apply "$src/backport433/cryptids-433.patch"
  git apply "$src/backport433/cube-433.patch"
  cp finite/{PrattCore,PrattNegativeControl,FullCubesConditional}.lean .
  grep -qx "import Mathlib.Tactic.Ring" PrattCore.lean
  printf '%s\n' "$fingerprint" > .source-fingerprint
  rm .preparing
}
step cube_setup materialize

prepare_finite_sources() {
  local candidate=$1 stage
  # Publish the generated directory atomically. Completed layouts remain reusable.
  # A newly built candidate file is already checked against DATA_SHA above.
  if [[ ! -d FinitePratt ]]; then
    stage=$(mktemp -d "$cube/.finite-render.XXXXXX")
    python3 -B render_pratt_range.py "$candidate" "$stage/FinitePratt"
    test -f "$stage/FinitePratt/All.lean"
    [[ $(find "$stage/FinitePratt" -maxdepth 1 -name 'Group*.lean' | wc -l) -eq 64 ]]
    mv -T "$stage/FinitePratt" FinitePratt
    rmdir "$stage"
  fi
  test -f FinitePratt/All.lean
  [[ $(find FinitePratt -maxdepth 1 -name 'Group*.lean' | wc -l) -eq 64 ]]
}

finite_data() {
  cd "$cube"
  # The pinned Python sources are used directly, without pip or a package index.
  export PYTHONPATH="$sym:$mp:$mp/src"
  python3 -B -c 'import sympy,mpmath; assert sympy.__version__=="1.14.0" and mpmath.__version__=="1.3.0"'
  local candidate=finite-full-candidates.json
  if [[ ! -f $candidate ]]; then
    python3 -B generate_cube_witnesses.py "$candidate.tmp"
    mv "$candidate.tmp" "$candidate"
  fi
  printf '%s  %s\n' "$DATA_SHA" "$candidate" | sha256sum -c -
  python3 -B verify_cube_witnesses.py "$candidate"
  prepare_finite_sources "$candidate"
}
step cube_data finite_data

# The pinned ProofWidgets Git tree already contains all generated widget JS.
# Disable only the two optional frontend rebuild targets, not Lean source.
prepare_git_only_lake() {
  lake --no-cache env lean --version
  local widgets=.lake/packages/proofwidgets
  [[ $(git -C "$widgets" rev-parse HEAD) == "$WIDGETS_SHA" ]]
  git -C "$widgets" diff --exit-code "$WIDGETS_SHA" -- widget/js
  local asset
  while IFS= read -r -d '' asset; do test -f "$widgets/$asset"; done \
    < <(git -C "$widgets" ls-tree -rz --name-only "$WIDGETS_SHA" -- widget/js)
  git -C "$widgets" show "$WIDGETS_SHA:lakefile.lean" > "$widgets/.lakefile-pinned.tmp"
  python3 -B - "$widgets" <<'PYW'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
original = (root / ".lakefile-pinned.tmp").read_bytes()
active = root / "lakefile.lean"
old = b"  needs := #[widgetJsAll]\n"
assert original.count(old) == 2
tuned = original.replace(old, b"  -- Use JS assets tracked at the pinned Git commit.\n")
assert active.read_bytes() in (original, tuned), "Unexpected ProofWidgets configuration changes"
if active.read_bytes() != tuned:
    active.write_bytes(tuned)
PYW
  rm "$widgets/.lakefile-pinned.tmp"
}

cube_deps() {
  cd "$cube"
  prepare_git_only_lake
  lake --no-cache build +Mathlib.NumberTheory.LucasPrimality:olean +Mathlib.Tactic.Ring:olean \
    +Cryptids.Semantics.Riemann.WeightedStieltjes:olean \
    +Cryptids.Semantics.Riemann.DigammaBinet:olean +Cryptids.Semantics.Riemann.HorizontalBounds:olean
  [[ $(git -C .lake/packages/mathlib rev-parse HEAD) == "$MATH_SHA" ]]
}
step cube_dependencies cube_deps

cube_analytic() {
  cd "$cube"
  mkdir -p .lake/build/lib/lean
  local f
  for f in AuditCount AuditContour; do lake env lean -j1 "$f.lean"; done
  for f in TriangleIdentity TriangleNumerics TriangleMass WeightedHeadTail TriangleContour TrianglePointwise TriangleResidues CubeTriangleLarge; do
    lake env lean -j1 -o ".lake/build/lib/lean/$f.olean" "$f.lean"
  done
}
step cube_analytic cube_analytic

cube_finite() {
  cd "$cube"
  lake env lean -j1 -o .lake/build/lib/lean/PrattCore.olean PrattCore.lean
  lake env lean -j1 PrattNegativeControl.lean
  sed 's/lake env lean -o/lake env lean -j1 -o/g;s/lake env lean FullCubesConditional.lean/lake env lean -j1 FullCubesConditional.lean/' \
    "$src/finite/run_finite_kernel.sh" > run_finite_local.sh
  bash run_finite_local.sh
  [[ $(find finite-kernel-logs -maxdepth 1 -name 'Group*.passed' | wc -l) -eq 64 ]]
}
step cube_finite cube_finite
note 'finite_groups=64/64'
note "candidate_sha256=$DATA_SHA"
if [[ $mode == --cube-only ]]; then note 'native_composition=NOT_RUN'; exit 0; fi

fetch_rh() { get_repo "$rh" https://github.com/leanprover-community/riemann-hypothesis.git "$RH_SHA"; }
step rh_git fetch_rh
build_rh() {
  cd "$rh"
  # Native build from pinned source, not the community build cache.
  prepare_git_only_lake
  lake --no-cache build +Main:olean
  [[ $(git -C .lake/packages/mathlib rev-parse HEAD) == "$MATH_SHA" ]]
}
step rh_build build_rh
assemble() { bash "$here/verify-native-assembly.sh" "$rh" "$cube"; }
step native_composition assemble
grep '^PASS ' "$run_root/logs/native_composition.log" >> "$summary"
