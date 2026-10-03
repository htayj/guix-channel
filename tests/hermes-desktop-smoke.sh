#!/bin/sh
# Installed Hermes acceptance. No host profile/credentials; Guix realizes test tools.
# Usage: sh tests/hermes-desktop-smoke.sh [--backend-only] [--backend STORE]
#        [--desktop STORE] [--evidence EMPTY-DIRECTORY] [--hold-seconds N]
# GUIX selects guix. Prebuilt outputs still use a fresh pure test-tool environment.
set -eu
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
backend= desktop= evidence= hold=0 backend_only=false
while test "$#" -gt 0; do
    case "$1" in
        --backend-only) backend_only=true; shift ;;
        --backend|--desktop|--evidence|--hold-seconds)
            test "$#" -ge 2 || { echo "missing value for $1" >&2; exit 64; }
            case "$1" in
                --backend) backend=$2 ;; --desktop) desktop=$2 ;;
                --evidence) evidence=$2 ;; --hold-seconds) hold=$2 ;;
            esac
            shift 2 ;;
        *) echo "unknown option: $1; see usage in $0" >&2; exit 64 ;;
    esac
done
case "$hold" in ''|*[!0-9]*) echo 'hold seconds must be nonnegative integer' >&2; exit 64 ;; esac
if test -z "$backend"; then
    backend=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts hermes-agent)
fi
if test "$backend_only" = false && test -z "$desktop"; then
    desktop=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts hermes-desktop)
fi
for output in "$backend" ${desktop:+"$desktop"}; do
    case "$output" in /gnu/store/*) test -d "$output" ;; *) echo "not a store output: $output" >&2; exit 64 ;; esac
done
test -x "$backend/bin/hermes-python"
test -x "$backend/bin/hermes"
if test -n "$desktop"; then test -x "$desktop/bin/hermes-desktop"; fi
if test -z "$evidence"; then evidence=$(mktemp -d /tmp/hermes-desktop-evidence.XXXXXXXX); fi
case "$evidence" in /*) ;; *) echo 'evidence path must be absolute' >&2; exit 64 ;; esac
mkdir -p "$evidence"
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || { echo 'evidence directory must be empty' >&2; exit 64; }
backend_before=$("$guix_bin" hash -S nar "$backend")
printf '%s\n' "$backend_before" >"$evidence/backend-nar-before.txt"
desktop_before=
if test -n "$desktop"; then
    desktop_before=$("$guix_bin" hash -S nar "$desktop")
    printf '%s\n' "$desktop_before" >"$evidence/desktop-nar-before.txt"
fi
status=0
# --pure removes host provider/session variables. The Python helper further uses
# an explicit environment allowlist, a private X server and a private session bus.
"$guix_bin" shell --pure --no-grafts python coreutils xorg-server dbus font-dejavu -- \
    python3 -I -B "$channel_dir/tests/hermes-desktop-smoke.py" \
    --backend "$backend" --desktop "$desktop" --evidence "$evidence" \
    --hold-seconds "$hold" >"$evidence/proof.log" 2>&1 || status=$?
# Hash even after runtime failure; failure must not conceal store mutation.
backend_after=$("$guix_bin" hash -S nar "$backend")
printf '%s\n' "$backend_after" >"$evidence/backend-nar-after.txt"
if test "$backend_before" != "$backend_after"; then status=1; echo 'backend NAR changed' >&2; fi
if test -n "$desktop"; then
    desktop_after=$("$guix_bin" hash -S nar "$desktop")
    printf '%s\n' "$desktop_after" >"$evidence/desktop-nar-after.txt"
    if test "$desktop_before" != "$desktop_after"; then status=1; echo 'desktop NAR changed' >&2; fi
fi
cat "$evidence/proof.log"
printf 'Hermes acceptance evidence: %s\n' "$evidence"
exit "$status"
