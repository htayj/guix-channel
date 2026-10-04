;;; Source-built Closure Compiler matching LiteGraph's 20171112.0.0 lock pin.
(define-module (tay packages litegraph-compiler)
  #:use-module (guix packages)
  #:use-module (guix download)
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

;; Source jars are unpacked as source, never used on the Java class path.
;; The build is offline; Maven's resolver and binary shade plugin are not used.
(define* (compiler-java-package name version source home synopsis
                                #:key (roots '("src"))
                                (inputs '()) (native-inputs '()) (exclude '())
                                (prepare #~#t) (finish #~#t)
                                (processor #f) (compiler-alias? #f)
                                (licenses license:asl2.0)
                                (legal-license %apache-license))
  (define dependencies inputs)
  (define build-dependencies native-inputs)
  (package
    (name name) (version version) (source source)
    (build-system ant-build-system)
    (inputs dependencies)
    (native-inputs build-dependencies)
    (arguments
     (list
      #:jdk icedtea-8
      #:tests? #f ; Upstream test dependencies are not part of this compiler closure.
      #:modules '((guix build ant-build-system) (guix build utils)
                  (ice-9 regex) (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (define (excluded? file)
                (any (lambda (pattern) (string-match pattern file)) '#$exclude))
              #$prepare
              (mkdir-p "build/classes")
              (mkdir-p "build/generated")
              (let ((sources
                     (sort (filter (lambda (file) (not (excluded? file)))
                                   (append-map (lambda (root)
                                                 (find-files root "\\.java$"))
                                               '#$roots)) string<?)))
                (call-with-output-file "build/sources.list"
                  (lambda (port)
                    (for-each (lambda (file) (format port "~s~%" file)) sources)))
                (apply invoke "javac" "-encoding" "UTF-8" "-source" "8" "-target" "8"
                       "-classpath" (getenv "CLASSPATH")
                       (append (if #$processor
                                   (list "-processor" #$processor
                                         "-processorpath" (getenv "CLASSPATH")
                                         "-s" "build/generated")
                                   (list "-proc:none"))
                               (list "-d" "build/classes" "@build/sources.list"))))
              (for-each
               (lambda (root)
                 (for-each
                  (lambda (file)
                    (unless (or (excluded? file)
                                (string-match "(\\.java|\\.class|\\.jar)$" file)
                                (string-suffix? "META-INF/MANIFEST.MF" file))
                      (let* ((relative (string-drop file (+ 1 (string-length root))))
                             (target (string-append "build/classes/" relative)))
                        (mkdir-p (dirname target))
                        (copy-file file target))))
                  (find-files root))) '#$roots)
              #$finish
              (if (file-exists? "build/classes/META-INF/MANIFEST.MF")
                  (invoke "jar" "cfm" (string-append "build/" #$name ".jar")
                          "build/classes/META-INF/MANIFEST.MF" "-C" "build/classes" ".")
                  (invoke "jar" "cf" (string-append "build/" #$name ".jar")
                          "-C" "build/classes" "."))))
          (add-after 'build 'archive-source-notices
            (lambda _
              (mkdir-p "build/source-notices")
              (for-each
               (lambda (root)
                 (for-each
                  (lambda (file)
                    (when (or (string-suffix? ".java" file)
                              (string-suffix? ".properties" file))
                      (let ((target (string-append "build/source-notices/" file)))
                        (mkdir-p (dirname target)) (copy-file file target))))
                  (find-files root))) '#$roots)
              (invoke "tar" "--sort=name" "--mtime=@315532800"
                      "--owner=0" "--group=0" "--numeric-owner"
                      "-cf" "build/copyright-sources.tar"
                      "-C" "build/source-notices" ".")))
          (replace 'install
            (lambda _
              (install-file (string-append "build/" #$name ".jar")
                            (string-append #$output "/share/java"))
              (when #$compiler-alias?
                (symlink (string-append #$name ".jar")
                         (string-append #$output "/share/java/closure-compiler.jar"))
                (symlink (string-append #$name ".jar")
                         (string-append #$output "/share/java/compiler.jar")))
              (let ((doc (string-append #$output "/share/doc/" #$name)))
                (mkdir-p doc)
                (install-file "build/copyright-sources.tar" doc)
                (when #$legal-license
                  (copy-file #$legal-license (string-append doc "/LICENSE.external")))
                (when #$compiler-alias?
                  (for-each
                   (lambda (input)
                     (let ((source (string-append input "/share/doc")))
                       (when (file-exists? source)
                         (copy-recursively source
                                           (string-append doc "/dependencies/"
                                                          (basename input))))))
                   (list #$@dependencies))
                  (copy-file #$%mozilla-license (string-append doc "/MPL-1.1.txt"))
                  (install-file "README.md" doc)
                  ;; Rhino notices and dependency copyright/license headers
                  ;; remain available alongside the self-contained bytecode.
                  (copy-recursively "src/com/google/javascript/rhino"
                                    (string-append doc "/rhino-source")))
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/" file)))
                     (mkdir-p (dirname target)) (copy-file file target)))
                 (find-files "." "(^|/)(COPYING|LICENSE|NOTICE)(\\..*)?$"))))))))
    (home-page home)
    (synopsis synopsis)
    (description "This pinned Java component is compiled from source for the
LiteGraph Closure Compiler.  Its build resolves dependencies only from the
store and never downloads executable artifacts.")
    (license licenses)))

(define %auto-source
  (compiler-source
   "https://codeload.github.com/google/auto/tar.gz/refs/tags/auto-value-1.4.1"
   "1qd59bwa56bynsdxfbgm40i7ndrj599wflza214kzigk16nprc1m" "auto-1.4.1.tar.gz"))

(define %protobuf-source
  (compiler-source
   "https://github.com/protocolbuffers/protobuf/releases/download/v3.0.2/protobuf-java-3.0.2.tar.gz"
   "1a225l3wmnqn51ncmhg917sbwp2pf1d9la8xgi6w040r7b2cfm9p" "protobuf-3.0.2.tar.gz"))

(define protobuf-for-litegraph
  (package
    (name "protobuf-for-litegraph") (version "3.0.2")
    (source %protobuf-source)
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f ; The release vendors gmock; do not compile that test dependency.
           #:configure-flags #~(list "CXXFLAGS=-O2 -std=c++11" "--disable-static")
           #:phases #~(modify-phases %standard-phases
                        (add-after 'unpack 'remove-vendored-tests
                          (lambda _
                            (delete-file-recursively "gmock")
                            ;; configure recursively configures gmock even
                            ;; when its check target is disabled.
                            (substitute* "configure"
                              (("subdirs=\"\\$subdirs gmock\"") "subdirs=\"\"")))))))
    (inputs (list zlib))
    (home-page "https://protobuf.dev")
    (synopsis "Protocol buffer generator matching Closure Compiler 20171112")
    (description "This version provides the protoc generator required to build
Closure Compiler and its Java protocol buffer runtime from matching sources.")
    (license license:bsd-3)))

(define java-protobuf-for-litegraph
  (compiler-java-package
   "java-protobuf-for-litegraph" "3.0.2" %protobuf-source
   "https://protobuf.dev" "Java protocol buffer runtime for Closure Compiler"
   #:legal-license #f
   #:roots '("java/core/src/main/java" "build/proto")
   #:native-inputs (list protobuf-for-litegraph)
   #:licenses license:bsd-3
   #:prepare
   #~(begin
       (mkdir-p "build/proto")
       (apply invoke "protoc" "--proto_path=src" "--java_out=build/proto"
              (map (lambda (file) (string-append "src/google/protobuf/" file ".proto"))
                   '("any" "api" "descriptor" "duration" "empty" "field_mask"
                     "source_context" "struct" "timestamp" "type" "wrappers"
                     "compiler/plugin"))))
   #:finish
   #~(for-each
      (lambda (file)
        (let ((target (string-append "build/classes/" (string-drop file 4))))
          (mkdir-p (dirname target)) (copy-file file target)))
      (find-files "src/google/protobuf" "\\.proto$"))))

(define java-jsinterop-for-litegraph
  (compiler-java-package
   "java-jsinterop-for-litegraph" "1.0.0"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/google/jsinterop/jsinterop-annotations/1.0.0/jsinterop-annotations-1.0.0-sources.jar"
    "11wg8x67pishcn42flfpkk8mn31zdxbkjykvhfwjzbinfw8krml0" "jsinterop-sources.jar")
   "https://github.com/google/jsinterop-annotations" "JsInterop annotations"))

(define java-error-prone-for-litegraph
  (compiler-java-package
   "java-error-prone-for-litegraph" "2.0.18"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.0.18/error_prone_annotations-2.0.18-sources.jar"
    "1gj7f3s8vjpfmm83wv0c7km56qsmfdrard06qgah8isqs2fv9ryv" "error-prone-sources.jar")
   "https://errorprone.info" "Error Prone annotations for Closure Compiler"))

(define java-gson-for-litegraph
  (compiler-java-package
   "java-gson-for-litegraph" "2.7"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/google/code/gson/gson/2.7/gson-2.7-sources.jar"
    "0x0d1zdw56ap3qjh3826w1bla6klc20kafxab1ia5w1nv7aj0cid" "gson-sources.jar")
   "https://github.com/google/gson" "JSON library matching Closure Compiler"))

(define java-guava-for-litegraph
  (compiler-java-package
   "java-guava-for-litegraph" "20.0"
   (compiler-source
    "https://codeload.github.com/google/guava/tar.gz/refs/tags/v20.0"
    "1azps1r215igpgyjidi2cbxidblj2w7dc896nnh7km38mjh3baai" "guava-20.0.tar.gz")
   "https://github.com/google/guava" "Guava matching Closure Compiler 20171112"
   #:roots '("guava/src")
   #:inputs (list java-jsr305 java-error-prone-for-litegraph)
   #:prepare
   #~(substitute* (find-files "guava/src" "\\.java$")
       ;; Like Guix's Guava recipe, remove only Objective-C/Android annotations.
       (("import com.google.j2objc[^;]*;") "")
       (("import org.codehaus.mojo.animal_sniffer[^;]*;") "")
       (("@J2ObjCIncompatible|@WeakOuter|@RetainedWith|@Weak|@IgnoreJRERequirement") ""))))

(define java-javapoet-for-litegraph
  (compiler-java-package
   "java-javapoet-for-litegraph" "1.7.0"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/squareup/javapoet/1.7.0/javapoet-1.7.0-sources.jar"
    "064g5ipyrx49fyxg1gmxr7bdh24b7bp5x8fl8fr5x1v7g3y3lrzy" "javapoet-sources.jar")
   "https://github.com/square/javapoet" "Java source generation for AutoValue"))

(define java-auto-common-for-litegraph
  (compiler-java-package
   "java-auto-common-for-litegraph" "0.8"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/google/auto/auto-common/0.8/auto-common-0.8-sources.jar"
    "1v5br48jvydcxckc2zq73rv8cs7akx5s1vr2rzyqzp33i708n98y" "auto-common-sources.jar")
   "https://github.com/google/auto" "Annotation processor utilities"
   #:inputs (list java-guava-for-litegraph)))

(define java-auto-service-for-litegraph
  (compiler-java-package
   "java-auto-service-for-litegraph" "1.0-rc2"
   (compiler-source
    "https://repo.maven.apache.org/maven2/com/google/auto/service/auto-service/1.0-rc2/auto-service-1.0-rc2-sources.jar"
    "1g3xxdwr7l7468wk6fq7rghzs7h88bcdy0hz8yi3ksmmxwpwm3ws" "auto-service-sources.jar")
   "https://github.com/google/auto" "AutoService annotation for AutoValue"
   ;; AutoValue needs the annotation, not the service annotation processor.
   #:roots '("src/com/google/auto/service")
   #:exclude '("/processor/")))

(define java-auto-value-for-litegraph
  (compiler-java-package
   "java-auto-value-for-litegraph" "1.4.1" %auto-source
   "https://github.com/google/auto" "AutoValue processor matching Closure Compiler"
   #:roots '("value/src/main/java")
   #:inputs (list java-guava-for-litegraph java-auto-common-for-litegraph
                  java-auto-service-for-litegraph java-javapoet-for-litegraph)
   #:finish
   #~(begin
       ;; Bootstrap without AutoService's processor; these are upstream's
       ;; @AutoService declarations, including its memoization extension.
       (mkdir-p "build/classes/META-INF/services")
       (call-with-output-file
           "build/classes/META-INF/services/javax.annotation.processing.Processor"
         (lambda (port)
           (display "com.google.auto.value.processor.AutoValueProcessor\ncom.google.auto.value.processor.AutoValueBuilderProcessor\ncom.google.auto.value.processor.AutoAnnotationProcessor\n" port)))
       (call-with-output-file
           "build/classes/META-INF/services/com.google.auto.value.extension.AutoValueExtension"
         (lambda (port)
           (display "com.google.auto.value.extension.memoized.MemoizeExtension\n" port))))))

(define %closure-runtime-inputs
  (list java-args4j java-jsr305 java-guava-for-litegraph java-gson-for-litegraph
        java-error-prone-for-litegraph java-jsinterop-for-litegraph
        java-protobuf-for-litegraph))

(define-public litegraph-closure-compiler
  (package
    (inherit
     (compiler-java-package
      "litegraph-closure-compiler" "20171112"
      (compiler-source
       "https://codeload.github.com/google/closure-compiler/tar.gz/refs/tags/v20171112"
       "0gz1w6p3yiahz155xcrkzz7k9rwih58njl97kh3da9xcg0b9pvim" "closure-compiler-20171112.tar.gz")
      "https://github.com/google/closure-compiler" "Source-built JavaScript optimizing compiler"
      #:roots '("src" "build/proto")
      #:inputs %closure-runtime-inputs
      #:native-inputs (list protobuf-for-litegraph java-auto-value-for-litegraph
                            java-auto-common-for-litegraph java-javapoet-for-litegraph
                            java-auto-service-for-litegraph node)
      #:exclude '("/(debugger|gwt|super-gwt|super|testing|webservice)/"
                   "\\.gwt\\.xml$")
      #:processor "com.google.auto.value.processor.AutoValueProcessor,com.google.auto.value.processor.AutoValueBuilderProcessor,com.google.auto.value.processor.AutoAnnotationProcessor"
      #:compiler-alias? #t
      #:licenses (list license:asl2.0 license:mpl1.1 license:gpl2+
                       license:expat license:bsd-3)
      #:prepare
      #~(begin
          (delete-file-recursively "gen")
          (delete-file "src/com/google/javascript/jscomp/resources.json")
          (mkdir-p "build/proto")
          (invoke "protoc" "--proto_path=src" "--java_out=build/proto"
                  "src/com/google/debugging/sourcemap/proto/mapping.proto"
                  "src/com/google/javascript/jscomp/conformance.proto"
                  "src/com/google/javascript/jscomp/function_info.proto"
                  "src/com/google/javascript/jscomp/instrumentation_template.proto")
          (substitute* "src/com/google/javascript/jscomp/parsing/ParserConfig.properties"
            (("\\$\\{compiler.version\\}") "v20171112")
            (("\\$\\{compiler.date\\}") "2017-11-12 00:00"))
          (with-directory-excursion "src/com/google/javascript/jscomp"
            ;; The generator strips everything through /js/.  The leading ./
            ;; is significant: bare js/ paths incorrectly retain that prefix.
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
          ;; Make the command-line jar self-contained without binary shading.
          ;; Keep dependency classes intact (no relocation or minimization).
          (for-each
           (lambda (input)
             (for-each
              (lambda (jar)
                (with-directory-excursion "build/classes" (invoke "jar" "xf" jar)))
              (find-files (string-append input "/share/java") "\\.jar$")))
           (list #$@%closure-runtime-inputs))
          (for-each delete-file
                    (find-files "build/classes/META-INF" "(INDEX\\.LIST|.*\\.(SF|RSA|DSA))$"))
          (for-each delete-file (find-files "build/classes" "\\.gwt\\.xml$"))
          (when (file-exists? "build/classes/META-INF/MANIFEST.MF")
            (delete-file "build/classes/META-INF/MANIFEST.MF"))
          (call-with-output-file "build/classes/META-INF/MANIFEST.MF"
            (lambda (port)
              (display "Manifest-Version: 1.0\nMain-Class: com.google.javascript.jscomp.CommandLineRunner\n\n" port))))))
    ))
