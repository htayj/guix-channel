#!/bin/sh
# Exercise the original FreeLarn in real PTYs with isolated HOME/XDG state.
# Main validation owns source realization, --check and lint; this smoke never
# runs Guix or resolves dependencies inside the network namespace.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [freelarn-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    freelarn_out=$1
else
    freelarn_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes freelarn)
fi
freelarn_out=$(CDPATH= cd -- "$freelarn_out" && pwd)

find_program() {
    program=$1
    shift
    for candidate in $($guix_bin build --no-grafts "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate/$program"
            return 0
        fi
    done
    return 1
}

# Explicit executable overrides allow already-realized dependencies to be used
# during the offline proof without invoking a daemon.  Otherwise resolve all
# three before entering the fresh network namespace.
python_bin=${PYTHON:-$(find_program bin/python3 python)}
unshare_bin=${UNSHARE:-$(find_program bin/unshare util-linux)}
timeout_bin=${TIMEOUT:-$(find_program bin/timeout coreutils-minimal)}
test -x "$python_bin"
test -x "$unshare_bin"
test -x "$timeout_bin"

test -x "$freelarn_out/bin/freelarn"
test -x "$freelarn_out/libexec/freelarn"
test ! -e "$freelarn_out/bin/stub"
for file in LICENSE docs/LICENSE README.md docs/HISTORY docs/CHANGELOG; do
    test -s "$freelarn_out/share/doc/freelarn/$file"
done
grep -q 'Apache License' "$freelarn_out/share/doc/freelarn/LICENSE"
grep -q 'Licensed under the Apache License, Version 2.0' \
    "$freelarn_out/share/doc/freelarn/docs/LICENSE"
grep -q 'C++11 compiler' "$freelarn_out/share/doc/freelarn/README.md"

temporary=$(mktemp -d "${TMPDIR:-/tmp}/freelarn-smoke.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
before=$(find "$freelarn_out" -xdev -type f -exec sha256sum {} \; | sort)

# The runner waits on welcome/name/status/inventory/restore/quit prompts, never
# pipes preloaded input to the child.  Both explicit XDG state and HOME fallback
# receive independent new-game/save/restore sessions.  The external timeout and
# PID namespace bound all descendants even if an upstream UI call blocks.
"$timeout_bin" --kill-after=5 100 \
    "$unshare_bin" --user --map-root-user --net --pid --fork --kill-child \
    "$python_bin" "$channel_dir/tests/freelarn-pty-runner.py" \
    "$freelarn_out/bin/freelarn" "$temporary"

test "$before" = "$(find "$freelarn_out" -xdev -type f -exec sha256sum {} \; | sort)"
printf '%s\n' 'freelarn isolated event-driven PTY, XDG/fallback, save/restore, and license smoke passed'
