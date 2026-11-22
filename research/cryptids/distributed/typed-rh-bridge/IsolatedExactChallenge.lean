-- Specification only; not imported by the solution.
import Mathlib.Data.Nat.Prime.Defs

namespace CubePrime
def PrimeBetweenCubes (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

axiom primeBetweenCubes :
    ∀ n : ℕ, 1 ≤ n → PrimeBetweenCubes n
axiom primeStrictlyBetweenConsecutiveCubes :
    ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3
end CubePrime
