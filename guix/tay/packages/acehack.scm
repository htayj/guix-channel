;;; GNU Guix package for the historical AceHack tty roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages acehack)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

;; AceHack has no release tags.  This is the final master tip of the public
;; git mirror, dated 2015-03-11.
(define %acehack-commit
  "9a4c7671a8d8de6c0a7ab4718382b49cf5ec61f5")

(define %acehack-version
  "3.6.0-0.9a4c767")

(define-public acehack
  (package
    (name "acehack")
    (version %acehack-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/deepy/acehack")
             (commit %acehack-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "19avxbxhwl7wy3j6g1h41d0d37rhhq45j8z71zfdbynfrv1cbg78"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The generated maps and yacc/lex products have ordering dependencies.
      #:parallel-build? #f
      ;; AceHack has no non-interactive upstream check target.  The installed
      ;; tty game is exercised by tests/acehack-smoke.sh.
      #:tests? #f
      #:configure-flags
      #~(list "--with-compression=no"
              "--enable-tty-graphics"
              "--disable-x11-graphics"
              "--disable-sdl-graphics"
              "--disable-gl-graphics"
              "--disable-mswin-graphics")
      #:make-flags
      ;; The configure template finds ncurses separately, but this old source
      ;; Makefile drops LIBS.  Supply tinfo explicitly at the final link too.
      #~(list "LIBS=-lm -ltinfo")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'make-store-safe
            (lambda _
              (use-modules (ice-9 textual-ports))
              ;; NGPL 2(a): each changed file must carry its own prominent,
              ;; dated notice, without replacing the upstream notices.
              (for-each
               (lambda (file)
                 (let ((original (call-with-input-file file get-string-all)))
                   (call-with-output-file file
                     (lambda (port)
                       (display
                        (string-append
                         "/* Modified by the tay Guix channel, 2026-10-07:\n"
                         " * store-safe tty build, mail/shell disabled, "
                         "ncurses compatibility,\n"
                         " * and reproducible build date.  See "
                         "share/doc/acehack/SOURCE.\n"
                         " * Distributed under the NetHack General Public "
                         "License. */\n")
                        port)
                       (display original port)))))
               '("include/config.h" "include/unixconf.h" "src/objects.c"
                 "win/tty/termcap.c" "util/makedefs.c"))
              ;; Standard Guix phases also patch source script interpreters
              ;; and refresh config.guess/sub; identify these downstream files.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("^#!.*$")
                    (string-append
                     "#!" #$(file-append bash-minimal "/bin/sh") "\n"
                     "# Modified by the tay Guix channel, 2026-10-07: "
                     "Guix build interpreter and configuration helpers.\n"))))
               '("configure" "sys/autoconf/config.guess"
                 "sys/autoconf/config.sub" "sys/autoconf/install-sh"
                 "sys/autoconf/bootstrap.sh"))
              ;; The original shell launcher hard-codes /usr/games and the
              ;; game changes into a compiled-in HACKDIR.  The Guix launcher
              ;; below instead owns the temporary playground.
              (substitute* "include/config.h"
                (("^# define CHDIR.*$") "/* # define CHDIR */"))
              ;; Do not permit a shell escape or access to a host mailbox.
              ;; Keep the mail scroll in the object table so that SCR_MAIL
              ;; retains its historical index even without the MAIL feature.
              (substitute* "include/unixconf.h"
                (("^#define SHELL.*$") "/* #define SHELL */")
                (("^#define MAIL.*$") "/* #define MAIL */"))
              (substitute* "src/objects.c"
                (("#ifdef MAIL") "#if 1"))
              ;; ncurses 6 already declares tparm with a varargs prototype.
              (substitute* "win/tty/termcap.c"
                (("extern char .+tparm.+") ""))
              ;; These are configure's documented no-op ownership helpers.
              (setenv "CHOWN" "true")
              (setenv "CHGRP" "true")
              (setenv "CHMOD" "true")
              ;; makedefs embeds this date in date.h, which is compiled into
              ;; both the executable and nhdat.  The fixed source revision
              ;; supplies the reproducible build timestamp below.
              (setenv "TZ" "UTC0")
              ;; This 2015 source retains K&R definitions which GCC's modern
              ;; default language mode rejects as errors.
              (setenv "CFLAGS"
                      (string-append (or (getenv "CFLAGS") "") " -std=gnu89"))
              (setenv "LIBS" "-ltinfo")))
          (add-before 'build 'make-build-date-reproducible
            (lambda _
              ;; The final master commit was made at 2015-03-11 12:27:57 UTC.
              ;; Do not let makedefs use the build machine's wall clock.
              (substitute* "util/makedefs.c"
                ;; Configuring this historical source defines KR1ED, whereas
                ;; other ports use the time_t branch below.  Patch both so a
                ;; future supported port cannot reintroduce a wall-clock
                ;; timestamp into date.h, nhdat, or the executable.
                (("\\(void\\) time\\(&clocktim\\);")
                 "clocktim = 1426076877L;")
                (("\\(void\\) time\\(\\(time_t \\*\\)&clocktim\\);")
                 "clocktim = 1426076877L;"))))
          (add-after 'configure 'fix-internal-compression-build
            (lambda _
              ;; This version's --with-compression=no branch correctly uses
              ;; INTERNAL_COMP, but verify_savefile still references the
              ;; optional extension macro.  An empty extension preserves the
              ;; no-external-compressor behavior while repairing that build
              ;; omission.
              (substitute* "include/autoconf.h"
                (("#undef COMPRESS_EXTENSION")
                 "#define COMPRESS_EXTENSION \"\""))
              (substitute* "include/autoconf.h"
                (("^#ifndef AUTOCONF_H")
                 (string-append
                  "/* Modified by the tay Guix channel, 2026-10-07: "
                  "empty extension for native internal compression. */\n"
                  "#ifndef AUTOCONF_H")))))
          (replace 'build
            (lambda _
              ;; NGPL 3(a): retain every source and build template used to
              ;; create the executable and nhdat, before adding binaries.
              (mkdir-p "source-for-distribution")
              (for-each
               (lambda (file)
                 (copy-recursively
                  file (string-append "source-for-distribution/" file)))
               '("configure" "README" "Files" "Porting" "Makefile"
                 "src" "include" "util" "dat" "doc" "sys/autoconf"
                 "win/tty"))
              (for-each
               (lambda (file)
                 (let ((target (string-append "source-for-distribution/" file)))
                   (mkdir-p (dirname target))
                   (copy-file file target)))
               '("sys/share/ioctl.c" "sys/share/unixtty.c"
                 "sys/unix/unixmain.c" "sys/unix/unixunix.c"
                 "sys/unix/unixres.c" "sys/unix/Install.unx"
                 "sys/unix/README.linux" "sys/winnt/win32api.h"))
              ;; Graphics-only headers are not used by the tty build;
              ;; bitmfile.h carries a MAXON copyright without a grant.
              ;; tmac.n has noncommercial/no-modification-distribution terms,
              ;; and is not executable/data source under NGPL lines 77-79.
              ;; Retain full Guidebook text, not this restricted formatter.
              (for-each
               (lambda (file)
                 (delete-file (string-append "source-for-distribution/" file)))
               '("include/bitmfile.h" "include/gem_rsc.h"
                 "include/load_img.h" "include/qt_xpms.h" "doc/tmac.n"))
              ;; The generated top-level Makefile's default target is the
              ;; executable; the documented `all' target also creates nhdat.
              ;; The installer additionally expects Guidebook.txt.
              (invoke "make" "all" "Guidebook.txt" "LIBS=-lm -ltinfo")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              ;; The upstream installer recursively removes its target and
              ;; installs a /usr-oriented shell script.  Its tty build needs
              ;; only the compiled game and nhdat, so install precisely those
              ;; immutable files and let the launcher create player state.
              (let* ((data (string-append #$output "/share/acehack"))
                     (libexec (string-append #$output "/libexec"))
                     (doc (string-append #$output "/share/doc/acehack"))
                     (program (string-append libexec "/acehack"))
                     (launcher (string-append #$output "/bin/acehack")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p (dirname launcher))
                (install-file "dat/nhdat" data)
                (install-file "src/acehack" libexec)
                (mkdir-p doc)
                ;; dat/license is the license for the executable and every
                ;; installed generated map/data asset in this sole origin.
                (install-file "dat/license" doc)
                (install-file "doc/Guidebook.txt" doc)
                (install-file "README" doc)
                (install-file "doc/fixes36.0" doc)
                (copy-recursively "source-for-distribution"
                                  (string-append doc "/source"))
                (copy-file
                 #$(local-file (search-tay-package-file "acehack.scm"))
                 (string-append doc "/acehack.scm"))
                ;; install-sh also requires its notice in supporting docs.
                (copy-file "sys/autoconf/install-sh"
                           (string-append doc "/install-sh-notice"))
                (call-with-output-file (string-append doc "/SOURCE")
                  (lambda (port)
                    (display
                     (string-append
                      "AceHack revision " #$%acehack-commit "\n"
                      "Historical mirror: https://github.com/deepy/acehack\n"
                      "Original AceHack author: Alex Smith (ais523); see README.\n"
                      "NetHack General Public License: see license.\n"
                      "Complete selected patched executable and nhdat source\n"
                      "accompanies this distribution in source/ (NGPL 3(a),\n"
                      "source definition at dat/license lines 77-79). Original\n"
                      "copyright, license and warranty notices remain intact.\n"
                      "Downstream modifications, 2026-10-07: disable CHDIR,\n"
                      "SHELL and MAIL; preserve mail-scroll indices; use ncurses'\n"
                      "tparm declaration; fix internal-compression extension;\n"
                      "fix makedefs timestamp. Changed files carry dated notices\n"
                      "(NGPL 2(a)). acehack.scm retains the exact build and\n"
                      "per-user XDG launcher recipe. Rebuild from the channel:\n"
                      "guix build -L guix acehack\n"
                      "Source selection retains Unix/tty, complete game and dat\n"
                      "inputs, configure/autoconf templates, documentation text\n"
                      "and mandatory win32api.h configure input. Other ports,\n"
                      "graphical payloads, encoded sounds and unused graphics\n"
                      "headers are not installed. No opaque binaries are shipped.\n"
                      "nhdat packs help/history/options, logo.vt100, modemenu,\n"
                      "encyclopedia, oracles, rumors, quest text, dungeon and all\n"
                      "compiled special/quest levels. These game/map/text inputs\n"
                      "use NGPL; literary attributions remain in dat/data.base.\n"
                      "src/rnd.c retains its LibTomCrypt public-domain AES/SHA256\n"
                      "attribution. include/qttableview.h retains Trolltech's\n"
                      "unlimited use/distribution/modification grant. The\n"
                      "2026-10-07 pre-build rights audit covered all 310 selected\n"
                      "upstream text files (src 107, include 91, util 10, dat 39,\n"
                      "doc 32, sys 23, tty 4, root 4); generated build inputs\n"
                      "and this recipe are retained in addition. Build\n"
                      "auxiliaries retain their own notices: configure's\n"
                      "unlimited copying grant; config.guess/sub's GNU GPL\n"
                      "Autoconf distribution exception; install-sh's MIT\n"
                      "permission (also in install-sh-notice). Runtime libraries\n"
                      "and tools are separate Guix inputs with their own notices.\n"
                      "Documentation limitation: original build-only doc/tmac.n\n"
                      "prohibits sale and redistribution of modifications and is\n"
                      "not installed. Full formatted Guidebook.txt and original\n"
                      "Guidebook.mn/Guidebook.tex text are retained. Rebuilding\n"
                      "historical Guidebook formatting requires that macro from\n"
                      "the pinned upstream build input; source/ is complete for\n"
                      "the executable/nhdat, not a self-contained documentation\n"
                      "formatter distribution. The full upstream origin is not\n"
                      "claimed to be wholly under free licenses.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~
state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/acehack\"~%
runtime=\"${XDG_RUNTIME_DIR:-$state}\"~%
~a -p \"$state/dumps\" \"$state/save\" \"$state/level\" \"$state/lock\" \"$runtime\"~%
for mutable in perm record logfile xlogfile; do~%
  if test ! -e \"$state/$mutable\"; then~%
    : > \"$state/$mutable\"~%
  fi~%
done~%
rundir=$(~a -d \"$runtime/acehack.XXXXXX\")~%
cleanup() { ~a -rf \"$rundir\"; }~%
trap cleanup EXIT HUP INT TERM~%
for file in ~s/*; do~%
  test -e \"$file\" || continue~%
  ~a -s \"$file\" \"$rundir/$(~a \"$file\")\"~%
done~%
for file in \"$state\"/*; do~%
  test -e \"$file\" || continue~%
  ~a -s \"$file\" \"$rundir/$(~a \"$file\")\"~%
done~%
cd \"$rundir\"~%
export HACKDIR=\"$rundir\"~%
set +e~%
~a \"$@\"~%
status=$?~%
set -e~%
for file in \"$rundir\"/*; do~%
  test -e \"$file\" || continue~%
  test -L \"$file\" && continue~%
  ~a -a \"$file\" \"$state/\"~%
done~%
exit $status~%"
                            #$(file-append bash-minimal "/bin/sh")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm")
                            data
                            #$(file-append coreutils-minimal "/bin/ln")
                            #$(file-append coreutils-minimal "/bin/basename")
                            #$(file-append coreutils-minimal "/bin/ln")
                            #$(file-append coreutils-minimal "/bin/basename")
                            program
                            #$(file-append coreutils-minimal "/bin/cp"))))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              ;; The executable and nhdat are both produced solely from this
              ;; origin and are covered by dat/license.  Retain that notice
              ;; together with every installed upstream document, so the
              ;; resulting package does not separate code or data from its
              ;; applicable license and notices.
              (let ((doc (string-append #$output "/share/doc/acehack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed AceHack notice" file)))
                 '("license" "README" "Guidebook.txt" "fixes36.0" "SOURCE"
                   "acehack.scm" "install-sh-notice" "source/dat/license"
                   "source/src/rnd.c" "source/win/tty/wintty.c"
                   "source/util/makedefs.c" "source/include/autoconf.h"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append doc "license"))
                (invoke "grep" "-F" "AceHack 3.6.0"
                        (string-append doc "README"))
                ;; README explicitly directs AceHack recipients to this
                ;; license, covering the compiled game and generated nhdat
                ;; as well as the retained upstream documentation.
                (invoke "grep" "-F" "contributors to AceHack"
                        (string-append doc "README"))
                (invoke "grep" "-F" "also expect that you will follow it"
                        (string-append doc "README")))))
          ;; Keep this last: the standard phases still strip binaries and
          ;; create a linker cache after patching shebangs.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
                (for-each
                 (lambda (file)
                   (chmod file
                          (cond ((file-is-directory? file) #o555)
                                ((access? file X_OK) #o555)
                                (else #o444))))
                 (find-files #$output ".*" #:directories? #t)))))))
    ;; lev_comp and dgn_comp regenerate their yacc/lex input during the
    ;; source build; groff supplies nroff and tbl for the Guidebook.
    (native-inputs (list bison flex groff-minimal util-linux))
    ;; The tty port uses ncurses and explicitly links its separated tinfo
    ;; library.  Bash and Coreutils are referenced by the store-safe launcher.
    (inputs (list bash-minimal coreutils-minimal ncurses/tinfo))
    (home-page "https://github.com/deepy/acehack")
    (synopsis "Historical tty NetHack variant")
    (description
     "AceHack is an independently playable historical NetHack variant.  This
package builds its tty-only interface from a fixed public source commit, with
no build-time or runtime downloads.  Its launcher creates a temporary
playground for each invocation, exposing immutable game data from the store
and keeping saves, scores, logs, locks, and other mutable state under XDG data
directories.  Installed documentation includes the complete selected patched
tty executable and game-data source, license and dated downstream notices;
SOURCE records third-party terms and the uninstalled documentation formatter
needed to reproduce the historical Guidebook formatting.")
    ;; NGPL covers the game and its generated data; build auxiliaries retain
    ;; their own grants in source/.  Restricted optional inputs are not shipped.
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
