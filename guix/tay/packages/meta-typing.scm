;;; GNU Guix package for ronami/meta-typing.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages meta-typing)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (tay packages meta-typing-npm-sources))

(define-public meta-typing
  (package
    (name "meta-typing")
    (version "0.1.0")
    ;; Keep the source ledger untouched while giving the buildable package a
    ;; Git origin at that same exact commit, recognizable to Guix updaters.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ronami/meta-typing")
             (commit "03a4927933e3a6e6439d42f29d656353512fe308")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0g6vwiih3hvlsypvcvqkv6xv8ysn4139gm2zqj4yw21awf5kybdl"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; Extract a fixed Node resolution tree without Yarn/npm,
              ;; registry queries, lifecycle scripts, or semver resolution.
              ;; tar autodetection also handles Guix's snippet repacking.
              (let ((sources
                     (list #$@(map (lambda (entry)
                                     #~(cons #$(car entry) #$(cdr entry)))
                                   %meta-typing-npm-sources))))
                (for-each
                 (lambda (entry)
                   (let ((archive (assoc-ref sources (cdr entry))))
                     (unless archive
                       (error "missing locked test-tool source" (cdr entry)))
                     (mkdir-p (car entry))
                     (invoke "tar" "xf" archive "-C" (car entry)
                             "--strip-components=1")))
                 '#$%meta-typing-npm-layout))
              (setenv "HOME" (string-append (getcwd) "/.home"))
              (setenv "XDG_CONFIG_HOME" (string-append (getenv "HOME") "/config"))
              (setenv "XDG_CACHE_HOME" (string-append (getenv "HOME") "/cache"))
              (mkdir-p (getenv "HOME"))
              (setenv "NO_UPDATE_NOTIFIER" "1")
              (unsetenv "NODE_PATH")
              (unsetenv "NODE_OPTIONS")))
          (replace 'build
            (lambda _
              ;; Declarations are the source artifact.  Type-check the complete
              ;; source tree using upstream's noEmit/strict tsconfig and its
              ;; lock-selected compiler; do not fabricate JavaScript output.
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/typescript/bin/tsc" "-p" "tsconfig.json")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; package.json's `test: tsd` uses the unmodified src test tree.
                ;; Invoke that exact CLI directly; it carries TypeScript 3.7.2.
                ;; Its update notifier is disabled, not its assertions.
                (invoke #$(file-append node-lts "/bin/node")
                        "node_modules/tsd/dist/cli.js"))))
          (replace 'install
            (lambda _
              (use-modules (srfi srfi-13))
              (let* ((module (string-append #$output
                                            "/lib/node_modules/meta-typing"))
                     (documentation (string-append #$output
                                                    "/share/doc/meta-typing")))
                ;; Install every public declaration, preserving its relative
                ;; imports.  The author's tsd tests are not public declarations
                ;; and would require development tools in consumer projects.
                (for-each
                 (lambda (file)
                   (unless (string-suffix? ".test-d.ts" file)
                     (install-file file
                                   (string-append module "/" (dirname file)))))
                 (find-files "src" "\\.d\\.ts$"))
                ;; Upstream's sole entry is types: ./src/index.d.ts.  Preserve
                ;; package identity, author and MIT metadata without a runtime
                ;; main, wrapper, fake module, or bundled compiler/test tools.
                (for-each (lambda (file) (install-file file module))
                          '("package.json" "LICENSE" "README.md"))
                (copy-recursively "assets" (string-append module "/assets"))
                (mkdir-p documentation)
                (symlink (string-append module "/README.md")
                         (string-append documentation "/README.md"))
                (symlink (string-append module "/LICENSE")
                         (string-append documentation "/LICENSE"))
                (symlink (string-append module "/assets")
                         (string-append documentation "/assets"))))))))
    (native-inputs
     (append (list node-lts) (map cdr %meta-typing-npm-sources)))
    (home-page "https://github.com/ronami/meta-typing")
    (synopsis "Algorithms and data structures expressed as TypeScript types")
    (description
     "Meta-typing implements arithmetic, list operations, sorting, trees,
matrices, puzzles, and other algorithms entirely in TypeScript's type system.
This declaration-only package installs the complete public type tree and
upstream metadata, MIT license, and illustrated documentation.  There is no
JavaScript runtime entry point.  Its pinned compiler and original tsd suite
run offline using a fixed test-tool closure.  Upstream describes the project
as an experiment for learning rather than a practical general-purpose library.")
    (license license:expat)))
