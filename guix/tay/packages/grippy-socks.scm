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
      ;; Upstream provides no test target.  The channel exercises the installed
      ;; interactive console launcher separately.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-unix-command-line
            (lambda _
              ;; Select the documented Unix build by disabling the Windows
              ;; and MSVC feature macros.
              (substitute* "util.h"
                (("^#define WIN")
                 (string-append
                  "// Guix channel change 2026-10-09: "
                  "select upstream Unix build.\n// #define WIN"))
                (("^#define PC") "// #define PC")
                ;; Bitmap storage consists of 32-bit words.  `unsigned long'
                ;; is 64 bits on LP64 systems and makes pointer iteration
                ;; overrun that storage.
                (("typedef unsigned long dword;")
                 (string-append
                  "// Guix channel change 2026-10-09: "
                  "use 32-bit bitmap words on LP64.\n"
                  "typedef unsigned int dword;")))))
          (add-after 'patch-unix-command-line 'patch-linux-allocator
            (lambda _
              ;; GCC's sized-delete ABI can be selected for this source even
              ;; though the upstream code only declares the unsized overload.
              (substitute* "util.cpp"
                (("#include <stdio.h>")
                 (string-append
                  "// Guix channel change 2026-10-09: "
                  "provide sized-delete ABI.\n#include <stdio.h>"))
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
              (use-modules (ice-9 rdelim))
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (data (string-append out "/share/grippy-socks"))
                     (doc (string-append out "/share/doc/grippy-socks"))
                     (program (string-append libexec "/grippy-socks-real"))
                     (launcher (string-append bin "/grippy-socks"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (ln #$(file-append coreutils-minimal "/bin/ln")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "daedalus" libexec)
                (rename-file (string-append libexec "/daedalus") program)
                (install-file "gripsox.ds" data)
                ;; Keep the complete GPL license and upstream documentation.
                ;; Copy the original grant verbatim from the source header,
                ;; followed by a dated notice distinguishing this build.
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "license.htm" "changes.htm"
                            "changes.doc" "daedalus.htm" "daedalus.doc"
                            "script.htm" "script.doc"))
                (call-with-output-file (string-append doc "/NOTICE")
                  (lambda (port)
                    (call-with-input-file "util.h"
                      (lambda (input)
                        (let loop ((line (read-line input)))
                          (unless (eof-object? line)
                            (display line port)
                            (newline port)
                            (unless (string=? line "*/")
                              (loop (read-line input)))))))
                    (display
                     (string-append
                      "\nGuix channel modifications, 2026-10-09:\n"
                      "util.h: select the upstream Unix build and use 32-bit "
                      "bitmap words on LP64.\n"
                      "util.cpp: provide GCC's sized-delete ABI using "
                      "the upstream allocator.\n"
                      "Shrink build-toolchain runpaths and install a private "
                      "engine with the unmodified Grippy Socks script.\n"
                      "The no-argument launcher uses a private XDG state "
                      "directory, OpenScript 'gripsox.ds', fNoExit 1, and "
                      "fSkipMessageDisplay 0.\n"
                      "The console engine has no graphical inside view or "
                      "MessageInside status display.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a~%set -eu~%real=~s~%script=~s~%"
                             "mkdir=~s~%ln=~s~%")
                            shell program (string-append data "/gripsox.ds")
                            mkdir ln)
                    (display
                     (string-append
                      "test \"$#\" -eq 0 || { echo "
                      "'usage: grippy-socks' >&2; exit 64; }\n")
                     port)
                    (display "umask 077\n" port)
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
                    ;; A bare filename treats the entire argument as a filename;
                    ;; use OpenScript with separate native grammar parameters.
                    ;; Keep the console prompt alive and show ordinary messages.
                    (display
                     (string-append
                      "exec \"$real\" \"OpenScript 'gripsox.ds' "
                      "fNoExit 1 fSkipMessageDisplay 0\"\n")
                     port)))
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
@file{$XDG_STATE_HOME/grippy-socks}, and enters the upstream interactive
command-line prompt after loading @file{gripsox.ds} with @code{OpenScript}.
The documented @code{fNoExit 1} lifecycle and @code{fSkipMessageDisplay 0}
display settings keep the prompt available and ordinary messages visible.
The script embeds its own bitmaps and textures, so no external bitmap is
needed.  This console build does not display the graphical inside view or
the script's @code{MessageInside} status and interaction text; ordinary
@code{Message} dialogs, including day summaries, remain available.  No
build-time or runtime downloads are performed.  The complete GPL license,
author grants and notices, dated packaging modifications, and upstream
documentation are retained under @file{share/doc/grippy-socks}.")
    (license license:gpl2+)))
