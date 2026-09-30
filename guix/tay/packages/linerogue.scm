;;; GNU Guix package for Chris Morris's LineRogue.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages linerogue)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bdw-gc)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages tls))

;; LineRogue is written in Kaya.  Reuse the channel's pinned, source-built
;; Kaya 0.4.4 compiler and runtime, which is private to chessrogue.scm, rather
;; than maintaining a second copy of that historical GHC 8.4 bootstrap.
(define kaya-for-linerogue
  (module-ref (resolve-module '(tay packages chessrogue))
              'kaya-for-chessrogue))

;; Installed below libexec and reachable only through 'linerogue --smoke'.
;; It plays the real game through the public launcher in a PTY.
(define %linerogue-smoke
  (local-file (search-tay-package-file "linerogue-smoke.py")))

(define-public linerogue
  (package
    (name "linerogue")
    (version "2")
    (source
     (origin
       (method url-fetch)
       ;; The author's Durham homepage is gone; this is the Internet
       ;; Archive's unmodified ("id_") capture of the release archive.
       (uri (string-append
             "https://web.archive.org/web/20070328170218id_/"
             "http://compsoc.dur.ac.uk/~cim/linerogue/linerogue2-src.tgz"))
       (file-name "linerogue2-src.tgz")
       (sha256
        (base32 "02gz14s1sdqiv2s1dp2w5c6rqh5frjqgzp3f3sfi553mdmd9ngxv"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The archive is nine Kaya modules without a build system or tests.
      ;; 'linerogue --smoke' plays the installed game in an isolated PTY;
      ;; tests/linerogue-smoke.sh runs it.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (add-after 'unpack 'adapt-to-kaya-0.4.4
            (lambda _
              ;; This release predates Kaya 0.4.4's contrib/Kayurses.k, which
              ;; renamed the WeightName constructors Bold and Normal to Heavy
              ;; and Light.  Every Bold and Normal token in these modules is
              ;; such a constructor; no other identifier contains them.
              (substitute* '("Creature.k" "CreatureData.k" "Player.k"
                             "World.k" "WorldData.k" "main.k")
                (("Bold") "Heavy")
                (("Normal") "Light"))
              ;; Kaya 0.4.4's Time module calls the wall clock now().
              (substitute* "main.k"
                (("lfSrand\\(time\\(\\)\\)") "lfSrand(now())"))))
          (replace 'build
            (lambda _
              ;; Kaya otherwise embeds fresh /dev/urandom-derived secrets in
              ;; each executable.  Its documented seed mode keeps this build
              ;; reproducible.
              (setenv "LC_ALL" "C")
              (invoke "kayac" "main.k" "-force" "-nortchecks"
                      "-seedkey" "linerogue-2")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec/linerogue"))
                     (doc (string-append #$output "/share/doc/linerogue"))
                     (program (string-append libexec "/linerogue"))
                     (smoke (string-append libexec "/linerogue-smoke"))
                     (launcher (string-append bin "/linerogue"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (terminfo #$(file-append ncurses "/share/terminfo"))
                     (site-packages
                      (lambda (package)
                        (car (find-files package "^site-packages$"
                                         #:directories? #t)))))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                ;; Keep the compiled game private; the launcher owns its HOME.
                (install-file "linerogue" libexec)
                (copy-file #$%linerogue-smoke smoke)
                (substitute* smoke
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod smoke #o555)
                (for-each (lambda (file) (install-file file doc))
                          '("README" "COPYING" "GPL-2" "COPYING.pcre"))
                ;; The executable statically includes Kaya's LGPL runtime,
                ;; standard library and contrib modules.
                (copy-recursively
                 (string-append #$kaya-for-linerogue "/share/doc/kaya-0.4.4")
                 (string-append doc "/kaya"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port "launcher=~s\nprogram=~s\nsmoke=~s\n"
                            launcher program smoke)
                    (format port "python=~s\noutput=~s\nmkdir=~s\n"
                            python #$output mkdir)
                    (format port "pyte=~s\nwcwidth=~s\n"
                            (site-packages #$python-pyte)
                            (site-packages #$python-wcwidth))
                    (format port "terminfo=~s\n" terminfo)
                    (display "\
export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"
if test \"${1-}\" = --smoke; then
  test \"$#\" -eq 1 || { echo 'usage: linerogue [--smoke]' >&2; exit 64; }
  exec \"$python\" \"$smoke\" \"$launcher\" \"$output\" \"$pyte\" \"$wcwidth\"
fi
test \"$#\" -eq 0 || { echo 'usage: linerogue [--smoke]' >&2; exit 64; }
# The game keeps its high-score table in $HOME/.linerogue.
data_home=\"${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME must be set}/.local/share}\"
state=\"$data_home/linerogue\"
\"$mkdir\" -p \"$state\"
cd \"$state\"
export HOME=\"$state\"
export TERM=\"${TERM:-xterm-256color}\"
exec \"$program\"
" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list kaya-for-linerogue gcc-toolchain))
    ;; Kaya does not propagate its C-library inputs.  Keep every library used
    ;; by the generated curses executable explicit in this consumer.
    (inputs (list bash-minimal coreutils-minimal gmp gnutls libgcrypt libgc
                  ncurses pcre python-minimal python-pyte python-wcwidth
                  zlib))
    (home-page (string-append
                "https://web.archive.org/web/20070328170218id_/"
                "http://compsoc.dur.ac.uk/~cim/linerogue/"))
    (synopsis "Turn-based terminal bike roguelike")
    (description
     "LineRogue is Chris Morris's turn-based ASCII game in which the player
steers a bike through ten levels of enemy vehicles, trails and lasers to reach
and destroy a giant brain.  This package builds the version 2 source release
with the channel's private Kaya 0.4.4 compiler.  The launcher keeps the
high-score table under @env{XDG_DATA_HOME}/linerogue, falling back to
@file{~/.local/share/linerogue}, and provides an isolated @option{--smoke}
mode that plays the game through a pseudo-terminal.")
    (license (list license:gpl2+ license:lgpl2.1+ license:bsd-3))))
