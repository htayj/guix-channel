#!/bin/sh
# Exercise Hellcrawl's installed terminal UI in isolated XDG state and a
# networkless namespace.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [hellcrawl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    hellcrawl_out=$1
else
    hellcrawl_out=$($guix_bin build -L . --no-grafts --no-substitutes hellcrawl)
fi

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

test -x "$hellcrawl_out/bin/hellcrawl"
test -x "$hellcrawl_out/libexec/hellcrawl"
test -x "$hellcrawl_out/libexec/hellcrawl-smoke-pty"
test -d "$hellcrawl_out/share/hellcrawl/dat"
test ! -e "$hellcrawl_out/share/hellcrawl/dat/tiles"
test ! -e "$hellcrawl_out/share/hellcrawl/webserver"

# The root license and every compatible notice copied by the package remain
# available with the installed executable and terminal data.
doc=$hellcrawl_out/share/doc/hellcrawl
test -s "$doc/licence.txt"
test -s "$doc/CREDITS.txt"
for notice in cc0.txt lgpl.txt libpng-LICENSE.txt lualicense.txt \
              pcre_license.txt worley.txt license.txt; do
    test -s "$doc/license/$notice"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/licence.txt" >/dev/null
grep -F 'Dungeon Crawl Stone Soup team' "$doc/CREDITS.txt" >/dev/null
grep -F 'CC0 1.0 Universal' "$doc/license/cc0.txt" >/dev/null
grep -F 'GNU LESSER GENERAL PUBLIC LICENSE' "$doc/license/lgpl.txt" >/dev/null
grep -F 'Lua is licensed under the terms of the MIT license reproduced below' \
    "$doc/license/lualicense.txt" >/dev/null
grep -F 'PCRE LICENCE' "$doc/license/pcre_license.txt" >/dev/null

# The issue-specific executable, invocation, and marker are a required part
# of the proof, not an advisory record.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 694' "$contract" >/dev/null
grep -F '"packageName": "hellcrawl"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/hellcrawl.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-694.png"' \
    "$contract" >/dev/null
grep -F '"executable": "hellcrawl"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
marker='hellcrawl smoke: terminal UI OK; no store writes'
grep -F "\"successMarker\": \"$marker\"" "$contract" >/dev/null

util_linux_out=$(find_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'hellcrawl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers all installed files, modes, and symlinks.  It must remain
# identical after the real game runs, catching accidental store writes.
before=$($guix_bin hash -S nar "$hellcrawl_out")

scratch=$(mktemp -d "${TMPDIR:-/tmp}/hellcrawl-smoke-test.XXXXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp"
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

# bounded-validation owns the complete process group.  The package wrapper's
# --smoke branch creates a fresh inner HOME/XDG tree and drives the real game
# through a PTY, while the namespace has no network interfaces.
raw=$scratch/terminal.raw
proof=$(GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 40000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$hellcrawl_out/bin/hellcrawl" --smoke)
case "$proof" in
    *"$marker"*) ;;
    *)
        echo 'hellcrawl smoke did not produce its success marker' >&2
        exit 1
        ;;
esac

test -s "$raw"
grep -aF 'choice of weapons' "$raw" >/dev/null
grep -aF 'Health:' "$raw" >/dev/null
grep -aF 'Goocastle' "$raw" >/dev/null

after=$($guix_bin hash -S nar "$hellcrawl_out")
test "$before" = "$after"
test ! -w "$hellcrawl_out"
printf '%s\n' "$proof"
