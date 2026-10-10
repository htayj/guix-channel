;;; GNU Guix package for the dNetHack terminal roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages dnethack)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config))

(define %dnethack-commit
  "a6f0a1c43e66f4fb1bcac34d7d9709706682ec19")

(define-public dnethack
  (package
    (name "dnethack")
    (version "3.26.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Chris-plus-alphanumericgibberish/dNAO")
             (commit %dnethack-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0lakz0czfkymnnb64q7yjvm3r3yfj3xqbylrha3cpc2ix07x0cvj"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The generated yacc/flex sources, maps, and nhdat have ordering
      ;; dependencies and must be made in one serialized build.
      #:parallel-build? #f
      ;; Upstream has no non-interactive test target.  The installed tty
      ;; executable is exercised by tests/dnethack-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'make-build-reproducible
            (lambda _
              ;; A Guix git checkout has no .git directory.  Keep the
              ;; generated version information tied to the fixed revision.
              (substitute* "GNUmakefile"
                (("export COMMIT_DESC := \\$[(]shell git describe --always[)]")
                 (string-append
                  "# Guix: pin version metadata, changed 2026-10-10.\n"
                  "export COMMIT_DESC := "
                  "a6f0a1c43e66f4fb1bcac34d7d9709706682ec19")))
              ;; The upstream admin-message hook reads an ambient relative
              ;; file; it is not part of the ordinary standalone game.
              (substitute* "include/config.h"
                (("^#define SERVER_ADMIN_MSG.*$")
                 (string-append
                  "/* Guix: disable standalone server hook, "
                  "changed 2026-10-10. */\n/* #define SERVER_ADMIN_MSG */")))
              ;; makedefs otherwise embeds the builder's wall clock in
              ;; include/date.h, verinfo, and the generated data archive.
              (substitute* "util/makedefs.c"
                (("\\(void\\) time\\(\\(time_t \\*\\)&clocktim\\);")
                 (string-append
                  "/* Guix: pin build timestamp, changed 2026-10-10. */\n"
                  "clocktim = 1779991412L;")))))
          (add-before 'build 'preserve-corresponding-source
            (lambda _
              ;; NGPL paragraphs 2(a) and 3(a): distribute the complete
              ;; build source with its copyright and third-party notices,
              ;; including the dated modifications above.
              (let ((doc (string-append #$output "/share/doc/dnethack")))
                (mkdir-p doc)
                (invoke "tar" "--sort=name" "--mtime=@1779991412"
                        "--owner=0" "--group=0" "--numeric-owner"
                        "-czf" (string-append doc "/dnethack-source.tar.gz")
                        "."))))
          (replace 'build
            (lambda _
              (invoke "make" "all" "CC=gcc")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/dnethack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/dnethack"))
                     (real (string-append libexec "/dnethack-real"))
                     (launcher (string-append bin "/dnethack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (ln #$(file-append coreutils-minimal "/bin/ln"))
                     (chmod-command #$(file-append coreutils-minimal "/bin/chmod")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "src/dnethack" libexec)
                (rename-file (string-append libexec "/dnethack") real)
                (install-file "dat/nhdat" data)
                (install-file "dat/license" data)
                (install-file "README" doc)
                (install-file "README.gray" doc)
                (install-file "README.menucolor" doc)
                (install-file "doc/Guidebook.txt" doc)
                (install-file "sys/unix/README.linux" doc)
                (for-each
                 (lambda (file) (install-file file doc))
                 (find-files "doc" "^fixes"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%" shell)
                    (format port "real=~s~%data=~s~%mkdir=~s~%ln=~s~%chmod=~s~%~%"
                            real data mkdir ln chmod-command)
                    (display
                     "state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/dnethack\"\n"
                     port)
                    (display "export TERM=\"${TERM:-xterm-256color}\"\n" port)
                    (display
                     (string-append
                      "\"$mkdir\" -p \"$state/save\" \"$state/dumplog\" "
                      "\"$state/whereis\"\n")
                     port)
                    (display
                     (string-append
                      "\"$chmod\" 700 \"$state\" \"$state/save\" "
                      "\"$state/dumplog\" \"$state/whereis\"\n")
                     port)
                    (display "cd \"$state\"\nstate=$PWD\n" port)
                    (display "test -e \"$state/perm\" || : > \"$state/perm\"\n"
                             port)
                    (display
                     (string-append
                      "for file in record logfile xlogfile livelog "
                      "paniclog hangup; do\n")
                     port)
                    (display "  test -e \"$state/$file\" || : > \"$state/$file\"\n"
                             port)
                    (display "done\n\n" port)
                    (display "mailbox=\"$state/mailbox\"\n"
                             port)
                    (display "test -e \"$mailbox\" || : > \"$mailbox\"\n"
                             port)
                    (display "export MAIL=\"$mailbox\"\n\n" port)
                    ;; Use the persistent playground for upstream level locks,
                    ;; bones and recovery files as well as saves and scores.
                    ;; Only the two read-only data files point into the store.
                    (display "\"$ln\" -sfn \"$data/nhdat\" nhdat\n" port)
                    (display "\"$ln\" -sfn \"$data/license\" license\n" port)
                    (display "export HACKDIR=\"$state\" NETHACKDIR=\"$state\"\n"
                             port)
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/dnethack"))
                    (doc (string-append #$output "/share/doc/dnethack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed dNetHack document" file)))
                 '("README" "README.gray" "README.menucolor"
                   "Guidebook.txt" "README.linux" "dnethack-source.tar.gz"))
                (unless (file-exists? (string-append data "/nhdat"))
                  (error "missing installed dNetHack data archive"))
                (unless (file-exists? (string-append data "/license"))
                  (error "missing installed dNetHack license"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "/license"))
                (invoke "grep" "-F" "dNetHack is free software"
                        (string-append doc "README"))
                ;; MacroMagicMarker.py is preserved with its MIT notice in
                ;; the source archive, but is not a runtime script.
                (unless (not (file-exists?
                              (string-append doc "MacroMagicMarker.py")))
                  (error "unintended MacroMagicMarker runtime install")))))
          ;; Keep the store output immutable after all generated files and
          ;; launcher shebangs have been installed.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex pkg-config))
    ;; Bash and coreutils support the store-safe launcher; ncurses/tinfo
    ;; provides the Unix curses linkage.
    (inputs (list bash-minimal coreutils-minimal ncurses/tinfo))
    (home-page "https://github.com/Chris-plus-alphanumericgibberish/dNAO")
    (synopsis "Terminal dungeon exploration game based on NetHack")
    (description
     "dNetHack is a maintained NetHack variant with a terminal interface and
     extensive new roles, races, monsters, items, and dungeon branches.  This
     package builds the ordinary Unix variant from a fixed dNAO revision,
     installs its tty executable and generated data archive, and provides a
     launcher that keeps all mutable game state in a persistent XDG data
     directory.  The complete corresponding source, including upstream
     copyright and third-party license notices, is installed alongside the
     documentation.")
    ;; The upstream dat/license covers the game and its generated data.
    ;; The accompanying complete source also contains the MIT/Expat-licensed
    ;; MacroMagicMarker generator with its full permission notice.
    (license (list (license:fsdg-compatible
                    "https://nethack.org/common/license.html")
                   license:expat))))
