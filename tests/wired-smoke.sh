#!/bin/sh
# Exercise Wired's installed D-Bus/X11 daemon without host state or networking.
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
    # Do not pass --no-check: this intentionally proves the package build with
    # its upstream tests enabled before exercising the installed result.
    wired_out=$($guix_bin build -L "$channel_dir" --no-grafts wired)
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
xorg_server_out=$(find_program_output bin/Xvfb xorg-server)
xwininfo_out=$(find_program_output bin/xwininfo xwininfo)
util_linux_out=$(find_program_output bin/unshare util-linux)
iproute_out=$(find_program_output bin/ip iproute2 || \
              find_program_output sbin/ip iproute2)
if test -x "$iproute_out/bin/ip"; then
    ip_bin=$iproute_out/bin/ip
else
    ip_bin=$iproute_out/sbin/ip
fi

test -x "$wired_out/bin/wired"
test -s "$wired_out/share/doc/wired/LICENSE"
test -s "$wired_out/share/wired/examples/wired.ron"
test -s "$wired_out/share/wired/examples/wired_multilayout.ron"
test -s "$wired_out/lib/systemd/user/wired.service"
test -x "$python_out/bin/python3"
test -x "$dbus_out/bin/dbus-run-session"
test -x "$dbus_out/bin/dbus-send"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xwininfo_out/bin/xwininfo"
test -x "$util_linux_out/bin/unshare"

# A fresh user, mount, and network namespace owns a private tmpfs /tmp.  The
# D-Bus and X11 protocols use only Unix sockets there; no host network or state
# is visible to the daemon.
exec "$util_linux_out/bin/unshare" --user --map-root-user --net --mount --fork \
    "$python_out/bin/python3" - "$wired_out" "$dbus_out" \
    "$xorg_server_out/bin/Xvfb" "$xwininfo_out/bin/xwininfo" "$ip_bin" \
    "$util_linux_out/bin/mount" <<'PY'
import hashlib
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import textwrap


out = pathlib.Path(sys.argv[1])
dbus = pathlib.Path(sys.argv[2])
xvfb = pathlib.Path(sys.argv[3])
xwininfo = pathlib.Path(sys.argv[4])
ip = pathlib.Path(sys.argv[5])
mount = pathlib.Path(sys.argv[6])


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
            digest.update(path.read_bytes())
    return digest.digest()


assert (out / "bin" / "wired").is_file()
license_text = (out / "share" / "doc" / "wired" / "LICENSE").read_text()
assert "MIT License" in license_text and "Copyright (c) 2020 Michael Palmos" in license_text
for example in ("wired.ron", "wired_multilayout.ron"):
    assert "layout_blocks:" in (out / "share" / "wired" / "examples" / example).read_text()
service = (out / "lib" / "systemd" / "user" / "wired.service").read_text()
assert f"ExecStart={out}/bin/wired" in service
assert "Type=dbus" in service
assert "BusName=org.freedesktop.Notifications" in service
assert "ConditionEnvironment=DISPLAY" in service

before = tree_digest(out)
for flag, expected in (("--help", "--config"), ("--version", "0.10.7")):
    result = subprocess.run([str(out / "bin" / "wired"), flag], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            check=False, timeout=10)
    assert result.returncode == 0 and expected in result.stdout, result.stdout

# Make /tmp an empty in-namespace filesystem before creating any daemon files.
subprocess.run([str(mount), "-t", "tmpfs", "-o", "mode=1777", "tmpfs", "/tmp"], check=True)
# This user namespace maps our caller to UID 0, but the host-provided passwd
# database intentionally has no UID 0 entry.  D-Bus needs only this local NSS
# identity to start; bind it over /etc/passwd in the private mount namespace.
private_passwd = pathlib.Path("/tmp/passwd")
private_passwd.write_text("root:x:0:0:Wired smoke:/tmp:/bin/sh\\n", encoding="utf-8")
subprocess.run([str(mount), "--bind", str(private_passwd), "/etc/passwd"], check=True)
interfaces = subprocess.run([str(ip), "-o", "link", "show"], text=True,
                            stdout=subprocess.PIPE, check=True).stdout.splitlines()
assert all(" lo:" in line for line in interfaces), interfaces

with tempfile.TemporaryDirectory(prefix="wired-smoke-", dir="/tmp") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, data, state, runtime, work = [root / name for name in
        ("home", "config", "cache", "data", "state", "runtime", "work")]
    for directory in (home, config, cache, data, state, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    smoke_config = work / "wired.ron"
    # The stock example is declarative text.  Its copy is the only config the
    # daemon sees, and contains no downloaded icon or font asset.
    shutil.copyfile(out / "share" / "wired" / "examples" / "wired.ron", smoke_config)
    session_script = work / "session.py"
    session_script.write_text(textwrap.dedent(r'''
        import os
        import pathlib
        import signal
        import subprocess
        import sys
        import time

        out, dbus, xvfb, xwininfo, config, work = map(pathlib.Path, sys.argv[1:])
        env = os.environ.copy()
        env.update({"DISPLAY": ":99", "PATH": ":".join((str(dbus / "bin"),
                    str(xvfb.parent), str(xwininfo.parent)))})
        display = subprocess.Popen([str(xvfb), ":99", "-screen", "0", "1024x768x24",
                                    "-nolisten", "tcp"], env=env, cwd=work,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        daemon = None
        try:
            for _ in range(100):
                probe = subprocess.run([str(xwininfo), "-display", ":99", "-root"],
                                       env=env, stdout=subprocess.DEVNULL,
                                       stderr=subprocess.DEVNULL, check=False)
                if probe.returncode == 0:
                    break
                time.sleep(.05)
            else:
                raise AssertionError(display.stdout.read().decode())
            daemon = subprocess.Popen([str(out / "bin" / "wired"), "--config", str(config)],
                                      env=env, cwd=work, stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT, start_new_session=True)
            get_info = [str(dbus / "bin" / "dbus-send"), "--session", "--print-reply",
                        "--dest=org.freedesktop.Notifications",
                        "/org/freedesktop/Notifications",
                        "org.freedesktop.Notifications.GetServerInformation"]
            for _ in range(100):
                reply = subprocess.run(get_info, env=env, text=True, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, check=False)
                if reply.returncode == 0:
                    break
                if daemon.poll() is not None:
                    raise AssertionError(daemon.stdout.read().decode())
                time.sleep(.05)
            else:
                raise AssertionError(reply.stdout)
            assert 'string "wired"' in reply.stdout, reply.stdout
            notify = get_info[:-1] + ["org.freedesktop.Notifications.Notify", "string:smoke",
                      "uint32:0", "string:", "string:smoke-summary", "string:smoke-body",
                      "array:string:", "dict:string:variant:", "int32:10000"]
            reply = subprocess.run(notify, env=env, text=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, check=False)
            assert reply.returncode == 0 and "uint32" in reply.stdout, reply.stdout
            for _ in range(100):
                windows = subprocess.run([str(xwininfo), "-display", ":99", "-root", "-tree"],
                                         env=env, text=True, stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, check=False)
                if '"wired"' in windows.stdout:
                    break
                time.sleep(.05)
            else:
                raise AssertionError(windows.stdout)
            killed = subprocess.run([str(out / "bin" / "wired"), "--kill"], env=env,
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    check=False)
            assert killed.returncode == 0, killed.stdout
            daemon.wait(timeout=10)
            assert daemon.returncode == 0, daemon.stdout.read().decode()
            assert not pathlib.Path("/tmp/wired.sock").exists()
        finally:
            for process in (daemon, display):
                if process is not None and process.poll() is None:
                    os.killpg(process.pid, signal.SIGTERM)
                    process.wait(timeout=5)
    '''), encoding="utf-8")
    environment = {"HOME": str(home), "XDG_CONFIG_HOME": str(config),
                   "XDG_CACHE_HOME": str(cache), "XDG_DATA_HOME": str(data),
                   "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
                   "LC_ALL": "C.UTF-8", "PATH": str(dbus / "bin")}
    subprocess.run([str(dbus / "bin" / "dbus-run-session"), "--", sys.executable,
                    str(session_script), str(out), str(dbus), str(xvfb), str(xwininfo),
                    str(smoke_config), str(work)], env=environment, check=True, timeout=30)

assert tree_digest(out) == before
PY
