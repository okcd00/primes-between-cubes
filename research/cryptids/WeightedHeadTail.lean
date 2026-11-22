import Cryptids.Semantics.Riemann.WeightedStieltjes

/-! A finite, uniform head–tail bound with Cryptids' exact zero definition and
analytic multiplicities. Pointwise bounds are supplied by the caller. -/
namespace CubePrime

open ConjectureMachines.Semantics.Riemann
open VonMangoldtCount
open Finset Complex Real

theorem norm_weighted_head_tail (hRH : RiemannHypothesis)
    {T U A B : ℝ} (hT : 6 ≤ T) (hTU : T ≤ U) (hA : 0 ≤ A) (hB : 0 ≤ B)
    (f : ℂ → ℂ) (hhead : ∀ ρ ∈ nontrivialZetaZerosUpTo T, ‖f ρ‖ ≤ A)
    (htail : ∀ ρ ∈ nontrivialZetaZerosBetween T U, ‖f ρ‖ ≤ B / |ρ.im| ^ 2) :
    ‖∑ ρ ∈ nontrivialZetaZerosUpTo U, (analyticOrderNatAt riemannZeta ρ : ℂ) * f ρ‖ ≤
      A * ((16 / 5) * T * Real.log T + (11 / 5) * T) +
        B * (((32 / 5) * Real.log T + 54 / 5) / T) := by
  classical
  let w (ρ : ℂ) : ℕ := analyticOrderNatAt riemannZeta ρ
  change ‖∑ ρ ∈ nontrivialZetaZerosUpTo U, (w ρ : ℂ) * f ρ‖ ≤ _
  have hN := weightedZeroCountingFunction_le_sixteen_fifths hRH hT
  have hs := WeightedStieltjes.sum_weighted_inv_sq_nontrivialZetaZerosBetween_le_of_riemannVonMangoldt
    (a := 16 / 5) (C := 11 / 5) (D := 0) (by linarith : 0 < T) hTU (by norm_num)
    (by norm_num) fun t ht => by
      simpa using (weightedZeroCountingFunction_le_sixteen_fifths hRH (hT.trans ht.1))
  have htailsum : (∑ ρ ∈ nontrivialZetaZerosBetween T U, (w ρ : ℝ) / |ρ.im| ^ 2) ≤
      ((32 / 5) * Real.log T + 54 / 5) / T := by
    dsimp [w]
    convert hs using 1 <;> ring
  rw [WeightedStieltjes.sum_nontrivialZetaZerosUpTo_eq_add_between hTU]
  refine (norm_add_le _ _).trans (add_le_add ?_ ?_)
  · calc
      _ ≤ ∑ ρ ∈ nontrivialZetaZerosUpTo T, ‖(w ρ : ℂ) * f ρ‖ := norm_sum_le _ _
      _ ≤ ∑ ρ ∈ nontrivialZetaZerosUpTo T, A * (w ρ : ℝ) := by
        apply sum_le_sum
        intro ρ hρ
        rw [norm_mul, Complex.norm_natCast, mul_comm A]
        exact mul_le_mul_of_nonneg_left (hhead ρ hρ) (by positivity)
      _ = A * (weightedZeroCountingFunction T : ℝ) := by
        rw [weightedZeroCountingFunction, Nat.cast_sum, mul_sum]
      _ ≤ _ := mul_le_mul_of_nonneg_left hN hA
  · calc
      _ ≤ ∑ ρ ∈ nontrivialZetaZerosBetween T U, ‖(w ρ : ℂ) * f ρ‖ := norm_sum_le _ _
      _ ≤ ∑ ρ ∈ nontrivialZetaZerosBetween T U, B * ((w ρ : ℝ) / |ρ.im| ^ 2) := by
        apply sum_le_sum
        intro ρ hρ
        rw [norm_mul, Complex.norm_natCast, ← mul_div_assoc, mul_comm B, mul_div_assoc]
        exact mul_le_mul_of_nonneg_left (htail ρ hρ) (by positivity)
      _ = B * (∑ ρ ∈ nontrivialZetaZerosBetween T U, (w ρ : ℝ) / |ρ.im| ^ 2) := by rw [mul_sum]
      _ ≤ _ := mul_le_mul_of_nonneg_left htailsum hB

#print axioms norm_weighted_head_tail

end CubePrime
