;;; GNU Guix package for Hydra Slayer from the NotEye repository.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hydra-slayer)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python))

(define %hydra-slayer-commit
  "55bb69d716a9fb269c6364f9df89d4bc260cb1a1")

(define hydra-slayer-smoke-script
  (local-file "hydra-slayer-smoke.py"))

(define-public hydra-slayer
  (package
    (name "hydra-slayer")
    (version "18.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/zenorogue/noteye")
             (commit %hydra-slayer-commit)))
       (file-name (git-file-name name version))
       ;; SHA-256 of the fixed GitHub archive used to validate this source:
       ;; 41ec5986e75684ba026afcc2a80235915adbf24f598bae14e62f7457cb8b4f24
       ;; git-fetch uses the normalized checkout digest:
       (sha256
        (base32
         "1ql0h077pnskr4whpk9sm0i154cz52akhmnc9p8rqd5143kkwhj1"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream tree has no test target.  The installed launcher and its
      ;; package-owned save/load proof are exercised by the channel smoke test.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; This is the standalone console build documented by the
              ;; upstream Makefile; it excludes NotEye's graphical frontend.
              ;; Guix's ncurses library is named libncurses, while the
              ;; upstream Makefile uses the historical libcurses alias.
              (substitute* "hydra/Makefile"
                (("-lcurses") "-lncurses"))
              (invoke "make" "-C" "hydra" "hydra")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/hydra-slayer"))
                     (smoke (string-append libexec
                                           "/hydra-slayer-smoke.py"))
                     (real (string-append libexec "/hydra"))
                     (launcher (string-append bin "/hydra"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python "/bin/python3"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "hydra/hydra" libexec)
                (copy-file #$hydra-slayer-smoke-script smoke)
                (chmod smoke #o555)
                (install-file "LICENSE" doc)
                (rename-file (string-append doc "/LICENSE")
                             (string-append doc "/COPYING"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a~%set -eu~%real=~s~%smoke=~s~%"
                             "python=~s~%mkdir=~s~%terminfo=~s~%")
                            shell real smoke python mkdir terminfo)
                    (display "export PYTHONDONTWRITEBYTECODE=1\n" port)
                    (display (string-append
                             "export TERMINFO_DIRS=\"$terminfo"
                             "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                             port)
                    (display (string-append
                             "state_root=\"${XDG_STATE_HOME:-"
                             "${HOME:?HOME or XDG_STATE_HOME must be set}"
                             "/.local/state}/hydra-slayer\"\n")
                             port)
                    (display "\"$mkdir\" -p \"$state_root\"\n" port)
                    (display "if test \"${1-}\" = --guix-smoke; then\n" port)
                    (display (string-append
                             "  test \"$#\" -eq 1 || { echo "
                             "'usage: hydra [--guix-smoke]' >&2; "
                             "exit 64; }\n")
                             port)
                    (display "  exec \"$python\" \"$smoke\" --binary \"$real\"\n" port)
                    (display "fi\n" port)
                    (display "cd \"$state_root\"\n" port)
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (inputs
     (list bash-minimal coreutils-minimal ncurses python))
    (home-page "https://github.com/zenorogue/noteye")
    (synopsis "Console roguelike about cutting Hydra heads")
    (description
     "Hydra Slayer is a standalone console roguelike in which the player
cuts heads from regenerating hydras.  This package builds the Hydra console
game from the fixed NotEye repository revision using its ncurses-only
Makefile, and does not install the unrelated NotEye frontend or its graphical
and audio assets.  The launcher stores the game's default files below
@file{$XDG_STATE_HOME/hydra-slayer} (or the corresponding directory below
@file{$HOME}), while preserving the upstream command-line arguments.  Its
@option{--guix-smoke} mode drives two real PTY sessions to verify new-game,
turn, save, load, and isolated state behavior without network access.  The
complete upstream GPL notice is installed with the executable.")
    (license license:gpl3+)))
