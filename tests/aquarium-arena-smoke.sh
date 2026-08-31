#!/bin/sh
# Isolated installed-runtime proof for Aquarium Arena.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [aquarium-arena-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    aquarium_out=$1
else
    aquarium_out=$($guix_bin build -L "$channel_dir" \
        --no-grafts --no-substitutes aquarium-arena)
fi

test -x "$aquarium_out/bin/aquarium-arena"
test -f "$aquarium_out/share/aquarium-arena/AquariumArena.py"
test -f "$aquarium_out/share/doc/aquarium-arena/LICENSE.md"
test -f "$aquarium_out/share/doc/aquarium-arena/FreeMono-COPYING"
test -f "$aquarium_out/share/doc/aquarium-arena/LiberationMono-LICENSE"
grep -F 'GNU GENERAL PUBLIC LICENSE' \
    "$aquarium_out/share/doc/aquarium-arena/LICENSE.md" >/dev/null
grep -F 'Version 3, 29 June 2007' \
    "$aquarium_out/share/doc/aquarium-arena/FreeMono-COPYING" >/dev/null
grep -F 'GNU General Public License v.2 with the exceptions set forth below' \
    "$aquarium_out/share/doc/aquarium-arena/LiberationMono-LICENSE" >/dev/null
grep -F 'issueNumber' "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F '"issueNumber": 656' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F '"packageName": "aquarium-arena"' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F 'aquarium-arena isolated smoke passed' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null

# A package that has no networking code needs no network fixture.  Rejecting
# socket/URL client imports from every installed Python module ensures the
# isolated pygame run below cannot initiate a network request.
if rg -n '(^|[[:space:]])(import|from)[[:space:]]+(socket|urllib|http|requests)' \
        "$aquarium_out/share/aquarium-arena" --glob '*.py'; then
    echo "unexpected networking import in installed Aquarium Arena" >&2
    exit 1
fi

before_hash=$($guix_bin hash -r "$aquarium_out")
temporary=$(mktemp -d "${TMPDIR:-/tmp}/aquarium-arena-smoke-XXXXXX")
home=$temporary/home
config=$temporary/config
data=$temporary/data
cache=$temporary/cache
state=$temporary/state
scratch=$temporary/scratch
frame=$temporary/initialized-game-frame.png
mkdir "$home" "$config" "$data" "$cache" "$state" "$scratch"

output=$(env -i \
    HOME="$home" \
    XDG_CONFIG_HOME="$config" \
    XDG_DATA_HOME="$data" \
    XDG_CACHE_HOME="$cache" \
    XDG_STATE_HOME="$state" \
    TMPDIR="$scratch" \
    SDL_VIDEODRIVER=dummy \
    SDL_AUDIODRIVER=dummy \
    AQUARIUM_ARENA_SMOKE_SCREENSHOT="$frame" \
    LC_ALL=C.UTF-8 \
    PATH="$aquarium_out/bin" \
    "$aquarium_out/bin/aquarium-arena" --guix-smoke)
test "$output" = 'aquarium-arena isolated smoke passed'
test -s "$frame"

test -f "$data/aquarium-arena/hiscore"
test "$(cat "$data/aquarium-arena/hiscore")" = 17
test -z "$(find "$home" "$config" "$cache" "$state" "$scratch" \
    -mindepth 1 -print -quit)"
test -z "$(find "$data" -type f ! -path "$data/aquarium-arena/hiscore" \
    -print -quit)"
test -z "$(find "$data" -type d ! -path "$data" \
    ! -path "$data/aquarium-arena" -print -quit)"
test "$before_hash" = "$($guix_bin hash -r "$aquarium_out")"
test -z "$(find "$aquarium_out" -perm /022 -print -quit)"

echo "aquarium-arena smoke passed: isolated pygame arena, turn, XDG high score, and immutable output"
