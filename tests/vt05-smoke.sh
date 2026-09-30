#!/bin/sh
# Render and erase real PTY output in each installed SDL terminal, offline.
# Screenshots are retained for visual review, including on failure.
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
    vt05_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts vt05)
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
imagemagick_out=$(find_program_output bin/import imagemagick)
util_linux_out=$(find_program_output bin/unshare util-linux)
coreutils_out=$(find_program_output bin/timeout coreutils)

# Check the installed output's content, file modes, and symlinks before and
# after the live proof, including failures.  Runtime state must stay outside it.
before=$($guix_bin hash -S nar "$vt05_out")
test -z "$(find "$vt05_out" -xdev -type f -perm /222 -print -quit)"

# The PID namespace kills any remaining PTY descendants when the driver exits.
# Xvfb uses a private socket directory and creates no host lock file or TCP
# listener.  No host network interfaces enter the private network namespace.
set +e
"$coreutils_out/bin/timeout" --kill-after=5s 120s \
    "$util_linux_out/bin/unshare" --user --map-root-user --mount --net --ipc \
    --pid --kill-child --fork --mount-proc \
    "$python_out/bin/python3" - "$vt05_out" "$xorg_server_out/bin/Xvfb" \
    "$xwininfo_out/bin/xwininfo" "$imagemagick_out/bin/import" \
    "$imagemagick_out/bin/convert" "$util_linux_out/bin/mount" <<'PY'
import os
import pathlib
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time


out = pathlib.Path(sys.argv[1]).resolve()
xvfb, xwininfo, capture, convert, mount = sys.argv[2:]
programs = (
    ("vt05", "VT05", "dumb", b"\x1d\x1f"),
    ("vt50", "VT50", "vt52", b"\x1bH\x1bJ"),
    ("vt52", "VT52", "vt52", b"\x1bH\x1bJ"),
    ("dp3300", "Datapoint 3300", "dumb", b"\x1d\x1f"),
    ("gecon", "GE Datanet 760", "dumb", b"\x0c"),
    ("dm2500", "Datamedia Elite 2500", "dumb", b"\x1e"),
)
artifacts = pathlib.Path(os.environ.get("VT05_SMOKE_ARTIFACTS") or
                         tempfile.mkdtemp(prefix="vt05-smoke-artifacts-")).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
print(f"vt05 screenshots and logs: {artifacts}", flush=True)

# This child runs on the emulator's actual PTY.  A private Unix socket controls
# when it writes; no marker file or child stdout is accepted as rendering proof.
# Disable ONLCR so each historical terminal receives precisely the fixture's
# own CR/LF pairs (not host tty translations).
child_code = r'''
import os, socket, sys, termios
assert os.isatty(0) and os.isatty(1), "emulator child has no PTY"
assert os.environ["TERM"] == sys.argv[2], "incorrect PTY terminal type"
attributes = termios.tcgetattr(1)
attributes[1] &= ~termios.OPOST
termios.tcsetattr(1, termios.TCSANOW, attributes)
clear = bytes.fromhex(sys.argv[3])
with socket.socket(socket.AF_UNIX) as control:
    control.connect(sys.argv[1])
    control.sendall(b"READY\n")
    with control.makefile("rb") as commands:
        for command in commands:
            if command == b"TEXT\n":
                payload = (clear + b"VT05 OFFLINE RENDER\r\n"
                           b"0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ\r\n"
                           b"REAL PTY OUTPUT\r\n")
            elif command == b"CLEAR\n":
                payload = clear
            else:
                raise RuntimeError("unknown fixture command")
            while payload:
                payload = payload[os.write(1, payload):]
            control.sendall(b"WRITTEN\n")
'''


def stop(process):
    if process is not None and process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)


def run(arguments):
    return subprocess.run(arguments, env=environment, cwd=work, check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          timeout=5).stdout


def screenshot(window, destination, width, height):
    run([capture, "-window", window, str(destination)])
    pixels = run([convert, str(destination), "-depth", "8", "RGB:-"])
    if len(pixels) != width * height * 3:
        raise RuntimeError("screenshot dimensions do not match the SDL window")
    # Ignore the cursor's leftmost cells.  The upper half contains all three
    # fixture lines, and clear/home puts the blinking cursor outside this crop.
    return b"".join(pixels[(row * width + 40) * 3:
                           (row + 1) * width * 3]
                    for row in range(height // 2))


def changed_pixels(before, after):
    return sum(max(abs(before[index + channel] - after[index + channel])
                   for channel in range(3)) > 25
               for index in range(0, len(before), 3))


# Mount propagation is private before masking the X11 socket directory.  Do
# not create or replace a host socket, directory, or .X*-lock file.
subprocess.run([mount, "--make-rprivate", "/"], check=True, timeout=5)
if not pathlib.Path("/tmp/.X11-unix").is_dir():
    raise RuntimeError("smoke requires an existing /tmp/.X11-unix mount point")
subprocess.run([mount, "-t", "tmpfs", "tmpfs", "/tmp/.X11-unix"],
               check=True, timeout=5)

with tempfile.TemporaryDirectory(prefix="vt05-smoke-") as temporary:
    root = pathlib.Path(temporary)
    work = root / "work"
    environment = {"PATH": "", "LC_ALL": "C", "LIBGL_ALWAYS_SOFTWARE": "1",
                   "SDL_VIDEODRIVER": "x11", "SDL_AUDIODRIVER": "dummy",
                   "SDL_RENDER_DRIVER": "software"}
    for variable, name in (("HOME", "home"), ("XDG_CONFIG_HOME", "config"),
                           ("XDG_CACHE_HOME", "cache"), ("XDG_DATA_HOME", "data"),
                           ("XDG_STATE_HOME", "state"), ("XDG_RUNTIME_DIR", "runtime")):
        directory = root / name
        directory.mkdir(mode=0o700)
        environment[variable] = str(directory)
    work.mkdir()
    if [name for _, name in socket.if_nameindex()] != ["lo"]:
        raise RuntimeError("smoke did not enter a private network namespace")

    display = None
    read_fd, write_fd = os.pipe()
    with (artifacts / "xvfb.log").open("wb") as display_log:
        try:
            display = subprocess.Popen(
                [xvfb, "-displayfd", str(write_fd), "-screen", "0", "1600x1200x24",
                 "-nolock", "-nolisten", "tcp"], env=environment, cwd=work,
                stdout=display_log, stderr=subprocess.STDOUT,
                pass_fds=(write_fd,), start_new_session=True)
            os.close(write_fd)
            write_fd = None
            import select
            if not select.select([read_fd], [], [], 10)[0]:
                raise RuntimeError("Xvfb did not report a ready display")
            number = os.read(read_fd, 32).decode("ascii").strip()
            if not number.isdigit():
                raise RuntimeError("Xvfb failed to allocate a display; see xvfb.log")
            environment["DISPLAY"] = ":" + number

            for program, title, term, clear in programs:
                client = None
                control = None
                socket_path = work / (program + ".sock")
                with socket.socket(socket.AF_UNIX) as listener, \
                        (artifacts / (program + ".log")).open("wb") as client_log:
                    listener.bind(str(socket_path))
                    listener.listen(1)
                    listener.settimeout(10)
                    try:
                        client = subprocess.Popen(
                            [str(out / "bin" / program), sys.executable, "-c", child_code,
                             str(socket_path), term, clear.hex()],
                            env=environment, cwd=work, stdin=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL, stderr=client_log,
                            start_new_session=True)
                        control, _ = listener.accept()
                        control.settimeout(5)
                        with control.makefile("rb") as replies:
                            if replies.readline() != b"READY\n":
                                raise RuntimeError(f"{program}: PTY child did not start")
                            window = None
                            deadline = time.monotonic() + 10
                            while time.monotonic() < deadline:
                                listing = run([xwininfo, "-root", "-tree"]).decode()
                                match = re.search(r'(0x[0-9a-fA-F]+) "' +
                                                  re.escape(title) + r'"', listing)
                                if match:
                                    window = match[1]
                                    break
                                if client.poll() is not None:
                                    raise RuntimeError(f"{program}: exited before its SDL window")
                                time.sleep(0.1)
                            if window is None:
                                raise RuntimeError(f"{program}: SDL window not found")
                            geometry = run([xwininfo, "-id", window]).decode()
                            width = int(re.search(r"Width:\s+(\d+)", geometry)[1])
                            height = int(re.search(r"Height:\s+(\d+)", geometry)[1])
                            # Let SDL finish its initial blank render before comparing.
                            time.sleep(0.4)
                            baseline = screenshot(window, artifacts / (program + "-blank.png"),
                                                  width, height)
                            control.sendall(b"TEXT\n")
                            if replies.readline() != b"WRITTEN\n":
                                raise RuntimeError(f"{program}: child could not write fixture")
                            deadline = time.monotonic() + 5
                            written = 0
                            while time.monotonic() < deadline:
                                rendered = screenshot(window, artifacts / (program + "-rendered.png"),
                                                      width, height)
                                written = changed_pixels(baseline, rendered)
                                if written >= 300:
                                    break
                                time.sleep(0.1)
                            if written < 300:
                                raise RuntimeError(f"{program}: PTY text was not rendered")
                            control.sendall(b"CLEAR\n")
                            if replies.readline() != b"WRITTEN\n":
                                raise RuntimeError(f"{program}: child could not write clear sequence")
                            deadline = time.monotonic() + 5
                            remaining = written
                            while time.monotonic() < deadline:
                                cleared = screenshot(window, artifacts / (program + "-cleared.png"),
                                                     width, height)
                                remaining = changed_pixels(baseline, cleared)
                                if remaining <= 20:
                                    break
                                time.sleep(0.1)
                            if remaining > 20:
                                raise RuntimeError(f"{program}: clear/home did not erase PTY text")
                            if client.poll() is not None:
                                raise RuntimeError(f"{program}: SDL client exited during rendering")
                            print(f"{program}: real PTY text rendered ({written} pixels), "
                                  f"then erased ({remaining} pixels remain)", flush=True)
                    finally:
                        if control is not None:
                            control.close()
                        stop(client)
        finally:
            os.close(read_fd)
            if write_fd is not None:
                os.close(write_fd)
            stop(display)

print(f"vt05 offline rendering smoke passed; screenshots: {artifacts}")
PY
status=$?
set -e
after=$($guix_bin hash -S nar "$vt05_out")
test "$before" = "$after" || {
    echo 'vt05 smoke changed the immutable package output' >&2
    exit 1
}
test -z "$(find "$vt05_out" -xdev -type f -perm /222 -print -quit)"
exit "$status"
