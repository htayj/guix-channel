#!/bin/sh
# Verify the installed interface without starting a backend or contacting a model.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [ai-code-interface-el-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" ai-code-interface-el)
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

unshare_out=$(find_program_output bin/unshare util-linux)
timeout_out=$(find_program_output bin/timeout coreutils)
unshare_bin=$unshare_out/bin/unshare
env_bin=$(command -v env)
launcher=$package_out/bin/ai-code-interface-el
license=$package_out/share/doc/ai-code-interface-el/LICENSE

test -x "$launcher"
test -f "$license"
grep -q 'Apache License' "$license"
grep -q 'Version 2.0, January 2004' "$license"

lisp_dir=$(dirname "$(find "$package_out/share/emacs/site-lisp" \
    -name ai-code.el -print -quit)")
test -f "$lisp_dir/ai-code.el"


test -f "$lisp_dir/README.org"
test -f "$lisp_dir/prompt/grilling.v1.md"
test -d "$lisp_dir/snippets/ai-code-prompt-mode"
test ! -e "$lisp_dir/ai-code-interface.png"
test ! -e "$lisp_dir/test"

temporary=$(mktemp -d -t ai-code-interface-el-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/workspace"
chmod 700 "$temporary/runtime"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}
before_fingerprint=$(output_fingerprint)

# A private network namespace and empty PATH fail closed.  The wrapper's
# absolute Emacs and shell paths do not depend on the user's environment.
result=$("$timeout_out/bin/timeout" --kill-after=5 60 \
    "$unshare_bin" --user --map-root-user --net --pid --kill-child --fork \
    "$env_bin" -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH='' \
    "$launcher" --batch --eval \
    "(let ((default-directory \"$temporary/workspace/\")
           (exec-path nil)
           (process-environment (cons \"PATH=\" process-environment)))
       (require 'ai-code)
       (unless (and (featurep 'ai-code)
                    (commandp 'ai-code-menu)
                    (string= (ai-code-current-backend-label) \"Claude Code\"))
         (error \"ai-code no-provider load assertion failed\"))
       (princ \"AI_CODE_RUNTIME_OK\\n\"))")
test "$result" = AI_CODE_RUNTIME_OK
printf '%s\n' "$result"

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
test -z "$(find "$temporary/home" "$temporary/config" "$temporary/data" \
    "$temporary/cache" "$temporary/state" "$temporary/runtime" \
    "$temporary/workspace" -type f -print -quit)"
