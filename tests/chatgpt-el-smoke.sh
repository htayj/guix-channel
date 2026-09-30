#!/bin/sh
# Exercise ChatGPT.el's local Comint request and rendering without a provider.
# Set CHATGPT_EL_TRANSCRIPT=FILE to save the received *ChatGPT* buffer text
# after the assertions pass.
set -eu

transcript=${CHATGPT_EL_TRANSCRIPT:-}
case $transcript in
    ''|/*) ;;
    *) transcript=$PWD/$transcript ;;
esac

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [chatgpt-el-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes chatgpt-el)
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

find_lisp_dir() {
    root=$1
    name=$2
    file=$(find "$root/share/emacs/site-lisp" -type f \
        \( -name "$name.el" -o -name "$name.elc" \) -print | sed -n '1p')
    test -n "$file"
    dirname "$file"
}

emacs_out=$(find_program_output bin/emacs emacs-minimal)
unshare_out=$(find_program_output bin/unshare util-linux)
bash_out=$(find_program_output bin/bash bash-minimal)
timeout_out=$(find_program_output bin/timeout coreutils)
polymode_out=$($guix_bin build emacs-polymode)
emacs_bin=$emacs_out/bin/emacs
unshare_bin=$unshare_out/bin/unshare
bash_bin=$bash_out/bin/bash
timeout_bin=$timeout_out/bin/timeout

license=$package_out/share/doc/chatgpt-el/LICENSE
test -f "$license"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$license"
grep -q 'Version 3, 29 June 2007' "$license"
lisp_dir=$(find_lisp_dir "$package_out" chatgpt)
polymode_dir=$(find_lisp_dir "$polymode_out" polymode)
test -f "$lisp_dir/chatgpt.el"
test ! -e "$lisp_dir/README.org"
test ! -e "$lisp_dir/TODO.org"

temporary=$(mktemp -d -t chatgpt-el-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" \
      "$temporary/cache" "$temporary/state" "$temporary/runtime" \
      "$temporary/workspace" "$temporary/bin"
chmod 700 "$temporary/runtime"

# The local `lwe' accepts only /read and one explicitly specified arithmetic
# question.  It parses the transmitted code and computes a fenced-code answer;
# an echo of the input cannot satisfy the Emacs-side assertion.
printf '#!%s\n' "$bash_bin" > "$temporary/bin/lwe"
cat >> "$temporary/bin/lwe" <<'EOF'
set -eu
printf 'fixture@local>'
while IFS= read -r line; do
    if test "$line" != /read; then
        printf 'UNEXPECTED_COMMAND\nfixture@local>'
        continue
    fi
    printf '\n • Reading prompt, hit ^d when done, or write line with /end.\n\n'
    prompt=0
    expression=
    while IFS= read -r line; do
        if test "$line" = /end; then
            break
        fi
        if test "$line" = 'Calculate the sum shown in this code:'; then
            prompt=1
        fi
        case "$line" in
            '(+ '[0-9]*' '[0-9]*')') expression=$line ;;
        esac
    done
    if test "$prompt" -ne 1 || test -z "$expression"; then
        printf 'INVALID_REQUEST\nfixture@local>'
        continue
    fi
    operands=${expression#'(+ '}
    operands=${operands%')'}
    set -- $operands
    printf 'Computed result:\n```text\n%s\n```\nfixture@local>' "$(($1 + $2))"
done
EOF
chmod 555 "$temporary/bin/lwe"

output_fingerprint() {
    find "$package_out" -xdev -type f -exec sha256sum {} \; | LC_ALL=C sort | sha256sum
}

before_fingerprint=$(output_fingerprint)

"$timeout_bin" 30 "$unshare_bin" --user --map-root-user --net --fork \
    env -i HOME="$temporary/home" XDG_CONFIG_HOME="$temporary/config" \
    XDG_DATA_HOME="$temporary/data" XDG_CACHE_HOME="$temporary/cache" \
    XDG_STATE_HOME="$temporary/state" XDG_RUNTIME_DIR="$temporary/runtime" \
    TMPDIR="$temporary" LC_ALL=C.UTF-8 PATH="$temporary/bin" \
    CHATGPT_EL_TRANSCRIPT="$transcript" \
    "$emacs_bin" --batch -Q -L "$lisp_dir" -L "$polymode_dir" \
    --eval "(let ((default-directory \"$temporary/workspace/\")
                  (exec-path (list \"$temporary/bin\")))
              (require 'chatgpt)
              (setq cg-load-wait-time-in-secs 3
                    chatgpt-display-on-query nil)
              (unless (and (featurep 'chatgpt) (commandp 'chatgpt-query)
                           (commandp 'chatgpt-run) (commandp 'chatgpt-code-query))
                (error \"ChatGPT commands unavailable\"))
              ;; The packaged default resolves the CLI from exec-path.
              (unless (equal chatgpt-cli-file-path \"$temporary/bin/lwe\")
                (error \"lwe not discovered: %S\" chatgpt-cli-file-path))
              (with-temp-buffer
                (chatgpt-mode)
                (unless (equal comint-prompt-regexp chatgpt-prompt-regexp)
                  (error \"ChatGPT mode prompt unavailable\"))
                ;; Slash-command completion with a unique prefix.
                (insert \"/system-me\")
                (cg-completion-at-point)
                (unless (string-suffix-p \"/system-message\" (buffer-string))
                  (error \"command completion failed: %S\" (buffer-string))))
              (condition-case err
                  (progn (chatgpt-run) (error \"missing key accepted\"))
                (error
                 (unless (string-match-p \"Please set the environment variable\"
                                         (error-message-string err))
                   (signal (car err) (cdr err)))))
              ;; A placeholder only satisfies upstream's presence check; the
              ;; local lwe never contacts a provider and networking is unshared.
              (let ((process-environment
                     (cons \"OPENAI_API_KEY=offline-placeholder\" process-environment)))
                (chatgpt-run))
              (let ((base (cg-get-base-buffer)))
                (unwind-protect
                    (progn
                      (unless (and base (comint-check-proc base))
                        (error \"chatgpt-run did not start lwe\"))
                      (unless (equal (process-command (get-buffer-process base))
                                     (list \"$temporary/bin/lwe\"))
                        (error \"unexpected process: %S\"
                               (process-command (get-buffer-process base))))
                      (with-temp-buffer
                        (emacs-lisp-mode)
                        (cg-query \"Calculate the sum shown in this code:\\n\\n\"
                                  \"(+ 1 42)\"))
                      (with-current-buffer base
                        (let ((deadline (+ (float-time) 3)))
                          (while (and (not (string-match-p
                                            \"Computed result:\\n\x60\x60\x60text\\n43\\n\x60\x60\x60\"
                                            (buffer-string)))
                                      (< (float-time) deadline))
                            (accept-process-output (get-buffer-process base) 0.1)))
                        (unless (string-match-p
                                 \"Computed result:\\n\x60\x60\x60text\\n43\\n\x60\x60\x60\"
                                 (buffer-string))
                          (error \"computed local response missing: %S\" (buffer-string)))
                        (when (string-match-p \"INVALID_REQUEST\\|UNEXPECTED_COMMAND\"
                                              (buffer-string))
                          (error \"local CLI rejected request\"))
                        (let ((transcript (getenv \"CHATGPT_EL_TRANSCRIPT\")))
                          (unless (member transcript '(nil \"\"))
                            (let ((coding-system-for-write 'utf-8-unix))
                              (write-region (buffer-substring-no-properties
                                             (point-min) (point-max))
                                            nil transcript nil 'silent)))))
                      (message \"ChatGPT.el local request and fenced response: 43\"))
                  (when (and base (get-buffer-process base))
                    (delete-process (get-buffer-process base)))
                  (when (buffer-live-p base)
                    (kill-buffer base)))))"

after_fingerprint=$(output_fingerprint)
test "$before_fingerprint" = "$after_fingerprint"
test -z "$(find "$package_out" -xdev -type f -perm /222 -print -quit)"
