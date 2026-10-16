;;; Offline Java/JNI build phases for the desktop controller stack.

(define-module (tay packages exppd-controllers-build)
  #:use-module (guix gexp)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages java)
  #:export (exppd-controllers-phases))

(define (exppd-controllers-phases jamepad jnigen controllerdb)
  #~(modify-phases %standard-phases
      (delete 'bootstrap)
      (delete 'configure)
      (add-after 'unpack 'prepare-controller-sources
        (lambda _
          (setenv "TZ" "UTC")
          (setenv "SOURCE_DATE_EPOCH" "315532802")
          (setenv "JAVA_HOME" #$openjdk17:jdk)
          (setenv "PATH" (string-append #$openjdk17:jdk "/bin:"
                                        (getenv "PATH")))
          ;; Preserve every cleaned source file, including upstream notices and
          ;; build descriptions, outside the tree before adding build products.
          (copy-recursively "." "../controller-sources/controllers")
          (for-each
           (lambda (entry)
             (let ((dir (string-append "deps/" (car entry))))
               (mkdir-p dir)
               (invoke "tar" "xf" (cdr entry) "--strip-components=1" "-C" dir)
               (copy-recursively dir
                                 (string-append "../controller-sources/"
                                                (car entry)))))
           (list (cons "jamepad" #$jamepad)
                 (cons "jnigen" #$jnigen)
                 (cons "controllerdb" #$controllerdb)))
          ;; Preserve Jamepad's historical mapping resource in the source tree;
          ;; the single runtime resource is explicitly pinned to controllerdb.
          (mkdir-p "build/classes/META-INF")))
      (replace 'build
        (lambda* (#:key inputs #:allow-other-keys)
          (define javac (string-append #$openjdk17:jdk "/bin/javac"))
          (define java (string-append #$openjdk17:jdk "/bin/java"))
          (define (java-files root) (sort (find-files root "\\.java$") string<?))
          (define (compile destination classpath sources)
            (mkdir-p destination)
            (apply invoke javac "--release" "8" "-encoding" "UTF-8"
                   "-proc:none" "-classpath" classpath "-d" destination sources))
          (let* ((gdx (search-input-file inputs "/share/java/gdx.jar"))
                 (lwjgl (search-input-file inputs "/share/java/lwjgl.jar"))
                 (parser (search-input-file inputs
                                            "/share/java/javaparser-core.jar"))
                 (classpath (string-append gdx ":" lwjgl))
                 (generator-root
                  "deps/jnigen/gdx-jnigen/src/main/java/com/badlogic/gdx/jnigen")
                 (generator-classpath (string-append "build/generator:" parser))
                 (sdl-include (search-input-directory inputs "/include/SDL2"))
                 (sdl-lib (dirname (search-input-file inputs "/lib/libSDL2.so"))))
            ;; Loader classes belong exclusively to gdx.jar.  Compile the real
            ;; upstream generator separately; no Gradle plugin is involved.
            (compile
             "build/generator" parser
             (append
              (map (lambda (name) (string-append generator-root "/" name ".java"))
                   '("NativeCodeGenerator" "FileDescriptor" "AntPathMatcher"))
              (java-files (string-append generator-root "/parsing"))))
            (compile
             "build/classes" classpath
             (append
              (java-files "gdx-controllers-core/src/main/java")
              (java-files "gdx-controllers-desktop/src/main/java")
              (java-files "deps/jamepad/src/main/java")))
            (call-with-output-file "build/GenerateJamepad.java"
              (lambda (port)
                (display
                 "// Guix driver for the unmodified upstream JNI generator.\nimport com.badlogic.gdx.jnigen.NativeCodeGenerator;\npublic final class GenerateJamepad {\n public static void main(String[] args) throws Exception {\n  new NativeCodeGenerator().generate(args[0], args[1], args[2]);\n }\n}\n"
                 port)))
            (compile "build/generator" generator-classpath
                     '("build/GenerateJamepad.java"))
            ;; NativeCodeGenerator uses javac -h and the native bodies embedded
            ;; in the original Java comments, including its string/array JNI
            ;; marshalling.  No replacement or handwritten bindings are used.
            (invoke java "-Dfile.encoding=UTF-8" "-classpath" generator-classpath
                    "GenerateJamepad" "deps/jamepad/src/main/java"
                    (string-append (getcwd) "/build/classes:" classpath)
                    "build/jni")
            (apply invoke "g++" "-std=c++11" "-O2" "-fPIC" "-shared"
                   "-fvisibility=hidden" "-Wl,--no-undefined"
                   "-Wl,-soname,libjamepad64.so"
                   (string-append "-I" #$openjdk17:jdk "/include")
                   (string-append "-I" #$openjdk17:jdk "/include/linux")
                   (string-append "-I" sdl-include) "-Ibuild/jni"
                   "-o" "build/libjamepad64.so"
                   (append (sort (find-files "build/jni" "\\.cpp$") string<?)
                           (list (string-append "-L" sdl-lib)
                                 (string-append "-Wl,-rpath," sdl-lib)
                                 (string-append "-Wl,-rpath," #$gcc:lib "/lib")
                                 "-lSDL2"))))
          ;; Reproduce upstream's desktop section filtering, using the immutable
          ;; source origin rather than downloading master during the build.
          (call-with-input-file "deps/controllerdb/gamecontrollerdb.txt"
            (lambda (input)
              (call-with-output-file "build/classes/gamecontrollerdb.txt"
                (lambda (output)
                  (display "# Guix desktop-only filtering of the pinned upstream database.\n" output)
                  (let loop ((section ""))
                    (let ((line (get-line input)))
                      (unless (eof-object? line)
                        (let ((next (if (string-prefix? "# " line)
                                        (substring line 2) section)))
                          (unless (member next '("Android" "iOS"))
                            (display line output) (newline output))
                          (loop next)))))))))
          (call-with-output-file "build/classes/META-INF/MANIFEST.MF"
            (lambda (port)
              (display "Manifest-Version: 1.0\nImplementation-Version: 2.2.4\n\n"
                       port)))
          ;; ZIP timestamps are normalized and entries sorted.  Do not depend
          ;; on jar --date (absent from older source-bootstrap JDK toolchains).
          (with-directory-excursion "build/classes"
            (let ((files (sort (find-files ".") string<?)))
              (for-each (lambda (file) (utime file 315532802 315532802)) files)
              (apply invoke "zip" "-q" "-X" "../gdx-controllers.jar" files)))))
      (replace 'install
        (lambda* (#:key outputs #:allow-other-keys)
          (let* ((out (assoc-ref outputs "out"))
                 (doc (string-append out "/share/doc/java-exppd-controllers"))
                 (sources (string-append out "/share/src/java-exppd-controllers")))
            (install-file "build/gdx-controllers.jar" (string-append out "/share/java"))
            (install-file "build/libjamepad64.so" (string-append out "/lib"))
            (copy-recursively "../controller-sources" sources)
            (copy-recursively "build/jni" (string-append sources "/generated-jni"))
            (install-file "build/GenerateJamepad.java"
                          (string-append sources "/generated-jni"))
            (for-each
             (lambda (component)
               (let ((root (string-append sources "/" component)))
                 (for-each
                  (lambda (file)
                    (let ((dest (string-append doc "/" component "/"
                                               (dirname (substring file
                                                                   (+ 1 (string-length root)))))))
                      (install-file file dest)))
                  (find-files root
                              "(^|/)(LICENSE|LICENCE|NOTICE|COPYING|COPYRIGHT|AUTHORS)([._-].*)?$"))))
             '("controllers" "jamepad" "jnigen" "controllerdb")))))))
