#!/bin/sh
# Exercise the installed KBtin launcher and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [kbtin-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    kbtin_out=$1
else
    kbtin_out=$($guix_bin build -L "$channel_dir" --no-grafts kbtin)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
openssl_out=
for candidate in $($guix_bin build openssl); do
    if test -x "$candidate/bin/openssl"; then
        openssl_out=$candidate
        break
    fi
done
test -n "$openssl_out"
test -x "$kbtin_out/bin/KBtin"
test -x "$kbtin_out/bin/kbtin"
test -f "$kbtin_out/share/kbtin/KBtin_help.gz"
test -f "$kbtin_out/share/man/man6/kbtin.6.zst"
test -f "$kbtin_out/share/doc/kbtin/COPYING"
test -s "$kbtin_out/etc/ssl/certs/ca-certificates.crt"
grep -q "GNU GENERAL PUBLIC LICENSE" "$kbtin_out/share/doc/kbtin/COPYING"

"$python_out/bin/python3" - "$kbtin_out" "$openssl_out/bin/openssl" <<'PY'
import os
import pathlib
import selectors
import signal
import socket
import ssl
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
openssl = sys.argv[2]


def read_until(stream, needle, timeout=8):
    """Read a pipe without blocking forever while waiting for one marker."""
    selector = selectors.DefaultSelector()
    selector.register(stream, selectors.EVENT_READ)
    data = b""
    deadline = time.monotonic() + timeout
    try:
        while needle not in data and time.monotonic() < deadline:
            for key, _ in selector.select(max(0, deadline - time.monotonic())):
                chunk = os.read(key.fd, 4096)
                if not chunk:
                    return data
                data += chunk
    finally:
        selector.close()
    return data


def recv_until(peer, needle, timeout=8):
    data = b""
    deadline = time.monotonic() + timeout
    peer.settimeout(0.2)
    while needle not in data and time.monotonic() < deadline:
        try:
            chunk = peer.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        data += chunk
    return data


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


def run_openssl(environment, *arguments):
    result = subprocess.run(
        [openssl, *[str(argument) for argument in arguments]],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=15,
    )
    assert result.returncode == 0, (
        arguments,
        result.stdout.decode("utf-8", "replace"),
        result.stderr.decode("utf-8", "replace"),
    )


def make_local_certificates(temporary, environment):
    """Create a CA-signed loopback certificate and a wrong self-signed one."""
    ca_key = temporary / "smoke-ca.key"
    ca_cert = temporary / "smoke-ca.crt"
    ca_config = temporary / "smoke-ca.cnf"
    ca_config.write_text(
        "[req]\n"
        "distinguished_name = req_distinguished_name\n"
        "x509_extensions = v3_ca\n"
        "prompt = no\n"
        "[req_distinguished_name]\n"
        "CN = KBtin smoke local CA\n"
        "[v3_ca]\n"
        "basicConstraints = critical,CA:true,pathlen:1\n"
        "keyUsage = critical,keyCertSign,cRLSign\n"
        "subjectKeyIdentifier = hash\n"
        "authorityKeyIdentifier = keyid:always,issuer\n",
        encoding="ascii",
    )
    run_openssl(
        environment,
        "req",
        "-x509",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-keyout",
        ca_key,
        "-out",
        ca_cert,
        "-config",
        ca_config,
        "-days",
        "3650",
        "-sha256",
    )

    server_key = temporary / "smoke-server.key"
    server_csr = temporary / "smoke-server.csr"
    server_cert = temporary / "smoke-server.crt"
    server_config = temporary / "smoke-server.cnf"
    server_config.write_text(
        "[req]\n"
        "distinguished_name = req_distinguished_name\n"
        "req_extensions = v3_req\n"
        "prompt = no\n"
        "[req_distinguished_name]\n"
        "CN = 127.0.0.1\n"
        "[v3_req]\n"
        "subjectAltName = IP:127.0.0.1\n"
        "extendedKeyUsage = serverAuth\n",
        encoding="ascii",
    )
    run_openssl(
        environment,
        "req",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-keyout",
        server_key,
        "-out",
        server_csr,
        "-config",
        server_config,
        "-sha256",
    )
    server_extensions = temporary / "smoke-server.ext"
    server_extensions.write_text(
        "basicConstraints = critical,CA:false\n"
        "keyUsage = critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage = serverAuth\n"
        "subjectAltName = IP:127.0.0.1\n"
        "subjectKeyIdentifier = hash\n"
        "authorityKeyIdentifier = keyid,issuer\n",
        encoding="ascii",
    )
    run_openssl(
        environment,
        "x509",
        "-req",
        "-in",
        server_csr,
        "-CA",
        ca_cert,
        "-CAkey",
        ca_key,
        "-CAcreateserial",
        "-out",
        server_cert,
        "-days",
        "3650",
        "-sha256",
        "-extfile",
        server_extensions,
    )

    wrong_key = temporary / "smoke-wrong.key"
    wrong_cert = temporary / "smoke-wrong.crt"
    wrong_config = temporary / "smoke-wrong.cnf"
    wrong_config.write_text(
        "[req]\n"
        "distinguished_name = req_distinguished_name\n"
        "x509_extensions = v3_wrong\n"
        "prompt = no\n"
        "[req_distinguished_name]\n"
        "CN = 127.0.0.1\n"
        "[v3_wrong]\n"
        "basicConstraints = critical,CA:false\n"
        "keyUsage = critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage = serverAuth\n"
        "subjectAltName = IP:127.0.0.1\n"
        "subjectKeyIdentifier = hash\n",
        encoding="ascii",
    )
    run_openssl(
        environment,
        "req",
        "-x509",
        "-newkey",
        "rsa:2048",
        "-nodes",
        "-keyout",
        wrong_key,
        "-out",
        wrong_cert,
        "-config",
        wrong_config,
        "-days",
        "3650",
        "-sha256",
    )
    return ca_cert, server_cert, server_key, wrong_cert, wrong_key


with tempfile.TemporaryDirectory(prefix="kbtin-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    work = temporary / "work"
    home.mkdir()
    work.mkdir()

    # Keep the client isolated from caller configuration and ambient tools.
    # The fake MUD below binds only to 127.0.0.1 and never performs DNS or
    # public-network I/O.
    environment = {
        "HOME": str(home),
        "PATH": "",
        "TERM": "dumb",
        "LC_ALL": "C.UTF-8",
    }
    version = subprocess.run(
        [str(out / "bin" / "kbtin"), "--version"],
        cwd=work,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=5,
    )
    assert version.returncode == 0, version
    assert version.stdout == "KBtin version 0-20260801\n", version.stdout

    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(8)
    port = listener.getsockname()[1]
    process = None
    peer = None
    stdout = b""
    stderr = b""
    try:
        process = subprocess.Popen(
            [str(out / "bin" / "kbtin"), "-p", "-q"],
            cwd=work,
            env=environment,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
        # Start a session through KBtin's command parser.  Using a numeric
        # loopback address makes an accidental public connection impossible.
        process.stdin.write(f"#ses smoke 127.0.0.1 {port}\n".encode())
        process.stdin.flush()
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address

        # Exercise TELNET negotiation and normal line parsing.
        peer.sendall(bytes((255, 251, 1)) + b"KBtin loopback banner\r\n")
        negotiation = recv_until(peer, bytes((255, 253, 1)))
        assert bytes((255, 253, 1)) in negotiation, negotiation
        stdout = read_until(process.stdout, b"KBtin loopback banner")
        assert b"KBtin loopback banner" in stdout, stdout

        process.stdin.write(b"look\n")
        process.stdin.flush()
        received = recv_until(peer, b"look\r\n")
        assert b"look\r\n" in received, received
        peer.sendall(b"Room: loopback parser smoke\r\n")
        stdout += read_until(process.stdout, b"Room: loopback parser smoke")
        assert b"Room: loopback parser smoke" in stdout, stdout

        # End the session, then close input so the pipe driver exits normally.
        process.stdin.write(b"#end\n")
        process.stdin.flush()
        process.stdin.close()
        process.wait(timeout=5)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        if process is not None:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=5)
            stdout += process.stdout.read()
            stderr = process.stderr.read()

    assert process.returncode in (0, -signal.SIGTERM, 143), (
        process.returncode,
        stderr.decode("utf-8", "replace"),
    )
    assert not list(home.iterdir()), list(home.iterdir())
    assert not list(work.iterdir()), list(work.iterdir())

    # Exercise TLS entirely offline.  The first endpoint uses a private CA
    # supplied through SSL_CERT_FILE, which the package adds to its
    # package-owned Mozilla bundle.  The second endpoint uses a self-signed
    # certificate with the correct loopback name; it must be rejected by the
    # packaged CA trust before any queued session data reaches the server.
    ca_cert, server_cert, server_key, wrong_cert, wrong_key = (
        make_local_certificates(temporary, environment)
    )

    tls_home = temporary / "tls-home"
    tls_work = temporary / "tls-work"
    tls_home.mkdir()
    tls_work.mkdir()
    tls_environment = dict(environment)
    tls_environment["HOME"] = str(tls_home)
    tls_environment["SSL_CERT_FILE"] = str(ca_cert)
    tls_listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tls_listener.bind(("127.0.0.1", 0))
    tls_listener.listen(1)
    tls_listener.settimeout(8)
    tls_port = tls_listener.getsockname()[1]
    tls_process = None
    tls_peer = None
    tls_stdout = b""
    tls_stderr = b""
    tls_received = b""
    try:
        tls_process = subprocess.Popen(
            [str(out / "bin" / "kbtin"), "-p", "-q"],
            cwd=tls_work,
            env=tls_environment,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
        tls_process.stdin.write(
            f"#sslses valid 127.0.0.1 {tls_port} ca\n".encode()
        )
        tls_process.stdin.flush()
        tls_peer, address = tls_listener.accept()
        assert address[0] == "127.0.0.1", address
        tls_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        tls_context.load_cert_chain(certfile=server_cert, keyfile=server_key)
        tls_peer = tls_context.wrap_socket(tls_peer, server_side=True)
        tls_peer.sendall(b"KBtin TLS local CA banner\r\n")
        tls_stdout = read_until(tls_process.stdout, b"KBtin TLS local CA banner")
        assert b"KBtin TLS local CA banner" in tls_stdout, tls_stdout

        tls_process.stdin.write(b"look\n")
        tls_process.stdin.flush()
        tls_received = recv_until(tls_peer, b"look\r\n")
        assert b"look\r\n" in tls_received, tls_received
        tls_peer.sendall(b"TLS valid local CA\r\n")
        tls_stdout += read_until(tls_process.stdout, b"TLS valid local CA")
        assert b"TLS valid local CA" in tls_stdout, tls_stdout

        tls_process.stdin.write(b"#end\n")
        tls_process.stdin.flush()
        tls_process.stdin.close()
        tls_process.wait(timeout=5)
    finally:
        if tls_peer is not None:
            tls_peer.close()
        tls_listener.close()
        if tls_process is not None:
            stop_process(tls_process)
            tls_stdout += tls_process.stdout.read()
            tls_stderr = tls_process.stderr.read()
    assert tls_process is not None
    assert tls_process.returncode in (0, -signal.SIGTERM, 143), (
        tls_process.returncode,
        tls_stderr.decode("utf-8", "replace"),
    )
    assert not list(tls_home.iterdir()), list(tls_home.iterdir())
    assert not list(tls_work.iterdir()), list(tls_work.iterdir())

    wrong_home = temporary / "wrong-tls-home"
    wrong_work = temporary / "wrong-tls-work"
    wrong_home.mkdir()
    wrong_work.mkdir()
    wrong_environment = dict(environment)
    wrong_environment["HOME"] = str(wrong_home)
    wrong_listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    wrong_listener.bind(("127.0.0.1", 0))
    wrong_listener.listen(1)
    wrong_listener.settimeout(8)
    wrong_port = wrong_listener.getsockname()[1]
    wrong_process = None
    wrong_peer = None
    wrong_payload = b""
    wrong_stdout = b""
    wrong_stderr = b""
    wrong_rejected = False
    try:
        wrong_process = subprocess.Popen(
            [str(out / "bin" / "kbtin"), "-p", "-q"],
            cwd=wrong_work,
            env=wrong_environment,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
        # These lines are deliberately queued behind the TLS session command;
        # a successful (unexpected) handshake would be able to send them.
        wrong_process.stdin.write(
            (
                f"#sslses wrong 127.0.0.1 {wrong_port} ca\n"
                "secret-user\nsecret-password\n"
            ).encode()
        )
        wrong_process.stdin.flush()
        wrong_peer, address = wrong_listener.accept()
        assert address[0] == "127.0.0.1", address
        wrong_peer.settimeout(8)
        wrong_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        wrong_context.load_cert_chain(certfile=wrong_cert, keyfile=wrong_key)
        try:
            wrong_peer = wrong_context.wrap_socket(wrong_peer, server_side=True)
        except (ConnectionResetError, OSError, ssl.SSLError, socket.timeout):
            wrong_rejected = True
        else:
            wrong_payload = recv_until(wrong_peer, b"\x00", timeout=2)
    finally:
        if wrong_peer is not None:
            wrong_peer.close()
        wrong_listener.close()
        if wrong_process is not None:
            stop_process(wrong_process)
            wrong_stdout = wrong_process.stdout.read()
            wrong_stderr = wrong_process.stderr.read()
    assert wrong_process is not None
    assert wrong_rejected, (
        "self-signed certificate was accepted",
        wrong_payload,
        wrong_stdout.decode("utf-8", "replace"),
    )
    assert not wrong_payload, wrong_payload
    assert not any(
        credential in wrong_payload
        for credential in (b"secret-user", b"secret-password")
    ), wrong_payload
    assert not list(wrong_home.iterdir()), list(wrong_home.iterdir())
    assert not list(wrong_work.iterdir()), list(wrong_work.iterdir())

print("kbtin fake-MUD smoke passed: version, fresh HOME, TELNET, TLS trust, and loopback protocol")
print("kbtin TLS smoke passed: private CA accepted and self-signed certificate rejected before data")
PY
