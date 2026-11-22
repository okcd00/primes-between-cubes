#!/usr/bin/env bash
# Replay the proof components at the repository's locked Mathlib version.
# Input: an existing public Cryptids clone containing the exact revision.
set -euo pipefail
src=$(cd "$(dirname "$0")" && pwd)
upstream=${1:?usage: bash replay.sh /path/to/cryptids-clone}
pin=3647718b5df22e1a61462dec0376bd204526285a
git -C "$upstream" cat-file -e "$pin^{commit}"
work=$(mktemp -d)
echo "Replay directory: $work"
for name in Schmidt VonMangoldtCount WeightedStieltjes DigammaBinet HorizontalBounds; do
  f="Cryptids/Semantics/Riemann/$name.lean"
  mkdir -p "$work/$(dirname "$f")"
  git -C "$upstream" show "$pin:$f" > "$work/$f"
done
git -C "$upstream" show "$pin:LICENSE" > "$work/LICENSE.cryptids"
cp "$src/../../lean-toolchain" "$src/../../lake-manifest.json" "$work/"
cp "$src/"*.lean "$src/lakefile.toml" "$work/"
if [[ -n "${CUBE_MATHLIB_PACKAGES:-}" ]]; then
  mkdir "$work/.lake"
  ln -s "$(realpath "$CUBE_MATHLIB_PACKAGES")" "$work/.lake/packages"
fi
cd "$work"
lean_version=$(lake env lean --version)
[[ "$lean_version" == *"version 4.35.0-rc3,"* ]] || { printf "%s\n" "Unexpected Lean toolchain: $lean_version" >&2; exit 1; }
git apply "$src/rc3-compat.patch"
lake build \
  +Cryptids.Semantics.Riemann.WeightedStieltjes:olean \
  +Cryptids.Semantics.Riemann.DigammaBinet:olean \
  +Cryptids.Semantics.Riemann.HorizontalBounds:olean
for f in AuditCount AuditContour; do
  lake env lean "$f.lean"
done
for f in TriangleIdentity TriangleNumerics TriangleMass WeightedHeadTail TriangleContour TrianglePointwise TriangleResidues CubeTriangleLarge; do
  lake env lean -o ".lake/build/lib/lean/$f.olean" "$f.lean"
done
