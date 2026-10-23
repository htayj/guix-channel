;;; Original HandhRL 0.3 with the channel's shared historical libtcod renderer.

(define-module (tay packages handhrl)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python))

;; Share the already source-built 1.5.1 renderer, including its portability
;; changes and notices, rather than maintaining another library recipe.
(define handhrl-libtcod
  (@@ (tay packages dwarftown) dwarftown-libtcod))

(define-public handhrl
  (package
    (name "handhrl")
    (version "0.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/jarcane/handhRL")
             (commit "03d0d256f150af256ac34a62fdafbf1a7514d76b")))
       (file-name (git-file-name name version))
       ;; Recursive checkout hash; the full tree matches the original codeload
       ;; archive, including executable bits and the two binary symlinks.
       (sha256
        (base32 "04i5j81p9nlj16n7wqdgx3ldqii8409cfzafsh29lwaz19ppqqgd"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; Remove the root binary symlinks before their platform targets.
            ;; No archived runtime or release executable is a build input.
            (for-each delete-file '("libtcod.so" "libtcodgui.so"))
            (for-each delete-file-recursively
                      '("linux32" "linux64" "releases"))
            (for-each delete-file
                      (find-files "." "\\.(exe|dll|so(\\..*)?|a|o|lib|dylib|pyc|pyo)$"))
            ;; The icon is used only by the Windows py2exe build script.
            (for-each delete-file '("build_exe.py" "handhicon.ico"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; upstream supplies no automated suite
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)               ; original Python 2 modules, not py2exe
          (delete 'install-license-files)
          (add-after 'unpack 'prepare-runtime
            (lambda _
              ;; This native build input is the shared renderer's own sanitized,
              ;; pinned origin, not another copy or a vendored prototype table.
              (mkdir "renderer-source")
              (invoke "tar" "xf" #+(package-source handhrl-libtcod)
                      "--strip-components=1" "-C" "renderer-source")
              (copy-file "renderer-source/cprotos.py" "cprotos.py")
              (with-fluids ((%default-port-encoding "ISO-8859-1"))
                (substitute* '("handhrl.py" "libtcodpy.py")
                  (("\r") ""))
                (substitute* "libtcodpy.py"
                  (("\\['\\./libtcod\\.so'\\]")
                   (string-append "['" #$handhrl-libtcod "/lib/libtcod.so']"))
                  ;; Use upstream's full prototype setup on Linux as well.
                  ;; The 1.5.1 Key fields need no 1.5.0 bitfield adaptation.
                  (("^if MAC:") "if MAC or LINUX:"))
                (substitute* "handhrl.py"
                  (("'terminal16x16_gs_ro\\.png'")
                   (string-append "'" #$output
                                  "/share/handhrl/terminal16x16_gs_ro.png'"))))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/handhrl"))
                     (doc (string-append #$output "/share/doc/handhrl"))
                     (launcher (string-append #$output "/bin/handhrl"))
                     (renderer-doc
                      (string-append #$handhrl-libtcod
                                     "/share/doc/dwarftown-libtcod")))
                ;; All original Linux game modules and its only loaded asset.
                ;; Procedural backgrounds and every game mode remain upstream.
                (for-each (lambda (file) (install-file file data))
                          '("handhrl.py" "hhmessage.py" "hhtable.py"
                            "libtcodpy.py" "cprotos.py"
                            "terminal16x16_gs_ro.png"))
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING.txt" "README.md" "LIBTCOD-LICENSE.txt"
                            "README-SDL.txt"))
                (copy-file "renderer-source/data/fonts/README.txt"
                           (string-append doc "/libtcod-fonts-README.txt"))
                (for-each
                 (lambda (file)
                   (install-file (string-append renderer-doc "/" file) doc))
                 '("LIBTCOD-CREDITS.txt" "lodepng.c" "lodepng.h"))
                ;; Retain both the game's bundled notices and the renderer's
                ;; notices without assuming the two copies are identical.
                (for-each
                 (lambda (file)
                   (copy-file (string-append renderer-doc "/" file)
                              (string-append doc "/renderer-" file)))
                 '("LIBTCOD-LICENSE.txt" "README-SDL.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file "files/handhrl-provenance.txt"))
                 (string-append doc "/handhrl-provenance.txt"))
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\numask 077\n"
                      "data_home=${XDG_DATA_HOME:-"
                      "${HOME:?HOME must be set}/.local/share}\n"
                      "case $data_home in\n"
                      "  /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'handhrl: data must be outside the store' "
                      ">&2; exit 1;;\n"
                      "  /*) ;;\n"
                      "  *) printf '%s\\n' "
                      "'handhrl: data directory must be absolute' "
                      ">&2; exit 1;;\n"
                      "esac\n"
                      "state=$(" #$coreutils-minimal
                      "/bin/realpath -m -- \"$data_home/handhrl\")\n"
                      "case $state in /gnu/store|/gnu/store/*) printf '%s\\n' "
                      "'handhrl: resolved data must be outside the store' "
                      ">&2; exit 1;; esac\n"
                      #$coreutils-minimal "/bin/mkdir -p -- \"$state\"\n"
                      "cd -- \"$state\"\n"
                      ;; File execution preserves shelve's __main__ identities.
                      ;; Only savegame/scorefile live here; no copied game tree.
                      "exec " #$python-2 "/bin/python2 -B -s -E "
                      data "/handhrl.py \"$@\"\n") port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal coreutils-minimal python-2 handhrl-libtcod))
    (home-page "https://github.com/jarcane/handhRL")
    (synopsis "Science-fiction dungeon exploration roguelike")
    (description
     "HandhRL is John S. Berry III's roguelike based on the Hulks and Horrors
tabletop roleplaying game.  Explore randomized caves, fight monsters and
collect equipment through the original turn-based keyboard interface.  This
package preserves the 0.3 Python 2 game, libtcod 1.5.1 renderer and original
font, with immutable modules and artwork.  Native savegame and scorefile
shelve databases reside below @file{$XDG_DATA_HOME/handhrl}, falling back to
@file{$HOME/.local/share/handhrl}.")
    (supported-systems '("x86_64-linux" "i686-linux" "aarch64-linux"))
    ;; Public domain applies to the font, not the tutorial-derived code.
    (license (list license:gpl3+ license:bsd-3 license:public-domain
                   license:zlib))))
