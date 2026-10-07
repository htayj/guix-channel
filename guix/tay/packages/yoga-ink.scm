;;; Source-built Yoga JavaScript binding for Ink.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages yoga-ink)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages emscripten-yoga)
  #:use-module (tay packages yoga-ink-npm-sources))

;; v3.2.1 is a lightweight tag pointing at this COMMIT, not its tree object
;; 119ccd5d49460bf6a0e94b5b5e27f7d379b082ff.  The canonical tag/commit APIs
;; were read on 2026-10-06.  Hashing the fetched checkout, without .git, gives
;; the same recursive NAR hash as Guix's native Yoga 3.2.1 source package.
(define %yoga-ink-commit "042f5013152eb81c1552dec945b88f7b95ca350f")

(define %yoga-ink-npm-helper
  (local-file (search-tay-package-file "files/yoga-ink-npm.py")))
(define %yoga-ink-build-helper
  (local-file (search-tay-package-file "files/yoga-ink-build.cjs")))

(define-public node-yoga-layout
  (package
    (name "node-yoga-layout")
    (version "3.2.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/facebook/yoga")
             (commit %yoga-ink-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "09g2kispng520mcaky87lkpj7k1lscsz2jyv05cjxzfrwwf4pfyb"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; No release npm archive or generated binary can seed this build.
            (for-each
             (lambda (directory)
               (when (file-exists? directory)
                 (delete-file-recursively directory)))
             '("javascript/binaries" "javascript/dist" "javascript/.emsdk"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 match))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (add-after 'unpack 'prepare-compiler-closure
            (lambda _
              (setenv "HOME" (string-append (getcwd) "/.build-home"))
              (mkdir-p (getenv "HOME"))
              (setenv "BROWSERSLIST_IGNORE_OLD_DATA" "true")
              (setenv "BROWSERSLIST_DISABLE_CACHE" "1")
              (call-with-output-file "yoga-npm-inputs.tsv"
                (lambda (port)
                  (for-each
                   (lambda (entry)
                     (format port "~a\t~a\t~a~%"
                             (car entry) (cadr entry) (caddr entry)))
                   '#$(map
                       (lambda (entry)
                         (list (car entry) (cdr entry)
                               (cdr (assoc (cdr entry)
                                           %yoga-ink-npm-sources))))
                       %yoga-ink-npm-layout))))
              (call-with-output-file "yoga-npm-notices.tsv"
                (lambda (port)
                  (for-each
                   (lambda (entry)
                     (format port "~a\t~a~%" (car entry) (cdr entry)))
                   '#$%yoga-ink-npm-license-supplements)))
              (invoke "python3" #$%yoga-ink-npm-helper
                      "yoga-npm-inputs.tsv" "javascript"
                      "compiler-notices" "yoga-npm-notices.tsv")
              (copy-file #$%yoga-ink-build-helper
                         "javascript/guix-build.cjs")))
          (replace 'configure
            (lambda _
              ;; This is emcmakeGenerateTask verbatim, with the store SDK in
              ;; place of installEmsdkTask's network downloader.  In particular
              ;; CMakeLists.txt and all upstream compile/link flags are intact.
              (with-directory-excursion "javascript"
                (invoke #$(file-append emscripten-yoga "/bin/emcmake")
                        "cmake" "-S" "." "-B" "build" "-G" "Ninja"))))
          (replace 'build
            (lambda* (#:key parallel-build? #:allow-other-keys)
              (with-directory-excursion "javascript"
                (invoke "cmake" "--build" "build"
                        "--parallel"
                        (number->string (if parallel-build?
                                            (parallel-job-count) 1)))
                ;; The release's enums.py-derived YGEnums.ts is already in
                ;; the pinned source tree and is compiled with every wrapper.
                ;; Upstream Babel dist config supplies .ts -> .js imports;
                ;; TS 5.0.4 emits the complete original declaration API.
                (invoke #$(file-append node-lts "/bin/node")
                        "guix-build.cjs"))))
          ;; Consumer contracts live in tests/yoga-ink-consumer.mjs; they are
          ;; neither staged into nor installed by the runtime package.
          (delete 'check)
          (replace 'install
            (lambda _
              (let ((destination
                     (string-append #$output "/lib/node_modules/yoga-layout"))
                    (doc (string-append #$output
                                        "/share/doc/node-yoga-layout")))
                (mkdir-p destination)
                (copy-recursively "javascript/dist"
                                  (string-append destination "/dist"))
                (copy-recursively "javascript/src"
                                  (string-append destination "/src"))
                (install-file "javascript/package.json" destination)
                (install-file "LICENSE" destination)
                (install-file "LICENSE" doc)
                (install-file "javascript/README.md" doc)
                (copy-recursively "compiler-notices"
                                  (string-append doc "/compiler-notices"))
                (call-with-output-file (string-append doc "/source-provenance.txt")
                  (lambda (port)
                    (format port
                            "Yoga release: v3.2.1~%Commit: ~a~%Tree: 119ccd5d49460bf6a0e94b5b5e27f7d379b082ff~%Recursive source SHA256: 09g2kispng520mcaky87lkpj7k1lscsz2jyv05cjxzfrwwf4pfyb~%Emscripten: 3.1.28, source-built~%Target: javascript/CMakeLists.txt, yoga-wasm-base64-esm~%Wrapper: upstream Babel dist config and TypeScript declarations~%No prebuilt Yoga WebAssembly input.~%"
                            #$%yoga-ink-commit)))))))))
    (native-inputs
     (append (list emscripten-yoga cmake-minimal ninja node-lts python)
             (map cdr yoga-ink-npm-inputs)
             (map cdr %yoga-ink-npm-license-supplements)))
    (home-page "https://yogalayout.dev/")
    (synopsis "Source-built JavaScript bindings for the Yoga flexbox engine")
    (description
     "Yoga is a flexbox layout engine.  This package compiles its C++ engine
and embind bindings to embedded WebAssembly using a source-built Emscripten SDK,
then compiles the upstream TypeScript wrapper and declarations.  It provides
both the eager @code{yoga-layout} and asynchronous @code{yoga-layout/load}
ES module exports, without downloading an SDK or using a prebuilt Yoga binary.")
    (license license:expat)))
