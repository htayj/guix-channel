;;; GNU Guix package for the historical GruntHack tty roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages grunthack)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages flex)
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
       (method url-fetch)
       (uri (string-append
             "https://github.com/NHTangles/GruntHack/archive/"
             %grunthack-commit ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256: 00c8b0178f4fb2aefd08c51d08263b9f6c57340b601afb6d9f9528fdd9bd718
       (sha256
        (base32 "11vippczsa4mkxnzn6k01cs5fv4z7ck0h7f513ysxcjgiwbv1j00"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      ;; Upstream has no non-interactive test target; the installed tty game
      ;; is exercised by tests/grunthack-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list "CC=gcc"
              ;; This historical source uses K&R definitions and declarations
              ;; that GCC's default gnu17 mode rejects as errors.
              "CFLAGS=-O2 -g0 -std=gnu89 -fcommon -I../include -D_DEFAULT_SOURCE -DTEXTCOLOR"
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
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (find #$(file-append coreutils-minimal "/bin/find"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script")))
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
                (let ((port (open-file launcher "w")))
                  (format port "#!~a~%set -eu~%~%
data=~s~%
real=~s~%
mkdir=~s~%
mktemp=~s~%
rm=~s~%
sleep=~s~%
script=~s~%
cat=~s~%
cp=~s~%
dirname=~s~%
find=~s~%~%
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
run_game() {~%
  log=$1~%
  mode=${2-truncate}~%
  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then~%
    if test \"$mode\" = append; then~%
      \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \"$log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    else~%
      \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \"$log\" > \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    fi~%
  else~%
    \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \"$log\" >/dev/null~%
  fi~%
}~%~%
case \"${1-}\" in~%
  --guix-smoke)~%
    test \"$#\" -eq 1 || { echo 'usage: grunthack [--guix-smoke]' >&2; exit 64; }~%
    smoke=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/grunthack-guix-smoke.XXXXXXXX\")~%
    cleanup() { \"$rm\" -rf \"$smoke\"; }~%
    trap cleanup EXIT HUP INT TERM~%
    \"$mkdir\" \"$smoke/home\" \"$smoke/config\" \"$smoke/data\" \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"~%
    chmod 700 \"$smoke/runtime\"~%
    export HOME=\"$smoke/home\" XDG_CONFIG_HOME=\"$smoke/config\"~%
    export XDG_DATA_HOME=\"$smoke/data\" XDG_CACHE_HOME=\"$smoke/cache\"~%
    export XDG_STATE_HOME=\"$smoke/state\" XDG_RUNTIME_DIR=\"$smoke/runtime\"~%
    export TMPDIR=\"$smoke/tmp\" TERM=xterm-256color LC_ALL=C~%
    prepare_state~%
    first_log=\"$state/smoke-first.log\"~%
    second_log=\"$state/smoke-second.log\"~%
    if ! { printf 'y'; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf 'l'; \"$sleep\" 1; printf 'S'; \"$sleep\" 1; printf 'y'; } | run_game \"$first_log\"; then~%
      echo 'grunthack smoke: first game failed' >&2; exit 1~%
    fi~%
    saved=~%
    for file in \"$state/save\"/*; do~%
      test -f \"$file\" || continue~%
      saved=\"$file\"~%
    done~%
    test -n \"$saved\" || { echo 'grunthack smoke: save missing' >&2; exit 1; }~%
    first_text=$(\"$cat\" \"$first_log\")~%
    case \"$first_text\" in *GruntHack*) ;; *) echo 'grunthack smoke: title missing' >&2; exit 1 ;; esac~%
    if ! { printf ' '; \"$sleep\" 1; printf '.'; \"$sleep\" 1; printf 'Q'; \"$sleep\" 1; printf 'y'; } | run_game \"$second_log\" append; then~%
      echo 'grunthack smoke: restore game failed' >&2; exit 1~%
    fi~%
    second_text=$(\"$cat\" \"$second_log\")~%
    case \"$second_text\" in *\"Restoring save file\"*) ;; *) echo 'grunthack smoke: restore missing' >&2; exit 1 ;; esac~%
    for root in \"$HOME\" \"$XDG_CONFIG_HOME\" \"$XDG_CACHE_HOME\" \"$XDG_STATE_HOME\" \"$XDG_RUNTIME_DIR\" \"$TMPDIR\"; do~%
      escaped=$(\"$find\" \"$root\" -mindepth 1 -print -quit)~%
      test -z \"$escaped\" || { echo 'grunthack smoke: mutable path escaped XDG data' >&2; exit 1; }~%
    done~%
    if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then~%
      \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"~%
      \"$cp\" \"$first_log\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
      \"$cat\" \"$second_log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    fi~%
    printf '%s\\n' 'grunthack guix smoke passed'~%
    exit 0~%
    ;;~%
  *)~%
    prepare_state~%
    exec \"$real\" \"$@\"~%
    ;;~%
esac~%"
                            shell data real mkdir mktemp rm sleep script cat cp
                            dirname find)
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
                   "README.linux" "license"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "GruntHack is a derivative of NetHack"
                        (string-append doc "README")))))
          ;; Guix makes completed store outputs immutable.  Do not chmod the
          ;; output while it is still being assembled: the recursive walk can
          ;; encounter generated paths that the upstream makefiles remove.
          )))
    (native-inputs
     (list bison flex gcc-toolchain gnu-make))
    (inputs
     (list bash-minimal coreutils-minimal ncurses/tinfo util-linux))
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
