#!/bin/sh
# Exercise the installed CLI and its real OpenCode host, without provider turns.
set -eu
if [ "$#" -ne 0 ]; then
    echo 'usage: tests/oh-my-opencode-slim.sh (no arguments)' >&2
    exit 2
fi
guix_bin=${GUIX:-${GUIX_BIN:-guix}}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# GUIX may be a command such as "guix time-machine -C channels.guix --",
# matching the other conventional consumer helpers in this repository.
out=$($guix_bin build -L "$channel_dir/guix" --no-grafts oh-my-opencode-slim)
host=$($guix_bin build -L "$channel_dir/guix" --no-grafts opencode)
companion=$($guix_bin build -L "$channel_dir/guix" --no-grafts oh-my-opencode-slim-companion)
# Writable OpenCode config directories trigger npm SDK bootstrap even with
# default plugins disabled. Exercise its supported read-only config mode,
# using only helper-created directories and a private loopback-only network.
exec $guix_bin shell --pure --no-grafts -L "$channel_dir/guix" \
    --preserve='^SLIM_ARTIFACTS$' \
    python util-linux iproute2 coreutils -- \
    unshare --user --map-root-user --mount --net --ipc --fork \
    python3 -I -B "$channel_dir/tests/oh-my-opencode-slim.py" "$out" "$host" "$companion"
