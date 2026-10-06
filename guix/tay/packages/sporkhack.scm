;;; GNU Guix package for the silent native Unix SporkHack terminal game.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages sporkhack)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

(define %sporkhack-commit
  "4ed114fc29b9d03f9b2857c730afd9563513ddad")

(define %sporkhack-state-patch
  (search-tay-package-file "patches/sporkhack-private-state.patch"))

(define-public sporkhack
  (package
    (name "sporkhack")
    (version "0.7.0-0.4ed114f")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/k21971/SporkHack/tar.gz/"
             %sporkhack-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256 of the exact codeload archive, fetched 2026-10-06:
       ;; 26ff9a80a8309f3c471506e5c9bdf2688dfd9ced48cebca1ea483ee7f88cc79a.
       (sha256
        (base32 "16n7ikwffgj8xahvrkj8xnfgv3b8yaywkr862m3kr7rhm209mzr6"))
       (patches (list %sporkhack-state-patch))
       (patch-flags '("-p1" "--fuzz=0"))
       (modules '((guix build utils) (ice-9 ftw) (srfi srfi-1)))
       ;; Filter the SOURCE, not just the installation.  The Roland AIFF
       ;; samples have no redistribution grant (their README speculates that
       ;; lack of a copyright mark suffices).  The Macintosh NHsound.hqx and
       ;; all other unused ports/tiles/binary resources are outside this native
       ;; Unix closure.  Regenerate lex/yacc sources from their original input
       ;; instead of retaining historical generated skeletons.
       (snippet
        #~(begin
            (define (select-directory directory names)
              (for-each
               (lambda (name)
                 (unless (member name names)
                   (delete-file-recursively
                    (string-append directory "/" name))))
               (scandir directory
                        (lambda (name) (not (member name '("." "..")))))))
            (select-directory
             "." '("README" "README.new_lev_comp" "README.statuscolors"
                   "Files" "Porting" "dat" "doc" "include" "src" "util"
                   "sys" "win"))
            (select-directory "sys" '("unix" "share"))
            (select-directory
             "sys/unix" '("Install.unx" "Makefile.dat" "Makefile.doc"
                          "Makefile.src" "Makefile.top" "Makefile.utl"
                          "README.linux" "setup.sh" "unixmain.c"
                          "unixres.c" "unixunix.c"))
            ;; tmac.n prohibits sale and redistribution of modifications.
            ;; Use the shipped plain-text guide; do not retain this macro.
            (delete-file "doc/tmac.n")
            ;; Unused graphics payload/header imports are not in HACKINCL
            ;; or the native compiler closure.  In particular bitmfile.h has
            ;; a MAXON copyright but no redistribution grant.
            (for-each delete-file
                      '("include/bitmfile.h" "include/gem_rsc.h"
                        "include/load_img.h" "include/qt_xpms.h"))
            (select-directory "win" '("tty" "curses"))
            (select-directory "sys/share" '("ioctl.c" "unixtty.c" "sounds"))
            (select-directory "sys/share/sounds" '("README"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; makedefs, its generated headers, and the level/data tools have
      ;; interdependent make rules.  Keep this historical build serialized.
      #:parallel-build? #f
      ;; No upstream non-interactive check target exists.  Native gameplay and
      ;; two-process save/restore are exercised by tests/sporkhack-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              "CFLAGS=-O2 -g -std=gnu89 -fcommon -D_DEFAULT_SOURCE -I../include"
              "LFLAGS=" "LEX=flex" "YACC=bison -y"
              "WINTTYLIB=-lncurses -ltinfo"
              "VCS_DESCRIPTION=git 4ed114fc29b9d03f9b2857c730afd9563513ddad")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-native-build
            (lambda _
              (use-modules (ice-9 textual-ports))
              ;; NGPL paragraph 2(a): modifications retain the original
              ;; notices and prominently identify the downstream/date.
              (for-each
               (lambda (file)
                 (let ((original (call-with-input-file file get-string-all)))
                   (call-with-output-file file
                     (lambda (port)
                       (display
                        (string-append
                         "/* Modified by the tay Guix channel, 2026-10-06:\n"
                         " * immutable data, internal compression, reproducible"
                         " native Unix build.\n"
                         " * Distributed under the NetHack General Public"
                         " License. */\n")
                        port)
                       (display original port)))))
               '("include/config.h" "util/makedefs.c"))
              (substitute* "include/config.h"
                (("#  define HACKDIR \"/sporkhack-0\\.7\\.0/var\"")
                 (string-append "#  define HACKDIR \"" #$output
                                "/share/sporkhack\""))
                (("#define COMPRESS \"/bin/gzip\"")
                 "/* External compressor disabled; use INTERNAL_COMP. */")
                (("#define COMPRESS_EXTENSION \"\\.gz\"")
                 "/* No external compressor filename extension. */"))
              ;; Neither tty nor curses defines USER_SOUNDS at this pin;
              ;; Qt is excluded.  Do not invent an external playback backend.
              (substitute* "util/makedefs.c"
                (("\\(void\\) time\\(&clocktim\\);")
                 "clocktim = 1657243108L;")
                (("\\(void\\) time\\(\\(time_t \\*\\)&clocktim\\);")
                 "clocktim = 1657243108L;"))
              (let ((original
                     (call-with-input-file "sys/unix/Makefile.top"
                       get-string-all)))
                (call-with-output-file "sys/unix/Makefile.top"
                  (lambda (port)
                    (display
                     (string-append
                      "# Modified by the tay Guix channel, 2026-10-06:"
                      " pinned version, plain-text guide.\n")
                     port)
                    (display original port))))
              (substitute* "sys/unix/Makefile.top"
                (((string-append "export VCS_DESCRIPTION = git "
                                 "\\$\\(shell git rev-parse --short HEAD\\)"))
                 (string-append "export VCS_DESCRIPTION = git "
                                #$%sporkhack-commit))
                (("all:[[:blank:]]+\\$\\(GAME\\) recover Guidebook")
                 "all: $(GAME) recover"))
              (setenv "TZ" "UTC0")
              (invoke "sh" "sys/unix/setup.sh")
              ;; Snapshot the complete selected, patched source before any
              ;; compilation.  Accompany executable distribution with it:
              ;; NGPL 3(a), not a noncommercial-only source-URL alternative.
              (mkdir-p "source-for-distribution")
              (for-each
               (lambda (file)
                 (copy-recursively
                  file (string-append "source-for-distribution/" file)))
               '("README" "README.new_lev_comp" "README.statuscolors"
                 "Files" "Porting" "Makefile" "dat" "doc" "include"
                 "src" "util" "sys" "win"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "all" make-flags)))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/sporkhack"))
                     (doc (string-append #$output "/share/doc/sporkhack"))
                     (bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (real (string-append libexec "/sporkhack-real"))
                     (launcher (string-append bin "/sporkhack")))
                (for-each mkdir-p (list data doc bin libexec))
                (copy-file "src/sporkhack" real)
                (chmod real #o755)
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhdat" "dat/license"))
                (for-each (lambda (file) (install-file file doc))
                          '("README" "README.new_lev_comp" "README.statuscolors"
                            "doc/Guidebook.txt" "sys/unix/README.linux"
                            "dat/license"))
                (copy-file "sys/share/sounds/README"
                           (string-append doc "/sounds-README"))
                (copy-recursively "source-for-distribution"
                                  (string-append doc "/source"))
                (install-file
                 #$(local-file (search-tay-package-file "sporkhack.scm")) doc)
                (install-file #$(local-file %sporkhack-state-patch) doc)
                (call-with-output-file (string-append doc "/SOURCE")
                  (lambda (port)
                    (display
                     (string-append
                      "SporkHack revision " #$%sporkhack-commit "\n"
                      "https://github.com/k21971/SporkHack\n"
                      "NetHack General Public License: see license.\n"
                      "Complete selected patched source accompanies the\n"
                      "executable in source/ (NGPL paragraph 3(a)); original\n"
                      "notices are retained.\n"
                      "Downstream changes, 2026-10-06: native Unix build,\n"
                      "reproducible makedefs timestamp, native internal\n"
                      "compression, and private state.\n"
                      "Unused ports, tiles, encoded samples and binary\n"
                      "resources are excluded from the source origin.  No\n"
                      "audio backend is built.\n"
                      "Source-rights audit, 2026-10-06: 314 selected upstream\n"
                      "files.  Counts: root 5, dat 39, doc 30, include 90,\n"
                      "src 107, util 10, sys/unix 11, sys/share 3 (including\n"
                      "sounds/README), tty 4, curses 15.\n"
                      "README paragraphs 2-4 describe the source distribution\n"
                      "and direct recipients to dat/license.  Its NGPL\n"
                      "paragraph 2(b) covers derivatives; source, header, map\n"
                      "and text files stay under that repository-wide grant.\n"
                      "Missing repetition of the grant in a file is not a\n"
                      "different license.\n"
                      "The imported RNG in src/rnd.c lines 129-131 expressly\n"
                      "identifies the LibTomCrypt code as public domain; that\n"
                      "notice is retained.\n"
                      "The encyclopedia dat/data.base retains its NGPL header\n"
                      "and literary source attributions; no contrary license\n"
                      "notice was identified.\n"
                      "Excluded: all unused ports/graphics,\n"
                      "sys/share/sounds/*.uu, sys/mac/NHsound.hqx, unused\n"
                      "portable encoded/generated files, sys/unix/cpp*.shr\n"
                      "and snd86unx.shr; doc/tmac.n forbids sale and\n"
                      "distribution of changes; unused include/bitmfile.h\n"
                      "has a MAXON copyright with no grant.  Unused GEM/Qt\n"
                      "graphics headers\n"
                      "gem_rsc.h, load_img.h and qt_xpms.h are also excluded.\n"
                      "Rebuild with the accompanying sporkhack.scm and state\n"
                      "patch:\n"
                      "guix build -L guix sporkhack\n"
                      "Filtered source: guix build -L guix --source sporkhack\n"
                      "Launcher state:\n"
                      "${XDG_STATE_HOME:-$HOME/.local/state}/sporkhack\n"
                      "Native configuration: ~/.sporkrc (fallback\n"
                      "~/.nethackrc), or NETHACKOPTIONS; both tty and curses\n"
                      "window systems exist.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%"
                            #$(file-append bash-minimal "/bin/sh"))
                    (format port "data=~s~%real=~s~%mkdir=~s~%"
                            data real
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display
                     (string-append
                      "state=\"${XDG_STATE_HOME:-${HOME:?}/.local/state}"
                      "/sporkhack\"\n"
                      "case \"$state\" in /*) ;; *) echo 'sporkhack:"
                      " XDG_STATE_HOME must be absolute' >&2; exit 1 ;;"
                      " esac\n"
                      "\"$mkdir\" -p \"$state/save\" \"$state/dumplog\"\n"
                      "for file in perm record logfile xlogfile livelog"
                      " wishtracker paniclog; do\n"
                      "  test -e \"$state/$file\" || : > \"$state/$file\"\n"
                      "done\n"
                      "export HACKDIR=\"$data\" NETHACKDIR=\"$data\"\n"
                      "export SPORKHACK_VAR_PLAYGROUND=\"$state/\"\n"
                      "export TERM=\"${TERM:-xterm-256color}\"\n"
                      "exec \"$real\" \"$@\"\n")
                     port)))
                (chmod launcher #o755))))
          ;; Do this only after generated files and store shebangs are final.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex))
    (inputs (list bash-minimal coreutils-minimal ncurses/tinfo))
    (home-page "https://github.com/k21971/SporkHack")
    (synopsis "Terminal dungeon exploration variant of NetHack")
    (description
     "SporkHack is a NetHack variant with additional monsters, objects and
 dungeon levels.  This package builds the native Unix tty and curses interfaces
 from a fixed source revision and generates the dungeon data locally.  It is
 silent: no sound samples or external audio playback backend are included.
 Immutable game data is kept in the store, while saves, bones, scores, locks,
 live logs, and dumps use private per-user XDG state.  The executable is
 accompanied by the complete selected, patched source and its license notices.")
    ;; dat/license supplies NGPL terms; per-file contribution provenance is
    ;; recorded in the package's source/ tree, not replaced by this metadata.
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
