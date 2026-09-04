;;; GNU Guix package for Dungeon Monkey Unlimited.
;;;
;;; SPDX-License-Identifier: LGPL-2.1-only

(define-module (tay packages dungeon-monkey-unlimited)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages pascal)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages xorg))

(define dmu-smoke-source
  (local-file "dungeon-monkey-unlimited-smoke.pas"))

(define-public dungeon-monkey-unlimited
  (package
    (name "dungeon-monkey-unlimited")
    (version "1.001")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://downloads.sourceforge.net/project/dmonkey/v1.000%20Series/"
         "DungeonMonkeyUnlimited-1.001-source.zip"))
       (sha256
        (base32
         "1p796097xgyykvax2piv8k04g9asdr2wnfd9aigzayjpfh6yswpp"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream archive has no build system or automated test target.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              (copy-file #$dmu-smoke-source "dmu-smoke.pas")))
          (replace 'build
            (lambda _
              (let ((fpc #$(file-append fpc "/bin/fpc"))
                    (sdl-units
                     #$(file-append fpc
                                    "/lib/fpc/3.2.2/units/x86_64-linux/sdl"))
                    (sdl #$(file-append sdl12-compat "/lib"))
                    (sdl-image #$(file-append sdl-image "/lib"))
                    (sdl-ttf #$(file-append sdl-ttf "/lib"))
                    (x11 #$(file-append libx11 "/lib")))
                (mkdir-p "build/units")
                (define (compile source output)
                  (invoke fpc
                          "-O2" "-g-" "-dLINUX"
                          "-Fu."
                          (string-append "-Fu" sdl-units)
                          "-FUbuild/units"
                          "-FEbuild"
                          (string-append "-Fl" sdl)
                          (string-append "-Fl" sdl-image)
                          (string-append "-Fl" sdl-ttf)
                          (string-append "-Fl" x11)
                          (string-append "-k-L" sdl)
                          (string-append "-k-L" sdl-image)
                          (string-append "-k-L" sdl-ttf)
                          (string-append "-k-L" x11)
                          (string-append "-k-rpath=" x11)
                          "-k-lSDL"
                          "-k-lSDL_image"
                          "-k-lSDL_ttf"
                          (string-append "-o" output)
                          source))
                (compile "dmu.pas" "build/dungeon-monkey-unlimited-real")
                (compile "dmu-smoke.pas" "build/dungeon-monkey-unlimited-smoke"))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (data (string-append out "/share/dungeon-monkey-unlimited"))
                     (graphics (string-append data "/image"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/dungeon-monkey-unlimited"))
                     (launcher (string-append bin "/dungeon-monkey-unlimited"))
                     (real (string-append libexec "/dungeon-monkey-unlimited-real"))
                     (smoke (string-append libexec "/dungeon-monkey-unlimited-smoke")))
                (mkdir-p bin)
                (mkdir-p graphics)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "build/dungeon-monkey-unlimited-real" libexec)
                (install-file "build/dungeon-monkey-unlimited-smoke" libexec)
                (copy-recursively "gamedata" (string-append data "/gamedata"))
                (for-each (lambda (file) (install-file file graphics))
                          (find-files "image" "\\.png$"))
                (install-file "image/VeraBd.ttf" graphics)
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "readme.txt" "credits.txt"))
                (copy-recursively "doc" (string-append doc "/upstream-doc"))
                ;; VeraBd.ttf is the unmodified Bitstream Vera bold font.
                ;; Install the exact notice shipped by Guix's font package.
                (copy-file
                 #$(file-append font-bitstream-vera
                                "/share/doc/font-bitstream-vera-1.10/COPYRIGHT.TXT")
                 (string-append doc "/Bitstream-Vera-COPYRIGHT.TXT"))
                (call-with-output-file (string-append doc "/THIRD-PARTY-NOTICES.txt")
                  (lambda (port)
                    (display "Dungeon Monkey Unlimited third-party materials\n\n" port)
                    (display "David E. Gervais tile graphics\n" port)
                    (display
                     (string-append
                      "Most tile graphics are by David E. Gervais and are\n"
                      "available under the Creative Commons Attribution 3.0\n")
                     port)
                    (display
                     (string-append
                      "license. Credit David E. Gervais when redistributing\n"
                      "these graphics.\n")
                     port)
                    (display "https://creativecommons.org/licenses/by/3.0/\n\n" port)
                    (display "RLTiles\n" port)
                    (display
                     (string-append
                      "Part of (or All) the graphic tiles used in this "
                      "program is the public domain roguelike tileset "
                      "\"RLTiles\".\n")
                     port)
                    (display
                     (string-append
                      "Some of the tiles have been modified by Joseph\n"
                      "Hewitt.\n\n")
                     port)
                    (display "You can find the original tileset at:\n" port)
                    (display "http://rltiles.sf.net\n\n" port)
                    (display "Bitstream Vera\n" port)
                    (display
                     (string-append
                      "The used VeraBd.ttf is distributed under the\n"
                      "Bitstream Vera license.\n")
                     port)
                    (display "license. The complete, exact license text is in\n" port)
                    (display "Bitstream-Vera-COPYRIGHT.TXT in this directory.\n" port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (format port "real=~s~%data=~s~%smoke=~s~%"
                            real data smoke)
                    (format port "ln=~s~%mkdir=~s~%mktemp=~s~%rm=~s~%"
                            #$(file-append coreutils-minimal "/bin/ln")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm"))
                    (display
                     (string-append
                      "usage() { echo 'usage: dungeon-monkey-unlimited "
                      "[--smoke]' >&2; exit 64; }\n")
                     port)
                    (display
                     (string-append
                      "case \"${1-}\" in\n"
                      "  --smoke)\n"
                      "    test \"$#\" -eq 1 || usage\n"
                      (string-append
                       "    scratch=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/dungeon-"
                       "monkey-unlimited-smoke.XXXXXXXX\")\n")
                      "    trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n"
                      (string-append
                       "    \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\" "
                       "\"$scratch/data\" \"$scratch/cache\" \"$scratch/state\" "
                       "\"$scratch/runtime\" \"$scratch/tmp\" "
                       "\"$scratch/work/savegame\"\n")
                      "    \"$ln\" -s \"$data/gamedata\" \"$scratch/work/gamedata\"\n"
                      "    \"$ln\" -s \"$data/image\" \"$scratch/work/image\"\n"
                      (string-append
                       "    export HOME=\"$scratch/home\"\n"
                       "    export XDG_CONFIG_HOME=\"$scratch/config\"\n"
                       "    export XDG_DATA_HOME=\"$scratch/data\"\n")
                      (string-append
                       "    export XDG_CACHE_HOME=\"$scratch/cache\"\n"
                       "    export XDG_STATE_HOME=\"$scratch/state\"\n"
                       "    export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n"
                       "    export TMPDIR=\"$scratch/tmp\"\n")
                      "    export SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy LC_ALL=C\n"
                      "    cd \"$scratch/work\"\n"
                      "    proof=$(\"$smoke\" 2>&1)\n"
                      "    case \"$proof\" in\n"
                      "      *'DMU-SMOKE: campaign-save-load-ok'*) ;;\n"
                      "      *) echo 'Dungeon Monkey smoke failed' >&2; exit 1 ;;\n"
                      "    esac\n"
                      "    printf '%s\\n' 'DMU-SMOKE: campaign-save-load-ok'\n"
                      "    exit 0\n"
                      "    ;;\n"
                      "  '') ;;\n"
                      "  *) ;;\n"
                      "esac\n"
                      (string-append
                       "state=\"${XDG_DATA_HOME:-${HOME:?HOME or XDG_DATA_HOME "
                       "must be set}/.local/share}/dungeon-monkey-unlimited\"\n")
                      "\"$mkdir\" -p \"$state/savegame\"\n"
                      "for resource in gamedata image; do\n"
                      "  if test ! -e \"$state/$resource\"; then\n"
                      "    \"$ln\" -s \"$data/$resource\" \"$state/$resource\"\n"
                      "  fi\n"
                      "done\n"
                      "cd \"$state\"\n"
                      "exec \"$real\" \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (inputs
     (list bash-minimal coreutils-minimal libx11 sdl12-compat sdl-image sdl-ttf))
    (native-inputs
     (list font-bitstream-vera fpc unzip))
    (home-page "https://sourceforge.net/projects/dmonkey/")
    (synopsis "SDL tactics role-playing game with procedurally generated campaigns")
    (description
     "Dungeon Monkey Unlimited is a Pascal and SDL tactics role-playing game
from the original Dungeon Monkey lineage.  It generates a fantasy campaign,
map, and encounters locally.  The package builds the pinned upstream source
with Free Pascal and SDL 1.2-compatible libraries, installs only the used
runtime assets, and runs the writable save/configuration files from an XDG
data directory.  Its package-owned @option{--smoke} mode deterministically
generates a campaign, activates a model, and verifies a save/load round-trip
in an isolated temporary directory.")
    (license
     (list license:lgpl2.1
           license:cc-by3.0
           license:public-domain
           (license:fsdg-compatible
            "https://spdx.org/licenses/Bitstream-Vera.html"
            "The bundled VeraBd.ttf is the unmodified Bitstream Vera font.")))))
