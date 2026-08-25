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
    package_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes \
        emacs-forth-mode@0-4450a3a)
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
source_out=$($guix_bin build -L "$channel_dir" larsbrinkhoff-forth-mode-source)
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

"$unshare_bin" --user --map-root-user --net --fork \
    env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
    "$emacs_bin" --batch -Q -L "$lisp_dir" \
    --eval "(let ((default-directory \"$fixtures/\")
                  (create-lockfiles nil))
              (require 'forth-mode)
              (require 'forth-block-mode)
              (require 'forth-interaction-mode)
              (unless (string= forth-executable \"$gforth_bin\")
                (error \"forth-executable was not set to packaged Gforth\"))
              (dolist (fixture '(\"test/noblock.fth\" \"test/block1.fth\" \"test/block2.fth\"))
                (find-file fixture)
                (unless (eq major-mode 'forth-mode)
                  (error \"forth-mode was not selected for %s\" fixture))
                (if (string= fixture \"test/noblock.fth\")
                    (when (bound-and-true-p forth-block-mode)
                      (error \"ordinary source unexpectedly enabled block mode\"))
                  (unless (bound-and-true-p forth-block-mode)
                    (error \"Forth block fixture did not enable block mode\")))
                (kill-buffer))
              (run-forth)
              (let ((process (get-buffer-process forth-interaction-buffer))
                    (deadline (+ (float-time) 5)))
                (while (and (not forth-implementation) (< (float-time) deadline))
                  (accept-process-output process 0.1))
                (unless (eq forth-implementation 'gforth)
                  (error \"installed Gforth backend was not loaded\"))
                (unless (string-match-p \"4\" (forth-interaction-send \"2 2 + .\"))
                  (error \"packaged Gforth did not evaluate input\"))
                (forth-kill)
                (setq deadline (+ (float-time) 5))
                (while (and (process-live-p process) (< (float-time) deadline))
                  (accept-process-output process 0.1))
                (when (process-live-p process)
                  (error \"Gforth process was not killed cleanly\"))))"

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
