;;; RPLACA -- Lisp-native Emacs-inspired LLM chat interface.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-only

(define-module (tay packages rplaca)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages projects))

(define-public sbcl-rplaca
  (package
    (name "sbcl-rplaca")
    (version "0.1.0")
    ;; Keep the application tied to the channel's audited immutable source
    ;; snapshot instead of duplicating its source metadata here.
    (source (package-source htayj-rplaca-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      ;; RPLACA has both systems in its source tree.  Building @code{lispi}
      ;; first makes its local dependency available to the application.
      #:asd-systems ''("lispi" "rplaca")
      ;; The upstream ASDF test system has no @code{test-op} method, so Guix
      ;; cannot invoke FiveAM through the standard check phase.  The complete
      ;; suite is exercised separately by the package validation command.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'create-asdf-configuration 'install-launcher
            (lambda _
              ;; Do not dump RPLACA into an SBCL executable: its user-state
              ;; path defaults are computed while the image is built, which
              ;; would incorrectly preserve the read-only store as $HOME.
              ;; Loading the compiled ASDF system at launch keeps those paths
              ;; bound to the invoking user's home directory.
              (let ((program (string-append #$output "/bin/rplaca")))
                (mkdir-p (dirname program))
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash)
                    (format port
                            (string-append
                             "export XDG_CONFIG_DIRS=~a/etc"
                             "${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}~%")
                            #$output)
                    (format port
                            (string-append
                             "exec ~a/bin/sbcl --noinform --non-interactive"
                             " --eval '(require :asdf)'"
                             " --eval '(asdf:load-system :rplaca)'"
                             " --eval '(rplaca:rplaca-main)' \"$@\"~%")
                            #$sbcl)))
                (chmod program #o555)))))))
    (inputs
     (list sbcl
           sbcl-alexandria
           sbcl-bordeaux-threads
           sbcl-chipz
           sbcl-cl-json
           sbcl-coalton
           sbcl-drakma
           sbcl-flexi-streams
           sbcl-mcclim))
    (synopsis "Lisp-native LLM chat interface")
    (description
     "RPLACA is an Emacs-inspired chat interface written in Common Lisp.  It
uses McCLIM for its presentation-rich GUI and provides agent tools, structured
project and session state, and a Lisp data mode for interacting with local
files and Common Lisp systems.")
    (home-page "https://github.com/htayj/rplaca")
    (license license:agpl3)))
