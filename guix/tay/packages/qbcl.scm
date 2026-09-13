;;; QBCL -- command-line tools for qBittorrent.
;;;
;;; SPDX-License-Identifier: GPL-2.0-or-later

(define-module (tay packages qbcl)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages projects))

(define-public sbcl-qbcl
  (package
    (name "sbcl-qbcl")
    (version "0.1.0")
    ;; The source snapshot is pinned in the channel's project ledger; keeping
    ;; it here avoids a second, independently maintained source hash.
    (source (package-source htayj-qbcl-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      ;; The pinned upstream revision has no test system or test files.
      #:tests? #f
      #:asd-systems ''("qbcl")
      #:phases
      #~(modify-phases %standard-phases
          ;; @code{client} has no @code{:timeout} initarg.  SBCL treats the
          ;; resulting compile-time warning as an ASDF compilation failure.
          (add-after 'unpack 'fix-client-construction
            (lambda _
              (substitute* "src/torrent/engine.lisp"
                ((":timeout timeout") ""))))
          (add-after 'create-asdf-configuration 'build-program
            (lambda* (#:key outputs #:allow-other-keys)
              (build-program
               (string-append (assoc-ref outputs "out") "/bin/qbcl")
               outputs
               #:dependencies '("qbcl")
               #:entry-program
               '((uiop:quit (qbcl:main arguments)))
               #:compress? #t))))))
    (inputs
     (list sbcl-alexandria
           sbcl-bordeaux-threads
           sbcl-cl-interpol
           sbcl-cl-ppcre
           sbcl-dexador
           sbcl-jonathan
           sbcl-local-time
           sbcl-quri
           sbcl-cl-str
           sbcl-unix-opts))
    (synopsis "Command-line qBittorrent controller")
    (description
     "QBCL is a Common Lisp command-line application for inspecting and
controlling qBittorrent through its Web API.  It provides torrent filtering,
formatted or JSON output, torrent actions, connection profiles, and an
@command{lstor} subcommand for inspecting torrent files.")
    (home-page "https://github.com/htayj/qbcl")
    (license license:gpl2+)))
