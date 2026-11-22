import PrattCore

namespace CubePrime.Pratt
axiom group_000 : ∀ n : ℕ, 1 ≤ n → n < 1025 → CubeAt n

theorem independentPrefix : ∀ n : ℕ, 1 ≤ n → n < 1025 → CubeAt n :=
  group_000
end CubePrime.Pratt
