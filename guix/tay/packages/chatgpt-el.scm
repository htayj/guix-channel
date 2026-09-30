;;; GNU Guix package for joshcho/ChatGPT.el.

(define-module (tay packages chatgpt-el)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-i-m))

(define-public chatgpt-el
  (package
    (name "chatgpt-el")
    ;; Upstream declares 0.2 but has no release tag at this revision.
    (version "0.2-0.51c658a")
    (source (package-source joshcho-chatgpt-el-source))
    (build-system emacs-build-system)
    (arguments
     (list
      #:include #~'("^chatgpt\\.el$")
      #:test-command
      #~(list
         "emacs" "-Q" "--batch" "-L" "." "--eval"
         "(let ((process-environment
                 (cons \"PATH=\" (cons \"OPENAI_API_KEY=\" process-environment)))
                (exec-path nil))
             (require 'chatgpt)
             (unless (and (featurep 'chatgpt) (commandp 'chatgpt-query)
                          (commandp 'chatgpt-run))
               (error \"ChatGPT commands unavailable\"))
             (unless (equal chatgpt-cli-file-path \"lwe\")
               (error \"unexpected lwe default: %S\" chatgpt-cli-file-path)))")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'find-lwe-without-which
            ;; Upstream shells out to `which' at load time; when `which' is
            ;; absent the default becomes the shell's error text.  Resolve the
            ;; user-provided CLI from `exec-path' instead.
            (lambda _
              (substitute* "chatgpt.el"
                (("\\(shell-command-to-string \"which lwe\"\\)")
                 "(or (executable-find \"lwe\") \"lwe\")"))))
          (add-after 'install 'install-license
            (lambda _
              (let ((doc (string-append #$output "/share/doc/chatgpt-el")))
                (mkdir-p doc)
                (install-file "LICENSE" doc)))))))
    ;; Required by chatgpt.el on load, not just for optional formatting.
    (propagated-inputs (list emacs-polymode))
    (home-page "https://github.com/joshcho/ChatGPT.el")
    (synopsis "Emacs interface to ChatGPT via the user-provided lwe CLI")
    (description
     "ChatGPT.el provides a Comint chat buffer, code-query commands, command
completion, and Polymode support for fenced code blocks.  At run time it
launches a separately installed @code{lwe} executable, discovered on
@code{PATH} or configured with @code{chatgpt-cli-file-path}.  The package
neither provides that executable nor configures an API key or initiates
provider requests during installation or loading.")
    (license license:gpl3)))
