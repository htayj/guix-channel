;;; GNU Guix package for the original Goblin Camp, now Goblins' Lot.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages goblins-lot)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages image)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages stb)
  #:use-module (gnu packages textutils))

;; 1.23.1 changes TCOD_RENDERER_SDL into an alias for the accelerated renderer.
;; This game uses the original software-renderer surface/callback interface.
;; Keep the complete pre-alias SDL2 implementation, not Guix's SDL3 libtcod.
(define libtcod-goblins-lot
  (package
    (name "libtcod-goblins-lot")
    (version "1.23.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/libtcod/libtcod/tar.gz/"
             "8fa20ee7a7b0a84e029aa743245a3030d6c19a1d"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0pbpda62r2sv1hvv0ibwv35saiz03c02hmmx07902qdkcsn9f740"))
       (patches
        (list (search-tay-package-file
               "patches/goblins-lot-libtcod-system-libraries.patch")))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            (copy-file
             #$(local-file (search-tay-package-file
                            "files/goblins-lot-GLAD-LICENSE.txt"))
             "src/vendor/GLAD-LICENSE.txt")
            ;; All replaced components come from ordinary Guix inputs.
            ;; Keep vendor/stb.c, the implementation TU for both stb headers,
            ;; and the matching generated GLAD loader and Khronos header.
            (for-each delete-file
                      '("src/vendor/lodepng.c" "src/vendor/lodepng.h"
                        "src/vendor/stb_ds.h" "src/vendor/stb_truetype.h"))
            (for-each delete-file-recursively
                      '("src/vendor/zlib" "src/vendor/utf8proc" "vcpkg"))))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "-DCMAKE_TOOLCHAIN_FILE="
              "-DBUILD_SHARED_LIBS=ON"
              "-DLIBTCOD_TESTS=ON"
              "-DLIBTCOD_THREADS=ON"
              "-DLIBTCOD_SDL2=find_package"
              "-DLIBTCOD_ZLIB=find_package"
              "-DLIBTCOD_GLAD=vendored"
              "-DLIBTCOD_LODEPNG=find_package"
              ;; This branch is patched to pkg-config, not the vcpkg toolchain.
              "-DLIBTCOD_UTF8PROC=vcpkg"
              "-DLIBTCOD_STB=find_package"
              (string-append "-DStb_INCLUDE_DIR=" #$stb))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'use-absolute-fontconfig
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "LIBTCOD_GOBLINS_LOT_SOURCE" (getcwd))
              (substitute* "src/libtcod/tileset_fallback.c"
                (("popen\\(\"fc-match")
                 (string-append "popen(\""
                                (search-input-file inputs "/bin/fc-match"))))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Upstream does not register CTest tests.  Run its real
                ;; Catch executable; display-dependent cases carry this tag.
                (copy-recursively
                 (string-append (getenv "LIBTCOD_GOBLINS_LOT_SOURCE") "/data")
                 "data")
                (setenv "HOME" (getcwd))
                (setenv "XDG_RUNTIME_DIR" (getcwd))
                (setenv "LD_LIBRARY_PATH" (string-append (getcwd) "/bin"))
                (invoke "bin/unittest" "~[!nonportable]"))))
          (add-after 'install 'install-retained-notices
            (lambda _
              (let ((doc (string-append
                          #$output "/share/doc/libtcod-goblins-lot")))
                (for-each
                 (lambda (file)
                   (install-file
                    (string-append (getenv "LIBTCOD_GOBLINS_LOT_SOURCE")
                                   "/" file) doc))
                 '("LICENSE.txt" "LIBTCOD-CREDITS.txt"))
                (for-each
                 (lambda (file)
                   (install-file (string-append
                                  (getenv "LIBTCOD_GOBLINS_LOT_SOURCE")
                                  "/src/vendor/" file)
                                 (string-append doc "/vendor")))
                 '("glad.c" "glad.h" "khrplatform.h" "stb.c"))
                ;; The external stb headers are compiled into this library.
                (for-each
                 (lambda (file)
                   (install-file (string-append #$stb "/" file)
                                 (string-append doc "/vendor")))
                 '("stb_ds.h" "stb_truetype.h"))
                (install-file
                 #$(local-file (search-tay-package-file
                                "files/goblins-lot-GLAD-LICENSE.txt")) doc)
                (install-file
                 #$(local-file (search-tay-package-file
                                "files/goblins-lot-stb-LICENSE.txt")) doc)))))))
    (native-inputs (list catch2 pkg-config))
    (inputs (list fontconfig lodepng/c sdl2 stb utf8proc zlib))
    (home-page "https://github.com/libtcod/libtcod")
    (synopsis "Complete SDL2 libtcod for Goblins' Lot")
    (description
     "This private libtcod preserves the software SDL2 renderer used by
Goblins' Lot, alongside its other renderers, Unicode, compression and threads.
It uses Guix's SDL2, LodePNG, utf8proc, zlib and whole stb headers, retaining the
matching generated GLAD loader without a network dependency manager.")
    (license (list license:bsd-3 license:expat))))

(define-public goblins-lot
  (let ((commit "497febbb3d1c807d475b7ba5299cb4527d5f8bd3")
        (revision "0"))
    (package
      (name "goblins-lot")
      ;; Upstream calls this 0.25dev; it is not a published 0.25 release.
      ;; This snapshot includes upstream's Python 3.12 and thread/GIL fixes.
      (version (git-version "0.25" revision commit))
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://gitlab.com/api/v4/projects/12852178/"
               "repository/archive.tar.gz?sha=" commit))
         (file-name (string-append name "-" version ".tar.gz"))
         (sha256
          (base32 "0fqi26b2w4r371gm4q1g4g83ca882d0shayxdh59jxgvmmip41lb"))
         (patches
          (list (search-tay-package-file
                 "patches/goblins-lot-native-paths.patch")))
         (modules '((guix build utils) (ice-9 rdelim)))
         (snippet
          #~(begin
              ;; These nine PE binaries and accompanying prebuilt reporter
              ;; outputs are unused by the native Linux CMake build.  Do not
              ;; redistribute Microsoft runtime/debug DLLs or opaque Windows
              ;; builds in the repacked source; retain all game source/assets.
              (delete-file-recursively "tools/installer/redists")
              (delete-file-recursively "game/crash-reporter/prebuilt")
              (delete-file "game/crash-reporter/ICSharpCode.SharpZipLib.dll")
              ;; Restore omitted referenced licenses in the distributed source,
              ;; not just in the installed binary's documentation directory.
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-libtappp-LICENSE.txt"))
               "t/libtappp/LICENSE")
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-pefile-COPYING.txt"))
               "tools/COPYING")
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-CMake-Copyright.txt"))
               "cmake/Copyright.txt")
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-CPython-3.11-LICENSE.txt"))
               "game/lib/gcamp/CPython-LICENSE.txt")
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-THIRD-PARTY-NOTICES.txt"))
               "THIRD-PARTY-NOTICES.txt")
              (copy-file
               #$(local-file (search-tay-package-file
                              "files/goblins-lot-notice-sources.txt"))
               "NOTICE-SOURCES.txt")
              ;; The module headers explicitly request the full license when
              ;; distributed outside CMake.  Keep all original author notices.
              (for-each
               (lambda (module)
                 (let ((port (open-file module "a")))
                   (display "\n# Full CMake license restored for GNU Guix, 2026-10-21.\n"
                            port)
                   (call-with-input-file "cmake/Copyright.txt"
                     (lambda (input)
                       (let loop ((line (read-line input)))
                         (unless (eof-object? line)
                           (display "# " port)
                           (display line port)
                           (newline port)
                           (loop (read-line input))))))
                   (close-port port)))
               '("cmake/FindSDL2.cmake" "cmake/FindSDL2_image.cmake"))))))
      (build-system cmake-build-system)
      (arguments
       (list
        #:configure-flags
        #~(list "-DCMAKE_CXX_STANDARD=17"
                "-DUSE_THREADS=ON"
                (string-append "-DGOBLIN_CAMP_BINDIR=" #$output "/bin"))
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'record-source-directory
              (lambda _
                (setenv "GOBLINS_LOT_SOURCE" (getcwd))))
            (add-before 'check 'build-original-tests
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (invoke "cmake" "--build" "." "--target" "build-test"
                          "--parallel" "1"))))
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  ;; Exercise the original target and prove, not an empty
                  ;; CTest registry.  Main must establish any target defect.
                  (invoke "cmake" "--build" "." "--target" "test"
                          "--parallel" "1"))))
            (add-after 'install 'install-copyrights-and-provenance
              (lambda _
                (let ((doc (string-append #$output "/share/doc/goblins-lot")))
                  (with-directory-excursion (getenv "GOBLINS_LOT_SOURCE")
                    (for-each
                     (lambda (file) (install-file file doc))
                     '("COPYING.txt" "README.md" "CHANGELOG.md"))
                    (copy-file "game/Readme.md"
                               (string-append doc "/game-Readme.md"))
                    ;; Includes the complete incorporated BSD-3 notice.
                    (install-file "game/include/Color.hpp" doc))
                  (for-each
                   (lambda (file) (install-file file doc))
                   (list
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-THIRD-PARTY-NOTICES.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-notice-sources.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-CPython-3.11-LICENSE.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-libtcod-1.5.1-LICENSE.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-libtcod-fonts-README.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-libtappp-LICENSE.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-CMake-Copyright.txt"))
                    #$(local-file (search-tay-package-file
                                   "files/goblins-lot-pefile-COPYING.txt"))))))))))
      (native-inputs (list perl pkg-config))
      (inputs (list boost python sdl2 sdl2-image mesa libpng zlib
                    libtcod-goblins-lot))
      (home-page "https://gitlab.com/dhyannataraj/goblins-lot")
      (synopsis "Original Goblin Camp settlement simulation")
      (description
       "Goblins' Lot is the maintained continuation of Ilkka Halila's original
Goblin Camp settlement simulation, not the newer game with that name.  Manage
goblins and orcs, designate construction and stockpiles, and survive in a
procedurally generated world.  This package builds the complete native game
with its ASCII display, both original graphical tilesets, embedded Python
scripts, core data, font and icons.  Native configuration and saves live below
@file{$XDG_CONFIG_HOME/goblins-lot}, or @file{$HOME/.config/goblins-lot}.")
      ;; Original artwork/data: GPLv3 minimum; code headers: GPLv3-or-later.
      ;; Color.hpp: BSD-3; copied imp.load_package: PSF; identified crawl-tiles
      ;; collection components: CC0.  See installed provenance for exact scope.
      (license (list license:gpl3 license:gpl3+ license:bsd-3 license:psfl
                     license:cc0)))))
