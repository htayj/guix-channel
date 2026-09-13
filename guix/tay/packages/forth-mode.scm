;;; GNU Guix package for larsbrinkhoff/forth-mode.

(define-module (tay packages forth-mode)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages forth)
  #:use-module (tay packages larsbrinkhoff-a-f))

(define-public emacs-forth-mode
  (package
    ;; This deliberately supersedes Guix's older NonGNU ELPA 0.2 package with
    ;; the same package identity when this channel is selected.
    (name "emacs-forth-mode")
    (version (package-version larsbrinkhoff-forth-mode-source))
    (source (package-source larsbrinkhoff-forth-mode-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; Install the top-level libraries and runtime-selectable backend
      ;; libraries, including SwiftForth's helper program.  build.el creates
      ;; autoloads.el for its test-only byte compilation; Guix generates its
      ;; own package autoloads, so do not install that upstream byproduct.
      #:include #~(cons "^backend/.*$" %default-include)
      #:exclude #~(cons* "^build\\.el$" "^autoloads\\.el$"
                          %default-exclude)
      #:test-command
      #~(list "make" "check"
              (string-append "FORTH=" #$(file-append gforth "/bin/gforth")))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'set-forth-executable
            (lambda* (#:key inputs #:allow-other-keys)
              ;; run-forth passes this value directly to
              ;; make-comint-in-buffer, so a store path avoids a wrapper and
              ;; PATH-dependent runtime lookup.
              (emacs-substitute-variables "forth-interaction-mode.el"
                ("forth-executable" (search-input-file inputs "/bin/gforth")))))
          (add-before 'check 'disable-networked-ert-test
            (lambda _
              ;; This test fetches the live Forth-standard indexes.  Retain
              ;; every offline ERT test, including the Gforth completion test.
              (substitute* "test/tests.el"
                (("(ert-deftest forth-spec-parsing \\(\\))" all)
                 (string-append all
                                "\n  (ert-skip \"requires a live Forth-standard"
                                " index\")")))))
          (add-before 'check 'set-test-home
            (lambda _
              (setenv "HOME" (getenv "TMPDIR")))))))
    ;; Gforth is both the packaged runtime selected above and the interpreter
    ;; exercised by the completion ERT test.
    (inputs (list gforth))
    (home-page "https://github.com/larsbrinkhoff/forth-mode")
    (synopsis "Programming language mode for Forth")
    (description
     "This package provides major modes for editing Forth source and
64-character Forth blocks, an interaction mode, and backends for several
Forth implementations.  The default interaction command is the packaged
Gforth interpreter, whose backend configures its existing completion support.")
    (license license:gpl3)))
