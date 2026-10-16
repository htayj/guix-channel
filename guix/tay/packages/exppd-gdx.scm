;;; Source-built desktop LibGDX closure for Experienced Pixel Dungeon.
(define-module (tay packages exppd-gdx)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages java)
  #:use-module (tay packages exppd-lwjgl))

(define %gdx-build-helper
  (local-file (canonicalize-path
               (search-path %load-path "tay/packages/exppd-gdx-build.scm"))))

(define (source-archive name uri hash)
  (origin
    (method url-fetch)
    (uri uri)
    (file-name name)
    (sha256 (base32 hash))
    (modules '((guix build utils)))
    (snippet
     #~(for-each delete-file
                 (find-files "." "\\.(class|jar|zip|so|dll|dylib|jnilib|a|o|obj|exe|lib|pdb|bc)(\\.[0-9]+)*$")))))

(define %jnigen-source
  (source-archive
   "gdx-jnigen-2.2.0-source.tar.gz"
   "https://codeload.github.com/libgdx/gdx-jnigen/tar.gz/d76af74312ba938ca86f1526b07037ad8509f73e"
   "03nwcpx637d4v00h8kdipwq0nv45k2nd9jr1kccznv6a3z2qdw57"))

;; This is a source archive, not a binary Maven dependency.  Its root sfd.ser
;; is the decoder's 512-float synthesis table, not executable code.
(define %jlayer-source
  (origin
    (method url-fetch)
    (uri "https://repo.maven.apache.org/maven2/com/badlogicgames/jlayer/jlayer/1.0.1-gdx/jlayer-1.0.1-gdx-sources.jar")
    (file-name "jlayer-1.0.1-gdx-sources.zip")
    (sha256 (base32 "0a93n7n7kncvm7ngcdnhfc5f2mdifjbxdhv3cnqwzhgp59ilfg9p"))))

(define %jorbis-source
  (source-archive
   "jorbis-0.0.17-source.tar.gz"
   "https://codeload.github.com/ymnk/jorbis/tar.gz/28592f3dde5134871165470e7390d66ed5f1dce5"
   "1p7awrqi4rvilcd4cd1rwd562idivihy8k75lwwj2ydc48q7w70n"))

;; The JLayer source artifact has per-file notices but omits the full license.
(define %jlayer-lgpl
  (origin
    (method url-fetch)
    (uri "https://www.gnu.org/licenses/old-licenses/lgpl-2.0.txt")
    (file-name "JLayer-COPYING.LIB")
    (sha256 (base32 "091byii6nib940vlfazd0f8djj5r3vfa3j3lndb5p29w2chmqlyc"))))

(define %jlayer-gpl
  (origin
    (method url-fetch)
    (uri "https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt")
    (file-name "JLayer-COPYING")
    (sha256 (base32 "1xikn8wqfgdwvrb4svlfj5y1lk0s8in7lw91lbky8hxnrcrgdbpd"))))

(define-public java-exppd-gdx
  (package
    (name "java-exppd-gdx")
    (version "1.12.1")
    (source
     (source-archive
      "libgdx-1.12.1-b3989cb-source.tar.gz"
      (string-append "https://codeload.github.com/libgdx/libgdx/tar.gz/"
                     "b3989cb385ab2f308756e6735eb90eb41cfec558")
      "1a1n10kl6kvk757d1zygibghv1s7kiai9bmmpm7a72m90amzbfm6"))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs
     (list (list "openjdk:jdk" openjdk17 "jdk")
           (list "unzip" unzip)
           (list "zip" zip)
           (list "java-javaparser" java-javaparser)))
    (inputs (list java-exppd-lwjgl freetype))
    (arguments
     (list
      ;; Upstream integration tests require a graphics/audio session; the game
      ;; package is the consumer.  No Gradle/Maven or build-time downloads run.
      #:tests? #f
      #:parallel-build? #f
      #:modules '((guix build gnu-build-system) (guix build utils))
      #:phases
      #~(begin
          (save-module-excursion
           (lambda () (primitive-load #$%gdx-build-helper)))
          (let* ((helper (resolve-module '(tay packages exppd-gdx-build)))
                 (exppd-gdx-prepare (module-ref helper 'exppd-gdx-prepare))
                 (exppd-gdx-build (module-ref helper 'exppd-gdx-build))
                 (exppd-gdx-install (module-ref helper 'exppd-gdx-install)))
            (modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-source-closure
            (lambda _
              (exppd-gdx-prepare
               #$%jnigen-source #$%jlayer-source #$%jorbis-source
               #$%jlayer-lgpl #$%jlayer-gpl)))
          (replace 'build
            (lambda _
              (exppd-gdx-build #$openjdk17:jdk
                               #$java-javaparser #$java-exppd-lwjgl
                               #$freetype #$output)))
          (replace 'install
            (lambda _ (exppd-gdx-install #$output))))))))
    (home-page "https://libgdx.com/")
    (synopsis "Source-built LibGDX desktop graphics, fonts and audio")
    (description
     "This package builds LibGDX core, its LWJGL3 desktop backend, FreeType
bindings, and the JLayer and JOrbis audio decoders from source.  JNI is generated
from upstream native method bodies and linked to system FreeType.  The shared
library loader resolves store-native libraries through exppd.native.path rather
than extracting binary jars.  Complete cleaned sources, generated JNI sources,
and component license texts are installed with the libraries.  The loader is
explicitly pinned to gdx-jnigen 2.2.0 for the shared desktop controller closure;
this is not a claim that LibGDX's upstream 2.3.1 dependency was identical.")
    (license (list license:asl2.0 license:lgpl2.0+ license:lgpl2.1+
                   license:expat license:public-domain))))
