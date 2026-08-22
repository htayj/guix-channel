#!/bin/sh
# Exercise the installed KildClient launcher and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [kildclient-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    kildclient_out=$1
else
    kildclient_out=$($guix_bin build -L "$channel_dir" kildclient)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$kildclient_out/bin/kildclient"
test -f "$kildclient_out/share/kildclient/kildclient.pl"
test -f "$kildclient_out/share/kildclient/kildclient.hlp"
xvfb_out=$($guix_bin build xvfb-run)
test -x "$xvfb_out/bin/xvfb-run"

"$python_out/bin/python3" - "$kildclient_out" "$xvfb_out/bin/xvfb-run" <<'PY'
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


with tempfile.TemporaryDirectory(prefix="kildclient-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    home.mkdir()
    config.mkdir()
    data.mkdir()

    # KildClient accepts WORLD as host:port.  The server never leaves the
    # loopback interface and sends no credentials or public-network traffic.
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(8)
    mud_port = mud.getsockname()[1]

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(config),
            "XDG_DATA_HOME": str(data),
            "LC_ALL": "C.UTF-8",
            # The installed wrapper, not the caller, must expose JSON.pm.
            "PERL5LIB": "",
        }
    )
    process = subprocess.Popen(
        [
            xvfb_run,
            "-a",
            str(out / "bin" / "kildclient"),
            "--config",
            str(config),
            f"127.0.0.1:{mud_port}",
        ],
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    peer = None
    stderr = ""
    try:
        peer, _ = mud.accept()
        peer.sendall(b"KildClient smoke banner\r\n")
        # A connection proves command-line world creation reached the network
        # loop.  Keep the peer open while the GTK main loop processes it.
        time.sleep(0.5)
    finally:
        if peer is not None:
            peer.close()
        mud.close()
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
        stderr = process.stderr.read()

    if process.returncode not in (0, -signal.SIGTERM, 143):
        raise RuntimeError(
            "KildClient failed (return code %s): %s"
            % (process.returncode, stderr)
        )
    if "Can't locate JSON.pm" in stderr:
        raise AssertionError(stderr)
    if "Perl error" in stderr:
        raise AssertionError(stderr)

print("kildclient fake-MUD smoke passed: fresh HOME, GTK startup, JSON, loopback connection")
PY
