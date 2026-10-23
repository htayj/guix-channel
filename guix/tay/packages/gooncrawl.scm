;;; Original Gooncrawl v2.0, built from its complete immutable source release.

(define-module (tay packages gooncrawl)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages image)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages sqlite))

;; Exact release gitlink.  The native Linux build uses supported system
;; libraries for the other gitlinks, not bundled convenience libraries.
(define %gooncrawl-fonts
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/crawl/crawl-fonts/tar.gz/"
                        "6d3046974f35189a679a4d84b254efe82d1653b3"))
    (file-name "gooncrawl-fonts-6d304697.tar.gz")
    (sha256
     (base32 "1my66aw1wmysqr0z3smz8qyz6j7q9f4j0h8f3w22b4gnklh5k6i8"))))

(define-public gooncrawl
  (package
    (name "gooncrawl")
    (version "2.0")
    (source
     (origin
       (method url-fetch)
       ;; v2.0's commit, not the older default branch or prebuilt ZIP assets.
       (uri (string-append "https://codeload.github.com/Floodkiller/crawl/tar.gz/"
                           "eb805b9c1b92935c93094ffc5c19a99ba18839d8"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0miasgr0p5zz5i0nwlqx2jlvi8r2cjhdr9g4mfpih7dyc9v9ckav"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      #:parallel-tests? #f
      #:make-flags
      #~(list (string-append "prefix=" #$output)
              (string-append "DATADIR=" #$output "/share/gooncrawl")
              "SAVEDIR=" "SHAREDDIR="
              (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
              (string-append "SQLITE_LIB=-L" #$sqlite "/lib -lsqlite3")
              "FORCE_CC=gcc" "FORCE_CXX=g++" "LUA_PACKAGE=lua-5.1"
              "WEBTILES=" "USE_LUAJIT=" "USE_PCRE=" "BUILD_ALL="
              "BUILD_LUA=" "BUILD_SQLITE=" "BUILD_ZLIB=" "BUILD_PCRE="
              "BUILD_FREETYPE=" "BUILD_LIBPNG=" "BUILD_SDL2="
              "BUILD_SDL2IMAGE=" "BUILD_SDL2MIXER=" "NO_TRY_GOLD=YesPlease")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-source-copies
            (lambda* (#:key tests? #:allow-other-keys)
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/gooncrawl-build.patch")))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/gooncrawl-jester-equipment.patch")))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/gooncrawl-stress-pledge.patch")))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/gooncrawl-stress-lua-loader.patch")))
              ;; gen_ver.pl requires release_ver in archives without .git.
              (call-with-output-file "crawl-ref/source/util/release_ver"
                (lambda (port) (display "v2.0\n" port)))
              ;; The release already sorts installed maps with LC_ALL=C.
              (mkdir-p "font-input")
              (invoke "tar" "xf" #$%gooncrawl-fonts
                      "-C" "font-input" "--strip-components=1")
              (copy-recursively "font-input" "crawl-ref/source/contrib/fonts")
              ;; Different selectors and diagnostic macros must not share
              ;; generated headers, object files, or Makefile.cflags state.
              (copy-recursively "crawl-ref" "terminal")
              (copy-recursively "crawl-ref" "tiles")
              (when tests?
                (copy-recursively "crawl-ref" "diagnostic"))))
          (replace 'build
            (lambda* (#:key tests? make-flags #:allow-other-keys)
              (when tests?
                (with-directory-excursion "diagnostic/source"
                  ;; ctest.cc explicitly requires source-tree data lookup.
                  ;; Do not substitute a release executable for diagnostics.
                  (apply invoke "make" "-j1" "crawl" "docs"
                         (append make-flags
                                 '("TILES=" "SOUND=" "prefix=" "DATADIR="
                                   "EXTERNAL_DEFINES=-DDEBUG -DDEBUG_TESTS")))))
              (with-directory-excursion "terminal/source"
                (apply invoke "make" "-j1" "crawl" "docs"
                       "TILES=" "SOUND=" make-flags)
                ;; DATA_DIR_PATH has no source-tree fallback.  Stage the real
                ;; immutable data before running the release stress harness.
                (apply invoke "make" "-j1" "install-data"
                       "TILES=" "SOUND=" make-flags))
              (with-directory-excursion "tiles/source"
                (let ((flags (append '("TILES=y" "SOUND=y" "COPY_FONTS=y"
                                       "SYS_PROPORTIONAL_FONT="
                                       "SYS_MONOSPACED_FONT=")
                                     make-flags)))
                  (apply invoke "make" "-j1" "crawl" "docs" flags)
                  (apply invoke "make" "-j1" "install-data" flags)))))
          (replace 'check
            (lambda* (#:key tests? make-flags #:allow-other-keys)
              (when tests?
                (let ((scratch (string-append (getcwd) "/test-state")))
                  (for-each
                   (lambda (entry)
                     (let ((directory (string-append scratch "/" (cdr entry))))
                       (mkdir-p directory)
                       (setenv (car entry) directory)))
                   '(("HOME" . "home") ("XDG_CONFIG_HOME" . "config")
                     ("XDG_DATA_HOME" . "data") ("XDG_CACHE_HOME" . "cache")
                     ("XDG_STATE_HOME" . "state") ("XDG_RUNTIME_DIR" . "runtime")
                     ("TMPDIR" . "tmp")))
                  (chmod (getenv "XDG_RUNTIME_DIR") #o700)
                  (setenv "TERM" "xterm-256color")
                  (setenv "TERMINFO_DIRS"
                          #$(file-append ncurses "/share/terminfo"))
                  (let ((state (string-append scratch "/unit")))
                    (mkdir-p state)
                    (setenv "CRAWL_DIR" state)
                    (with-directory-excursion "diagnostic/source"
                      (apply invoke "make" "-j1" "test-test"
                             (append make-flags
                                     '("TILES=" "SOUND=" "prefix=" "DATADIR="
                                       "EXTERNAL_DEFINES=-DDEBUG -DDEBUG_TESTS")))))
                  ;; Preserve upstream's scenarios, seed, timeouts and native
                  ;; fake_pty driver.  These seeds are only upstream tests.
                  (let ((state (string-append scratch "/stress")))
                    (mkdir-p state)
                    (setenv "CRAWL_DIR" state)
                    (with-directory-excursion "terminal/source"
                      (apply invoke "make" "-j1" "nondebugtest"
                             "TILES=" "SOUND=" make-flags)))))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/gooncrawl"))
                     (data (string-append out "/share/gooncrawl"))
                     (doc (string-append out "/share/doc/gooncrawl")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (for-each
                 (lambda (entry)
                   (let* ((name (car entry))
                          (program (string-append libexec "/" name))
                          (launcher (string-append bin "/" name)))
                     (copy-file (cdr entry) program)
                     (chmod program #o555)
                     (call-with-output-file launcher
                       (lambda (port)
                         (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                         (display
                          (string-append
                           "case ${XDG_STATE_HOME-} in\n"
                           "  /*) base=$XDG_STATE_HOME ;;\n"
                           "  *) case ${HOME-} in\n"
                           "       /*) base=$HOME/.local/state ;;\n"
                           "       *) echo 'gooncrawl: an absolute HOME or "
                           "XDG_STATE_HOME is required' >&2; exit 1 ;;\n"
                           "     esac ;;\n"
                           "esac\n") port)
                         ;; Resolve .. and existing symlinks before any write.
                         (format port "state=$(~s -m -- \"$base/gooncrawl\")~%"
                                 #$(file-append coreutils-minimal "/bin/realpath"))
                         (display
                          (string-append
                           "case $state in\n"
                           "  /gnu/store|/gnu/store/*) echo 'gooncrawl: "
                           "refusing state in the immutable store' >&2; "
                           "exit 1 ;;\n"
                           "esac\n") port)
                         (format port "~s -p -- \"$state/macros\"~%"
                                 #$(file-append coreutils-minimal "/bin/mkdir"))
                         (display "export CRAWL_DIR=\"$state\"\n" port)
                         (format port
                                 (string-append "export TERMINFO_DIRS=~s"
                                                "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                                 #$(file-append ncurses "/share/terminfo"))
                         ;; Native options are case-insensitive and reject
                         ;; duplicates.  Supply the public macro default only
                         ;; when the user did not explicitly select one.
                         (display
                          (string-append
                           "macro_given=\n"
                           "for arg do\n"
                           "  case $arg in\n"
                           "    -[mM][aA][cC][rR][oO]|--[mM][aA][cC][rR][oO]) "
                           "macro_given=yes ;;\n"
                           "  esac\n"
                           "done\n"
                           "if [ -z \"$macro_given\" ]; then\n"
                           "  set -- -macro \"$state/macros\" \"$@\"\n"
                           "fi\n") port)
                         ;; HOME and original rc lookup remain untouched.
                         (format port "exec ~s \"$@\"~%" program)))
                     (chmod launcher #o555)))
                 '(("gooncrawl" . "terminal/source/crawl")
                   ("gooncrawl-tiles" . "tiles/source/crawl")))
                (install-file "README.md" doc)
                (install-file "crawl-ref/INSTALL.txt" doc)
                ;; Upstream Unix install-data omits the operative grant.
                (install-file "crawl-ref/licence.txt" doc)
                (install-file "crawl-ref/CREDITS.txt" doc)
                (copy-recursively "tiles/docs" (string-append doc "/docs"))
                (copy-recursively "crawl-ref/docs/license"
                                  (string-append doc "/license"))
                (install-file "crawl-ref/source/rltiles/license.txt"
                              (string-append doc "/license/rltiles"))
                (copy-recursively "crawl-ref/docs/gooncrawl"
                                  (string-append data "/docs/gooncrawl"))
                (for-each
                 (lambda (entry)
                   (copy-file (car entry) (string-append doc "/" (cdr entry))))
                 (list
                  (cons #$(local-file
                           (search-tay-package-file "files/gooncrawl-provenance.txt"))
                        "gooncrawl-provenance.txt")
                  (cons #$(local-file
                           (search-tay-package-file "files/gooncrawl-font-notices.txt"))
                        "gooncrawl-font-notices.txt")
                  (cons #$(local-file
                           (search-tay-package-file
                            "files/gooncrawl-third-party-notices.txt"))
                        "gooncrawl-third-party-notices.txt")
                  (cons #$(local-file
                           (search-tay-package-file "files/gooncrawl-GPL-3.txt"))
                        "gooncrawl-GPL-3.txt")
                  (cons #$(local-file
                           (search-tay-package-file "files/gooncrawl-Apache-2.0.txt"))
                        "gooncrawl-Apache-2.0.txt")))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "files/gooncrawl-font-notices.txt"))
                 (string-append data "/dat/tiles/FONT-LICENSES.txt"))))))))
    (native-inputs (list bison flex perl pkg-config which))
    (inputs (list bash-minimal coreutils-minimal lua-5.1 ncurses sqlite zlib
                  sdl2 sdl2-image sdl2-mixer freetype libpng mesa glu))
    (home-page "https://github.com/Floodkiller/crawl")
    (synopsis "Dungeon Crawl Stone Soup variant with restored and new features")
    (description
     "Gooncrawl is an independently playable Dungeon Crawl Stone Soup variant
with restored content, additional species and gods, and other gameplay changes.
This package builds its native console and SDL2/OpenGL tiles frontends, including
SDL2 mixer audio support and the exact original DejaVu fonts.  Both commands
share the complete immutable game data and keep saves, scores, macros and caches
under @file{$XDG_STATE_HOME/gooncrawl}, falling back to
@file{$HOME/.local/state/gooncrawl}.  The original user configuration and public
command-line options remain available.  The separate, mutually exclusive
Webtiles server deployment is not packaged.")
    ;; GPL2+ supplies the later-version option for the Apache2 PCG combination.
    ;; The integrated game grant is not a blanket CC0 grant for every tile.
    (license (list license:gpl2+ license:bsd-2 license:bsd-3 license:cc0
                   license:public-domain license:expat license:asl2.0
                   (license:x11-style "https://dejavu-fonts.github.io/License.html"
                                      "Bitstream Vera and Arev font licenses")))))
