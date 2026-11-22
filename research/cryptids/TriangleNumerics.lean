import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Tactic

/-! Arithmetic budget for the triangular explicit formula. This file does not
establish that the analytic errors actually meet the proposed component bounds. -/
namespace CubePrime
open Real

theorem cube_triangle_budget {m : ℝ} (hm : 65536 ≤ m) :
    (14 * log (2 * m) + 16 + (15 / 7) * log m) / sqrt m ≤ 5 / 6 := by
  have hm0 : 0 < m := by linarith
  set s := sqrt m with hs
  have h256 : 256 ≤ s := by
    rw [hs, ← sqrt_sq (by norm_num : 0 ≤ (256 : ℝ))]
    exact sqrt_le_sqrt (by norm_num; exact hm)
  have hs0 : 0 < s := by linarith
  have hsq : s ^ 2 = m := sq_sqrt hm0.le
  have hlog2 : log (2 : ℝ) < 7 / 10 := by linarith [log_two_lt_d9]
  have hlog256 : log (256 : ℝ) = 8 * log 2 := by
    rw [show (256 : ℝ) = (2 : ℝ) ^ (8 : ℕ) by norm_num, log_pow]
    norm_num
  have hlogs : log s = log (s / 256) + log 256 := by
    rw [log_div hs0.ne' (by norm_num)]
    ring
  have hlogm : log m = 2 * log s := by rw [← hsq, log_pow]; norm_num
  have hlog2m : log (2 * m) = log 2 + log m := log_mul (by norm_num) hm0.ne'
  have hsub := log_le_sub_one_of_pos (show 0 < s / 256 by positivity)
  have hlog_m : log m ≤ log (2 * m) := log_le_log hm0 (by linarith)
  have hup : log (2 * m) ≤ 12 + 2 * (s / 256 - 1) := by
    linarith only [hlog2m, hlogm, hlogs, hlog256, hlog2, hsub]
  rw [div_le_iff₀ hs0]
  linarith only [hlog_m, hup, h256]

/-- Allows the existing Mathlib bound `ψ(b)-θ(b) ≤ 2 √b log b`,
without adding a custom sharper prime-power estimate. -/
theorem cube_triangle_budget_mathlib {m : ℝ} (hm : 65536 ≤ m) :
    (14 * log (2 * m) + 16 + (30 / 7) * log m) / sqrt m ≤ 15 / 16 := by
  have hm0 : 0 < m := by linarith
  set s := sqrt m with hs
  have h256 : 256 ≤ s := by
    rw [hs, ← sqrt_sq (by norm_num : 0 ≤ (256 : ℝ))]
    exact sqrt_le_sqrt (by norm_num; exact hm)
  have hs0 : 0 < s := by linarith
  have hsq : s ^ 2 = m := sq_sqrt hm0.le
  have hlog2 : log (2 : ℝ) < 7 / 10 := by linarith [log_two_lt_d9]
  have hlog256 : log (256 : ℝ) = 8 * log 2 := by
    rw [show (256 : ℝ) = (2 : ℝ) ^ (8 : ℕ) by norm_num, log_pow]
    norm_num
  have hlogs : log s = log (s / 256) + log 256 := by
    rw [log_div hs0.ne' (by norm_num)]
    ring
  have hlogm : log m = 2 * log s := by rw [← hsq, log_pow]; norm_num
  have hlog2m : log (2 * m) = log 2 + log m := log_mul (by norm_num) hm0.ne'
  have hsub := log_le_sub_one_of_pos (show 0 < s / 256 by positivity)
  have hlog_m : log m ≤ log (2 * m) := log_le_log hm0 (by linarith)
  have hup : log (2 * m) ≤ 12 + 2 * (s / 256 - 1) := by
    linarith only [hlog2m, hlogm, hlogs, hlog256, hlog2, hsub]
  rw [div_le_iff₀ hs0]
  linarith only [hlog_m, hup, h256]

/-- A coarse budget for the four vertical errors, when each has the indicated
`32*(2 A + B)/(2π)` coefficient and `A=1, B=85`. -/
theorem cube_vertical_budget {m h : ℝ} (hm : 65536 ≤ m) (hh : (7 / 5) * m ^ 2 ≤ h) :
    (128 * 87 : ℝ) / (2 * π) * (m ^ 3) ^ (3 / 4 : ℝ) ≤ h ^ 2 / 60 := by
  have hm0 : 0 ≤ m := by linarith
  have hb : 1 ≤ m ^ 3 := one_le_pow₀ (by linarith : (1 : ℝ) ≤ m)
  have hpow : (m ^ 3) ^ (3 / 4 : ℝ) ≤ m ^ 3 := by
    simpa using (rpow_le_rpow_of_exponent_le hb (by norm_num : (3 : ℝ) / 4 ≤ 1))
  have hcoef : (128 * 87 : ℝ) / (2 * π) ≤ 1856 := by
    rw [div_le_iff₀ (by positivity)]
    linarith [pi_gt_three]
  have hhsq : ((7 / 5) * m ^ 2) ^ 2 ≤ h ^ 2 :=
    pow_le_pow_left₀ (by positivity) hh 2
  have hm4 : 65536 * m ^ 3 ≤ m ^ 4 := by
    nlinarith only [mul_le_mul_of_nonneg_right hm (pow_nonneg hm0 3)]
  calc
    _ ≤ 1856 * m ^ 3 := by
      exact mul_le_mul hcoef hpow (by positivity) (by norm_num)
    _ ≤ ((7 / 5) * m ^ 2) ^ 2 / 60 := by nlinarith only [hm4, pow_nonneg hm0 3]
    _ ≤ h ^ 2 / 60 := div_le_div_of_nonneg_right hhsq (by norm_num)

#print axioms cube_triangle_budget
#print axioms cube_triangle_budget_mathlib
#print axioms cube_vertical_budget
end CubePrime
