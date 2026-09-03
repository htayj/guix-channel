#!/bin/sh
# Exercise DRL's reviewed console, save, and restore contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
find_bin=$(command -v find)
rm_bin=$(command -v rm)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [drl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    drl_out=$1
else
    drl_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes drl)
fi

test -x "$drl_out/bin/drl"
test -x "$drl_out/libexec/drl-real"
test -s "$drl_out/share/drl/config.lua"
test -s "$drl_out/share/drl/smoke-settings.lua"
grep -F 'input_legacysave = 118' "$drl_out/share/drl/smoke-settings.lua" >/dev/null
test -s "$drl_out/share/drl/data/core/main.lua"
test -s "$drl_out/share/drl/data/drl/main.lua"
test ! -e "$drl_out/share/drl/data/drl/graphics"
test ! -e "$drl_out/share/drl/data/drl/fonts"
test ! -e "$drl_out/ext"

doc=$drl_out/share/doc/drl
for notice in LICENSE FPCVALKYRIE-LICENSE THIRD-PARTY-NOTICES; do
    test -s "$doc/$notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'MIT License' "$doc/FPCVALKYRIE-LICENSE" >/dev/null
test -d "$doc/third-party-licenses/bash"
test -d "$doc/third-party-licenses/coreutils"
test -d "$doc/third-party-licenses/lua-5.1"
test -d "$doc/third-party-licenses/ncurses"
test -d "$doc/third-party-licenses/util-linux"

# The issue-specific executable, invocation, marker, and screenshot are a
# required contract, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 680' "$contract" >/dev/null
grep -F '"packageName": "drl"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-680.png"' \
    "$contract" >/dev/null
grep -F '"executable": "drl"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "DRL_GOOCASTLE_RUNTIME_OK"' \
    "$contract" >/dev/null

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

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'drl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$drl_out")

smoke_root=$(mktemp -d /tmp/goocastle-agent-drl-XXXXXXXX)
case "$smoke_root" in
    /tmp/goocastle-agent-drl-*) ;;
    *) echo 'refusing an unvalidated drl smoke workspace' >&2; exit 1 ;;
esac
cleanup ()
{
    "$rm_bin" -rf "$smoke_root"
}
trap cleanup EXIT HUP INT TERM
mkdir "$smoke_root/home" "$smoke_root/config" "$smoke_root/data" \
    "$smoke_root/cache" "$smoke_root/state" "$smoke_root/runtime" \
    "$smoke_root/tmp"
chmod 700 "$smoke_root/runtime"
export HOME="$smoke_root/home"
export XDG_CONFIG_HOME="$smoke_root/config"
export XDG_DATA_HOME="$smoke_root/data"
export XDG_CACHE_HOME="$smoke_root/cache"
export XDG_STATE_HOME="$smoke_root/state"
export XDG_RUNTIME_DIR="$smoke_root/runtime"
export TMPDIR="$smoke_root/tmp"
export TERM=xterm-256color
export LC_ALL=C

# bounded-validation owns the complete process group.  The package wrapper's
# --guix-smoke branch creates the PTYs for the two real curses sessions.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$smoke_root/terminal.raw}
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 60000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$drl_out/bin/drl" --guix-smoke)
case "$proof" in
    *'DRL_GOOCASTLE_RUNTIME_OK'*) ;;
    *)
        echo 'drl smoke did not produce its success marker' >&2
        exit 1
        ;;
esac
test -s "$raw"

after=$($guix_bin hash -S nar "$drl_out")
test "$before" = "$after"
test -z "$("$find_bin" "$drl_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$drl_out"

# The PTY stream can be turned into the reviewed runtime screenshot by the
# evidence adapter.  It must remain a PNG path under this channel's evidence.
if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'drl smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
