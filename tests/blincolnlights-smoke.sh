#!/bin/sh
# Offline SDL-panel and PDP-5 launcher smoke test for blincolnlights.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
panel_file=/tmp/pdp1_panel
temporary=$(mktemp -d "${TMPDIR:-/tmp}/blincolnlights-smoke.XXXXXX")
owns_panel=$temporary/owns-pdp1-panel

cleanup() {
    if test -f "$owns_panel"; then
        rm -f -- "$panel_file"
    fi
    rm -rf -- "$temporary"
}
trap cleanup EXIT HUP INT TERM

if test "$#" -gt 1; then
    echo "usage: $0 [blincolnlights-output]" >&2
    exit 64
fi

if test -e "$panel_file" || test -L "$panel_file"; then
    echo "refusing to remove pre-existing $panel_file" >&2
    exit 1
fi

if test "$#" -eq 1; then
    blincolnlights_out=$1
else
    blincolnlights_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes blincolnlights)
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

test -x "$blincolnlights_out/bin/blincolnlights-panel-pdp1"
test -x "$blincolnlights_out/bin/blincolnlights-pdp5"
test -x "$blincolnlights_out/bin/blincolnlights-pdp1"
test -x "$blincolnlights_out/bin/blincolnlights-pdp1-b18"
test -x "$blincolnlights_out/bin/blincolnlights-tx0-pdp1"
test -x "$blincolnlights_out/bin/blincolnlights-tx0-b18"
test -x "$blincolnlights_out/bin/blincolnlights-whirlwind"
test -x "$blincolnlights_out/bin/blincolnlights-whirlwind-b18"
test -x "$blincolnlights_out/bin/mkptyfl"
test -x "$blincolnlights_out/bin/mkptyfio"
test -s "$blincolnlights_out/share/doc/blincolnlights/LICENSE"
test -s "$blincolnlights_out/share/doc/blincolnlights/README.guix"
test -f "$blincolnlights_out/share/blincolnlights/pdp1/tapes/ddt.rim"
test -L "$blincolnlights_out/share/blincolnlights/pdp1/tapes/dpys5.rim"
test "$(readlink "$blincolnlights_out/share/blincolnlights/pdp1/tapes/dpys5.rim")" = ddt.rim
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xwininfo_out/bin/xwininfo"
test -x "$util_linux_out/bin/unshare"

# The emulators expose fixed TCP services.  Put this test in a user-owned
# loopback-only network namespace so it neither reaches nor conflicts with the
# host network.  Xvfb itself additionally refuses TCP listeners.
"$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$python_out/bin/python3" - "$blincolnlights_out" \
    "$xorg_server_out/bin/Xvfb" "$xwininfo_out/bin/xwininfo" "$ip_bin" \
    "$panel_file" "$owns_panel" <<'PY'
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
panel_file = pathlib.Path(sys.argv[5])
owner_marker = pathlib.Path(sys.argv[6])


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


programs = (
    "blincolnlights-panel-b18", "blincolnlights-panel-pdp1",
    "blincolnlights-panel-whirlwind", "blincolnlights-pdp1",
    "blincolnlights-pdp1-b18", "blincolnlights-pdp5",
    "blincolnlights-tx0-pdp1", "blincolnlights-tx0-b18",
    "blincolnlights-whirlwind", "blincolnlights-whirlwind-b18",
    "mkptyfl", "mkptyfio",
)
for program in programs:
    executable = out / "bin" / program
    assert executable.is_file() and os.access(executable, os.X_OK), executable

license_text = (out / "share/doc/blincolnlights/LICENSE").read_text(encoding="utf-8")
assert "MIT License" in license_text and "Permission is hereby granted" in license_text
runtime_note = (out / "share/doc/blincolnlights/README.guix").read_text(encoding="utf-8")
assert "/tmp/pdp1_panel" in runtime_note and "single" in runtime_note
assert str((out / "share/blincolnlights/pdp1/tapes/dpys5.rim").readlink()) == "ddt.rim"
before = tree_digest(out)

with tempfile.TemporaryDirectory(prefix="blincolnlights-runtime-") as temporary:
    root = pathlib.Path(temporary)
    home, config, cache, data, state, runtime, work = [root / name for name in
        ("home", "config", "cache", "data", "state", "runtime", "work")]
    for directory in (home, config, cache, data, state, runtime, work):
        directory.mkdir()
    runtime.chmod(0o700)
    environment = {
        "HOME": str(home), "XDG_CONFIG_HOME": str(config),
        "XDG_CACHE_HOME": str(cache), "XDG_DATA_HOME": str(data),
        "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
        "DISPLAY": ":99", "LIBGL_ALWAYS_SOFTWARE": "1",
        "SDL_AUDIODRIVER": "dummy", "SDL_RENDER_DRIVER": "software",
        "LC_ALL": "C.UTF-8", "PATH": "",
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
    panel_log = (work / "panel.log").open("wb")
    pdp5_log = (work / "pdp5.log").open("wb")
    display = panel = pdp5 = None
    try:
        display = subprocess.Popen(
            [xvfb, ":99", "-screen", "0", "1024x768x24", "-nolisten", "tcp"],
            env=environment, cwd=work, stdout=xvfb_log, stderr=subprocess.STDOUT,
            start_new_session=True)
        time.sleep(0.4)
        assert display.poll() is None, (work / "xvfb.log").read_text(
            encoding="utf-8", errors="replace")
        panel = subprocess.Popen(
            [str(out / "bin/blincolnlights-panel-pdp1")],
            env=environment, cwd=work, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=panel_log, start_new_session=True)
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline and not panel_file.exists():
            if panel.poll() is not None:
                raise AssertionError(("panel exited early", panel.returncode,
                                      (work / "panel.log").read_text(
                                          encoding="utf-8", errors="replace")))
            time.sleep(0.1)
        assert panel_file.is_file() and panel_file.stat().st_size > 0, panel_file
        owner_marker.write_text("created by this smoke test\n", encoding="utf-8")
        pdp5 = subprocess.Popen(
            [str(out / "bin/blincolnlights-pdp5")],
            env=environment, cwd=work, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=pdp5_log, start_new_session=True)
        time.sleep(2)
        assert panel.poll() is None, (work / "panel.log").read_text(
            encoding="utf-8", errors="replace")
        assert pdp5.poll() is None, (work / "pdp5.log").read_text(
            encoding="utf-8", errors="replace")
        listing = subprocess.run([xwininfo, "-root", "-tree"], env=environment,
                                 cwd=work, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, text=True)
        assert listing.returncode == 0 and "PDP-1" in listing.stdout, listing.stderr
        stop(pdp5)
        pdp5 = None
        pdp5_state = state / "blincolnlights/blincolnlights-pdp5"
        assert (pdp5_state / "coremem").is_file(), pdp5_state
        assert (pdp5_state / "maindec").is_symlink(), pdp5_state
        assert (pdp5_state / "tapes").is_symlink(), pdp5_state
        for log in ("panel.log", "pdp5.log"):
            text = (work / log).read_text(encoding="utf-8", errors="replace")
            assert "can't find operator panel" not in text, text
    finally:
        if pdp5 is not None:
            stop(pdp5)
        if panel is not None:
            stop(panel)
        if display is not None:
            stop(display)
        pdp5_log.close()
        panel_log.close()
        xvfb_log.close()

assert tree_digest(out) == before, "the immutable package output changed"
print("blincolnlights offline smoke passed: SDL panel, PDP-5 state wrapper, MIT notice")
PY
