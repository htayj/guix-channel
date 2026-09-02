;;; GNU Guix package for CryptRover.
;;;
;;; CryptRover's Google Code archive contains a prebuilt `cr' and a
;;; network-fetching configure script.  The package deliberately removes the
;;; former and does not run the latter: the Linux no-sound build is made
;;; directly from src/*.c.

(define-module (tay packages cryptrover)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define-public cryptrover
  (package
    (name "cryptrover")
    (version "1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/google-code-archive-downloads/"
             "v2/code.google.com/cryptrover/cryptrover_1.1_nosound.tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256: 4c8fdb89c21e3302b81afcb7fb974e02533685c461a1e395e869c58e1ea51494
       ;; Guix's (base32 ...) origin literal uses Nix-base32:
       ;; 150lllg8xib9x2ay78b1qj2kclq29sbzpdzw3aw04cqyqa4xp3sc.
       (sha256
        (base32 "150lllg8xib9x2ay78b1qj2kclq29sbzpdzw3aw04cqyqa4xp3sc"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream tree has no test target.  The installed terminal game is
      ;; exercised by tests/cryptrover-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'remove-prebuilt-executable
            (lambda _
              ;; The archive's 19,704-byte `cr' is not an acceptable build
              ;; input.  All executable code must come from src/*.c.
              (delete-file "cr")))
          (add-after 'remove-prebuilt-executable 'fix-ctype-include
            (lambda _
              ;; GCC 14 no longer permits the implicit declarations used by
              ;; this old C99 source file.
              (substitute* "src/mdport.c"
                (("#include \"mdport.h\"")
                 "#include \"mdport.h\"\n#include <ctype.h>"))))
          (add-after 'fix-ctype-include 'fix-panel-cleanup-order
            (lambda _
              ;; ncurses panels retain their WINDOW pointer.  The upstream
              ;; order frees each window before its panel, which segfaults
              ;; with current ncurses when the initial help screen closes.
              (substitute* "src/io.c"
                (("delwin\\(help_win\\);") "")
                (("del_panel\\(help_panel\\);")
                 "del_panel(help_panel);\n\tdelwin(help_win);")
                (("delwin\\(highscore_win\\);") "")
                (("del_panel\\(highscore_panel\\);")
                 "del_panel(highscore_panel);\n\tdelwin(highscore_win);"))))
          (replace 'build
            (lambda _
              ;; Calling make directly avoids configure's wget-based optional
              ;; dependency bootstrap.  SDL=0 selects the ncurses path.
              (invoke "make" "CC=gcc" "SDL=0")))
          (replace 'install
            (lambda _
              (use-modules (rnrs io ports))
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/cryptrover"))
                     (program (string-append libexec "/cryptrover"))
                     (launcher (string-append bin "/cryptrover"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                ;; Keep the rebuilt program private to the launcher.  This
                ;; prevents scores.dat from ever being created in the store.
                (install-file "cr" libexec)
                (rename-file (string-append libexec "/cr") program)
                (install-file "README" doc)
                (install-file "COPYING" doc)
                ;; mdport.c is separately BSD-3-Clause licensed.  Preserve
                ;; its complete notice, copied from the source file, without
                ;; installing the unused bundled PDCurses headers.
                (let* ((text (call-with-input-file "src/mdport.c"
                               get-string-all))
                       (start (string-contains text
                                                "Copyright (C) 2005"))
                       (end (string-contains text "*/" start)))
                  (call-with-output-file (string-append doc
                                                        "/BSD-3-Clause.txt")
                    (lambda (port)
                      (display "Notice copied from src/mdport.c:\n\n" port)
                      (display (substring text start (+ end 2)) port))))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\n" shell)
                    (display "set -eu\n" port)
                    (format port
                            "program=~s\nscript=~s\ncp=~s\ndirname=~s\n"
                            program script cp dirname)
                    (format port "mkdir=~s\nmktemp=~s\nterminfo=~s\n"
                            mkdir mktemp terminfo)
                    (format port "sleep=~s\n" sleep)
                    (format port "shell=~s\n" shell)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n"
                      "run_game() {\n"
                      "  state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}/cryptrover\"\n"
                      "  \"$mkdir\" -p \"$state\"\n"
                      "  cd \"$state\"\n"
                      "  exec \"$program\" \"$@\"\n"
                      "}\n")
                     port)
                    (display "if test \"${1:-}\" = --smoke; then\n" port)
                    (display "  test \"$#\" -eq 1 || { echo " port)
                    (display
                     "'usage: cryptrover [--smoke]' >&2; exit 64; }\n"
                     port)
                    (display "  scratch=$(\"$mktemp\" -d" port)
                    (display
                     " \"${TMPDIR:-/tmp}/cryptrover-smoke.XXXXXXXX\")\n"
                     port)
                    (display
                     "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\""
                     port)
                    (display " \"$scratch/data\"\n" port)
                    (display
                     "  \"$mkdir\" -p \"$scratch/cache\" \"$scratch/state\""
                     port)
                    (display " \"$scratch/runtime\" \"$scratch/work\"\n"
                             port)
                    (display "  export HOME=\"$scratch/home\"\n" port)
                    (display
                     "  export XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display
                     "  export XDG_DATA_HOME=\"$scratch/data\"\n" port)
                    (display
                     "  export XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display
                     "  export XDG_STATE_HOME=\"$scratch/state\"\n" port)
                    (display
                     "  export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display
                     "  export TERM=xterm-256color LC_ALL=C SHELL=\"$shell\"\n"
                     port)
                    (display "  state=\"$scratch/state/cryptrover\"\n" port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  cd \"$state\"\n" port)
                    (display "  raw=\"$scratch/work/terminal.raw\"\n" port)
                    ;; md_readchar waits briefly after ESC to distinguish it
                    ;; from a cursor sequence, so keep ESC separate from the
                    ;; two space keys that dismiss the loss screens.
                    (display "  {\n" port)
                    (display "    printf '?.'\n" port)
                    (display "    \"$sleep\" 1\n" port)
                    (display "    printf '\\033'\n" port)
                    (display "    \"$sleep\" 2\n" port)
                    (display "    printf '  '\n" port)
                    (display "    \"$sleep\" 1\n" port)
                    (display "  } | \"$script\" -qefc \"$program\"" port)
                    (display
                     " \"$raw\" >\"$scratch/work/script.stdout\"\n" port)
                    (display "  test -s \"$raw\"\n" port)
                    (display "  test -s \"$state/scores.dat\"\n" port)
                    (display
                     "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n"
                     port)
                    (display "    capture_dir=$(\"$dirname\"" port)
                    (display
                     " \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\n" port)
                    (display "    \"$mkdir\" -p \"$capture_dir\"\n" port)
                    (display "    \"$cp\" \"$raw\"" port)
                    (display
                     " \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    (display "  printf '%s\\n' CRYPTROVER_RUNTIME_OK\n" port)
                    (display "  exit 0\n" port)
                    (display "fi\n" port)
                    (display "run_game \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal ncurses util-linux))
    (home-page "https://code.google.com/p/cryptrover/")
    (synopsis "Terminal dungeon survival game")
    (description
     "CryptRover is a terminal dungeon game in which an archaeologist must
survive twelve crypt levels with a limited air supply.  This package builds
the fixed no-sound source archive from C99 sources with ncurses, omits the
archive's prebuilt executable and network-fetching configure path, and keeps
scores in an XDG state directory behind a launcher.  The launcher provides a
deterministic isolated @code{--smoke} mode for the installed terminal game.")
    (license (list license:gpl3+ license:bsd-3))))
