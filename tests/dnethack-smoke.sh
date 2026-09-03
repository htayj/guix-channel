#!/bin/sh
# Exercise dNetHack's reviewed save/restore contract in isolated state.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=$(command -v node)
find_bin=$(command -v find)
rm_bin=$(command -v rm)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [dnethack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    dnethack_out=$1
else
    dnethack_out=$($guix_bin build -L "$channel_dir" --no-grafts \
        --no-substitutes dnethack)
fi

test -x "$dnethack_out/bin/dnethack"
test -x "$dnethack_out/libexec/dnethack-real"
test -s "$dnethack_out/share/dnethack/nhdat"
test -s "$dnethack_out/share/dnethack/license"
test ! -e "$dnethack_out/share/doc/dnethack/MacroMagicMarker.py"

doc=$dnethack_out/share/doc/dnethack
for notice in README README.gray README.menucolor Guidebook.txt README.linux; do
    test -s "$doc/$notice"
done
grep -F 'NETHACK GENERAL PUBLIC LICENSE' \
    "$dnethack_out/share/dnethack/license" >/dev/null
grep -F 'dNetHack is free software' "$doc/README" >/dev/null

# The issue-specific executable, invocation, and marker are a required part
# of the proof, not an advisory record.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 679' "$contract" >/dev/null
grep -F '"packageName": "dnethack"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-679.png"' \
    "$contract" >/dev/null
grep -F '"executable": "dnethack"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "dnethack guix smoke passed"' \
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
    echo 'dnethack smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$dnethack_out")

smoke_root=$(mktemp -d -t dnethack-smoke.XXXXXX)
cleanup ()
{
    "$rm_bin" -rf "$smoke_root"
}
trap cleanup EXIT HUP INT TERM
mkdir "$smoke_root/home" "$smoke_root/config" "$smoke_root/data" \
    "$smoke_root/cache" "$smoke_root/state" "$smoke_root/runtime" \
    "$smoke_root/tmp"
chmod 700 "$smoke_root/runtime"
export HOME="$smoke_root/home"
export XDG_CONFIG_HOME="$smoke_root/config"
export XDG_DATA_HOME="$smoke_root/data"
export XDG_CACHE_HOME="$smoke_root/cache"
export XDG_STATE_HOME="$smoke_root/state"
export XDG_RUNTIME_DIR="$smoke_root/runtime"
export TMPDIR="$smoke_root/tmp"
export PATH="$dnethack_out/bin"
export TERM=xterm-256color
export LC_ALL=C.UTF-8
unset HACKDIR NETHACKDIR NETHACKOPTIONS MAIL MAILREADER SIMPLEMAIL || true

# bounded-validation owns the complete process group.  The package wrapper's
# --guix-smoke branch creates the PTYs for the two real curses sessions.
proof=$("$node_bin" "$bounded_validation" --timeout-ms 60000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$dnethack_out/bin/dnethack" --guix-smoke)
case "$proof" in
    *'dnethack guix smoke passed'*) ;;
    *)
        echo 'dnethack smoke did not produce its success marker' >&2
        exit 1
        ;;
esac

after=$($guix_bin hash -S nar "$dnethack_out")
test "$before" = "$after"
test -z "$("$find_bin" "$dnethack_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$dnethack_out"
printf '%s\n' 'dnethack guix smoke passed'
