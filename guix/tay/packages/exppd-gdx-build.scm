;;; Build-side implementation of the source-only LibGDX desktop closure.
(define-module (tay packages exppd-gdx-build)
  #:use-module (guix build utils)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (exppd-gdx-prepare exppd-gdx-build exppd-gdx-install))

(define (unpack-source archive directory)
  (mkdir-p directory)
  (invoke "tar" "xf" archive "-C" directory "--strip-components=1"))

(define (replace-between file start end replacement)
  (let* ((text (call-with-input-file file get-string-all))
         (first (string-contains text start))
         (last (and first (string-contains text end (+ first (string-length start))))))
    (unless (and first last) (error "upstream source boundary changed" file start end))
    (call-with-output-file file
      (lambda (port)
        (display (string-take text first) port)
        (display replacement port)
        (display (string-drop text last) port)))))

(define (legal-file? file)
  (string-match "(^|/)([^/]*LICENSE[^/]*|LICENCE[^/]*|NOTICE[^/]*|COPYING[^/]*|COPYRIGHT[^/]*|AUTHORS[^/]*)$" file))

(define (exppd-gdx-prepare jnigen jlayer jorbis lgpl gpl)
  (setenv "TZ" "UTC")
  (setenv "SOURCE_DATE_EPOCH" "315532802")
  (unpack-source jnigen "deps/jnigen")
  (unpack-source jorbis "deps/jorbis")
  (mkdir-p "deps/jlayer")
  (invoke "unzip" "-q" jlayer "-d" "deps/jlayer")
  (for-each delete-file
            (find-files "deps" "\\.(class|jar|zip|so|dll|dylib|jnilib|a|o|exe)(\\.[0-9]+)*$"))
  (copy-file lgpl "deps/jlayer/COPYING.LIB")
  (copy-file gpl "deps/jlayer/COPYING")
  ;; Keep the complete upstream public loader API and filename mapping.  Only
  ;; its private native loading path changes: no opaque jar extraction fallback.
  (let ((loader "deps/jnigen/gdx-jnigen-loader/src/main/java/com/badlogic/gdx/utils/SharedLibraryLoader.java"))
    (replace-between
     loader
     "\t/** Extracts the source file and calls System.load."
     "\t/** Sets the library as loaded,"
     "\t/** Loads a source-built native from an explicit store directory. */
\tprivate void loadFile (String sourcePath) {
\t\tString searchPath = System.getProperty(\"exppd.native.path\", \"\");
\t\tfor (String directory : searchPath.split(File.pathSeparator)) {
\t\t\tif (directory.length() == 0) continue;
\t\t\tFile file = new File(directory, sourcePath);
\t\t\tif (file.isAbsolute() && file.isFile()) {
\t\t\t\tSystem.load(file.getAbsolutePath());
\t\t\t\treturn;
\t\t\t}
\t\t}
\t\tthrow new SharedLibraryLoadRuntimeException(\"Source-built native not found: \" + sourcePath
\t\t\t+ \" in exppd.native.path=\" + searchPath);
\t}

"))
  ;; Take the source snapshot before any compiler runs.  Preserve all upstream
  ;; files, including non-desktop code and the embedded stb/ETC1 notices.
  (let ((entries (scandir ".")))
    (mkdir-p "source-closure/libgdx")
    (for-each
     (lambda (entry)
       (unless (member entry '("." ".." "deps" "source-closure"))
         (let ((destination (string-append "source-closure/libgdx/" entry)))
           (if (file-is-directory? entry)
               (copy-recursively entry destination)
               (copy-file entry destination)))))
     entries))
  (copy-recursively "deps" "source-closure/deps")
  #t)

(define (java-sources roots)
  (sort (append-map (lambda (root) (find-files root "\\.java$")) roots) string<?))

(define (compile-java javac directory classpath sources)
  (unless (pair? sources) (error "empty Java compilation" directory))
  (mkdir-p directory)
  (let ((arguments (string-append directory ".sources")))
    (call-with-output-file arguments
      (lambda (port)
        (for-each (lambda (source) (format port "~s~%" source)) sources)))
    (invoke javac "--release" "8" "-encoding" "UTF-8" "-proc:none"
            "-classpath" classpath "-d" directory (string-append "@" arguments))))

(define (copy-resources root target)
  (when (file-exists? root)
    (for-each
     (lambda (file)
       (unless (string-match "\\.(java|class|jar)$" file)
         (let ((destination (string-append target "/" (string-drop file (+ 1 (string-length root))))))
           (mkdir-p (dirname destination))
           (copy-file file destination))))
     (find-files root))))

(define (exppd-gdx-build jdk parser lwjgl freetype output)
  (define javac (string-append jdk "/bin/javac"))
  (define java (string-append jdk "/bin/java"))
  (define classpath (string-append lwjgl "/share/java/lwjgl.jar"))
  (define parser-path (string-join (find-files (string-append parser "/share/java") "\\.jar$") ":"))
  (define source-roots
    '("gdx/src" "extensions/gdx-freetype/src" "backends/gdx-backend-lwjgl3/src"
      "deps/jnigen/gdx-jnigen-loader/src/main/java" "deps/jlayer/javazoom"
      "deps/jorbis/com/jcraft/jogg" "deps/jorbis/com/jcraft/jorbis"))
  (setenv "JAVA_HOME" jdk)
  (setenv "PATH" (string-append jdk "/bin:" (getenv "PATH")))
  (compile-java javac "build/classes" classpath (java-sources source-roots))
  (copy-resources "gdx/res" "build/classes")
  (copy-resources "extensions/gdx-freetype/res" "build/classes")
  (copy-resources "backends/gdx-backend-lwjgl3/res" "build/classes")
  (copy-file "deps/jlayer/sfd.ser" "build/classes/sfd.ser")
  ;; The real upstream generator parses the embedded JNI method bodies and
  ;; uses javac -h for signatures.  No handwritten native-method substitute.
  (compile-java javac "build/generator" parser-path
                (java-sources '("deps/jnigen/gdx-jnigen/src/main/java")))
  (call-with-output-file "build/Generate.java"
    (lambda (port)
      (display "import com.badlogic.gdx.jnigen.NativeCodeGenerator;
public final class Generate {
  public static void main(String[] a) throws Exception {
    new NativeCodeGenerator().generate(a[0], a[1], a[2]);
  }
}
" port)))
  (compile-java javac "build/generator" "build/generator" '("build/Generate.java"))
  (let ((generator-path (string-append "build/generator:" parser-path))
        (game-path (string-append (getcwd) "/build/classes:" classpath)))
    (invoke java "-classpath" generator-path "Generate" "gdx/src" game-path "build/jni/gdx")
    (invoke java "-classpath" generator-path "Generate" "extensions/gdx-freetype/src"
            game-path "build/jni/freetype"))
  (mkdir-p "build/native")
  ;; gdx2d is C, not C++; preserve its C linkage through the JNI glue.
  (invoke "gcc" "-std=gnu99" "-O2" "-fPIC" "-c" "gdx/jni/gdx2d/gdx2d.c"
          (string-append "-I" jdk "/include")
          (string-append "-I" jdk "/include/linux")
          "-o" "build/native/gdx2d.o")
  (let ((jni-includes (list (string-append "-I" jdk "/include")
                            (string-append "-I" jdk "/include/linux"))))
    (apply invoke "g++" "-std=c++11" "-O2" "-fPIC" "-shared" "-Wl,-z,defs"
           "-Igdx/jni" "-Ibuild/jni/gdx" "-o" "build/native/libgdx64.so"
           (append jni-includes
                   (sort (find-files "build/jni/gdx" "\\.cpp$") string<?)
                   '("gdx/jni/etc1/etc1_utils.cpp" "build/native/gdx2d.o" "-lm")))
    (apply invoke "g++" "-std=c++11" "-O2" "-fPIC" "-shared" "-Wl,-z,defs"
           "-Ibuild/jni/freetype" "-o" "build/native/libgdx-freetype64.so"
           (append jni-includes
                   (list (string-append "-I" freetype "/include/freetype2"))
                   (sort (find-files "build/jni/freetype" "\\.cpp$") string<?)
                   (list (string-append "-L" freetype "/lib")
                         (string-append "-Wl,-rpath," freetype "/lib") "-lfreetype"))))
  ;; Legal texts travel both alongside and inside the combined component jar.
  (for-each
   (lambda (component)
     (let* ((root (cdr component))
            (destination (string-append "build/classes/META-INF/licenses/" (car component))))
       (for-each
        (lambda (file)
          (let ((target (string-append destination "/"
                                       (string-drop file (+ 1 (string-length root))))))
            (mkdir-p (dirname target))
            (copy-file file target)))
        (filter legal-file? (find-files root)))))
   '(("libgdx" . "source-closure/libgdx")
     ("jnigen" . "deps/jnigen") ("jlayer" . "deps/jlayer") ("jorbis" . "deps/jorbis")))
  (mkdir-p "build/classes/META-INF")
  (call-with-output-file "build/classes/META-INF/MANIFEST.MF"
    (lambda (port)
      (display "Manifest-Version: 1.0\nImplementation-Version: 1.12.1\n\n" port)))
  ;; Sorted entries and DOS-epoch timestamps avoid JDK-specific jar flags.
  (with-directory-excursion "build/classes"
    (let ((files (sort (find-files ".") string<?)))
      (for-each (lambda (file) (utime file 315532802 315532802)) files)
      (apply invoke "zip" "-q" "-X" "../gdx.jar" files)))
  #t)

(define (exppd-gdx-install output)
  (install-file "build/gdx.jar" (string-append output "/share/java"))
  (for-each (lambda (file) (install-file file (string-append output "/lib")))
            (find-files "build/native" "\\.so$"))
  (copy-recursively "source-closure" (string-append output "/share/src/java-exppd-gdx"))
  (copy-recursively "build/jni" (string-append output "/share/src/java-exppd-gdx/generated-jni"))
  (copy-recursively "build/classes/META-INF/licenses"
                    (string-append output "/share/doc/java-exppd-gdx/licenses"))
  #t)
