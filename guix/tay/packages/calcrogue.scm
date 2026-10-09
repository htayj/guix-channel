;;; GNU Guix package for CalcRogue's native curses port.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages calcrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

;; mibic's original banner grants the LGPL without specifying a version, but
;; the archive supplies only GPL text.  Select LGPL 2.1 under its section 13,
;; retain the original banner, and supply these unmodified GNU license terms.
;; The official GCC mirror provides an immutable revision of the document.
(define %calcrogue-lgpl
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/gcc-mirror/gcc/"
          "d0ca130aa5d50cdaeea8e5c343d65250cdf51955/COPYING.LIB"))
    (file-name "calcrogue-COPYING.LGPL-2.1")
    (sha256
     (base32 "0qg8j2is0qxipsi87k5qk4gkny781rh61ws41fc1xpgc2rbdxgd9"))))

(define-public calcrogue
  (package
    (name "calcrogue")
    ;; CHANGELOG identifies Beta 6a SP1; the title still says Beta 6a.
    ;; This is the recovered source release, not a claim that 6c never existed.
    (version "6a-sp1")
    (source
     (origin
       (method url-fetch)
       (uri "https://www.ticalc.org/pub/89/asm/games/rpg/crogue.zip")
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32 "141cjsiky4vfpm45ybk0v2v5k9w9cbvxkbh10qkpsyqd8vaxhf33"))
       (patches
        (list
         (search-tay-package-file "patches/calcrogue-native-state.patch")
         (search-tay-package-file "patches/calcrogue-modern-c.patch")))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Distribution directories contain executables, precompiled game
            ;; data and the nonfree HW3Patch ZIP.  None belongs in this build.
            (for-each delete-file-recursively
                      '("binLinux" "binWin" "binPalm" "binTI89"
                        "binTI92p" "binV200" "src/sys/palm"))
            ;; Regenerate both tools' parser/scanner skeletons from the grammar;
            ;; do not reuse the legacy scanner with no included grant notice.
            (for-each delete-file
                      '("src/tools/mibic/lex.yy.c"
                        "src/tools/mibic/y.tab.c" "src/tools/mibic/y.tab.h"))
            #t))))
    (build-system gnu-build-system)
    ;; Upstream's bytecode compiler, C struct overlays and va_list bridges use
    ;; the i386 ABI.  Build all helpers and the game in that same native ABI
    ;; instead of inventing an incompatible partial LP64 port.
    ;; Build/install explicitly with --system=i686-linux.
    (supported-systems '("i686-linux"))
    (arguments
     (list
      #:tests? #f                 ; Upstream has no check target.
      #:parallel-build? #f       ; Data generation writes automatic.h and tiles.dat.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-native-source
            (lambda* (#:key inputs #:allow-other-keys)
              (chdir "src")
              (substitute* "include/machdep.h"
                (("/usr/bin/gzip")
                 (search-input-file inputs "/bin/gzip"))
                ;; Each user has private cwd state, so use upstream's existing
                ;; nonshared save/score branch rather than getlogin().
                (("#\tdefine SHARED_SCORES")
                 "/* Scores and saves are private to the launcher cwd. */"))
              (substitute* "sys/curses/main.c"
                (("@CALCROGUE_DATA_FILE@")
                 (string-append #$output "/share/calcrogue/crogdat.dat")))
              ;; These outputs must be regenerated from the macro data, not
              ;; accidentally inherited from the source distribution.
              (for-each delete-file '("auto/automatic.h" "auto/tiles.dat"))))
          (replace 'configure
            (lambda _
              ;; This is a custom configure script, not GNU configure.  It
              ;; defaults to the Windows-named computer target even on Unix.
              (invoke "make" "-C" "tools/sgt"
                      #$(string-append "CXX=" (cxx-for-target)))
              (invoke "sh" "configure")
              (substitute* "auto/configure.mk"
                (("PC_CC_OPTS[ \t]*:=[^\n]*")
                 "PC_CC_OPTS := -DTARGET=T_UNIX -Wall -std=gnu89")
                (("PC_CC_OPTS_TOOL[ \t]*:=[^\n]*")
                 "PC_CC_OPTS_TOOL := -Wall -std=gnu89")
                (("PC_CC_LIBS[ \t]*:=[^\n]*")
                 "PC_CC_LIBS := -lncurses"))
              (mkdir-p "../binLinux")))
          (replace 'build
            (lambda _
              ;; Explicit yacc mode regenerates y.tab.c and y.tab.h.  The data
              ;; compiler and fixedmap are built from source before macro data
              ;; is compiled, and only then are game objects compiled.
              (invoke "make" "-C" "tools/mibic"
                      #$(string-append "CC=" (cc-for-target))
                      "LEX=flex" "YACC=bison -y"
                      "CCOPTS=-Wall -O2 -std=gnu89")
              (invoke "make" "../binLinux/crogdat.dat" "BUILD_VERBOSE=1")
              (invoke "make" "linux" "BUILD_VERBOSE=1")))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (private (string-append #$output "/libexec/calcrogue"))
                     (data (string-append #$output "/share/calcrogue"))
                     (doc (string-append #$output "/share/doc/calcrogue"))
                     (launcher (string-append bin "/calcrogue")))
                (mkdir-p private)
                (copy-file "../binLinux/crogue"
                           (string-append private "/calcrogue"))
                (chmod (string-append private "/calcrogue") #o555)
                (install-file "../binLinux/crogdat.dat" data)
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "README" "CHANGELOG" "../readme.txt"))
                (copy-file #$%calcrogue-lgpl
                           (string-append doc "/COPYING.LGPL-2.1"))
                (install-file "tools/sgt/COPYING"
                              (string-append doc "/sgt"))
                ;; The exact source grant is not replaced by license metadata.
                (install-file "tools/mibic/src/main.c"
                              (string-append doc "/mibic"))
                (install-file "src/crogue.c" doc)
                (call-with-output-file (string-append doc "/SOURCE")
                  (lambda (port)
                    (display
                     (string-append
                      "CalcRogue Beta 6a SP1, recovered ticalc.org archive.\n"
                      "Archive SHA256: "
                      "6338d8d5460d7b7d270601aed9f76289"
                      "a759b6d8602e5f48bd6e133fa3962c90\n"
                      "Game and data: GPL 2 or later (see crogue.c).\n"
                      "mibic: unversioned LGPL banner in mibic/main.c.\n"
                      "LGPL 2.1 selected under section 13, not author-stated.\n"
                      "GNU LGPL terms from GCC mirror revision:\n"
                      "d0ca130aa5d50cdaeea8e5c343d65250cdf51955.\n"
                      "Native i686 preserves the upstream 32-bit VM/C ABI.\n"
                      "Build: guix build -L guix -s i686-linux calcrogue\n"
                      "Modifications, 2026-10-09: immutable data separated\n"
                      "from private cwd saves/scores; compressed cleanup,\n"
                      "absent-save detection; shell-free store gzip;\n"
                      "replace obsolete cast-lvalue pointer increment.\n"
                      "Flex/Bison outputs and game data rebuilt from source.\n"
                      "All bin* and Palm font sources excluded.\n"
                      "Historical latest-release status is not established.\n")
                     port)))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\numask 077\n"
                            #$(file-append bash-minimal "/bin/bash"))
                    (display
                     (string-append
                      "state=${XDG_STATE_HOME:-${HOME:?'HOME or "
                      "XDG_STATE_HOME must be set'}/.local/state}/calcrogue\n")
                     port)
                    (format port "~a -p -- \"$state\"\n"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display "cd -- \"$state\"\n" port)
                    (format port "export TERMINFO_DIRS=~a\n"
                            #$(file-append ncurses "/share/terminfo"))
                    (format port "exec ~a \"$@\"\n"
                            (string-append private "/calcrogue"))))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip m4 flex bison which))
    (inputs (list ncurses gzip bash-minimal coreutils-minimal))
    (home-page "https://www.ticalc.org/archives/files/fileinfo/260/26014.html")
    (synopsis "Native terminal port of a calculator roguelike")
    (description
     "CalcRogue is a turn-based dungeon exploration game originally written
for calculators, PDAs and computers.  This package builds the recovered Beta
6a SP1 source and its generated game data for the ordinary Linux curses
frontend.  The launcher keeps native saves, saved levels, options and high
scores in @file{$XDG_STATE_HOME/calcrogue}, falling back to
@file{$HOME/.local/state/calcrogue}; game data remains immutable in the store.
It does not include the calculator binaries, HW3Patch or Palm font sources.")
    (license (list license:gpl2+ license:lgpl2.1))))
