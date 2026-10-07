;;; GNU Guix package for Martin Read's Dungeon Bash.

(define-module (tay packages martins-dungeon-bash)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ncurses))

(define-public martins-dungeon-bash
  (package
    (name "martins-dungeon-bash")
    ;; Stable upstream release 1.7, published 2009-01-06.
    (version "1.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://www.chiark.greenend.org.uk/~mpread/dungeonbash/"
             "archive-1.7/dungeonbash-1.7.tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 790bde04ff869ba2817ad1f07d062d75f7f15af4a2c99669dd60a4b98fdf1380
       (sha256
        (base32
         "100kvy7vk930vmlrdjd2yidg3xvm5l37vw6iga0s56w6zw2dw2vr"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated test target.  The ordinary terminal game,
      ;; including save/load, is exercised by
      ;; tests/martins-dungeon-bash-native.py.
      #:tests? #f
      #:make-flags
      #~(list
         (string-append "CC=" #$(cc-for-target))
         ;; Keep upstream's warning checks while allowing GCC 14 to report
         ;; historical maybe-uninitialized diagnostics without rejecting the
         ;; otherwise successful build.  -g0 avoids variable build paths.
         (string-append
          "CFLAGS=-O2 -g0 -Wall -Wstrict-prototypes "
          "-Wwrite-strings -Wmissing-prototypes -Wredundant-decls "
          "-Wunreachable-code -DMAJVERS=1 -DMINVERS=7"))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-compressor-paths
            (lambda _
              ;; The upstream program invokes these tools through system().
              ;; Embed the declared Guix input paths so normal save/load use
              ;; does not depend on the caller's PATH.
              (substitute* "main.c"
                (("\"gzip dunbash.sav\"")
                 (string-append "\"" #$gzip "/bin/gzip dunbash.sav\""))
                (("\"gunzip dunbash.sav\"")
                 (string-append "\"" #$gzip "/bin/gunzip dunbash.sav.gz\"")))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append
                           out "/share/doc/martins-dungeon-bash"))
                     (real (string-append libexec "/dungeonbash"))
                     (launcher (string-append bin "/dungeonbash"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "dungeonbash" libexec)
                ;; notes.txt is the complete BSD-2-Clause notice for the C
                ;; sources and binary.  The archive's HTML spoiler documents
                ;; have no separately verified documentation license and are
                ;; intentionally not installed.
                (install-file "notes.txt" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%~%"
                            #$bash-minimal)
                    (format port "real=~s~%mkdir=~s~%" real mkdir)
                    (format port "terminfo=~s~%~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "export TERM=\"${TERM:-xterm-256color}\"\n" port)
                    ;; XDG paths must be absolute; ignore empty or relative
                    ;; values.  Keep every upstream relative state file in a
                    ;; writable per-user directory, never the caller's cwd.
                    (display "case \"${XDG_STATE_HOME:-}\" in\n" port)
                    (display "  /*) state=\"$XDG_STATE_HOME\" ;;\n" port)
                    (display
                     (string-append
                      "  *) state=\"${HOME:?HOME must be set when "
                      "XDG_STATE_HOME is not absolute}/.local/state\" ;;\n")
                     port)
                    (display "esac\n" port)
                    (display "state=\"$state/martins-dungeon-bash\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; The source's Makefile directly invokes GCC and links against panel and
    ;; ncurses.  The launcher only establishes terminal data and user state.
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses))
    (home-page "https://www.chiark.greenend.org.uk/~mpread/dungeonbash/")
    (synopsis "Simple terminal roguelike game")
    (description
     "Martin's Dungeon Bash is a simple C roguelike game.  This package
builds the fixed upstream v1.7 source release with GNU make, panel, and
ncurses, and installs its complete BSD-2-Clause notice.  The ordinary launcher
stores saves, character dumps, and the death log in
@file{$XDG_STATE_HOME/martins-dungeon-bash}, defaulting to
@file{$HOME/.local/state/martins-dungeon-bash} when @code{XDG_STATE_HOME} is unset,
empty, or not absolute.  Saving exits the game; the next launch restores and
consumes that save, as upstream intended.  It performs no runtime downloads.")
    (license license:bsd-2)))
