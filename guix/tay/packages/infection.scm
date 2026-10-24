;;; Original Infection 2013 and its source-built Derelict bindings.

(define-module (tay packages infection)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages dlang))

;; The included DerelictTCOD types target this exact historical API.  Share
;; its existing source build, portability fixes and notices unchanged.
(define infection-libtcod
  (@@ (tay packages dwarftown) dwarftown-libtcod))

(define infection-font-license
  (license:non-copyleft
   "file://share/doc/infection/infection-font-notices.txt"
   "Bitstream Vera and Arev font licenses; DejaVu changes are public domain"))

(define-public infection
  (package
    (name "infection")
    ;; The author labels this the 2013 7DRL, without a numbered release.
    (version "2013")
    (source
     (origin
       (method url-fetch)
       ;; Preserve the author's exact bytes via Guix's verified archive route;
       ;; the live author server sends a malformed doubled media type.
       (uri (string-append
             "https://web.archive.org/web/20160809031909/"
             "http://www.tndwolf.org/infection/infection_src.rar"))
       (file-name "infection-2013-src.rar")
       (sha256
        (base32 "02hjbbmsdmj4322xdvsxyi5bw3paj6np7c9qyhmb0ag4wb4hd5hs"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; upstream supplies no automated suite
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (mkdir "source")
              (chdir "source")
              ;; libarchive reads RAR without nonfree unrar.  Never extract
              ;; Mercurial history, archived executables or import libraries.
              (invoke "bsdtar" "-xf" source
                      "--exclude=.hg" "--exclude=.hg/*"
                      "--exclude=src/lib" "--exclude=src/build"
                      "--exclude=*.exe" "--exclude=*.dll"
                      "--exclude=*.lib" "--exclude=*.obj"
                      "--exclude=*.o" "--exclude=*.a"
                      "--exclude=*.so" "--exclude=*.dylib")
              ;; Keep the author's two custom glyph cells, not the similarly
              ;; named but different sample bitmap from libtcod.
              (call-with-output-file "font.sha256"
                (lambda (port)
                  (display
                   (string-append
                    "cb17ade2c0a346af0de6f5d66877d68cf"
                    "2736d1689ae7bc4dc4e34382e1720ce"
                    "  data/dejavu16x16_gs_tc.png\n")
                   port)))
              (invoke "sha256sum" "-c" "font.sha256")
              (delete-file "font.sha256")))
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              ;; Only D text is normalized.  No data, title or font bytes are
              ;; rewritten.  These files came from a Windows working tree.
              (substitute* (find-files "src" "\\.d$")
                (("\r") ""))
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/infection-portability.patch")))
              (substitute* "src/derelict/tcod/libtcod.d"
                (("enum libNames = \"libtcod\\.so\";")
                 (string-append "enum libNames = \"" #$infection-libtcod
                                "/lib/libtcod.so\";")))
              ;; Reuse the renderer's pinned, sanitized source only to retain
              ;; the original font README, just as in the HandhRL package.
              (mkdir "renderer-source")
              (invoke "tar" "xf" #+(package-source infection-libtcod)
                      "--strip-components=1" "-C" "renderer-source")))
          (replace 'build
            (lambda _
              (mkdir-p "build")
              ;; Match upstream's release mode.  Compile the entire Linux
              ;; closure, not the archived Windows Derelict .lib files.
              ;; wintypes/xtypes are unused on this platform; sharedlib's
              ;; Windows branch alone imports wintypes.
              (invoke "ldc2" "--gcc=gcc" "-release" "-Isrc" "-od=build"
                      "-of=build/infection"
                      "src/main.d" "src/characters.d" "src/map.d"
                      "src/system.d" "src/traits.d" "src/world.d"
                      "src/derelict/tcod/types.d"
                      "src/derelict/tcod/functions.d"
                      "src/derelict/tcod/libtcod.d"
                      "src/derelict/util/exception.d"
                      "src/derelict/util/loader.d"
                      "src/derelict/util/sharedlib.d"
                      "src/derelict/util/system.d")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/infection"))
                     (doc (string-append #$output "/share/doc/infection"))
                     (launcher (string-append #$output "/bin/infection"))
                     (renderer-doc
                      (string-append #$infection-libtcod
                                     "/share/doc/dwarftown-libtcod")))
                (install-file "build/infection"
                              (string-append #$output "/libexec"))
                (copy-recursively "data" (string-append data "/data"))
                (install-file "src/license.txt" doc)
                (for-each
                 (lambda (file)
                   (install-file
                    (string-append renderer-doc "/" file) doc))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"
                   "README-SDL.txt" "lodepng.c" "lodepng.h"))
                (copy-file "renderer-source/data/fonts/README.txt"
                           (string-append doc "/libtcod-fonts-README.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "files/infection-provenance.txt"))
                 (string-append doc "/infection-provenance.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "files/infection-font-notices.txt"))
                 (string-append doc "/infection-font-notices.txt"))
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    ;; Original reads are all data/ relative.  No active save
                    ;; system exists, so do not invent persistent state or a
                    ;; copied writable game tree.  HOME/XDG remain caller-owned.
                    (format port
                            (string-append
                             "#!~a/bin/sh\nset -eu\numask 077\n"
                             "cd -- '~a'\n"
                             "exec '~a/libexec/infection' \"$@\"\n")
                            #$bash-minimal data #$output)))
                (chmod launcher #o555)))))))
    (native-inputs (list ldc libarchive))
    (inputs (list bash-minimal infection-libtcod))
    (home-page "https://www.tndwolf.org/infection/")
    (synopsis "Infect a human body in a turn-based roguelike")
    (description
     "Infection is Luca Carbone's 2013 Seven Day Roguelike Challenge game.
Guide a pathogen through the body's organs, infect cornerstone cells, fight
immune cells and acquire traits with the resources you consume.  This package
builds the original D game and included Derelict bindings from source, retaining
both difficulty modes, original controls, title art and modified DejaVu bitmap
font.  The launcher reads the original assets from immutable storage; the game
has no active save system.")
    (supported-systems (package-supported-systems ldc))
    (license (list license:bsd-2 license:boost1.0 license:bsd-3
                   license:zlib infection-font-license))))
