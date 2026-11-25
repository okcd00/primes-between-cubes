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

Only allowlisted verification evidence is recorded here; raw logs remain on the internal machine.
