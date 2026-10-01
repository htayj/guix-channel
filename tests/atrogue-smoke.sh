#!/bin/sh
# Main owns realization, reproducibility, lint, runtime, and native capture.
# No Goocastle script/executor/renderer participates in this proof.
set -eu

fail() {
    printf 'atrogue-smoke: %s\n' "$*" >&2
    exit 1
}

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [atrogue-output]" >&2
    exit 64
fi
if test "$#" -eq 1; then
    atrogue_out=$1
else
    atrogue_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts atrogue)
fi
atrogue_out=$(CDPATH= cd -- "$atrogue_out" && pwd) || fail "cannot access package output"

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

# All tools must be realized before creating the offline network namespace.
python_bin=${PYTHON:-$(find_program bin/python3 python)}
unshare_bin=${UNSHARE:-$(find_program bin/unshare util-linux)}
timeout_bin=${TIMEOUT:-$(find_program bin/timeout coreutils-minimal)}
test -x "$python_bin" || fail "missing Python"
test -x "$unshare_bin" || fail "missing unshare"
test -x "$timeout_bin" || fail "missing timeout"
test -x "$atrogue_out/bin/atrogue" || fail "missing launcher"
test -x "$atrogue_out/libexec/atrogue/atrogue" || fail "missing source-built game"
for file in COPYING README INSTALL docu/key.html docu/intro_screen.html docu/arg.html; do
    test -s "$atrogue_out/share/doc/atrogue/$file" || fail "missing notice/documentation $file"
done
test -z "$(find "$atrogue_out" -xdev \( -type f -o -type d \) -perm /222 -print)" \
    || fail "installed output contains writable files/directories"
before=$(find "$atrogue_out" -xdev -type f -exec sha256sum {} \; | sort)
temporary=$(mktemp -d "${TMPDIR:-/tmp}/atrogue-smoke.XXXXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

"$timeout_bin" --kill-after=5 160 \
    "$unshare_bin" --user --map-root-user --net --pid --fork --kill-child \
    "$python_bin" "$channel_dir/tests/atrogue-pty-runner.py" \
    "$atrogue_out/bin/atrogue" "$temporary" \
    || fail "isolated real gameplay/native persistence proof failed"
test "$before" = "$(find "$atrogue_out" -xdev -type f -exec sha256sum {} \; | sort)" \
    || fail "installed output changed during gameplay"
printf '%s\n' 'atrogue real movement/rest, persistent native screenshots, opt-in log, XDG/HOME fallback, long paths, offline namespace, read-only output proof passed'
