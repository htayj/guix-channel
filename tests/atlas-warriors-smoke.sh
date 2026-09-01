#!/bin/sh
# Isolated installed-runtime proof for Atlas Warriors.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [atlas-warriors-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    atlas_out=$1
else
    atlas_out=$($guix_bin build -L "$channel_dir" \
        --no-grafts --no-substitutes atlas-warriors)
fi

test -x "$atlas_out/bin/atlas-warriors"
test -f "$atlas_out/share/atlas-warriors/rl.py"
test -f "$atlas_out/share/atlas-warriors/items.xml"
test -f "$atlas_out/share/atlas-warriors/assets/back_level_0.png"
test -f "$atlas_out/share/doc/atlas-warriors/LICENSE"
test -f "$atlas_out/share/doc/atlas-warriors/README.md"
test -f "$atlas_out/share/doc/atlas-warriors/DejaVu-LICENSE"
grep -F 'The MIT License (MIT)' "$atlas_out/share/doc/atlas-warriors/LICENSE" >/dev/null
grep -F 'Simplified BSD License' "$atlas_out/share/doc/atlas-warriors/LICENSE" >/dev/null
grep -F 'Attribution 3.0 Unported' \
    "$atlas_out/share/doc/atlas-warriors/LICENSE" >/dev/null
grep -F 'Dark Paper Pack' "$atlas_out/share/doc/atlas-warriors/README.md" >/dev/null
grep -F 'Bitstream Vera Fonts Copyright' \
    "$atlas_out/share/doc/atlas-warriors/DejaVu-LICENSE" >/dev/null

font_out=$($guix_bin build font-dejavu)
for font in DejaVuSans.ttf DejaVuSansMono.ttf DejaVuSerif.ttf; do
    test "$("$guix_bin" hash "$font_out/share/fonts/truetype/$font")" = \
        "$("$guix_bin" hash "$atlas_out/share/atlas-warriors/$font")"
done

grep -F '"issueNumber": 657' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F '"packageName": "atlas-warriors"' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-657.png"' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F '"--guix-smoke"' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null
grep -F 'atlas-warriors isolated smoke passed' \
    "$channel_dir/.goocastle/runtime-evidence-contracts.json" >/dev/null

if rg -n 'webbrowser|(^import|^from)[[:space:]]+(socket|urllib|http|requests)' \
        "$atlas_out/share/atlas-warriors" --glob '*.py'; then
    echo "unexpected network or browser reference in installed Atlas Warriors" >&2
    exit 1
fi

before_hash=$($guix_bin hash -r "$atlas_out")
temporary=$(mktemp -d "${TMPDIR:-/tmp}/atlas-warriors-smoke-XXXXXX")
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
    ATLAS_WARRIORS_SMOKE_SCREENSHOT="$frame" \
    LC_ALL=C.UTF-8 \
    PATH="$atlas_out/bin" \
    "$atlas_out/bin/atlas-warriors" --guix-smoke)
test "$output" = 'atlas-warriors isolated smoke passed'
test -s "$frame"

test -f "$state/atlas-warriors/tutorial.json"
test -f "$state/atlas-warriors/error.log"
test -z "$(find "$home" "$config" "$data" "$cache" "$scratch" \
    -mindepth 1 -print -quit)"
test -z "$(find "$state" -type f ! -path "$state/atlas-warriors/tutorial.json" \
    ! -path "$state/atlas-warriors/error.log" -print -quit)"
test -z "$(find "$state" -type d ! -path "$state" \
    ! -path "$state/atlas-warriors" -print -quit)"
test "$before_hash" = "$($guix_bin hash -r "$atlas_out")"
test -z "$(find "$atlas_out" -perm /022 -print -quit)"

echo "atlas-warriors smoke passed: isolated pygame map, turn, XDG state, and immutable output"
