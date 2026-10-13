;;; Source-built LibGDX 0.9.8/LWJGL 2.9.0 closure for Enter the Roguelike Dimension.

(define-module (tay packages etrd-libraries)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages java)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages auxiliary))

;; These snippets run before any build.  The one nested archive retained long
;; enough to unpack is LibGDX's JLayer SOURCE ZIP, not its bundled decoder jar.
(define* (clean-source name uri hash #:optional (jlayer? #f))
  (origin
    (method url-fetch)
    (uri uri)
    (file-name name)
    (sha256 (base32 hash))
    (modules '((guix build utils)))
    (snippet
     #~(begin
        ;; Snippet PATH contains the outer compressor, not every patch input.
        (when #$jlayer?
          (invoke #+(file-append unzip "/bin/unzip") "-q"
                  "backends/gdx-openal/libs/jlayer-1.0.1-libgdx.zip"
                  "-d" "jlayer-source"))
        (for-each delete-file
                  (find-files "."
                              "\\.(class|jar|zip|so|dll|dylib|jnilib|a|o|obj|exe|lib|pdb|bc)(\\.[0-9]+)*$"))))))

(define %lwjgl-source
  (clean-source
   "lwjgl-source-2.9.0.zip"
   (string-append "https://downloads.sourceforge.net/project/java-game-lib/"
                  "Official%20Releases/LWJGL%202.9.0/lwjgl-source-2.9.0.zip")
   "1jj8wrzqzpjbpnz4ivcm3wvkl6wzris9g3zwz2ix9if3w679fzcc"))

;; Maven here is only an archive host.  These artifacts contain textual Java,
;; C, and JNI headers.  They are never executable jars or compiled inputs.
;; No origin snippet is used: Guix's first-directory heuristic would discard
;; the siblings in these flat ZIPs.  Unpack/sanitization happens explicitly.
(define %jinput-source
  (origin
    (method url-fetch)
    (uri "https://repo.maven.apache.org/maven2/net/java/jinput/jinput/2.0.5/jinput-2.0.5-sources.jar")
    (file-name "jinput-2.0.5-sources.zip")
    (sha256
     (base32 "0b8yvj5xyq9k41za8hjqk03klz0j48a5rmbx2lj24lgiasif30s6"))))

(define %jutils-source
  (origin
    (method url-fetch)
    (uri "https://repo.maven.apache.org/maven2/net/java/jutils/jutils/1.0.0/jutils-1.0.0-sources.jar")
    (file-name "jutils-1.0.0-sources.zip")
    (sha256
     (base32 "1kd17q0rnjpg4xgqzxp8iw7mjg0jzvk2k0d4y4zma695q2imwwgm"))))

(define %jorbis-source
  (clean-source
   "jorbis-0.0.17-source.tar.gz"
   "https://codeload.github.com/ymnk/jorbis/tar.gz/28592f3dde5134871165470e7390d66ed5f1dce5"
   "1p7awrqi4rvilcd4cd1rwd562idivihy8k75lwwj2ydc48q7w70n"))

(define %store-natives-patch
  (local-file (search-tay-package-file "patches/etrd-store-natives.patch")))

(define %jinput-evdev-patch
  (local-file (search-tay-package-file "patches/etrd-jinput-evdev.patch")))

;; The official source ZIP omits doc/LICENSE.  This is its authentic companion
;; notice from the matching upstream tag, not a guessed or abridged license:
;; https://raw.githubusercontent.com/LWJGL/lwjgl/
;; 8deac76a5b374ce2f1011c772f989c3368c935d6/doc/LICENSE
(define %lwjgl-license
  (plain-file
   "LWJGL-LICENSE"
   "Copyright (c) 2002-2008 Lightweight Java Game Library Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of 'Light Weight Java Game Library' nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"))

(define-public java-etrd-libraries
  (package
    (name "java-etrd-libraries")
    (version "0.9.8-lwjgl-2.9.0")
    (source
     (clean-source
      "libgdx-0.9.8-ab8c85e-source.tar.gz"
      (string-append "https://codeload.github.com/libgdx/libgdx/tar.gz/"
                     "ab8c85edb8c5fd0b71d748ada456f779edf40d8c")
      "1q5qa2bldh6xvdzy5m10ra0zw7rc6z0aimbp2apr05xc3d8rcm2d"
      #t))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs
     `(("icedtea:jdk" ,icedtea-8 "jdk")
       ("unzip" ,unzip)
       ("zip" ,zip)))
    (inputs
     `(("icedtea" ,icedtea-8)
       ("gcc:lib" ,gcc "lib")
       ("libx11" ,libx11)
       ("libxt" ,libxt)
       ("libxext" ,libxext)
       ("libxcursor" ,libxcursor)
       ("libxrandr" ,libxrandr)
       ("libxxf86vm" ,libxxf86vm)
       ("xrandr" ,xrandr)
       ("mesa" ,mesa)
       ("openal" ,openal)))
    (arguments
     (list
      ;; The upstream demos require a real display/audio device.  The EtRD
      ;; native-consumer test exercises these libraries through their game.
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-source-closure
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "TZ" "UTC")
              (setenv "SOURCE_DATE_EPOCH" "315532800")
              (setenv "JAVA_HOME" (assoc-ref inputs "icedtea:jdk"))
              (mkdir-p "deps/lwjgl")
              ;; The cleaned official flat ZIP was repacked as a tar archive
              ;; rooted at '.', unlike JOrbis's single top-level directory.
              (invoke "tar" "xf" #$%lwjgl-source "-C" "deps/lwjgl")
              (mkdir-p "deps/jorbis")
              (invoke "tar" "xf" #$%jorbis-source "-C" "deps/jorbis"
                      "--strip-components=1")
              (invoke "unzip" "-q" #$%jinput-source "-d" "deps/jinput")
              (invoke "unzip" "-q" #$%jutils-source "-d" "deps/jutils")
              (for-each delete-file
                        (find-files "deps" "\\.(class|jar|so|dll|dylib|jnilib|a|o|exe)$"))
              ;; Upstream's genuine component-based classifier replaces the
              ;; nonexistent EVIOCGUSAGE ioctl, including its Java/JNI callers.
              (with-directory-excursion "deps/jinput"
                (substitute*
                    '("plugins/linux/src/java/net/java/games/input/LinuxEventDevice.java"
                      "plugins/linux/src/java/net/java/games/input/NativeDefinitions.java"
                      "plugins/linux/src/native/net_java_games_input_LinuxEventDevice.c"
                      "plugins/linux/src/native/net_java_games_input_LinuxEventDevice.h")
                  (("\r\n") "\n"))
                (invoke "patch" "--batch" "--fuzz=0" "-p1"
                        "-i" #$%jinput-evdev-patch))
              ;; The pinned source uses CRLF; keep the strict textual patch
              ;; independent of archive line endings without relaxing context.
              (substitute*
                  (list
                   "gdx/src/com/badlogic/gdx/utils/GdxNativesLoader.java"
                   (string-append "backends/gdx-backend-lwjgl/src/"
                                  "com/badlogic/gdx/backends/lwjgl/"
                                  "LwjglNativesLoader.java"))
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1"
                      "-i" #$%store-natives-patch)
              (substitute*
                  (list
                   "gdx/src/com/badlogic/gdx/utils/GdxNativesLoader.java"
                   (string-append "backends/gdx-backend-lwjgl/src/"
                                  "com/badlogic/gdx/backends/lwjgl/"
                                  "LwjglNativesLoader.java"))
                (("@ETRD_NATIVE_DIRECTORY@")
                 (string-append #$output "/lib")))
              ;; Keep Mac's genuine optional vendor API without an opaque
              ;; AppleJavaExtensions.jar compile-time dependency.
              (substitute* "deps/lwjgl/src/java/org/lwjgl/MacOSXSysImplementation.java"
                (("import com.apple.eio.FileManager;") "")
                (("FileManager.openURL\\(url\\);")
                 (string-append "Class.forName(\"com.apple.eio.FileManager\")"
                                ".getMethod(\"openURL\", String.class)"
                                ".invoke(null, url);")))
              (substitute* "deps/lwjgl/src/native/linux/opengl/extgl_glx.c"
                (("dlopen\\(\"libGL.so.1\"")
                 (string-append "dlopen(\"" #$mesa "/lib/libGL.so.1\"")))
              (substitute* "deps/lwjgl/src/java/org/lwjgl/opengl/XRandR.java"
                (("\"xrandr\"")
                 (string-append "\"" #$xrandr "/bin/xrandr\"")))
              (substitute*
                  "deps/jinput/coreAPI/src/java/net/java/games/input/Version.java"
                (("@API_VERSION@") "2.0.5")
                (("@BUILD_NUMBER@") "source"))
              ;; The generic core, ordinary utilities, and generated bindings
              ;; remain; only developer tools requiring ASM/apt are excluded.
              (for-each delete-file-recursively
                        '("deps/lwjgl/src/java/org/lwjgl/util/generator"
                          "deps/lwjgl/src/java/org/lwjgl/util/mapped"
                          "deps/lwjgl/src/java/org/lwjgl/util/applet"
                          "deps/lwjgl/src/java/org/lwjgl/test"
                          "deps/lwjgl/src/java/org/lwjgl/examples"
                          "deps/jinput/coreAPI/src/java/net/java/games/input/test"
                          "deps/jinput/coreAPI/src/java/net/java/games/input/example"))
              (delete-file "gdx/src/com/badlogic/gdx/utils/GdxBuild.java")
              (substitute* "gdx/jni/gdx2d/gdx2d.c"
                (("#include <stdlib.h>")
                 "#include <stdlib.h>\n#include <string.h>"))
              ;; Native compilation uses this JDK's headers, not copied headers.
              ;; Current Guix glibc needs neither half of the old memcpy wrap.
              (delete-file-recursively "gdx/jni/jni-headers")
              (delete-file "gdx/jni/memcpy_wrap.c")))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (define jdk (assoc-ref inputs "icedtea:jdk"))
              (define javac (string-append jdk "/bin/javac"))
              (define (java-sources roots)
                (sort (append-map (lambda (root) (find-files root "\\.java$"))
                                  roots)
                      string<?))
              (define (compile-java name roots classpath)
                (let ((classes (string-append "build/" name "-classes")))
                  (mkdir-p classes)
                  (apply invoke javac "-source" "7" "-target" "7"
                         "-encoding" "UTF-8" "-d" classes
                         (append (if classpath (list "-cp" classpath) '())
                                 (java-sources roots)))))
              (define (archive-java name)
                (let ((classes (string-append "build/" name "-classes"))
                      (jar (string-append (getcwd) "/build/" name ".jar")))
                  ;; JDK8's jar lacks --date.  Sorted, timestamp-normalized ZIP
                  ;; entries are ordinary jars and need no generated manifest.
                  (for-each (lambda (file) (utime file 315532800 315532800))
                            (find-files classes ".*"))
                  (with-directory-excursion classes
                    (apply invoke "zip" "-X" "-q" jar
                           (sort (find-files "." ".*") string<?)))))
              (define (direct-c directory)
                (filter (lambda (file) (string=? (dirname file) directory))
                        (find-files directory "\\.c$")))
              (define (compile-native name sources includes flags)
                (let ((objects (string-append "build/" name "-objects")))
                  (map
                   (lambda (source)
                     (let ((object (string-append objects "/" source ".o")))
                       (mkdir-p (dirname object))
                       (apply invoke (if (string-suffix? ".cpp" source) "g++" "gcc")
                              "-O2" "-fPIC" "-c" source "-o" object
                              (append
                               (list (string-append "-ffile-prefix-map=" (getcwd) "=."))
                               (if (string-suffix? ".cpp" source)
                                   '("-std=gnu++98") '("-std=c99"))
                               (map (lambda (dir) (string-append "-I" dir)) includes)
                               flags))
                       object))
                   (sort sources string<?))))
              (define jni-includes
                (list (string-append jdk "/include")
                      (string-append jdk "/include/linux")))
              (define classpath
                (string-join (map (lambda (name) (string-append "build/" name ".jar"))
                                  '("gdx" "lwjgl" "jinput" "jutils" "jorbis" "jlayer"))
                             ":"))
              (mkdir-p "build")
              (compile-java "jutils" '("deps/jutils/net") #f)
              (archive-java "jutils")
              (compile-java "jinput"
                            '("deps/jinput/coreAPI/src/java"
                              "deps/jinput/plugins/linux/src/java"
                              "deps/jinput/plugins/awt/src")
                            "build/jutils.jar")
              (archive-java "jinput")
              (compile-java "jorbis" '("deps/jorbis/com/jcraft/jogg"
                                      "deps/jorbis/com/jcraft/jorbis") #f)
              (archive-java "jorbis")
              (compile-java "jlayer" '("jlayer-source/src/javazoom/jl/decoder") #f)
              (copy-file "jlayer-source/resources/sfd.ser" "build/jlayer-classes/sfd.ser")
              (archive-java "jlayer")
              (compile-java "lwjgl" '("deps/lwjgl/src/java/org/lwjgl"
                                     "deps/lwjgl/src/generated")
                            "build/jinput.jar:build/jutils.jar")
              (archive-java "lwjgl")
              (compile-java "gdx" '("gdx/src") #f)
              (for-each
               (lambda (resource)
                 (let ((destination
                        (string-append "build/gdx-classes/"
                                       (substring resource (string-length "gdx/src/")))))
                   (mkdir-p (dirname destination))
                   (copy-file resource destination)))
               (find-files "gdx/src" "\\.(png|fnt)$"))
              (archive-java "gdx")
              (compile-java "gdx-backend-lwjgl"
                            '("backends/gdx-openal/src"
                              "backends/gdx-backend-lwjgl/src")
                            classpath)
              (archive-java "gdx-backend-lwjgl")
              (let ((objects
                     (compile-native
                      "jinput"
                      (append (direct-c "deps/jinput/plugins/common/src/native")
                              (direct-c "deps/jinput/plugins/linux/src/native"))
                      (append jni-includes
                              '("deps/jinput/plugins/common/src/native"
                                "deps/jinput/plugins/linux/src/native"))
                      '())))
                (apply invoke "gcc" "-shared" "-o" "build/libjinput-linux64.so" objects))
              ;; Upstream build.xml's headers target uses javah on these
              ;; handwritten JNI classes.  Generate from our compiled source
              ;; classes, not from any bundled binary jar or foreign header.
              (mkdir-p "build/lwjgl-headers")
              (apply invoke (string-append jdk "/bin/javah")
                     "-classpath" "build/lwjgl-classes:build/jinput.jar:build/jutils.jar"
                     "-d" "build/lwjgl-headers"
                     '("org.lwjgl.LinuxSysImplementation"
                       "org.lwjgl.opengl.LinuxEvent"
                       "org.lwjgl.opengl.LinuxMouse"
                       "org.lwjgl.opengl.LinuxKeyboard"
                       "org.lwjgl.opengl.LinuxDisplay"
                       "org.lwjgl.opengl.LinuxPeerInfo"
                       "org.lwjgl.opengl.LinuxPbufferPeerInfo"
                       "org.lwjgl.opengl.LinuxDisplayPeerInfo"
                       "org.lwjgl.opengl.LinuxAWTGLCanvasPeerInfo"
                       "org.lwjgl.opengl.LinuxContextImplementation"
                       "org.lwjgl.opengl.LinuxCanvasImplementation"
                       "org.lwjgl.opengl.AWTSurfaceLock"
                       "org.lwjgl.DefaultSysImplementation"
                       "org.lwjgl.input.Cursor"
                       "org.lwjgl.input.Keyboard"
                       "org.lwjgl.input.Mouse"
                       "org.lwjgl.openal.AL"
                       "org.lwjgl.opencl.CL"
                       "org.lwjgl.opencl.CallbackUtil"
                       "org.lwjgl.BufferUtils"
                       "org.lwjgl.opengl.GLContext"
                       "org.lwjgl.opengl.Pbuffer"
                       "org.lwjgl.opengl.CallbackUtil"
                       "org.lwjgl.opengl.NVPresentVideoUtil"
                       "org.lwjgl.opengl.NVVideoCaptureUtil"))
              (let* ((directories
                      '("common" "common/opengl" "generated/openal"
                        "generated/opencl" "generated/opengl" "linux" "linux/opengl"))
                     (objects
                      (compile-native
                       "lwjgl"
                       (append-map
                        (lambda (dir)
                          (direct-c (string-append "deps/lwjgl/src/native/" dir)))
                        directories)
                       (append jni-includes
                               '("build/lwjgl-headers"
                                 "deps/lwjgl/src/native/common"
                                 "deps/lwjgl/src/native/common/opengl"
                                 "deps/lwjgl/src/native/linux"
                                 "deps/lwjgl/src/native/linux/opengl"))
                       '("-pthread")))
                     (jawt (string-append #$icedtea-8 "/lib/amd64"))
                     (library-dirs
                      (append
                       (map (lambda (root) (string-append root "/lib"))
                            (list #$libx11 #$libxext #$libxcursor #$libxrandr
                                  #$libxxf86vm))
                       (list jawt (string-append jawt "/server")))))
                (apply invoke "gcc" "-shared" "-o" "build/liblwjgl64.so"
                       (append objects
                               (list
                                (string-append "-Wl,--version-script="
                                               "deps/lwjgl/src/native/linux/"
                                               "lwjgl.map"))
                               (append-map
                                (lambda (dir)
                                  (list (string-append "-L" dir)
                                        (string-append "-Wl,-rpath," dir)))
                                library-dirs)
                               '("-lX11" "-lXext" "-lXcursor" "-lXrandr"
                                 "-lXxf86vm" "-ljawt" "-lm" "-ldl" "-pthread"))))
              (let ((objects
                     (compile-native "gdx"
                                     (find-files "gdx/jni" "\\.(c|cpp)$")
                                     (append jni-includes '("gdx/jni")) '())))
                (apply invoke "g++" "-shared" "-o" "build/libgdx64.so"
                       (append objects
                               (list "-lm"
                                     (string-append "-Wl,-rpath,"
                                                    (assoc-ref inputs "gcc:lib")
                                                    "/lib")))))))
          (replace 'install
            (lambda _
              (define (root-files directory pattern)
                (filter (lambda (file) (string=? (dirname file) directory))
                        (find-files directory pattern)))
              (let ((jars (string-append #$output "/share/java"))
                    (lib (string-append #$output "/lib"))
                    (doc (string-append #$output "/share/doc/java-etrd-libraries")))
                (for-each (lambda (file) (install-file file jars))
                          (root-files "build" "\\.jar$"))
                (for-each (lambda (file) (install-file file lib))
                          (root-files "build" "\\.so$"))
                (symlink (string-append #$openal "/lib/libopenal.so.1")
                         (string-append lib "/libopenal64.so"))
                (install-file #$%lwjgl-license doc)
                ;; Retain every built library's corresponding source and full
                ;; copyright/permission headers, including third-party native
                ;; and Java notices.  LGPL decoders include actual source/data.
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append doc "/sources/" directory)))
                 '("gdx/src" "gdx/jni"
                   "backends/gdx-openal/src" "backends/gdx-backend-lwjgl/src"
                   "deps/lwjgl/src/java" "deps/lwjgl/src/generated"
                   "deps/lwjgl/src/native"
                   "deps/jinput/coreAPI/src/java"
                   "deps/jinput/plugins/common/src/native"
                   "deps/jinput/plugins/linux/src"
                   "deps/jinput/plugins/awt/src"
                   "deps/jutils/net"
                   "deps/jorbis/com/jcraft/jogg" "deps/jorbis/com/jcraft/jorbis"
                   "jlayer-source/src" "jlayer-source/resources"))
                (for-each
                 (lambda (file)
                   (let ((destination (string-append doc "/notices/" file)))
                     (mkdir-p (dirname destination))
                     (copy-file file destination)))
                 (append
                  (root-files
                   "." "^(LICENSE|NOTICE|AUTHORS|CONTRIBUTORS|COPYING(\\.LIB)?)$")
                  (root-files "gdx" "^(LICENSE|NOTICE|AUTHORS|CONTRIBUTORS)$")
                  (root-files "deps/jorbis"
                              "^(COPYING\\.LIB|README|ChangeLog)$")))))))))
    (home-page "https://libgdx.com/")
    (synopsis "Source-built legacy Java graphics and audio libraries for EtRD")
    (description
     "This package builds the exact LibGDX 0.9.8 and LWJGL 2.9.0 desktop
library sources used by Enter the Roguelike Dimension, together with JInput,
JUtils, JOrbis, and the LibGDX JLayer fork.  Java and Linux JNI code are compiled
from public pinned source archives, including upstream's generated textual
bindings.  Native libraries use immutable store paths and source-built OpenAL
and Mesa, without extracting binary resources.  Corresponding library sources
and their full third-party notices accompany the jars and shared libraries.")
    (license (list license:asl2.0 license:bsd-3 license:lgpl2.0+
                   license:zlib license:public-domain))))
