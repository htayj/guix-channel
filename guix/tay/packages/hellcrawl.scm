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
          (add-after 'enter-source-directory 'patch-cxx-compatibility
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
                    (format port "program=~s~%mkdir=~s~%"
                            program
                            #$(file-append coreutils-minimal "/bin/mkdir"))
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
                    (display "}\nprepare_environment\nexec \"$program\" \"$@\"\n"
                             port)))
                (chmod launcher #o555)))))))
    (native-inputs (list bison flex perl pkg-config which))
    (inputs (list bash-minimal coreutils-minimal lua-5.1 ncurses
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
download.  The repository acceptance test drives the installed game through
an isolated PTY, advances a dungeon turn, and saves and reloads the character.")
    ;; Console code and data inherit GPL-2.0-or-later; the bundled perlin,
    ;; json, worley, and pcg sources carry the compatible licenses below.
    ;; Tile-only libraries are not linked.  Their upstream notices remain
    ;; installed with the documentation, not asserted as program licenses.
    (license (list license:gpl2+
                   license:bsd-2
                   license:cc0
                   license:public-domain
                   license:expat
                   license:asl2.0))))
