;;; GNU Guix package for Jeff Lait's Six Two One.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages six-two-one)
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

(define %six-two-one-sources
  '("ai" "buf" "builder" "chooser" "config" "defedit" "dircontrol"
    "display" "dpdf" "engine" "firefly" "gamedef" "gfxengine" "glbdef"
    "grammar" "item" "main" "map" "mob" "msg" "panel" "rand" "scrpos"
    "speed" "text" "thread" "thread_linux" "wordlist"))

(define-public six-two-one
  (package
    (name "six-two-one")
    (version "2016-03-06")
    (source
     (origin
       (method url-fetch)
       ;; Upstream's HTTPS endpoint has a mismatched certificate.  HTTP serves
       ;; the identical archive; the fixed digest authenticates its contents.
       (uri "http://www.zincland.com/7drl/sixtwoone/sixtwoone7drl.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256 c3597321994f25a092e2b66cbeee0bf044331af4961bc434ec688770a63d6843.
       ;; The earlier delivery used an incorrect base32 conversion of this
       ;; SAME digest, not a changed release.  guix hash yields the value below.
       (sha256
        (base32 "0hv87nk711v8xhsc86wnyhd36i7h1gpbwv5nwa9a09agk4hp6nf3"))))
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
              ;; Strip bundled executables and libraries before compiling.
              ;; Use the checked-in glbdef.cpp/h, never the enum generator.
              (delete-file-recursively "windows")
              (delete-file "linux/sixtwoone_bin")
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
                           '#$%six-two-one-sources))
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
                ;; The private static archive is rebuilt entirely from the
                ;; pinned source.  Only Guix's SDL, PNG, zlib and libc are
                ;; dynamically linked; no bundled .so enters the closure.
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
                ;; USE_AUDIO is disabled in upstream main.cpp: do not add an
                ;; unused SDL_mixer/music dependency or redistribute music.
                (apply invoke #$(cxx-for-target) "-o" "build/six-two-one"
                       (append
                        (map (lambda (file) (object file "build/game")) game-sources)
                        (list "build/libtcod.a" "-lSDL" "-lpng" "-lz"
                              "-lm" "-pthread"))))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/six-two-one"))
                     (doc (string-append out "/share/doc/six-two-one"))
                     (bin (string-append out "/bin"))
                     (program (string-append out "/libexec/six-two-one"))
                     (launcher (string-append bin "/six-two-one")))
                (mkdir-p bin)
                (mkdir-p (dirname program))
                (copy-file "build/six-two-one" program)
                (chmod program #o555)
                (for-each
                 (lambda (file) (install-file file data))
                 '("linux/terminal.png" "sixtwoone.cfg" "text.txt"))
                (install-file "rooms/village.map" (string-append data "/rooms"))
                (install-file "wordlist/wordlist.txt" (string-append data "/wordlist"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README.TXT" "src/LICENSE.TXT"
                   "lib/libtcod-1.5.0/LIBTCOD-LICENSE.txt"
                   "lib/libtcod-1.5.0/LIBTCOD-CREDITS.txt"
                   "lib/libtcod-1.5.0/README-SDL.txt"
                   "src/support/fontbuilder/OFL.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "six-two-one-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "six-two-one-wrapper.sh"))
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
    (home-page "http://www.zincland.com/7drl/sixtwoone/")
    (synopsis "Topological word puzzle roguelike")
    (description
     "Six Two One is Jeff Lait's 2016 Seven Day Roguelike.  Explore a cube-like
labyrinth and decode six nine-letter words before your life force runs out.
The game and its libtcod 1.5.0 rendering library are compiled from source;
platform binaries, demo fonts and unused music are omitted.  Configuration,
world definitions and saved games persist under @file{$XDG_DATA_HOME/six-two-one},
falling back to @file{$HOME/.local/share/six-two-one}.  Read-only game text,
Oxygen Mono glyphs, room map and Moby wordlist remain in the store.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:bsd-3 license:public-domain license:silofl1.1))))
