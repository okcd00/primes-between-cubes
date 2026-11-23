# Lake setup-file omission and incremental replay pilot

Scope: a disposable two-module package with a real Foundation → Main import, stock Linux Lean 4.33.1 commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`, Lake 5.0.0-src+819816b, and `LEAN_NUM_THREADS=2`. No RH artifact, cube theorem, or private compute host was used.

1. Compile this small package with `lake --no-cache build +Main:olean`: Foundation and Main both build. Inventory the two generated `*.setup.json` (741 bytes) and hash all 30 other files under `.lake/build`.
2. Once compilation exits, move only those two setup files outside the build tree. Run `lake --no-build --no-cache build +Main:olean`, then the normal `lake --no-cache build +Main:olean`. Both exit 0, neither regenerates setup files, and all 30 retained file hashes match. The first command reports “All targets up-to-date (3 jobs).”
3. In a disposable copy, move away Foundation.olean as a negative control. `lake --no-build --no-cache build +Main:olean` exits nonzero at Foundation (“target is out-of-date and needs to be rebuilt”). The positive fixture still has all 30 original hashes. A failed check may update the copied build bookkeeping, so keep this negative control outside the working tree.

Minimal fixture (`lakefile.toml`):
```toml
name = "resumePilot"
[[lean_lib]]
name = "Foundation"
[[lean_lib]]
name = "Main"
```

`Foundation.lean`:
```lean
module
public theorem twice_one : (1 : Nat) + 1 = 2 := rfl
```

`Main.lean`:
```lean
module
public import Foundation
public theorem checked : (1 : Nat) + 1 = 2 := twice_one
```

This tests the hypothesis that a **completed** module can be reused without its compiler setup file in this pinned Lake version and build mode. For a constrained RH build, monitor free space on the actual run volume and generated setup-file size. If reclaiming space is necessary, stop with disk headroom, wait for this run's Lake and Lean processes to exit, inventory only generated setup files in the verified RH IR directory, and preserve all compiled objects, traces, hashes, and checkpoints. Do not remove setup files while a compiler may still read them. Resume with the same run directory. This pilot does not establish reuse for every partially completed module, global disk or RAM fit, any proof verdict, or the separate independent exact-statement gate.
