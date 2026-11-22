#!/usr/bin/env bash
# Regression: discarding a theorem proof body changes 4.33.1 kernel conversion.
set -euo pipefail
bin=$(realpath "${1:?usage: test-theorem-reduction.sh LEAN_433_BIN}")
unset LEAN_PATH LEAN_SRC_PATH
export PATH="$bin:$PATH"
[[ $(lean --version) == *819816b2e0a3bf405af45ae5c7af2491d8f5bee6* ]]
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
cd "$temp"
cat > Body.lean <<'LEAN'
import Lean

def EmptyRel : Nat → Nat → Prop := fun _ _ => False
theorem accessible : Acc EmptyRel 0 := Acc.intro 0 (fun _ h => False.elim h)
def readAcc : Nat := Acc.rec (motive := fun _ _ => Nat) (fun _ _ _ => 7) accessible

open Lean Elab Term in
run_elab do
  -- Bypass elaborator transparency: ask the actual kernel whether Eq.refl 7
  -- has type readAcc = 7. Do not disable checking or use an unsafe declaration.
  let type := mkApp3 (mkConst `Eq [.succ .zero]) (mkConst `Nat) (mkConst `readAcc) (mkNatLit 7)
  let value := mkApp2 (mkConst `Eq.refl [.succ .zero]) (mkConst `Nat) (mkNatLit 7)
  Lean.addDecl (.thmDecl { name := `bodyMatters, levelParams := [], type, value })

#print axioms bodyMatters
LEAN
lean -j1 Body.lean > with-body.log 2>&1
grep -F "'bodyMatters' does not depend on any axioms" with-body.log
sed 's/^theorem accessible .*$/axiom accessible : Acc EmptyRel 0/' Body.lean > Erased.lean
if lean -j1 Erased.lean > without-body.log 2>&1; then
  echo 'negative control unexpectedly passed'; exit 1
fi
grep -F "(kernel) declaration type mismatch, 'bodyMatters'" without-body.log
echo 'CONTROL_PASS theorem body is required by this stock Lean 4.33.1 kernel conversion'
