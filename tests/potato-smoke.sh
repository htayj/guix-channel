#!/bin/sh
# Exercise the installed Potato launcher and a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [potato-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    potato_out=$1
else
    potato_out=$($guix_bin build -L "$channel_dir" \
        --no-grafts --no-substitutes potato)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"
xvfb_run_out=$($guix_bin build xvfb-run)
test -x "$xvfb_run_out/bin/xvfb-run"
test -x "$potato_out/bin/potato"
test -f "$potato_out/libexec/potato/main.tcl"
test -f "$potato_out/libexec/potato/lib/potato-version.tcl"
test -f "$potato_out/share/applications/potato.desktop"
test -f "$potato_out/share/icons/hicolor/55x55/apps/potato.png"
test -f "$potato_out/share/doc/potato/LICENSE"
test -f "$potato_out/share/doc/potato/THIRD-PARTY-NOTICES"
test -f "$potato_out/share/doc/potato/tcllib-license.terms"
grep -F 'base64-2.4.2.tm: Tcllib base64 implementation' \
    "$potato_out/share/doc/potato/THIRD-PARTY-NOTICES" >/dev/null
grep -F 'ListboxDnD' "$potato_out/share/doc/potato/THIRD-PARTY-NOTICES" \
    >/dev/null
grep -F 'treeviewUtils' "$potato_out/share/doc/potato/THIRD-PARTY-NOTICES" \
    >/dev/null
tcllib_out=$($guix_bin build tcllib)
tcllib_license=$(find "$tcllib_out/share/doc" -name license.terms \
    -type f -print -quit)
test -n "$tcllib_license"
cmp "$tcllib_license" "$potato_out/share/doc/potato/tcllib-license.terms"
test -z "$(find "$potato_out/libexec/potato/lib/app-potato" \
    -type f \( -name '*.dll' -o -name '*.dylib' \) -print -quit)"
grep -a -F \
    'if {1} { set reqtls {TLS disabled by the Guix package: Tcl TLS lacks hostname validation}; set errdict {}' \
    "$potato_out/libexec/potato/lib/potato.tcl" >/dev/null
grep -F 'set misc(checkForUpdates) 0' \
    "$potato_out/libexec/potato/lib/potato-config.tcl" >/dev/null
grep -a -F \
    'if {0} { ;# Guix package disables scheduled cleartext update checks' \
    "$potato_out/libexec/potato/lib/potato.tcl" >/dev/null
test -z "$("$guix_bin" gc --requisites "$potato_out" | \
    grep '/tcl-tls-' || true)"
test "$(HOME=/nonexistent "$potato_out/bin/potato" --version)" = \
    "Potato MU* Client 2.0.0b19"

"$python_out/bin/python3" - "$potato_out" "$xvfb_run_out/bin/xvfb-run" <<'PY'
import os
import pathlib
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb_run = sys.argv[2]


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=8)


with tempfile.TemporaryDirectory(prefix="potato-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    def launch(home, arguments=(), extra_environment=None):
        environment = {
            "HOME": str(home),
            "PATH": "",
            "LC_ALL": "C.UTF-8",
            # Avoid inheriting an ambient Tcl package path or user startup.
            "TCLLIBPATH": "",
        }
        if extra_environment:
            environment.update(extra_environment)
        return subprocess.Popen(
            [xvfb_run, "-a", str(out / "bin" / "potato"), *arguments],
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )

    # This is deliberately a pristine HOME: no .potato directory and no
    # potato.custom fixture exist before starting the graphical client.
    empty_home = temporary / "empty-home"
    empty_home.mkdir()
    empty_process = launch(empty_home)
    try:
        time.sleep(1)
        assert empty_process.poll() is None, empty_process.stderr.read()
    finally:
        stop(empty_process)

    # A hostile Tcl package proves the forced TLS-unavailable branch does not
    # load an ambient tls package through TCLLIBPATH.
    hostile_tcllib = temporary / "hostile-tcllib"
    hostile_tcllib.mkdir()
    (hostile_tcllib / "pkgIndex.tcl").write_text(
        "package ifneeded tls 9.9 [list source [file join $dir tls.tcl]]\n",
        encoding="ascii",
    )
    (hostile_tcllib / "tls.tcl").write_text(
        "set fd [open [file join $::env(HOME) hostile-tcllib-loaded] w]\n"
        "puts $fd loaded\n"
        "close $fd\n"
        "package provide tls 9.9\n",
        encoding="ascii",
    )
    hostile_home = temporary / "hostile-home"
    hostile_home.mkdir()
    hostile_process = launch(
        hostile_home, extra_environment={"TCLLIBPATH": str(hostile_tcllib)}
    )
    try:
        time.sleep(1)
        assert hostile_process.poll() is None, hostile_process.stderr.read()
    finally:
        stop(hostile_process)
    assert not (hostile_home / "hostile-tcllib-loaded").exists()

    # Keep the protocol fixture separate from initialization.  Potato sources
    # potato.custom before processing the command-line address; the hook sends
    # one deterministic command only after the loopback connection succeeds.
    home = temporary / "protocol-home"
    home.mkdir()
    potato_home = home / ".potato"
    potato_home.mkdir()
    (potato_home / "potato.custom").write_text(
        "proc ::potato_smoke_send {} {\n"
        "    if {[info exists ::potato::conn(1,connected)] &&\n"
        "        $::potato::conn(1,connected) == 1} {\n"
        "        ::potato::send_to_noparse 1 \"look\"\n"
        "        set marker [open [file join $::env(HOME) potato-protocol-complete] w]\n"
        "        puts $marker complete\n"
        "        close $marker\n"
        "    } else {\n"
        "        after 100 ::potato_smoke_send\n"
        "    }\n"
        "}\n"
        "after 100 ::potato_smoke_send\n",
        encoding="ascii",
    )

    # Bind only to loopback.  The fake server sends a banner and verifies the
    # client's normal CRLF command; no DNS or public MUD is contacted.
    mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    mud.bind(("127.0.0.1", 0))
    mud.listen(1)
    mud.settimeout(10)
    mud_port = mud.getsockname()[1]

    process = launch(home, (f"127.0.0.1:{mud_port}",))
    peer = None
    received = b""
    try:
        peer, address = mud.accept()
        assert address[0] == "127.0.0.1", address
        peer.settimeout(0.5)
        peer.sendall(b"Potato loopback smoke banner\r\n")
        deadline = time.monotonic() + 10
        while b"look\r\n" not in received and time.monotonic() < deadline:
            try:
                chunk = peer.recv(4096)
            except socket.timeout:
                continue
            if not chunk:
                break
            received += chunk
        assert b"look\r\n" in received, received
        marker = home / "potato-protocol-complete"
        deadline = time.monotonic() + 3
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(0.05)
        assert marker.read_text(encoding="ascii") == "complete\n"
    finally:
        if peer is not None:
            peer.close()
        mud.close()
        stop(process)

    stdout = process.stdout.read().decode("utf-8", "replace")
    stderr = process.stderr.read().decode("utf-8", "replace")
    assert process.returncode in (0, -signal.SIGTERM, 143), (
        process.returncode,
        stdout,
        stderr,
    )
    # The temporary HOME is expected to hold preferences/worlds/logs; the
    # immutable package tree must not be used as a writable profile.
    assert potato_home.exists(), potato_home
    assert not (out / "libexec" / "potato" / "potato.ini").exists()

print("potato smoke passed: fresh HOME init, hostile TCLLIBPATH, and loopback fake-MUD")
PY
