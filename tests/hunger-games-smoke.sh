#!/bin/sh
# Exercise The Hunger Games through its installed command-line launcher.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
grep_bin=$(command -v grep)
find_bin=$(command -v find)
mkdir_bin=$(command -v mkdir)
dirname_bin=$(command -v dirname)
cp_bin=$(command -v cp)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [hunger-games-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hunger_games_out=$1
else
    hunger_games_out=$($guix_bin build -L . --no-grafts --no-substitutes hunger-games)
fi

find_output () {
    program=$1
    package=$2
    for output in $($guix_bin build -L . --no-grafts --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_output bin/unshare util-linux)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
node_bin=$(command -v node)
test -r "$bounded_validation"
test -x "$node_bin"
test -x "$hunger_games_out/bin/hunger-games"
test -x "$hunger_games_out/libexec/hunger-games-real"

data="$hunger_games_out/share/hunger-games"
test -s "$data/hunger.ds"
test -s "$data/hunger.bmp"
test -z "$("$find_bin" "$data" -type f ! -name hunger.ds ! -name hunger.bmp \
    -print -quit)"
test -z "$("$find_bin" "$data" -type f -name '*.wav' -print -quit)"

doc="$hunger_games_out/share/doc/hunger-games"
for file in README.md license.htm changes.htm changes.doc daedalus.htm \
    daedalus.doc script.htm script.doc; do
    test -s "$doc/$file"
done
"$grep_bin" -F 'GNU GENERAL PUBLIC LICENSE' "$doc/license.htm" >/dev/null
"$grep_bin" -F 'Version 2, June 1991' "$doc/license.htm" >/dev/null
"$grep_bin" -F 'Walter D.' "$doc/changes.htm" >/dev/null
"$grep_bin" -F 'Pullen' "$doc/changes.htm" >/dev/null
"$grep_bin" -F 'By Walter D. Pullen' "$data/hunger.ds" >/dev/null
"$grep_bin" -F 'Happy Hunger Games!' "$data/hunger.ds" >/dev/null

# The reviewed per-issue runtime contract is part of this package proof.
contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
"$grep_bin" -F '"issueNumber": 695' "$contract" >/dev/null
"$grep_bin" -F '"packageName": "hunger-games"' "$contract" >/dev/null
"$grep_bin" -F '"packageModulePath": "tay/packages/hunger-games.scm"' \
    "$contract" >/dev/null
"$grep_bin" -F '"artifactPath": ".goocastle/evidence/issue-695.png"' \
    "$contract" >/dev/null
"$grep_bin" -F '"executable": "hunger-games"' "$contract" >/dev/null
"$grep_bin" -F '"--smoke"' "$contract" >/dev/null
"$grep_bin" -F '"successMarker": "HUNGER_GAMES_SMOKE_OK"' \
    "$contract" >/dev/null

# The NAR hash and writable-file scan cover the complete installed tree.
before=$($guix_bin hash -S nar "$hunger_games_out")
test -z "$("$find_bin" "$hunger_games_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$hunger_games_out"

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$(mktemp -d /tmp/goocastle-agent-XXXXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$(mktemp -d "$disposable_workspace/hunger-games-XXXXXXXX")
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
export TERM=xterm-256color
export LC_ALL=C
export ALL_PROXY=http://127.0.0.1:9
export HTTP_PROXY=http://127.0.0.1:9
export HTTPS_PROXY=http://127.0.0.1:9
export NO_PROXY='*'

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$hunger_games_out/bin/hunger-games" --smoke)
test "$proof" = 'HUNGER_GAMES_SMOKE_OK'
test -s "$raw"
"$grep_bin" -aFx 'HUNGER_GAMES_SMOKE_OK' "$raw" >/dev/null
# The engine must have emitted the script's own post-movement status and map
# receipts.  These are the substantive runtime evidence used for the screen
# capture; a wrapper-only marker is not sufficient.
"$grep_bin" -aF 'The Hunger Games' "$raw" >/dev/null
"$grep_bin" -aF 'Arena tribute map' "$raw" >/dev/null

# The smoke wrapper runs in the data directory but must not create state or
# temporary files there.  The raw terminal stream is the sole expected file.
test -z "$("$find_bin" "$scratch/work" -mindepth 1 -print -quit)"
test -z "$("$find_bin" "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"
test ! -e "$scratch/state/hunger-games"

after=$($guix_bin hash -S nar "$hunger_games_out")
test "$before" = "$after"
test -z "$("$find_bin" "$hunger_games_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$hunger_games_out"

# The evidence adapter may request a screenshot copy from the captured
# terminal stream, but it must remain under this issue's reviewed path.
if test -n "${GOOCASTLE_SCREENSHOT-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'hunger-games smoke: screenshot must be a channel evidence PNG' >&2
           exit 1 ;;
    esac
    "$mkdir_bin" -p "$("$dirname_bin" -- "$GOOCASTLE_SCREENSHOT")"
    "$cp_bin" "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
