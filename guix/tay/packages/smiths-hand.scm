;;; GNU Guix package for Jeff Lait's The Smith's Hand.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages smiths-hand)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages auxiliary))

(define %smiths-hand-sources
  '("ai" "buf" "chooser" "config" "dircontrol" "display" "dpdf" "engine"
    "firefly" "gfxengine" "glbdef" "grammar" "item" "main" "map" "mob"
    "msg" "panel" "rand" "scrpos" "simulator" "speed" "text" "thread"
    "thread_linux"))

(define-public the-smiths-hand
  (package
    (name "the-smiths-hand")
    (version "2014-03-16")
    (source
     (origin
       (method url-fetch)
       ;; Upstream's HTTPS endpoint has a mismatched certificate.  The fixed
       ;; digest authenticates the canonical HTTP snapshot.
       (uri "http://www.zincland.com/7drl/smith/smith7drl.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256 a245e26b305d1ff9ec25bcc87635d4e8000f167e2563b5e269a3ed0c19e2adee.
       (sha256
        (base32 "1vmdw8chrvd3d7ibaqr5gqb0y078shspdj5w4pngj7sx61my4id2"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                         ; upstream has no test target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              ;; Never use a platform binary from the source distribution.
              (delete-file-recursively "windows")
              (delete-file "linux/smith_bin")
              (for-each
               delete-file
               (find-files
                "lib" (string-append
                       "(\\.so($|\\.)|\\.dll$|\\.exe$|^hmtool(_debug)?$|"
                       "^samples_(c|cpp)(_debug)?$)")))
              ;; libtcod 1.5.0 predates opaque libpng structures.
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_img_png.c"
                (("info_ptr->channels") "png_get_channels(png_ptr, info_ptr)")
                (("png_infopp_NULL|png_voidp_NULL") "NULL"))
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_c.c"
                (("TCOD_sys_map_ascii_to_font\\(asciiCode, fontCharX, fontCharY\\)")
                 (string-append "TCOD_sys_map_ascii_to_font(int asciiCode, "
                                "int fontCharX, int fontCharY)"))
                ;; A static archive need not pull sys_c.c's constructor.
                (("strcpy\\(font_file,fontFile\\);")
                 "TCOD_sys_startup();\n\tstrcpy(font_file,fontFile);"))
              (substitute* "src/dircontrol.h"
                (("#include <dirent.h>")
                 "#include <dirent.h>\n#include <limits.h>"))
              (substitute* "src/map.cpp"
                (("#include <fstream>") "#include <fstream>\n#include <unistd.h>"))
              ;; There is no licensed music in the archive.  Windowed mode is
              ;; also usable on displays smaller than the upstream fullscreen.
              (substitute* "smith.cfg"
                (("enable = true") "enable = false")
                (("full = true") "full = false"))))
          (replace 'build
            (lambda _
              (let* ((vendor "lib/libtcod-1.5.0")
                     (common (list "-O2" "-g0" "-D_GNU_SOURCE"
                                   (string-append "-I" vendor "/include")
                                   (string-append "-I" #$sdl12-compat "/include")
                                   (string-append "-I" #$sdl12-compat "/include/SDL")))
                     (c-sources
                      (filter (lambda (file)
                                (not (string-suffix? "sys_sfml_c.c" file)))
                              (find-files (string-append vendor "/src") "\\.c$")))
                     (cpp-sources
                      (filter (lambda (file)
                                (and (not (string-contains file "/gui/"))
                                     (not (string-contains file "/hmtool/"))))
                              (find-files (string-append vendor "/src") "\\.cpp$")))
                     (game-sources
                      (map (lambda (name) (string-append "src/" name ".cpp"))
                           '#$%smiths-hand-sources))
                     (cxx-flags (append common (list "-std=gnu++11"))))
                (define (object file directory)
                  (string-append directory "/" (basename file) ".o"))
                (define (compile compiler flags files directory)
                  (mkdir-p directory)
                  (for-each
                   (lambda (file)
                     (apply invoke compiler
                            (append flags (list "-c" file "-o"
                                                (object file directory)))))
                   files))
                ;; Generate enums with the supplied source-built host tool.
                (invoke "g++" "-O2" "-std=gnu++11"
                        "src/support/enummaker/enummaker.cpp"
                        "-o" "src/support/enummaker/enummaker")
                (with-directory-excursion "src/linux"
                  (invoke "make" "premake"))
                ;; Only this private source-built archive is statically linked.
                (compile #$(cc-for-target)
                         (append common (list "-std=gnu99"))
                         c-sources "build/tcod-c")
                (compile #$(cxx-for-target) cxx-flags
                         cpp-sources "build/tcod-cpp")
                (apply invoke "ar" "crsD" "build/libtcod.a"
                       (append
                        (map (lambda (file) (object file "build/tcod-c")) c-sources)
                        (map (lambda (file) (object file "build/tcod-cpp")) cpp-sources)))
                (compile #$(cxx-for-target)
                         (append cxx-flags (list "-DLINUX" "-pthread"))
                         game-sources "build/game")
                ;; USE_AUDIO is disabled in upstream main.cpp.  SDL_mixer's
                ;; upstream Makefile link flag is unused; no music is installed.
                (apply invoke #$(cxx-for-target) "-o" "build/smith"
                       (append
                        (map (lambda (file) (object file "build/game")) game-sources)
                        (list "build/libtcod.a" "-lSDL" "-lpng" "-lz"
                              "-lm" "-pthread"))))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/the-smiths-hand"))
                     (doc (string-append out "/share/doc/the-smiths-hand"))
                     (bin (string-append out "/bin"))
                     (program (string-append out "/libexec/smith"))
                     (launcher (string-append bin "/smith")))
                (mkdir-p bin)
                (mkdir-p (dirname program))
                (copy-file "build/smith" program)
                (chmod program #o555)
                (for-each
                 (lambda (file) (install-file file data))
                 '("linux/terminal.png" "smith.cfg" "text.txt"))
                (install-file "rooms/village.map" (string-append data "/rooms"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README.TXT" "src/LICENSE.TXT"
                   "lib/libtcod-1.5.0/LIBTCOD-LICENSE.txt"
                   "lib/libtcod-1.5.0/LIBTCOD-CREDITS.txt"
                   "lib/libtcod-1.5.0/README-SDL.txt"))
                (copy-file "lib/libtcod-1.5.0/data/fonts/README.txt"
                           (string-append doc "/FONT-NOTICE.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "smiths-hand-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "smiths-hand-wrapper.sh"))
                 launcher)
                (substitute* launcher
                  (("@SH@") #$(file-append bash-minimal "/bin/sh"))
                  (("@REAL@") program)
                  (("@DATA@") data)
                  (("@MKDIR@") #$(file-append coreutils-minimal "/bin/mkdir"))
                  (("@CP@") #$(file-append coreutils-minimal "/bin/cp"))
                  (("@CHMOD@") #$(file-append coreutils-minimal "/bin/chmod"))
                  (("@LN@") #$(file-append coreutils-minimal "/bin/ln")))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal coreutils-minimal libpng sdl12-compat zlib))
    (home-page "http://www.zincland.com/7drl/smith/")
    (synopsis "Village smith roguelike with adventurer equipment trading")
    (description
     "The Smith's Hand is Jeff Lait's Seven Day Roguelike about a village smith.
Equip adventurers exploring an orc-infested cave, balancing profits against
their safety.  The original game and libtcod 1.5.0 are compiled from source.
Only the public-domain terminal font and village map accompany the game text;
platform binaries, demo assets and music are omitted.  Configuration and native
saved games persist under @file{$XDG_DATA_HOME/the-smiths-hand}, falling back to
@file{$HOME/.local/share/the-smiths-hand}.  The launcher starts the original SDL
interface without command-line options; default music is disabled.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:bsd-3 license:public-domain))))
