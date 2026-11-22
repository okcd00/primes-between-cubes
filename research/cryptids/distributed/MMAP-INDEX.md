# Scratch-file-backed dependency selection

For the pinned Lean4Export format, `slice_mmap.py` uses compact mapped arrays
for ID lookup, a bitset for already selected records, and only tracks name
prefixes of known semantic roots. Its dependency parser is the existing
`slice-index.py`. It does not prune theorem bodies or modify any retained
record. Output bytes are emitted in the original order, and publication is
atomic after a second forward hash of the source. An unchanged kernel must
still check the inert output; this is not part of the trusted verifier.

On a real 29,701,616-byte 1,024-interval proof export (566,571 records), mapped
selection retained the **entire** export for the main theorem. Same-host
one-off observations, with other builds running:

| Method | Time | Peak process RSS | Index/scratch bytes (logical) |
| --- | ---: | ---: | ---: |
| Fresh SQLite index | 11.027 s | 22,144 KiB | 29,818,880 |
| Fresh mmap index | 4.888 s | 19,628 KiB | 11,113,638 |

For the small `CubePrime.Pratt.splice` subclosure, mmap rebuilt then selected
in 2.231 s, while **reused** SQLite did it in 0.308 s. The outputs were
byte-identical (935,632 bytes, SHA-256
`fbac1e371684468064327f95f2bb4fc5643edc89c2a522b28666ea2b76cbe703`).
The selected artifact independently passed verified con-leche, and a
duplicate record was rejected before publication. No reuse, parallel
traversal, full-RH test, or algorithmic time-complexity improvement is claimed.
A large input must still be readable and indexed. The mapped-page, disk and
frontier costs can be material on a much larger or sparse source.
