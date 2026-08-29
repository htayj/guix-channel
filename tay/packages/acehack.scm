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
  #:use-module (gnu packages ncurses))

;; AceHack has no release tags.  This is the final master tip of the
;; authoritative public git mirror, dated 2015-03-11.
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
              ;; This 2015 source retains K&R definitions which GCC's modern
              ;; default language mode rejects as errors.
              (setenv "CFLAGS"
                      (string-append (or (getenv "CFLAGS") "") " -std=gnu89"))
              (setenv "LIBS" "-ltinfo")))
          (add-after 'configure 'fix-internal-compression-build
            (lambda _
              ;; This version's --with-compression=no branch correctly uses
              ;; INTERNAL_COMP, but verify_savefile still references the
              ;; optional extension macro.  An empty extension preserves the
              ;; no-external-compressor behavior while repairing that build
              ;; omission.
              (substitute* "include/autoconf.h"
                (("#undef COMPRESS_EXTENSION")
                 "#define COMPRESS_EXTENSION \"\""))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              ;; Use the upstream installation recipe solely to enumerate and
              ;; produce its compiled tty data; discard its /usr-oriented
              ;; wrapper and split mutable files out of the store afterwards.
              (invoke "make" "install" "CHOWN=true" "CHGRP=true" "CHMOD=true")
              (let* ((staging (string-append #$output "/acehackdir"))
                     (data (string-append #$output "/share/acehack"))
                     (libexec (string-append #$output "/libexec"))
                     (doc (string-append #$output "/share/doc/acehack"))
                     (program (string-append libexec "/acehack"))
                     (launcher (string-append #$output "/bin/acehack")))
                (mkdir-p data)
                (copy-recursively staging data)
                (mkdir-p libexec)
                (rename-file (string-append data "/acehack") program)
                ;; recover and these files are stateful administration or
                ;; player data, not immutable packaged game assets.
                (for-each
                 (lambda (name)
                   (let ((file (string-append data "/" name)))
                     (when (file-exists? file)
                       (if (file-is-directory? file)
                           (delete-file-recursively file)
                           (delete-file file)))))
                 '("recover" "license" "Guidebook.txt" "perm" "record"
                   "logfile" "xlogfile" "livelog" "save" "level" "lock"))
                (mkdir-p doc)
                ;; dat/license is the license for the executable and every
                ;; installed generated map/data asset in this sole origin.
                (install-file "dat/license" doc)
                (install-file "doc/Guidebook.txt" doc)
                (install-file "README" doc)
                (install-file "doc/fixes36.0" doc)
                (delete-file-recursively staging)
                (delete-file launcher)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~
state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/acehack\"~%
runtime=\"${XDG_RUNTIME_DIR:-$state}\"~%
~a -p \"$state/save\" \"$state/level\" \"$state/lock\" \"$runtime\"~%
for mutable in perm record logfile xlogfile; do~%
  : > \"$state/$mutable\"~%
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
                            #$(file-append coreutils-minimal "/bin/cp")))))))
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
directories.")
    ;; dat/license is the NetHack General Public License, which the complete
    ;; AceHack source and its generated game data identify as their license.
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
