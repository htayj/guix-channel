#!/bin/sh
# External consumer only.  OUTPUT is already built; EVIDENCE is fresh.
# GUIX=/absolute/path/to/guix sh tests/faangband-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
test "$#" -eq 2 || { echo "usage: $0 OUTPUT EVIDENCE" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
guix_bin=$(command -v "${GUIX:-guix}")
output=$(realpath -e -- "$1")
test "$output" = "$1" && test "$(dirname -- "$output")" = /gnu/store || {
    echo 'OUTPUT must be a canonical direct /gnu/store output' >&2; exit 64;
}
test -x "$output/bin/faangband"
evidence=$(realpath -m -- "$2")
test "$evidence" = "$2" && test ! -e "$evidence" && test ! -L "$evidence" || {
    echo 'EVIDENCE must be a fresh nonexistent canonical absolute path' >&2; exit 64;
}
case "$evidence/" in /gnu/store/*) echo 'EVIDENCE must be outside store' >&2; exit 64 ;; esac
find_output () {
    file=$1
    shift
    for item in $("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$@"); do
        if test -e "$item/$file"; then printf '%s\n' "$item"; return 0; fi
    done
    echo "cannot resolve external observer tool: $file" >&2
    return 1
}
# Only generic observer tools are realized here, never FAangband or its source.
python=$(find_output bin/python3 '--expression=(@ (gnu packages python) python)')
pyte=$(find_output / '--expression=(@ (gnu packages python-xyz) python-pyte)')
wcwidth=$(find_output / '--expression=(@ (gnu packages python-xyz) python-wcwidth)')
pillow=$(find_output / '--expression=(@ (gnu packages python-xyz) python-pillow)')
unshare=$(find_output bin/unshare util-linux)
xorg=$(find_output bin/Xvfb xorg-server)
xlib=$(find_output lib/libX11.so.6 libx11)
xdotool=$(find_output bin/xdotool xdotool)
pulse=$(find_output bin/pulseaudio pulseaudio)
ocr=$(find_output bin/tesseract tesseract-ocr)
modules=
for directory in "$pyte"/lib/python*/site-packages "$wcwidth"/lib/python*/site-packages "$pillow"/lib/python*/site-packages; do
    test -d "$directory"
    modules=${modules:+$modules:}$directory
done
mkdir -p -- "$evidence"
printf '%s\n' "$output" >"$evidence/store-output.txt"
"$guix_bin" gc -R "$output" >"$evidence/runtime-closure.txt"
before=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
status=0
# The driver records and checks each native process's namespaces and identity.
PYTHON_SITE_PACKAGES="$modules" UNSHARE="$unshare/bin/unshare" \
XVFB="$xorg/bin/Xvfb" LIBX11="$xlib/lib/libX11.so.6" \
XDOTOOL="$xdotool/bin/xdotool" TESSERACT="$ocr/bin/tesseract" \
PULSEAUDIO="$pulse/bin/pulseaudio" PACTL="$pulse/bin/pactl" PAREC="$pulse/bin/parec" \
    "$python/bin/python3" -I -S -B "$channel_dir/tests/faangband-native.py" \
    "$output" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$output")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
printf '%s\n' "$status" >"$evidence/consumer-exit-status.txt"
"$python/bin/python3" -I -S -B - "$evidence" "$before" "$after" "$status" <<'PY'
import json
from pathlib import Path
import sys
root, before, after, status = sys.argv[1:]
root = Path(root)
path = root / 'native-gameplay.json'
proof = json.loads(path.read_text()) if path.exists() else {}
success = int(status) == 0 and before == after and proof.get('success') is True
(root / 'consumer-receipt.json').write_text(json.dumps(dict(
    success=success, nar_before=before, nar_after=after,
    output_unchanged=before == after, driver_status=int(status)), indent=2) + '\n')
if not success:
    sys.exit(1)
PY
printf 'FAangband native lifecycle, SDL2 audio and unchanged NAR: %s\nEvidence: %s\n' "$after" "$evidence"
