#!/bin/sh
# Exercise the installed Aidermacs package without user state or a network.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-aidermacs-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes \
        emacs-aidermacs)
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
transient_out=$($guix_bin build emacs-transient)
compat_out=$($guix_bin build emacs-compat)
cond_let_out=$($guix_bin build emacs-cond-let)
markdown_out=$($guix_bin build emacs-markdown-mode)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$unshare_out/bin/unshare

test -x "$emacs_bin"
test -x "$unshare_bin"

license=$package_out/share/doc/emacs-aidermacs/LICENSE
test -f "$license"
grep -q 'Apache License' "$license"
grep -q 'Version 2.0, January 2004' "$license"

package_lisp=$(find "$package_out/share/emacs/site-lisp" -type f \
    \( -name aidermacs.el -o -name aidermacs.elc \) -print | sed -n '1p')
test -n "$package_lisp"
package_lisp_dir=$(dirname "$package_lisp")

for runtime_file in aidermacs.el aidermacs-backend-comint.el \
                    aidermacs-backend-vterm.el aidermacs-backends.el \
                    aidermacs-models.el aidermacs-output.el; do
    test -f "$package_lisp_dir/$runtime_file" -o -f "$package_lisp_dir/${runtime_file}c"
    grep -q 'SPDX-License-Identifier: Apache-2.0' "$package_lisp_dir/$runtime_file"
done
test ! -e "$package_lisp_dir/aidermacs.png"
test ! -e "$package_lisp_dir/introscreen.png"

find_lisp_dir() {
    root=$1
    name=$2
    file=$(find "$root/share/emacs/site-lisp" -type f \
        \( -name "$name.el" -o -name "$name.elc" \) -print | sed -n '1p')
    test -n "$file"
    dirname "$file"
}

transient_lisp_dir=$(find_lisp_dir "$transient_out" transient)
compat_lisp_dir=$(find_lisp_dir "$compat_out" compat)
cond_let_lisp_dir=$(find_lisp_dir "$cond_let_out" cond-let)
markdown_lisp_dir=$(find_lisp_dir "$markdown_out" markdown-mode)

temporary=$(mktemp -d -t emacs-aidermacs-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/workspace"
chmod 700 "$temporary/runtime"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}

before_fingerprint=$(output_fingerprint)

# A private network namespace gives this test a fail-closed network boundary.
"$unshare_bin" --user --map-root-user --net --fork \
    env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
    "$emacs_bin" --batch -Q \
    -L "$package_lisp_dir" -L "$transient_lisp_dir" -L "$compat_lisp_dir" \
    -L "$cond_let_lisp_dir" -L "$markdown_lisp_dir" \
    --eval "(progn
      (require 'url)
      (defun aidermacs-smoke-prohibit-network (&rest _)
        (error \"network prohibited during aidermacs smoke test\"))
      (advice-add 'url-retrieve-synchronously :around
                  #'aidermacs-smoke-prohibit-network)
      (unwind-protect
          (let ((default-directory \"$temporary/workspace/\")
                (exec-path nil)
                (process-environment (cons \"PATH=\" process-environment)))
            (require 'aidermacs)
            (unless (featurep 'aidermacs)
              (error \"aidermacs feature was not provided\"))
            (unless (commandp 'aidermacs-transient-menu)
              (error \"aidermacs transient command is unavailable\"))
            (unless (string= (aidermacs--process-message-if-multi-line
                              \"one\\ntwo\")
                             \"{aidermacs\\none\\ntwo\\naidermacs}\")
              (error \"multi-line message transformation failed\"))
            (clrhash aidermacs--resolved-programs)
            (condition-case err
                (progn (aidermacs-get-program)
                       (error \"missing Aider program was accepted\"))
              (error
               (unless (string-match-p \"Aider executable not found\"
                                       (error-message-string err))
                 (signal (car err) (cdr err))))))
        (advice-remove 'url-retrieve-synchronously
                       #'aidermacs-smoke-prohibit-network)))"

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
