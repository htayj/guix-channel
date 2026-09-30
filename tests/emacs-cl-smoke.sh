#!/bin/sh
# Exercise the installed Common Lisp evaluator and compiler offline.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-cl-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes emacs-cl)
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
unshare_out=$(find_program_output bin/unshare util-linux)
timeout_out=$(find_program_output bin/timeout coreutils)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$unshare_out/bin/unshare
timeout_bin=$timeout_out/bin/timeout

test -x "$emacs_bin"
test -x "$unshare_bin"
test -x "$timeout_bin"

license=$(find "$package_out/share/doc" -type f -name COPYING -print | sed -n '1p')
test -n "$license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$license"
grep -q 'Version 2, June 1991' "$license"

lisp_file=$(find "$package_out/share/emacs/site-lisp" -type f -name load-cl.el -print | sed -n '1p')
test -n "$lisp_file"
lisp_dir=$(dirname "$lisp_file")
for runtime_file in load-cl.el cl-eval.el cl-compile.el cl-reader.el \
                    cl-conditions.el cl-types.el populate.el; do
    test -f "$lisp_dir/$runtime_file"
done
test ! -e "$lisp_dir/tests.el"
test ! -e "$lisp_dir/temporary.lisp"
test ! -e "$lisp_dir/emacs-cl"

temporary=$(mktemp -d -t emacs-cl-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime"
chmod 700 "$temporary/runtime"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}

before_fingerprint=$(output_fingerprint)

"$unshare_bin" --user --map-root-user --net --fork \
    env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
    "$emacs_bin" --batch -Q -L "$lisp_dir" -l load-cl.el \
    --eval '(let ((eval-expr (lambda (text)
                               (emacs-cl-eval-interactively
                                (READ-FROM-STRING text)))))
              (unless (equal (funcall eval-expr "(+ 1 2)") (list 3))
                (error "Common Lisp arithmetic failed"))
              (unless (equal (funcall eval-expr
                              "(PROGN (DEFUN DOUBLE (X) (+ X X)) (DOUBLE 21))")
                             (list 42))
                (error "Common Lisp function call failed"))
              (unless (equal (funcall eval-expr
                              "(PROGN (DEFUN ORDERED (&KEY (A 1) (B 2)) (LIST A B)) (ORDERED :B 7 :A 9))")
                             (list (list 9 7)))
                (error "Common Lisp keyword arguments failed"))
              (unless (equal (funcall eval-expr "(PARSE-INTEGER \"42\")")
                             (list 42 2))
                (error "Common Lisp integer parsing failed"))
              (unless (equal (funcall eval-expr
                              "(FORMAT NIL \"~A:~D\" \"x\" 7)")
                             (list "x:7"))
                (error "Common Lisp FORMAT failed"))
              (unless (equal (funcall eval-expr
                              "(+ 999999999999999999999 1)")
                             (list 1000000000000000000000))
                (error "Common Lisp bignum arithmetic failed"))
              (unless (equal (funcall eval-expr
                              "(LOOP FOR I FROM 1 TO 4 COLLECT (* I I))")
                             (list (list 1 4 9 16)))
                (error "Common Lisp LOOP failed"))
              (unless (equal (funcall eval-expr
                              "(FUNCALL (COMPILE NIL (QUOTE (LAMBDA (X) (+ X 1)))) 41)")
                             (list 42))
                (error "Common Lisp compiled function failed"))
              (unless (equal (funcall eval-expr
                              "(FUNCALL (COMPILE NIL (QUOTE (LAMBDA (N) (FLET ((ADD (X) (+ X N))) (ADD 2))))) 40)")
                             (list 42))
                (error "Common Lisp compiled closure failed"))
              ;; One comma remains for the inner evaluation; two commas
              ;; reach this outer level.  Neither may quote the value of X.
              (unless (equal (funcall eval-expr
                              "(PROGN (DEFPARAMETER *BQ-X* 5) (DEFPARAMETER *BQ-Y* 9) (EVAL ``(A ,*BQ-X* ,,*BQ-Y*)))")
                             (list (list (car (READ-FROM-STRING "(A)")) 5 9)))
                (error "Common Lisp mixed nested backquote failed"))
              (unless (equal (funcall eval-expr
                              "(HANDLER-CASE (CAR 1) (TYPE-ERROR () :CAUGHT))")
                             (list (keyword "CAUGHT")))
                (error "Common Lisp error conversion failed"))
              (message "emacs-cl evaluator: arithmetic, DEFUN, &KEY, LOOP, PARSE-INTEGER, FORMAT, bignums, COMPILE, closures, mixed nested backquote, HANDLER-CASE passed"))'

# An uncaught condition must not leave a batch debugger blocked at stdin EOF.
if "$timeout_bin" 20 "$unshare_bin" --user --map-root-user --net --fork \
    env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
    "$emacs_bin" --batch -Q -L "$lisp_dir" -l load-cl.el -l batch.el \
    --eval '(emacs-cl-eval-interactively (READ-FROM-STRING "(CAR 1)"))' \
    < /dev/null > "$temporary/error.log" 2>&1; then
    echo 'uncaught Common Lisp error unexpectedly succeeded' >&2
    exit 1
fi
grep -q 'Debugger: end of input; exiting.' "$temporary/error.log"
printf '%s\n' 'emacs-cl uncaught error: batch debugger exited at EOF'

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
