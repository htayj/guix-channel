#!/bin/sh
# Standalone native tty acceptance. No production test mode or shipped Python.
# Guix realizes test-only Python/pyte and namespace tools for every invocation,
# including a prebuilt package output. No test dependency enters the game.
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
            echo "usage: $0 [unnethack-store-output] [--output fresh-evidence-directory]"
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
    # mkdir is the driver's responsibility: it refuses stale evidence.
    output="${TMPDIR:-/tmp}/unnethack-evidence-$(date +%s)-$$"
fi
guix_bin=$(command -v "${GUIX:-guix}")
if test -z "$package"; then
    package=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-offload --cores=1 --max-jobs=1 unnethack)
fi
package=$(CDPATH= cd -- "$package" && pwd)
case "$package" in /gnu/store/*) ;; *) echo 'UnNetHack output must be in /gnu/store' >&2; exit 1 ;; esac
test -x "$package/bin/unnethack"
test ! -e "$package/libexec/unnethack-smoke.py"
test ! -e "$package/bin/unnethack-smoke"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$package")
status=0
"$guix_bin" shell --pure --no-grafts --no-offload --cores=1 --max-jobs=1 \
    python python-pyte util-linux coreutils -- \
    python3 -B "$channel_dir/tests/unnethack-smoke.py" \
    "$package/bin/unnethack" --output "$output" || status=$?
after=$($guix_bin hash -S nar "$package")
test "$before" = "$after"
test ! -w "$package"
test -z "$(find "$package" -xdev -perm /222 -print -quit)"
test "$status" -eq 0 || { echo "UnNetHack proof failed ($status): $output" >&2; exit 1; }
printf '%s\n' "$before" >"$output/nar-before.txt"
printf '%s\n' "$after" >"$output/nar-after.txt"
printf 'UnNetHack unchanged read-only NAR: %s\nNative evidence: %s\n' "$after" "$output"
