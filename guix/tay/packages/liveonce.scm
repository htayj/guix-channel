;;; GNU Guix package for You Only Live Once, a Seven Day Roguelike.
;;;
;;; The fixed upstream archive bundles prebuilt Linux and Windows programs,
;;; Microsoft runtime DLLs, SDL.DLL, PDCurses import libraries, and
;;; alphabet*.bmp fonts.  Upstream's LICENSE.TXT calls the fonts screen
;;; captures of standard fonts with unclear licensing.  None of those files is
;;; used: the build compiles only the BSD-licensed C++ sources for the curses
;;; port and installs the public-domain maps and the text database.

(define-module (tay packages liveonce)
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

(define %liveonce-smoke
  (local-file (search-tay-package-file "liveonce-smoke.sh")))

(define-public liveonce
  (package
    (name "liveonce")
    ;; The homepage names 005 "the most recent version".
    (version "005")
    (source
     (origin
       (method url-fetch)
       ;; www.zincland.com serves a certificate for another host name, so the
       ;; homepage's own HTTP link is the canonical location.
       (uri (string-append "http://www.zincland.com/7drl/liveonce/liveonce"
                           version ".tar.gz"))
       ;; SHA-256: 412652e41364a921d1440630d7acf59e63ece5e00fb6de62e0ccd8363d867ee2
       (sha256
        (base32 "1qkyhqykdn6cw1idxdhgw3jyqqwyynndfc068k8j3ab42gj549j1"))
       (patches
        (search-patches "tay/packages/patches/liveonce-curses-build.patch"))
       (modules '((guix build utils)))
       (snippet
        ;; Remove the prebuilt executables and libraries, the unclearly
        ;; licensed bitmap fonts, and the SDL port, which is not built.
        #~(for-each delete-file-recursively
                    '("linux" "linux_curses" "windows" "windows_curses"
                      "src/gfx" "src/wincurses"
                      "src/gfx_sdl.cpp" "src/gfx_sdl.h")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated tests.  bin/liveonce-smoke plays and
      ;; reloads a real game in a PTY; tests/liveonce-smoke.sh runs it.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The archive has no top-level directory.
              (mkdir "liveonce")
              (chdir "liveonce")
              (invoke "tar" "xf" source)))
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; enummaker generates glbdef.cpp and glbdef.h from source.txt.
              (invoke "make" "-C" "src/support/enummaker" "CXX=g++")
              (invoke "make" "-C" "src/linuxport" "premake")
              (invoke "make" "-C" "src/linuxport"
                      (string-append "CXX=" #$(cxx-for-target))
                      (string-append "LIVEONCE_DATADIR=" #$output
                                     "/share/liveonce"))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/liveonce"))
                     (data (string-append out "/share/liveonce"))
                     (doc (string-append out "/share/doc/liveonce"))
                     (launcher (string-append bin "/liveonce"))
                     (smoke (string-append bin "/liveonce-smoke"))
                     (shell #$(file-append bash-minimal "/bin/sh")))
                (install-file "src/linuxport/liveonce" libexec)
                (for-each (lambda (file) (install-file file data))
                          '("src/text.txt" "src/rooms/valley.map"
                            "src/rooms/piecelist.map"))
                ;; LICENSE.TXT carries the BSD notice for the game, the
                ;; complete MT19937 notice for mt19937ar.c, and the public
                ;; domain dedication of the maps.
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "README.TXT"))
                (mkdir-p bin)
                ;; The game reads its data from the store and writes only
                ;; valley.sav, relative to its working directory.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    (display
                     (string-append
                      "case \"${XDG_DATA_HOME:-}\" in\n"
                      "  /*) state=\"$XDG_DATA_HOME/liveonce\" ;;\n"
                      "  *) state=\"${HOME:?HOME or XDG_DATA_HOME must be set}"
                      "/.local/share/liveonce\" ;;\n"
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
                    (format port "exec ~a/liveonce \"$@\"~%" libexec)))
                (copy-file #$%liveonce-smoke smoke)
                (substitute* smoke
                  (("@SHELL@") shell)
                  (("@COREUTILS@") #$coreutils-minimal)
                  (("@UTIL_LINUX@") #$util-linux)
                  (("@OUT@") out))
                (chmod launcher #o555)
                (chmod smoke #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses util-linux))
    (home-page "http://www.zincland.com/7drl/liveonce/")
    (synopsis "Seven Day Roguelike about a village's successive heroes")
    (description
     "You Only Live Once is a terminal roguelike written for the 2005 Seven
Day Roguelike challenge.  When the current villager dies, play continues as
the next inhabitant of the mountain valley.  This package builds the curses
port from source and omits the prebuilt programs, the SDL port, and its bitmap
fonts.  The @command{liveonce} launcher keeps the saved game in
@file{$XDG_DATA_HOME/liveonce/valley.sav}, or below
@file{~/.local/share/liveonce} when @env{XDG_DATA_HOME} is unset.  The game
needs an 80-column terminal with at least 30 lines.
@command{liveonce-smoke} saves and reloads a game in a disposable
pseudo-terminal session.")
    (license (list (license:non-copyleft "file://LICENSE.TXT"
                                         "See LICENSE.TXT in the distribution.")
                   license:public-domain))))
