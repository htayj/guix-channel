(define-module (tay packages unnethack)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

(define-public unnethack
  (package
    (name "unnethack")
    (version "6.0.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/UnNetHack/UnNetHack")
             (commit "1f061e93b44d93e509f35dbfa3c853f758712558")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1s08lc1jjv4nyrj4dg0d4rrlg84m6v46dw8xca6gz0sp636pdvqb"))
       (modules '((guix build utils)))
       ;; These are Windows/tiled-port resources, not used by the native TTY
       ;; port.  Attribution alone is not a per-file redistribution grant.
       (snippet
        #~(begin
            (copy-file "tilesets/README" "TILESET-ATTRIBUTIONS")
            (delete-file-recursively "tilesets")
            (for-each delete-file (find-files "dat" "\\.ttf$"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f ; Generated headers and level compilers share targets.
      #:configure-flags
      #~(list "--enable-tty-graphics"
              "--disable-dummy-graphics"
              "--with-owner=no" "--with-group=no"
              "--with-compression=no" ; Retain native internal compression.
              "--with-gamesdir=." "--with-bonesdir=bones"
              (string-append "--docdir=" #$output "/share/doc")
              "--with-savesdir=saves" "--with-leveldir=level"
              (string-append "--with-sharedir=" #$output "/share/unnethack")
              (string-append "--with-unsharedir=" #$output "/share/unnethack")
              "--enable-dump-file=dumps/%n.nh")
      #:make-flags #~(list "GAMEPERM=0755")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-source-and-notices
            (lambda _
              ;; Keep source and every original notice for the TTY build,
              ;; before applying the dated, documented build-only change.
              (mkdir-p "tty-source")
              (for-each
               (lambda (directory)
                 (copy-recursively directory
                                   (string-append "tty-source/" directory)))
               '("src" "include" "util" "dat" "doc" "tests"))
              (for-each
               (lambda (directory)
                 (copy-recursively directory
                                   (string-append "tty-source/" directory)))
               '("sys/unix" "sys/autoconf" "win/tty" "win/share"))
              (mkdir-p "tty-source/sys/share")
              (for-each
               (lambda (file)
                 (install-file file "tty-source/sys/share"))
               (find-files "sys/share" "\\.(c|h)$"))
              (mkdir-p "tty-source/sys/winnt")
              (copy-file "sys/winnt/win32api.h"
                         "tty-source/sys/winnt/win32api.h")
              (for-each
               (lambda (file)
                 (copy-file file (string-append "tty-source/" file)))
               '("configure" "README" "README.configure" "ChangeLog" "Porting"))
              ;; Configure's col probe needs the util-linux:out executable.
              ;; SOURCE_DATE_EPOCH is honored natively by util/makedefs.c.
              (setenv "SOURCE_DATE_EPOCH" "1643846400")
              (setenv "TZ" "UTC")
              ;; tests/Makefile otherwise uses make's built-in CC=cc, which
              ;; is absent in Guix.  Environment inheritance fixes that without
              ;; overriding src/Makefile's required -DAUTOCONF compiler flag.
              (setenv "CC" "gcc")
              ;; The upstream Unix sources use pre-C23 K&R definitions.
              (setenv "CFLAGS" "-O2 -g -std=gnu11")
              ;; The 6.0.4 header overrides compiler-owned attribute names.
              ;; This breaks glibc's __has_attribute query, and suppresses
              ;; genuine diagnostics.  Restore their native compiler meaning.
              (substitute* "include/tradstdc.h"
                (((string-append
                  "/\\* disable gcc's __attribute__\\(\\("
                  "__warn_unused_result__\\)\\) since explicitly"))
                 (string-append
                  "/* Modified by tay Guix channel, 2026-10-02: preserve "
                  "compiler attributes. */\n"
                  "/* Historically, explicitly"))
                (("^#define (__warn_unused_result__|warn_unused_result) /\\*empty\\*/")
                 ""))
              (substitute* "tests/Makefile"
                (("^all:")
                 (string-append
                  "# Modified by tay Guix channel, 2026-10-02: add Check "
                  "header flags.\n"
                  "all:")))
              ;; Check is not guaranteed to install headers in GCC's default
              ;; search path.  Preserve all five upstream C test executables.
              (substitute* "tests/Makefile"
                (("`pkg-config --libs check`")
                 "`pkg-config --cflags --libs check`"))
              (call-with-output-file "TTY-SOURCE-NOTICE"
                (lambda (port)
                  (display
                   (string-append
                    "UnNetHack 6.0.4 native TTY package\n"
                    "\n"
                    "Source: https://github.com/UnNetHack/UnNetHack\n"
                    "Commit: 1f061e93b44d93e509f35dbfa3c853f758712558\n"
                    "\n"
                    "2026-10-02: the Guix package adds pkg-config header "
                    "flags to\n"
                    "tests/Makefile.  All upstream C tests remain enabled. "
                    " Header\n"
                    "compatibility changes are documented below.  Native "
                    "internal\n"
                    "compression, generated levels, all game rules, "
                    "UTF-8/color TTY\n"
                    "rendering, help, recovery, Guidebook, and dump "
                    "support remain available.\n"
                    "\n"
                    "Mutable file areas are configured relative to the "
                    "private user\n"
                    "playground; read-only game data and documentation use "
                    "store paths.\n"
                    "The launcher creates "
                    "${XDG_DATA_HOME:-$HOME/.local/share}/unnethack,\n"
                    "with saves/, bones/, level/, and dumps/ below it.  It "
                    "never installs\n"
                    "setuid/setgid files or changes ownership.  The "
                    "default configuration\n"
                    "remains editable at ~/.unnethackrc or via "
                    "NETHACKOPTIONS.\n"
                    "\n"
                    "NGPL covers the game and its native data, including "
                    "level descriptions,\n"
                    "data.base, rumors, quest text, oracles, help and "
                    "configuration.  Original\n"
                    "source notices are retained in tty-source/.  "
                    "dat/license is installed\n"
                    "verbatim.  debian-copyright preserves the upstream "
                    "BSD-3-clause\n"
                    "lisp-window notice (Shawn Betts and Ryan Yeske, "
                    "2001); this package does\n"
                    "not compile that optional port.  Its Benjamin Rubin "
                    "copyright line\n"
                    "contains no GPL grant, and is not represented as one. "
                    " Build-tool\n"
                    "GPL notices and exceptions remain in the "
                    "corresponding source files.\n"
                    "\n"
                    "Unlicensed-per-file optional resources are not "
                    "shipped: tilesets/\n"
                    "untiles32x.png (Stephan T. Lavavej, based on Vanilla "
                    "tiles),\n"
                    "unchozo32b.png (James Hogwood, Kelly Bailey, Patric "
                    "Mueller),\n"
                    "unh16.bmp and unh32.bmp (no individual attribution in "
                    "tilesets/README),\n"
                    "and dat/DejaVuSansCondensed.ttf and "
                    "DejaVuSansMono.ttf (no accompanying\n"
                    "font license at this pin).  The exact upstream "
                    "tilesets/README is\n"
                    "recorded separately.  These files are neither "
                    "consumed by the native\n"
                    "TTY build nor required for any TTY feature.  No "
                    "graphical-port claim\n"
                    "is made.  tty-source/ contains the corresponding "
                    "native build source,\n"
                    "not an archive of excluded or unsupported graphical "
                    "assets.\n")
                   port)
                  (display
                   (string-append
                    "\n"
                    "The default upstream make check runs all five C "
                    "suites (base32,\n"
                    "hacklib, options, unicode, wishing).  The separate "
                    "legacy Ruby\n"
                    "spec/rake task requires RSpec 1 and windowtype:dummy; "
                    "it is not a\n"
                    "native-TTY test and is not part of the upstream make "
                    "check target.\n"
                    "The standalone three-process PTY scenario verifies "
                    "actual gameplay\n"
                    "and exact native save/restore continuity without that "
                    "test port.\n")
                   port)
                  (display
                   (string-append
                    "\n"
                    "2026-10-02: include/tradstdc.h no longer defines "
                    "empty macros for\n"
                    "compiler-owned "
                    "__warn_unused_result__/warn_unused_result "
                    "attributes.\n"
                    "Those two legacy suppressions caused glibc "
                    "__has_attribute expansion\n"
                    "to fail; native compiler diagnostics and attributes "
                    "are now preserved.\n"
                    "All other game source remains unchanged.\n")
                   port)
                  (display
                   (string-append
                    "\n"
                    "Build uses the upstream-compatible GNU C11 dialect, "
                    "UTC, and a fixed\n"
                    "SOURCE_DATE_EPOCH (1643846400), which makedefs honors "
                    "natively.  The\n"
                    "launcher refuses playground paths longer than the "
                    "game's native\n"
                    "128-byte environment limit instead of falling back to "
                    "the store.\n"
                    "Native PTY acceptance is standalone in the channel "
                    "tests; no dummy\n"
                    "frontend, test interpreter, or smoke command is "
                    "installed.\n")
                   port)))))
          ;; The first/default target only builds the game executable.  The
          ;; actual all target also builds recovery, Guidebook, every level,
          ;; data/oracles/rumors/quest/options and the nhdat librarian archive.
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "all" make-flags)))
          (replace 'install
            (lambda _
              ;; Do not invoke upstream's install: its mutable file areas are
              ;; intentionally relative and would install state into the build.
              (let ((data (string-append #$output "/share/unnethack"))
                    (doc (string-append #$output "/share/doc/unnethack"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p bin)
                (for-each (lambda (file) (install-file file data))
                          '("src/unnethack" "util/recover" "dat/nhdat"
                            "dat/unnethack_dump.css"))
                (copy-file "sys/unix/defaults.nh"
                           (string-append data "/unnethackrc.default"))
                (chmod (string-append data "/unnethack") #o755)
                (chmod (string-append data "/recover") #o755)
                (for-each (lambda (file) (install-file file doc))
                          '("dat/license" "dat/help" "dat/hh" "dat/cmdhelp"
                            "dat/history" "dat/opthelp" "dat/wizhelp"
                            "README" "README.configure"
                            "ChangeLog" "TTY-SOURCE-NOTICE"
                            "TILESET-ATTRIBUTIONS"))
                (copy-file "doc/Guidebook" (string-append doc "/Guidebook.txt"))
                (install-file "dat/sysconf" doc)
                (copy-file "debian/copyright"
                           (string-append doc "/debian-copyright"))
                ;; Retain attribution without redistributing unclear images.
                (copy-file "tty-source/sys/autoconf/Makefile.top"
                           (string-append doc "/upstream-Makefile.top"))
                (copy-recursively "tty-source" (string-append doc "/tty-source"))
                (mkdir-p (string-append #$output "/share/man/man6"))
                (copy-file "doc/nethack.6"
                           (string-append #$output "/share/man/man6/unnethack.6"))
                (copy-file "doc/recover.6"
                           (string-append #$output "/share/man/man6/unnethack-recover.6"))
                (call-with-output-file (string-append bin "/unnethack")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/bash\n"
                             "set -eu\n"
                             "umask 077\n"
                             "base=${XDG_DATA_HOME:-${HOME:?HOME is "
                             "unset}/.local/share}\n"
                             "case $base in /*) ;; *) echo 'unnethack: "
                             "XDG_DATA_HOME must be absolute' >&2; exit 1;; esac\n"
                             "state=$base/unnethack\n"
                             "bytes=$(LC_ALL=C printf '%s' \"$state\" | ~a/bin/wc "
                             "-c)\n"
                             "if [ \"$bytes\" -gt 128 ]; then echo 'unnethack: "
                             "playground path exceeds native 128-byte limit' >&2; "
                             "exit 1; fi\n"
                             "~a/bin/mkdir -p -- \"$state\" \"$state/saves\" "
                             "\"$state/bones\" \"$state/level\" \"$state/dumps\"\n"
                             "for file in perm record logfile xlogfile; do\n"
                             "  if [ ! -e \"$state/$file\" ]; then : > "
                             "\"$state/$file\"; fi\n"
                             "done\n"
                             "export NETHACKDIR=\"$state\"\n"
                             "unset HACKDIR\n"
                             "exec ~a/share/unnethack/unnethack \"$@\"\n")
                            #$bash-minimal #$coreutils-minimal
                            #$coreutils-minimal
                            #$output)))
                (chmod (string-append bin "/unnethack") #o755))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex pkg-config check groff util-linux))
    (inputs (list ncurses coreutils-minimal))
    (home-page "https://unnethack.wordpress.com/")
    (synopsis "NetHack variant with additional levels and challenges")
    (description
     "UnNetHack extends NetHack with additional levels, monsters, objects and
randomness.  This package provides its original native terminal interface,
including UTF-8 glyphs and color, and preserves the game's data, help and
recovery utility.  Saves, bones, levels, scores and dumps live in the user's
XDG data directory, without privileged installation or writes to the store.")
    (license
     (license:fsdg-compatible "https://nethack.org/common/license.html"))))
