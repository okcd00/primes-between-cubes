import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

namespace CubeSchoenfeldTight
open Real

private theorem log512 : log (512 : ℝ) ≤ 63 / 10 := by
  have h := sum_le_exp_of_nonneg (x := (7 : ℝ) / 10) (by norm_num) 4
  norm_num [Finset.sum_range_succ, Nat.factorial_succ] at h
  have he : (2 : ℝ) ≤ exp (7 / 10) := by linarith
  have hl := log_le_log (by norm_num : (0 : ℝ) < 2) he
  rw [log_exp] at hl
  rw [show (512 : ℝ) = 2 ^ (9 : ℕ) by norm_num, log_pow]
  norm_num
  linarith

private theorem log_scaled {m : ℝ} (hm : 512 ≤ m) :
    log m ≤ (63 / 10) * (sqrt (sqrt m) / sqrt (sqrt 512)) := by
  let a := sqrt (sqrt (512 : ℝ))
  let b := sqrt (sqrt m)
  have ha : 0 < a := by positivity
  have hab : a ≤ b := sqrt_le_sqrt (sqrt_le_sqrt hm)
  have hb : 0 < b := ha.trans_le hab
  have ha4 : a^4 = 512 := by
    rw [show a^4 = (a^2)^2 by ring]
    dsimp [a]
    rw [sq_sqrt (sqrt_nonneg _), sq_sqrt (by norm_num : (0 : ℝ) ≤ 512)]
  have hb4 : b^4 = m := by
    rw [show b^4 = (b^2)^2 by ring]
    dsimp [b]
    rw [sq_sqrt (sqrt_nonneg _), sq_sqrt (by linarith : 0 ≤ m)]
  have h1 : 1 ≤ b / a := (le_div_iff₀ ha).2 (by simpa using hab)
  have hl := log_le_sub_one_of_pos (div_pos hb ha)
  rw [log_div hb.ne' ha.ne'] at hl
  have hla : log (512 : ℝ) = 4 * log a := by
    rw [← ha4, log_pow]
    norm_num
  have hlb : log m = 4 * log b := by
    rw [← hb4, log_pow]
    norm_num
  change log m ≤ (63 / 10) * (b/a)
  rw [hlb]
  linarith [log512]

theorem budget {m : ℝ} (hm : 512 ≤ m) :
    (3 / 4) * sqrt (m ^ 3) * (log m) ^ 2 +
      6 * sqrt (m ^ 3) * log m < (299 / 100) * m ^ 2 := by
  have mp : 0 < m := by linarith
  let a := sqrt (sqrt (512 : ℝ))
  let b := sqrt (sqrt m)
  let t := b / a
  have ha : 0 < a := by positivity
  have hab : a ≤ b := sqrt_le_sqrt (sqrt_le_sqrt hm)
  have ht1 : 1 ≤ t := (le_div_iff₀ ha).2 (by simpa using hab)
  have ht0 : 0 ≤ t := by linarith
  have hs512 : (181 / 8 : ℝ) ≤ sqrt (512 : ℝ) := by
    nlinarith [sq_sqrt (by norm_num : (0 : ℝ) ≤ 512), sqrt_nonneg (512 : ℝ)]
  have ht2 : t^2 * sqrt (512 : ℝ) = sqrt m := by
    dsimp [t, a, b]
    rw [div_pow, sq_sqrt (sqrt_nonneg m), sq_sqrt (sqrt_nonneg (512 : ℝ))]
    exact div_mul_cancel₀ _ (by positivity)
  have hl0 : 0 ≤ log m := log_nonneg (by linarith)
  have hl : log m ≤ (63 / 10) * t := log_scaled hm
  have hl2 : (log m)^2 ≤ ((63 / 10) * t)^2 := pow_le_pow_left₀ hl0 hl 2
  have ht_le_t2 : t ≤ t^2 := by nlinarith [mul_nonneg ht0 (show 0 ≤ t - 1 by linarith)]
  have h1 : (3/4 : ℝ) * (log m)^2 + 6 * log m ≤ (27027/400) * t^2 := by
    nlinarith
  have h2 : (181/8 : ℝ) * t^2 ≤ sqrt m := by
    rw [← ht2]
    nlinarith [mul_le_mul_of_nonneg_right hs512 (sq_nonneg t)]
  have h3 : (3/4 : ℝ) * (log m)^2 + 6 * log m < (299/100) * sqrt m := by
    nlinarith [sqrt_pos.2 mp]
  have sqrt_cube : sqrt (m ^ 3) = m * sqrt m := by
    rw [show m ^ 3 = m ^ 2 * m by ring, sqrt_mul (sq_nonneg m), sqrt_sq mp.le]
  rw [sqrt_cube]
  calc
    _ = (m * sqrt m) * ((3/4) * (log m)^2 + 6 * log m) := by ring
    _ < (m * sqrt m) * ((299/100) * sqrt m) := mul_lt_mul_of_pos_left h3 (by positivity)
    _ = _ := by rw [show (m * sqrt m) * ((299/100) * sqrt m) =
                      (299/100) * m * (sqrt m)^2 by ring, sq_sqrt mp.le]; ring

#print axioms budget
end CubeSchoenfeldTight
