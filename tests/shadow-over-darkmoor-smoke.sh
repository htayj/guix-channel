#!/bin/sh
# Exercise the installed terminal game in an isolated HOME and XDG state tree.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [shadow-over-darkmoor-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    darkmoor_out=$1
else
    darkmoor_out=$($guix_bin build -L . --no-grafts shadow-over-darkmoor)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"

test -x "$darkmoor_out/bin/shadow-over-darkmoor"
test -s "$darkmoor_out/share/java/shadow-over-darkmoor.jar"
test -s "$darkmoor_out/share/doc/shadow-over-darkmoor/LICENSE"
test -s "$darkmoor_out/share/doc/shadow-over-darkmoor/README.md"
test -s "$darkmoor_out/share/doc/shadow-over-darkmoor/CHANGELOG.md"
test -s "$darkmoor_out/share/doc/shadow-over-darkmoor/clojure-runtime-notices/readme.txt"
test -s "$darkmoor_out/share/doc/shadow-over-darkmoor/clojure-runtime-notices/epl-v10.html"
test ! -e "$darkmoor_out/share/doc/shadow-over-darkmoor/.DS_Store"
test -z "$(find "$darkmoor_out/share/doc/shadow-over-darkmoor" \
    -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print -quit)"
grep -F 'Eclipse Public License - v 2.0' \
    "$darkmoor_out/share/doc/shadow-over-darkmoor/LICENSE" >/dev/null
grep -F 'asciiart.eu' "$darkmoor_out/share/doc/shadow-over-darkmoor/README.md" >/dev/null
grep -F 'Text To Ascii Art Generator' \
    "$darkmoor_out/share/doc/shadow-over-darkmoor/README.md" >/dev/null
grep -F 'ASM' \
    "$darkmoor_out/share/doc/shadow-over-darkmoor/clojure-runtime-notices/readme.txt" >/dev/null

# There are no upstream network features.  Make the normal network namespace
# unavailable to the game when the kernel permits it.  On kernels that deny
# unprivileged namespaces, the Python proof below also rejects network APIs in
# every packaged application source entry and supplies only closed-loopback
# proxy endpoints.
if test "${DARKMOOR_SMOKE_IN_NETNS:-}" != 1; then
    ip_bin=$(command -v ip || true)
    if test -n "$ip_bin" && unshare --user --map-root-user --net --fork true; then
        exec env DARKMOOR_SMOKE_IN_NETNS=1 \
            GUIX="$guix_bin" \
            unshare --user --map-root-user --net --fork \
            "$0" "$darkmoor_out"
    fi
fi

"$python_out/bin/python3" - "$darkmoor_out" <<'PY'
import fcntl
import hashlib
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
import zipfile


out = pathlib.Path(sys.argv[1])
jar = out / "share/java/shadow-over-darkmoor.jar"


def output_snapshot(root):
    """Record package-output metadata and bytes before executing its wrapper."""
    result = []
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        if path.is_file():
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
        else:
            digest = None
        result.append((str(path.relative_to(root)), status.st_mode,
                       status.st_size, status.st_mtime_ns, digest))
    return result


with zipfile.ZipFile(jar) as archive:
    names = archive.namelist()
    manifest = archive.read("META-INF/MANIFEST.MF").decode("utf-8")
    resources = [name for name in names if name.startswith("resources/")
                 and name.endswith(".txt")]
    sources = [name for name in names if name.startswith("darkmoor/")
               and name.endswith(".clj")]
    assert "Main-Class: darkmoor.core" in manifest, manifest
    assert len(resources) == 22, resources
    assert len(sources) == 19, sources
    # The program is wholly terminal-local; ensure no application namespace
    # introduces a network API before the isolated PTY launch.
    for name in sources:
        source = archive.read(name).decode("utf-8")
        assert "java.net" not in source and "http" not in source, name


def read_terminal(fd, timeout):
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


def read_until(fd, marker, timeout):
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
        if marker in data:
            return bytes(data)
    raise AssertionError(f"did not observe terminal marker {marker!r}: "
                         + data.decode("utf-8", "replace")[-4000:])


def wait_exit(pid, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        finished, status = os.waitpid(pid, os.WNOHANG)
        if finished:
            assert os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0, status
            return
        time.sleep(0.05)
    os.kill(pid, signal.SIGTERM)
    os.waitpid(pid, 0)
    raise AssertionError("Shadow Over Darkmoor did not exit after q")


before = output_snapshot(out)
with tempfile.TemporaryDirectory(prefix="shadow-over-darkmoor-smoke-") as tmp:
    temporary = pathlib.Path(tmp)
    home = temporary / "home"
    state_home = temporary / "state"
    caller = temporary / "empty-caller"
    home.mkdir()
    state_home.mkdir()
    caller.mkdir()

    environment = {
        "HOME": str(home),
        "XDG_STATE_HOME": str(state_home),
        "PATH": "",
        "TERM": "xterm-256color",
        "LC_ALL": "C.UTF-8",
        # A fallback for hosts where an unprivileged network namespace is
        # unavailable.  The application itself has no network API.
        "ALL_PROXY": "http://127.0.0.1:9",
        "HTTP_PROXY": "http://127.0.0.1:9",
        "HTTPS_PROXY": "http://127.0.0.1:9",
        "NO_PROXY": "*",
    }
    pid, terminal = pty.fork()
    if pid == 0:
        os.chdir(caller)
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
        os.execve(str(out / "bin/shadow-over-darkmoor"),
                  [str(out / "bin/shadow-over-darkmoor")], environment)

    transcript = bytearray()
    try:
        # Drive the actual terminal state machine, observing each prompt so
        # input cannot be consumed by an earlier pause on a slower host.
        transcript.extend(read_until(terminal, b"Hit ENTER to continue.", 6))
        os.write(terminal, b"\n")
        transcript.extend(read_until(terminal, b"Hit ENTER to continue.", 6))
        os.write(terminal, b"\n")
        transcript.extend(read_until(terminal, b"q  Quit the game", 6))
        os.write(terminal, b"q\n")
        transcript.extend(read_terminal(terminal, 3))
        wait_exit(pid, 5)
    finally:
        os.close(terminal)

    text = transcript.decode("utf-8", "replace")
    assert "Casper Rutz" in text, text[-4000:]
    assert "Your mission is simple: survive." in text, text[-4000:]
    assert "COMMANDS" in text, text[-4000:]
    resources_dir = state_home / "shadow-over-darkmoor/resources"
    assert resources_dir.is_dir()
    assert len(list(resources_dir.glob("*.txt"))) == 22
    assert not any(caller.iterdir()), list(caller.iterdir())
    assert not any(home.iterdir()), list(home.iterdir())

assert output_snapshot(out) == before, "the package output changed during smoke"
PY
