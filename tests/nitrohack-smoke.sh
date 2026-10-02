#!/bin/sh
# Standalone native curses acceptance; no shipped test mode or Python.
# Guix realizes test-only dependencies even for an existing store output.
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
            echo "usage: $0 [nitrohack-store-output] [--output fresh-evidence-directory]"
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
    output="${TMPDIR:-/tmp}/nitrohack-evidence-$(date +%s)-$$"
fi
test ! -e "$output" || { echo 'evidence already exists; choose fresh --output' >&2; exit 1; }
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 nitrohack)
fi
package=$(CDPATH= cd -- "$package" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'NitroHack output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/nitrohack"
test -x "$package/libexec/nitrohack-real"
test ! -e "$package/libexec/nitrohack-smoke.py"
test ! -e "$package/bin/nitrohack-smoke"
test ! -e "$package/share/nitrohack/nitrohack"
test -s "$package/share/nitrohack/nhdat"
test -s "$package/share/nitrohack/license"
doc=$package/share/doc/nitrohack
for notice in README Guidebook.txt copyright; do
    test -s "$doc/$notice"
done
grep -F 'NITROHACK GENERAL PUBLIC LICENSE' "$package/share/nitrohack/license" >/dev/null
grep -F 'renamed to NitroHack as of December 2011' "$package/share/nitrohack/license" >/dev/null
grep -F 'Daniel Thaler' "$doc/copyright" >/dev/null
grep -F 'NetHack Devteam' "$doc/copyright" >/dev/null
test -z "$(find "$package" -type f \( -name '*.ico' -o -name '*.bdf' -o -name '*.ttf' -o -name '*.wav' \) -print -quit)"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/nitrohack-smoke.py" \
    "$package/bin/nitrohack" --output "$output" || status=$?
after=$($guix_bin hash -S nar "$package")
if test -d "$output"; then
    printf '%s\n' "$before" >"$output/nar-before.txt"
    printf '%s\n' "$after" >"$output/nar-after.txt"
fi
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
test "$status" -eq 0 || { echo "NitroHack proof failed ($status): $output" >&2; exit 1; }
printf 'NitroHack unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
