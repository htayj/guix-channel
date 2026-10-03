#!/bin/sh
# Ordinary native Hack sessions; no production test mode or external executor.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [hack-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    hack_out=$1
else
    hack_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes hack)
fi
hack_out=$(CDPATH= cd -- "$hack_out" && pwd)
case "$hack_out" in
    /gnu/store/*) ;;
    *) echo 'Hack output must be in /gnu/store' >&2; exit 1 ;;
esac


test -x "$hack_out/bin/hack"
test -x "$hack_out/libexec/hack"
for asset in data help hh rumors; do
    test -s "$hack_out/share/hack/$asset"
done
test -s "$hack_out/share/man/man6/hack.6.zst"
for notice in COPYRIGHT COPYRIGHT-JF READ_ME; do
    test -s "$hack_out/share/doc/hack/$notice"
done
grep -F 'Stichting Centrum voor Wiskunde en Informatica' "$hack_out/share/doc/hack/COPYRIGHT" >/dev/null
grep -F 'Copyright (c) 1982 Jay Fenlason' "$hack_out/share/doc/hack/COPYRIGHT-JF" >/dev/null

root=$(mktemp -d "${TMPDIR:-/tmp}/hack-native-proof.XXXXXX")
# Preserve only when explicitly requested, to let Main inspect native saves.
cleanup() {
    if test -z "${HACK_KEEP_PROOF:-}"; then rm -rf "$root"; fi
}
trap cleanup EXIT HUP INT TERM
for directory in home config data cache state runtime tmp work proof; do
    mkdir "$root/$directory"
done
chmod 700 "$root/runtime"
before=$($guix_bin hash -S nar "$hack_out")
# Guix realizes the complete environment before Python enters its namespaces;
# no daemon, network or ambient Python installation is used inside the proof.
status=0
"$guix_bin" shell --pure --no-grafts python python-pyte util-linux coreutils -- \
    env HACK_RAW_CAPTURE="${HACK_RAW_CAPTURE:-$root/proof/pre-exit.raw}" \
    HACK_TEXT_CAPTURE="${HACK_TEXT_CAPTURE:-$root/proof/pre-exit.txt}" \
    HACK_TRANSCRIPT="${HACK_TRANSCRIPT:-$root/proof/transcript.raw}" \
    python3 -B "$channel_dir/tests/hack-smoke.py" \
    "$hack_out/bin/hack" "$root" || status=$?
after=$($guix_bin hash -S nar "$hack_out")
test "$before" = "$after"
printf '%s\n' "$before" >"$root/proof/nar-before.txt"
printf '%s\n' "$after" >"$root/proof/nar-after.txt"
test "$status" -eq 0 || { echo "Hack native proof failed ($status)" >&2; exit 1; }
printf '%s\n' 'Hack native movement/turn, exact restore, further turn/resave and NAR immutability passed'
if test -n "${HACK_KEEP_PROOF:-}"; then printf 'proof-root: %s\n' "$root"; fi
