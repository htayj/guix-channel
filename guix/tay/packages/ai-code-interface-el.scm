;;; GNU Guix package for tninja/ai-code-interface.el.

(define-module (tay packages ai-code-interface-el)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-s-z))

(define-public ai-code-interface-el
  (let ((load-path-inputs
         (cons emacs-magit
               (map cadr (package-transitive-propagated-inputs emacs-magit)))))
    (package
      (name "ai-code-interface-el")
      (version "1.930")
      (source (package-source tninja-ai-code-interface-el-source))
      (build-system emacs-build-system)
      (arguments
       (list
        ;; All 53 top-level ai-code libraries are runtime modules.  Other
        ;; upstream Elisp (in etc/, examples/, and test/) is not installed.
        #:include #~'("^ai-code.*\\.el$")
        #:phases
        #~(modify-phases %standard-phases
            (add-before 'install 'patch-generated-helper-shell
              (lambda _
                (substitute* "ai-code-editor-viewport-transport.el"
                  (("#!/bin/sh")
                   (string-append "#!" #$bash-minimal "/bin/sh")))))
            (add-after 'install 'install-runtime-data-and-launcher
              (lambda _
                (use-modules (srfi srfi-1))
                (let* ((out #$output)
                       (lisp-file (car (find-files
                                        (string-append out "/share/emacs/site-lisp")
                                        "^ai-code\\.el$")))
                       (lisp-dir (dirname lisp-file))
                       (bin (string-append out "/bin"))
                       (launcher (string-append bin "/ai-code-interface-el"))
                       ;; magit propagates transient, compat, cond-let,
                       ;; llama, with-editor and async.  -Q intentionally
                       ;; ignores EMACSLOADPATH, so add those paths explicitly.
                       (roots (cons out (list #$@load-path-inputs)))
                       (lisp-dirs
                        (sort (delete-duplicates
                               (append-map
                                (lambda (root)
                                  (map dirname
                                       (find-files
                                        (string-append root "/share/emacs/site-lisp")
                                        "\\.el$")))
                                roots))
                              string<?)))
                  ;; Harness prompts and YASnippet files are looked up next
                  ;; to ai-code.el, not via the Emacs data directory.
                  (copy-recursively "prompt" (string-append lisp-dir "/prompt"))
                  (copy-recursively "snippets" (string-append lisp-dir "/snippets"))
                  (install-file "README.org" lisp-dir)
                  (install-file "LICENSE"
                                (string-append out "/share/doc/ai-code-interface-el"))
                  (mkdir-p bin)
                  (call-with-output-file launcher
                    (lambda (port)
                      (format port "#!~a/bin/sh~%exec ~a/bin/emacs -Q"
                              #$bash-minimal #$emacs-minimal)
                      (for-each (lambda (dir) (format port " -L '~a'" dir))
                                lisp-dirs)
                      (display " \"$@\"\n" port)))
                  (chmod launcher #o755))))
            (add-after 'build 'check-upstream
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (setenv "HOME" (getcwd))
                  (invoke (string-append #$output "/bin/ai-code-interface-el")
                          "--batch" "-L" "."
                          "-l" "test/test_00-bootstrap.el" "-l" "ert"
                          "--eval"
                          "(mapc #'load-file (file-expand-wildcards \"test/test_*.el\"))"
                          "-f" "ert-run-tests-batch-and-exit")))))))
      (inputs (list emacs-minimal bash-minimal coreutils-minimal git-minimal))
      (propagated-inputs (list emacs-magit emacs-transient))
      (home-page "https://github.com/tninja/ai-code-interface.el")
      (synopsis "Emacs interface for AI coding assistants")
      (description
       "AI Code Interface provides an Emacs transient menu and session tools
for optional coding-agent backends.  The interface loads without a provider;
external coding CLIs, model access, and credentials are supplied by the user
only when a backend is selected.  The bundled batch launcher runs Emacs with
an isolated load path and forwards user arguments.")
      (license license:asl2.0))))
