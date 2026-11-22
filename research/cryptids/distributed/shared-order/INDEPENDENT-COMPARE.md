# Independent comparison of the same upper-shard statement

The isolated `IndependentShard.lean` imports Mathlib, not either cube implementation.
Its single temporary boundary is `cube_shard`, the **expanded** primality and strict
cube inequalities for `65281 <= n < 65535`. Compile `BaseShard.lean` and
`SharedShard.lean` in separate output paths to agree on the target name while importing
the original checked Group255 and the hybrid checked Group255, respectively.

With the same exact Lean 4.33.1 and previously pinned Lean4Export/con-leche pair:

```bash
lean4export IndependentShard -- checked_shard > challenge.ndjson
lean4export BaseShard -- cube_shard > base.ndjson
lean4export SharedShard -- cube_shard > shared.ndjson
con-leche --verified --jobs=1 --compare challenge.ndjson base.ndjson
con-leche --verified --jobs=1 --compare challenge.ndjson shared.ndjson
```

Both comparisons actually exited 0, justified exactly `cube_shard`, and used the same
774,293-byte challenge `cf97bd1cfca059a83795afa5ca59e8e05ef8283d396e76c13d02d1c5be0e92ca`.
Both providers had the three standard axioms only. Shifting the lower bound down by
one (same names) independently exited 1 with a type-mismatch diagnosis.

| Provider | Export bytes | Verified provider declarations | One-worker provider check | Process peak RSS |
| --- | ---: | ---: | ---: | ---: |
| Lucas | 28,842,618 | 6,880 | 38.693 s | 1.06 GiB |
| Shared order | 37,170,570 | 9,160 | 3.074 s | 0.07 GiB |

One observation per provider on the same host, with other builds running; not a
controlled speed ratio or a full cold end-to-end replay. The **independent export
grew**, despite smaller and faster stock .olean compilation in the matched pilot:
the proof of order soundness brings a larger algebraic dependency closure. The
reduction is in checker arithmetic and observed working memory, not every resource
measure. Do not extrapolate to the full cube or RH closure.

Export hashes: Lucas `af86e230138e99297df0808e2c220c9752fa618354527c5b9d2e4e6b7adcef4e`;
shared `f2a4e1770a91912185456c2606da1e686ebb2c44e63153e62a0374ce59bd360d`.
No raw exports are stored in Git.
