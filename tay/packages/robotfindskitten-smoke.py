#!/usr/bin/env python3
"""Drive robotfindskitten through one deterministic private PTY session."""

import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import struct
import sys
import tempfile
import termios
import time


MARKER = "GUIX_SMOKE_OK robotfindskitten"
KEYSTROKES = b" " + (b"hjkl" * 16) + b"q"


def fail(message):
    raise RuntimeError(message)


def run_game(binary, root):
    """Run the game with a fixed argument vector and finite key sequence."""
    home = root / "home"
    config = root / "config"
    data = root / "data"
    state = root / "state"
    cache = root / "cache"
    runtime = root / "runtime"
    temporary = root / "tmp"
    work = root / "work"
    for directory in (home, config, data, state, cache, runtime, temporary, work):
        directory.mkdir()
    runtime.chmod(0o700)

    environment = {
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data),
        "XDG_STATE_HOME": str(state),
        "XDG_CACHE_HOME": str(cache),
        "XDG_RUNTIME_DIR": str(runtime),
        "TMPDIR": str(temporary),
        "TERM": "xterm",
        "TERMINFO_DIRS": os.environ.get("TERMINFO_DIRS", ""),
        "LC_ALL": "C",
        "PATH": "",
    }

    pid, master = pty.fork()
    if pid == 0:
        os.chdir(work)
        os.execve(binary, [binary, "-n", "1", "-s", "0"], environment)

    fcntl.ioctl(master, termios.TIOCSWINSZ,
                struct.pack("HHHH", 24, 80, 0, 0))
    os.set_blocking(master, False)
    pending = memoryview(KEYSTROKES)
    transcript = bytearray()
    status = None
    deadline = time.monotonic() + 20

    try:
        while True:
            if pending:
                try:
                    written = os.write(master, pending)
                    pending = pending[written:]
                except BlockingIOError:
                    pass
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    pending = pending[len(pending):]

            readable, _, _ = select.select([master], [], [], 0.1)
            if readable:
                try:
                    chunk = os.read(master, 65536)
                except BlockingIOError:
                    chunk = b""
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    chunk = b""
                if chunk:
                    transcript.extend(chunk)

            waited, candidate = os.waitpid(pid, os.WNOHANG)
            if waited == pid:
                status = candidate
                while True:
                    try:
                        chunk = os.read(master, 65536)
                    except BlockingIOError:
                        break
                    except OSError as error:
                        if error.errno == errno.EIO:
                            break
                        raise
                    if not chunk:
                        break
                    transcript.extend(chunk)
                break

            if time.monotonic() >= deadline:
                os.kill(pid, 15)
                os.waitpid(pid, 0)
                fail("robotfindskitten PTY session exceeded 20 seconds")
    finally:
        os.close(master)

    exit_code = os.waitstatus_to_exitcode(status)
    if exit_code != 0:
        fail(f"robotfindskitten exited with status {exit_code}")
    if b"robotfindskitten 3.0000000.726" not in transcript:
        fail("terminal transcript lacks the fixed release version")
    if b"In this game, you are robot (#)." not in transcript:
        fail("terminal transcript lacks the gameplay introduction")
    if transcript.count(b"#") < 2:
        fail("terminal transcript lacks a moved robot state")
    return bytes(transcript)


def assert_private_tree(root):
    """Reject symlinks and paths escaping the private smoke directory."""
    resolved_root = root.resolve()
    for directory, directories, files in os.walk(root, followlinks=False):
        for name in [*directories, *files]:
            path = Path(directory, name)
            if path.is_symlink():
                fail(f"unexpected symlink in smoke state: {path}")
            try:
                path.resolve().relative_to(resolved_root)
            except ValueError as error:
                raise RuntimeError(f"smoke state escaped {root}: {path}") from error


def main():
    if len(sys.argv) != 2:
        print("usage: robotfindskitten-smoke.py BINARY", file=sys.stderr)
        return 64

    binary = os.path.abspath(sys.argv[1])
    temporary_parent = Path(os.environ.get("TMPDIR", "/tmp")).resolve()
    temporary_parent.mkdir(parents=True, exist_ok=True)
    root = Path(tempfile.mkdtemp(
        prefix="robotfindskitten-smoke-", dir=str(temporary_parent)))
    raw = bytearray()
    try:
        raw.extend(run_game(binary, root))
        assert_private_tree(root)
        raw_path = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
        if raw_path:
            Path(raw_path).write_bytes(raw)
        print(MARKER)
        return 0
    except (OSError, RuntimeError, AssertionError) as error:
        print(f"robotfindskitten smoke: {error}", file=sys.stderr)
        return 1


sys.exit(main())
