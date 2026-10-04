;;; Source-built LiteGraph.js graph engine and browser canvas editor.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages litegraph)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages java)
  #:use-module (gnu packages node)
  #:use-module (gnu packages node-xyz)
  #:use-module (gnu packages python)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages litegraph-compiler)
  #:use-module (tay packages litegraph-npm-sources)
  #:use-module (tay packages starred-i-m))

(define %litegraph-npm-helper
  (local-file (search-tay-package-file "files/litegraph-npm.py")))

(define %litegraph-engine-test
  (local-file (search-tay-package-file "files/litegraph-engine.cjs")))

(define %litegraph-embedded-notices
  (local-file (search-tay-package-file "files/litegraph-embedded-notices.txt")))

(define-public litegraph
  (package
    (name "litegraph")
    (version "0.7.14-0.0555a2f")
    (source (package-source jagenjo-litegraph-js-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; Upstream's committed bundles and API documentation are
              ;; outputs, not inputs.  Rebuild the bundles from src/.
              (for-each delete-file-recursively
                        (filter file-exists? '("build" "doc")))
              ;; This inactive node is only a comment, but concat would copy its
              ;; unlicensed Voxagon/Tuxedo Labs shader into the readable bundle.
              ;; Remove exactly that comment; executable code is unchanged.
              (let* ((file "src/nodes/glfx.js")
                     (text (call-with-input-file file
                             (@ (ice-9 textual-ports) get-string-all)))
                     (start (string-contains text "/* not working yet"))
                     (newline (if (string-contains text "\r\n") "\r\n" "\n"))
                     (marker (string-append
                              "global.LGraphDepthOfField = LGraphDepthOfField;"
                              newline "\t*/" newline))
                     (end (and start (string-contains text marker start))))
                (unless (and end
                             (string-contains (substring text start end)
                                              "tuxedolabs.blogspot.com")
                             (not (string-contains text "/* not working yet"
                                                   (+ end 1))))
                  (error "Unexpected inactive depth-of-field block" file))
                (call-with-output-file file
                  (lambda (port)
                    (display (substring text 0 start) port)
                    (display (substring text (+ end (string-length marker)))
                             port))))
              ;; The lockfile pins compiler 20171112.0.0 despite the newer
              ;; package.json range.  Replay that exact Grunt locator tree from
              ;; fixed archives: no npm resolution or lifecycle scripts run.
              (call-with-output-file ".litegraph-npm-inputs"
                (lambda (port)
                  (for-each
                   (lambda (entry)
                     (format port "~a\t~a\t~a~%"
                             (car entry) (cadr entry) (caddr entry)))
                   (list #$@(map
                             (lambda (path)
                               (let* ((key (assoc-ref %litegraph-npm-path-keys
                                                      path))
                                      (source (assoc-ref %litegraph-npm-sources
                                                         key)))
                                 #~(list #$path #$key #$source)))
                             %litegraph-npm-paths)))))
              (invoke "python3" #$%litegraph-npm-helper
                      ".litegraph-npm-inputs" ".litegraph-build-notices")
              ;; grunt-closure-tools runs `java -jar` on this exact upstream
              ;; Gruntfile path; the jar itself is built from Closure sources.
              (mkdir-p "node_modules/google-closure-compiler")
              (symlink #$(file-append litegraph-closure-compiler
                                     "/share/java/closure-compiler.jar")
                       "node_modules/google-closure-compiler/compiler.jar")
              (setenv "HOME" (getcwd))))
          (replace 'build
            (lambda _
              ;; js-yaml eagerly requires Esprima.  Compile the matching source
              ;; tag directly to CommonJS without its npm webpack bundle.
              (invoke #$(file-append node-typescript "/bin/tsc")
                      "--project" "node_modules/esprima/src/"
                      "--strict" "false" "--ignoreDeprecations" "5.0")
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/grunt-cli/bin/grunt" "build")
              (for-each
               (lambda (file)
                 (unless (and (file-exists? file)
                              (> (stat:size (stat file)) 100000))
                   (error "Grunt did not generate" file)))
               '("build/litegraph.js" "build/litegraph.min.js"))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Exercise both generated bundles in separate Node processes:
                ;; execution, JSON export/import, edge preservation and rerun.
                (invoke #$(file-append node-lts "/bin/node")
                        #$%litegraph-engine-test (getcwd)))))
          (replace 'install
            (lambda _
              (let ((module (string-append #$output
                                           "/lib/node_modules/litegraph.js"))
                    (doc (string-append #$output "/share/doc/litegraph")))
                (for-each
                 (lambda (file)
                   (let ((destination (string-append module "/" file)))
                     (mkdir-p (dirname destination))
                     (copy-file file destination)))
                 '("build/litegraph.js" "build/litegraph.min.js"
                   "src/litegraph-editor.js" "src/litegraph.d.ts"
                   "css/litegraph.css" "css/litegraph-editor.css" "LICENSE"))
                ;; The bundles have no runtime npm dependencies.
                (call-with-output-file (string-append module "/package.json")
                  (lambda (port)
                    (display
                     (string-append
                      "{\"name\":\"litegraph.js\",\"version\":\"0.7.14\","
                      "\"license\":\"MIT\",\"main\":\"build/litegraph.js\","
                      "\"types\":\"src/litegraph.d.ts\"}\n")
                     port)))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md"))
                (install-file "guides/README.md" (string-append doc "/guides"))
                ;; litegraph-editor.css resolves ../editor/imgs/; the Editor's
                ;; buttons and canvas grid use the same first-party images.
                (copy-recursively "editor/imgs"
                                  (string-append module "/editor/imgs"))
                (copy-file #$%litegraph-embedded-notices
                           (string-append doc "/THIRD-PARTY-NOTICES"))
                (copy-file #$%litegraph-embedded-notices
                           (string-append module "/THIRD-PARTY-NOTICES"))
                (copy-recursively
                 ".litegraph-build-notices"
                 (string-append doc "/build-tools/npm"))
                (copy-recursively
                 #$(file-append litegraph-closure-compiler
                                "/share/doc/litegraph-closure-compiler")
                 (string-append doc "/build-tools/closure-compiler"))))))))
    (native-inputs
     (append (list litegraph-closure-compiler icedtea-8 node-lts node-typescript
                   python)
             (map cdr %litegraph-npm-sources)))
    (home-page "https://github.com/jagenjo/litegraph.js")
    (synopsis "JavaScript graph engine with browser canvas node editor")
    (description
     "LiteGraph is a JavaScript graph engine for building, executing,
serializing and visually editing node graphs.  Its HTML5 canvas editor supports
dragging nodes, connecting slots and editing node widgets in a browser, and its
generated bundle also runs headlessly in Node.  This package rebuilds both the
readable and Closure-compiled bundles from the pinned upstream source with the
locked Grunt toolchain and a source-built Closure Compiler.  It installs those
bundles, the editor script, stylesheets, interface images and TypeScript
declarations, without demo media or upstream prebuilt outputs.")
    ;; LiteGraph is Expat.  Its bundles embed BSD-3 GPUImage and Expat XDoG/Wagner
    ;; shaders; Closure Compiler may inject Apache-2.0 runtime helpers.
    (license (list license:expat license:bsd-3 license:asl2.0))))
