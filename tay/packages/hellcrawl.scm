;;; GNU Guix package for the Hellcrawl terminal roguelike.

(define-module (tay packages hellcrawl)
  #:use-module (guix build-system gnu)
  #:use-module (guix build utils)
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
  #:use-module (gnu packages sqlite))

;; This helper is built from source and is only reachable through the
;; package-owned --smoke mode.  It avoids a runtime dependency on a host PTY
;; utility while keeping the requested runtime closure small.
(define %hellcrawl-smoke-pty
  (local-file "hellcrawl-smoke-pty.c"))

(define-public hellcrawl
  (package
    (name "hellcrawl")
    ;; Hellcrawl 5.7, published at the pinned upstream commit.
    (version "5.7")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Hellmonk/hellcrawl")
             (commit "8abd87763372e1c1be472510ac55faeff7b0dca7")))
       (file-name (git-file-name name version))
       ;; Guix git-fetch tree hash for the fixed checkout.  The corresponding
       ;; raw git-archive SHA-256 is
       ;; 0f0fb566c6af9ecd1fdf1306fb2c2984b8cbda71f19b5bc5d31ff32b3b8bbffb.
       (sha256
        (base32 "105593jwy1k7s25m1nlvszcy3hqc616hkmvdh6n5qmyy4lwagc79"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream tests require their historical test harness.  The
      ;; installed terminal game is exercised by tests/hellcrawl-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "crawl-ref/source")
              ;; git-fetch supplies no .git directory, so make version
              ;; generation deterministic for this fixed release.
              (call-with-output-file "util/release_ver"
                (lambda (port)
                  (display "5.7\n" port)))))
          (add-after 'enter-source-directory 'build-smoke-helper
            (lambda _
              (copy-file #$%hellcrawl-smoke-pty "hellcrawl-smoke-pty.c")
              ;; forkpty is provided by the standard system libutil; the GNU
              ;; toolchain is supplied by gnu-build-system.
              (invoke "gcc" "-O2" "-Wall" "-Wextra"
                      "-o" "hellcrawl-smoke-pty"
                      "hellcrawl-smoke-pty.c" "-lutil")))
          (add-after 'build-smoke-helper 'patch-cxx-compatibility
            (lambda _
              ;; Modern libstdc++ no longer provides ostream through the
              ;; transitive headers used by this old release.
              (substitute* "domino.h"
                (("#include <vector>" )
                 "#include <vector>\n#include <ostream>"))))
          (replace 'build
            (lambda _
              ;; An empty TILES value selects the console build and avoids
              ;; SDL, fonts, sound, and tile/contrib sources.
              (invoke "make" "crawl"
                      (string-append "DATADIR="
                                     #$output "/share/hellcrawl")
                      (string-append "SQLITE_INCLUDE_DIR="
                                     #$sqlite "/include")
                      (string-append "SQLITE_LIB=-L"
                                     #$sqlite "/lib -lsqlite3")
                      "FORCE_CC=gcc"
                      "FORCE_CXX=g++"
                      "LUA_PACKAGE=lua-5.1"
                      "TILES=")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/hellcrawl"))
                     (doc (string-append out "/share/doc/hellcrawl"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/hellcrawl"))
                     (runner (string-append libexec
                                             "/hellcrawl-smoke-pty"))
                     (launcher (string-append bin "/hellcrawl")))
                ;; install-data copies only the console data and text
                ;; documentation when TILES and WEBTILES are unset.  A
                ;; prefix is required by this old Makefile even with an
                ;; absolute DATADIR.
                (invoke "make" "install-data"
                        (string-append "prefix=" out)
                        (string-append "DATADIR=" data)
                        (string-append "SQLITE_INCLUDE_DIR="
                                       #$sqlite "/include")
                        (string-append "SQLITE_LIB=-L"
                                       #$sqlite "/lib -lsqlite3")
                        "FORCE_CC=gcc"
                        "FORCE_CXX=g++"
                        "LUA_PACKAGE=lua-5.1"
                        "TILES=")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "crawl" libexec)
                (rename-file (string-append libexec "/crawl") program)
                (install-file "hellcrawl-smoke-pty" libexec)
                ;; Keep the upstream license filename and attribution next
                ;; to the installed terminal program and data.
                (install-file "../licence.txt" doc)
                (install-file "../CREDITS.txt" doc)
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                (install-file "rltiles/license.txt"
                              (string-append doc "/license"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%"
                            #$bash-minimal)
                    (format port "program=~s~%runner=~s~%output=~s~%"
                            program runner out)
                    (format port
                            "cp=~s~%mkdir=~s~%mktemp=~s~%find=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append findutils "/bin/find"))
                    (format port "terminfo=~s~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display
                     "prepare_environment() {\n"
                     port)
                    (display
                     (string-append
                      "  state=\"${XDG_DATA_HOME:-${HOME:?HOME or "
                      "XDG_DATA_HOME must be set}/.local/share}/hellcrawl\"\n")
                     port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  export CRAWL_DIR=\"$state\"\n" port)
                    ;; The game has legacy ~/.crawl lookups as well as
                    ;; CRAWL_DIR, so point HOME at the same mutable root.
                    (display "  export HOME=\"$state\"\n" port)
                    (display
                     (string-append
                      "  export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "}\nrun_game() {\n  prepare_environment\n"
                             port)
                    (display "  exec \"$program\" \"$@\"\n}\n" port)
                    (display
                     "if test \"${1:-}\" = --smoke; then\n"
                     port)
                    (display "  test \"$#\" -eq 1\n" port)
                    (display
                     (string-append
                      "  scratch=$(\"$mktemp\" -d "
                      "\"${TMPDIR:-/tmp}/hellcrawl-smoke.XXXXXXXX\")\n")
                     port)
                    (display
                     (string-append
                      "  \"$mkdir\" -p \"$scratch/home\" "
                      "\"$scratch/config\" \"$scratch/data\" "
                      "\"$scratch/cache\"\n")
                     port)
                    (display
                     (string-append
                      "  \"$mkdir\" -p \"$scratch/state\" "
                      "\"$scratch/runtime\" \"$scratch/tmp\"\n")
                     port)
                    (display "  export HOME=\"$scratch/home\"\n" port)
                    (display "  export XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display "  export XDG_DATA_HOME=\"$scratch/data\"\n" port)
                    (display "  export XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display "  export XDG_STATE_HOME=\"$scratch/state\"\n" port)
                    (display "  export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display "  export TMPDIR=\"$scratch/tmp\"\n" port)
                    (display "  export TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  prepare_environment\n  cd \"$scratch\"\n" port)
                    (display
                     (string-append
                      "  \"$runner\" \"$program\" -seed 285 -no-save "
                      "-name Goocastle -species Hu -background Fi "
                      ">\"$scratch/ui.raw\"\n")
                     port)
                    (display "  test -s \"$scratch/ui.raw\"\n" port)
                    (display
                     "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n"
                     port)
                    (display
                     (string-append
                      "    \"$cp\" \"$scratch/ui.raw\" "
                      "\"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n")
                     port)
                    (display "  fi\n" port)
                    (display
                     (string-append
                      "  test -z \"$(\"$find\" \"$scratch/home\" "
                      "\"$scratch/config\" \"$scratch/cache\" "
                      "\"$scratch/state\" \"$scratch/runtime\" "
                      "-mindepth 1 -print -quit)\"\n")
                     port)
                    (display "  test -d \"$scratch/data/hellcrawl\"\n" port)
                    (display "  test ! -w \"$output\"\n" port)
                    (display
                     (string-append
                      "  printf '%s\\n' 'hellcrawl smoke: terminal UI OK; "
                      "no store writes'\n")
                     port)
                    (display "  exit 0\nfi\nrun_game \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list bison flex perl pkg-config which))
    (inputs (list bash-minimal coreutils-minimal findutils lua-5.1 ncurses
                  sqlite zlib))
    (home-page "https://github.com/Hellmonk/hellcrawl")
    (synopsis "Terminal fork of Dungeon Crawl Stone Soup")
    (description
     "Hellcrawl is an independently playable, streamlined fork of Dungeon
Crawl Stone Soup.  This package builds and installs its terminal frontend
from the fixed upstream source tree, using Guix's Lua, ncurses, SQLite, and
zlib libraries.  It excludes the upstream tile, font, sound, webserver, and
contrib gitlink contents.  The launcher keeps saves, logs, and other mutable
state under @file{$XDG_DATA_HOME/hellcrawl}, falling back to
@file{$HOME/.local/share/hellcrawl}; it has no updater, telemetry, or runtime
download.  Its package-owned @option{--smoke} mode drives the installed game
through an isolated PTY and verifies character creation, dungeon entry, and
the absence of writes to the immutable store output.")
    ;; The terminal closure contains the GPL program and compatible BSD-2,
    ;; BSD-3, CC0/public-domain, MIT, zlib, Apache-2.0, and bundled-notice
    ;; components.  The upstream notices are installed beside the output.
    (license (list license:gpl2+
                   license:bsd-2
                   license:bsd-3
                   license:cc0
                   license:public-domain
                   license:expat
                   license:zlib
                   license:asl2.0
                   license:lgpl2.1+
                   (license:fsdg-compatible
                    "https://www.libpng.org/pub/png/src/libpng-LICENSE.txt")
                   (license:fsdg-compatible
                    "https://www.pcre.org/original/doc/html/pcre2license.html")))))
