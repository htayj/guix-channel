#!/usr/bin/env python3
"""Open a fixture in the packaged Liquid editor through a PTY, then quit."""

import errno
import fcntl
import os
import pty
import re
import select
import shutil
import signal
import struct
import sys
import tempfile
import termios
import time
from pathlib import Path

MARKER = "liquid smoke proof: fixture rendered successfully"
ROWS, COLS = 24, 80
FIXTURE_LINES = (
    "(ns liquid.fixture)",
    "",
    ";; LIQUID-FIXTURE-SENTINEL",
    '(defn greet [] "hello from fixture")',
)
FIXTURE = ("\n".join(FIXTURE_LINES) + "\n").encode("ascii")
CSI = re.compile(rb"\x1b\[([0-9;?]*)[ -/]*([@-~])")

if len(sys.argv) != 2:
    raise SystemExit("usage: liquid-smoke.py LIQUID-LAUNCHER")
program = sys.argv[1]


def network_interfaces():
    lines = Path("/proc/self/net/dev").read_text().splitlines()[2:]
    return {line.split(":", 1)[0].strip() for line in lines if ":" in line}


# The package launcher enters a fresh network namespace before running this
# script.  Refuse to prove anything if a host interface is still visible.
if network_interfaces() != {"lo"}:
    raise SystemExit("liquid smoke must run in an isolated network namespace")

scratch = Path(tempfile.mkdtemp(prefix="liquid-smoke.",
                                dir=os.environ.get("TMPDIR")))
directories = {name: scratch / name for name in
               ("home", "config", "data", "cache", "state", "runtime",
                "tmp", "work")}
for directory in directories.values():
    directory.mkdir()
fixture = directories["work"] / "fixture.clj"
fixture.write_bytes(FIXTURE)

child_environment = {
    "HOME": str(directories["home"]),
    "XDG_CONFIG_HOME": str(directories["config"]),
    "XDG_DATA_HOME": str(directories["data"]),
    "XDG_CACHE_HOME": str(directories["cache"]),
    "XDG_STATE_HOME": str(directories["state"]),
    "XDG_RUNTIME_DIR": str(directories["runtime"]),
    "TMPDIR": str(directories["tmp"]),
    "TERM": "xterm-256color",
    "LC_ALL": "C",
}


def render(stream):
    """Return the 80x24 screen produced by Liquid's CSI drawing stream."""
    screen = [[" "] * COLS for _ in range(ROWS)]
    row = column = 0
    index = 0
    while index < len(stream):
        byte = stream[index]
        if byte == 0x1b:
            match = CSI.match(stream, index)
            if not match:
                index += 1
                continue
            text = match.group(1).decode("ascii").lstrip("?")
            params = [int(part) if part else 0 for part in text.split(";")] \
                if text else []
            command = match.group(2)
            if command in (b"H", b"f"):
                row = min(ROWS - 1, max(0, (params[0] if params else 1) - 1))
                column = min(COLS - 1, max(0, (params[1] if len(params) > 1
                                                else 1) - 1))
            elif command == b"J":
                mode = params[0] if params else 0
                if mode in (2, 3):
                    screen = [[" "] * COLS for _ in range(ROWS)]
                elif mode == 0:
                    screen[row][column:] = [" "] * (COLS - column)
                    for clear in range(row + 1, ROWS):
                        screen[clear] = [" "] * COLS
            elif command == b"K":
                mode = params[0] if params else 0
                if mode == 0:
                    screen[row][column:] = [" "] * (COLS - column)
                elif mode == 1:
                    screen[row][:column + 1] = [" "] * (column + 1)
                else:
                    screen[row] = [" "] * COLS
            index = match.end()
            continue
        if byte == 0x0d:
            column = 0
        elif byte == 0x0a:
            row = min(ROWS - 1, row + 1)
        elif byte == 0x08:
            column = max(0, column - 1)
        elif 0x20 <= byte < 0x7f or byte >= 0xc0:
            screen[row][column] = chr(byte) if byte < 0x7f else "?"
            # Liquid disables autowrap (CSI ?7l), so the last column sticks.
            column = min(COLS - 1, column + 1)
        index += 1
    return ["".join(line).rstrip() for line in screen]


def startup_ready(lines):
    return lines[17].startswith("-" * 40) and lines[18] == "Output"


def fixture_ready(lines):
    return (tuple(lines[:4]) == FIXTURE_LINES and startup_ready(lines))


captured = bytearray()
pid = None
master = None


def stop_child():
    if pid is None:
        return
    try:
        os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass


def fail(message):
    stop_child()
    screen = "\n".join(render(bytes(captured)))
    shutil.rmtree(scratch, ignore_errors=True)
    raise SystemExit("liquid smoke: %s\nlast screen:\n%s" % (message, screen))


def read_for(seconds, deadline):
    """Read PTY output for SECONDS; return (got_bytes, eof)."""
    end = min(time.monotonic() + seconds, deadline)
    got = False
    while time.monotonic() < end:
        ready, _, _ = select.select([master], [], [], 0.1)
        if not ready:
            continue
        try:
            chunk = os.read(master, 65536)
        except OSError as error:
            if error.errno == errno.EIO:
                return got, True
            raise
        if not chunk:
            return got, True
        captured.extend(chunk)
        got = True
    return got, False


def wait_until(predicate, deadline, what):
    while time.monotonic() < deadline:
        _, eof = read_for(0.2, deadline)
        if predicate(render(bytes(captured))):
            # Let the asynchronous printer finish before sending more keys.
            while True:
                got, eof = read_for(1.0, deadline)
                if eof:
                    fail("editor exited while waiting for " + what)
                if not got:
                    return
                if time.monotonic() >= deadline:
                    break
        if eof:
            fail("editor exited while waiting for " + what)
    fail("timed out waiting for " + what)


def send(keys):
    try:
        os.write(master, keys)
    except OSError as error:
        fail("could not send input: %s" % error)


pid, master = pty.fork()
if pid == 0:
    try:
        fcntl.ioctl(0, termios.TIOCSWINSZ,
                    struct.pack("HHHH", ROWS, COLS, 0, 0))
        os.chdir(directories["work"])
        os.execve(program, [program], child_environment)
    finally:
        os._exit(127)

deadline = time.monotonic() + 60
wait_until(startup_ready, deadline, "the initial editor frame")
send(b":e fixture.clj\r")
wait_until(fixture_ready, deadline, "the rendered fixture")
frame_end = len(captured)
if not fixture_ready(render(bytes(captured))):
    fail("the fixture frame changed before quitting")

send(b":q\r")
eof = False
while not eof:
    if time.monotonic() >= deadline:
        fail("timed out waiting for :q to exit the editor")
    _, eof = read_for(0.5, deadline)
_, status = os.waitpid(pid, 0)
pid = None
os.close(master)
if not os.WIFEXITED(status) or os.WEXITSTATUS(status) != 0:
    fail("editor did not exit cleanly after :q (status %d)" % status)
# The upstream exit handler clears the screen and shows the cursor again.
if b"\x1b[2J" not in captured[frame_end:] or \
        b"\x1b[?25h" not in captured[frame_end:]:
    fail("editor exit did not restore the terminal")

if fixture.read_bytes() != FIXTURE:
    fail("the fixture file was modified")
stray = [str(path.relative_to(scratch)) for path in scratch.rglob("*")
         if not path.is_dir() and path != fixture]
if stray:
    fail("editor wrote unexpected state: " + ", ".join(sorted(stray)))
shutil.rmtree(scratch)

raw_capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
if raw_capture:
    capture = Path(raw_capture)
    capture.parent.mkdir(parents=True, exist_ok=True)
    capture.write_bytes(bytes(captured[:frame_end]))

print(MARKER)
