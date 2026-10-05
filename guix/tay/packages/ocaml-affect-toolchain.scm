;;; Compiler-matched source toolchain for Affect; not a global OCaml upgrade.

(define-module (tay packages ocaml-affect-toolchain)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ocaml))

;; Affect requires OCaml >= 5.5.0.  This stable release was published on
;; 2026-06-19, not a development snapshot.  Keep Guix's source-bootstrap,
;; compiler test suite and search paths, without changing other OCaml users.
;; Use the complete INRIA distribution: GitHub archives omit tests and the
;; manual, so they cannot satisfy the inherited compiler check phase.
;; The release LICENSE is LGPL 2.1 with the OCaml linking exception (the
;; inherited compiler's older QPL metadata is no longer applicable).
(define-public ocaml-affect
  (package
    (inherit ocaml-5.4)
    (name "ocaml-affect")
    (version "5.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://caml.inria.fr/pub/distrib/ocaml-5.5/"
                           "ocaml-" version ".tar.gz"))
       (sha256
        (base32 "0xx4fc2xi6mxx1y8sc38vfk8iddsfp2xp3mgs1f36hysmg13g58s"))))
    ;; Enable the upstream-supported compressed compilation artefacts rather
    ;; than silently dropping this feature when libzstd is not discovered.
    (inputs
     (cons `("zstd:lib" ,zstd "lib") (package-inputs ocaml-5.4)))
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-5.4)
       ((#:configure-flags flags)
        #~(cons "--with-zstd" #$(sexp->gexp flags)))))
    (license license:lgpl2.1)))

;; Findlib is a GNU-build-system package with an explicit native compiler.
;; Match that compiler independently of the OCaml build system's defaults.
;; Released Findlib 1.9.8 is constrained below OCaml 5.5 by opam.  Pin the
;; upstream OCaml-5.5 adaptation in PR #122, including topfind generation
;; and relative ld.conf handling, rather than hiding its loader warnings.
;; https://github.com/ocaml/ocamlfind/pull/122
(define-public ocaml-findlib-affect
  (package
    (inherit ocaml-findlib)
    (name "ocaml-findlib-affect")
    (version (git-version "1.9.8" "1"
                          "1faecd4016c615e1d8806643c8e4eb3d08dcdf97"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/ocaml/ocamlfind/tar.gz/"
             "1faecd4016c615e1d8806643c8e4eb3d08dcdf97"))
       (file-name (string-append "findlib-" version ".tar.gz"))
       (sha256
        (base32 "124dkqsqdvsymvlzbqgidlrq0grhb6w6bnnrwb59c1dw0f08pzbz"))))
    (native-inputs
     (modify-inputs (package-native-inputs ocaml-findlib)
       (delete "ocaml")
       (append ocaml-affect)))))

;; As in the Miou toolchain, use upstream 0.16.1, which includes PR #325:
;; https://github.com/ocaml/ocamlbuild/pull/325
;; Its my_std.mli declares Digest.channel as a value rather than the obsolete
;; caml_md5_chan external, matching Digest's interface since OCaml 5.2.
;; This fixes compilation; it does not suppress the compatibility failure.
(define-public ocamlbuild-affect
  (package
    (inherit ocamlbuild)
    (name "ocamlbuild-affect")
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
    ;; Preserve Guix's install recipe and existing test policy (its test
    ;; failures depend on compiler diagnostic formatting).
    (arguments
     (substitute-keyword-arguments (package-arguments ocamlbuild)
       ((#:ocaml _ #f) ocaml-affect)
       ((#:findlib _ #f) ocaml-findlib-affect)))))

(define-public ocaml-topkg-affect
  (package
    (inherit ocaml-topkg)
    (name "ocaml-topkg-affect")
    (version "1.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://erratique.ch/software/topkg/releases/"
                           "topkg-" version ".tbz"))
       (sha256
        (base32 "1z7n2abmabc018b60ck41qqmfg9yxn3cj8lgf9f1p8nfr4nhdni0"))))
    (native-inputs
     (modify-inputs (package-native-inputs ocaml-topkg)
       (delete "ocamlbuild")
       (append ocamlbuild-affect)))
    ;; The upstream library has had no Result dependency since 1.0.1.
    ;; topkg-care is a separate package, not part of Affect's build closure.
    (propagated-inputs '())
    (arguments
     (substitute-keyword-arguments
         (strip-keyword-arguments '(#:tests?)
                                  (package-arguments ocaml-topkg))
       ((#:ocaml _ #f) ocaml-affect)
       ((#:findlib _ #f) ocaml-findlib-affect)
       ((#:build-flags _ '())
        #~(list "build" "--pkg-name" "topkg" "--dev-pkg" "false"
                "--tests" "true"))))
    (description
     "Topkg is a packager for distributing OCaml software.  It provides an API
to describe the files a package installs in a given build configuration and to
specify information about the package's distribution, creation and publication
procedures.")))

;; Cmdliner 2 builds directly with its source bootstrap Makefile.  It no
;; longer needs Result or ocamlbuild, and build.ml sorts the source order
;; itself.  Install the tool, completions and documentation as well as the
;; complete bytecode/native/dynlink library used by Affect's CLI component.
(define-public ocaml-cmdliner-affect
  (package
    (inherit ocaml-cmdliner)
    (name "ocaml-cmdliner-affect")
    (version "2.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://erratique.ch/software/cmdliner/releases/"
                           "cmdliner-" version ".tbz"))
       (sha256
        (base32 "1dnn42hhmndlgk32m3yr3r1i0ic348l9iwbqh53lrxglvv8kif85"))))
    (inputs '())
    (native-inputs '())
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-cmdliner)
       ((#:ocaml _ #f) ocaml-affect)
       ((#:findlib _ #f) ocaml-findlib-affect)
       ;; Retain Guix's test policy: this bootstrap Makefile has no test
       ;; target.  Upstream's development tests require its separate B0 setup.
       ((#:make-flags _ '())
        #~(list (string-append "PREFIX=" #$output)
                (string-append "LIBDIR=" #$output
                               "/lib/ocaml/site-lib/cmdliner")
                (string-append "DOCDIR=" #$output "/share/doc/cmdliner")
                (string-append "MANDIR=" #$output "/share/man")))
       ((#:phases _)
        #~(modify-phases %standard-phases
            (delete 'configure)
            (add-after 'install 'install-documentation
              (lambda* (#:key make-flags #:allow-other-keys)
                (apply invoke "make" "install-doc" make-flags)))))))
    (description
     "Cmdliner is a module for the declarative definition of command line
interfaces.  It provides a simple and compositional mechanism to convert
command line arguments to OCaml values and pass them to your functions.  The
module automatically handles syntax errors, help messages and UNIX man page
generation.  It supports programs with single or multiple commands and respects
most of the POSIX and GNU conventions.")
    ;; The 2.x release switched from the older BSD license to ISC.
    (license license:isc)))
