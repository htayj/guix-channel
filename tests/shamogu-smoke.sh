#!/bin/sh
# Installed native Shamogu proof, offline namespaces and unchanged store NAR.
# Usage: sh tests/shamogu-smoke.sh [SHAMOGU-OUTPUT]
# GUIX selects Guix; SHAMOGU_EVIDENCE_DIR selects a new/empty proof directory.
set -eu
umask 077
fail() { printf 'shamogu-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -le 1 || { echo "usage: $0 [SHAMOGU-OUTPUT]" >&2; exit 64; }
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -eq 1; then
    out=$1
else
    out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts shamogu)
fi
out=$(realpath -e -- "$out")
test -d "$out" || fail 'output is not a directory'
test -x "$out/bin/shamogu" || fail 'missing installed Shamogu executable'
for license in LICENSE README.md CHANGES.md go.mod go.sum tiles/LICENSE tiles/README; do
    test -s "$out/share/doc/shamogu/$license" || fail "missing installed license/document: $license"
done
for module in codeberg.org/anaseto/gruid codeberg.org/anaseto/gruid-js \
    codeberg.org/anaseto/gruid-sdl codeberg.org/anaseto/gruid-tcell \
    github.com/gdamore/tcell/v2 github.com/gdamore/encoding \
    github.com/lucasb-eyer/go-colorful golang.org/x/image golang.org/x/sys \
    golang.org/x/term golang.org/x/text; do
    test -s "$out/share/doc/shamogu/modules/$module/LICENSE" || fail "missing module license: $module"
done
test -s "$out/share/doc/shamogu/modules/github.com/rivo/uniseg/LICENSE.txt" || fail 'missing uniseg license'
test -s "$out/share/doc/shamogu/modules/codeberg.org/anaseto/gruid-sdl/sdl2/LICENSE" || fail 'missing nested SDL binding notice'
for module in image sys term text; do
    test -s "$out/share/doc/shamogu/modules/golang.org/x/$module/PATENTS" || fail "missing Go patent grant: $module"
done
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'output contains writable files'

scratch=$(mktemp -d "${TMPDIR:-/tmp}/shamogu-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
root=$scratch/root
mkdir -- "$root"
evidence=${SHAMOGU_EVIDENCE_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/shamogu-evidence.XXXXXXXX")}
evidence=$(realpath -m -- "$evidence")
case "$evidence/" in
    /gnu/store/*|"$out/"*|"$scratch/"*) fail 'evidence must be outside the store, output and scratch directory' ;;
esac
mkdir -p -- "$evidence"
test -z "$(find "$evidence" -mindepth 1 -maxdepth 1 -print -quit)" || fail 'evidence directory must be new or empty'
before=$("$guix_bin" hash -rx "$out")
printf '%s\n' "$before" >"$evidence/output-before.nar-hash"
status=0
# Realize every proof dependency before entering the network namespace. --pure
# supplies pyte's Guix Python search path without consulting a host user profile.
"$guix_bin" shell --pure --no-grafts python python-pyte xorg-server xterm \
    imagemagick util-linux coreutils bash-minimal go -- bash -c '
        set -eu
        python_bin=$(realpath -e -- "$(command -v python3)")
        unshare_bin=$(realpath -e -- "$(command -v unshare)")
        timeout_bin=$(realpath -e -- "$(command -v timeout)")
        SHAMOGU_XVFB=$(realpath -e -- "$(command -v Xvfb)")
        SHAMOGU_XTERM=$(realpath -e -- "$(command -v xterm)")
        SHAMOGU_IMPORT=$(realpath -e -- "$(command -v import)")
        export SHAMOGU_XVFB SHAMOGU_XTERM SHAMOGU_IMPORT
        "$python_bin" -B -c "import pyte"
        export GOTOOLCHAIN=local GOPROXY=off GOSUMDB=off GO111MODULE=off
        export GOCACHE="$3/go-cache"
        mkdir -p "$3"
        go build -trimpath -o "$3/shamogu-save-reader" "$4"
        # No fallback: a refused namespace or any helper failure is fatal.
        # Preserve the host UID: root-mapped xterm calls initgroups, which
        # conflicts with unshare single-user mappings denying setgroups.
        exec "$timeout_bin" --kill-after=10 180 \
            "$unshare_bin" --user --map-current-user --net --pid --fork --kill-child \
            "$python_bin" -B "$1" "$2" "$3"
    ' shamogu-smoke "$channel_dir/tests/shamogu-pty-runner.py" \
    "$out/bin/shamogu" "$root" "$channel_dir/tests/shamogu-save-reader.go" >"$evidence/launcher.log" 2>&1 || status=$?
# Hash after failed gameplay too, and retain any captured native proof before
# removing the helper-owned isolated HOME/XDG tree.
after=$("$guix_bin" hash -rx "$out")
printf '%s\n' "$after" >"$evidence/output-after.nar-hash"
if test -d "$root/proof"; then
    cp -a -- "$root/proof" "$evidence/proof"
fi
cat "$evidence/launcher.log"
printf 'Shamogu evidence: %s\n' "$evidence"
test "$before" = "$after" || fail 'installed output changed during native gameplay'
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'output contains writable files after gameplay'
test "$status" -eq 0 || fail "isolated native proof failed ($status); see $evidence/launcher.log"
test -s "$evidence/proof/receipt.json" || fail 'helper produced no proof receipt'
test -s "$evidence/proof/screenshot.png" || fail 'helper produced no native screenshot'
printf '%s\n' 'SHAMOGU_GUIX_SMOKE_OK'
