;;; GNU Guix package for the Gruesome console roguelike.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages gruesome)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pascal)
  #:use-module (gnu packages tcl))

(define-public gruesome
  (package
    (name "gruesome")
    (version "0.0.3")
    (source
     (origin
       (method url-fetch)
       (uri "http://www.gamesofgrey.com/games/gruesome/gruesome0.0.3.zip")
       (sha256
        (base32
         "1w482gxkvh8ln3d9hyyq7b9akhzr3s3mi6d37a4s79jlb7afxm1g"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The archive contains a single Free Pascal program and no upstream
      ;; configure or check targets.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "Gruesome")))
          (replace 'build
            (lambda _
              (mkdir-p "build/units")
              (invoke #$(file-append fpc "/bin/fpc")
                      "-O2" "-g-"
                      "-FUbuild/units" "-FEbuild"
                      "-obuild/gruesome-real" "source.pas")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (real-dir (string-append out "/libexec"))
                     (real (string-append real-dir "/gruesome-real"))
                     (doc (string-append out "/share/doc/gruesome"))
                     (launcher (string-append bin "/gruesome"))
                     (expect #$(file-append expect "/bin/expect")))
                (mkdir-p bin)
                (mkdir-p real-dir)
                (mkdir-p doc)
                (install-file "build/gruesome-real" real-dir)
                ;; These are the complete upstream notices.  The archive's
                ;; Windows executable is intentionally not installed.
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "readme.txt" "history.txt"
                            "source.pas"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/bash~%set -eu~%"
                            #$(file-append bash-minimal))
                    (format port "real=~s~%expect=~s~%"
                            real expect)
                    (format port
                            "cat=~s~%chmod=~s~%mkdir=~s~%mktemp=~s~%rm=~s~%"
                            #$(file-append coreutils-minimal "/bin/cat")
                            #$(file-append coreutils-minimal "/bin/chmod")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm"))
                    (display
                     (string-append
                      "case \"${1-}\" in\n"
                      "  --smoke)\n"
                      "    test \"$#\" -eq 1 || { echo "
                      "'usage: gruesome [--smoke]' >&2; exit 64; }\n"
                      "    scratch=$(\"$mktemp\" -d "
                      "\"${TMPDIR:-/tmp}/gruesome-smoke.XXXXXXXX\")\n"
                      "    trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n"
                      "    \"$mkdir\" -p \"$scratch/home\" \"
                      "$scratch/config\" \"$scratch/data\" \"
                      "$scratch/cache\" \"$scratch/state\" \"
                      "$scratch/runtime\" \"$scratch/tmp\" \"
                      "$scratch/work\"\n"
                      "    \"$chmod\" 700 \"$scratch/runtime\"\n"
                      "    export HOME=\"$scratch/home\"\n"
                      "    export XDG_CONFIG_HOME=\"$scratch/config\"\n"
                      "    export XDG_DATA_HOME=\"$scratch/data\"\n"
                      "    export XDG_CACHE_HOME=\"$scratch/cache\"\n"
                      "    export XDG_STATE_HOME=\"$scratch/state\"\n"
                      "    export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n"
                      "    export TMPDIR=\"$scratch/tmp\"\n"
                      "    export PATH= TERM=xterm-256color LC_ALL=C\n"
                      "    export ALL_PROXY=http://127.0.0.1:9\n"
                      "    export HTTP_PROXY=http://127.0.0.1:9\n"
                      "    export HTTPS_PROXY=http://127.0.0.1:9\n"
                      "    export NO_PROXY='*'\n"
                      "    export GRUESOME_REAL=\"$real\"\n"
                      "    cd \"$scratch/work\"\n"
                      "    raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\n"
                      "    log=/dev/null\n"
                      "    if test -n \"$raw\"; then log=\"$raw\"; fi\n"
                      "    \"$expect\" <<'EXPECT_EOF' >\"$log\" 2>&1\n"
                      "set timeout 15\n"
                      "log_user 1\n"
                      "match_max 100000\n"
                      "spawn -noecho $env(GRUESOME_REAL)\n"
                      "expect {\n"
                      "  -re {What is your name\\?} {}\n"
                      "  timeout { exit 1 }\n"
                      "  eof { exit 1 }\n"
                      "}\n"
                      "send -- \"Goocastle\\r\"\n"
                      "expect {\n"
                      "  -re {Press any key to begin\\.} {}\n"
                      "  timeout { exit 1 }\n"
                      "  eof { exit 1 }\n"
                      "}\n"
                      "send -- \" \"\n"
                      "expect {\n"
                      "  -re {Turns: 0} {}\n"
                      "  timeout { exit 1 }\n"
                      "  eof { exit 1 }\n"
                      "}\n"
                      "after 1000\n"
                      "send -- \".\"\n"
                      "expect {\n"
                      "  -re {You lurk in the shadows\\.} {}\n"
                      "  timeout { exit 1 }\n"
                      "  eof { exit 1 }\n"
                      "}\n"
                      "send -- \"Q\"\n"
                      "expect {\n"
                      "  -re {Till next lurking\\.\\.\\.\\.} {}\n"
                      "  timeout { exit 1 }\n"
                      "  eof { exit 1 }\n"
                      "}\n"
                      "send -- \" \"\n"
                      "expect eof\n"
                      "set status [wait]\n"
                      "if {[lindex $status 3] != 0} { exit 1 }\n"
                      "EXPECT_EOF\n"
                      "    if test -n \"$raw\"; then\n"
                      "      printf '%s\\n' 'GRUESOME-SMOKE: gameplay-turn-ok' >>"
                      "\"$raw\"\n"
                      "      \"$cat\" \"$raw\" >&2\n"
                      "    fi\n"
                      "    printf '%s\\n' 'GRUESOME-SMOKE: gameplay-turn-ok'\n"
                      "    exit 0\n"
                      "    ;;\n"
                      "  *)\n"
                      "    exec \"$real\" \"$@\"\n"
                      "    ;;\n"
                      "esac\n")
                     port))
                (chmod launcher #o555))))))))
    (native-inputs
     (list fpc unzip))
    ;; Expect is used by the installed --smoke launcher, not just by the
    ;; build-time package test.
    (inputs
     (list bash-minimal coreutils-minimal expect))
    (home-page "http://www.gamesofgrey.com/games/gruesome/")
    (synopsis "Console roguelike about a grue in procedurally generated caves")
    (description
     "Gruesome is a console roguelike in which the player controls a grue
that explores randomly generated caverns, avoids torchlight, and hunts
adventurers.  This package builds the pinned upstream Pascal source with Free
Pascal, installs the complete upstream documentation and GPL notice, and
does not install the opaque Windows executable shipped in the archive.  The
launcher provides an isolated @option{--smoke} interaction that exercises one
gameplay turn through an expect-controlled pseudo-terminal.")
    (license license:gpl3+)))
