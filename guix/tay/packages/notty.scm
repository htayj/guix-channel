;;; Source-built Notty and its Unix and Lwt backends (issue 156).

(define-module (tay packages notty)
  #:use-module (guix build-system dune)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages ocaml)
  #:use-module ((tay packages starred-n-r) #:select (pqwy-notty-source)))

;; The immutable snapshot commit is exactly upstream's v0.2.3 tag.
(define %notty-version "0.2.3")

(define-public notty
  (package
    (name "notty")
    (version %notty-version)
    ;; Reuse the exact archive and hash of the immutable source deliverable.
    ;; Dune builds in its own unpacked directory, never in the snapshot output.
    (source (package-source pqwy-notty-source))
    (build-system dune-build-system)
    (arguments
     (list
      #:package "notty"
      #:phases
      #~(modify-phases %standard-phases
          ;; The commit archive lacks the Git metadata needed by dune subst.
          ;; Stamp only the private build tree, leaving the snapshot intact.
          (add-after 'unpack 'set-package-version
            (lambda _
              (substitute* "dune-project"
                (("%%VERSION_NUM%%") #$%notty-version))))
          ;; Upstream describes these interactive examples as its tests.  There
          ;; are no runtest stanzas at this revision; retain the standard check
          ;; phase and compile every example, including the Lwt consumers.
          (add-after 'build 'build-upstream-examples
            (lambda _
              (invoke "dune" "build" "-p" "notty" "@ex")))
          (add-after 'install 'install-upstream-documentation
            (lambda _
              (let ((doc (string-append #$output "/share/doc/notty"))
                    (examples (string-append #$output "/libexec/notty")))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.md" "README.md" "CHANGES.md"))
                (copy-recursively "examples"
                                  (string-append doc "/examples"))
                (for-each (lambda (file) (install-file file examples))
                          (find-files "_build/default/examples" "\\.exe$"))))))))
    ;; The pinned opam file requires cppo >= 1.1 and uutf >= 1.0.  Lwt >=
    ;; 2.5.2 is optional upstream, but supplied here so notty.lwt is installed.
    ;; Unix and compiler-libs.toplevel come with Guix's OCaml 4.14 compiler,
    ;; which is within the explicitly supported upstream 4.08--4.14 range.
    ;; Unicode 13 width data is shipped upstream: no uucp dependency is needed.
    (native-inputs (list ocaml-cppo))
    (propagated-inputs (list ocaml-uutf ocaml-lwt))
    (home-page "https://github.com/pqwy/notty")
    (synopsis "Declarative terminal graphics library for OCaml")
    (description
     "Notty describes terminal displays as composable Unicode images.  This
package includes its pure layout and input-codec core, Unix terminal I/O, Lwt
on Unix, and OCaml toplevel support, together with the upstream rendering
examples.  The source is pinned to a specific upstream revision and builds
without opam or network access.")
    (license license:isc)))
