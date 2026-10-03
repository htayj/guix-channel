#!/bin/sh
# External native proof only. Supply an already-built GearHead output.
# Dependencies: guix, python3 + pyte, coreutils, findutils, util-linux,
# Xvfb, xterm, xdotool, ImageMagick import, and a monospace X font.
# Usage: sh tests/gearhead-smoke.sh /gnu/store/...-gearhead EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "gearhead smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s GEARHEAD-OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'output must be a prebuilt Guix store directory' ;; esac
test -x "$out/bin/gearhead" || fail 'missing package launcher'
test -x "$out/libexec/gharena" || fail 'missing native ASCII executable'
for data in Design GameData Series doc; do
    test -d "$out/share/gearhead/$data" || fail "missing installed assets: $data"
done
for notice in license.txt readme.md Credits.txt gharena.pas SOURCE-PROVENANCE \
              fpc-rtl/COPYING fpc-rtl/COPYING.FPC fpc-rtl/PROVENANCE; do
    test -s "$out/share/doc/gearhead/$notice" || fail "missing installed notice: $notice"
done
test -f "$out/share/gearhead/Series/ADV_FederatedTerritories.txt" || fail 'missing native RPG campaign'
test "$(find "$out/share/gearhead/Series" -maxdepth 1 -type f -name 'ADV_*.txt' -print | wc -l)" -eq 1 || fail 'expected one native campaign selection'
for cmd in python3 timeout unshare xterm Xvfb xdotool import find readlink id wc; do
    command -v "$cmd" >/dev/null || fail "missing dependency: $cmd"
done
guix_bin=$(command -v "${GUIX:-guix}")
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
case "$evidence/" in "$out/"*) fail 'evidence must be outside the package output' ;; esac
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'package contains writable files'
if ! timeout --kill-after=5 10 unshare --user --map-current-user --keep-caps \
        --net --mount --mount-proc --pid --fork --kill-child true; then
    printf '%s\n' 'gearhead smoke requires same-user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export GEARHEAD_HOST_NETNS="$(readlink /proc/self/ns/net)"
export GEARHEAD_HOST_MNTNS="$(readlink /proc/self/ns/mnt)"
export GEARHEAD_HOST_PIDNS="$(readlink /proc/self/ns/pid)"
export GEARHEAD_HOST_UID="$(id -u)"
unset DISPLAY WAYLAND_DISPLAY LD_PRELOAD LD_LIBRARY_PATH
status=0
timeout --kill-after=5 300 \
    unshare --user --map-current-user --keep-caps --net --mount \
    --mount-proc --pid --fork --kill-child \
    python3 -B "$channel_dir/tests/gearhead-pty-runner.py" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$($guix_bin hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'installed NAR changed during gameplay'
test "$status" -eq 0 || fail "native driver failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'driver produced no complete proof'
printf '%s\n' 'gearhead smoke: native creation/movement/save/reload/quit OK; live xterm captures; offline namespace; read-only store; NAR unchanged'
