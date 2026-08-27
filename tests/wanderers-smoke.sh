#!/bin/sh
# Exercise Wanderers in an isolated X11 session without host state or network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [wanderers-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    wanderers_out=$1
else
    wanderers_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes wanderers)
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
xdotool_out=$(find_program_output bin/xdotool xdotool)
util_linux_out=$(find_program_output bin/unshare util-linux)
iproute_out=$(find_program_output bin/ip iproute2 || \
              find_program_output sbin/ip iproute2)
if test -x "$iproute_out/bin/ip"; then
    ip_bin=$iproute_out/bin/ip
else
    ip_bin=$iproute_out/sbin/ip
fi

test -x "$wanderers_out/bin/wanderers"
test -x "$wanderers_out/libexec/wanderers"
test -s "$wanderers_out/share/wanderers/data/tileset.bmp"
test -s "$wanderers_out/share/wanderers/data/dg/cave1.au"
test -s "$wanderers_out/share/doc/wanderers/COPYING"
test -s "$wanderers_out/share/doc/wanderers/README.markdown"
test -s "$wanderers_out/share/doc/wanderers/lib/glcaml_stub.c"
test -s "$wanderers_out/share/doc/wanderers/lib/sdl_stub.c"
test -s "$wanderers_out/share/doc/wanderers/OCamlMakefile"
test -x "$python_out/bin/python3"
test -x "$xorg_server_out/bin/Xvfb"
test -x "$xwininfo_out/bin/xwininfo"
test -x "$xdotool_out/bin/xdotool"
test -x "$util_linux_out/bin/unshare"
test -x "$ip_bin"

# A user/network namespace has no host network interfaces.  Bring up its sole
# loopback device only so the X11 test has no route to a network endpoint.
if test "${WANDERERS_SMOKE_IN_NETNS:-}" != 1; then
    if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
            sh -c '"$1" link set lo up' sh "$ip_bin"; then
        echo "wanderers-smoke: user and network namespaces are required" >&2
        exit 1
    fi
    exec env WANDERERS_SMOKE_IN_NETNS=1 GUIX="$guix_bin" \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        sh -c '"$1" link set lo up; exec "$2" "$3"' \
        sh "$ip_bin" "$0" "$wanderers_out"
fi

temporary=$(mktemp -d "${TMPDIR:-/tmp}/wanderers-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
home=$temporary/home
xdg_config=$temporary/config
xdg_cache=$temporary/cache
xdg_data=$temporary/data
xdg_state=$temporary/state
xdg_runtime=$temporary/runtime
work=$temporary/work
mkdir -p "$home" "$xdg_config" "$xdg_cache" "$xdg_data" "$xdg_state" \
    "$xdg_runtime" "$work"
chmod 700 "$xdg_runtime"

"$python_out/bin/python3" - "$wanderers_out" "$xorg_server_out/bin/Xvfb" \
    "$xwininfo_out/bin/xwininfo" "$xdotool_out/bin/xdotool" "$ip_bin" \
    "$home" "$xdg_config" "$xdg_cache" "$xdg_data" "$xdg_state" \
    "$xdg_runtime" "$work" <<'PY'
import hashlib
import os
import pathlib
import signal
import subprocess
import sys
import time


(out, xvfb, xwininfo, xdotool, ip, home, config, cache, data, state, runtime,
 work) = map(pathlib.Path, sys.argv[1:])


def tree_digest(root):
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        status = path.lstat()
        digest.update(str(path.relative_to(root)).encode())
        digest.update(repr((status.st_mode, status.st_size)).encode())
        if path.is_symlink():
            digest.update(os.readlink(path).encode())
        elif path.is_file():
            digest.update(path.read_bytes())
    return digest.digest()


def run(command, **kwargs):
    return subprocess.run(command, check=True, text=True, **kwargs)


assert (out / "bin" / "wanderers").is_file()
assert (out / "libexec" / "wanderers").is_file()
assert (out / "share" / "wanderers" / "data" / "tileset.bmp").is_file()
assert (out / "share" / "wanderers" / "data" / "dg" / "cave1.au").is_file()
assert "GNU GENERAL PUBLIC LICENSE" in (out / "share" / "doc" / "wanderers" / "COPYING").read_text()
readme = (out / "share" / "doc" / "wanderers" / "README.markdown").read_text()
assert "GPL3 license" in readme and "BSD 2-clause license" in readme
library = out / "share" / "doc" / "wanderers" / "lib"
for name in ("glcaml.ml", "glcaml.mli", "glcaml_stub.c", "win.ml", "win.mli"):
    assert "Redistribution and use in source and binary forms" in (library / name).read_text()
for name in ("sdl.ml", "sdl.mli", "sdl_stub.c"):
    assert "GNU Library General Public License version 2" in (library / name).read_text()
assert "permission is granted to anyone to use this software" in (library / "sdl.mli").read_text().lower()
assert (out / "share" / "doc" / "wanderers" / "OCamlMakefile").is_file()

# The namespace must contain only loopback, and Xvfb is explicitly forbidden
# from opening TCP.  The game itself has no network feature or service.
interfaces = run([str(ip), "-o", "link", "show"], stdout=subprocess.PIPE).stdout.splitlines()
assert len(interfaces) == 1 and " lo:" in interfaces[0], interfaces
before = tree_digest(out)

environment = {
    "HOME": str(home), "XDG_CONFIG_HOME": str(config),
    "XDG_CACHE_HOME": str(cache), "XDG_DATA_HOME": str(data),
    "XDG_STATE_HOME": str(state), "XDG_RUNTIME_DIR": str(runtime),
    "DISPLAY": ":99", "LIBGL_ALWAYS_SOFTWARE": "1",
    "SDL_AUDIODRIVER": "dummy", "SDL_JOYSTICK_DISABLED": "1",
    # The launcher uses absolute coreutils paths, so this proves it does not
    # accidentally depend on a host profile.
    "PATH": "", "LC_ALL": "C.UTF-8",
}
xserver = subprocess.Popen([str(xvfb), ":99", "-screen", "0", "1024x768x24",
                            "-nolisten", "tcp"], env=environment, cwd=work,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           start_new_session=True)
game = None
try:
    for _ in range(100):
        if subprocess.run([str(xwininfo), "-display", ":99", "-root"], env=environment,
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            break
        time.sleep(.05)
    else:
        raise AssertionError(xserver.stdout.read().decode())
    game = subprocess.Popen([str(out / "bin" / "wanderers"), "guix-smoke"],
                            env=environment, cwd=work, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, start_new_session=True)
    window = None
    for _ in range(160):
        result = subprocess.run([str(xdotool), "search", "--name", "^Wanderers$"],
                                env=environment, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL)
        if result.returncode == 0 and result.stdout.strip():
            window = result.stdout.splitlines()[0]
            break
        if game.poll() is not None:
            raise AssertionError(game.stdout.read().decode())
        time.sleep(.05)
    if window is None:
        raise AssertionError("Wanderers window did not appear")
    windows = run([str(xwininfo), "-display", ":99", "-root", "-tree"],
                  env=environment, stdout=subprocess.PIPE).stdout
    assert '"Wanderers"' in windows, windows
    run([str(xdotool), "key", "--window", window, "ctrl+q"], env=environment)
    game.wait(timeout=10)
    assert game.returncode == 0, game.stdout.read().decode()
finally:
    for process in (game, xserver):
        if process is not None and process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)

user_data = data / "wanderers"
assert user_data.is_dir()
asset_link = user_data / "data"
assert asset_link.is_symlink() and asset_link.resolve() == out / "share" / "wanderers" / "data"
assert (user_data / "game.save").is_file()
assert tree_digest(out) == before
PY
