#!/bin/sh
# Exercise xNetHack's tty new-game/save/restore/quit contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [xnethack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    xnethack_out=$1
else
    xnethack_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes xnethack)
fi

test -x "$xnethack_out/bin/xnethack"
test -x "$xnethack_out/libexec/xnethack"
test -x "$xnethack_out/libexec/xnethack-smoke.py"
test ! -L "$xnethack_out/bin/xnethack"
test ! -L "$xnethack_out/libexec/xnethack"
data=$xnethack_out/share/xnethack
for file in nhdat license symbols sysconf; do
    test -s "$data/$file"
done
test ! -e "$data/sounds"
test ! -e "$data/PDCurses"

doc=$xnethack_out/share/doc/xnethack
for notice in LICENSE README.md Guidebook.txt xnh-changelog-10.0.md \
    lua-COPYRIGHT; do
    test -s "$doc/$notice"
done
test -s "$xnethack_out/share/man/man6/xnethack.6.zst"
grep -F 'NETHACK GENERAL PUBLIC LICENSE' "$data/license" >/dev/null
grep -F 'Permission is hereby granted' "$doc/lua-COPYRIGHT" >/dev/null
# Game-end dumps must not be written to the shared /tmp.  (A negated command
# never triggers set -e, so fail explicitly.)
if grep -Eq '^(DUMPLOGFILE|DUMPHTMLFILE)=' "$data/sysconf"; then
    echo 'xnethack sysconf still enables /tmp dump files' >&2
    exit 1
fi

find_program_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_program_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
coreutils_out=$(find_program_output bin/timeout coreutils)
test -x "$coreutils_out/bin/timeout"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'xnethack smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$xnethack_out")

smoke_root=$(mktemp -d /tmp/goocastle-agent-xnethack-XXXXXXXX)
case "$smoke_root" in
    /tmp/goocastle-agent-xnethack-*) ;;
    *) echo 'refusing an unvalidated xnethack smoke workspace' >&2; exit 1 ;;
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
unset HACKDIR NETHACKDIR XNETHACK_VAR_PLAYGROUND XNETHACKOPTIONS MAIL \
    MAILREADER NETHACKOPTIONS WIZKIT || true

# nh_getenv() rejects values over 128 bytes, so the launcher must refuse a
# playground path over 128 bytes even when a UTF-8 locale counts fewer
# characters.  The launcher appends "/xnethack/" (10 bytes) to
# XDG_STATE_HOME.  Probe both sides of the boundary with --version; the
# over-limit path is 129 bytes but only 128 UTF-8 characters.
boundary=$smoke_root/boundary/
pad_len=$((128 - 10 - ${#boundary} - 1))
test "$pad_len" -gt 0
pad=$(printf '%*s' "$pad_len" '' | tr ' ' a)
at_limit=${boundary}a$pad
over_limit=$boundary$(printf '\303\251')$pad
test "$(printf '%s' "$at_limit/xnethack/" | wc -c)" -eq 128
test "$(printf '%s' "$over_limit/xnethack/" | wc -c)" -eq 129
LC_ALL=C.UTF-8 XDG_STATE_HOME=$at_limit \
    "$coreutils_out/bin/timeout" --kill-after=5 30 \
    "$xnethack_out/bin/xnethack" --version | grep -F 'xNetHack Version 10.0' \
    >/dev/null
status=0
message=$(LC_ALL=C.UTF-8 XDG_STATE_HOME=$over_limit \
    "$coreutils_out/bin/timeout" --kill-after=5 30 \
    "$xnethack_out/bin/xnethack" --version 2>&1) || status=$?
test "$status" -eq 1
test "$message" = 'xnethack: state directory path exceeds 128 bytes'
test ! -e "$over_limit"

# The package's own smoke branch creates a second fresh HOME/XDG tree and
# drives two real PTY sessions.  The unshare wrapper prevents the package
# process from inheriting network access; timeout bounds the whole run.  The
# driver writes the raw capture only after every behaviour assertion passed.
raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$smoke_root/terminal.raw}
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$coreutils_out/bin/timeout" --kill-after=5 120 \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$xnethack_out/bin/xnethack" --guix-smoke)
test "$proof" = 'xnethack guix smoke passed'
test -s "$raw"

after=$($guix_bin hash -S nar "$xnethack_out")
test "$before" = "$after"
test -z "$(find "$xnethack_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$xnethack_out"

printf '%s\n' "$proof"
