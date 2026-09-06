#!/bin/sh
# Exercise Hack's reviewed tty save/restore contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}

if test "$#" -gt 1; then
    echo "usage: $0 [hack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hack_out=$1
else
    # The program under test must come from this channel's source build.
    hack_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes hack)
fi

test -x "$hack_out/bin/hack"
test -x "$hack_out/libexec/hack"
for asset in data help hh rumors; do
    test -s "$hack_out/share/hack/$asset"
done
test -s "$hack_out/share/man/man6/hack.6.zst"
test -s "$hack_out/share/doc/hack/COPYRIGHT"
test -s "$hack_out/share/doc/hack/COPYRIGHT-JF"
test -s "$hack_out/share/doc/hack/READ_ME"
test ! -e "$hack_out/share/doc/hack/Original_READ_ME"
grep -F 'Stichting Centrum voor Wiskunde en Informatica' "$hack_out/share/doc/hack/COPYRIGHT" >/dev/null
grep -F 'Copyright (c) 1982 Jay Fenlason' "$hack_out/share/doc/hack/COPYRIGHT-JF" >/dev/null

contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 692' "$contract" >/dev/null
grep -F '"packageName": "hack"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-692.png"' "$contract" >/dev/null
grep -F '"executable": "hack"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "hack guix smoke passed"' "$contract" >/dev/null

test -r "$bounded_validation"
unshare_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        unshare_out=$candidate
        break
    fi
done
test -n "$unshare_out"

# Verify that the actual package process can run without a network namespace.
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- "$unshare_out/bin/unshare" --user --map-root-user --net --fork true >/dev/null 2>&1; then
    echo 'hack smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$hack_out")

smoke_root=$(mktemp -d /tmp/goocastle-agent-hack-smoke-XXXXXXXX)
case "$smoke_root" in
    /tmp/goocastle-agent-hack-smoke-*) ;;
    *) echo 'refusing an unvalidated Hack smoke workspace' >&2; exit 1 ;;
esac
mkdir "$smoke_root/home" "$smoke_root/config" "$smoke_root/data" "$smoke_root/cache" "$smoke_root/state" "$smoke_root/runtime" "$smoke_root/tmp"
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
unset HACKDIR HACKOPTIONS MAIL MAILREADER SHELL || true

# The package's --guix-smoke branch creates fresh XDG directories again and
# runs both real game sessions inside PTYs.  The immutable bounded executor
# owns the complete process group and the network-less namespace.
raw=$smoke_root/terminal.raw
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" "$node_bin" "$bounded_validation" --timeout-ms 60000 -- "$unshare_out/bin/unshare" --user --map-root-user --net --fork "$hack_out/bin/hack" --guix-smoke)
test "$proof" = 'hack guix smoke passed'
test -s "$raw"

after=$($guix_bin hash -S nar "$hack_out")
test "$before" = "$after"
test -z "$(find "$hack_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$hack_out"

# The PTY stream can be turned into the reviewed runtime screenshot by the
# evidence adapter.  Keep the artifact within this channel's evidence tree.
if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'hack smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' 'hack guix smoke passed'
