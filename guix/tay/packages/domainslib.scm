;;; Native OCaml task pools and their complete native test closure.

(define-module (tay packages domainslib)
  #:use-module (guix build-system dune)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml)
  #:use-module (tay packages miou)
  #:use-module (tay packages starred-n-r)
  #:use-module (srfi srfi-13))

;; Reuse the published compiler, findlib, ocamlbuild, Astring and Alcotest
;; graph, including implicit Dune build-system inputs.  No second ABI closure.
(define with-native-ocaml (@@ (tay packages miou) with-miou-ocaml))
(define native-dscheck (@@ (tay packages miou) dscheck))

(define (multicore-release name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/ocaml-multicore/" name
                        "/releases/download/" version "/" name "-" version ".tbz"))
    (sha256 (base32 hash))))

;; Each new Dune dependency retains its complete native package test alias.
;; -p selects upstream packages, never hand-picked test executables.
(define (native-dune-arguments package-name)
  (list #:package package-name
        #:phases
        #~(modify-phases %standard-phases
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (invoke "dune" "runtest" "--release")))))))


;; Dune build/runtest -p takes commas; dune install takes separate positional
;; package names.  Guix's single-package installer cannot pass that distinction.
(define (native-multi-package-arguments packages)
  (list #:package (string-join packages ",")
        #:phases
        #~(modify-phases %standard-phases
            (replace 'install
              (lambda* (#:key outputs #:allow-other-keys)
                (let ((out (assoc-ref outputs "out")))
                  (apply invoke "dune" "install" "--prefix" out "--libdir"
                         (string-append out "/lib/ocaml/site-lib")
                         '#$packages)))))))
(define native-domain-shims
  (package
    (name "ocaml-domain-shims-domainslib")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://gitlab.com/gasche/domain-shims/-/archive/0.1.0/domain-shims-0.1.0.tar.gz")
       (sha256
        (base32 "0cad63qyfzn0nhf8b80yaw974q4zy1jahwd44rmaawpsj4ap2rq8"))))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "domain_shims"))
    (home-page "https://gitlab.com/gasche/domain-shims")
    (synopsis "OCaml domain compatibility library")
    (description
     "Domain shims exposes the native OCaml 5 Domain module and provides a
compatible sequential implementation for older compilers.  This variant uses
native OCaml domains, not the sequential compatibility implementation.")
    (properties '((hidden? . #t)))
    ;; LICENSE covers the MIT implementation and the copied LGPL interface.
    (license (list license:expat license:lgpl2.1))))

(define native-thread-table
  (package
    (name "ocaml-thread-table-domainslib")
    (version "1.0.0")
    (source (multicore-release "thread-table" version
                              "1p8xp3ry1flzc39kir3ip9vwm4b0q366kajb5i2gjzarcf2di354"))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "thread-table"))
    (native-inputs (list ocaml-alcotest))
    (home-page "https://github.com/ocaml-multicore/thread-table")
    (synopsis "Lock-free thread-local integer hash table for OCaml")
    (description
     "Thread-table is a thread-safe integer-keyed hash table for associating
thread-specific state with threads within a domain.  Lookups need no
synchronization.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-backoff
  (package
    (name "ocaml-backoff-domainslib")
    (version "0.1.1")
    (source (multicore-release "backoff" version
                              "00wzmhvkg5d6jgqjqkjfgd2dh7wbwgfa97c7al5brc97n88s7gh0"))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "backoff"))
    (native-inputs (list ocaml-alcotest native-domain-shims))
    (home-page "https://github.com/ocaml-multicore/backoff")
    (synopsis "Exponential backoff for OCaml atomic operations")
    (description
     "Backoff supplies an exponential backoff mechanism for retry loops in
concurrent OCaml algorithms, reducing contention between domains.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-multicore-magic
  (package
    (name "ocaml-multicore-magic-domainslib")
    (version "2.3.1")
    (source (multicore-release "multicore-magic" version
                              "0pqr3hak7xdhbsmra95sff1k7nipza0x6jmhh5r1h4lzvj5j1mq1"))
    (build-system dune-build-system)
    ;; Install both native public libraries, including the Dscheck backend.
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'select-available-test-backends
            (lambda _
              ;; The upstream JS-only test is otherwise enabled on x86_64
              ;; even without a JS compiler.  Do not change either native
              ;; test or the native library: this closure has no JS backend.
              (substitute* "test/dune"
                (("\\(<> %\\{architecture\\} i386\\)")
                 "(and (<> %{architecture} i386) (<> %{bin-available:js_of_ocaml} false))"))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "dune" "runtest" "--release")))))))
    (propagated-inputs (list native-dscheck))
    (native-inputs (list ocaml-alcotest native-domain-shims))
    (home-page "https://github.com/ocaml-multicore/multicore-magic")
    (synopsis "Low-level native multicore utilities for OCaml")
    (description
     "Multicore-magic provides low-level utilities for concurrent OCaml
algorithms, including transparent atomic operations, padding and native runtime
support.  The package also installs the Dscheck atomic backend.  Both native
upstream tests run; JavaScript-backend tests require a separate JS compiler.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-yojson
  (package
    (inherit ocaml-yojson)
    (version "2.2.2")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/ocaml-community/yojson/releases/download/2.2.2/yojson-2.2.2.tbz")
       (sha256
        (base32 "15f5284wkc34q2vs2m6chzydns0ykik8wi7ns8x75m3rka6avgws"))))
    ;; Run all tests of the native yojson package.  yojson-five and
    ;; yojson-bench are separately published packages, not dependencies.
    (arguments (list #:package "yojson"))
    (properties '((hidden? . #t)))))

(define native-ocaml-version
  (package
    (inherit ocaml-version)
    (version "4.1.4")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/ocurrent/ocaml-version/tar.gz/37616057ce5a171b7ef54efe7adf3603accd5222")
       (file-name "ocaml-version-4.1.4.tar.gz")
       (sha256
        (base32 "0hpsy1plfjg5jivkfi1mf9rhpmrgrkrpgdylfn0pnkab1gm7302q"))))
    ;; The old 3.5 recipe disabled nonexistent tests; this release has tests.
    (arguments (native-dune-arguments "ocaml-version"))
    (native-inputs (list ocaml-alcotest))
    (properties '((hidden? . #t)))))

;; Guix's MDX 2.1 predates OCaml 5.4's compiler-libs interfaces.  Version
;; 2.5.1 supports 5.4; retain its full upstream tests, not old expected-text
;; substitutions from Guix's 2.1 recipe.
(define native-mdx
  (package
    (inherit ocaml-mdx)
    (version "2.5.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/realworldocaml/mdx/releases/download/2.5.1/mdx-2.5.1.tbz")
       (sha256
        (base32 "1xb3x1k8yfiwwwavvk3xvaqyysn2swp9s7d9z5pq190is46ri0nx"))))
    (arguments (native-dune-arguments "mdx"))
    (propagated-inputs
     (list ocaml-findlib ocaml-fmt ocaml-csexp ocaml-astring ocaml-logs
           ocaml-cmdliner ocaml-re native-ocaml-version ocaml-camlp-streams
           ocaml-result))
    (native-inputs (list ocaml-cppo ocaml-lwt ocaml-alcotest))
    (properties '((hidden? . #t)))))

(define native-domain-local-await
  (package
    (name "ocaml-domain-local-await-domainslib")
    (version "1.0.1")
    (source (multicore-release "domain-local-await" version
                              "0vzsrmj3xcmd74qqyz10p3d334ckfb78dp5jajqf41ybacy12li9"))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "domain-local-await"))
    (propagated-inputs (list native-thread-table))
    ;; README's MDX blocks require domain_shims and version-aware MDX.
    (native-inputs
     (list ocaml-alcotest native-domain-shims native-mdx native-ocaml-version))
    (home-page "https://github.com/ocaml-multicore/domain-local-await")
    (synopsis "Scheduler-independent blocking mechanism for OCaml")
    (description
     "Domain-local-await lets concurrent libraries suspend and resume execution
through a scheduler-provided blocking mechanism.  A default implementation
works with plain native domains and system threads.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-multicore-bench
  (package
    (name "ocaml-multicore-bench-domainslib")
    (version "0.1.7")
    (source (multicore-release "multicore-bench" version
                              "10swa6a2v31c4nbd5jfyjbzs2v24qnihrpl8hniiihlk5g57vfmy"))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "multicore-bench"))
    (propagated-inputs
     (list native-domain-local-await native-multicore-magic ocaml-mtime
           native-yojson native-domain-shims native-backoff))
    (native-inputs (list native-mdx))
    (home-page "https://github.com/ocaml-multicore/multicore-bench")
    (synopsis "Native multicore benchmark framework for OCaml")
    (description
     "Multicore-bench measures concurrent OCaml data structures and algorithms.
It supplies the native benchmark runner used by Saturn's upstream tests.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-qcheck
  (package
    (inherit ocaml-qcheck)
    (version "0.27")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/c-cube/qcheck/tar.gz/23b8258920398638c12a7d9182d902683996242d")
       (file-name "qcheck-0.27.tar.gz")
       (sha256
        (base32 "0ig46nwbzrjw8f81mr7aldmrra8y105ssrc6c4xpry7a5mb1xxmx"))))
    ;; Install and test the four public packages needed by the consumers.
    ;; The separately published ppx_deriving_qcheck compiler extension is
    ;; unrelated: this is complete package-specific, not monorepo coverage.
    (arguments (native-multi-package-arguments
                '("qcheck" "qcheck-core" "qcheck-alcotest" "qcheck-ounit")))
    (propagated-inputs (list ocaml-alcotest ocaml-ounit2))
    (native-inputs '())
    (properties '((hidden? . #t)))
    ;; QCheck changed from the old Guix recipe's LGPL to BSD-2-Clause.
    (license license:bsd-2)))

;; Keep the inherited Psq source and tests, but name its dependencies directly.
;; A second deep package rewrite would insert untransformed replacement inputs
;; during build-system lowering, after the compiler rewrite had already run.
(define native-psq
  (package
    (inherit ocaml-psq)
    (native-inputs (list native-qcheck ocaml-alcotest))
    (properties '((hidden? . #t)))))

(define native-mirage-clock
  (package
    (inherit ocaml-mirage-clock)
    ;; The existing source builds mirage-clock-unix and its portable test.
    ;; config/discover links dune.configurator; it is not an implicit input
    ;; of dune-build-system, so retain the source and add the actual tool.
    (native-inputs (list dune-configurator))
    (properties '((hidden? . #t)))))

(define native-multicoretests
  (package
    (name "ocaml-multicoretests-libraries-domainslib")
    (version "0.10")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/ocaml-multicore/multicoretests/tar.gz/refs/tags/0.10")
       (file-name "multicoretests-0.10.tar.gz")
       (sha256
        (base32 "1pajcph5d7xyzpx5p89b3x9qvxbfvyjjnpdvsskd9p9q2qg0gyn1"))))
    (build-system dune-build-system)
    ;; These two separately published packages provide every model-testing
    ;; library used by Domainslib, Saturn and Kcas, including native domains.
    ;; qcheck-lin and multicoretests are different, unneeded upstream packages.
    (arguments (native-multi-package-arguments
                '("qcheck-stm" "qcheck-multicoretests-util")))
    (propagated-inputs (list native-qcheck))
    (home-page "https://github.com/ocaml-multicore/multicoretests")
    (synopsis "State-machine property testing for native OCaml domains")
    (description
     "The QCheck state-machine libraries generate sequential, system-thread
and parallel-domain operations and compare observations against declarative
models.  This package includes the shared multicore test utilities and every
native QCheck STM library.")
    (properties '((hidden? . #t)))
    (license license:bsd-2)))

(define native-domain-local-timeout
  (package
    (name "ocaml-domain-local-timeout-domainslib")
    (version "1.0.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/ocaml-multicore/domain-local-timeout/tar.gz/70847fb897f52d7ede023058bb53be9e167f5e45")
       (file-name "domain-local-timeout-1.0.1.tar.gz")
       (sha256
        (base32 "1h34yyyq91gbsppsf1vb97xnfxg0r4pflwraa16k8hv10xkv54ww"))))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "domain-local-timeout"))
    (propagated-inputs (list native-psq ocaml-mtime native-thread-table))
    (native-inputs
     (list native-domain-local-await native-mdx ocaml-alcotest))
    (home-page "https://github.com/ocaml-multicore/domain-local-timeout")
    (synopsis "Scheduler-independent timeouts for OCaml")
    (description
     "Domain-local-timeout provides a timeout mechanism that concurrent
libraries can use independently of a particular scheduler.  It is used by
Kcas transactions and retains its native upstream tests.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-kcas
  (package
    (name "ocaml-kcas-domainslib")
    (version "0.7.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/ocaml-multicore/kcas/tar.gz/611ee84b9bc17e7eccc82ec29f461a7e63e68319")
       (file-name "kcas-0.7.0.tar.gz")
       (sha256
        (base32 "1xz958zncfjj775pvns5apg0q6d4msclk3i49gwhgp22lhkz7lga"))))
    (build-system dune-build-system)
    (arguments
     (substitute-keyword-arguments
         (native-multi-package-arguments '("kcas" "kcas_data"))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'ignore-opaque-location-renderings
              (lambda _
                (use-modules (ice-9 rdelim) (ice-9 regex)
                             (srfi srfi-1) (srfi srfi-13))
                ;; Execute every example and retain operation results.  Only
                ;; opaque location constructor output is compiler-dependent;
                ;; MDX's ellipsis matches its arbitrary multiline rendering.
                (for-each
                 (lambda (file)
                   (let ((lines
                          (call-with-input-file file
                            (lambda (port)
                              (let loop ((lines '()))
                                (let ((line (read-line port)))
                                  (if (eof-object? line)
                                      (reverse lines)
                                      (loop (cons line lines)))))))))
                     (call-with-output-file (string-append file ".tmp")
                       (lambda (port)
                         (let loop ((lines lines))
                           (unless (null? lines)
                             (let* ((line (car lines))
                                    (header (string-match
                                             "^([ ]*)val [^ ]+ : .*=" line)))
                               (if header
                                   (let ((padding (match:substring header 1)))
                                     (let collect ((rest (cdr lines))
                                                   (block (list line)))
                                       (if (and (pair? rest)
                                                (string-prefix?
                                                 (string-append padding " ")
                                                 (car rest)))
                                           (collect (cdr rest)
                                                    (cons (car rest) block))
                                           (begin
                                             (if (any
                                                  (lambda (line)
                                                    (string-contains
                                                     line "Kcas.Loc.Loc"))
                                                  block)
                                                 (format port "~a...~%" padding)
                                                 (for-each
                                                  (lambda (line)
                                                    (format port "~a~%" line))
                                                  (reverse block)))
                                             (loop rest)))))
                                   (begin
                                     (format port "~a~%" line)
                                     (loop (cdr lines)))))))))
                     (rename-file (string-append file ".tmp") file)))
                 '("README.md" "doc/scheduler-interop.md"
                   "src/kcas/kcas.mli"))))))))
    (propagated-inputs
     (list native-domain-local-await native-domain-local-timeout
           native-backoff native-multicore-magic))
    (native-inputs
     (list ocaml-alcotest native-domain-shims native-qcheck
           native-multicoretests native-mdx native-multicore-bench))
    (home-page "https://github.com/ocaml-multicore/kcas")
    (synopsis "Multi-word atomic transactions for OCaml")
    (description
     "Kcas provides lock-free multi-word compare-and-set transactions with
blocking and timeout support.  This package includes its transactional data
structures and runs both packages' complete native tests.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define native-saturn
  (package
    (name "ocaml-saturn-domainslib")
    (version "1.0.0")
    (source (multicore-release "saturn" version
                              "021a0yk4sjbjy998r0nc20gk1p2sxg29ay0l7zaym37r2dklz7id"))
    (build-system dune-build-system)
    (arguments (native-dune-arguments "saturn"))
    (propagated-inputs (list native-backoff native-multicore-magic))
    (native-inputs
     (list ocaml-alcotest native-domain-shims native-dscheck native-mdx
           native-multicore-bench native-qcheck native-multicoretests
           native-yojson))
    (home-page "https://github.com/ocaml-multicore/saturn")
    (synopsis "Concurrent native OCaml data structures")
    (description
     "Saturn supplies concurrent stacks, queues, hash tables, bags, skip lists
and work-stealing deques for native OCaml domains.  The package retains all
native upstream model-checking, property, state-machine, documentation and
benchmark tests.")
    (properties '((hidden? . #t)))
    (license license:isc)))

(define-public domainslib
  (with-native-ocaml
   (package
     (name "domainslib")
     (version (git-version "0.5.2" "1"
                           "2a884868ff69c13ecef8efecca9ba1102ff11a7f"))
     ;; Preserve the existing immutable source origin and verified snapshot.
     (source (package-source ocaml-multicore-domainslib-source))
     (build-system dune-build-system)
     (arguments
      (list
       #:package "domainslib"
       #:phases
       #~(modify-phases %standard-phases
           (replace 'check
             (lambda* (#:key tests? #:allow-other-keys)
               (when tests?
                 ;; Unfiltered recursive alias: integration, clock, model and
                 ;; property tests, byte/native backtraces and debug runtime.
                 (invoke "dune" "runtest" "--release"))))
           (add-after 'install 'install-upstream-notices
             (lambda _
               (let ((documentation
                      (string-append #$output "/share/doc/domainslib")))
                 (install-file "LICENSE.md" documentation)
                 (install-file "README.md" documentation)
                 (install-file "CHANGES.md" documentation)))))))
     (propagated-inputs (list native-saturn native-domain-local-await))
     ;; Mirage-clock's existing Guix recipe installs its Unix clock library.
     (native-inputs (list native-kcas native-mirage-clock native-qcheck
                          native-multicoretests))
     (home-page "https://github.com/ocaml-multicore/domainslib")
     (synopsis "Parallel task pools and channels for native OCaml")
     (description
      "Domainslib implements native multicore task pools, promises, parallel
loops, reductions, scans, searches and bounded or unbounded channels.  This
package uses the published OCaml 5.4.1 toolchain and runs the complete upstream
Dune test alias, including native integration and randomized model tests.")
     (license license:isc))))
