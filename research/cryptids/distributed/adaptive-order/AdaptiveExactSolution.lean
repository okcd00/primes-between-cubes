import FullCubesConditionalAdaptive
theorem CubePrime.primeStrictlyBetweenConsecutiveCubes_of_RH :
  RiemannHypothesis → ∀ n : ℕ, 1 ≤ n →
    ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 :=
  CubePrime.primeBetweenCubes_of_RH

#print axioms CubePrime.primeBetweenCubes_of_RH
#print axioms CubePrime.primeStrictlyBetweenConsecutiveCubes_of_RH
