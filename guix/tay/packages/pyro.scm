;;; GNU Guix package for Eric Burgess's historical Pyro roguelike.
;;; SPDX-License-Identifier: MIT

(define-module (tay packages pyro)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python))

(define-public pyro
  (package
    (name "pyro")
    (version "0.04a")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://downloads.sourceforge.net/project/pyrogue/pyro/"
             version "/pyro-" version "-source.zip"))
       (file-name (string-append name "-" version "-source.zip"))
       ;; This source-only release contains exactly the same 16 source files
       ;; as pyro/source in the Windows release.  The research's 81451f8d...
       ;; digest belongs to pyro-0.04a.zip, NOT pyro-0.04a-source.zip.
       ;; Source-only SHA-256:
       ;; 74dfcbdf5b1624c4b347058b14e88c0f7483152d4c729667e81bc44c1c5f5b7c
       (sha256
        (base32 "0z2vbwf4ri0vx1krcwjc5laq6x0gikl192q58yrw890nbggwppvl"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; There is no upstream test suite.  setup.py and install.nsi are
      ;; Windows packaging instructions, not an installation/build system.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'install-license-files)
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The source-only ZIP is flat, with no containing directory.
              (mkdir "source")
              (chdir "source")
              (invoke "unzip" "-q" source)))
          (delete 'patch-source-shebangs)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (root (string-append out "/libexec/pyro"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/pyro"))
                     (launcher (string-append bin "/pyro")))
                ;; Retain the full original licensed source, including the
                ;; inert Windows packaging recipes.  No Windows binaries or
                ;; bundled interpreter are present in the source-only ZIP.
                (copy-recursively "." root)
                (mkdir-p bin)
                (for-each (lambda (file) (install-file file doc))
                          '("pyro-license.txt" "readme.txt"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh\nset -eu\n" #$bash-minimal)
                    (format port "python=~s\nprogram=~s\nmkdir=~s\nterminfo=~s\n"
                            #$(file-append python-2 "/bin/python2")
                            (string-append root "/pyro.py")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            (string-append #$ncurses "/share/terminfo"))
                    (display
                     (string-append
                      "test \"$#\" -eq 0 || { echo 'usage: pyro' >&2; exit 64; }\n"
                      "state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}/pyro\"\n"
                      "case \"$state\" in /*) ;; *) echo "
                      "'Pyro requires an absolute state directory' >&2; "
                      "exit 64 ;; esac\n"
                      "umask 077\n"
                      "\"$mkdir\" -p \"$state\"\n"
                      "cd \"$state\"\n"
                      ;; Keep custom terminal entries and append our fallback.
                      "export TERMINFO_DIRS=\"${TERMINFO_DIRS:+"
                      "$TERMINFO_DIRS:}$terminfo\"\n"
                      ;; -B prohibits store bytecode writes; -E and -s avoid
                      ;; accidental host Python/Psyco dependencies.
                      "exec \"$python\" -B -E -s \"$program\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal coreutils-minimal ncurses python-2))
    (home-page "https://sourceforge.net/projects/pyrogue/")
    (synopsis "Python curses dungeon-crawling roguelike")
    (description
     "Pyro is a turn-based dungeon-crawling roguelike by Eric Burgess.
This package preserves the complete original Python 2 source release and
its MIT notice.  The game uses the standard-library curses interface and
requires no external assets or network access.  The launcher supplies a
terminal database and runs from @file{$XDG_STATE_HOME/pyro}, defaulting to
@file{$HOME/.local/state/pyro}, so the game's native @file{pyro.log} is
writable without modifying the installed source.  This alpha release does
not implement saved games; its log is replaced on each launch.")
    ;; install.nsi retains Philip Chu / Technicat's zlib-style grant verbatim.
    (license (list license:expat license:zlib))))
