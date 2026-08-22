#!/bin/sh
# Exercise the installed TinyFugue launcher and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [tinyfugue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    tinyfugue_out=$1
else
    tinyfugue_out=$($guix_bin build -L "$channel_dir" \
        --no-grafts --no-substitutes tinyfugue)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$tinyfugue_out/bin/tf"
test -f "$tinyfugue_out/share/tf-lib/stdlib.tf"
test -f "$tinyfugue_out/share/doc/tinyfugue/COPYING"
test -f "$tinyfugue_out/share/man/man1/tf.1.zst"

"$python_out/bin/python3" - "$tinyfugue_out" <<'PY'
import os
import pathlib
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])


with tempfile.TemporaryDirectory(prefix="tinyfugue-smoke-") as temporary:
    home = pathlib.Path(temporary) / "home"
    home.mkdir()
    # Do not inherit TinyFugue library/startup settings or unrelated caller
    # state.  In particular, TFLIBRARY/TFLIBDIR could otherwise replace the
    # packaged library with arbitrary code before the loopback connection.
    environment = {
        "HOME": str(home),
        "TERM": "dumb",
        "LC_ALL": "C",
        "PATH": "",
    }

    version = subprocess.run(
        [str(out / "bin" / "tf"), "-?"],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=5,
    )
    assert version.returncode == 1, version.returncode
    assert "Usage:" in version.stdout, version.stdout
    assert "TinyFugue version 5.2.2" in version.stdout, version.stdout

    # The fake MUD is bound only to loopback.  It receives one normal client
    # line and sends a banner; no public MUD, DNS lookup, or credentials are
    # involved.
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(8)
    port = listener.getsockname()[1]
    process = subprocess.Popen(
        [
            str(out / "bin" / "tf"),
            "-f",
            "-v",
            "-l",
            "-q",
            "127.0.0.1",
            str(port),
        ],
        env=environment,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    peer = None
    received = b""
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(8)
        peer.sendall(b"TinyFugue local smoke banner\r\n")

        process.stdin.write(b"look\n")
        process.stdin.flush()
        deadline = time.monotonic() + 8
        while b"look\r\n" not in received and time.monotonic() < deadline:
            try:
                chunk = peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            received += chunk
        assert b"look\r\n" in received, received

        # Ask the client to leave cleanly.  The timeout/termination fallback
        # below ensures a broken remote peer cannot leave a test process.
        process.stdin.write(b"/quit\n")
        process.stdin.flush()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)

    stdout = process.stdout.read().decode("utf-8", "replace")
    stderr = process.stderr.read().decode("utf-8", "replace")
    assert process.returncode in (0, -signal.SIGTERM, 143), (
        process.returncode,
        stderr,
    )
    assert "TinyFugue local smoke banner" in stdout, stdout
    assert not list(home.iterdir()), list(home.iterdir())

print(
    "tinyfugue fake-MUD smoke passed: version, fresh HOME, and "
    "loopback protocol"
)
PY
