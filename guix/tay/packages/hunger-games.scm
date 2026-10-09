;;; GNU Guix package for The Hunger Games simulation from Daedalus 3.5.

(define-module (tay packages hunger-games)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement))

(define %hunger-games-commit
  "32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8")

(define-public hunger-games
  (package
    (name "hunger-games")
    (version "3.5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/CruiserOne/Daedalus")
             (commit %hunger-games-commit)))
       (file-name (git-file-name name version))
       ;; Recursive Guix source hash for the fixed Git checkout.
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
                ( ("^#define WIN")
                  (string-append
                   "// Guix channel change 2026-10-09: "
                   "select upstream Unix build.\n// #define WIN"))
                ( ("^#define PC") "// #define PC")
                ;; Bitmap storage consists of 32-bit words.  `unsigned long'
                ;; is 64 bits on LP64 systems and makes pointer iteration
                ;; overrun that storage.
                ( ("typedef unsigned long dword;")
                  (string-append
                   "// Guix channel change 2026-10-09: "
                   "use 32-bit bitmap words on LP64.\n"
                   "typedef unsigned int dword;")))))
          (add-after 'patch-unix-command-line 'patch-linux-allocator
            (lambda _
              ;; GCC's sized-delete ABI can be selected for this source even
              ;; though the upstream code only declares the unsized overload.
              (substitute* "util.cpp"
                ( ("#include <stdio.h>")
                  (string-append
                   "// Guix channel change 2026-10-09: "
                   "provide sized-delete ABI.\n#include <stdio.h>"))
                ( ("void \\*operator new\\(size_t cb, void \\*pv\\)")
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
                     (data (string-append out "/share/hunger-games"))
                     (doc (string-append out "/share/doc/hunger-games"))
                     (program (string-append libexec "/hunger-games-real"))
                     (launcher (string-append bin "/hunger-games"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (ln #$(file-append coreutils-minimal "/bin/ln")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "daedalus" libexec)
                (rename-file (string-append libexec "/daedalus") program)
                (install-file "hunger.ds" data)
                (install-file "hunger.bmp" data)
                ;; Retain the complete license, author notices, and upstream
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
                             "mkdir=~s~%ln=~s~%")
                            shell program data (string-append data "/hunger.ds")
                            mkdir ln)
                    (display
                     (string-append
                      "test \"$#\" -eq 0 || { echo "
                      "'usage: hunger-games' >&2; exit 64; }\n")
                     port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-"
                      "${HOME:?HOME or XDG_STATE_HOME must be set}"
                      "/.local/state}\"\n")
                     port)
                    (display "state=\"$state_root/hunger-games\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "\"$ln\" -sfn \"$script\" hunger.ds\n" port)
                    (display "\"$ln\" -sfn \"$data/hunger.bmp\" hunger.bmp\n" port)
                    ;; Use the explicit script operation: a bare filename at
                    ;; startup treats the whole command line as that filename.
                    ;; fNoExit takes a separate parameter in the native grammar.
                    ;; The GUI-oriented script suppresses messages; enable
                    ;; their documented console presentation for human play.
                    (display
                     (string-append
                      "exec \"$real\" \"OpenScript 'hunger.ds' "
                      "fNoExit 1 fSkipMessageDisplay 0\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal))
    (home-page "https://github.com/CruiserOne/Daedalus")
    (synopsis "Terminal Hunger Games simulation")
    (description
     "Hunger Games is a turn-based survival simulation implemented as a
Daedalus 3.5 script.  This package builds the command-line Daedalus engine
from the fixed upstream source with GNU make and GCC, and installs the Hunger
Games script and its arena bitmap as runtime data.  The launcher keeps the
rebuilt executable private under @file{libexec}, stores ordinary game state
below @file{$XDG_STATE_HOME/hunger-games}, makes the installed arena bitmap
discoverable there, and enters the upstream interactive command-line prompt
using the documented @code{fNoExit 1} lifecycle setting after explicitly loading
the script with @code{OpenScript} and @file{hunger.ds}.  The display setting
@code{fSkipMessageDisplay 0} makes game messages visible in the console.
Enter @code{*FHelp} for help and @code{MoveForward}
to move, @code{*FInv} for inventory, @code{*FTable} for standings, and
@code{*FMap} for the arena map legend.  Enter @code{fNoExit 0 Exit} to leave the
prompt normally.
No game settings are forced and no build-time or runtime downloads are
performed.  The complete GPL license, author notices, and upstream
documentation are retained under @file{share/doc/hunger-games}.")
    (license license:gpl2+)))
