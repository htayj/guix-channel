;;; GNU Guix package for the Bell Labs release 7.7.1 dungeon game.

(define-module (tay packages bell-labs-rogue7)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses))

;; LICENSE.TXT combines the notices for the original program and its
;; Super-Rogue, Rogue, Kisseberth, and Burren-derived portions.  The terms are
;; BSD-like, but include additional product-naming conditions, so do not map
;; them to Guix's unmodified BSD-3-Clause record.
(define bell-labs-rogue7-license
  (license:non-copyleft
   "https://rlgallery.org/files/early-roguelike-rel2021.03-src.tgz"
   "Advanced Rogue-derived BSD-style license with notice, endorsement, and naming conditions"))

(define-public bell-labs-rogue7
  (package
    (name "bell-labs-rogue7")
    ;; vers.c identifies this release as 7.7.1; rel2021.03 is the fixed
    ;; RLGallery source collection release published on 2021-03-24.
    (version "7.7.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://rlgallery.org/files/early-roguelike-rel2021.03-src.tgz")
       (file-name "early-roguelike-rel2021.03-src.tgz")
       ;; `guix download` reports this archive hash.  The clean, unpacked
       ;; release tree has recursive hash
       ;; 1hfbpszzshdy4drcjk600yca9z4kqh418gs1zqcc9g1y7fb24gzq.
       (sha256
        (base32 "09myhrn19s33bsdyavi15nq20811l0sxrz8nc2d8qcmx7aysl9jn"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The release does not include an automated test suite.  Its installed
      ;; behavior, including save and restore, is covered by the isolated
      ;; tests/bell-labs-rogue7-smoke.sh proof.
      #:tests? #f
      #:configure-flags
      #~(list "--with-program-name=bell-labs-rogue7"
              "--disable-logfile"
              "--disable-scorefile"
              "--disable-savedir")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'enter-arogue7-directory
            (lambda _
              (chdir "arogue7")))
          (add-before 'configure 'use-roguehome-for-all-game-state
            (lambda _
              ;; Upstream consults ROGUEHOME for its score file but normally
              ;; prefers the passwd database's home directory for saves.  The
              ;; launcher below supplies ROGUEHOME, so make that explicit
              ;; choice govern saves too and keep all mutable state outside
              ;; the immutable store.
              (substitute* "main.c"
                (("    strncpy\\(home, md_gethomedir\\(\\), LINELEN\\);")
                 (string-append
                  "    if ((env = getenv(\"ROGUEHOME\")) != NULL && *env)\n"
                  "        strncpy(home, env, LINELEN);\n"
                  "    else\n"
                  "        strncpy(home, md_gethomedir(), LINELEN);")))))
          (add-before 'configure 'use-portable-ncurses-term-header
            (lambda _
              ;; configure correctly finds <term.h> in Guix's ncurses, but
              ;; this source then unconditionally selects a distribution-
              ;; specific <ncurses/term.h> spelling when NCURSES_VERSION is
              ;; defined.  Include the probed portable header instead.
              (substitute* "mdport.c"
                (("<ncurses/term.h>") "<term.h>"))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec"))
                    (doc (string-append #$output
                                        "/share/doc/bell-labs-rogue7")))
                ;; Do not invoke upstream's install target: it creates global
                ;; score, log, and save paths and assumes mutable system
                ;; locations.  Keep the real executable private to the
                ;; launcher and install the reviewed source documentation.
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "bell-labs-rogue7" libexec)
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "aguide.mm" "arogue77.html"))
                (call-with-output-file (string-append bin
                                                      "/bell-labs-rogue7")
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display "if test -n \"${XDG_DATA_HOME:-}\"; then\n" port)
                    (display "  state=\"$XDG_DATA_HOME/bell-labs-rogue7\"\n" port)
                    (display "else\n" port)
                    (display (string-append
                              "  state=\"${HOME:?HOME or XDG_DATA_HOME must be set}"
                              "/.local/share/bell-labs-rogue7\"\n")
                             port)
                    (display "fi\n" port)
                    (format port "~a/bin/mkdir -p \"$state\"~%"
                            #$coreutils-minimal)
                    (display "export ROGUEHOME=\"$state/\"\n" port)
                    ;; Ensure that the dynamically linked terminal program
                    ;; finds the terminfo supplied by its ncurses input.
                    (format port
                            (string-append
                             "export TERMINFO_DIRS=\"~a/share/terminfo"
                             "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            #$ncurses)
                    (format port "exec ~a/libexec/bell-labs-rogue7 \"$@\"~%"
                            #$output)))
                (chmod (string-append bin "/bell-labs-rogue7") #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://icemonster.rlgallery.org/forge/warden/early-roguelike")
    (synopsis "Historical terminal dungeon game, release 7.7.1")
    (description
     "This package builds the release 7.7.1 terminal dungeon game from the
fixed Roguelike Gallery Early Roguelike Collection source archive.  The
launcher stores scores and saved games under @file{$XDG_DATA_HOME/bell-labs-rogue7},
or @file{$HOME/.local/share/bell-labs-rogue7} when XDG_DATA_HOME is unset.
It performs no build-time or runtime downloads.  The complete upstream
license, attribution notices, and two source documentation files are installed
under @file{share/doc/bell-labs-rogue7}.")
    (license bell-labs-rogue7-license)))
