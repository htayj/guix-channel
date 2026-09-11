;;; GNU Guix package for the NitroHack terminal roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages nitrohack)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages web))

;; Tag 4.0.4 names this immutable upstream revision.  The repository is
;; archived, so use the commit archive rather than a moving branch or a
;; build-time checkout.
(define %nitrohack-commit
  "21b9774b24efbdafdd20e152f9b1e5ed2a7b4150")

(define-public nitrohack
  (package
    (name "nitrohack")
    (version "4.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/DanielT/NitroHack/archive/"
             %nitrohack-commit ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 5db7e86e88ef3ac03a10cfe29738e4c45ab24be2ed552ebf8c71d6d11034682d
       (sha256
        (base32 "0bb86h8d3mkiijzjwmgdw95v4nn4whw9gqng20xc0fpgi1pfidsx"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; The generated parsers, headers, and nhdat archive form one build
      ;; graph in upstream CMake; serialize it for older CMake metadata.
      #:parallel-build? #f
      ;; Upstream has no test target.  The installed curses executable is
      ;; exercised by tests/nitrohack-smoke.sh.
      #:tests? #f
      #:configure-flags
      #~(list
         "-DENABLE_SERVER=OFF"
         (string-append "-DBINDIR=" #$output "/libexec")
         (string-append "-DLIBDIR=" #$output "/lib")
         (string-append "-DDATADIR=" #$output "/share/nitrohack")
         (string-append "-DCMAKE_INSTALL_RPATH=" #$output "/libexec:"
                        #$output "/lib")
         ;; Upstream emits a shell launcher here.  It is removed after the
         ;; install because the Guix launcher below supplies the library path
         ;; and keeps the real executable private.
         (string-append "-DSHELLDIR=" #$output "/share/nitrohack"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'make-build-reproducible
            (lambda _
              ;; makedefs embeds the current clock in date.h and nhdat.  Use
              ;; the timestamp of the pinned 4.0.4 commit instead.
              (substitute* "libnitrohack/util/makedefs.c"
                (("time\\(&clocktim\\);")
                 "clocktim = 1329666608L;"))
              ;; Guix's wide ncurses headers are installed directly as
              ;; include/curses.h rather than Debian's ncursesw/curses.h.
              (substitute* "nitrohack/include/nhcurses.h"
                (("<ncursesw/curses\\.h>") "<curses.h>"))
              (setenv "TZ" "UTC0")))
          ;; CMake's generated shell script is not the package interface.  It
          ;; is installed in a separate directory so it cannot overwrite the
          ;; real executable, then discarded below.
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/nitrohack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/nitrohack"))
                     (installed-shell (string-append data "/nitrohack"))
                     (real (string-append libexec "/nitrohack-real"))
                     (launcher (string-append bin "/nitrohack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname-bin #$(file-append coreutils-minimal "/bin/dirname"))
                     (find #$(file-append findutils "/bin/find"))
                     (grep #$(file-append grep "/bin/grep"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script"))
                     (stty #$(file-append coreutils-minimal "/bin/stty"))
                     (terminfo (string-append #$ncurses "/share/terminfo"))
                     (source (dirname (car (find-files ".." "^README$"))))
                     (notices '("README" "doc/Guidebook.txt"
                                "dist/debian/copyright")))
                (invoke "cmake" "--install" ".")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (unless (file-exists? (string-append libexec "/nitrohack"))
                  (error "CMake did not install the NitroHack executable"))
                (rename-file (string-append libexec "/nitrohack") real)
                (when (file-exists? installed-shell)
                  (delete-file installed-shell))
                (for-each
                 (lambda (file)
                   (install-file (string-append source "/" file) doc))
                 notices)
                ;; The upstream CMake data install retains nhdat and the
                ;; complete NitroHack/NetHack General Public License beside
                ;; the generated game data.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~%"
                            shell)
                    (format port "real=~s~%data=~s~%out=~s~%libexec=~s~%"
                            real data out libexec)
                    (format port "cat=~s~%cp=~s~%dirname=~s~%find=~s~%"
                            cat cp dirname-bin find)
                    (format port "grep=~s~%mkdir=~s~%mktemp=~s~%rm=~s~%"
                            grep mkdir mktemp rm)
                    (format port "sleep=~s~%script=~s~%stty=~s~%terminfo=~s~%"
                            sleep script stty terminfo)
                    (display
                     "export LD_LIBRARY_PATH=\"$libexec:$out/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\n"
                     port)
                    (display
                     "export TERM=\"${TERM:-xterm-256color}\"\n"
                     port)
                    (display
                     "export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n\n"
                     port)
                    (display "run_session() {\n" port)
                    (display "  log=$1\n  mode=${2-truncate}\n" port)
                    (display "  command=\"$stty rows 25 cols 80; exec $real -@ -u goocastle-smoke\"\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then\n" port)
                    (display "    \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"\n" port)
                    (display "    if test \"$mode\" = append; then\n" port)
                    (display "      \"$script\" -qefc \"$command\" \"$log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "    else\n      \"$script\" -qefc \"$command\" \"$log\" > \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n    fi\n" port)
                    (display "  else\n    \"$script\" -qefc \"$command\" \"$log\" >/dev/null\n  fi\n" port)
                    (display "}\n\n" port)
                    (display "if test \"${1-}\" = --guix-smoke; then\n" port)
                    (display "  test \"$#\" -eq 1 || { echo 'usage: nitrohack [--guix-smoke]' >&2; exit 64; }\n" port)
                    ;; Keep the package smoke self-contained: it does not
                    ;; inspect or reuse a caller's home/configuration state.
                    (display "  smoke=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/nitrohack-guix-smoke.XXXXXXXX\")\n" port)
                    (display "  \"$mkdir\" -p \"$smoke/home\" \"$smoke/config\" \"$smoke/data\" \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"\n" port)
                    (display "  export HOME=\"$smoke/home\" XDG_CONFIG_HOME=\"$smoke/config\" XDG_DATA_HOME=\"$smoke/data\" XDG_CACHE_HOME=\"$smoke/cache\" XDG_STATE_HOME=\"$smoke/state\" XDG_RUNTIME_DIR=\"$smoke/runtime\" TMPDIR=\"$smoke/tmp\" TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  first_log=\"$smoke/tmp/smoke-first.log\"\n  second_log=\"$smoke/tmp/smoke-second.log\"\n" port)
                    ;; New game, deterministic movement, then save and leave
                    ;; the first session through the main menu.
                    (display "  if ! { \"$sleep\" 1; printf 'n'; \"$sleep\" 1; printf '.'; \"$sleep\" 1; printf 'h'; \"$sleep\" 1; printf 'j'; \"$sleep\" 1; printf 'l'; \"$sleep\" 1; printf 'S'; \"$sleep\" 1; printf 'y'; \"$sleep\" 1; printf 'q'; } | run_session \"$first_log\"; then\n" port)
                    (display "    echo 'nitrohack smoke: first game failed' >&2; exit 1\n  fi\n" port)
                    (display "  saved=\"\"\n  for file in \"$smoke/config/NitroHack/save\"/*.nhgame; do\n    test -f \"$file\" || continue\n    saved=\"$file\"\n  done\n  test -n \"$saved\" || { echo 'nitrohack smoke: save artifact missing' >&2; exit 1; }\n" port)
                    (display "  case \"$saved\" in \"$smoke/\"*) ;; *) echo 'nitrohack smoke: save escaped isolated state' >&2; exit 1 ;; esac\n" port)
                    (display "  \"$grep\" -F 'NitroHack' \"$first_log\" >/dev/null || { echo 'nitrohack smoke: gameplay title missing' >&2; exit 1; }\n" port)
                    (display "  \"$grep\" -F 'welcome to NitroHack' \"$first_log\" >/dev/null || { echo 'nitrohack smoke: gameplay welcome missing' >&2; exit 1; }\n" port)
                    ;; Relaunch, load the saved game, observe the restored
                    ;; welcome, save/quit again, and leave the menu.
                    (display "  if ! { \"$sleep\" 1; printf 'l'; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf 'S'; \"$sleep\" 1; printf 'y'; \"$sleep\" 1; printf 'q'; } | run_session \"$second_log\" append; then\n" port)
                    (display "    echo 'nitrohack smoke: restore game failed' >&2; exit 1\n  fi\n" port)
                    (display "  \"$grep\" -E 'welcome back to NitroHack|Welcome back' \"$second_log\" >/dev/null || { echo 'nitrohack smoke: restored-game text missing' >&2; exit 1; }\n" port)
                    ;; The game is allowed to write only its fresh HOME and
                    ;; XDG config tree.  Data/cache/state/runtime are checked
                    ;; explicitly because the game does not use those APIs.
                    (display "  test -z \"$(\"$find\" \"$smoke/data\" \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" -mindepth 1 -print -quit)\" || { echo 'nitrohack smoke: unexpected XDG write' >&2; exit 1; }\n" port)
                    (display "  test -z \"$(\"$find\" \"$out\" -xdev -type f -perm /222 -print -quit)\" || { echo 'nitrohack smoke: package output became writable' >&2; exit 1; }\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then\n    \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"\n    \"$cp\" \"$first_log\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n    \"$cat\" \"$second_log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n  fi\n" port)
                    (display "  printf '%s\\n' 'nitrohack guix smoke passed'\n  exit 0\nfi\n\n" port)
                    ;; Ordinary invocations retain normal argument
                    ;; forwarding while keeping the executable private.
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/nitrohack/"))
                    (doc (string-append #$output "/share/doc/nitrohack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed NitroHack notice" file)))
                 '("README" "Guidebook.txt" "copyright"))
                (unless (file-exists? (string-append data "nhdat"))
                  (error "missing installed NitroHack data archive"))
                (unless (file-exists? (string-append data "license"))
                  (error "missing installed NitroHack license"))
                (invoke "grep" "-F" "NITROHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "NitroHack"
                        (string-append doc "README")))))
          ;; All generated data and launcher files must be immutable after
          ;; installation; user state is redirected by the runtime itself.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    ;; CMake invokes the checked-in bison/flex generators.  gcc-toolchain is
    ;; explicit because the project predates modern Guix CMake defaults.
    (native-inputs (list bison cmake-minimal flex gcc-toolchain))
    ;; Jansson and wide ncurses are linked by the local client/UI.  The shell
    ;; helpers and util-linux/script are runtime inputs for the reviewed smoke
    ;; branch only.
    (inputs (list bash-minimal coreutils-minimal findutils grep jansson
                  ncurses util-linux))
    (home-page "https://github.com/DanielT/NitroHack")
    (synopsis "Modernized terminal dungeon exploration game")
    (description
     "NitroHack is a modernized, network-capable fork of the classic
NetHack dungeon exploration game.  This package builds the local wide-curses
client from the fixed 4.0.4 source revision, with the optional PostgreSQL
network server disabled and no runtime downloads.  Its launcher keeps the
rebuilt executable private, supplies the Guix library and terminfo paths, and
provides an isolated --guix-smoke save/restore proof.  Game configuration,
saves, and logs remain under the user's XDG configuration directory.  The
upstream NitroHack/NetHack General Public License, README, Guidebook, and
Debian copyright notice are installed with the generated nhdat archive.")
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
