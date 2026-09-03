;;; GNU Guix package for the Dragonslayer game from Daedalus 3.5.

(define-module (tay packages dragonslayer)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement))

(define %dragonslayer-commit
  "32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8")

(define-public dragonslayer
  (package
    (name "dragonslayer")
    (version "3.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/CruiserOne/Daedalus")
             (commit %dragonslayer-commit)))
       (file-name (git-file-name name version))
       ;; Guix recursive base32: lf4pteu5f2l67eysaq3yd277vmha3yfkpjfouu52umw7zp7ix44q.
       ;; Guix package fields use the equivalent Nix base32 representation.
       (sha256
        (base32
         "0fdzx2zzqbd3p99yljksmbh0s3mbzzmq2dq42a9yz5rfkn9gjy2r"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream provides no test target.  The installed command-line game
      ;; and its package-owned --smoke mode are exercised by the channel test.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-unix-command-line
            (lambda _
              ;; The repository preserves Windows CRLF files.  Normalize only
              ;; the two files patched below, then select the documented Unix
              ;; build by disabling the Windows and MSVC feature macros.
              (substitute* '("util.h" "daedalus.cpp")
                (("\r") ""))
              (substitute* "util.h"
                (("^#define WIN$") "// #define WIN")
                (("^#define PC$") "// #define PC"))
              ;; `--smoke` is recognized after the script path has been opened
              ;; by the ordinary command-line parser.  This keeps the proof on
              ;; the same script-loading and movement code as normal use.
              (substitute* "daedalus.cpp"
                (("#include <memory.h>\n")
                 "#include <memory.h>\n#include <string.h>\n")
                (("  int iarg = 1;\n")
                 "  int iarg = 1;\n  flag fSmoke = fFalse;\n")
                (("  szLine.0. = chNull;\n")
                 (string-append
                  "  szLine[0] = chNull;\n"
                  "  for (iarg = 1; iarg < argc; iarg++)\n"
                  "    if (strcmp(argv[iarg], \"--smoke\") == 0)\n"
                  "      fSmoke = fTrue;\n"))
                (("  RunCommandLine\\(szLine, NULL\\);\n\nLLoop:")
                 (string-append
                  "  RunCommandLine(szLine, NULL);\n\n"
                  "  if (fSmoke) {\n"
                  "    DoCommand(cmdMoveU);\n"
                  "    printf(\"DRAGONSLAYER_SMOKE_OK\\n\");\n"
                  "    return 0;\n"
                  "  }\n\n"
                  "LLoop:"))))
          (replace 'build
            (lambda _
              ;; This is the offline Unix build documented by upstream's
              ;; Makefile; the standard GCC toolchain supplies g++ and make.
              (invoke "make" "daedalus")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (data (string-append out "/share/dragonslayer"))
                     (doc (string-append out "/share/doc/dragonslayer"))
                     (program (string-append libexec "/dragonslayer-real"))
                     (launcher (string-append bin "/dragonslayer"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "daedalus" libexec)
                (rename-file (string-append libexec "/daedalus") program)
                (install-file "dragon.ds" data)
                ;; Retain the complete license and the upstream user and
                ;; scripting documentation with the executable and script.
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "license.htm" "changes.htm"
                            "changes.doc" "daedalus.htm" "daedalus.doc"
                            "script.htm" "script.doc"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%real=~s~%script=~s~%mkdir=~s~%"
                            shell program (string-append data "/dragon.ds") mkdir)
                    (display
                     "if test \"${1-}\" = --smoke; then\n"
                     port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: dragonslayer [--smoke]' >&2; exit 64; }\n")
                     port)
                    ;; Do not create a state directory in the proof path.
                    (display "  exec \"$real\" \"$script\" --smoke\n"
                             port)
                    (display "fi\n" port)
                    (display
                     (string-append
                      "test \"$#\" -eq 0 || { echo "
                      "'usage: dragonslayer [--smoke]' >&2; exit 64; }\n")
                     port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-"
                      "${HOME:?HOME or XDG_STATE_HOME must be set}"
                      "/.local/state}\"\n")
                     port)
                    (display "state=\"$state_root/dragonslayer\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "exec \"$real\" \"$script\"\n" port)))
                (chmod launcher #o555))))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal))
    (home-page "https://github.com/CruiserOne/Daedalus")
    (synopsis "Terminal Dragonslayer game")
    (description
     "Dragonslayer is a turn-based dungeon game implemented as a Daedalus
3.5 script.  This package builds the command-line Daedalus engine from the
fixed upstream source with GNU make and GCC, and installs only the Dragonslayer
script as its runtime data.  The launcher keeps the rebuilt executable private
under @file{libexec}, stores ordinary game state below
@file{$XDG_STATE_HOME/dragonslayer}, and provides an isolated @option{--smoke}
proof path that opens the installed script and performs one movement without
save commands.  No build-time or runtime downloads are performed.  The
complete GPL license, author notices, and upstream documentation are retained
under @file{share/doc/dragonslayer}.")
    (license license:gpl2+)))
