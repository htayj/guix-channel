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
                           (invoke "tar" "xzf" archive "-C" directory
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
                          "--strip-components=1")))))))))
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
