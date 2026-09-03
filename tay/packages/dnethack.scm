;;; GNU Guix package for the dNetHack terminal roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages dnethack)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages linux))

(define %dnethack-commit
  "a6f0a1c43e66f4fb1bcac34d7d9709706682ec19")

(define-public dnethack
  (package
    (name "dnethack")
    (version "3.26.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Chris-plus-alphanumericgibberish/dNAO")
             (commit %dnethack-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0lakz0czfkymnnb64q7yjvm3r3yfj3xqbylrha3cpc2ix07x0cvj"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The generated yacc/flex sources, maps, and nhdat have ordering
      ;; dependencies and must be made in one serialized build.
      #:parallel-build? #f
      ;; Upstream has no non-interactive test target.  The installed tty
      ;; executable is exercised by tests/dnethack-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'make-build-reproducible
            (lambda _
              ;; A Guix git checkout has no .git directory.  Keep the
              ;; generated version information tied to the fixed revision.
              (substitute* "GNUmakefile"
                (("export COMMIT_DESC := \\$[(]shell git describe --always[)]")
                 "export COMMIT_DESC := a6f0a1c43e66f4fb1bcac34d7d9709706682ec19"))
              ;; The upstream admin-message hook reads an ambient relative
              ;; file; it is not part of the ordinary standalone game.
              (substitute* "include/config.h"
                (("^#define SERVER_ADMIN_MSG.*$")
                 "/* #define SERVER_ADMIN_MSG */"))
              ;; makedefs otherwise embeds the builder's wall clock in
              ;; include/date.h, verinfo, and the generated data archive.
              (substitute* "util/makedefs.c"
                (("\\(void\\) time\\(\\(time_t \\*\\)&clocktim\\);")
                 "clocktim = 1779991412L;"))))
          (replace 'build
            (lambda _
              (invoke "make" "all" "CC=gcc")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/dnethack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/dnethack"))
                     (real (string-append libexec "/dnethack-real"))
                     (launcher (string-append bin "/dnethack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (ln #$(file-append coreutils-minimal "/bin/ln"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (readlink #$(file-append coreutils-minimal "/bin/readlink"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "src/dnethack" libexec)
                (rename-file (string-append libexec "/dnethack") real)
                (install-file "dat/nhdat" data)
                (install-file "dat/license" data)
                (install-file "README" doc)
                (install-file "README.gray" doc)
                (install-file "README.menucolor" doc)
                (install-file "doc/Guidebook.txt" doc)
                (install-file "sys/unix/README.linux" doc)
                (for-each
                 (lambda (file) (install-file file doc))
                 (find-files "doc" "^fixes"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    (format port "real=~s~%data=~s~%mkdir=~s~%mktemp=~s~%"
                            real data mkdir mktemp)
                    (format port "ln=~s~%rm=~s~%readlink=~s~%sleep=~s~%"
                            ln rm readlink sleep)
                    (format port "script=~s~%cat=~s~%~%" script cat)
                    (display
                     "state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/dnethack\"\n"
                     port)
                    (display "export TERM=\"${TERM:-xterm-256color}\"\n" port)
                    (display "\"$mkdir\" -p \"$state/save\" \"$state/dumplog\" \"$state/whereis\"\n"
                             port)
                    (display "test -e \"$state/perm\" || : > \"$state/perm\"\n"
                             port)
                    (display "for file in record logfile xlogfile livelog paniclog hangup; do\n"
                             port)
                    (display "  test -e \"$state/$file\" || : > \"$state/$file\"\n"
                             port)
                    (display "done\n\n" port)
                    (display "mailbox=\"$state/mailbox\"\n"
                             port)
                    (display "test -e \"$mailbox\" || : > \"$mailbox\"\n"
                             port)
                    (display "export MAIL=\"$mailbox\"\n\n" port)
                    (display "new_playground() {\n" port)
                    (display "  playground=$(\"$mktemp\" -d \"$state/playground.XXXXXX\")\n"
                             port)
                    (display "  \"$ln\" -s \"$data/nhdat\" \"$playground/nhdat\"\n"
                             port)
                    (display "  \"$ln\" -s \"$data/license\" \"$playground/license\"\n"
                             port)
                    (display "  for file in perm record logfile xlogfile livelog paniclog hangup; do\n"
                             port)
                    (display "    \"$ln\" -s \"$state/$file\" \"$playground/$file\"\n"
                             port)
                    (display "  done\n" port)
                    (display "  \"$ln\" -s \"$state/save\" \"$playground/save\"\n"
                             port)
                    (display "  \"$ln\" -s \"$state/dumplog\" \"$playground/dumplog\"\n"
                             port)
                    (display "  \"$ln\" -s \"$state/whereis\" \"$playground/whereis\"\n"
                             port)
                    (display "  printf '%s\\n' \"$playground\"\n" port)
                    (display "}\n\n" port)
                    (display "if test \"${1-}\" = --guix-smoke; then\n" port)
                    (display "  test \"$#\" -eq 1 || { echo 'usage: dnethack [--guix-smoke]' >&2; exit 64; }\n"
                             port)
                    ;; Both runs use the same data directory and separate
                    ;; private playgrounds.  The first run saves after a rest;
                    ;; the second restores that save and quits cleanly.
                    (display "  first=$(new_playground)\n" port)
                    (display "  cd \"$first\"\n"
                             port)
                    (display "  export HACKDIR=\"$first\" NETHACKDIR=\"$first\"\n"
                             port)
                    (display "  first_log=\"$first/smoke-first\"\n" port)
                    (display "  if ! { \"$sleep\" 1; printf 'y'; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf '.'; \"$sleep\" 1; printf 'S'; \"$sleep\" 1; printf 'y'; } | \"$script\" -qefc \"$real -X -n -u goocastle-tourist-human-neutral-male\" \"$first_log\"; then\n"
                             port)
                    (display "    echo 'dnethack smoke: first game failed' >&2; exit 1\n  fi\n"
                             port)
                    (display "  saved=\"\"\n  for file in \"$state/save\"/*; do\n    test -f \"$file\" || continue\n    saved=\"$file\"\n  done\n  test -n \"$saved\"\n"
                             port)
                    (display "  first_text=$(\"$cat\" \"$first_log\")\n"
                             port)
                    (display "  case \"$first_text\" in *dNetHack*|*dNethack*) ;; *) echo 'dnethack smoke: gameplay title missing' >&2; exit 1 ;; esac\n"
                             port)
                    (display "  second=$(new_playground)\n" port)
                    (display "  cd \"$second\"\n"
                             port)
                    (display "  export HACKDIR=\"$second\" NETHACKDIR=\"$second\"\n"
                             port)
                    (display "  second_log=\"$second/smoke-second\"\n" port)
                    (display "  if ! { \"$sleep\" 1; printf 'y'; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf ' '; \"$sleep\" 1; printf 'y'; \"$sleep\" 1; printf '#quit\\n'; \"$sleep\" 1; printf 'y'; } | \"$script\" -qefc \"$real -X -n -u goocastle-tourist-human-neutral-male\" \"$second_log\"; then\n"
                             port)
                    (display "    echo 'dnethack smoke: restore game failed' >&2; exit 1\n  fi\n"
                             port)
                    (display "  second_text=$(\"$cat\" \"$second_log\")\n"
                             port)
                    (display "  case \"$second_text\" in *[Rr]estor*|*'Welcome back'*) ;; *) echo 'dnethack smoke: restoration missing' >&2; exit 1 ;; esac\n"
                             port)
                    (display "  for link in nhdat license perm record logfile xlogfile livelog paniclog hangup save dumplog whereis; do\n"
                             port)
                    (display "    test -L \"$second/$link\" || { echo \"dnethack smoke: missing $link link\" >&2; exit 1; }\n"
                             port)
                    (display "  done\n" port)
                    (display "  test \"$(\"$readlink\" \"$second/nhdat\")\" = \"$data/nhdat\"\n"
                             port)
                    (display "  test \"$(\"$readlink\" \"$second/license\")\" = \"$data/license\"\n"
                             port)
                    (display "  case \"$second\" in \"$state/\"*) ;; *) echo 'dnethack smoke: playground escaped state' >&2; exit 1 ;; esac\n"
                             port)
                    (display "  \"$rm\" -rf \"$first\" \"$second\"\n"
                             port)
                    (display "  printf '%s\\n' 'dnethack guix smoke passed'\n  exit 0\nfi\n\n"
                             port)
                    (display "playground=$(new_playground)\n"
                             port)
                    (display "cleanup() { \"$rm\" -rf \"$playground\"; }\n"
                             port)
                    (display "trap cleanup EXIT HUP INT TERM\n"
                             port)
                    (display "cd \"$playground\"\n"
                             port)
                    (display "export HACKDIR=\"$playground\" NETHACKDIR=\"$playground\"\n"
                             port)
                    (display "set +e\n\"$real\" \"$@\"\nstatus=$?\nset -e\nexit \"$status\"\n"
                             port)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/dnethack"))
                    (doc (string-append #$output "/share/doc/dnethack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed dNetHack document" file)))
                 '("README" "README.gray" "README.menucolor"
                   "Guidebook.txt" "README.linux"))
                (unless (file-exists? (string-append data "/nhdat"))
                  (error "missing installed dNetHack data archive"))
                (unless (file-exists? (string-append data "/license"))
                  (error "missing installed dNetHack license"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "/license"))
                (invoke "grep" "-F" "dNetHack is free software"
                        (string-append doc "README"))
                ;; MacroMagicMarker.py is MIT-licensed build input, not an
                ;; installed runtime asset; make sure it was not copied.
                (unless (not (file-exists?
                              (string-append doc "MacroMagicMarker.py")))
                  (error "unintended MacroMagicMarker runtime install")))))
          ;; Keep the store output immutable after all generated files and
          ;; launcher shebangs have been installed.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex pkg-config))
    ;; Bash and coreutils support the store-safe launcher.  util-linux is used
    ;; only by its reviewed --guix-smoke branch to provide a PTY to the real
    ;; tty executable; ncurses/tinfo provides the Unix curses linkage.
    (inputs (list bash-minimal coreutils-minimal ncurses/tinfo util-linux))
    (home-page "https://github.com/Chris-plus-alphanumericgibberish/dNAO")
    (synopsis "Terminal dungeon exploration game based on NetHack")
    (description
     "dNetHack is a maintained NetHack variant with a terminal interface and
     extensive new roles, races, monsters, items, and dungeon branches.  This
     package builds the ordinary Unix variant from a fixed dNAO revision,
     installs only its tty executable and generated data archive, and provides
     a launcher that keeps all mutable game state in XDG data directories.")
    ;; The upstream dat/license is the NetHack General Public License for the
    ;; C sources, generated map/data files, and the resulting executable.
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
