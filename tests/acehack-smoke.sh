#!/bin/sh
# External native consumer: tests/acehack-smoke.sh OUTPUT EVIDENCE
# OUTPUT is prebuilt; EVIDENCE must be fresh.  Generic tools are realized before
# isolation.  Acceptance is normal birth, dungeon turns, save, restore and turns.
set -eu
umask 077
test "$#" -eq 2 || { echo "usage: $0 OUTPUT EVIDENCE" >&2; exit 64; }
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
package=$(CDPATH= cd -- "$1" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'OUTPUT must be a /gnu/store output' >&2; exit 64 ;; esac
test -x "$package/bin/acehack" || { echo 'OUTPUT lacks bin/acehack' >&2; exit 64; }
test ! -e "$2" && test ! -L "$2" || { echo 'EVIDENCE exists; choose a fresh directory' >&2; exit 64; }
guix_bin=$(command -v "${GUIX:-guix}") || { echo 'GUIX executable not found' >&2; exit 127; }
mkdir -- "$2"
evidence=$(CDPATH= cd -- "$2" && pwd)
# Never realize AceHack or its source here; resolve only generic test tools.
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- true
"$guix_bin" gc -R "$package" >"$evidence/runtime-closure.txt"
before=$("$guix_bin" hash -S nar "$package")
printf '%s\n' "$before" >"$evidence/nar-before.txt"
printf '%s\n' "$package" >"$evidence/store-output.txt"
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/acehack-native.py" \
    "$package" "$evidence" >"$evidence/driver.stdout" 2>"$evidence/driver.stderr" || status=$?
after=$("$guix_bin" hash -S nar "$package")
printf '%s\n' "$after" >"$evidence/nar-after.txt"
printf '%s\n' "$status" >"$evidence/consumer-exit-status.txt"
if test "$before" != "$after"; then
    echo "AceHack store NAR changed; evidence: $evidence" >&2
    exit 1
fi
if test "$status" -ne 0; then
    echo "AceHack native consumer failed ($status); evidence: $evidence" >&2
    exit "$status"
fi
printf 'AceHack unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$evidence"
