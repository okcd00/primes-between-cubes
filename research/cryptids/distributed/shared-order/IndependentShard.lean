import Mathlib.NumberTheory.LucasPrimality
axiom cube_shard : ∀ n : ℕ, 65281 ≤ n → n < 65535 →
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n+1) ^ 3
theorem checked_shard (n : ℕ) (h1 : 65281 ≤ n) (h2 : n < 65535) :
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n+1) ^ 3 :=
  cube_shard n h1 h2
