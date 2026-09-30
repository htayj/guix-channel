#!/bin/sh
# Isolated installed-runtime proof for Hydra Slayer.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [hydra-slayer-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hydra_out=$1
else
    hydra_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes hydra-slayer)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

test -x "$hydra_out/bin/hydra"
test -x "$hydra_out/libexec/hydra"
test -x "$hydra_out/libexec/hydra-slayer-smoke.py"
test -s "$hydra_out/share/doc/hydra-slayer/COPYING"
grep -F 'GNU GENERAL PUBLIC LICENSE' \
    "$hydra_out/share/doc/hydra-slayer/COPYING" >/dev/null
grep -F 'This program is free software' \
    "$hydra_out/share/doc/hydra-slayer/COPYING" >/dev/null
test ! -e "$hydra_out/share/hydra"

marker='HYDRA_SLAYER_GUIX_SMOKE_OK: new-game, turn, save-load, isolated-state'

coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
timeout_bin=$coreutils_out/bin/timeout
unshare_bin=$util_linux_out/bin/unshare
if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'hydra-slayer smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$hydra_out")
test -z "$(find "$hydra_out" -xdev -type f -perm /222 -print -quit)"

# Only this task-created directory is removed; a caller's TMPDIR and any
# requested raw-capture path are left in place.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/hydra-slayer-smoke.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
      "$scratch/work"

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C.UTF-8
host_path=$PATH
export PATH="$hydra_out/bin"

# The package's --guix-smoke branch creates another fresh XDG tree below the
# disposable state directory and drives both real curses sessions in PTYs.
# The PID namespace reaps every descendant if the time bound expires, and the
# network namespace has no usable interfaces.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/state/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$timeout_bin" --kill-after=5 90 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    "$hydra_out/bin/hydra" --guix-smoke)
export PATH="$host_path"
test "$proof" = "$marker"
test -s "$raw"
grep -aF 'Hydra Slayer v18.3' "$raw" >/dev/null
# The raw capture is the loaded session's alternate-screen frames only; the
# driver itself asserts the first session's primary-screen save report.
if grep -aF "$(printf '\033[?1049l')" "$raw" >/dev/null; then
    echo 'hydra-slayer smoke: raw capture includes primary-screen output' >&2
    exit 1
fi
grep -aF 'Welcome back to Hydra Slayer!' "$raw" >/dev/null

# The package must use only the disposable XDG state tree.  The other fresh
# XDG directories and the working directory remain empty.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"
test -n "$(find "$scratch/state" -mindepth 1 -print -quit)"
test -z "$(find "$scratch/state" -type l -print -quit)"

after=$($guix_bin hash -S nar "$hydra_out")
test "$before" = "$after"
test ! -w "$hydra_out"

printf '%s\n' "$marker"
