#!/bin/sh
# Exercise the installed Durthang CLI and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [durthang-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    durthang_out=$1
else
    durthang_out=$($guix_bin build -L "$channel_dir" --no-grafts durthang)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$durthang_out/bin/durthang"
test -f "$durthang_out/share/doc/durthang/LICENSE"
grep -q "GNU GENERAL PUBLIC LICENSE" "$durthang_out/share/doc/durthang/LICENSE"
grep -q "Version 3" "$durthang_out/share/doc/durthang/LICENSE"

"$python_out/bin/python3" - "$durthang_out" <<'PY'
import errno
import fcntl
import json
import os
import pathlib
import pty
import signal
import socket
import struct
import subprocess
import sys
import termios
import tempfile
import time


out = pathlib.Path(sys.argv[1])
binary = out / "bin" / "durthang"


with tempfile.TemporaryDirectory(prefix="durthang-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config_home = temporary / "config"
    data_home = temporary / "data"
    runtime_home = temporary / "runtime"
    home.mkdir()
    config_home.mkdir()
    data_home.mkdir()
    runtime_home.mkdir(mode=0o700)

    # Do not inherit a D-Bus session, credential configuration, TLS trust
    # variables, or XDG paths from the caller.  In particular, this proves
    # that the credential check below cannot accidentally reach a real Secret
    # Service or a caller-owned file backend.
    environment = {
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(config_home),
        "XDG_DATA_HOME": str(data_home),
        "XDG_RUNTIME_DIR": str(runtime_home),
        "TERM": "xterm-256color",
        "LC_ALL": "C.UTF-8",
        "RUST_LOG": "info",
        "PATH": "/nonexistent",
    }

    help_result = subprocess.run(
        [str(binary), "--help"],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=10,
    )
    assert help_result.returncode == 0, help_result
    assert "Usage: durthang" in help_result.stdout, help_result.stdout
    assert "--config <FILE>" in help_result.stdout, help_result.stdout

    version_result = subprocess.run(
        [str(binary), "--version"],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=10,
    )
    assert version_result.returncode == 0, version_result
    assert "durthang 0.2.0" in version_result.stdout, version_result.stdout

    # The only address in this config is the loopback listener below.  Include
    # a character so /credentials performs a real keyring read later.
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(8)
    port = listener.getsockname()[1]
    config_file = config_home / "durthang" / "config.toml"
    config_file.parent.mkdir()
    config_file.write_text(
        "[[servers]]\n"
        "id = \"loopback-smoke\"\n"
        "name = \"Loopback smoke MUD\"\n"
        "host = \"127.0.0.1\"\n"
        "port = %d\n"
        "tls = false\n\n"
        "[[characters]]\n"
        "id = \"loopback-character\"\n"
        "name = \"Smoke character\"\n"
        "server_id = \"loopback-smoke\"\n"
        "login = \"smoke-login\"\n"
        "password_hint = \"not-a-password\"\n" % port,
        encoding="utf-8",
    )

    master, slave = pty.openpty()
    # Keep the TUI output flowing; otherwise a full PTY buffer could stop the
    # event loop before it handles the test input.
    fcntl.fcntl(master, fcntl.F_SETFL, os.O_NONBLOCK)
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    process = subprocess.Popen(
        [str(binary), "--config", str(config_file)],
        env=environment,
        stdin=slave,
        stdout=slave,
        stderr=subprocess.PIPE,
        close_fds=True,
        start_new_session=True,
    )
    os.close(slave)

    peer = None
    received = bytearray()
    screen = bytearray()

    def drain_screen():
        while True:
            try:
                chunk = os.read(master, 8192)
            except BlockingIOError:
                return
            except OSError as error:
                if error.errno == errno.EIO:
                    return
                raise
            if not chunk:
                return
            screen.extend(chunk)

    def read_peer():
        if peer is None:
            return
        while True:
            try:
                chunk = peer.recv(8192)
            except socket.timeout:
                return
            if not chunk:
                return
            received.extend(chunk)

    log_file = data_home / "durthang" / "durthang.log"
    # Wait until the TUI has initialized raw mode before sending the initial
    # selection key; bytes sent earlier can remain in the PTY line buffer.
    deadline = time.monotonic() + 5
    while not log_file.exists() and process.poll() is None and time.monotonic() < deadline:
        drain_screen()
        time.sleep(0.05)
    assert process.poll() is None, process.returncode
    # The server is the initial row and its character is immediately below it.
    # Select that character before connecting so the credential command has a
    # concrete keyring entry to read.
    os.write(master, b"\x1b[B\r")
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(0.1)

        # Exercise Telnet option negotiation and GMCP parsing without a public
        # MUD.  The banner also gives the client visible protocol data.
        iac = bytes([0xFF])
        peer.sendall(
            iac
            + bytes([0xFB, 0xC9])  # WILL GMCP
            + b"\x1b[32mDurthang loopback smoke\x1b[0m\r\n"
            + iac
            + bytes([0xFA, 0xC9])  # SB GMCP
            + b"Room.Info {\"num\":42,\"name\":\"Smoke Room\",\"exits\":{\"north\":43}}"
            + iac
            + bytes([0xF0])  # SE
        )

        # Wait until the installed client has completed its TCP connection and
        # moved to the game screen before sending input through the PTY.
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            drain_screen()
            read_peer()
            if log_file.exists() and "Network: connected" in log_file.read_text(
                encoding="utf-8"
            ):
                break
            time.sleep(0.05)
        else:
            raise AssertionError("Durthang never reported a connected session")

        # The client persists its in-memory automap on a clean /quit.
        map_file = data_home / "durthang" / "loopback-smoke.map.json"

        os.write(master, b"look\r")
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            drain_screen()
            read_peer()
            if b"look\r\n" in received:
                break
            time.sleep(0.05)
        assert b"look\r\n" in received, bytes(received)
        assert b"\xff\xfa\x1f" in received, bytes(received)
        assert b"\xff\xf0" in received, bytes(received)

        # A credential lookup without a session Secret Service must report an
        # explicit error.  It must not turn into a mock or file-backed secret.
        os.write(master, b"/credentials\r")
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            drain_screen()
            if b"Error retrieving credentials" in screen:
                break
            time.sleep(0.05)
        assert b"Error retrieving credentials" in screen, bytes(screen)
        # The deliberately non-secret marker belongs in the test configuration
        # only.  Finding it anywhere else would show an inadmissible file
        # fallback for the failed Secret Service lookup.
        secret_fallbacks = [
            path
            for path in temporary.rglob("*")
            if path.is_file()
            and path != config_file
            and b"not-a-password" in path.read_bytes()
        ]
        assert not secret_fallbacks, secret_fallbacks

        # /quit is a local meta-command and therefore must not be sent as a
        # password or ordinary MUD line.
        os.write(master, b"/quit\r")
        process.wait(timeout=6)
        # GMCP must change durable automap state, not merely be accepted by
        # the Telnet parser.  The map is persisted under the isolated data
        # directory for this exact loopback server id when /quit runs.
        map_state = json.loads(map_file.read_text(encoding="utf-8"))
        room = map_state.get("rooms", {}).get("42")
        assert map_state.get("current_room_id") == "42", map_state
        assert room and room.get("name") == "Smoke Room", map_state
        assert room.get("exits", {}).get("north") == "43", map_state
        log_text = log_file.read_text(encoding="utf-8")
        assert "Durthang shutting down" in log_text, log_text
        assert "look" in bytes(received).decode("utf-8", "replace")
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
        stderr = process.stderr.read().decode("utf-8", "replace")
        os.close(master)

    assert process.returncode == 0, (process.returncode, stderr)
    assert "not-a-password" in config_file.read_text(encoding="utf-8")

print("durthang fake-MUD smoke passed: isolated profile, keyring failure, and loopback Telnet/GMCP map")
PY
