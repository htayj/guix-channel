;;; Source-built desktop controller stack for Experienced Pixel Dungeon.

(define-module (tay packages exppd-controllers)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages exppd-gdx)
  #:use-module (tay packages exppd-lwjgl)
  #:use-module (tay packages exppd-controllers-build))

(define (controller-source name uri hash)
  (origin
    (method url-fetch)
    (uri uri)
    (file-name name)
    (sha256 (base32 hash))
    (modules '((guix build utils)))
    (snippet
     #~(for-each
        delete-file
        (find-files "."
                    "\\.(class|jar|zip|so|dll|dylib|jnilib|a|o|obj|exe|lib|pdb|bc)(\\.[0-9]+)*$")))))

(define %jamepad-source
  (controller-source
   "jamepad-2.26.5.0-source.tar.gz"
   (string-append "https://codeload.github.com/williamahartman/Jamepad/tar.gz/"
                  "bb3661b356a9c690bfc7174941bd68848800aca5")
   "0d1blmi88swzlbxnjrch93vw4n97n3gppflmkjhnrja25gk9gma4"))

(define %jnigen-source
  (controller-source
   "gdx-jnigen-2.2.0-source.tar.gz"
   (string-append "https://codeload.github.com/libgdx/gdx-jnigen/tar.gz/"
                  "d76af74312ba938ca86f1526b07037ad8509f73e")
   "03nwcpx637d4v00h8kdipwq0nv45k2nd9jr1kccznv6a3z2qdw57"))

;; Upstream controllers downloads this project's mutable master at build time.
;; Use a fixed source archive, including its original zlib license, instead.
(define %controllerdb-source
  (controller-source
   "sdl-gamecontrollerdb-414eaee-source.tar.gz"
   (string-append "https://codeload.github.com/mdqinc/SDL_GameControllerDB/tar.gz/"
                  "414eaee7aacc0d2ccdf281663c3d3bc65a8dbedd")
   "033zgyn1dzplgcr9cfd8yd9dapyfhkgmabd87prp26ar4w6bg3g7"))

(define-public java-exppd-controllers
  (package
    (name "java-exppd-controllers")
    (version "2.2.4")
    (source
     (controller-source
      "gdx-controllers-2.2.4-source.tar.gz"
      (string-append "https://codeload.github.com/libgdx/gdx-controllers/tar.gz/"
                     "2deca84cae049e1a93019dda25c3245d0a9b1f68")
      "1842yp4vdi8448iq3ha6kjj70f8xc42jz8q0qx3m9sdgz9mlcwnh"))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs
     `(("openjdk:jdk" ,openjdk17 "jdk")
       ("java-javaparser" ,java-javaparser)
       ("zip" ,zip)))
    (inputs
     `(("java-exppd-gdx" ,java-exppd-gdx)
       ("java-exppd-lwjgl" ,java-exppd-lwjgl)
       ("sdl2" ,sdl2)
       ("gcc:lib" ,gcc "lib")))
    (arguments
     (list
      ;; Upstream tests are interactive controller/device tests.  The game is
      ;; the integration consumer; no Gradle or network fetch runs here.
      #:tests? #f
      #:parallel-build? #f
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (ice-9 ftw) (ice-9 textual-ports)
                  (srfi srfi-1) (srfi srfi-13))
      #:phases
      (exppd-controllers-phases %jamepad-source %jnigen-source
                               %controllerdb-source)))
    (home-page "https://github.com/libgdx/gdx-controllers")
    (synopsis "Desktop LibGDX controllers with source-built Jamepad JNI")
    (description
     "This package builds the desktop and core controller modules of LibGDX
controllers 2.2.4 and Jamepad 2.26.5.0.  The 2.2.4 tag is a deliberate source
pin, not a claim that it is identical to the game's historical SNAPSHOT.
Jamepad's JNI is generated from its actual native method bodies using the
source-built upstream jnigen 2.2.0 generator.  It links Guix SDL2 dynamically
instead of bundling upstream's SDL static binary.  Controller mappings come
from a fixed revision of SDL_GameControllerDB.  The complete cleaned sources,
generated JNI, and original license notices are retained.  The shared
jnigen-loader classes are supplied by java-exppd-gdx, not duplicated here.")
    (license (list license:asl2.0 license:zlib))))
