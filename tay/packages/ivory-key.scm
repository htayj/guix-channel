;;; Ivory Key -- declarative keyboard-layout compiler.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages ivory-key)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages projects))

(define-public sbcl-ivory-key
  (package
    (name "sbcl-ivory-key")
    (version "0.1.0")
    ;; Keep the executable tied to the channel's audited immutable source
    ;; snapshot instead of duplicating its source metadata here.
    (source (package-source htayj-ivory-key-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("ivory-key")
      #:asd-test-systems ''("ivory-key/tests")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'create-asdf-configuration 'build-program
            (lambda* (#:key outputs #:allow-other-keys)
              (build-program
               (string-append (assoc-ref outputs "out") "/bin/ivory-key")
               outputs
               #:dependencies '("ivory-key")
               #:entry-program
               '((uiop:quit (ivory-key.cli:main arguments)))
               #:compress? #t))))))
    (synopsis "Declarative keyboard-layout compiler")
    (description
     "Ivory Key is a Common Lisp compiler for declarative keyboard layouts.
It models logical positions, semantic output, context state, and timed
interaction rules independently from XKB, Kanata, evdev, and firmware syntax.
The @command{ivory-key} command can inspect, format, simulate, plan, and
compile supported layouts without deploying a keyboard configuration.")
    (home-page "https://github.com/htayj/ivory-key")
    (license license:gpl3+)))
