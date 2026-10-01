#!/bin/sh
# Exercise the compiled original Rougelike in real event-driven curses PTYs.
# Main validation owns realization, --check, lint, and execution.
set -eu

fail() {
    printf 'rouge-smoke: %s\n' "$*" >&2
    exit 1
}

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [rouge-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    rouge_out=$1
else
    rouge_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes rouge)
fi
rouge_out=$(CDPATH= cd -- "$rouge_out" && pwd) || fail "cannot access package output: $rouge_out"

find_program() {
    program=$1
    shift
    for candidate in $($guix_bin build --no-grafts "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate/$program"
            return 0
        fi
    done
    fail "cannot resolve required dependency $program"
}

# Resolve dependencies before offline execution. Explicit overrides use already
# realized tools without requiring Guix or network access in the namespace.
python_bin=${PYTHON:-$(find_program bin/python3 python)}
unshare_bin=${UNSHARE:-$(find_program bin/unshare util-linux)}
timeout_bin=${TIMEOUT:-$(find_program bin/timeout coreutils-minimal)}
test -x "$python_bin" || fail "Python is not executable: $python_bin"
test -x "$unshare_bin" || fail "unshare is not executable: $unshare_bin"
test -x "$timeout_bin" || fail "timeout is not executable: $timeout_bin"

test -x "$rouge_out/bin/rouge" || fail "missing game executable"
test "$(find "$rouge_out/bin" -mindepth 1 -maxdepth 1 -printf '%f\n')" = rouge \
    || fail "unexpected executable in package bin directory"
for file in license.txt GNU-GPL readme.txt THIRD-PARTY-NOTICES; do
    test -s "$rouge_out/share/doc/rouge/$file" || fail "missing installed notice $file"
done
grep -q 'GNU GENERAL PUBLIC LICENSE' "$rouge_out/share/doc/rouge/GNU-GPL" \
    || fail "installed GNU-GPL is not the GPL text"
test -s "$rouge_out/share/rouge/controls.cfg" || fail "missing default controls"
test -n "$(find "$rouge_out/lib/common-lisp" -type f -name '*.fasl' -print)" \
    || fail "missing compiled ASDF game"

# The game and all compiled ASDF files remain read-only. Hash every installed
# regular file before and after, so controls/state cannot leak into the output.
# Symlinks report mode 0777, but are not mutable files. Check their targets via
# the actual installed regular files and directories, not link mode bits.
test -z "$(find "$rouge_out" -xdev \( -type f -o -type d \) -perm /222 -print)" \
    || fail "package contains writable files or directories"
before=$(find "$rouge_out" -xdev -type f -exec sha256sum {} \; | sort)
temporary=$(mktemp -d "${TMPDIR:-/tmp}/rouge-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

# Four sessions independently exercise explicit XDG and HOME fallback state.
# Each action awaits the original screen, never preloads commands. The capture
# is the actual first live gameplay transcript, ending before Q and endwin.
"$timeout_bin" --kill-after=5 160 \
    "$unshare_bin" --user --map-root-user --net --pid --fork --kill-child \
    "$python_bin" "$channel_dir/tests/rouge-pty-runner.py" \
    "$rouge_out/bin/rouge" "$temporary" || fail "real curses gameplay/state proof failed"

test "$before" = "$(find "$rouge_out" -xdev -type f -exec sha256sum {} \; | sort)" \
    || fail "installed output contents changed during gameplay"
printf '%s\n' 'rouge isolated event-driven curses PTY, wait/switch, XDG/fallback hiscore reload and MD5, user controls, readonly output, and license smoke passed'
