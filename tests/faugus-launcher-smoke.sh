#!/bin/sh
# External consumer of the normal installed GTK launcher.  The driver observes
# AT-SPI labels and sends X11 input; it never imports or rewrites Faugus state.
set -eu
if test "$#" -ne 2; then
    echo "usage: GUIX=guix $0 OUTPUT EVIDENCE (fresh directory)" >&2
    exit 64
fi
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -e -- "$1")
evidence=$(realpath -m -- "$2")
case "$out" in /gnu/store/*) ;; *) echo 'OUTPUT must be a store output' >&2; exit 64 ;; esac
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
test -x "$out/bin/faugus-launcher"
test -f "$out/share/licenses/faugus-launcher/LICENSE"
test -f "$out/share/licenses/faugus-launcher/ASSETS-LICENSE"
test ! -e "$evidence"
mkdir -p -- "$evidence"
find_output ()
{
    executable=$1
    shift
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 --keep-failed "$@"); do
        if test -e "$output/$executable"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "cannot resolve proof dependency $executable ($*)" >&2
    return 1
}
# All dependency/store resolution and actual NAR serialization are outside the
# offline namespace.  Hidden at-spi2-core is selected by its module binding.
python_out=$(find_output bin/python3 python)
pygobject_out=$(find_output lib python-pygobject)
glib_out=$(find_output lib/girepository-1.0 glib)
atspi_out=$(find_output lib/girepository-1.0/Atspi-2.0.typelib \
    -e '(@ (gnu packages gtk) at-spi2-core)')
# Atspi-2.0 requires DBus-1.0 (and GLib's GIRepository needs its base
# typelibs), which gobject-introspection's runtime output installs.
gi_out=$(find_output lib/girepository-1.0/DBus-1.0.typelib gobject-introspection)
xorg_out=$(find_output bin/Xvfb xorg-server)
xdotool_out=$(find_output bin/xdotool xdotool)
wm_out=$(find_output bin/openbox openbox)
image_out=$(find_output bin/import imagemagick)
dbus_out=$(find_output bin/dbus-daemon dbus)
coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
font_out=$(find_output share/fonts font-dejavu)
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/faugus-native.XXXXXX")
trap '"$coreutils_out/bin/rm" -rf "$scratch"' EXIT HUP INT TERM
before=$("$guix_bin" hash -S nar "$out")
status=0
"$coreutils_out/bin/env" -i LC_ALL=C.UTF-8 PATH="$coreutils_out/bin" \
    PYTHONDONTWRITEBYTECODE=1 \
    HOST_UID="$("$coreutils_out/bin/id" -u)" \
    HOST_GID="$("$coreutils_out/bin/id" -g)" \
    HOST_NET_NS="$("$coreutils_out/bin/readlink" /proc/self/ns/net)" \
    "$coreutils_out/bin/timeout" --kill-after=10 300 \
    "$util_linux_out/bin/unshare" --user --map-current-user --keep-caps \
    --mount --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python_out/bin/python3" -B "$channel_dir/tests/faugus-native-driver.py" \
    "$out" "$evidence" "$scratch" "$pygobject_out" "$glib_out" "$atspi_out" \
    "$xorg_out/bin/Xvfb" "$xdotool_out/bin/xdotool" "$image_out/bin/import" \
    "$image_out/bin/convert" "$dbus_out/bin/dbus-daemon" \
    "$util_linux_out/bin/mount" "$font_out" "$coreutils_out/bin/true" \
    "$wm_out/bin/openbox" "$gi_out" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
"$python_out/bin/python3" - "$evidence" "$status" "$before" "$after" <<'PY'
import json
from pathlib import Path
import sys
root, status, before, after = sys.argv[1:]
path = Path(root) / 'evidence.json'
record = json.loads(path.read_text()) if path.exists() else {
    'status': 'failed', 'error': 'driver ended without final evidence'}
record.update(exit_status=int(status), output_nar_before=before,
              output_nar_after=after, output_unchanged=before == after)
if int(status) or before != after:
    record['status'] = 'failed'
path.write_text(json.dumps(record, indent=2) + '\n')
sys.exit(0 if record['status'] == 'passed' else 1)
PY
printf 'Faugus native GUI proof passed; evidence: %s\n' "$evidence"
