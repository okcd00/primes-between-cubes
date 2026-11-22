import Mathlib.Analysis.Complex.ExponentialBounds
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic

/-! A checked reduction to Dudek's explicit short-interval estimate. -/
namespace CubePrime

def PrimeBetweenCubes (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

def ShortIntervalBound : Prop :=
  ∀ x : ℝ, 2 ≤ x → ∃ p : ℕ, p.Prime ∧
    x - (4 / Real.pi) * Real.sqrt x * Real.log x < (p : ℝ) ∧ (p : ℝ) ≤ x

private theorem length_lt (m : ℝ) (hm : 64 ≤ m) :
    (4 / Real.pi) * Real.sqrt (m ^ 3) * Real.log (m ^ 3) <
      m ^ 3 - (m - 1) ^ 3 := by
  have hm0 : 0 < m := by linarith
  let s := Real.sqrt m
  have hs : 8 ≤ s := by
    change 8 ≤ Real.sqrt m
    rw [← Real.sqrt_sq (by norm_num : (0 : ℝ) ≤ 8)]
    exact Real.sqrt_le_sqrt (by norm_num; exact hm)
  have hs0 : 0 < s := by linarith
  have hsq : s ^ 2 = m := Real.sq_sqrt hm0.le
  have hlog : Real.log m ≤ (3 / 5) * s := by
    have h := Real.log_le_sub_one_of_pos (show 0 < s / 8 by positivity)
    have h8 : Real.log 8 ≤ 21 / 10 := by
      rw [show (8 : ℝ) = 2 ^ (3 : ℕ) by norm_num, Real.log_pow]
      linarith [Real.log_two_lt_d9]
    rw [Real.log_div hs0.ne' (by norm_num : (8 : ℝ) ≠ 0)] at h
    have he : Real.log s = Real.log m / 2 := Real.log_sqrt hm0.le
    linarith
  have hs3 : Real.sqrt (m ^ 3) = m * s := by
    rw [show m ^ 3 = m ^ 2 * m by ring, Real.sqrt_mul (sq_nonneg m),
      Real.sqrt_sq hm0.le]
  have hpi : (4 : ℝ) / Real.pi < 4 / 3 :=
    div_lt_div_of_pos_left (by norm_num) (by norm_num) Real.pi_gt_three
  have hlog0 := Real.log_nonneg (show 1 ≤ m by linarith)
  have hbound : (4 / Real.pi) * (m * s) * (3 * Real.log m) ≤
      (4 / 3) * (m * s) * (3 * ((3 / 5) * s)) := by
    gcongr
  have hpoly : (12 / 5) * m ^ 2 < m ^ 3 - (m - 1) ^ 3 := by
    nlinarith [mul_pos hm0 (show 0 < (3 / 5) * m - 3 by linarith)]
  rw [hs3, Real.log_pow]
  push_cast
  calc
    _ ≤ (4 / 3) * (m * s) * (3 * ((3 / 5) * s)) := hbound
    _ = (12 / 5) * m ^ 2 := by
      calc
        _ = (12 / 5) * m * s ^ 2 := by ring
        _ = _ := by rw [hsq]; ring
    _ < _ := hpoly

private theorem small (n : ℕ) (hn : 1 ≤ n) (h : n < 63) :
    PrimeBetweenCubes n := by
  interval_cases n
  · exact ⟨2, by norm_num, by decide, by decide⟩
  · exact ⟨11, by norm_num, by decide, by decide⟩
  · exact ⟨29, by norm_num, by decide, by decide⟩
  · exact ⟨67, by norm_num, by decide, by decide⟩
  · exact ⟨127, by norm_num, by decide, by decide⟩
  · exact ⟨223, by norm_num, by decide, by decide⟩
  · exact ⟨347, by norm_num, by decide, by decide⟩
  · exact ⟨521, by norm_num, by decide, by decide⟩
  · exact ⟨733, by norm_num, by decide, by decide⟩
  · exact ⟨1009, by norm_num, by decide, by decide⟩
  · exact ⟨1361, by norm_num, by decide, by decide⟩
  · exact ⟨1733, by norm_num, by decide, by decide⟩
  · exact ⟨2203, by norm_num, by decide, by decide⟩
  · exact ⟨2749, by norm_num, by decide, by decide⟩
  · exact ⟨3389, by norm_num, by decide, by decide⟩
  · exact ⟨4099, by norm_num, by decide, by decide⟩
  · exact ⟨4919, by norm_num, by decide, by decide⟩
  · exact ⟨5839, by norm_num, by decide, by decide⟩
  · exact ⟨6863, by norm_num, by decide, by decide⟩
  · exact ⟨8009, by norm_num, by decide, by decide⟩
  · exact ⟨9277, by norm_num, by decide, by decide⟩
  · exact ⟨10651, by norm_num, by decide, by decide⟩
  · exact ⟨12197, by norm_num, by decide, by decide⟩
  · exact ⟨13829, by norm_num, by decide, by decide⟩
  · exact ⟨15629, by norm_num, by decide, by decide⟩
  · exact ⟨17579, by norm_num, by decide, by decide⟩
  · exact ⟨19687, by norm_num, by decide, by decide⟩
  · exact ⟨21961, by norm_num, by decide, by decide⟩
  · exact ⟨24391, by norm_num, by decide, by decide⟩
  · exact ⟨27011, by norm_num, by decide, by decide⟩
  · exact ⟨29803, by norm_num, by decide, by decide⟩
  · exact ⟨32771, by norm_num, by decide, by decide⟩
  · exact ⟨35951, by norm_num, by decide, by decide⟩
  · exact ⟨39313, by norm_num, by decide, by decide⟩
  · exact ⟨42899, by norm_num, by decide, by decide⟩
  · exact ⟨46663, by norm_num, by decide, by decide⟩
  · exact ⟨50671, by norm_num, by decide, by decide⟩
  · exact ⟨54877, by norm_num, by decide, by decide⟩
  · exact ⟨59333, by norm_num, by decide, by decide⟩
  · exact ⟨64007, by norm_num, by decide, by decide⟩
  · exact ⟨68927, by norm_num, by decide, by decide⟩
  · exact ⟨74093, by norm_num, by decide, by decide⟩
  · exact ⟨79531, by norm_num, by decide, by decide⟩
  · exact ⟨85193, by norm_num, by decide, by decide⟩
  · exact ⟨91127, by norm_num, by decide, by decide⟩
  · exact ⟨97367, by norm_num, by decide, by decide⟩
  · exact ⟨103837, by norm_num, by decide, by decide⟩
  · exact ⟨110597, by norm_num, by decide, by decide⟩
  · exact ⟨117659, by norm_num, by decide, by decide⟩
  · exact ⟨125003, by norm_num, by decide, by decide⟩
  · exact ⟨132661, by norm_num, by decide, by decide⟩
  · exact ⟨140611, by norm_num, by decide, by decide⟩
  · exact ⟨148891, by norm_num, by decide, by decide⟩
  · exact ⟨157477, by norm_num, by decide, by decide⟩
  · exact ⟨166393, by norm_num, by decide, by decide⟩
  · exact ⟨175621, by norm_num, by decide, by decide⟩
  · exact ⟨185221, by norm_num, by decide, by decide⟩
  · exact ⟨195121, by norm_num, by decide, by decide⟩
  · exact ⟨205391, by norm_num, by decide, by decide⟩
  · exact ⟨216023, by norm_num, by decide, by decide⟩
  · exact ⟨226991, by norm_num, by decide, by decide⟩
  · exact ⟨238331, by norm_num, by decide, by decide⟩

theorem from_short_interval (h : ShortIntervalBound) (n : ℕ) (hn : 1 ≤ n) :
    PrimeBetweenCubes n := by
  by_cases hsmall : n < 63
  · exact small n hn hsmall
  have hm : (64 : ℝ) ≤ ((n + 1 : ℕ) : ℝ) := by exact_mod_cast (show 64 ≤ n + 1 by omega)
  let m : ℝ := ((n + 1 : ℕ) : ℝ)
  have hml : 64 ≤ m := hm
  have hx : 2 ≤ m ^ 3 := by
    have h0 : 0 ≤ m := by linarith
    nlinarith [pow_nonneg h0 2, mul_nonneg (show 0 ≤ m - 64 by linarith) (sq_nonneg m)]
  obtain ⟨p, hp, hlo, hhi⟩ := h (m ^ 3) hx
  have hlen := length_lt m hml
  have hreal : ((n : ℝ) ^ 3) < (p : ℝ) := by
    have he : m - 1 = (n : ℝ) := by simp [m]
    rw [he] at hlen
    linarith
  have hreal' : (p : ℝ) ≤ ((n + 1 : ℕ) : ℝ) ^ 3 := hhi
  refine ⟨p, hp, by exact_mod_cast hreal, ?_⟩
  have hp_le : p ≤ (n + 1) ^ 3 := by exact_mod_cast hreal'
  refine lt_of_le_of_ne hp_le ?_
  intro he
  exact Nat.Prime.not_prime_pow (by decide : 2 ≤ 3) (he ▸ hp)

#print axioms from_short_interval
end CubePrime
