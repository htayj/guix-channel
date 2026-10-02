;;; GNU Guix package for the historical GruntHack tty roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages grunthack)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define %grunthack-commit
  "51d75eebbcf8ab0ce31ddab9581d266db0a691c5")

(define-public grunthack
  (package
    (name "grunthack")
    (version "0.2.4-0.51d75ee")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/NHTangles/GruntHack")
             (commit %grunthack-commit)))
       (file-name (git-file-name name version))
       ;; NAR SHA-256 obtained with guix download --git at this exact commit.
       (sha256
        (base32 "0a2il12ap9lkdmys74vj90vv1dn18ypm7gn73yic8hdqh1j3kg5m"))
       ;; The Macintosh instrument samples have no redistribution grant:
       ;; their README only speculates about Roland sample-library copyright.
       ;; They are unused by tty.  Keep that notice but omit the sample payload
       ;; from the source derivation as well as the installed game.
       (modules '((guix build utils)))
       (snippet
        #~(for-each delete-file (find-files "sys/share/sounds" "\\.uu$")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      ;; Upstream has no non-interactive test target; the installed tty game
      ;; is exercised by tests/grunthack-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              ;; This historical source uses K&R definitions and declarations
              ;; that GCC's default gnu17 mode rejects as errors.
              (string-append
               "CFLAGS=-O2 -g0 -std=gnu89 -fcommon -I../include"
               " -D_DEFAULT_SOURCE -DTEXTCOLOR")
              "LEX=flex"
              "YACC=bison -y"
              "WINTTYLIB=-lncurses"
              ;; Guix's ncurses splits the terminfo entry points into a
              ;; separate library, while the old Makefile assumes they are
              ;; pulled in transitively.
              "WINCURSESLIB=-ltinfo"
              "VCS_DESCRIPTION=git 51d75ee")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda _
              (use-modules (ice-9 textual-ports))
              ;; NGPL paragraph 2(a): retain upstream headers and prominently
              ;; identify every file changed by this downstream build.
              (for-each
               (lambda (file)
                 (let ((original (call-with-input-file file get-string-all)))
                   (call-with-output-file file
                     (lambda (port)
                       (display
                        (string-append
                         "/* Modified by the tay Guix channel, 2026-10-02:\n"
                         " * native tty build, XDG paths, and reproducible"
                         " data generation.\n"
                         " * See the distributed package definition for"
                         " exact changes. */\n")
                        port)
                       (display original port)))))
               '("include/unixconf.h" "include/extern.h" "include/config.h"
                 "sys/unix/unixmain.c" "util/makedefs.c"))
              ;; setup.sh installs the Unix Makefiles at their expected
              ;; relative paths.  The source archive has no .git directory,
              ;; so the version string is supplied through make-flags.
              (invoke "sh" "sys/unix/setup.sh")
              ;; Keep VAR_PLAYGROUND's code path but obtain its value from the
              ;; launcher, rather than embedding a writable system directory.
              (substitute* "include/unixconf.h"
                (("^#define VAR_PLAYGROUND[ \t]+[^\n]*")
                 "#define VAR_PLAYGROUND nh_getenv(\"GRUNTHACK_VAR_PLAYGROUND\")")
                (("^#define MAIL[ \t]+[^\n]*") "/* #define MAIL */"))
              ;; The tty build calls this always-available no-op/check helper,
              ;; but the shipped header declares only the old name.
              (substitute* "include/extern.h"
                (("E void NDECL\\(server_admin_msg\\);")
                 "E void NDECL(server_admin_msg);\nE void NDECL(ck_server_admin_msg);"))
             (substitute* "include/config.h"
               (("#define COMPRESS \"/bin/gzip\"")
                "/* #define COMPRESS */")
               (("#define COMPRESS_EXTENSION \"\\.gz\"")
                "/* #define COMPRESS_EXTENSION */")
                (("#define DUMP_FN[ \t]+.*")
                 "#define DUMP_FN \"\"")
               (("#define SERVER_ADMIN_MSG[ \t]+.*")
                "/* #define SERVER_ADMIN_MSG */"))
              ;; The upstream path setup otherwise treats an explicit HACKDIR
              ;; as a custom installation and leaves score/save prefixes in
              ;; the data directory.  The launcher intentionally supplies
              ;; HACKDIR/NETHACKDIR for store data, so honor VAR_PLAYGROUND in
              ;; that case as well.
              (substitute* "sys/unix/unixmain.c"
                (("if \\(dir[[:space:]]*/\\* User specified directory")
                 "if (dir && !VAR_PLAYGROUND /* User specified directory"))
              (setenv "TZ" "UTC0")
              ;; makedefs embeds the build clock in generated headers and
              ;; data.  The pinned revision was committed on 2018-09-17.
              (substitute* "util/makedefs.c"
                (("\\(void\\) time\\(&clocktim\\);")
                 "clocktim = 1537142400L;"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" (append (list "all") make-flags))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/grunthack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/grunthack"))
                     (real (string-append libexec "/grunthack-real"))
                     (launcher (string-append bin "/grunthack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "src/grunthack" libexec)
                (rename-file (string-append libexec "/grunthack") real)
                (install-file "dat/ghdat" data)
                (install-file "dat/license" data)
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README" "README-curses.txt" "doc/Guidebook.txt"
                   "doc/changes01.0" "doc/changes01.1" "doc/changes02.0"
                   "doc/changes02.1" "sys/unix/README.linux"))
                (install-file "dat/license" doc)
                (copy-file "sys/share/sounds/README"
                           (string-append doc "/sounds-README"))
                (call-with-output-file (string-append doc "/SOURCE")
                  (lambda (port)
                    (display
                     (string-append
                      "GruntHack 0.2.4, upstream revision "
                      "51d75eebbcf8ab0ce31ddab9581d266db0a691c5\n"
                      "Complete upstream source (noncommercial NGPL"
                      " paragraph 3(b)):\n"
                      "https://github.com/NHTangles/GruntHack/archive/"
                      "51d75eebbcf8ab0ce31ddab9581d266db0a691c5.tar.gz\n"
                      "License: NetHack General Public License (see license).\n"
                      "Downstream changes, 2026-10-02: native tty compilation,"
                      " XDG writable\n"
                      "paths, reproducible data generation, and omission of"
                      " unused Macintosh\n"
                      "instrument samples without a clear redistribution grant.\n"
                      "Guix can retrieve the filtered source with:"
                      " guix build --source grunthack\n"
                      "Exact build and source changes:"
                      " guix/tay/packages/grunthack.scm\n"
                      "in the tay Guix channel.\n")
                     port)))
                (let ((port (open-file launcher "w")))
                  (format port "#!~a~%set -eu~%~%
data=~s~%
real=~s~%
mkdir=~s~%~%
prepare_state() {~%
  state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/grunthack\"~%
  \"$mkdir\" -p \"$state/save\" \"$state/whereis\"~%
  for file in perm record logfile xlogfile livelog; do~%
    test -e \"$state/$file\" || : > \"$state/$file\"~%
  done~%
  export HACKDIR=\"$data\" NETHACKDIR=\"$data\"~%
  export GRUNTHACK_VAR_PLAYGROUND=\"$state/\"~%
  export TERM=\"${TERM:-xterm-256color}\"~%
}~%~%
prepare_state~%
exec \"$real\" \"$@\"~%"
                            shell data real mkdir)
                  (close-port port))
                (unless (file-exists? launcher)
                  (error "GruntHack launcher was not created" launcher))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/grunthack/"))
                    (doc (string-append #$output "/share/doc/grunthack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append data file))
                     (error "missing installed GruntHack runtime file" file)))
                 '("ghdat" "license"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed GruntHack notice" file)))
                 '("README" "README-curses.txt" "Guidebook.txt"
                   "changes01.0" "changes01.1" "changes02.0" "changes02.1"
                   "README.linux" "license" "SOURCE" "sounds-README"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "GruntHack is a derivative of NetHack"
                        (string-append doc "README")))))
          ;; Guix makes completed store outputs immutable.  Do not chmod the
          ;; output while it is still being assembled: the recursive walk can
          ;; encounter generated paths that the upstream makefiles remove.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs
     ;; make all formats Guidebook.txt with tbl/nroff/col.  These tools are
     ;; build-only; the ordinary native launcher does not reference them.
     (list bison flex gcc-toolchain gnu-make groff util-linux))
    (inputs
     (list bash-minimal coreutils-minimal ncurses/tinfo))
    (home-page "https://github.com/NHTangles/GruntHack")
    (synopsis "Historical terminal dungeon exploration game")
    (description
     "GruntHack is a NetHack derivative with expanded monsters, items, and
 dungeon levels.  This package builds the tty port from a fixed upstream
 revision, generates its game data offline, and installs only the executable,
 data archive, license, and relevant text documentation.  Its launcher keeps
 immutable game data in the store while placing saves, scores, locks, and
 other mutable state under the user's XDG data directory.")
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
