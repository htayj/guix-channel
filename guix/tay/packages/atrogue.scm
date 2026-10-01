;;; GNU Guix package for Atrogue.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages atrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses))

(define-public atrogue
  (package
    (name "atrogue")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://sourceforge/atrogue/atrogue/atrogue-"
                           version "/atrogue-" version ".tar.gz"))
       (sha256
        (base32
         "16bra4vnzrdqcwipck8m7sxp2xh0p704lc0zr502hnnsayrlg617"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; itchconfig is not GNU configure; the classical Makefile is supported
      ;; upstream.  Its clean/config/object prerequisites require serial make.
      #:tests? #f                    ; No upstream test target.
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'terminate-direction-string
            (lambda _
              ;; All 32 entries were filling the fixed-size array, omitting
              ;; the NUL required by strchr for non-movement commands.
              (substitute* "stuff.c"
                (("static const char str\\[4 \\* 8\\]")
                 "static const char str[]"))))
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; Public inline helpers use GNU89 linkage semantics.
              (invoke "make" "devel"
                      #$(string-append "CC=" (cc-for-target))
                      "CFLAGS=-O2 -g -std=gnu89")))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (private (string-append #$output "/libexec/atrogue"))
                     (doc (string-append #$output "/share/doc/atrogue"))
                     (launcher (string-append bin "/atrogue")))
                (install-file "atrogue" private)
                (install-file "docu/atrogue.6"
                              (string-append #$output "/share/man/man6"))
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "README" "INSTALL"))
                (copy-recursively "docu" (string-append doc "/docu"))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\numask 077\n"
                            #$(file-append bash-minimal "/bin/bash"))
                    (display
                     (string-append
                      "state=${XDG_DATA_HOME:-${HOME:?'HOME or "
                      "XDG_DATA_HOME must be set'}/.local/share}/atrogue\n")
                     port)
                    (format port "~a -p -- \"$state\"\n"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    ;; get_homepath rejects absolute HOME paths over 50 bytes.
                    ;; A private cwd and relative HOME avoid that fallback and
                    ;; keep its fixed-size filename/message buffers bounded.
                    (display "cd -- \"$state\"\nexport HOME=.\n" port)
                    (format port "exec ~a \"$@\"\n"
                            (string-append private "/atrogue"))))
                (chmod launcher #o555)))))))
    (inputs (list ncurses bash-minimal coreutils-minimal))
    (home-page "http://atrogue.sourceforge.net/")
    (synopsis "Terminal roguelike with configurable dungeon exploration")
    (description
     "Atrogue is a curses-based roguelike with randomly generated dungeons,
character roles, magic, combat, and configurable exploration preferences.
The launcher confines optional message logs and native text screenshots to
@file{$XDG_DATA_HOME/atrogue}, falling back to
@file{$HOME/.local/share/atrogue}.  Logging remains disabled by default.
The upstream release does not implement saving or loading a dungeon; quitting
ends the current game.")
    (license license:gpl3+)))
