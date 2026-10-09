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
  #:use-module (gnu packages commencement)
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
      ;; The default cache would record the compiler's library paths in the
      ;; runtime output.  CoreRL has no bundled libraries, so RUNPATH is
      ;; sufficient and keeps native inputs out of the closure.
      #:make-dynamic-linker-cache? #f
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
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Keep the upstream build command and select GNU89 for its
              ;; intentionally pre-C99 declarations.  Resolve the compiler's
              ;; symlinked runtime libraries before embedding RPATHs so the
              ;; native gcc-toolchain itself does not enter the output.
              (let* ((libc-lib (dirname
                                (canonicalize-path
                                 (search-input-file inputs "/lib/libc.so.6"))))
                     (libgcc-lib (dirname
                                  (canonicalize-path
                                   (search-input-file
                                    inputs "/lib/libgcc_s.so.1")))))
                (setenv "GUIX_LD_WRAPPER_DISABLE_RPATH" "1")
                (invoke "gcc" "-std=gnu89" "-o" "corerl" "1kcore.c"
                        (string-append "-L" #$ncurses "/lib")
                        (string-append "-Wl,-rpath," libc-lib)
                        (string-append "-Wl,-rpath," libgcc-lib)
                        (string-append "-Wl,-rpath," #$ncurses "/lib")
                        "-lncurses"))))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (doc (string-append #$output "/share/doc/corerl"))
                     (program (string-append libexec "/corerl"))
                     (launcher (string-append bin "/corerl"))
                     (notice (string-append doc "/NOTICE"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "corerl" libexec)
                (install-file "1kcore.c" doc)
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
                      "Grant: Studio Tectorum, 'coreRL in 1kib', "
                      "2013-10-24\n"
                      "https://www.roguelikeeducation.org/2.html\n"
                      "\"This version of the source is also released "
                      "into the public domain\"\n"
                      "The article links that grant directly to 1kcore.c.\n"
                      "The complete, unmodified 1023-byte source is "
                      "installed alongside this notice.\n"
                      "Source SHA-256: "
                      "05d55844b30fbfae72bd87ab9e26539c"
                      "fb8232e540bc0d0ce50b04d6d1369e24\n"
                      "The executable is compiled from that source; "
                      "no upstream binaries or other assets are included.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%" shell)
                    (display "set -eu\n" port)
                    (format port "program=~s~%" program)
                    (format port "terminfo=~s~%" terminfo)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display "exec \"$program\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal ncurses))
    (home-page "https://www.roguelikeeducation.org/2.html")
    (synopsis "One-kilobyte terminal roguelike")
    (description
     "CoreRL is a tiny curses roguelike from Studio Tectorum's Roguelike
Education article.  This package builds the complete 1023-byte public-domain
C source with GNU89 and ncurses.  Use the arrow keys to move and @kbd{q} to
quit.  Bumping into enemies removes them, while moving onto the stairs
advances to the next level.  A launcher supplies the ncurses terminfo path
and executes the game; the original source and its public-domain grant are
installed with the documentation.  The game has no save or configuration
files.")
    (license license:public-domain)))
