#!/bin/sh
# Drive the ordinary native ChessRogue launcher; never build the target.
set -eu
umask 077
if test "$#" -ne 2; then
    echo "usage: $0 OUTPUT EVIDENCE (prebuilt store output; fresh absolute directory)" >&2
    exit 64
fi
case "$1" in /gnu/store/*) ;; *) echo 'OUTPUT must be an absolute store path' >&2; exit 64 ;; esac
case "$2" in /*) ;; *) echo 'EVIDENCE must be absolute' >&2; exit 64 ;; esac
guix_bin=$(command -v "${GUIX:-guix}") || { echo 'GUIX executable not found' >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd) || { echo 'cannot resolve native consumer directory' >&2; exit 1; }
out=$(realpath -e -- "$1") || { echo 'OUTPUT cannot be resolved' >&2; exit 64; }
case "$out" in /gnu/store/*/*) echo 'OUTPUT must be a store item, not a subdirectory' >&2; exit 64 ;; /gnu/store/*) ;; *) echo 'resolved OUTPUT is outside the store' >&2; exit 64 ;; esac
test -d "$out" || { echo "OUTPUT is not a directory: $out" >&2; exit 64; }
test -x "$out/bin/chessrogue" || { echo "missing launcher: $out/bin/chessrogue" >&2; exit 1; }
test -x "$out/libexec/chessrogue" || { echo "missing native executable: $out/libexec/chessrogue" >&2; exit 1; }
evidence=$(realpath -m -- "$2") || { echo 'EVIDENCE cannot be resolved' >&2; exit 64; }
case "$evidence/" in /gnu/store/*|"$out/"*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
if test -e "$evidence" || test -L "$evidence"; then
    echo 'EVIDENCE must not already exist' >&2
    exit 64
fi
mkdir -p -- "$(dirname -- "$evidence")" || { echo 'cannot create evidence parent' >&2; exit 1; }
mkdir -- "$evidence" || { echo 'cannot create fresh evidence directory' >&2; exit 1; }
# Installed payload: existence only; Python owns canonical content checks.
test -s "$out/share/chessrogue/crkeymap.txt" || { echo 'missing installed runtime keymap' >&2; exit 1; }
for file in COPYING.txt COPYING.pcre.txt COPYING.sdl.txt README.txt \
    INSTALL.txt CHANGELOG.txt HINTS.txt crkeymap.txt kaya/COPYING kaya/GPL2 \
    kaya/GPL3 kaya/LGPL2.1 kaya/LGPL3 kaya/compiler/COPYING; do
    test -s "$out/share/doc/chessrogue/$file" || { echo "missing installed document: $file" >&2; exit 1; }
done
test -r "$channel_dir/tests/chessrogue-native.py" || { echo 'native consumer is not readable' >&2; exit 1; }
find_output ()
{
    for output in $("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 "$2"); do
        if test -e "$output/$1"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "missing $1 in Guix prerequisite $2" >&2
    return 1
}
# Realize only consumer tools, serially, before offline ordinary gameplay.
core=$(find_output bin/env coreutils)
util=$(find_output bin/unshare util-linux)
python=$(find_output bin/python3 python)
pyte=$(find_output lib python-pyte)
wcwidth=$(find_output lib python-wcwidth)
pythonpath=
for package in "$pyte" "$wcwidth"; do
    for directory in "$package"/lib/python*/site-packages; do
        test -d "$directory" || { echo "missing Python consumer site-packages: $directory" >&2; exit 1; }
        pythonpath=${pythonpath:+$pythonpath:}$directory
    done
done
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" > "$evidence/output-before.nar-hash"
status=0
"$core/bin/env" -i PATH='' LC_ALL=C PYTHONPATH="$pythonpath" \
    PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 MOUNT="$util/bin/mount" \
    HOST_UID="$("$core/bin/id" -u)" HOST_GID="$("$core/bin/id" -g)" \
    HOST_USER_NS="$("$core/bin/readlink" /proc/self/ns/user)" \
    HOST_MOUNT_NS="$("$core/bin/readlink" /proc/self/ns/mnt)" \
    HOST_PID_NS="$("$core/bin/readlink" /proc/self/ns/pid)" \
    HOST_NET_NS="$("$core/bin/readlink" /proc/self/ns/net)" \
    "$core/bin/timeout" --kill-after=5 300 \
    "$util/bin/unshare" --user --map-current-user --keep-caps --mount \
    --propagation private --net --pid --mount-proc --kill-child --fork \
    "$python/bin/python3" -B -s "$channel_dir/tests/chessrogue-native.py" \
    "$out" "$evidence" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" > "$evidence/output-after.nar-hash"
if test "$before" != "$after"; then
    echo 'ChessRogue output NAR changed during ordinary gameplay' >&2
    exit 1
fi
test "$status" -eq 0 || exit "$status"
printf '%s\n' "CHESSROGUE_NATIVE_OK evidence=$evidence"
