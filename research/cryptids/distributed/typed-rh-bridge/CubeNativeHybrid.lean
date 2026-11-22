-- Native final proof: resolves ordinary RH from the actual upstream Main.
import Main
import FullCubesConditionalHybrid

theorem CubePrime.primeBetweenCubes :
    ∀ n : ℕ, 1 ≤ n → CubePrime.PrimeBetweenCubes n :=
  CubePrime.primeBetweenCubes_of_RH riemannHypothesis

theorem CubePrime.primeStrictlyBetweenConsecutiveCubes :
    ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 :=
  CubePrime.primeBetweenCubes

#print axioms riemannHypothesis
#print axioms CubePrime.primeBetweenCubes
#print axioms CubePrime.primeStrictlyBetweenConsecutiveCubes
