#!/bin/sh
# Exercise the installed NitroHack curses client in isolated state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [nitrohack-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    nitrohack_out=$1
else
    nitrohack_out=$($guix_bin build -L . --no-grafts --no-substitutes nitrohack)
fi

find_output()
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
convert_bin=$(command -v convert || true)
python_bin=$(command -v python3 || true)

test -x "$nitrohack_out/bin/nitrohack"
test -x "$nitrohack_out/libexec/nitrohack-real"
test ! -e "$nitrohack_out/share/nitrohack/nitrohack"
test -s "$nitrohack_out/share/nitrohack/nhdat"
test -s "$nitrohack_out/share/nitrohack/license"

doc=$nitrohack_out/share/doc/nitrohack
for notice in README Guidebook.txt copyright; do
    test -s "$doc/$notice"
done
grep -F 'NITROHACK GENERAL PUBLIC LICENSE' \
    "$nitrohack_out/share/nitrohack/license" >/dev/null
grep -F 'NitroHack' "$doc/README" >/dev/null
grep -F 'Daniel Thaler' "$doc/copyright" >/dev/null
grep -F 'NetHack Devteam' "$doc/copyright" >/dev/null

# The reviewed per-issue executable contract is part of this package proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 709' "$contract" >/dev/null
grep -F '"packageName": "nitrohack"' "$contract" >/dev/null
grep -F '"packageModulePath": "tay/packages/nitrohack.scm"' \
    "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-709.png"' \
    "$contract" >/dev/null
grep -F '"executable": "nitrohack"' "$contract" >/dev/null
grep -F '"--guix-smoke"' "$contract" >/dev/null
grep -F '"successMarker": "nitrohack guix smoke passed"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
test -x "$strace_out/bin/strace"
test -r "$bounded_validation"
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'nitrohack smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# The NAR digest includes every installed byte, mode, and symlink.  It must
# remain unchanged after the actual curses sessions run.
before=$($guix_bin hash -S nar "$nitrohack_out")
test -z "$(find "$nitrohack_out" -xdev -type f -perm /222 \
    -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-nitrohack-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-nitrohack-*) ;;
    *) echo 'refusing an unvalidated nitrohack smoke workspace' >&2; exit 1 ;;
esac
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"
chmod 700 "$scratch/runtime"
raw=$scratch/work/terminal.raw
trace=$scratch/work/file-open.trace

# The bounded executor owns the complete PTY process group.  The unprivileged
# network namespace has no interfaces, and env -i supplies only fresh HOME,
# XDG, terminal, locale, PATH, and the reviewed raw capture hook.
proof=$(
    "$node_bin" "$bounded_validation" --timeout-ms 60000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$strace_out/bin/strace" -f -qq -e trace=%file -o "$trace" \
    "$coreutils_out/bin/env" -i \
    HOME="$scratch/home" \
    XDG_CONFIG_HOME="$scratch/config" \
    XDG_DATA_HOME="$scratch/data" \
    XDG_CACHE_HOME="$scratch/cache" \
    XDG_STATE_HOME="$scratch/state" \
    XDG_RUNTIME_DIR="$scratch/runtime" \
    TMPDIR="$scratch/tmp" \
    TERM=xterm-256color LC_ALL=C \
    PATH="$nitrohack_out/bin" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    nitrohack --guix-smoke
)
test "$proof" = 'nitrohack guix smoke passed'
test -s "$raw"
test -s "$trace"

# The wrapper's inner smoke environment is rooted below this fresh temporary
# tree.  Confirm that a save was made under its XDG config directory, not in
# the caller's HOME, package output, or store.
saved=$(find "$scratch/tmp" -path '*/config/NitroHack/save/*.nhgame' \
    -type f -print -quit)
test -n "$saved"
case "$saved" in
    "$scratch/tmp/"*/config/NitroHack/save/*.nhgame) ;;
    *) echo 'nitrohack smoke: save escaped fresh XDG config' >&2; exit 1 ;;
esac
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" -mindepth 1 \
    -print -quit)"

# Read-only dynamic-loader opens under /gnu/store are expected; no write,
# truncate, create, unlink, rename, or mkdir operation may target the store.
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

# Independently observe the meaningful PTY behavior: title, new-game welcome,
# deterministic gameplay status, and restored-game welcome.
for marker in NitroHack 'welcome to NitroHack' 'HP:' 'welcome back to NitroHack'; do
    grep -aF "$marker" "$raw" >/dev/null || {
        echo "nitrohack smoke: PTY transcript missing $marker" >&2
        exit 1
    }
done

test -z "$(find "$nitrohack_out" -xdev -type f -perm /222 \
    -print -quit)"
test ! -w "$nitrohack_out"

after=$($guix_bin hash -S nar "$nitrohack_out")
test "$before" = "$after"

if test -n "${GOOCASTLE_SCREENSHOT:-}"; then
    case "$GOOCASTLE_SCREENSHOT" in
        "$channel_dir"/.goocastle/evidence/*.png) ;;
        *) echo 'nitrohack smoke: screenshot must be a channel evidence PNG' >&2; exit 1 ;;
    esac
    test -x "$convert_bin"
    test -x "$python_bin"
    mkdir -p "$(dirname -- "$GOOCASTLE_SCREENSHOT")"
    rendered=$scratch/work/terminal.txt
    "$python_bin" "$channel_dir/.goocastle/render-terminal-screenshot.py" \
        "$raw" "$rendered"
    "$convert_bin" -background '#1f1f1f' -fill '#eeeeee' \
        -font DejaVu-Sans-Mono -pointsize 16 \
        -bordercolor '#1f1f1f' -border 20 \
        label:@"$rendered" "PNG24:$GOOCASTLE_SCREENSHOT"
    test -s "$GOOCASTLE_SCREENSHOT"
fi

printf '%s\n' "$proof"
