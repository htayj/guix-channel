#!/bin/sh
# Run the installed Liquid editor on a fixture in an isolated PTY and netns.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [liquid-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    liquid_out=$1
else
    liquid_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts liquid)
fi

test -x "$liquid_out/bin/liquid"
test -x "$liquid_out/bin/liquid-smoke"
test -x "$liquid_out/libexec/liquid-smoke.py"
test -s "$liquid_out/share/java/liquid.jar"
license=$(find "$liquid_out/share/doc" -type f -name LICENSE)
test -n "$license"
# SHA-256 of the complete 11,218-byte EPL-1.0 LICENSE in upstream commit
# 045f587b3914485baf85d9eae4f97f968cbfafaa, not a fragile title match.
license_hash=$(sha256sum "$license")
test "${license_hash%% *}" = \
    a5cb01efb6648a83f1f466ea82c32bb52dc4c70ab27d0b70f0c7407d8fc3a815

before=$($guix_bin hash -S nar "$liquid_out")
test -z "$(find "$liquid_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/liquid-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
    "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/work"

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/work/terminal.raw}
proof=$(cd "$scratch/work" && env -i \
    PATH="${PATH:-/usr/bin:/bin}" \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    TERM=xterm-256color \
    LC_ALL=C \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$liquid_out/bin/liquid-smoke")
test "$proof" = 'liquid smoke proof: fixture rendered successfully'
test -s "$raw"

# The runner deletes its private tree; nothing may escape into this HOME/XDG
# tree or the caller directory, and the package output must stay unchanged.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test -z "$(find "$scratch/work" -mindepth 1 ! -name terminal.raw -print -quit)"
after=$($guix_bin hash -S nar "$liquid_out")
test "$before" = "$after"
test -z "$(find "$liquid_out" -xdev -type f -perm /222 -print -quit)"
printf '%s\n' "$proof"
