#!/bin/sh
# Exercise bcrawl's installed terminal arena in isolated XDG and network state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [bcrawl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    bcrawl_out=$1
else
    bcrawl_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes bcrawl)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

test -x "$bcrawl_out/bin/bcrawl"
test -x "$bcrawl_out/libexec/bcrawl"
test -d "$bcrawl_out/share/bcrawl/dat"
test ! -e "$bcrawl_out/share/bcrawl/dat/tiles"

# The root license and every compatible exception/notices copied by the
# package must remain available with the installed executable and data.
doc=$bcrawl_out/share/doc/bcrawl
test -s "$doc/LICENSE"
test -s "$doc/CREDITS.txt"
for notice in cc0.txt lgpl.txt libpng-LICENSE.txt lualicense.txt \
              pcre_license.txt worley.txt; do
    test -s "$doc/license/$notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/LICENSE" >/dev/null
grep -F 'bcrawl credits' "$doc/CREDITS.txt" >/dev/null
grep -F 'CC0 1.0 Universal' "$doc/license/cc0.txt" >/dev/null
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/license/lgpl.txt" >/dev/null
grep -F 'Lua is licensed under the terms of the MIT license' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null

# The issue-specific executable, invocation, and marker are a required part
# of the proof, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 660' "$contract" >/dev/null
grep -F '"packageName": "bcrawl"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-660.png"' "$contract" >/dev/null
grep -F '"executable": "bcrawl"' "$contract" >/dev/null
grep -F '"args": [' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
marker='bcrawl smoke: arena gameplay OK; no store writes'
grep -F "\"successMarker\": \"$marker\"" "$contract" >/dev/null

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'bcrawl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real game runs; this catches a regression that directs
# state back to the immutable package output.
before=$($guix_bin hash -S nar "$bcrawl_out")

# The launcher creates a new HOME/XDG tree and uses util-linux script for its
# PTY.  The outer bounded executor owns the complete process group, while the
# new user/network namespace gives the game no network interfaces at all.
proof=$(node /opt/goocastle/bin/bounded-validation.mjs --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$bcrawl_out/bin/bcrawl" --smoke)
case "$proof" in
    *"$marker"*) ;;
    *)
        echo 'bcrawl smoke did not produce its success marker' >&2
        exit 1
        ;;
esac

after=$($guix_bin hash -S nar "$bcrawl_out")
test "$before" = "$after"
