#!/bin/sh
# Exercise Rune against loopback-only fake MUD endpoints in a fresh state dir.
set -eu

guix_tool=${GUIX:-"guix time-machine -C channels.guix --"}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [rune-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    rune_out=$1
else
    rune_out=$($guix_tool build -L . --no-grafts rune)
fi

if test "${RUNE_SMOKE_IN_NETNS:-}" = 1; then
    python_out=$RUNE_SMOKE_PYTHON
    openssl_out=$RUNE_SMOKE_OPENSSL
else
    python_out=
    for candidate in $($guix_tool build python); do
        if test -x "$candidate/bin/python3"; then
            python_out=$candidate
            break
        fi
    done
    test -n "$python_out"

    openssl_out=
    for candidate in $($guix_tool build openssl); do
        if test -x "$candidate/bin/openssl"; then
            openssl_out=$candidate
            break
        fi
    done
    test -n "$openssl_out"

    # The fake endpoints and Rune share a fresh user+network namespace.  It
    # contains only loopback, so a future accidental non-local dial cannot
    # leave the smoke test.  This isolation is an acceptance gate: do not run
    # the protocol checks on ordinary host networking when namespaces are
    # unavailable.
    iproute_out=$($guix_tool build iproute2)
    if test -x "$iproute_out/bin/ip"; then
        ip_bin=$iproute_out/bin/ip
    else
        ip_bin=$iproute_out/sbin/ip
    fi
    test -x "$ip_bin"
    if ! unshare --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up' sh "$ip_bin"; then
        echo "rune-smoke: user+network namespaces are required for the isolation gate" >&2
        exit 1
    fi
    exec env RUNE_SMOKE_IN_NETNS=1 \
        RUNE_SMOKE_PYTHON="$python_out" \
        RUNE_SMOKE_OPENSSL="$openssl_out" \
        RUNE_SMOKE_NETWORK_MODE=namespace \
        GUIX="$guix_tool" \
        unshare --user --map-root-user --net --fork \
        sh -c '"$1" link set lo up; exec "$2" "$3"' \
        sh "$ip_bin" "$0" "$rune_out"
fi

test -x "$rune_out/bin/rune"
test -s "$rune_out/share/doc/rune/LICENSE"
test -s "$rune_out/share/doc/rune/README.md"
# 21 direct source modules contribute 25 distinct notices once nested Lunar
# fixtures and the two generated Go triegen copies are retained; uniseg's
# generated Unicode 15.0.0 tables add their referenced Unicode license.
test "$(find "$rune_out/share/doc/rune/licenses" -type f | wc -l)" -eq 26
test -s "$rune_out/share/doc/rune/licenses/unicode-15.0.0/LICENSE-UNICODE"
test -s "$rune_out/share/doc/rune/licenses/go-rune-github-com-clipperhouse-displaywidth/source/github.com/clipperhouse/displaywidth/internal/gen/triegen/LICENSE"
test -s "$rune_out/share/doc/rune/licenses/go-rune-github-com-clipperhouse-uax29-v2/source/github.com/clipperhouse/uax29/v2/internal/gen/triegen/LICENSE"
grep -F 'Unicode, Inc.' "$rune_out/share/doc/rune/licenses/unicode-15.0.0/LICENSE-UNICODE" >/dev/null
grep -F 'Copyright 2009 The Go Authors.' \
    "$rune_out/share/doc/rune/licenses/go-rune-github-com-clipperhouse-displaywidth/source/github.com/clipperhouse/displaywidth/internal/gen/triegen/LICENSE" >/dev/null
# The TLS wrapper must use Guix's immutable certificate bundle, not a host
# path.  Runtime TLS below then proves the actual client handshake path.
grep -F '/etc/ssl/certs' "$rune_out/bin/rune" >/dev/null

"$python_out/bin/python3" - "$rune_out" "$openssl_out/bin/openssl" <<'PY'
import fcntl
import json
import os
import pathlib
import pty
import re
import select
import signal
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import termios
import time
import zlib


out = pathlib.Path(sys.argv[1])
openssl = sys.argv[2]
network_mode = os.environ["RUNE_SMOKE_NETWORK_MODE"]
IAC, DO, WILL, SB, SE = 255, 253, 251, 250, 240
TTYPE, GMCP, MCCP2 = 24, 201, 86


def environment(home, config):
    env = {
        "HOME": str(home),
        "LC_ALL": "C.UTF-8",
        "TERM": "xterm-256color",
        "PATH": "",
        "RUNE_CONFIG_DIR": str(config),
    }
    return env


def tree_signature(root):
    return {
        str(path.relative_to(root)): (path.lstat().st_mode, path.lstat().st_size,
                                      path.lstat().st_mtime_ns)
        for path in sorted(root.rglob("*"))
    }


def spawn_terminal(arguments, env, cwd):
    pid, terminal = pty.fork()
    if pid == 0:
        os.chdir(cwd)
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
        os.execve(arguments[0], arguments, env)
    return pid, terminal


def read_fd(fd, timeout):
    data = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.15)
        if not ready:
            continue
        try:
            part = os.read(fd, 8192)
        except OSError:
            break
        if not part:
            break
        data.extend(part)
    return bytes(data)


def recv_until(peer, expected, timeout, collected=b""):
    data = bytearray(collected)
    deadline = time.monotonic() + timeout
    while expected not in data and time.monotonic() < deadline:
        ready, _, _ = select.select([peer], [], [], 0.15)
        if not ready:
            continue
        part = peer.recv(8192)
        if not part:
            break
        data.extend(part)
    assert expected in data, (expected, bytes(data))
    return bytes(data)


def stop(pid):
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        done, _ = os.waitpid(pid, os.WNOHANG)
        if done:
            return
        time.sleep(0.05)
    os.kill(pid, signal.SIGKILL)
    os.waitpid(pid, 0)


def clean_terminal(raw):
    return re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\([0-9A-Z]", b"", raw)


def loopback_listener():
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(10)
    return listener


with tempfile.TemporaryDirectory(prefix="rune-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home, config, work = temporary / "home", temporary / "config", temporary / "work"
    home.mkdir()
    config.mkdir()
    work.mkdir()
    before = tree_signature(out)

    # This fresh, user-owned configuration proves both Lua backend selection
    # and durable state placement.  No file under the store is a writable
    # configuration or cache target.
    (config / "init.lua").write_text(
        'assert(rune.store.set("smoke", { backend = "lunar", immutable = true }))\n'
        'rune.gmcp.on("Char.Vitals", function(data)\n'
        '  if data.hp == 77 then rune.gmcp.send("Smoke.Ack", { hp = data.hp }) end\n'
        'end, { name = "rune-smoke-vitals" })\n', encoding="utf-8")
    env = environment(home, config)

    version = subprocess.run([str(out / "bin" / "rune"), "--version"], env=env,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             text=True, check=True, timeout=10)
    assert version.stdout == "rune 0.10.1 (lua: lunar)\n", version.stdout

    listener = loopback_listener()
    pid, terminal = spawn_terminal(
        [str(out / "bin" / "rune"), "--config-dir", str(config),
         f"127.0.0.1:{listener.getsockname()[1]}"], env, work)
    peer = None
    transcript = b""
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.setblocking(False)

        # Real Telnet capability negotiation: Rune must answer both a local
        # TTYPE request and the two server-offered modern capabilities.
        peer.sendall(bytes([IAC, DO, TTYPE, IAC, WILL, GMCP, IAC, WILL, MCCP2]))
        received = recv_until(peer, bytes([IAC, WILL, TTYPE]), 5)
        received = recv_until(peer, bytes([IAC, DO, GMCP]), 5, received)
        received = recv_until(peer, bytes([IAC, DO, MCCP2]), 5, received)
        peer.sendall(bytes([IAC, SB, TTYPE, 1, IAC, SE]))
        received = recv_until(peer, bytes([IAC, SB, TTYPE, 0]) + b"RUNE" +
                              bytes([IAC, SE]), 5, received)

        # GMCP handshake and application callback are both wire-visible.
        received = recv_until(peer, b"Core.Hello", 5, received)
        peer.sendall(bytes([IAC, SB, GMCP]) + b'Char.Vitals {"hp":77}' +
                     bytes([IAC, SE]))
        received = recv_until(peer, b"Smoke.Ack", 5, received)

        # MCCP2 switches the remaining read source to zlib.  A plain trailer
        # after Z_STREAM_END catches loss at the compressed/uncompressed edge.
        compressed = zlib.compress(b"RUNE_MCCP2_SMOKE\r\n")
        peer.sendall(bytes([IAC, SB, MCCP2, IAC, SE]) + compressed +
                     b"RUNE_MCCP2_TRAILER\r\n")
        time.sleep(0.4)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        try:
            stop(pid)
        except ChildProcessError:
            pass
        transcript += read_fd(terminal, 1)
        os.close(terminal)

    plain = clean_terminal(transcript)
    assert b"RUNE_MCCP2_SMOKE" in plain, plain[-4000:]
    assert b"RUNE_MCCP2_TRAILER" in plain, plain[-4000:]
    store = config / "store.json"
    assert store.is_file(), list(config.rglob("*"))
    persisted = json.loads(store.read_text(encoding="utf-8"))
    assert persisted["smoke"] == {"backend": "lunar", "immutable": True}, persisted
    assert not any(str(path.resolve()).startswith(str(out)) for path in config.rglob("*"))

    def run_openssl(*arguments):
        result = subprocess.run([openssl, *map(str, arguments)], stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=20, check=False)
        assert result.returncode == 0, result.stderr.decode("utf-8", "replace")

    # Verified tls:// must use normal x509 validation.  Build a small local
    # CA, then issue a serverAuth leaf with a 127.0.0.1 IP SAN.  SSL_CERT_FILE
    # is additive to the package's immutable NSS certificate directory and
    # lets this isolated fixture test the normal trusted path.
    ca, ca_key = temporary / "ca.pem", temporary / "ca.key"
    cert, key, csr, extensions = (temporary / "server.pem", temporary / "server.key",
                                  temporary / "server.csr", temporary / "server.ext")
    run_openssl("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
                "-subj", "/CN=Rune smoke CA",
                "-addext", "basicConstraints=critical,CA:TRUE",
                "-addext", "keyUsage=critical,keyCertSign,cRLSign",
                "-keyout", ca_key, "-out", ca)
    run_openssl("req", "-newkey", "rsa:2048", "-nodes", "-subj", "/CN=127.0.0.1",
                "-keyout", key, "-out", csr)
    extensions.write_text(
        "basicConstraints=critical,CA:FALSE\n"
        "keyUsage=critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=serverAuth\n"
        "subjectAltName=IP:127.0.0.1\n", encoding="ascii")
    run_openssl("x509", "-req", "-in", csr, "-CA", ca, "-CAkey", ca_key,
                "-CAcreateserial", "-days", "1", "-extfile", extensions, "-out", cert)
    listener = loopback_listener()
    trusted_env = dict(env, SSL_CERT_FILE=str(ca))
    tls_pid, tls_terminal = spawn_terminal(
        [str(out / "bin" / "rune"), "--config-dir", str(config),
         f"tls://127.0.0.1:{listener.getsockname()[1]}"], trusted_env, work)
    accepted = None
    tls_transcript = b""
    try:
        accepted, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(certfile=cert, keyfile=key)
        stream = context.wrap_socket(accepted, server_side=True)
        accepted = None
        stream.sendall(b"RUNE_TLS_SMOKE\r\n")
        time.sleep(0.4)
        stream.close()
    finally:
        if accepted is not None:
            accepted.close()
        listener.close()
        try:
            stop(tls_pid)
        except ChildProcessError:
            pass
        tls_transcript += read_fd(tls_terminal, 1)
        os.close(tls_terminal)
    assert b"RUNE_TLS_SMOKE" in clean_terminal(tls_transcript), tls_transcript[-4000:]

    # The same tls:// path must reject an untrusted self-signed IP-SAN leaf.
    # The TLS server sees a certificate alert (not EOF); this makes the test
    # distinguish real chain validation from a generic client crash.
    bad_cert, bad_key = temporary / "wrong-server.pem", temporary / "wrong-server.key"
    run_openssl("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
                "-subj", "/CN=127.0.0.1", "-addext", "subjectAltName=IP:127.0.0.1",
                "-keyout", bad_key, "-out", bad_cert)
    listener = loopback_listener()
    reject_pid, reject_terminal = spawn_terminal(
        [str(out / "bin" / "rune"), "--config-dir", str(config),
         f"tls://127.0.0.1:{listener.getsockname()[1]}"], env, work)
    accepted = None
    rejection_reason = ""
    try:
        accepted, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(certfile=bad_cert, keyfile=bad_key)
        try:
            context.wrap_socket(accepted, server_side=True)
        except ssl.SSLError as error:
            rejection_reason = (error.reason or "").upper()
            assert "EOF" not in rejection_reason, rejection_reason
            assert any(token in rejection_reason for token in
                       ("UNKNOWN_CA", "BAD_CERTIFICATE", "CERTIFICATE_UNKNOWN")), rejection_reason
        else:
            raise AssertionError("tls:// accepted an untrusted self-signed certificate")
        accepted = None
    finally:
        if accepted is not None:
            accepted.close()
        listener.close()
        try:
            stop(reject_pid)
        except ChildProcessError:
            pass
        reject_transcript = read_fd(reject_terminal, 1)
        os.close(reject_terminal)
    assert rejection_reason, "no certificate-validation alert received"
    # Rune remains an interactive client after the rejected handshake; the
    # peer-side certificate alert above is the unambiguous verification proof
    # (rather than treating an EOF or a process crash as a rejection).
    assert b"Disconnected" in clean_terminal(reject_transcript), reject_transcript[-4000:]
    assert tree_signature(out) == before, "Rune modified its immutable store output"
    assert network_mode == "namespace"
    assert {name for _, name in socket.if_nameindex()} == {"lo"}

print("rune smoke passed: fresh state, Lunar, Telnet/TTYPE, GMCP, MCCP2, verified TLS, "
      f"store immutability, and loopback isolation ({network_mode})")
PY
