import AdaptiveCore
open CubePrime.Adaptive
-- Real first witness and actual fourth interval.
example : witnessOK [3] 1 [(7, 4, 3)] = true := by decide +kernel
example : witnessOK [] 1 [(7,4,3)] = false := by decide +kernel
example : witnessOK [41] 4 [(83,4,41)] = true := by decide +kernel
example : witnessOK [41] 3 [(83,4,41)] = false := by decide +kernel
example : rootsOK [41] [] = false := by decide +kernel
example : witnessOK [41] 5 [(83,4,41)] = false := by decide +kernel
