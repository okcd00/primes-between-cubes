import Cryptids.Semantics.Riemann.WeightedStieltjes

/-! Exact three-point identity for the truncated smooth explicit formula. -/
namespace CubePrime

open ConjectureMachines.Semantics.Riemann
open WeightedStieltjes Finset Complex

noncomputable def diff2 {α : Type*} [Ring α] (f : ℝ → α) (x h : ℝ) : α :=
  f (x + h) - 2 * f x + f (x - h)

/-- The linear residue cancels and the quadratic main term becomes h².
The summands still carry their analytic multiplicities through `resZeroRho`. -/
theorem triangle_explicit_identity (x h U : ℝ) :
    diff2 psi1 x h =
      h ^ 2 +
        (∑ ρ ∈ nontrivialZetaZerosUpTo U, diff2 (fun y => resZeroRho y ρ) x h).re +
        diff2 (fun y => psi1ContourRemainder y U) x h := by
  have he : (∑ ρ ∈ nontrivialZetaZerosUpTo U, diff2 (fun y => resZeroRho y ρ) x h).re =
      (∑ ρ ∈ nontrivialZetaZerosUpTo U, resZeroRho (x + h) ρ).re -
        2 * (∑ ρ ∈ nontrivialZetaZerosUpTo U, resZeroRho x ρ).re +
        (∑ ρ ∈ nontrivialZetaZerosUpTo U, resZeroRho (x - h) ρ).re := by
    simp only [diff2, two_mul, sum_add_distrib, sum_sub_distrib, Complex.add_re, Complex.sub_re]
  rw [he]
  unfold diff2 psi1ContourRemainder
  ring

#print axioms triangle_explicit_identity

end CubePrime
