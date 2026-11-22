#!/usr/bin/env bash
# Read-only, no network, no builds, no absolute paths or host/user identifiers in output.
set -u
printf 'OS and architecture: '; uname -s -m
printf 'Visible logical CPUs: '; getconf _NPROCESSORS_ONLN 2>/dev/null || true
if command -v free >/dev/null 2>&1; then
  free -h | awk '/^Mem:/ {print "RAM total:", $2, "available:", $7}'
fi
df -hP . | awk 'NR==2 {print "Disk available in run directory:",$4}'
if [[ -r /proc/sys/vm/max_map_count ]]; then
  printf 'Maximum VM mappings per process: '; tr -cd '0-9\n' < /proc/sys/vm/max_map_count
else
  printf 'Maximum VM mappings per process: unavailable\n'
fi
printf 'Process virtual-memory limit (KiB or unlimited): '; ulimit -v 2>/dev/null || true
for t in git lean lake cmake ninja make python3 zstd; do
  if command -v "$t" >/dev/null 2>&1; then
    printf '%s: available\n' "$t"
  else
    printf '%s: unavailable\n' "$t"
  fi
done
# Calling an elan shim can download a toolchain, so do not invoke Lean or Lake here.
