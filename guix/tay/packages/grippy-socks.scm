;;; GNU Guix package for the Grippy Socks simulation from Daedalus 3.5.

(define-module (tay packages grippy-socks)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf))

(define %grippy-socks-commit
  "32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8")

(define-public grippy-socks
  (package
    (name "grippy-socks")
    (version "3.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/CruiserOne/Daedalus")
             (commit %grippy-socks-commit)))
       (file-name (git-file-name name version))
       ;; Recursive/Nix base32 hash, as reported by `guix hash -rx` on the
       ;; fixed Git checkout.
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
              ;; Select the documented Unix build by disabling the Windows
              ;; and MSVC feature macros.
              (substitute* "util.h"
                (("^#define WIN") "// #define WIN")
                (("^#define PC") "// #define PC")
                ;; Bitmap storage consists of 32-bit words.  `unsigned long'
                ;; is 64 bits on LP64 systems and makes pointer iteration
                ;; overrun that storage.
                (("typedef unsigned long dword;")
                 "typedef unsigned int dword;"))
              ;; Remove the proof-only flag before the ordinary command-line
              ;; parser sees the arguments.  The remaining path is handled by
              ;; the same script loader and movement code as normal use.
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
                (("    //printf\\(\\\"%d: '%s'\\\\n\\\", iarg, argv\\[iarg\\]\\);")
                 (string-append
                  "    if (argv[iarg][0] == chNull)\n"
                  "      continue;\n"
                  "    //printf(\"%d: '%s'\\n\", iarg, argv[iarg]);"))
                (("  RunCommandLine\\(szLine, NULL\\);")
                 (string-append
                  ;; Trim the separator left by the original argument loop.
                  "  while (pch > szLine && pch[-1] == ' ') *--pch = chNull;\n"
                  "  RunCommandLine(szLine, NULL);\n\n"
                  "  if (fSmoke) {\n"
                  "    DoCommand(cmdMoveForward);\n"
                  "    return 0;\n"
                  "  }\n\n")))))
          (add-after 'patch-unix-command-line 'patch-linux-allocator
            (lambda _
              ;; GCC's sized-delete ABI can be selected for this source even
              ;; though the upstream code only declares the unsized overload.
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
              ;; The upstream Makefile documents this offline Unix build.
              (invoke "make" "daedalus")))
          (add-after 'build 'shrink-build-rpath
            (lambda _
              ;; The linker wrapper adds every build library directory to the
              ;; runpath.  Keep only directories needed by the executable so
              ;; the native compiler toolchain does not become a runtime
              ;; reference.
              (invoke "patchelf" "--shrink-rpath" "daedalus")))
          (delete 'make-dynamic-linker-cache)
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (data (string-append out "/share/grippy-socks"))
                     (doc (string-append out "/share/doc/grippy-socks"))
                     (program (string-append libexec "/grippy-socks-real"))
                     (launcher (string-append bin "/grippy-socks"))
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
                (install-file "gripsox.ds" data)
                ;; Keep the complete license, author notices, and upstream
                ;; documentation with the installed game content.
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
                            shell program data (string-append data "/gripsox.ds")
                            mkdir cat ln)
                    (display
                     "if test \"${1-}\" = --smoke; then\n"
                     port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: grippy-socks [--smoke]' >&2; exit 64; }\n")
                     port)
                    ;; The engine's output is deliberately captured by the
                    ;; proof harness, while the package marker stays stable.
                    (display "  cd \"$data\"\n" port)
                    (display "  raw=${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\n" port)
                    (display "  if test -n \"$raw\"; then\n" port)
                    (display
                     "    if ! \"$real\" gripsox.ds --smoke >\"$raw\" 2>&1; then\n"
                     port)
                    (display
                     "      \"$cat\" \"$raw\" >&2 || true\n      exit 1\n    fi\n"
                     port)
                    (display "    printf 'GRIPPY_SOCKS_SMOKE_OK\\n' >>\"$raw\"\n"
                             port)
                    (display "    \"$cat\" \"$raw\" >&2\n" port)
                    (display "  else\n    \"$real\" gripsox.ds --smoke >&2\n  fi\n"
                             port)
                    (display "  printf 'GRIPPY_SOCKS_SMOKE_OK\\n'\n  exit 0\n"
                             port)
                    (display "fi\n" port)
                    (display
                     (string-append
                      "test \"$#\" -eq 0 || { echo "
                      "'usage: grippy-socks' >&2; exit 64; }\n")
                     port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-"
                      "${HOME:?HOME or XDG_STATE_HOME must be set}"
                      "/.local/state}\"\n")
                     port)
                    (display "state=\"$state_root/grippy-socks\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "\"$ln\" -sfn \"$script\" gripsox.ds\n" port)
                    (display "exec \"$real\" gripsox.ds\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain patchelf))
    (inputs (list bash-minimal coreutils-minimal))
    (home-page "https://github.com/CruiserOne/Daedalus")
    (synopsis "Terminal Grippy Socks mental health simulation")
    (description
     "Grippy Socks is a turn-based mental health simulation implemented as a
Daedalus 3.5 script.  This package builds the command-line Daedalus engine
from the fixed upstream source with GNU make and GCC, and installs only the
Grippy Socks script as runtime data.  The launcher keeps the rebuilt
executable private under @file{libexec}, stores ordinary game state below
@file{$XDG_STATE_HOME/grippy-socks}, and provides an isolated @option{--smoke}
proof path that opens the installed script and performs one movement.  No
build-time or runtime downloads are performed.  The complete GPL license,
author notices, and upstream documentation are retained under
@file{share/doc/grippy-socks}.")
    (license license:gpl2+)))
