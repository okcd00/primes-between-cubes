import Mathlib.Data.Nat.Prime.Defs

namespace CubePrime
theorem primeStrictlyBetweenConsecutiveCubes :
    ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 := by
  sorry -- Challenge statement only; never import it into the solution.
end CubePrime
