#!/bin/sh
# External one-shot consumer; never build the game or generic tools here.
# GUIX=guix sh tests/clojure-roguelike-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
fail() { printf 'clojure-roguelike-smoke: %s\n' "$*" >&2; exit 1; }
test "$#" -eq 2 || {
    printf 'usage: GUIX=guix sh %s OUTPUT EVIDENCE\n' "$0" >&2
    exit 64
}
# Resolve every executable before isolation. Overrides name commands or absolute
# executables already installed by the caller; no implicit realization occurs.
guix_bin=$(command -v "${GUIX:-guix}") || fail 'GUIX executable not found'
python_bin=$(command -v "${PYTHON:-python3}") || fail 'PYTHON executable not found'
unshare_bin=$(command -v "${UNSHARE:-unshare}") || fail 'UNSHARE executable not found'
mount_bin=$(command -v "${MOUNT:-mount}") || fail 'MOUNT executable not found'
timeout_bin=$(command -v "${TIMEOUT:-timeout}") || fail 'TIMEOUT executable not found'
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$python_bin" -s -B "$channel_dir/tests/clojure-roguelike-native.py" \
    "$1" "$2" "$guix_bin" "$python_bin" "$unshare_bin" "$mount_bin" "$timeout_bin"
