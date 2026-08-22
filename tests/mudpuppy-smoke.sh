#!/bin/sh
# Exercise Mudpuppy's installed terminal client only against loopback fixtures.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [mudpuppy-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    mudpuppy_out=$1
else
    mudpuppy_out=$($guix_bin build -L "$channel_dir" --no-grafts mudpuppy)
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

test -x "$mudpuppy_out/bin/mudpuppy"
test -s "$mudpuppy_out/share/doc/mudpuppy/LICENSE"
test -d "$mudpuppy_out/share/doc/mudpuppy/third-party-licenses"

"$python_out/bin/python3" - "$mudpuppy_out" "$openssl_out/bin/openssl" <<'PY'
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


def clean_environment(home, config, data):
    environment = {
        "HOME": str(home),
        "MUDPUPPY_CONFIG": str(config),
        "MUDPUPPY_DATA": str(data),
        "LC_ALL": "C.UTF-8",
        "TERM": "xterm-256color",
        "PATH": "",
    }
    return environment


def read_fd(fd, timeout):
    result = bytearray()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if not ready:
            continue
        try:
            part = os.read(fd, 8192)
        except OSError:
            break
        if not part:
            break
        result.extend(part)
    return bytes(result)


def read_fd_until(fd, expected, timeout):
    result = bytearray()
    deadline = time.monotonic() + timeout
    while expected not in result and time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if not ready:
            continue
        try:
            part = os.read(fd, 8192)
        except OSError:
            break
        if not part:
            break
        result.extend(part)
    assert expected in result, bytes(result)
    return bytes(result)


def recv_until(peer, expected, timeout):
    result = bytearray()
    deadline = time.monotonic() + timeout
    while expected not in result and time.monotonic() < deadline:
        ready, _, _ = select.select([peer], [], [], 0.2)
        if not ready:
            continue
        part = peer.recv(8192)
        if not part:
            break
        result.extend(part)
    assert expected in result, bytes(result)
    return bytes(result)


def stop_pid(pid):
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        os.waitpid(pid, 0)
    except ChildProcessError:
        pass


def spawn_terminal(arguments, environment, cwd):
    pid, terminal = pty.fork()
    if pid == 0:
        os.chdir(cwd)
        # Ratatui requires a non-zero terminal size to initialize normally.
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
        os.execve(arguments[0], arguments, environment)
    return pid, terminal


def terminal_text(raw):
    return re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\([0-9A-Z]", b"", raw)


with tempfile.TemporaryDirectory(prefix="mudpuppy-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    work = temporary / "work"
    for directory in (home, config, data, work):
        directory.mkdir()

    # The launcher must report a deterministic upstream version and the
    # caller-owned state directories before creating files.  This also proves
    # the embedded Guix CPython wrapper does not need a profile or host Python.
    environment = clean_environment(home, config, data)
    setup_release = work / "setup-release"
    environment["MUDPUPPY_SMOKE_RELEASE"] = str(setup_release)
    version = subprocess.run(
        [str(out / "bin" / "mudpuppy"), "--version"],
        cwd=work,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=10,
    )
    assert version.returncode == 0, version.stdout
    assert "0.1.0" in version.stdout, version.stdout
    assert f"Config directory: {config}" in version.stdout, version.stdout
    assert f"Data directory: {data}" in version.stdout, version.stdout
    assert not list(home.iterdir()), list(home.iterdir())
    assert not list(config.iterdir()), list(config.iterdir())
    assert not list(data.iterdir()), list(data.iterdir())

    # This is the complete per-user scripting configuration.  The Python
    # module is outside the store and sends a command only after its handler
    # sees the loopback server's banner.
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(10)
    port = listener.getsockname()[1]
    (config / "config.toml").write_text(
        'modules = ["smoke_script"]\n'
        '[muds.loopback]\n'
        'host = "127.0.0.1"\n'
        f"port = {port}\n"
        '[characters.smoke]\n'
        'mud = "loopback"\n',
        encoding="utf-8",
    )
    (config / "smoke_script.py").write_text(
        "import asyncio\n"
        "import os\n"
        "from pathlib import Path\n"
        "from pup_events import line\n"
        "\n"
        "async def setup():\n"
        "    # Upstream only processes setup completion if the task was still\n"
        "    # pending when its select loop started.  The harness releases this\n"
        "    # task only after observing the live character-menu render.\n"
        "    marker = Path(os.environ['MUDPUPPY_SMOKE_RELEASE'])\n"
        "    while not marker.exists():\n"
        "        await asyncio.sleep(0.01)\n"
        "    # Remain pending across several frontend ticks so completion\n"
        "    # wakes the active select branch instead of racing its guard.\n"
        "    await asyncio.sleep(0.25)\n"
        "\n"
        "@line()\n"
        "async def reply_to_loopback_banner(sesh, event):\n"
        '    if str(event.line) == "PUPPY-BANNER":\n'
        '        sesh.send_line("scripted-response")\n',
        encoding="utf-8",
    )

    pid, terminal = spawn_terminal(
        [
            str(out / "bin" / "mudpuppy"),
            "--log-level", "DEBUG",
            "--connect", "smoke",
        ],
        environment,
        work,
    )
    peer = None
    raw_terminal = b""
    try:
        raw_terminal += read_fd_until(terminal, b"Choose a character", 5)
        setup_release.touch()
        try:
            peer, address = listener.accept()
        except TimeoutError as error:
            raw_terminal += read_fd(terminal, 1)
            raise AssertionError(
                "mudpuppy did not connect to the loopback-only fake MUD: "
                + terminal_text(raw_terminal).decode("utf-8", "replace")
                + "\nlog:\n"
                + (
                    (data / "mudpuppy.log").read_text("utf-8", "replace")
                    if (data / "mudpuppy.log").is_file()
                    else "mudpuppy did not create its data log"
                )
            ) from error
        assert address[0] == "127.0.0.1", address
        peer.settimeout(3)
        # Wait for Mudpuppy's built-in Python Telnet handlers to finish
        # per-session setup.  Their initial DO CHARSET request is observable
        # protocol evidence and prevents the banner from racing handler
        # registration immediately after TCP accept.
        negotiation = recv_until(peer, b"\xff\xfd*", 10)
        assert b"\xff\xfd*" in negotiation, negotiation
        # A plain local Telnet line reaches the actual TUI receive loop.  The
        # response is emitted by the external Python event handler above.
        peer.sendall(b"PUPPY-BANNER\r\n")
        try:
            received = recv_until(peer, b"scripted-response\r\n", 10)
        except AssertionError as error:
            raw_terminal += read_fd(terminal, 1)
            raise AssertionError(
                "Mudpuppy connected but did not run the scripted response: "
                + terminal_text(raw_terminal).decode("utf-8", "replace")
                + "\nlog:\n"
                + (data / "mudpuppy.log").read_text("utf-8", "replace")
            ) from error
        assert b"scripted-response\r\n" in received, received
        raw_terminal += read_fd(terminal, 2)
    finally:
        if peer is not None:
            peer.close()
        listener.close()
        stop_pid(pid)
        raw_terminal += read_fd(terminal, 1)
        os.close(terminal)

    assert b"PUPPY-BANNER" in terminal_text(raw_terminal), raw_terminal[-4000:]
    assert (data / "mudpuppy.log").is_file(), list(data.iterdir())
    assert not list(home.iterdir()), list(home.iterdir())

    # TLS is part of this build through rustls.  A private self-signed
    # loopback listener must be rejected by the verified TLS setting; no
    # external host, public certificate, credentials, or application payload
    # is involved.
    cert = temporary / "loopback-cert.pem"
    key = temporary / "loopback-key.pem"
    cert_result = subprocess.run(
        [
            openssl, "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-keyout", str(key), "-out", str(cert), "-days", "1",
            "-subj", "/CN=localhost",
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=20,
    )
    assert cert_result.returncode == 0, cert_result.stderr.decode("utf-8", "replace")

    tls_listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tls_listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    tls_listener.bind(("127.0.0.1", 0))
    tls_listener.listen(1)
    tls_listener.settimeout(10)
    tls_port = tls_listener.getsockname()[1]
    (config / "config.toml").write_text(
        'modules = ["smoke_script"]\n'
        '[muds.tls_loopback]\n'
        'host = "localhost"\n'
        f"port = {tls_port}\n"
        'tls = "Enabled"\n'
        '[characters.tls]\n'
        'mud = "tls_loopback"\n',
        encoding="utf-8",
    )

    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=cert, keyfile=key)
    setup_release.unlink()
    tls_pid, tls_terminal = spawn_terminal(
        [
            str(out / "bin" / "mudpuppy"),
            "--log-level", "DEBUG",
            "--connect", "tls",
        ],
        environment,
        work,
    )
    tls_peer = None
    tls_error = None
    tls_terminal_output = b""
    try:
        tls_terminal_output += read_fd_until(
            tls_terminal, b"Choose a character", 5
        )
        setup_release.touch()
        try:
            tls_peer, address = tls_listener.accept()
        except TimeoutError as error:
            tls_terminal_text = terminal_text(read_fd(tls_terminal, 1)).decode(
                "utf-8", "replace"
            )
            tls_log = data / "mudpuppy.log"
            raise AssertionError(
                "mudpuppy did not open a loopback TLS connection: "
                + tls_terminal_text
                + "\nlog:\n"
                + (
                    tls_log.read_text("utf-8", "replace")
                    if tls_log.is_file()
                    else "mudpuppy did not create its data log"
                )
            ) from error
        assert address[0] == "127.0.0.1", address
        tls_peer.settimeout(10)
        try:
            context.wrap_socket(tls_peer, server_side=True)
        except ssl.SSLError as error:
            tls_error = error
        assert tls_error is not None, "client accepted an untrusted self-signed certificate"
        tls_reason = getattr(tls_error, "reason", "")
        assert tls_reason in {
            "TLSV1_ALERT_UNKNOWN_CA",
            "SSLV3_ALERT_BAD_CERTIFICATE",
            "TLSV1_ALERT_BAD_CERTIFICATE",
            "SSLV3_ALERT_CERTIFICATE_UNKNOWN",
        }, f"expected a certificate-verification alert, got {tls_error!r}"
        assert not any(
            marker in tls_reason
            for marker in ("UNEXPECTED_EOF", "WANT_READ", "WANT_WRITE")
        ), f"transport failure is not proof of certificate verification: {tls_error!r}"

        # The alert is the protocol-level proof.  Corroborate that it was the
        # application's verified TLS path by waiting for its connection error
        # to reach the private data log before stopping the PTY process.
        tls_log = data / "mudpuppy.log"
        deadline = time.monotonic() + 2
        tls_log_text = ""
        while time.monotonic() < deadline:
            if tls_log.is_file():
                tls_log_text = tls_log.read_text("utf-8", "replace")
                if "certificate" in tls_log_text.lower():
                    break
            time.sleep(0.05)
        tls_terminal_output += read_fd(tls_terminal, 0.2)
        assert "certificate" in tls_log_text.lower(), (
            "certificate alert was not corroborated by Mudpuppy logging; "
            f"error={tls_error!r}, terminal="
            f"{terminal_text(tls_terminal_output).decode('utf-8', 'replace')}, "
            f"log={tls_log_text}"
        )
    finally:
        if tls_peer is not None:
            tls_peer.close()
        tls_listener.close()
        stop_pid(tls_pid)
        read_fd(tls_terminal, 1)
        os.close(tls_terminal)

    # License preservation is observable in the installed output, not merely
    # claimed by the package expression.
    third_party = out / "share/doc/mudpuppy/third-party-licenses"
    assert any(path.is_file() for path in third_party.rglob("*")), third_party

print(
    "mudpuppy fake-MUD smoke passed: fresh HOME, PTY TUI, embedded Python "
    "scripting, loopback Telnet, mutable state, and TLS certificate rejection"
)
PY
