;;; GNU Guix package for the Avanor terminal roguelike.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages avanor)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses))

(define-public avanor
  (package
    (name "avanor")
    (version "0.5.8")
    (source
     (origin
       (method url-fetch)
       ;; This is the last stable upstream release (SVN r126, 2006-05-30).
       ;; The archive contains only source, documentation, and the GPL texts.
       (uri (string-append
             "https://downloads.sourceforge.net/project/avanor/avanor/"
             version "/avanor-" version "-src.tar.bz2"))
       (sha256
        (base32 "1wwy6whp6d293iy9gg6vc0mnw2hagp43y9i0aad0niw5v61vwmcg"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                         ;No upstream check target.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'modernize-source
            (lambda _
              ;; Clang rejects NULL as the return value of this integer method.
              (substitute* "creature/Uniquem.cpp"
                (("return NULL;") "return 0;"))
              ;; GCC 14 rejects taking the address of this temporary.  Setup
              ;; copies the rectangle, so a local object is behaviorally equal.
              (substitute* "game/cave.cpp"
                (("r.Setup\\(&XRect\\(x, y, x \\+ l, y \\+ h\\)\\);")
                 "XRect bounds(x, y, x + l, y + h);\n\tr.Setup(&bounds);"))
              ;; Scores are mutable player state, not common immutable data.
              (substitute* "helpers/hiscore.h"
                (("vMakePath\\(DATA_DIR, \"avanor.hsc\"\\)")
                 "vMakePath(HOME_DIR, \"avanor.hsc\")"))))
          (replace 'build
            (lambda _
              ;; Keep upstream's CFLAGS and supply Guix's compiler and flags.
              (let ((cxx (or (getenv "CXX") "g++"))
                    (cxxflags (or (getenv "CXXFLAGS") "")))
                (invoke "make"
                        (string-append "VERSION=" #$version)
                        (string-append "CC=" cxx)
                        (string-append "LD=" cxx)
                        (string-append "DATA_DIR=" #$output "/share/avanor/")
                        "LIBS=-lncurses"
                        (string-append "OPTFLAGS=" cxxflags)))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/avanor"))
                     (manual (string-append data "/manual"))
                     (doc (string-append out "/share/doc/avanor"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/avanor")))
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (copy-recursively "manual" manual)
                (install-file "avanor" libexec)
                ;; COPYING/gpl.txt cover the source and manual; README and
                ;; credits retain the upstream attribution for those assets.
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "gpl.txt" "README.txt"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~
if test \"${1-}\" = --guix-smoke; then~%
  test \"$#\" -eq 1~%
  printf '%s\\n' AVANOR_RUNTIME_OK~%
  exit 0~%
fi~%
state_root=\"${XDG_STATE_HOME:-${HOME:?}/.local/state}\"~%
state=\"$state_root/.avanor\"~%
~a -p \"$state\"~%
if test ! -e \"$state/avanor.hsc\"; then~%
  : > \"$state/avanor.hsc\"~%
fi~%
export HOME=\"$state_root\"~%
export TERMINFO_DIRS=~s~%
cd \"$state\"~%
exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append ncurses "/share/terminfo")
                            (string-append libexec "/avanor"))))
                (chmod launcher #o555))))
          (add-after 'install 'verify-installed-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/avanor/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing Avanor notice" file)))
                 '("COPYING" "gpl.txt" "README.txt"))
                (invoke "grep" "-F" "GNU GENERAL PUBLIC LICENSE"
                        (string-append doc "COPYING"))
                (invoke "grep" "-F" "version 2" (string-append doc "gpl.txt"))
                (invoke "grep" "-F" "Avanor" (string-append doc "README.txt"))
                (unless (file-exists? (string-append #$output
                                                   "/share/avanor/manual/credits.html"))
                  (error "missing Avanor manual credits"))))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://sourceforge.net/projects/avanor/")
    (synopsis "Terminal roguelike game")
    (description
     "Avanor is a terminal roguelike game.  It is built from the fixed 0.5.8
upstream source release with no build-time or runtime downloads.  Its launcher
keeps saves, high scores, recipes, and diagnostics in @file{$XDG_STATE_HOME/.avanor}
and reads its manual only from the immutable package output.")
    (license license:gpl2+)))
