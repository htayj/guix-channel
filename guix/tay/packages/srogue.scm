;;; GNU Guix package for Super-Rogue 9.0.

(define-module (tay packages srogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

;; The canonical Roguelike Gallery repository has no release tags.  The
;; named rel2021.03 collection release is the newest stable source archive;
;; its srogue/ tree is identical to upstream commit
;; 6bb7e13c1fd1b674860c7a20809aa41657f94ea3 apart from the generated
;; Autoconf files it adds.  That commit is an ancestor of main commit
;; 35c5e434e658592a0139c7a110c4a323357e1019, where srogue/LICENSE.TXT is
;; byte-identical.
(define %srogue-license-commit "35c5e434e658592a0139c7a110c4a323357e1019")

;; LICENSE.TXT grants BSD-style redistribution for Robert D. Kindelberger's
;; Super-Rogue, but its clauses 3-5 add conditions: the authors' names and
;; "Super-Rogue" may not endorse derived products, and derived products may
;; not be called or include "Super-Rogue" without prior written permission.
;; It also carries complete BSD-style notices for the Rogue 3.6 portions by
;; Michael Toy, Ken Arnold and Glenn Wichman, Nicholas J. Kisseberth's
;; save/restore code and David Burren's FreeSec encryption code.  The file
;; is installed with the package.
(define srogue-license
  (license:non-copyleft
   (string-append "https://icemonster.rlgallery.org/forge/warden/"
                  "early-roguelike/raw/commit/" %srogue-license-commit
                  "/srogue/LICENSE.TXT")
   "BSD-style terms plus Super-Rogue endorsement and naming conditions"))

(define %srogue-smoke
  (local-file (search-tay-package-file "srogue-smoke.sh")))

(define-public srogue
  (package
    (name "srogue")
    (version "9.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://rlgallery.org/files/early-roguelike-rel2021.03-src.tgz")
       (file-name "early-roguelike-rel2021.03-src.tgz")
       (sha256
        (base32 "09myhrn19s33bsdyavi15nq20811l0sxrz8nc2d8qcmx7aysl9jn"))
       (patches
        (search-patches "tay/packages/patches/srogue-portable-state.patch"))
       (modules '((guix build utils) (ice-9 ftw)))
       (snippet
        '(begin
           ;; The archive collects eight independent games.  Keep only
           ;; Super-Rogue, plus the install-sh helper its configure script
           ;; looks for in the parent directory.
           (copy-file "install-sh" "srogue/install-sh")
           (for-each (lambda (entry)
                       (unless (member entry '("." ".." "srogue"))
                         (delete-file-recursively entry)))
                     (scandir "."))))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; There is no test suite.  'srogue --guix-smoke' plays, saves and
      ;; restores a real game in a PTY; tests/srogue-smoke.sh runs it.
      #:tests? #f
      ;; Upstream's defaults install a setgid binary with host-wide score,
      ;; log and save locations; all state goes below the user's XDG data
      ;; directory instead.
      #:configure-flags
      #~(list "--with-ncurses"
              "--with-program-name=srogue"
              "--disable-setgid"
              "--disable-scorefile"
              "--disable-logfile"
              "--disable-savedir")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'enter-srogue-directory
            (lambda _
              (chdir "srogue")))
          (delete 'install-license-files)
          (replace 'install
            ;; Upstream's install target creates the host-wide score file
            ;; that configure was told not to use.
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/srogue"))
                     (doc (string-append out "/share/doc/srogue"))
                     (launcher (string-append bin "/srogue"))
                     (smoke (string-append libexec "/srogue-smoke"))
                     (shell #$(file-append bash-minimal "/bin/sh")))
                (install-file "srogue" libexec)
                ;; srogue.doc is the ASCII rendering of the rogue.nr
                ;; tutorial that 'make all' produced with groff.
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "rogue.nr" "srogue.doc"))
                (mkdir-p bin)
                ;; With setgid and the score file disabled, the game keeps
                ;; srogue.sav and its per-user score file srogue.scr in
                ;; ROGUEHOME, falling back to HOME.  Both name the XDG state
                ;; directory.  home[] is an 80-byte buffer that must also
                ;; hold "/srogue.sav" and a NUL, so reject longer
                ;; directories before creating anything.  ${#state} counts
                ;; characters in UTF-8 locales, so count bytes in a C-locale
                ;; subshell.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a
set -eu
if test \"${1-}\" = --guix-smoke; then
  shift
  exec ~a \"$@\"
fi
case \"${XDG_DATA_HOME:-}\" in
  /*) state=\"$XDG_DATA_HOME/srogue\" ;;
  *) state=\"${HOME:?HOME or XDG_DATA_HOME must be set}\"
     state=\"$state/.local/share/srogue\" ;;
esac
state_bytes=$(LC_ALL=C; printf %s \"${#state}\")
if [ \"$state_bytes\" -gt 68 ]; then
  echo 'srogue: state directory is too long (at most 68 bytes)' >&2
  exit 1
fi
~a -p -- \"$state\"
export HOME=\"$state\" ROGUEHOME=\"$state\"
export TERMINFO_DIRS=\"~a${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"
cd -- \"$state\"
exec ~a/srogue \"$@\"~%"
                            shell smoke
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append ncurses "/share/terminfo")
                            libexec)))
                (copy-file #$%srogue-smoke smoke)
                (substitute* smoke
                  (("@SHELL@") shell)
                  (("@COREUTILS@") #$coreutils-minimal)
                  (("@DIFFUTILS@") #$diffutils)
                  (("@UTIL_LINUX@") #$util-linux)
                  (("@OUT@") out))
                (chmod launcher #o555)
                (chmod smoke #o555)))))))
    (native-inputs (list groff))
    (inputs (list bash-minimal coreutils-minimal diffutils ncurses util-linux))
    (home-page "https://rlgallery.org/")
    (synopsis "Robert Kindelberger's expanded version of the Rogue dungeon game")
    (description
     "Super-Rogue is Robert D. Kindelberger's 1984 extension of the classic
terminal game Rogue.  It adds character attributes such as strength,
dexterity, wisdom and constitution, limits on the weight and volume of the
pack, and trading posts where treasure can be bought and sold.  This package
builds version 9.0 from the Roguelike Gallery's collection of early
roguelikes.  Its @command{srogue} launcher keeps saved
games and the personal score list in @file{$XDG_DATA_HOME/srogue}, falling
back to @file{$HOME/.local/share/srogue}; it never writes into the Guix
store.")
    (license srogue-license)))
