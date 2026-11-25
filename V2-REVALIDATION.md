# V2 revalidation status

Current state: RUNNING

## Previous attempt

The RH dependency fetch failed: LeanSearchClient returned an empty server response (Git 128; stage exit 1). Exact pinned dependencies were prepared from existing local Git objects.

    host_max_vm_mappings=2560000
    host_vmem_limit_kib_or_unlimited=unlimited
    lean=4.33.1:819816b2e0a3bf405af45ae5c7af2491d8f5bee6
    mathlib=0df444a360eaa60ab8c11dca51a86af692955474
    rh_source=58afe6f4b8167e8945f7c82954b0fc477541f9d0
    cryptids=3647718b5df22e1a61462dec0376bd204526285a
    cube_git=PASS
    cube_setup=PASS
    cube_data=PASS
    cube_dependencies=PASS
    cube_analytic=PASS
    cube_finite=PASS
    finite_groups=64/64
    candidate_sha256=fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d
    rh_git=PASS
    rh_build=FAIL
    exit=1
    stopped_at=rh_build
    independent_export_replay=NOT_RUN

## Current attempt

    host_max_vm_mappings=2560000
    host_vmem_limit_kib_or_unlimited=unlimited
    lean=4.33.1:819816b2e0a3bf405af45ae5c7af2491d8f5bee6
    mathlib=0df444a360eaa60ab8c11dca51a86af692955474
    rh_source=58afe6f4b8167e8945f7c82954b0fc477541f9d0
    cryptids=3647718b5df22e1a61462dec0376bd204526285a
    cube_git=PASS
    cube_setup=PASS
    cube_data=PASS
    cube_dependencies=PASS
    cube_analytic=PASS
    cube_finite=PASS
    finite_groups=64/64
    candidate_sha256=fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d
    rh_git=PASS

## Selected axiom audit evidence

    'ConjectureMachines.Semantics.Riemann.VonMangoldtCount.weightedZeroCountingFunction_le_sixteen_fifths' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.WeightedStieltjes.psi1_eq_sum_Icc_sub_mul_vonMangoldt' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.WeightedStieltjes.sum_weighted_inv_sq_nontrivialZetaZerosBetween_le_of_riemannVonMangoldt' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.WeightedStieltjes.abs_psi1_sub_main_add_log_two_pi_sub_zeroSum_le_of_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.WeightedStieltjes.contourLeftVerticalError_neg_one_fourth_le' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.WeightedStieltjes.exists_zero_free_height_with_small_tailAndHorizontal' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.DigammaBinet.norm_logDeriv_riemannZeta_leftVertical_le_eighty_five' depends on axioms: [propext, Classical.choice, Quot.sound]
    'ConjectureMachines.Semantics.Riemann.HorizontalBounds.exists_zero_free_height_with_log_pow_five_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.triangle_explicit_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.cube_triangle_budget' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.cube_triangle_budget_mathlib' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.cube_vertical_budget' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.prime_of_large_triangle' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.psi1_second_diff_eq_triangular_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.norm_weighted_head_tail' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.exists_triangle_remainder_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.triangle_remainder_le_of_common_height' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.Pointwise.second_diff_small' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.Pointwise.second_diff_large_ordinate' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.triangle_residue_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.prime_between_large_nat_cubes_of_RH' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.cube_triangle_estimates' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.prime_between_large_cubes_of_RH' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.Pratt.checkBatch_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.Pratt.finite_cube_range' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CubePrime.primeBetweenCubes_of_RH' depends on axioms: [propext, Classical.choice, Quot.sound]

Only allowlisted verification evidence is recorded here; raw logs remain on the internal machine.
