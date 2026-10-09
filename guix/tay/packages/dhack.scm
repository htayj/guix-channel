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
                    (format port "real=~s~%terminfo=~s~%"
                            real terminfo)
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
                    ;; No working-directory change is needed: the source has
                    ;; no assets or mutable files and this works from anywhere.
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; The source recipe uses GNU make and g++, but the build phase invokes the
    ;; four source files directly to make the selected language mode explicit.
    (native-inputs (list gcc-toolchain gnu-make unzip))
    (inputs (list bash-minimal ncurses))
    (home-page "https://code.google.com/archive/p/dreamhack")
    (synopsis "Historical terminal symbolic roguelike")
    (description
     "Dhack is the historical standalone DreamHack symbolic roguelike.  This
package builds only the four C++ translation units from the archived Google
Code trunk at its final code revision, links them with ncurses, and excludes
the archive's old trunk, wiki files, and prebuilt Windows binary.  The
launcher keeps the rebuilt executable private under @file{libexec}, installs
the complete GPLv3 notice, and configures ncurses to use its packaged
terminfo database.  The game has no save, network, updater, telemetry, or runtime
download behavior.")
    (license license:gpl3+)))
