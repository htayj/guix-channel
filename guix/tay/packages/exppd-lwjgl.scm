;;; Source-built LWJGL 3 desktop bindings for Experienced Pixel Dungeon.

(define-module (tay packages exppd-lwjgl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages java)
  #:use-module (gnu packages jemalloc)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages exppd-lwjgl-build))

;; GLFW 3.4 loads Xlib and Xext dynamically and optionally loads libdecor.
;; The inherited Guix 3.3 soname patch predates these new dlopen calls.
;; Preserve both real window-system backends, and resolve their new dependencies
;; from the store rather than relying on a caller's LD_LIBRARY_PATH.
(define glfw-exppd
  (package
    (inherit glfw-3.4)
    (name "glfw-exppd")
    (inputs
     (modify-inputs (package-inputs glfw-3.4)
       (prepend libxext libdecor)))
    (arguments
     (substitute-keyword-arguments (package-arguments glfw-3.4)
       ((#:configure-flags flags #~'())
        #~(append #$flags
                  '("-DGLFW_BUILD_X11=ON" "-DGLFW_BUILD_WAYLAND=ON")))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-before 'patch-sonames 'patch-new-platform-sonames
              (lambda* (#:key inputs #:allow-other-keys)
                (substitute* "src/x11_init.c"
                  (("\"libX11.so.6\"")
                   (string-append
                    "\"" (search-input-file inputs "lib/libX11.so.6") "\""))
                  (("\"libXext.so.6\"")
                   (string-append
                    "\"" (search-input-file inputs "lib/libXext.so.6") "\"")))
                (substitute* "src/wl_init.c"
                  (("\"libdecor-0.so.0\"")
                   (string-append
                    "\"" (search-input-file inputs "lib/libdecor-0.so.0")
                    "\"")))))))))))

(define-public java-exppd-lwjgl
  (package
    (name "java-exppd-lwjgl")
    (version "3.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/LWJGL/lwjgl3/tar.gz/"
             "f0ec1437a6149dae00eaa27c47268e5e4efb129f"))
       (file-name "lwjgl-3.3.3-source.tar.gz")
       (sha256
        (base32 "11078rpzlr5pkv8qla9662w526mh1fxl1prsd7b6qj08qxj5x3rq"))
       (modules '((guix build utils)))
       (snippet
        #~(for-each
           delete-file
           (find-files
            "."
            (string-append
             "\\.(jar|class|zip|so|dll|dylib|jnilib|a|o|obj|exe|lib|pdb|bc)"
             "(\\.[0-9]+)*$"))))))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs
     `(("openjdk:jdk" ,openjdk17 "jdk")
       ("java-jsr305" ,java-jsr305)))
    ;; LWJGL 3.3.3 requires glfwInitAllocator, introduced in GLFW 3.4.
    (inputs
     `(("glfw-exppd" ,glfw-exppd)
       ("openal" ,openal)
       ("jemalloc" ,jemalloc)
       ("libffi" ,libffi)
       ("mesa" ,mesa)))
    (arguments
     (list
      ;; Upstream tests are interactive hardware tests.  The consuming game
      ;; supplies the real desktop acceptance test, not mocked JNI calls.
      #:tests? #f
      #:parallel-build? #f
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (ice-9 ftw) (ice-9 regex) (srfi srfi-1) (srfi srfi-13))
      #:phases
      (exppd-lwjgl-phases openjdk17 java-jsr305 libffi
                          glfw-exppd openal jemalloc mesa)))
    (home-page "https://www.lwjgl.org/")
    (synopsis "Source-built LWJGL desktop bindings for Experienced Pixel Dungeon")
    (description
     "This package compiles LWJGL 3.3.3 core, GLFW, jemalloc, OpenAL, OpenGL,
stb, and tinyfiledialogs Java bindings and their Linux JNI implementations from
committed Java and C sources.  It includes the Java 9, 10, and 16 multi-release
implementations without invoking the Kotlin generator or downloading binaries.
The bindings use Guix's source-built GLFW, OpenAL Soft, jemalloc, and libffi,
not LWJGL's bundled native releases.  Complete corresponding module sources,
generator sources, build recipes, and third-party notices accompany the jar and
native libraries.")
    (license (list license:bsd-3 license:expat license:zlib
                   license:unlicense license:isc))))
