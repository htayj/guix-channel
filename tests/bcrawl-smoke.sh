#!/bin/sh
# Isolated installed-runtime proof for Bcrawl: play, save and restore a
# character through the real terminal UI without network or store writes.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [bcrawl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    bcrawl_out=$1
else
    bcrawl_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes bcrawl)
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

test -x "$bcrawl_out/bin/bcrawl"
test -x "$bcrawl_out/libexec/bcrawl"
test -x "$bcrawl_out/libexec/bcrawl-smoke.py"
test -d "$bcrawl_out/share/bcrawl/dat"
test ! -e "$bcrawl_out/share/bcrawl/dat/tiles"

# The root license and every compatible exception/notices copied by the
# package must remain available with the installed executable and data.
doc=$bcrawl_out/share/doc/bcrawl
test -s "$doc/LICENSE"
test -s "$doc/CREDITS.txt"
for notice in cc0.txt lgpl.txt libpng-LICENSE.txt lualicense.txt \
              pcre_license.txt worley.txt; do
    test -s "$doc/license/$notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'bcrawl credits' "$doc/CREDITS.txt" >/dev/null
grep -F 'CC0 1.0 Universal' "$doc/license/cc0.txt" >/dev/null
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/license/lgpl.txt" >/dev/null
grep -F 'Lua is licensed under the terms of the MIT license' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null

marker='bcrawl smoke: terminal UI OK; no store writes'

coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
timeout_bin=$coreutils_out/bin/timeout
unshare_bin=$util_linux_out/bin/unshare
if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'bcrawl smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real game runs; this catches a regression that directs
# state back to the immutable package output.
before=$($guix_bin hash -S nar "$bcrawl_out")
test -z "$(find "$bcrawl_out" -xdev -type f -perm /222 -print -quit)"

# Only this task-created directory is removed; a caller's TMPDIR and any
# requested raw-capture path are left in place.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/bcrawl-smoke.XXXXXXXX")
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
export LC_ALL=C
host_path=$PATH
export PATH="$bcrawl_out/bin"

# The launcher's --smoke branch creates another fresh HOME/XDG tree below
# TMPDIR and drives two real curses sessions in PTYs: a seeded new game that
# takes turns and saves, then a restore that checks the saved game clock,
# takes a turn and saves again.  The PID namespace reaps every descendant if
# the time bound expires, and the network namespace has no usable interfaces.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/state/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$timeout_bin" --kill-after=5 180 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    "$bcrawl_out/bin/bcrawl" --smoke)
export PATH="$host_path"
test "$proof" = "$marker"
test -s "$raw"
# The raw capture is the restore session's alternate-screen frames only, up to
# the restored gameplay screen; it holds no quit, save or shutdown output.
if grep -aF "$(printf '\033[?1049l')" "$raw" >/dev/null; then
    echo 'bcrawl smoke: raw capture includes primary-screen output' >&2
    exit 1
fi
grep -aF 'Welcome back, Goocastle the Human Fighter.' "$raw" >/dev/null

# The launcher removed its own state tree; everything the test provided,
# including the working directory, remains empty apart from the capture.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"
test -z "$(find "$scratch/state" -mindepth 1 ! -path "$raw" -print -quit)"

after=$($guix_bin hash -S nar "$bcrawl_out")
test "$before" = "$after"
test ! -w "$bcrawl_out"

printf '%s\n' "$marker"
