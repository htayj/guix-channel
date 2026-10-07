;;; Source-built Closure Compiler matching Emscripten 3.1.28.
(define-module (tay packages emscripten-yoga-closure)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages compression) #:select (zip))
  #:use-module (tay packages rot-js-compiler))

;; The v20220502 BUILD.bazel and bazel/typedast.bzl actions are unchanged
;; from v20211201.  Reuse the existing source-only Java builder and dependency
;; closure rather than introduce Maven resolution or a second Java build system.
;; WORKSPACE.bazel changes bazel-common to 82a7dd0f4cd8593fdaa40d65a1fa820b14ff3493:
;; its protobuf source pin is now 3.19.3; the other compiler dependency versions
;; remain unchanged.  In particular, @com_google_protobuf//:protobuf_java uses
;; that source runtime, not bazel-common's unrelated protobuf-java Maven import.
(define (rot-compiler-binding name)
  (module-ref (resolve-module '(tay packages rot-js-compiler)) name))

(define compiler-source (rot-compiler-binding 'compiler-source))
(define compiler-java-package (rot-compiler-binding 'compiler-java-package))
(define ant-for-closure (rot-compiler-binding 'ant-for-rot))

(define %protobuf-source
  (compiler-source
   "https://github.com/protocolbuffers/protobuf/releases/download/v3.19.3/protobuf-java-3.19.3.tar.gz"
   "0y14bz5g836aczbh2fsnhfg9z1n4y5n84wph42r60b1lxakw8q1i"
   "protobuf-java-3.19.3.tar.gz"))

(define protobuf-for-emscripten-yoga
  (package
    (inherit (rot-compiler-binding 'protobuf-for-rot))
    (name "protobuf-for-emscripten-yoga")
    (version "3.19.3")
    (source %protobuf-source)
    ;; The release source includes configure; the inherited phase removes the
    ;; vendored googletest subdirectory without bootstrapping or fetching it.
    (synopsis "Protocol buffer generator matching Closure 20220502")
    (description "This source-built Protocol Buffers release supplies protoc
for the Closure Compiler bundled with Emscripten 3.1.28.  Its version matches
upstream's protobuf source dependency and supports proto3 optional fields.")
    (license license:bsd-3)))

(define java-protobuf-for-emscripten-yoga
  (package
    (inherit
     (compiler-java-package
      "java-protobuf-for-emscripten-yoga" "3.19.3" %protobuf-source
      "https://protobuf.dev" "Java protocol buffer runtime matching Closure 20220502"
      #:roots '("java/core/src/main/java" "build/proto")
      #:native-inputs (list protobuf-for-emscripten-yoga)
      #:licenses license:bsd-3 #:legal-license #f
      #:prepare
      #~(begin
          (mkdir-p "build/proto")
          ;; The complete core generation set from java/core/generate-sources-build.xml.
          (apply invoke "protoc" "--proto_path=src" "--java_out=build/proto"
                 (map (lambda (file)
                        (string-append "src/google/protobuf/" file ".proto"))
                      '("any" "api" "descriptor" "duration" "empty" "field_mask"
                        "source_context" "struct" "timestamp" "type" "wrappers"
                        "compiler/plugin"))))))
    (description "This package compiles the Protocol Buffers 3.19.3 Java core
runtime and its generated standard messages from source.  It matches the protoc
generator used for Emscripten 3.1.28's Closure Compiler.")))

(define %closure-runtime-inputs
  (map (lambda (input)
         (if (eq? input (rot-compiler-binding 'java-protobuf-for-rot))
             java-protobuf-for-emscripten-yoga
             input))
       (rot-compiler-binding '%closure-runtime-inputs)))

(define %closure-native-inputs
  (append
   (map (lambda (input)
          (if (eq? input (rot-compiler-binding 'protobuf-for-rot))
              protobuf-for-emscripten-yoga
              input))
        (map cadr (package-native-inputs rot-js-closure-compiler)))
   (list zip)))

(define-public emscripten-yoga-closure-compiler
  (package
    (inherit
     (compiler-java-package
      "emscripten-yoga-closure-compiler" "20220502"
      (compiler-source
       "https://github.com/google/closure-compiler/archive/refs/tags/v20220502.tar.gz"
       "1y4q4b871d7nvi5dlmk8hxpvvshj9g9d8w5id9mv1cz6gkgwkdpd"
       "closure-compiler-v20220502.tar.gz")
      "https://github.com/google/closure-compiler"
      "Source-built JavaScript compiler matching Emscripten 3.1.28"
      #:roots '("src" "build/proto")
      #:inputs %closure-runtime-inputs
      #:native-inputs %closure-native-inputs
      ;; Match the upstream Java source exclusions and release resources.
      ;; resources.json and its generator are only used by the J2CL variant;
      ;; the JVM ResourceLoader reads the packaged .properties and runtime JS.
      #:exclude '("/(debugger|j2clbuild|j2cl|super[^/]*|testing|webservice)/"
                  "resources/resources\\.json$" "build_resources\\.js$"
                  "build_polyfill_table\\.js$" "\\.gwt\\.xml$" "BUILD\\.bazel$"
                  "\\.proto$" "package\\.html$" "\\.textproto$"
                  "refactoring/examples/refasterjs/.*\\.js$"
                  "SourceMapObjectParser\\.externs\\.js$")
      #:processor "com.google.auto.value.processor.AutoValueProcessor,com.google.auto.value.processor.AutoValueBuilderProcessor,com.google.auto.value.processor.AutoAnnotationProcessor,com.google.auto.value.processor.AutoOneOfProcessor"
      #:compiler? #t
      ;; Preserve the Rhino and bundled dependency licenses and notices through
      ;; the shared builder's copyright source archive and dependency documents.
      #:licenses (list license:asl2.0 license:mpl1.1 license:gpl2+ license:expat
                       license:bsd-3 license:cddl1.0)
      #:prepare
      #~(begin
          (mkdir-p "build/proto")
          ;; Imports are repository-relative; include all four typed-AST schemas
          ;; plus mapping, conformance and profile.  typed_ast.proto uses proto3
          ;; optional presence, which protoc 3.11.4 cannot generate.
          (apply invoke "protoc" "--proto_path=." "--java_out=build/proto"
                 (sort (find-files "src" "\\.proto$") string<?))
          (substitute* "src/com/google/javascript/jscomp/CommandLineRunner.java"
            (("inlineDefine_COMPILER_VERSION") "\"v20220502\""))
          (with-directory-excursion "src/com/google/javascript/jscomp"
            (with-output-to-file "js/polyfills.txt"
              (lambda ()
                (apply invoke "node" "js/build_polyfill_table.js"
                       (sort (filter (lambda (file)
                                       (not (string-suffix? "build_polyfill_table.js" file)))
                                     (find-files "./js" "\\.js$")) string<?))))))
      #:finish
      #~(begin
          ;; The extern archive paths are relative to externs/, as in BUILD.bazel.
          (let ((target (string-append (getcwd) "/build/classes/externs.zip")))
            (with-directory-excursion "externs"
              (let ((files (sort (find-files "." "\\.js$") string<?)))
                (for-each (lambda (file) (utime file 315532800 315532800)) files)
                (apply invoke "zip" "-X" target files))))
          ;; This is the upstream unshaded deployment layout.  Every bundled jar
          ;; is source-built; only Ant's ant.jar belongs here, not optional jars.
          (for-each
           (lambda (input)
             (for-each
              (lambda (jar)
                (with-directory-excursion "build/classes" (invoke "jar" "xf" jar)))
              (find-files (string-append input "/share/java") "\\.jar$")))
           (list #$@(filter (lambda (input) (not (eq? input ant-for-closure)))
                           %closure-runtime-inputs)))
          (with-directory-excursion "build/classes"
            (invoke "jar" "xf" #$(file-append ant-for-closure "/lib/ant.jar")))
          ;; Reproduce bazel/typedast.bzl, using the just-compiled compiler before
          ;; runtime_libs.typedast exists.  This is a required build action, not
          ;; a smoke test; no pre-generated or placeholder typed AST is shipped.
          (let ((runtime-sources
                 (sort (filter (lambda (file)
                                 (not (or (string-suffix? "runtime_type_check.js" file)
                                          (string-suffix? "build_polyfill_table.js" file))))
                               (find-files "src/com/google/javascript/jscomp/js"
                                           "\\.js$")) string<?)))
            (apply invoke "java" "-cp" "build/classes"
                   "com.google.javascript.jscomp.CommandLineRunner"
                   "--checks_only" "--strict_mode_input" "--env=CUSTOM"
                   "--language_out=ES_NEXT" "--inject_libraries=false"
                   "--jscomp_error=checkTypes" "--jscomp_off=uselessCode"
                   "--typed_ast_output_file__INTENRNAL_USE_ONLY=build/classes/runtime_libs.typedast"
                   (map (lambda (file) (string-append "--js=" file)) runtime-sources)))
          (mkdir-p "build/classes/META-INF")
          (for-each delete-file
                    (find-files "build/classes/META-INF" "(INDEX\\.LIST|.*\\.(SF|RSA|DSA))$"))
          (call-with-output-file "build/classes/META-INF/MANIFEST.MF"
            (lambda (port)
              (display "Manifest-Version: 1.0\nMain-Class: com.google.javascript.jscomp.CommandLineRunner\n\n" port))))))
    (description "This package builds Closure Compiler v20220502 from source,
matching the compiler bundled with Emscripten 3.1.28 for Yoga.  It includes
source-built Java dependencies, generated Protocol Buffers classes, externs,
polyfills and the compiler-generated runtime typed AST.  The self-contained
unshaded jar is installed as @file{share/java/closure-compiler.jar}.")))
