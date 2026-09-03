#!/bin/sh
# Exercise Dragonslayer's installed command-line game in isolated state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [dragonslayer-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    dragonslayer_out=$1
else
    dragonslayer_out=$($guix_bin build -L . --no-grafts --no-substitutes dragonslayer)
fi

find_output () {
    program=$1
    package=$2
    for output in $($guix_bin build -L . --no-grafts --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

util_linux_out=$(find_output bin/unshare util-linux)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"
test -x "$dragonslayer_out/bin/dragonslayer"
test -x "$dragonslayer_out/libexec/dragonslayer-real"
test -s "$dragonslayer_out/share/dragonslayer/dragon.ds"
test ! -e "$dragonslayer_out/share/dragonslayer/hunger.bmp"

doc="$dragonslayer_out/share/doc/dragonslayer"
for file in README.md license.htm changes.htm changes.doc daedalus.htm \
    daedalus.doc script.htm script.doc; do
    test -s "$doc/$file"
done
grep -F 'GNU GENERAL PUBLIC LICENSE' "$doc/license.htm" >/dev/null
grep -F 'Version 2, June 1991' "$doc/license.htm" >/dev/null
grep -F 'Walter D. Pullen' "$doc/changes.htm" >/dev/null
grep -F 'By Walter D. Pullen' \
    "$dragonslayer_out/share/dragonslayer/dragon.ds" >/dev/null
grep -F 'Based on the leaves.bmp background from Windows 3.1' \
    "$dragonslayer_out/share/dragonslayer/dragon.ds" >/dev/null

grep -F '"issueNumber": 681' .goocastle/runtime-evidence-contracts.json >/dev/null
grep -F '"packageName": "dragonslayer"' \
    .goocastle/runtime-evidence-contracts.json >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-681.png"' \
    .goocastle/runtime-evidence-contracts.json >/dev/null
grep -F '"successMarker": "DRAGONSLAYER_SMOKE_OK"' \
    .goocastle/runtime-evidence-contracts.json >/dev/null

test -z "$(find "$dragonslayer_out" -xdev -type f -perm /222 -print -quit)"
before=$($guix_bin hash -S nar "$dragonslayer_out")

scratch=$(mktemp -d /tmp/goocastle-agent-dragonslayer-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export PATH=
export TERM=xterm-256color
export LC_ALL=C
export ALL_PROXY=http://127.0.0.1:9
export HTTP_PROXY=http://127.0.0.1:9
export HTTPS_PROXY=http://127.0.0.1:9
export NO_PROXY='*'

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
proof=$(cd "$scratch/work" && \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$dragonslayer_out/bin/dragonslayer" --smoke)
test "$proof" = 'DRAGONSLAYER_SMOKE_OK'
test -s "$raw"
grep -aF 'Welcome to Dragonslayer!' "$raw" >/dev/null
grep -aF 'Level:' "$raw" >/dev/null
grep -aF 'DRAGONSLAYER_SMOKE_OK' "$raw" >/dev/null
test -z "$(find "$scratch/work" -mindepth 1 -print -quit)"
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$dragonslayer_out")
test "$before" = "$after"
test -z "$(find "$dragonslayer_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$dragonslayer_out"
printf '%s\n' "$proof"
