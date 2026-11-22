# Finite range checkpoint

The candidate data for `1 ≤ n ≤ 65534` was generated with Python and SymPy 1.14.0.
A separate standard-library-only Python verifier checked 65,534 strict cube intervals and
160,511 nonbase Lucas primality certificates with exact integers. The generated JSON hash
is `fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d`.
This is an independent check of the candidate data, not an axiom or evidence of full Lean replay.

After running the upstream analytic replay script, copy these finite files into its printed
replay directory. With the same pinned toolchain and Mathlib used there, run:

```sh
lake build +Mathlib.NumberTheory.LucasPrimality:olean
lake env lean -o .lake/build/lib/lean/PrattCore.olean PrattCore.lean
lake env lean PrattNegativeControl.lean
python3 -B generate_cube_witnesses.py finite-full-candidates.json
python3 -B verify_cube_witnesses.py finite-full-candidates.json
python3 -B render_pratt_range.py finite-full-candidates.json FinitePratt
bash run_finite_kernel.sh
```

The generic checker soundness and a stress batch of the upper 64 intervals (65471 through
65534) passed with only Lean's standard axioms. The renderer splits the full range into
64 source groups and computes each local certificate using `decide +kernel`, not native
code or an imported data assumption. The full run and the combined RH-conditional theorem
are not asserted to have passed in this checkpoint. The standalone proof of RH is not
imported here.
