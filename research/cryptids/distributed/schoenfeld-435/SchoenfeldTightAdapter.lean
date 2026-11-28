import SchoenfeldTightAll
import Mathlib.NumberTheory.Chebyshev
import Mathlib.Analysis.Real.Pi.Bounds

namespace CubeSchoenfeldTight

theorem large_cube_of_schoenfeld
    (hs : ∀ x : ℝ, 73.2 ≤ x →
      |Chebyshev.psi x - x| < Real.sqrt x * Real.log x ^ 2 / (8 * Real.pi))
    (n : ℕ) (hn : 511 ≤ n) :
    ∃ p : ℕ, p.Prime ∧ n^3 < p ∧ p < (n+1)^3 := by
  apply large_cube (psi := Chebyshev.psi) (theta := Chebyshev.theta) (pi := Real.pi)
  · exact Real.pi_gt_three.le
  · intro x hx
    apply hs x
    convert hx using 1 <;> norm_num
  · exact Chebyshev.theta_le_psi
  · exact fun _ hx => Chebyshev.psi_sub_theta_le hx
  · intro n
    simpa only [primesUpTo, Nat.primesLE_eq_filter_range]
      using Chebyshev.theta_eq_sum_primesLE_log n
  · exact hn

theorem all_cubes_of_schoenfeld
    (hs : ∀ x : ℝ, 73.2 ≤ x →
      |Chebyshev.psi x - x| < Real.sqrt x * Real.log x ^ 2 / (8 * Real.pi))
    (n : ℕ) (hn : 1 ≤ n) :
    ∃ p : ℕ, p.Prime ∧ n^3 < p ∧ p < (n+1)^3 := by
  by_cases hsmall : n < 511
  · exact finite_prefix n hn (by omega)
  · exact large_cube_of_schoenfeld hs n (by omega)

#print axioms large_cube_of_schoenfeld
#print axioms all_cubes_of_schoenfeld
end CubeSchoenfeldTight
