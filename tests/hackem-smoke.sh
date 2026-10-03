#!/bin/sh
# Standalone native tty acceptance; no production test mode or external runner.
set -eu
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=
package=
while test "$#" -gt 0; do
    case "$1" in
        --output)
            test "$#" -ge 2 || { echo 'missing --output directory' >&2; exit 64; }
            output=$2
            shift 2
            ;;
        --help|-h)
            echo "usage: $0 [hackem-store-output] [--output fresh-evidence-directory]"
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
    output="${TMPDIR:-/tmp}/hackem-evidence-$(date +%s)-$$"
fi
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 hackem)
fi
package=$(CDPATH= cd -- "$package" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'HackEM output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/hackem"
test -x "$package/libexec/hackem-real"
test -s "$package/share/hackem/nhdat"
test -s "$package/share/hackem/license"
test -s "$package/share/hackem/symbols"
test ! -e "$package/share/hackem/sounds"
for notice in LICENSE README.md Guidebook.txt hackem_changelog.txt README.linux isaac64.c; do
    test -s "$package/share/doc/hackem/$notice"
done
test -s "$package/share/man/man6/hackem.6.zst"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/hackem-smoke.py" \
    "$package/bin/hackem" --output "$output" || status=$?
after=$($guix_bin hash -S nar "$package")
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
test "$status" -eq 0 || { echo "HackEM native acceptance failed ($status): $output" >&2; exit 1; }
printf '%s\n' "$before" >"$output/nar-before.txt"
printf '%s\n' "$after" >"$output/nar-after.txt"
printf 'HackEM unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
