;;; Geminum Orbis, built from the complete original Subversion revision 59.
;;;
;;; Kevin Wells (Dark_Oppressor) changed the project's licensing field to
;;; "Public domain" on 2011-04-21 in his own RogueBasin revision 24451:
;;; https://roguebasin.com/index.php?title=Geminum_Orbis&oldid=24451
;;; https://roguebasin.com/api.php?action=compare&format=json&fromrev=24448&torev=24451
;;; This package selects that author-side public-domain dedication.  Separately,
;;; https://sourceforge.net/projects/adventurerpg/ and the project metadata at
;;; https://sourceforge.net/rest/p/adventurerpg/ identify the license as "GNU
;;; General Public License version 2.0 (GPLv2)".  The metadata's edit date and
;;; per-version scope are not exposed; it does not state an explicit dual-license
;;; or fallback clause.  Neither statement licenses the external curses library.
;;; The installed notice reproduces these statements and the source credits.

(define-module (tay packages geminum-orbis)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix svn-download)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses))

(define-public geminum-orbis
  (package
    (name "geminum-orbis")
    ;; The unreleased trunk has no version manifest; identify the exact revision.
    (version "0-r59")
    (source
     (origin
       (method svn-fetch)
       (uri (svn-reference
             (url "https://svn.code.sf.net/p/adventurerpg/code/trunk/")
             (revision 59)))
       (file-name (string-append name "-" version "-checkout"))
       ;; Recursive NAR hash of the canonical svn export -r59, not the .7z release.
       (sha256
        (base32 "0c3993xpns19jyhxz8h7b2ls3slixwxf2qzd4zs7p0r93yvkr7f0"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                      ; upstream has no automated test suite
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'normalize-source-and-apply-platform-patch
            (lambda _
              ;; Canonical SVN exports retain CRLF.  Normalize only C++ source
              ;; line endings for the LF patch; maps and docs stay byte-exact.
              (substitute* (find-files "." "\\.(h|cpp)$")
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (canonicalize-path
                          (car
                           (search-patches
                            "tay/packages/patches/geminum-orbis-platform.patch")))))))
          (replace 'build
            (lambda _
              ;; All original game headers form one translation unit.  The port
              ;; reads both original maps directly from the immutable store.
              (invoke #$(cxx-for-target) "-std=gnu++11" "-O2"
                      (string-append "-DGEMINUM_DATA_DIR=\"" #$output
                                     "/share/geminum-orbis/levels\"")
                      (string-append "-I" #$ncurses "/include")
                      "geminumorbis.cpp" "-o" "geminum-orbis"
                      (string-append "-L" #$ncurses "/lib")
                      (string-append "-Wl,-rpath," #$ncurses "/lib")
                      "-lncursesw")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/geminum-orbis"))
                     (data (string-append out "/share/geminum-orbis"))
                     (doc (string-append out "/share/doc/geminum-orbis"))
                     (launcher (string-append bin "/geminum-orbis")))
                (install-file "geminum-orbis" libexec)
                (copy-recursively "levels" (string-append data "/levels"))
                (copy-recursively "docs" (string-append doc "/upstream"))
                ;; Upstream r59 has no license file.  This is an explicitly
                ;; downstream provenance notice, not a fabricated upstream one.
                (call-with-output-file (string-append doc "/LICENSE-PROVENANCE.txt")
                  (lambda (port)
                    (display
                     (string-append
                      "Geminum Orbis: downstream licensing and credits record\n\n"
                      "Source: https://svn.code.sf.net/p/adventurerpg/code/trunk\n"
                      "Subversion revision: 59 (2009-02-04)\n\n"
                      "Original startup notice (geminumorbis.cpp):\n"
                      "Geminum Orbis Copyright 2006-2008\n"
                      "Created By: Dark_Oppressor\n\n"
                      "Original credits (misc.h):\n"
                      "Programming: Dark_Oppressor\n"
                      "Playtesters: Vannilesoep, suicide_mission, Spoon[], ^Slick\n"
                      "Gr33tz to: DJNsomniac\n\n"
                      "The author Kevin Wells, also known as Dark_Oppressor,\n"
                      "set the RogueBasin Geminum Orbis licensing field to:\n"
                      "|licensing = Public domain\n"
                      "Revision 24451, Dark Oppressor, 2011-04-21T04:47:32Z.\n"
                      "https://roguebasin.com/index.php?title=Geminum_Orbis&oldid=24451\n"
                      "https://roguebasin.com/api.php?action=compare&format=json"
                      "&fromrev=24448&torev=24451\n\n"
                      "This package selects that author-side public-domain\n"
                      "dedication for the game and its original maps.\n\n"
                      "Separately, SourceForge identifies the project license as:\n"
                      "GNU General Public License version 2.0 (GPLv2)\n"
                      "https://sourceforge.net/projects/adventurerpg/\n"
                      "https://sourceforge.net/rest/p/adventurerpg/\n"
                      "The metadata edit date and per-version scope are unknown.\n"
                      "It supplies no explicit dual-license or fallback clause.\n"
                      "These are distinct project-level statements; this notice\n"
                      "does not add an upstream license or relicense dependencies.\n")
                     port)))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\numask 077\n"
                      ": \"${HOME:?HOME must be set}\"\n"
                      "case ${XDG_STATE_HOME:-} in\n"
                      "  /*) state_home=$XDG_STATE_HOME ;;\n"
                      "  *) state_home=$HOME/.local/state ;;\n"
                      "esac\n"
                      "case $state_home in\n"
                      "  /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'geminum-orbis: state must be outside the store' >&2; exit 1 ;;\n"
                      "  /*) ;;\n"
                      "  *) printf '%s\\n' "
                      "'geminum-orbis: state directory must be absolute' >&2; exit 1 ;;\n"
                      "esac\n"
                      "state=$(" #$coreutils-minimal
                      "/bin/realpath -m -- \"$state_home/geminum-orbis\")\n"
                      "case $state in /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'geminum-orbis: resolved state must be outside the store' "
                      ">&2; exit 1 ;; esac\n"
                      #$coreutils-minimal "/bin/mkdir -p -- \"$state\"\n"
                      "cd -- \"$state\"\n"
                      "export TERMINFO_DIRS=\"" #$ncurses "/share/terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n"
                      "exec " libexec "/geminum-orbis \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://sourceforge.net/projects/adventurerpg/")
    (synopsis "Original Geminum Orbis dungeon roguelike")
    (description
     "Geminum Orbis is Kevin Wells's unfinished terminal dungeon roguelike,
previously known as Adventure RPG.  This package builds the full original C++
Subversion revision 59 with a native ncurses interface and both original static
maps.  It supports character generation, dungeon exploration, doors, and stairs;
upstream's save and load interface remains unimplemented.  The terminal must
have at least 80 columns and 25 rows and support colors.  The launcher keeps
writable high-score state in @file{$XDG_STATE_HOME/geminum-orbis}, falling back
to @file{$HOME/.local/state/geminum-orbis} when @env{XDG_STATE_HOME} is unset or
relative, while reading maps directly from the store.  @env{HOME} must be set.")
    (license license:public-domain)))
