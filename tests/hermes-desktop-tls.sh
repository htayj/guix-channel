#!/bin/sh
# Optional TLS acceptance of prebuilt outputs; never builds Desktop/backend.
# Usage: sh tests/hermes-desktop-tls.sh --desktop STORE --backend STORE --ca CA \
#        --remote https://IP[:PORT] --evidence EMPTY-ABSOLUTE-DIR [--hold-seconds N]
# Guix supplies Python, OpenSSL, NSS certutil, private Xvfb/D-Bus and fonts.
# Must run as ordinary user with working user namespaces/Electron sandbox.
# HTTP/WSS fixtures are PKI evidence only; real remote uses no credentials.
set -eu
guix_bin=$(command -v "${GUIX:-guix}")
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
desktop= backend= ca= remote= evidence= hold=0
while test "$#" -gt 0; do
    case "$1" in
        --desktop|--backend|--ca|--remote|--evidence|--hold-seconds)
            test "$#" -ge 2 || { echo "missing value for $1" >&2; exit 64; }
            case "$1" in
                --desktop) desktop=$2 ;; --backend) backend=$2 ;; --ca) ca=$2 ;;
                --remote) remote=$2 ;; --evidence) evidence=$2 ;; --hold-seconds) hold=$2 ;;
            esac
            shift 2 ;;
        *) echo "unknown option: $1; see usage in $0" >&2; exit 64 ;;
    esac
done
test -n "$desktop" && test -n "$backend" && test -n "$ca" && test -n "$remote" && test -n "$evidence" || {
    echo '--desktop --backend --ca --remote --evidence are required' >&2; exit 64;
}
case "$hold" in ''|*[!0-9]*) echo 'hold seconds must be nonnegative integer' >&2; exit 64 ;; esac
for output in "$desktop" "$backend"; do
    case "$output" in /gnu/store/*) test -d "$output" ;; *) echo "not a store output: $output" >&2; exit 64 ;; esac
done
test -x "$desktop/bin/hermes-desktop"
test -x "$backend/bin/hermes-python"
case "$ca" in /*) test -f "$ca" ;; *) echo 'CA path must be absolute' >&2; exit 64 ;; esac
case "$evidence" in /*) ;; *) echo 'evidence path must be absolute' >&2; exit 64 ;; esac
mkdir -p "$evidence"
test -z "$(find "$evidence" -mindepth 1 -print -quit)" || { echo 'evidence directory must be empty' >&2; exit 64; }
# Helper enforces emptiness. Keep NAR/proof evidence outside until it starts.
work=$(mktemp -d /tmp/hermes-tls-launch.XXXXXXXX)
trap 'rm -rf "$work"' EXIT HUP INT TERM
"$guix_bin" hash -S nar "$desktop" >"$work/desktop-nar-before.txt"
"$guix_bin" hash -S nar "$backend" >"$work/backend-nar-before.txt"
status=0
"$guix_bin" shell --pure --no-grafts python openssl coreutils xorg-server dbus font-dejavu \
    -e '(list (@ (gnu packages nss) nss) "bin")' -- \
    python3 -I -B "$channel_dir/tests/hermes-desktop-tls.py" \
    --desktop "$desktop" --backend "$backend" --ca "$ca" --remote "$remote" \
    --evidence "$evidence" --hold-seconds "$hold" >"$work/proof.log" 2>&1 || status=$?
"$guix_bin" hash -S nar "$desktop" >"$work/desktop-nar-after.txt"
"$guix_bin" hash -S nar "$backend" >"$work/backend-nar-after.txt"
for output in desktop backend; do
    if ! cmp -s "$work/$output-nar-before.txt" "$work/$output-nar-after.txt"; then
        status=1; echo "$output NAR changed" >&2
    fi
done
cp "$work/"* "$evidence/"
cat "$evidence/proof.log"
printf 'Hermes TLS acceptance evidence: %s\n' "$evidence"
exit "$status"
