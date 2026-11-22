#!/usr/bin/env python3
"""Measure the child Linux process without changing host settings."""
from pathlib import Path
import resource
import subprocess
import sys
import time

FIELDS = ("VmRSS", "RssFile", "RssAnon", "VmSize")

def sample(pid):
    p = Path("/proc") / str(pid)
    try:
        values = {}
        with (p/"status").open() as fd:
            for line in fd:
                field, sep, val = line.partition(":")
                if sep and field in FIELDS:
                    values[field] = int(val.split()[0])
        with (p/"maps").open("rb") as fd:
            values["Maps"] = sum(1 for _ in fd)
        return values
    except (OSError, ValueError, IndexError):
        return {}

def main(argv):
    if not argv:
        print("usage: measure-lean-import.py COMMAND [ARGS ...]", file=sys.stderr)
        return 64
    proc = subprocess.Popen(argv)
    peaks = {}
    samples = 0
    start = time.monotonic()
    while proc.poll() is None:
        values = sample(proc.pid)
        if values:
            samples += 1
            for k,v in values.items():
                peaks[k] = max(peaks.get(k,0),v)
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            pass
    status = proc.wait()
    def out(key): return str(peaks.get(key,"unavailable"))
    print(f"RESOURCE native_import_samples={samples} elapsed_s={time.monotonic()-start:.1f} "
          f"max_maps_sampled={out('Maps')} max_rss_sampled_kib={out('VmRSS')} "
          f"max_file_rss_sampled_kib={out('RssFile')} max_anon_rss_sampled_kib={out('RssAnon')} "
          f"max_vmem_sampled_kib={out('VmSize')} "
          f"child_rss_peak_kib={resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss}",
          file=sys.stderr, flush=True)
    return status if status >= 0 else 128-status

if __name__=="__main__":
    sys.exit(main(sys.argv[1:]))
