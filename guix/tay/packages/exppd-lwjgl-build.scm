;;; Offline compilation of LWJGL's committed, generated textual bindings.

(define-module (tay packages exppd-lwjgl-build)
  #:use-module (guix gexp)
  #:export (exppd-lwjgl-phases))

(define (exppd-lwjgl-phases jdk jsr305 libffi glfw openal jemalloc mesa)
  #~(modify-phases %standard-phases
      (delete 'bootstrap)
      (delete 'configure)
      (add-after 'unpack 'adapt-system-library-symbols
        (lambda _
          ;; Upstream's jemalloc binary uses --with-jemalloc-prefix=je_.
          ;; Guix's build uses the ordinary unprefixed public API instead.
          ;; Change dlsym names only, preserving all binding methods.
          (substitute*
              "modules/lwjgl/jemalloc/src/generated/java/org/lwjgl/system/jemalloc/JEmalloc.java"
            (("\"je_") "\""))))
      (add-after 'unpack 'declare-stb-dxt-memory-functions
        (lambda _
          ;; stb_dxt's implementation calls memcpy; declare its C library
          ;; dependency at the header itself for modern C compilers.
          (substitute* "modules/lwjgl/stb/src/main/c/stb_dxt.h"
            (("#include <stdlib.h>")
             "#include <stdlib.h>\n#include <string.h>"))))
      (replace 'build
        (lambda _
          (define modules '("core" "glfw" "jemalloc" "openal" "opengl" "stb" "tinyfd"))
          (define (module-path module suffix)
            (string-append "modules/lwjgl/" module "/src/" suffix))
          (define (root-files directory pattern)
            (if (file-exists? directory)
                (filter (lambda (file) (string=? (dirname file) directory))
                        (find-files directory pattern))
                '()))
          (define (java-files roots)
            (sort (append-map
                   (lambda (root)
                     (if (file-exists? root)
                         (filter (lambda (file)
                                   ;; Match build.xml:560,564 for the seven
                                   ;; enabled bindings.  These interop classes
                                   ;; require disabled EGL/OpenGLES/Vulkan
                                   ;; modules; upstream omits them too.
                                   (not (member
                                         (basename file)
                                         '("module-info.java"
                                           "GLFWNativeEGL.java"
                                           "GLFWVulkan.java"))))
                                 (find-files root "\\.java$"))
                         '()))
                   roots)
                  string<?))
          (define javac (string-append #$jdk:jdk "/bin/javac"))
          (define annotations
            (string-join (find-files #$jsr305 "\\.jar$") ":"))
          (define (compile-java name roots destination flags)
            (let ((sources (java-files roots))
                  (args-file (string-append "build/" name ".sources")))
              (unless (pair? sources) (error "empty Java source selection" name))
              (mkdir-p destination)
              (call-with-output-file args-file
                (lambda (port)
                  (for-each (lambda (file) (format port "~s~%" file)) sources)))
              (apply invoke javac
                     (append flags
                             (list "-encoding" "UTF-8" "-proc:none"
                                   "-sourcepath" "" "-classpath"
                                   (string-append "build/classes:" annotations)
                                   "-d" destination (string-append "@" args-file))))))
          (define core-c (module-path "core" "main/c"))
          (define uring (string-append core-c "/linux/liburing"))
          (define common-flags
            (list "-std=gnu11" "-m64" "-O2" "-fPIC" "-pthread"
                  "-DNDEBUG" "-DLWJGL_LINUX" "-DLWJGL_x64"
                  "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64"
                  (string-append "-I" #$jdk:jdk "/include")
                  (string-append "-I" #$jdk:jdk "/include/linux")
                  (string-append "-I" core-c)
                  (string-append "-I" core-c "/linux")))
          (define ffi-flags
            ;; Only unsupported-ABI sentinels from upstream's patched header.
            ;; Actual ABI enums, struct sizes, offsets and trampolines all come
            ;; from Guix libffi's OWN headers, matching the linked shared lib.
            (append
             (list (string-append "-I" #$libffi "/include") "-DX86_64")
             (map (lambda (name) (string-append "-DFFI_" name "=-1"))
                  '("SYSV" "STDCALL" "THISCALL" "FASTCALL" "MS_CDECL"
                    "PASCAL" "REGISTER" "VFP"))))
          (define (compile-native module sources flags libraries)
            (let* ((directory (string-append "build/native/" module))
                   (objects
                    (map (lambda (source)
                           (string-append directory "/"
                                          (string-map
                                           (lambda (c) (if (char=? c #\/) #\_ c))
                                           source)
                                          ".o"))
                         sources))
                   (library (string-append "build/lib"
                                           (if (string=? module "core")
                                               "lwjgl"
                                               (string-append "lwjgl_" module))
                                           ".so")))
              (unless (pair? sources) (error "empty C source selection" module))
              (mkdir-p directory)
              ;; Deliberately serial, including one compiler invocation per
              ;; translation unit.  No upstream Ant parallel executor or LTO.
              (for-each
               (lambda (source object)
                 (apply invoke "gcc"
                        (append common-flags flags
                                (list "-c" source "-o" object))))
               sources objects)
              (apply invoke "gcc" "-shared" "-m64" "-pthread"
                     "-Wl,-z,noexecstack" "-Wl,--no-undefined"
                     "-Wl,--version-script,config/linux/version.script"
                     "-o" library
                     (append objects libraries))))
          (mkdir-p "build/classes")
          ;; Compile the seven selected binding modules, retaining all platform
          ;; classes except upstream's disabled EGL/Vulkan interoperability.
          ;; LWJGL uses sun.misc.Unsafe, hence upstream's source/target approach
          ;; rather than javac --release 8, which hides that supported JDK API.
          (compile-java "base"
                        (append-map
                         (lambda (module)
                           (list (module-path module "main/java")
                                 (module-path module "generated/java")))
                         modules)
                        "build/classes" '("-source" "8" "-target" "8"))
          (for-each
           (lambda (version)
             (compile-java
              (string-append "java" version)
              (list (module-path "core" (string-append "main/java" version)))
              (string-append "build/classes/META-INF/versions/" version)
              (list "--release" version)))
           '("9" "10" "16"))
          ;; The generated stb units contain STB_*_IMPLEMENTATION and include
          ;; stb_vorbis.c directly: compiling main/c/stb_vorbis.c again would
          ;; duplicate definitions.  All 11 generated C units are compiled.
          (compile-native
           "core"
           (append (root-files core-c "\\.c$")
                   (root-files uring "\\.c$")
                   (root-files (module-path "core" "generated/c") "\\.c$")
                   (root-files (module-path "core" "generated/c/linux") "\\.c$"))
           (append ffi-flags
                   (list (string-append "-I" uring)
                         (string-append "-I" uring "/include")
                         "-DCONFIG_HAVE_MEMFD_CREATE"))
           (list (string-append "-L" #$libffi "/lib")
                 (string-append "-Wl,-rpath," #$libffi "/lib") "-lffi" "-ldl"))
          (compile-native
           "opengl"
           ;; Match config/linux/build.xml:314-320: WGL.c is Windows-only.
           (filter (lambda (file)
                     (not (string=? (basename file) "org_lwjgl_opengl_WGL.c")))
                   (root-files (module-path "opengl" "generated/c") "\\.c$"))
           (list (string-append "-I" (module-path "opengl" "main/c"))) '())
          (compile-native
           "stb" (root-files (module-path "stb" "generated/c") "\\.c$")
           (list (string-append "-I" (module-path "stb" "main/c"))) '("-lm"))
          (compile-native
           "tinyfd"
           (append (root-files (module-path "tinyfd" "main/c") "\\.c$")
                   (root-files (module-path "tinyfd" "generated/c") "\\.c$"))
           (list (string-append "-I" (module-path "tinyfd" "main/c"))) '())
          (install-file "LICENSE.md" "build/classes/META-INF/licenses/lwjgl")
          (for-each
           (lambda (module)
             (for-each
              (lambda (file)
                (install-file file
                              (string-append "build/classes/META-INF/licenses/" module)))
              (root-files (string-append "modules/lwjgl/" module)
                          "[Ll][Ii][Cc][Ee][Nn][Ss][Ee]")))
           modules)
          (call-with-output-file "build/MANIFEST.MF"
            (lambda (port)
              (display "Manifest-Version: 1.0\nSpecification-Title: Lightweight Java Game Library\nSpecification-Version: 3.3.3\nImplementation-Version: Guix-source-f0ec1437\nMulti-Release: true\n\n" port)))
          (invoke (string-append #$jdk:jdk "/bin/jar")
                  "--create" "--file" "build/lwjgl.jar"
                  "--date=1980-01-01T00:00:02Z"
                  "--manifest" "build/MANIFEST.MF" "-C" "build/classes" ".")))
      (replace 'install
        (lambda _
          (define modules '("core" "glfw" "jemalloc" "openal" "opengl" "stb" "tinyfd"))
          (define lib (string-append #$output "/lib"))
          (define doc (string-append #$output "/share/doc/java-exppd-lwjgl"))
          (install-file "build/lwjgl.jar" (string-append #$output "/share/java"))
          (for-each (lambda (file) (install-file file lib))
                    (find-files "build" "^liblwjgl(_[^/]*)?\\.so$"))
          ;; These three bindings use dlopen/libffi, not separate JNI objects.
          ;; LWJGL's bundled-name mapper expects precisely these filenames.
          (symlink (string-append #$glfw "/lib/libglfw.so.3")
                   (string-append lib "/libglfw.so"))
          (symlink (string-append #$openal "/lib/libopenal.so.1")
                   (string-append lib "/libopenal.so"))
          (symlink (string-append #$mesa "/lib/libGL.so.1")
                   (string-append lib "/libGL.so.1"))
          (symlink (string-append #$jemalloc "/lib/libjemalloc.so.2")
                   (string-append lib "/libjemalloc.so"))
          (install-file "LICENSE.md" doc)
          ;; Preserve full sources/embedded notices, not just a license summary.
          ;; Keep template/generator inputs as well as the compiled generated C
          ;; and Java; none of these paths contains downloaded build binaries.
          (for-each
           (lambda (directory)
             (copy-recursively directory (string-append doc "/sources/" directory)))
           (append (map (lambda (module) (string-append "modules/lwjgl/" module))
                        modules)
                   '("config" "modules/generator" "modules/ant")))
          (install-file "build.xml" (string-append doc "/sources"))
          (call-with-output-file (string-append doc "/BUILDING.txt")
            (lambda (port)
              (display
               (string-append
                "LWJGL 3.3.3, commit "
                "f0ec1437a6149dae00eaa27c47268e5e4efb129f.\n"
                "Built offline from committed generated Java/C; "
                "no Kotlin generator or binary native downloads.\n"
                "Seven selected Java binding modules and core "
                "Java 9/10/16 variants are included.\n"
                "GLFWNativeEGL and GLFWVulkan are omitted exactly as upstream "
                "build.xml:560,564 when their optional binding modules are "
                "disabled; OpenGL native interoperability is retained.\n"
                "The combined classpath jar deliberately has no individual "
                "JPMS module descriptors.\n"
                "System GLFW 3.4, OpenAL Soft, jemalloc and libffi are Guix "
                "source builds, not upstream bundled versions.\n"
                "GLFW 3.4 provides the glfwInitAllocator API required "
                "by these LWJGL bindings.\n"
                "JEmalloc dlsym strings use unprefixed Guix symbols "
                "instead of upstream je_ names.\n"
                "System libffi headers determine all layouts; unsupported "
                "x86_64 ABI constants retain upstream's -1 sentinel "
                "via compiler definitions.\n"
                "Native source selection follows config/linux/build.xml "
                "(core including Linux liburing, OpenGL, stb, tinyfd).\n"
                "STB implementations are included by generated C units, "
                "never compiled a second time.\n"
                "Consumer must set org.lwjgl.librarypath to this "
                "output's lib directory.\n") port)))))))
