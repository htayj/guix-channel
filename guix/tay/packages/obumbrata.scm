;;; Obumbrata et Velata, Martin Read's 2014 Seven Day Roguelike entry.

(define-module (tay packages obumbrata)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl))

(define-public obumbrata
  (package
    (name "obumbrata")
    ;; Published release, corresponding to tag 1.0.0 / 7drl-2014 at
    ;; c2f5361f63deeed1c7415f742dfa83f90d0ce699.  The later development tip
    ;; e4860dc7c2a8beac5ad9d04cb8377a4f58e3c6b is not a published release.
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       ;; Upstream does not serve HTTPS (connection refused, 2026-10-03).
       (uri (string-append
             "http://www.blackswordsonics.com/martin/obumbrata/obumbrata_"
             version ".tar.gz"))
       ;; SHA-256: 253d6250d2378fe91f15ea92ef9c9ad5c7f967bada7778ee8955bb2c8eacac47
       (sha256
        (base32 "0ixcmj72rfsmi7p7hxysp9kzkiymkaffz4pa2lgyk3rps9864g95"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; There is no upstream test target.  The external ordinary-executable
      ;; consumer tests/obumbrata-smoke.sh exercises native moves and restores.
      #:tests? #f
      ;; Each Perl generator emits two files with an ordinary multi-target
      ;; rule; running these concurrently would invoke a generator twice.
      #:parallel-build? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "CXX=" #$(cxx-for-target))
              "DEVELOPMENT_CFLAGS=$(PRODUCTION_CFLAGS)"
              "DEVELOPMENT_CXXFLAGS=$(PRODUCTION_CXXFLAGS)"
              "DEVELOPMENT_LDFLAGS=$(COMMON_LDFLAGS)")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'fix-build-source
            (lambda _
              ;; The release accidentally joins PATCHVERS=0 to -std=gnu11.
              (substitute* "Makefile"
                (("\\$\\(PATCHVERS\\)-std=gnu11")
                 "$(PATCHVERS) -std=gnu11"))
              ;; map.hh declares std::vector parameters.  Modern libstdc++
              ;; no longer happens to expose vector through its deque header.
              (substitute* "map.hh"
                (("#include <deque>")
                 "#include <deque>\n#include <vector>"))
              ;; Guix's ncurses is wide-character but installs these headers
              ;; directly under include, not Debian's ncursesw subdirectory.
              (substitute* "display-nc.cc"
                (("<ncursesw/curses.h>") "<curses.h>")
                (("<ncursesw/panel.h>") "<panel.h>")
                ;; iscntrl needs its owning header.  Keep curses special keys
                ;; and ERR outside the ctype call's unsigned-char domain.
                (("#include <langinfo.h>")
                 "#include <langinfo.h>\n#include <ctype.h>")
                (("if \\(\\(ch > 127\\)\\)")
                 "if ((ch < 0) || (ch > 127))"))
              ;; log.cc names std::string, and rng.cc allocates with malloc;
              ;; neither declaration belongs to their existing headers.
              (substitute* "log.cc"
                (("#include <map>") "#include <map>\n#include <string>"))
              (substitute* "rng.cc"
                (("#include <time.h>") "#include <time.h>\n#include <stdlib.h>"))))
          (replace 'configure
            (lambda _
              ;; This is a bundled Perl script, not an Autoconf configure.
              (invoke "perl" "configure"
                      (string-append "--prefix=" #$output)
                      (string-append "--gamesdir=" #$output "/libexec"))))
          (delete 'install-license-files)
          (add-after 'install 'install-notices-and-launcher
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (doc (string-append #$output "/share/doc/obumbrata"))
                     (launcher (string-append bin "/obumbrata")))
                ;; All shipped code, generator data, notes and the man page
                ;; are project-authored; no fonts, tiles or sounds are bundled.
                (install-file "COPYING" doc)
                (install-file "notes.txt" doc)
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port
                            (string-append
                             "export TERMINFO_DIRS=~s"
                             "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            #$(file-append ncurses "/share/terminfo"))
                    ;; Keep upstream libxdg-basedir HOME/XDG persistence and
                    ;; every ordinary native UI path.  No installed proof mode.
                    (format port "exec ~a/libexec/obumbrata \"$@\"~%" #$output)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain perl))
    (inputs (list bash-minimal ncurses libxdg-basedir))
    (home-page "http://www.blackswordsonics.com/martin/obumbrata/")
    (synopsis "Shadow-realm terminal roguelike")
    (description
     "Obumbrata et Velata is a terminal roguelike made for the 2014 Seven
Day Roguelike Challenge.  A princess, demon hunter or thanatophile explores
an unfair shadow realm.  The game uses wide-character curses and saves
locally through the XDG base-directory conventions.  This package builds
the published release from its C and C++ sources and bundled Perl data
generators, and retains the complete BSD redistribution notices.")
    (license license:bsd-2)))
