import SchoenfeldTightGate
import FinitePratt.Group000
import FinitePratt.Group001

namespace CubeSchoenfeldTight
open scoped BigOperators

theorem finite_prefix : ∀ n : ℕ, 1 ≤ n → n < 513 → CubePrime.Pratt.CubeAt n :=
  CubePrime.Pratt.splice CubePrime.Pratt.group_000 CubePrime.Pratt.group_001

theorem all_cubes {psi theta : ℝ → ℝ} {pi : ℝ}
    (hp : 3 ≤ pi)
    (hs : ∀ x : ℝ, (366 / 5 : ℝ) ≤ x →
      |psi x - x| < Real.sqrt x * (Real.log x)^2 / (8*pi))
    (ht : ∀ x : ℝ, theta x ≤ psi x)
    (htail : ∀ x : ℝ, 1 ≤ x → psi x - theta x ≤ 2 * Real.sqrt x * Real.log x)
    (hsum : ∀ n : ℕ, theta n = ∑ p ∈ primesUpTo n, Real.log p)
    (n : ℕ) (hn : 1 ≤ n) :
    ∃ p : ℕ, p.Prime ∧ n^3 < p ∧ p < (n+1)^3 := by
  by_cases hsmall : n < 511
  · exact finite_prefix n hn (by omega)
  · exact large_cube hp hs ht htail hsum n (by omega)

example : CubePrime.Pratt.CubeAt 510 := finite_prefix 510 (by decide) (by decide)
example : CubePrime.Pratt.CubeAt 511 := finite_prefix 511 (by decide) (by decide)
example : CubePrime.Pratt.CubeAt 512 := finite_prefix 512 (by decide) (by decide)

#print axioms finite_prefix
#print axioms all_cubes
end CubeSchoenfeldTight
