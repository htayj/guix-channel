;;; Source-built Closure Compiler matching rot.js's 20211201.0.0 pin.
(define-module (tay packages rot-js-compiler)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix build-system ant)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages java)
  #:use-module (gnu packages node)
  #:use-module (gnu packages compression))

(define (compiler-source uri hash file-name)
  (origin (method url-fetch) (uri uri) (file-name file-name)
          (sha256 (base32 hash))))

(define %apache-license
  (compiler-source "https://www.apache.org/licenses/LICENSE-2.0.txt"
                   "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"
                   "LICENSE-2.0.txt"))
(define %mozilla-license
  (compiler-source "https://www.mozilla.org/media/MPL/1.1/index.txt"
                   "0sg4icrlvnnaqkb7cmx429yn3swd0y1hwdrs39hq36d9lwkgqjgq"
                   "MPL-1.1.txt"))

(define ant-for-rot
  (package
    (inherit ant/java8)
    (name "ant-for-rot") (version "1.10.11")
    (source
     (origin
       (method url-fetch)
       (uri "https://archive.apache.org/dist/ant/source/apache-ant-1.10.11-src.tar.gz")
       (sha256 (base32 "0favr81rd9j0w01nyra5yb0xr14g0gr9dnni72val3i4gvh72kf4"))
       (modules '((guix build utils)))
       (snippet #~(for-each delete-file (find-files "lib/optional" "\\.jar$")))))
    (arguments
     (substitute-keyword-arguments (package-arguments ant/java8)
       ((#:phases phases)
        #~(modify-phases #$phases
            ;; Ant's bootstrap dist omits root notices; the compiler bundles ant.jar.
            (add-after 'build 'install-notices
              (lambda _
                (let ((doc (string-append #$output "/share/doc/ant-for-rot")))
                  (install-file "LICENSE" doc)
                  (install-file "NOTICE" doc))))))))))

;; Like the LiteGraph compiler, source jars are unpacked as source only.
;; javac, protoc and the compiler itself reproduce the upstream Bazel actions;
;; neither Maven resolution, downloaded bytecode nor Bazel toolchains are used.
(define* (compiler-java-package name version source home synopsis
                               #:key (roots '("src")) (inputs '())
                               (native-inputs '()) (exclude '())
                               (prepare #~#t) (finish #~#t) (processor #f)
                               (compiler? #f) (licenses license:asl2.0)
                               (legal-license %apache-license))
  ;; Thunked package fields bind field names, so gexps use distinct names.
  (define jar-name name)
  (define bundled-inputs inputs)
  (package
    (name name) (version version) (source source)
    (build-system ant-build-system)
    (inputs inputs) (native-inputs native-inputs)
    (arguments
     (list
      #:jdk icedtea-8
      ;; Every jar on CLASSPATH comes from this pinned closure, including Ant.
      #:ant ant-for-rot
      #:tests? #f ; Compiler-tool tests are separate from the rot.js test suite.
      #:modules '((guix build ant-build-system) (guix build utils)
                  (ice-9 regex) (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda _
              (define (excluded? file)
                (any (lambda (pattern) (string-match pattern file)) '#$exclude))
              #$prepare
              (mkdir-p "build/classes")
              (mkdir-p "build/generated")
              (call-with-output-file "build/sources.list"
                (lambda (port)
                  (for-each
                   (lambda (file) (format port "~s~%" file))
                   (sort (filter (lambda (file) (not (excluded? file)))
                                 (append-map (lambda (root)
                                               (find-files root "\\.java$"))
                                             '#$roots)) string<?))))
              (apply invoke "javac" "-encoding" "UTF-8" "-source" "8" "-target" "8"
                     "-classpath" (getenv "CLASSPATH")
                     (append (if #$processor
                                 (list "-processor" #$processor
                                       "-processorpath" (getenv "CLASSPATH")
                                       "-s" "build/generated")
                                 (list "-proc:none"))
                             (list "-d" "build/classes" "@build/sources.list")))
              (for-each
               (lambda (root)
                 (for-each
                  (lambda (file)
                    (unless (or (excluded? file)
                                (string-match "(\\.java|\\.class|\\.jar)$" file)
                                (string-suffix? "META-INF/MANIFEST.MF" file))
                      (let ((target (string-append
                                     "build/classes/"
                                     (string-drop file (+ 1 (string-length root))))))
                        (mkdir-p (dirname target)) (copy-file file target))))
                  (find-files root))) '#$roots)
              #$finish
              (if (file-exists? "build/classes/META-INF/MANIFEST.MF")
                  (invoke "jar" "cfm" (string-append "build/" #$jar-name ".jar")
                          "build/classes/META-INF/MANIFEST.MF" "-C" "build/classes" ".")
                  (invoke "jar" "cf" (string-append "build/" #$jar-name ".jar")
                          "-C" "build/classes" "."))))
          (add-after 'build 'archive-source-notices
            (lambda _
              (mkdir-p "build/source-notices")
              (for-each
               (lambda (root)
                 (for-each
                  (lambda (file)
                    (let ((target (string-append "build/source-notices/" file)))
                      (mkdir-p (dirname target)) (copy-file file target)))
                  (find-files root "\\.(java|properties|vm)$"))) '#$roots)
              (invoke "tar" "--sort=name" "--mtime=@315532800"
                      "--owner=0" "--group=0" "--numeric-owner"
                      "-cf" "build/copyright-sources.tar"
                      "-C" "build/source-notices" ".")))
          (replace 'install
            (lambda _
              (install-file (string-append "build/" #$jar-name ".jar")
                            (string-append #$output "/share/java"))
              (when #$compiler?
                (symlink (string-append #$jar-name ".jar")
                         (string-append #$output "/share/java/closure-compiler.jar"))
                (symlink (string-append #$jar-name ".jar")
                         (string-append #$output "/share/java/compiler.jar")))
              (let ((doc (string-append #$output "/share/doc/" #$jar-name)))
                (mkdir-p doc)
                (install-file "build/copyright-sources.tar" doc)
                (when #$legal-license
                  (copy-file #$legal-license (string-append doc "/LICENSE.external")))
                (when #$compiler?
                  (for-each
                   (lambda (input)
                     (for-each
                      (lambda (directory)
                        (let ((source (string-append input directory)))
                          (when (file-exists? source)
                            (copy-recursively
                             source (string-append doc "/dependencies/"
                                                   (basename input) directory)))))
                      '("/share/doc" "/share/ant/manual")))
                   (list #$@bundled-inputs))
                  (copy-file #$%mozilla-license (string-append doc "/MPL-1.1.txt"))
                  (install-file "README.md" doc)
                  (install-file "BUILD.bazel" doc)
                  (install-file "WORKSPACE.bazel" doc)
                  (copy-recursively "src/com/google/javascript/rhino"
                                    (string-append doc "/rhino-source")))
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/" file)))
                     (mkdir-p (dirname target)) (copy-file file target)))
                 (find-files "." "(^|/)(COPYING|LICENSE|NOTICE)(\\..*)?$"))))))))
    (home-page home) (synopsis synopsis)
    (description "This pinned Java component is compiled from source for the
rot.js Closure Compiler.  Its build resolves dependencies from the store only,
without downloading executable artifacts.")
    (license licenses)))

;; Versions are from v20211201's WORKSPACE.bazel and its bazel-common pin
;; c4e23c9375b02fb44c5236f300743a85796fd461.  Guava's build-only annotations
;; additionally follow the 31.0.1-jre POM; they are not bundled in the compiler.
(define %guava-source
  (compiler-source
   "https://codeload.github.com/google/guava/tar.gz/refs/tags/v31.0.1"
   "15h60k02ak4rwa3aqsha832i3g36d4jrhvrkzni23h4h0f3n8nm6"
   "guava-31.0.1.tar.gz"))
(define %protobuf-source
  (compiler-source
   "https://github.com/protocolbuffers/protobuf/releases/download/v3.11.4/protobuf-java-3.11.4.tar.gz"
   "0yz43aqbc1mgrn2qqfs1b808q6wqv79hqq6jck3i3k2www654nbf"
   "protobuf-java-3.11.4.tar.gz"))

(define (maven-source group artifact version hash)
  (compiler-source
   (string-append "https://repo.maven.apache.org/maven2/" group "/" artifact "/"
                  version "/" artifact "-" version "-sources.jar")
   hash (string-append artifact "-" version "-sources.jar")))

(define java-error-prone-for-rot
  (compiler-java-package
   "java-error-prone-for-rot" "2.3.2"
   (maven-source "com/google/errorprone" "error_prone_annotations" "2.3.2"
                 "0ba0y6a6j4fmghgr4aqxm1wh9l6gny9021cc4abp19l22pnqirkw")
   "https://errorprone.info" "Error Prone annotations matching Closure 20211201"))
(define java-error-prone-for-rot-guava
  (compiler-java-package
   "java-error-prone-for-rot-guava" "2.7.1"
   (maven-source "com/google/errorprone" "error_prone_annotations" "2.7.1"
                 "08w9ciygxyfj8y8lw1bpw0nwg5ps4vj1viibs6mqxbdq33wj32g3")
   "https://errorprone.info" "Guava build annotations"))
(define java-checker-qual-for-rot
  (compiler-java-package
   "java-checker-qual-for-rot" "3.12.0"
   (maven-source "org/checkerframework" "checker-qual" "3.12.0"
                 "0xm8vx6vp6npmg662piz040ndaanf0w3042dc81ki2gdjm8s96gx")
   "https://checkerframework.org" "Guava type annotations"
   #:licenses license:expat #:legal-license #f))
(define java-j2objc-for-rot
  (compiler-java-package
   "java-j2objc-for-rot" "1.3"
   (maven-source "com/google/j2objc" "j2objc-annotations" "1.3"
                 "0wmr1d4nwfygza0f1ascmjvh41zgsg3053ggs16glly1zrlzckds")
   "https://github.com/google/j2objc" "Guava Objective-C annotations"))
(define java-jsr305-for-rot-guava
  (compiler-java-package
   "java-jsr305-for-rot-guava" "3.0.2"
   (maven-source "com/google/code/findbugs" "jsr305" "3.0.2"
                 "0fq6mai14sg5rj1swxfc90xha0qnqwl4iiqxb5m8qw6hfbi8b7hw")
   "https://sourceforge.net/projects/findbugs" "Guava JSR 305 annotations"
   #:licenses license:bsd-3 #:legal-license #f))
(define java-jsr250-for-rot
  (compiler-java-package
   "java-jsr250-for-rot" "1.0"
   (maven-source "javax/annotation" "jsr250-api" "1.0"
                 "0f7qnz2l2xw4xid7zmjvmhd6cx4ybw62l087ps0r66b0dkblfp02")
   "https://jcp.org/en/jsr/detail?id=250" "Common Java annotations"
   #:licenses license:cddl1.0 #:legal-license #f))
(define java-failureaccess-for-rot
  (compiler-java-package
   "java-failureaccess-for-rot" "1.0.1" %guava-source
   "https://github.com/google/guava" "Guava failure access support"
   #:roots '("futures/failureaccess/src")))
(define java-guava-for-rot
  (compiler-java-package
   "java-guava-for-rot" "31.0.1-jre" %guava-source
   "https://github.com/google/guava" "Guava matching Closure 20211201"
   #:roots '("guava/src")
   #:inputs (list java-failureaccess-for-rot)
   #:native-inputs (list java-jsr305-for-rot-guava java-error-prone-for-rot-guava
                         java-checker-qual-for-rot java-j2objc-for-rot)))
(define java-gson-for-rot
  (compiler-java-package
   "java-gson-for-rot" "2.7"
   (maven-source "com/google/code/gson" "gson" "2.7"
                 "0x0d1zdw56ap3qjh3826w1bla6klc20kafxab1ia5w1nv7aj0cid")
   "https://github.com/google/gson" "JSON library matching Closure 20211201"))
(define java-re2j-for-rot
  (compiler-java-package
   "java-re2j-for-rot" "1.3"
   (maven-source "com/google/re2j" "re2j" "1.3"
                 "0w146jy69a9ri38m05vf5lqq80h9avi3iw4i4jfsfvic2dxz7cw4")
   "https://github.com/google/re2j" "Linear-time regular expressions for Closure"
   ;; super/ is GWT translatable super-source; the JVM build uses Characters.java.
   #:exclude '("/super/")
   #:licenses license:bsd-3 #:legal-license #f))

(define protobuf-for-rot
  (package
    (name "protobuf-for-rot") (version "3.11.4") (source %protobuf-source)
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f
           #:configure-flags #~(list "CXXFLAGS=-O2 -std=c++11" "--disable-static")
           #:phases #~(modify-phases %standard-phases
                        (add-after 'unpack 'remove-vendored-tests
                          (lambda _
                            (delete-file-recursively "third_party/googletest")
                            (substitute* "configure"
                              (("subdirs=\"\\$subdirs third_party/googletest\"")
                               "subdirs=\"\"")))))))
    (inputs (list zlib))
    (home-page "https://protobuf.dev")
    (synopsis "Protocol buffer generator matching Closure 20211201")
    (description "This source-built version supplies the protoc generator used
by the Closure Compiler 20211201 build and its matching Java runtime.")
    (license license:bsd-3)))
(define java-protobuf-for-rot
  (compiler-java-package
   "java-protobuf-for-rot" "3.11.4" %protobuf-source
   "https://protobuf.dev" "Java protocol buffer runtime matching Closure 20211201"
   #:roots '("java/core/src/main/java" "build/proto")
   #:native-inputs (list protobuf-for-rot)
   #:licenses license:bsd-3 #:legal-license #f
   #:prepare
   #~(begin
       (mkdir-p "build/proto")
       (apply invoke "protoc" "--proto_path=src" "--java_out=build/proto"
              (map (lambda (file) (string-append "src/google/protobuf/" file ".proto"))
                   '("any" "api" "descriptor" "duration" "empty" "field_mask"
                     "source_context" "struct" "timestamp" "type" "wrappers"
                     "compiler/plugin"))))))

(define java-javapoet-for-rot
  (compiler-java-package
   "java-javapoet-for-rot" "1.13.0"
   (maven-source "com/squareup" "javapoet" "1.13.0"
                 "048zpf34r3l38lsgnz0n5kxp1w2676xaw161vhzlaikqg1kr0sfi")
   "https://github.com/square/javapoet" "Java source generation for AutoValue"))
(define java-auto-common-for-rot
  (compiler-java-package
   "java-auto-common-for-rot" "1.1.2"
   (maven-source "com/google/auto" "auto-common" "1.1.2"
                 "19gnphqr37c5fbmfq3r0pi957f6ws7s6fpqw2m6xdkxpg4l08974")
   "https://github.com/google/auto" "Annotation processor utilities"
   #:inputs (list java-guava-for-rot java-failureaccess-for-rot java-javapoet-for-rot
                  java-checker-qual-for-rot)))
(define java-auto-service-for-rot
  (compiler-java-package
   "java-auto-service-for-rot" "1.0"
   (maven-source "com/google/auto/service" "auto-service-annotations" "1.0"
                 "0i7dr81l670kzpgi3xcjkhyzz9hh2p5438i9cmr679xar2az8qx0")
   "https://github.com/google/auto" "Service annotations for AutoValue"))
(define %auto-source
  (compiler-source
   "https://codeload.github.com/google/auto/tar.gz/refs/tags/auto-value-1.6"
   "0w4ff2d65r7j3bqpkakfpvpqvw6hga3agrxhxwjqwk66sq1x5qs8"
   "auto-value-1.6.tar.gz"))
(define java-auto-value-annotations-for-rot
  (compiler-java-package
   "java-auto-value-annotations-for-rot" "1.6" %auto-source
   "https://github.com/google/auto" "AutoValue annotations matching Closure"
   #:roots '("value/src/main/java")
   #:exclude '("/processor/" "AutoValueExtension\\.java$")))
(define java-auto-value-for-rot
  (compiler-java-package
   "java-auto-value-for-rot" "1.6" %auto-source
   "https://github.com/google/auto" "AutoValue processor matching Closure 20211201"
   #:roots '("value/src/main/java")
   #:inputs (list java-guava-for-rot java-failureaccess-for-rot
                  java-jsr305 java-error-prone-for-rot java-checker-qual-for-rot
                  java-auto-common-for-rot java-auto-service-for-rot
                  java-javapoet-for-rot)
   #:finish
   #~(begin
       ;; Bootstrap the service registrations declared by upstream @AutoService.
       (mkdir-p "build/classes/META-INF/services")
       (call-with-output-file
           "build/classes/META-INF/services/javax.annotation.processing.Processor"
         (lambda (port)
           (display "com.google.auto.value.processor.AutoValueProcessor\ncom.google.auto.value.processor.AutoValueBuilderProcessor\ncom.google.auto.value.processor.AutoAnnotationProcessor\ncom.google.auto.value.processor.AutoOneOfProcessor\ncom.google.auto.value.extension.memoized.processor.MemoizedValidator\n" port)))
       (call-with-output-file
           "build/classes/META-INF/services/com.google.auto.value.extension.AutoValueExtension"
         (lambda (port)
           (display "com.google.auto.value.extension.memoized.processor.MemoizeExtension\n" port))))))

(define %closure-runtime-inputs
  (list java-args4j java-jsr305 java-jsr250-for-rot java-guava-for-rot
        java-failureaccess-for-rot java-gson-for-rot java-error-prone-for-rot
        java-auto-value-annotations-for-rot java-protobuf-for-rot java-re2j-for-rot
        ant-for-rot))

(define-public rot-js-closure-compiler
  (compiler-java-package
   "rot-js-closure-compiler" "20211201.0.0"
   (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/google/closure-compiler")
           ;; Tag v20211201.
           (commit "0c03641ae285b528d00cf7770c94b07759a28f12")))
     (file-name (git-file-name "rot-js-closure-compiler" "20211201.0.0"))
     (sha256 (base32 "0w88bkzsjs9byhhshrz3zihk778b9bwaj6j3749020304lgkmvif")))
   "https://github.com/google/closure-compiler"
   "Source-built JavaScript compiler matching rot.js's upstream pin"
   #:roots '("src" "build/proto")
   #:inputs %closure-runtime-inputs
   #:native-inputs
   (list protobuf-for-rot java-auto-value-for-rot java-auto-common-for-rot
         java-auto-service-for-rot java-javapoet-for-rot java-checker-qual-for-rot node)
   ;; Resource exclusions match the upstream release jar: build metadata,
   ;; proto definitions, Javadoc package pages and test fixtures stay out.
   #:exclude '("/(debugger|j2clbuild|j2cl|super[^/]*|testing|webservice)/"
               "resources/resources\\.json$" "build_resources\\.js$"
               "build_polyfill_table\\.js$" "\\.gwt\\.xml$" "BUILD\\.bazel$"
               "\\.proto$" "package\\.html$" "\\.textproto$"
               "SourceMapObjectParser\\.externs\\.js$")
   #:processor "com.google.auto.value.processor.AutoValueProcessor,com.google.auto.value.processor.AutoValueBuilderProcessor,com.google.auto.value.processor.AutoAnnotationProcessor,com.google.auto.value.processor.AutoOneOfProcessor"
   #:compiler? #t
   ;; Rhino sources are MPL 1.1 or GPL 2+; bundled dependencies add the rest.
   #:licenses (list license:asl2.0 license:mpl1.1 license:gpl2+ license:expat
                    license:bsd-3 license:cddl1.0)
   #:prepare
   #~(begin
       (mkdir-p "build/proto")
       ;; Proto imports are relative to the repository root, as in BUILD.bazel.
       (apply invoke "protoc" "--proto_path=." "--java_out=build/proto"
              (sort (find-files "src" "\\.proto$") string<?))
       (substitute* "src/com/google/javascript/jscomp/CommandLineRunner.java"
         (("inlineDefine_COMPILER_VERSION") "\"v20211201\""))
       (with-directory-excursion "src/com/google/javascript/jscomp"
         (with-output-to-file "js/polyfills.txt"
           (lambda ()
             (apply invoke "node" "js/build_polyfill_table.js"
                    (sort (filter (lambda (file)
                                    (not (string-suffix? "build_polyfill_table.js" file)))
                                  (find-files "./js" "\\.js$")) string<?))))))
   #:finish
   #~(begin
       (let ((target (string-append (getcwd) "/build/classes/externs.zip")))
         (with-directory-excursion "externs"
           (let ((files (sort (find-files "." "\\.js$") string<?)))
             (for-each (lambda (file) (utime file 315532800 315532800)) files)
             (apply invoke "zip" "-X" target files))))
       ;; Build the unshaded, self-contained jar from source-built dependencies.
       ;; Ant keeps jars under /lib; only ant.jar belongs in the compiler.
       (for-each
        (lambda (input)
          (for-each
           (lambda (jar)
             (with-directory-excursion "build/classes" (invoke "jar" "xf" jar)))
           (find-files (string-append input "/share/java") "\\.jar$")))
        (list #$@(filter (lambda (input) (not (eq? input ant-for-rot)))
                        %closure-runtime-inputs)))
       (with-directory-excursion "build/classes"
         (invoke "jar" "xf" #$(file-append ant-for-rot "/lib/ant.jar")))
       ;; Match upstream's two-stage runtime_libs_typedast action.  The compiler
       ;; first compiles without typed ASTs, then generates and bundles the real
       ;; runtime AST resource; this is code generation, not a test/smoke run.
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
