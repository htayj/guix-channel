;;; GNU Guix package for the native EvilHack tty/curses roguelike.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages evilhack)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (tay packages auxiliary))

(define %evilhack-commit
  "c444f6a3ab1e9f16d0676961dba86f628e91c6ba")

(define-public evilhack
  (package
    (name "evilhack")
    (version "0.9.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/k21971/EvilHack")
             (commit %evilhack-commit)))
       (file-name (git-file-name name version))
       ;; Verified from a fresh canonical v0.9.3 checkout, excluding .git.
       (sha256
        (base32 "0xrp2djn1mwvxkygkn8q8yjsfn3r6swgfxccvcyzzmxk5560pb5n"))
       (patches
        (list (search-tay-package-file "patches/evilhack-private-state.patch")))
       (patch-flags '("-p1" "--fuzz=0"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Optional graphical/font/encoded sound assets are not in the
           ;; selected standalone Unix tty/curses closure.  In particular,
           ;; the sound README does not supply a clear redistribution grant.
           (for-each delete-file
                     (append
                      (find-files "." "\\.(uue?|hqx|png|PNG|xpm|xbm|bdf)$")
                      '("win/X11/nh32icon" "win/X11/nh56icon"
                        "win/X11/nh72icon" "sys/unix/XCode.xcconfig"
                        "doc/tmac.n" "doc/tmac.nh")))))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Generated yacc/lex sources and level/data targets need serial make.
      #:parallel-build? #f
      ;; No upstream non-interactive test suite exists.  The external native
      ;; consumer in tests/evilhack-smoke.sh exercises the installed game.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "LINK=" #$(cc-for-target))
              "LEX=flex" "YACC=bison -y" "GITINFO=0")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-unix-build
            (lambda _
              (substitute* "sys/unix/setup.sh"
                (("/bin/sh") #$(file-append bash-minimal "/bin/sh"))
                (("^#!([^\n]+)")
                 (string-append "#!" #$(file-append bash-minimal "/bin/sh")
                                "\n# Guix, 2026-10-03: use the build-input shell.\n")))
              (substitute* "sys/unix/Makefile.src"
                (("^SHELL=/bin/sh[[:space:]]*$")
                 (string-append
                  "# Guix, 2026-10-03: use the build-input shell.\nSHELL="
                  #$(file-append bash-minimal "/bin/sh") "\n")))
              (substitute* "sys/unix/hints/linux"
                (("^CFLAGS=-g3 -O0.*$")
                 (string-append
                  "# Guix, 2026-10-03: optimized standalone reproducible build.\n"
                  "CFLAGS=-O2 -g0 -I../include -DNOTPARMDECL -fno-common\n"))
                (((string-append
                   "^CFLAGS\\+=-D(SYSCF|HACKDIR|VAR_PLAYGROUND|"
                   "DGAMELAUNCH|LIVELOG_ENABLE|DUMPLOG|DUMPHTML|"
                   "TTY_TILES_ESCCODES|REALTIME_ON_BOTL).*$"))
                 (string-append
                  "# Guix, 2026-10-03: omit host/server/"
                  "optional asset integration.\n"))
                (("^CFLAGS\\+=-DCOMPRESS=.*$")
                 (string-append
                  "# Guix, 2026-10-03: native save compression from an input.\n"
                  "CFLAGS+=-DCOMPRESS=\\\""
                  #$(file-append gzip "/bin/gzip")
                  "\\\" -DCOMPRESS_EXTENSION=\\\".gz\\\"\n"))
                (("^CFLAGS\\+=-DCURSES_GRAPHICS[[:space:]]*$")
                 (string-append
                  "CFLAGS+=-DCURSES_GRAPHICS -DNOMAIL -DNOSHELL "
                  "-DNOUSER_SOUNDS -DREPRODUCIBLE_BUILD "
                  "-DVAR_PLAYGROUND=\\\".\\\"\n"))
                (("^WINSRC \\+= tile.c[[:space:]]*$")
                 "# Guix, 2026-10-03: tty tile assets are not shipped.\n")
                (("^WINOBJ \\+= tile.o[[:space:]]*$")
                 "# Guix, 2026-10-03: tty tile assets are not shipped.\n"))
              (substitute* "include/config.h"
                (("^#define SYSCF[[:space:]].*$")
                 (string-append
                  "/* Guix, 2026-10-03: no global server configuration. */\n"
                  "/* #define SYSCF */\n"))
                (("^#define SYSCF_FILE[[:space:]].*$")
                 "/* #define SYSCF_FILE */\n"))
              (substitute* "include/unixconf.h"
                (("^#define SERVER_ADMIN_MSG[[:space:]].*$")
                 (string-append
                  "/* Guix, 2026-10-03: standalone game, no server messages. */\n"
                  "/* #define SERVER_ADMIN_MSG */\n")))
              ;; Use an original free formatter rather than the inherited
              ;; non-sale/non-modification news macros.  Keep the complete
              ;; source-generated guide, both external and inside nhdat.
              (copy-file
               #$(local-file
                  (search-tay-package-file "patches/evilhack-guide.tmac"))
               "doc/guix-guide.tmac")
              (substitute* "doc/Guidebook.mn"
                (("^\\.so tmac\\.nh.*$")
                 ".\\\" Guix, 2026-10-03: free formatter loaded by Makefile.\n")
                (("^\\.if !.*\\.so doc/tmac\\.nh.*$")
                 ".\\\" Guix, 2026-10-03: no legacy formatter fallback.\n"))
              (substitute* "sys/unix/Makefile.doc"
                (("tmac.n tmac.nh") "guix-guide.tmac")
                (("tbl tmac.n -") "tbl guix-guide.tmac -")
                ;; GNU groff has no 'el' warning category.  Retain -wall and
                ;; fix actual formatter diagnostics rather than hide them.
                ((" -Wel") "")
                ;; Upstream deliberately ignores failures for paginated docs;
                ;; every generated guide is part of this package's closure.
                (("^\t-\\$\\(GUIDECMD\\)") "\t$(GUIDECMD)"))
              (let ((port (open-file "sys/unix/Makefile.doc" "a")))
                (display
                 (string-append
                  "\n# Guix, 2026-10-03: free guide formatter; "
                  "propagate every pipeline failure.\n"
                  "SHELL := " #$(file-append bash-minimal "/bin/bash") "\n"
                  ".SHELLFLAGS := -ec -o pipefail\n")
                 port)
                (close-port port))
              ;; The server-only random target is not needed or installed.
              (substitute* "sys/unix/Makefile.top"
                (("check-dlb serverseed[[:space:]]*$")
                 "check-dlb\n# Guix, 2026-10-03: omit server-only seed generation.\n"))
              (setenv "SOURCE_DATE_EPOCH" "1783867340")
              (setenv "TZ" "UTC0")
              (invoke "sh" "sys/unix/setup.sh" "sys/unix/hints/linux")))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              ;; Do not ship the checked-in Guidebook.txt: regenerate it.
              (delete-file "doc/Guidebook.txt")
              (apply invoke "make" (append '("all") make-flags))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/evilhack"))
                     (doc (string-append #$output "/share/doc/evilhack"))
                     (libexec (string-append #$output "/libexec"))
                     (bin (string-append #$output "/bin"))
                     (real (string-append libexec "/evilhack-real"))
                     (launcher (string-append bin "/evilhack")))
                (for-each mkdir-p (list data doc libexec bin))
                (install-file "src/evilhack" libexec)
                (rename-file (string-append libexec "/evilhack") real)
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhdat" "dat/license" "dat/symbols"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README" "README.md"
                            "doc/Guidebook.txt" "doc/evilhack-changelog.md"
                            "sys/unix/README.linux"
                            "include/isaac64.h" "src/isaac64.c"))
                ;; NGPL 2(a): retain the dated modified source and exact recipe
                ;; alongside the complete upstream license notices.
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/guix-modified-source/" file)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 '("sys/unix/unixmain.c" "sys/unix/setup.sh"
                   "sys/unix/Makefile.src" "sys/unix/Makefile.top"
                   "sys/unix/hints/linux" "include/config.h"
                   "include/unixconf.h" "doc/Guidebook.mn"
                   "sys/unix/Makefile.doc" "doc/guix-guide.tmac"))
                (install-file
                 #$(local-file (search-tay-package-file "evilhack.scm")) doc)
                (call-with-output-file (string-append doc "/guix-notices")
                  (lambda (port)
                    (display
                     (string-append
                      "EvilHack v0.9.3, canonical commit " #$%evilhack-commit "\n"
                      "Canonical source archive: https://github.com/k21971/EvilHack\n"
                      "at the immutable commit above; git-fetch NAR SHA256:\n"
                      "0xrp2djn1mwvxkygkn8q8yjsfn3r6swgfxccvcyzzmxk5560pb5n.\n"
                      "The channel recipe and retained modifications supply "
                      "the complete build instructions.\n"
                      "Guix modifications, 2026-10-03: standalone offline "
                      "tty/curses build;\n"
                      "private native mutable prefixes; no global server "
                      "configuration, mail,\n"
                      "shell escape, HTML dump, or optional font/tile/sound "
                      "assets; fixed\n"
                      "makedefs epoch; declared gzip for native save compression;\n"
                      "no serverseed; source-generated guide and game data.\n"
                      "Modified source files carry dated Guix comments. "
                      "Native gameplay,\n"
                      "frontend and save format are unchanged.\n\n"
                      "Modified source and the complete package recipe "
                      "are retained here.\n"
                      "Rebuild: guix build -L CHANNEL/guix --no-grafts evilhack.\n"
                      "The game code, tty/curses frontend, data, maps, "
                      "symbols and guide are\n"
                      "under the NetHack General Public License "
                      "(LICENSE and data/license).\n"
                      "Bundled ISAAC64: Timothy B. Terriberry; "
                      "CC0/public domain; retain\n"
                      "isaac64.c and isaac64.h notices. "
                      "No opaque binaries are shipped.\n"
                      "Guide formatter is original Guix-channel code "
                      "under Expat; retained source has its full notice.\n"
                      "Runtime libraries/tools are separate Guix inputs "
                      "with their own\n"
                      "notices: ncurses/tinfo (X11); Bash, GNU coreutils and\n"
                      "GNU gzip (GPLv3+);\n"
                      "and the C runtime (LGPLv2.1+ and BSD notices "
                      "in its Guix output).\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port (string-append
                                  "#!~a~%set -eu~%umask 077~%data=~s~%real=~s~%"
                                  "mkdir=~s~%mktemp=~s~%ln=~s~%rm=~s~%"
                                  "realpath=~s~%~%"
                                  "
state=$($realpath -m -- \"${XDG_DATA_HOME:-${HOME:?}/.local/share}/evilhack\")~%
\"$mkdir\" -p \"$state/save\"~%
for file in perm record logfile xlogfile paniclog; do~%
  test -e \"$state/$file\" || : > \"$state/$file\"~%
done~%
playground=$($mktemp -d \"$state/playground.XXXXXX\")~%
cleanup() { \"$rm\" -rf -- \"$playground\"; }~%
trap cleanup EXIT~%
for file in nhdat license symbols; do~%
  \"$ln\" -s \"$data/$file\" \"$playground/$file\"~%
done~%
export HOME=\"$state\" EVILHACK_STATE=\"$state/\"~%
export HACKDIR=\"$playground\" NETHACKDIR=\"$playground\"~%
export TERM=\"${TERM:-xterm-256color}\"~%
cd \"$playground\"~%
\"$real\" \"$@\" <&0 &~%
child=$!~%
stop() { kill -\"$1\" \"$child\" 2>/dev/null || :; wait \"$child\" || :; exit \"$2\"; }~%
trap 'stop HUP 129' HUP~%
trap 'stop INT 130' INT~%
trap 'stop TERM 143' TERM~%
status=0~%
wait \"$child\" || status=$?~%
exit \"$status\"~%")
                            #$(file-append bash-minimal "/bin/sh") data real
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/ln")
                            #$(file-append coreutils-minimal "/bin/rm")
                            #$(file-append coreutils-minimal "/bin/realpath"))))
                (chmod launcher #o555))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex pkg-config groff-minimal))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses/tinfo))
    (home-page "https://github.com/k21971/EvilHack")
    (synopsis "EvilHack terminal dungeon exploration game")
    (description
     "EvilHack is an independently playable NetHack variant with a terminal
interface and additional monsters, items, roles and dungeon branches.  This
package builds its standalone Unix tty and curses interfaces and generates
the game data offline from a fixed upstream release.  The launcher exposes
immutable data through a temporary playground and keeps native saves, scores,
bones, locks, logs and configuration below the user's XDG data directory.
Optional graphical and sound assets are excluded.")
    (license
     (list (license:fsdg-compatible "https://nethack.org/common/license.html")
           license:cc0 license:expat))))
