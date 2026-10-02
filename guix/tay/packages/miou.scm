;;; GNU Guix package for robur-coop/miou.

(define-module (tay packages miou)
  #:use-module (guix build-system)
  #:use-module (guix build-system dune)
  #:use-module ((guix build-system ocaml) #:prefix ocaml:)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix monads)
  #:use-module (guix packages)
  #:use-module (guix store)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages ocaml)
  #:use-module (guix utils)
  #:use-module (tay packages starred-n-r))

;; The pinned Miou requires OCaml >= 5.1 and Dune >= 3.13.  Guix's default
;; compiler is 4.14, while its existing 5.4 package is 5.4.1.  Rewrite the
;; complete dependency graph, including implicit build-system inputs: changing
;; only #:ocaml would leave findlib, dune-configurator and test libraries built
;; against the incompatible default compiler.  No OCaml-5.0 variant is used:
;; that compiler is below Miou's minimum version.
(define miou-ocaml ocaml-5.4)

;; Guix's ocamlbuild 0.14.2 predates the OCaml 5.2 Digest signature change.
;; Upstream 0.14.3 introduced the fix; 0.16.1 retains it and removes the
;; incompatible local external declaration.  Reuse Guix's build recipe.
(define miou-ocamlbuild
  ((package-input-rewriting (list (cons ocaml miou-ocaml)))
   (package
     (inherit ocamlbuild)
     (version "0.16.1")
     (source
      (origin
        (method git-fetch)
        (uri (git-reference
              (url "https://github.com/ocaml/ocamlbuild")
              (commit "131ba63a1b96d00f3986c8187677c8af61d20a08")))
        (file-name (git-file-name "ocamlbuild" "0.16.1"))
        (sha256
         (base32 "148r0imzsalr7c3zqncrl4ji29wpb5ls5zkqxy6xnh9q99gxb4a6")))))))

(define with-miou-toolchain
  (package-input-rewriting
   (list (cons ocaml miou-ocaml)
         (cons ocamlbuild miou-ocamlbuild))))

;; Astring's phases complete, but the pinned Guile 3.0.9 builder aborts in
;; atexit cleanup after separate-from-pid1 forks.  Guile 3.0.10 fixed signal
;; handling around primitive-fork; use Guix's existing 3.0.11 only for this
;; affected dependency, retaining all build phases and validation.
;; The OCaml build-system's #:guile is already a lowered derivation, unlike
;; gnu-build-system's package argument.  Lower it inside the store monad at
;; the bag's build boundary rather than embedding a package in builder args.
(define miou-astring-build-system
  (build-system
    (inherit ocaml:ocaml-build-system)
    (lower
     (lambda args
       (let ((lowered (apply ocaml:lower args)))
         (and lowered
              (bag
                (inherit lowered)
                (build
                 (lambda* (name inputs #:key system #:allow-other-keys
                                #:rest arguments)
                   (mlet %store-monad
                       ((guile (package->derivation guile-3.0-latest system
                                                    #:graft? #f)))
                     (apply ocaml:ocaml-build name inputs
                            (ensure-keyword-arguments
                             arguments (list #:guile guile)))))))))))))

(define miou-astring
  (with-miou-toolchain
   (package
     (inherit ocaml-astring)
     (build-system miou-astring-build-system))))

(define with-miou-base
  (package-input-rewriting
   (list (cons ocaml miou-ocaml)
         (cons ocamlbuild miou-ocamlbuild)
         (cons ocaml-astring miou-astring))))

;; Backport the upstream normalizer's support for OCaml's multi-line source
;; spans.  Leave the behavioral e2e expected results unchanged.
;; https://github.com/mirage/alcotest/blob/master/test/e2e/strip_randomness.ml
(define miou-alcotest
  (with-miou-base
   (package
     (inherit ocaml-alcotest)
     (arguments
      (substitute-keyword-arguments (package-arguments ocaml-alcotest)
        ((#:phases phases)
         #~(modify-phases #$(sexp->gexp phases)
             (add-after 'unpack 'normalize-multi-line-backtraces
               (lambda _
                 (substitute* "test/e2e/strip_randomness.ml"
                   (("\\^\\^ str \", line \"")
                    "^^ str \", line\" ^^ opt (char 's') ^^ char ' '")
                   (("\\^\\^ str \", characters \"")
                    "^^ opt (char '-' ^^ rep1 digit) ^^ str \", characters \"")))))))))))

(define with-miou-ocaml
  (package-input-rewriting
   (list (cons ocaml miou-ocaml)
         (cons ocamlbuild miou-ocamlbuild)
         (cons ocaml-astring miou-astring)
         (cons ocaml-alcotest miou-alcotest))))

(define miou-findlib
  (with-miou-ocaml ocaml-findlib))

;; Dscheck >= 0.4 is required by Miou's upstream synchronization tests.
;; Release 0.6 removes the old containers/oseq/tsort dependency chain and uses
;; the OCaml >= 5.2 standard library instead.  Keep its own upstream tests.
(define dscheck
  (package
    (name "ocaml-dscheck-miou")
    (version "0.6.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ocaml-multicore/dscheck")
             (commit "45406eca007f391dc9764b949f23b0cfed343a9b")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0fyllhya1ls55w7fhrzncg732rbv2qr3l3yw2lsn07gs5zl5v2b0"))))
    (build-system dune-build-system)
    (arguments
     (list #:package "dscheck"
           #:phases
           #~(modify-phases %standard-phases
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (invoke "dune" "runtest" "--release")))))))
    (native-inputs (list ocaml-alcotest ocaml-cmdliner))
    (home-page "https://github.com/ocaml-multicore/dscheck")
    (synopsis "Deterministic concurrency testing for OCaml atomics")
    (description
     "Dscheck explores interleavings of atomic operations to test concurrent
OCaml data structures.  It is used by Miou's upstream synchronization tests.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define-public miou
  (with-miou-ocaml
   (package
     (name "miou")
     (version (git-version "0.8.0" "1"
                           "5fcb7e65b648f5c3d22d01d0ebe70c321042f09d"))
     ;; Reuse the channel's immutable codeload origin, including its verified
     ;; hash, rather than introducing another representation of the same pin.
     (source (package-source robur-coop-miou-source))
     (build-system dune-build-system)
     (arguments
      (list
       #:package "miou"
       #:phases
       #~(modify-phases %standard-phases
           (replace 'check
             (lambda* (#:key tests? #:allow-other-keys)
               (when tests?
                 ;; The unfiltered recursive alias includes test_core,
                 ;; test_unix (three worker domains), and test/sync/test_sync.
                 (invoke "dune" "runtest" "--release"))))
           (add-after 'install 'install-upstream-notices
             (lambda _
               (let ((documentation
                      (string-append #$output "/share/doc/miou")))
                 (install-file "LICENSE.md" documentation)
                 (install-file "README.md" documentation)
                 (install-file "CHANGES.md" documentation)))))))
     ;; Audit the actual Dune targets at the pin, not only the stale opam
     ;; with-test list: the tests link fmt and dscheck.  Digestif is confined
     ;; to the standalone merkle example; happy-eyeballs, dns[-client], hxd,
     ;; mirage-crypto-rng, ipaddr and mtime have no Dune targets at this pin.
     ;; Dune-configurator is needed only for compiling the Unix C probes.
     ;; All six public libraries are installed by @install -p miou, including
     ;; bitv, Unix poll/select C stubs and the runtime_events integration.
     (native-inputs (list dune-configurator ocaml-fmt dscheck))
     (home-page "https://github.com/robur-coop/miou")
     (synopsis "Composable concurrency primitives for OCaml")
     (description
      "Miou provides an OCaml 5 scheduler with structured concurrent and
parallel tasks, promises, synchronization primitives and cancellation.  This
package includes the core scheduler, backoff, synchronization and bit-vector
libraries, the Unix event loop with its native stubs, and runtime-event tracing.")
     (license license:expat))))
