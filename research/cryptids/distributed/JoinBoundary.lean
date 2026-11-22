import PrattCore

namespace CubePrime.Pratt

-- These are inputs to the export/link experiment. They are not accepted axioms.
axiom group_000 : ∀ n : ℕ, 1 ≤ n → n < 257 → CubeAt n
axiom group_001 : ∀ n : ℕ, 257 ≤ n → n < 513 → CubeAt n

theorem pilotFinitePrefix : ∀ n : ℕ, 1 ≤ n → n < 513 → CubeAt n :=
  splice group_000 group_001

end CubePrime.Pratt
