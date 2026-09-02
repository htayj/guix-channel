;;; GNU Guix package for initrl's CutlassRL.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages cutlassrl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages python))

;; No release tags exist.  This is the fixed master tip containing upstream
;; VERSION 0.05, fetched from the canonical repository's commit archive.
(define %cutlassrl-commit
  "304bb87fc185726f3f7afb08c69564687003d093")

(define-public cutlassrl
  (package
    (name "cutlassrl")
    (version "0.05-0.304bb87")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/stenno/CutlassRL/archive/"
             %cutlassrl-commit ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 16d8da09eb1af649931fbdb5d34051395c4c89328b594f24e325d37494f35716
       ;; Guix's (base32 ...) origin literal uses Nix-base32 (05jpy...),
       ;; while the same digest in ordinary RFC 4648 base32 is c3mn....
       (sha256
        (base32
         "05jpyfa79lr5wcj4yncb6a4lqp1ra50d7ddx3y9lkxhsxc4xmn0n"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; CutlassRL has no configure, build, test, or install system.  Its
      ;; Python source is installed unchanged under a private runtime root.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (delete 'check)
          (delete 'install-license-files)
          ;; Keep the upstream Python 2 shebang and invoke the declared
          ;; interpreter explicitly from the store-safe launcher below.
          (delete 'patch-source-shebangs)
          (add-after 'unpack 'enter-source
            (lambda _
              (chdir "CutlassRL/src")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (root (string-append out "/libexec/cutlassrl"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/cutlassrl"))
                     (program (string-append root "/main.py"))
                     (launcher (string-append bin "/cutlassrl"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     ;; Guix currently exposes its Python 2.7 package as
                     ;; python-2 (the package name is python2).
                     (python #$(file-append python-2 "/bin/python2"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (script #$(file-append util-linux "/bin/script")))
                (mkdir-p root)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "main.py" root)
                (install-file "Game.py" root)
                (copy-recursively "Modules" (string-append root "/Modules"))
                (copy-recursively "Levels" (string-append root "/Levels"))
                ;; The source and UniCurses modules carry GPL notices; keep
                ;; the complete GPLv3 text next to the installed source.
                (install-file "COPYING" root)
                (install-file "../README" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port
                            "program=~s\npython=~s\nscript=~s\n"
                            program python script)
                    (format port
                            "cat=~s\ncp=~s\ndirname=~s\nmkdir=~s\n"
                            cat cp dirname mkdir)
                    (format port "mktemp=~s\nrm=~s\nshell=~s\n"
                            mktemp rm shell)
                    (display
                     "if test \"${1-}\" = \"--smoke\"; then\n"
                     port)
                    (display
                     "  test \"$#\" -eq 1 || { echo 'usage: cutlassrl [--smoke]' >&2; exit 64; }\n"
                     port)
                    (display
                     "  scratch=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/cutlassrl-smoke.XXXXXXXX\")\n"
                     port)
                    (format port "  trap '~a -rf \"$scratch\"' EXIT HUP INT TERM\n"
                            rm)
                    (display
                     (string-append
                      "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\" "
                      "\"$scratch/data\" \"$scratch/cache\" "
                      "\"$scratch/state\" \"$scratch/runtime\" "
                      "\"$scratch/tmp\" \"$scratch/work\"\n"
                      "  export HOME=\"$scratch/home\"\n"
                      "  export XDG_CONFIG_HOME=\"$scratch/config\"\n"
                      "  export XDG_DATA_HOME=\"$scratch/data\"\n"
                      "  export XDG_CACHE_HOME=\"$scratch/cache\"\n"
                      "  export XDG_STATE_HOME=\"$scratch/state\"\n"
                      "  export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n"
                      "  export TMPDIR=\"$scratch/tmp\"\n"
                      "  export TERM=xterm-256color LC_ALL=C SHELL=\"$shell\"\n"
                      "  export PYTHONDONTWRITEBYTECODE=1\n"
                      "  state=\"$XDG_DATA_HOME/cutlassrl\"\n"
                      "  \"$mkdir\" -p \"$state\"\n"
                      "  test ! -w \"$program\"\n"
                      "  cd \"$state\"\n"
                      "  first=\"$scratch/work/first.raw\"\n"
                      "  second=\"$scratch/work/second.raw\"\n"
                      "  first_error=\"$scratch/work/first.error\"\n"
                      "  second_error=\"$scratch/work/second.error\"\n"
                      "  command=\"$python $program Goocastle\"\n"
                      "  if ! printf 'ls' | \"$script\" -qefc \"$command\" \"$first\" > /dev/null 2>\"$first_error\"; then\n"
                      "    \"$cat\" \"$first_error\" >&2 || true\n"
                      "    echo 'cutlassrl smoke: first game failed' >&2\n"
                      "    exit 1\n"
                      "  fi\n"
                      "  test -s \"$first\"\n"
                      "  test -s \"$state/Goocastle.sav\"\n"
                      "  if ! printf 'q!' | \"$script\" -qefc \"$command\" \"$second\" > /dev/null 2>\"$second_error\"; then\n"
                      "    \"$cat\" \"$second_error\" >&2 || true\n"
                      "    echo 'cutlassrl smoke: save load game failed' >&2\n"
                      "    exit 1\n"
                      "  fi\n"
                      "  test -s \"$second\"\n"
                      "  loaded=\"$(\"$cat\" \"$second\")\"\n"
                      "  case \"$loaded\" in\n"
                      "    *Loaded...*) ;;\n"
                      "    *) echo 'cutlassrl smoke: save was not loaded' >&2; exit 1 ;;\n"
                      "  esac\n"
                      "  test ! -e \"$state/Goocastle.sav\"\n"
                      "  test -s \"$state/mainlog.log\"\n"
                      "  log=\"$(\"$cat\" \"$state/mainlog.log\")\"\n"
                      "  case \"$log\" in\n"
                      "    *name=Goocastle*) ;;\n"
                      "    *) echo 'cutlassrl smoke: mainlog.log has no player name' >&2; exit 1 ;;\n"
                      "  esac\n"
                      "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n"
                      "    \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"\n"
                      "    \"$cp\" \"$second\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n"
                      "  fi\n"
                      "  printf '%s\\n' CUTLASSRL_RUNTIME_OK\n"
                      "  exit 0\n")
                     port)
                    (display
                     "fi\nstate=\"${XDG_DATA_HOME:-${HOME:?HOME must be set}/.local/share}/cutlassrl\"\n\"$mkdir\" -p \"$state\"\ncd \"$state\"\nexec \"$python\" \"$program\" \"$@\"\n"
                     port)))
                (chmod launcher #o555)))))))
    ;; Python 2.7 is exposed as python-2 by the current Guix channel.
    (inputs (list bash-minimal coreutils-minimal python-2 util-linux))
    (home-page "https://github.com/stenno/CutlassRL")
    (synopsis "Python terminal roguelike")
    (description
     "CutlassRL is an unfinished Python 2 terminal roguelike by initrl.  It
is built from a fixed upstream commit without a configure or build system,
runtime downloads, or opaque platform binaries.  The installed Python source,
level data, and GPLv3 license are kept under a private libexec directory.  The
store-safe launcher runs the game from @file{$XDG_DATA_HOME/cutlassrl}, falling
back to @file{$HOME/.local/share/cutlassrl}, and its package-owned
@option{--smoke} mode drives the real curses game through a PTY to verify
movement, save/load, and logging in isolated temporary state.")
    (license license:gpl3+)))
