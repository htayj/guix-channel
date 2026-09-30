;;; GNU Guix package for UltraRogue 1.0.8.

(define-module (tay packages ultrarogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses))

;; The upstream repository has no release tags.  README.md and rogue/vers.c
;; identify this revision as 1.0.8 (January 2026).  Its 60-file tree is
;; identical to GitHub's archive of the commit (SHA-256
;; 995317d014309e18ec1816fb5b3e831882d81668ed68d0305bb425d63c7f190d).
(define %urogue-commit "0cebe8a805d64e9593fd4e84790e9c0b2353f169")

;; LICENSE.TXT attributes the inherited code to Herb Chong, Michael Morgan
;; and Ken Dalka, Rogue's authors, and Nicholas J. Kisseberth, each under
;; BSD-3-Clause terms.  Herb Chong's conditions 4 and 5 additionally restrict
;; using "UltraRogue" or "urogue" to endorse or name derived products, so
;; this is not the unmodified BSD-3-Clause license.  Earl Fogel's 2018+
;; changes are dedicated with "no rights reserved".
(define ultrarogue-license
  (license:non-copyleft
   (string-append "https://github.com/earlfogel/UltraRogue/blob/"
                  %urogue-commit "/LICENSE.TXT")
   "BSD-3-Clause terms plus UltraRogue/urogue naming conditions"))

(define-public urogue
  (package
    (name "urogue")
    (version "1.0.8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/earlfogel/UltraRogue")
             (commit %urogue-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0bbid7p6kxj5xh2ccwwqwr50bk22iwc2qfi3r115ygkpyc4bp5yi"))
       (patches
        (search-patches "tay/packages/patches/urogue-portable-state.patch"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; No configure script or automated tests upstream;
      ;; tests/urogue-smoke.sh plays, saves, restores and scores a game.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target)) "CRLIB=-lncurses")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (with-directory-excursion "rogue"
                (apply invoke "make" "urogue" make-flags))))
          (replace 'install
            ;; Upstream's install target copies into its author's home.
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec"))
                    (doc (string-append #$output "/share/doc/urogue-"
                                        #$version))
                    (launcher (string-append #$output "/bin/urogue")))
                (mkdir-p bin)
                (install-file "rogue/urogue" libexec)
                ;; The licenses, documentation, and the original author's
                ;; README with its distribution notes.
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "README.md" "CHANGELOG" "INSTALL"
                            "extras/README.orig" "extras/spoilers.txt"))
                ;; UltraRogue keeps its save, character and score files in
                ;; HOME.  The launcher points HOME at the XDG data directory.
                ;; The file names need a slash and up to ten more bytes in
                ;; fixed 80-byte buffers, so reject longer directories
                ;; before creating anything.  ${#state} counts characters in
                ;; UTF-8 locales, so count bytes in a C-locale subshell.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh
set -eu
case \"${XDG_DATA_HOME:-}\" in
  /*) state=\"$XDG_DATA_HOME/urogue\" ;;
  *) state=\"${HOME:?HOME or XDG_DATA_HOME must be set}\"
     state=\"$state/.local/share/urogue\" ;;
esac
state_bytes=$(LC_ALL=C; printf %s \"${#state}\")
if [ \"$state_bytes\" -gt 68 ]; then
  echo 'urogue: state directory is too long (at most 68 bytes)' >&2
  exit 1
fi
~a/bin/mkdir -p -- \"$state\"
export HOME=\"$state\"
exec ~a/libexec/urogue \"$@\"~%"
                            #$bash-minimal #$coreutils-minimal #$output)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://github.com/earlfogel/UltraRogue")
    (synopsis "Classic terminal dungeon crawl with an expanded bestiary")
    (description
     "UltraRogue is a terminal dungeon-crawling game derived from Advanced
Rogue.  Players choose a fighter, magician, cleric or thief, descend through
randomly generated levels, and search for the artifacts guarded by an
expanded bestiary.  This package builds Earl Fogel's 1.0.8 revision.  Its
launcher keeps saves, character settings, and scores in
@file{$XDG_DATA_HOME/urogue}, falling back to
@file{$HOME/.local/share/urogue}; it never writes into the Guix store.")
    (license ultrarogue-license)))
