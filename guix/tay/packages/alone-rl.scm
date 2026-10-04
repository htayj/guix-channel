;;; Source-built Alone/RL and its independently packaged Java/Rust closure.

(define-module (tay packages alone-rl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (tay packages alone-rl-java)
  #:use-module (gnu packages java)
  #:use-module (tay packages alone-rl-terrain)
  #:use-module (tay packages auxiliary))

(define %alone-rl-test-launcher
  (local-file
   (search-tay-package-file "auxiliary/alone-rl-test-launcher.java")))

(define-public alone-rl
  (package
    (name "alone-rl")
    (version "0.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/fabio-t/alone-rl/tar.gz/"
             "de2ab3f0023cbfb0f9ab5a68e3d48fabf4b17de8"))
       (file-name "alone-rl-0.3.1-de2ab3f.tar.gz")
       (sha256
        (base32 "0xhv3rmydq9hg29a2d9245gxdy822qrnpazbnrwlwcmz9harsdmv"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 format)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-source-build
            (lambda _
              ;; Neither Gradle nor its binary bootstrap is used.  Retain every
              ;; real game class, the vendored AsciiPanel, and its font sheets.
              (delete-file-recursively "gradle")
              (delete-file "gradlew")
              (delete-file "gradlew.bat")
              (substitute* "src/main/resources/project.properties"
                (("\\$\\{version\\}") #$version)
                (("\\$\\{name\\}") "AloneRL"))))
          (replace 'build
            (lambda _
              (let* ((roots (list #$@alone-rl-java-runtime #$alone-rl-terrain))
                     (jars (append-map
                            (lambda (root)
                              (find-files (string-append root "/share/java")
                                          "\\.jar$"))
                            roots))
                     (classpath (string-join jars ":")))
                (setenv "ALONE_BUILD_CLASSPATH" classpath)
                (mkdir-p "build/classes")
                (apply invoke "javac" "--release" "25" "-encoding" "UTF-8"
                       "-cp" classpath "-d" "build/classes"
                       (sort (find-files "src/main/java" "\\.java$") string<?))
                (copy-recursively "src/main/resources" "build/classes")
                (invoke "jar" "--create" "--file" "build/alone-rl.jar"
                        "--date=1980-01-01T00:00:02Z"
                        "--main-class=com.github.fabioticconi.alone.Main"
                        "-C" "build/classes" "."))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let* ((jars (append-map
                              (lambda (root)
                                (find-files (string-append root "/share/java")
                                            "\\.jar$"))
                              (list #$@alone-rl-java-tests)))
                       (classpath
                        (string-append "build/classes:"
                                       (getenv "ALONE_BUILD_CLASSPATH") ":"
                                       (string-join jars ":"))))
                  (mkdir-p "build/test-classes")
                  (apply invoke "javac" "--release" "25" "-encoding" "UTF-8"
                         "-cp" classpath "-d" "build/test-classes"
                         (sort (find-files "src/test/java" "\\.java$") string<?))
                  (invoke "javac" "--release" "25" "-encoding" "UTF-8"
                          "-cp" classpath "-d" "build/test-classes"
                          #$%alone-rl-test-launcher)
                  (invoke "java" "-Djava.awt.headless=true" "-cp"
                          (string-append classpath ":build/test-classes")
                          "AloneRlTestLauncher" "build/test-classes")))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((out #$output)
                     (share (string-append out "/share/alone-rl"))
                     (doc (string-append out "/share/doc/alone-rl"))
                     (bin (string-append out "/bin"))
                     (roots (list #$@alone-rl-java-runtime #$alone-rl-terrain))
                     (jars (append-map
                            (lambda (root)
                              (find-files (string-append root "/share/java")
                                          "\\.jar$"))
                            roots))
                     (classpath
                      (string-join
                       (cons (string-append share "/alone-rl.jar") jars) ":")))
                (mkdir-p share)
                (mkdir-p doc)
                (mkdir-p bin)
                (install-file "build/alone-rl.jar" share)
                (copy-recursively "data" (string-append share "/data"))
                ;; The checkout's map is not a user's generated session.
                (let ((map (string-append share "/data/map/elevation.data")))
                  (when (file-exists? map) (delete-file map)))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "THIRD-PARTY.md" "README.md"))
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/AsciiPanel")))
                 '("src/main/java/asciiPanel/LICENSE.md"
                   "src/main/java/asciiPanel/README.md"))
                (call-with-output-file (string-append doc "/SOURCE-NOTICE")
                  (lambda (port)
                    (display
                     (string-append
                      "Alone/RL 0.3.1: fabio-t/alone-rl "
                      "de2ab3f0023cbfb0f9ab5a68e3d48fabf4b17de8, "
                      "GNU AGPL 3 or later.\n"
                      "Vendored AsciiPanel code and ten original PNG fonts: "
                      "trystan/AsciiPanel "
                      "372dfbae987c64ff34d26fa1da0763b0f1c2bf37, MIT; "
                      "full notice in AsciiPanel/LICENSE.md.\n"
                      "The upstream THIRD-PARTY.md is preserved verbatim but "
                      "its Artemis Apache-only description is incomplete: "
                      "the exact artemis-odb 2.3.0 release includes original "
                      "BSD-2-Clause LICENSE and Apache-2.0 LICENSE.libgdx. "
                      "Both full texts are in the dependency notice bundle.\n"
                      "Logback 1.6.3 offers EPL-2.0 or LGPL-2.1, not the "
                      "historical EPL-1.0 description; both complete grants "
                      "are included in its dependency notice bundle.\n"
                      "All application and dependency JARs and terrain native "
                      "library are built from pinned source inputs. No Gradle "
                      "bootstrap, released terrain JAR, or embedded prebuilt "
                      "native payload is installed.\n"
                      "Continue persists generated elevation only; it is not "
                      "a saved player, inventory or clock.\n")
                     port)))
                ;; Copy complete independently built dependency legal texts.
                (for-each
                 (lambda (root index)
                   (copy-recursively
                    (string-append root "/share/doc")
                    (string-append doc "/dependencies/" (number->string index))))
                 roots (iota (length roots)))
                (call-with-output-file (string-append bin "/alone-rl")
                  (lambda (port)
                    (format port "#!~a/bin/sh\nset -eu\n"
                            #$bash-minimal)
                    (display
                     (string-append
                      "data_home=${XDG_DATA_HOME:-${HOME:?"
                      "HOME or XDG_DATA_HOME must be set}/.local/share}\n"
                      "data=$data_home/alone-rl\n") port)
                    (format port "~a/bin/mkdir -p \"$data\"\n"
                            #$coreutils-minimal)
                    ;; Seed missing files without overwriting a player's map.
                    (format port
                            (string-append
                             "~a/bin/cp -R --no-clobber --no-preserve=mode "
                             "~a/data/. \"$data/\"\n")
                            #$coreutils-minimal share)
                    (format port
                            (string-append
                             "exec ~a --enable-native-access=ALL-UNNAMED "
                             "-Dalone.data=\"$data\" -Dtergen.library=~a/lib/"
                             "libterrain_generator_ffi.so -cp '~a' "
                             "com.github.fabioticconi.alone.Main \"$@\"\n")
                            (search-input-file inputs "bin/java")
                            #$alone-rl-terrain classpath)))
                (chmod (string-append bin "/alone-rl") #o555)))))))
    (native-inputs
     (append `(("openjdk:jdk" ,openjdk25 "jdk"))
             (map (lambda (dependency)
                    (list (package-name dependency) dependency))
                  alone-rl-java-tests)))
    (inputs
     (append `(("bash-minimal" ,bash-minimal)
               ("coreutils-minimal" ,coreutils-minimal)
               ("openjdk:jdk" ,openjdk25 "jdk")
               ("alone-rl-terrain" ,alone-rl-terrain))
             (map (lambda (dependency)
                    (list (package-name dependency) dependency))
                  alone-rl-java-runtime)))
    (home-page "https://github.com/fabio-t/alone-rl")
    (synopsis "Single-player ASCII survival roguelike")
    (description
     "Alone/RL is a standalone Swing survival roguelike with island terrain
generation, crafting and exploration.  This package builds its Java libraries
and Rust terrain generator from pinned sources without Gradle network resolution
or prebuilt native payloads.  Fonts and immutable initial data are bundled;
generated elevation data is kept under the user's XDG data directory.")
    (license (list license:agpl3+ license:expat))))
