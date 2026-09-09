#!/bin/sh
# Isolated installed-runtime proof for Hydra Slayer.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=${GOOCASTLE_NODE:-$(command -v node)}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}

if test "$#" -gt 1; then
    echo "usage: $0 [hydra-slayer-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hydra_out=$1
else
    hydra_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes hydra-slayer)
fi

test -x "$hydra_out/bin/hydra"
test -x "$hydra_out/libexec/hydra"
test -x "$hydra_out/libexec/hydra-slayer-smoke.py"
test -s "$hydra_out/share/doc/hydra-slayer/COPYING"
grep -F 'GNU GENERAL PUBLIC LICENSE' \
    "$hydra_out/share/doc/hydra-slayer/COPYING" >/dev/null
grep -F 'This program is free software' \
    "$hydra_out/share/doc/hydra-slayer/COPYING" >/dev/null
test ! -e "$hydra_out/share/hydra"

# The reviewed contract is part of this package-specific proof.
contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
grep -F '"issueNumber": 697' "$contract" >/dev/null
grep -F '"packageName": "hydra-slayer"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/hydra-slayer.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-697.png"' \
    "$contract" >/dev/null
grep -F '"executable": "hydra"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
marker='HYDRA_SLAYER_GUIX_SMOKE_OK: new-game, turn, save-load, isolated-state'
grep -F "\"successMarker\": \"$marker\"" "$contract" >/dev/null

test -r "$bounded_validation"
util_linux_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        util_linux_out=$candidate
        break
    fi
done
test -n "$util_linux_out"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'hydra-slayer smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$hydra_out")
test -z "$(find "$hydra_out" -xdev -type f -perm /222 -print -quit)"

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    scratch=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    scratch=$(mktemp -d /tmp/goocastle-agent-XXXXXX)
fi
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
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
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/state/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 90000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$hydra_out/bin/hydra" --guix-smoke)
export PATH="$host_path"
test "$proof" = "$marker"
test -s "$raw"
grep -aF 'Hydra Slayer v18.3' "$raw" >/dev/null
grep -aF 'Game saved to' "$raw" >/dev/null
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

if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'hydra-slayer smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$marker"
