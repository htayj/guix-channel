;;; Umoria -- the maintained restoration of the original Moria.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages umoria)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses))

(define-public umoria
  (package
    (name "umoria")
    (version "5.7.15")
    (source
     (origin
       (method git-fetch)
       ;; Independently verified annotated v5.7.15 peeled commit.
       (uri (git-reference
             (url "https://github.com/dungeons-of-moria/umoria")
             (commit "624a051dd368d19e86cc0c0908d658a7876809b3")))
       (file-name (git-file-name name version))
       ;; Original tag archive SHA-256:
       ;; 97f76a68b856dd5df37c20fc57c8a51017147f489e8ee8866e1764778b2e2d57
       (sha256
        (base32 "0hr90nbnvdrpr3j4zv20wgk8mz7w6lwh5ajf6grw8lgp9n810gnn"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ;No upstream automated tests/CTest target.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'separate-immutable-data-and-user-state
            (lambda _
              (let ((doc (string-append #$output "/share/doc/umoria")))
                (for-each (lambda (file) (install-file file doc))
                          '("AUTHORS" "LICENSE" "README.md" "CHANGELOG.md"))
                (copy-recursively "historical" (string-append doc "/historical"))
                (call-with-output-file (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display
                     "Umoria 5.7.15: GNU GPL version 3 or later.
AUTHORS and CHANGELOG.md document the 2008 relicense and 5.7.15 correction;
AUTHORS retains historical GPLv2 and public-domain contributor credits.
Code, generated ASCII help/splash/death data, and historical documentation
come from the same source release.  No fonts, tiles, sounds, bundled libraries
or prebuilt executables are installed.  CMake generates version/date text
from version.h and the fixed 2021-06-02 CHANGELOG entry.
Ncurses is a separate source-built Guix dependency under the X11 license;
its license is retained by that package.  The launcher uses separate Guix
Bash and GNU Coreutils packages under their own GPL licenses.
" port))))
              (substitute* "src/config.cpp"
                (("namespace files \\{")
                 (string-append
                  "namespace files {\n        const char *state_directory = "
                  "std::getenv(\"UMORIA_STATE_DIRECTORY\");"))
                (("\"data/([^\"]+)\"" _ file)
                 (string-append "\"" #$output "/share/umoria/data/" file "\""))
                (("license = \"LICENSE\"")
                 (string-append "license = \"" #$output "/share/umoria/LICENSE\""))
                (("scores = \"scores.dat\"")
                 (string-append
                  "scores = std::string(state_directory ? state_directory"
                  " : \".\") + \"/scores.dat\""))
                (("save_game = \"game.sav\"")
                 (string-append
                  "save_game = std::string(state_directory ? state_directory"
                  " : \".\") + \"/game.sav\"")))
              ;; AUTHORS/CHANGELOG establish GPL-3.0-or-later; fix the stale
              ;; command-line banner without changing any gameplay options.
              (substitute* "src/main.cpp"
                (("released under a GPL v2 license")
                 "released under a GPL-3.0-or-later license"))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/umoria"))
                     (doc (string-append #$output "/share/doc/umoria"))
                     (libexec (string-append #$output "/libexec/umoria"))
                     (bin (string-append #$output "/bin"))
                     (launcher (string-append bin "/umoria")))
                ;; Upstream CMake generates versioned splash/help and has no
                ;; install target.  Install its complete staged data closure.
                (copy-recursively "umoria/data" (string-append data "/data"))
                (for-each (lambda (file) (install-file file data))
                          '("umoria/AUTHORS" "umoria/LICENSE" "umoria/scores.dat"))
                (install-file "umoria/umoria" libexec)
                (for-each (lambda (file) (install-file file doc))
                          '("umoria/AUTHORS" "umoria/LICENSE"))
                (mkdir-p bin)
                (copy-file #$(local-file
                              (search-tay-package-file
                               "files/umoria-launcher.sh")) launcher)
                (substitute* launcher
                  (("#!/bin/sh") (string-append "#!" #$bash-minimal "/bin/sh"))
                  (("@MKDIR@") (string-append #$coreutils-minimal "/bin/mkdir"))
                  (("@CP@") (string-append #$coreutils-minimal "/bin/cp"))
                  (("@CHMOD@") (string-append #$coreutils-minimal "/bin/chmod"))
                  (("@DATA@") data)
                  (("@GAME@") (string-append libexec "/umoria")))
                (chmod launcher #o555))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file (if (or (file-is-directory? file) (access? file X_OK))
                                 #o555 #o444)))
               (find-files #$output ".*" #:directories? #t))
              (chmod #$output #o555))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://umoria.org/")
    (synopsis "Classic Moria terminal dungeon exploration game")
    (description
     "Umoria is the maintained restoration of Robert Alan Koeneke's Moria,
with character races and classes, spells, shops, randomized dungeons, monsters,
and persistent save games.  The original curses interface and all game data
are preserved.  Scores and the default save live below @env{XDG_STATE_HOME},
with a @file{~/.local/state} fallback; explicit save and character-sheet paths
retain their upstream meaning.")
    (license license:gpl3+)))
