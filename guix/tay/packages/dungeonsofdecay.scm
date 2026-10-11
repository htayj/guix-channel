;;; Original Dungeons of Decay 0.4.9 and its private libtcod 1.5.0 renderer.

(define-module (tay packages dungeonsofdecay)
  #:use-module (tay packages auxiliary)
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
  #:use-module (gnu packages sdl))

(define dungeonsofdecay-steve-wallace-permission
  ;; This is the actual author's custom use/modify permission, not BSD and
  ;; not a purported blanket relicensing of all copied game components.
  (license:non-copyleft
   "file://share/doc/dungeonsofdecay/dungeonsofdecay-third-party-notices.txt"
   "Steve Wallace's custom permission to use and modify his dungeon builder"))

;; The C object closure in upstream makefiles/makefile-linux64:103-130.
;; The Python consumer requires wrappers.c, but no C++ or GUI library.
(define %dungeonsofdecay-libtcod-c-sources
  '("bresenham_c" "bsp_c" "color_c" "console_c" "fov_c"
    "fov_circular_raycasting" "fov_diamond_raycasting" "fov_digital"
    "fov_recursive_shadowcasting" "fov_permissive2" "fov_restrictive"
    "heightmap_c" "image_c" "lex_c" "list_c" "mersenne_c" "namegen_c"
    "noise_c" "parser_c" "path_c" "sys_c" "sys_sdl_c" "sys_sdl_img_bmp"
    "sys_sdl_img_png" "tree_c" "wrappers" "zip_c"))

;; Private on purpose: neither current libtcod nor its current Python binding
;; has the ABI of the wrapper shipped with this exact game release.
(define dungeonsofdecay-libtcod
  (package
    (name "dungeonsofdecay-libtcod")
    (version "1.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/libtcod/libtcod/tar.gz/"
             "0f3a054b6ddd9ac8ffa676f600b24293da8595aa"))
       (file-name "dungeonsofdecay-libtcod-1.5.0.tar.gz")
       ;; Raw archive SHA256 f92676147d89fcbe92afb7d696872948d7ff8b571cdf4d83c4dcfd8be86bba02.
       (sha256
        (base32 "00msdgl8pzfwqj1lvpqway5zzms8563rdmmpmy9bxz49gla7c9pr"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; No prebuilt library or bundled dependency is a build input.
            (delete-file-recursively "dependencies")
            (for-each delete-file
                      (find-files "." "\\.(exe|dll|so(\\..*)?|a|o|lib|dylib)$"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; upstream has no automated test target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'apply-portability-patch
            (lambda _
              (substitute* '("src/sys_sdl_c.c" "src/sys_sdl_img_png.c")
                (("\r") ""))
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/dungeonsofdecay-libtcod-portability.patch")))))
          (replace 'build
            (lambda _
              (let* ((sources (map (lambda (name)
                                     (string-append "src/" name ".c"))
                                   '#$%dungeonsofdecay-libtcod-c-sources))
                     (objects (map (lambda (file)
                                     (string-append "build/" (basename file) ".o"))
                                   sources))
                     (flags (list "-O2" "-g0" "-fPIC" "-std=gnu99"
                                  "-fno-strict-aliasing" "-D_GNU_SOURCE=1"
                                  "-D_REENTRANT" "-Iinclude"
                                  (string-append "-I" #$sdl12-compat "/include")
                                  (string-append "-I" #$sdl12-compat "/include/SDL")
                                  (string-append "-I" #$libpng "/include")
                                  (string-append "-I" #$zlib "/include"))))
                (mkdir-p "build")
                (for-each
                 (lambda (source object)
                   (apply invoke #$(cc-for-target)
                          (append flags (list "-c" source "-o" object))))
                 sources objects)
                ;; Shared linking includes sys_c's ordinary startup constructor.
                ;; Only separately source-built Guix libraries are linked.
                (apply invoke #$(cc-for-target)
                       (append
                        (list "-shared" "-Wl,-soname,libtcod.so" "-Wl,-z,defs"
                              "-o" "build/libtcod.so")
                        objects
                        (list (string-append "-L" #$sdl12-compat "/lib")
                              (string-append "-Wl,-rpath," #$sdl12-compat "/lib")
                              (string-append "-L" #$libpng "/lib")
                              (string-append "-Wl,-rpath," #$libpng "/lib")
                              (string-append "-L" #$zlib "/lib")
                              (string-append "-Wl,-rpath," #$zlib "/lib")
                              "-lSDL" "-lpng" "-lz" "-lm" "-pthread"))))))
          (replace 'install
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/dungeonsofdecay-libtcod")))
                (install-file "build/libtcod.so" (string-append #$output "/lib"))
                (for-each (lambda (file) (install-file file doc))
                          '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"
                            "README-SDL.txt"))
                (copy-file "data/fonts/README.txt"
                           (string-append doc "/libtcod-fonts-README.txt"))))))))
    (inputs (list sdl12-compat libpng zlib))
    (home-page "https://github.com/libtcod/libtcod/tree/1.5.0")
    (synopsis "Historical C renderer for Dungeons of Decay")
    (description
     "This private libtcod 1.5.0 C shared library provides the exact native
API required by Dungeons of Decay's released Python wrapper.  It is built
from the immutable upstream source with Guix SDL, libpng and zlib inputs;
no bundled platform libraries are reused.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license license:bsd-3)))

(define-public dungeonsofdecay
  (package
    (name "dungeonsofdecay")
    (version "0.4.9")
    (source
     (origin
       (method url-fetch)
       ;; Never use SourceForge's latest/download, which selects Windows binaries.
       (uri (string-append
             "mirror://sourceforge/dungeonsofdecay/"
             "Dungeons_of_Decay_0_4_9_sources.zip"))
       (file-name "Dungeons_of_Decay_0_4_9_sources.zip")
       ;; Raw archive SHA256:
       ;; 800d5d9be83077767c80f19c93d8d07a1f2552aba5d6f7d29d7734843c8d5c43.
       (sha256
        (base32 "0hswily88d3pkp9ggmm5md92a7vss3c9777ih1y7cxrhx2dms3c0"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; no upstream automated tests
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The released ZIP has a flat root, not a containing directory.
              (mkdir "source")
              (chdir "source")
              (invoke "unzip" source)))
          (delete 'configure)
          (delete 'build)              ; ordinary Python 2, not Windows py2exe
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-runtime
            (lambda _
              ;; Preserve the CP1252 bytes and Python 2 coding declarations.
              (with-fluids ((%default-port-encoding "ISO-8859-1"))
                (substitute* (find-files "." "\\.py$")
                  (("\r") ""))
                (invoke "patch" "--fuzz=0" "-p1" "--input"
                        #$(local-file
                           (search-tay-package-file
                            "patches/dungeonsofdecay-ctypes-abi.patch")))
                (invoke "patch" "--fuzz=0" "-p1" "--input"
                        #$(local-file
                           (search-tay-package-file
                            "patches/dungeonsofdecay-game-portability.patch")))
                (substitute* "libtcodpy.py"
                  (("@LIBTCOD@")
                   #$(file-append dungeonsofdecay-libtcod "/lib/libtcod.so")))
                (substitute* '("Dungeons_of_Decay.py" "supporters.py")
                  (("'(arial10x10|arial12x12|entrance|scroll)\\.png'" all stem)
                   (string-append "'" #$output "/share/dungeonsofdecay/"
                                  stem ".png'"))))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/dungeonsofdecay"))
                     (doc (string-append #$output "/share/doc/dungeonsofdecay"))
                     (launcher (string-append #$output "/bin/dungeonsofdecay"))
                     (renderer-doc
                      (string-append #$dungeonsofdecay-libtcod
                                     "/share/doc/dungeonsofdecay-libtcod")))
                (for-each (lambda (file) (install-file file data))
                          '("Dungeons_of_Decay.py" "dmap.py" "ingredients.py"
                            "libtcodpy.py" "supporters.py" "values.py"
                            "arial10x10.png" "arial12x12.png"
                            "entrance.png" "scroll.png"))
                (for-each (lambda (file) (install-file file doc))
                          '("readme.txt" "changelog_decay.txt" "gpl-3.0.txt"))
                (for-each
                 (lambda (file)
                   (install-file (string-append renderer-doc "/" file) doc))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"
                   "README-SDL.txt" "libtcod-fonts-README.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file
                     "files/dungeonsofdecay-provenance.txt"))
                 (string-append doc "/dungeonsofdecay-provenance.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file
                     "files/dungeonsofdecay-third-party-notices.txt"))
                 (string-append doc "/dungeonsofdecay-third-party-notices.txt"))
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\n"
                      "if [ -n \"${XDG_DATA_HOME:-}\" ]; then\n"
                      "  data_home=$XDG_DATA_HOME\n"
                      "else\n"
                      "  data_home=${HOME:?HOME must be set}/.local/share\n"
                      "fi\n"
                      "state=$data_home/dungeonsofdecay\n"
                      "case $state in /*) ;; *) printf '%s\\n' "
                      "'dungeonsofdecay: data directory must be absolute' "
                      ">&2; exit 1;; esac\n"
                      #$coreutils-minimal "/bin/mkdir -p -- \"$state\"\n"
                      "cd -- \"$state\"\n"
                      ;; Running the file, not importing it, preserves shelve's
                      ;; historical __main__ class names.  No game tree is copied.
                      "exec " #$python-2 "/bin/python2 -B -s -E "
                      data "/Dungeons_of_Decay.py \"$@\"\n") port)))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal coreutils-minimal python-2 dungeonsofdecay-libtcod))
    (home-page "https://sourceforge.net/projects/dungeonsofdecay/")
    (synopsis "Coffee-break dungeon exploration roguelike")
    (description
     "Dungeons of Decay is Matthias Sommer's historical coffee-break
roguelike.  Explore randomized dungeons, fight monsters and collect equipment
using the original turn-based keyboard interface.  This package retains the
0.4.9 Python 2 game and its libtcod 1.5.0 renderer, with immutable scripts and
artwork.  Native savegame.rls shelve files reside below
@file{$XDG_DATA_HOME/dungeonsofdecay}, falling back to
@file{$HOME/.local/share/dungeonsofdecay}.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:gpl3+ license:bsd-3 license:public-domain
                   dungeonsofdecay-steve-wallace-permission))))
