import Cryptids.Semantics.Riemann.WeightedStieltjes

/-! The arithmetic side of the triangular explicit formula. -/
namespace CubePrime

open ConjectureMachines.Semantics.Riemann.WeightedStieltjes
open Finset Real
open scoped ArithmeticFunction.vonMangoldt

noncomputable def triWeight (x h k : ℝ) : ℝ := max 0 (h - |k - x|)

theorem triWeight_eq_truncated_linear {x h k : ℝ} (hh : 0 ≤ h) :
    max 0 (x + h - k) - 2 * max 0 (x - k) + max 0 (x - h - k) =
      triWeight x h k := by
  unfold triWeight
  rcases le_or_gt k (x - h) with hk | hk
  · simp only [max_eq_right (by linarith : 0 ≤ x + h - k),
      max_eq_right (by linarith : 0 ≤ x - k), max_eq_right (by linarith : 0 ≤ x - h - k),
      abs_of_nonpos (by linarith : k - x ≤ 0)]
    rw [max_eq_left (by linarith)]
    ring
  rcases le_or_gt k x with hkx | hkx
  · simp only [max_eq_right (by linarith : 0 ≤ x + h - k),
      max_eq_right (by linarith : 0 ≤ x - k), max_eq_left (by linarith : x - h - k ≤ 0),
      abs_of_nonpos (by linarith : k - x ≤ 0)]
    rw [max_eq_right (by linarith)]
    ring
  rcases le_or_gt k (x + h) with hkb | hkb
  · simp only [max_eq_right (by linarith : 0 ≤ x + h - k),
      max_eq_left (by linarith : x - k ≤ 0), max_eq_left (by linarith : x - h - k ≤ 0),
      abs_of_nonneg (by linarith : 0 ≤ k - x)]
    rw [max_eq_right (by linarith)]
    ring
  · simp only [max_eq_left (by linarith : x + h - k ≤ 0),
      max_eq_left (by linarith : x - k ≤ 0), max_eq_left (by linarith : x - h - k ≤ 0),
      abs_of_nonneg (by linarith : 0 ≤ k - x)]
    rw [max_eq_left (by linarith)]
    ring

private theorem mass_embedding {y b : ℝ} (hy : 1 ≤ y) (hyb : y ≤ b) :
    psi1 y = ∑ k ∈ Icc 1 ⌊b⌋₊, max 0 (y - k) * Λ k := by
  rw [psi1_eq_sum_Icc_sub_mul_vonMangoldt hy]
  calc
    _ = ∑ k ∈ Icc 1 ⌊y⌋₊, max 0 (y - k) * Λ k := by
      apply sum_congr rfl
      intro k hk
      have hk' : (k : ℝ) ≤ (⌊y⌋₊ : ℝ) := by exact_mod_cast (mem_Icc.mp hk).2
      rw [max_eq_right (sub_nonneg.mpr (hk'.trans (Nat.floor_le (by linarith))))]
    _ = _ := by
      apply sum_subset (Icc_subset_Icc_right (Nat.floor_le_floor hyb))
      intro k hk hky
      have hn : ⌊y⌋₊ < k := by
        have hk1 := (mem_Icc.mp hk).1
        by_contra! h
        exact hky (mem_Icc.mpr ⟨hk1, h⟩)
      have hn' : y < k := (Nat.floor_lt (by linarith)).mp hn
      rw [max_eq_left (sub_nonpos.mpr hn'.le), zero_mul]

theorem psi1_second_diff_eq_triangular_sum {x h : ℝ} (hh : 0 ≤ h) (ha : 1 ≤ x - h) :
    psi1 (x + h) - 2 * psi1 x + psi1 (x - h) =
      ∑ k ∈ Icc 1 ⌊x + h⌋₊, triWeight x h k * Λ k := by
  rw [mass_embedding (y := x + h) (b := x + h) (by linarith) le_rfl,
    mass_embedding (y := x) (b := x + h) (by linarith) (by linarith),
    mass_embedding (y := x - h) (b := x + h) ha (by linarith)]
  rw [mul_sum, ← sum_sub_distrib, ← sum_add_distrib]
  apply sum_congr rfl
  intro k hk
  rw [← triWeight_eq_truncated_linear hh]
  ring

/-- If the triangular mass exceeds the total possible contribution of nonprimes,
there is a prime strictly between both endpoints, not merely in a closed interval. -/
theorem prime_of_large_triangle {x h : ℝ} (hh : 0 ≤ h) (ha : 1 ≤ x - h)
    (hmass : h * (2 * sqrt (x + h) * log (x + h)) <
      psi1 (x + h) - 2 * psi1 x + psi1 (x - h)) :
    ∃ p : ℕ, p.Prime ∧ x - h < (p : ℝ) ∧ (p : ℝ) < x + h := by
  classical
  by_contra! hn
  have h1 : 1 ≤ x + h := by linarith
  let S := Icc 1 ⌊x + h⌋₊
  have hS : S = Ioc 0 ⌊x + h⌋₊ := by
    ext k
    simp only [S, mem_Icc, mem_Ioc]
    omega
  have hw (p : ℕ) (hp : p.Prime) : triWeight x h p = 0 := by
    unfold triWeight
    apply max_eq_left
    apply sub_nonpos.mpr
    by_contra! hsmall
    have hmem := abs_lt.mp hsmall
    have hlo : x - h < (p : ℝ) := by linarith
    have hhi : (p : ℝ) < x + h := by linarith
    exact (hn p hp hlo).not_gt hhi
  have hsmall : ∑ k ∈ S, triWeight x h k * Λ k ≤
      h * (Chebyshev.psi (x + h) - Chebyshev.theta (x + h)) := by
    rw [Chebyshev.psi_sub_theta_eq_sum_not_prime, ← hS, mul_sum, sum_filter]
    apply sum_le_sum
    intro k hk
    split_ifs with hprime
    · simp [hw k hprime]
    · apply mul_le_mul_of_nonneg_right _ ArithmeticFunction.vonMangoldt_nonneg
      exact max_le hh (by linarith [abs_nonneg ((k : ℝ) - x)])
  rw [psi1_second_diff_eq_triangular_sum hh ha] at hmass
  exact hmass.not_ge (hsmall.trans (mul_le_mul_of_nonneg_left (Chebyshev.psi_sub_theta_le h1) hh))

#print axioms prime_of_large_triangle
#print axioms psi1_second_diff_eq_triangular_sum

end CubePrime
