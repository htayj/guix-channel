;;; GNU Guix package for Letter Hunt, a Seven Day Roguelike by Jeff Lait.
;;;
;;; The fixed upstream archive bundles prebuilt Linux and Windows programs,
;;; Microsoft runtime DLLs, SDL.dll, PDCurses import libraries, and
;;; alphabet*.bmp fonts.  Upstream's LICENSE.TXT calls the fonts screen
;;; captures of standard fonts with unclear licensing.  None of those files is
;;; used: the build compiles only the BSD-licensed C++ sources for the curses
;;; port and installs the text database, the public-domain room pieces, and
;;; the public-domain Moby word list.

(define-module (tay packages letter-hunt)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

(define %letter-hunt-smoke
  (local-file (search-tay-package-file "letter-hunt-smoke.sh")))

(define-public letter-hunt
  (package
    (name "letter-hunt")
    ;; letterhunt002 is the homepage's "Bug fix Release" of 2006-10-24, the
    ;; most recent version.
    (version "002")
    (source
     (origin
       (method url-fetch)
       ;; www.zincland.com serves a certificate for another host name, so the
       ;; homepage's own HTTP link is the canonical location.
       (uri (string-append "http://www.zincland.com/7drl/letterhunt/letterhunt"
                           version ".tar.gz"))
       ;; SHA-256: c53398658812dc6aa9300748f5fa0f89665d692ee15dafa8af464ff08a6f5059
       (sha256
        (base32 "0nahdy5g0ks6mylaypg15rlmsrl91zxgaj0762lnmp0ji1jrhcy5"))
       (patches
        (search-patches "tay/packages/patches/letter-hunt-curses-build.patch"))
       (modules '((guix build utils)))
       (snippet
        ;; Remove the prebuilt executables and libraries, the unclearly
        ;; licensed bitmap fonts, and the SDL port, which is not built.
        #~(for-each delete-file-recursively
                    '("linux" "linux_curses" "windows" "windows_curses"
                      "gfx" "src/gfx" "src/wincurses"
                      "src/gfx_sdl.cpp" "src/gfx_sdl.h")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated tests.  letter-hunt --guix-smoke plays and
      ;; reloads a real game in PTYs; tests/letter-hunt-smoke.sh runs it.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The archive has no top-level directory.
              (mkdir "letterhunt")
              (chdir "letterhunt")
              (invoke "tar" "xf" source)))
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; enummaker generates glbdef.cpp and glbdef.h from source.txt.
              (invoke "make" "-C" "src/support/enummaker" "CXX=g++")
              (invoke "make" "-C" "src/linuxport" "premake")
              (invoke "make" "-C" "src/linuxport"
                      (string-append "CXX=" #$(cxx-for-target))
                      (string-append "LETTERHUNT_DATADIR=" #$output
                                     "/share/letter-hunt"))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/letter-hunt"))
                     (data (string-append out "/share/letter-hunt"))
                     (doc (string-append out "/share/doc/letter-hunt"))
                     (launcher (string-append bin "/letter-hunt"))
                     (smoke (string-append libexec "/letter-hunt-smoke"))
                     (shell #$(file-append bash-minimal "/bin/sh")))
                (install-file "src/linuxport/letterhunt" libexec)
                (install-file "src/text.txt" data)
                (install-file "rooms/piecelist.map"
                              (string-append data "/rooms"))
                (install-file "wordlist/wordlist.txt"
                              (string-append data "/wordlist"))
                ;; LICENSE.TXT carries the BSD notice for the game, the
                ;; complete MT19937 notice for mt19937ar.c, and the public
                ;; domain dedications of the maps and the Moby word list.
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "README.TXT"))
                (mkdir-p bin)
                ;; The game reads its data from the store and writes only
                ;; letterhunt.sav and hiscore.txt, relative to its working
                ;; directory.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    ;; The smoke program rejects any further arguments.
                    (format port
                            (string-append
                             "if test \"${1-}\" = --guix-smoke; then~%"
                             "  shift~%"
                             "  exec ~a \"$@\"~%"
                             "fi~%")
                            smoke)
                    (display
                     (string-append
                      "case \"${XDG_STATE_HOME:-}\" in\n"
                      "  /*) state=\"$XDG_STATE_HOME/letter-hunt\" ;;\n"
                      "  *) state=\"${HOME:?HOME or XDG_STATE_HOME must be set}"
                      "/.local/state/letter-hunt\" ;;\n"
                      "esac\n")
                     port)
                    (format port "~a -p \"$state\"~%"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display "cd \"$state\"\n" port)
                    (format port
                            (string-append
                             "export TERMINFO_DIRS=\"~a"
                             "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            #$(file-append ncurses "/share/terminfo"))
                    (format port "exec ~a/letterhunt \"$@\"~%" libexec)))
                (copy-file #$%letter-hunt-smoke smoke)
                (substitute* smoke
                  (("@SHELL@") shell)
                  (("@COREUTILS@") #$coreutils-minimal)
                  (("@DIFFUTILS@") #$diffutils)
                  (("@UTIL_LINUX@") #$util-linux)
                  (("@OUT@") out))
                (chmod launcher #o555)
                (chmod smoke #o555)))))))
    (inputs (list bash-minimal coreutils-minimal diffutils ncurses util-linux))
    (home-page "http://www.zincland.com/7drl/letterhunt/")
    (synopsis "Seven Day Roguelike about spelling words with captured letters")
    (description
     "Letter Hunt is a terminal roguelike written as a Seven Day Roguelike.
The monsters are letters; capturing them in the right order spells words from
a plain-text word list, which earns points and temporary power-ups.  There is
no final goal: the game ends when the attrition of ever harder letters wears
the hero down.  This package builds the curses port from source and omits the
prebuilt programs, the SDL port, and its bitmap fonts.  The
@command{letter-hunt} launcher keeps the saved game and high scores in
@file{$XDG_STATE_HOME/letter-hunt}, or below @file{~/.local/state/letter-hunt}
when @env{XDG_STATE_HOME} is unset.  The game needs an 80-column terminal with
at least 30 lines.  @command{letter-hunt --guix-smoke} saves and reloads a game
in disposable pseudo-terminal sessions.")
    (license (list (license:non-copyleft "file://LICENSE.TXT"
                                         "See LICENSE.TXT in the distribution.")
                   license:public-domain))))
