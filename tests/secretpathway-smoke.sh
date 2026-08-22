#!/bin/sh
# Exercise SecretPathway's installed launcher against a loopback fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [secretpathway-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    secretpathway_out=$1
else
    secretpathway_out=$($guix_bin build -L "$channel_dir" secretpathway)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$secretpathway_out/bin/secretpathway"
test -f "$secretpathway_out/share/java/secretpathway.jar"
test -f "$secretpathway_out/share/applications/secretpathway.desktop"
xvfb_out=$($guix_bin build xvfb-run)
test -x "$xvfb_out/bin/xvfb-run"

"$python_out/bin/python3" - \
    "$secretpathway_out" "$xvfb_out/bin/xvfb-run" <<'PY'
import os
import pathlib
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb_run = sys.argv[2]


with tempfile.TemporaryDirectory(prefix="secretpathway-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    home.mkdir()
    config.mkdir()
    data.mkdir()

    # The only endpoint supplied to the client is this loopback listener.  No
    # public MUD hostname or credential is present anywhere in the smoke.
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(12)
    mud_port = mud.getsockname()[1]

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(config),
            "XDG_DATA_HOME": str(data),
            "LC_ALL": "C.UTF-8",
        }
    )
    process = subprocess.Popen(
        [
            xvfb_run,
            "-a",
            str(out / "bin" / "secretpathway"),
            "--version",
            "--hostname",
            "127.0.0.1",
            "--port",
            str(mud_port),
        ],
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    peer = None
    stdout = ""
    stderr = ""
    try:
        peer, address = mud.accept()
        if address[0] != "127.0.0.1":
            raise AssertionError(address)
        peer.settimeout(3)
        # Offer Telnet ECHO.  SecretPathway should actively refuse it with
        # IAC DONT ECHO, proving that the Telnet protocol layer ran rather
        # than merely accepting a TCP socket.
        peer.sendall(b"\xff\xfb\x01")
        response = peer.recv(3)
        if response != b"\xff\xfe\x01":
            raise AssertionError("unexpected Telnet response: %r" % response)
        peer.sendall(b"SecretPathway loopback smoke\r\n")
        time.sleep(0.75)
        if process.poll() is not None:
            raise RuntimeError("SecretPathway exited before GUI/network smoke")
    finally:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
        if peer is not None:
            peer.close()
        mud.close()
        stdout = process.stdout.read()
        stderr = process.stderr.read()

    if process.returncode not in (0, -signal.SIGTERM, 143):
        raise RuntimeError(
            "SecretPathway failed (return code %s): %s"
            % (process.returncode, stderr)
        )
    if "Version 1.0" not in stdout:
        raise AssertionError(stdout)
    if "Exception in thread" in stderr or "Desktop API is not supported" in stderr:
        raise AssertionError(stderr)
    if not (home / ".java" / ".userPrefs").is_dir():
        raise AssertionError("Java preferences were not written under fresh HOME")

print(
    "secretpathway fake-MUD smoke passed: version, fresh HOME, "
    "Swing startup, and loopback Telnet connection"
)
PY
