;;; GNU Guix package for initrl's CutlassRL.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages cutlassrl)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages python))

;; No release tags exist.  This is the fixed master tip containing upstream
;; VERSION 0.05, fetched directly from the canonical Git repository.
(define %cutlassrl-commit
  "304bb87fc185726f3f7afb08c69564687003d093")

(define-public cutlassrl
  (package
    (name "cutlassrl")
    (version "0.05-0.304bb87")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/stenno/CutlassRL")
             (commit %cutlassrl-commit)))
       (file-name (git-file-name name version))
       ;; Recursive NAR hash of the canonical checkout at the pinned commit.
       (sha256
        (base32
         "1d2dz0c2xlp5xlkn136apbyc1cgfdypfr2k9kds30yy2gv13jk8h"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; CutlassRL has no configure, build, test, or install system.  Its
      ;; Python source is installed under a private runtime root.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (delete 'check)
          (delete 'install-license-files)
          ;; Keep the upstream Python 2 shebang and invoke the declared
          ;; interpreter explicitly from the store-safe launcher below.
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (add-after 'unpack 'enter-source
            (lambda _
              (chdir "CutlassRL/src")))
          (add-after 'enter-source 'locate-level-data
            (lambda _
              ;; Saves belong to the writable launcher CWD; the bundled
              ;; final level belongs to the immutable runtime source tree.
              (substitute* "Game.py"
                (("^#    Copyright \\(c\\) init" copyright)
                 (string-append
                  copyright "\n#\n"
                  "# Modified by the tay Guix channel, 2026-10-09:\n"
                  "# resolve bundled level data beside installed Game.py;\n"
                  "# native saves and logs remain in the writable state directory."))
                (("os\\.path\\.join\\('Levels','last\\.lvl'\\)")
                 "os.path.join(os.path.dirname(__file__), 'Levels', 'last.lvl')"))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (root (string-append out "/libexec/cutlassrl"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/cutlassrl"))
                     (program (string-append root "/main.py"))
                     (launcher (string-append bin "/cutlassrl"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     ;; Guix currently exposes its Python 2.7 package as
                     ;; python-2 (the package name is python2).
                     (python #$(file-append python-2 "/bin/python2"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir")))
                (mkdir-p root)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "main.py" root)
                (install-file "Game.py" root)
                (copy-recursively "Modules" (string-append root "/Modules"))
                (copy-recursively "Levels" (string-append root "/Levels"))
                ;; Keep project GPLv3 text and every source notice, including
                ;; UniCurses' independent GPL3+ grant and Fov's Aaron MacDonald
                ;; permission notice.  __init__.py and Levels/last.lvl have no
                ;; separate notices in the upstream project distribution.
                (install-file "COPYING" root)
                (install-file "../../README" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port "program=~s\npython=~s\nmkdir=~s\n"
                            program python mkdir)
                    (display
                     (string-append
                      "export PYTHONDONTWRITEBYTECODE=1\n"
                      "state=\"${XDG_DATA_HOME:-${HOME:?HOME must be set}"
                      "/.local/share}/cutlassrl\"\n"
                      "\"$mkdir\" -p \"$state\"\n"
                      "cd \"$state\"\n"
                      "exec \"$python\" \"$program\" \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    ;; Python 2.7 is exposed as python-2 by the current Guix channel.
    (inputs (list bash-minimal coreutils-minimal python-2))
    (home-page "https://github.com/stenno/CutlassRL")
    (synopsis "Python terminal roguelike")
    (description
     "CutlassRL is an unfinished Python 2 terminal roguelike by initrl.  It
is built from a fixed upstream commit without a configure or build system,
runtime downloads, or opaque platform binaries.  The installed Python source,
level data, and GPLv3 license are kept under a private libexec directory, with
the bundled final level resolved relative to the installed game source.  The
store-safe launcher runs the game from @file{$XDG_DATA_HOME/cutlassrl}, falling
back to @file{$HOME/.local/share/cutlassrl}, so native saves and logs belong to
the user rather than the immutable package.  Python bytecode writes are disabled.")
    (license
     (list license:gpl3+
           (license:non-copyleft
            "file://Modules/Fov.py"
            "Aaron MacDonald's 2007 field-of-view code permits use and
modification provided its notice is retained.")))))
