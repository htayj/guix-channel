#!/bin/sh
# Exercise the installed hosted Modus evaluator in isolated, network-less state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [modus-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    modus_out=$1
else
    modus_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts \
        --no-substitutes modus)
fi

find_output()
{
    program=$1
    package=$2
    for output in $($guix_bin build "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

coreutils_out=$(find_output bin/timeout coreutils)
util_linux_out=$(find_output bin/unshare util-linux)

modus=$modus_out/bin/modus
share=$modus_out/share/modus
doc=$modus_out/share/doc/modus
test -x "$modus"
test -s "$share/modus-quicklisp/setup.lisp"
test -s "$share/systems/sha1.tar"
test -s "$doc/LICENSE"
test -s "$doc/README.md"
test -s "$doc/QUICKLOAD.md"
test -s "$doc/third-party-notices/sha1-LICENSE.txt"
grep -F 'Copyright (c) 2025 The Modus Development Team' "$doc/LICENSE" >/dev/null
grep -F 'Apache License' "$doc/third-party-notices/sha1-LICENSE.txt" >/dev/null
if ! "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        true >/dev/null 2>&1; then
    echo 'modus smoke requires an unprivileged network namespace' >&2
    exit 77
fi

# A NAR hash covers every installed byte, mode, and symlink.
before=$($guix_bin hash -S nar "$modus_out")
test -z "$(find "$modus_out" -xdev -type f -perm /222 -print -quit)"

scratch=$(mktemp -d /tmp/goocastle-agent-modus-XXXXXXXX)
case "$scratch" in
    /tmp/goocastle-agent-modus-*) ;;
    *) echo 'refusing an unvalidated modus smoke workspace' >&2; exit 1 ;;
esac
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/home" "$scratch/config" "$scratch/data" "$scratch/cache" \
      "$scratch/state" "$scratch/runtime" "$scratch/tmp" "$scratch/caller" \
      "$scratch/work"
chmod 700 "$scratch/runtime"
work=$scratch/work

# Run the installed executable with only fresh HOME/XDG state, no network
# interfaces, and a bounded lifetime.  Stdout goes to the caller; stdin is
# optional.
run_modus()
{
    (cd "$scratch/caller" && "$coreutils_out/bin/timeout" 60 \
        "$util_linux_out/bin/unshare" --user --map-root-user --net --fork \
        "$coreutils_out/bin/env" -i \
        HOME="$scratch/home" \
        XDG_CONFIG_HOME="$scratch/config" \
        XDG_DATA_HOME="$scratch/data" \
        XDG_CACHE_HOME="$scratch/cache" \
        XDG_STATE_HOME="$scratch/state" \
        XDG_RUNTIME_DIR="$scratch/runtime" \
        TMPDIR="$scratch/tmp" \
        LC_ALL=C \
        "$modus" "$@")
}

# Compare a captured stdout file byte-for-byte with the expected bytes.
expect_stdout()
{
    printf "$2" >"$work/expected"
    cmp -s "$1" "$work/expected" || {
        echo "modus smoke: unexpected stdout in $1" >&2
        exit 1
    }
}

# 1. SBCL-faithful --eval prints nothing unless the form itself writes.
run_modus --noinform --no-userinit --no-sysinit --non-interactive \
    --eval '(+ 1 2)' >"$work/silent.out"
test ! -s "$work/silent.out"

# 2. The corrected runtime invocation: the evaluator computes (+ 1 2) and
# prints the result through its own FORMAT.
run_modus --noinform --no-userinit --no-sysinit --non-interactive \
    --eval '(format t "= ~D~%" (+ 1 2))' >"$work/sum.out"
expect_stdout "$work/sum.out" '= 3\n'

# 3. The research smoke: exact single-line stdout.
run_modus --noinform --no-userinit --no-sysinit --non-interactive \
    --eval '(write-line "modus-cli-ok")' >"$work/ok.out"
expect_stdout "$work/ok.out" 'modus-cli-ok\n'

# 4. Evaluation is real: a false arithmetic assertion must fail the process.
run_modus --noinform --no-userinit --no-sysinit --non-interactive \
    --eval '(unless (= (+ 1 2) 3) (error "bad sum"))' >/dev/null
if run_modus --noinform --no-userinit --no-sysinit --non-interactive \
        --eval '(unless (= (+ 1 2) 4) (error "bad sum"))' >/dev/null; then
    echo 'modus smoke: a failing --eval assertion exited successfully' >&2
    exit 1
fi

# 5. The interactive REPL reads stdin, prints each value, and exits on EOF.
printf '(+ 1 2)\n' | run_modus --noinform --no-userinit --no-sysinit \
    >"$work/repl.out"
expect_stdout "$work/repl.out" '> 3\n> \n'

# 6. The documented offline Quicklisp step loads the installed setup and
# bundled sha1 system from the store while running from an unrelated cwd.
run_modus --noinform --no-userinit --no-sysinit --non-interactive \
    --eval "(load \"$share/modus-quicklisp/setup.lisp\")" \
    --eval '(ql:quickload :sha1)' \
    --eval '(write-line (sha1:sha1-hex "abc"))' >"$work/ql.out"
test "$(sed -n '$p' "$work/ql.out")" = \
    'A9993E364706816ABA3E25717850C26C9CD0D89D'

# The evidence transcript is the unmodified stdout bytes of the corrected
# invocation, the research smoke, and the REPL session, in that order.
transcript=$work/terminal.raw
cat "$work/sum.out" "$work/ok.out" "$work/repl.out" >"$transcript"

# Modus writes no state for these non-interactive runs: every isolated tree
# and the caller's working directory remain empty.
test -z "$(find "$scratch/home" "$scratch/config" "$scratch/data" \
    "$scratch/cache" "$scratch/state" "$scratch/runtime" "$scratch/tmp" \
    "$scratch/caller" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$modus_out")
test "$before" = "$after"
test -z "$(find "$modus_out" -xdev -type f -perm /222 -print -quit)"
test ! -w "$modus_out"

if test -n "${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"; then
    cp "$transcript" "$GOOCASTLE_RUNTIME_RAW_CAPTURE"
fi

printf '%s\n' 'modus smoke passed'
