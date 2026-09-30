#!/bin/sh
# Exercise the installed Forth modes and their packaged Gforth runtime offline.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-forth-mode-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        -e '(@ (tay packages forth-mode) emacs-forth-mode)')
fi

find_program_output() {
    program=$1
    shift
    for candidate in $($guix_bin build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
gforth_out=$(find_program_output bin/gforth gforth)
source_out=$($guix_bin build -L "$channel_dir/guix" larsbrinkhoff-forth-mode-source)
emacs_bin=$emacs_out/bin/emacs
gforth_bin=$gforth_out/bin/gforth
source_fixtures=$source_out/share/larsbrinkhoff/projects/forth-mode

test -x "$emacs_bin"
test -x "$gforth_bin"
test -d "$source_fixtures/test"
test -f "$source_fixtures/LICENSE"

license=$(find "$package_out/share/doc" -type f -name LICENSE -print | sed -n '1p')
test -n "$license"
test -f "$license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$license"
grep -q 'Version 3, 29 June 2007' "$license"

lisp_file=$(find "$package_out/share/emacs/site-lisp" -type f \
    \( -name forth-mode.el -o -name forth-mode.elc \) -print | sed -n '1p')
test -n "$lisp_file"
lisp_dir=$(dirname "$lisp_file")

for runtime_file in forth-mode.el forth-block-mode.el forth-interaction-mode.el \
                    forth-parse.el forth-smie.el forth-spec.el forth-syntax.el \
                    backend/gforth.el backend/lbforth.el backend/pforth.el \
                    backend/spforth.el backend/swiftforth.el backend/swiftforth.fth \
                    backend/vfxforth.el; do
    test -f "$lisp_dir/$runtime_file" -o -f "$lisp_dir/${runtime_file}c"
done
test ! -e "$lisp_dir/build.el"
test ! -e "$lisp_dir/autoloads.el"

temporary=$(mktemp -d -t emacs-forth-mode-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime"
chmod 700 "$temporary/runtime"

# Block mode normalizes buffers while visiting block files.  Stage only the
# upstream fixtures in writable temporary space; the source and package
# outputs remain immutable inputs to this proof.
mkdir "$temporary/fixtures"
cp -R "$source_fixtures/test" "$temporary/fixtures/test"
chmod -R u+rwX "$temporary/fixtures"
fixtures=$temporary/fixtures

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}

before_fingerprint=$(output_fingerprint)

# A private network namespace provides a fail-closed offline test environment.
unshare_out=$(find_program_output bin/unshare util-linux)
unshare_bin=$unshare_out/bin/unshare
test -x "$unshare_bin"

run_isolated() {
    "$unshare_bin" --user --map-root-user --net --fork \
        env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
        XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
        XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
        TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
        FORTH_SMOKE_FIXTURES="$fixtures" FORTH_SMOKE_GFORTH="$gforth_bin" \
        "$@"
}

run_isolated "$emacs_bin" --batch -Q -L "$lisp_dir" \
    -l "$channel_dir/tests/emacs-forth-mode-smoke.el" \
    --eval '(forth-mode-smoke-run)'

# Capture the real terminal Emacs scene, not a substitute display command.
# The byte boundary written after redisplay keeps the exported PTY prefix
# inside the final alternate screen, before Emacs restores the terminal.
raw_capture=${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}
if test -n "$raw_capture"; then
    script_out=$(find_program_output bin/script util-linux)
    stty_out=$(find_program_output bin/stty coreutils)
    head_out=$(find_program_output bin/head coreutils)
    script_bin=$script_out/bin/script
    stty_bin=$stty_out/bin/stty
    head_bin=$head_out/bin/head
    test -x "$script_bin"
    test -x "$stty_bin"
    test -x "$head_bin"
    script_log=$temporary/tty.script
    # Isolated init files are read before terminal setup, unlike -Q, so
    # xterm query replies cannot be injected by a replaying terminal.
    mkdir -p "$temporary/home/.emacs.d"
    printf '(setq package-enable-at-startup nil)\n' \
        >"$temporary/home/.emacs.d/early-init.el"
    printf '(setq inhibit-default-init t xterm-extra-capabilities nil)\n' \
        >"$temporary/home/.emacs.d/init.el"
    run_isolated TERM=xterm-256color FORTH_SMOKE_TTY_LOG="$script_log" \
        FORTH_SMOKE_EVIDENCE="$temporary" \
        "$script_bin" -q -f -e \
        -c "$stty_bin rows 24 cols 80; exec $emacs_bin -nw \
            --no-site-file --no-site-lisp --no-splash --no-x-resources \
            -L $lisp_dir -l $channel_dir/tests/emacs-forth-mode-smoke.el \
            --eval '(forth-mode-smoke-tty-scene)'" \
        "$script_log" </dev/null >/dev/null || {
        cat "$temporary/tty-scene.err" >&2 2>/dev/null || true
        exit 1
    }
    test -f "$temporary/tty-scene.ok"
    test ! -e "$temporary/tty-scene.err"
    frame_bytes=$(cat "$temporary/tty-frame.bytes")
    case $frame_bytes in
        ''|*[!0-9]*) echo 'forth-mode smoke: invalid frame byte count' >&2; exit 1 ;;
    esac
    # Drop only script(1)'s leading banner from the recorded frame prefix.
    "$head_bin" -c "$frame_bytes" "$script_log" |
        sed -e '1{/^Script started on /d;}' >"$raw_capture"
    esc=$(printf '\033')
    last_enter=$(grep -abo "$esc\[?1049h" "$raw_capture" | sed -n '$s/:.*//p')
    test -n "$last_enter"
    last_leave=$(grep -abo "$esc\[?1049l" "$raw_capture" | sed -n '$s/:.*//p')
    if test -n "$last_leave" && test "$last_leave" -gt "$last_enter"; then
        echo 'forth-mode smoke: exported frame includes terminal restore' >&2
        exit 1
    fi
    for proof in 'OMP Forth editing proof' 'square' 'Forth'; do
        last_proof=$(grep -abo "$proof" "$raw_capture" | sed -n '$s/:.*//p')
        test -n "$last_proof"
        test "$last_proof" -gt "$last_enter"
    done
    if grep -aq "$esc\[>0c\|$esc]11;?" "$raw_capture"; then
        echo 'forth-mode smoke: exported frame contains terminal queries' >&2
        exit 1
    fi
fi

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
