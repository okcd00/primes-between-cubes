import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.Tactic

/-! Explicit arithmetic for the local Jensen bound used by Hubbard's `fz_count`.
This file does not yet assert a bound on zeta zeros. -/
namespace CubePrime
open Real

/-- A usable bound on the exact Jensen expression, subject to a lower
bound on the normalization constant. -/
lemma jensen_window_numerics {u m : ℝ} (hu : 3 ≤ u) (hm : 1 / 4 ≤ m) :
    log ((62 + 20 * u) / m) / log (29 / 22) ≤ 25 * log u := by
  have hm0 : 0 < m := by linarith
  have hu0 : 0 < u := by linarith
  have hlog : 0 ≤ log u := log_nonneg (by linarith)
  have hratio : (62 + 20 * u) / m ≤ 164 * u := by
    rw [div_le_iff₀ hm0]
    nlinarith [mul_nonneg hu0.le (sub_nonneg.mpr hm)]
  have hB : log ((62 + 20 * u) / m) ≤ 6 * log u := by
    calc
      log ((62 + 20 * u) / m) ≤ log (164 * u) := log_le_log (by positivity) hratio
      _ ≤ log (u ^ 5 * u) := by
        apply log_le_log (by positivity)
        have h := pow_le_pow_left₀ (by norm_num : 0 ≤ (3 : ℝ)) hu 5
        have h' : (164 : ℝ) ≤ u ^ 5 := by norm_num at h; linarith
        exact mul_le_mul_of_nonneg_right h' hu0.le
      _ = 6 * log u := by rw [log_mul (by positivity) hu0.ne', log_pow]; ring
  have hden : (7 : ℝ) / 29 ≤ log (29 / 22) := by
    have h := log_le_sub_one_of_pos (by norm_num : (0 : ℝ) < 22 / 29)
    have e : (22 : ℝ) / 29 = (29 / 22)⁻¹ := by norm_num
    rw [e, log_inv] at h
    linarith
  rw [div_le_iff₀ (by linarith : 0 < log (29 / 22 : ℝ))]
  nlinarith [mul_nonneg hlog (sub_nonneg.mpr hden)]
/-- An additive variant is much sharper at higher ordinates. -/
lemma jensen_window_numerics_add {u m : ℝ} (hu : 3 ≤ u) (hm : 1 / 4 ≤ m) :
    log ((62 + 20 * u) / m) / log (29 / 22) ≤ 4 * (log u + 6) := by
  have hm0 : 0 < m := by linarith
  have hu0 : 0 < u := by linarith
  have hlog : 0 ≤ log u := log_nonneg (by linarith)
  have hratio : (62 + 20 * u) / m ≤ 164 * u := by
    rw [div_le_iff₀ hm0]
    nlinarith [mul_nonneg hu0.le (sub_nonneg.mpr hm)]
  have hexp : (164 : ℝ) ≤ exp 6 := by
    calc
      (164 : ℝ) ≤ ((5 : ℝ) / 2) ^ 6 := by norm_num
      _ ≤ exp 1 ^ 6 := pow_le_pow_left₀ (by norm_num) (by linarith [exp_one_gt_d9]) 6
      _ = exp 6 := by rw [← exp_nat_mul]; norm_num
  have h164 : log (164 : ℝ) ≤ 6 := (log_le_iff_le_exp (by norm_num)).2 hexp
  have hB : log ((62 + 20 * u) / m) ≤ log u + 6 := by
    have h := log_le_log (by positivity) hratio
    rw [log_mul (by norm_num : (164 : ℝ) ≠ 0) hu0.ne'] at h
    linarith
  have hlow {v : ℝ} (hv : 0 < v) : 1 - v⁻¹ ≤ log v := by
    have h := log_le_sub_one_of_pos (inv_pos.mpr hv)
    rw [log_inv] at h
    linarith
  have ha := hlow (by norm_num : (0 : ℝ) < 29 / 25)
  have hb := hlow (by norm_num : (0 : ℝ) < 25 / 22)
  have he : log (29 / 22 : ℝ) = log (29 / 25) + log (25 / 22) := by
    rw [← log_mul (by norm_num : (29 : ℝ) / 25 ≠ 0) (by norm_num)]
    congr 1
    norm_num
  have hden : (1 : ℝ) / 4 ≤ log (29 / 22) := by
    rw [he]
    norm_num at ha hb
    linarith
  rw [div_le_iff₀ (by linarith : 0 < log (29 / 22 : ℝ))]
  nlinarith [mul_nonneg (show 0 ≤ log u + 6 by linarith) (sub_nonneg.mpr hden)]

#print axioms jensen_window_numerics_add
#print axioms jensen_window_numerics

end CubePrime
