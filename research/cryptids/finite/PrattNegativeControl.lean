import PrattCore
open CubePrime.Pratt
example : checkBatch 1 [2] [] = true := by decide +kernel
example : checkWitnesses [8] 1 [8] = false := by decide +kernel
example : checkWitnesses [8] 2 [8] = false := by decide +kernel
example : checkBatch 1 [8] [] = false := by decide +kernel
example : checkBatch 2 [8] [] = false := by decide +kernel
example : checkBatch 2 [9] [⟨9, 2, [(2,3)]⟩] = false := by decide +kernel
example : checkBatch 2 [11] [⟨11, 2, [(2,1),(5,1)]⟩] = false := by decide +kernel
