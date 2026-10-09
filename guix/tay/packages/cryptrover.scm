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
      ;; The upstream tree has no test target.
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
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
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
                    (format port "program=~s\nmkdir=~s\nterminfo=~s\n"
                            program mkdir terminfo)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n"
                      "state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}/cryptrover\"\n"
                      "\"$mkdir\" -p \"$state\"\n"
                      "cd \"$state\"\n"
                      "exec \"$program\" \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://code.google.com/archive/p/cryptrover/")
    (properties '((upstream-name . "cryptrover")))
    (synopsis "Terminal dungeon survival game")
    (description
     "CryptRover is a terminal dungeon game in which an archaeologist must
survive twelve crypt levels with a limited air supply.  This package builds
the fixed no-sound source archive from C99 sources with ncurses, omits the
archive's prebuilt executable and network-fetching configure path, and keeps
scores in an XDG state directory behind a launcher.  The launcher runs the
native game directly in the player's terminal.")
    (license (list license:gpl3+ license:bsd-3))))
