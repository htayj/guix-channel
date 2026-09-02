#!/bin/sh
# Exercise CryptRover's installed terminal game in isolated XDG state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [cryptrover-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    cryptrover_out=$1
else
    cryptrover_out=$($guix_bin build -L . --no-grafts --no-substitutes cryptrover)
fi

test -x "$cryptrover_out/bin/cryptrover"
test -x "$cryptrover_out/libexec/cryptrover"
test ! -e "$cryptrover_out/bin/cr"
test ! -e "$cryptrover_out/libexec/cr"

doc=$cryptrover_out/share/doc/cryptrover
test -s "$doc/README"
test -s "$doc/COPYING"
test -s "$doc/BSD-3-Clause.txt"
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/COPYING" >/dev/null
grep -F 'Redistribution and use in source and binary forms' \
    "$doc/BSD-3-Clause.txt" >/dev/null
grep -F 'specific prior written permission' \
    "$doc/BSD-3-Clause.txt" >/dev/null

# The reviewed per-issue runtime contract is part of this proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 671' "$contract" >/dev/null
grep -F '"packageName": "cryptrover"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-671.png"' \
    "$contract" >/dev/null
grep -F '"executable": "cryptrover"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F '"successMarker": "CRYPTROVER_RUNTIME_OK"' \
    "$contract" >/dev/null

util_linux_out=
for output in $($guix_bin build -L . --no-grafts --no-substitutes util-linux); do
    if test -x "$output/bin/script" && test -x "$output/bin/unshare"; then
        util_linux_out=$output
        break
    fi
done
test -n "$util_linux_out"
test -x "$util_linux_out/bin/script"
test -x "$util_linux_out/bin/unshare"
test -r "$bounded_validation"

# The game has no network feature; the empty namespace makes that property a
# runtime invariant of this proof as well.
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'cryptrover smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$cryptrover_out")
test -z "$(find "$cryptrover_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-cryptrover-XXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-cryptrover-*) ;;
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
export LC_ALL=C

raw=$scratch/work/terminal.raw
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    env -i HOME="$HOME" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    XDG_STATE_HOME="$XDG_STATE_HOME" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    TMPDIR="$TMPDIR" TERM="$TERM" LC_ALL="$LC_ALL" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    PATH="$cryptrover_out/bin" \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$cryptrover_out/bin/cryptrover" --smoke)
test "$proof" = CRYPTROVER_RUNTIME_OK
test -s "$raw"

# The PTY transcript proves the initial map/help, one real wait turn, the
# loss/high-score path, and the generated score record.
grep -aF 'To move or attack use wasd' "$raw" >/dev/null
grep -aF 'Dungeon level: 1/12' "$raw" >/dev/null
grep -aF 'Air: 99%' "$raw" >/dev/null
grep -aF 'YOU HAVE LOST!' "$raw" >/dev/null
grep -aF 'Gold:' "$raw" >/dev/null
grep -aF '@' "$raw" >/dev/null
score_file=$(find "$scratch/tmp" -type f \
    -path '*/state/cryptrover/scores.dat' -print -quit)
test -n "$score_file"
test -s "$score_file"
grep -F 'Gold:' "$score_file" >/dev/null

# No caller HOME/XDG tree is touched except the fresh state tree, and no
# package-output path receives the game's relative scores.dat.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" \
    -mindepth 1 \
    -print -quit)"
test -z "$(find "$cryptrover_out" -xdev -name scores.dat -print -quit)"
test ! -w "$cryptrover_out"

after=$($guix_bin hash -S nar "$cryptrover_out")
test "$before" = "$after"
test -z "$(find "$cryptrover_out" -xdev -type f -perm /222 -print -quit)"

if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'cryptrover-smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
