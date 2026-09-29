;;; GNU Guix package for XRogue: Expeditions into the Dungeons of Doom.

(define-module (tay packages xrogue)
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

;; The repository publishes no release tag.  This is its sole master
;; revision, committed on 2011-09-29 by the Roguelike Restoration Project.
(define %xrogue-commit
  "544e05aa5ff86884f87569fd5c8810005e8ea6e8")

;; LICENSE.TXT combines per-author notices for XRogue, the incorporated
;; Advanced Rogue and Rogue portions, Nicholas J. Kisseberth's save/restore
;; code, and David Burren's FreeSec encryption code.  Each notice has the
;; three New BSD conditions, but the XRogue and Advanced Rogue notices add two
;; clauses: the names "XRogue", "Advanced Rogue", and "ARogue" may not be used
;; to endorse or promote derived products, and derived products may not be
;; called by or include those names, without prior written permission.
;; Those additional naming conditions mean this is not Guix's unmodified
;; BSD-3-Clause record.
(define xrogue-license
  (license:non-copyleft
   (string-append "https://github.com/RoguelikeRestorationProject/xrogue/"
                  "blob/" %xrogue-commit "/LICENSE.TXT")
   "BSD-3-Clause terms plus XRogue and Advanced Rogue naming conditions"))

(define-public xrogue
  (package
    (name "xrogue")
    ;; README.TXT announces XRogue 8.0.3; vers.c reports release "8.0.3",
    ;; dated 12/10/2005.
    (version "8.0.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/RoguelikeRestorationProject/xrogue")
             (commit %xrogue-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "13f5ng2ih21ys4wjmkinbs5hbvv2jrrdm4xvllfnzw9jfp7dswd6"))
       (patches
        (search-patches "tay/packages/patches/xrogue-portable-state.patch"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream ships no configure script and no automated test suite.  The
      ;; installed program, including play, save, restore, and score listing,
      ;; is covered by tests/xrogue-smoke.sh.
      #:tests? #f
      #:make-flags
      ;; This 1991 source is written in K&R C.  It relies on the common symbol
      ;; model that -fcommon restores, and on implicit int, implicit function
      ;; declarations, and loose pointer and return typing, which GCC 14
      ;; rejects as errors by default.  Demote exactly those diagnostics.
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "CFLAGS=-O2 -fcommon"
                             " -Wno-error=implicit-int"
                             " -Wno-error=implicit-function-declaration"
                             " -Wno-error=int-conversion"
                             " -Wno-error=incompatible-pointer-types"
                             " -Wno-error=return-mismatch"
                             " -Wno-error=declaration-missing-parameter-type")
              "CRLIB=-lncurses")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "xrogue" make-flags)))
          (replace 'install
            (lambda _
              ;; Upstream's Makefile has no install target; its "dist" targets
              ;; only build tarballs.  Install the program privately and
              ;; expose it through a launcher that keeps all mutable state
              ;; outside the immutable store.
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec"))
                    (doc (string-append #$output "/share/doc/xrogue")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "xrogue" libexec)
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.TXT" "README.TXT"))
                (call-with-output-file (string-append bin "/xrogue")
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display "set -eu\n" port)
                    ;; The XDG base directory specification requires relative
                    ;; values to be ignored.
                    (display "case \"${XDG_DATA_HOME:-}\" in\n" port)
                    (display "  /*) state=\"$XDG_DATA_HOME/xrogue\" ;;\n" port)
                    (display (string-append
                              "  *) state=\"${HOME:?HOME or XDG_DATA_HOME"
                              " must be set}/.local/share/xrogue\" ;;\n")
                             port)
                    (display "esac\n" port)
                    ;; md_getroguedir() only honours ROGUEHOME when that
                    ;; directory already exists, so create it first.  The
                    ;; patched program keeps both the score file and saved
                    ;; games there.
                    (format port "~a/bin/mkdir -p \"$state\"~%"
                            #$coreutils-minimal)
                    (display "export ROGUEHOME=\"$state\"\n" port)
                    ;; Let the dynamically linked program find the terminfo
                    ;; database supplied by its own ncurses input.
                    (format port
                            (string-append
                             "export TERMINFO_DIRS=\"~a/share/terminfo"
                             "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            #$ncurses)
                    (format port "exec ~a/libexec/xrogue \"$@\"~%"
                            #$output)))
                (chmod (string-append bin "/xrogue") #o555)))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://github.com/RoguelikeRestorationProject/xrogue")
    (synopsis "Expeditions into the Dungeons of Doom, release 8.0.3")
    (description
     "XRogue is a terminal dungeon-crawling game derived from Advanced Rogue
and the original Rogue.  This package builds release 8.0.3 from the fixed
Roguelike Restoration Project source revision.  The launcher keeps the score
file and saved games under @file{$XDG_DATA_HOME/xrogue}, or
@file{$HOME/.local/share/xrogue} when @env{XDG_DATA_HOME} is unset, so the
store is never written to at runtime.  Remote score propagation is disabled by
upstream's empty @code{NETCOMMAND}, and the package performs no build-time or
runtime downloads.  The complete upstream license and README notices are
installed under @file{share/doc/xrogue}.")
    (license xrogue-license)))
