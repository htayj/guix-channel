;;; The original EverSector release and its complete source-built Java closure.
(define-module (tay packages eversector)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages eversector-test-libraries)
  #:use-module (srfi srfi-13))

(define %game-commit "224ead104afc6bc9df9d7dcf86f87766ff1b5152")
(define %apwt-commit "9dfe7b026c8ab8ab3d92a73bdc6a63ccb121c8e1")
(define %asciipanel-commit "4af354155a0c5f4d66efe3d837a9f327f5f2a358")
(define %squidlib-commit "a2e5a061f085a5e3fe34b3353757d4209f6a8f33")
(define %regexodus-commit "135e7400a03f459655cf8cb93a45f24786ca9519")

(define (project-source repository commit hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/" repository
                        "/tar.gz/" commit))
    (file-name (string-append (car (reverse (string-split repository #\/)))
                              "-" commit ".tar.gz"))
    (sha256 (base32 hash))
    (modules '((guix build utils)))
    (snippet
     #~(for-each delete-file
                 (find-files "." "\\.(class|jar|zip|so|dll|dylib|jnilib|a|o|exe)$")))))

;; These four libraries have the same ordinary javac/resource/JUnit lifecycle.
;; The upstream Maven/Gradle files remain with their sources, but are not used
;; to fetch executable JitPack/Maven artifacts inside a build.
(define* (java-library component version source source-prefix synopsis
                       description license
                       #:key (dependencies '()) (test-inputs '())
                       (test-classes '()) (exclusions '()) (state-path? #f))
  (package
    (name (string-append "java-eversector-" component))
    (version version)
    (source source)
    (build-system gnu-build-system)
    (properties '((hidden? . #t)))
    (native-inputs
     (append (list (list "icedtea:jdk" icedtea-8 "jdk")
                   (list "zip" zip))
             (map (lambda (package)
                    (list (package-name package) package))
                  (append
                   (if (null? test-classes)
                       '()
                       (list java-junit-4.13.2 java-hamcrest-core))
                   test-inputs))))
    (inputs dependencies)
    (arguments
     (append
      (if (null? test-classes) (list #:tests? #f) '())
      (list
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-source
            (lambda _
              (setenv "TZ" "UTC")
              (setenv "SOURCE_DATE_EPOCH" "315532800")
              (copy-recursively (string-append #$source-prefix "/src")
                                "original-src")
              (when #$state-path?
                ;; APWT normally writes beside its jar.  Retain its genuine
                ;; local/ save format and redirect only that base directory.
                (substitute* "src/main/java/maugrift/apwt/util/FileManager.java"
                  (((string-append
                     "Finds the path to the jar and its directory, "
                     "returning the latter\\."))
                   "Finds the launcher's private state working directory.")
                  (("@return the path to the jar file's directory")
                   "@return the private state working directory")
                  (((string-append
                     "String jarPath = FileManager\\.class"
                     "\\.getProtectionDomain\\(\\)\\.getCodeSource\\(\\)"
                     "\\.getLocation\\(\\)\\.getPath\\(\\);"))
                   (string-append
                    "// Guix: state belongs to the launcher's "
                    "private working directory."))
                  (((string-append
                     "return jarPath\\.substring\\(0, "
                     "jarPath\\.lastIndexOf\\(\"/\"\\) \\+ 1\\);"))
                   "return System.getProperty(\"user.dir\") + \"/\";")))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((root (string-append #$source-prefix "/src/main"))
                     (sources
                      (filter
                       (lambda (file)
                         (not (any (lambda (part) (string-contains file part))
                                   '#$exclusions)))
                       (sort (find-files (string-append root "/java") "\\.java$")
                             string<?)))
                     (classpath
                      (string-join
                       (append-map
                        (lambda (input)
                          (if (string-prefix? "java-" (car input))
                              (find-files (cdr input) "\\.jar$") '()))
                        inputs)
                       ":")))
                (mkdir-p "build/classes")
                (apply invoke (search-input-file inputs "/bin/javac")
                       "-source" "8" "-target" "8" "-encoding" "UTF-8"
                       "-classpath" classpath "-d" "build/classes" sources)
                (when (file-exists? (string-append root "/resources"))
                  (copy-recursively (string-append root "/resources")
                                    "build/classes"))
                ;; Java 8's jar tool generates current-date metadata.  A
                ;; sorted, timestamp-normalized ordinary ZIP is also a jar.
                (for-each (lambda (file) (utime file 315532800 315532800))
                          (find-files "build/classes" ".*"))
                (let ((jar (string-append (getcwd) "/build/" #$component ".jar")))
                  (with-directory-excursion "build/classes"
                    (apply invoke "zip" "-X" "-q" jar
                           (sort (find-files "." ".*") string<?)))))))
          (replace 'check
            (lambda* (#:key inputs tests? #:allow-other-keys)
              (when tests?
                (let* ((root (string-append #$source-prefix "/src/test"))
                       (classpath
                        (string-join
                         (cons "build/classes"
                               (append-map
                                (lambda (input)
                                  (if (string-prefix? "java-" (car input))
                                      (find-files (cdr input) "\\.jar$") '()))
                                inputs))
                         ":")))
                  (mkdir-p "build/test-classes")
                  (apply invoke (search-input-file inputs "/bin/javac")
                         "-source" "8" "-target" "8" "-encoding" "UTF-8"
                         "-classpath" classpath "-d" "build/test-classes"
                         (sort (find-files (string-append root "/java")
                                           "\\.java$") string<?))
                  (when (file-exists? (string-append root "/resources"))
                    (copy-recursively (string-append root "/resources")
                                      "build/test-classes"))
                  (apply invoke
                         (string-append (assoc-ref inputs "icedtea:jdk")
                                        "/bin/java")
                         "-Djava.awt.headless=true" "-classpath"
                         (string-append "build/test-classes:" classpath)
                         "org.junit.runner.JUnitCore" '#$test-classes)))))
          (replace 'install
            (lambda _
              (let ((source (string-append #$output "/share/eversector-source/"
                                           #$component)))
                (install-file (string-append "build/" #$component ".jar")
                              (string-append #$output "/share/java"))
                (copy-recursively
                 "original-src" (string-append source "/" #$source-prefix "/src"))
                (when #$state-path?
                  (copy-recursively "src" (string-append source "/built-src")))
                (for-each
                 (lambda (file)
                   (when (and (eq? 'regular (stat:type (stat file)))
                              (or (string-contains (string-downcase file) "license")
                                  (string-contains (string-downcase file) "notice")
                                  (member file '("README.md" "README.MD"
                                                 "build.gradle" "pom.xml"
                                                 "settings.gradle"))))
                     (install-file file source)))
                 (scandir "."))
                (when (not (string=? #$source-prefix "."))
                  (for-each
                   (lambda (file)
                     (install-file (string-append #$source-prefix "/" file)
                                   (string-append source "/" #$source-prefix)))
                   '("pom.xml"))))))))))
    (home-page (string-append "https://github.com/"
                             (case (string->symbol component)
                               ((asciipanel) "trystan/AsciiPanel")
                               ((squidlib-util) "yellowstonegames/SquidLib")
                               ((regexodus) "tommyettinger/RegExodus")
                               (else "friedev/apwt"))))
    (synopsis synopsis)
    (description description)
    (license license)))

(define java-eversector-regexodus
  (java-library
   "regexodus" "0.1.12"
   (project-source "tommyettinger/RegExodus" %regexodus-commit
                   "1m1b8d48560dpwq6d5islk3x0dmmhc6brfj50cp1b01mvgam4pb6")
   "." "Regular expression library for EverSector's SquidLib"
   "RegExodus is a Java regular-expression library derived from jregex.  This
package builds the exact version required by EverSector's SquidLib utilities."
   license:bsd-3
   #:test-classes '("regexodus.BasicTest" "regexodus.FinneganTest")))

(define java-eversector-squidlib-util
  (java-library
   "squidlib-util" "3.0.4"
   (project-source "yellowstonegames/SquidLib" %squidlib-commit
                   "1z9fk7brbg9nrbc0lp8biymvsjh9q0j4qr7w2xg148b8zzvfb7rj")
   "squidlib-util" "Roguelike logic and utilities used by EverSector"
   "SquidLib's platform-independent utility module provides random-number
generators, procedural maps, collections and other roguelike logic.  This
package builds the original version required by EverSector, without the
unrelated graphical backends or GWT emulation sources."
   (list license:asl2.0 license:bsd-3 license:expat license:public-domain)
   #:dependencies (list java-eversector-regexodus)
   ;; Match the exact upstream Maven compiler exclusions, not game stubs.
   #:exclusions '("/emu/" "/etc/")
   ;; These are the unchanged @Test-bearing classes selected by Maven's
   ;; default *Test.java convention.  Other files are executable examples.
   #:test-classes '("squidpony.examples.FOVTest"
                    "squidpony.examples.HashQualityTest"
                    "squidpony.examples.LanguageGenTest"
                    "squidpony.examples.ObTextTest"
                    "squidpony.examples.ProbabilityTableTest"
                    "squidpony.examples.RNGFeatureTest"
                    "squidpony.examples.RangedRandomTest"
                    "squidpony.examples.ShufflerTest"
                    "squidpony.examples.StringKitTest"
                    "squidpony.squidmath.BinaryHeapTest"
                    "squidpony.squidmath.CoordPackerTest"
                    "squidpony.squidmath.DiceTest"
                    "squidpony.squidmath.GreasedRegionTest"
                    "squidpony.squidmath.LightRNGTest"
                    "squidpony.squidmath.NoiseRangeTest"
                    "squidpony.squidmath.NumberToolsTest"
                    "squidpony.squidmath.OrderedDataTest")))

(define java-eversector-asciipanel
  (java-library
   "asciipanel" (git-version "1.2" "0" %asciipanel-commit)
   (project-source "trystan/AsciiPanel" %asciipanel-commit
                   "11skwz9323n3z1p6ig2kiqszi63hrm9wr8bvix2kg7wi3b0a1r48")
   "." "Swing CP437 display used by EverSector"
   "AsciiPanel displays a CP437 terminal in a Java Swing component using bitmap
fonts, configurable foreground and background colors, and keyboard input.
This package builds the exact revision selected by EverSector."
   license:expat
   #:test-inputs (list java-eversector-powermock-mockito)
   #:test-classes '("asciiPanel.AsciiPanelTest")))

(define java-eversector-apwt
  (java-library
   "apwt" (git-version "0" "0" %apwt-commit)
   (project-source "friedev/apwt" %apwt-commit
                   "0x1sv5q1kbah7c17dicfzbgyxkyb1naqh3jb3h4hwsph0b07idl9")
   "." "AsciiPanel window toolkit used by EverSector"
   "APWT is Aaron Friesen's AsciiPanel window toolkit.  It supplies displays,
screens, glyph strings, menus and file utilities for the original EverSector.
This package builds the game's exact submodule revision."
   license:expat
   #:dependencies (list java-eversector-asciipanel
                        java-eversector-squidlib-util java-eversector-regexodus)
   #:state-path? #t))              ; Upstream has no automated test suite.

(define %store-data-patch
  (local-file
   (search-tay-package-file "patches/eversector-store-data.patch")))

(define %font-notice
  (plain-file
   "FONT-NOTICES.txt"
   "EverSector font provenance and permissions (retrieved 2026-10-14)

All original assets/fonts/{alloy,cooz,qbicfeet}/{ascii.png,tiles.png} remain.
Aaron Friesen's custom tiles and changes accompany his GPL version 3 game;
the copied font designs retain the following permissions and attributions.
Original author credits: https://frie.dev/eversector/

Alloy 12x12: Alloy; exact author's wiki upload v1.1 dated 2010-12-03:
https://dwarffortresswiki.org/index.php/File:Alloy_curses_12x12.png
Cooz 16x16: Cooz; derives from tiles by Klokjammer and Marble Dice, with
other tile modifications and original tiles described in the repository:
https://dwarffortresswiki.org/index.php/File:Cooz_curses_square_16x16.png
https://dwarffortresswiki.org/index.php/File:Kjammer_square_16x16_v02.png
https://dwarffortresswiki.org/index.php/File:Md_curses_16x16.png
https://dwarffortresswiki.org/index.php/User:Marble_Dice
The exact Cooz file page declares its content GFDL & MIT unless otherwise
noted, links the copyright policy with rel=license, and states no exception.
Its recovered 2009 upload has incomplete earlier upload provenance; current
file-page terms are affirmative, not proof of each lost historical event.

The wiki's policy covers ALL contributions, not only textual articles:
https://dwarffortresswiki.org/index.php/Dwarf_Fortress_Wiki:Copyrights
https://dwarffortresswiki.org/index.php?title=Dwarf_Fortress_Wiki:Copyrights&oldid=212313
'You agree, by posting on this wiki, to release all your contributions under
the MIT and GFDL licenses. In cases where this is not possible, you agree to
not post the contribution on this wiki.'  This distribution uses the MIT
option.  No image-specific restrictive exception was stated on these pages.

qbicfeet 10x10: qbicfeet, included in Trystan Spangler's MIT AsciiPanel:
https://github.com/trystan/AsciiPanel/blob/4af354155a0c5f4d66efe3d837a9f327f5f2a358/src/main/resources/qbicfeet_10x10.png
The original AsciiPanel MIT copyright, permission and disclaimer are also
installed as licenses/AsciiPanel.txt and in source/asciipanel/LICENSE.md.

MIT permission text for wiki tilesets (authors credited above):
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the Software), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))

(define-public eversector
  (package
    (name "eversector")
    (version "0.7.3")
    (source
     (project-source "friedev/eversector" %game-commit
                     "05s63hlml13jnd6zg071d7zfqd9xg0986hg97laym9gy202qp2xy"))
    (build-system gnu-build-system)
    (native-inputs (list (list "icedtea:jdk" icedtea-8 "jdk")
                         (list "zip" zip)))
    (inputs (list bash-minimal coreutils-minimal icedtea-8
                  java-eversector-asciipanel java-eversector-apwt
                  java-eversector-squidlib-util java-eversector-regexodus))
    (arguments
     (list
      #:tests? #f                       ; Upstream has no automated suite.
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'configure-store-data
            (lambda _
              (setenv "TZ" "UTC")
              (setenv "SOURCE_DATE_EPOCH" "315532800")
              (copy-recursively "src" "original-src")
              ;; APWT is built separately from the exact gitlink sources.
              (delete-file "src/main/java/maugrift/apwt")
              (invoke "patch" "--batch" "--fuzz=0" "-p1"
                      "--input" #$%store-data-patch)
              (substitute* "src/main/java/maugrift/eversector/Main.java"
                (("@EVERSECTOR_DATA@")
                 (string-append #$output "/share/eversector")))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((classpath
                     (string-join
                      (append-map
                       (lambda (input)
                         (if (string-prefix? "java-eversector-" (car input))
                             (find-files (string-append (cdr input) "/share/java")
                                         "\\.jar$") '()))
                       inputs)
                      ":")))
                (mkdir-p "build/classes")
                (apply invoke (search-input-file inputs "/bin/javac")
                       "-encoding" "UTF-8" "-source" "8" "-target" "8"
                       "-classpath" classpath "-d" "build/classes"
                       (sort (find-files "src/main/java" "\\.java$") string<?))
                (for-each (lambda (file) (utime file 315532800 315532800))
                          (find-files "build/classes" ".*"))
                (let ((jar (string-append (getcwd) "/build/eversector.jar")))
                  (with-directory-excursion "build/classes"
                    (apply invoke "zip" "-X" "-q" jar
                           (sort (find-files "." ".*") string<?)))))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((data (string-append #$output "/share/eversector"))
                     (source (string-append data "/source"))
                     (bin (string-append #$output "/bin"))
                     (jars
                      (append-map
                       (lambda (input)
                         (if (string-prefix? "java-eversector-" (car input))
                             (find-files (string-append (cdr input) "/share/java")
                                         "\\.jar$") '()))
                       inputs)))
                (copy-recursively "assets" (string-append data "/assets"))
                (copy-recursively "licenses" (string-append data "/licenses"))
                (for-each (lambda (file) (install-file file data))
                          '("README.md" "LICENSE.txt" "CHANGELOG.md"))
                (copy-file #$%font-notice (string-append data "/FONT-NOTICES.txt"))
                (install-file "build/eversector.jar"
                              (string-append #$output "/share/java"))
                (copy-recursively "original-src"
                                  (string-append source "/game/src"))
                (copy-recursively "src"
                                  (string-append source "/built-game/src"))
                (for-each
                 (lambda (file) (install-file file (string-append source "/game")))
                 '("build.gradle" "build.sh" "settings.gradle" "README.md"
                   "LICENSE.txt" "CHANGELOG.md" ".gitmodules"))
                (copy-recursively "licenses" (string-append source "/game/licenses"))
                (copy-recursively "assets" (string-append source "/game/assets"))
                (for-each
                 (lambda (component)
                   (let* ((input (assoc-ref inputs
                                           (string-append "java-eversector-"
                                                          component)))
                          (original (string-append input "/share/eversector-source/"
                                                   component)))
                     (symlink original (string-append source "/" component))))
                 '("apwt" "asciipanel" "squidlib-util" "regexodus"))
                ;; Preserve the original source symlink and its submodule
                ;; relationship, with the independently pinned original APWT.
                (mkdir-p (string-append source "/game/lib"))
                (symlink "../../apwt" (string-append source "/game/lib/apwt"))
                (install-file #$%store-data-patch
                              (string-append source "/packaging"))
                (call-with-output-file (string-append data "/SOURCE-PINS.txt")
                  (lambda (port)
                    (format port (string-append
                                  "EverSector ~a~%APWT ~a~%AsciiPanel ~a~%"
                                  "SquidLib ~a~%RegExodus ~a~%")
                            #$%game-commit #$%apwt-commit #$%asciipanel-commit
                            #$%squidlib-commit #$%regexodus-commit)))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/eversector")
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%"
                            (search-input-file inputs "/bin/sh"))
                    (display
                     (string-append
                      "state=${XDG_STATE_HOME:-"
                      "${HOME:?HOME is not set}/.local/state}/eversector\n")
                     port)
                    (format port "~a -p -- \"$state\"~%cd -- \"$state\"~%"
                            (search-input-file inputs "/bin/mkdir"))
                    (format port
                            (string-append
                             "exec ~a -Dfile.encoding=UTF-8 -cp '~a' "
                             "maugrift.eversector.Main \"$@\"~%")
                            (search-input-file inputs "/bin/java")
                            (string-join
                             (append
                              (list (string-append #$output "/share/java/eversector.jar")
                                    data)
                              (sort jars string<?)) ":"))))
                (chmod (string-append bin "/eversector") #o755)))))))
    (home-page "https://frie.dev/eversector/")
    (synopsis "Space simulation roguelike with an individually simulated galaxy")
    (description "EverSector is a keyboard-controlled space simulation roguelike.
Pilot a starship through a procedurally generated galaxy, mine resources on
planets and asteroid belts, trade with stations, claim territory for your
faction, and interact with individually simulated ships.  This package builds
the original author's final release from source, retaining all three original
font families and keeping player saves and options in private user state.")
    (license (list license:gpl3 license:expat))))
