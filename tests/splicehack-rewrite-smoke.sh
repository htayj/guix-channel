#!/bin/sh
# External native acceptance; GUI tools are test-only, never installed helpers.
set -eu
umask 077
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=${SPLICEHACK_REWRITE_EVIDENCE_DIRECTORY:-}
package=
while test "$#" -gt 0; do
    case "$1" in
        --output)
            test "$#" -ge 2 || { echo 'missing --output directory' >&2; exit 64; }
            output=$2
            shift 2
            ;;
        --help|-h)
            echo "usage: $0 [splicehack-rewrite-store-output] [--output fresh-evidence-directory]"
            exit 0
            ;;
        --*) echo "unknown option: $1" >&2; exit 64 ;;
        *)
            test -z "$package" || { echo 'only one package output allowed' >&2; exit 64; }
            package=$1
            shift
            ;;
    esac
done
if test -z "$output"; then
    output="${TMPDIR:-/tmp}/splicehack-rewrite-evidence-$(date +%s)-$$"
fi
test ! -e "$output" || { echo 'evidence directory exists; choose a fresh --output' >&2; exit 64; }
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 splicehack-rewrite)
fi
package=$(CDPATH= cd -- "$package" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'SpliceHack Rewrite output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/splicehack-rewrite"
test -x "$package/libexec/splicehack-rewrite-real"
for asset in nhdat license symbols; do
    test -s "$package/share/splicehack-rewrite/$asset"
done
for notice in README Guidebook.txt isaac64.c lua-readme.html license spl-sources.txt spl-changelog.txt; do
    test -s "$package/share/doc/splicehack-rewrite/$notice"
done
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$("$guix_bin" hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    xterm xorg-server xdotool imagemagick python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/splicehack-rewrite-smoke.py" \
    "$package/bin/splicehack-rewrite" --output "$output" || status=$?
after=$("$guix_bin" hash -S nar "$package")
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
if test -d "$output"; then
    printf '%s\n' "$before" >"$output/nar-before.txt"
    printf '%s\n' "$after" >"$output/nar-after.txt"
fi
test "$status" -eq 0 || { echo "SpliceHack Rewrite native acceptance failed ($status): $output" >&2; exit 1; }
printf 'SpliceHack Rewrite unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
