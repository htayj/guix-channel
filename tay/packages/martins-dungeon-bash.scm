;;; GNU Guix package for Martin Read's Dungeon Bash.

(define-module (tay packages martins-dungeon-bash)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
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
      ;; Upstream has no automated test target.  The installed terminal game,
      ;; including save/load, is exercised by tests/martins-dungeon-bash-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list
         "CC=gcc"
         ;; Keep upstream's warning policy while removing debug information
         ;; that would otherwise embed the variable build directory.
         "CFLAGS=-O2 -g0 -Wall -Wstrict-prototypes -Wwrite-strings -Wmissing-prototypes -Werror -Wredundant-decls -Wunreachable-code -DMAJVERS=1 -DMINVERS=7")
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
                     (doc (string-append out "/share/doc/martins-dungeon-bash"))
                     (real (string-append libexec "/dungeonbash"))
                     (launcher (string-append bin "/dungeonbash"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (script #$(file-append util-linux "/bin/script"))
                     (stty #$(file-append coreutils-minimal "/bin/stty"))
                     (smoke-first
                      (string-append stty " rows 24 cols 80; exec " real))
                     (smoke-second
                      (string-append stty " rows 24 cols 80; exec " real)))
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
                    (format port "real=~s~%cat=~s~%mkdir=~s~%script=~s~%"
                            real cat mkdir script)
                    (format port "terminfo=~s~%~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display
                     "export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n"
                     port)
                    (display "export TERM=\"${TERM:-xterm-256color}\"\n" port)
                    (display "if test \"${1-}\" = --smoke; then\n" port)
                    (display
                     "  test \"$#\" -eq 1 || { echo 'usage: dungeonbash [--smoke]' >&2; exit 64; }\n"
                     port)
                    (display "  export LC_ALL=C\n" port)
                    (display
                     "  state=\"${XDG_STATE_HOME:-${HOME:?HOME or XDG_STATE_HOME must be set}/.local/state}/martins-dungeon-bash\"\n"
                     port)
                    (display "  work=\"$state/smoke\"\n" port)
                    (display "  \"$mkdir\" -p \"$work\"\n" port)
                    (display "  cd \"$state\"\n" port)
                    (format port
                            "  printf 'Goocastle\\n5S ' | TERM=xterm-256color \"$script\" -qefc ~s /dev/null >\"$work/first.raw\"~%"
                            smoke-first)
                    (display "  test -s \"$state/dunbash.sav.gz\"\n" port)
                    (format port
                            "  printf 'XY ' | TERM=xterm-256color \"$script\" -qefc ~s /dev/null >\"$work/load.raw\"~%"
                            smoke-second)
                    (display "  test ! -e \"$state/dunbash.sav.gz\"\n" port)
                    (display "  first=\"$(\"$cat\" \"$work/first.raw\")\"\n" port)
                    (display "  case \"$first\" in\n" port)
                    (display "    *\"Welcome to Martin's Infinite Dungeon.\"*) ;;\n" port)
                    (display "    *) echo 'dungeonbash smoke: first transcript missing welcome' >&2; exit 1 ;;\n" port)
                    (display "  esac\n" port)
                    (display "  second=\"$(\"$cat\" \"$work/load.raw\")\"\n" port)
                    (display "  case \"$second\" in\n" port)
                    (display "    *\"Game loaded.\"*) ;;\n" port)
                    (display "    *) echo 'dungeonbash smoke: load transcript missing Game loaded' >&2; exit 1 ;;\n" port)
                    (display "  esac\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n" port)
                    (display "    \"$cat\" \"$work/first.raw\" \"$work/load.raw\" >\"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    (display "  printf '%s\\n' MARTINS_DUNGEON_BASH_SMOKE_OK\n" port)
                    (display "  exit 0\n" port)
                    (display "fi\n" port)
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; The source's Makefile directly invokes GCC and links against panel and
    ;; ncurses.  util-linux supplies the package-owned PTY smoke wrapper.
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses util-linux))
    (home-page "https://www.chiark.greenend.org.uk/~mpread/dungeonbash/")
    (synopsis "Simple terminal roguelike game")
    (description
     "Martin's Dungeon Bash is a simple C roguelike game.  This package
builds the fixed upstream v1.7 source release with GNU make, panel, and
ncurses, and installs its complete BSD-2-Clause notice.  Normal invocation
preserves the upstream working-directory save behavior.  The package-owned
@option{--smoke} mode exercises a save and reload through an isolated PTY and
keeps its state outside the store; it performs no build-time or runtime
downloads.")
    (license license:bsd-2)))
