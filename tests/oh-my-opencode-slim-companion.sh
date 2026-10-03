#!/bin/sh
# Genuine installed GUI acceptance; no provider calls or host user state.
# Usage: GUIX=guix sh tests/oh-my-opencode-slim-companion.sh [companion-output]
# OH_MY_OPENCODE_SLIM_COMPANION_SMOKE_ARTIFACTS selects an empty absolute
# evidence directory. Screenshots, metrics and logs are retained even on failure.
set -eu

# Intentional word splitting allows the conventional GUIX command prefix.
guix_bin=${GUIX:-${GUIX_BIN:-guix}}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [companion-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    companion_out=$1
else
    companion_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts oh-my-opencode-slim-companion)
fi
case "$companion_out" in
    /gnu/store/*) test -d "$companion_out" ;;
    *) echo "not a store output: $companion_out" >&2; exit 64 ;;
esac
test -x "$companion_out/bin/oh-my-opencode-slim-companion"
artifacts=${OH_MY_OPENCODE_SLIM_COMPANION_SMOKE_ARTIFACTS:-}
if test -z "$artifacts"; then
    artifacts=$(mktemp -d /tmp/slim-companion-artifacts.XXXXXXXX)
fi
case "$artifacts" in
    /*) ;;
    *) echo 'artifacts directory must be absolute' >&2; exit 64 ;;
esac
mkdir -p "$artifacts"
test -z "$(find "$artifacts" -mindepth 1 -print -quit)" || {
    echo 'artifacts directory must be empty' >&2; exit 64;
}
status=0
scratch=$(mktemp -d /tmp/slim-companion-work.XXXXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
# Only the disposable runtime enters the network namespace; package realization
# can use the Guix daemon normally. No host X server, compositor or bus is used.
$guix_bin shell --pure --no-grafts -L "$channel_dir/guix" \
    oh-my-opencode-slim-companion xorg-server xdotool imagemagick python \
    util-linux coreutils -- \
    timeout --kill-after=5s 120s \
    unshare --user --map-root-user --mount --net --ipc --pid --kill-child \
    --fork --mount-proc \
    python3 -I -B "$channel_dir/tests/oh-my-opencode-slim-companion.py" \
    "$companion_out" "$artifacts" "$scratch" >"$artifacts/proof.log" 2>&1 || status=$?
cat "$artifacts/proof.log"
printf 'Slim companion GUI evidence: %s\n' "$artifacts"
exit "$status"
