#!/bin/sh
# Ordinary native tty play; all Python/pyte and namespace tools are test-only.
# Test dependencies are realized even when a prebuilt store output is supplied.
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
            echo "usage: $0 [grunthack-store-output] [--output fresh-evidence-directory]"
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
    output="${TMPDIR:-/tmp}/grunthack-evidence-$(date +%s)-$$"
fi
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 grunthack)
fi
package=$(CDPATH= cd -- "$package" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'GruntHack output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/grunthack"
test -x "$package/libexec/grunthack-real"
data="$package/share/grunthack"
doc="$package/share/doc/grunthack"
for file in ghdat license; do test -s "$data/$file"; done
for file in README README-curses.txt Guidebook.txt changes01.0 changes01.1 \
    changes02.0 changes02.1 README.linux license SOURCE sounds-README; do
    test -s "$doc/$file"
done
grep -F 'NETHACK GENERAL PUBLIC LICENSE' "$data/license" >/dev/null
grep -F 'GruntHack is a derivative of NetHack' "$doc/README" >/dev/null
grep -F '51d75eebbcf8ab0ce31ddab9581d266db0a691c5' "$doc/SOURCE" >/dev/null
test ! -e "$data/sounds"
test ! -e "$data/GruntHack.ad"
test ! -e "$package/libexec/grunthack-smoke.py"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/grunthack-smoke.py" \
    "$package/bin/grunthack" --output "$output" || status=$?
after=$($guix_bin hash -S nar "$package")
if test -d "$output"; then
    printf '%s\n' "$before" >"$output/nar-before.txt"
    printf '%s\n' "$after" >"$output/nar-after.txt"
fi
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
test "$status" -eq 0 || { echo "GruntHack proof failed ($status): $output" >&2; exit 1; }
printf 'GruntHack unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
