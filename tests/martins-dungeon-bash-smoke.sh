#!/bin/sh
# Exercise Martin's Dungeon Bash save/load behavior in an isolated PTY.
set -eu

guix_bin=${GUIX:-guix}
guix_bin=$(command -v "$guix_bin")
node_bin=${GOOCASTLE_NODE:-$(command -v node)}
env_bin=$(command -v env)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [martins-dungeon-bash-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L . --no-grafts --no-substitutes \
        martins-dungeon-bash)
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

coreutils_out=$(find_output bin/mktemp coreutils-minimal)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
util_linux_out=$(find_output bin/script util-linux)

test -x "$node_bin"
test -r "$bounded_validation"
test -x "$game_out/bin/dungeonbash"
test -x "$game_out/libexec/dungeonbash"

doc="$game_out/share/doc/martins-dungeon-bash"
test -s "$doc/notes.txt"
"$grep_out/bin/grep" -F 'Copyright 2009 Martin Read.' \
    "$doc/notes.txt" >/dev/null
"$grep_out/bin/grep" -F 'copyright 2005-2009 Martin Read' \
    "$doc/notes.txt" >/dev/null
"$grep_out/bin/grep" -F 'Redistribution and use in source and binary forms' \
    "$doc/notes.txt" >/dev/null
"$grep_out/bin/grep" -F 'THIS SOFTWARE IS PROVIDED BY THE AUTHOR' \
    "$doc/notes.txt" >/dev/null
test ! -e "$doc/spoilers"
test -z "$($findutils_out/bin/find "$game_out" -type f \
    -iname '*.html' -print -quit)"

# The reviewed runtime contract is part of this package-specific proof.
contract="$channel_dir/.goocastle/runtime-evidence-contracts.json"
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 705' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "martins-dungeon-bash"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F \
    '"packageModulePath": "tay/packages/martins-dungeon-bash.scm"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F \
    '"artifactPath": ".goocastle/evidence/issue-705.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"executable": "dungeonbash"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"--smoke"' "$contract" >/dev/null
"$grep_out/bin/grep" -F \
    '"successMarker": "MARTINS_DUNGEON_BASH_SMOKE_OK"' "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
if ! "$node_bin" "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        "$coreutils_out/bin/true" >/dev/null 2>&1; then
    echo 'martins-dungeon-bash smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers every installed file, mode, and symlink.  It must remain
# unchanged after the wrapper and both real game sessions run.
before=$($guix_bin hash -S nar "$game_out")
test -z "$($findutils_out/bin/find "$game_out" -xdev -type f \
    -perm /222 -print -quit)"
test ! -w "$game_out"

if test -n "${GOOCASTLE_DISPOSABLE_WORKSPACE-}"; then
    disposable_workspace=$GOOCASTLE_DISPOSABLE_WORKSPACE
else
    disposable_workspace=$($coreutils_out/bin/mktemp -d /tmp/goocastle-agent-XXXXXXXX)
fi
case "$disposable_workspace" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$disposable_workspace"
scratch=$($coreutils_out/bin/mktemp -d \
    "$disposable_workspace/martins-dungeon-bash-XXXXXXXX")
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C.UTF-8
export PATH=
export ALL_PROXY=http://127.0.0.1:9
export HTTP_PROXY=http://127.0.0.1:9
export HTTPS_PROXY=http://127.0.0.1:9
export NO_PROXY='*'

# The package's --smoke branch controls two PTY sessions.  The immutable
# bounded executor owns the complete process group, and the new network
# namespace has no interfaces or routes.
proof=$(cd "$scratch/work" && \
    "$env_bin" -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" TERM=xterm-256color LC_ALL=C.UTF-8 PATH= \
    ALL_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 \
    HTTPS_PROXY=http://127.0.0.1:9 NO_PROXY='*' \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$game_out/bin/dungeonbash" --smoke)
test "$proof" = MARTINS_DUNGEON_BASH_SMOKE_OK
test -s "$raw"
"$grep_out/bin/grep" -aF 'Welcome to Martin' "$raw" >/dev/null
"$grep_out/bin/grep" -aF 'Game loaded.' "$raw" >/dev/null
"$grep_out/bin/grep" -aF 'Press capital Y to confirm' "$raw" >/dev/null

smoke_state="$scratch/state/martins-dungeon-bash"
test -s "$smoke_state/smoke/first.raw"
test -s "$smoke_state/smoke/load.raw"
test ! -e "$smoke_state/dunbash.sav.gz"
test -z "$($findutils_out/bin/find "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"
test -z "$($findutils_out/bin/find "$game_out" -xdev -type f \
    -perm /222 -print -quit)"
test ! -w "$game_out"
printf '%s\n' "$proof"
