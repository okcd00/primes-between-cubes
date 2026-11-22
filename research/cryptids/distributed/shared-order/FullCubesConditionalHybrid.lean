import CubeTriangleLarge
import FiniteHybrid.All

namespace CubePrime
def PrimeBetweenCubes (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

theorem primeBetweenCubes_of_RH (hRH : RiemannHypothesis) :
    ∀ n : ℕ, 1 ≤ n → PrimeBetweenCubes n := by
  intro n hn
  by_cases h : n < 65535
  · exact OneFactor.finite_cube_range n hn h
  · exact prime_between_large_nat_cubes_of_RH hRH (not_lt.mp h)

#print axioms primeBetweenCubes_of_RH
end CubePrime
