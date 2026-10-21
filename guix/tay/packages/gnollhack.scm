;;; Native Unix GnollHack: immutable text data and a private playground.

(define-module (tay packages gnollhack)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages ncurses)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (tay packages auxiliary))

(define %gnollhack-commit
  "10c2529b38ee457e8d015f8e1561039ab4d4bf2e")

(define-public gnollhack
  (package
    (name "gnollhack")
    (version "4.3.0-27")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/hyvanmielenpelit/GnollHack/tar.gz/"
             %gnollhack-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "06pkiwzlx8wbw5zj93dfsxjim6ax3lbgfl131413fcyf41bmc30q"))
       (modules '((guix build utils)))
       ;; These foreign clients contain proprietary FMOD SDKs/prebuilt code,
       ;; noncommercial modern artwork and fonts.  None is consumed by the
       ;; original Unix tty/curses port.  Keep shared C code and all native
       ;; text/map sources, including sound/tile numeric engine metadata.
       (snippet
        #~(begin
            (for-each delete-file-recursively
                      '("win/win32" "sys/android" "binary"))
            (delete-file "sys/wince/gnollhack64x96.bmp")))
       (patches
        (list (search-tay-package-file
               "patches/gnollhack-immutable-data.patch")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Generated headers, utilities and levels have shared dependencies.
      #:parallel-build? #f
      ;; Upstream has no native Linux check target.  check-dlb is an archive
      ;; construction target, not a test; real gameplay is tested separately.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "SHELL=" #$(file-append bash-minimal "/bin/sh"))
              (string-append "PREFIX=" #$output)
              (string-append "HACKDIR=" #$output "/share/gnollhack")
              ;; Guix supplies the wide-character ncurses ABI, not -lcurses.
              "WINTTYLIB=-lncursesw" "WINCURSESLIB=-lncursesw"
              "YACC=bison -y" "LEX=flex" "GITINFO=0")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-native-build
            (lambda _
              ;; NGPL 2(a): every modified original carries a dated notice.
              (define (notice file text comment)
                (let ((contents (call-with-input-file
                                 file (@ (ice-9 textual-ports) get-string-all))))
                  (call-with-output-file file
                    (lambda (port)
                      (display (string-append comment
                                              " Modified by tay Guix channel, "
                                              "2026-10-21: " text
                                              (if (string=? comment "/*")
                                                  " */\n" "\n")) port)
                      (display contents port)))))
              (notice "include/config.h"
                      "enable upstream reproducible builds and file prefixes."
                      "/*")
              (substitute* "include/config.h"
                (("/\\* #define REPRODUCIBLE_BUILD \\*/")
                 "#define REPRODUCIBLE_BUILD\n#define NOCWD_ASSUMPTIONS"))
              (notice "include/unixconf.h"
                      "qualify the default mail reader in the Guix closure."
                      "/*")
              (substitute* "include/unixconf.h"
                (("\"/bin/mail\"")
                 (string-append "\"" #$(file-append mailutils "/bin/mail") "\"")))
              (notice "sys/unix/unixunix.c"
                      "qualify the fallback shell in the Guix closure."
                      "/*")
              (substitute* "sys/unix/unixunix.c"
                (("\"/bin/sh\"")
                 (string-append "\"" #$(file-append bash-minimal "/bin/sh") "\"")))
              (notice "sys/unix/hints/linux"
                      (string-append "use GNU C11, immutable data, "
                                     "unprivileged execution and store gzip.")
                      "#")
              (substitute* "sys/unix/hints/linux"
                (("CFLAGS=-g -O ") "CFLAGS=-g -O2 -std=gnu11 ")
                (("/bin/gzip") #$(file-append gzip "/bin/gzip"))
                ((" -DSECURE") ""))
              (substitute* "sys/unix/setup.sh"
                (("^# Build and install makefiles\\.")
                 (string-append
                  "# Modified by tay Guix channel, 2026-10-21: "
                  "use the build shell.\n# Build and install makefiles."))
                (("/bin/sh") #$(file-append bash-minimal "/bin/sh")))
              (notice "sys/unix/sysconf"
                      "keep native dumps private and avoid host diagnostic tools."
                      "#")
              (substitute* "sys/unix/sysconf"
                (("=/tmp/gnollhack\\.") "=dumps/gnollhack.")
                (("^GDBPATH=") "#GDBPATH=")
                (("^GREPPATH=") "#GREPPATH=")
                (("^PANICTRACE_GDB=1") "PANICTRACE_GDB=0"))
              ;; No repository probe: version metadata identifies this archive.
              (call-with-output-file "dat/gitinfo.txt"
                (lambda (port)
                  (format port "githash=~a~%gitbranch=4.3.0-27~%"
                          #$%gnollhack-commit)))
              ;; The pinned release date, not the time the builder runs.
              (setenv "SOURCE_DATE_EPOCH" "1792195200")
              (setenv "TZ" "UTC0")
              (invoke "sh" "sys/unix/setup.sh" "sys/unix/hints/linux")
              ;; Save complete corresponding native sources (with the dated
              ;; integration changes) before creating executables and data.
              ;; This accompanies binaries under NGPL 3(a), not a source offer.
              (mkdir-p "native-source")
              (for-each
               (lambda (directory)
                 (copy-recursively directory
                                   (string-append "native-source/" directory)))
               '("src" "include" "util" "dat" "doc" "sys/unix" "sys/share"
                 "win/tty" "win/curses" "win/share"))
              (for-each
               (lambda (file) (copy-file file
                                         (string-append "native-source/" file)))
               '("LICENSE.md" "README.md" "Makefile"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              ;; all builds the whole engine, recovery utility, Guidebook,
              ;; every special/quest level, text databases and nhdat librarian.
              (apply invoke "make" "all" make-flags)))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/gnollhack"))
                     (doc (string-append #$output "/share/doc/gnollhack"))
                     (bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (man (string-append #$output "/share/man/man6")))
                (for-each mkdir-p (list data doc bin libexec man))
                (copy-file "src/gnollhack" (string-append libexec "/gnollhack"))
                (copy-file "util/recover" (string-append libexec "/gnollhack-recover"))
                (chmod (string-append libexec "/gnollhack") #o555)
                (chmod (string-append libexec "/gnollhack-recover") #o555)
                ;; Exactly the upstream default DLB install closure.  All
                ;; playable levels/texts are generated into nhdat, not copied
                ;; into a user's HOME or substituted with a sample dungeon.
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhdat" "dat/license" "dat/symbols"
                            "sys/unix/sysconf"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.md" "README.md" "dat/license"
                            "dat/credits" "doc/Guidebook"))
                (copy-recursively "native-source"
                                  (string-append doc "/native-source"))
                (copy-file "doc/nethack.6" (string-append man "/gnollhack.6"))
                (copy-file "doc/recover.6"
                           (string-append man "/gnollhack-recover.6"))
                ;; Internal pager is the upstream Unix default; gzip, shell,
                ;; mailreader and ncurses terminfo are input-qualified.
                (for-each
                 (lambda (program)
                   (let ((launcher (string-append bin "/" program)))
                     (call-with-output-file launcher
                       (lambda (port)
                         (format port "#!~a~%set -eu~%umask 077~%"
                                 #$(file-append bash-minimal "/bin/sh"))
                         (display
                          (string-append
                           "case ${XDG_DATA_HOME-} in\n"
                           "  /*) base=$XDG_DATA_HOME ;;\n"
                           "  *) case ${HOME-} in\n"
                           "       /*) base=$HOME/.local/share ;;\n"
                           "       *) echo 'gnollhack: an absolute HOME or "
                           "XDG_DATA_HOME is required' >&2; exit 1 ;;\n"
                           "     esac ;;\n"
                           "esac\n") port)
                         (format port "state=$(~s -m -- \"$base/gnollhack\")~%"
                                 #$(file-append coreutils-minimal "/bin/realpath"))
                         (display
                          (string-append
                           "case $state in\n"
                           "  /gnu/store|/gnu/store/*) echo 'gnollhack: "
                           "state must be outside the store' >&2; exit 1 ;;\n"
                           "esac\n"
                           "bytes=$(LC_ALL=C; export LC_ALL; printf '%s' "
                           "\"$state\" | ") port)
                         (format port "~s -c)~%"
                                 #$(file-append coreutils-minimal "/bin/wc"))
                         (display
                          (string-append
                           "if [ \"$bytes\" -gt 128 ]; then\n"
                           "  echo 'gnollhack: playground exceeds native "
                           "128-byte environment limit' >&2; exit 1\n"
                           "fi\n") port)
                         (format port "~s -p -- \"$state/save\" \"$state/dumps\"~%"
                                 #$(file-append coreutils-minimal "/bin/mkdir"))
                         (display
                          (string-append
                           "for file in perm record logfile livelog xlogfile "
                           "wishtracker paniclog; do\n"
                           "  test -e \"$state/$file\" || : > \"$state/$file\"\n"
                           "done\n"
                           ;; Keep HOME and all user option/configuration
                           ;; variables untouched.  The upstream launcher also
                           ;; selects the playground through the environment.
                           "export GNOLLHACKDIR=\"$state\"\n"
                           "export NetHackDIR=\"$state\"\n") port)
                         (format port
                                 (string-append
                                  "export TERMINFO_DIRS=~s"
                                  "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                                 #$(file-append ncurses "/share/terminfo"))
                         (format port "exec ~s \"$@\"~%"
                                 (string-append libexec "/" program))))
                     (chmod launcher #o555)))
                 '("gnollhack" "gnollhack-recover"))))))))
    (native-inputs (list bison flex groff util-linux))
    (inputs (list bash-minimal coreutils-minimal gzip mailutils ncurses))
    (home-page "https://github.com/hyvanmielenpelit/GnollHack")
    (synopsis "NetHack variant with expanded dungeons and character development")
    (description
     "GnollHack extends NetHack with new classes, monsters, items, spells,
levels and character development.  This package provides the upstream native
Unix terminal port, with both tty and curses interfaces and the complete game
simulation, generated text and maps, native saves and recovery utility.
Immutable data stays in the store; saves, bones, levels, scores, logs and dumps
use the user's XDG data directory.  Existing user configuration remains
supported.  The separate graphical and audio clients are not included.")
    (license
     (license:fsdg-compatible "https://nethack.org/common/license.html"))))
