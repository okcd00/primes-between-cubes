import SchoenfeldTightAdapter
import BoundSolution

namespace CubePrime

def PrimeBetweenCubes (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

theorem primeBetweenCubes : ∀ n : ℕ, 1 ≤ n → PrimeBetweenCubes n :=
  CubeSchoenfeldTight.all_cubes_of_schoenfeld schoenfeld_strict_bound

theorem primeStrictlyBetweenConsecutiveCubes :
    ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 :=
  primeBetweenCubes

#print axioms riemannHypothesis
#print axioms schoenfeld_strict_bound
#print axioms primeBetweenCubes
#print axioms primeStrictlyBetweenConsecutiveCubes
end CubePrime
