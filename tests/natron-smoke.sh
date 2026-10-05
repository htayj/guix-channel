#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# External native proof. Invoke with sh; no package build or installation here.
# GUIX realizes tools and the package's exact recursive source BEFORE isolation.
# Usage: GUIX=guix sh tests/natron-smoke.sh OUTPUT EVIDENCE
set -eu
umask 077
fail () { printf '%s\n' "natron smoke: $*" >&2; exit 1; }
test "$#" -eq 2 || { printf 'usage: %s OUTPUT EVIDENCE\n' "$0" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(realpath -- "$1")
case "$out" in /gnu/store/*) ;; *) fail 'OUTPUT must be a prebuilt Guix store directory' ;; esac
test -x "$out/bin/Natron" || fail 'missing bin/Natron'
test -x "$out/bin/NatronRenderer" || fail 'missing bin/NatronRenderer'
guix_bin=$(command -v "${GUIX:-guix}")
if test "${NATRON_PROOF_ENV:-}" != ready; then
    source=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 --source natron)
    case "$source" in /gnu/store/*) ;; *) fail 'invalid recursive source result' ;; esac
    test -f "$source/libs/OpenFX/include/ofxImageEffect.h" || fail 'missing pinned OpenFX headers'
    fonts=$("$guix_bin" build --no-grafts --no-offload --cores=1 --max-jobs=1 font-dejavu)
    exec "$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
        python gcc-toolchain util-linux coreutils findutils bash-minimal xvfb-run \
        --preserve='^(GUIX|NATRON_PROOF_ENV|NATRON_PROOF_SOURCE|NATRON_PROOF_FONTS)$' -- \
        env GUIX="$guix_bin" NATRON_PROOF_ENV=ready NATRON_PROOF_SOURCE="$source" \
        NATRON_PROOF_FONTS="$fonts" \
        sh "$channel_dir/tests/natron-smoke.sh" "$out" "$2"
fi
for cmd in python3 g++ timeout unshare mount xvfb-run; do
    command -v "$cmd" >/dev/null || fail "missing realized dependency: $cmd"
done
test -d "$NATRON_PROOF_SOURCE/libs/OpenFX/include" || fail 'missing source headers'
mkdir -p -- "$2"
evidence=$(realpath -- "$2")
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || fail 'EVIDENCE must be empty'
case "$evidence/" in "$out/"*|/gnu/store/*) fail 'EVIDENCE must be outside the store' ;; esac
test -z "$(find "$out" -type f -perm /222 -print -quit)" || fail 'writable package files'
if ! timeout --kill-after=5 10 unshare --user --map-current-user --keep-caps \
    --mount --net --pid --fork --kill-child true; then
    printf '%s\n' 'natron smoke requires sameUID user/mount/network/PID namespaces' >&2
    exit 77
fi
before=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
export NATRON_PROOF_UID="$(id -u)" NATRON_PROOF_GID="$(id -g)"
export NATRON_HOST_NETNS="$(readlink /proc/self/ns/net)"
export NATRON_HOST_MNTNS="$(readlink /proc/self/ns/mnt)"
export NATRON_HOST_PIDNS="$(readlink /proc/self/ns/pid)"
export NATRON_HOST_USERNS="$(readlink /proc/self/ns/user)"
unset DISPLAY WAYLAND_DISPLAY LD_PRELOAD OCIO OFX_PLUGIN_PATH PYTHONSTARTUP PYTHONPATH
status=0
timeout --kill-after=10 240 unshare --user --map-current-user --keep-caps \
    --net --mount --pid --fork --kill-child \
    python3 -B "$channel_dir/tests/natron/driver.py" "$out" "$evidence" "$NATRON_PROOF_SOURCE" \
    >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$out")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
test "$before" = "$after" || fail 'output NAR changed'
test "$status" -eq 0 || fail "native proof failed ($status); see $evidence/driver.stderr"
test -s "$evidence/proof.json" || fail 'missing completed native proof'
printf '%s\n' 'natron smoke: real GUI exact menu glyph/clean exit and renderer 2x2 frame1 exact PPM; offline sameUID namespaces; read-only store; NAR unchanged'
