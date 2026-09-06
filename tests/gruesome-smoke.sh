#!/bin/sh
# Exercise the installed Gruesome launcher in an isolated PTY and state tree.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
grep_bin=$(command -v grep)
find_bin=$(command -v find)
env_bin=$(command -v env)
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [gruesome-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    gruesome_out=$1
else
    gruesome_out=$($guix_bin build -L . --no-grafts --no-substitutes gruesome)
fi

test -r "$bounded_validation"
test -x "$node_bin"
test -x "$gruesome_out/bin/gruesome"
test -x "$gruesome_out/libexec/gruesome-real"

doc="$gruesome_out/share/doc/gruesome"
for notice in license.txt readme.txt history.txt; do
    test -s "$doc/$notice"
done
"$grep_bin" -F 'GNU GENERAL PUBLIC LICENSE' "$doc/license.txt" >/dev/null
"$grep_bin" -F 'Version 3, 29 June 2007' "$doc/license.txt" >/dev/null
"$grep_bin" -F 'Copyright 2009 Darren Grey' "$doc/readme.txt" >/dev/null
"$grep_bin" -F 'Source can be compiled on Linux or Mac with FPC' \
    "$doc/readme.txt" >/dev/null
test -z "$($find_bin "$gruesome_out" -type f -iname '*.exe' -print -quit)"

# The reviewed per-issue runtime contract is part of this package proof.
contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
"$grep_bin" -F '"issueNumber": 690' "$contract" >/dev/null
"$grep_bin" -F '"packageName": "gruesome"' "$contract" >/dev/null
"$grep_bin" -F '"packageModulePath": "tay/packages/gruesome.scm"' \
    "$contract" >/dev/null
"$grep_bin" -F '"artifactPath": ".goocastle/evidence/issue-690.png"' \
    "$contract" >/dev/null
"$grep_bin" -F '"executable": "gruesome"' "$contract" >/dev/null
"$grep_bin" -F '"--smoke"' "$contract" >/dev/null
"$grep_bin" -F '"successMarker": "GRUESOME-SMOKE: gameplay-turn-ok"' \
    "$contract" >/dev/null

# The complete installed tree is immutable and must remain byte-for-byte
# unchanged while the user-facing launcher runs.
before=$($guix_bin hash -S nar "$gruesome_out")
test -z "$($find_bin "$gruesome_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$gruesome_out"

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
scratch=$(mktemp -d "$disposable_workspace/gruesome-XXXXXXXX")
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
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

# The package's --smoke path opens and controls a PTY via expect.  The
# immutable host validator supervises the complete process group, and the
# network namespace contains no host interfaces or routes.
unshare_bin=
for output in $($guix_bin build --no-grafts --no-substitutes util-linux); do
    if test -x "$output/bin/unshare"; then
        unshare_bin="$output/bin/unshare"
        break
    fi
done
test -n "$unshare_bin"
true_bin=/usr/bin/true
test -x "$true_bin"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$unshare_bin" --user --map-root-user --net --fork "$true_bin" \
        >/dev/null 2>&1; then
    echo 'gruesome smoke requires an unprivileged network namespace' >&2
    exit 77
fi

proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$env_bin" -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm-256color LC_ALL=C PATH= \
    ALL_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 \
    HTTPS_PROXY=http://127.0.0.1:9 NO_PROXY='*' \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$unshare_bin" --user --map-root-user --net --fork \
    "$gruesome_out/bin/gruesome" --smoke)
test "$proof" = 'GRUESOME-SMOKE: gameplay-turn-ok'
test -s "$raw"
"$grep_bin" -aF 'What is your name?' "$raw" >/dev/null
"$grep_bin" -aF 'You lurk in the shadows.' "$raw" >/dev/null
"$grep_bin" -aF 'Till next lurking....' "$raw" >/dev/null
"$grep_bin" -aF 'GRUESOME-SMOKE: gameplay-turn-ok' "$raw" >/dev/null

# The game has no persistent data files.  All package-owned paths and all
# isolated HOME/XDG/work paths must remain empty after the smoke.
test -z "$($find_bin "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"
after=$($guix_bin hash -S nar "$gruesome_out")
test "$before" = "$after"
test -z "$($find_bin "$gruesome_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$gruesome_out"

if test -n "${GOOCASTLE_SCREENSHOT-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'gruesome smoke: screenshot must be a channel evidence PNG' >&2
           exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    # The screenshot adapter turns the captured terminal byte stream into a
    # PNG after this proof.  Keep this optional handoff path constrained to the
    # reviewed evidence directory.
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
