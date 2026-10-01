#!/bin/sh
# Exercise original curses gameplay/save state in an isolated PTY.  Retain the
# exact terminal byte stream for Main's actual xterm replay/screenshot capture.
set -eu
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
guix_bin=${GUIX:-guix}
if test "$#" -gt 1; then
    echo "usage: $0 [sewer-massacre-output]" >&2
    exit 64
fi
out=${1:-}
if test -z "$out"; then
    out=$($guix_bin build -L "$channel_dir/guix" --no-grafts sewer-massacre)
fi
test -x "$out/bin/sewer-massacre"
test -s "$out/share/doc/sewer-massacre/license.txt"
test -s "$out/share/doc/sewer-massacre/GNU-GPL"
test -z "$(find "$out" -name controls.cfg -o -name readme.txt)"
program() {
    relative=$1
    shift
    for path in $($guix_bin build --no-grafts "$@"); do
        if test -x "$path/$relative"; then
            printf '%s\n' "$path/$relative"
            return 0
        fi
    done
    return 1
}
python=$(program bin/python3 python)
unshare=$(program bin/unshare util-linux)
timeout=$(program bin/timeout coreutils)
artifacts=${SEWERS_SMOKE_ARTIFACTS:-$(mktemp -d /tmp/sewers-artifacts-XXXXXXXX)}
mkdir -p "$artifacts"
artifacts=$(CDPATH= cd -- "$artifacts" && pwd)
before=$($guix_bin hash -S nar "$out")
set +e
"$timeout" --kill-after=5s 60s \
    "$unshare" --user --map-root-user --net --ipc --pid --kill-child --fork \
    "$python" - "$out" "$artifacts" <<'PY'
import errno
import fcntl
import os
import pathlib
import pty
import select
import signal
import socket
import struct
import sys
import tempfile
import termios
import time

out, artifacts = sys.argv[1:]
artifacts = pathlib.Path(artifacts)
assert [name for _, name in socket.if_nameindex()] == ["lo"]
with tempfile.TemporaryDirectory(prefix="sewers-smoke-") as temporary:
    root = pathlib.Path(temporary)
    environment = {"PATH": "", "LC_ALL": "C", "TERM": "xterm-256color"}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                           ("TMPDIR", "tmp")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    work = root / "work"
    work.mkdir()
    ready, done = root / "ready", root / "done"
    environment["SEWERS_CAPTURE_READY"] = str(ready)
    environment["SEWERS_CAPTURE_DONE"] = str(done)
    pid, master = pty.fork()
    if pid == 0:
        os.chdir(work)
        fcntl.ioctl(1, termios.TIOCSWINSZ, struct.pack("HHHH", 25, 80, 0, 0))
        os.execve(out + "/bin/sewer-massacre",
                  [out + "/bin/sewer-massacre", "--smoke"], environment)
    raw = bytearray()
    deadline = time.monotonic() + 35
    captured = False
    reaped = False
    status = None
    try:
        with (artifacts / "terminal.raw").open("wb", buffering=0) as log:
            while True:
                if time.monotonic() >= deadline:
                    raise RuntimeError("gameplay/save proof timed out")
                if select.select([master], [], [], 0.05)[0]:
                    try:
                        block = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        block = b""
                    if not block:
                        break
                    raw.extend(block)
                    log.write(block)
                    continue
                if ready.exists() and not captured:
                    assert ready.read_text().strip() == "gameplay-and-save-restore-ok"
                    # The source rendezvous follows refresh().  Drain its PTY
                    # output before snapshotting, excluding endwin/marker bytes.
                    (artifacts / "gameplay.raw").write_bytes(raw)
                    captured = True
                    done.write_text("captured\n")
            _, status = os.waitpid(pid, 0)
            reaped = True
        assert os.waitstatus_to_exitcode(status) == 0, raw.decode(errors="replace")
        assert captured, "game exited before gameplay/save proof: " + raw.decode(errors="replace")
        assert b"SEWERS_SMOKE_OK" in raw, "final gameplay marker missing"
        assert b"Level:" in raw and b"Cash:" in raw and b"STR:" in raw, "HUD missing"
        assert b"unhandled" not in raw.lower(), "Lisp runtime failed"
        state = root / "state" / "sewer-massacre"
        assert {p.name for p in state.iterdir()} == {"current.sav"}
        assert (state / "current.sav").stat().st_size > 0
        assert not list(work.iterdir()), "launcher wrote caller working directory"
        for name in ("home", "config", "data", "cache", "runtime", "tmp"):
            assert not list((root / name).iterdir()), "unexpected state in " + name
    finally:
        os.close(master)
        if not reaped:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
print("SEWERS_SMOKE_OK: generated map, moved player, restored save")
print("Exact pre-endwin terminal capture: " + str(artifacts / "gameplay.raw"))
PY
status=$?
set -e
after=$($guix_bin hash -S nar "$out")
test "$before" = "$after" || { echo 'package output changed' >&2; exit 1; }
exit "$status"
