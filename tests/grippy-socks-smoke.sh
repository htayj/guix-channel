#!/bin/sh
# Exercise Grippy Socks through its installed command-line launcher.
set -eu

guix_bin=$(command -v "${GUIX:-guix}")
grep_bin=$(command -v grep)
find_bin=$(command -v find)
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [grippy-socks-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    grippy_socks_out=$1
else
    grippy_socks_out=$($guix_bin build -L . --no-grafts --no-substitutes grippy-socks)
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
node_bin=$(command -v node)

test -r "$bounded_validation"
test -x "$node_bin"
test -x "$grippy_socks_out/bin/grippy-socks"
test -x "$grippy_socks_out/libexec/grippy-socks-real"
test -s "$grippy_socks_out/share/grippy-socks/gripsox.ds"
test ! -e "$grippy_socks_out/share/grippy-socks/hunger.bmp"
test -z "$(find "$grippy_socks_out/share/grippy-socks" -type f \
    ! -name gripsox.ds -print -quit)"

doc="$grippy_socks_out/share/doc/grippy-socks"
for file in README.md license.htm changes.htm changes.doc daedalus.htm \
    daedalus.doc script.htm script.doc; do
    test -s "$doc/$file"
done
"$grep_bin" -F 'GNU GENERAL PUBLIC LICENSE' "$doc/license.htm" >/dev/null
"$grep_bin" -F 'Version 2, June 1991' "$doc/license.htm" >/dev/null
"$grep_bin" -F 'Walter D.' "$doc/changes.htm" >/dev/null
"$grep_bin" -F 'Pullen' "$doc/changes.htm" >/dev/null
"$grep_bin" -F 'By Walter D. Pullen' \
    "$grippy_socks_out/share/grippy-socks/gripsox.ds" >/dev/null

# The reviewed per-issue runtime contract is part of this package proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_bin" -F '"issueNumber": 689' "$contract" >/dev/null
"$grep_bin" -F '"packageName": "grippy-socks"' "$contract" >/dev/null
"$grep_bin" -F '"packageModulePath": "tay/packages/grippy-socks.scm"' \
    "$contract" >/dev/null
"$grep_bin" -F '"artifactPath": ".goocastle/evidence/issue-689.png"' \
    "$contract" >/dev/null
"$grep_bin" -F '"executable": "grippy-socks"' "$contract" >/dev/null
"$grep_bin" -F '"--smoke"' "$contract" >/dev/null
"$grep_bin" -F '"successMarker": "GRIPPY_SOCKS_SMOKE_OK"' \
    "$contract" >/dev/null

# The NAR hash and writable-file scan cover the complete installed tree.
before=$($guix_bin hash -S nar "$grippy_socks_out")
test -z "$(find "$grippy_socks_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$grippy_socks_out"

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$(mktemp -d /tmp/goocastle-agent-XXXXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$(mktemp -d "$disposable_workspace/grippy-socks-XXXXXXXX")
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
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$grippy_socks_out/bin/grippy-socks" --smoke)
test "$proof" = 'GRIPPY_SOCKS_SMOKE_OK'
test -s "$raw"
"$grep_bin" -aF 'Grippy Socks: A mental health simulation' "$raw" >/dev/null
"$grep_bin" -aF 'Select OK for more help, or Cancel to start playing.' "$raw" >/dev/null
"$grep_bin" -aF 'GRIPPY_SOCKS_SMOKE_OK' "$raw" >/dev/null

# The smoke wrapper runs in the data directory but must not create state or
# temporary files there.  The raw terminal stream is the sole expected file.
test -z "$($find_bin "$scratch/work" -mindepth 1 -print -quit)"
test -z "$($find_bin "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$grippy_socks_out")
test "$before" = "$after"
test -z "$($find_bin "$grippy_socks_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$grippy_socks_out"

# The evidence adapter may request a screenshot copy from the captured
# terminal stream, but it must remain under this issue's reviewed path.
if test -n "${GOOCASTLE_SCREENSHOT-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'grippy-socks smoke: screenshot must be a channel evidence PNG' >&2
           exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
