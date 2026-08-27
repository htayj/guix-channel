;;; GNU Guix package for Yomguithereal/react-blessed.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages react-blessed)
  #:use-module (guix build-system node)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (tay packages react-blessed-npm-sources)
  #:use-module (tay packages starred-s-z))

(define %react-blessed-runtime-modules
  '("node_modules/blessed"
    "node_modules/js-tokens"
    "node_modules/loose-envify"
    "node_modules/object-assign"
    "node_modules/react"
    "node_modules/react-reconciler"
    "node_modules/scheduler"))

(define-public react-blessed
  (package
    (name "react-blessed")
    (version "0.7.2")
    (source (package-source yomguithereal-react-blessed-source))
    (build-system node-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          ;; The source archive is deliberately complete: no package manager
          ;; resolves or fetches anything.  Reconstruct the exact npm tree
          ;; described by the upstream lockfile from fixed Guix source inputs.
          (add-after 'unpack 'materialize-locked-node-modules
            (lambda _
              (use-modules (json) (srfi srfi-1) (srfi srfi-13))
              (mkdir-p ".npm-source-cache")
              (let ((archives (list #$@(map cdr %react-blessed-npm-sources))))
                (for-each
                 (lambda (archive index)
                   (let ((directory (string-append ".npm-source-cache/"
                                                    (number->string index))))
                     (mkdir-p directory)
                     (invoke "tar" "xzf" archive "-C" directory
                             "--strip-components=1")))
                 archives
                 (iota (length archives)))
                (let ((sources
                       (map (lambda (index)
                              (let* ((directory (string-append ".npm-source-cache/"
                                                               (number->string index)))
                                     (metadata
                                      (call-with-input-file
                                       (string-append directory "/package.json")
                                       json->scm)))
                                (cons (string-append (assoc-ref metadata "name") "@"
                                                     (assoc-ref metadata "version"))
                                      directory)))
                            (iota (length archives)))))
                  (for-each
                   (lambda (entry)
                     (let* ((path (car entry))
                            (metadata (cdr entry)))
                       (unless (string-null? path)
                         (let* ((start
                                 (let loop ((offset 0) (last #f))
                                   (let ((next (string-contains path "node_modules/"
                                                                offset)))
                                     (if next
                                         (loop (+ next 1) next)
                                         last))))
                                (name (substring path
                                                 (+ start
                                                    (string-length "node_modules/"))))
                                (key (string-append name "@"
                                                    (assoc-ref metadata "version")))
                                (cached (assoc-ref sources key)))
                           (unless cached
                             (error "locked npm source was not supplied" key))
                           (mkdir-p (dirname path))
                           (copy-recursively cached path)))))
                   (assoc-ref (call-with-input-file "package-lock.json" json->scm)
                              "packages"))))))
          ;; Guix 1.5 promotes peers when it patches dependencies.  Blessed
          ;; and React are bundled below, but DevTools remains an optional,
          ;; documented integration and must never be promoted by default.
          (replace 'patch-dependencies (lambda _ #t))
          (delete 'delete-lockfiles)
          (add-after 'materialize-locked-node-modules 'remove-optional-devtools-peer
            (lambda _
              (modify-json
               (delete-fields
                '("peerDependencies.react-devtools-core"
                  "peerDependenciesMeta.react-devtools-core")
                #:strict? #f))))
          (replace 'configure (lambda _ #t))
          (replace 'build
            (lambda _
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/rollup/dist/bin/rollup" "-c")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke #$(file-append node-lts "/bin/node")
                        "node_modules/mocha/bin/mocha" "-R" "spec"
                        "--require" "@babel/register" "./test/endpoint.js"))))
          (replace 'install
            (lambda _
              (let ((module (string-append #$output "/lib/node_modules/react-blessed"))
                    (documentation (string-append #$output "/share/doc/react-blessed")))
                (mkdir-p module)
                (copy-recursively "dist" (string-append module "/dist"))
                (copy-file "package.json" (string-append module "/package.json"))
                (mkdir-p (string-append module "/node_modules"))
                (for-each
                 (lambda (path)
                   (copy-recursively path (string-append module "/" path)))
                 '#$%react-blessed-runtime-modules)
                (mkdir-p documentation)
                (copy-file "LICENSE.txt" (string-append documentation "/LICENSE.txt"))
                (copy-file "README.md" (string-append documentation "/README.md"))))))))
    ;; Origins are source archives only.  The node build system supplies Node;
    ;; all JavaScript build and test dependencies come from this locked list.
    (native-inputs (map cdr %react-blessed-npm-sources))
    (home-page "https://github.com/Yomguithereal/react-blessed")
    (synopsis "React renderer for Blessed terminal interfaces")
    (description
     "React Blessed renders React 17 component trees through Blessed.  It is
built and tested from the pinned upstream source using its fully fixed npm
closure, with no package-manager resolution or network access during builds.")
    (license license:expat)))
