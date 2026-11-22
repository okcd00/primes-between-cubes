import Mathlib.Data.Nat.Prime.Defs

namespace CubePrime

def PrimeBetweenCubes (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

-- These are specification declarations, never imported by the solution.
theorem primeBetweenCubes :
    ∀ n : ℕ, 1 ≤ n → PrimeBetweenCubes n := by
  sorry

theorem primeStrictlyBetweenConsecutiveCubes :
    ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 :=
  primeBetweenCubes

end CubePrime
