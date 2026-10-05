;;; GNU Guix package for Brogue Community Edition.

(define-module (tay packages brogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages sdl))

(define-public brogue
  (package
    (name "brogue")
    (version "1.15.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/tmewett/BrogueCE")
             (commit "1ba4240b7a928ddf0ffb772717bf1d433cd63804")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the tracked v1.15.1 tag tree.  Git metadata is
       ;; excluded from this value.
       (sha256
        (base32 "031qj38vnsjgc9qjkkqa8z6z3vkfm5zx2djk25hdrash31l37s3b"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream regression harness refers to recording directories that
      ;; are not shipped in this release.  Keep the available upstream seed
      ;; catalog comparisons as a separate build phase instead.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'omit-unlicensed-window-icon
            (lambda _
              ;; No license covers upstream's icon.png.  Do not install it or
              ;; retain its mandatory load: SDL's normal default window icon
              ;; leaves the licensed dungeon tiles and native renderer intact.
              (substitute* "src/platform/tiles.c"
                (("^        // set its icon\n")
                 "        // The unlicensed window icon is omitted.\n")
                (("^        char filename\\[BROGUE_FILENAME_MAX\\];\n") "")
                (((string-append "^        sprintf\\(filename, "
                                 "\"%s/assets/icon.png\", dataDirectory\\);\n"))
                 "")
                (("^        SDL_Surface \\*icon = IMG_Load\\(filename\\);\n") "")
                (("^        if \\(!icon\\) imgfatal\\(__FILE__, __LINE__\\);\n") "")
                (("^        SDL_SetWindowIcon\\(Win, icon\\);\n") "")
                (("^        SDL_FreeSurface\\(icon\\);\n") ""))))
          (replace 'build
            (lambda _
              (invoke "make"
                      "CC=gcc"
                      "RELEASE=YES"
                      "GRAPHICS=YES"
                      "TERMINAL=YES"
                      (string-append "CPPFLAGS=-I"
                                     #$(file-append sdl2-image "/include/SDL2"))
                      (string-append "DATADIR=" #$output "/share/brogue")
                      "bin/brogue")))
          (add-after 'build 'check-seed-catalogs
            (lambda _
              ;; The upstream comparison helper writes its generated catalog
              ;; in the current directory and expects ./brogue.  Run it from
              ;; a copy so the source checkout remains a clean test input.
              (let* ((source (getcwd))
                     (copy (string-append source "-seed-catalog-check")))
                (copy-recursively source copy)
                (chdir copy)
                (copy-file "bin/brogue" "brogue")
                (chmod "brogue" #o555)
                (invoke #$(file-append python "/bin/python3")
                        "test/compare_seed_catalog.py"
                        "test/seed_catalogs/seed_catalog_brogue.txt"
                        "40")
                (invoke #$(file-append python "/bin/python3")
                        "test/compare_seed_catalog.py"
                        "test/seed_catalogs/seed_catalog_rapid_brogue.txt"
                        "10"
                        "--extra_args=--variant rapid_brogue"))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/brogue"))
                     (assets (string-append data "/assets"))
                     (doc (string-append out "/share/doc/brogue"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/brogue"))
                     (launcher (string-append bin "/brogue")))
                (mkdir-p assets)
                (mkdir-p doc)
                (mkdir-p libexec)
                (mkdir-p bin)
                ;; Keep the binary immutable and private to the wrapper.  The
                ;; program receives the immutable data directory explicitly.
                ;; install-file takes a destination directory, so place the
                ;; executable directly in libexec rather than creating a
                ;; directory named after it.
                (install-file "bin/brogue" libexec)
                (for-each (lambda (file)
                            (install-file file assets))
                          '("bin/assets/tiles.png" "bin/assets/tiles.bin"))
                (install-file "bin/keymap.txt" data)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("README.md" "CHANGELOG.md" "LICENSE.txt"))
                (install-file "bin/assets/LICENSE.txt"
                              (string-append doc "/assets"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%"
                            #$bash-minimal)
                    (format port "program=~s~%data=~s~%keymap=~s~%"
                            program data (string-append data "/keymap.txt"))
                    (format port "cp=~s~%mkdir=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display "state=\"${XDG_STATE_HOME:-" port)
                    (display "${HOME:?HOME or XDG_STATE_HOME must be set}/.local/" port)
                    (display "state}/brogue\"\n" port)
                    ;; Always append the immutable path so an argument cannot
                    ;; redirect the graphical resource lookup elsewhere.
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$state/keymap.txt\"\n" port)
                    (display "fi\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "exec \"$program\" \"$@\" --data-dir \"$data\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list diffutils gcc-toolchain python))
    (inputs (list bash-minimal coreutils-minimal ncurses sdl2 sdl2-image))
    (home-page "https://github.com/tmewett/BrogueCE")
    (synopsis "Turn-based dungeon exploration game")
    (description
     "Brogue Community Edition is a minimalist turn-based dungeon exploration
game.  This package builds the fixed upstream source with both its graphical
SDL2 frontend and its ncurses terminal frontend.  The launcher keeps saves,
recordings, scores, run history, and diagnostics in an XDG state directory,
copies the user-editable keymap there, and passes the immutable packaged asset
directory explicitly to the binary.  The web frontend is not built and the
package performs no updater, telemetry, runtime-download, or network action.")
    ;; The engine and variants carry AGPL-3.0-or-later; the platform files
    ;; explicitly carry GPL-3.0-or-later.  tiles.png and its derived cache are
    ;; covered by bin/assets/LICENSE.txt under CC BY-SA 4.0.
    (license (list license:agpl3+ license:gpl3+ license:cc-by-sa4.0))))
