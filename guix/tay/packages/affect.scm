;;; Source-built Affect with its complete pinned library surface.

(define-module (tay packages affect)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system ocaml)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml)
  #:use-module (tay packages ocaml-affect-toolchain)
  #:use-module (tay packages starred-d-h))

(define-public affect
  (package
    (name "affect")
    (version (git-version "0.0.0" "0"
                          "780faa266d62f9567fd9d23f84bddc77f77087c0"))
    (source (package-source dbuenzli-affect-source))
    (build-system ocaml-build-system)
    (arguments
     (list
      #:ocaml ocaml-affect
      #:findlib ocaml-findlib-affect
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'set-snapshot-version
            (lambda _
              ;; Codeload snapshots have no VCS watermarking information.
              ;; Only installed metadata is watermarked; preservation output
              ;; and external upstream example sources remain untouched.
              (substitute* "pkg/META"
                (("%%VERSION_NUM%%") #$version))))
          (replace 'build
            (lambda _
              (invoke "ocaml" "-I"
                      #$(file-append ocaml-findlib-affect "/lib/ocaml/site-lib")
                      "pkg/pkg.ml" "build" "--dev-pkg" "false"
                      "--with-cmdliner" "true")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; B0.ml also declares B0_testing-based and stress suites.
                ;; They need b0.std, which is not a library dependency of
                ;; Affect.  Run the standalone offline upstream programs here;
                ;; do not misrepresent these as the full B0 test suite.
                (for-each
                 (lambda (name)
                   (let ((exe (string-append "test/" name ".native")))
                     (invoke "ocamlfind" "ocamlopt" "-thread"
                             "-package" "threads,unix,cmdliner" "-linkpkg"
                             "-I" "_build/src" "-I" "_build/src/unix"
                             "-I" "_build/src/tmp" "-I" "_build/src/cli"
                             "-cclib" "-L_build/src/unix"
                             "_build/src/affect.cmxa"
                             "_build/src/unix/affect_unix.cmxa"
                             "_build/src/cli/affect_cli.cmxa"
                             (string-append "test/" name ".ml") "-o" exe)
                     (invoke exe)))
                 '("quick_start" "blueprint_minimal"
                   "blueprint_minimal_unix" "blueprint_cli")))))
          (add-after 'install 'install-consumer-material
            (lambda _
              (let ((data (string-append #$output "/share/affect")))
                (mkdir-p data)
                (call-with-output-file (string-append data "/consumer-toolchain")
                  (lambda (port)
                    (format port "~a~%~a~%~a~%"
                            #+ocaml-affect #+ocaml-findlib-affect
                            #$ocaml-cmdliner-affect)))
                ;; Preserve original source bytes for external compilation,
                ;; independently of in-tree build products and substitutions.
                (install-file
                 #$(file-append dbuenzli-affect-source
                                "/share/dbuenzli/projects/affect/test/quick_start.ml")
                 (string-append data "/examples"))
                (install-file
                 #$(file-append dbuenzli-affect-source
                                "/share/dbuenzli/projects/affect/test/blueprint_cli.ml")
                 (string-append data "/examples"))
                (call-with-output-file (string-append data "/source-commit")
                  (lambda (port)
                    (display "780faa266d62f9567fd9d23f84bddc77f77087c0\n"
                             port)))))))))
    (native-inputs (list ocamlbuild-affect ocaml-topkg-affect opam-installer))
    (propagated-inputs (list ocaml-cmdliner-affect))
    (home-page "https://erratique.ch/software/affect")
    (synopsis "Structured asynchronous functions and cooperative Unix I/O")
    (description
     "Affect provides structured asynchronous functions, composable actions,
parallel execution and cancellation for OCaml.  This package builds the base,
Unix, temporary networking and Cmdliner CLI libraries from the original pinned
source with an OCaml 5.5 toolchain.  Its build checks run the offline standalone
upstream quick-start and blueprint programs; the separate B0_testing and stress
suites are not run.  The preserved source-snapshot package remains unchanged.")
    (license license:isc)))
