#!/bin/sh
# Exercise the installed vim-region commands and their expand-region dependency offline.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-vim-region-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        -e '(@ (tay packages vim-region) emacs-vim-region)')
fi

find_program_output() {
    program=$1
    shift
    for candidate in $("$guix_bin" build "$@"); do
        if test -x "$candidate/$program"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
util_out=$(find_program_output bin/script util-linux)
coreutils_out=$(find_program_output bin/timeout coreutils)
expand_out=$("$guix_bin" build --no-grafts \
    -e '(@ (gnu packages emacs-xyz) emacs-expand-region)')
source_out=$("$guix_bin" build -L "$channel_dir/guix" ongaeshi-emacs-vim-region-source)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$util_out/bin/unshare
script_bin=$util_out/bin/script
stty_bin=$coreutils_out/bin/stty
timeout_bin=$coreutils_out/bin/timeout
env_bin=$coreutils_out/bin/env
head_bin=$coreutils_out/bin/head
source_file=$source_out/share/ongaeshi/projects/emacs-vim-region/vim-region.el

for program in "$emacs_bin" "$unshare_bin" "$script_bin" "$stty_bin" \
               "$timeout_bin" "$env_bin" "$head_bin"; do
    test -x "$program"
done
test -f "$source_file"

# Reject missing or ambiguous installed libraries rather than accidentally
# loading an unrelated library from a profile or a user configuration.
find_library() {
    output=$1
    name=$2
    found=$(find "$output/share/emacs/site-lisp" -type f -name "$name" -print)
    case $found in
        *'
'*)
            printf 'vim-region smoke: ambiguous %s in %s\n' "$name" "$output" >&2
            return 1 ;;
    esac
    test -n "$found"
    printf '%s\n' "$found"
}

lisp_file=$(find_library "$package_out" vim-region.el)
lisp_dir=$(dirname -- "$lisp_file")
expand_file=$(find_library "$expand_out" expand-region.el)
expand_dir=$(dirname -- "$expand_file")
test -f "$lisp_dir/vim-region.elc"
test -f "$expand_dir/expand-region.elc"

temporary=$(mktemp -d -t emacs-vim-region-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/batch" "$temporary/tty"
chmod 700 "$temporary/runtime"

# This upstream has no standalone LICENSE: the complete GPL3+ grant is in
# the runtime header, retained byte-for-byte before the code-only require.
sed '/^;;; \(Commentary\|Code\):/,$d' "$source_file" >"$temporary/source-header"
sed '/^;;; \(Commentary\|Code\):/,$d' "$lisp_file" >"$temporary/installed-header"
test -s "$temporary/source-header"
cmp "$temporary/source-header" "$temporary/installed-header"
grep -Eq 'Copyright.*2013.*ongaeshi' "$temporary/installed-header"
grep -Fq 'free software; you can redistribute it and/or modify' "$temporary/installed-header"
grep -Fq 'under the terms of the GNU General Public License as published by' "$temporary/installed-header"
grep -Fq 'the Free Software Foundation, either version 3 of the License, or' "$temporary/installed-header"
grep -Fq '(at your option) any later version.' "$temporary/installed-header"

output_fingerprint() {
    find "$package_out" "$expand_out" -xdev -type f -exec sha256sum {} \; |
        LC_ALL=C sort | sha256sum
}

assert_immutable() {
    test -z "$(find "$package_out" "$expand_out" -xdev -type f -perm /222 -print -quit)" || {
        echo 'vim-region smoke: writable package or dependency file' >&2
        return 1
    }
}

assert_immutable
before_fingerprint=$(output_fingerprint)
printf 'alpha gammabeta \nkeep this line\n' >"$temporary/expected-buffer.txt"
printf '%s\n' 'mode=on' 'local-mode=on' 'point=6' 'mark=1' \
    'region=alpha' 'active=yes' 'modified=yes' >"$temporary/expected-state.txt"

assert_evidence() {
    cmp "$temporary/expected-buffer.txt" "$1/final-buffer.txt"
    cmp "$temporary/expected-state.txt" "$1/final-state.txt"
}

# A private network namespace provides a fail-closed offline environment;
# empty PATH and isolated HOME/XDG directories rule out user-side helpers.
run_isolated() {
    "$unshare_bin" --user --map-root-user --net --fork \
        "$env_bin" -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
        XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
        XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
        TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' SHELL=/bin/sh \
        "$@"
}

run_isolated VIM_REGION_SMOKE_EVIDENCE="$temporary/batch" \
    VIM_REGION_SMOKE_EXPAND_DIR="$expand_dir" VIM_REGION_SMOKE_PACKAGE_DIR="$lisp_dir" \
    "$timeout_bin" --kill-after=5s 45s "$emacs_bin" --batch -Q \
    -L "$expand_dir" -L "$lisp_dir" \
    -l "$channel_dir/tests/emacs-vim-region-smoke.el" \
    --eval '(vim-region-smoke-run)'
assert_evidence "$temporary/batch"

# A real terminal scene is mandatory even without a requested raw export.
# These init files are read before terminal setup; -Q would skip them and
# allow xterm query replies to enter the command loop during replay.
mkdir -p "$temporary/home/.emacs.d"
printf '(setq package-enable-at-startup nil)\n' \
    >"$temporary/home/.emacs.d/early-init.el"
printf '(setq inhibit-default-init t xterm-extra-capabilities nil)\n' \
    >"$temporary/home/.emacs.d/init.el"
script_log=$temporary/tty.script
# script forwards stdin EOF as a synthetic terminal character.  /dev/null
# therefore injects an editing command after the scene runs.  Keep an empty
# FIFO open on both ends instead: no input bytes and no premature EOF.
mkfifo "$temporary/tty.stdin"
exec 3<>"$temporary/tty.stdin"

# script -c is parsed by a shell.  Quote every filesystem argument, including
# repository paths containing spaces or apostrophes.
shell_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

tty_command="$(shell_quote "$stty_bin") rows 24 cols 80; exec $(shell_quote "$emacs_bin") -nw \
--no-site-file --no-site-lisp --no-splash --no-x-resources \
-L $(shell_quote "$expand_dir") -L $(shell_quote "$lisp_dir") \
-l $(shell_quote "$channel_dir/tests/emacs-vim-region-smoke.el") \
--eval '(vim-region-smoke-tty-scene)'"

# Bound both elapsed time and log growth.  The helper records the byte
# boundary after final redisplay and before Emacs leaves its alternate screen.
(
    ulimit -f 8192
    run_isolated TERM=xterm-256color VIM_REGION_SMOKE_TTY_LOG="$script_log" \
        VIM_REGION_SMOKE_EVIDENCE="$temporary/tty" \
        VIM_REGION_SMOKE_EXPAND_DIR="$expand_dir" VIM_REGION_SMOKE_PACKAGE_DIR="$lisp_dir" \
        "$timeout_bin" --kill-after=5s 45s "$script_bin" -q -f -e \
        -c "$tty_command" "$script_log" <&3 >/dev/null
) || {
    cat "$temporary/tty/tty-scene.err" >&2 2>/dev/null || true
    exit 1
}
test -f "$temporary/tty/tty-scene.ok"
test ! -e "$temporary/tty/tty-scene.err"
assert_evidence "$temporary/tty"
frame_bytes=$(cat "$temporary/tty/tty-frame.bytes")
case $frame_bytes in
    ''|*[!0-9]*) echo 'vim-region smoke: invalid frame byte count' >&2; exit 1 ;;
esac
test "$frame_bytes" -gt 0
test "$frame_bytes" -le 1048576
test "$frame_bytes" -le "$(wc -c <"$script_log")"

raw_capture=${EMACS_VIM_REGION_RAW_CAPTURE:-}
if test -n "$raw_capture"; then
    # Drop only script's leading banner, preserving actual terminal bytes.
    "$head_bin" -c "$frame_bytes" "$script_log" |
        sed -e '1{/^Script started on /d;}' >"$raw_capture"
    esc=$(printf '\033')
    last_enter=$(grep -abo "$esc\[?1049h" "$raw_capture" | sed -n '$s/:.*//p')
    test -n "$last_enter"
    last_leave=$(grep -abo "$esc\[?1049l" "$raw_capture" | sed -n '$s/:.*//p')
    if test -n "$last_leave" && test "$last_leave" -gt "$last_enter"; then
        echo 'vim-region smoke: exported frame includes terminal restore' >&2
        exit 1
    fi
    for proof in '*vim-region editing proof*' 'gammabeta' 'keep this line' ' vim-region'; do
        last_proof=$(grep -abFo "$proof" "$raw_capture" | sed -n '$s/:.*//p')
        test -n "$last_proof"
        test "$last_proof" -gt "$last_enter"
    done
    if grep -aq "$esc\[>0c\|$esc]11;?" "$raw_capture"; then
        echo 'vim-region smoke: exported frame contains terminal queries' >&2
        exit 1
    fi
fi

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
assert_immutable
