# Lower-resource verifier baselines

Research receipts only. No change to the v1 release and no unconditional v2 claim.

## Full adaptive v1 conditional solution

The genuine source export was 535,930,117 bytes, SHA-256
`bbcb3cad3d067c1a1c4bb6fdea28ff51828793dc82313b7415c98446eebf76c4`
(66,359 declarations). The isolated exact statement comparison remains the
separate con-leche comparison; accepting an environment is not statement
matching. A negative input with an admitted axiom is not a verification pass.

| Mode | Wall | Peak checker/process RSS | Outcome |
|---|---:|---:|---|
| Kefir from raw file | 127.335 s | 290,996 KiB | all declarations accepted, three allowed axioms |
| Kefir from authenticated zstd stream | 126.099 s | 291,044 KiB | same checked declaration count and three-axiom result |
| Susz pack, 2 threads, no index | 0.445 s | 156,564 KiB | 54,810,433-byte file |
| Gruszka full, 2 workers | 12.349 s | 353,916 KiB | all declarations accepted, no subset/unchecked mode |

Kefir `095cff9e85e40e767fe18ad5197f32d9ff5fb511`, Gruszka
`ebc80dcb20786d4f25335146b8a9fe8f398843c1`, Susz packer
`3a1a74148c3f530b316bb27c9cd8d60619d0c3ae`, Rust 1.100.0 (locked
builds, unchanged kernels). The packed environment's independently computed
Susz kernel digest matched the NDJSON (54ab05bcbed02ebee27fbb21b899fa642973822f822334de6d5078303cc39927);
both named conditional roots depend only on `Classical.choice`,
`Quot.sound`, and `propext` in the graph. Both kernels reject an ill-typed
provider. These are local, partially contended observations, not controlled
throughput estimates. RSS above is a per-process maximum: the zstd adapter
ran separately.

## Native-export comparison for the first 1,024 intervals

Using the same compiled Lean 4.33.1 `FinitePratt.Group000` and target
`CubePrime.Pratt.group_000`, the pinned Lean exporter
`15f6055e299ad5b89345e533cc2192f4cc00f659` took 3.464 s at
2,155,320 KiB peak RSS, while Rust olean-export
`42d2d1da4e76b98a97f3c8a9cb39449e959e0759` took 6.117 s at
1,197,484 KiB. These are one-off, contended measurements; Rust used less
memory and was slower on this case. The normalized kernel digest agreed
for all 6,927 declarations in the two exports:
`2e6cd77fffbaaee9e078573f07cdeb8efbbfb2fbfde9ec601dadf05f57e25fb0`.
The Rust-produced stream also passed con-leche verified exact comparison
against the independent finite challenge, filling precisely
`CubePrime.Pratt.group_000`.

## Remaining boundaries

Limited, intentionally truncated prefixes of the MIT RH provider are I/O
and memory pilots, not proof validation. The first full streamed attempt has
no recoverable terminal receipt after the environment reset. No RH bridge
discharge, native RH import, independent no-premise final match or v2 release
is claimed here. Existing verified v1 artifacts and exact v2 acceptance
criteria are unchanged.
