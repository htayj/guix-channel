;;; GNU Guix package for MatthewZMD/aidermacs.

(define-module (tay packages aidermacs)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-i-m))

(define-public emacs-aidermacs
  (package
    (name "emacs-aidermacs")
    ;; The upstream libraries at this fixed revision each declare version
    ;; 1.11.  Retain the commit suffix because it is not a release tag.
    (version "1.11-0.2fc9939")
    (source (package-source matthewzmd-aidermacs-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; Do not install README images, workflow files, or other development
      ;; material: these are the six runtime libraries in the pinned tree.
      #:include
      #~'("^aidermacs\\.el$"
          "^aidermacs-backend-comint\\.el$"
          "^aidermacs-backend-vterm\\.el$"
          "^aidermacs-backends\\.el$"
          "^aidermacs-models\\.el$"
          "^aidermacs-output\\.el$")
      #:test-command
      #~(list
         "emacs" "-Q" "--batch" "-L" "." "--eval"
         "(progn
            (dolist (file '(\"aidermacs.el\"
                            \"aidermacs-backend-comint.el\"
                            \"aidermacs-backend-vterm.el\"
                            \"aidermacs-backends.el\"
                            \"aidermacs-models.el\"
                            \"aidermacs-output.el\"))
              (byte-compile-file file))
            (require 'url)
            (defun aidermacs-test-prohibit-network (&rest _)
              (error \"network prohibited during aidermacs test\"))
            (advice-add 'url-retrieve-synchronously :around
                        #'aidermacs-test-prohibit-network)
            (unwind-protect
                (let ((default-directory (make-temp-file \"aidermacs-test-\" t))
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
                             #'aidermacs-test-prohibit-network)))")
      #:phases
      #~(modify-phases %standard-phases
          ;; Keep build checks independent of the builder's home directory.
          (add-before 'check 'set-test-home
            (lambda _
              (let ((home (string-append (getenv "TMPDIR") "/home")))
                (mkdir-p home)
                (setenv "HOME" home)
                (setenv "XDG_CONFIG_HOME" home)
                (setenv "XDG_DATA_HOME" home)
                (setenv "XDG_CACHE_HOME" home))))
          (add-after 'install 'install-license
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/emacs-aidermacs")))
                (mkdir-p doc)
                (install-file "LICENSE" doc)))))))
    ;; These libraries are required when the package is loaded, so expose
    ;; them in user profiles.  Vterm is deliberately optional upstream.
    (propagated-inputs
     (list emacs-compat emacs-markdown-mode emacs-transient))
    (home-page "https://github.com/MatthewZMD/aidermacs")
    (synopsis "Emacs interface for the Aider coding assistant")
    (description
     "Aidermacs provides an Emacs interface for the Aider coding assistant,
with Comint and optional Vterm backends.  It does not package an Aider
executable: at run time it looks for @code{aider-ce} or @code{aider} on
@code{PATH}, or uses a path configured in @code{aidermacs-program}.  Users
must provide that program separately.  Network and model-provider actions are
only initiated by explicit user commands.")
    (license license:asl2.0)))
