import TriangleIdentity
import TrianglePointwise
import WeightedHeadTail

namespace CubePrime
open ConjectureMachines.Semantics.Riemann
open WeightedStieltjes CubePrime.Pointwise Finset Complex

theorem triangle_residue_bound (hRH : RiemannHypothesis)
    {x h T U : ℝ} (hh : 0 < h) (hhx : h < x) (hT : 6 ≤ T) (hTU : T ≤ U) :
    |(∑ ρ ∈ nontrivialZetaZerosUpTo U, diff2 (fun y => resZeroRho y ρ) x h).re| ≤
      (h ^ 2 / Real.sqrt (x - h)) * ((16 / 5) * T * Real.log T + (11 / 5) * T) +
        (4 * (x + h) ^ (3 / 2 : ℝ)) * (((32 / 5) * Real.log T + 54 / 5) / T) := by
  have hlo : 0 < x - h := sub_pos.mpr hhx
  have hhi : 0 < x + h := by linarith
  let f (ρ : ℂ) := diff2 (fz ρ) x h
  have hrepresentation {ρ : ℂ} (hz : IsNontrivialZetaZero ρ) : rhoF ρ.im = ρ := by
    have hre := hRH ρ hz.1 hz.2.1 hz.2.2
    apply Complex.ext
    · simp [rhoF, hre]
    · simp [rhoF]
  have hs : ∑ ρ ∈ nontrivialZetaZerosUpTo U, diff2 (fun y => resZeroRho y ρ) x h =
      -(∑ ρ ∈ nontrivialZetaZerosUpTo U, (analyticOrderNatAt riemannZeta ρ : ℂ) * f ρ) := by
    rw [← sum_neg_distrib]
    apply sum_congr rfl
    intro ρ _
    unfold f diff2 resZeroRho smoothedPerronKernel fz
    ring
  apply (Complex.abs_re_le_norm _).trans
  rw [hs, norm_neg]
  apply norm_weighted_head_tail hRH hT hTU (by positivity) (by positivity)
  · intro ρ hρ
    have hz := (VonMangoldtCount.mem_nontrivialZetaZerosUpTo.mp hρ).1
    have hb := second_diff_small ρ.im hh hhx
    rw [hrepresentation hz] at hb
    rw [show (-1 / 2 : ℝ) = -(1 / 2) by ring, Real.rpow_neg hlo.le,
      ← Real.sqrt_eq_rpow, ← div_eq_mul_inv] at hb
    exact hb
  · intro ρ hρ
    have hm := VonMangoldtCount.mem_nontrivialZetaZerosBetween.mp hρ
    have hg : ρ.im ≠ 0 := by intro e; simp [e] at hm; linarith [hm.2.2]
    have hb := second_diff_large_ordinate ρ.im hh hhx hg
    rwa [hrepresentation hm.1] at hb

#print axioms triangle_residue_bound
end CubePrime
