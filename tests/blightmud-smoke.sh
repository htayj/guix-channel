#!/bin/sh
# Exercise Blightmud only against loopback fake-MUD endpoints in a fresh HOME.
set -eu

# Use the authenticated channel configuration by default.  A caller may set
# GUIX explicitly (for an already-running pinned Guix, for example), but a
# bare host Guix is never selected silently.
guix_tool=${GUIX:-"guix time-machine -C channels.guix --"}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [blightmud-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    blightmud_out=$1
else
    blightmud_out=$($guix_tool build -L . --no-grafts blightmud)
fi

if test "${BLIGHTMUD_SMOKE_IN_NETNS:-}" = 1; then
    python_out=$BLIGHTMUD_SMOKE_PYTHON
    openssl_out=$BLIGHTMUD_SMOKE_OPENSSL
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

    # Keep the whole test (fake servers and client) in one loopback-only user
    # and network namespace.  This both permits the normal startup path and
    # makes any accidental outbound endpoint unreachable.  If the kernel
    # denies unprivileged namespaces, retain the source invariant and route
    # conventional proxy variables to a closed loopback endpoint instead.
    ip_bin=$(command -v ip || true)
    if test -n "$ip_bin" && unshare --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up' sh "$ip_bin"; then
        exec env BLIGHTMUD_SMOKE_IN_NETNS=1 \
            BLIGHTMUD_SMOKE_PYTHON="$python_out" \
            BLIGHTMUD_SMOKE_OPENSSL="$openssl_out" \
            BLIGHTMUD_SMOKE_NETWORK_MODE=namespace \
            GUIX="$guix_tool" \
            unshare --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up; exec "$2" "$3"' \
            sh "$ip_bin" "$0" "$blightmud_out"
    fi
    export BLIGHTMUD_SMOKE_NETWORK_MODE=fallback
fi

test -x "$blightmud_out/bin/blightmud"
test -s "$blightmud_out/share/doc/blightmud/LICENSE"
test -d "$blightmud_out/share/doc/blightmud/third-party-licenses"
test "$(find "$blightmud_out/share/doc/blightmud/third-party-licenses" -type f | wc -l)" -eq 906

# The package, not a command-line convention, disables the startup release
# request.  User-triggered plugin actions remain outside this smoke's scope.
grep -F '(not (string-contains lib "check_latest_version"))' \
    "$channel_dir/tay/packages/blightmud.scm" >/dev/null
grep -F 'Package-managed update check disabled' \
    "$channel_dir/tay/packages/blightmud.scm" >/dev/null
grep -F -- '--no-default-features' "$channel_dir/tay/packages/blightmud.scm" >/dev/null

"$python_out/bin/python3" - "$blightmud_out" "$openssl_out/bin/openssl" <<'PY'
import fcntl
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


out = pathlib.Path(sys.argv[1])
openssl = sys.argv[2]
network_mode = os.environ.get("BLIGHTMUD_SMOKE_NETWORK_MODE", "fallback")
IAC, DO, WILL, SB, SE = 255, 253, 251, 250, 240
GMCP, MSDP, MCCP2 = 201, 69, 86


def environment(home, extra=None):
    env = {
        "HOME": str(home),
        "LC_ALL": "C.UTF-8",
        "TERM": "xterm-256color",
        "PATH": "",
    }
    if network_mode == "fallback":
        # This is not as strong as a network namespace.  The packaged source
        # invariant removes the release-check call; proxies make any future
        # conventional HTTP client use only a closed loopback endpoint.
        env.update({name: "http://127.0.0.1:9" for name in
                    ("ALL_PROXY", "all_proxy", "HTTP_PROXY", "http_proxy",
                     "HTTPS_PROXY", "https_proxy")})
    if extra:
        env.update(extra)
    return env


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


def wait_exit(pid, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        done, status = os.waitpid(pid, os.WNOHANG)
        if done:
            assert os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0, status
            return
        time.sleep(0.05)
    raise AssertionError("Blightmud did not exit after loopback disconnect")


def terminal_diagnostic(pid, terminal):
    """Return the PTY transcript and a non-blocking child status for failures."""
    transcript = clean_terminal(read_fd(terminal, 1))
    done, status = os.waitpid(pid, os.WNOHANG)
    state = f"exit status {status}" if done else "still running"
    return state, transcript[-4000:]


def clean_terminal(raw):
    return re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\([0-9A-Z]", b"", raw)


def client_hello(peer):
    peer.settimeout(5)
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        try:
            record = peer.recv(6, socket.MSG_PEEK)
        except (BlockingIOError, socket.timeout):
            continue
        if len(record) >= 6:
            assert record[0] == 0x16 and record[1] == 0x03 and record[2] <= 0x04, record
            assert record[5] == 0x01, record
            return
    raise AssertionError("no TLS ClientHello received")


with tempfile.TemporaryDirectory(prefix="blightmud-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = home / ".config" / "blightmud"
    work = temporary / "work"
    config.mkdir(parents=True)
    work.mkdir()

    # This config is outside the store.  Its three callbacks prove that the
    # installed Lua runtime processes GMCP, MSDP, and MCCP2-decompressed text.
    (config / "smoke.lua").write_text(
        "gmcp.receive('Char.Vitals', function(value)\n"
        # Blightmud's bundled GMCP parser retains the delimiter space in the
        # JSON body it supplies to receive callbacks.
        "  if value == ' {\\\"hp\\\":42}' then mud.send('GMCP_CALLBACK_OK') end\n"
        "end)\n"
        "msdp.register('HP', function(value)\n"
        "  if value == '42' then mud.send('MSDP_CALLBACK_OK') end\n"
        "end)\n"
        "mud.add_output_listener(function(line)\n"
        "  if line:line() == 'MCCP2_SMOKE' then mud.send('MCCP2_CALLBACK_OK') end\n"
        "  if line:line() == 'TLS_PROTOCOL_SMOKE' then mud.send('TLS_PROTOCOL_CALLBACK_OK') end\n"
        "  return line\n"
        "end)\n"
        "mud.on_disconnect(function() blight.output('DISCONNECT_CALLBACK_OK'); blight.quit() end)\n",
        encoding="utf-8",
    )

    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(10)
    port = listener.getsockname()[1]
    pid, terminal = spawn_terminal(
        [str(out / "bin" / "blightmud"), "--connect", f"127.0.0.1:{port}"],
        environment(home), work,
    )
    peer = None
    terminal_data = b""
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.setblocking(False)

        # Negotiate GMCP and observe the protocol response plus the client hello.
        peer.sendall(bytes([IAC, WILL, GMCP]))
        received = recv_until(peer, bytes([IAC, DO, GMCP]), 5)
        received = recv_until(peer, b"Core.Hello", 5, received)
        peer.sendall(bytes([IAC, SB, GMCP]) + b'Char.Vitals {"hp":42}' + bytes([IAC, SE]))
        received = recv_until(peer, b"GMCP_CALLBACK_OK", 5, received)

        # MSDP is a distinct Telnet subnegotiation with binary field markers.
        peer.sendall(bytes([IAC, WILL, MSDP]))
        received = recv_until(peer, bytes([IAC, DO, MSDP]), 5, received)
        peer.sendall(bytes([IAC, SB, MSDP, 1]) + b"HP" + bytes([2]) + b"42" + bytes([IAC, SE]))
        received = recv_until(peer, b"MSDP_CALLBACK_OK", 5, received)

        # MCCP2 begins after IAC SB MCCP2 IAC SE; every later byte is zlib.
        peer.sendall(bytes([IAC, WILL, MCCP2]))
        received = recv_until(peer, bytes([IAC, DO, MCCP2]), 5, received)
        import zlib
        peer.sendall(bytes([IAC, SB, MCCP2, IAC, SE]) + zlib.compress(b"MCCP2_SMOKE\r\n"))
        received = recv_until(peer, b"MCCP2_CALLBACK_OK", 5, received)
        peer.close()
        peer = None
        wait_exit(pid, 8)
        terminal_data += read_fd(terminal, 1)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        try:
            stop(pid)
        except ChildProcessError:
            pass
        terminal_data += read_fd(terminal, 1)
        os.close(terminal)

    assert b"MCCP2_SMOKE" in clean_terminal(terminal_data), terminal_data[-4000:]
    data_dir = home / ".local" / "share" / "blightmud"
    assert data_dir.is_dir(), list(home.rglob("*"))
    assert not any(pathlib.Path("/gnu/store") in path.parents for path in home.rglob("*"))

    # Generate a temporary CA and an IP SAN matching the exact connected host.
    # The package adds SSL_CERT_FILE as an additive private-CA source, while
    # preserving webpki roots and mandatory verification.
    ca, ca_key = temporary / "ca.pem", temporary / "ca.key"
    cert, key, csr, extensions = (temporary / "server.pem", temporary / "server.key",
                                  temporary / "server.csr", temporary / "server.ext")
    commands = [
        [openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
         "-subj", "/CN=Blightmud smoke CA", "-addext", "basicConstraints=critical,CA:TRUE",
         "-addext", "keyUsage=critical,keyCertSign,cRLSign", "-keyout", str(ca_key),
         "-out", str(ca)],
        [openssl, "req", "-newkey", "rsa:2048", "-nodes", "-subj", "/CN=127.0.0.1",
         "-keyout", str(key), "-out", str(csr)],
    ]
    for command in commands:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                timeout=20, check=False)
        assert result.returncode == 0, result.stderr.decode("utf-8", "replace")
    extensions.write_text(
        "basicConstraints=critical,CA:FALSE\n"
        "keyUsage=critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage=serverAuth\n"
        "subjectAltName=IP:127.0.0.1\n", encoding="ascii")
    result = subprocess.run(
        [openssl, "x509", "-req", "-in", str(csr), "-CA", str(ca), "-CAkey", str(ca_key),
         "-CAcreateserial", "-days", "1", "-extfile", str(extensions), "-out", str(cert)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20, check=False,
    )
    assert result.returncode == 0, result.stderr.decode("utf-8", "replace")

    def tls_listener():
        listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(10)
        return listener

    # Positive verified TLS: the package adds SSL_CERT_FILE as an additive
    # private CA source, so this matching CA and IP SAN must permit a real
    # TLS exchange and encrypted MUD protocol callback.
    listener = tls_listener()
    tls_pid, tls_terminal = spawn_terminal(
        [str(out / "bin" / "blightmud"), "--tls", "--connect",
         f"127.0.0.1:{listener.getsockname()[1]}"],
        environment(home, {"SSL_CERT_FILE": str(ca)}), work,
    )
    accepted = None
    tls_terminal_data = b""
    try:
        accepted, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        client_hello(accepted)
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(certfile=cert, keyfile=key)
        try:
            stream = context.wrap_socket(accepted, server_side=True)
        except ssl.SSLError as error:
            state, transcript = terminal_diagnostic(tls_pid, tls_terminal)
            raise AssertionError(
                f"verified private-CA TLS failed: {error.reason}; client {state}; "
                f"PTY={transcript!r}") from error
        accepted = None
        stream.settimeout(5)
        stream.sendall(b"TLS_PROTOCOL_SMOKE\r\n")
        assert b"TLS_PROTOCOL_CALLBACK_OK" in stream.recv(8192)
        stream.close()
        wait_exit(tls_pid, 8)
        tls_terminal_data += read_fd(tls_terminal, 1)
    finally:
        if accepted is not None:
            accepted.close()
        listener.close()
        try:
            stop(tls_pid)
        except ChildProcessError:
            pass
        tls_terminal_data += read_fd(tls_terminal, 1)
        os.close(tls_terminal)
    assert b"TLS_PROTOCOL_SMOKE" in clean_terminal(tls_terminal_data), tls_terminal_data[-4000:]
    assert b"DISCONNECT_CALLBACK_OK" in clean_terminal(tls_terminal_data), tls_terminal_data[-4000:]

    # Negative verified TLS: observe a real ClientHello, then require a
    # certificate-validation alert--not EOF, a timeout, or a WANT condition.
    # Reuse the valid CA-signed IP-SAN/serverAuth leaf, but omit SSL_CERT_FILE.
    # The only intended validation failure is therefore the unknown issuer.
    listener = tls_listener()
    tls_pid, tls_terminal = spawn_terminal(
        [str(out / "bin" / "blightmud"), "--tls", "--connect",
         f"127.0.0.1:{listener.getsockname()[1]}"], environment(home), work,
    )
    accepted = None
    tls_terminal_data = b""
    try:
        accepted, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        client_hello(accepted)
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(certfile=cert, keyfile=key)
        try:
            context.wrap_socket(accepted, server_side=True)
        except ssl.SSLError as error:
            reason = (error.reason or "").upper()
            server_certificate_alert = any(token in reason for token in
                                           ("UNKNOWN_CA", "BAD_CERTIFICATE",
                                            "CERTIFICATE_UNKNOWN"))
            server_eof = "EOF" in reason
        else:
            raise AssertionError("verified TLS accepted a certificate from an unknown CA")
        accepted = None
        wait_exit(tls_pid, 8)
        tls_terminal_data += read_fd(tls_terminal, 1)
        client_log = home / ".local" / "share" / "blightmud" / "logs" / "log.txt"
        assert client_log.is_file(), list((home / ".local").rglob("*"))
        client_log_text = client_log.read_text(encoding="utf-8", errors="replace")
        assert "TLS error: invalid peer certificate" in client_log_text, client_log_text[-4000:]
        assert ("UnknownIssuer" in client_log_text or
                "unknown issuer" in client_log_text.lower()), client_log_text[-4000:]
        assert server_certificate_alert or server_eof, reason
    finally:
        if accepted is not None:
            accepted.close()
        listener.close()
        try:
            stop(tls_pid)
        except ChildProcessError:
            pass
        tls_terminal_data += read_fd(tls_terminal, 1)
        os.close(tls_terminal)
    assert b"DISCONNECT_CALLBACK_OK" in clean_terminal(tls_terminal_data), tls_terminal_data[-4000:]

    interfaces = {name for _, name in socket.if_nameindex()}
    if network_mode == "namespace":
        assert interfaces == {"lo"}, interfaces

print("blightmud smoke passed: loopback Lua, GMCP, MSDP, MCCP2, verified TLS, "
      f"and update-check isolation ({network_mode})")
PY
