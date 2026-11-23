# Compact scope-audit pilot (not proof validation)

The existing pinned verifier still defines the acceptance gate. This experimental
read-only role sieve recognizes exact structured Lean names and tracks each dense,
sequential Lean4Export 3.1.0 name ID with one byte, rather than constructing and
retaining the flattened strings. Unknown axioms, duplicate watched theorem roles,
out-of-order name IDs, mis-typed roles, and a one-component string `Classical.choice`
masquerading as the two-component name are rejected. It does not check other record
kinds, expressions, declarations, theorem types, bodies, or closure. It must not
replace the export checksum or verifier, and it is not integrated into the runner.

* Actual 4.33.1 finite provider already independently kernel-replayed (see
  low-memory-kernels README): 29,701,616 bytes; SHA-256
  `e6634e81f1d1f90aefef32659c1f8af2ec9cad465874814be4d0105c10461d09`.
  Both role auditors found exactly the three standard axioms and
  `CubePrime.Pratt.group_000` in the finite test role. The compact name table used
  44,749 logical bytes for 44,748 exported name IDs. Two fresh Python processes
  took 0.761/0.851 s with peak Linux RSS 8,960 KiB; current string-table auditor
  (configured for the same fixture role) took 0.834/0.855 s, 18,272 KiB.
  These short measurements are preliminary; they do not establish
  a speedup, RH memory fit, or kernel savings.
* Replayed an existing exported provider with an extra axiom: scope check exited 1.
  Unit tests also reject nine synthetic cases; none of those is an authentic RH artifact.

Repeat: `python3 -m unittest -v test_compact_role_audit.py`, then
`python3 compact_role_audit.py finite-fixture PATH/FiniteProvider.ndjson`.
No run over the full RH export or native final export is claimed.
