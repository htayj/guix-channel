;;; GNU Guix package for Save Scummer, a Seven Day Roguelike by Jeff Lait.
;;;
;;; The fixed upstream archive bundles prebuilt Linux, Windows, and Mac
;;; programs, Microsoft runtime DLLs, SDL.dll, PDCurses import libraries, and
;;; bitmap fonts.  None of those files is used: the build compiles only the
;;; C++ sources for the curses port and installs the text database and the
;;; public-domain room pieces.
;;;
;;; LICENSE.TXT grants BSD-style redistribution of every .cpp, .h, and .txt
;;; file, puts the .map files in the public domain, and carries the complete
;;; MT19937 notice for mt19937ar.c.  Nine sources (ai.cpp, avatar.cpp,
;;; avatar.h, dpdf.cpp, dpdf.h, mapdata.cpp, mapdata.h, worldstate.cpp, and
;;; worldstate.h) keep a stale "PROPRIETARY INFORMATION ... POWDER
;;; Development" file header from the author's template; the archive-wide
;;; LICENSE.TXT by the same author covers them.

(define-module (tay packages savescummer)
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

(define %savescummer-smoke
  (local-file (search-tay-package-file "savescummer-smoke.sh")))

(define-public savescummer
  (package
    (name "savescummer")
    ;; savescummer002 of 2007-04-08 is the homepage's most recent release.
    (version "002")
    (source
     (origin
       (method url-fetch)
       ;; www.zincland.com serves a certificate for another host name, so the
       ;; homepage's own HTTP link is the canonical location.
       (uri (string-append "http://www.zincland.com/7drl/savescummer/savescummer"
                           version ".tar.gz"))
       ;; SHA-256: 793cc9cc9d486a22709714ba20d73826656083f829e2c5f2d6d3aa4074bf0ace
       (sha256
        (base32 "1khapxs41anksvrcbqi9z21n0r9673bj1fhljxq24sj8kp6cjg3r"))
       (patches
        (search-patches "tay/packages/patches/savescummer-curses-build.patch"))
       (modules '((guix build utils)))
       (snippet
        ;; Remove the prebuilt executables and libraries, the bitmap fonts,
        ;; and the SDL and Windows ports, which are not built.
        #~(for-each delete-file-recursively
                    '("linux" "linux_curses" "windows" "windows_curses" "mac"
                      "gfx" "src/gfx" "src/wincurses" "src/winport"
                      "src/gfx_sdl.cpp" "src/gfx_sdl.h")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated tests.  savescummer --smoke plays, saves,
      ;; and reloads a real game in PTYs; tests/savescummer-smoke.sh runs it.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; enummaker generates glbdef.cpp and glbdef.h from source.txt.
              (invoke "make" "-C" "src/support/enummaker" "CXX=g++")
              (invoke "make" "-C" "src/linuxport" "premake")
              (invoke "make" "-C" "src/linuxport"
                      (string-append "CXX=" #$(cxx-for-target))
                      (string-append "SAVESCUMMER_DATADIR=" #$output
                                     "/share/savescummer"))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/savescummer"))
                     (data (string-append out "/share/savescummer"))
                     (doc (string-append out "/share/doc/savescummer"))
                     (launcher (string-append bin "/savescummer"))
                     (smoke (string-append libexec "/savescummer-smoke"))
                     (shell #$(file-append bash-minimal "/bin/sh")))
                (install-file "src/linuxport/savescummer" libexec)
                (install-file "src/text.txt" data)
                (install-file "rooms/piecelist.map"
                              (string-append data "/rooms"))
                ;; LICENSE.TXT carries the BSD notice for the game, the
                ;; complete MT19937 notice for mt19937ar.c, and the public
                ;; domain dedication of the maps.
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "README.TXT"))
                (mkdir-p bin)
                ;; The game reads its data from the store and writes only
                ;; savescummer.sav and hiscore.txt, relative to its working
                ;; directory.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    ;; The smoke program rejects any further arguments.
                    (format port
                            (string-append
                             "if test \"${1-}\" = --smoke; then~%"
                             "  shift~%"
                             "  exec ~a \"$@\"~%"
                             "fi~%")
                            smoke)
                    (display
                     (string-append
                      "case \"${XDG_STATE_HOME:-}\" in\n"
                      "  /*) state=\"$XDG_STATE_HOME/savescummer\" ;;\n"
                      "  *) state=\"${HOME:?HOME or XDG_STATE_HOME must be set}"
                      "/.local/state/savescummer\" ;;\n"
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
                    (format port "exec ~a/savescummer \"$@\"~%" libexec)))
                (copy-file #$%savescummer-smoke smoke)
                (substitute* smoke
                  (("@SHELL@") shell)
                  (("@COREUTILS@") #$coreutils-minimal)
                  (("@DIFFUTILS@") #$diffutils)
                  (("@UTIL_LINUX@") #$util-linux)
                  (("@OUT@") out))
                (chmod launcher #o555)
                (chmod smoke #o555)))))))
    (inputs (list bash-minimal coreutils-minimal diffutils ncurses util-linux))
    (home-page "http://www.zincland.com/7drl/savescummer/")
    (synopsis "Seven Day Roguelike played by rewinding and restoring saves")
    (description
     "Save Scummer is a terminal roguelike written as a Seven Day Roguelike.
The hero moves on its own; the player advances time, rewinds it turn by turn,
and keeps ten backup save slots to scum the odds of survival, which the game
tracks as a running probability.  This package builds the curses port from
source and omits the prebuilt programs, the SDL port, and its bitmap fonts.
The @command{savescummer} launcher keeps the saved game and high scores in
@file{$XDG_STATE_HOME/savescummer}, or below @file{~/.local/state/savescummer}
when @env{XDG_STATE_HOME} is unset.  The game needs an 80-column terminal with
at least 30 lines.  @command{savescummer --smoke} plays, saves, and reloads a
game in disposable pseudo-terminal sessions.")
    (license (list (license:non-copyleft "file://LICENSE.TXT"
                                         "See LICENSE.TXT in the distribution.")
                   license:public-domain))))
