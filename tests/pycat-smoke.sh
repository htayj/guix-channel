#!/bin/sh
# Loopback-only integration test for the installed pycat command.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [pycat-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    pycat_out=$1
else
    pycat_out=$($guix_bin build -L "$channel_dir" pycat)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
test -x "$pycat_out/bin/pycat"
test -f "$pycat_out/share/doc/pycat/README.md"
test -f "$pycat_out/share/doc/pycat/LICENSE"

"$python_out/bin/python3" - "$pycat_out" <<'PY'
import os
import pathlib
import socket
import subprocess
import sys
import tempfile
import time

out = pathlib.Path(sys.argv[1])


def receive_until(sock, needle):
    data = b""
    deadline = time.monotonic() + 5
    while needle not in data:
        if time.monotonic() >= deadline:
            raise AssertionError((needle, data))
        sock.settimeout(max(deadline - time.monotonic(), 0.1))
        data += sock.recv(4096)
    return data


with tempfile.TemporaryDirectory(prefix="pycat-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    work = temporary / "work"
    home = temporary / "home"
    work.mkdir()
    home.mkdir()

    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(5)
    mud_port = mud.getsockname()[1]

    probe = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    probe.bind(("::1", 0))
    frontend_port = probe.getsockname()[1]
    probe.close()

    # The world module exists only in the invocation directory.  Successful
    # loading proves the launcher preserves upstream custom-module behavior.
    (work / "smoke_helper.py").write_text("MARKER = 'sibling helper'\n")
    (work / "smoke_world.py").write_text(
        """from smoke_helper import MARKER

try:
    GENERATION += 1
except NameError:
    GENERATION = 1

class SmokeWorld:
    def __init__(self, mud, arg):
        self.mud = mud
        self.state = {}
        self.gmcp = {}
        self.timers = {}
    def getHostPort(self):
        return (\"127.0.0.1\", %d)
    def quit(self):
        pass
    def trigger(self, line):
        return None
    def handleGmcp(self, key, value):
        pass
    def alias(self, line):
        if line == "#world-marker":
            self.mud.show(f"world module loaded: {MARKER} generation {GENERATION}\\n")
            return True
        return False
def getClass():
    return SmokeWorld
""" % mud_port
    )
    # A cwd module with the same name as a pycat core module must not be
    # imported while the installed program starts.
    (work / "proxy.py").write_text(
        "from pathlib import Path\n"
        "Path('PWNED').write_text('cwd proxy was imported')\n"
        "raise RuntimeError('cwd proxy must not be imported')\n"
    )

    process = subprocess.Popen(
        [str(out / "bin" / "pycat"), "smoke_world", str(frontend_port)],
        cwd=work,
        # Empty user state proves no host Python packages, configuration, or
        # credentials are necessary.  The fake MUD is the only peer.
        env={
            "HOME": str(home),
            "PATH": str(out / "bin"),
            "PYTHONNOUSERSITE": "1",
            "LC_ALL": "C.UTF-8",
        },
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    frontend = None
    peer = None
    try:
        peer, _ = mud.accept()
        peer.settimeout(5)

        # Send before a frontend connects: pycat must retain proxy output.
        peer.sendall(b"cached greeting\n")
        deadline = time.monotonic() + 5
        while True:
            try:
                frontend = socket.create_connection(("::1", frontend_port),
                                                     timeout=0.3)
                break
            except OSError:
                if time.monotonic() >= deadline:
                    raise
                time.sleep(0.05)
        receive_until(frontend, b"cached greeting\n")

        # The initial user world imports its sibling while the core retains
        # precedence over the malicious cwd proxy module.
        frontend.sendall(b"#world-marker\n")
        receive_until(frontend, b"world module loaded: sibling helper generation 1\n")

        frontend.sendall(b"look\n")
        assert peer.recv(4096) == b"look\n"
        peer.sendall(b"look result\n")
        receive_until(frontend, b"look result\n")

        # Upstream reloads its active world module with importlib.reload.
        # The private finder must find the same explicit file and reapply the
        # temporary sibling-import scope.
        frontend.sendall(b"#reload\n")
        receive_until(frontend, b"Reloading world")
        frontend.sendall(b"#world-marker\n")
        receive_until(frontend, b"world module loaded: sibling helper generation 2\n")

        assert not (work / "PWNED").exists()
        assert not any(home.iterdir()), list(home.iterdir())
    finally:
        if frontend is not None:
            frontend.close()
        if peer is not None:
            peer.close()
        mud.close()
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
        if process.returncode not in (-15, 0):
            raise RuntimeError(process.stderr.read())

print("pycat fake-MUD smoke passed")
PY
