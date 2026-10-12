;;; GNU Guix package for Enemy Trench's native Python/SDL game.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages enemy-trench)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages c)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages textutils))

(define tutorial-license
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/TStand90/tcod_tutorial_v2/"
          "6df33407c2146f45b424b7ffed15d67a18891b9f/LICENSE.txt"))
    (file-name "enemy-trench-tutorial-CC0.txt")
    (sha256
     (base32 "1684rx3wb9z994zx1a6064in11slkxw4zrgzi9hzglw76hs0y0d2"))))

(define glad-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/Dav1dde/glad/v0.1.28/LICENSE")
    (file-name "enemy-trench-tcod-glad-LICENSE")
    (sha256
     (base32 "0igv95bndn1mvw7987h5rw85slxl079xnvfdmdhan77gsjcq7a52"))))

;; Guix has SoundFile, CFFI, NumPy and pcpp, but no Python tcod.  The public
;; libtcod 2.2.2 uses SDL3; this SDL2 binding needs its matching 1.20.1 sources.
;; The upstream sdist contains all those C/Python sources, not binary wheels.
(define python-tcod-enemy-trench
  (package
    (name "python-tcod-enemy-trench")
    ;; AudioDevice.convert and the current mixer API were added in 13.6.
    (version "13.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tcod" version))
       (sha256
        (base32 "1g08dw9l13i37ivcbxscv72k6is0vq7dfzm4gb9hwzrjbici1xwa"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; This sdist ships tests/data, but not the upstream Python test suite.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'use-system-compression-and-unicode
            (lambda _
              (use-modules (guix build utils))
              ;; The sdist uses CRLF here.  Normalize only the patched file,
              ;; then apply the upstream parser backport without fuzz.
              (substitute* "build_sdl.py"
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "-i"
                      #$(local-file
                         (search-tay-package-file
                          "patches/enemy-trench-tcod-sdl-variadic.patch")))
              ;; Preserve the binding's matching libtcod and generated GL
              ;; loader; use the channel's public zlib/utf8proc implementations.
              (delete-file-recursively "libtcod/src/vendor/zlib")
              (delete-file-recursively "libtcod/src/vendor/utf8proc")
              ;; isascii is a nonstandard ctype extension hidden by strict
              ;; C99 feature selection.  Express its exact 7-bit predicate
              ;; portably, preserving the xterm keyboard translation.
              (substitute* "libtcod/src/libtcod/renderer_xterm.c"
                (("isascii\\(ch\\)") "(ch >= 0 && ch <= 0x7f)"))
              (substitute* "build_libtcod.py"
                (("sources \\+= \\[\"libtcod/src/vendor/utf8proc/utf8proc.c\"\\]") "")
                (("sources \\+= glob.glob\\(\"libtcod/src/vendor/zlib/\\*.c\"\\)") "")
                (("libraries: List\\[str\\] = \\[\\*build_sdl.libraries\\]")
                 "libraries: List[str] = [*build_sdl.libraries, 'z', 'utf8proc']"))
              ;; get_package_data refers to old absent tcod/lib notices.
              ;; Install the actual snapshot's notices explicitly below.
              (substitute* "setup.py"
                (("        \"lib/(LIBTCOD-CREDITS.txt|LIBTCOD-LICENSE.txt|README-SDL.txt)\",\n") ""))))
          (add-after 'install 'install-native-notices
            (lambda _
              (use-modules (guix build utils))
              (let ((doc (string-append #$output "/share/doc/python-tcod-enemy-trench")))
                (install-file "LICENSE.txt" doc)
                (install-file "libtcod/LICENSE.txt" (string-append doc "/libtcod"))
                (install-file "libtcod/LIBTCOD-CREDITS.txt" (string-append doc "/libtcod"))
                (copy-file #$glad-license (string-append doc "/glad-LICENSE"))
                ;; Preserve complete original source notices for the small
                ;; bundled lodepng/stb/GL components compiled into the extension.
                (for-each
                 (lambda (file)
                   (install-file (string-append "libtcod/src/vendor/" file)
                                 (string-append doc "/vendor")))
                 '("khrplatform.h" "lodepng.c" "lodepng.h" "stb_truetype.h"))))))))
    (native-inputs
     (list python-setuptools python-wheel python-pcpp python-pycparser))
    (inputs (list sdl2 zlib utf8proc))
    (propagated-inputs
     (list python-cffi python-numpy-1 python-typing-extensions))
    (home-page "https://github.com/libtcod/python-tcod")
    (synopsis "SDL2 Python tcod bindings for Enemy Trench")
    (description
     "This private dependency builds Python tcod and its matching libtcod
1.20.1 sources for Enemy Trench's SDL2 interface.  Compression and Unicode
processing use Guix libraries; all native components are built from source.")
    (license (list license:bsd-2 license:bsd-3 license:expat license:zlib))))

;; Keep one NumPy ABI/API generation throughout this older application's
;; closure, reusing Guix's source-built SoundFile and its absolute libsndfile.
(define python-soundfile-enemy-trench
  (package
    (inherit python-soundfile)
    (name "python-soundfile-enemy-trench")
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-soundfile)
       (replace "python-numpy" python-numpy-1)))))

(define-public enemy-trench
  (let ((commit "698bee218f76d16b98abc7eb2991a7690fffd9b4")
        (revision "0"))
    (package
      (name "enemy-trench")
      ;; Untagged final update after the 1.0.5 release, not a fabricated tag.
      (version (git-version "1.0.5" revision commit))
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://gitlab.com/api/v4/projects/30983243/"
               "repository/archive.tar.gz?sha="
               commit))
         (file-name (string-append name "-" version ".tar.gz"))
         (sha256
          (base32 "07pv78krzf0s978svyyrs2wzibk6rwsh8r2z16fibkas7x2mqd13"))
         (patches
          (list (search-tay-package-file
                 "patches/enemy-trench-paths-and-gas-audio.patch")))
         (modules '((guix build utils)))
         (snippet
          '(begin
             ;; All 94 shipped Python 3.9/3.10/3.11 bytecode files are stale.
             (for-each delete-file (find-files "." "\\.pyc$"))
             (for-each delete-file-recursively
                       (find-files "." "__pycache__$" #:directories? #t))))))
      (build-system copy-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'separate-resources-and-state
              (lambda _
                (use-modules (guix build utils))
                (let ((data (string-append #$output "/share/enemy-trench")))
                  ;; Every audio resource, including concatenated music names,
                  ;; uses an absolute immutable path.  No CWD workaround.
                  ;; SoundFile defaults to float64, which SDL2 cannot convert.
                  ;; Decode directly as SDL's native float32 sample format;
                  ;; keep channels, samplerate, mixer timing and gain intact.
                  (substitute* (find-files "." "\\.py$")
                    (("soundfile.read\\(([^,\n]*)\\)" all resource)
                     (string-append "soundfile.read(" resource
                                    ", dtype=\"float32\")"))
                    (("soundfile.read\\(\"media/")
                     (string-append "soundfile.read(\"" data "/media/")))
                  (substitute* '("main.py" "setup_game.py" "input_handlers.py"
                                 "engine.py")
                    (("path.join\\(game_dir, \"(settings.ini|saves[^\"]*)\"" all relative)
                     (string-append "path.join(state_dir, \"" relative "\""))
                    (("game_dir\\+\"/saves\"") "path.join(state_dir, \"saves\")")
                    (("open\\(\"settings.ini\"")
                     "open(path.join(state_dir, \"settings.ini\")")
                    (("makedirs\\(\"saves\"\\)")
                     "makedirs(path.join(state_dir, \"saves\"))"))
                  (copy-file
                   #$(local-file (search-tay-package-file "enemy-trench-paths.py"))
                   "enemy_trench_paths.py"))))
            (replace 'install
              (lambda _
                (use-modules (guix build utils))
                (let* ((data (string-append #$output "/share/enemy-trench"))
                       (doc (string-append #$output "/share/doc/enemy-trench"))
                       (bin (string-append #$output "/bin"))
                       (launcher (string-append bin "/enemy-trench"))
                       (site #$(string-append
                                "/lib/python"
                                (version-major+minor (package-version python))
                                "/site-packages"))
                       (dependencies
                        (list #$python-tcod-enemy-trench #$python-soundfile-enemy-trench
                              #$python-numpy-1 #$python-cffi #$python-pycparser
                              #$python-typing-extensions)))
                  (mkdir-p data)
                  (mkdir-p doc)
                  (mkdir-p bin)
                  (for-each
                   (lambda (file)
                     (let ((relative (if (string-prefix? "./" file)
                                         (substring file 2) file)))
                       (install-file file (string-append data "/" (dirname relative)))))
                   (find-files "." "\\.py$"))
                  (copy-recursively "media" (string-append data "/media"))
                  (for-each (lambda (file) (install-file file doc))
                            '("LICENSE.EnemyTrench.txt" "README.txt" "requirements.txt"))
                  (copy-file #$tutorial-license (string-append doc "/tutorial-CC0.txt"))
                  (call-with-output-file (string-append doc "/THIRD-PARTY-NOTICES.txt")
                    (lambda (port)
                      (display
                       (string-append
                        "Enemy Trench: Copyright (C) 2022 vulkanoid, "
                        "GPL-3.0-or-later.\n"
                        "Tutorial-derived code: TStand90/tcod_tutorial_v2, "
                        "CC0-1.0.\n"
                        "Source: https://github.com/TStand90/tcod_tutorial_v2/"
                        "tree/6df33407c2146f45b424b7ffed15d67a18891b9f\n"
                        "Python tcod, SoundFile, NumPy, CFFI, SDL2 and "
                        "libsndfile are separate source-built Guix dependencies "
                        "retaining their own notices.\n"
                        "The gas audio filename mismatch is repaired to use "
                        "upstream gas_breath.ogg; the inferred history basis "
                        "is recorded in the channel patch.\n")
                       port)))
                  ;; -I -S excludes the caller's Python variables, user site,
                  ;; sitecustomize/.pth hooks and working directory.  -B prevents
                  ;; any cache creation.  Add only our explicit runtime closure.
                  (call-with-output-file (string-append data "/launch.py")
                    (lambda (port)
                      (display "import sys\n" port)
                      (format port "sys.path[:0] = [~s" data)
                      (for-each (lambda (dependency)
                                  (format port ", ~s" (string-append dependency site)))
                                dependencies)
                      (display "]\nimport main\nmain.main()\n" port)))
                  (call-with-output-file launcher
                    (lambda (port)
                      (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                      (display
                       (string-append "test $# -eq 0 || { "
                                      "echo 'usage: enemy-trench' >&2; "
                                      "exit 64; }\n")
                       port)
                      (format port "exec ~a/bin/python3 -I -S -B ~s~%"
                              #$python (string-append data "/launch.py"))))
                  (chmod launcher #o555)))))))
      (inputs (list bash-minimal python python-tcod-enemy-trench
                    python-soundfile-enemy-trench python-numpy-1 python-cffi
                    python-pycparser python-typing-extensions))
      (home-page "https://gitlab.com/vulkanoid/enemy-trench")
      (synopsis "World War I graphical turn-based roguelike")
      (description
       "Enemy Trench is a graphical turn-based roguelike set during the Battle
of the Somme.  Choose an infantryman, medic or sergeant and advance through
trenches and other battlefields.  This package runs the native Python/SDL2 game
with immutable media and stores settings and saves in the user's XDG data
directory.  The pinned version is the untagged final update after 1.0.5.")
      (license (list license:gpl3+ license:cc0)))))
