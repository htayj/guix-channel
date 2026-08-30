#!/bin/sh
# Exercise AceHack in an empty HOME/XDG tree and a network-less namespace.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 2; then
    echo "usage: $0 [acehack-output [python-output]]" >&2
    exit 64
fi

if test "$#" -ge 1; then
    acehack_out=$1
else
    acehack_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes acehack)
fi

if test "$#" -eq 2; then
    python_out=$2
else
    python_out=
    for candidate in $($guix_bin build python); do
        if test -x "$candidate/bin/python3"; then
            python_out=$candidate
            break
        fi
    done
    test -n "$python_out"
fi

unshare_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        unshare_out=$candidate
        break
    fi
done
test -n "$unshare_out"

# No network namespace is inherited by the actual package process.  A tty game
# needs no loopback device, so none is brought up here.
if test "${ACEHACK_SMOKE_IN_NETNS:-}" != 1; then
    if ! "$unshare_out/bin/unshare" --user --map-root-user --net --fork true; then
        echo "acehack-smoke: user and network namespaces are required" >&2
        exit 1
    fi
    exec env ACEHACK_SMOKE_IN_NETNS=1 GUIX="$guix_bin" \
        "$unshare_out/bin/unshare" --user --map-root-user --net --fork \
        "$0" "$acehack_out" "$python_out"
fi

test -x "$acehack_out/bin/acehack"
test -x "$acehack_out/libexec/acehack"
test -s "$acehack_out/share/acehack/nhdat"
test -s "$acehack_out/share/doc/acehack/license"
test -s "$acehack_out/share/doc/acehack/README"
test -s "$acehack_out/share/doc/acehack/Guidebook.txt"
test -s "$acehack_out/share/doc/acehack/fixes36.0"
grep -F 'NETHACK GENERAL PUBLIC LICENSE' "$acehack_out/share/doc/acehack/license" >/dev/null
grep -F 'AceHack 3.6.0' "$acehack_out/share/doc/acehack/README" >/dev/null

"$python_out/bin/python3" - "$channel_dir" "$acehack_out" <<'PY'
import fcntl
import hashlib
import json
import os
import pathlib
import pty
import select
import signal
import struct
import sys
import tempfile
import termios
import time


channel, output = map(pathlib.Path, sys.argv[1:])
launcher = output / "bin" / "acehack"


def snapshot(root):
    entries = []
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        entries.append((str(path.relative_to(root)), status.st_mode, status.st_size, digest))
    return entries


def read_until(fd, markers, timeout):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.15)
        if not ready:
            continue
        try:
            chunk = os.read(fd, 8192)
        except OSError:
            break
        if not chunk:
            break
        data.extend(chunk)
        if any(marker in data for marker in markers):
            return bytes(data)
    raise AssertionError("did not observe %r: %s" %
                         (markers, data.decode("utf-8", "replace")[-4000:]))


def drain(fd, timeout):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.15)
        if not ready:
            continue
        try:
            chunk = os.read(fd, 8192)
        except OSError:
            break
        if not chunk:
            break
        data.extend(chunk)
    return bytes(data)


def wait_for_exit(pid, timeout, transcript):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        done, status = os.waitpid(pid, os.WNOHANG)
        if done:
            assert os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0, (status, transcript)
            return
        time.sleep(0.05)
    os.kill(pid, signal.SIGTERM)
    os.waitpid(pid, 0)
    raise AssertionError("AceHack did not exit: " + transcript.decode("utf-8", "replace")[-4000:])


contract = json.loads((channel / ".goocastle/runtime-evidence-contracts.json").read_text())
matching = [entry for entry in contract["contracts"] if entry["issueNumber"] == 650]
assert matching == [{
    "issueNumber": 650,
    "packageName": "acehack",
    "artifactPath": ".goocastle/evidence/issue-650.png",
    "runtime": {
        "executable": "acehack",
        "invocation": {"file": "acehack", "args": ["-s", "-v", "all"]},
        "successMarker": "Cannot find any entries for all",
    },
}], matching

before = snapshot(output)
for path in [output] + list(output.rglob("*")):
    assert not path.lstat().st_mode & 0o222, path

with tempfile.TemporaryDirectory(prefix="acehack-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    caller = temporary / "empty-caller"
    caller.mkdir()

    def environment(root):
        root.mkdir()
        paths = {name: root / name for name in ("home", "config", "cache", "data", "state", "runtime")}
        for path in paths.values():
            path.mkdir()
        os.chmod(paths["runtime"], 0o700)
        return {
            "HOME": str(paths["home"]), "XDG_CONFIG_HOME": str(paths["config"]),
            "XDG_CACHE_HOME": str(paths["cache"]), "XDG_DATA_HOME": str(paths["data"]),
            "XDG_STATE_HOME": str(paths["state"]), "XDG_RUNTIME_DIR": str(paths["runtime"]),
            "PATH": str(output / "bin"), "TERM": "xterm-256color", "LC_ALL": "C",
        }, paths

    # This exact contract invocation has an otherwise empty score file, so its
    # stdout marker is deterministic and proves the installed wrapper works.
    score_environment, score_paths = environment(temporary / "score")
    import subprocess
    result = subprocess.run([str(launcher), "-s", "-v", "all"], cwd=caller,
                            env=score_environment, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=10, check=True)
    score_lines = [line for line in result.stdout.splitlines() if line]
    assert score_lines.count("Cannot find any entries for all") == 1, result.stdout
    assert (score_paths["data"] / "acehack").is_dir()

    game_environment, game_paths = environment(temporary / "game")

    def start_game(*args):
        pid, terminal = pty.fork()
        if pid == 0:
            os.chdir(caller)
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
            os.execve(str(launcher), [str(launcher), *args], game_environment)
        return pid, terminal

    # Start a real character, move, and save it.  The fixed -u name identifies
    # the save, while this key sequence chooses the legal Rogue/Human/Male/
    # Chaotic tuple deterministically.
    pid, terminal = start_game("-u", "smoke-valkyrie-human-neutral-male")
    transcript = bytearray()
    try:
        transcript.extend(read_until(terminal, (b"n - New game",), 20))
        os.write(terminal, b"n")
        transcript.extend(read_until(terminal, (b"Choose the class",), 8))
        os.write(terminal, b"rHMC.")
        lore = read_until(terminal, (b"--More--",), 20)
        transcript.extend(lore)
        os.write(terminal, b" ")
        if b"Hello smoke" not in lore:
            transcript.extend(read_until(terminal, (b"Hello smoke",), 8))
        os.write(terminal, b"l")
        movement = drain(terminal, 1)
        for _ in range(3):
            transcript.extend(movement)
            if b"--More--" not in movement:
                break
            os.write(terminal, b" ")
            movement = drain(terminal, 1)
        os.write(terminal, b"S")
        transcript.extend(read_until(terminal, (b"Quicksave and exit",), 8))
        os.write(terminal, b"y")
        wait_for_exit(pid, 12, bytes(transcript))
    finally:
        os.close(terminal)

    user_state = game_paths["data"] / "acehack"
    assert user_state.is_dir() and any(user_state.iterdir()), list(user_state.iterdir())
    assert (user_state / "dumps").is_dir()

    # A second real launch restores that save, then quits cleanly.
    # The first -u value is a role-selection shorthand and is normalized to
    # the player name "smoke".  Omit it here so Continue can select that save.
    pid, terminal = start_game()
    transcript = bytearray()
    try:
        transcript.extend(read_until(terminal, (b"c - Continue game",), 20))
        os.write(terminal, b"c")
        restored = read_until(terminal, (b"Restoring save file",), 20)
        transcript.extend(restored)
        restored = drain(terminal, 1)
        for _ in range(3):
            transcript.extend(restored)
            if b"--More--" not in restored:
                break
            os.write(terminal, b" ")
            restored = drain(terminal, 1)
        # AceHack binds uppercase Q to quiver; the safe quit command is the
        # upstream extended command and asks for confirmation before deleting
        # the restored save.
        os.write(terminal, b"#quit\n")
        transcript.extend(read_until(terminal, (b"Really abandon this game",), 8))
        os.write(terminal, b"y")
        finished = drain(terminal, 1)
        for _ in range(6):
            transcript.extend(finished)
            if b"--More--" in finished:
                os.write(terminal, b" ")
            elif b"Do you want your possessions identified?" in finished:
                os.write(terminal, b"n")
            else:
                break
            finished = drain(terminal, 1)
        wait_for_exit(pid, 12, bytes(transcript))
    finally:
        os.close(terminal)

    assert not any(caller.iterdir()), list(caller.iterdir())
    for name in ("home", "config", "cache", "state", "runtime"):
        assert not any(game_paths[name].iterdir()), (name, list(game_paths[name].iterdir()))

assert snapshot(output) == before, "package output changed during smoke"
PY
