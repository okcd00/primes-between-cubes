#!/usr/bin/env bash
# Install an explicitly pinned, local Linux Lean toolchain; no sudo or shell-profile edits.
set -euo pipefail
unset LEAN_PATH LEAN_SRC_PATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export GIT_TERMINAL_PROMPT=0
readonly pin=819816b2e0a3bf405af45ae5c7af2491d8f5bee6
readonly leangz_pin=46485d0eca748ed2d2678e70d59949bbc602f32c
usage() { cat <<'HELP'
Usage: bash install-lean.sh --release | --archive FILE | --git | --check BIN_DIR
Install directory defaults to .lean-local (override LEAN_INSTALL_DIR).
--release downloads the official archive; --archive accepts the same verified file offline.
--git builds pinned Git source; needs CMake/Make/C++/LibUV/OpenSSL and leantar 0.1.20,
      or an already populated offline Cargo cache for leantar. No package installs.
--check verifies an existing installed bin directory without installing anything.
HELP
}
die() { printf 'Lean setup: %s\n' "$*" >&2; exit 2; }
require() { command -v "$1" >/dev/null || die "missing command: $1"; }
confirm_toolchain() {
  local p=$1 version lake_version
  [[ -x $p/lean && -x $p/lake && -r $p/../lib/lean/Init.olean ]] ||
    die 'expected the real toolchain bin directory (with lib/lean/Init.olean), not an elan shim'
  [[ $(basename "$(realpath "$p/lean")") != elan && (! -e $p/elan || ! $p/lean -ef $p/elan) ]] ||
    die 'elan shim is not a toolchain executable'
  version=$("$p/lean" --version)
  [[ $version == *"version 4.33.1,"*"$pin"* ]] || die "unexpected Lean version: $version"
  lake_version=$(PATH="$p:$PATH" "$p/lake" --version)
  [[ $lake_version == *"Lean version 4.33.1"* ]] || die "unexpected Lake version: $lake_version"
}
printf_bin() { confirm_toolchain "$1"; printf '%s\n' "$1"; }
case ${1:-help} in
  help|--help|-h) usage; exit 0;;
  --check) [[ $# -eq 2 ]] || die '--check requires one bin directory'
    require realpath; printf_bin "$(realpath "$2")"; exit 0;;
  --release|--git) [[ $# -eq 1 ]] || die 'unexpected arguments';;
  --archive) [[ $# -eq 2 ]] || die '--archive requires a release archive';;
  *) usage >&2; exit 2;;
esac
mode=$1
[[ $(uname -s) == Linux ]] || die 'this installer supports Linux only'
case $(uname -m) in
  x86_64)    plat=linux; digest=890afd185370f85666025b883914ab4f4b339136f8c96167b69cfb62aecaf235 ;;
  aarch64)   plat=linux_aarch64; digest=f7353a8b2a8741c84558523e450556f9a1c45e3cafcf54399ce68c6a24c55f07 ;;
  *) die 'supported architectures are x86_64 and aarch64';;
esac
require realpath
require flock
root=${LEAN_INSTALL_DIR:-"$PWD/.lean-local"}
mkdir -p "$root"
root=$(realpath "$root")
exec 8>"$root/.install.lock"
flock -n 8 || die 'another installer is using this directory'

if [[ $mode != --git ]]; then
  for t in sha256sum tar zstd mktemp; do require "$t"; done
  asset="lean-4.33.1-$plat"
  final="$root/$asset"
  if [[ -e $final ]]; then printf_bin "$final/bin"; exit; fi
  stage=$(mktemp -d "$root/.release.XXXXXX")
  trap 'rm -rf -- "$stage"' EXIT
  if [[ $mode == --release ]]; then
    require curl
    file="$stage/$asset.tar.zst"
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
      "https://github.com/leanprover/lean4/releases/download/v4.33.1/$asset.tar.zst" -o "$file"
  else
    file=$(realpath "$2")
    [[ -f $file ]] || die 'release archive not found'
  fi
  # GitHub release API SHA-256 for the exact platform asset, checked before extraction.
  actual=$(sha256sum < "$file"); actual=${actual%% *}
  [[ $actual == "$digest" ]] || die 'archive SHA-256 mismatch'
  tar --zstd -xf "$file" -C "$stage" --no-same-owner
  confirm_toolchain "$stage/$asset/bin"
  mv -T "$stage/$asset" "$final"
  printf_bin "$final/bin"
  exit
fi

for t in git cmake make cc c++ pkg-config getconf; do require "$t"; done
pkg-config --exists libuv openssl || die 'development files for libuv and OpenSSL must be present'
n=$(getconf _NPROCESSORS_ONLN)
jobs=${LEAN_BUILD_JOBS:-$(( n < 8 ? n : 8 ))}
[[ $jobs =~ ^[1-9][0-9]*$ && $jobs -le $n && $jobs -le 64 ]] || die 'invalid LEAN_BUILD_JOBS'
get_src() {
  local dest=$1 url=$2 rev=$3
  [[ ! -L $dest ]] || die 'refusing a symlink as source checkout'
  [[ -d $dest/.git ]] || git init -q "$dest"
  if ! git -C "$dest" cat-file -e "$rev^{commit}" 2>/dev/null; then
    git -C "$dest" fetch --no-tags --depth=1 "$url" "$rev"
  fi
  [[ -z $(git -C "$dest" status --porcelain --untracked-files=normal) ]] ||
    die 'existing source checkout is dirty (use a new LEAN_INSTALL_DIR)'
  git -C "$dest" -c advice.detachedHead=false checkout --quiet --detach "$rev"
  [[ $(git -C "$dest" rev-parse HEAD) == "$rev" ]]
}
lt=${LEANTAR_BIN:-$(command -v leantar || true)}
if [[ -z $lt ]]; then
  cargo_bin=${CARGO_BIN:-$(command -v cargo || true)}
  rustc_bin=${RUSTC_BIN:-$(command -v rustc || true)}
  [[ -n $cargo_bin && -n $rustc_bin ]] ||
    die 'provide trusted leantar 0.1.20 via LEANTAR_BIN, or Rust/Cargo with an offline dependency cache'
  cargo_bin=$(realpath "$cargo_bin"); rustc_bin=$(realpath "$rustc_bin")
  for tool in "$cargo_bin" "$rustc_bin"; do
    [[ -x $tool && $(basename "$tool") != rustup &&
       (! -e $(dirname "$tool")/rustup || ! $tool -ef $(dirname "$tool")/rustup) ]] ||
      die 'specify real preinstalled CARGO_BIN/RUSTC_BIN, not rustup shims'
  done
  get_src "$root/leangz" https://github.com/digama0/leangz.git "$leangz_pin" >&2
  RUSTC="$rustc_bin" CARGO_NET_OFFLINE=true CARGO_TARGET_DIR="$root/leangz-target" \
    "$cargo_bin" build --manifest-path "$root/leangz/Cargo.toml" --offline --locked --release --bin leantar >&2 ||
    die 'offline Cargo build failed; provide a trusted leantar 0.1.20 via LEANTAR_BIN'
  lt="$root/leangz-target/release/leantar"
fi
lt=$(realpath "$lt")
[[ -x $lt && $("$lt" --version) == 'leantar 0.1.20' ]] || die 'expected leantar 0.1.20'
src="$root/lean-src"
build="$root/lean-build"
get_src "$src" https://github.com/leanprover/lean4.git "$pin" >&2
# LEANTAR is provided explicitly to prevent Lean's CMake release download. The
# upstream CaDiCaL fallback is Git (rel-2.1.2), not a package manager download.
# Avoid unreliable system GMP versions by using Lean's built-in bignums.
cmake -S "$src" -B "$build" -G 'Unix Makefiles' \
  -DCMAKE_BUILD_TYPE=Release -DLEANTAR="$lt" -DUSE_MIMALLOC=OFF -DUSE_GMP=OFF >&2
cmake --build "$build" --parallel "$jobs" >&2
printf_bin "$build/stage1/bin"
