;;; GNU Guix package for Jeff Lait's Tower of Babel.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages babel7drl)
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
  #:use-module (gnu packages python)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages auxiliary))

;; The source list is the one in src/linux/Makefile, not the optional tools.
(define %babel7drl-sources
  '("ai" "buf" "builder" "chooser" "config" "dircontrol" "display" "dpdf"
    "engine" "firefly" "gamedef" "gfxengine" "glbdef" "grammar" "item"
    "main" "map" "mob" "msg" "panel" "rand" "scrpos" "speed" "text"
    "thesaurus" "thread" "thread_linux"))

(define-public babel7drl
  (package
    (name "babel7drl")
    (version "2019-03-09")
    (source
     (origin
       (method url-fetch)
       ;; Upstream HTTPS has a mismatched certificate.  The fixed digest
       ;; authenticates the original archive served over HTTP.
       (uri "http://www.zincland.com/7drl/babel/babel7drl.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256 ce482e9f9b04efbff95e395a745366cc962ca71536d5bc5d9bd23f6b049424e1.
       (sha256
        (base32 "1q94jh26ngyjkdfvrm9n2nkjr5nccr9p8nirbvwvzvq4kfgjwj6f"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; upstream has no automated test target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              ;; No bundled platform executable or shared library is reused.
              (delete-file-recursively "windows")
              (delete-file-recursively "src/windows")
              (delete-file-recursively "src/lib")
              (delete-file "linux/babel_bin")
              (for-each
               delete-file
               (find-files
                "lib" (string-append
                       "(\\.so($|\\.)|\\.dll$|\\.exe$|^hmtool(_debug)?$|"
                       "^samples_(c|cpp)(_debug)?$)")))
              ;; libtcod 1.5 predates libpng's opaque structs and typed-NULL
              ;; removal.  Preserve behavior with the supported public API.
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_img_png.c"
                (("info_ptr->channels") "png_get_channels(png_ptr, info_ptr)")
                (("png_infopp_NULL|png_voidp_NULL") "NULL"))
              (substitute* "lib/libtcod-1.5.0/src/sys_sdl_c.c"
                (("TCOD_sys_map_ascii_to_font\\(asciiCode, fontCharX, fontCharY\\)")
                 (string-append "TCOD_sys_map_ascii_to_font(int asciiCode, "
                                "int fontCharX, int fontCharY)"))
                ;; The private archive need not pull sys_c.c's constructor;
                ;; initialize before loading glyphs, as in six-two-one.
                (("strcpy\\(font_file,fontFile\\);")
                 "TCOD_sys_startup();\n\tstrcpy(font_file,fontFile);"))
              (substitute* "src/dircontrol.h"
                (("#include <dirent.h>")
                 "#include <dirent.h>\n#include <limits.h>"))
              (substitute* "src/mygba.h"
                (("#ifdef LINUX") "#ifdef LINUX\n#include <unistd.h>"))))
          (add-before 'build 'generate-enums
            (lambda _
              ;; Keep Python 2 strictly build-time.  Its dict iteration must
              ;; not vary between builds when producing glbdef.cpp/h.
              (setenv "PYTHONHASHSEED" "0")
              (with-directory-excursion "src"
                (invoke #+(file-append python-2 "/bin/python2")
                        "support/enummaker/enummaker.py"))))
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
                           '#$%babel7drl-sources))
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
                ;; Both libtcod C and C++ APIs are built from the pinned source.
                ;; Only Guix SDL/PNG/zlib/libc are linked dynamically.
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
                ;; Upstream comments out USE_AUDIO.  SDL_mixer and unlicensed
                ;; user-selected music are neither linked nor installed.
                (apply invoke #$(cxx-for-target) "-o" "build/babel7drl"
                       (append
                        (map (lambda (file) (object file "build/game")) game-sources)
                        (list "build/libtcod.a" "-lSDL" "-lpng" "-lz"
                              "-lm" "-pthread"))))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/babel7drl"))
                     (doc (string-append #$output "/share/doc/babel7drl"))
                     (program (string-append #$output "/libexec/babel7drl"))
                     (launcher (string-append #$output "/bin/babel7drl")))
                (mkdir-p (dirname launcher))
                (mkdir-p (dirname program))
                (copy-file "build/babel7drl" program)
                (chmod program #o555)
                (for-each
                 (lambda (file) (install-file file data))
                 '("linux/terminal.png" "babel.cfg" "names.txt" "text.txt"))
                (install-file "rooms/village.map" (string-append data "/rooms"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README.TXT" "7drlchanges.TXT" "src/LICENSE.TXT"
                   "lib/libtcod-1.5.0/LIBTCOD-LICENSE.txt"
                   "lib/libtcod-1.5.0/LIBTCOD-CREDITS.txt"
                   "lib/libtcod-1.5.0/README-SDL.txt"
                   "src/support/fontbuilder/OFL.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "babel7drl-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "babel7drl-wrapper.sh"))
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
    (native-inputs (list unzip python-2))
    (inputs (list bash-minimal coreutils-minimal libpng sdl12-compat zlib))
    (home-page "http://www.zincland.com/7drl/babel/")
    (synopsis "Roguelike with randomized worlds and keyboard commands")
    (description
     "Tower of Babel is Jeff Lait's 2019 Seven Day Roguelike.  Discover the
randomized rules, language, statistics and keyboard commands of procedurally
created alternate worlds through the game's fictional terminal interface.
The game and its libtcod 1.5.0 library are built from source.  Configuration
and the writable runtime layout reside in @file{$XDG_DATA_HOME/babel7drl},
falling back to @file{$HOME/.local/share/babel7drl}; read-only maps, text and
Oxygen Mono glyphs remain in the store.  The released game does not save games
on shutdown, and its fictional servers do not require network access.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:bsd-3 license:public-domain license:silofl1.1))))
