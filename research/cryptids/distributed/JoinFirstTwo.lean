import FinitePratt.Group000
import FinitePratt.Group001

namespace CubePrime.Pratt
/-- Demonstrator combining two separately compiled disjoint intervals. -/
theorem pilotFinitePrefix : ∀ n : ℕ, 1 ≤ n → n < 513 → CubeAt n :=
  splice group_000 group_001

#print axioms pilotFinitePrefix
end CubePrime.Pratt
