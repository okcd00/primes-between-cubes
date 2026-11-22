/-
Copyright 2026 Steve Hubbard (upstream GoldbachLean).
Adapted from Steve Hubbard's goldbach-lean, commit
93b86c05bb441be2ac0b3f06cc4c8624f8e8d0eb,
entries/dudek2014/LeanLab/Dudek2014/SigmaTrudgian.lean.
Released under the Apache License, Version 2.0.
The original section was isolated and connected to Cryptids' zero predicates here.
-/
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Tactic
import Cryptids.Semantics.Riemann.WeightedStieltjes

namespace CubePrime.Pointwise
open Set Real Complex
noncomputable section

/-- `ρ = 1/2 + iγ`. -/
noncomputable def rhoF (g : ℝ) : ℂ := 1 / 2 + g * Complex.I

/-- `t^{ρ+1}/(ρ(ρ+1))`. -/
noncomputable def fz (ρ : ℂ) (t : ℝ) : ℂ := (t : ℂ) ^ (ρ + 1) / (ρ * (ρ + 1))

/-- `t^ρ/ρ`. -/
noncomputable def f1 (ρ : ℂ) (t : ℝ) : ℂ := (t : ℂ) ^ ρ / ρ

lemma rhoF_re (g : ℝ) : (rhoF g).re = 1 / 2 := by simp [rhoF]

lemma rhoF_ne (g : ℝ) : rhoF g ≠ 0 := fun h => by
  have := congrArg Complex.re h; rw [rhoF_re] at this; simp at this

lemma rhoF_ne' (g : ℝ) : rhoF g ≠ -1 := fun h => by
  have := congrArg Complex.re h; rw [rhoF_re] at this; simp at this; norm_num at this

lemma hasDerivAt_fz (g : ℝ) {t : ℝ} (ht : 0 < t) : HasDerivAt (fz (rhoF g)) (f1 (rhoF g) t) t := by
  have h0 := rhoF_ne g
  have h1 : rhoF g + 1 ≠ 0 := fun h => rhoF_ne' g (by linear_combination h)
  have := (hasDerivAt_ofReal_cpow_const' ht.ne' (rhoF_ne' g)).div_const (rhoF g)
  convert this using 1
  · funext y; unfold fz; field_simp
  · unfold f1; rfl

lemma hasDerivAt_f1 (g : ℝ) {t : ℝ} (ht : 0 < t) :
    HasDerivAt (f1 (rhoF g)) ((t : ℂ) ^ (rhoF g - 1)) t := by
  have h0 := rhoF_ne g
  have := hasDerivAt_ofReal_cpow_const' ht.ne' (r := rhoF g - 1) (by
    intro h; exact h0 (by linear_combination h))
  simp only [sub_add_cancel] at this
  exact this

lemma norm_cpow_rhoF {g t : ℝ} (ht : 0 < t) (w : ℂ) :
    ‖(t : ℂ) ^ (rhoF g + w)‖ = t ^ (1 / 2 + w.re) := by
  rw [Complex.norm_cpow_eq_rpow_re_of_pos ht]; simp [rhoF_re]

/-- `|Δ²| ≤ h² (x - h)^{-1/2}`. -/
lemma second_diff_small (g : ℝ) {x h : ℝ} (hh : 0 < h) (hhx : h < x) :
    ‖fz (rhoF g) (x + h) - 2 * fz (rhoF g) x + fz (rhoF g) (x - h)‖
      ≤ h ^ 2 * (x - h) ^ (-1 / 2 : ℝ) := by
  set K := (x - h) ^ (-1 / 2 : ℝ)
  have hxh : 0 < x - h := by linarith
  -- the first derivative moves by at most `K h`
  have step1 : ∀ u ∈ Icc (0 : ℝ) h,
      ‖f1 (rhoF g) (x + u) - f1 (rhoF g) (x - h + u)‖ ≤ K * h := by
    intro u hu
    have hm := norm_image_sub_le_of_norm_deriv_le_segment' (f := f1 (rhoF g))
      (a := x - h + u) (b := x + u) (C := K)
      (fun v hv => (hasDerivAt_f1 g (by linarith [hv.1, hu.1])).hasDerivWithinAt)
      (fun v hv => by
        have hv0 : 0 < v := by linarith [hv.1, hu.1]
        have e : (v : ℂ) ^ (rhoF g - 1) = (v : ℂ) ^ (rhoF g + (-1 : ℂ)) := by ring_nf
        rw [e, norm_cpow_rhoF hv0]
        have e2 : (1 / 2 : ℝ) + (-1 : ℂ).re = -1 / 2 := by norm_num
        rw [e2]
        exact Real.rpow_le_rpow_of_nonpos hxh (by linarith [hv.1, hu.1]) (by norm_num))
      (x + u) ⟨by linarith, le_rfl⟩
    calc _ ≤ K * (x + u - (x - h + u)) := hm
      _ = K * h := by ring
  have hK : 0 ≤ K := Real.rpow_nonneg hxh.le _
  set G : ℝ → ℂ := fun u => fz (rhoF g) (x + u) - fz (rhoF g) (x - h + u)
  have hG : ∀ u ∈ Icc (0 : ℝ) h, HasDerivWithinAt G
      (f1 (rhoF g) (x + u) - f1 (rhoF g) (x - h + u)) (Icc 0 h) u := by
    intro u hu
    have a1 := (hasDerivAt_fz g (by linarith [hu.1] : 0 < x + u)).comp_const_add x u
    have a2 := (hasDerivAt_fz g (by linarith [hu.1] : 0 < x - h + u)).comp_const_add (x - h) u
    exact (a1.sub a2).hasDerivWithinAt
  have hm := norm_image_sub_le_of_norm_deriv_le_segment' hG
    (fun u hu => step1 u (Ico_subset_Icc_self hu)) h ⟨hh.le, le_rfl⟩
  have e : G h - G 0 = fz (rhoF g) (x + h) - 2 * fz (rhoF g) x + fz (rhoF g) (x - h) := by
    simp only [G, add_zero, sub_add_cancel]; ring
  rw [← e]
  calc ‖G h - G 0‖ ≤ K * h * (h - 0) := hm
    _ = h ^ 2 * K := by ring

lemma norm_rho_mul_ge (g : ℝ) : g ^ 2 ≤ ‖rhoF g * (rhoF g + 1)‖ := by
  rw [norm_mul]
  have h1 : |g| ≤ ‖rhoF g‖ := by
    have := Complex.abs_im_le_norm (rhoF g); simpa [rhoF] using this
  have h2 : |g| ≤ ‖rhoF g + 1‖ := by
    have := Complex.abs_im_le_norm (rhoF g + 1); simpa [rhoF] using this
  calc g ^ 2 = |g| * |g| := by rw [← sq, sq_abs]
    _ ≤ ‖rhoF g‖ * ‖rhoF g + 1‖ := mul_le_mul h1 h2 (abs_nonneg _) (by positivity)

lemma norm_rho_mul_ge' (g : ℝ) : 3 / 4 ≤ ‖rhoF g * (rhoF g + 1)‖ := by
  rw [norm_mul]
  have h1 : 1 / 2 ≤ ‖rhoF g‖ := by
    have := Complex.abs_re_le_norm (rhoF g); rw [rhoF_re] at this; simpa using this
  have h2 : 3 / 2 ≤ ‖rhoF g + 1‖ := by
    have := Complex.abs_re_le_norm (rhoF g + 1); simp [rhoF_re] at this; norm_num at this
    simpa using this
  nlinarith

lemma norm_fz_le (g : ℝ) {t B : ℝ} (ht : 0 < t) (htB : t ≤ B) :
    ‖fz (rhoF g) t‖ * ‖rhoF g * (rhoF g + 1)‖ ≤ B ^ (3 / 2 : ℝ) := by
  have hn : 0 < ‖rhoF g * (rhoF g + 1)‖ := lt_of_lt_of_le (by norm_num) (norm_rho_mul_ge' g)
  unfold fz
  rw [norm_div, div_mul_cancel₀ _ hn.ne', show rhoF g + 1 = rhoF g + (1 : ℂ) from rfl,
    norm_cpow_rhoF ht]
  norm_num
  exact Real.rpow_le_rpow ht.le htB (by norm_num)

/-- `|Δ²| ≤ 4 (x + h)^{3/2}/|ρ(ρ+1)|`. -/
lemma second_diff_large (g : ℝ) {x h : ℝ} (hh : 0 < h) (hhx : h < x) :
    ‖fz (rhoF g) (x + h) - 2 * fz (rhoF g) x + fz (rhoF g) (x - h)‖
      ≤ 4 * (x + h) ^ (3 / 2 : ℝ) / ‖rhoF g * (rhoF g + 1)‖ := by
  have hn : 0 < ‖rhoF g * (rhoF g + 1)‖ := lt_of_lt_of_le (by norm_num) (norm_rho_mul_ge' g)
  have a := norm_fz_le g (by linarith : 0 < x + h) le_rfl
  have b := norm_fz_le g (by linarith : 0 < x) (by linarith : x ≤ x + h)
  have c := norm_fz_le g (by linarith : 0 < x - h) (by linarith : x - h ≤ x + h)
  rw [le_div_iff₀ hn]
  calc ‖fz (rhoF g) (x + h) - 2 * fz (rhoF g) x + fz (rhoF g) (x - h)‖ * ‖rhoF g * (rhoF g + 1)‖
      ≤ (‖fz (rhoF g) (x + h)‖ + 2 * ‖fz (rhoF g) x‖ + ‖fz (rhoF g) (x - h)‖)
          * ‖rhoF g * (rhoF g + 1)‖ := by
        gcongr
        refine (norm_add_le _ _).trans ?_
        gcongr
        refine (norm_sub_le _ _).trans ?_
        rw [norm_mul]; norm_num
    _ ≤ 4 * (x + h) ^ (3 / 2 : ℝ) := by nlinarith


/-- The high-frequency bound in terms of the ordinate, independent of the
specific upstream representation of the zero. -/
lemma second_diff_large_ordinate (g : ℝ) {x h : ℝ} (hh : 0 < h) (hhx : h < x) (hg : g ≠ 0) :
    ‖fz (rhoF g) (x + h) - 2 * fz (rhoF g) x + fz (rhoF g) (x - h)‖
      ≤ 4 * (x + h) ^ (3 / 2 : ℝ) / |g| ^ 2 := by
  refine (second_diff_large g hh hhx).trans ?_
  have hx : 0 ≤ x + h := by linarith
  apply div_le_div_of_nonneg_left (by positivity) (sq_pos_of_ne_zero (abs_ne_zero.mpr hg))
  simpa [sq_abs] using norm_rho_mul_ge g

end
end CubePrime.Pointwise

#print axioms CubePrime.Pointwise.second_diff_small
#print axioms CubePrime.Pointwise.second_diff_large_ordinate
