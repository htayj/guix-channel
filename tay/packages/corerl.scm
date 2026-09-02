;;; GNU Guix package for Studio Tectorum's CoreRL.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages corerl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define-public corerl
  (package
    (name "corerl")
    ;; The article describes this dated source as the 1 KiB CoreRL release.
    (version "1kib-20131024")
    (source
     (origin
       (method url-fetch)
       (uri "https://www.roguelikeeducation.org/vault/core/1kcore.c")
       (file-name "corerl-1kib-20131024.c")
       ;; SHA-256:
       ;; 05d55844b30fbfae72bd87ab9e26539cfb8232e540bc0d0ce50b04d6d1369e24
       (sha256
        (base32 "094y6v8xc10bwl60vg20wlr85ywwack9xaw7pmraxgqgnd25im85"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The source has no configure script or upstream test target.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (add-after 'unpack 'restore-upstream-source-name
            (lambda _
              ;; url-fetch uses the provenance-preserving package filename;
              ;; the documented upstream command names the file 1kcore.c.
              (rename-file "corerl-1kib-20131024.c" "1kcore.c")))
          (replace 'build
            (lambda _
              ;; Keep the upstream build command and select GNU89 for its
              ;; intentionally pre-C99 declarations.
              (invoke "gcc" "-std=gnu89" "-o" "corerl" "1kcore.c"
                      (string-append "-L" #$ncurses "/lib")
                      "-lncurses")))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (doc (string-append #$output "/share/doc/corerl"))
                     (program (string-append libexec "/corerl"))
                     (launcher (string-append bin "/corerl"))
                     (notice (string-append doc "/NOTICE"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (script #$(file-append util-linux "/bin/script"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "corerl" program)
                (call-with-output-file notice
                  (lambda (port)
                    (display "CoreRL 1 KiB (1kib-20131024)\n" port)
                    (display
                     (string-append
                      "Canonical source: "
                      "https://www.roguelikeeducation.org/"
                      "vault/core/1kcore.c\n")
                     port)
                    (display
                     (string-append
                      "Article: https://www.roguelikeeducation.org/"
                      "2.html\n")
                     port)
                    (display
                     (string-append
                      "The 1023-byte C source is released into the public "
                      "domain.\n")
                     port)
                    (display
                     (string-append
                      "This notice records the upstream grant for the "
                      "source-derived executable.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%" shell)
                    (display "set -eu\n" port)
                    (format port "program=~s~%" program)
                    (format port "output=~s~%" #$output)
                    (format port "cat=~s~%cp=~s~%dirname=~s~%" cat cp dirname)
                    (format port "mkdir=~s~%mktemp=~s~%rm=~s~%script=~s~%"
                            mkdir mktemp rm script)
                    (format port "terminfo=~s~%" terminfo)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "if test \"${1-}\" = --smoke; then\n" port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: corerl [--smoke]' >&2; exit 64; }\n")
                     port)
                    (display
                     (string-append
                      "  export HOME=\"${HOME:?HOME must be set}\"\n")
                     port)
                    (display
                     (string-append
                      "  export XDG_CONFIG_HOME=\"${XDG_CONFIG_HOME:?"
                      "XDG_CONFIG_HOME must be set}\"\n")
                     port)
                    (display
                     (string-append
                      "  export XDG_DATA_HOME=\"${XDG_DATA_HOME:?"
                      "XDG_DATA_HOME must be set}\"\n")
                     port)
                    (display
                     (string-append
                      "  export XDG_CACHE_HOME=\"${XDG_CACHE_HOME:?"
                      "XDG_CACHE_HOME must be set}\"\n")
                     port)
                    (display
                     (string-append
                      "  export XDG_STATE_HOME=\"${XDG_STATE_HOME:?"
                      "XDG_STATE_HOME must be set}\"\n")
                     port)
                    (display "  export TERM=xterm-256color\n" port)
                    (display "  export LC_ALL=C\n" port)
                    (format port
                            (string-append
                             "  scratch=$(~a -d \"${TMPDIR:-/tmp}/"
                             "corerl-smoke.XXXXXXXX\")~%")
                            mktemp)
                    (format port
                            (string-append
                             "  trap '~a -rf \"$scratch\"' EXIT HUP "
                             "INT TERM~%")
                            rm)
                    (format port "  ~a -p \"$scratch/work\"~%" mkdir)
                    (display "  transcript=\"$scratch/work/transcript\"\n" port)
                    ;; Down, Up, and q are deterministic input to the real
                    ;; curses game running inside util-linux's PTY.
                    (format port
                            (string-append
                             "  printf '\\033[B\\033[Aq' | ~a -qefc "
                             "~s /dev/null >\"$transcript\"~%")
                            script program)
                    (display "  test -s \"$transcript\"\n" port)
                    (format port
                            "  transcript_text=$(~a \"$transcript\")~%"
                            cat)
                    (display "  case \"$transcript_text\" in\n" port)
                    (display "    *'@'*) ;;\n" port)
                    (display
                     (string-append
                      "    *) echo 'CoreRL smoke: missing player' >&2; "
                      "exit 1 ;;\n")
                     port)
                    (display "  esac\n" port)
                    (display "  case \"$transcript_text\" in\n" port)
                    (display "    *'e'*) ;;\n" port)
                    (display
                     (string-append
                      "    *) echo 'CoreRL smoke: missing enemy' >&2; "
                      "exit 1 ;;\n")
                     port)
                    (display "  esac\n" port)
                    (display "  case \"$transcript_text\" in\n" port)
                    (display "    *'<'*) ;;\n" port)
                    (display
                     (string-append
                      "    *) echo 'CoreRL smoke: missing stairs' >&2; "
                      "exit 1 ;;\n")
                     port)
                    (display "  esac\n" port)
                    (display "  case \"$transcript_text\" in\n" port)
                    (display "    *'Quit on level 1.'*) ;;\n" port)
                    (display
                     (string-append
                      "    *) echo 'CoreRL smoke: missing normal quit' >&2; "
                      "exit 1 ;;\n")
                     port)
                    (display "  esac\n" port)
                    (display
                     "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\";\n"
                     port)
                    (display "  then\n" port)
                    (format port
                            (string-append
                             "    capture_dir=$(~a "
                             "\"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")~%")
                            dirname)
                    (display "    " port)
                    (format port "~a -p \"$capture_dir\"~%" mkdir)
                    (format port
                            (string-append
                             "    ~a \"$transcript\" "
                             "\"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%")
                            cp)
                    (display "  fi\n" port)
                    (display "  printf '%s\\n' CORERL_RUNTIME_OK\n" port)
                    (display "  exit 0\n" port)
                    (display "fi\n" port)
                    (display "exec \"$program\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal ncurses util-linux))
    (home-page "https://www.roguelikeeducation.org/2.html")
    (synopsis "One-kilobyte terminal roguelike")
    (description
     "CoreRL is a tiny curses roguelike from Studio Tectorum's Roguelike
Education article.  This package builds the fixed 1 KiB public-domain C
source with GNU89 and ncurses, installing the real executable privately behind
a wrapper.  The wrapper provides a deterministic @code{--smoke} mode that
drives the game through a PTY, checks the generated level and normal quit
result, and leaves its transcript in temporary storage.  No assets,
prebuilt binaries, submodules, build-time downloads, runtime downloads, or
persistent state are included.")
    (license license:public-domain)))
