;;; GNU Guix package for vadimdemedes/ink.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages ink)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (gnu packages web)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages ink-npm-sources)
  #:use-module (tay packages starred-s-z)
  #:use-module (tay packages unrs-resolver)
  #:use-module (tay packages yoga-ink))

;; Resolve auxiliary files through the load path, not the working directory:
;; module-relative local-file names break when the module is recompiled.
(define %ink-package-lock
  (local-file (search-tay-package-file "ink-package-lock.json")))

(define %ink-closure-helper
  (local-file (search-tay-package-file "ink-closure.mjs")))

;; tsx 4.21.0's esbuild API talks to the exact matching native executable.
;; The npm JS adapter is source; all @esbuild platform binaries are excluded.
;; The inherited Guix x/sys input is a compatible later source revision.
;; Delete npm distribution assets from the Go source.
(define esbuild-for-ink
  (package
    (inherit esbuild)
    (name "esbuild-for-ink")
    (version "0.25.12")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/evanw/esbuild/tar.gz/"
                           "refs/tags/v" version))
       (file-name (string-append "esbuild-" version ".tar.gz"))
       (sha256
        (base32 "1d5arkh37ihgsr2hmcv40lmllqby8mqqqi97ygkbv3p68916x9gc"))
       (modules '((guix build utils)))
       (snippet #~(delete-file-recursively "npm"))))))

(define-public node-ink
  (package
    (name "node-ink")
    (version "7.1.1")
    ;; The channel's canonical source snapshot includes the four upstream
    ;; fixes after the v7.1.1 tag.  Its manifest still declares version 7.1.1.
    (source (package-source vadimdemedes-ink-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'materialize-fixed-node-modules
            (lambda _
              (copy-file #$%ink-package-lock
                         "package-lock.json")
              (for-each
               (lambda (path archive)
                 (mkdir-p path)
                 (invoke "tar" "xzf" archive "-C" path
                         "--strip-components=1"))
               '#$(map car %ink-npm-sources)
               (list #$@(map cdr %ink-npm-sources)))
              ;; Native source outputs replace every npm-native binary path.
              ;; Yoga's complete package (ESM, enums, types and embedded Wasm)
              ;; is built from C++ and the original wrapper sources.
              (symlink #$(file-append node-yoga-layout
                                     "/lib/node_modules/yoga-layout")
                       "node_modules/yoga-layout")
              (delete-file-recursively "node_modules/unrs-resolver")
              (symlink #$(file-append node-unrs-resolver
                                     "/lib/node_modules/unrs-resolver")
                       "node_modules/unrs-resolver")
              (for-each
               (lambda (path)
                 (when (file-exists? path) (delete-file-recursively path)))
               '("node_modules/node-pty/prebuilds"
                 "node_modules/node-pty/third_party/conpty"))
              (setenv "ESBUILD_BINARY_PATH"
                      #$(file-append esbuild-for-ink "/bin/esbuild"))
              (setenv "HOME" (string-append (getcwd) "/.build-home"))
              (mkdir-p (getenv "HOME"))
              (setenv "npm_config_offline" "true")
              (setenv "npm_config_audit" "false")
              (setenv "npm_config_fund" "false")
              (setenv "npm_config_update_notifier" "false")
              (setenv "PATH" (string-append (getcwd) "/node_modules/.bin:"
                                            #$(file-append node "/bin") ":"
                                            (getenv "PATH")))
              (invoke #$(file-append node "/bin/node")
                      #$%ink-closure-helper "bins")))
          (replace 'configure (lambda _ #t))
          (replace 'build
            (lambda _
              ;; Rebuild node-pty using the packaged Node's own node-gyp and
              ;; installed headers.  There is no lifecycle execution, header
              ;; download, prebuild fallback or substitute fake PTY in tests.
              (invoke #$(file-append node "/bin/node")
                      #$(file-append
                         node
                         "/lib/node_modules/npm/node_modules/node-gyp/bin/"
                         "node-gyp.js")
                      "rebuild" "--directory=node_modules/node-pty"
                      (string-append "--nodedir=" #$node)
                      "--build-from-source" "--offline")
              ;; Compile the genuine source files and declaration files with
              ;; the upstream compiler options, never copy the npm Ink build.
              (invoke #$(file-append node "/bin/npm") "run" "build")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; The full-board fixture is not a PTY test: it imports the
                ;; snake example, hence all of Ink, through a fresh tsx
                ;; process, transpiling ~50 modules and instantiating Yoga's
                ;; embedded Wasm before the pure reducer runs.  The retained
                ;; failed build's tsx cache shows that cold load still in
                ;; progress when the test's 1 s spawn deadline killed it.
                ;; Allow 10 s for startup; every exit/won/score/length
                ;; assertion is unchanged.
                (substitute* "test/alternate-screen-example.tsx"
                  (("\\}, 1000\\);") "}, 10_000);"))
                ;; npm test runs tsc --noEmit, XO, then the serial AVA 7 suite.
                ;; The original AVA file globs and PTY fixtures are untouched.
                ;; Do not mark CI: several upstream tests explicitly exercise
                ;; non-CI terminal rendering and supply their own CI values.
                (unsetenv "CI")
                (setenv "TERM" "xterm-256color")
                (invoke #$(file-append node "/bin/npm") "test"))))
          (replace 'install
            (lambda _
              (invoke #$(file-append node "/bin/node")
                      #$%ink-closure-helper "install" #$output
                      #$@%ink-consumer-modules
                      #$@%ink-runtime-modules
                      "node_modules/yoga-layout")
              (let ((doc (string-append #$output "/share/doc/node-ink")))
                (mkdir-p doc)
                (copy-file "license" (string-append doc "/license"))
                (copy-file "readme.md" (string-append doc "/readme.md"))
                (copy-file "package-lock.json"
                           (string-append doc "/channel-package-lock.json"))))))))
    (native-inputs
     (append (list node python-wrapper esbuild-for-ink node-unrs-resolver)
             (map cdr %ink-npm-sources)))
    ;; Full Node supplies npm for the original upstream test script and
    ;; consumers; node-minimal lacks both the tested toolchain and PTY headers.
    (inputs (list node node-yoga-layout))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/vadimdemedes/ink")
    (synopsis "React renderer for interactive command-line interfaces")
    (description
     "Ink renders React components as interactive terminal interfaces.  This
package compiles Ink 7.1.1's canonical source snapshot and TypeScript declarations
with a fixed offline npm graph.  Yoga's C++ layout engine and WebAssembly binding,
esbuild's test transpiler and the lint resolver are built from source; the full
upstream typecheck, lint and AVA suite use a genuinely compiled node-pty addon.
React 19.2.4 is installed alongside Ink, so consumers can link both packages
without loading two React instances.  The package's ESM exports point to its
built JavaScript and declarations.")
    ;; Runtime npm graph is MIT, ISC and MIT OR CC0-1.0; select MIT for the
    ;; latter.  License texts stay beside their modules.  Build-only graphs
    ;; retain their licenses and are not installed with the runtime library.
    (license (list license:expat license:isc))))
