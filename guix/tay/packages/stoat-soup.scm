;;; GNU Guix package for the Stoat Soup console roguelike.

(define-module (tay packages stoat-soup)
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
  #:use-module (gnu packages sqlite))

;; pcg.cc identifies Apache 2.0, but the release omits its full license text.
(define %stoat-soup-apache-license
  (origin
    (method url-fetch)
    (uri "https://www.apache.org/licenses/LICENSE-2.0.txt")
    (file-name "stoat-soup-apache-2.0.txt")
    (sha256
     (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))

(define-public stoat-soup
  (package
    (name "stoat-soup")
    (version "0.23-ish-aug26")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/damerell/crawl/tar.gz/refs/tags/"
             version))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; Archive SHA-256:
       ;; 50a0fd6a8836d522ef84c3789df85981b703cc441ae2552457332e5a1ade133e.
       ;; Release tag commit: 5df72bd44e7113642e311008665fafda6c7baa8c.
       (sha256
        (base32 "0ghkvqd5lbikawj5bqhs8k607dw1b7w9sy63hkpj5m9ni1mgv82h"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Keep the template-heavy C++ build within a single compiler's memory
      ;; footprint; the upstream stress targets are sequential as well.
      #:parallel-build? #f
      #:parallel-tests? #f
      #:make-flags
      #~(list (string-append "prefix=" #$output)
              (string-append "DATADIR=" #$output "/share/stoat-soup")
              "SAVEDIR=" "SHAREDDIR="
              (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
              (string-append "SQLITE_LIB=-L" #$sqlite "/lib -lsqlite3")
              "FORCE_CC=gcc" "FORCE_CXX=g++" "LUA_PACKAGE=lua-5.1"
              ;; Do not fetch or compile any absent bundled submodules.
              "TILES=" "BUILD_LUA=" "BUILD_SQLITE=" "BUILD_ZLIB="
              "USE_PCRE=" "NO_TRY_GOLD=YesPlease")
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
                  (display "0.23-ish-aug26\n" port)))
              ;; Guix's build compiler is gcc; no cc alias is provided.
              ;; Query that actual compiler for HOST/ARCH instead of recording
              ;; "unknown" in the native build metadata.
              (substitute* "Makefile"
                (((string-append "^HOST := \\$\\(shell sh -c 'cc -dumpmachine "
                                 "[|][|] echo unknown'\\)$"))
                 "HOST := $(shell sh -c 'gcc -dumpmachine || echo unknown')"))
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
                       (state (string-append scratch "/state/stoat-soup")))
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
                           "timeout 595 ./crawl -macro " state " -dir " state
                           " -seed 1 -no-save -name test -wizard -no-throttle"))
                  ;; Upstream builds its own util/fake_pty for this target.
                  ;; That test utility is deliberately never installed.
                  (apply invoke "make" "-j1" "nondebugtest" make-flags)))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (doc (string-append out "/share/doc/stoat-soup"))
                     (notices (string-append doc "/source-notices"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/stoat-soup"))
                     (launcher (string-append bin "/stoat-soup")))
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (copy-file "crawl" program)
                (chmod program #o555)
                (install-file "../../LICENCE" doc)
                (install-file "../../README.md" doc)
                (install-file "../INSTALL.md" doc)
                (install-file "../CREDITS.txt" doc)
                ;; install-data only copies selected text documentation;
                ;; retain the complete upstream docs and Stoat-specific docs.
                (copy-recursively "../docs" (string-append doc "/docs"))
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                (copy-recursively "../stoat-docs"
                                  (string-append doc "/stoat-docs"))
                ;; These notices live in source headers, not docs/license.
                ;; Copy originals intact rather than paraphrasing obligations.
                (for-each (lambda (file) (install-file file notices))
                          '("json.cc" "json.h" "pcg.cc"
                            "perlin.cc" "perlin.h"
                            "worley.cc" "worley.h"
                            "domino.cc" "domino.h" "domino-data.h"))
                (copy-file #$%stoat-soup-apache-license
                           (string-append doc "/license/apache-2.0.txt"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (display
                     (string-append
                      "state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}/stoat-soup\"\n")
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
    (home-page "https://github.com/damerell/crawl")
    (synopsis "Console Stoat Soup roguelike variant")
    (description
     "Stoat Soup is an independently playable variant of Dungeon Crawl Stone
Soup.  This package builds the pinned upstream release's console frontend with
Guix's Lua, ncurses, SQLite, and zlib, without graphical submodules.  It installs
the complete console game data and upstream documentation.  The launcher keeps
saves, scores, macros, and compiled caches in @file{$XDG_STATE_HOME/stoat-soup},
falling back to @file{$HOME/.local/state/stoat-soup}, and forwards native game
options without adding a separate runtime mode.")
    ;; GNU console closure: main game GPLv2+, domino and named historical
    ;; contributions BSD-2, json and worley MIT, perlin public domain/CC0,
    ;; pcg Apache 2.0.  MSVC stdint BSD-3, SDL LGPL, libpng and PCRE code
    ;; are not selected; retained historical docs are not dependencies.
    (license (list license:gpl2+ license:bsd-2 license:expat
                   license:public-domain license:cc0 license:asl2.0))))
