;;; Compiler-matched source toolchain for Minttea; not a global OCaml upgrade.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages ocaml-minttea-toolchain)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ocaml)
  #:use-module (tay packages auxiliary))

;; Riot 0.0.9 requires OCaml >= 5.1 and < 5.3.  Use the latest stable 5.2
;; release without widening that constraint or altering other OCaml users.
;; The complete INRIA distribution contains the inherited compiler tests and
;; manual, unlike GitHub archives.  Keep all inherited compiler check phases.
;; Backport upstream e3919fef's OSEC-2026-01 / CVE-2026-28364 fix, including
;; its fuzzy Marshal regression, rather than shipping vulnerable vanilla 5.2.1.
;; The runtime's malloc-buffer input C API now requires the upstream length
;; argument.  No in-tree callers use that API in the official 5.2.1 sources.
(define-public ocaml-minttea
  (package
    (inherit ocaml-5.0)
    (name "ocaml-minttea")
    (version "5.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://caml.inria.fr/pub/distrib/ocaml-5.2/"
                           "ocaml-" version ".tar.gz"))
       (sha256
        (base32 "1l2c0isbkqw7gykf8wg4sa8if3kc1681x8dqwp0a55qsjn8803rd"))
       (patches
        (list (search-tay-package-file
               "patches/ocaml-minttea-marshal-bounds.patch")))
       (patch-flags '("-p1" "--fuzz=0"))))
    ;; Preserve support for compressed marshaled data and compilation artefacts.
    (inputs
     (cons `("zstd:lib" ,zstd "lib") (package-inputs ocaml-5.0)))
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-5.0)
       ((#:configure-flags flags)
        #~(cons "--with-zstd" #$(sexp->gexp flags)))))
    ;; The release LICENSE uses LGPL 2.1 with the OCaml linking exception,
    ;; not the inherited old compiler's QPL/LGPL metadata.
    (license license:lgpl2.1)))

;; Installed Guix's Findlib 1.9.5 is constrained below OCaml 5 by opam.
;; Stable 1.9.8 supports 5.2; it needs no OCaml-5.5 development adaptation.
;; This GNU-build-system recipe has an explicit native compiler, so match it
;; independently of implicit OCaml-build-system inputs.
(define-public ocaml-findlib-minttea
  (package
    (inherit ocaml-findlib)
    (name "ocaml-findlib-minttea")
    (version "1.9.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/ocaml/ocamlfind/tar.gz/refs/tags/"
             "findlib-" version))
       (file-name (string-append "findlib-" version ".tar.gz"))
       (sha256
        (base32 "1783rrlqfjgz0gx4iihkbl3i1qwlipwg7wwsg837zxmbrhsrk2fn"))))
    (native-inputs
     (modify-inputs (package-native-inputs ocaml-findlib)
       (delete "ocaml")
       (append ocaml-minttea)))))

;; Ocamlbuild 0.16.1 includes upstream PR #325's OCaml-5.2 Digest interface
;; fix.  Keep the inherited install recipe and test policy; do not hide the
;; obsolete caml_md5_chan declaration with compiler-warning suppression.
(define-public ocamlbuild-minttea
  (package
    (inherit ocamlbuild)
    (name "ocamlbuild-minttea")
    (version "0.16.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/ocaml/ocamlbuild/tar.gz/"
             "131ba63a1b96d00f3986c8187677c8af61d20a08"))
       (file-name (string-append "ocamlbuild-" version ".tar.gz"))
       (sha256
        (base32 "1jhrga6v51pfyyli4z3hcrvr3hk0mkxbdp3y22f4dcks09jcahjy"))))
    (arguments
     (substitute-keyword-arguments (package-arguments ocamlbuild)
       ((#:ocaml _ #f) ocaml-minttea)
       ((#:findlib _ #f) ocaml-findlib-minttea)))))

(define %minttea-compiler-replacements
  (list (cons ocaml ocaml-minttea)
        (cons ocaml-findlib ocaml-findlib-minttea)
        (cons ocamlbuild ocamlbuild-minttea)))

;; Match each replacement RHS before using it in a larger rewrite: Guix's
;; deep rewrite visits implicit build-system inputs but does not recursively
;; rewrite newly substituted package objects by default.  Dune 3.19.1 is
;; sufficient for Riot's >= 3.12 constraint; preserve its bootstrap recipe.
(define-public dune-bootstrap-minttea
  ((package-input-rewriting %minttea-compiler-replacements)
   (package
     (inherit dune-bootstrap)
     (name "dune-bootstrap-minttea"))))

(define %minttea-bootstrap-replacements
  (append %minttea-compiler-replacements
          (list (cons dune-bootstrap dune-bootstrap-minttea)
                (cons dune dune-bootstrap-minttea))))

(define-public dune-configurator-minttea
  ((package-input-rewriting %minttea-bootstrap-replacements)
   (package
     (inherit dune-configurator)
     (name "dune-configurator-minttea"))))

(define-public dune-minttea
  (package
    (inherit dune-bootstrap-minttea)
    (name "dune-minttea")
    (propagated-inputs (list dune-configurator-minttea))
    ;; Like Guix's full dune, expose it; only the bootstrap stays hidden.
    (properties '())))

;; Shared contract for the Minttea dependency closure.  Extend this alist with
;; already compiler-matched dependency replacements, then apply one deep
;; package-input-rewriting to each root; do not mix unrelated toolchains.
(define-public %minttea-toolchain-replacements
  (append %minttea-compiler-replacements
          (list (cons dune-bootstrap dune-bootstrap-minttea)
                (cons dune-configurator dune-configurator-minttea)
                (cons dune dune-minttea))))

(define-public with-minttea-toolchain
  (package-input-rewriting %minttea-toolchain-replacements))
