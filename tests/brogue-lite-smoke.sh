#!/bin/sh
# Exercise Brogue Lite's installed terminal frontend in isolated state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [brogue-lite-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    brogue_lite_out=$1
else
    brogue_lite_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes brogue-lite)
fi

test -x "$brogue_lite_out/bin/brogue-lite"
test -x "$brogue_lite_out/libexec/brogue-lite"
test -x "$brogue_lite_out/libexec/brogue-lite-smoke-runner.py"
test -s "$brogue_lite_out/share/brogue-lite/keymap.txt"
test ! -e "$brogue_lite_out/share/brogue-lite/assets"

# Keep the source and asset licensing notices beside the installed program.
doc=$brogue_lite_out/share/doc/brogue-lite
for notice in README.md CHANGELOG.md CHANGELOG_LITE.md LICENSE.txt; do
    test -s "$doc/$notice"
done
test -s "$doc/assets/LICENSE.txt"
grep -F 'GNU AFFERO GENERAL PUBLIC LICENSE' "$doc/LICENSE.txt" >/dev/null
grep -F 'Brogue Lite' "$doc/README.md" >/dev/null
grep -F 'Creative Commons Attribution-ShareAlike 4.0' \
    "$doc/assets/LICENSE.txt" >/dev/null

# The reviewed executable contract is part of this proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 665' "$contract" >/dev/null
grep -F '"packageName": "brogue-lite"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-665.png"' \
    "$contract" >/dev/null
grep -F '"executable": "brogue-lite"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "brogue lite isolated smoke passed"' \
    "$contract" >/dev/null

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'brogue-lite smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$brogue_lite_out")

# The installed wrapper owns the fresh HOME/XDG/TMPDIR setup and the PTY
# session.  The bounded executor owns the complete namespace/process group so
# no network or leaked interactive process can escape this test.
proof=$(node "$bounded_validation" --timeout-ms 45000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$brogue_lite_out/bin/brogue-lite" --guix-smoke)
case "$proof" in
    *'brogue lite isolated smoke passed'*) ;;
    *)
        echo 'brogue-lite smoke did not produce its success marker' >&2
        exit 1
        ;;
esac

after=$($guix_bin hash -S nar "$brogue_lite_out")
test "$before" = "$after"
test -z "$(find "$brogue_lite_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$brogue_lite_out"
printf '%s\n' 'brogue lite isolated smoke passed'
