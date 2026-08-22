#!/bin/sh
# Exercise the installed GUI against a loopback-only fake MUD.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [mushtato-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    mushtato_out=$1
else
    mushtato_out=$($guix_bin build -L "$channel_dir" --no-grafts mushtato)
fi

python_out=
for candidate in $($guix_bin build python); do
    if test -x "$candidate/bin/python3"; then
        python_out=$candidate
        break
    fi
done
test -n "$python_out"

xvfb_out=$($guix_bin build xvfb-run)
test -x "$xvfb_out/bin/xvfb-run"
test -x "$mushtato_out/bin/mushtato"
test -f "$mushtato_out/share/applications/mushtato.desktop"
test -f "$mushtato_out/share/doc/mushtato/LICENSE"
test -f "$mushtato_out/share/doc/mushtato/THIRD-PARTY-LICENSES/Qt-LGPL-3.0.txt"
test -f "$mushtato_out/share/doc/mushtato/THIRD-PARTY-LICENSES/Qt-GPL-3.0.txt"

for size in 16 24 32 48 64 128 256 512 1024; do
    test -s "$mushtato_out/share/icons/hicolor/${size}x${size}/apps/mushtato.png"
done

"$python_out/bin/python3" - "$mushtato_out" "$xvfb_out/bin/xvfb-run" <<'PY'
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
xvfb_run = sys.argv[2]


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


with tempfile.TemporaryDirectory(prefix="mushtato-smoke-") as temporary:
    temporary = pathlib.Path(temporary)
    home = temporary / "home"
    data = temporary / "data"
    config = temporary / "config"
    runtime = temporary / "runtime"
    for directory in (home, data, config, runtime):
        directory.mkdir()
    runtime.chmod(0o700)

    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(config),
            "XDG_DATA_HOME": str(data),
            "XDG_RUNTIME_DIR": str(runtime),
            "LC_ALL": "C.UTF-8",
        }
    )
    for name in (
        "http_proxy", "https_proxy", "all_proxy",
        "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY",
    ):
        environment.pop(name, None)

    # This is deliberately an empty XDG tree: exercise the installed GUI's
    # actual first-run dialog and persistence code rather than planting a
    # settings file before starting it.  Dismiss the real modal dialog, which
    # is documented to persist defaults on both OK and Cancel.
    settings = data / "MushTato" / "settings.json"
    assert not settings.exists()
    launcher = (out / "bin" / "mushtato").read_text(encoding="utf-8")
    match = re.search(r'export GUIX_PYTHONPATH="([^$]*)\$\{GUIX_PYTHONPATH', launcher)
    assert match, "installed launcher did not expose its Guix Python closure"
    real_launcher = out / "bin" / ".mushtato-real"
    real_python = real_launcher.read_text(encoding="utf-8").splitlines()[0].split()[0][2:]
    first_run_environment = environment.copy()
    first_run_environment["GUIX_PYTHONPATH"] = match.group(1)
    first_run = r'''
from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication
from engine.storage.paths import settings_path
from gui.app import ensure_settings

application = QApplication([])
path = settings_path()
assert not path.exists(), path
def dismiss_first_run():
    dialog = application.activeModalWidget()
    if dialog is None:
        QTimer.singleShot(10, dismiss_first_run)
    else:
        dialog.reject()
QTimer.singleShot(0, dismiss_first_run)
ensure_settings(path)
assert path.exists(), path
'''
    first_run_result = subprocess.run(
        [xvfb_run, "-a", real_python, "-sP", "-c", first_run],
        env=first_run_environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=20,
    )
    assert first_run_result.returncode == 0, first_run_result.stdout
    # Theme, shortcuts, and toggles are application defaults.  Qt resolves
    # the three font defaults through the active Fontconfig installation, so
    # their names are deliberately checked structurally rather than against
    # this host's font families.
    expected_settings = {
        "hotkeys": {
            "add_world": "Ctrl+N", "connect": "Ctrl+Return",
            "spawn_log_window": "Ctrl+L", "switch_input_focus": "Ctrl+Tab",
            "close_window": "Ctrl+W", "open_text_editor": "Ctrl+Shift+E",
            "new_tab": "Ctrl+T",
        },
        "theme": "dark", "splitter_sizes": [],
        "editor_line_numbers": True, "editor_word_wrap": True,
        "editor_window_geometry": [], "editor_last_dir": "", "upload_last_dir": "",
    }
    import json
    assert settings == data / "MushTato" / "settings.json"
    actual_settings = json.loads(settings.read_text(encoding="utf-8"))
    dynamic_font_keys = {
        "scrollback_font_family", "scrollback_font_size",
        "input_font_family", "input_font_size",
        "editor_font_family", "editor_font_size",
    }
    stable_settings = {key: value for key, value in actual_settings.items()
                       if key not in dynamic_font_keys}
    assert stable_settings == expected_settings, actual_settings
    for family_key, size_key in (
        ("scrollback_font_family", "scrollback_font_size"),
        ("input_font_family", "input_font_size"),
        ("editor_font_family", "editor_font_size"),
    ):
        assert isinstance(actual_settings[family_key], str) and actual_settings[family_key]
        assert isinstance(actual_settings[size_key], int) and actual_settings[size_key] > 0

    # Use a separate configured XDG fixture for the direct-connect protocol
    # test; the first-run assertion above remains genuinely empty.
    configured_data = temporary / "configured-data"
    configured_data.mkdir()
    configured_settings = configured_data / "MushTato" / "settings.json"
    configured_settings.parent.mkdir()
    configured_settings.write_text("{}\n", encoding="utf-8")
    configured_environment = environment.copy()
    configured_environment["XDG_DATA_HOME"] = str(configured_data)

    help_result = subprocess.run(
        [str(out / "bin" / "mushtato"), "--help"],
        env=configured_environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=10,
    )
    assert help_result.returncode == 0, help_result.stdout
    assert "MUD/MUSH server hostname" in help_result.stdout, help_result.stdout

    # This payload owns both ends of the test connection.  When the kernel
    # permits an unprivileged network namespace, it runs entirely inside one;
    # otherwise the explicit fallback still supplies and verifies numeric
    # loopback only (reported below so the isolation limitation is visible).
    loopback_client = r'''
import os, pathlib, signal, socket, subprocess, sys, time
out = pathlib.Path(sys.argv[1]); xvfb_run = sys.argv[2]
ip = sys.argv[3]
if ip:
    subprocess.run([ip, "link", "set", "lo", "up"], check=True)
mud = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
mud.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
mud.bind(("127.0.0.1", 0)); mud.listen(1); mud.settimeout(12)
port = mud.getsockname()[1]
process = subprocess.Popen([xvfb_run, "-a", str(out / "bin" / "mushtato"), "127.0.0.1", str(port)], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True, text=True)
peer = None
try:
    peer, address = mud.accept(); assert address[0] == "127.0.0.1", address
    peer.settimeout(5); peer.sendall(b"\xff\xfb\x01MushTato loopback smoke banner\r\n")
    response = b""
    while len(response) < 3: response += peer.recv(3 - len(response))
    assert response == b"\xff\xfe\x01", response
    time.sleep(0.5); assert process.poll() is None, process.stderr.read()
finally:
    if peer is not None: peer.close()
    mud.close()
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL); process.wait(timeout=5)
stderr = process.stderr.read()
assert process.returncode in (0, -signal.SIGTERM, 143), (process.returncode, stderr)
assert "Traceback" not in stderr, stderr
'''
    import shutil
    unshare = shutil.which("unshare")
    ip = shutil.which("ip")
    namespace_reason = None
    if unshare and ip:
        probe = subprocess.run(
            [unshare, "--user", "--map-root-user", "--net", "--fork",
             ip, "link", "set", "lo", "up"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=10,
        )
        if probe.returncode == 0:
            protocol_result = subprocess.run(
                [unshare, "--user", "--map-root-user", "--net", "--fork",
                 sys.executable, "-c", loopback_client,
                 str(out), xvfb_run, ip],
                env=configured_environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, check=False, timeout=30,
            )
            assert protocol_result.returncode == 0, protocol_result.stdout
        else:
            namespace_reason = probe.stderr.strip() or "unshare network probe failed"
    else:
        namespace_reason = "unshare or ip command unavailable"
    if namespace_reason is not None:
        print("NETWORK NAMESPACE LIMITATION: " + namespace_reason, file=sys.stderr)
        protocol_result = subprocess.run(
            [sys.executable, "-c", loopback_client, str(out), xvfb_run, ""],
            env=configured_environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, check=False, timeout=30,
        )
        assert protocol_result.returncode == 0, protocol_result.stdout

    assert configured_settings.is_file()
    assert not any((out / "share").rglob("settings.json"))

print("mushtato fake-MUD smoke passed: fresh HOME, Xvfb GUI, and loopback Telnet")
PY
