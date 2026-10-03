#!/usr/bin/env python3
"""Exercise the installed lbForth, without build tools or checkout sources."""

import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def snapshot(root):
    """Record contents and filesystem metadata without following symlinks."""
    result = {}
    for path in [root, *sorted(root.rglob("*"))]:
        stat = path.lstat()
        content = None
        if path.is_symlink():
            content = os.readlink(path)
        elif path.is_file():
            content = hashlib.sha256(path.read_bytes()).hexdigest()
        result[str(path.relative_to(root))] = (
            stat.st_mode, stat.st_size, stat.st_mtime_ns, content
        )
    return result


def run(forth, work, environment, source):
    completed = subprocess.run(
        [str(forth)], input=source, text=True, capture_output=True,
        cwd=work, env=environment, timeout=30, check=True,
    )
    if completed.stderr:
        raise AssertionError(f"unexpected stderr: {completed.stderr}")
    print(completed.stdout, end="")
    return completed.stdout


def require_result(output, label, expected):
    match = re.search(rf"{label}:\s*(-?\d+)\s*END", output)
    if not match or int(match.group(1)) != expected:
        raise AssertionError(f"{label}: expected {expected}, got {output!r}")


def main():
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {sys.argv[0]} lbforth-output")
    output = Path(sys.argv[1]).resolve(strict=True)
    forth = output / "bin/forth"
    if not forth.is_file() or not os.access(forth, os.X_OK):
        raise AssertionError(f"missing installed interpreter: {forth}")
    before = snapshot(output)
    try:
        with tempfile.TemporaryDirectory(prefix="lbforth-smoke-") as directory:
            temporary = Path(directory)
            for name in ("home", "config", "data", "cache", "state", "runtime", "work"):
                (temporary / name).mkdir(mode=0o700)
            environment = {
                "HOME": str(temporary / "home"),
                "XDG_CONFIG_HOME": str(temporary / "config"),
                "XDG_DATA_HOME": str(temporary / "data"),
                "XDG_CACHE_HOME": str(temporary / "cache"),
                "XDG_STATE_HOME": str(temporary / "state"),
                "XDG_RUNTIME_DIR": str(temporary / "runtime"),
                "TMPDIR": str(temporary), "LC_ALL": "C", "PATH": "/nonexistent",
            }
            work = temporary / "work"
            results = run(forth, work, environment, '''
: square dup * ;
.( ARITHMETIC: ) 6 square 7 + . .( END ) cr
: choose dup 0< if negate 2 * else 3 + then ;
.( NEGATIVE: ) -5 choose . .( END ) cr
.( POSITIVE: ) 5 choose . .( END ) cr
: total 0 swap 0 do i + loop ;
.( LOOP: ) 10 total . .( END ) cr
: factorial dup 1 > if dup 1- recurse * else drop 1 then ;
.( RECURSION: ) 5 factorial . .( END ) cr
: countdown begin dup while 1- repeat ;
.( BEGIN: ) 8 countdown . .( END ) cr
.( DEPTH: ) depth . .( END ) cr
bye
''')
            for label, expected in (
                ("ARITHMETIC", 43), ("NEGATIVE", 10), ("POSITIVE", 8),
                ("LOOP", 45), ("RECURSION", 120), ("BEGIN", 0), ("DEPTH", 0),
            ):
                require_result(results, label, expected)
            if "Undefined:" in results or "Exception!" in results:
                raise AssertionError("language program raised an unexpected error")

            errors = run(forth, work, environment, '''
17
no-such-lbforth-word
.( UNDEFINED-DEPTH: ) depth . .( END ) cr
.( RECOVERED: ) 20 22 + . .( END ) cr
: rejected 1 abort" rejected-input" ;
rejected
.( ABORT-DEPTH: ) depth . .( END ) cr
.( ABORT-RECOVERED: ) 7 6 * . .( END ) cr
include no-such-lbforth-file.fth
.( FILE-RECOVERED: ) 9 9 * . .( END ) cr
bye
''')
            if "Undefined: no-such-lbforth-word" not in errors:
                raise AssertionError("undefined-word diagnostic missing")
            if "rejected-input" not in errors:
                raise AssertionError('ABORT" diagnostic missing')
            if "File not found" not in errors:
                raise AssertionError("missing-file diagnostic missing")
            for label, expected in (
                ("UNDEFINED-DEPTH", 0), ("RECOVERED", 42),
                ("ABORT-DEPTH", 0), ("ABORT-RECOVERED", 42),
                ("FILE-RECOVERED", 81),
            ):
                require_result(errors, label, expected)
            if list(work.iterdir()):
                raise AssertionError("interpreter unexpectedly wrote to working directory")
    finally:
        if snapshot(output) != before:
            raise AssertionError("installed output changed during interpreter execution")
    print("Installed lbForth arithmetic, control flow, error recovery, and immutable output passed.")


if __name__ == "__main__":
    main()
