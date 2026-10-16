;;; GNU Guix package for Jake Keel's Exalt.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages exalt)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages auxiliary))

;; The C++ translation units from exalt.vcproj, in its original order.  SQLite
;; is provided by Guix; unused bundled zlib and Windows VLD are not compiled.
(define %exalt-sources
  '("buff" "creature" "npc" "pc" "stats" "status" "attr" "item"
    "itemstack" "area" "cell" "cellfeature" "door" "level" "lightsrc"
    "warp" "world" "gameobj" "quality" "cmd" "gamefunc" "input" "main"
    "msg" "msgmanager" "birthstate" "gamestate" "helpstate" "mainstate"
    "logger" "random" "bitmap" "extio" "tokenizer" "db" "astar" "fov"
    "font" "fontmanager" "itemfact" "monsterfact" "box2i" "colors"
    "cstring" "infobrowser" "look" "maindisplay" "menubox" "menuoption"
    "prompt" "terminal" "vertex2i" "levelfact" "dungen" "dunroom"
    "duntemp" "duntempman" "duntheme" "maze" "simplegen" "simpletheme"
    "ai" "aidata" "aimanager" "aistate" "melee" "attackmelee" "follow"
    "moveto" "tracksmell" "wait"))

(define-public exalt
  (package
    (name "exalt")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://downloads.sourceforge.net/project/"
                           "exaltengine/exalt-" version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       ;; Published 2010-10-18.  SHA-256 of the exact source archive:
       ;; eb12dc32476105b025fbddabfb91634f6ed472d3017270ccf1f02b66d0f4f3c9.
       (sha256
        (base32 "1jgkyk86cazhy7670wh1sdrd8vjgcf8zpayxzcjv01b18wrdq4pb"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Neither opaque platform libraries nor dead private copies of
            ;; dependencies belong in the source derivation or installed tree.
            (for-each delete-file-recursively
                      '("lib" "src/sqlite" "src/zlib" "src/vld"))
            (delete-file "vld.dll")
            ;; No original font binary is redistributed: two never-selected
            ;; families have nonfree/unresolved terms, and the selected Mono
            ;; 1.04's exact grant/source provenance remains unresolved.
            (for-each delete-file (find-files "data/fonts" "\\.ttf$"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; upstream has no automated test suite
      #:parallel-build? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 popen)
                  (ice-9 textual-ports)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The upstream ZIP and snippet-produced tarball have a flat
              ;; root.  Standard unpack would select data/ as its source root.
              (mkdir "exalt-source")
              (chdir "exalt-source")
              (invoke "tar" "--extract" "--file" source)))
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'preserve-source-and-port
            (lambda _
              ;; Retain the original own code and assets for observing the
              ;; game's actual formats, before applying the Linux port.
              (copy-recursively "src" "original-source/src")
              (copy-recursively "data" "original-source/data")
              (for-each
               (lambda (file) (install-file file "original-source"))
               '("copying.txt" "exalt.vcproj"))
              ;; Upstream Win32 sources use CRLF; the Linux patches use LF.
              ;; Preserve the byte-original snapshot above before normalizing
              ;; only the working C++ files and headers for patch application.
              (substitute* (find-files "src" "\\.(cpp|h)$")
                (("\r") ""))
              (for-each
               (lambda (patch)
                 (invoke "patch" "--batch" "--forward" "-p1" "-i" patch))
               (list
                #$(local-file
                   (search-tay-package-file "patches/exalt-sdl-rendering.patch"))
                #$(local-file
                   (search-tay-package-file "patches/exalt-platform.patch"))))))
          (replace 'build
            (lambda _
              (define (pkg-config option)
                (let* ((pipe (open-pipe* OPEN_READ "pkg-config" option
                                         "sdl2" "SDL2_ttf" "sqlite3"))
                       (text (get-string-all pipe))
                       (status (close-pipe pipe)))
                  (unless (zero? status)
                    (error "pkg-config failed" option status))
                  (string-tokenize text)))
              (let* ((sources
                      (map (lambda (name) (string-append "src/" name ".cpp"))
                           '#$%exalt-sources))
                     ;; Upstream assigns map::erase's returned iterator, as
                     ;; supported by MSVC and standardized in C++11.
                     (flags (append '("-std=gnu++11" "-O2" "-g0" "-Isrc")
                                    (pkg-config "--cflags")))
                     (libraries (pkg-config "--libs")))
                (define (object source)
                  (string-append "build/" (basename source) ".o"))
                (mkdir-p "build")
                ;; Compile serially in the vcproj's deterministic order, with
                ;; warnings visible and no permissive compilation switches.
                (for-each
                 (lambda (source)
                   (apply invoke #$(cxx-for-target)
                          (append flags (list "-c" source "-o"
                                              (object source)))))
                 sources)
                (apply invoke #$(cxx-for-target) "-o" "build/exalt"
                       (append (map object sources) libraries)))))
          (replace 'install
            (lambda _
              (let* ((share (string-append #$output "/share/exalt"))
                     (doc (string-append #$output "/share/doc/exalt"))
                     (program (string-append #$output "/libexec/exalt"))
                     (launcher (string-append #$output "/bin/exalt")))
                (mkdir-p (dirname program))
                (copy-file "build/exalt" program)
                (chmod program #o555)
                (copy-recursively "data" (string-append share "/data"))
                ;; Deliberate same-family data substitution, not an assertion
                ;; that 2.1.5 reproduces the original 1.04 glyph pixels.
                (symlink
                 #$(file-append font-liberation
                                "/share/fonts/truetype/LiberationMono-Regular.ttf")
                 (string-append share "/data/fonts/liberation.ttf"))
                (copy-recursively "original-source"
                                  (string-append share "/source"))
                (copy-recursively "src" (string-append share "/source-linux/src"))
                (install-file "copying.txt" (string-append share "/source-linux"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("copying.txt" "exalt.vcproj"))
                (copy-file
                 #$(file-append
                    font-liberation
                    (string-append "/share/doc/font-liberation-"
                                   (package-version font-liberation) "/LICENSE"))
                 (string-append doc "/LIBERATION-LICENSE.txt"))
                (copy-file
                 #$(local-file (search-tay-package-file "exalt-notices.txt"))
                 (string-append doc "/THIRD-PARTY-NOTICES.txt"))
                (mkdir-p (string-append share "/source-linux/patches"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "patches/exalt-sdl-rendering.patch"))
                 (string-append share
                                "/source-linux/patches/exalt-sdl-rendering.patch"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "patches/exalt-platform.patch"))
                 (string-append share
                                "/source-linux/patches/exalt-platform.patch"))
                (copy-file
                 #$(local-file (search-tay-package-file "exalt.scm"))
                 (string-append share "/source-linux/exalt.scm"))
                (copy-file
                 #$(local-file (search-tay-package-file "exalt-wrapper.sh"))
                 (string-append share "/source-linux/exalt-wrapper.sh"))
                (copy-file
                 #$(local-file (search-tay-package-file "exalt-notices.txt"))
                 (string-append share "/source-linux/exalt-notices.txt"))
                (mkdir-p (dirname launcher))
                (copy-file
                 #$(local-file (search-tay-package-file "exalt-wrapper.sh"))
                 launcher)
                (substitute* launcher
                  (("@SH@") #$(file-append bash-minimal "/bin/sh"))
                  (("@REAL@") program)
                  (("@DATA@") (string-append share "/data"))
                  (("@MKDIR@") #$(file-append coreutils-minimal "/bin/mkdir"))
                  (("@LN@") #$(file-append coreutils-minimal "/bin/ln")))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip pkg-config))
    (inputs (list bash-minimal coreutils-minimal font-liberation
                  sdl2 sdl2-ttf sqlite))
    (home-page "https://sourceforge.net/projects/exaltengine/")
    (synopsis "Multiwindow fantasy roguelike engine")
    (description
     "Exalt is Jake Keel's graphical fantasy roguelike engine and pre-alpha
sample game.  This package compiles the original 0.3.0 C++ game with a Linux
SDL2 and SDL_ttf port, retaining the five terminal windows, world selection,
character creation and game logic.  It uses system SQLite and Liberation
Mono from Guix's font-liberation package, deliberately replacing the bundled
1.04 font with the SIL Open Font License 1.1 release 2.1.5.  Typography may
differ; all original bundled fonts and opaque Windows libraries are omitted.
User state is kept in
@file{$XDG_DATA_HOME/exalt}, falling back to
@file{$HOME/.local/share/exalt}.  Upstream's loaded-game initialization is
unfinished; this package does not add save/resume support.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    (license (list license:gpl3+ license:silofl1.1))))
