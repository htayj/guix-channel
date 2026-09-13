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
              ;; The repository preserves Windows CRLF files.  Match the
              ;; original line endings explicitly in the two files patched
              ;; below, then select the documented Unix build by disabling the
              ;; Windows and MSVC feature macros.
              (substitute* "util.h"
                (("^#define WIN") "// #define WIN")
                (("^#define PC") "// #define PC")
                ;; The bitmap code computes storage in 32-bit words.  On
                ;; LP64 systems `unsigned long` is 64 bits, so the original
                ;; definition makes pointer iteration overrun that storage.
                (("typedef unsigned long dword;") "typedef unsigned int dword;"))
              ;; Remove `--smoke` before the ordinary command-line parser sees
              ;; the arguments.  This keeps the proof on the same script-
              ;; loading and movement code as normal use.
              (substitute* "daedalus.cpp"
                (("#include <memory.h>")
                 "#include <memory.h>\n#include <string.h>\n")
                (("  int iarg = 1;")
                 "  int iarg = 1;\n  flag fSmoke = fFalse;\n")
                (("  szLine\\[0\\] = chNull;")
                 (string-append
                  "  szLine[0] = chNull;\n"
                  "  for (iarg = 1; iarg < argc; iarg++)\n"
                  "    if (strcmp(argv[iarg], \"--smoke\") == 0) {\n"
                  "      fSmoke = fTrue;\n"
                  "      argv[iarg][0] = chNull;\n"
                  "    }\n"))
                ;; Ignore the cleared proof-only flag when constructing the
                ;; command line.  Otherwise the original loop appends extra
                ;; spaces to the script pathname, making the engine report a
                ;; false successful smoke result after a failed file open.
                (("    //printf\\(\"%d: '%s'\\\\n\", iarg, argv\\[iarg\\]\\);")
                 (string-append
                  "    if (argv[iarg][0] == chNull)\n"
                  "      continue;\n"
                  "    //printf(\"%d: '%s'\\n\", iarg, argv[iarg]);"))
                (("  RunCommandLine\\(szLine, NULL\\);")
                (string-append
                  ;; The original loop leaves one trailing separator after
                  ;; its final argument.  Trim it before handing the absolute
                  ;; script name to the file-command parser.
                  "  while (pch > szLine && pch[-1] == ' ') *--pch = chNull;\n"
                  "  RunCommandLine(szLine, NULL);\n\n"
                  "  if (fSmoke) {\n"
                  "    DoCommand(cmdMoveU);\n"
                  "    return 0;\n"
                  "  }\n\n")))))
          (add-after 'patch-unix-command-line 'patch-linux-allocator
            (lambda _
              (substitute* "util.cpp"
                (("void \\*operator new\\(size_t cb, void \\*pv\\)")
                 (string-append
                  "void operator delete(void *pv, size_t cb)\n"
                  "{\n"
                  "  DeallocateP(pv);\n"
                  "}\n\n"
                  "void *operator new(size_t cb, void *pv)")))))
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
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (ln #$(file-append coreutils-minimal "/bin/ln")))
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
                    (format port
                            (string-append
                             "#!~a~%set -eu~%real=~s~%data=~s~%script=~s~%"
                             "mkdir=~s~%cat=~s~%ln=~s~%")
                            shell program data (string-append data "/dragon.ds")
                            mkdir cat ln)
                    (display
                     "if test \"${1-}\" = --smoke; then\n"
                     port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: dragonslayer [--smoke]' >&2; exit 64; }\n")
                     port)
                    ;; Do not create a state directory in the proof path.
                    ;; Daedalus has a small command-line buffer, so invoke its
                    ;; installed script from its data directory by short name.
                    (display "  cd \"$data\"\n" port)
                    (display "  raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\n" port)
                    (display "  if test -n \"$raw\"; then\n" port)
                    (display
                     "    if ! \"$real\" dragon.ds --smoke >\"$raw\" 2>&1; then\n"
                     port)
                    (display
                     "      \"$cat\" \"$raw\" >&2 || true\n      exit 1\n    fi\n"
                     port)
                    (display "    printf 'DRAGONSLAYER_SMOKE_OK\\n' >>\"$raw\"\n" port)
                    (display "    \"$cat\" \"$raw\" >&2\n" port)
                    (display "  else\n    \"$real\" dragon.ds --smoke >&2\n  fi\n" port)
                    (display "  printf 'DRAGONSLAYER_SMOKE_OK\\n'\n  exit 0\n" port)
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
                    (display "\"$ln\" -sfn \"$script\" dragon.ds\n" port)
                    (display "exec \"$real\" dragon.ds\n" port)))
                (chmod launcher #o555)))))))
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
