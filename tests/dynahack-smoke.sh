#!/bin/sh
# External native proof only; consumes an already-built Guix output.
# Usage: sh tests/dynahack-smoke.sh /gnu/store/...-dynahack EMPTY-EVIDENCE-DIRECTORY
set -eu
umask 077
fail () { printf '%s\n' "dynahack smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s DYNAHACK-OUTPUT EVIDENCE-DIRECTORY\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'output must be a prebuilt Guix store directory' ;; esac
test -x "$out/bin/dynahack" || fail 'missing native launcher'
test -d "$out/share/dynahack" || fail 'missing installed game data'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${DYNAHACK_PROOF_ENV:-}" != ready; then
    exec "$guix_bin" shell --pure --no-grafts \
        python python-pyte xorg-server xterm xdotool imagemagick \
        font-dejavu fontconfig util-linux coreutils findutils bash-minimal \
        --preserve='^(GUIX|DYNAHACK_PROOF_ENV)$' -- \
        env GUIX="$guix_bin" DYNAHACK_PROOF_ENV=ready \
        sh "$channel_dir/tests/dynahack-smoke.sh" "$out" "$2"
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
    printf '%s\n' 'dynahack smoke requires same-user, mount, network and PID namespaces' >&2
    exit 77
fi
before=$($guix_bin hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export DYNAHACK_HOST_NETNS="$(readlink /proc/self/ns/net)"
export DYNAHACK_HOST_MNTNS="$(readlink /proc/self/ns/mnt)"
export DYNAHACK_HOST_PIDNS="$(readlink /proc/self/ns/pid)"
export DYNAHACK_HOST_UID="$(id -u)"
unset NETHACKDIR HACKDIR DYNAHACKOPTIONS DISPLAY WAYLAND_DISPLAY LD_PRELOAD LD_LIBRARY_PATH
status=0
timeout --kill-after=5 300 \
    unshare --user --map-current-user --keep-caps --net --mount \
    --mount-proc --pid --fork --kill-child \
    python3 "$channel_dir/tests/dynahack-smoke.py" "$out" "$evidence" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$($guix_bin hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'installed NAR changed during gameplay'
test "$status" -eq 0 || fail "native driver failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'driver produced no complete proof'
printf '%s\n' 'dynahack smoke: native movement/save/two exact restores/quit OK; offline namespaces; read-only store; NAR unchanged'
