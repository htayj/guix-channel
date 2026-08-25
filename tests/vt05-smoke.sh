#!/bin/sh
# Offline Xvfb/PTY smoke test for the installed VT52 emulator.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [vt05-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    vt05_out=$1
else
    vt05_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes vt05)
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

test -x "$vt05_out/bin/vt05"
test -x "$vt05_out/bin/vt50"
test -x "$vt05_out/bin/vt52"
test -x "$vt05_out/bin/dp3300"
test -x "$vt05_out/bin/gecon"
test -x "$vt05_out/bin/dm2500"
test -s "$vt05_out/share/doc/vt05/LICENSE"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xwininfo_out/bin/xwininfo"
test -x "$util_linux_out/bin/unshare"

# A private network namespace has no non-loopback interfaces.  This makes the
# graphical PTY smoke independent of host networking while Xvfb itself also
# refuses TCP listeners.
exec "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$vt05_out" "$xorg_server_out/bin/Xvfb" \
    "$xwininfo_out/bin/xwininfo" "$ip_bin" <<'PY'
import hashlib
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1])
xvfb = sys.argv[2]
xwininfo = sys.argv[3]
ip = sys.argv[4]
programs = ("vt05", "vt50", "vt52", "dp3300", "gecon", "dm2500")


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode("utf-8"))
        digest.update(repr((status.st_mode, status.st_uid, status.st_gid,
                            status.st_size, status.st_mtime_ns,
                            status.st_ctime_ns)).encode("ascii"))
        if path.is_symlink():
            digest.update(os.readlink(path).encode("utf-8"))
        elif path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


for program in programs:
    executable = out / "bin" / program
    assert executable.is_file() and os.access(executable, os.X_OK), executable
license_file = out / "share" / "doc" / "vt05" / "LICENSE"
license_text = license_file.read_text(encoding="utf-8")
assert "MIT License" in license_text, license_text
assert "Permission is hereby granted" in license_text, license_text
before = tree_digest(out)

with tempfile.TemporaryDirectory(prefix="vt05-smoke-") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, data, state, runtime, work = [root / name for name in
        ("home", "config", "cache", "data", "state", "runtime", "work")]
    for directory in (home, config, cache, data, state, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    marker = work / "VT05_SMOKE"
    environment = {
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_CACHE_HOME": str(cache), "XDG_DATA_HOME": str(data),
        "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
        "DISPLAY": ":99", "LIBGL_ALWAYS_SOFTWARE": "1",
        "SDL_AUDIODRIVER": "dummy", "LC_ALL": "C.UTF-8", "PATH": "",
    }
    for name in ("http_proxy", "https_proxy", "all_proxy", "HTTP_PROXY",
                 "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY", "no_proxy"):
        environment.pop(name, None)

    subprocess.run([ip, "link", "set", "lo", "up"], check=True,
                   env=environment, cwd=work)
    links = subprocess.check_output([ip, "-o", "link", "show"],
                                    text=True, env=environment, cwd=work)
    assert [line.split(":", 2)[1].strip().split("@", 1)[0]
            for line in links.splitlines()] == ["lo"], links

    xvfb_log = (work / "xvfb.log").open("wb")
    display = subprocess.Popen(
        [xvfb, ":99", "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
        env=environment, cwd=work, stdout=xvfb_log, stderr=subprocess.STDOUT,
        start_new_session=True)
    client_log = (work / "vt52.log").open("wb")
    client = None
    try:
        time.sleep(0.4)
        assert display.poll() is None, (work / "xvfb.log").read_text(
            encoding="utf-8", errors="replace")
        command = ("test \"$TERM\" = vt52 || exit 1; "
                   f"printf '%s\\n' VT05_SMOKE > {marker}; sleep 60")
        client = subprocess.Popen(
            [str(out / "bin" / "vt52"), "/bin/sh", "-c", command],
            env=environment, cwd=work, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=client_log,
            start_new_session=True)
        deadline = time.monotonic() + 12
        window_seen = False
        while time.monotonic() < deadline:
            listing = subprocess.run([xwininfo, "-root", "-tree"],
                                     env=environment, cwd=work,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     text=True)
            if listing.returncode == 0 and '"VT52"' in listing.stdout:
                window_seen = True
            if window_seen and marker.is_file():
                break
            if client.poll() is not None:
                raise AssertionError(("vt52 exited early", client.returncode,
                                      (work / "vt52.log").read_text(
                                          encoding="utf-8", errors="replace")))
            time.sleep(0.1)
        assert window_seen, "VT52 window was not visible through Xvfb"
        assert marker.read_text(encoding="utf-8") == "VT05_SMOKE\n"
        log = (work / "vt52.log").read_text(encoding="utf-8", errors="replace")
        assert "SDL_CreateWindowAndRenderer() failed" not in log, log
        assert client.poll() is None, log
    finally:
        if client is not None:
            stop(client)
        stop(display)
        client_log.close()
        xvfb_log.close()

assert tree_digest(out) == before, "the immutable package output changed"
print("vt05 offline smoke passed: VT52 SDL window, PTY TERM contract, and MIT notice")
PY
