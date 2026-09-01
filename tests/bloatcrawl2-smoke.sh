#!/bin/sh
# Exercise Bloatcrawl 2's installed terminal UI in isolated XDG state and a
# networkless namespace.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [bloatcrawl2-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    bloatcrawl2_out=$1
else
    bloatcrawl2_out=$($guix_bin build -L . --no-grafts --no-substitutes \
        bloatcrawl2)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir" --no-grafts \
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
grep -F 'Lua is licensed under the terms of the MIT license' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null
grep -F 'public domain roguelike tileset' "$doc/license/license.txt" >/dev/null

# The issue-specific executable, invocation, marker, and artifact are part of
# the proof, not an advisory record.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 661' "$contract" >/dev/null
grep -F '"packageName": "bloatcrawl2"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-661.png"' \
    "$contract" >/dev/null
grep -F '"executable": "bloatcrawl2"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
marker='bloatcrawl2 smoke: terminal UI OK; no store writes'
grep -F "\"successMarker\": \"$marker\"" "$contract" >/dev/null

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'bloatcrawl2 smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real game runs, catching accidental store writes.
before=$($guix_bin hash -S nar "$bloatcrawl2_out")

scratch=$(mktemp -d "${TMPDIR:-/tmp}/bloatcrawl2-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

# The package's --smoke mode creates its own private HOME/XDG tree and drives
# the real binary through a PTY.  The outer network namespace has no network
# interfaces, and the bounded executor owns the complete process group.
raw="$scratch/terminal.raw"
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bloatcrawl2_out/bin/bloatcrawl2" --smoke)
case "$proof" in
    *"$marker"*) ;;
    *)
        echo 'bloatcrawl2 smoke did not produce its success marker' >&2
        exit 1
        ;;
esac

# These markers are emitted by the captured PTY stream after character
# creation and dungeon entry; the package wrapper also checks them before it
# emits the success marker.
test -s "$raw"
grep -aF 'choice of weapons' "$raw" >/dev/null
grep -aF 'HP:' "$raw" >/dev/null
grep -aF 'Goocastle' "$raw" >/dev/null

after=$($guix_bin hash -S nar "$bloatcrawl2_out")
test "$before" = "$after"
test ! -w "$bloatcrawl2_out"
printf '%s\n' "$proof"
