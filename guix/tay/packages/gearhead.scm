;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; GearHead: Arena ASCII edition.  The SDL image/font closure is not shipped.

(define-module (tay packages gearhead)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages pascal)
  #:use-module (tay packages auxiliary))

(define-public gearhead
  (package
    (name "gearhead")
    (version "1.310")
    (source
     (origin
       (method url-fetch)
       ;; v1.310 (2019-02-07), peeled release commit, not a moving branch.
       (uri (string-append
             "https://codeload.github.com/jwvhewitt/gearhead-1/tar.gz/"
             "4314041f9e703e356807a9d17e613aae09289df4"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256: a2f120f006d72eef9408e558dd0a569f0a04c06cbf0a447063a934943a419af6.
       (sha256
        (base32 "1xls84x98d59cdq482mzdk0082lzaq5dsn7512afybnp0vq21wd2"))
       (patches
        (list (search-tay-package-file "patches/gearhead-writable-maps.patch")
              (search-tay-package-file "patches/gearhead-resume.patch")))
       ;; Upstream Pascal sources use CRLF; GNU patch must not strip it.
       (patch-flags '("-p1" "--binary"))
       (modules '((guix build utils)))
       (snippet
        ;; Image contains the graphical assets and bundled fonts.  Neither
        ;; those nor the optional SDL/alternate boxdrawing ports are used.
        #~(for-each delete-file-recursively
                    '("Image" "sdlgfx.pp" "sdlinfo.pp" "sdlmap.pp"
                      "sdlmenus.pp" "cosplay.pas" "xterm-boxdrawing"
                      "GameData/sdl_colors.txt")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream supplies no automated test suite.  The external runner in
      ;; tests/gearhead-smoke.sh exercises the unchanged native game interface.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'extract-fpc-rtl-notices
            (lambda _
              ;; FPC links its runtime into gharena.  Keep the Library GPL
              ;; and its linking exception from the compiler's pinned source.
              (mkdir-p "build/fpc-notices")
              (invoke "tar" "-xf" #+(package-source fpc)
                      "-C" "build/fpc-notices" "--wildcards"
                      "*/install/doc/COPYING" "*/fpcsrc/rtl/COPYING.FPC")))
          (replace 'build
            (lambda _
              (mkdir-p "build/units")
              (invoke #$(file-append fpc "/bin/fpc")
                      "-O2" "-g-" "-FUbuild/units" "-FEbuild"
                      "-obuild/gharena" "gharena.pas")))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (data (string-append #$output "/share/gearhead"))
                     (doc (string-append #$output "/share/doc/gearhead"))
                     (launcher (string-append bin "/gearhead")))
                (install-file "build/gharena" libexec)
                ;; Text-only runtime closure; the upstream readme's LGPL
                ;; distribution statement covers these data directories.
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append data "/" directory)))
                 '("Design" "GameData" "Series" "doc"))
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "readme.md" "history.txt"
                            "compiling.txt" "doc/Credits.txt" "gharena.pas"))
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/fpc-rtl")))
                 (find-files "build/fpc-notices" "^COPYING(\\.FPC)?$"))
                (call-with-output-file (string-append doc "/SOURCE-PROVENANCE")
                  (lambda (port)
                    (display
                     (string-append
                      "GearHead: Arena v1.310 (ASCII)\n"
                      "Upstream: https://github.com/jwvhewitt/gearhead-1\n"
                      "Commit: 4314041f9e703e356807a9d17e613aae09289df4\n"
                      "Archive SHA-256: "
                      "a2f120f006d72eef9408e558dd0a569f0a04c06cbf0a447063a934943a419af6\n"
                      "\n"
                      "LGPL-2.1-or-later: Pascal code and text-only Design, GameData, "
                      "Series and doc.\n"
                      "See readme.md distribution statement, gharena.pas copyright "
                      "header, and license.txt.\n"
                      "Image (including all bundled fonts), SDL sources and optional "
                      "xterm-boxdrawing\n"
                      "are excluded.  No image, font, audio, or prebuilt program is "
                      "installed.\n"
                      "\n"
                      "The local map-editor patch saves user maps in Config_Directory "
                      "rather than\n"
                      "the immutable Series directory, and permits loading both user "
                      "and shipped maps.\n"
                      "\n"
                      "The native combat-resume patch preserves the paused actor,\n"
                      "clock and completed scene initialization on ASCII reload.\n"
                      "It restores the complete saved string attributes verbatim.\n"
                      "Tactics mode is unchanged; legacy/startup saves without the\n"
                      "scene-initialized marker retain original entry behavior.\n\n"
                      "The gearhead launcher accepts the native optional "
                      "CONFIG-DIRECTORY argument.\n"
                      "With no argument it uses absolute XDG_STATE_HOME/gearhead, or\n"
                      "HOME/.local/state/gearhead.  gharena.cfg, SaveGame and user maps "
                      "stay there.\n"
                      "Game data is read from the store.  There is no installed smoke "
                      "mode.\n")
                     port)))
                (call-with-output-file (string-append doc "/fpc-rtl/PROVENANCE")
                  (lambda (port)
                    (format port
                            (string-append
                             "Linked Free Pascal RTL, compiler version ~a.~%"
                             "COPYING and COPYING.FPC are extracted from "
                             "the pinned Guix fpc "
                             "source.~%"
                             "Library GPL version 2 or later, "
                             "with the independent-module "
                             "linking exception.~%")
                            #$(package-version fpc))))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%"
                            #$(file-append bash-minimal "/bin/sh"))
                    (display
                     (string-append
                      "if [ \"$#\" -gt 1 ]; then\n"
                      "  echo 'usage: gearhead [CONFIG-DIRECTORY]' >&2\n"
                      "  exit 2\n"
                      "fi\n"
                      "if [ \"$#\" -eq 1 ]; then\n"
                      "  state=$1\n"
                      "else\n"
                      "  case \"${XDG_STATE_HOME:-}\" in\n"
                      "    /*) state=$XDG_STATE_HOME/gearhead ;;\n"
                      "    *) state=${HOME:?HOME must be set}/.local/state/gearhead ;;\n"
                      "  esac\n"
                      "fi\n"
                      "case \"$state\" in\n"
                      "  /*) ;;\n"
                      "  *) state=$PWD/$state ;;\n"
                      "esac\n"
                      "umask 077\n")
                     port)
                    (format port "~a -p -- \"$state\"~%cd ~s~%exec ~s \"$state\"~%"
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            data (string-append libexec "/gharena"))))
                (chmod launcher #o555)))))))
    (native-inputs (list fpc))
    (inputs (list bash-minimal coreutils-minimal))
    (home-page "https://www.gearheadrpg.com/")
    (synopsis "Mecha role-playing roguelike with an ASCII interface")
    (description
     "GearHead: Arena is a science-fiction roguelike role-playing game with
procedural campaigns, character development, and mecha combat.  This package
builds the ASCII edition with Free Pascal and includes only the text-based game
data and documentation, without the graphical assets, bundled fonts, or SDL
edition.  Configuration, saved games, and edited maps are kept outside the
store in a user-selected directory.")
    (license license:lgpl2.1+)))
