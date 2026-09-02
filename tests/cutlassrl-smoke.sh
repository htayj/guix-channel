#!/bin/sh
# Exercise CutlassRL's real Python 2 curses game through its package-owned
# isolated save/load smoke mode.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [cutlassrl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    cutlassrl_out=$1
else
    cutlassrl_out=$($guix_bin build -L . --no-grafts --no-substitutes cutlassrl)
fi

find_program_output ()
{
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

test -x "$cutlassrl_out/bin/cutlassrl"
test -s "$cutlassrl_out/libexec/cutlassrl/main.py"
test -s "$cutlassrl_out/libexec/cutlassrl/Game.py"
test -s "$cutlassrl_out/libexec/cutlassrl/Modules/Unicurses.py"
test -s "$cutlassrl_out/libexec/cutlassrl/Modules/__init__.py"
test -s "$cutlassrl_out/libexec/cutlassrl/Levels/last.lvl"
test -s "$cutlassrl_out/libexec/cutlassrl/COPYING"
test -s "$cutlassrl_out/share/doc/cutlassrl/README"

# The Windows-only PDCurses DLL and the historical build helpers are not
# source runtime inputs and must not be present in the installed tree.
test ! -e "$cutlassrl_out/libexec/cutlassrl/pdcurses.dll"
test ! -e "$cutlassrl_out/libexec/cutlassrl/cpf.sh"
test ! -e "$cutlassrl_out/libexec/cutlassrl/rldev.pl"

grep -F 'GNU GENERAL PUBLIC LICENSE' \
    "$cutlassrl_out/libexec/cutlassrl/COPYING" >/dev/null
grep -F 'GNU General Public License' \
    "$cutlassrl_out/libexec/cutlassrl/Game.py" >/dev/null
grep -F 'Copyright (C) 2010 by Michael Kamensky.' \
    "$cutlassrl_out/libexec/cutlassrl/Modules/Unicurses.py" >/dev/null
grep -F 'GNU General Public License' \
    "$cutlassrl_out/libexec/cutlassrl/Modules/Unicurses.py" >/dev/null

# The reviewed issue contract is part of the executable proof.
contract=$channel_dir/.goocastle/runtime-evidence-contracts.json
test -s "$contract"
grep -F '"issueNumber": 672' "$contract" >/dev/null
grep -F '"packageName": "cutlassrl"' "$contract" >/dev/null
grep -F '"artifactPath": ".goocastle/evidence/issue-672.png"' \
    "$contract" >/dev/null
grep -F '"executable": "cutlassrl"' "$contract" >/dev/null
grep -F '"--smoke"' "$contract" >/dev/null
grep -F '"successMarker": "CUTLASSRL_RUNTIME_OK"' \
    "$contract" >/dev/null

# Check the normal launcher contract as well as the package-owned smoke mode.
grep -F 'XDG_DATA_HOME' "$cutlassrl_out/bin/cutlassrl" >/dev/null
grep -F 'exec "$python" "$program" "$@"' \
    "$cutlassrl_out/bin/cutlassrl" >/dev/null

util_linux_out=$(find_program_output bin/unshare util-linux)
test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
bounded_validation=${GOOCASTLE_BOUNDED_VALIDATION:-/opt/goocastle/bin/bounded-validation.mjs}
test -r "$bounded_validation"

# The actual proof runs in a network namespace with no interfaces.  Probe the
# host capability through the same bounded argv-only executor used below.
if ! node "$bounded_validation" --timeout-ms 5000 -- \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'cutlassrl smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# The NAR hash covers every installed byte, mode, and symlink.  It must not
# change after the real game has attempted its save, load, and log writes.
before=$($guix_bin hash -S nar "$cutlassrl_out")
test -z "$(find "$cutlassrl_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-cutlassrl-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-*) ;;
    *) echo 'refusing an unvalidated disposable workspace' >&2; exit 1 ;;
esac
test -d "$scratch"
mkdir "$scratch/home" "$scratch/config" "$scratch/data" \
      "$scratch/cache" "$scratch/state" "$scratch/runtime" \
      "$scratch/tmp" "$scratch/work"

export HOME="$scratch/home"
export XDG_CONFIG_HOME="$scratch/config"
export XDG_DATA_HOME="$scratch/data"
export XDG_CACHE_HOME="$scratch/cache"
export XDG_STATE_HOME="$scratch/state"
export XDG_RUNTIME_DIR="$scratch/runtime"
export TMPDIR="$scratch/tmp"
export TERM=xterm-256color
export LC_ALL=C

raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-$scratch/terminal.raw}
proof=$(cd "$scratch/work" && env -i \
    HOME="$HOME" \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" \
    XDG_DATA_HOME="$XDG_DATA_HOME" \
    XDG_CACHE_HOME="$XDG_CACHE_HOME" \
    XDG_STATE_HOME="$XDG_STATE_HOME" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    TMPDIR="$TMPDIR" \
    TERM="$TERM" \
    LC_ALL="$LC_ALL" \
    GOOCASTLE_RUNTIME_RAW_CAPTURE="$raw" \
    node "$bounded_validation" --timeout-ms 30000 -- \
    "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
    "$cutlassrl_out/bin/cutlassrl" --smoke)
test "$proof" = CUTLASSRL_RUNTIME_OK
test -s "$raw"

# The wrapper's second transcript proves that the loaded save was consumed;
# the output checks below prove the exact state files and their location.
state="$scratch/data/cutlassrl"
test -s "$state/mainlog.log"
test ! -e "$state/Goocastle.sav"
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/work" -type f \( -name '*.pyc' -o -name '*.pyo' \) \
    -print -quit)"

after=$($guix_bin hash -S nar "$cutlassrl_out")
test "$before" = "$after"
test -z "$(find "$cutlassrl_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$cutlassrl_out"
printf '%s\n' "$proof"
