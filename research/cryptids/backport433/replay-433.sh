#!/usr/bin/env bash
# Compile the cube side with the exact Mathlib baseline of Alpöge's RH.
# Does not restore or import the RH archive.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
upstream=${1:?usage: bash replay-433.sh /path/to/existing-Cryptids-clone}
pin=3647718b5df22e1a61462dec0376bd204526285a
git -C "$upstream" cat-file -e "$pin^{commit}"
work=$(mktemp -d)
printf 'Replay directory: %s\n' "$work"
for name in Schmidt VonMangoldtCount WeightedStieltjes DigammaBinet HorizontalBounds; do
  f="Cryptids/Semantics/Riemann/$name.lean"
  mkdir -p "$work/$(dirname "$f")"
  git -C "$upstream" show "$pin:$f" > "$work/$f"
done
git -C "$upstream" show "$pin:LICENSE" > "$work/CRYPTIDS-LICENSE"
cp "$src/"*.lean "$src/"HUBBARD-{LICENSE,NOTICE} "$work/"
cp -r "$src/finite" "$here/Compat" "$work/"
cp "$here/"{lean-toolchain,lakefile.toml,lake-manifest.json,MATHLIB-LICENSE} "$work/"
if [[ -n "${CUBE_MATHLIB_PACKAGES:-}" ]]; then
  mkdir "$work/.lake"
  ln -s "$(realpath "$CUBE_MATHLIB_PACKAGES")" "$work/.lake/packages"
fi
cd "$work"
git apply "$here/cryptids-433.patch"
git apply "$here/cube-433.patch"
version=$(lake env lean --version)
[[ "$version" == *"version 4.33.1,"*"819816b2e0a3bf405af45ae5c7af2491d8f5bee6"* ]]
lake build +Cryptids.Semantics.Riemann.WeightedStieltjes:olean \
  +Cryptids.Semantics.Riemann.DigammaBinet:olean +Cryptids.Semantics.Riemann.HorizontalBounds:olean \
  +Mathlib.NumberTheory.LucasPrimality:olean
for f in AuditCount AuditContour; do lake env lean -j1 "$f.lean"; done
for f in TriangleIdentity TriangleNumerics TriangleMass WeightedHeadTail TriangleContour TrianglePointwise TriangleResidues CubeTriangleLarge; do
  lake env lean -j1 -o ".lake/build/lib/lean/$f.olean" "$f.lean"
done
cp finite/{PrattCore,PrattNegativeControl,FullCubesConditional}.lean .
cp finite/run_finite_kernel.sh .
lake env lean -j1 -o .lake/build/lib/lean/PrattCore.olean PrattCore.lean
lake env lean -j1 PrattNegativeControl.lean
