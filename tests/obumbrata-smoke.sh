#!/bin/sh
# External native acceptance; GUI tools are test-only, never installed helpers.
set -eu
umask 077
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=${OBUMBRATA_EVIDENCE_DIRECTORY:-}
package=
while test "$#" -gt 0; do
    case "$1" in
        --output)
            test "$#" -ge 2 || { echo 'missing --output directory' >&2; exit 64; }
            output=$2; shift 2 ;;
        --help|-h)
            echo "usage: $0 [obumbrata-store-output] [--output fresh-evidence-directory]"
            exit 0 ;;
        --*) echo "unknown option: $1" >&2; exit 64 ;;
        *)
            test -z "$package" || { echo 'only one package output allowed' >&2; exit 64; }
            package=$1; shift ;;
    esac
done
if test -z "$output"; then
    output="${TMPDIR:-/tmp}/obumbrata-evidence-$(date +%s)-$$"
fi
test ! -e "$output" || { echo 'evidence directory exists; choose a fresh --output' >&2; exit 64; }
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 obumbrata)
fi
package=$(realpath -e -- "$package")
case "$package" in /gnu/store/*) ;; *) echo 'Obumbrata output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/obumbrata"
test -x "$package/libexec/obumbrata"
for notice in COPYING notes.txt; do
    test -s "$package/share/doc/obumbrata/$notice"
done
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$("$guix_bin" hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    xterm xorg-server xdotool imagemagick python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/obumbrata-smoke.py" \
    "$package/bin/obumbrata" --output "$output" || status=$?
after=$("$guix_bin" hash -S nar "$package")
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
if test -d "$output"; then
    printf '%s\n' "$before" >"$output/nar-before.txt"
    printf '%s\n' "$after" >"$output/nar-after.txt"
fi
test "$status" -eq 0 || { echo "Obumbrata native acceptance failed ($status): $output" >&2; exit 1; }
printf 'Obumbrata unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
