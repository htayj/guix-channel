#!/bin/sh
# Exercise the installed GoMud terminal client against a loopback-only fake
# MUD.  The client is a terminal application; no X server or public endpoint
# is involved.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [go-mud-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    go_mud_out=$1
else
    go_mud_out=$($guix_bin build -L "$channel_dir" --no-grafts go-mud)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$go_mud_out/bin/go-mud"
test -s "$go_mud_out/share/doc/go-mud/LICENSE"
test -s "$go_mud_out/share/doc/go-mud/README.md"
test -s "$go_mud_out/share/doc/go-mud/config-example.json"
test -s "$go_mud_out/share/doc/go-mud/config-example.yaml"
test -s "$go_mud_out/share/doc/go-mud/licenses/go-github-com-flw-cn-printer-LICENSE/LICENSE"
test -s "$go_mud_out/share/doc/go-mud/licenses/go-github-com-flw-cn-go-smartconfig-LICENSE/LICENSE"

"$python_out/bin/python3" - "$go_mud_out" <<'PY'
import os
import pathlib
import pty
import re
import select
import signal
import socket
import fcntl
import struct
import termios
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])


def read_fd(fd, timeout):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        remaining = max(0.0, deadline - time.monotonic())
        ready, _, _ = select.select([fd], [], [], min(0.2, remaining))
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


def read_socket_until(sock, expected, timeout):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline and expected not in data:
        remaining = max(0.0, deadline - time.monotonic())
        ready, _, _ = select.select([sock], [], [], min(0.2, remaining))
        if not ready:
            continue
        chunk = sock.recv(8192)
        if not chunk:
            break
        data.extend(chunk)
    assert expected in data, bytes(data)
    return bytes(data)


def stop_process(process):
    if process.poll() is None:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=5)


with tempfile.TemporaryDirectory(prefix="go-mud-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    work = temporary / "work"
    home.mkdir()
    work.mkdir()

    # Version output must work without a profile, a config file, a terminal,
    # or any ambient HOME state.  smartConfig writes --version to stderr.
    version_environment = {
        "HOME": str(home),
        "PATH": "",
        "LC_ALL": "C.UTF-8",
        "TERM": "dumb",
    }
    version = subprocess.run(
        [str(out / "bin" / "go-mud"), "--version"],
        cwd=work,
        env=version_environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=8,
    )
    assert version.returncode == 0, version
    assert "v0.6.6" in version.stdout, version.stdout
    assert "1970-01-01 00:00:00 UTC" in version.stdout, version.stdout

    # Bind only to loopback.  The endpoint sends a UTF-8 Chinese banner and a
    # Telnet negotiation; it never resolves or contacts a public MUD.
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(8)
    port = listener.getsockname()[1]

    environment = {
        "HOME": str(home),
        "PATH": "",
        "TERM": "xterm-256color",
        "LC_ALL": "C.UTF-8",
    }
    arguments = [
        str(out / "bin" / "go-mud"),
        "-H",
        "127.0.0.1",
        "-P",
        str(port),
        "--mud.encodings",
        "UTF-8",
        "--lua.enable=false",
    ]

    pid, terminal = pty.fork()
    if pid == 0:
        os.chdir(work)
        # tview does not render its content to a zero-sized pseudo-terminal.
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
        os.execve(arguments[0], arguments, environment)

    peer = None
    output = b""
    try:
        peer, _ = listener.accept()
        peer.settimeout(2)
        # Exercise terminal-type negotiation in both directions.  DO TTYPE
        # must elicit WILL TTYPE; TTYPE SEND must then elicit TTYPE IS GoMud.
        # The following line contains non-ASCII UTF-8 bytes and a prompt.
        peer.sendall(bytes((255, 253, 24)))
        read_socket_until(peer, bytes((255, 251, 24)), 4)
        peer.sendall(bytes((255, 250, 24, 1, 255, 240)))
        read_socket_until(peer, bytes((255, 250, 24, 0)) + b"GoMud" + bytes((255, 240)), 4)
        # The completed TTYPE exchange also ensures the UI and receive loop
        # are running before the UTF-8 payload is delivered.
        peer.sendall("中文 UTF-8 GoMud smoke\r\n".encode("utf-8"))
        output += read_fd(terminal, 4)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        _, status = os.waitpid(pid, 0)
        output += read_fd(terminal, 2)
        os.close(terminal)

    # tview redraws individual cells and places cursor-motion bytes between
    # adjacent UTF-8 characters.  Remove those terminal controls before
    # checking the protocol payload rather than assuming one renderer's raw
    # layout.
    plain_output = re.sub(
        rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\([0-9A-Z]", b"", output
    )
    assert "中文 UTF-8 GoMud smoke".encode("utf-8") in plain_output, output[-4000:]
    assert os.WIFEXITED(status) or os.WIFSIGNALED(status), status

print("go-mud fake-MUD smoke passed: deterministic version, fresh HOME, loopback, UTF-8")
PY
