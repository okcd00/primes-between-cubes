import Cryptids.Semantics.Riemann.WeightedStieltjes
import Cryptids.Semantics.Riemann.DigammaBinet
import Cryptids.Semantics.Riemann.HorizontalBounds

/-! Use the same zero-free height for the three-point formula. -/
namespace CubePrime
open ConjectureMachines.Semantics.Riemann
open WeightedStieltjes Real

theorem triangle_remainder_le_of_common_height {x h U a : ℝ}
    (hh : 0 < h) (hlo : 1 ≤ x - h) (hU : 0 < U) (ha : -1 / 2 < a) (ha' : a < 0)
    (hgood : ∀ ρ ∈ nontrivialZetaZerosUpTo U, |ρ.im| < U) :
    |psi1ContourRemainder (x + h) U - 2 * psi1ContourRemainder x U +
      psi1ContourRemainder (x - h) U| ≤ 2 * h * contourDiffError x h a U := by
  let d (y : ℝ) := contourBoundaryError y a U
  let r (y : ℝ) := psi1ContourRemainder y U
  let B := 2 * (x + h) ^ (3 : ℝ) / (π * U)
  let M := max ((d (x + h) + d x) / h) ((d x + d (x - h)) / h)
  have hbound {y : ℝ} (hy : 1 ≤ y) (hy' : y ≤ x + h) : |r y| ≤ B + d y := by
    refine (abs_psi1ContourRemainder_le_of_neg hy hU ha ha' hgood).trans ?_
    dsimp [B, d]
    gcongr
  have h₁ := hbound (y := x + h) (by linarith) le_rfl
  have h₂ := hbound (y := x) (by linarith) (by linarith)
  have h₃ := hbound hlo (by linarith)
  have hleft : d (x + h) + d x ≤ M * h := (div_le_iff₀ hh).mp (le_max_left _ _)
  have hright : d x + d (x - h) ≤ M * h := (div_le_iff₀ hh).mp (le_max_right _ _)
  change |r (x + h) - 2 * r x + r (x - h)| ≤ _
  calc
    _ ≤ |r (x + h)| + 2 * |r x| + |r (x - h)| := by
      refine (abs_add_le _ _).trans ?_
      have h := abs_sub (r (x + h)) (2 * r x)
      rw [abs_mul, abs_of_nonneg (by norm_num : (0 : ℝ) ≤ 2)] at h
      linarith
    _ ≤ 4 * B + 2 * h * M := by linarith only [h₁, h₂, h₃, hleft, hright]
    _ = 2 * h * contourDiffError x h a U := by
      unfold contourDiffError
      change 4 * B + 2 * h * M = 2 * h * (4 * (x + h) ^ (3 : ℝ) / (π * h * U) + M)
      dsimp [B]
      field_simp [hh.ne', hU.ne', Real.pi_ne_zero]

/-- Select one good U for all three points; the vertical component is explicit
while the truncation and horizontal terms together cost at most h²/60. -/
theorem exists_triangle_remainder_bound (hRH : RiemannHypothesis)
    {x h T : ℝ} (hh : 0 < h) (hlo : 1 ≤ x - h) (hT : 6 ≤ T) :
    ∃ U ≥ T, (∀ ρ ∈ nontrivialZetaZerosUpTo U, |ρ.im| < U) ∧
      |psi1ContourRemainder (x + h) U - 2 * psi1ContourRemainder x U +
        psi1ContourRemainder (x - h) U| ≤
        (128 * 87 : ℝ) / (2 * π) * (x + h) ^ (3 / 4 : ℝ) + h ^ 2 / 60 := by
  obtain ⟨C, hC, hheights⟩ :=
    HorizontalBounds.exists_zero_free_height_with_log_pow_five_bound hRH hT
  obtain ⟨U, hUT, hgood, hsmall⟩ :=
    exists_zero_free_height_with_small_tailAndHorizontal hlo hh hC hheights
      (h / 120) (by positivity)
  have hU : 0 < U := by linarith
  have hleft : ∀ t : ℝ,
      ‖-deriv riemannZeta (((-1 / 4 : ℝ) : ℂ) + (t : ℂ) * Complex.I) /
        riemannZeta (((-1 / 4 : ℝ) : ℂ) + (t : ℂ) * Complex.I)‖ ≤
        (1 : ℝ) * log (|t| + 2) + (85 : ℝ) := by
    intro t
    have he : (((-1 / 4 : ℝ) : ℂ) + (t : ℂ) * Complex.I) =
        (-1 / 4 : ℂ) + (t : ℂ) * Complex.I := by push_cast; ring
    rw [he, neg_div, norm_neg, ← logDeriv_apply, one_mul]
    exact DigammaBinet.norm_logDeriv_riemannZeta_leftVertical_le_eighty_five t
  have hl := contourLeftVerticalDiffError_neg_one_fourth_le hlo hh hU.le
    (by norm_num : (0 : ℝ) ≤ 1) (by norm_num : (0 : ℝ) ≤ 85) hleft
  have hsum := contourDiffError_le_leftVertical_add_tailAndHorizontal x h (-1 / 4) U
  refine ⟨U, hUT, hgood, (triangle_remainder_le_of_common_height (a := -1 / 4) hh hlo hU
    (by norm_num) (by norm_num) hgood).trans ?_⟩
  have hbound := mul_le_mul_of_nonneg_left
    (hsum.trans (add_le_add hl hsmall)) (show 0 ≤ 2 * h by positivity)
  refine hbound.trans_eq ?_
  field_simp [hh.ne', Real.pi_ne_zero]
  ring

#print axioms exists_triangle_remainder_bound
#print axioms triangle_remainder_le_of_common_height
end CubePrime
