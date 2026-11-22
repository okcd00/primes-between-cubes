import OneFactorCore
open CubePrime.OneFactor
-- Corrupt the order witness, then corrupt the interval independently.
example : certOK 16777259 281449458497869 1 = false := by decide +kernel
example : certOK 16777259 281449458497869 198221372019760 = true := by decide +kernel
example : checkRun 16777259 65533 [(281449458497869, 198221372019760)] = false := by decide +kernel
-- Order certification alone does not imply primality without the size guard.
-- 4 has order 5 modulo 341, but the proposed root is too small.
example : certOK 5 341 4 = false := by decide +kernel
-- A composite root could pass a Boolean check; soundness never assumes it prime.
example : knownPrimeOK 4 [] = false := by decide +kernel
