;;; GNU Guix package for the Bloatcrawl 2 terminal roguelike.

(define-module (tay packages bloatcrawl2)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
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

(define bloatcrawl2-smoke-script
  (local-file (search-tay-package-file "bloatcrawl2-smoke.py")))

(define-public bloatcrawl2
  (package
    (name "bloatcrawl2")
    ;; The Bloatcrawl 2.2.0 tag, published on 2020-01-01.
    (version "2.2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Hellmonk/bloatcrawl2")
             (commit "ff89137ce52d26b891517517c0aec9013ed8bea5")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the tracked tag tree.  Git metadata and gitlink
       ;; contents are absent: the terminal build uses Guix libraries.  The
       ;; corresponding `guix hash --format=base32' value is
       ;; i3qwtrvxsipm7ojrexgkoias6i2fgxj4s7pahzefaelwrekfrwsa; this is its
       ;; Nix-base32 representation required by the origin field.
       (sha256
        (base32 "194d8n8nh5q1hpj07plp7ifm6d7j28hagk1566wwy7ljnz36kqa6"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream test suite needs its own test harness and diagnostic
      ;; options.  The installed game is exercised by tests/bloatcrawl2-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "crawl-ref/source")
              ;; git-fetch supplies no .git directory, so give Makefile's
              ;; documented version fallback the fixed upstream release.
              (call-with-output-file "util/release_ver"
                (lambda (port)
                  (display "2.2.0\n" port)))))
          (add-after 'enter-source-directory 'patch-python-compat
            (lambda _
              ;; Python 3.11 removed the old collections.MutableMapping
              ;; alias used by this release's YAML generator.
              (substitute* "util/species-gen.py"
                (("class Species\\(collections\\.MutableMapping\\):")
                 "from collections.abc import MutableMapping

class Species(MutableMapping):"))))
          (add-after 'patch-python-compat 'patch-cxx-header
            (lambda _
              ;; Current libstdc++ no longer exposes iswalnum through the
              ;; transitive headers used by this old source file.
              (substitute* "ui.cc"
                (("#include <chrono>")
                 "#include <chrono>\n#include <cwctype>"))))
          (replace 'build
            (lambda _
              ;; An empty TILES value selects the console build and avoids
              ;; SDL, fonts, sound, and the tile source tree.
              (invoke "make"
                      "crawl"
                      (string-append "DATADIR="
                                     #$output "/share/bloatcrawl2")
                      (string-append "SQLITE_INCLUDE_DIR="
                                     #$sqlite "/include")
                      "FORCE_CC=gcc"
                      "FORCE_CXX=g++"
                      "LUA_PACKAGE=lua-5.1"
                      "TILES=")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/bloatcrawl2"))
                     (doc (string-append #$output "/share/doc/bloatcrawl2"))
                     (libexec (string-append #$output "/libexec"))
                     (bin (string-append #$output "/bin"))
                     (program (string-append libexec "/bloatcrawl2"))
                     (smoke-runner (string-append libexec
                                    "/bloatcrawl2-smoke.py"))
                     (launcher (string-append bin "/bloatcrawl2")))
                ;; Upstream install also manages mutable paths.  install-data
                ;; only copies the immutable console assets and documentation.
                (invoke "make"
                        "install-data"
                        ;; Upstream refuses install-data without a staging
                        ;; prefix, even though DATADIR is absolute.
                        (string-append "prefix="
                                       #$output)
                        (string-append "DATADIR=" data)
                        (string-append "SQLITE_INCLUDE_DIR="
                                       #$sqlite "/include")
                        "FORCE_CC=gcc"
                        "FORCE_CXX=g++"
                        "LUA_PACKAGE=lua-5.1"
                        "TILES=")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "crawl" libexec)
                (rename-file (string-append libexec "/crawl") program)
                ;; The PTY driver creates a character and plays turns.
                (copy-file #$bloatcrawl2-smoke-script smoke-runner)
                (chmod smoke-runner #o555)
                ;; LICENSE applies to the program as a whole.  CREDITS and
                ;; the compatible component notices cover installed assets.
                (install-file "../../LICENSE" doc)
                (install-file "../CREDITS.txt" doc)
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                ;; install-data does not include the source-side RLTiles
                ;; notice when tiles are disabled, but the source tree is
                ;; still covered by the release's licensing record.
                (install-file "rltiles/license.txt"
                              (string-append doc "/license"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%"
                            #$bash-minimal)
                    (format port "program=~s~%output=~s~%" program
                            #$output)
                    (format port
                            "cp=~s~%mkdir=~s~%mktemp=~s~%rm=~s~%find=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm")
                            #$(file-append findutils "/bin/find"))
                    (format port "python=~s~%runner=~s~%"
                            #$(file-append python "/bin/python3") smoke-runner)
                    (format port "terminfo=~s~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display "set -eu\nprepare_environment() {\n" port)
                    (display "  state=\"${XDG_DATA_HOME:-${HOME:?HOME or "
                             port)
                    (display
                     "XDG_DATA_HOME must be set}/.local/share}/bloatcrawl2\"
"
                     port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  export CRAWL_DIR=\"$state\"\n" port)
                    ;; Bloatcrawl 2 also creates its legacy .crawl directory
                    ;; below HOME for macros and cache data, even when
                    ;; CRAWL_DIR is set.  Keep that data in the same XDG-owned
                    ;; state root rather than leaking it into the caller's
                    ;; home directory.
                    (display "  export HOME=\"$state\"\n" port)
                    (display "  export TERMINFO_DIRS=\"$terminfo" port)
                    (display "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n" port)
                    (display "}\nrun_game() {\n  prepare_environment\n" port)
                    (display "  exec \"$program\" \"$@\"\n}\n" port)
                    (display "if test \"${1:-}\" = --smoke" port)
                    (display " && test \"$#\" -eq 1; then\n" port)
                    (display "  scratch=$(\"$mktemp\" -d" port)
                    (display " \"${TMPDIR:-/tmp}/bloatcrawl2-smoke.XXXXXXXX\")\n"
                             port)
                    (display "  trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n"
                             port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\""
                             port)
                    (display " \"$scratch/cache\" \"$scratch/data\"" port)
                    (display " \"$scratch/state\"" port)
                    (display " \"$scratch/runtime\" \"$scratch/work\"\n" port)
                    (display "  export HOME=\"$scratch/home\"" port)
                    (display " XDG_CONFIG_HOME=\"$scratch/config\"" port)
                    (display " XDG_CACHE_HOME=\"$scratch/cache\"" port)
                    (display " XDG_DATA_HOME=\"$scratch/data\"" port)
                    (display " XDG_STATE_HOME=\"$scratch/state\"" port)
                    (display " XDG_RUNTIME_DIR=\"$scratch/runtime\"" port)
                    (display " TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  prepare_environment\n" port)
                    ;; The PTY driver creates a seeded character, plays turns
                    ;; on the HUD clock and quits.  It writes the session's
                    ;; raw prefix, up to the last gameplay frame, to ui.raw.
                    (display "  cd \"$scratch/work\"\n" port)
                    (display "  pty_proof=$(\"$python\" \"$runner\" \"$program\""
                             port)
                    (display " \"$scratch/ui.raw\")\n" port)
                    (display "  test \"$pty_proof\" = BLOATCRAWL2_PTY_OK\n" port)
                    (display "  test -s \"$scratch/ui.raw\"\n" port)
                    ;; Evidence capture receives the real PTY stream before
                    ;; cleanup, so its PNG renders the terminal UI itself.
                    (display
                     "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\";"
                     port)
                    (display " then\n" port)
                    (display "    \"$cp\" \"$scratch/ui.raw\"" port)
                    (display " \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    ;; Scores, morgues and macros stay in the XDG data tree.
                    (display "  test -z \"$(\"$find\" \"$scratch/home\"" port)
                    (display " \"$scratch/config\" \"$scratch/cache\"" port)
                    (display " \"$scratch/state\" \"$scratch/runtime\"" port)
                    (display " \"$scratch/work\" -mindepth 1 -print -quit)\"\n"
                             port)
                    (display "  test -d \"$CRAWL_DIR\" && test ! -w \"$output\"\n"
                             port)
                    (display "  printf '%s\\n'" port)
                    (display
                     " 'bloatcrawl2 smoke: terminal UI OK; no store writes'\n"
                     port)
                    (display "  exit 0\nfi\n" port)
                    (display "run_game \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; Upstream's generated-source scripts use the unversioned `python'
    ;; interpreter name; python-wrapper supplies that name in the build PATH.
    (native-inputs (list bison
                         flex
                         perl
                         pkg-config
                         python-pyyaml
                         python-wrapper
                         which))
    (inputs (list bash-minimal
                  coreutils-minimal
                  findutils
                  lua-5.1
                  ncurses
                  python
                  sqlite
                  zlib))
    (home-page "https://github.com/Hellmonk/bloatcrawl2")
    (synopsis "Terminal fork of Dungeon Crawl Stone Soup")
    (description
     "Bloatcrawl 2 is an independently playable fork of Dungeon Crawl Stone
Soup.  This package builds and installs only its terminal frontend; it does
not fetch, build, or install tile, sound, SDL, font, or webserver components.
The launcher keeps mutable saves and scores in
@file{$XDG_DATA_HOME/bloatcrawl2}, falling back to
@file{$HOME/.local/share/bloatcrawl2}.  It has no updater, telemetry, or
runtime download in the console path.")
    ;; The root license applies to the combined program.  The release also
    ;; includes compatible BSD, MIT, Apache-2.0, zlib, CC0/public-domain,
    ;; LGPL, and Boost-licensed components; their notices are installed.
    (license (list license:gpl2+
                   license:cc0
                   license:public-domain
                   license:bsd-2
                   license:bsd-3
                   license:expat
                   license:asl2.0
                   license:zlib
                   license:lgpl2.1+
                   license:boost1.0
                   (license:fsdg-compatible
                    "https://www.libpng.org/pub/png/src/libpng-LICENSE.txt")
                   (license:fsdg-compatible
                    "https://www.pcre.org/original/doc/html/pcre2license.html")))))
