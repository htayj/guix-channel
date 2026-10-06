;;; Source-built rot.js runtime, API documentation and offline browser suite.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages rot-js)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages chromium)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages java)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages rot-js-compiler)
  #:use-module (tay packages rot-js-npm-sources))

(define %rot-js-npm-helper
  (local-file (search-tay-package-file "files/rot-js-npm.py")))

(define %rot-js-browser-test
  (local-file (search-tay-package-file "files/rot-js-browser.cjs")))

(define %rot-js-consumer-test
  (local-file (search-tay-package-file "files/rot-js-consumer.cjs")))

(define %rot-js-build-notices
  (local-file (search-tay-package-file "files/rot-js-build-notices.txt")))

(define-public rot-js
  (package
    (name "rot-js")
    (version "2.2.1")
    ;; Canonical source commit 46782e248c2db9d379a5e4f13bb8323f18dff04b.
    ;; package.json says 2.2.1; the stale lock root says 2.2.0.  Tool versions
    ;; and every locator are replayed unchanged, without npm resolution.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ondras/rot.js")
             (commit "46782e248c2db9d379a5e4f13bb8323f18dff04b")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0vd530vgkzg80bcwlcr8zcv5h2ywb8c1ij0cc4nfwigklrwrlrxk"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; No committed runtime, declaration, docs or example bundle is
              ;; accepted as the rebuilt output.  Preserve first-party sources.
              (for-each delete-file-recursively
                        (filter file-exists?
                                '("lib" "dist" "doc" ".ts.flag"
                                  "examples/bundled-modules/example.bundle.js")))
              (mkdir-p "dist")
              (call-with-output-file ".rot-js-npm-inputs"
                (lambda (port)
                  (for-each
                   (lambda (entry)
                     (format port "~a\t~a\t~a~%"
                             (car entry) (cadr entry) (caddr entry)))
                   (list #$@(map
                             (lambda (path)
                               (let* ((key (assoc-ref %rot-js-npm-path-keys path))
                                      (source (assoc-ref %rot-js-npm-sources key)))
                                 #~(list #$path #$key #$source)))
                             %rot-js-npm-paths)))))
              (invoke "python3" #$%rot-js-npm-helper
                      ".rot-js-npm-inputs" ".rot-js-build-notices")
              ;; Preserve the real upstream google-closure-compiler JS CLI.
              ;; Its Java locator points exclusively at our source-built jar;
              ;; native images and the npm prebuilt Java jar are absent.
              (mkdir-p "node_modules/google-closure-compiler-java")
              (symlink #$(file-append rot-js-closure-compiler
                                     "/share/java/closure-compiler.jar")
                       "node_modules/google-closure-compiler-java/compiler.jar")
              (call-with-output-file
                  "node_modules/google-closure-compiler-java/package.json"
                (lambda (port)
                  (display
                   (string-append
                    "{\"name\":\"google-closure-compiler-java\","
                    "\"version\":\"20211201.0.0\",\"main\":\"index.js\","
                    "\"license\":\"Apache-2.0\"}\n")
                   port)))
              (call-with-output-file
                  "node_modules/google-closure-compiler-java/index.js"
                (lambda (port)
                  (display "module.exports = require.resolve('./compiler.jar');\n"
                           port)))
              (substitute* "tests/index.html"
                (("https://unpkg.com/jasmine-core@3/lib/jasmine-core/")
                 "../node_modules/jasmine-core/lib/jasmine-core/")
                (("specDone: console.log,")
                 "jasmineStarted: console.log,\n\tspecDone: console.log,"))
              (copy-file #$%rot-js-browser-test "tests/run.js")
              (setenv "ROT_JS_CHROMIUM"
                      #$(file-append ungoogled-chromium "/bin/chromium"))
              (setenv "HOME" (getcwd))
              ;; Deterministic real fonts for the upstream canvas metric specs:
              ;; rot.js's default "monospace" resolves to DejaVu Sans Mono.
              (call-with-output-file "rot-js-fonts.conf"
                (lambda (port)
                  (format port
                          (string-append
                           "<?xml version=\"1.0\"?><fontconfig>"
                           "<dir>~a/share/fonts/truetype</dir>"
                           "<cachedir>~a/.font-cache</cachedir>"
                           "<alias binding=\"strong\"><family>monospace</family>"
                           "<prefer><family>DejaVu Sans Mono</family></prefer>"
                           "</alias><alias binding=\"strong\">"
                           "<family>sans-serif</family><prefer>"
                           "<family>DejaVu Sans</family></prefer>"
                           "</alias></fontconfig>")
                          #$font-dejavu (getcwd))))
              (setenv "FONTCONFIG_FILE"
                      (string-append (getcwd) "/rot-js-fonts.conf"))
              (setenv "BROWSERSLIST_IGNORE_OLD_DATA" "true")))
          (replace 'build
            (lambda _
              ;; Same pinned tsc -> Rollup -> Babel -> Closure and TypeDoc
              ;; commands as upstream.  pipefail prevents a failed Rollup
              ;; command from being hidden by Babel's successful empty output.
              (invoke "make" "all" "SHELL=bash" ".SHELLFLAGS=-eu -o pipefail -c")
              (with-directory-excursion "examples/bundled-modules"
                (invoke "bash" "-eu" "-o" "pipefail" "run.sh"))
              (for-each
               (lambda (file)
                 (unless (and (file-exists? file)
                              (> (stat:size (stat file)) 0))
                   (error "Upstream build did not generate" file)))
               '("dist/rot.js" "dist/rot.min.js" "lib/index.js"
                 "lib/index.d.ts" "doc/index.html"
                 "examples/bundled-modules/example.bundle.js"))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; All eleven upstream browser spec files, local Jasmine
                ;; 3.10.1, Puppeteer-core 13, real Chromium, no HTTP requests.
                ;; The three upstream xit declarations remain disabled and
                ;; are explicitly reported; no additional skip is accepted.
                (invoke "make" "test")
                (invoke "node" #$%rot-js-consumer-test (getcwd)))))
          (replace 'install
            (lambda _
              (let ((module (string-append #$output "/lib/node_modules/rot-js"))
                    (doc (string-append #$output "/share/doc/rot-js")))
                (mkdir-p module)
                ;; Native modules, UMD/minified builds, generated declarations,
                ;; original manual/addons and all example styles share the
                ;; upstream layout, so their relative imports still resolve.
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append module "/" directory)))
                 '("lib" "dist" "doc" "examples" "addons" "manual"))
                (for-each (lambda (file) (install-file file module))
                          '("package.json" "license.txt" "README.md"))
                (mkdir-p doc)
                (symlink (string-append module "/doc")
                         (string-append doc "/api"))
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "README.md"))
                ;; Babel helpers, TypeDoc/lunr browser assets and the build
                ;; toolchain retain all archive notices and fixed provenance.
                (copy-recursively ".rot-js-build-notices"
                                  (string-append doc "/build-tools/npm"))
                (copy-file #$%rot-js-build-notices
                           (string-append doc "/build-tools/npm/SUPPLEMENTAL-NOTICES"))
                (copy-recursively
                 #$(file-append rot-js-closure-compiler
                                "/share/doc/rot-js-closure-compiler")
                 (string-append doc "/build-tools/closure-compiler"))
                (install-file #$%rot-js-consumer-test doc)))))))
    (native-inputs
     (append (list rot-js-closure-compiler openjdk11 node-lts python
                   ungoogled-chromium font-dejavu)
             (map cdr %rot-js-npm-sources)))
    (home-page "https://github.com/ondras/rot.js")
    (synopsis "JavaScript roguelike toolkit with terminal and browser displays")
    (description
     "This JavaScript roguelike toolkit supplies map generation, field-of-view,
pathfinding, schedulers, turn engines, random generators, color/text tools and
terminal or canvas rendering.  This package rebuilds its TypeScript modules,
declarations, UMD and minified bundles, example bundle and API documentation
from the pinned upstream source with the locked offline toolchain and a
source-built Closure Compiler.  It installs the API documentation, manual,
addons and examples alongside the JavaScript runtime.  The upstream browser
suite runs with local Jasmine assets and Chromium.  TypeDoc's syntax highlighter
uses pinned upstream Oniguruma WebAssembly solely at build time; this object is
not source-built and is not installed as part of the rot.js runtime.")
    ;; BSD-3 rot.js plus Babel/lunr Expat helpers and Apache-2.0 generated docs
    ;; and possible Closure runtime helpers.  Build-only tool licenses are
    ;; recorded separately, including vscode-oniguruma's third-party notices.
    (license (list license:bsd-3 license:expat license:asl2.0))))
