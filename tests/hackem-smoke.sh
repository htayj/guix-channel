#!/bin/sh
# Exercise Hack'EM's reviewed tty save/restore contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [hackem-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hackem_out=$1
else
    hackem_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes hackem)
fi

test -x "$hackem_out/bin/hackem"
test -x "$hackem_out/libexec/hackem-real"
test -s "$hackem_out/share/hackem/nhdat"
test -s "$hackem_out/share/hackem/license"
test ! -e "$hackem_out/share/hackem/sounds"
test ! -e "$hackem_out/share/hackem/PDCurses"

doc=$hackem_out/share/doc/hackem
for notice in LICENSE README.md Guidebook.txt hackem_changelog.txt README.linux; do
    test -s "$doc/$notice"
done
test -s "$hackem_out/share/man/man6/hackem.6.zst"
grep -F 'NETHACK GENERAL PUBLIC LICENSE' \
    "$hackem_out/share/hackem/license" >/dev/null
grep -F "Hack'EM" "$doc/README.md" >/dev/null

# The issue-specific executable, invocation, marker, and screenshot are a
# required contract, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 693' "$contract" >/dev/null
grep -F '"packageName": "hackem"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/hackem.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-693.png"' \
    "$contract" >/dev/null
grep -F '"executable": "hackem"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "hackem guix smoke passed"' \
    "$contract" >/dev/null

bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
unshare_out=$($guix_bin build -L "$channel_dir" --no-grafts util-linux | sed -n '2p')
test -x "$unshare_out/bin/unshare"

before=$($guix_bin hash -S nar "$hackem_out")

smoke_root=$(mktemp -d /tmp/goocastle-agent-hackem-XXXXXXXX)
case "$smoke_root" in
    /tmp/goocastle-agent-hackem-*) ;;
    *) echo 'refusing an unvalidated hackem smoke workspace' >&2; exit 1 ;;
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
export TERM=xterm-256color LC_ALL=C LANG=C
unset HACKDIR NETHACKDIR HACKEM_VAR_PLAYGROUND MAIL MAILREADER \
    NETHACKOPTIONS WIZKIT || true

# The package's own smoke branch creates a second fresh HOME/XDG tree.  The
# unshare wrapper prevents the actual package process from inheriting network
# access, while bounded-validation owns the complete PTY process group.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$smoke_root/terminal.raw}
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 60000 -- \
    "$unshare_out/bin/unshare" --user --map-root-user --net --fork \
    "$hackem_out/bin/hackem" --guix-smoke)
case "$proof" in
    *'hackem guix smoke passed'*) ;;
    *)
        echo 'hackem smoke did not produce its success marker' >&2
        exit 1
        ;;
esac
test -s "$raw"

after=$($guix_bin hash -S nar "$hackem_out")
test "$before" = "$after"
test -z "$(find "$hackem_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$hackem_out"

printf '%s\n' "$proof"
