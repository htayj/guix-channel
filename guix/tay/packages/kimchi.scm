;;; GNU Guix package for the Kimchi console roguelike.

(define-module (tay packages kimchi)
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
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (tay packages auxiliary)
  #:use-module (gnu packages sqlite))

;; pcg.cc identifies Apache 2.0, but the release omits its full license text.
(define %kimchi-apache-license
  (origin
    (method url-fetch)
    (uri "https://www.apache.org/licenses/LICENSE-2.0.txt")
    (file-name "kimchi-apache-2.0.txt")
    (sha256
     (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))

(define-public kimchi
  (package
    (name "kimchi")
    (version "1.3.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/kimjoy2002/crawl/tar.gz/"
             "8f533dcfe5fe76833cb636531bae56e3bf106556"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; Independently fetched archive SHA-256:
       ;; 0aa72c8d85467374435f69bfa59e2f02787f452a24b49cc3075b18ad43906b47.
       ;; kimchi-1.3.2 release commit; no recursive submodule fetching.
       (sha256
        (base32 "0ivbj11ss62v0z1rrd14592pyy025ygabgv9bx1p8ws6hn6jr9qa"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Keep the template-heavy C++ build within a single compiler's memory
      ;; footprint; the upstream stress targets are sequential as well.
      #:parallel-build? #f
      #:parallel-tests? #f
      #:make-flags
      #~(list (string-append "prefix=" #$output)
              (string-append "DATADIR=" #$output "/share/kimchi")
              "SAVEDIR=" "SHAREDDIR="
              (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
              (string-append "SQLITE_LIB=-L" #$sqlite "/lib -lsqlite3")
              "FORCE_CC=gcc" "FORCE_CXX=g++" "LUA_PACKAGE=lua-5.1"
              ;; Do not fetch or compile any absent bundled submodules.
              "TILES=" "WEBTILES=" "SOUND=" "BUILD_ALL=" "COPY_FONTS="
              "BUILD_LUA=" "BUILD_SQLITE=" "BUILD_ZLIB="
              "USE_PCRE=" "NO_TRY_LLD=YesPlease" "NO_TRY_GOLD=YesPlease")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "crawl-ref/source")
              ;; The fixed archive lacks .git: do not derive a version from
              ;; the build host or the surrounding channel checkout.
              (call-with-output-file "util/release_ver"
                (lambda (port)
                  (display "kimchi-1.3.2\n" port)))
              ;; Python 3.10 moved abstract containers to collections.abc.
              ;; The generator already uses yaml.safe_load, not removed load.
              (substitute* "util/species-gen.py"
                (("^import collections\n") "import collections\nimport collections.abc\n")
                (("collections.MutableMapping") "collections.abc.MutableMapping"))
              ;; Guix's build compiler is gcc; no cc alias is provided.
              ;; Query that actual compiler for HOST/ARCH instead of recording
              ;; "unknown" in the native build metadata.
              (substitute* "Makefile"
                (("^HOST :=.*$")
                 "HOST := $(shell gcc -dumpmachine)\n"))
              ;; A source archive has neither git nor repository metadata.
              (substitute* "Makefile"
                (("^SRC_VERSION[ ]*:=.*$")
                 "SRC_VERSION := kimchi-1.3.2\n")
                (("^RECENT_TAG[ ]*:=.*$")
                 "RECENT_TAG := kimchi-1.3.2\n"))
              ;; The fork adds an Artificer equipment menu before Lua ready().
              ;; Keep upstream fixtures intact: the external PTY adapter picks
              ;; the original bundle of wands from that actual native menu.
              ;; It never synthesizes saves or drives any gameplay actions.
              (copy-file #$(local-file
                            (search-tay-package-file
                             "../../../tests/kimchi-stress-pty.py"))
                         "util/kimchi-stress-pty.py")
              (substitute* "Makefile"
                (("util/fake_pty test/stress/run")
                 "python3 util/kimchi-stress-pty.py test/stress/run"))
              ;; builddb is a prerequisite of upstream nondebugtest.  Its
              ;; default macro path would otherwise create HOME/.crawl even
              ;; with CRAWL_DIR set.  Make expands $$ to the shell's $.
              (substitute* "Makefile"
                (("\\./\\$\\(GAME\\) --builddb")
                 "./$(GAME) -macro \"$$CRAWL_DIR\" --builddb"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "-j1" "crawl" "docs" make-flags)
              ;; DATA_DIR_PATH is compiled in without a source-tree fallback.
              ;; Stage genuine install-data before check so the stress suite
              ;; reads the same complete console assets as the installed game.
              (apply invoke "make" "-j1" "install-data" make-flags)))
          (replace 'check
            (lambda* (#:key tests? make-flags #:allow-other-keys)
              (when tests?
                (let* ((scratch (string-append (getcwd) "/test-state"))
                       (state (string-append scratch "/state/kimchi")))
                  (for-each
                   (lambda (entry)
                     (let ((directory (string-append scratch "/" (cdr entry))))
                       (mkdir-p directory)
                       (setenv (car entry) directory)))
                   '(("HOME" . "home")
                     ("XDG_CONFIG_HOME" . "config")
                     ("XDG_DATA_HOME" . "data")
                     ("XDG_CACHE_HOME" . "cache")
                     ("XDG_STATE_HOME" . "state")
                     ("XDG_RUNTIME_DIR" . "runtime")
                     ("TMPDIR" . "tmp")))
                  (chmod (getenv "XDG_RUNTIME_DIR") #o700)
                  (mkdir-p state)
                  (setenv "CRAWL_DIR" state)
                  (setenv "TERM" "xterm-256color")
                  (setenv "TERMINFO_DIRS"
                          #$(file-append ncurses "/share/terminfo"))
                  ;; Preserve test/stress/run's actual defaults and all tests;
                  ;; only redirect mutable files and the legacy macro path.
                  (setenv "CRAWL"
                          (string-append
                           "timeout --foreground 595 ./crawl -macro " state " -dir " state
                           " -seed 1 -no-save -name test -wizard -no-throttle"))
                  ;; Only the uninstalled observer selects the native menu.
                  ;; Every original bot and arena fixture remains enabled.
                  (apply invoke "make" "-j1" "nondebugtest" make-flags)))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (doc (string-append out "/share/doc/kimchi"))
                     (notices (string-append doc "/source-notices"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/kimchi"))
                     (launcher (string-append bin "/kimchi")))
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (copy-file "crawl" program)
                (chmod program #o555)
                (install-file "../../LICENSE" doc)
                (install-file "../INSTALL.txt" doc)
                (install-file "../CREDITS.txt" doc)
                ;; install-data selects text docs.  Do not additionally
                ;; install the source documentation's rendered PDF assets.
                (copy-recursively (string-append out "/share/kimchi/docs")
                                  (string-append doc "/docs"))
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                ;; These notices live in source headers, not docs/license.
                ;; Copy originals intact rather than paraphrasing obligations.
                (for-each (lambda (file) (install-file file notices))
                          '("json.cc" "json.h" "pcg.cc"
                            "perlin.cc" "perlin.h"
                            "worley.cc" "worley.h"
                            "domino.cc" "domino.h" "domino-data.h"
                            "platform.h"))
                (copy-file #$%kimchi-apache-license
                           (string-append doc "/license/apache-2.0.txt"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (display
                     (string-append
                      "state=\"${XDG_DATA_HOME:-${HOME:?HOME or "
                      "XDG_DATA_HOME must be set}/.local/share}/kimchi\"\n")
                     port)
                    (format port "~s -p \"$state\"~%"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display "export CRAWL_DIR=\"$state\"\n" port)
                    (format port
                            (string-append "export TERMINFO_DIRS=~s"
                                           "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            #$(file-append ncurses "/share/terminfo"))
                    ;; Inspectors such as --edit-save consume all remaining
                    ;; arguments; put native defaults first, not in that tail.
                    (format port
                            "exec ~s -macro \"$state\" -dir \"$state\" \"$@\"~%"
                            program)))
                (chmod launcher #o555)))))))
    (native-inputs (list bison flex perl pkg-config python-pyyaml
                         python-wrapper which))
    (inputs (list bash-minimal coreutils-minimal lua-5.1 ncurses sqlite zlib))
    (home-page "https://github.com/kimjoy2002/crawl")
    (synopsis "Korean console Dungeon Crawl Stone Soup variant")
    (description
     "Kimchi is an independently playable Korean variant of Dungeon Crawl Stone
Soup, based on the 0.24 series.  This package builds the pinned upstream
release's console frontend with
Guix's Lua, ncurses, SQLite, and zlib, without graphical submodules.  It installs
the complete console game data and upstream documentation.  The launcher keeps
saves, scores, macros, and compiled caches in @file{$XDG_DATA_HOME/kimchi},
falling back to @file{$HOME/.local/share/kimchi}, and forwards native game
options without adding a separate runtime mode.")
    ;; GNU console closure: main game GPLv2+, domino and named historical
    ;; contributions BSD-2, json and worley MIT, perlin public domain/CC0,
    ;; pcg Apache 2.0.  MSVC stdint BSD-3, SDL LGPL, libpng and PCRE code
    ;; are not selected; retained historical docs are not dependencies.
    (license (list license:gpl2+ license:bsd-2 license:expat
                   license:public-domain license:cc0 license:asl2.0))))
