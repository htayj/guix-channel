;;; GNU Guix package for the historical DreamHack terminal roguelike.
;;;
;;; The Google Code project was archived after SVN revision 47.  Revision 45
;;; is the last revision that changed the trunk sources; revisions 46 and 47
;;; only changed wiki files.

(define-module (tay packages dhack)
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

(define-public dhack
  (package
    (name "dhack")
    ;; 0.2c is the latest named upstream release.  The source below is the
    ;; complete archived snapshot, with the build restricted to trunk at the
    ;; last code revision, SVN r45.
    (version "0.2c")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/google-code-archive-source/"
             "v2/code.google.com/dreamhack/source-archive.zip"))
       (file-name "dreamhack-source-r47.zip")
       ;; SHA-256:
       ;; 42c44d93343bb4b204ae08b3938c6718cfc3d5de48d7698d1705d8d9934ba9cc
       ;; Generic Guix base32 rendering:
       ;; ilce3ezuho2lebfobczzhddhddh4hvo6jdlwtdixaxmnte2lvhga
       ;; Origin fields use the Nix-base32 rendering below.
       (sha256
        (base32 "1k599f9xkn052y6nkms8vvaw7kqqcy697cq8mq2b5d1v6j9lvi22"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream makefile has no test target.  The installed terminal
      ;; program is covered by tests/dhack-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-trunk
            (lambda _
              ;; Do not build oldtrunk, the archive's historical binaries, or
              ;; any of the wiki material.
              (chdir "trunk")))
          (replace 'build
            (lambda _
              ;; Keep the four-file upstream build explicit while making its
              ;; C++ language mode reproducible with current compilers.
              (invoke "g++" "-std=c++14"
                      "main.cpp" "global.cpp" "CGame.cpp" "CEngine.cpp"
                      "-o" "dhack" "-lncurses")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/dhack"))
                     (real (string-append libexec "/dhack-real"))
                     (launcher (string-append bin "/dhack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (stty #$(file-append coreutils-minimal "/bin/stty"))
                     (script #$(file-append util-linux "/bin/script"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                ;; The executable is private to the launcher.  DreamHack's
                ;; only installed notice is the complete trunk COPYING file.
                (install-file "dhack" libexec)
                (rename-file (string-append libexec "/dhack") real)
                (install-file "COPYING" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    (format port "real=~s~%cat=~s~%cp=~s~%dirname=~s~%"
                            real cat cp dirname)
                    (format port "mkdir=~s~%mktemp=~s~%sleep=~s~%stty=~s~%"
                            mkdir mktemp sleep stty)
                    (format port "script=~s~%terminfo=~s~%shell=~s~%"
                            script terminfo shell)
                    ;; ncurses must find the terminfo database shipped by the
                    ;; selected Guix input, while preserving a caller's path.
                    (display
                     "export TERM=\"${TERM:-xterm-256color}\"\n"
                     port)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "export SHELL=\"$shell\"\n" port)
                    (display "if test \"${1-}\" = --smoke; then\n" port)
                    (display "  test \"$#\" -eq 1 || { echo " port)
                    (display
                     "'usage: dhack [--smoke]' >&2; exit 64; }\n"
                     port)
                    ;; The only files made by this branch are the private
                    ;; transcript and its parent directory below TMPDIR.
                    (display "  scratch=$(\"$mktemp\" -d " port)
                    (display
                     "\"${TMPDIR:-/tmp}/dhack-smoke.XXXXXXXX\")\n"
                     port)
                    (display "  raw=\"$scratch/terminal.raw\"\n" port)
                    ;; Wait between inputs so they enter ncurses after each
                    ;; screen has switched to its next getch/getnstr call.
                    (display "  if ! {\n" port)
                    (display "    \"$sleep\" 1; printf ' ';\n" port)
                    (display "    \"$sleep\" 1; printf 'Goocastle\\n';\n" port)
                    (display "    \"$sleep\" 1; printf ' ';\n" port)
                    (display "    \"$sleep\" 1; printf '  ';\n" port)
                    (display "    \"$sleep\" 1; printf '6';\n" port)
                    (display "    \"$sleep\" 1; printf '6';\n" port)
                    (display "    \"$sleep\" 1; printf 'g';\n" port)
                    (display "    \"$sleep\" 1; printf 'i';\n" port)
                    (display "    \"$sleep\" 1; printf ' ';\n" port)
                    (display "    \"$sleep\" 1; printf 'q';\n" port)
                    (display "  } | " port)
                    (display "\"$script\" -qefc " port)
                    (display "\"$stty rows 25 cols 80; exec $real\" /dev/null "
                             port)
                    (display ">\"$raw\"; then\n" port)
                    (display "    echo 'dhack smoke: PTY child " port)
                    (display "failed' >&2\n" port)
                    (display "    exit 1\n" port)
                    (display "  fi\n" port)
                    (display "  test -s \"$raw\"\n" port)
                    (display "  transcript=$(\"$cat\" \"$raw\")\n" port)
                    ;; These assertions cover the title, named player, and a
                    ;; real post-intro gameplay frame, not merely process exit.
                    (display "  case \"$transcript\" in *DreamHack*) ;; *) "
                             port)
                    (display "echo 'dhack smoke: " port)
                    (display "title missing' >&2; exit 1 ;; esac\n" port)
                    (display "  case \"$transcript\" in *Goocastle*) ;; *) "
                             port)
                    (display "echo 'dhack smoke: player name " port)
                    (display "missing' >&2; exit 1 ;; esac\n" port)
                    (display "  case \"$transcript\" in *'HP:'*) ;; *) "
                             port)
                    (display "echo 'dhack smoke: HP gameplay output " port)
                    (display "missing' >&2; exit 1 ;; esac\n" port)
                    (display "  case \"$transcript\" in *'@'*) ;; *) "
                             port)
                    (display "echo 'dhack smoke: player glyph " port)
                    (display "missing' >&2; exit 1 ;; esac\n" port)
                    (display "  case \"$transcript\" in *Inventory*) ;; *) "
                             port)
                    (display "echo 'dhack smoke: inventory output " port)
                    (display "missing' >&2; exit 1 ;; esac\n" port)
                    ;; The runtime evidence adapter may request the raw PTY
                    ;; stream at a repository-owned evidence path.
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}"
                             port)
                    (display "\"; then\n" port)
                    (display "    \"$mkdir\" -p \"$(\"$dirname\" " port)
                    (display
                     "\"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"\n"
                     port)
                    (display
                     "    \"$cp\" \"$raw\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n"
                     port)
                    (display "  fi\n" port)
                    (display "  printf '%s\\n' DHACK_RUNTIME_OK\n" port)
                    (display "  exit 0\nfi\n" port)
                    ;; No working-directory change is needed: the source has
                    ;; no assets or mutable files and this works from anywhere.
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; The source recipe uses GNU make and g++, but the build phase invokes the
    ;; four source files directly to make the selected language mode explicit.
    (native-inputs (list gcc-toolchain gnu-make unzip))
    (inputs (list bash-minimal coreutils-minimal ncurses util-linux))
    (home-page "https://code.google.com/archive/p/dreamhack")
    (synopsis "Historical terminal symbolic roguelike")
    (description
     "Dhack is the historical standalone DreamHack symbolic roguelike.  This
package builds only the four C++ translation units from the archived Google
Code trunk at its final code revision, links them with ncurses, and excludes
the archive's old trunk, wiki files, and prebuilt Windows binary.  The
launcher keeps the rebuilt executable private under @file{libexec}, installs
the complete GPLv3 notice, and provides an isolated @option{--smoke} PTY
check.  The game has no save, network, updater, telemetry, or runtime
download behavior.")
    (license license:gpl3+)))
