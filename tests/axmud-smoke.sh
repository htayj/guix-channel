#!/bin/sh
# Exercise Axmud's installed Gtk launcher against a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [axmud-output]" >&2
    exit 64
fi

# The fixture runs in one user+network namespace where supported.  Bring up
# loopback in that same namespace immediately before executing this script;
# never bind the fake MUD to a non-loopback address in either branch.
if test "${AXMUD_SMOKE_NAMESPACED:-}" != 1 && command -v unshare >/dev/null; then
    ip_out=$($guix_bin build iproute2)
    namespace_status=$(mktemp -t axmud-smoke-namespace.XXXXXX)
    if unshare --user --map-root-user --net sh -c '
            status=$1
            ip=$2
            script=$3
            shift 3
            "$ip" link set lo up || exit 125
            test "$(cat /sys/class/net/lo/operstate)" = unknown || exit 125
            printf ready > "$status"
            export AXMUD_SMOKE_NAMESPACED=1
            exec "$script" "$@"
        ' sh "$namespace_status" "$ip_out/sbin/ip" "$0" "$@"; then
        rm -f "$namespace_status"
        exit 0
    else
        namespace_result=$?
        if test -f "$namespace_status" && test "$(cat "$namespace_status")" = ready; then
            rm -f "$namespace_status"
            exit "$namespace_result"
        fi
        rm -f "$namespace_status"
        echo "axmud-smoke: user+net namespace unavailable; using explicit 127.0.0.1-only fallback" >&2
    fi
fi

if test "$#" -eq 1; then
    axmud_out=$1
else
    axmud_out=$($guix_bin build -L "$channel_dir" --no-grafts axmud)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
xorg_server_out=$($guix_bin build xorg-server)
xdotool_out=$($guix_bin build xdotool)

test -n "$python_out"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xdotool_out/bin/xdotool"
test -x "$axmud_out/bin/axmud.pl"
test -x "$axmud_out/bin/baxmud.pl"
test -f "$axmud_out/share/doc/axmud/COPYING"
test -f "$axmud_out/share/doc/axmud/COPYING.LESSER"
test -f "$axmud_out/share/doc/axmud/docs-COPYING"
test -f "$axmud_out/share/doc/axmud/help-COPYING"
test -f "$axmud_out/share/doc/axmud/icons-COPYING"
test -f "$axmud_out/share/doc/axmud/images-COPYING"
test -f "$axmud_out/share/doc/axmud/sounds-COPYING"

"$python_out/bin/python3" - "$axmud_out" "$xorg_server_out/bin/Xvfb" "$xdotool_out/bin/xdotool" <<'PY'
import os
import pathlib
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb = sys.argv[2]
xdotool = sys.argv[3]


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


def wait_for(path, timeout=60):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if path.exists():
            return
        time.sleep(0.1)
    raise AssertionError("Axmud did not create %s" % path)


def wait_for_x(display):
    number = display.removeprefix(":").split(".", 1)[0]
    wait_for(pathlib.Path("/tmp/.X11-unix") / ("X" + number), timeout=15)


def wait_for_window(name, timeout=20):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        found = subprocess.run([xdotool, "search", "--name", name],
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                               text=True, env=environment)
        windows = found.stdout.split()
        if windows:
            return windows[-1]
        time.sleep(0.1)
    raise AssertionError("X11 did not expose window %r" % name)


def click_recommended_settings(wizard):
    # WizWin::Setup::introPage puts this button at grid columns 7..10 and
    # row 7..8 of a 12-by-12 grid.  Click its center relative to the actual
    # top-level window geometry: this is deterministic under the fixed Xvfb
    # display and does not depend on Gtk's keyboard-focus policy.
    geometry = subprocess.run([xdotool, "getwindowgeometry", "--shell", wizard],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, check=True, env=environment).stdout
    values = dict(line.split("=", 1) for line in geometry.splitlines() if "=" in line)
    for key in ("X", "Y", "WIDTH", "HEIGHT"):
        assert key in values, geometry
    x = int(values["X"]) + int(values["WIDTH"]) * 17 // 24
    y = int(values["Y"]) + int(values["HEIGHT"]) * 15 // 24
    subprocess.run([xdotool, "mousemove", "--sync", str(x), str(y), "click", "1"],
                   check=True, env=environment)


def wait_for_text(root, text, timeout=20):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for path in root.rglob("*"):
            if path.is_file() and text in path.read_text(encoding="utf-8", errors="replace"):
                return path
        time.sleep(0.1)
    raise AssertionError("Axmud did not persist %r beneath %s" % (text, root))


def read_until(peer, required, timeout=8):
    received = b""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            chunk = peer.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        received += chunk
        if required in received:
            return received
    raise AssertionError("missing %r in %r" % (required, received))


with tempfile.TemporaryDirectory(prefix="axmud-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    config = temporary / "config"
    data = temporary / "data"
    cache = temporary / "cache"
    runtime = temporary / "runtime"
    for directory in (home, config, data, cache, runtime):
        directory.mkdir()
    runtime.chmod(0o700)

    environment = os.environ.copy()
    environment.update({
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_DATA_HOME": str(data), "XDG_CACHE_HOME": str(cache),
        "XDG_RUNTIME_DIR": str(runtime), "LC_ALL": "C.UTF-8", "DISPLAY": ":93",
    })
    for name in ("http_proxy", "https_proxy", "all_proxy",
                 "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"):
        environment.pop(name, None)
    if os.environ.get("AXMUD_SMOKE_NAMESPACED") == "1":
        # /sys may be inherited without a new mount namespace, so ask the
        # network namespace directly rather than inspecting that mount.
        assert socket.if_nameindex() == [(1, "lo")]

    server = subprocess.Popen(
        [xvfb, environment["DISPLAY"], "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
        env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, start_new_session=True, text=True,
    )
    try:
        wait_for_x(environment["DISPLAY"])
        data_dir = home / "axmud-data"
        config_file = data_dir / "axmud.conf"
        first = subprocess.Popen(
            [str(out / "bin" / "axmud.pl")], env=environment,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, start_new_session=True, text=True,
        )
        try:
            wait_for(config_file)
            # Activating the documented recommended-settings button calls
            # Setup::saveChanges(), rather than merely creating axmud.conf.
            wizard = wait_for_window("Axmud setup wizard")
            click_recommended_settings(wizard)
            wait_for_window("Axmud Connections")
        finally:
            stop(first)
        first_stderr = first.stderr.read()
        if first.returncode not in (0, -signal.SIGTERM, 143):
            raise RuntimeError("Axmud first run failed: %s" % first_stderr)
        first_config = config_file.read_text(encoding="utf-8", errors="replace")
        assert "@@@ file_type config" in first_config and "@@@ eof" in first_config
        for label in ("images", "sound files"):
            match = re.search(r"# Allow MXP to download " + re.escape(label) + r"\n([01])", first_config)
            assert match and match.group(1) == "0", (label, first_config)
        for relative in ("logs", "data/worlds", "plugins", "scripts"):
            assert (data_dir / relative).is_dir(), relative
        assert not any(out.rglob("axmud.conf")), "store output contains mutable config"

        # The valid, wizard-completed user profile opts into logs and GMCP
        # debugging for this test only.  Session::processGmcpData writes the
        # parsed package name and payload to the standard debug log.
        for label in ("Allow logging", "Show debug messages for incoming GMCP data"):
            first_config, substitutions = re.subn(r"(# " + re.escape(label) + r"\n)0", r"\g<1>1", first_config, count=1)
            assert substitutions == 1, label
        config_file.write_text(first_config, encoding="utf-8")

        mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        mud.bind(("127.0.0.1", 0))
        mud.listen(1)
        mud.settimeout(15)
        port = mud.getsockname()[1]
        client = subprocess.Popen(
            [str(out / "bin" / "axmud.pl"), "127.0.0.1", str(port), "none"],
            env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, start_new_session=True, text=True,
        )
        peer = None
        try:
            peer, address = mud.accept()
            assert address[0] == "127.0.0.1", address
            peer.settimeout(1)
            peer.sendall(b"\xff\xfd\x01\xff\xfb\xc9")
            received = read_until(peer, b"\xff\xfd\xc9")
            assert b"\xff\xfc\x01" in received, received
            banner = "Axmud rendered fake-MUD banner 248"
            peer.sendall((banner + "\r\n").encode("ascii"))
            peer.sendall(b"\xff\xfa\xc9Core.Hello {\"client\":\"smoke\"}\xff\xf0")
            banner_log = wait_for_text(data_dir / "logs", banner)
            gmcp_log = wait_for_text(data_dir / "logs", "GMCP: core.hello")
            assert '{"client":"smoke"}' in gmcp_log.read_text(encoding="utf-8", errors="replace")
            peer.sendall(b"\xff\xfc\xc9")
            received += read_until(peer, b"\xff\xfe\xc9")
            assert b"\xff\xfe\xc9" in received, received
        finally:
            if peer is not None:
                peer.close()
            mud.close()
            stop(client)
        client_stderr = client.stderr.read()
        if client.returncode not in (0, -signal.SIGTERM, 143):
            raise RuntimeError("Axmud protocol run failed: %s" % client_stderr)
        assert "Can't locate" not in client_stderr, client_stderr
        assert config_file.exists() and config_file.read_text(encoding="utf-8", errors="replace")
        assert not any(out.rglob("axmud.conf")), "runtime state escaped into store"
    finally:
        stop(server)

print("axmud fake-MUD smoke passed: completed setup, persisted banner/GMCP logs, Telnet, loopback")
PY
