#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# External consumers only; no installed test hook or replacement renderer.
# Usage: sh tests/bodge-nuklear-smoke.sh BODGE-NUKLEAR-OUTPUT EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "bodge-nuklear smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'expected prebuilt wrapper store output' ;; esac
test -d "$out/etc/xdg/common-lisp" || fail 'missing installed ASDF configuration'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${NUKLEAR_PROOF_ENV:-}" != ready; then
    blob=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 -L "$channel_dir/guix" \
        -e '(begin (use-modules (tay packages bodge-nuklear)) sbcl-nuklear-blob)')
    fonts=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 font-misc-misc)
    aliases=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 font-alias)
    x11_outputs=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 libx11)
    x11=
    for candidate in $x11_outputs; do
        case "$candidate" in /gnu/store/*) ;; *) fail 'unexpected libx11 output path' ;; esac
        if test -f "$candidate/lib/libX11.so.6"; then
            test -z "$x11" || fail 'multiple libx11 outputs contain native library'
            x11=$candidate
        fi
    done
    test -n "$x11" || fail 'no realized libx11 output contains native library'
    exec "$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
        python python-xlib sbcl gcc-toolchain libx11 xorg-server xdotool imagemagick \
        font-misc-misc font-alias binutils glibc util-linux coreutils findutils bash-minimal \
        --preserve='^(GUIX|NUKLEAR_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" NUKLEAR_PROOF_ENV=ready NUKLEAR_BLOB="$blob" \
        NUKLEAR_FONTS="$fonts" NUKLEAR_ALIASES="$aliases" NUKLEAR_X11="$x11" \
        sh "$channel_dir/tests/bodge-nuklear-smoke.sh" "$out" "$2"
fi
for cmd in python3 sbcl gcc ldd readelf nm timeout unshare mount find Xvfb xdotool import convert stdbuf; do
    command -v "$cmd" >/dev/null || fail "missing proof dependency: $cmd"
done
blob=$(realpath -- "$NUKLEAR_BLOB")
case "$blob" in /gnu/store/*) ;; *) fail 'expected realized blob store output' ;; esac
test -f "$blob/lib/x86_64/libnuklear.so" || fail 'missing delivered native library'
test -f "$blob/share/bodge-nuklear/demo/x11/main.c" || fail 'missing original X11 demo'
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
for installed in "$out" "$blob"; do
    case "$evidence/" in "$installed/"*) fail 'evidence must be outside installed outputs' ;; esac
    test -z "$(find "$installed" -type f -perm /222 -print -quit)" || fail 'writable installed files'
done
before_out=$("$guix_bin" hash -S nar "$out")
before_blob=$("$guix_bin" hash -S nar "$blob")
printf '%s\n' "$before_out" >"$evidence/wrapper-nar-before.txt"
printf '%s\n' "$before_blob" >"$evidence/blob-nar-before.txt"
for ns in user net mnt pid ipc; do
    value=$(readlink "/proc/self/ns/$ns")
    case "$ns" in
        user) export NUKLEAR_HOST_USER="$value" ;;
        net) export NUKLEAR_HOST_NET="$value" ;;
        mnt) export NUKLEAR_HOST_MNT="$value" ;;
        pid) export NUKLEAR_HOST_PID="$value" ;;
        ipc) export NUKLEAR_HOST_IPC="$value" ;;
    esac
done
export NUKLEAR_HOST_UID=$(id -ru)
export NUKLEAR_HOST_EUID=$(id -u)
unset LD_PRELOAD LD_LIBRARY_PATH CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS SBCL_HOME
status=0
timeout --kill-after=5 240 \
    unshare --user --map-current-user --keep-caps --net --mount --ipc \
    --mount-proc --pid --fork --kill-child \
    python3 "$channel_dir/tests/bodge-nuklear-smoke.py" "$out" "$evidence" "$blob" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after_out=$("$guix_bin" hash -S nar "$out")
after_blob=$("$guix_bin" hash -S nar "$blob")
printf '%s\n' "$after_out" >"$evidence/wrapper-nar-after.txt"
printf '%s\n' "$after_blob" >"$evidence/blob-nar-after.txt"
test "$before_out" = "$after_out" || fail 'installed wrapper NAR changed'
test "$before_blob" = "$after_blob" || fail 'installed blob NAR changed'
for installed in "$out" "$blob"; do
    test -z "$(find "$installed" -type f -perm /222 -print -quit)" || fail 'installed files became writable'
done
test "$status" -eq 0 || fail "native consumer failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'native consumer receipt missing'
python3 - "$evidence/proof.json" "$before_out" "$after_out" "$before_blob" "$after_blob" <<'PY'
import json
from pathlib import Path
import sys
path = Path(sys.argv[1])
receipt = json.loads(path.read_text())
receipt["nar"] = {
    "wrapper": {"before": sys.argv[2], "after": sys.argv[3], "unchanged": sys.argv[2] == sys.argv[3]},
    "blob": {"before": sys.argv[4], "after": sys.argv[5], "unchanged": sys.argv[4] == sys.argv[5]},
}
path.write_text(json.dumps(receipt, indent=2) + "\n")
PY
printf '%s\n' 'bodge-nuklear smoke: installed SBCL systems, font/context/input/button/text/clear; original X11 demo linked to delivered library, rendered pixels, button activation and clean WM_DELETE_WINDOW; offline same-UID namespaces, read-only store, both NARs unchanged'
