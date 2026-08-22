#!/bin/sh
# Exercise MMapper's graphical local proxy only against loopback fixtures.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [mmapper-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    mmapper_out=$1
else
    mmapper_out=$($guix_bin build -L "$channel_dir" --no-grafts mmapper)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"

xorg_server_out=
for candidate in $($guix_bin build xorg-server); do
    if test -x "$candidate/bin/Xvfb"; then
        xorg_server_out=$candidate
        break
    fi
done
test -n "$xorg_server_out"

openssl_out=
for candidate in $($guix_bin build openssl); do
    if test -x "$candidate/bin/openssl"; then
        openssl_out=$candidate
        break
    fi
done
test -n "$openssl_out"

iproute_out=$($guix_bin build iproute2)
if test -x "$iproute_out/bin/ip"; then ip_bin=$iproute_out/bin/ip; else ip_bin=$iproute_out/sbin/ip; fi
test -x "$ip_bin"
unshare_bin=$(command -v unshare)
test -n "$unshare_bin"

test -x "$mmapper_out/bin/mmapper"
test -s "$mmapper_out/share/doc/mmapper/COPYING.txt"
test -s "$mmapper_out/share/doc/mmapper/LICENSE.GLM"
test -s "$mmapper_out/share/doc/mmapper/LICENSE.BOOST"
test -s "$mmapper_out/share/doc/mmapper/LICENSE.FONTS"
test -s "$mmapper_out/share/doc/mmapper/LICENSE.CANTARELL"
grep -q "GNU GENERAL PUBLIC LICENSE" "$mmapper_out/share/doc/mmapper/COPYING.txt"
grep -F '/etc/ssl/certs/ca-certificates.crt' "$mmapper_out/bin/mmapper" >/dev/null

# Use the same unprivileged user and a private network namespace: its sole
# interface is loopback, so this fixture cannot contact a public MUD.
exec "$unshare_bin" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$mmapper_out" "$xorg_server_out/bin/Xvfb" \
    "$ip_bin" "$openssl_out/bin/openssl" <<'PY'
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
xvfb = sys.argv[2]
ip = sys.argv[3]
openssl = sys.argv[4]


def wait_for_connect(listener, label, timeout=12):
    listener.settimeout(timeout)
    try:
        peer, address = listener.accept()
    except TimeoutError as error:
        raise AssertionError(f"MMapper did not connect to {label}") from error
    assert address[0] == "127.0.0.1", address
    return peer


def wait_for_port(port, timeout=12):
    deadline = time.monotonic() + timeout
    last_error = None
    while time.monotonic() < deadline:
        try:
            return socket.create_connection(("127.0.0.1", port), timeout=0.4)
        except OSError as error:
            last_error = error
            time.sleep(0.1)
    raise AssertionError(f"MMapper never opened its loopback proxy: {last_error}")


def recv_until(peer, marker, timeout=8):
    received = bytearray()
    peer.settimeout(0.25)
    deadline = time.monotonic() + timeout
    while marker not in received and time.monotonic() < deadline:
        try:
            chunk = peer.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        received.extend(chunk)
    assert marker in received, bytes(received)
    return bytes(received)


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=8)


with tempfile.TemporaryDirectory(prefix="mmapper-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    runtime = temporary / "runtime"
    work = temporary / "work"
    for directory in (home, config, data, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    ca_certificate = temporary / "ca.pem"
    ca_key = temporary / "ca.key"
    certificate = temporary / "server.pem"
    private_key = temporary / "server.key"
    request = temporary / "server.csr"
    extensions = temporary / "server.ext"
    extensions.write_text(
        "basicConstraints=critical,CA:FALSE\n"
        "keyUsage=critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=serverAuth\n"
        "subjectAltName=IP:127.0.0.1\n",
        encoding="ascii",
    )
    commands = (
        [openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes",
         "-days", "1", "-subj", "/CN=MMapper smoke CA",
         "-addext", "basicConstraints=critical,CA:TRUE",
         "-addext", "keyUsage=critical,keyCertSign,cRLSign",
         "-keyout", str(ca_key), "-out", str(ca_certificate)],
        [openssl, "req", "-new", "-newkey", "rsa:2048", "-nodes",
         "-subj", "/CN=127.0.0.1", "-keyout", str(private_key),
         "-out", str(request)],
        [openssl, "x509", "-req", "-days", "1", "-sha256",
         "-in", str(request), "-CA", str(ca_certificate),
         "-CAkey", str(ca_key), "-CAcreateserial", "-extfile", str(extensions),
         "-out", str(certificate)],
    )
    for command in commands:
        generated = subprocess.run(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, timeout=20)
        assert generated.returncode == 0, generated.stderr.decode("utf-8", "replace")
    display_number = next(
        number for number in range(90, 200)
        if not pathlib.Path(f"/tmp/.X{number}-lock").exists()
        and not pathlib.Path(f"/tmp/.X11-unix/X{number}").exists())
    display_name = f":{display_number}"
    environment = {"HOME": str(home), "XDG_CONFIG_HOME": str(config),
                   "XDG_DATA_HOME": str(data), "XDG_RUNTIME_DIR": str(runtime),
                   "DISPLAY": display_name, "LIBGL_ALWAYS_SOFTWARE": "1",
                   "QT_XCB_GL_INTEGRATION": "xcb_egl", "QT_QPA_PLATFORM": "xcb",
                   "MMAPPER_EXTRA_CA_FILE": str(ca_certificate),
                   "LC_ALL": "C.UTF-8", "PATH": ""}

    subprocess.run([ip, "link", "set", "lo", "up"], check=True)
    links = subprocess.check_output([ip, "-o", "link", "show"], text=True)
    assert [line.split(":", 2)[1].strip().split("@", 1)[0]
            for line in links.splitlines()] == ["lo"], links
    display = subprocess.Popen(
        [xvfb, display_name, "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
        env=environment, cwd=work, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        start_new_session=True)
    time.sleep(0.5)
    assert display.poll() is None, display.stderr.read().decode("utf-8", "replace")

    # A genuine fresh GUI launch must create state outside the store.
    first = subprocess.Popen([str(out / "bin" / "mmapper")], env=environment,
                             cwd=work, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             start_new_session=True)
    try:
        deadline = time.monotonic() + 30
        while not (config / "MUME" / "MMapper2.conf").exists() and time.monotonic() < deadline:
            time.sleep(0.1)
        assert (config / "MUME" / "MMapper2.conf").is_file(), first.poll()
        assert first.poll() is None, first.stderr.read().decode("utf-8", "replace")
    finally:
        stop(first)
    first_run_state = (config / "MUME" / "MMapper2.conf").read_text(encoding="utf-8")
    # Configuration::GeneralSettings::write records this transition.  This
    # proves the empty-map GUI reached normal startup and persisted state,
    # rather than merely launching the proxy with a pre-created configuration.
    assert "Run%20first%20time=false" in first_run_state, first_run_state

    # QSettings uses this INI file on Linux.  Pin both ends of the proxy to
    # loopback and require TLS against a local leaf signed by the smoke-only CA
    # that the client environment explicitly trusts.
    remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    remote.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    remote.bind(("127.0.0.1", 0))
    remote.listen(1)
    remote_port = remote.getsockname()[1]
    local_probe = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    local_probe.bind(("127.0.0.1", 0))
    local_port = local_probe.getsockname()[1]
    local_probe.close()
    settings = config / "MUME" / "MMapper2.conf"
    settings.parent.mkdir(exist_ok=True)
    settings.write_text(
        "[Connection]\n"
        f"Local%20port%20number={local_port}\n"
        f"Remote%20port%20number={remote_port}\n"
        "Server%20name=127.0.0.1\n"
        "TLS%20encryption=true\n"
        "Proxy%20listens%20on%20any%20interface=false\n"
        "Proxy%20connection%20status=true\n"
        "[%General]\n"
        "Run%20first%20time=false\n",
        encoding="utf-8",
    )
    client = None
    mmapper = None
    mmapper_log_stream = None
    server_peer = None
    try:
        mmapper_log = temporary / "mmapper.stderr"
        mmapper_log_stream = mmapper_log.open("wb")
        mmapper = subprocess.Popen(
            [str(out / "bin" / "mmapper")],
            env=environment,
            cwd=work,
            stdout=subprocess.DEVNULL,
            stderr=mmapper_log_stream,
            start_new_session=True,
        )
        client = wait_for_port(local_port)
        # 0.0.0.0 routes to loopback locally, so inspect the kernel listener
        # table instead: the proxy must bind exactly 127.0.0.1, never INADDR_ANY.
        port_hex = f"{local_port:04X}"
        listeners = pathlib.Path("/proc/net/tcp").read_text()
        assert f"0100007F:{port_hex}" in listeners, listeners
        assert f"00000000:{port_hex}" not in listeners, listeners
        accepted = wait_for_connect(remote, "the fake TLS MUD")
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(certfile=certificate, keyfile=private_key)
        server_peer = context.wrap_socket(accepted, server_side=True)
        server_peer.settimeout(5)
        client.settimeout(5)
        # QSslSocket's handshake completes before MMapper's queued encrypted
        # callback finishes connecting its proxy pipeline.  Synchronize on the
        # application's own connection event before sending MUD data.
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            mmapper_log_stream.flush()
            if "mud socket connected" in mmapper_log.read_text(
                    encoding="utf-8", errors="replace"):
                break
            time.sleep(0.05)
        else:
            raise AssertionError(mmapper_log.read_text(
                encoding="utf-8", errors="replace"))
        banner = b"MAPPER-SMOKE-BANNER\r\n"
        server_peer.sendall(banner)
        forwarded = recv_until(client, banner)
        assert b"ENCRYPTION WARNING" not in forwarded, forwarded
        command = b"look\r\n"
        client.sendall(command)
        recv_until(server_peer, command)
        # The application has persisted its settings only under fresh XDG
        # directories; neither executable nor packaged docs are writable.
        deadline = time.monotonic() + 5
        while not settings.exists() and time.monotonic() < deadline:
            time.sleep(0.1)
        assert settings.is_file(), list(config.rglob("*"))
        assert not any(out.rglob("MMapper2.conf"))
        mmapper_log_stream.flush()
        assert "onPeerVerifyError" not in mmapper_log.read_text(
            encoding="utf-8", errors="replace")
    finally:
        if client:
            client.close()
        if server_peer:
            server_peer.close()
        remote.close()
        if mmapper:
            stop(mmapper)
        if mmapper_log_stream:
            mmapper_log_stream.close()
        stop(display)

print("mmapper smoke passed: fresh XDG state, loopback-only listener, "
      "verified local TLS, and bidirectional proxy data")
PY
