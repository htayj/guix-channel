#!/bin/sh
# Drive the installed daemon on private D-Bus/X11 sockets, never the desktop.
# WIRED_SMOKE_ARTIFACTS selects the retained PNG/log directory (otherwise /var/tmp).
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [wired-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    wired_out=$1
else
    # Keep the locked upstream Cargo tests enabled.
    wired_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes wired)
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

python_out=$(find_program_output bin/python3 python)
dbus_out=$(find_program_output bin/dbus-run-session dbus)
# Current Guix keeps the underlying glib binding private/hidden.  Evaluate
# that package directly and select its actual bin output, rather than relying
# on name lookup of glib:bin (which is not a registered package name here).
glib_out=$(find_program_output bin/gdbus -e '(@@ (gnu packages glib) glib)')
xorg_out=$(find_program_output bin/Xvfb xorg-server)
xwininfo_out=$(find_program_output bin/xwininfo xwininfo)
util_linux_out=$(find_program_output bin/unshare util-linux)
coreutils_out=$(find_program_output bin/timeout coreutils)
imagemagick_out=$(find_program_output bin/import imagemagick)
font_out=$($guix_bin build font-dejavu)

test -x "$wired_out/bin/wired"
test -s "$wired_out/share/doc/wired/LICENSE"
test -s "$wired_out/share/doc/wired/Cargo.lock"
test -s "$wired_out/share/wired/examples/wired.ron"
test -s "$wired_out/share/wired/examples/wired_multilayout.ron"
test -s "$wired_out/lib/systemd/user/wired.service"

# PID cleanup survives assertion failures/timeouts.  Network isolation covers
# abstract X11 sockets; the private tmpfs covers pathname sockets and the
# upstream fixed /tmp/wired.sock.  Do not relax isolation to reuse a host bus.
exec "$coreutils_out/bin/timeout" --kill-after=5s 90s \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --mount --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" - "$wired_out" "$dbus_out/bin/dbus-run-session" \
    "$glib_out/bin/gdbus" "$xorg_out/bin/Xvfb" "$xwininfo_out/bin/xwininfo" \
    "$util_linux_out/bin/mount" "$imagemagick_out/bin/import" \
    "$imagemagick_out/bin/convert" "$font_out" <<'PY'
import hashlib
import os
import pathlib
import socket
import subprocess
import sys
import tempfile
import textwrap
import tomllib

out = pathlib.Path(sys.argv[1]).resolve()
bus, gdbus, xvfb, xwininfo, mount, capture, convert, fonts = sys.argv[2:]
artifacts = pathlib.Path(os.environ.get("WIRED_SMOKE_ARTIFACTS") or
                         tempfile.mkdtemp(prefix="wired-smoke-artifacts-", dir="/var/tmp")).resolve()
if artifacts == out or out in artifacts.parents:
    raise RuntimeError("artifacts must not be inside the installed output")
artifacts.mkdir(parents=True, exist_ok=True)
print(f"Wired screenshots and logs: {artifacts}", flush=True)
# Keep the selected destination accessible even if it lives in host /tmp.
artifact_fd = os.open(artifacts, os.O_RDONLY | os.O_DIRECTORY)


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode())
        digest.update(repr((status.st_mode, status.st_uid, status.st_gid,
                            status.st_size, status.st_mtime_ns)).encode())
        if path.is_symlink():
            digest.update(os.readlink(path).encode())
        elif path.is_file():
            assert not status.st_mode & 0o222, f"writable store file: {path}"
            digest.update(path.read_bytes())
    return digest.digest()


before = tree_digest(out)
try:
    doc = out / "share/doc/wired"
    license_text = (doc / "LICENSE").read_text()
    assert "MIT License" in license_text and "Copyright (c) 2020 Michael Palmos" in license_text
    lock = tomllib.loads((doc / "Cargo.lock").read_text())
    notices = doc / "third-party-licenses"
    # Every pinned registry component retains its original manifest/SPDX
    # metadata; all conventionally named upstream notice files accompany it.
    manifests = [tomllib.loads(path.read_text()) for path in notices.rglob("Cargo.toml")]
    preserved = {(item["package"]["name"], item["package"]["version"]) for item in manifests
                 if "package" in item and isinstance(item["package"].get("version"), str)}
    registry = {(item["name"], item["version"]) for item in lock["package"]
                if item.get("source", "").startswith("registry+")}
    assert registry <= preserved, f"missing pinned license manifests: {registry - preserved}"
    for example in ("wired.ron", "wired_multilayout.ron"):
        assert "layout_blocks:" in (out / "share/wired/examples" / example).read_text()
    service = (out / "lib/systemd/user/wired.service").read_text()
    assert f"ExecStart={out}/bin/wired" in service
    assert "Type=dbus" in service and "BusName=org.freedesktop.Notifications" in service
    assert "ConditionEnvironment=DISPLAY" in service

    subprocess.run([mount, "--make-rprivate", "/"], check=True, timeout=5)
    subprocess.run([mount, "-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/tmp"], check=True, timeout=5)
    evidence = pathlib.Path("/tmp/evidence")
    evidence.mkdir()
    subprocess.run([mount, "--bind", f"/proc/self/fd/{artifact_fd}", str(evidence)],
                   pass_fds=(artifact_fd,), check=True, timeout=5)
    os.close(artifact_fd)
    artifact_fd = None
    # D-Bus needs this namespace-local NSS identity, not the host's passwd.
    private_passwd = pathlib.Path("/tmp/passwd")
    private_passwd.write_text("root:x:0:0:Wired smoke:/tmp:/bin/sh\n")
    subprocess.run([mount, "--bind", str(private_passwd), "/etc/passwd"], check=True, timeout=5)
    assert [name for _, name in socket.if_nameindex()] == ["lo"]

    with tempfile.TemporaryDirectory(prefix="wired-smoke-", dir="/tmp") as temporary:
        root = pathlib.Path(temporary)
        environment = {"LC_ALL": "C.UTF-8", "PATH": "", "LIBGL_ALWAYS_SOFTWARE": "1"}
        for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                               ("XDG_CACHE_HOME", "cache"), ("XDG_DATA_HOME", "data"),
                               ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime"),
                               ("TMPDIR", "tmp")):
            directory = root / name
            directory.mkdir(mode=0o700)
            environment[variable] = str(directory)
        work = root / "work"
        work.mkdir()
        # Fontconfig sees only the explicitly supplied free DejaVu fonts;
        # neither host font paths nor Arial downloads are consulted.
        font_config = work / "fonts.conf"
        font_config.write_text(f'<fontconfig><dir>{fonts}/share/fonts</dir>'
                               f'<cachedir>{root}/cache/fontconfig</cachedir></fontconfig>')
        environment["FONTCONFIG_FILE"] = str(font_config)
        config = work / "wired.ron"
        config.write_text((out / "share/wired/examples/wired.ron").read_text()
                          .replace('"Arial Bold 11"', '"DejaVu Sans Bold 11"')
                          .replace('"Arial 11"', '"DejaVu Sans 11"'))
        for flag, expected in (("--help", "--config"), ("--version", "0.10.7")):
            result = subprocess.run([str(out / "bin/wired"), flag], env=environment,
                                    cwd=work, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=10, check=True)
            assert expected in result.stdout, result.stdout
        session_script = work / "session.py"
        session_script.write_text(textwrap.dedent(r'''
            import ast
            import os
            import pathlib
            import re
            import select
            import signal
            import struct
            import subprocess
            import sys
            import time

            out, gdbus, xvfb, xwininfo, capture, convert, config, work, evidence = sys.argv[1:]
            evidence = pathlib.Path(evidence)
            environment = os.environ.copy()
            daemon = display = None

            def run(arguments):
                return subprocess.run(arguments, env=environment, cwd=work, text=True,
                                      stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                      timeout=5, check=True).stdout

            def stop(process):
                if process is not None and process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait(timeout=3)

            def wait_for(probe, message):
                for _ in range(100):
                    if daemon is not None and daemon.poll() is not None:
                        raise AssertionError("daemon exited; see wired.log")
                    if probe():
                        return
                    time.sleep(.05)
                raise AssertionError(message)

            def windows():
                tree = run([xwininfo, "-root", "-tree"])
                return {match[0] for match in re.findall(r'(0x[0-9a-f]+) "wired".*?(\d+)x(\d+)\+(-?\d+)\+(-?\d+)', tree)
                        if int(match[1]) > 1 and int(match[2]) > 1
                        and 0 <= int(match[3]) < 1024 and 0 <= int(match[4]) < 768}

            def screenshot(name):
                path = evidence / name
                run([capture, "-window", "root", str(path)])
                image = path.read_bytes()
                assert image[:8] == b"\x89PNG\r\n\x1a\n"
                assert struct.unpack(">II", image[16:24]) == (1024, 768)
                return subprocess.run([convert, str(path), "-depth", "8", "RGB:-"],
                                      env=environment, cwd=work, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, check=True, timeout=5).stdout

            call = [gdbus, "call", "--session", "--dest", "org.freedesktop.Notifications",
                    "--object-path", "/org/freedesktop/Notifications", "--method"]
            with (evidence / "xvfb.log").open("wb") as display_log, \
                    (evidence / "wired.log").open("wb") as daemon_log:
                read_fd, write_fd = os.pipe()
                try:
                    display = subprocess.Popen([xvfb, "-displayfd", str(write_fd), "-screen", "0",
                                                "1024x768x24", "-nolisten", "tcp", "-nolock"],
                                               env=environment, cwd=work, stdout=display_log,
                                               stderr=subprocess.STDOUT, pass_fds=(write_fd,),
                                               start_new_session=True)
                    os.close(write_fd)
                    write_fd = None
                    assert select.select([read_fd], [], [], 10)[0], "Xvfb startup timed out"
                    number = os.read(read_fd, 32).decode().strip()
                    assert number.isdigit(), "Xvfb failed; see xvfb.log"
                    environment["DISPLAY"] = ":" + number
                    run([xwininfo, "-root"])
                    daemon = subprocess.Popen([out + "/bin/wired", "--config", config],
                                              env=environment, cwd=work, stdout=daemon_log,
                                              stderr=subprocess.STDOUT, start_new_session=True)
                    info = call + ["org.freedesktop.Notifications.GetServerInformation"]
                    def ready():
                        try:
                            reply = run(info)
                        except subprocess.CalledProcessError:
                            return False
                        assert ast.literal_eval(reply)[0] == "wired", reply
                        (evidence / "server-info.txt").write_text(reply)
                        return True
                    wait_for(ready, "private notification service did not become ready")
                    baseline = windows()
                    empty = screenshot("wired-before.png")
                    # gdbus supports the a{sv} dictionary that dbus-send cannot
                    # represent.  Timeout zero keeps it open until explicit close.
                    reply = run(call + ["org.freedesktop.Notifications.Notify", "wired-smoke",
                                        "0", "", "Wired isolated notification", "Native D-Bus send and close",
                                        "[]", "{}", "0"])
                    match = re.fullmatch(r"\(uint32 (\d+),\)\s*", reply)
                    assert match, reply
                    notification_id = match.group(1)
                    (evidence / "notify-reply.txt").write_text(reply)
                    wait_for(lambda: bool(windows() - baseline), "notification never became visible")
                    notification_windows = windows() - baseline
                    for window in notification_windows:
                        details = run([xwininfo, "-id", window])
                        assert "Map State: IsViewable" in details, details
                        (evidence / (window + ".txt")).write_text(details)
                    # Wait for cairo's first rendered frame, not just a mapped
                    # window.  Retain the actual screenshot for visual review.
                    wait_for(lambda: screenshot("wired-notification.png") != empty,
                             "notification window mapped but rendered no pixels")
                    run(call + ["org.freedesktop.Notifications.CloseNotification", notification_id])
                    wait_for(lambda: not (windows() & notification_windows), "CloseNotification left a visible window")
                    wait_for(lambda: screenshot("wired-closed.png") == empty,
                             "CloseNotification did not restore the empty display")
                    assert daemon.poll() is None, "close killed the daemon"
                    run([out + "/bin/wired", "--kill"])
                    assert daemon.wait(timeout=10) == 0, "unclean --kill shutdown"
                    assert pathlib.Path("/tmp/wired.sock").is_socket()
                    print("WIRED_RUNTIME_OK: private D-Bus Notify, rendered X11 PNG, CloseNotification, clean --kill", flush=True)
                finally:
                    stop(daemon)
                    stop(display)
                    os.close(read_fd)
                    if write_fd is not None:
                        os.close(write_fd)
        '''))
        with (evidence / "session.log").open("wb") as session_log:
            subprocess.run([bus, "--dbus-daemon=" + str(pathlib.Path(bus).with_name("dbus-daemon")),
                            "--", sys.executable, str(session_script), str(out), gdbus,
                            xvfb, xwininfo, capture, convert, str(config), str(work), str(evidence)],
                           env=environment, cwd=work, stdout=session_log, stderr=subprocess.STDOUT,
                           check=True, timeout=60)
        print((evidence / "session.log").read_text(), end="", flush=True)
finally:
    if artifact_fd is not None:
        os.close(artifact_fd)
    assert tree_digest(out) == before, "installed store output changed during runtime"
PY
