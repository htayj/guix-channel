;;; GNU Guix package for RapidBrogue.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages rapidbrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages sdl))

(define %gpl3-text
  (origin
    (method url-fetch)
    (uri "https://www.gnu.org/licenses/gpl-3.0.txt")
    (file-name "GPL-3.0.txt")
    (sha256
     (base32 "11k9nggwk1mgsrkdwgdjz65avrradxlpdgrdkc7ryjgn8jbxqwir"))))

(define %cc-by-sa4-text
  (origin
    (method url-fetch)
    (uri "https://creativecommons.org/licenses/by-sa/4.0/legalcode.txt")
    (file-name "CC-BY-SA-4.0.txt")
    (sha256
     (base32 "1x8wzmizbpb8cx392x9g0mx29vqn7mm12p5zyi8xrd0bgnf55a98"))))

(define-public rapidbrogue
  (package
    (name "rapidbrogue")
    (version "1.4.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/flend/RapidBrogue")
             (commit "02e6715fd81c4c9da1546943700da7b2b3ed482a")))
       (file-name (git-file-name name version))
       ;; Verified with guix hash -rx on the rapid_brogue-v1.4.0 checkout,
       ;; excluding Git metadata.  BulletBrogue is a different release line.
       (sha256
        (base32 "1j8qs94zgdf0rrn5j99r97q20xg27iivl5m27wnlga0iknzb9rhh"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; This release has neither a check target nor a shipped test suite.
      ;; The separate channel proof drives real gameplay and save restoration.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              (invoke "make"
                      "CC=gcc"
                      "RELEASE=YES"
                      "TERMINAL=YES"
                      "GRAPHICS=YES"
                      "WEBBROGUE=NO"
                      "MAC_APP=NO"
                      "RAPIDBROGUE=YES"
                      (string-append "CPPFLAGS=-I"
                                     #$(file-append sdl2-image "/include/SDL2"))
                      (string-append "DATADIR=" #$output "/share/rapidbrogue")
                      "bin/brogue")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/rapidbrogue"))
                     (doc (string-append out "/share/doc/rapidbrogue"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/rapidbrogue"))
                     (launcher (string-append bin "/rapidbrogue")))
                (mkdir-p data)
                (mkdir-p doc)
                (mkdir-p libexec)
                (mkdir-p bin)
                (install-file "bin/brogue" libexec)
                (rename-file (string-append libexec "/brogue") program)
                ;; Keep the complete upstream graphical resource set,
                ;; including the precomputed tile shifts.  With tiles.bin
                ;; present initTiles does not regenerate a cache in DATADIR.
                (copy-recursively "bin/assets" (string-append data "/assets"))
                (install-file "bin/keymap.txt" data)
                (for-each (lambda (file) (install-file file doc))
                          '("BUILD.md" "README.md" "CHANGELOG.md"
                            "LICENSE.txt"))
                (install-file "bin/assets/LICENSE.txt"
                              (string-append doc "/assets"))
                (copy-file #$%gpl3-text (string-append doc "/GPL-3.0.txt"))
                (copy-file #$%cc-by-sa4-text
                           (string-append doc "/CC-BY-SA-4.0.txt"))
                ;; These upstream headers retain the author attributions and
                ;; exact AGPL/GPL grants in addition to the full license texts.
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/source-notices")))
                 '("src/brogue/Rogue.h" "src/brogue/Dijkstra.c"
                   "src/platform/PlatformDefines.h"
                   "src/platform/platformdependent.c"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (format port "program=~s~%data=~s~%keymap=~s~%"
                            program data (string-append data "/keymap.txt"))
                    (format port "cp=~s~%mkdir=~s~%terminfo=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append ncurses "/share/terminfo"))
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-${HOME:?"
                      "HOME or XDG_STATE_HOME must be set}/.local/state}\"\n")
                     port)
                    ;; Upstream reads the keymap and writes saves, recordings,
                    ;; high scores and native screenshots relative to cwd.
                    (display "state=\"$state_root/rapidbrogue\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$state/keymap.txt\"\nfi\n" port)
                    (display
                     (string-append "export TERMINFO_DIRS=\"$terminfo"
                                    "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "cd \"$state\"\n" port)
                    ;; SDL remains the upstream default; -t selects ncurses.
                    ;; Do not replace the game with a package-owned smoke mode.
                    (display "exec \"$program\" \"$@\" --data-dir \"$data\"\n" port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses sdl2 sdl2-image))
    (home-page "https://github.com/flend/RapidBrogue")
    (synopsis "Ten-level rapid variant of the Brogue roguelike")
    (description
     "RapidBrogue compresses Brogue Community Edition into ten levels,
with the Amulet on level six, a faster difficulty curve and strengthened
magic items.  It retains the original SDL interface with text, tile and
hybrid graphics and an optional ncurses frontend.  The complete upstream
tile atlas, embedded glyphs, tile cache and icon are installed.  The launcher
keeps the editable keymap, saves, recordings, high scores and screenshots
in an XDG state directory while using immutable packaged resources.
No updater, telemetry or runtime downloads are used.")
    ;; The engine is AGPL-3.0-or-later; the legacy platform files explicitly
    ;; grant GPL-3.0-or-later.  tiles.png (including its embedded glyphs) and
    ;; derived tiles.bin use the asset directory's CC BY-SA 4.0 notice.
    ;; The icon, keymap and documentation are covered by the root license.
    (license (list license:agpl3+ license:gpl3+ license:cc-by-sa4.0))))
