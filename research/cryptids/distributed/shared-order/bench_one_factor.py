#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
from time import monotonic

name, out = sys.argv[1:3]
started = monotonic()
with open(out + ".log", "w") as log:
    pid = os.posix_spawnp(os.environ.get("LEAN_BIN", "lean"), [os.environ.get("LEAN_BIN", "lean"), "-j1", "-o", out, name],
                         os.environ, file_actions=[
                         (os.POSIX_SPAWN_DUP2, log.fileno(), 1),
                         (os.POSIX_SPAWN_DUP2, log.fileno(), 2)])
    _, status, resource = os.wait4(pid, 0)
rc = os.waitstatus_to_exitcode(status)
print(json.dumps(dict(source=name, sec=round(monotonic()-started, 3),
                      rss_kib=resource.ru_maxrss, exit=rc, source_bytes=Path(name).stat().st_size,
                      olean_bytes=Path(out).stat().st_size if rc == 0 else None)), flush=True)
sys.exit(rc)
