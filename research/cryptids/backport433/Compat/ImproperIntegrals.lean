/-
Copyright (c) 2023 David Loeffler. All rights reserved.
Released under Apache 2.0, see MATHLIB-LICENSE.
Extracted two theorems from Mathlib c55e6e786f49471c72fbddbec5415808896aec1e
for the 4.33.1 compatibility build.
-/
module
public import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
@[expose] public section
open scoped Real
open MeasureTheory

theorem integrable_inv_one_add_mul_sq {b : ℝ} (hb : b ≠ 0) :
    Integrable fun x ↦ (1 + (b * x) ^ 2)⁻¹ :=
  (integrable_inv_one_add_sq.comp_mul_left' hb).congr (by simp)

@[simp]
theorem integral_univ_inv_one_add_mul_sq (b : ℝ) :
    ∫ x, (1 + (b * x) ^ 2)⁻¹ = π / |b| := by
  rw [Measure.integral_comp_mul_left (fun x ↦ (1 + x ^ 2)⁻¹) b, integral_univ_inv_one_add_sq]
  simp [div_eq_inv_mul]
