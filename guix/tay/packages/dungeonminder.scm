;;; GNU Guix package for DungeonMinder and its historical libtcod API.

(define-module (tay packages dungeonminder)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image)
  #:use-module (gnu packages sdl))

(define dungeonminder-license
  ;; The original endorsement clause says "may be used", not "may not".
  ;; Preserve that custom grant rather than misidentifying it as BSD-3.
  (license:non-copyleft
   "file://share/doc/dungeonminder/dungeonminder-license.txt"
   "Adam Gatt's permissive notice, with its original endorsement clause"))

(define dungeonminder-libtcod-source
  (origin
    (method url-fetch)
    ;; Tag 1.4.0 resolves to 9ac2a3a526e7cefe8b7b330e37619bb1c4b6fb96.
    ;; The content hash pins the actual historical source, not today's API.
    (uri "https://codeload.github.com/libtcod/libtcod/tar.gz/refs/tags/1.4.0")
    (file-name "dungeonminder-libtcod-1.4.0.tar.gz")
    (sha256
     (base32 "1jynp5gkj639g5vddfvki7dbak5pscsjscmahv32lnq3p0vbdxyb"))
    (patches
     (list (search-tay-package-file
            "patches/dungeonminder-libtcod-portability.patch")))
    (modules '((guix build utils)))
    (snippet
     #~(begin
         ;; These bundled runtime binaries are never build inputs.  SDL,
         ;; libpng and zlib are separately source-built Guix dependencies.
         (for-each delete-file '("libSDL.so" "SDL.dll" "zlib1.dll"))))))

(define-public dungeonminder
  (package
    (name "dungeonminder")
    (version "0.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/google-code-archive-downloads/"
             "v2/code.google.com/dungeonminder/DungeonMinder.cpp"))
       (file-name "DungeonMinder.cpp")
       (sha256
        (base32 "0q12yjax6za94zjbarssx2hb7aggvbhgax0iwsmsg9373a1llrvh"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream supplies a single translation unit, not a test suite.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (copy-file source "DungeonMinder.cpp")
              (chmod "DungeonMinder.cpp" #o644)
              ;; The archived source is CRLF; normalize only line endings so
              ;; the source portability patch has ordinary unified context.
              (substitute* "DungeonMinder.cpp"
                (("\r") ""))
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/dungeonminder-source-portability.patch")))
              (mkdir "libtcod")
              (invoke "tar" "xf" #$dungeonminder-libtcod-source
                      "--strip-components=1" "-C" "libtcod")))
          (delete 'configure)
          (replace 'build
            (lambda _
              (let* ((private-lib (string-append #$output "/lib/dungeonminder"))
                     (sdl-lib (string-append #$sdl12-compat "/lib"))
                     (png-lib (string-append #$libpng "/lib"))
                     (z-lib (string-append #$zlib "/lib"))
                     (rpath (string-append "-Wl,-rpath," private-lib))
                     (cflags
                      (string-append
                       "-O2 -fPIC -Iinclude -Wall -fno-strict-aliasing "
                       "-D_GNU_SOURCE=1 -D_REENTRANT "
                       "-I" #$sdl12-compat "/include "
                       "-I" #$libpng "/include "
                       "-I" #$zlib "/include " rpath)))
                (with-directory-excursion "libtcod"
                  ;; Avoid the original shared /tmp/libtcod object directory.
                  ;; Create it first so parallel object rules cannot race it.
                  (mkdir-p "build-objects/libtcod")
                  ;; The original C++ shared-library rule uses gcc, omitting
                  ;; its C++ runtime dependency.  Use the existing CPP driver.
                  (substitute* "makefile-linux-nodeps"
                    (("gcc -shared -Wl,-soname,\\$@ -o \\$@ \\$\\(LIBOBJS_CPP\\)")
                     "$(CPP) -shared -Wl,-soname,$@ -o $@ $(LIBOBJS_CPP)"))
                  (invoke "make" "-f" "makefile-linux-nodeps"
                          (string-append "-j" (number->string (parallel-job-count)))
                          "CC=gcc -std=gnu99" "CPP=g++ -std=gnu++98"
                          (string-append "TEMP=" (getcwd) "/build-objects")
                          (string-append "CFLAGS=" cflags)
                          (string-append "SDL_LIBS=-L" sdl-lib
                                         " -Wl,-rpath," sdl-lib " -lSDL -lm")
                          (string-append "PNG_LIBS=-L" png-lib
                                         " -Wl,-rpath," png-lib " -lpng")
                          (string-append "ZLIB_LIBS=-L" z-lib
                                         " -Wl,-rpath," z-lib " -lz")))
                (invoke "g++" "-std=gnu++98" "-O2" "-Wall"
                        "-Ilibtcod/include"
                        (string-append "-DDUNGEONMINDER_FONT=\"" #$output
                                       "/share/dungeonminder/terminal.png\"")
                        "DungeonMinder.cpp" "-o" "dungeonminder"
                        "-Llibtcod" rpath "-ltcod++" "-ltcod" "-lm"))))
          (replace 'install
            (lambda _
              (let ((data (string-append #$output "/share/dungeonminder"))
                    (doc (string-append #$output "/share/doc/dungeonminder"))
                    (lib (string-append #$output "/lib/dungeonminder")))
                (install-file "dungeonminder" (string-append #$output "/bin"))
                (for-each (lambda (file) (install-file file lib))
                          '("libtcod/libtcod.so" "libtcod/libtcod++.so"))
                ;; This is the byte-identical 128x128 root terminal.png from
                ;; libtcod 1.4.0 and the game's Linux release.  Its historical
                ;; layout is 8x8 cells, ASCII in columns, not modern TCOD order.
                (install-file "libtcod/terminal.png" data)
                (install-file
                 #$(local-file
                    (search-tay-package-file "files/dungeonminder-license.txt"))
                 doc)
                (for-each (lambda (file) (install-file file doc))
                          '("libtcod/LIBTCOD-LICENSE.txt"
                            "libtcod/LIBTCOD-CREDITS.txt" "libtcod/README-SDL.txt"))
                (copy-file "libtcod/fonts/README.txt"
                           (string-append doc "/libtcod-fonts-README.txt"))
                (install-file
                 #$(local-file
                    (search-tay-package-file
                     "files/dungeonminder-font-provenance.txt"))
                 doc)))))))
    (inputs (list sdl12-compat libpng zlib))
    (home-page "https://code.google.com/archive/p/dungeonminder/")
    (synopsis "Guide an autonomous hero through a dungeon using spells")
    (description
     "DungeonMinder is a reverse roguelike in which an autonomous hero explores
and fights through ten dungeon levels.  The player follows the hero and casts
spells from three schools to influence creatures and terrain.  This package
builds the original C++ game and its private libtcod 1.4.0 renderer from source,
retaining the historical font, keyboard controls and 80 by 60 cell display.")
    (license (list dungeonminder-license license:bsd-3))))
