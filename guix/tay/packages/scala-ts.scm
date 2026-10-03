;;; GNU Guix package for codingismy11to7/scala-ts.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages scala-ts)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages guile)
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
      (with-extensions (list guile-json-4)
        #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; npm 10 needs registry packuments to repair a v1 lockfile,
              ;; even when every tarball is cached.  Extract the fixed
              ;; archives directly according to that lockfile instead.  This
              ;; is deterministic, performs no package-manager resolution,
              ;; and runs no package scripts during installation.
              (use-modules (json) (srfi srfi-1))
              (let* ((archives (list #$@(map cdr %scala-ts-npm-sources)))
                     (sources
                      (map
                       (lambda (archive index)
                         (let ((directory
                                (string-append ".npm-source-cache/"
                                               (number->string index))))
                           (mkdir-p directory)
                           ;; Snippet origins are repacked with zstd by Guix;
                           ;; let tar detect compression rather than force gzip.
                           (invoke "tar" "xf" archive "-C" directory
                                   "--strip-components=1")
                           (let ((metadata
                                  (call-with-input-file
                                   (string-append directory "/package.json")
                                   json->scm)))
                             (cons (string-append (assoc-ref metadata "name")
                                                  "@"
                                                  (assoc-ref metadata "version"))
                                   directory))))
                       archives
                       (iota (length archives))))
                     (lockfile
                      (call-with-input-file "package-lock.json" json->scm)))
                (define (source-for name version)
                  (or (assoc-ref sources (string-append name "@" version))
                      (error "locked npm source was not supplied"
                             name version)))
                (define (install-dependencies dependencies parent)
                  (for-each
                   (lambda (entry)
                     (let* ((name (car entry))
                            (metadata (cdr entry))
                            (version (assoc-ref metadata "version"))
                            (target (string-append parent "/node_modules/"
                                                    name)))
                       (unless (and version
                                    (assoc-ref metadata "resolved")
                                    (assoc-ref metadata "integrity"))
                         (error "lockfile dependency is not fixed" name))
                       (mkdir-p (dirname target))
                       (copy-recursively (source-for name version) target)
                       (install-dependencies
                        (or (assoc-ref metadata "dependencies") '())
                        target)))
                   (or dependencies '())))
                (define (bin-entries bin name)
                  (cond ((string? bin) (list (cons name bin)))
                        ((pair? bin) bin)
                        (else '())))
                (define (install-root-binaries dependencies)
                  (let ((bin-directory "node_modules/.bin"))
                    (mkdir-p bin-directory)
                    (for-each
                     (lambda (entry)
                       (let* ((name (car entry))
                              (package-directory
                               (string-append "node_modules/" name))
                              (metadata
                               (call-with-input-file
                                (string-append package-directory
                                               "/package.json")
                                json->scm))
                              (bin (assoc-ref metadata "bin")))
                         (for-each
                          (lambda (bin-entry)
                            (let ((link (string-append bin-directory "/"
                                                        (car bin-entry)))
                                  (target (string-append "../" name "/"
                                                         (cdr bin-entry))))
                              (chmod (string-append package-directory "/"
                                                     (cdr bin-entry))
                                     #o755)
                              (mkdir-p (dirname link))
                              (unless (file-exists? link)
                                (symlink target link))))
                          (bin-entries bin name))))
                     (or dependencies '()))))
                (let ((dependencies (assoc-ref lockfile "dependencies")))
                  (install-dependencies dependencies ".")
                  (install-root-binaries dependencies)
                  (delete-file-recursively ".npm-source-cache")))))
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
                (copy-file "package.json" (string-append module "/package.json"))
                ;; Use the freshly compiled CommonJS entry point, with the
                ;; declarations generated by the same TypeScript invocation.
                (substitute* (string-append module "/package.json")
                  (("\"main\": \"legacy/scala-ts.umd.js\",")
                   (string-append "\"main\": \"dist/scala-ts.js\",\n"
                                  "  \"types\": \"dist/scala-ts.d.ts\",")))
                (copy-file "LICENSE" (string-append module "/LICENSE"))
                ;; ES5 class lowering copies TypeScript's __extends helper
                ;; into dist/Exceptions.js.  Keep the pinned compiler's
                ;; copyright notice and license with that emitted code.
                (copy-file "node_modules/typescript/CopyrightNotice.txt"
                           (string-append module "/TypeScript-CopyrightNotice.txt"))
                (copy-file "node_modules/typescript/LICENSE.txt"
                           (string-append module "/TypeScript-LICENSE.txt"))
                (copy-file "README.md" (string-append module "/README.md"))
                (when (file-exists? "NOTICE")
                  (copy-file "NOTICE" (string-append module "/NOTICE")))
                ;; Both the generated CommonJS modules and their declarations
                ;; import immutable.  Install the lock-selected MIT archive
                ;; beside the module, retaining its complete license notice.
                (let ((immutable (string-append module
                                                 "/node_modules/immutable")))
                  (mkdir-p immutable)
                  (invoke "tar" "xzf" #$scala-ts-immutable "-C" immutable
                          "--strip-components=1")))))))))
    ;; Registry archives are fixed build inputs, not a uniformly source-only
    ;; closure: fsevents and source-map retain native/Wasm blobs.  The helper
    ;; sanitizes node-notifier's unused Darwin/Windows payloads at the origin.
    ;; Only immutable is copied into the installed runtime dependency tree.
    (native-inputs
     (append (list node-lts) (map cdr %scala-ts-npm-sources)))
    (home-page "https://github.com/codingismy11to7/scala-ts")
    (synopsis "Scala-inspired functional programming data types for TypeScript")
    (description
     "Scala-ts provides Scala-inspired Option, Either, Try, List, Set, and
other functional programming data types for TypeScript.  The installed
CommonJS entry point and TypeScript declarations are generated from the pinned
upstream source.  Its fixed npm source closure is built and tested offline,
and the immutable runtime dependency is included with its license notice.")
    (license (list license:asl2.0 license:expat))))
