#!/bin/sh
# Exercise KMuddy against a loopback-only fake MUD under a fresh KDE home.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [kmuddy-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    kmuddy_out=$1
else
    kmuddy_out=$($guix_bin build -L "$channel_dir" kmuddy)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
xvfb_out=$($guix_bin build xvfb-run)
binutils_out=$($guix_bin build binutils)

test -x "$kmuddy_out/bin/kmuddy"
test -f "$kmuddy_out/share/doc/kmuddy/LICENSE"
test -f "$kmuddy_out/share/doc/kmuddy/COPYING.LIB"
test -n "$python_out"
test -x "$python_out/bin/python3"
test -x "$xvfb_out/bin/xvfb-run"
test -x "$binutils_out/bin/readelf"

"$binutils_out/bin/readelf" -d "$kmuddy_out/bin/kmuddy" | grep -F 'libmxp.so.0'

"$python_out/bin/python3" - "$kmuddy_out" "$xvfb_out/bin/xvfb-run" <<'PY'
import os
import pathlib
import signal
import socket
import subprocess
import sys
import tempfile
import time
import zlib


out = pathlib.Path(sys.argv[1])
xvfb_run = sys.argv[2]


def receive_until(peer, required, timeout=5):
    """Collect bytes until every required protocol fragment is observed."""
    received = b""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        peer.settimeout(max(0.1, deadline - time.monotonic()))
        try:
            chunk = peer.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        received += chunk
        if all(fragment in received for fragment in required):
            break
    return received


with tempfile.TemporaryDirectory(prefix="kmuddy-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    cache = temporary / "cache"
    for directory in (home, config, data, cache):
        directory.mkdir()

    # The peer is loopback-only.  It observes KMuddy's telnet negotiation and
    # sends visible text plus an MXP element; no public MUD is contacted.
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(15)
    port = mud.getsockname()[1]

    profiles = home / ".kmuddy"
    profile = profiles / "profile1"
    profile.mkdir(parents=True)
    (profiles / "profiles.xml").write_text(
        '<?xml version="1.0"?><profiles version="1.0">'
        '<profile id="profile1" name="Loopback smoke"/>'
        '</profiles>', encoding="utf-8"
    )
    (profile / "settings.xml").write_text(
        '<?xml version="1.0"?><profile version="1.0">'
        '<setting type="string" name="server" value="127.0.0.1"/>'
        f'<setting type="integer" name="port" value="{port}"/>'
        '<setting type="integer" name="use-mxp" value="3"/>'
        '</profile>', encoding="utf-8"
    )
    # This is the current source's documented KConfig serialization, derived
    # from cGlobalSettings::load(), rather than an invented command argument.
    (config / "kmuddyrc").write_text(
        '[Version Info]\nVersion=1\n\n[String values]\n'
        'auto-connect=profile1\n'
        f'profile-path={profiles}\n', encoding="utf-8"
    )

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(config),
            "XDG_DATA_HOME": str(data),
            "XDG_CACHE_HOME": str(cache),
            "LC_ALL": "C.UTF-8",
        }
    )
    process = subprocess.Popen(
        [xvfb_run, "-a", str(out / "bin" / "kmuddy")],
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    peer = None
    negotiation = b""
    mxp_response = b""
    try:
        peer, address = mud.accept()
        if address[0] != "127.0.0.1":
            raise AssertionError("unexpected non-loopback peer: %r" % (address,))
        # Offer MCCP2 and MXP, and require the client to accept both options.
        peer.sendall(b"\xff\xfb\x56\xff\xfb\x5b")
        negotiation = receive_until(peer, (b"\xff\xfd\x56", b"\xff\xfd\x5b"))
        if b"\xff\xfd\x56" not in negotiation:
            raise AssertionError("KMuddy did not accept MCCP2: %r" % negotiation)
        if b"\xff\xfd\x5b" not in negotiation:
            raise AssertionError("KMuddy did not accept MXP: %r" % negotiation)

        # Begin MCCP2 compression, then enter MXP open mode and request the
        # protocol version.  KMuddy must emit the observable MXP reply.
        peer.sendall(
            b"\xff\xfa\x56\xff\xf0"
            + zlib.compress(b"\x1b[1z<VERSION>\r\n")
        )
        mxp_response = receive_until(peer, (b"<VERSION MXP=",))
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
        raise RuntimeError("KMuddy failed: %s" % stderr)
    if b"<VERSION MXP=" not in mxp_response:
        raise AssertionError("KMuddy did not answer the MXP VERSION request: %r" % mxp_response)
    if not (profiles / "profile1" / "settings.xml").is_file():
        raise AssertionError("KMuddy profile state was not kept under HOME")
    if not (config / "kmuddyrc").is_file():
        raise AssertionError("KMuddy configuration was not kept outside the store")

print("kmuddy fake-MUD smoke passed: fresh HOME, Xvfb, MCCP2, MXP VERSION, loopback")
PY
