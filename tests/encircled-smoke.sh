#!/bin/sh
# External native consumer: tests/encircled-smoke.sh OUTPUT EVIDENCE
# OUTPUT is prebuilt; EVIDENCE must be fresh.  Generic tools are realized before
# isolation.  Acceptance is a strict read-only NAR check plus the native driver.
set -eu
umask 077
test "$#" -eq 2 || { echo "usage: $0 OUTPUT EVIDENCE" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# OUTPUT must already be absolute and canonical; reject symlinks.
case "$1" in /*) ;; *) echo 'OUTPUT must be an absolute path' >&2; exit 64 ;; esac
case "$1" in */) echo 'OUTPUT must not end with /' >&2; exit 64 ;; esac
package=$(CDPATH= cd -P -- "$1" && pwd)
if test "$package" != "$1"; then
    echo "OUTPUT must be canonical ($package)" >&2
    exit 64
fi
if test -L "$1"; then
    echo 'OUTPUT must not be a symlink' >&2
    exit 64
fi
store_name=${package#/gnu/store/}
case "$package" in /gnu/store/*) ;; *) echo 'OUTPUT must be a store output' >&2; exit 64 ;; esac
case "$store_name" in */*) echo 'OUTPUT must be a direct store output' >&2; exit 64 ;; esac
store_hash=${store_name%%-*}
case "$store_hash" in *[!0-9abcdfghijklmnpqrsvwxyz]*) echo 'Invalid Guix store hash' >&2; exit 64 ;; esac
test "${#store_hash}" -eq 32 || { echo 'Invalid Guix store hash length' >&2; exit 64; }
case "${store_name#*-}" in encircled-?*) ;; *) echo 'OUTPUT must be an encircled output' >&2; exit 64 ;; esac
test -x "$package/bin/encircled" || { echo 'OUTPUT lacks executable bin/encircled' >&2; exit 64; }
# EVIDENCE must be absolute, fresh (including dangling symlinks), canonical
# parent, outside /gnu/store, with no trailing / or . / .. components.
case "$2" in
    /*) ;;
    *) echo 'EVIDENCE must be an absolute path' >&2; exit 64 ;;
esac
case "$2" in
    //*) echo 'EVIDENCE must be canonical' >&2; exit 64 ;;
    */./*|*/../*|*//*) echo 'EVIDENCE must have canonical components' >&2; exit 64 ;;
    */) echo 'EVIDENCE must not end with /' >&2; exit 64 ;;
    */.) echo 'EVIDENCE must not end with .' >&2; exit 64 ;;
    */..) echo 'EVIDENCE must not end with ..' >&2; exit 64 ;;
    /.) echo 'EVIDENCE must not be .' >&2; exit 64 ;;
    /..) echo 'EVIDENCE must not be ..' >&2; exit 64 ;;
esac
parent=$(dirname -- "$2")
test -d "$parent" || { echo 'EVIDENCE parent directory missing' >&2; exit 64; }
parent=$(CDPATH= cd -P -- "$parent" && pwd)
case "$parent" in
    /) evidence="$2" ;;
    *) evidence="$parent/$(basename -- "$2")" ;;
esac
if test "$evidence" != "$2"; then
    echo "EVIDENCE parent must be canonical ($evidence)" >&2
    exit 64
fi
case "$evidence" in /gnu/store|/gnu/store/*) echo 'EVIDENCE must be outside the store' >&2; exit 64 ;; esac
test ! -e "$evidence" && test ! -L "$evidence" || { echo 'EVIDENCE must be fresh and nonexistent' >&2; exit 64; }
# Never realize Encircled or its source here; resolve only generic test tools.
guix_bin=$(command -v "${GUIX:-guix}") || { echo 'GUIX executable not found' >&2; exit 127; }
guix_bin=$(CDPATH= cd -- "$(dirname -- "$guix_bin")" && pwd)/$(basename -- "$guix_bin")
test -x "$guix_bin" || { echo 'GUIX is not executable' >&2; exit 127; }
mkdir -- "$2"
# Realize tools first; never build Encircled.
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- true
"$guix_bin" gc -R "$package" >"$evidence/runtime-closure.txt"
before=$("$guix_bin" hash -S nar "$package")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
printf '%s\n' "$package" >"$evidence/store-output.txt"
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    env PYTHONNOUSERSITE=1 python3 -s -B "$channel_dir/tests/encircled-native.py" \
    "$package" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$package")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
printf '%s\n' "$status" >"$evidence/consumer-exit-status.txt"
if test "$before" != "$after"; then
    echo "Encircled store NAR changed; evidence: $evidence" >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "Encircled native consumer failed ($status); evidence: $evidence" >&2
    exit "$status"
fi
printf 'Encircled unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$evidence"
