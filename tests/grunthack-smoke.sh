#!/bin/sh
# Exercise GruntHack's reviewed tty save/restore contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [grunthack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    grunthack_out=$1
else
    grunthack_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes grunthack)
fi

test -x "$grunthack_out/bin/grunthack"
test -x "$grunthack_out/libexec/grunthack-real"
test -s "$grunthack_out/share/grunthack/ghdat"
test -s "$grunthack_out/share/grunthack/license"
test ! -e "$grunthack_out/share/grunthack/sounds"
test ! -e "$grunthack_out/share/grunthack/GruntHack.ad"

doc=$grunthack_out/share/doc/grunthack
for notice in README README-curses.txt Guidebook.txt changes01.0 \
    changes01.1 changes02.0 changes02.1 README.linux license; do
    test -s "$doc/$notice"
done
grep -F 'NETHACK GENERAL PUBLIC LICENSE' \
    "$grunthack_out/share/grunthack/license" >/dev/null
grep -F 'GruntHack is a derivative of NetHack' "$doc/README" >/dev/null

# The issue-specific executable, invocation, marker, and screenshot are a
# required contract, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 691' "$contract" >/dev/null
grep -F '"packageName": "grunthack"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/grunthack.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-691.png"' \
    "$contract" >/dev/null
grep -F '"executable": "grunthack"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "grunthack guix smoke passed"' \
    "$contract" >/dev/null

bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"

before=$($guix_bin hash -S nar "$grunthack_out")

smoke_root=$(mktemp -d /tmp/goocastle-agent-grunthack-XXXXXXXX)
case "$smoke_root" in
    /tmp/goocastle-agent-grunthack-*) ;;
    *) echo 'refusing an unvalidated grunthack smoke workspace' >&2; exit 1 ;;
esac
cleanup ()
{
    rm -rf "$smoke_root"
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
unset HACKDIR NETHACKDIR GRUNTHACK_VAR_PLAYGROUND NETHACKOPTIONS MAIL MAILREADER SIMPLEMAIL || true

# bounded-validation owns the complete process group.  The installed wrapper
# creates the fresh HOME/XDG tree and the PTYs for both real curses sessions.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$smoke_root/terminal.raw}
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 60000 -- \
    "$grunthack_out/bin/grunthack" --guix-smoke)
case "$proof" in
    *'grunthack guix smoke passed'*) ;;
    *)
        echo 'grunthack smoke did not produce its success marker' >&2
        exit 1
        ;;
esac
test -s "$raw"

after=$($guix_bin hash -S nar "$grunthack_out")
test "$before" = "$after"
test -z "$(find "$grunthack_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$grunthack_out"

# The PTY stream can be turned into the reviewed runtime screenshot by the
# evidence adapter.  It must remain a PNG path under this channel's evidence.
if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'grunthack smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
