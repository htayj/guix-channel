;;; GNU Guix package for the GearHead2 ASCII mecha roguelike.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages gearhead2)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages pascal))

(define %gearhead2-commit
  "415dee8d8730ef1ed8adfd741b1a2b2fa201c2e7")

(define %gearhead2-config-patch
  (local-file
   (search-tay-package-file "patches/gearhead2-xdg-config.patch")))

(define %gearhead2-restore-patch
  (local-file
   (search-tay-package-file "patches/gearhead2-native-restore.patch")))

(define-public gearhead2
  (package
    (name "gearhead2")
    (version "0.701")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/jwvhewitt/gearhead-2")
             (commit %gearhead2-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1h4aab0wl3s971s0h69wgk4amsyfga9gzpmq9l59ji3kh1457cm9"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated test suite or check target.  The external
      ;; terminal driver exercises the installed game, not a bundled mode.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'separate-configuration-and-state
            (lambda _
              ;; The upstream Pascal source uses CRLF.  Normalize only the
              ;; patched files before applying the reviewed LF patch.
              (substitute* '("gears.pp" "pcaction.pp" "arenaplay.pp" "gearutil.pp")
                (("\r") ""))
              (invoke "patch" "-p1" "--fuzz=0" "--no-backup-if-mismatch"
                      "--input" #$%gearhead2-config-patch)
              (invoke "patch" "-p1" "--fuzz=0" "--no-backup-if-mismatch"
                      "--input" #$%gearhead2-restore-patch)))
          (replace 'build
            (lambda _
              (mkdir-p "build/units")
              (invoke #+(file-append fpc "/bin/fpc")
                      "-dASCII" "-O2" "-g-"
                      "-FUbuild/units" "-FEbuild"
                      "-obuild/gearhead2-real" "gearhead2.pas")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (real (string-append libexec "/gearhead2-real"))
                     (data (string-append out "/share/gearhead2"))
                     (doc (string-append out "/share/doc/gearhead2"))
                     (launcher (string-append bin "/gearhead2")))
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "build/gearhead2-real" libexec)
                ;; Retain relative paths consumed by the ASCII game, but never
                ;; install PNG images, .obj meshes, fonts or SDL libraries.
                ;; sdl_colors.txt is a text palette used even by the ASCII UI.
                (for-each
                 (lambda (directory)
                   (mkdir-p (string-append data "/" directory))
                   (for-each
                    (lambda (file)
                      (let ((target (string-append data "/" file)))
                        (mkdir-p (dirname target))
                        (copy-file file target)))
                    (find-files directory "\\.txt$")))
                 '("gamedata" "design" "series" "doc"))
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "readme.txt" "history.txt"
                            "doc/Credits.txt"))
                ;; The executable embeds FPC RTL code even though the compiler
                ;; is native-only.  Its installed docs omit the LGPL companion,
                ;; so take the complete notice and exception from that exact
                ;; compiler's hash-verified source, not from a floating URL.
                (mkdir-p "build/fpc-notices")
                (invoke "tar" "-xf" #+(package-source fpc)
                        "-C" "build/fpc-notices" "--wildcards"
                        "*/install/doc/COPYING" "*/fpcsrc/rtl/COPYING.FPC")
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/fpc-rtl")))
                 (find-files "build/fpc-notices" "^COPYING(\\.FPC)?$"))
                (for-each
                 (lambda (input)
                   (let* ((root (car input))
                          (target (string-append doc "/third-party-licenses/"
                                                 (cdr input)))
                          (notices
                           (find-files
                            root
                            "^(COPYING|LICENSE|COPYRIGHT|NOTICE)([-.].*)?$")))
                     (unless (pair? notices)
                       (error "runtime dependency has no license notice"
                              (cdr input)))
                     (for-each (lambda (file) (install-file file target))
                               notices)))
                 (list (cons #$bash-minimal "bash")
                       (cons #$coreutils-minimal "coreutils")))
                (call-with-output-file (string-append doc "/SOURCE-PROVENANCE")
                  (lambda (port)
                    (format port
                            (string-append
                             "GearHead2 ~a, native ASCII build~%"
                             "Source: https://github.com/jwvhewitt/gearhead-2~%"
                             "Commit: ~a~%~%")
                            #$version #$%gearhead2-commit)
                    (display
                     (string-append
                      "The GearHead Universe and GearHead2 are copyright 2005\n"
                      "Joseph Hewitt.  The Pascal sources and installed game text\n"
                      "are distributed under LGPL-2.1-or-later; see license.txt\n"
                      "and the retained upstream credits in Credits.txt.\n\n"
                      "This package builds gearhead2.pas with Free Pascal and\n"
                      "-dASCII -O2 -g-.  Free Pascal is a native build input only.\n"
                      "The executable embeds the Free Pascal Runtime Library,\n"
                      "licensed under the Library GPL with its linking exception;\n"
                      "see fpc-rtl/COPYING and fpc-rtl/COPYING.FPC.\n"
                      "Shell and utility license notices are retained under\n"
                      "third-party-licenses/.\n"
                      "The configuration-path patch separates the XDG config file\n"
                      "from the positional save/report directory.  The launcher\n"
                      "runs against immutable text data, with writable user state.\n\n"
                      "The restore patch resumes paused clock-mode player input\n"
                      "without replaying the tick or scene-start triggers and\n"
                      "preserves every serialized string attribute.\n\n"
                      "Only .txt files from gamedata, design, series and doc are\n"
                      "installed as game data.  Graphical PNG assets, .obj meshes,\n"
                      "fonts, SDL libraries and unrelated tools are excluded:\n"
                      "they are not needed by the native ASCII game.  The ordinary\n"
                      "launcher uses Guix bash-minimal and coreutils-minimal.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%"
                            #$(file-append bash-minimal "/bin/sh"))
                    (format port "real=~s~%data=~s~%mkdir=~s~%"
                            real data
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (display
                     (string-append
                      "config_root=\"${XDG_CONFIG_HOME:-${HOME:?HOME or "
                      "XDG_CONFIG_HOME must be set}/.config}\"\n"
                      "case \"$config_root\" in\n"
                      "  /*) ;;\n"
                      "  *) config_root=\"$PWD/$config_root\" ;;\n"
                      "esac\n"
                      "export XDG_CONFIG_HOME=\"$config_root\"\n"
                      "if test \"$#\" -eq 0; then\n"
                      "  state_root=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}\"\n"
                      "  set -- \"$state_root/gearhead2\"\n"
                      "fi\n"
                      "state=$1\n"
                      "shift\n"
                      "case \"$state\" in\n"
                      "  /*) ;;\n"
                      "  *) state=\"$PWD/$state\" ;;\n"
                      "esac\n"
                      "\"$mkdir\" -p -- \"$config_root/gearhead2\" \"$state\"\n"
                      "cd \"$data\"\n"
                      "exec \"$real\" \"$state\" \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (native-inputs (list fpc))
    (inputs (list bash-minimal coreutils-minimal))
    (home-page "https://github.com/jwvhewitt/gearhead-2")
    (synopsis "science-fiction mecha roguelike with an ASCII interface")
    (description
     "GearHead2 is a science-fiction role-playing roguelike featuring mecha
combat, character development and generated adventures in the GearHead universe.
This package builds the native ASCII interface from the pinned Pascal source and
installs its text game data and documentation without graphical assets or SDL
libraries.  The launcher reads immutable shared game data, stores gearhead2.cfg
under XDG_CONFIG_HOME, and keeps saves and reports under XDG_STATE_HOME by default.
An explicit first positional directory selects an alternative save/report location.")
    (license license:lgpl2.1+)))
