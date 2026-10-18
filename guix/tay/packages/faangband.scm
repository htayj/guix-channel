;;; FAangband -- First Age Angband, with free graphics and sound.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages faangband)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages xorg))

(define %faangband-commit
  "7ad7178b5da5819fe1a2d13182001b5bf6e9eaac")

(define-public faangband
  (package
    (name "faangband")
    (version "2.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/NickMcConnell/FAangband/tar.gz/"
             %faangband-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256 of the 25,292,997-byte codeload archive, not a Git NAR:
       ;; 6b521b077f385dc49bee435e6a84c8a54f53920a0d7b1db3908f744d63f2d997
       (sha256
        (base32 "15yry9ilsx4gj2risyqd1a956kx5r226lpj3xsdw8p9qgw3inlkb"))
       (modules '((guix build utils) (ice-9 rdelim) (srfi srfi-13)))
       (snippet
        #~(begin
            ;; Remove the restricted artwork before repacking the source,
            ;; not merely from the installed output.  Keep all other tiles.
            (delete-file-recursively "lib/tiles/shockbolt")
            (substitute* "lib/tiles/Makefile"
              ((" old shockbolt") " old"))
            ;; list.txt is a record-oriented file: remove complete records
            ;; 5 and 6, including every associated directory/size/pref/extra.
            (let ((lines
                   (call-with-input-file "lib/tiles/list.txt"
                     (lambda (port)
                       (let loop ((line (read-line port)) (keep? #t) (out '()))
                         (if (eof-object? line)
                             (reverse out)
                             (let ((keep? (if (string-prefix? "name:" line)
                                              (not (or (string-prefix? "name:5:" line)
                                                       (string-prefix? "name:6:" line)))
                                              keep?)))
                               (loop (read-line port) keep?
                                     (if keep? (cons line out) out)))))))))
              (call-with-output-file "lib/tiles/list.txt"
                (lambda (port)
                  (for-each (lambda (line) (display line port) (newline port))
                            lines))))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "--with-private-dirs"
              "--enable-curses" "--enable-x11"
              "--enable-sdl2" "--enable-sdl2-mixer"
              ;; Scripted input is a build check, not an installed frontend.
              "--disable-test"
              (string-append "--bindir=" #$output "/libexec")
              (string-append "--sysconfdir=" #$output "/share")
              (string-append "--localstatedir=" #$output "/var")
              ;; sdl2-config only describes SDL itself.  The extension
              ;; headers live in separate inputs, each below include/SDL2.
              (string-append "CPPFLAGS=-I" #$sdl2-image "/include/SDL2"
                             " -I" #$sdl2-ttf "/include/SDL2"
                             " -I" #$sdl2-mixer "/include/SDL2"))
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 popen)
                  (ice-9 rdelim)
                  (ice-9 regex))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'bootstrap
            (lambda _
              ;; The codeload tree has no configure.  autogen.sh uses
              ;; aclocal (Automake), autoheader and autoconf, not Libtool.
              (invoke "sh" "autogen.sh")))
          (add-after 'unpack 'stamp-release-and-desktop-paths
            (lambda _
              ;; Use scripts/version.sh's snapshot fallback, without Git or
              ;; build-machine dates.  This also fixes the displayed build ID.
              (call-with-output-file "version"
                (lambda (port) (display #$version port) (newline port)))
              (substitute* "lib/icons/faangband-sdl.desktop"
                (("-msdl") "-msdl2")
                (("Name=FAangband \\(SDL\\)") "Name=FAangband (SDL2)"))
              (substitute* '("lib/icons/faangband-sdl.desktop"
                             "lib/icons/faangband-x11.desktop")
                (("Exec=faangband ")
                 (string-append "Exec=" #$output "/bin/faangband "))
                (("TryExec=faangband")
                 (string-append "TryExec=" #$output "/bin/faangband"))
                (("/usr/share/faangband/xtra/icon/att-32.png")
                 (string-append #$output "/share/faangband/icons/att-32.png")))))
          (add-after 'unpack 'preserve-directory-option-paths
            (lambda _
              ;; Split the option at its first '=' only.  strtok discarded
              ;; the rest of valid HOME/XDG paths containing another '='.
              (substitute* "src/main.c"
                (("\tpath = strtok\\(info_copy, \"=\"\\);")
                 (string-append
                  "\tpath = info_copy;\n"
                  "\tdir = strchr(path, '=');\n"
                  "\tif (!dir || !dir[1])\n"
                  "\t\tquit_fmt(\"Try '-d<dir>=<path>'.\", info);\n"
                  "\t*dir++ = '\\0';"))
                (("\tdir = strtok\\(NULL, \"=\"\\);") ""))))
          (add-after 'configure 'prepare-upstream-check-build
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Unit tests use compiled DEFAULT_* paths, and their SDL
                ;; test stub only handles SOUND_SDL, not SOUND_SDL2.  Use
                ;; upstream's standalone test configuration, not patched
                ;; tests or fake sound functions in the production build.
                ;; Copy before compilation; do not copy production objects.
                (mkdir-p "upstream-check")
                (for-each
                 (lambda (file)
                   (copy-recursively file (string-append "upstream-check/" file)))
                 '("src" "mk" "m4" "scripts" "tests" "Makefile"
                   "configure.ac" "acinclude.m4" "install-sh" "config.guess"
                   "config.sub" "version" "run-tests" "configure"))
                ;; Avoid duplicating the sound and graphics asset archive.
                (symlink "../lib" "upstream-check/lib"))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let ((home (string-append (getcwd) "/upstream-check-home")))
                  (mkdir-p home)
                  (setenv "HOME" home)
                  (setenv "GUIX_LOCPATH"
                          #$(file-append glibc-utf8-locales "/lib/locale"))
                  (setenv "LC_ALL" "en_US.utf8")
                  ;; Unlike the standard configure phase, this standalone
                  ;; invocation must supply Autoconf's internal shell too.
                  ;; Running "sh configure" alone leaves SHELL=/bin/sh for
                  ;; config.sub and config.status inside the build sandbox.
                  (setenv "CONFIG_SHELL" (which "sh"))
                  (with-directory-excursion "upstream-check"
                    ;; --with-no-install makes DEFAULT_* point at this
                    ;; directory's lib symlink.  No output staging is needed.
                    (invoke "sh" "configure" "--with-no-install"
                            "--enable-test" "--disable-curses" "--disable-x11"
                            "--disable-sdl" "--disable-sdl2"
                            "--disable-sdl-mixer" "--disable-sdl2-mixer"
                            ;; Upstream expands ~ via getpwuid, not HOME.
                            ;; Its existing config.h guard accepts an explicit
                            ;; private base for this check configuration only.
                            ;; Keep the quotes through Make's shell evaluation
                            ;; so the compiler sees a C string literal.
                            (string-append "CPPFLAGS=-DPRIVATE_USER_PATH='\""
                                           home "\"'"))
                    (invoke "make" "-C" "src")
                    ;; The pinned Perl harness can exit zero after failed
                    ;; assertions.  Keep its real output and also require a
                    ;; nonempty all-passed total; do not relax any assertion.
                    ;; src/Makefile exports the configured flags, but not CC.
                    ;; Its independent tests/Makefile otherwise defaults to
                    ;; the unavailable "cc"; a command-line CC reaches both
                    ;; recursive makes without replacing their flags.
                    (let ((port (open-pipe* OPEN_READ "make" "-C" "src"
                                             "tests" "CC=gcc"))
                          (passed? #f))
                      (let loop ((line (read-line port)))
                        (unless (eof-object? line)
                          (display line) (newline) (force-output)
                          (let* ((plain
                                  (regexp-substitute/global
                                   #f (string-append (string (integer->char 27))
                                                      "\\[[0-9;]*m")
                                   line 'pre "" 'post))
                                 (match
                                  (string-match
                                   "^Total: ([0-9]+)/([0-9]+) passed" plain)))
                            (when match
                              (let ((pass (string->number (match:substring match 1)))
                                    (total (string->number (match:substring match 2))))
                                (set! passed? (and (> total 0) (= pass total))))))
                          (loop (read-line port))))
                      (let ((status (close-pipe port)))
                        (unless (and (zero? status) passed?)
                          (error "FAangband upstream unit tests failed" status))))
                    ;; This is upstream's scripted frontend and expected
                    ;; output/matcher suite, not native UI acceptance.
                    (invoke "sh" "run-tests" "src/faangband"))))))
          (delete 'install-license-files)
          (add-after 'install 'install-launcher-and-notices
            (lambda _
              (let* ((data (string-append #$output "/share/faangband"))
                     (doc (string-append #$output "/share/doc/faangband"))
                     (launcher (string-append #$output "/bin/faangband")))
                (mkdir-p (dirname launcher))
                (copy-file
                 #$(local-file (search-tay-package-file "files/faangband-launcher.sh"))
                 launcher)
                (substitute* launcher
                  (("#!/bin/sh") (string-append "#!" #$bash-minimal "/bin/sh"))
                  (("@MKDIR@") #$(file-append coreutils-minimal "/bin/mkdir"))
                  (("@CP@") #$(file-append coreutils-minimal "/bin/cp"))
                  (("@TERMINFO@") #$(file-append ncurses "/share/terminfo"))
                  (("@DATA@") data)
                  (("@GAME@") (string-append #$output "/libexec/faangband")))
                (chmod launcher #o555)
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "changes.txt" "docs/copying.rst"
                            "docs/thanks.rst"))
                (copy-file
                 #$(local-file (search-tay-package-file "files/faangband-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES"))
                ;; Preserve exact component copyright/redistribution clauses
                ;; and the WELL attribution, including their original text.
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/component-notices")))
                 '("src/message.c" "src/message.h" "src/sound.h" "src/snd-sdl.h"
                   "src/z-textblock.c" "src/z-textblock.h" "src/z-rand.c"
                   "src/z-util.c"))
                (install-file "lib/readme.txt" doc)
                (for-each
                 (lambda (file)
                   (install-file (string-append data "/icons/" file)
                                 (string-append #$output "/share/applications")))
                 '("faangband-x11.desktop" "faangband-sdl.desktop"))))))))
    (native-inputs (list autoconf automake glibc-utf8-locales perl))
    (inputs (list bash-minimal coreutils-minimal ncurses libx11
                  sdl2 sdl2-image sdl2-ttf sdl2-mixer))
    (home-page "https://github.com/NickMcConnell/FAangband")
    (synopsis "First Age Angband roguelike with graphical and terminal frontends")
    (description
     "FAangband is a roguelike set in Tolkien's First Age, with wilderness,
multiple towns, races, classes, persistent characters, and procedural dungeons.
This source build retains curses, X11, SDL2, sound, fonts, and the Original,
Nomad, Adam Bolt, and David Gervais tiles.  Only the restricted Shockbolt tiles
are omitted.  The launcher keeps mutable player data below
@file{$XDG_DATA_HOME/faangband}, with @file{$HOME/.local/share} as fallback,
and uses immutable store paths for game assets.  Upstream C unit tests and
scripted game tests are run as build checks in a separate test configuration.")
    ;; GPL version 2 only, not "or later", per copying.rst and source headers.
    ;; Original/Nomad/icons use that umbrella grant, not an invented exception.
    ;; Adam Bolt's any-purpose grant is recorded verbatim in copying.rst.
    ;; Sound uses the rights holder's explicit 2023-12-23 CC BY 4.0 update;
    ;; retain the pinned historical NC notice alongside the dated explanation.
    (license
     (list license:gpl2 license:bsd-2 license:public-domain
           license:cc-by3.0 license:cc-by4.0
           (license:fsdg-compatible
            (string-append
             "https://github.com/NickMcConnell/FAangband/blob/"
             %faangband-commit "/docs/copying.rst")
            (string-append
             "Adam Bolt's graphics may be redistributed and used for any "
             "purpose, with or without modification."))))))
