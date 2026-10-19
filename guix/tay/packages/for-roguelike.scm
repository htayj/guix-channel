;;; FOR's complete original alpha, recovered from its canonical Git history.

(define-module (tay packages for-roguelike)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages xml))

;; Reuse the channel's already source-built exact historical C/C++ API, including
;; Unicode, SDL 1.2 and OpenGL.  Current libtcod is not API-compatible.
(define for-libtcod
  (@@ (tay packages dwarftown) dwarftown-libtcod))

(define for-font-license
  (license:non-copyleft
   "file://share/doc/for-roguelike/for-roguelike-font-license.txt"
   "Bitstream Vera and Arev font licenses; DejaVu changes are public domain"))

(define-public for-roguelike
  (package
    (name "for-roguelike")
    (version "0.1alpha-0.6ce29fb")
    (source
     (origin
       (method url-fetch)
       ;; Canonical lcarst/for master, commit 6ce29fb0d9ebb020c12264630a828ec205a31362.
       ;; Software Heritage's full 2015-08-09 visit, not a partial later visit.
       (uri (string-append
             "https://archive.softwareheritage.org/api/1/vault/flat/"
             "swh:1:dir:67ae1e5002b1bc69f97a8fe4e1fd2736374356ae/raw/"))
       (file-name "for-6ce29fb0d9ebb020c12264630a828ec205a31362.tar.gz")
       ;; Raw SHA256 76d0dbbaf94726358470193cb698cbed8e7a23b5ed1285c3596f12f81ebe64ab.
       (sha256
        (base32 "1av4pqggh4kgb71qa4pdnlipm3pdrfcbcg0rf223a9j7z6xdpl3n"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; These historical executables have no filename extension.
            ;; Neither source outputs nor game builds retain opaque binaries.
            (for-each delete-file
                      '("deps/libtcod-1.5.1/hmtool"
                        "deps/libtcod-1.5.1/samples_c"
                        "deps/libtcod-1.5.1/samples_c_debug"
                        "deps/libtcod-1.5.1/samples_cpp"
                        "deps/libtcod-1.5.1/samples_cpp_debug"
                        "build/osx/FOR/build/Debug/for"))
            (delete-file-recursively "deps/libsdl/SDL.framework")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                    ; upstream supplies no automated test suite
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-source
            (lambda _
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/for-roguelike-portability.patch")))
              ;; Only these immutable reads change.  All native output paths,
              ;; the debug-world branch and time-seeded RNG remain unchanged.
              (let ((data (string-append #$output "/share/for-roguelike")))
                (substitute* "src/Gui.cpp"
                  (("\"data/tileset.cfg\"")
                   (string-append "\"" data "/data/tileset.cfg\""))
                  (("\"font.png\"")
                   (string-append "\"" data "/font.png\"")))
                (substitute* "src/Debug.cpp"
                  (("\"data/items.cfg\"")
                   (string-append "\"" data "/data/items.cfg\""))))))
          (replace 'build
            (lambda _
              ;; The original Makefile names nonexistent AmmoParser.cpp et al.
              ;; Compile every actual game translation unit, including the
              ;; historical unfinished save interface, without feature cuts.
              (let* ((noise-root "deps/libnoisesrc-1.0.0/noise/src")
                     (sources
                      (append (find-files "src" "\\.cpp$")
                              (filter (lambda (file)
                                        (not (string-contains file "/win32/")))
                                      (find-files noise-root "\\.cpp$"))
                              '("deps/noiseutils/noiseutils.cpp")))
                     (flags
                      (list "-std=gnu++11" "-O2" "-g0" "-DLINUX" "-Isrc"
                            "-Ideps/noiseutils"
                            "-Ideps/libnoiseheaders-1.0.0/include"
                            (string-append "-I" #$for-libtcod "/include")
                            (string-append "-I" #$boost "/include")
                            (string-append "-I" #$xerces-c "/include")))
                     (objects
                      (map (lambda (source)
                             (string-append "build-objects/" source ".o"))
                           sources)))
                (for-each
                 (lambda (source object)
                   (mkdir-p (dirname object))
                   (apply invoke #$(cxx-for-target)
                          (append flags (list "-c" source "-o" object))))
                 sources objects)
                (apply invoke #$(cxx-for-target)
                       (append
                        (list "-o" "for-roguelike") objects
                        (append-map
                         (lambda (input)
                           (list (string-append "-L" input "/lib")
                                 (string-append "-Wl,-rpath," input "/lib")))
                         (list #$for-libtcod #$boost #$xerces-c))
                        '("-ltcodxx" "-ltcod" "-lxerces-c"
                          "-lboost_random" "-lboost_serialization" "-lm"))))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/for-roguelike"))
                     (doc (string-append #$output "/share/doc/for-roguelike"))
                     (launcher (string-append #$output "/bin/for-roguelike")))
                (install-file "for-roguelike" (string-append #$output "/libexec"))
                ;; Retain the exact active PNG bytes and all original game data.
                ;; terminal.png is unused and its provenance is not established.
                (install-file "bin/font.png" data)
                (copy-recursively "bin/data" (string-append data "/data"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md" "CHANGES"))
                (copy-recursively "meta" (string-append doc "/meta"))
                (copy-file "deps/noiseutils/COPYING.txt"
                           (string-append doc "/noiseutils-COPYING.txt"))
                (copy-file "deps/libnoisesrc-1.0.0/COPYING.txt"
                           (string-append doc "/libnoise-COPYING.txt"))
                (copy-file "deps/libtcod-1.5.1/data/fonts/README.txt"
                           (string-append doc "/libtcod-fonts-README.txt"))
                (for-each
                 (lambda (file)
                   (install-file
                    (string-append #$for-libtcod
                                   "/share/doc/dwarftown-libtcod/" file) doc))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt" "README-SDL.txt"
                   "lodepng.c" "lodepng.h"))
                (for-each
                 (lambda (file)
                   (copy-file
                    (string-append "deps/libtcod-1.5.1/" file)
                    (string-append doc "/bundled-" file)))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt"))
                (for-each
                 (lambda (file) (install-file file doc))
                 (list
                  #$(local-file
                     (search-tay-package-file "files/for-roguelike-GPL-3.txt"))
                  #$(local-file
                     (search-tay-package-file "files/for-roguelike-font-license.txt"))
                  #$(local-file
                     (search-tay-package-file "files/for-roguelike-provenance.txt"))))
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\numask 077\n"
                      "state_home=${XDG_STATE_HOME:-"
                      "${HOME:?HOME must be set}/.local/state}\n"
                      "case $state_home in\n"
                      "  /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'for-roguelike: state must be outside the store' "
                      ">&2; exit 1;;\n"
                      "  /*) ;;\n"
                      "  *) printf '%s\\n' "
                      "'for-roguelike: state directory must be absolute' "
                      ">&2; exit 1;;\n"
                      "esac\n"
                      "state=$(" #$coreutils-minimal
                      "/bin/realpath -m -- \"$state_home/for-roguelike\")\n"
                      "case $state in /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'for-roguelike: resolved state must be outside the store' "
                      ">&2; exit 1;; esac\n"
                      #$coreutils-minimal "/bin/mkdir -p -- \"$state\"\n"
                      "cd -- \"$state\"\n"
                      "exec " #$output "/libexec/for-roguelike \"$@\"\n") port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal for-libtcod boost xerces-c))
    (home-page "https://www.roguebasin.com/index.php/FOR")
    (synopsis "Original Fallout-like roguelike alpha")
    (description
     "FOR is Lasse Carstensen's original unfinished Fallout-like roguelike.
This package builds the complete recovered C++ alpha and libnoise/noiseutils
sources with the historical libtcod 1.5.1 SDL renderer and the unchanged original
font and data.  The native debug-world startup generates Junktown and supports
keyboard exploration; upstream save serializers are unfinished, not resumable
save support.  Native debug dumps go below @file{$XDG_STATE_HOME/for-roguelike},
falling back to @file{$HOME/.local/state/for-roguelike}, without copying assets
or modifying the caller's working directory.")
    (license (list license:gpl3+ license:lgpl2.1+ license:bsd-3 license:zlib
                   for-font-license))))
