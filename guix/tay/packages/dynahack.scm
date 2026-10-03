;;; Local DynaHack curses client, built from the final maintainer release.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages dynahack)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

;; v0.6.0 resolves to this immutable upstream revision.
(define %dynahack-commit
  "25aaf2ab6a27a9104864d22337d7117c7d261571")

(define-public dynahack
  (package
    (name "dynahack")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/tung/DynaHack/tar.gz/refs/tags/v"
             version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "104q1r8a3541qq8ixnjsp8vilklwbxipjq1m1byscrc2af5ycvb2"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Neither resource participates in the local curses build.
            ;; tmac.n forbids sale/modified redistribution; the Windows icon
            ;; has no separately established asset grant.  Exclude both from
            ;; the cleaned source and retained installed source notices.
            (delete-file "doc/tmac.n")
            (delete-file-recursively "nitrohack/rc")))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; Upstream has no CTest or other automatic test suite.  The external
      ;; tests/dynahack-smoke.sh exercises the installed, ordinary native UI.
      #:tests? #f
      #:parallel-build? #f
      #:configure-flags
      #~(list "-DENABLE_NETCLIENT=OFF" "-DENABLE_SERVER=OFF"
              "-DUSE_PDCURSES=OFF" "-DCMAKE_C_FLAGS=-std=gnu99"
              (string-append "-DBINDIR=" #$output "/libexec/dynahack")
              (string-append "-DLIBDIR=" #$output "/lib/dynahack")
              (string-append "-DDATADIR=" #$output "/share/dynahack")
              (string-append "-DSHELLDIR=" #$output "/libexec/dynahack"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'reproducible-date
            (lambda _
              (setenv "TZ" "UTC0")
              (setenv "DYNAHACK_SOURCE_DIR" (getcwd))
              ;; NGPL paragraph 2(a): every modified file carries a dated
              ;; notice.  A fixed date removes build-time wall-clock entropy.
              (substitute* "libnitrohack/util/makedefs.c"
                (("time\\(&clocktim\\);")
                 (string-append
                  "/* Guix modification, 2026-10-03: reproducible date. */\n"
                  "\tclocktim = 1455667200L;")))))
          (add-after 'unpack 'guix-curses-header
            (lambda _
              ;; Guix supplies the wide ABI with a flat include directory.
              (substitute* "nitrohack/include/nhcurses.h"
                (("# include <ncursesw/curses.h>")
                 (string-append
                  "/* Guix modification, 2026-10-03: flat wide-curses header. */\n"
                  "# include <curses.h>")))))
          (add-after 'install 'native-launcher-and-notices
            (lambda _
              (with-directory-excursion (getenv "DYNAHACK_SOURCE_DIR")
              (let* ((bin (string-append #$output "/bin"))
                     (doc (string-append #$output "/share/doc/dynahack")))
                ;; Replace only upstream's redundant launcher, not the client.
                (delete-file
                 (string-append #$output "/libexec/dynahack/dynahack.sh"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/dynahack")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/bash\nset -eu\numask 077\n"
                             "userdir=\"${XDG_CONFIG_HOME:-$HOME/.config}"
                             "/DynaHack\"\n"
                             "vardir=\"${XDG_STATE_HOME:-$HOME/.local/state}"
                             "/dynahack\"\n"
                             "export TERMINFO_DIRS=~a/share/terminfo"
                             "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\n"
                             "~a/bin/mkdir -p -- \"$userdir\" \"$vardir\"\n"
                             "exec ~a/libexec/dynahack/dynahack "
                             "-H ~a/share/dynahack "
                             "-U \"$userdir\" -V \"$vardir\" \"$@\"\n")
                            #$bash-minimal #$ncurses #$coreutils-minimal
                            #$output #$output)))
                (chmod (string-append bin "/dynahack") #o555)
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "libnitrohack/dat/license"
                            "doc/changelog.txt" "doc/save-recovery.md"
                            "doc/Guidebook.tex" "dist/debian/copyright"
                            "libnitrohack/src/mtrand.c"))
                (copy-file
                 #$(local-file (search-tay-package-file "dynahack-LGPL-2.0"))
                 (string-append doc "/LGPL-2.0"))
                ;; Retain every per-map and code attribution, not only the
                ;; generic NGPL license.  This also provides complete preferred
                ;; source for the linked LGPL MT19937 and the NGPL game/data.
                (copy-recursively "libnitrohack"
                                  (string-append doc "/source/libnitrohack"))
                (copy-recursively "nitrohack"
                                  (string-append doc "/source/nitrohack"))
                (copy-recursively "include"
                                  (string-append doc "/source/include"))
                (install-file "CMakeLists.txt" (string-append doc "/source"))
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/guix-modified-source/"
                                                file)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 '("libnitrohack/util/makedefs.c"
                   "nitrohack/include/nhcurses.h"))
                (install-file
                 #$(local-file (search-tay-package-file "dynahack.scm")) doc)
                (call-with-output-file (string-append doc "/SOURCE-NOTICE")
                  (lambda (port)
                    (format port
                            (string-append
                             "DynaHack ~a, upstream v~a, commit ~a.~%"
                             "Source: https://codeload.github.com/tung/"
                             "DynaHack/tar.gz/refs/tags/v~a~%"
                             "Archive SHA256: 626de68b538265a6fd0a3560"
                             "79635f9c4e1a37ba5ada1e11c68194a1500e9880~%"
                             "Guix changes dated 2026-10-03: fixed build date,"
                             " flat wide-curses header, local-only CMake flags,~%"
                             "and launcher selecting per-user native config/"
                             "save/log/dumps and bones/scores/locks.~%"
                             "Modified source and dynahack.scm are retained "
                             "here.  Rebuild with~%"
                             "guix build -L CHANNEL/guix dynahack.~%"
                             "The local curses client, libnitrohack and "
                             "generated nhdat ship;~%"
                             "optional network client/server are disabled.~%"
                             "Unneeded nonfree doc/tmac.n and unlicensed "
                             "Windows icon resources are removed from source.~%"
                             "No binary assets are built or installed.~%"
                             "Code/maps are NGPL; MT19937 (mtrand.c) is "
                             "GNU Library GPL 2 or later.~%"
                             "The full LGPL-2.0 text, original MT19937 "
                             "notice and game/map source notices ship.~%"
                             "ncurses/zlib/bash/coreutils retain their "
                             "Guix input licenses and notices.~%")
                            #$version #$version #$%dynahack-commit
                            #$version))))))))))
    (native-inputs (list bison flex))
    (inputs (list bash-minimal coreutils-minimal ncurses zlib))
    (home-page "https://github.com/tung/DynaHack")
    (synopsis "NetHack variant with a local curses interface")
    (description
     "DynaHack is an independently playable NetHack variant derived from
NitroHack and UnNetHack.  This package builds the final maintainer release's
local curses client and dungeon data from source, without the optional network
client or server.  Native configuration, saves, logs and dumps live under
XDG_CONFIG_HOME/DynaHack, while bones, scores, locks and trouble logs use
XDG_STATE_HOME/dynahack.  The immutable game data remains in the store.  The
installed executable has no testing mode; tests/dynahack-smoke.sh is an external
native gameplay and persistence consumer.")
    (license (list (license:fsdg-compatible
                    "https://nethack.org/common/license.html")
                   license:lgpl2.0+))))
