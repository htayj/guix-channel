#!/usr/bin/env python3
"""Drive two deterministic Hydra Slayer sessions in private state."""

import argparse
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import tempfile
import termios
import time


MARKER = "HYDRA_SLAYER_GUIX_SMOKE_OK: new-game, turn, save-load, isolated-state"


def run_session(binary, arguments, keystrokes, environment):
    """Run one curses session in a bounded 24x80 pseudo-terminal."""
    pid, master = pty.fork()
    if pid == 0:
        os.execve(binary, [binary, *arguments], environment)

    fcntl.ioctl(master, termios.TIOCSWINSZ,
                struct.pack("HHHH", 24, 80, 0, 0))
    os.set_blocking(master, False)
    pending = memoryview(keystrokes)
    transcript = bytearray()
    status = None
    deadline = time.monotonic() + 30

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
                    transcript.extend(os.read(master, 65536))
                except BlockingIOError:
                    pass
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise

            waited, candidate = os.waitpid(pid, os.WNOHANG)
            if waited == pid:
                status = candidate
                # Drain bytes already queued by the PTY before returning.
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
                os.kill(pid, signal.SIGTERM)
                os.waitpid(pid, 0)
                raise RuntimeError("Hydra Slayer session exceeded 30 seconds")
    finally:
        os.close(master)

    exit_code = os.waitstatus_to_exitcode(status)
    if exit_code != 0:
        raise RuntimeError(f"Hydra Slayer session exited with status {exit_code}")
    return bytes(transcript)


def assert_tree_is_private(root):
    """Reject symlinks and resolved paths escaping the disposable tree."""
    resolved_root = root.resolve()
    for directory, directories, files in os.walk(root, followlinks=False):
        for name in [*directories, *files]:
            path = Path(directory, name)
            if path.is_symlink():
                raise RuntimeError(f"unexpected symlink in smoke state: {path}")
            try:
                path.resolve().relative_to(resolved_root)
            except ValueError as error:
                raise RuntimeError(f"smoke state escaped {root}: {path}") from error


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--binary", required=True)
    options = parser.parse_args()

    state_home = Path(os.environ.get(
        "XDG_STATE_HOME",
        str(Path(os.environ.get("HOME", ".")) / ".local" / "state"),
    )).resolve()
    state_home.mkdir(parents=True, exist_ok=True)
    smoke_root = Path(tempfile.mkdtemp(
        prefix="hydra-slayer-smoke-", dir=str(state_home)))
    home = smoke_root / "home"
    config = smoke_root / "config"
    data = smoke_root / "data"
    cache = smoke_root / "cache"
    state = smoke_root / "state"
    runtime = smoke_root / "runtime"
    temporary = smoke_root / "tmp"
    for directory in (home, config, data, cache, state, runtime, temporary):
        directory.mkdir()

    environment = {
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data),
        "XDG_CACHE_HOME": str(cache),
        "XDG_STATE_HOME": str(state),
        "XDG_RUNTIME_DIR": str(runtime),
        "TMPDIR": str(temporary),
        "TERM": "xterm-256color",
        "LC_ALL": "C.UTF-8",
        "USER": "guix-smoke",
    }
    if "TERMINFO_DIRS" in os.environ:
        environment["TERMINFO_DIRS"] = os.environ["TERMINFO_DIRS"]

    save = state / "hydra.sav"
    backup = state / "hydra-bak.sav"
    log = state / "hydralog.txt"
    scores = state / "hydrascores.sav"
    common_arguments = [
        "-s", "398",
        "-f", str(save),
        "-b", str(backup),
        "-t", str(log),
        "-g", str(scores),
    ]

    first = run_session(options.binary, common_arguments, b"n\r.Ssy", environment)
    if not save.is_file() or save.stat().st_size == 0:
        raise RuntimeError("the first session did not create hydra.sav")
    if b"Game saved to" not in first:
        raise RuntimeError("the first session did not report a saved game")

    second = run_session(options.binary, common_arguments, b"qxyq", environment)
    if b"Welcome back to Hydra Slayer!" not in second:
        raise RuntimeError("the second session did not load the saved game")
    if b"Added character to" in second:
        raise RuntimeError("the quit-without-recording path wrote a high score")

    raw_capture = os.environ.get("GOOCASTLE_RUNTIME_RAW_CAPTURE")
    if raw_capture:
        Path(raw_capture).write_bytes(first + second)
    else:
        (smoke_root / "terminal.raw").write_bytes(first + second)

    assert_tree_is_private(smoke_root)
    print(MARKER)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, AssertionError) as error:
        raise SystemExit(f"hydra-slayer smoke: {error}")
