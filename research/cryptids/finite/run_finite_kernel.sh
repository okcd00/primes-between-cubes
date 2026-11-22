#!/usr/bin/env bash
set -euo pipefail
mkdir -p .lake/build/lib/lean/FinitePratt finite-kernel-logs
export CUBE_FINGERPRINT
CUBE_FINGERPRINT=$(sha256sum PrattCore.lean lake-manifest.json lean-toolchain | sha256sum | cut -d " " -f 1)
printf '%s\0' FinitePratt/Group*.lean |
  xargs -0 -P "${CUBE_JOBS:-5}" -I '{}' bash -c '
    f=$1; name=${f##*/}; name=${name%.lean}
    fingerprint="$CUBE_FINGERPRINT $(sha256sum "$f" | cut -d " " -f 1)"
    if [[ -f finite-kernel-logs/$name.passed && -f .lake/build/lib/lean/FinitePratt/$name.olean ]] &&
       [[ "$(cat "finite-kernel-logs/$name.passed")" == "$fingerprint" ]]; then
      exit 0
    fi
    lake env lean -o ".lake/build/lib/lean/FinitePratt/$name.olean" "$f" > "finite-kernel-logs/$name.log" 2>&1 &&
      printf "%s\n" "$fingerprint" > "finite-kernel-logs/$name.passed"
  ' -- '{}'
lake env lean -o .lake/build/lib/lean/FinitePratt/All.olean FinitePratt/All.lean
lake env lean -o .lake/build/lib/lean/CubeTriangleLarge.olean CubeTriangleLarge.lean
lake env lean FullCubesConditional.lean
