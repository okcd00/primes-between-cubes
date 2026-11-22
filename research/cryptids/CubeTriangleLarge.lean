import TriangleContour
import TriangleIdentity
import TriangleMass
import TriangleNumerics
import TriangleResidues

namespace CubePrime
open Real Finset
open ConjectureMachines.Semantics.Riemann.WeightedStieltjes

theorem cube_triangle_estimates {m x h : ℝ} (hm : 65536 ≤ m)
    (ha : x - h = (m - 1) ^ 3) (hb : x + h = m ^ 3) :
    (7 / 5) * m ^ 2 ≤ h ∧
    (h ^ 2 / sqrt (x - h)) * ((16 / 5) * (2*m) * log (2*m) + (11 / 5) * (2*m)) +
      (4 * (x + h) ^ (3 / 2 : ℝ)) * (((32 / 5) * log (2*m) + 54 / 5) / (2*m)) +
      h * (2 * sqrt (x + h) * log (x + h)) ≤ (15 / 16 : ℝ) * h ^ 2 := by
  have hm0 : 0 < m := by linarith
  have hm1 : 1 ≤ m := by linarith
  have hm16 : 16 ≤ m := by linarith
  have hh : (7 / 5) * m ^ 2 ≤ h := by
    nlinarith only [ha, hb, mul_le_mul_of_nonneg_right hm16 hm0.le, hm16]
  refine ⟨hh, ?_⟩
  have hh0 : 0 < h := lt_of_lt_of_le (by positivity) hh
  let s := sqrt m
  have hs0 : 0 < s := sqrt_pos.mpr hm0
  have hs2 : s ^ 2 = m := sq_sqrt hm0.le
  have hsqb : sqrt (x + h) = m * s := by
    rw [hb, show m ^ 3 = m ^ 2 * m by ring, sqrt_mul (sq_nonneg m), sqrt_sq hm0.le]
  have hsqlo : (9 / 10) * m * s ≤ sqrt (x - h) := by
    have hstep : ((15 / 16) * m) ^ 3 ≤ (m - 1) ^ 3 :=
      pow_le_pow_left₀ (by positivity) (by linarith) 3
    have hpoly : ((9 / 10) * m * s) ^ 2 ≤ x - h := by
      rw [ha]
      have he : ((9 / 10) * m * s) ^ 2 = (81 / 100) * m ^ 3 := by
        rw [mul_pow, mul_pow, hs2]; ring
      rw [he]
      nlinarith only [hstep, pow_nonneg hm0.le 3]
    have ha0 : 0 ≤ x - h := by rw [ha]; positivity
    rw [← sqrt_sq (show 0 ≤ (9 / 10) * m * s by positivity)]
    exact sqrt_le_sqrt hpoly
  have hsa0 : 0 < sqrt (x - h) := lt_of_lt_of_le (by positivity) hsqlo
  have hp : (x + h) ^ (3 / 2 : ℝ) = m ^ 4 * s := by
    have hb0 : 0 < x + h := by rw [hb]; positivity
    rw [show (3 / 2 : ℝ) = 1 + 1 / 2 by norm_num, Real.rpow_add hb0,
      Real.rpow_one, ← sqrt_eq_rpow, hsqb, hb]; ring
  have hh2 : (49 / 25 : ℝ) * m ^ 4 ≤ h ^ 2 := by
    have hp := pow_le_pow_left₀ (by positivity : (0 : ℝ) ≤ (7 / 5) * m ^ 2) hh 2
    nlinarith only [hp]
  have hlog : 0 ≤ log (2 * m) := log_nonneg (by linarith)
  have hlogm : 0 ≤ log m := log_nonneg hm1
  have hlogb : log (x + h) = 3 * log m := by rw [hb, log_pow]; norm_num
  have hheadFactor : (h ^ 2 / sqrt (x - h)) * (2*m) ≤ (20 / 9) * (h ^ 2 / s) := by
    have hfrac : (s * (2 * m)) / sqrt (x - h) ≤ 20 / 9 := by
      rw [div_le_iff₀ hsa0]
      linarith only [hsqlo, show s * (2*m) = 2 * (m*s) by ring,
        show (9 / 10 : ℝ) * m * s = (9 / 10) * (m*s) by ring]
    calc
      _ = (h^2 / s) * ((s * (2*m)) / sqrt (x - h)) := by field_simp [hs0.ne', hsa0.ne']
      _ ≤ _ := by rw [mul_comm (20 / 9 : ℝ)]; gcongr
  have htailFactor : (4 * (x + h) ^ (3 / 2 : ℝ)) / (2*m) ≤ (50 / 49) * (h ^ 2 / s) := by
    rw [hp]
    calc
      _ = (2 * m ^ 3 * s) := by field_simp [hm0.ne']; norm_num
      _ = (2 * m ^ 4) / s := by
        apply (eq_div_iff hs0.ne').mpr
        calc
          2 * m ^ 3 * s * s = 2 * m ^ 3 * s ^ 2 := by ring
          _ = _ := by rw [hs2]; ring
      _ ≤ ((50 / 49) * h ^ 2) / s := by
        apply div_le_div_of_nonneg_right _ hs0.le
        linarith only [hh2]
      _ = _ := by ring
  have hprimeFactor : h * (2 * sqrt (x + h) * log (x + h)) ≤
      (h ^ 2 / s) * ((30 / 7) * log m) := by
    have h7 : 6 * m ^ 2 ≤ (30 / 7) * h := by linarith only [hh]
    have hh' : 6 * h * m ^ 2 ≤ (30 / 7) * h ^ 2 := by
      nlinarith only [mul_le_mul_of_nonneg_right h7 hh0.le]
    have he : 6 * h * m * s = (6 * h * m ^ 2) / s := by
      apply (eq_div_iff hs0.ne').mpr
      calc
        6 * h * m * s * s = 6 * h * m * s ^ 2 := by ring
        _ = _ := by rw [hs2]; ring
    rw [hsqb, hlogb]
    calc
      _ = (6 * h * m * s) * log m := by ring
      _ ≤ (((30 / 7) * h ^ 2) / s) * log m := by
        rw [he]
        exact mul_le_mul_of_nonneg_right (div_le_div_of_nonneg_right hh' hs0.le) hlogm
      _ = _ := by ring
  have hhead := mul_le_mul_of_nonneg_right hheadFactor
    (by positivity : 0 ≤ (16 / 5) * log (2*m) + 11 / 5)
  have htail := mul_le_mul_of_nonneg_right htailFactor
    (by positivity : 0 ≤ (32 / 5) * log (2*m) + 54 / 5)
  have hlinear : ((64 / 9 : ℝ) + 320 / 49) * log (2*m) + (44 / 9 + 540 / 49) ≤
      14 * log (2*m) + 16 := by linarith only [hlog]
  have hzero := mul_le_mul_of_nonneg_left hlinear (show 0 ≤ h ^ 2 / s by positivity)
  have hbudget := (div_le_iff₀ hs0).mp (cube_triangle_budget_mathlib hm)
  have hfinal := mul_le_mul_of_nonneg_left hbudget (show 0 ≤ h ^ 2 / s by positivity)
  have hf : (h ^ 2 / s) * (15 / 16 * s) = 15 / 16 * h ^ 2 := by field_simp [hs0.ne']
  rw [hf] at hfinal
  rw [show (16 / 5 : ℝ) * (2*m) * log (2*m) + (11 / 5) * (2*m) =
      (2*m) * ((16 / 5) * log (2*m) + 11 / 5) by ring]
  rw [show (4 * (x + h) ^ (3 / 2 : ℝ)) * (((32 / 5) * log (2*m) + 54 / 5) / (2*m)) =
      ((4 * (x + h) ^ (3 / 2 : ℝ)) / (2*m)) * ((32 / 5) * log (2*m) + 54 / 5) by ring]
  nlinarith only [hhead, htail, hprimeFactor, hzero, hfinal]

/-- Large-range strict interval theorem, still conditional on ordinary RH. -/
theorem prime_between_large_cubes_of_RH (hRH : RiemannHypothesis)
    {m : ℝ} (hm : 65536 ≤ m) :
    ∃ p : ℕ, p.Prime ∧ (m - 1)^3 < (p : ℝ) ∧ (p : ℝ) < m^3 := by
  let a := (m - 1) ^ 3
  let b := m ^ 3
  let x := (a + b) / 2
  let h := (b - a) / 2
  have ha : x - h = a := by dsimp [x, h]; ring
  have hb : x + h = b := by dsimp [x, h]; ring
  have hm0 : 0 < m := by linarith
  have h1 : 1 ≤ a := one_le_pow₀ (by linarith : (1 : ℝ) ≤ m - 1)
  have hx1 : 1 ≤ x - h := by rwa [ha]
  obtain ⟨hgap, hbudget⟩ := cube_triangle_estimates hm ha hb
  have hh : 0 < h := lt_of_lt_of_le (by positivity) hgap
  have hT : 6 ≤ 2 * m := by linarith
  obtain ⟨U, hTU, hgood, hR⟩ := exists_triangle_remainder_bound hRH hh hx1 hT
  have hZ := triangle_residue_bound hRH hh (by linarith only [hx1] : h < x) hT hTU
  have hV := cube_vertical_budget hm hgap
  have hV' : (128 * 87 : ℝ) / (2 * π) * (x + h) ^ (3 / 4 : ℝ) ≤ h ^ 2 / 60 := by
    rw [hb]
    exact hV
  have hR' : |diff2 (fun y => psi1ContourRemainder y U) x h| ≤ h ^ 2 / 30 := by
    unfold diff2
    linarith only [hR, hV']
  have hI := triangle_explicit_identity x h U
  have hmass : h * (2 * sqrt (x + h) * log (x + h)) <
      psi1 (x + h) - 2 * psi1 x + psi1 (x - h) := by
    change psi1 (x + h) - 2 * psi1 x + psi1 (x - h) =
      h ^ 2 + (∑ ρ ∈ nontrivialZetaZerosUpTo U, diff2 (fun y => resZeroRho y ρ) x h).re +
      diff2 (fun y => psi1ContourRemainder y U) x h at hI
    have h₁ := (abs_le.mp hZ).1
    have h₂ := (abs_le.mp hR').1
    nlinarith only [hbudget, hI, h₁, h₂, sq_pos_of_pos hh]
  simpa [ha, hb, a, b] using prime_of_large_triangle hh.le hx1 hmass

/-- Natural-number endpoint version; the finite branch must cover n ≤ 65534. -/
theorem prime_between_large_nat_cubes_of_RH (hRH : RiemannHypothesis)
    {n : ℕ} (hn : 65535 ≤ n) : ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 := by
  have hm : (65536 : ℝ) ≤ (n : ℝ) + 1 := by exact_mod_cast Nat.succ_le_succ hn
  obtain ⟨p, hp, ha, hb⟩ := prime_between_large_cubes_of_RH hRH hm
  rw [add_sub_cancel_right] at ha
  exact ⟨p, hp, by exact_mod_cast ha, by exact_mod_cast hb⟩

#print axioms prime_between_large_nat_cubes_of_RH
#print axioms cube_triangle_estimates
#print axioms prime_between_large_cubes_of_RH

end CubePrime
