#!/bin/sh
# Isolated installed-runtime proof for Bloatcrawl 2: create a character and
# play turns through the real terminal UI without network or store writes.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [bloatcrawl2-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    bloatcrawl2_out=$1
else
    bloatcrawl2_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        bloatcrawl2)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

test -x "$bloatcrawl2_out/bin/bloatcrawl2"
test -x "$bloatcrawl2_out/libexec/bloatcrawl2"
test -x "$bloatcrawl2_out/libexec/bloatcrawl2-smoke.py"
test -d "$bloatcrawl2_out/share/bloatcrawl2/dat"
test ! -e "$bloatcrawl2_out/share/bloatcrawl2/dat/tiles"
test ! -e "$bloatcrawl2_out/share/bloatcrawl2/webserver"

# The root license and every compatible notice copied by the package must
# remain available with the installed executable and data.
doc=$bloatcrawl2_out/share/doc/bloatcrawl2
test -s "$doc/LICENSE"
test -s "$doc/CREDITS.txt"
for notice in cc0.txt lgpl.txt libpng-LICENSE.txt lualicense.txt \
              pcre_license.txt worley.txt license.txt; do
    test -s "$doc/license/$notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'Dungeon Crawl Stone Soup team' "$doc/CREDITS.txt" >/dev/null
grep -F 'CC0 1.0 Universal' "$doc/license/cc0.txt" >/dev/null
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/license/lgpl.txt" >/dev/null
grep -F 'Lua is licensed under the terms of the MIT license reproduced below' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null
grep -F 'public' "$doc/license/license.txt" >/dev/null
grep -F 'domain' "$doc/license/license.txt" >/dev/null
grep -F 'RLTiles' "$doc/license/license.txt" >/dev/null

marker='bloatcrawl2 smoke: terminal UI OK; no store writes'

coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)
timeout_bin=$coreutils_out/bin/timeout
unshare_bin=$util_linux_out/bin/unshare
if ! "$timeout_bin" --kill-after=5 10 \
        "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
        true >/dev/null 2>&1; then
    echo 'bloatcrawl2 smoke requires unprivileged user, network, and PID namespaces' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real game runs; this catches a regression that directs
# state back to the immutable package output.
before=$($guix_bin hash -S nar "$bloatcrawl2_out")
test -z "$(find "$bloatcrawl2_out" -xdev -type f -perm /222 -print -quit)"

# Only this task-created directory is removed; a caller's TMPDIR and any
# requested raw-capture path are left in place.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/bloatcrawl2-smoke.XXXXXXXX")
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
export PATH="$bloatcrawl2_out/bin"

# The launcher's --smoke branch creates another fresh HOME/XDG tree below
# TMPDIR and drives one real curses session in a PTY: a seeded Human Fighter
# chooses a weapon, enters the dungeon and waits three turns, each checked
# against the HUD game clock, then abandons the character.  The PID namespace
# reaps every descendant if the time bound expires, and the network namespace
# has no usable interfaces.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/state/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$timeout_bin" --kill-after=5 180 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    "$bloatcrawl2_out/bin/bloatcrawl2" --smoke)
export PATH="$host_path"
test "$proof" = "$marker"
test -s "$raw"
# The raw capture is the session's contiguous prefix up to the gameplay frame
# after the last turn; it holds no quit, end-game or shutdown output.
if grep -aF "$(printf '\033[?1049l')" "$raw" >/dev/null; then
    echo 'bloatcrawl2 smoke: raw capture includes primary-screen output' >&2
    exit 1
fi
grep -aF 'Health:' "$raw" >/dev/null

# The launcher removed its own state tree; everything the test provided,
# including the working directory, remains empty apart from the capture.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"
test -z "$(find "$scratch/state" -mindepth 1 ! -path "$raw" -print -quit)"

after=$($guix_bin hash -S nar "$bloatcrawl2_out")
test "$before" = "$after"
test ! -w "$bloatcrawl2_out"

printf '%s\n' "$marker"
