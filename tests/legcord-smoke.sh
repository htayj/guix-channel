#!/bin/sh
# Installed Legcord acceptance; no host Discord profile or credentials.
# Usage: sh tests/legcord-smoke.sh [--legcord STORE] [--evidence EMPTY-DIRECTORY]
#        [--hold-seconds N]. GUIX selects the Guix executable.
set -eu
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
legcord= evidence= hold=0
while test "$#" -gt 0; do
    case "$1" in
        --legcord|--evidence|--hold-seconds)
            test "$#" -ge 2 || { echo "missing value for $1" >&2; exit 64; }
            case "$1" in
                --legcord) legcord=$2 ;; --evidence) evidence=$2 ;;
                --hold-seconds) hold=$2 ;;
            esac
            shift 2 ;;
        *) echo "unknown option: $1; see usage in $0" >&2; exit 64 ;;
    esac
done
case "$hold" in ''|*[!0-9]*) echo 'hold seconds must be a nonnegative integer' >&2; exit 64 ;; esac
if test -z "$legcord"; then
    legcord=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts legcord)
fi
case "$legcord" in /gnu/store/*) test -d "$legcord" ;; *) echo "not a store output: $legcord" >&2; exit 64 ;; esac
test -x "$legcord/bin/legcord"
if test -z "$evidence"; then evidence=$(mktemp -d /tmp/legcord-evidence.XXXXXXXX); fi
case "$evidence" in /*) ;; *) echo 'evidence path must be absolute' >&2; exit 64 ;; esac
mkdir -p "$evidence"
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || { echo 'evidence directory must be empty' >&2; exit 64; }
before=$("$guix_bin" hash -S nar "$legcord")
printf '%s\n' "$before" >"$evidence/legcord-nar-before.txt"
status=0
# --pure plus the driver's allowlist discards host session/provider variables.
"$guix_bin" shell --pure --no-grafts python python-websocket-client \
    -e '(@ (gnu packages python-xyz) python-pillow)' \
    coreutils xorg-server dbus font-dejavu xdotool -- \
    python3 -s -P -B "$channel_dir/tests/legcord-smoke.py" --legcord "$legcord" \
    --evidence "$evidence" --hold-seconds "$hold" >"$evidence/proof.log" 2>&1 || status=$?
# Check even on runtime failure: failure must not conceal store mutation.
after=$("$guix_bin" hash -S nar "$legcord")
printf '%s\n' "$after" >"$evidence/legcord-nar-after.txt"
if test "$before" != "$after"; then status=1; echo 'Legcord NAR changed' >&2; fi
cat "$evidence/proof.log"
printf 'Legcord acceptance evidence: %s\n' "$evidence"
exit "$status"
