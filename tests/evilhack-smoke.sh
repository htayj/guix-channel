#!/bin/sh
# External proof only: explicit prebuilt output, never build/install the game.
# Guix realizes the separate proof dependencies before entering offline namespaces.
# Run with sh; this script needs no executable bit.
# Usage: sh tests/evilhack-smoke.sh /gnu/store/...-evilhack EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "evilhack smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s EVILHACK-OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'output must be a prebuilt Guix store directory' ;; esac
test -x "$out/bin/evilhack" || fail 'missing console executable'
test -d "$out/share/evilhack" || fail 'missing installed game data'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${EVILHACK_PROOF_ENV:-}" != ready; then
    font_out=$($guix_bin build --no-grafts font-misc-misc)
    exec "$guix_bin" shell --pure --no-grafts \
        python python-pyte xorg-server xterm xdotool imagemagick \
        font-misc-misc fontconfig util-linux coreutils findutils bash-minimal \
        --preserve='^(GUIX|EVILHACK_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" EVILHACK_PROOF_ENV=ready EVILHACK_X_FONT_PATH="$font_out/share/fonts/X11/misc" \
        sh "$channel_dir/tests/evilhack-smoke.sh" "$out" "$2"
fi
for cmd in python3 timeout unshare mount xterm Xvfb xdotool import convert find; do
    command -v "$cmd" >/dev/null || fail "missing dependency: $cmd"
done
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'evidence directory must be empty'
case "$evidence/" in "$out/"*) fail 'evidence must be outside the output' ;; esac
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'package contains writable files'
if ! timeout --kill-after=5 10 unshare --user --map-current-user --keep-caps \
        --net --mount --mount-proc --pid --fork --kill-child true; then
    printf '%s\n' 'evilhack smoke requires same-user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export EVILHACK_HOST_NETNS="$(readlink /proc/self/ns/net)"
export EVILHACK_HOST_MNTNS="$(readlink /proc/self/ns/mnt)"
export EVILHACK_HOST_PIDNS="$(readlink /proc/self/ns/pid)"
export EVILHACK_HOST_UID="$(id -u)"
# The driver replaces HOME/XDG directories and /tmp before starting the game.
# Do not inherit paths, options, display or preload hooks from a real game.
unset NETHACKDIR HACKDIR NETHACKOPTIONS HACKOPTIONS EVILHACKOPTIONS EVILHACK_STATE DISPLAY WAYLAND_DISPLAY LD_PRELOAD
status=0
timeout --kill-after=5 300 \
    unshare --user --map-current-user --keep-caps --net --mount \
    --mount-proc --pid --fork --kill-child \
    python3 "$channel_dir/tests/evilhack-smoke.py" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$($guix_bin hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'installed NAR changed during gameplay'
test "$status" -eq 0 || fail "gameplay driver failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'driver produced no complete proof'
printf '%s\n' 'evilhack smoke: native movement/save/two exact restores/quit OK; offline namespace; read-only store; NAR unchanged'
