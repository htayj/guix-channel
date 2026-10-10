;;; Original Dwarftown 1.0 and its private historical renderer.

(define-module (tay packages dwarftown)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages swig))

;; This definition is intentionally private: the game's SWIG interface needs
;; the 1.5.1 C++ API, not the current libtcod package's API.
(define dwarftown-libtcod
  (package
    (name "dwarftown-libtcod")
    (version "1.5.1")
    (source
     (origin
       (method url-fetch)
       ;; Official 1.5.1 tag resolves to this audited commit.
       (uri (string-append
             "https://codeload.github.com/libtcod/libtcod/tar.gz/"
             "a7cabfda0b0c770d4092f0dec02efbd2a3b6d990"))
       (file-name "dwarftown-libtcod-1.5.1.tar.gz")
       (sha256
        (base32 "09q8h9iqdp45vjqsh5g5yvxsqmxdw2xbkdnyzvqfa6k5wbisvwlh"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Dependencies come from Guix, never the archived runtime copies.
            (delete-file-recursively "dependencies")
            (for-each delete-file
                      (find-files "." "\\.(exe|dll|so(\\..*)?|a|o)$"))
            (delete-file "ascii-paint/ascii-paint-linux")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; No upstream automated test target; native gameplay is checked outside
      ;; the package build with a real display and original input interface.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'apply-portability-patch
            (lambda _
              ;; These historical files are CRLF.  Normalize literal carriage
              ;; returns before applying ordinary unified patch context.
              (substitute* '("src/sys_sdl_c.c" "src/sys_sdl_img_png.c")
                (("\r") ""))
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/dwarftown-libtcod-portability.patch")))))
          (delete 'configure)
          (replace 'build
            (lambda _
              (let* ((lib (string-append #$output "/lib"))
                     (sdl-lib (string-append #$sdl12-compat "/lib"))
                     (z-lib (string-append #$zlib "/lib"))
                     (gl-lib (string-append #$mesa "/lib"))
                     (cflags
                      (string-append
                       "-O2 -fPIC -Iinclude -Iinclude/gui -Wall "
                       "-fno-strict-aliasing -D_GNU_SOURCE=1 -D_REENTRANT "
                       "-I" #$sdl12-compat "/include "
                       "-I" #$sdl12-compat "/include/SDL "
                       "-I" #$zlib "/include "
                       "-I" #$mesa "/include "
                       "-Wl,-rpath," lib)))
                ;; The original shared /tmp object location and parallel
                ;; directory/link prerequisites are unsafe in isolated builds.
                (mkdir-p "build-objects/libtcod/release/png")
                (substitute* "makefiles/makefile-linux64"
                  (("libtcodxx.so : ") "libtcodxx.so : libtcod.so ")
                  (("gcc -shared -Wl,-soname,\\$@ -o \\$@ \\$\\(LIBOBJS_CPP_RELEASE\\)")
                   "$(CPP) -shared -Wl,-soname,$@ -o $@ $(LIBOBJS_CPP_RELEASE)"))
                (invoke "make" "-f" "makefiles/makefile-linux64"
                        (string-append "-j" (number->string (parallel-job-count)))
                        "libtcod.so" "libtcodxx.so"
                        "CC=gcc -std=gnu99" "CPP=g++ -std=gnu++98"
                        (string-append "TEMP=" (getcwd) "/build-objects")
                        (string-append "CFLAGS=" cflags)
                        (string-append "SDL_LIBS=-L" sdl-lib
                                       " -Wl,-rpath," sdl-lib " -lSDL -lm")
                        (string-append "ZLIB_LIBS=-L" z-lib
                                       " -Wl,-rpath," z-lib " -lz")
                        (string-append "OPENGL_LIB=-L" gl-lib
                                       " -Wl,-rpath," gl-lib " -lGL")))))
          (replace 'install
            (lambda _
              (let ((lib (string-append #$output "/lib"))
                    (doc (string-append #$output
                                        "/share/doc/dwarftown-libtcod")))
                (for-each (lambda (file) (install-file file lib))
                          '("libtcod.so" "libtcodxx.so"))
                (copy-recursively "include" (string-append #$output "/include"))
                (for-each (lambda (file) (install-file file doc))
                          '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"
                            "README-SDL.txt"))
                ;; Keep the embedded codec's actual notice and complete source,
                ;; including its version.  1.5.1 does not use external libpng.
                (install-file "src/png/lodepng.c" doc)
                (install-file "src/png/lodepng.h" doc)))))))
    (inputs (list sdl12-compat zlib mesa))
    (home-page "https://github.com/libtcod/libtcod")
    (synopsis "Historical renderer private to Dwarftown")
    (description
     "This private libtcod 1.5.1 renderer supplies the original C and C++ API
used by Dwarftown.  It builds the historical SDL and OpenGL renderer and embedded
LodePNG codec from source, linking separate Guix SDL and zlib dependencies.")
    (license (list license:bsd-3 license:zlib))))

(define-public dwarftown
  (package
    (name "dwarftown")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/pwmarcz/dwarftown/tar.gz/"
             "9488ae4ec385459ed6c8d15a642e43c8a11607f7"))
       (file-name "dwarftown-1.0-9488ae4.tar.gz")
       (sha256
        (base32 "12sqg5rk5f62kifsiwci4cdsh07af2l96srz74ry67a6bcdj2xl6"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Discard every shipped interpreter and binary module; build only
            ;; from the interface and helper sources, with official headers.
            (for-each delete-file-recursively
                      '("wrapper/linux" "wrapper/linux64" "wrapper/windows"
                        "wrapper/include"))
            (delete-file "wrapper/swig/libtcod_wrap.cxx")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                     ;no upstream automated suite
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'set-immutable-paths
            (lambda _
              (let ((data (string-append #$output "/share/dwarftown"))
                    (module (string-append #$output
                                           "/lib/dwarftown/?.so")))
                ;; Lua's module resolution must not depend on the caller CWD
                ;; or injected Lua paths.  Ordinary output files still do.
                (substitute* "src/main.lua"
                  (("^package.path = .*")
                   (string-append
                    "package.path = '" data "/src/?.lua;" data
                    "/src/?/init.lua;" data "/wrapper/?.lua'\n"
                    "package.cpath = '" module "'")))
                (substitute* "src/ui.lua"
                  (("fonts/terminal10x18.png")
                   (string-append data "/fonts/terminal10x18.png"))))))
          (replace 'build
            (lambda _
              (let ((include (string-append #$dwarftown-libtcod "/include"))
                    (lib (string-append #$dwarftown-libtcod "/lib"))
                    (lua-lib (string-append #$lua-5.1 "/lib")))
                ;; SWIG 4.0 retains the old metatable names by default;
                ;; squash bases preserves the pre-3.0 inheritance layout.
                (invoke "swig" "-c++" "-lua" "-squash-bases"
                        (string-append "-I" include)
                        "-Iwrapper/swig" "-DTCODLIB_API"
                        "-o" "wrapper/swig/libtcod_wrap.cxx"
                        "wrapper/swig/libtcod.i")
                (invoke "g++" "-std=gnu++98" "-O2" "-fPIC" "-shared"
                        (string-append "-I" include)
                        (string-append "-I" #$lua-5.1 "/include")
                        "-Iwrapper/swig" "wrapper/swig/libtcod_wrap.cxx"
                        "-o" "libtcodlua.so"
                        (string-append "-L" lib)
                        (string-append "-Wl,-rpath," lib)
                        (string-append "-L" lua-lib)
                        (string-append "-Wl,-rpath," lua-lib)
                        "-ltcodxx" "-ltcod" "-llua"))))
          (replace 'install
            (lambda _
              (let ((data (string-append #$output "/share/dwarftown"))
                    (doc (string-append #$output "/share/doc/dwarftown"))
                    (bin (string-append #$output "/bin")))
                (copy-recursively "src" (string-append data "/src"))
                (copy-recursively "fonts" (string-append data "/fonts"))
                (install-file "wrapper/tcod.lua" (string-append data "/wrapper"))
                (install-file "wrapper/terminal.png"
                              (string-append data "/wrapper"))
                (install-file "libtcodlua.so"
                              (string-append #$output "/lib/dwarftown"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.txt" "README.txt"))
                (copy-file "wrapper/readme.txt"
                           (string-append doc "/wrapper-readme.txt"))
                (install-file
                 #$(local-file
                    (search-tay-package-file "files/dwarftown-provenance.txt"))
                 doc)
                (for-each
                 (lambda (file)
                   (install-file
                    (string-append #$dwarftown-libtcod
                                   "/share/doc/dwarftown-libtcod/" file)
                    doc))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"
                   "README-SDL.txt" "lodepng.c" "lodepng.h"))
                ;; Preserve the actual 5.1.5 notice rather than treating the
                ;; archived bundled interpreter's 2008 notice as current.
                (mkdir "lua-notice")
                (invoke "tar" "xf" #$(package-source lua-5.1)
                        "--strip-components=1" "-C" "lua-notice")
                (copy-file "lua-notice/COPYRIGHT"
                           (string-append doc "/LUA-COPYRIGHT"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/dwarftown")
                  (lambda (port)
                    (format port
                            "#!~a/bin/sh\nexec ~a/bin/lua ~a/src/main.lua \"$@\"\n"
                            #$bash-minimal #$lua-5.1 data)))
                (chmod (string-append bin "/dwarftown") #o755)))))))
    (native-inputs (list swig-4.0))
    (inputs (list bash-minimal lua-5.1 dwarftown-libtcod))
    (home-page "https://pwmarcz.pl/dwarftown/")
    (synopsis "Explore the original Dwarftown roguelike dungeon")
    (description
     "Dwarftown is the original Lua roguelike from the 2011 Seven Day Roguelike
Challenge.  This package builds its Lua 5.1 SWIG module and private libtcod 1.5.1
renderer from source, retaining the original 80 by 25 console, 10 by 18 font,
keyboard controls and gameplay.  Character dumps, error logs and screenshots
are written in the caller's working directory; character dumps are not
resumable saves.")
    (license (list license:expat license:bsd-3 license:zlib))))
