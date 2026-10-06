;;; Minttea and Leaves with the same-source standalone Spices provider.

(define-module (tay packages minttea)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system dune)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml)
  #:use-module (tay packages minttea-deps)
  #:use-module (tay packages ocaml-minttea-toolchain)
  #:use-module (tay packages starred-i-m))

(define %minttea-spices-provider
  (with-minttea-dependencies ocaml-spices-minttea))

(define %minttea-propagated-inputs
  (map with-minttea-dependencies
       (list ocaml-riot-minttea ocaml-tty-minttea ocaml-colors-minttea
             ocaml-ptime-minttea ocaml-uuseg ocaml-spices-minttea)))

(define %minttea-consumer-closure
  (append %minttea-propagated-inputs
          (apply append
                 (map (lambda (p)
                        (map cadr (package-transitive-propagated-inputs p)))
                      %minttea-propagated-inputs))))

(define-public minttea
  (with-minttea-dependencies
   (package
     (name "minttea")
     (version "0.0.3-1.40ee449")
     ;; Reuse the exact ledger origin without snippets or source pruning.
     (source (package-source leostera-minttea-source))
     (build-system dune-build-system)
     ;; Build the complete source and run every upstream MDX alias.  Install
     ;; Minttea/Leaves only; the same-source standalone package owns Spices.
     (arguments
      (list
       #:phases
       #~(modify-phases #$%minttea-runtime-phases
           (add-after 'unpack 'adapt-basic-example-key-events
             (lambda _
               ;; Keep the installed upstream tree byte-exact.  Only the
               ;; working basic example predates the key modifier payload.
               ;; An archive also protects original scripts from the later
               ;; automatic shebang patch phase.
               (invoke "tar" "-cf" ".upstream-examples.tar" "examples")
               (substitute* "examples/basic/main.ml"
                 (("Event.KeyDown \\(Key \"q\" \\| Escape\\)")
                  "Event.KeyDown ((Key \"q\" | Escape), _modifier)")
                 (("Event.KeyDown \\(Up \\| Key \"k\"\\)")
                  "Event.KeyDown ((Up | Key \"k\"), _modifier)")
                 (("Event.KeyDown \\(Down \\| Key \"j\"\\)")
                  "Event.KeyDown ((Down | Key \"j\"), _modifier)")
                 (("Event.KeyDown \\(Enter \\| Space\\)")
                  "Event.KeyDown ((Enter | Space), _modifier)"))))
           (add-after 'unpack 'reconcile-generated-opam
             (lambda _
               (substitute* "dune"
                 (("\\(mdx") "(mdx (package minttea)"))
               (substitute* "leaves/dune"
                 (("\\(mdx") "(mdx (package leaves)"))
               ;; Uuseg_string is exposed by the explicit string sublibrary.
               (substitute* '("spices/dune" "leaves/dune")
                 (("uuseg") "uuseg uuseg.string"))
               ;; The checked-in generated opam file still says Riot 0.0.8,
               ;; whereas dune-project and the APIs used by this source target
               ;; 0.0.9.  Regenerate all three manifests from their source
               ;; declarations, retaining the original project and libraries.
               (invoke "dune" "build" "minttea.opam" "leaves.opam"
                       "spices.opam")))
           (add-after 'build 'build-native-examples
             (lambda _
               (invoke "dune" "build" "--release"
                       "examples/counter/main.exe"
                       "examples/basic/main.exe")))
           (replace 'install
             (lambda _
               (invoke "dune" "install" "--prefix" #$output "--libdir"
                       (string-append #$output "/lib/ocaml/site-lib")
                       "minttea" "leaves")))
           (add-after 'install 'install-native-examples
             (lambda _
               (let ((bin (string-append #$output "/bin"))
                     (share (string-append #$output "/share/minttea")))
                 (mkdir-p bin)
                 (copy-file "_build/default/examples/counter/main.exe"
                            (string-append bin "/minttea-counter"))
                 (copy-file "_build/default/examples/basic/main.exe"
                            (string-append bin "/minttea-basic"))
                 (mkdir-p share)
                 (invoke "tar" "-xf" ".upstream-examples.tar" "-C" share)
                 (call-with-output-file (string-append share "/source-commit")
                   (lambda (port)
                     (display "40ee44920bda53bd2838065374c9b188c06f8cba\n" port)))
                 (call-with-output-file (string-append share "/spices-provider")
                   (lambda (port)
                     (format port "~a\n" #$%minttea-spices-provider)))
                 (call-with-output-file (string-append share "/consumer-toolchain")
                   (lambda (port)
                     (format port "~a\n~a\n" #$ocaml-minttea
                             #$ocaml-findlib-minttea)))
                 (call-with-output-file (string-append share "/consumer-closure")
                   (lambda (port)
                     (for-each (lambda (prefix) (format port "~a\n" prefix))
                               (cons #$output
                                     (list #$@%minttea-consumer-closure)))))))))))
     (propagated-inputs
      %minttea-propagated-inputs)
     (native-inputs (list ocaml-mdx-minttea))
     (home-page "https://github.com/leostera/minttea")
     (synopsis "Functional terminal user interfaces for OCaml")
     (description
      "Minttea provides functional, stateful terminal applications using the
Riot actor runtime.  This package includes the source-defined Minttea framework,
Leaves reusable components and Spices declarative styling libraries, together
with the native counter and basic selection examples.")
     (license license:expat))))
