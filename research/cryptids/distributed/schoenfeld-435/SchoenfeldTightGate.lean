import SchoenfeldTightCore
import Mathlib.Data.Nat.Prime.Basic

open scoped BigOperators
namespace CubeSchoenfeldTight

def primesUpTo (n : ℕ) : Finset ℕ :=
  (Finset.range (n+1)).filter Nat.Prime

private theorem mem_primesUpTo {p n : ℕ} :
    p ∈ primesUpTo n ↔ p ≤ n ∧ p.Prime := by
  simp [primesUpTo]

theorem large_cube {psi theta : ℝ → ℝ} {pi : ℝ}
    (hp : 3 ≤ pi)
    (hs : ∀ x : ℝ, (366 / 5 : ℝ) ≤ x →
      |psi x - x| < Real.sqrt x * (Real.log x)^2 / (8*pi))
    (ht : ∀ x : ℝ, theta x ≤ psi x)
    (htail : ∀ x : ℝ, 1 ≤ x → psi x - theta x ≤ 2 * Real.sqrt x * Real.log x)
    (hsum : ∀ n : ℕ, theta n = ∑ p ∈ primesUpTo n, Real.log p)
    (n : ℕ) (hn : 511 ≤ n) :
    ∃ p : ℕ, p.Prime ∧ n^3 < p ∧ p < (n+1)^3 := by
  have hm : (512 : ℝ) ≤ (n : ℝ) + 1 := by
    have h : 512 ≤ n + 1 := by omega
    exact_mod_cast h
  have h := theta_increase psi theta hm hp hs ht htail
  have hcast : (n : ℝ) + 1 - 1 = n := by ring
  rw [hcast] at h
  have h' : theta (↑(n^3 : ℕ)) < theta (↑((n+1)^3 : ℕ)) := by
    simpa only [Nat.cast_pow, Nat.cast_add, Nat.cast_one] using h
  by_contra! hnoprime
  have heq : primesUpTo (n^3) = primesUpTo ((n+1)^3) := by
    ext p
    simp only [mem_primesUpTo]
    constructor
    · rintro ⟨hle, hprime⟩
      exact ⟨hle.trans (Nat.pow_le_pow_left (by omega) 3), hprime⟩
    · rintro ⟨hle, hprime⟩
      refine ⟨?_, hprime⟩
      by_contra! hlo
      have hne : p ≠ (n + 1)^3 := fun he => by
        rw [he] at hprime
        exact (Nat.Prime.not_prime_pow (by decide : 2 ≤ 3)) hprime
      exact (not_le_of_gt (lt_of_le_of_ne hle hne)) (hnoprime p hprime hlo)
  rw [hsum (n^3), hsum ((n+1)^3), heq] at h'
  exact (lt_irrefl _) h'

#print axioms large_cube
end CubeSchoenfeldTight
