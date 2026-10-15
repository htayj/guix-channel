;;; GNU Guix package for Jeff Lait's Everything Is Fodder.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages everything-is-fodder)
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

;; The object list in upstream linux/Makefile.  Template implementations and
;; mt19937ar.c are included by their callers, not compiled separately.
(define %everything-is-fodder-sources
  '("ai" "buf" "builder" "chooser" "config" "dircontrol" "display"
    "dpdf" "engine" "firefly" "gamedef" "gfxengine" "glbdef" "grammar"
    "item" "main" "map" "mob" "msg" "panel" "rand" "scrpos" "speed"
    "text" "thesaurus" "thread" "thread_linux"))

(define-public everything-is-fodder
  (package
    (name "everything-is-fodder")
    (version "2017-03-12")
    (source
     (origin
       (method url-fetch)
       ;; Upstream's HTTPS endpoint has a mismatched certificate.  The fixed
       ;; digest authenticates the archive served by its canonical HTTP URL.
       (uri "http://www.zincland.com/7drl/fodder/fodder7drl.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256 ff7a3a70ae65cfecaa6a9aafe689821f8ca566478930f1c180faefe66d5b7a2b.
       (sha256
        (base32 "0avsbdnydvzsh30z2c498xkab30zha4ydbwsdamfrkv5mrq3lypz"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                         ; upstream has no test target
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              ;; Preserve the original, unpatched game sources for inspecting
              ;; the native save format and checking runtime observations.
              (for-each
               (lambda (file) (install-file file "original-source"))
               (filter (lambda (file) (string=? (dirname file) "src"))
                       (find-files "src" "\\.(cpp|h)$|^mt19937ar\\.c$")))
              ;; No upstream executable or shared library participates in the
              ;; build.  Use the checked-in glbdef.cpp/h, not the enum generator.
              (delete-file-recursively "windows")
              (delete-file "linux/fodder_bin")
              (for-each
               delete-file
               (find-files
                "lib" (string-append
                       "(\\.so($|\\.)|\\.dll$|\\.exe$|^hmtool(_debug)?$|"
                       "^samples_(c|cpp)(_debug)?$)")))
              ;; Old libtcod predates opaque libpng structs and removal of its
              ;; typed NULL macros.  Use the public API with identical meaning.
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_img_png.c"
                (("info_ptr->channels") "png_get_channels(png_ptr, info_ptr)")
                (("png_infopp_NULL|png_voidp_NULL") "NULL"))
              ;; Match the header's typed prototype, not K&R implicit ints.
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_c.c"
                (("TCOD_sys_map_ascii_to_font\\(asciiCode, fontCharX, fontCharY\\)")
                 (string-append "TCOD_sys_map_ascii_to_font(int asciiCode, "
                                "int fontCharX, int fontCharY)"))
                ;; A static archive need not pull sys_c.c's constructor.
                ;; Initialize before loading glyphs; later startup otherwise
                ;; resets ASCII mapping and the first-draw color cache.
                (("strcpy\\(font_file,fontFile\\);")
                 "TCOD_sys_startup();\n\tstrcpy(font_file,fontFile);"))
              ;; POSIX NAME_MAX and unlink declarations used by game headers.
              (substitute* "src/dircontrol.h"
                (("#include <dirent.h>")
                 "#include <dirent.h>\n#include <limits.h>"))
              (substitute* "src/mygba.h"
                (("#ifdef LINUX") "#ifdef LINUX\n#include <unistd.h>"))))
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
                           '#$%everything-is-fodder-sources))
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
                ;; Rebuild the private static archive serially from the pinned
                ;; source, following the channel's Six Two One convention.
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
                ;; USE_AUDIO remains disabled in upstream main.cpp.  Do not
                ;; introduce SDL_mixer or change gameplay to enable audio.
                (apply invoke #$(cxx-for-target) "-o" "build/everything-is-fodder"
                       (append
                        (map (lambda (file) (object file "build/game")) game-sources)
                        (list "build/libtcod.a" "-lSDL" "-lpng" "-lz"
                              "-lm" "-pthread"))))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/everything-is-fodder"))
                     (doc (string-append out "/share/doc/everything-is-fodder"))
                     (bin (string-append out "/bin"))
                     (program (string-append out "/libexec/everything-is-fodder"))
                     (launcher (string-append bin "/everything-is-fodder")))
                (mkdir-p bin)
                (mkdir-p (dirname program))
                (copy-file "build/everything-is-fodder" program)
                (chmod program #o555)
                (for-each
                 (lambda (file) (install-file file data))
                 '("linux/terminal.png" "fodder.cfg" "text.txt"))
                (install-file "rooms/village.map" (string-append data "/rooms"))
                (copy-recursively "original-source"
                                  (string-append data "/source/game"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README.TXT" "7drlchanges.TXT" "src/LICENSE.TXT"
                   "lib/libtcod-1.5.0/LIBTCOD-LICENSE.txt"
                   "lib/libtcod-1.5.0/LIBTCOD-CREDITS.txt"
                   "lib/libtcod-1.5.0/README-SDL.txt"
                   "src/support/fontbuilder/OFL.txt"))
                (for-each
                 (lambda (file)
                   (install-file file (string-append doc "/upstream-linux")))
                 '("linux/Makefile" "linux/BUILD.TXT"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "everything-is-fodder-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "everything-is-fodder-wrapper.sh"))
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
    (home-page "http://www.zincland.com/7drl/fodder/")
    (synopsis "Elemental transmutation roguelike")
    (description
     "Everything Is Fodder is Jeff Lait's 2017 Seven Day Roguelike.  Explore
random dungeons, transmute elaborate objects into elemental coins, and spend
those coins to cast spells on the quest to defeat the demon lord Ba'zlbub.
The game and its libtcod 1.5.0 rendering library are compiled from source;
platform binaries and unused demo assets are omitted.  Configuration and
saved games persist under @file{$XDG_DATA_HOME/everything-is-fodder}, falling
back to @file{$HOME/.local/share/everything-is-fodder}.  Original game text,
Oxygen Mono glyphs and the room map remain in the store.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:bsd-3 license:public-domain license:silofl1.1))))
