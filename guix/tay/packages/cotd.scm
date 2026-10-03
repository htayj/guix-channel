;;; City of the Damned -- the original SBCL/SDL game.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages cotd)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-d-h))

(define-public sbcl-defenum
  (let ((commit "893dbdca4a76342ae24dcd73aacede79a2ccd159"))
    (package
      (name "sbcl-defenum")
      (version (git-version "0" "0" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.code.sf.net/p/defenum/code")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1h6wqdca9f0scwm9qsnhh9hsqsr2cnk9p3qhsjk3gh1p6ah6bd3c"))))
      (build-system asdf-build-system/sbcl)
      (arguments (list #:asd-systems ''("defenum")
                       #:tests? #f)) ; No upstream test system.
      (home-page "https://defenum.sourceforge.net/")
      (synopsis "Enumeration types for Common Lisp")
      (description
       "DEFENUM defines C++ and Java-style enumeration types in Common Lisp.
This package builds the original SourceForge implementation without optional
CL-ENUMERATIONS integration.")
      ;; ASDF says BSD; COPYING actually grants this custom permissive license.
      (license (license:non-copyleft
                "https://git.code.sf.net/p/defenum/code/blob/893dbdca4a76342ae24dcd73aacede79a2ccd159/COPYING"
                "Permission to use, copy, modify and distribute for any purpose with notices preserved.")))))

(define-public cotd
  (package
    (name "cotd")
    ;; README calls this 2.0.2; ASDF still says 1.0.5.  Identify the tree rather
    ;; than pretend the stale ASDF version is the latest release.
    (version (git-version "2.0.2" "0"
                          "b771e2e0bbf0bbe08d50cb32124dc3903dc74cd4"))
    (source (package-source gwathlobal-cotd-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("cotd")
      #:tests? #f ; No upstream test system; ASDF compiles the entire game.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-game
            (lambda _
              (let ((assets (string-append #$output "/share/cotd"))
                    (doc (string-append #$output "/share/doc/cotd")))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md" "CHANGELOG.txt"
                            "COMPILING.txt" "COMPILE-DEPENDECIES.txt"))
                (copy-recursively "src/data" (string-append assets "/data"))
                (copy-recursively "src/help" (string-append assets "/help"))
                (chdir "src")
                ;; Separate immutable artwork/help from save files, options,
                ;; highscores, logs and character dumps in the working directory.
                (substitute* "file-storage.lisp"
                  (("filename \\*current-dir\\*")
                   (string-append "filename #P\"" assets "/\"")))
                (substitute* "cotd.lisp"
                  (("tiles-path \\*current-dir\\*")
                   (string-append "tiles-path #P\"" assets "/\""))
                  (("\"libSDL-1.2.so.0.7.2\"")
                   (string-append "\"" #$sdl "/lib/libSDL-1.2.so.0\"")))
                (delete-file-recursively "data")
                (delete-file-recursively "help"))))
          ;; Ordinary FASLs, not a dumped build-time SBCL heap.  Guix ASDF
          ;; normalizes timestamps and records the complete compiled closure.
          (add-after 'create-asdf-configuration 'install-launcher
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (launcher (string-append bin "/cotd")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-file #$(local-file
                              (search-tay-package-file "cotd-entry.lisp"))
                           (string-append libexec "/cotd.lisp"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\numask 077\n"
                            #$(file-append bash-minimal "/bin/sh"))
                    (display
                     (string-append "if [ \"$#\" -ne 0 ]; then "
                                    "echo 'Usage: cotd' >&2; exit 2; fi\n")
                     port)
                    (format port "export COTD_ASDF_CONFIG=~s\n"
                            (string-append #$output "/etc/xdg/common-lisp/"))
                    (display
                     (string-append "state=\"${XDG_STATE_HOME:-${HOME:?"
                                    "HOME or XDG_STATE_HOME required}"
                                    "/.local/state}/cotd\"\n")
                     port)
                    (format port "~a -p -- \"$state\"\ncd -- \"$state\"\n"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (format port
                            (string-append "exec ~a --noinform --no-userinit"
                                           " --no-sysinit --script ~a\n")
                            #$(file-append sbcl "/bin/sbcl")
                            (string-append libexec "/cotd.lisp"))))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal sbcl sdl
                  sbcl-lispbuilder-sdl sbcl-bordeaux-threads sbcl-defenum
                  sbcl-cl-store sbcl-log4cl))
    (home-page "https://github.com/gwathlobal/CotD")
    (synopsis "SDL roguelike battle of angels and demons in a human city")
    (description
     "City of the Damned is the original Common Lisp roguelike with an SDL
interface.  Play custom scenarios or a strategic campaign, choosing an angel,
demon, soldier or other faction.  The source-built game retains its original
artwork, help, combat, map generation and save/load facilities.  Mutable files
are stored in XDG_STATE_HOME/cotd, defaulting to HOME/.local/state/cotd; packaged
artwork and help remain read-only.  No Quicklisp or release-binary downloads
are performed.")
    (license license:gpl3)))
