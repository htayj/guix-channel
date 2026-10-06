;;; Source dependencies for Minttea's isolated OCaml closure.

(define-module (tay packages minttea-deps)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system dune)
  #:use-module (guix build-system ocaml)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages multiprecision)
  #:use-module (tay packages ocaml-minttea-toolchain)
  #:use-module (tay packages starred-i-m)
  #:export (with-minttea-dependencies %minttea-runtime-phases))

;; Hashes below are of the complete release archives, not unpacked trees.
(define (release-source url file hash)
  (origin
    (method url-fetch)
    (uri url)
    (file-name file)
    (sha256 (base32 hash))))

;; 0.33 supports OCaml 5.2's Parsetree; Guix's 0.28 does not.
(define ppxlib-source-package
  (package
    (inherit ocaml-ppxlib)
    (version "0.33.0")
    (source
     (release-source
      "https://github.com/ocaml-ppx/ppxlib/releases/download/0.33.0/ppxlib-0.33.0.tbz"
      "ppxlib-0.33.0.tbz"
      "0fn6sai70bhwp3j9y2qlmwd3hc8464q8lsdx3pi7afzja7slx97z"))
    ;; The release has updated expectations; old 0.28 textual patches must
    ;; not rewrite them.  Keep the full upstream runtest suite.
    (arguments (list #:tests? #t))
    (native-inputs
     (list ocaml-cinaps ocaml-re ocaml-stdio ocaml-base))
    (license license:expat)))

(define ptime-source-package
  (package
    (inherit ocaml-ptime)
    (version "1.1.0")
    (source
     (release-source
      "https://erratique.ch/software/ptime/releases/ptime-1.1.0.tbz"
      "ptime-1.1.0.tbz"
      "1c9y07vnvllfprf0z1vqf6fr73qxw7hj6h1k5ig109zvaiab3xfb"))
    ;; 1.1's pkg.ml builds the OS clock without the obsolete js_of_ocaml
    ;; option.  Its three upstream tests are built and run by Topkg.
    (arguments
     (list #:build-flags #~(list "build" "--tests" "true")
           #:phases #~(modify-phases %standard-phases
                        (delete 'configure))))
    (propagated-inputs '())
    (license license:isc)))

(define uri-source-package
  (package
    (inherit ocaml-uri)
    (version "4.4.0")
    (source
     (release-source
      "https://github.com/mirage/ocaml-uri/releases/download/v4.4.0/uri-4.4.0.tbz"
      "uri-4.4.0.tbz"
      "1i6ygbqnn6wf6cp015jfkw5biv3899p4rdy7kkjn28fdympazayd"))
    (native-inputs (list ocaml-ounit2 ocaml-ppx-sexp-conv))
    (license license:isc)))

(define qcheck-source-package
  (package
    (inherit ocaml-qcheck)
    (version "0.21.3")
    (source
     (release-source
      "https://codeload.github.com/c-cube/qcheck/tar.gz/refs/tags/v0.21.3"
      "qcheck-0.21.3.tar.gz"
      "1ar416qlrb2qrnlm7vw7lzg860nrg9vw8p3rnx16xy8ryj6z5pix"))
    ;; Build all source-defined libraries, including the OUnit and Alcotest
    ;; integrations and the PPX, and keep their upstream test aliases.
    (arguments (list #:tests? #t))
    (native-inputs '())
    (propagated-inputs (list ocaml-alcotest ocaml-ounit2 ocaml-ppxlib))
    ;; LICENSE at this pin is BSD-2, not Guix 0.20's LGPL metadata.
    (license license:bsd-2)))

(define mdx-source-package
  (package
    (inherit ocaml-mdx)
    (version "2.4.1")
    (source
     (release-source
      "https://github.com/realworldocaml/mdx/releases/download/2.4.1/mdx-2.4.1.tbz"
      "mdx-2.4.1.tbz"
      "04xg282dv9xrpcvav4fckrsxnfwmai1l73f9405fsgamrj8wqh0s"))
    (arguments (list #:package "mdx" #:tests? #t))
    ;; This release vendors the matching odoc-parser; a second external
    ;; parser/odoc installation would introduce unrelated compiler APIs.
    (propagated-inputs
     (list ocaml-fmt ocaml-astring ocaml-logs ocaml-cmdliner ocaml-re
           ocaml-result ocaml-version ocaml-csexp ocaml-camlp-streams))
    (native-inputs (list ocaml-cppo ocaml-lwt ocaml-alcotest))
    (license license:isc)))

(define cmdliner-source-package
  (package
    (inherit ocaml-cmdliner)
    (version "1.3.0")
    (source
     (release-source
      "https://erratique.ch/software/cmdliner/releases/cmdliner-1.3.0.tbz"
      "cmdliner-1.3.0.tbz"
      "1fwc2rj6xfyihhkx4cn7zs227a74rardl262m2kzch5lfgsq10cf"))
    (inputs '())
    (native-inputs '())
    ;; Preserve the bootstrap Makefile policy: it has no test target.
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-cmdliner)
       ((#:make-flags _ '())
        #~(list (string-append "PREFIX=" #$output)
                (string-append "LIBDIR=" #$output
                               "/lib/ocaml/site-lib/cmdliner")))
       ((#:phases _)
        #~(modify-phases %standard-phases
            (delete 'configure)
            (add-after 'install 'install-documentation
              (lambda* (#:key make-flags #:allow-other-keys)
                (apply invoke "make" "install-doc" make-flags)))))))
    (license license:isc)))

;; Keep Jane Street's v0.16 cross-pins together.  Base v0.15's C stubs do
;; not support OCaml 5, and Sexplib v0.16 requires Sexplib0/Parsexp v0.16.
(define (janestreet-v0.16-source project hash)
  (release-source
   (string-append "https://ocaml.janestreet.com/ocaml-core/v0.16/files/"
                  project "-v0.16.0.tar.gz")
   (string-append project "-v0.16.0.tar.gz") hash))

(define sexplib0-source-package
  (package
    (inherit ocaml-sexplib0)
    (version "0.16.0")
    (source (janestreet-v0.16-source
             "sexplib0" "07bhj2akd6i33h11qin4wns9qnjicf871yzji7vi4i8rd1ja5nw6"))))

(define base-source-package
  (package
    (inherit ocaml-base)
    (version "0.16.3")
    (source
     (release-source
      "https://github.com/janestreet/base/archive/refs/tags/v0.16.3.tar.gz"
      "base-v0.16.3.tar.gz"
      "0g7rrwnd3sb4pcpnvq7hc7dd7rg1gh0axxdhqwjh60dxw81ybycv"))
    (native-inputs (list dune-configurator))
    (properties '())))

(define stdio-source-package
  (package
    (inherit ocaml-stdio)
    (version "0.16.0")
    (source (janestreet-v0.16-source
             "stdio" "0gm7nci6bi3gfc5q3m8rv4138ip6rhidih3fihvwajk1a1cvgw31"))))

(define parsexp-source-package
  (package
    (inherit ocaml-parsexp)
    (version "0.16.0")
    (source (janestreet-v0.16-source
             "parsexp" "04jywn2q3c4z2xla59qvr0i0bq3zv1p2ghzrp1fai4b1iqn5gqmn"))
    (inputs '())
    (propagated-inputs (list ocaml-base ocaml-sexplib0))))

(define ppx-sexp-conv-source-package
  (package
    (inherit ocaml-ppx-sexp-conv)
    (version "0.16.0")
    (source (janestreet-v0.16-source
             "ppx_sexp_conv" "0390j76ins0hwxn4735ci2j2irgdphfszgq8hi151prvnfivgg21"))
    (propagated-inputs (list ocaml-base ocaml-sexplib0 ocaml-ppxlib))
    (license license:expat)))

(define ppx-deriving-yojson-source-package
  (package
    (inherit ocaml-ppx-deriving-yojson)
    (version "3.9.1")
    (source
     (release-source
      "https://github.com/ocaml-ppx/ppx_deriving_yojson/releases/download/v3.9.1/ppx_deriving_yojson-3.9.1.tbz"
      "ppx_deriving_yojson-3.9.1.tbz"
      "0kag2417b3qygmc7kab2h5i27xkw539adwjki125f7rqpg3zfgka"))
    (native-inputs (list ocaml-ounit2))
    (license license:expat)))

;; 5.2.1's upstream tests are explicitly restricted below OCaml 5 in opam.
;; Use a release whose test suite supports this compiler, rather than dropping
;; the tests inherited by Guix's package (the source pin is defined below).
(define ppx-deriving-source-package
  (package
    (inherit ocaml-ppx-deriving)
    (version "6.0.3")
    (source
     (release-source
      "https://github.com/ocaml-ppx/ppx_deriving/releases/download/v6.0.3/ppx_deriving-6.0.3.tbz"
      "ppx_deriving-6.0.3.tbz"
      "0vaar4csqm8l219497k4bcxj3311za5s843qm44irq6569xsjjip"))
    (propagated-inputs (list ocaml-ppx-derivers ocaml-ppxlib))
    (license license:expat)))

(define (janestreet-source-package old project hash propagated)
  (package
    (inherit old)
    (version "0.16.0")
    (source (janestreet-v0.16-source project hash))
    (propagated-inputs propagated)
    (license license:expat)))

(define ppx-here-source-package
  (janestreet-source-package ocaml-ppx-here "ppx_here"
   "1w3kjbnp16ypipfracpb0gr7imk4wbnks7j1ngx0dhq04nwri097"
   (list ocaml-base ocaml-ppxlib)))
(define ppx-cold-source-package
  (janestreet-source-package ocaml-ppx-cold "ppx_cold"
   "1nm4d8p26mg3yf9vaaw5jspdi4mq2q6bwd5fv13a46jh7dcdnfw0"
   (list ocaml-base ocaml-ppxlib)))
(define ppx-let-source-package
  (janestreet-source-package ocaml-ppx-let "ppx_let"
   "0p76id6wlkjpnypfxmzdx073c2hgf6k0q6vqps3sxw7l00qznjig"
   (list ocaml-base ocaml-ppx-here ocaml-ppxlib)))
(define ppx-compare-source-package
  (janestreet-source-package ocaml-ppx-compare "ppx_compare"
   "1ai6iz2g8sla5jbqr7n34aw7s5n0cbcqp6w7d95nrpk25s2xvhbs"
   (list ocaml-base ocaml-ppxlib)))
(define ppx-enumerate-source-package
  (janestreet-source-package ocaml-ppx-enumerate "ppx_enumerate"
   "0lwrxx02shaskn810qba4a7592nd8lkxflgd90ywdi4sdmfn6ci8"
   (list ocaml-base ocaml-ppxlib)))
(define ppx-hash-source-package
  (janestreet-source-package ocaml-ppx-hash "ppx_hash"
   "1rdn2fzsqjdzx53smn20afxix8c8vav2z03gagyqn9xrnx32a0cv"
   (list ocaml-base ocaml-ppx-compare ocaml-ppx-sexp-conv ocaml-ppxlib)))
(define ppx-optcomp-source-package
  (janestreet-source-package ocaml-ppx-optcomp "ppx_optcomp"
   "18hbb7nmvrlnsmr6i2l9pyv2mav1jsbjicf6wkydlxak9840kclr"
   (list ocaml-base ocaml-stdio ocaml-ppxlib)))
(define ppx-globalize-source-package
  (package
    (inherit ocaml-ppx-cold)
    (name "ocaml-ppx-globalize")
    (version "0.16.0")
    (source (janestreet-v0.16-source
             "ppx_globalize" "06s9mfcknbjvsjfgklhizd508zq0vz559lvxn5s2j4b5nysdfs4h"))
    (propagated-inputs (list ocaml-base ocaml-ppxlib))
    (synopsis "Globalize values across local allocation scopes")
    (description "Ppx_globalize provides a syntax extension for globalizing values.")
    (home-page "https://github.com/janestreet/ppx_globalize")))
(define ppx-base-source-package
  (janestreet-source-package ocaml-ppx-base "ppx_base"
   "18v9jlykzf9vmf4c817mxl6d3gqy6mx31ksnzai64cix2mimg0v4"
   (list ocaml-ppx-cold ocaml-ppx-compare ocaml-ppx-enumerate
         ppx-globalize-source-package ocaml-ppx-hash ocaml-ppx-sexp-conv ocaml-ppxlib)))
(define ppx-assert-source-package
  (janestreet-source-package ocaml-ppx-assert "ppx_assert"
   "1m9zi1ljdv31afgmi7cfbbgsvl6xhbvg4n69298ivsr730j6xp2p"
   (list ocaml-base ocaml-ppx-cold ocaml-ppx-compare ocaml-ppx-here
         ocaml-ppx-sexp-conv ocaml-ppxlib)))
(define jst-config-source-package
  (janestreet-source-package ocaml-jst-config "jst-config"
   "0nyr2hyff4s0qq66095p223w9705msdlzmcs17f8r1l2hmnxbsps"
   (list ocaml-base ocaml-ppx-assert dune-configurator)))
(define jane-street-headers-source-package
  (janestreet-source-package ocaml-jane-street-headers "jane-street-headers"
   "1sk0scvi657c0jvmdcgi2nmd4aa8qq0vc3q121xli5dlxsgl0vc7" '()))
(define time-now-source-package
  (janestreet-source-package ocaml-time-now "time_now"
   "18f3dpafs7pj07wnymyhrpp6kzhx1jya5r3ni6xyvap6vsm8982z"
   (list ocaml-base ocaml-jane-street-headers ocaml-jst-config ocaml-ppx-base
         ocaml-ppx-optcomp)))
(define ppx-inline-test-source-package
  (janestreet-source-package ocaml-ppx-inline-test "ppx_inline_test"
   "0rxwpykb37rfldhdzcxfdv5zlr46nfp10jhgx78qg1cqzvw64r11"
   (list ocaml-base ocaml-time-now ocaml-ppxlib)))
(define ppx-expect-source-package
  (janestreet-source-package ocaml-ppx-expect "ppx_expect"
   "0g229sjb2ps1pz3gb21d0xfyg3xja44l91d6ma57axnmw855lyg0"
   (list ocaml-base ocaml-ppx-here ocaml-ppx-inline-test ocaml-stdio
         ocaml-ppxlib ocaml-re)))

(define cstruct-source-package
  (package
    (inherit ocaml-cstruct)
    (version "6.2.0")
    (source
     (release-source
      "https://github.com/mirage/ocaml-cstruct/releases/download/v6.2.0/cstruct-6.2.0.tbz"
      "cstruct-6.2.0.tbz" "0qiyy1h7qsy90hdl01qdsg4rv61f3d5sp8wg2i4q63jqj8rhfy4s"))))

;; Gen's upstream library depends on bytes/seq, not the documentation tool
;; Odoc.  Its dune configurator is a build input and its tests also use OUnit2.
(define gen-source-package
  (package
    (inherit ocaml-gen)
    (propagated-inputs (list ocaml-seq))
    (native-inputs (list dune-configurator ocaml-qtest ocaml-qcheck ocaml-ounit2))))

(define qtest-source-package
  (package
    (inherit ocaml-qtest)
    ;; The inline runner asks for ounit2, not the legacy OUnit alias.
    (propagated-inputs (list ocaml-ounit2 ocaml-qcheck))))

(define compiler-libs-source-package
  (package
    (inherit ocaml-compiler-libs)
    ;; v0.12.4 is constrained below OCaml 5.2.  v0.17 supports 5.2's APIs.
    (version "0.17.0")
    (source
     (release-source
      "https://github.com/janestreet/ocaml-compiler-libs/archive/refs/tags/v0.17.0.tar.gz"
      "ocaml-compiler-libs-v0.17.0.tar.gz"
      "1iydfnys6f5j5ynmxx6ci3lycls1pdkwg9yvgpjrkdhx6pbl95lv"))))

(define calendar-source-package
  (package
    (inherit ocaml-calendar)
    (version "3.0.0")
    (source
     (release-source
      "https://github.com/ocaml-community/calendar/archive/refs/tags/v3.0.0.tar.gz"
      "calendar-v3.0.0.tar.gz"
      "17kfa0gfrv0d5f6zksg7yah8ly5pwyzws483mwvqiwfkc8bx617a"))
    (build-system dune-build-system)
    (arguments (list #:package "calendar" #:tests? #t))
    (native-inputs (list ocaml-alcotest))
    (inputs '())
    (propagated-inputs (list ocaml-re))
    ;; LICENSE includes the OCaml linking exception.
    (license license:lgpl2.1+)))

(define alcotest-source-package
  (package
    (inherit ocaml-alcotest)
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-alcotest)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'fix-test-format 'normalize-multiline-stacktraces
              (lambda _
                ;; OCaml 5.2 reports a source span as "lines N-M".  Extend
                ;; the existing frame normalizer, not expected test output.
                (substitute* "test/e2e/strip_randomness.ml"
                  (("str \", line \"")
                   "str \", line\" ^^ opt (char 's') ^^ char ' '")
                  (("\\^\\^ str \", characters \"")
                   "^^ opt (char '-' ^^ rep1 digit) ^^ str \", characters \""))))))))))

(define zarith-source-package
  (package
    (inherit ocaml-zarith)
    ;; zarith.cmxa records -lgmp for every downstream native link.  GMP
    ;; therefore belongs in the propagated compilation closure, not inputs.
    (inputs '())
    (propagated-inputs (list gmp))))

(define stringext-source-package
  (package
    (inherit ocaml-stringext)
    (native-inputs (list ocaml-qcheck ocaml-ounit2))
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-stringext)
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'use-canonical-ounit2-library
              (lambda _
                ;; Both test sources use OUnit2, including QCheck's adapter.
                (substitute* "lib_test/dune"
                  (("stringext oUnit qcheck")
                   "stringext ounit2 qcheck"))))))))))

(define eqaf-source-package
  (package
    (inherit ocaml-eqaf)
    ;; The upstream tests call Fmt directly, independent of Alcotest's inputs.
    (native-inputs (list ocaml-alcotest ocaml-crowbar ocaml-fmt))))

;; One rewriter covers implicit compilers and every explicit transitive
;; dependency.  The toolchain right-hand sides are already compiler-matched.
;; Our upgraded libraries are traversed too, so PPXs and test binaries cannot
;; accidentally import Guix's OCaml 4.14 artefacts.
(define with-minttea-dependencies
  (package-input-rewriting
   (append %minttea-toolchain-replacements
           (list (cons ocaml-ppxlib ppxlib-source-package)
                 (cons ocaml-ptime ptime-source-package)
                 (cons ocaml-uri uri-source-package)
                 (cons ocaml-qcheck qcheck-source-package)
                 (cons ocaml-mdx mdx-source-package)
                 (cons ocaml-cmdliner cmdliner-source-package)
                 (cons ocaml-sexplib0 sexplib0-source-package)
                 (cons ocaml-base base-source-package)
                 (cons ocaml-stdio stdio-source-package)
                 (cons ocaml-parsexp parsexp-source-package)
                 (cons ocaml-ppx-sexp-conv ppx-sexp-conv-source-package)
                 (cons ocaml-ppx-deriving-yojson ppx-deriving-yojson-source-package)
                 (cons ocaml-ppx-deriving ppx-deriving-source-package)
                 (cons ocaml-ppx-here ppx-here-source-package)
                 (cons ocaml-ppx-cold ppx-cold-source-package)
                 (cons ocaml-ppx-compare ppx-compare-source-package)
                 (cons ocaml-ppx-enumerate ppx-enumerate-source-package)
                 (cons ocaml-ppx-hash ppx-hash-source-package)
                 (cons ocaml-ppx-optcomp ppx-optcomp-source-package)
                 (cons ocaml-ppx-base ppx-base-source-package)
                 (cons ocaml-ppx-assert ppx-assert-source-package)
                 (cons ocaml-jst-config jst-config-source-package)
                 (cons ocaml-jane-street-headers jane-street-headers-source-package)
                 (cons ocaml-time-now time-now-source-package)
                 (cons ocaml-ppx-inline-test ppx-inline-test-source-package)
                 (cons ocaml-ppx-expect ppx-expect-source-package)
                 (cons ocaml-cstruct cstruct-source-package)
                 (cons ocaml-gen gen-source-package)
                 (cons ocaml-qtest qtest-source-package)
                 (cons ocaml-compiler-libs compiler-libs-source-package)
                 (cons ocaml-calendar calendar-source-package)
                 (cons ocaml-ppx-let ppx-let-source-package)
                 (cons ocaml-alcotest alcotest-source-package)
                 (cons ocaml-zarith zarith-source-package)
                 (cons ocaml-stringext stringext-source-package)
                 (cons ocaml-eqaf eqaf-source-package)))
   #:recursive? #t))

(define-public ocaml-ppxlib-minttea
  (with-minttea-dependencies ppxlib-source-package))
(define-public ocaml-ptime-minttea
  (with-minttea-dependencies ptime-source-package))
(define-public ocaml-uri-minttea
  (with-minttea-dependencies uri-source-package))
(define-public ocaml-qcheck-minttea
  (with-minttea-dependencies qcheck-source-package))
(define-public ocaml-mdx-minttea
  (with-minttea-dependencies mdx-source-package))

(define %minttea-runtime-phases
  #~(modify-phases %standard-phases
      (add-before 'build 'set-writable-build-home
        (lambda _
          (let ((home (string-append (getcwd) "/.build-home")))
            (mkdir-p home)
            (setenv "HOME" home)
            (setenv "XDG_CACHE_HOME" (string-append home "/.cache")))))
      (add-after 'unpack 'exclude-compiler-context-metadata
        (lambda _
          (use-modules (ice-9 rdelim))
          ;; Compare semantic PPX output and all errors, not the internal
          ;; compiler context fields added by different compiler releases.
          (for-each
           (lambda (file)
             (let ((lines
                    (call-with-input-file file
                      (lambda (port)
                        (let loop ((skip? #f) (result '()))
                          (let ((line (read-line port)))
                            (cond
                             ((eof-object? line) (reverse result))
                             ((string-contains line "[@@@ocaml.ppx.context")
                              (loop #t result))
                             (skip?
                              (loop (not (string-contains line "}]")) result))
                             (else (loop #f (cons line result))))))))))
               (call-with-output-file file
                 (lambda (port)
                   (for-each (lambda (line) (format port "~a\n" line)) lines))))
             (substitute* file
               (("dune describe pp ([^\n]+)" _ target)
                (string-append "dune describe pp " target
                               " | sed '/^\\[@@@ocaml.ppx.context$/,/^[[:space:]]*}]$/d'"))))
           (filter file-exists?
                   '("bytestring/ppx.t/run.t" "config/ppx.t/run.t")))))))

;; All new Dune packages retain the build system's upstream runtest phase.
;; PACKAGE selects source-defined subpackages (not a pruned test alias).
(define* (minttea-library name version source home synopsis description
                          license propagated native #:optional package-name)
  (with-minttea-dependencies
   (package
     (name name)
     (version version)
     (source source)
     (build-system dune-build-system)
     (arguments (list #:package package-name #:tests? #t
                      #:phases %minttea-runtime-phases))
     (propagated-inputs propagated)
     (native-inputs native)
     (home-page home)
     (synopsis synopsis)
     (description description)
     (license license))))

;; Guix's private cstruct-unix alias points at the cstruct-only package;
;; build the real source-defined library needed by X509/TLS test suites.
(define-public ocaml-cstruct-unix-minttea
  (with-minttea-dependencies
   (package
     (inherit cstruct-source-package)
     (name "ocaml-cstruct-unix-minttea")
     (arguments (list #:package "cstruct-unix" #:tests? #t))
     (propagated-inputs (list ocaml-cstruct))
     (native-inputs '())
     (synopsis "Unix I/O for Cstruct byte arrays"))))

(define-public ocaml-randomconv-minttea
  (minttea-library
   "ocaml-randomconv-minttea" "0.2.0"
   (release-source
    "https://github.com/hannesm/randomconv/releases/download/v0.2.0/randomconv-0.2.0.tbz"
    "randomconv-0.2.0.tbz"
    "1sk3bdfz1nlqrivp8vy3slpbhqw858gc5zwjix3a8hg30zgiw5xk")
   "https://github.com/hannesm/randomconv"
   "Conversion of random bytes to native numbers"
   "Randomconv converts random byte vectors to native OCaml numeric values."
   license:isc '() '() "randomconv"))

;; Mirage 0.11 and TLS 0.17 tests use the old Cstruct callback API.  Keep
;; that test-only dependency isolated instead of weakening their constraints
;; or confusing it with Riot's string-based Randomconv 0.2 runtime API.
(define randomconv-for-crypto-tests
  (minttea-library
   "ocaml-randomconv-crypto-tests-minttea" "0.1.3"
   (release-source
    "https://github.com/hannesm/randomconv/releases/download/v0.1.3/randomconv-v0.1.3.tbz"
    "randomconv-v0.1.3.tbz"
    "1iv3r0s5kqxs893b0d55f0r62k777haiahfkkvvfbqwgqsm6la4v")
   "https://github.com/hannesm/randomconv"
   "Conversion of random Cstruct vectors to numbers"
   "This Randomconv release supplies the Cstruct API used by cryptography tests."
   license:isc (list ocaml-cstruct) '() "randomconv"))

(define mirage-crypto-source
  (release-source
   "https://github.com/mirage/mirage-crypto/releases/download/v0.11.3/mirage-crypto-0.11.3.tbz"
   "mirage-crypto-0.11.3.tbz"
   "1ccmbmx478glnsw93cn07816ggfg0ws9yi72qzmhbncw2vx31ddz"))

(define-public ocaml-mirage-crypto-minttea
  (minttea-library
   "ocaml-mirage-crypto-minttea" "0.11.3" mirage-crypto-source
   "https://github.com/mirage/mirage-crypto"
   "Symmetric cryptography for OCaml"
   "Mirage Crypto provides symmetric ciphers and cryptographic hashes."
   license:isc (list ocaml-cstruct ocaml-eqaf)
   (list dune-configurator ocaml-ounit2) "mirage-crypto"))

(define-public ocaml-mirage-crypto-rng-minttea
  (minttea-library
   "ocaml-mirage-crypto-rng-minttea" "0.11.3" mirage-crypto-source
   "https://github.com/mirage/mirage-crypto"
   "Cryptographic random number generation for OCaml"
   "This library implements cryptographic random generators and Unix entropy collection."
   license:isc
   (list ocaml-mirage-crypto-minttea ocaml-cstruct ocaml-logs ocaml-duration)
   (list dune-configurator ocaml-ounit2 randomconv-for-crypto-tests)
   "mirage-crypto-rng"))

(define-public ocaml-mirage-crypto-pk-minttea
  (minttea-library
   "ocaml-mirage-crypto-pk-minttea" "0.11.3" mirage-crypto-source
   "https://github.com/mirage/mirage-crypto"
   "Public-key cryptography for OCaml"
   "Mirage Crypto PK supplies RSA, DSA and Diffie-Hellman implementations."
   license:isc
   (list ocaml-mirage-crypto-minttea ocaml-mirage-crypto-rng-minttea
         ocaml-cstruct ocaml-zarith ocaml-sexplib0 ocaml-eqaf)
   (list ocaml-ounit2 randomconv-for-crypto-tests) "mirage-crypto-pk"))

(define-public ocaml-mirage-crypto-ec-minttea
  (minttea-library
   "ocaml-mirage-crypto-ec-minttea" "0.11.3" mirage-crypto-source
   "https://github.com/mirage/mirage-crypto"
   "Elliptic-curve cryptography for OCaml"
   "Mirage Crypto EC provides elliptic-curve signatures and key agreement."
   (list license:expat license:isc)
   (list ocaml-mirage-crypto-minttea ocaml-mirage-crypto-rng-minttea
         ocaml-cstruct ocaml-eqaf)
   (list dune-configurator ocaml-alcotest ocaml-hex ocaml-ppx-deriving
         ocaml-ppx-deriving-yojson ocaml-yojson) "mirage-crypto-ec"))

(define-public ocaml-gmap-minttea
  (minttea-library
   "ocaml-gmap-minttea" "0.3.0"
   (release-source
    "https://github.com/hannesm/gmap/releases/download/0.3.0/gmap-0.3.0.tbz"
    "gmap-0.3.0.tbz" "073wa0lrb0jj706j87cwzf1a8d1ff14100mnrjs8z3xc4ri9xp84")
   "https://github.com/hannesm/gmap" "Heterogeneous maps for OCaml"
   "Gmap implements persistent heterogeneous maps with typed keys."
   license:isc '() (list ocaml-alcotest ocaml-fmt) "gmap"))

(define-public ocaml-asn1-combinators-minttea
  (minttea-library
   "ocaml-asn1-combinators-minttea" "0.2.6"
   (release-source
    "https://github.com/mirleft/ocaml-asn1-combinators/releases/download/v0.2.6/asn1-combinators-v0.2.6.tbz"
    "asn1-combinators-v0.2.6.tbz"
    "148s3clqws2nmzwhvlgy0b3nnvq2xbw1qb3mcc865vv9i06xwah1")
   "https://github.com/mirleft/ocaml-asn1-combinators"
   "ASN.1 parsing and serialization combinators"
   "ASN.1 Combinators provides typed grammars and DER/BER codecs."
   license:isc (list ocaml-cstruct ocaml-zarith ocaml-ptime-minttea)
   (list ocaml-alcotest) "asn1-combinators"))

(define-public ocaml-hkdf-minttea
  (minttea-library
   "ocaml-hkdf-minttea" "1.0.4"
   (release-source
    "https://github.com/hannesm/ocaml-hkdf/releases/download/v1.0.4/hkdf-v1.0.4.tbz"
    "hkdf-v1.0.4.tbz" "0nzx6vzbc1hh6vx1ly8df4b16lgps6zjpp9mjycsnnn49bddc9mr")
   "https://github.com/hannesm/ocaml-hkdf" "HMAC-based key derivation"
   "HKDF implements the extract-and-expand key derivation function."
   license:bsd-2 (list ocaml-cstruct ocaml-mirage-crypto-minttea)
   (list ocaml-alcotest) "hkdf"))

(define-public ocaml-pbkdf-minttea
  (minttea-library
   "ocaml-pbkdf-minttea" "1.2.0"
   (release-source
    "https://github.com/abeaumont/ocaml-pbkdf/archive/1.2.0.tar.gz"
    "pbkdf-1.2.0.tar.gz" "0mvlh5iq4wqdfylxaq64sycxihp5jkjdgrrr9wmrlgk2yrsn3d3v")
   "https://github.com/abeaumont/ocaml-pbkdf" "Password-based key derivation"
   "PBKDF implements password-based cryptographic key derivation."
   license:bsd-2 (list ocaml-cstruct ocaml-mirage-crypto-minttea)
   (list ocaml-alcotest) "pbkdf"))

(define-public ocaml-x509-minttea
  (minttea-library
   "ocaml-x509-minttea" "0.16.5"
   (release-source
    "https://github.com/mirleft/ocaml-x509/releases/download/v0.16.5/x509-0.16.5.tbz"
    "x509-0.16.5.tbz" "16fdii9sffdbrbzzhdfk677rs77h01ffw2v9nagn2zx3zsjjb7hl")
   "https://github.com/mirleft/ocaml-x509" "X.509 certificates for OCaml"
   "X509 parses, generates and validates X.509 certificates and keys."
   license:bsd-2
   (list ocaml-cstruct ocaml-asn1-combinators-minttea ocaml-ptime-minttea
         ocaml-base64 ocaml-mirage-crypto-minttea ocaml-mirage-crypto-rng-minttea
         ocaml-mirage-crypto-pk-minttea ocaml-mirage-crypto-ec-minttea
         ocaml-fmt ocaml-gmap-minttea ocaml-domain-name ocaml-logs
         ocaml-pbkdf-minttea ocaml-ipaddr)
   (list ocaml-alcotest ocaml-cstruct-unix-minttea) "x509"))

(define-public ocaml-tls-minttea
  (minttea-library
   "ocaml-tls-minttea" "0.17.3"
   (release-source
    "https://github.com/mirleft/ocaml-tls/releases/download/v0.17.3/tls-0.17.3.tbz"
    "tls-0.17.3.tbz" "1m1ia0nsk08bb4a5qryxnd3l2ivpw0xacn34fdkw7l8fsg6xxra7")
   "https://github.com/mirleft/ocaml-tls" "Transport Layer Security for OCaml"
   "TLS implements the Transport Layer Security protocol in OCaml."
   license:bsd-2
   (list ocaml-cstruct ocaml-mirage-crypto-minttea ocaml-mirage-crypto-rng-minttea
         ocaml-mirage-crypto-pk-minttea ocaml-mirage-crypto-ec-minttea
         ocaml-x509-minttea ocaml-domain-name ocaml-fmt ocaml-hkdf-minttea
         ocaml-logs ocaml-ipaddr)
   (list ocaml-ounit2 ocaml-alcotest ocaml-cmdliner randomconv-for-crypto-tests
         ocaml-cstruct-unix-minttea)
   "tls"))

(define-public ocaml-tty-minttea
  (minttea-library
   "ocaml-tty-minttea" "0.0.2"
   (release-source
    "https://github.com/leostera/tty/releases/download/0.0.2/tty-0.0.2.tbz"
    "tty-0.0.2.tbz" "0jsik0yswv3npg5kvrjaq1bzh3nrcck3kvs1l32rqpfhxxizkq3r")
   "https://github.com/leostera/tty" "Terminal access for OCaml"
   "TTY provides terminal profiles, colors and UTF-8 keyboard input."
   license:expat (list ocaml-uutf) '() "tty"))

(define-public ocaml-colors-minttea
  (minttea-library
   "ocaml-colors-minttea" "0.0.1"
   (release-source
    "https://github.com/leostera/colors/releases/download/0.0.1/colors-0.0.1.tbz"
    "colors-0.0.1.tbz" "0ilqrazs7g5w4xbq3a8nr2rac16ilr1alg62qagphml3ags673bx")
   "https://github.com/leostera/colors" "Color manipulation for OCaml"
   "Colors provides color blending and color-space conversions."
   license:expat '() (list ocaml-mdx-minttea) "colors"))

;; Config and Bytestring's PPXs use Spices, so this independent source-defined
;; package breaks a build-time cycle with Minttea's Riot dependency.  It uses
;; the same unchanged ledger origin as the final three-library Minttea build.
(define-public ocaml-spices-minttea
  (package
    (inherit
     (minttea-library
      "ocaml-spices-minttea" "0.0.3-1.40ee449"
      (package-source leostera-minttea-source)
      "https://github.com/leostera/minttea" "Declarative terminal styling"
      "Spices provides declarative styles and rendering for terminal interfaces."
      license:expat
      (list ocaml-tty-minttea ocaml-colors-minttea ocaml-uuseg)
      (list ocaml-mdx-minttea) "spices"))
    (arguments
     (list #:package "spices" #:tests? #t
           #:phases
           #~(modify-phases #$%minttea-runtime-phases
               (add-after 'unpack 'declare-unicode-string-library
                 (lambda _
                   ;; Root/Leaves MDX aliases belong to those packages, not
                   ;; the independent Spices bootstrap.  Full Minttea builds
                   ;; still run both aliases without -p selection.
                   (substitute* "dune"
                     (("\\(mdx") "(mdx (package minttea)"))
                   (substitute* "leaves/dune"
                     (("\\(mdx") "(mdx (package leaves)"))
                   (substitute* "spices/dune"
                     (("str uuseg") "str uuseg uuseg.string")))))))))

(define-public ocaml-config-minttea
  (minttea-library
   "ocaml-config-minttea" "0.0.1"
   (release-source
    "https://github.com/ocaml-sys/config.ml/releases/download/0.0.1/config-0.0.1.tbz"
    "config-0.0.1.tbz" "1751i8h4lnbra8hz09ins0szzp0mdpiqxkdsby7khcrhk693qk9k")
   "https://github.com/ocaml-sys/config.ml" "Conditional compilation PPX"
   "Config provides a PPX for platform-dependent conditional compilation."
   license:expat (list ocaml-ppxlib-minttea ocaml-sedlex ocaml-spices-minttea)
   '() "config"))

(define-public ocaml-libc-minttea
  (package
    (inherit
     (minttea-library
      "ocaml-libc-minttea" "0.0.1"
      (release-source
       "https://github.com/ocaml-sys/libc.ml/releases/download/0.0.1/libc-0.0.1.tbz"
       "libc-0.0.1.tbz" "1n0h5i09wg57yjfkma5xvjazv8pvjnb2v6mgls7almxvlxhpk73v")
      "https://github.com/ocaml-sys/libc.ml" "OCaml platform system definitions"
      "Libc provides definitions and bindings for platform system libraries."
      license:expat '() (list ocaml-config-minttea) "libc"))
    (arguments
     (list #:package "libc" #:tests? #t
           #:phases
           #~(modify-phases #$%minttea-runtime-phases
               (add-after 'unpack 'avoid-system-libc-archive-collision
                 (lambda _
                   ;; OCaml forwards include directories as linker -L paths.
                   ;; A libc.a here would shadow GCC's implicit system -lc.
                   ;; Keep the public Libc module and its original prefixed
                   ;; helper namespace; let Dune generate consistent archive
                   ;; names, META and cmxa metadata from the new library name.
                   (let ((helpers
                          '("Types" "Linux_like"
                            "Libc_aarch64_apple_darwin"
                            "Libc_aarch64_linux_gnu"
                            "Libc_aarch64_linux_musl"
                            "Libc_x86_64_linux_gnu"
                            "Libc_x86_64_linux_musl"
                            "Libc_x86_64_unknown_freebsd")))
                     (for-each
                      (lambda (module)
                        (rename-file
                         (string-append "libc/" (string-downcase module) ".ml")
                         (string-append "libc/libc__" module ".ml")))
                      helpers)
                     (for-each
                      (lambda (module)
                        (substitute* (find-files "libc" "\\.ml$")
                          (((string-append "(^|[^[:alnum:]_])" module
                                           "([^[:alnum:]_]|$)")
                            _ before after)
                           (string-append before "Libc__" module after))))
                      helpers)
                     ;; Original wrapped Dune installs these prefixed helper
                     ;; CMIs because public Libc types refer to them.
                     (substitute* "libc/dune"
                       ((" \\(public_name libc\\)")
                        " (name ocaml_libc)\n (public_name libc)\n (wrapped false)"))))))))))

(define riot-0.0.8-source
  (release-source
   "https://github.com/riot-ml/riot/releases/download/0.0.8/riot-0.0.8.tbz"
   "riot-0.0.8.tbz" "1qd5k5df7517i9gxyj8nvz5qlx87vl026dyl9w4b7xfvkp7q7j2a"))

(define-public ocaml-rio-minttea
  (minttea-library
   "ocaml-rio-minttea" "0.0.8" riot-0.0.8-source
   "https://github.com/riot-ml/riot" "Composable read and write streams"
   "Rio implements uniform, composable interfaces for reading and writing."
   license:expat (list ocaml-cstruct) '() "rio"))

(define-public ocaml-bytestring-minttea
  (minttea-library
   "ocaml-bytestring-minttea" "0.0.8" riot-0.0.8-source
   "https://github.com/riot-ml/riot" "Byte strings and byte-pattern PPX"
   "Bytestring provides byte strings and a pattern-matching PPX."
   license:expat
   (list ocaml-rio-minttea ocaml-cstruct ocaml-uutf ocaml-ppxlib-minttea
         ocaml-sedlex ocaml-spices-minttea)
   (list ocaml-qcheck-minttea) "bytestring"))

(define-public ocaml-gluon-minttea
  (package
    (inherit
     (minttea-library
      "ocaml-gluon-minttea" "0.0.9"
      (release-source
       "https://github.com/riot-ml/gluon/releases/download/0.0.9/gluon-0.0.9.tbz"
       "gluon-0.0.9.tbz" "0ajrfspqijhy2322cdwcaw6hm2npcl9a71m03b9hxm0qi4z44qk1")
      "https://github.com/riot-ml/gluon" "Low-level asynchronous system I/O"
      "Gluon provides low-level I/O and platform event polling for Riot."
      license:expat
      (list ocaml-bytestring-minttea ocaml-rio-minttea ocaml-uri-minttea
            ocaml-libc-minttea)
      (list ocaml-config-minttea) "gluon"))
    (arguments
     (list #:package "gluon" #:tests? #t
           #:phases
           #~(modify-phases #$%minttea-runtime-phases
               (add-after 'unpack 'apply-upstream-epoll-cast
                 (lambda _
                   ;; Upstream PR #2, merged after 0.0.9, fixes GCC 14's
                   ;; -Wint-conversion error without changing the pointer value.
                   (substitute* "gluon/sys/unix/gluon_unix_epoll.c"
                     (("event\\.data\\.u64 = ocaml_value;")
                      "event.data.u64 = (intptr_t) ocaml_value;")))))))))

(define-public ocaml-telemetry-minttea
  (minttea-library
   "ocaml-telemetry-minttea" "0.0.1"
   (release-source
    "https://github.com/leostera/telemetry/releases/download/0.0.1/telemetry-0.0.1.tbz"
    "telemetry-0.0.1.tbz" "0vx745ckh8k8v57cycimbahacwnfisfwhpq3nm0k5ny55z6gniv0")
   "https://github.com/leostera/telemetry" "OCaml telemetry event dispatch"
   "Telemetry provides extensible event dispatch for instrumentation."
   license:expat '() '() "telemetry"))

(define-public ocaml-castore-minttea
  (minttea-library
   "ocaml-castore-minttea" "0.0.2"
   (release-source
    "https://github.com/leostera/castore/releases/download/0.0.2/castore-0.0.2.tbz"
    "castore-0.0.2.tbz" "0glb4l0i1fy8lv8y9z6bfy9lawkdmsdhbg584awbcczphn83j7cd")
   "https://github.com/leostera/castore" "Embedded certificate authority store"
   "Castore provides the release's embedded certificate authority store."
   license:expat '()
   (list ocaml-mdx-minttea ocaml-x509-minttea ocaml-cstruct) "castore"))

(define-public ocaml-riot-minttea
  (package
    (inherit
     (minttea-library
      "ocaml-riot-minttea" "0.0.9"
      (release-source
       "https://github.com/riot-ml/riot/releases/download/0.0.9/riot-0.0.9.tbz"
       "riot-0.0.9.tbz" "12ma2d5l59hakh0xq991wf9ymzkkxdx5qzxvk117jn15mjvgadgh")
      "https://github.com/riot-ml/riot" "Actor-model multicore OCaml scheduler"
      "Riot provides Erlang-style lightweight processes and message passing."
      license:expat
      (list ocaml-bytestring-minttea ocaml-gluon-minttea ocaml-rio-minttea
            ocaml-telemetry-minttea ocaml-mtime ocaml-ptime-minttea
            ocaml-mirage-crypto-minttea ocaml-mirage-crypto-rng-minttea
            ocaml-randomconv-minttea ocaml-tls-minttea ocaml-uri-minttea)
      (list ocaml-mdx-minttea ocaml-config-minttea ocaml-castore-minttea
            ocaml-x509-minttea) "riot"))
    (arguments
     (list #:package "riot" #:tests? #t
           #:phases
           #~(modify-phases #$%minttea-runtime-phases
               (add-after 'unpack 'guard-concurrent-process-exit
                 (lambda _
                   ;; A cross-domain exit may land after step_process reads
                   ;; Runnable.  Check and CAS the same state snapshot so the
                   ;; scheduler cannot resurrect a terminal process or crash.
                   ;; substitute* operates line by line; replace this complete
                   ;; definition through a source-line transform instead.
                   (use-modules (ice-9 rdelim))
                   (let* ((file "riot/runtime/core/process.ml")
                          (lines
                           (call-with-input-file file
                             (lambda (port)
                               (let loop ((skip? #f) (result '()))
                                 (let ((line (read-line port)))
                                   (cond
                                    ((eof-object? line) (reverse result))
                                    ((string=? line "let rec mark_as_running t =")
                                     (loop #t
                                      (cons
                                       (string-append
                                        "let rec mark_as_running t =\n"
                                        "  let old_state = Atomic.get t.state in\n"
                                        "  match old_state with\n"
                                        "  | Exited _ | Finalized -> false\n"
                                        "  | _ ->\n"
                                        "      if Atomic.compare_and_set t.state old_state Running then (\n"
                                        "        Log.trace (fun f -> f \"Process %a: marked as running\" Pid.pp t.pid);\n"
                                        "        true)\n"
                                        "      else mark_as_running t") result)))
                                    (skip?
                                     (loop (not (string=? line "  else mark_as_running t")) result))
                                    (else (loop #f (cons line result))))))))))
                     (call-with-output-file file
                       (lambda (port)
                         (for-each (lambda (line) (format port "~a\n" line)) lines))))
                   (substitute* "riot/runtime/scheduler/scheduler.ml"
                     (("      Process.mark_as_running proc;")
                      (string-append
                       "      if not (Process.mark_as_running proc) then (\n"
                       "        if Process.is_exited proc && not (Process.is_finalized proc) then\n"
                       "          add_to_run_queue sch proc)\n"
                       "      else ("))
                     (("    with Terminated_while_running reason ->")
                      "      )\n    with Terminated_while_running reason ->"))))
               (add-after 'unpack 'use-local-uri-endpoint
                 (lambda _
                   ;; URI parsing and TCP connection remain real; the public
                   ;; DNS/HTTP endpoint is not the behavior under test.
                   (substitute* "test/net_addr_uri_test.ml"
                     (("  let addr =")
                      (string-append
                       "  let socket, port = Port_finder.next_open_port () in\n"
                       "  let _server = spawn (fun () ->\n"
                       "    let conn, _ = Net.Tcp_listener.accept socket |> Result.get_ok in\n"
                       "    Net.Tcp_stream.close conn) in\n"
                       "  let addr ="))
                     (("Uri.of_string \"http://ocaml.org\"")
                      "Uri.of_string (Printf.sprintf \"http://127.0.0.1:%d\" port)"))))
               (add-before 'check 'enable-loopback-tests
                 (lambda _
                   ;; false is upstream's enabled condition.  All socket tests
                   ;; connect to loopback and TLS uses bundled cert/key fixtures.
                   (setenv "OPAM_REPO_CI" "false"))))))))
