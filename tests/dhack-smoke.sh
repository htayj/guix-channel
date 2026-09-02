#!/bin/sh
# Exercise the installed DreamHack terminal game in a fresh XDG tree.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [dhack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    dhack_out=$1
else
    dhack_out=$($guix_bin build -L . --no-grafts --no-substitutes dhack)
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

coreutils_out=$(find_output bin/env coreutils-minimal)
util_linux_out=$(find_output bin/script util-linux)
strace_out=$(find_output bin/strace strace)
node_bin=${GOOCASTLE_NODE:-/usr/bin/node}
test -x "$node_bin" || node_bin=$(command -v node)
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}

test -x "$dhack_out/bin/dhack"
test -x "$dhack_out/libexec/dhack-real"
test ! -e "$dhack_out/bin/dreamhack"
test ! -e "$dhack_out/libexec/main"

doc=$dhack_out/share/doc/dhack
test -s "$doc/COPYING"
test "$(sha256sum "$doc/COPYING" | cut -d ' ' -f 1)" = \
    8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903
case "$(cat "$doc/COPYING")" in
    *"GNU GENERAL PUBLIC LICENSE"*"Version 3"*) ;;
    *) echo 'dhack smoke: installed GPLv3 notice is incomplete' >&2; exit 1 ;;
esac

# The reviewed per-issue runtime contract is part of this package proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
contract_text=$(cat "$contract")
case "$contract_text" in *'"issueNumber": 673'*) ;; *) exit 1 ;; esac
case "$contract_text" in *'"packageName": "dhack"'*) ;; *) exit 1 ;; esac
case "$contract_text" in *'"artifactPath": ".goocastle/evidence/issue-673.png"'*) ;; *) exit 1 ;; esac
case "$contract_text" in *'"executable": "dhack"'*) ;; *) exit 1 ;; esac
case "$contract_text" in *'"--smoke"'*) ;; *) exit 1 ;; esac
case "$contract_text" in *'"successMarker": "DHACK_RUNTIME_OK"'*) ;; *) exit 1 ;; esac

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
test -x "$strace_out/bin/strace"
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'dhack smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash and a writable-file scan cover all installed bytes and modes.
# They must remain unchanged after the real game runs.
before=$($guix_bin hash -S nar "$dhack_out")
test -z "$(find "$dhack_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d "${TMPDIR:-/tmp}/dhack-smoke-proof.XXXXXXXX")
case "$scratch" in
    "${TMPDIR:-/tmp}/dhack-smoke-proof."*) ;;
    *) echo 'refusing an unvalidated dhack smoke workspace' >&2; exit 1 ;;
esac
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/tmp" "$scratch/work" \
      "$scratch/caller"
raw=$scratch/work/terminal.raw
trace=$scratch/work/file-open.trace

# This is the required isolated invocation: only fresh HOME/XDG/TMPDIR state,
# a fixed terminal/locale, the package on PATH, and the package's raw-stream
# capture hook are supplied.  The bounded executor owns the complete PTY
# process group; unshare supplies a network namespace with no interfaces.
proof=$(
    "$node_bin" "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$strace_out/bin/strace" -f -qq -e trace=%file -o "$trace" \
    "$coreutils_out/bin/env" -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    TMPDIR="$scratch/tmp" \
    TERM=xterm-256color LC_ALL=C \
    PATH="$dhack_out/bin" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    dhack --smoke
)
test "$proof" = DHACK_RUNTIME_OK
test -s "$raw"
test -s "$trace"

# Read-only dynamic-loader and terminfo opens under /gnu/store are expected;
# any file-open or file-removal operation there must remain absent.
store_write_trace=
while IFS= read -r trace_line; do
    case "$trace_line" in
        *"/gnu/store/"*O_WRONLY*|*"/gnu/store/"*O_RDWR*|\
        *"/gnu/store/"*O_CREAT*|*"/gnu/store/"*O_TRUNC*|\
        *"/gnu/store/"*O_APPEND*|*'unlink("/gnu/store/'*|\
        *'rename('*"/gnu/store/"*|*'mkdir("/gnu/store/'*)
            store_write_trace=1
            break
            ;;
    esac
done <"$trace"
test -z "$store_write_trace"

# The launcher itself checks these; repeat the transcript checks outside the
# package so this proof independently observes the real PTY stream.
transcript=$(cat "$raw")
for marker in DreamHack Goocastle 'HP:' '@' Inventory; do
    case "$transcript" in
        *"$marker"*) ;;
        *) echo "dhack smoke: PTY transcript missing $marker" >&2; exit 1 ;;
    esac
done

# Every fresh HOME/XDG tree must remain empty: DreamHack has no state API, and
# the wrapper's transcript is confined to the private TMPDIR work tree.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" -mindepth 1 -print -quit)"
test -z "$(find "$dhack_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$dhack_out"

after=$($guix_bin hash -S nar "$dhack_out")
test "$before" = "$after"

# The PTY stream can be turned into the reviewed runtime screenshot by the
# evidence adapter.  It must remain a PNG path under this channel's evidence.
if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'dhack smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    cp "$raw" "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
