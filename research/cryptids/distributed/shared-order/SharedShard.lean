import FiniteHybrid.Group255
theorem cube_shard : ∀ n : ℕ, 65281 ≤ n → n < 65535 →
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n+1) ^ 3 :=
  CubePrime.OneFactor.hybrid_255
#print axioms cube_shard
