#!/bin/sh
# Genuine installed ASCII UI proof. Usage: sh tests/gearhead2-smoke.sh [OUTPUT]
# GUIX selects Guix; GEARHEAD2_EVIDENCE_DIR must be a new/empty directory.
set -eu
umask 077
fail() { printf 'gearhead2-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -le 1 || { echo "usage: $0 [OUTPUT]" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -eq 1; then out=$1; else
    out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts gearhead2)
fi
out=$(realpath -e -- "$out")
test -x "$out/bin/gearhead2" || fail 'missing ordinary installed launcher'
for directory in gamedata design series doc; do
    test -d "$out/share/gearhead2/$directory" || fail "missing text data directory: $directory"
done
for notice in license.txt readme.txt history.txt Credits.txt SOURCE-PROVENANCE fpc-rtl/COPYING fpc-rtl/COPYING.FPC; do
    test -s "$out/share/doc/gearhead2/$notice" || fail "missing source notice: $notice"
done
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'output contains writable files'
test -z "$(find "$out" -iname '*.png' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.fon' -o -iname 'libSDL*')" || fail 'ASCII output contains images, fonts or SDL libraries'
scratch=$(mktemp -d "${TMPDIR:-/tmp}/gearhead2-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
root=$scratch/root
mkdir -- "$root"
evidence=${GEARHEAD2_EVIDENCE_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/gearhead2-evidence.XXXXXXXX")}
evidence=$(realpath -m -- "$evidence")
case "$evidence/" in
    /gnu/store/*|"$out/"*|"$scratch/"*) fail 'evidence must be outside store, output and scratch' ;;
esac
mkdir -p -- "$evidence"
test -z "$(find "$evidence" -mindepth 1 -maxdepth 1 -print -quit)" || fail 'evidence directory must be empty'
before=$("$guix_bin" hash -rx "$out")
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
status=0
# Realize Python/pyte, X11 and all namespace/screenshot tools BEFORE going offline.
"$guix_bin" shell --pure --no-grafts python python-pyte xorg-server xterm \
    imagemagick util-linux coreutils bash-minimal binutils -- bash -c '
        set -eu
        python_bin=$(realpath -e -- "$(command -v python3)")
        unshare_bin=$(realpath -e -- "$(command -v unshare)")
        timeout_bin=$(realpath -e -- "$(command -v timeout)")
        mount_bin=$(realpath -e -- "$(command -v mount)")
        GEARHEAD2_XVFB=$(realpath -e -- "$(command -v Xvfb)")
        GEARHEAD2_XTERM=$(realpath -e -- "$(command -v xterm)")
        GEARHEAD2_IMPORT=$(realpath -e -- "$(command -v import)")
        export GEARHEAD2_XVFB GEARHEAD2_XTERM GEARHEAD2_IMPORT
        "$python_bin" -B -c "import pyte"
        # Inspect every installed ELF, not only the shell launcher.
        "$python_bin" -B -c '\''
import pathlib, subprocess, sys
out = pathlib.Path(sys.argv[1])
for path in out.rglob("*"):
    if path.is_file():
        with path.open("rb") as stream:
            elf = stream.read(4) == b"\x7fELF"
        if elf:
            dynamic = subprocess.check_output(["readelf", "-d", str(path)])
            if b"SDL" in dynamic:
                raise SystemExit("ASCII executable links SDL: " + str(path))
'\'' "$2"
        # A refused namespace or read-only mount is fatal, never downgraded.
        # Keep the real UID: root-mapped xterm initgroups conflicts with the
        # single-user namespace mapping. Capabilities permit the private mount.
        exec "$timeout_bin" --kill-after=10 300 \
            "$unshare_bin" --user --map-current-user --keep-caps --mount \
                --net --pid --fork --kill-child \
            bash -c '\''
                set -eu
                "$1" --make-rprivate /
                "$1" --bind /gnu/store /gnu/store
                "$1" -o remount,bind,ro /gnu/store
                exec "$2" -B "$3" "$4/bin/gearhead2" "$5" "$6"
            '\'' gearhead2-offline "$mount_bin" "$python_bin" "$1" "$2" "$3" "$4"
    ' gearhead2-smoke "$channel_dir/tests/gearhead2-pty-runner.py" \
    "$out" "$root" "$channel_dir/tests/gearhead2-save-reader.py" \
    >"$evidence/launcher.log" 2>&1 || status=$?
# Preserve native saves/logs even when gameplay fails; hash after failure too.
after=$("$guix_bin" hash -rx "$out")
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
cp -a -- "$root" "$evidence/isolated"
cat "$evidence/launcher.log"
printf 'GearHead2 evidence: %s\n' "$evidence"
test "$before" = "$after" || fail 'installed output changed during gameplay'
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'output became writable'
test "$status" -eq 0 || fail "offline native proof failed ($status); see retained evidence"
test -s "$evidence/isolated/proof/receipt.json" || fail 'no proof receipt'
test -s "$evidence/isolated/proof/screenshot.png" || fail 'no live terminal screenshot'
printf '%s\n' 'GEARHEAD2_GUIX_SMOKE_OK'
