#!/bin/sh
# Isolated installed-runtime proof for Dungeon Monkey Unlimited.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
grep_bin=$(command -v grep)
find_bin=$(command -v find)
env_bin=$(command -v env)
true_bin=$(command -v true)
convert_bin=$(command -v convert || true)
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [dungeon-monkey-unlimited-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    dmu_out=$1
else
    dmu_out=$($guix_bin build -L . --no-grafts --no-substitutes \
        dungeon-monkey-unlimited)
fi

test -x "$dmu_out/bin/dungeon-monkey-unlimited"
test -x "$dmu_out/libexec/dungeon-monkey-unlimited-real"
test -x "$dmu_out/libexec/dungeon-monkey-unlimited-smoke"

data="$dmu_out/share/dungeon-monkey-unlimited"
doc="$dmu_out/share/doc/dungeon-monkey-unlimited"
test -s "$data/gamedata/messages.txt"
test -s "$data/gamedata/advcom_core_introduction.txt"
test -s "$data/image/title_screen.png"
test -s "$data/image/VeraBd.ttf"
test ! -e "$data/image/augie.ttf"
test ! -e "$data/image/Thumbs.db"
test ! -e "$data/image/debug.txt"
test ! -e "$data/convert32.pas"
test ! -e "$data/testit.pas"
test ! -e "$data/mtest.pas"

for notice in license.txt readme.txt credits.txt \
    THIRD-PARTY-NOTICES.txt Bitstream-Vera-COPYRIGHT.TXT; do
    test -s "$doc/$notice"
done
test -s "$doc/upstream-doc/effects_ref.txt"
"$grep_bin" -F 'GNU Lesser General Public License' \
    "$doc/license.txt" >/dev/null
"$grep_bin" -F 'Version 2.1, February 1999' "$doc/license.txt" >/dev/null
"$grep_bin" -F 'DUNGEON  MONKEY  UNLIMITED' "$doc/readme.txt" >/dev/null
"$grep_bin" -F 'David Gervais' "$doc/credits.txt" >/dev/null
"$grep_bin" -F 'RLTiles' "$doc/credits.txt" >/dev/null
"$grep_bin" -F 'Creative Commons Attribution 3.0' \
    "$doc/THIRD-PARTY-NOTICES.txt" >/dev/null
"$grep_bin" -F 'Part of (or All) the graphic tiles used in this program is' \
    "$doc/THIRD-PARTY-NOTICES.txt" >/dev/null
"$grep_bin" -F 'Copyright (c) 2003 by Bitstream, Inc.' \
    "$doc/Bitstream-Vera-COPYRIGHT.TXT" >/dev/null
"$grep_bin" -F 'shall be included in all copies' \
    "$doc/Bitstream-Vera-COPYRIGHT.TXT" >/dev/null

contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
"$grep_bin" -F '"issueNumber": 683' "$contract" >/dev/null
"$grep_bin" -F '"packageName": "dungeon-monkey-unlimited"' \
    "$contract" >/dev/null
"$grep_bin" -F '"packageModulePath": "tay/packages/dungeon-monkey-unlimited.scm"' \
    "$contract" >/dev/null
"$grep_bin" -F '"artifactPath": ".goocastle/evidence/issue-683.png"' \
    "$contract" >/dev/null
"$grep_bin" -F '"executable": "dungeon-monkey-unlimited"' \
    "$contract" >/dev/null
"$grep_bin" -F '"--smoke"' "$contract" >/dev/null
"$grep_bin" -F '"successMarker": "DMU-SMOKE: campaign-save-load-ok"' \
    "$contract" >/dev/null

test -z "$("$find_bin" "$dmu_out" -xdev -type f -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$dmu_out")

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$(mktemp -d /tmp/goocastle-agent-XXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$(mktemp -d "$disposable_workspace/dungeon-monkey-unlimited-XXXXXXXX")
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export PATH=
export ALL_PROXY=http://127.0.0.1:9
export HTTP_PROXY=http://127.0.0.1:9
export HTTPS_PROXY=http://127.0.0.1:9
export NO_PROXY='*'
export LC_ALL=C

if ! "$guix_bin" build util-linux >/dev/null 2>&1; then
    echo 'dungeon-monkey-unlimited smoke: util-linux is required' >&2
    exit 77
fi
unshare_bin=
for output in $($guix_bin build util-linux); do
    if test -x "$output/bin/unshare"; then
        unshare_bin="$output/bin/unshare"
        break
    fi
done
test -n "$unshare_bin"
test -r "$bounded_validation"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$unshare_bin" --user --map-root-user --net --fork \
        "$true_bin" >/dev/null 2>&1; then
    echo 'dungeon-monkey-unlimited smoke requires an unprivileged network namespace' >&2
    exit 77
fi

artifact=
screenshot_bmp=
if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    artifact="$channel_dir/.goocastle/evidence/issue-683.png"
    screenshot_bmp="$disposable_workspace/dungeon-monkey-unlimited-smoke.bmp"
    mkdir -p "$(dirname -- "$artifact")"
    test -x "$convert_bin"
fi

if test -n "$screenshot_bmp"; then
    proof=$("$env_bin" -i \
        HOME="$scratch/home" \
        XDG_CONFIG_HOME="$scratch/config" \
        XDG_DATA_HOME="$scratch/data" \
        XDG_CACHE_HOME="$scratch/cache" \
        XDG_STATE_HOME="$scratch/state" \
        XDG_RUNTIME_DIR="$scratch/runtime" \
        TMPDIR="$scratch/tmp" \
        SDL_VIDEODRIVER=dummy \
        SDL_AUDIODRIVER=dummy \
        DMU_SMOKE_SCREENSHOT="$screenshot_bmp" \
        LC_ALL=C PATH= \
        "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
        "$unshare_bin" --user --map-root-user --net --fork \
        "$dmu_out/bin/dungeon-monkey-unlimited" --smoke)
else
    proof=$("$env_bin" -i \
        HOME="$scratch/home" \
        XDG_CONFIG_HOME="$scratch/config" \
        XDG_DATA_HOME="$scratch/data" \
        XDG_CACHE_HOME="$scratch/cache" \
        XDG_STATE_HOME="$scratch/state" \
        XDG_RUNTIME_DIR="$scratch/runtime" \
        TMPDIR="$scratch/tmp" \
        SDL_VIDEODRIVER=dummy \
        SDL_AUDIODRIVER=dummy \
        LC_ALL=C PATH= \
        "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
        "$unshare_bin" --user --map-root-user --net --fork \
        "$dmu_out/bin/dungeon-monkey-unlimited" --smoke)
fi
test "$proof" = 'DMU-SMOKE: campaign-save-load-ok'

if test -n "$screenshot_bmp"; then
    "$convert_bin" "$screenshot_bmp" "PNG24:$artifact"
    test -s "$artifact"
fi

test -z "$("$find_bin" "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" \
    "$scratch/runtime" "$scratch/tmp" "$scratch/work" \
    -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$dmu_out")
test "$before" = "$after"
test ! -w "$dmu_out"
printf '%s\n' "$proof"
