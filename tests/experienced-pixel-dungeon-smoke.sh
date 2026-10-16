#!/bin/sh
# Ordinary graphical consumer; OUTPUT must already be built. Never builds the game.
# GUIX=/absolute/path/to/guix sh tests/experienced-pixel-dungeon-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (fresh canonical absolute path)" >&2
    exit 64
fi
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
find_output ()
{
    file=$1
    shift
    for output in $("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 "$@"); do
        if test -e "$output/$file"; then printf '%s\n' "$output"; return 0; fi
    done
    echo "cannot resolve $file from Guix selector $*" >&2
    return 1
}
game_out=$(realpath -e -- "$1")
test "$game_out" = "$1" || { echo 'OUTPUT must be canonical' >&2; exit 64; }
case "$game_out" in
    /gnu/store/*) test "$(dirname -- "$game_out")" = /gnu/store ;;
    *) echo 'OUTPUT must be a direct store item' >&2; exit 64 ;;
esac
test -x "$game_out/bin/experienced-pixel-dungeon"
evidence=$(realpath -m -- "$2")
if test "$evidence" != "$2" || test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must be a fresh nonexistent canonical absolute path' >&2; exit 64
fi
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside store' >&2; exit 64 ;; esac
# Resolve the complete observer/tool closure before isolation. No network inside.
coreutils=$(find_output bin/env coreutils)
findutils=$(find_output bin/find findutils)
util_linux=$(find_output bin/unshare util-linux)
# Select bindings from the same upstream Guix modules, never ambiguous package
# names contributed by another channel with a different Python ABI.
python=$(find_output bin/python3 \
    '--expression=(@ (gnu packages python) python)')
pillow=$(find_output / \
    '--expression=(@ (gnu packages python-xyz) python-pillow)')
numpy=$(find_output / \
    '--expression=(@ (gnu packages python-xyz) python-numpy)')
test -x "$python/bin/python3"
xorg=$(find_output bin/Xvfb xorg-server)
xdotool=$(find_output bin/xdotool xdotool)
xlib=$(find_output lib/libX11.so.6 libx11)
ocr=$(find_output bin/tesseract tesseract-ocr)
pulse=$(find_output bin/pulseaudio pulseaudio)
test -x "$pulse/bin/pactl"
test -x "$pulse/bin/parec"
modules=
for directory in "$pillow"/lib/python*/site-packages "$numpy"/lib/python*/site-packages; do
    test -d "$directory"
    modules=${modules:+$modules:}$directory
done
mkdir -p -- "$evidence"
before=$("$guix_bin" hash -S nar "$game_out")
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
status=0
"$coreutils/bin/env" -i LC_ALL=C PATH="" PYTHON_SITE_PACKAGES="$modules" \
    XVFB="$xorg/bin/Xvfb" MOUNT="$util_linux/bin/mount" \
    XDOTOOL="$xdotool/bin/xdotool" LIBX11="$xlib/lib/libX11.so.6" \
    TESSERACT="$ocr/bin/tesseract" \
    PULSEAUDIO="$pulse/bin/pulseaudio" PACTL="$pulse/bin/pactl" PAREC="$pulse/bin/parec" \
    HOST_UID="$("$coreutils/bin/id" -u)" HOST_GID="$("$coreutils/bin/id" -g)" \
    HOST_USER_NS="$("$coreutils/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$coreutils/bin/readlink" /proc/self/ns/mnt)" \
    HOST_NET_NS="$("$coreutils/bin/readlink" /proc/self/ns/net)" \
    HOST_PID_NS="$("$coreutils/bin/readlink" /proc/self/ns/pid)" \
    "$coreutils/bin/timeout" --kill-after=15 600 \
    "$util_linux/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -I -S -B "$channel_dir/tests/experienced-pixel-dungeon-native.py" \
    "$game_out" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$game_out")
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
"$python/bin/python3" -I -S -B - "$game_out" "$evidence" "$before" "$after" "$status" <<'PY'
import json
from pathlib import Path
import sys
output, evidence, before, after, status = sys.argv[1:]
root = Path(evidence)
record = json.loads((root / 'native-gameplay.json').read_text()) if (root / 'native-gameplay.json').exists() else {}
success = int(status) == 0 and before == after and record.get('success') is True
(root / 'consumer-receipt.json').write_text(json.dumps(dict(
    output=output, driver_status=int(status), nar_before=before, nar_after=after,
    output_unchanged=before == after, success=success), indent=2) + '\n')
if not success:
    sys.exit(1)
PY
"$findutils/bin/find" "$evidence" -type f -exec "$coreutils/bin/chmod" a-w -- {} +
printf '%s\n' "EXPPD_NATIVE_GAMEPLAY_OK evidence=$evidence"
