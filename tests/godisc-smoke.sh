#!/bin/sh
# Exercise the installed godisc binary and launcher with a loopback-only MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [godisc-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    godisc_out=$1
else
    godisc_out=$($guix_bin build -L "$channel_dir" --no-grafts godisc)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
tmux_out=$($guix_bin build tmux)
test -x "$tmux_out/bin/tmux"
test -x "$godisc_out/bin/godisc"
test -x "$godisc_out/bin/godisc-tmux"
license_file=$(find "$godisc_out/share/doc" -type f -name LICENSE -print -quit)
test -n "$license_file"
grep -q "MIT License" "$license_file"

# The upstream launcher was tied to /usr/local/bin and /home/$USER.  Check
# that the installed script uses Guix's explicit runtime and its configurable
# endpoint instead of silently retaining either host-specific path.
launcher_real="$godisc_out/bin/.godisc-tmux-real"
test -x "$launcher_real"
grep -F 'tmux' "$launcher_real" >/dev/null
if grep -F '/usr/local/bin/godisc' "$launcher_real" >/dev/null; then
    echo "godisc-tmux retained the upstream /usr/local/bin path" >&2
    exit 1
fi
if grep -F '/home/$SESSION' "$launcher_real" >/dev/null; then
    echo "godisc-tmux retained the upstream /home/$SESSION path" >&2
    exit 1
fi

"$python_out/bin/python3" - "$godisc_out" "$tmux_out" <<'PY'
import os
import pathlib
import select
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
tmux = pathlib.Path(sys.argv[2]) / "bin" / "tmux"
binary = out / "bin" / "godisc"


def run_probe(command, home):
    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "GODISC_SKIP_WEB_CACHE": "1",
            "LC_ALL": "C.UTF-8",
        }
    )
    result = subprocess.run(
        [str(binary)] + command,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
        timeout=10,
    )
    assert result.returncode == 0, (result, result.stderr)
    return result.stdout


with tempfile.TemporaryDirectory(prefix="godisc-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    version_home = temporary / "version-home"
    help_home = temporary / "help-home"
    version_home.mkdir()
    help_home.mkdir()

    assert run_probe(["--version"], version_home).strip() == (
        "godisc 0-20180125-47a9163"
    )
    assert run_probe(["--help"], help_home).strip() == (
        "usage: godisc [HOST PORT]"
    )

    home = temporary / "home"
    home.mkdir()

    # Execute the real tmux launcher from a genuinely fresh profile.  A
    # noninteractive invocation cannot attach, but it must create the complete
    # config path and its three-pane session before that expected attach error.
    launcher_home = temporary / "launcher-home"
    launcher_home.mkdir()
    launcher_config = temporary / "custom-godisc-config"
    session = "godisc-smoke-%d" % os.getpid()
    launcher_environment = {
        "HOME": str(launcher_home),
        "USER": "godisc-smoke",
        "TERM": "xterm-256color",
        "LC_ALL": "C.UTF-8",
        "GODISC_CONFIG_DIR": str(launcher_config),
        "GODISC_TMUX_SESSION": session,
        "GODISC_HOST": "127.0.0.1",
        "GODISC_PORT": "1",
        "GODISC_SKIP_WEB_CACHE": "1",
        "GODISC_NONINTERACTIVE": "1",
        "PATH": "",
    }
    launcher = subprocess.run(
        [str(out / "bin" / "godisc-tmux")],
        env=launcher_environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=10,
    )
    assert launcher.returncode != 0, launcher
    assert launcher_config.is_dir(), launcher.stderr
    assert (launcher_config / "tellChat.log").is_file()
    assert (launcher_config / "xp.log").is_file()
    tmux_environment = dict(launcher_environment)
    tmux_environment["PATH"] = str(tmux.parent)
    try:
        has_session = subprocess.run(
            [str(tmux), "has-session", "-t", session],
            env=tmux_environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=5,
        )
        assert has_session.returncode == 0, has_session.stderr
        panes = subprocess.run(
            [str(tmux), "list-panes", "-t", session + ":1", "-F", "#{pane_index}"],
            env=tmux_environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
            timeout=5,
        )
        assert len(panes.stdout.splitlines()) == 3, panes.stdout
    finally:
        subprocess.run(
            [str(tmux), "kill-session", "-t", session],
            env=tmux_environment,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=5,
        )

    # This fake MUD binds only to IPv4 loopback.  The client receives a real
    # Telnet WILL-ECHO negotiation and a banner; no public MUD or DNS lookup is
    # involved.  GODISC_SKIP_WEB_CACHE also prevents the old HTML startup
    # cache from making an external request during an offline smoke.
    listener = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", 0))
    listener.listen(1)
    listener.settimeout(8)
    port = listener.getsockname()[1]

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "GODISC_SKIP_WEB_CACHE": "1",
            "GODISC_NONINTERACTIVE": "1",
            "LC_ALL": "C.UTF-8",
            "PATH": str(out / "bin"),
        }
    )
    process = subprocess.Popen(
        [str(binary), "127.0.0.1", str(port)],
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )

    peer = None
    output = bytearray()
    received = bytearray()
    try:
        peer, address = listener.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(0.2)

        # IAC WILL ECHO is a genuine Telnet command.  ziutek/telnet must
        # consume it, answer IAC DO ECHO, and expose only the banner to Go.
        peer.sendall(
            bytes([0xFF, 0xFB, 0x01])
            + b"godisc loopback smoke\r\n"
        )
        deadline = time.monotonic() + 8
        stdout_fd = process.stdout.fileno()
        while time.monotonic() < deadline:
            readable, _, _ = select.select([stdout_fd], [], [], 0.1)
            if readable:
                chunk = os.read(stdout_fd, 8192)
                if not chunk:
                    break
                output.extend(chunk)
                if b"godisc loopback smoke" in output:
                    break
            try:
                received.extend(peer.recv(8192))
            except socket.timeout:
                pass
        assert b"godisc loopback smoke" in output, bytes(output)
        response_deadline = time.monotonic() + 2
        while b"\xff\xfd\x01" not in received and time.monotonic() < response_deadline:
            try:
                received.extend(peer.recv(8192))
            except socket.timeout:
                pass
        assert b"\xff\xfd\x01" in received, bytes(received)
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
    assert process.returncode in (0, -signal.SIGTERM, 143), (
        process.returncode,
        stderr,
    )
    config = home / ".config" / "godisc"
    assert config.is_dir(), list(home.rglob("*"))
    assert str(config).startswith(str(temporary)), config

print("godisc fake-MUD smoke passed: version, launcher audit, and loopback Telnet")
PY
