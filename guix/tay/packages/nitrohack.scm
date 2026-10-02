;;; GNU Guix package for the NitroHack terminal roguelike.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages nitrohack)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages web))

;; Tag 4.0.4 names this immutable upstream revision.  Fetch the complete
;; pinned tree rather than GitHub's automatically generated tarball.
(define %nitrohack-commit
  "21b9774b24efbdafdd20e152f9b1e5ed2a7b4150")
;; License audit at this revision: libnitrohack/dat/license is the NGPL
;; renamed to NitroHack in December 2011; dist/debian/copyright credits
;; Daniel Thaler and the NetHack Devteam.  nhdat is generated from this same
;; licensed tree.  The Windows nh.ico asset is not installed; this curses
;; output contains no fonts, tiles, or sound assets.

(define-public nitrohack
  (package
    (name "nitrohack")
    (version "4.0.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DanielT/NitroHack")
             (commit %nitrohack-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0s36b2wy5fm30lfpmsa9f00n4ykr4d2cak7rmrirf35ss5vxapgn"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; The generated parsers, headers, and nhdat archive form one build
      ;; graph in upstream CMake; serialize it for older CMake metadata.
      #:parallel-build? #f
      ;; Upstream has no test target.  The installed curses executable is
      ;; exercised by tests/nitrohack-smoke.sh.
      #:tests? #f
      #:configure-flags
      #~(list
         ;; The live #456 delivery brief explicitly omits the PostgreSQL
         ;; server, not the original curses client's network feature.
         "-DENABLE_SERVER=OFF"
         "-DENABLE_NETCLIENT=ON"
         (string-append "-DBINDIR=" #$output "/libexec")
         (string-append "-DLIBDIR=" #$output "/lib")
         (string-append "-DDATADIR=" #$output "/share/nitrohack")
         (string-append "-DCMAKE_INSTALL_RPATH=" #$output "/libexec:"
                        #$output "/lib")
         ;; Upstream emits a shell launcher here.  It is removed after the
         ;; install because the Guix launcher below supplies the library path
         ;; and keeps the real executable private.
         (string-append "-DSHELLDIR=" #$output "/share/nitrohack"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'make-build-reproducible
            (lambda _
              ;; makedefs embeds the current clock in date.h and nhdat.  Use
              ;; the timestamp of the pinned 4.0.4 commit instead.
              (substitute* "libnitrohack/util/makedefs.c"
                (("time\\(&clocktim\\);")
                 (string-append
                  "/* Guix modification, 2026-10-02: pin build timestamp. */\n"
                  "clocktim = 1329666608L;")))
              ;; Guix's wide ncurses headers are installed directly as
              ;; include/curses.h rather than Debian's ncursesw/curses.h.
              (substitute* "nitrohack/include/nhcurses.h"
                (("<ncursesw/curses\\.h>")
                 "<curses.h> /* Guix modification, 2026-10-02: flat ncurses headers. */"))
              (setenv "TZ" "UTC0")))
          ;; CMake's generated shell script is not the package interface.  It
          ;; is installed in a separate directory so it cannot overwrite the
          ;; real executable, then discarded below.
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/nitrohack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/nitrohack"))
                     (installed-shell (string-append data "/nitrohack"))
                     (real (string-append libexec "/nitrohack-real"))
                     (launcher (string-append bin "/nitrohack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (terminfo (string-append #$ncurses "/share/terminfo"))
                     (source (dirname (car (find-files ".." "^README$"))))
                     (notices '("README" "doc/Guidebook.txt"
                                "dist/debian/copyright")))
                (invoke "cmake" "--install" ".")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (unless (file-exists? (string-append libexec "/nitrohack"))
                  (error "CMake did not install the NitroHack executable"))
                (rename-file (string-append libexec "/nitrohack") real)
                (when (file-exists? installed-shell)
                  (delete-file installed-shell))
                (for-each
                 (lambda (file)
                   (install-file (string-append source "/" file) doc))
                 notices)
                ;; The upstream CMake data install retains nhdat and the
                ;; complete NitroHack/NetHack General Public License beside
                ;; the generated game data.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~%"
                            shell)
                    (format port "real=~s~%out=~s~%libexec=~s~%terminfo=~s~%"
                            real out libexec terminfo)
                    (display
                     (string-append
                      "export LD_LIBRARY_PATH=\""
                      "$libexec:$out/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\n")
                     port)
                    (display
                     "export TERM=\"${TERM:-xterm-256color}\"\n"
                     port)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\""
                      "$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n\n")
                     port)
                    ;; Ordinary invocations retain normal argument
                    ;; forwarding while keeping the executable private.
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/nitrohack/"))
                    (doc (string-append #$output "/share/doc/nitrohack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed NitroHack notice" file)))
                 '("README" "Guidebook.txt" "copyright"))
                (unless (file-exists? (string-append data "nhdat"))
                  (error "missing installed NitroHack data archive"))
                (unless (file-exists? (string-append data "license"))
                  (error "missing installed NitroHack license"))
                (invoke "grep" "-F" "NITROHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "renamed to NitroHack as of December 2011"
                        (string-append data "license"))
                (invoke "grep" "-F" "Daniel Thaler"
                        (string-append doc "copyright"))
                (invoke "grep" "-F" "NetHack Devteam"
                        (string-append doc "copyright"))
                (invoke "grep" "-F" "NitroHack"
                        (string-append doc "README")))))
          ;; All generated data and launcher files must be immutable after
          ;; installation; user state is redirected by the runtime itself.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    ;; CMake invokes the checked-in bison/flex generators.  gcc-toolchain is
    ;; explicit because the project predates modern Guix CMake defaults.
    (native-inputs (list bison cmake-minimal flex gcc-toolchain))
    ;; Preserve the original wide-curses client, including its network client.
    ;; Python and namespace tools are realized only by the standalone test.
    (inputs (list bash-minimal jansson ncurses))
    (home-page "https://github.com/DanielT/NitroHack")
    (synopsis "Modernized terminal dungeon exploration game")
    (description
     "NitroHack is a modernized, network-capable fork of the classic
NetHack dungeon exploration game.  This package builds the local wide-curses
client from the fixed 4.0.4 source revision, with the optional PostgreSQL
network server disabled and no runtime downloads.  Its launcher keeps the
rebuilt executable private, supplies the Guix library and terminfo paths, and
forwards ordinary arguments without a test mode.  Game configuration,
saves, and logs remain under the user's XDG configuration directory.  The
upstream NitroHack/NetHack General Public License, README, Guidebook, and
Debian copyright notice are installed with the generated nhdat archive.")
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
