;;; GNU Guix package for codingismy11to7/scala-ts.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages scala-ts)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (tay packages scala-ts-npm-sources)
  #:use-module (tay packages starred-a-c))

(define scala-ts-immutable
  (assoc-ref %scala-ts-npm-sources "immutable@4.0.0-rc.12"))

(define-public scala-ts
  (package
    (name "scala-ts")
    (version "0.1.8")
    (source (package-source codingismy11to7-scala-ts-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; `npm ci' uses the committed v1 lockfile verbatim.  Its cache
              ;; is populated solely from fixed Guix source inputs before the
              ;; offline install, so dependency ranges cannot be resolved.
              (let ((cache (string-append (getcwd) "/.npm-cache"))
                    (npm #$(file-append node-lts "/bin/npm")))
                (setenv "npm_config_cache" cache)
                (setenv "npm_config_offline" "true")
                (setenv "npm_config_audit" "false")
                (setenv "npm_config_fund" "false")
                (for-each
                 (lambda (archive)
                   (invoke npm "cache" "add" "--offline" archive))
                 (list #$@(map cdr %scala-ts-npm-sources)))
                (invoke npm "ci" "--offline" "--ignore-scripts"
                        "--no-audit" "--no-fund"))))
          (replace 'build
            (lambda _
              (invoke #$(file-append node-lts "/bin/npm") "run" "build")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke #$(file-append node-lts "/bin/npm")
                        "run" "test:prod"))))
          (replace 'install
            (lambda _
              (let ((module (string-append #$output
                                            "/lib/node_modules/scala-ts")))
                (mkdir-p module)
                (copy-recursively "dist" (string-append module "/dist"))
                (copy-recursively "legacy" (string-append module "/legacy"))
                (copy-file "package.json" (string-append module "/package.json"))
                ;; Retain the historical CommonJS main while exposing the
                ;; declarations produced by this source build.
                (invoke "sed" "-i"
                        (string-append
                         "s|\"main\": \"legacy/scala-ts.umd.js\",|"
                         "\"main\": \"legacy/scala-ts.umd.js\",\\n"
                         "  \"types\": \"dist/scala-ts.d.ts\",|")
                        (string-append module "/package.json"))
                (copy-file "LICENSE" (string-append module "/LICENSE"))
                (copy-file "README.md" (string-append module "/README.md"))
                ;; The UMD bundle externalizes immutable.  Its lock-selected
                ;; MIT-licensed archive is installed beside the module, with
                ;; its upstream license notice intact, for self-contained
                ;; `require' resolution at runtime.
                (let ((immutable (string-append module
                                                 "/node_modules/immutable")))
                  (mkdir-p immutable)
                  (invoke "tar" "xzf" #$scala-ts-immutable "-C" immutable
                          "--strip-components=1"))))))))
    ;; Every archive here is a registry source selected by package-lock.json;
    ;; none is an npm-generated binary or a build-time network dependency.
    (native-inputs
     (append (list node-lts) (map cdr %scala-ts-npm-sources)))
    (home-page "https://github.com/codingismy11to7/scala-ts")
    (synopsis "Scala-inspired functional programming data types for TypeScript")
    (description
     "Scala-ts provides Scala-inspired Option, Either, Try, List, Set, and
other functional programming data types for TypeScript.  It is built and
tested from the pinned upstream source using an offline installation of the
fully fixed npm lockfile closure.")
    (license (list license:asl2.0 license:expat))))
