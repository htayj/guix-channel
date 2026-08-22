#!/bin/sh
# Exercise the installed Trebuchet launcher and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [trebuchet-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    trebuchet_out=$1
else
    trebuchet_out=$($guix_bin build -L "$channel_dir" \
        --no-grafts --no-substitutes trebuchet)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
xvfb_out=$($guix_bin build xvfb-run)
test -x "$xvfb_out/bin/xvfb-run"
openssl_out=
for candidate in $($guix_bin build openssl); do
    if test -x "$candidate/bin/openssl"; then
        openssl_out=$candidate
        break
    fi
done
test -n "$openssl_out"
test -x "$trebuchet_out/bin/treb"
test -f "$trebuchet_out/libexec/trebuchet/Trebuchet.tcl"
test -f "$trebuchet_out/libexec/trebuchet/LICENSE"
test -f "$trebuchet_out/libexec/trebuchet/cacerts/ca-bundle.crt"

unset PYTHONOPTIMIZE
"$python_out/bin/python3" - "$trebuchet_out" \
    "$xvfb_out/bin/xvfb-run" "$openssl_out/bin/openssl" <<'PY'
import os
import pathlib
import signal
import socket
import ssl
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb_run = sys.argv[2]
openssl = sys.argv[3]


def clean_environment(home, remote_port):
    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "LC_ALL": "C.UTF-8",
            # The wrapper must provide both Tcl library directories itself.
            "TCLLIBPATH": "",
            "TREB_REMOTE_PORT": str(remote_port),
        }
    )
    for name in (
        "TREB_ROOT_DIR",
        "http_proxy",
        "https_proxy",
        "all_proxy",
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "ALL_PROXY",
    ):
        environment.pop(name, None)
    return environment


def loopback_port():
    probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
    probe.close()
    return port


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


def loopback_listener_addresses(port):
    addresses = []
    for proc_file in ("/proc/net/tcp", "/proc/net/tcp6"):
        proc_path = pathlib.Path(proc_file)
        if not proc_path.exists():
            continue
        for line in proc_path.read_text(encoding="ascii").splitlines()[1:]:
            fields = line.split()
            if len(fields) < 4 or fields[3] != "0A":
                continue
            address, port_hex = fields[1].split(":")
            if int(port_hex, 16) == port:
                addresses.append(address.upper())
    return addresses


def require_loopback_listener(port):
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        addresses = loopback_listener_addresses(port)
        if addresses:
            wildcard = {"00000000", "0" * 32}
            assert not wildcard.intersection(addresses), (port, addresses)
            return addresses
        time.sleep(0.05)
    raise AssertionError(("remote control listener not found", port))


with tempfile.TemporaryDirectory(prefix="trebuchet-smoke-") as temporary:
    temporary = pathlib.Path(temporary)

    # First prove that the installed launcher reaches the pinned application's
    # Tcl/Tk startup and reports its upstream revision, without a caller
    # supplied Tcl library path or configuration directory.
    version_home = temporary / "version-home"
    version_home.mkdir()
    version = subprocess.run(
        [xvfb_run, "-a", str(out / "bin" / "treb"), "--tkshell"],
        env=clean_environment(version_home, loopback_port()),
        input='puts "$treb_name $treb_version"\nexit\n',
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
        timeout=15,
    )
    assert version.returncode == 0, (version.returncode, version.stderr)
    assert "Trebuchet Tk 1.082" in version.stdout, version.stdout
    assert not list(version_home.iterdir()), list(version_home.iterdir())

    # The fake MUD and Trebuchet's remote-control socket both bind only to
    # loopback.  The remote --connect option creates a temporary world without
    # a character or password, so this test never sends credentials.
    home = temporary / "home"
    home.mkdir()
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(10)
    mud_port = mud.getsockname()[1]
    remote_port = loopback_port()
    (home / ".trebtkrc").write_text(
        "/prefs:set hide_splash 1\n"
        "/prefs:set autoup_firsttime 0\n"
        "/prefs:set autoupdate_check 0\n"
        "/prefs:set startup_script "
        "{after 1000 {/socket:sendln_raw World.1 look}}\n",
        encoding="utf-8",
    )

    process = subprocess.Popen(
        [
            xvfb_run,
            "-a",
            str(out / "bin" / "treb"),
            "--connect",
            "127.0.0.1",
            str(mud_port),
        ],
        env=clean_environment(home, remote_port),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    require_loopback_listener(remote_port)
    peer = None
    received = b""
    try:
        peer, address = mud.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(1)
        peer.sendall(b"Trebuchet local smoke banner\r\n")
        deadline = time.monotonic() + 10
        while b"look\r\n" not in received and time.monotonic() < deadline:
            try:
                chunk = peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            received += chunk
    finally:
        if peer is not None:
            peer.close()
        mud.close()
        stop_process(process)

    stdout = process.stdout.read()
    stderr = process.stderr.read()
    assert process.returncode in (0, -signal.SIGTERM, 143), (
        process.returncode,
        stderr,
    )
    assert b"look\r\n" in received, received
    # The application owns its mutable cache under HOME, never beneath its
    # read-only Guix runtime root.  The cache is expected after GUI startup.
    assert (home / ".trebtk-web-cache").is_dir(), list(home.iterdir())
    assert (home / ".trebtkrc").is_file()

    # A self-signed certificate must be rejected before the configured
    # character/password can be sent.  This exercises the TLS path against a
    # local-only endpoint and deliberately uses a certificate whose issuer is
    # absent from Guix's current CA bundle.
    tls_home = temporary / "tls-home"
    tls_home.mkdir()
    cert = temporary / "wrong-cert.pem"
    key = temporary / "wrong-key.pem"
    subprocess.run(
        [
            openssl,
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            str(key),
            "-out",
            str(cert),
            "-subj",
            "/CN=wrong.local",
            "-days",
            "1",
        ],
        env=clean_environment(tls_home, loopback_port()),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
        timeout=15,
    )
    tls_listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tls_listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tls_listener.bind(("127.0.0.1", 0))
    tls_listener.listen(1)
    tls_listener.settimeout(10)
    tls_port = tls_listener.getsockname()[1]
    (tls_home / ".trebtkrc").write_text(
        "/prefs:set hide_splash 1\n"
        "/prefs:set autoup_firsttime 0\n"
        "/prefs:set autoupdate_check 0\n"
        "/prefs:set startup_script {"
        "/world:add World.1 127.0.0.1 "
        f"{tls_port} smoke-user smoke-pass -secure 1 -temp 1\n"
        "/world:connect World.1}\n",
        encoding="utf-8",
    )
    tls_process = subprocess.Popen(
        [xvfb_run, "-a", str(out / "bin" / "treb")],
        env=clean_environment(tls_home, loopback_port()),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    tls_peer = None
    tls_received = b""
    tls_rejected = False
    try:
        tls_peer, tls_address = tls_listener.accept()
        assert tls_address[0] == "127.0.0.1", tls_address
        tls_peer.settimeout(10)
        tls_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        tls_context.load_cert_chain(certfile=cert, keyfile=key)
        try:
            tls_peer = tls_context.wrap_socket(tls_peer, server_side=True)
            tls_peer.settimeout(2)
            try:
                tls_received = tls_peer.recv(4096)
            except (ConnectionResetError, ssl.SSLError, socket.timeout):
                pass
        except ssl.SSLError:
            tls_rejected = True
    finally:
        if tls_peer is not None:
            tls_peer.close()
        tls_listener.close()
        stop_process(tls_process)
    tls_process.stdout.read()
    tls_process.stderr.read()
    assert tls_rejected, tls_received
    assert not any(
        credential in tls_received for credential in (b"smoke-user", b"smoke-pass")
    ), tls_received

    # STARTTLS is a separate downgrade-sensitive path.  Complete the local
    # Telnet STARTTLS negotiation, then feed an invalid TLS record.  The
    # client must not remove TLS and answer a subsequent plaintext login
    # prompt with the configured credentials.
    starttls_home = temporary / "starttls-home"
    starttls_home.mkdir()
    starttls_listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    starttls_listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    starttls_listener.bind(("127.0.0.1", 0))
    starttls_listener.listen(1)
    starttls_listener.settimeout(10)
    starttls_port = starttls_listener.getsockname()[1]
    (starttls_home / ".trebtkrc").write_text(
        "/prefs:set hide_splash 1\n"
        "/prefs:set autoup_firsttime 0\n"
        "/prefs:set autoupdate_check 0\n"
        "/prefs:set startup_script {"
        "/world:add World.1 127.0.0.1 "
        f"{starttls_port} smoke-user smoke-pass -temp 1\n"
        "/world:connect World.1}\n",
        encoding="utf-8",
    )
    starttls_process = subprocess.Popen(
        [xvfb_run, "-a", str(out / "bin" / "treb")],
        env=clean_environment(starttls_home, loopback_port()),
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
    )
    starttls_peer = None
    starttls_received = b""
    starttls_client_hello = False
    try:
        starttls_peer, starttls_address = starttls_listener.accept()
        assert starttls_address[0] == "127.0.0.1", starttls_address
        starttls_peer.settimeout(1)
        starttls_peer.sendall(b"\xff\xfd\x2e")  # IAC DO STARTTLS.
        deadline = time.monotonic() + 5
        while b"\xff\xfb\x2e" not in starttls_received and time.monotonic() < deadline:
            try:
                chunk = starttls_peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            starttls_received += chunk
        assert b"\xff\xfb\x2e" in starttls_received, starttls_received
        starttls_peer.sendall(b"\xff\xfa\x2e\x01\xff\xf0")  # FOLLOWS.
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                chunk = starttls_peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            starttls_received += chunk
            if b"\x16\x03" in chunk:
                starttls_client_hello = True
                break
        assert starttls_client_hello, starttls_received
        try:
            starttls_peer.sendall(b"this is not a TLS record\r\n")
        except (ConnectionResetError, BrokenPipeError):
            pass
        time.sleep(0.5)
        try:
            starttls_peer.sendall(b"login:\r\n")
        except (ConnectionResetError, BrokenPipeError):
            pass
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                chunk = starttls_peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            starttls_received += chunk
    finally:
        if starttls_peer is not None:
            starttls_peer.close()
        starttls_listener.close()
        stop_process(starttls_process)
    starttls_process.stdout.read()
    starttls_process.stderr.read()
    assert b"smoke-user" not in starttls_received, starttls_received
    assert b"smoke-pass" not in starttls_received, starttls_received

print("trebuchet fake-MUD smoke passed: version, fresh HOME, Tcl/Tk, and loopback protocol")
print("trebuchet TLS smoke passed: wrong certificate rejected before credentials")
print("trebuchet STARTTLS smoke passed: handshake failure did not downgrade")
PY
