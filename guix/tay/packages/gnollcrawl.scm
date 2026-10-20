;;; GNU Guix package for the native Gnollcrawl roguelike.

(define-module (tay packages gnollcrawl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages image)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages sqlite))

;; The exact font gitlink from the game release, not replacement system fonts.
(define %gnollcrawl-fonts
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/crawl/crawl-fonts/tar.gz/"
                        "6d3046974f35189a679a4d84b254efe82d1653b3"))
    (file-name "gnollcrawl-fonts-6d304697.tar.gz")
    (sha256
     (base32 "1my66aw1wmysqr0z3smz8qyz6j7q9f4j0h8f3w22b4gnklh5k6i8"))))

;; pcg.cc supplies the copyright notice but omits the full Apache license.
;; This is the same text and verified origin used by Stoat Soup.
(define %gnollcrawl-apache-license
  (origin
    (method url-fetch)
    (uri "https://www.apache.org/licenses/LICENSE-2.0.txt")
    (file-name "gnollcrawl-apache-2.0.txt")
    (sha256
     (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))

;; Verbatim nameID 13 permission notices from the two exact upstream fonts.
;; The proportional font includes the Arev notice as well as Bitstream Vera.
(define %gnollcrawl-font-notices
  (plain-file "gnollcrawl-font-licenses.txt"
              "DejaVuSans.ttf\n==============\n\nFonts are (c) Bitstream (see below). DejaVu changes are in public domain. Glyphs imported from Arev fonts are (c) Tavmjung Bah (see below)\n\nBitstream Vera Fonts Copyright\n------------------------------\n\nCopyright (c) 2003 by Bitstream, Inc. All Rights Reserved. Bitstream Vera is\na trademark of Bitstream, Inc.\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof the fonts accompanying this license (\"Fonts\") and associated\ndocumentation files (the \"Font Software\"), to reproduce and distribute the\nFont Software, including without limitation the rights to use, copy, merge,\npublish, distribute, and/or sell copies of the Font Software, and to permit\npersons to whom the Font Software is furnished to do so, subject to the\nfollowing conditions:\n\nThe above copyright and trademark notices and this permission notice shall\nbe included in all copies of one or more of the Font Software typefaces.\n\nThe Font Software may be modified, altered, or added to, and in particular\nthe designs of glyphs or characters in the Fonts may be modified and\nadditional glyphs or characters may be added to the Fonts, only if the fonts\nare renamed to names not containing either the words \"Bitstream\" or the word\n\"Vera\".\n\nThis License becomes null and void to the extent applicable to Fonts or Font\nSoftware that has been modified and is distributed under the \"Bitstream\nVera\" names.\n\nThe Font Software may be sold as part of a larger software package but no\ncopy of one or more of the Font Software typefaces may be sold by itself.\n\nTHE FONT SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS\nOR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT,\nTRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL BITSTREAM OR THE GNOME\nFOUNDATION BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING\nANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES,\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF\nTHE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE\nFONT SOFTWARE.\n\nExcept as contained in this notice, the names of Gnome, the Gnome\nFoundation, and Bitstream Inc., shall not be used in advertising or\notherwise to promote the sale, use or other dealings in this Font Software\nwithout prior written authorization from the Gnome Foundation or Bitstream\nInc., respectively. For further information, contact: fonts at gnome dot\norg. \n\nArev Fonts Copyright\n------------------------------\n\nCopyright (c) 2006 by Tavmjong Bah. All Rights Reserved.\n\nPermission is hereby granted, free of charge, to any person obtaining\na copy of the fonts accompanying this license (\"Fonts\") and\nassociated documentation files (the \"Font Software\"), to reproduce\nand distribute the modifications to the Bitstream Vera Font Software,\nincluding without limitation the rights to use, copy, merge, publish,\ndistribute, and/or sell copies of the Font Software, and to permit\npersons to whom the Font Software is furnished to do so, subject to\nthe following conditions:\n\nThe above copyright and trademark notices and this permission notice\nshall be included in all copies of one or more of the Font Software\ntypefaces.\n\nThe Font Software may be modified, altered, or added to, and in\nparticular the designs of glyphs or characters in the Fonts may be\nmodified and additional glyphs or characters may be added to the\nFonts, only if the fonts are renamed to names not containing either\nthe words \"Tavmjong Bah\" or the word \"Arev\".\n\nThis License becomes null and void to the extent applicable to Fonts\nor Font Software that has been modified and is distributed under the \n\"Tavmjong Bah Arev\" names.\n\nThe Font Software may be sold as part of a larger software package but\nno copy of one or more of the Font Software typefaces may be sold by\nitself.\n\nTHE FONT SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF\nMERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT\nOF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL\nTAVMJONG BAH BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,\nINCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL\nDAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING\nFROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM\nOTHER DEALINGS IN THE FONT SOFTWARE.\n\nExcept as contained in this notice, the name of Tavmjong Bah shall not\nbe used in advertising or otherwise to promote the sale, use or other\ndealings in this Font Software without prior written authorization\nfrom Tavmjong Bah. For further information, contact: tavmjong @ free\n. fr.\n\nDejaVuSansMono.ttf\n==================\n\nFonts are (c) Bitstream (see below). DejaVu changes are in public domain.\n\nBitstream Vera Fonts Copyright\n------------------------------\n\nCopyright (c) 2003 by Bitstream, Inc. All Rights Reserved. Bitstream Vera is a trademark of Bitstream, Inc.\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of the fonts accompanying this license (\"Fonts\") and associated documentation files (the \"Font Software\"), to reproduce and distribute the Font Software, including without limitation the rights to use, copy, merge, publish, distribute, and/or sell copies of the Font Software, and to permit persons to whom the Font Software is furnished to do so, subject to the following conditions:\n\nThe above copyright and trademark notices and this permission notice shall be included in all copies of one or more of the Font Software typefaces.\n\nThe Font Software may be modified, altered, or added to, and in particular the designs of glyphs or characters in the Fonts may be modified and additional glyphs or  or characters may be added to the Fonts, only if the fonts are renamed to names not containing either the words \"Bitstream\" or the word \"Vera\".\n\nThis License becomes null and void to the extent applicable to Fonts or Font Software that has been modified and is distributed under the \"Bitstream Vera\" names.\n\nThe Font Software may be sold as part of a larger software package but no copy of one or more of the Font Software typefaces may be sold by itself.\n\nTHE FONT SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL BITSTREAM OR THE GNOME FOUNDATION BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE FONT SOFTWARE.\n\nExcept as contained in this notice, the names of Gnome, the Gnome Foundation, and Bitstream Inc., shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Font Software without prior written authorization from the Gnome Foundation or Bitstream Inc., respectively. For further information, contact: fonts at gnome dot org. \n\n"))

(define-public gnollcrawl
  (package
    (name "gnollcrawl")
    (version "0.19-GnollCrawlA")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/Dracunos/gnollcrawl/tar.gz/"
                           "a8ffd03080715e6321eadab873c62b14f58ff646"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1ma1nx60lxlyzyvyzvbgl0w96jlxcnkcxmjc7vss4sw9dgf6fxpn"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      #:parallel-tests? #f
      #:make-flags
      #~(list (string-append "prefix=" #$output)
              (string-append "DATADIR=" #$output "/share/gnollcrawl")
              "SAVEDIR=" "SHAREDDIR="
              (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
              (string-append "SQLITE_LIB=-L" #$sqlite "/lib -lsqlite3")
              "FORCE_CC=gcc" "FORCE_CXX=g++" "LUA_PACKAGE=lua-5.1"
              "WEBTILES=" "USE_LUAJIT=" "USE_PCRE=" "BUILD_ALL="
              "BUILD_LUA=" "BUILD_SQLITE=" "BUILD_ZLIB=" "BUILD_PCRE="
              "BUILD_FREETYPE=" "BUILD_LIBPNG=" "BUILD_SDL2="
              "BUILD_SDL2IMAGE=" "BUILD_SDL2MIXER=" "NO_TRY_GOLD=YesPlease")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-source-copies
            (lambda* (#:key tests? #:allow-other-keys)
              ;; This release mixes CRLF and LF in C/C++ source and its
              ;; Makefile.  Normalize code only before applying the LF patch;
              ;; game maps, Lua data, fonts, images and docs stay byte-exact.
              (substitute* (append (find-files "crawl-ref/source"
                                               "\\.(cc|h|c|cpp)$")
                                   '("crawl-ref/source/Makefile"))
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (canonicalize-path
                          (car
                           (search-patches
                            "tay/packages/patches/gnollcrawl-platform.patch")))))
              ;; Release archives lack Git metadata; never take a version from
              ;; an enclosing checkout.  Use the actual Gnollcrawl release.
              (call-with-output-file "crawl-ref/source/util/release_ver"
                (lambda (port) (display "0.19-GnollCrawlA\n" port)))
              (substitute* "crawl-ref/source/domino.h"
                (("#include <vector>") "#include <vector>\n#include <ostream>"))
              ;; This shared application header precedes declarations using
              ;; std::function; modern libstdc++ needs its explicit header.
              (substitute* "crawl-ref/source/AppHdr.h"
                (("#include <stdint.h>")
                 "#include <stdint.h>\n#include <functional>"))
              (substitute* "crawl-ref/source/Makefile"
                ;; substitute* retains the line's newline: match the entire
                ;; HOST assignment without an end anchor that requires EOF.
                (("^HOST := [^\n]*")
                 "HOST := $(shell sh -c 'gcc -dumpmachine || echo unknown')")
                ;; Deterministic order in the installed Lua map loader.
                (("find dat -name '\\*\\.des'\\|sed s:dat/::\\|")
                 "find dat -name '*.des'|LC_ALL=C sort|sed s:dat/::|"))
              ;; Avoid a wall-clock compilation timestamp in version output.
              ;; Preserve the rest of the genuine upstream build metadata.
              (substitute* "crawl-ref/source/version.cc"
                (("__DATE__ \\\" at \\\" __TIME__")
                 "\"reproducible Guix build\""))
              (mkdir-p "font-input")
              (invoke "tar" "xf" #$%gnollcrawl-fonts
                      "-C" "font-input" "--strip-components=1")
              (copy-recursively "font-input" "crawl-ref/source/contrib/fonts")
              ;; Different frontends and diagnostic macros must never share
              ;; objects, generated headers, or selector-dependent .cflags.
              (copy-recursively "crawl-ref" "terminal")
              (copy-recursively "crawl-ref" "tiles")
              (when tests?
                (copy-recursively "crawl-ref" "diagnostic"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (with-directory-excursion "terminal/source"
                (apply invoke "make" "-j1" "crawl" "docs"
                       "TILES=" "SOUND=" make-flags)
                ;; Stage the real installed data before any upstream tests:
                ;; DATA_DIR_PATH has no source-tree fallback.
                (apply invoke "make" "-j1" "install-data"
                       "TILES=" "SOUND=" make-flags))
              (with-directory-excursion "tiles/source"
                (let ((flags (append '("TILES=y" "SOUND=y" "COPY_FONTS=y"
                                       "SYS_PROPORTIONAL_FONT="
                                       "SYS_MONOSPACED_FONT=")
                                     make-flags)))
                  (apply invoke "make" "-j1" "crawl" "docs" flags)
                  (apply invoke "make" "-j1" "install-data" flags)))))
          (replace 'check
            (lambda* (#:key tests? make-flags #:allow-other-keys)
              (when tests?
                (let ((scratch (string-append (getcwd) "/test-state")))
                  (for-each
                   (lambda (entry)
                     (let ((directory (string-append scratch "/" (cdr entry))))
                       (mkdir-p directory)
                       (setenv (car entry) directory)))
                   '(("HOME" . "home") ("XDG_CONFIG_HOME" . "config")
                     ("XDG_DATA_HOME" . "data") ("XDG_CACHE_HOME" . "cache")
                     ("XDG_STATE_HOME" . "state") ("XDG_RUNTIME_DIR" . "runtime")
                     ("TMPDIR" . "tmp")))
                  (chmod (getenv "XDG_RUNTIME_DIR") #o700)
                  (setenv "TERM" "xterm-256color")
                  (setenv "TERMINFO_DIRS"
                          #$(file-append ncurses "/share/terminfo"))
                  ;; Do not replace the upstream stress harness defaults,
                  ;; seed, scenarios, timeout, or native fake_pty driver.
                  (let ((state (string-append scratch "/stress")))
                    (mkdir-p state)
                    (setenv "CRAWL_DIR" state)
                    (with-directory-excursion "terminal/source"
                      (apply invoke "make" "-j1" "nondebugtest"
                             "TILES=" "SOUND=" make-flags)))
                  ;; Unit tests require these documented diagnostic macros.
                  ;; This third copy and its executable are never installed.
                  (let ((state (string-append scratch "/unit"))
                        (data (string-append scratch "/unit-data")))
                    (mkdir-p state)
                    (setenv "CRAWL_DIR" state)
                    (with-directory-excursion "diagnostic/source"
                      (let ((flags
                             ;; Last assignment wins in GNU make.  Override
                             ;; only this auxiliary executable's DATADIR;
                             ;; release frontends retain immutable store data.
                             (append make-flags
                                     (list "TILES=" "SOUND="
                                           "EXTERNAL_DEFINES=-DDEBUG -DDEBUG_TESTS"
                                           (string-append "DATADIR=" data)))))
                        (apply invoke "make" "-j1" "crawl" "docs" flags)
                        (apply invoke "make" "-j1" "install-data" flags)
                        ;; ctest enumerates the source test/ tree, but its
                        ;; Lua loader resolves scripts and map fixtures via
                        ;; DATA_DIR_PATH.  Supply that full tree in the same
                        ;; private data root, without shipping test assets.
                        (copy-recursively "test" (string-append data "/test"))
                        (apply invoke "make" "-j1" "test-test" flags))))))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (data (string-append out "/share/gnollcrawl"))
                     (doc (string-append out "/share/doc/gnollcrawl"))
                     (notices (string-append doc "/source-notices")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (for-each
                 (lambda (entry)
                   (let* ((name (car entry))
                          (program (string-append libexec "/" name))
                          (launcher (string-append bin "/" name)))
                     (copy-file (cdr entry) program)
                     (chmod program #o555)
                     (call-with-output-file launcher
                       (lambda (port)
                         (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                         (display
                          (string-append
                           "case ${XDG_DATA_HOME-} in\n"
                           "  /*) base=$XDG_DATA_HOME ;;\n"
                           "  *) case ${HOME-} in\n"
                           "       /*) base=$HOME/.local/share ;;\n"
                           "       *) echo 'gnollcrawl: an absolute HOME or "
                           "XDG_DATA_HOME is required' >&2; exit 1 ;;\n"
                           "     esac ;;\n"
                           "esac\n") port)
                         ;; realpath -m resolves .. and existing symlinks even
                         ;; when the fresh per-game state does not yet exist.
                         (format port "state=$(~s -m -- \"$base/gnollcrawl\")~%"
                                 #$(file-append coreutils-minimal "/bin/realpath"))
                         (display
                          (string-append
                           "case $state in\n"
                           "  /gnu/store|/gnu/store/*) echo 'gnollcrawl: "
                           "refusing state in the immutable store' >&2; "
                           "exit 1 ;;\n"
                           "esac\n") port)
                         (format port "~s -p -- \"$state\"~%"
                                 #$(file-append coreutils-minimal "/bin/mkdir"))
                         (display "export CRAWL_DIR=\"$state\"\n" port)
                         (format port
                                 (string-append "export TERMINFO_DIRS=~s"
                                                "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                                 #$(file-append ncurses "/share/terminfo"))
                         ;; HOME stays unchanged: original ~/.crawlrc and
                         ;; ~/.crawl/init.txt lookups and explicit -rc work.
                         (format port "exec ~s \"$@\"~%" program)))
                     (chmod launcher #o555)))
                 '(("gnollcrawl" . "terminal/source/crawl")
                   ("gnollcrawl-tiles" . "tiles/source/crawl")))
                (install-file "README.md" doc)
                (install-file "crawl-ref/INSTALL.txt" doc)
                (install-file "crawl-ref/licence.txt" doc)
                (install-file "crawl-ref/CREDITS.txt" doc)
                (copy-recursively "tiles/docs" (string-append doc "/docs"))
                (copy-recursively "crawl-ref/docs/license"
                                  (string-append doc "/license"))
                (install-file "crawl-ref/source/rltiles/license.txt"
                              (string-append doc "/license/rltiles"))
                ;; Preserve the complete original copyright/permission text,
                ;; including the BSD domino and MIT json/worley headers.
                (for-each
                 (lambda (file)
                   (install-file (string-append "crawl-ref/source/" file) notices))
                 '("domino.cc" "domino.h" "domino_data.h"
                   "json.cc" "json.h" "worley.cc" "worley.h"
                   "perlin.cc" "perlin.h" "pcg.cc" "platform.h"))
                (copy-file #$%gnollcrawl-apache-license
                           (string-append doc "/license/apache-2.0.txt"))
                (copy-file #$%gnollcrawl-font-notices
                           (string-append doc "/license/fonts.txt"))
                (copy-file #$%gnollcrawl-font-notices
                           (string-append data "/dat/tiles/FONT-LICENSES.txt"))))))))
    (native-inputs (list bison flex perl pkg-config which))
    (inputs (list bash-minimal coreutils-minimal lua-5.1 ncurses sqlite zlib
                  sdl2 sdl2-image sdl2-mixer freetype libpng mesa glu))
    (home-page "https://github.com/Dracunos/gnollcrawl")
    (synopsis "Gnoll-focused Dungeon Crawl Stone Soup variant")
    (description
     "Gnollcrawl is an independently playable Dungeon Crawl Stone Soup variant
with gnoll encounters, no experience gain, and no hunger.  This package builds
its native terminal and SDL2/OpenGL tiles frontends, with SDL2 mixer audio
support and the exact upstream DejaVu fonts.  Both commands share the complete
immutable game data and keep saves, scores, macros, and caches under
@file{$XDG_DATA_HOME/gnollcrawl}, falling back to
@file{$HOME/.local/share/gnollcrawl}.  The original user configuration remains
available.  The separate, mutually exclusive WEBTILES server deployment is not
packaged.")
    ;; The published whole-game grant covers the game bundle; only part of
    ;; the artwork has a separate CC0 grant.  Do not label all tiles CC0.
    ;; Apache PCG is compatible through the GPL's version-3-or-later option.
    (license (list license:gpl2+ license:bsd-2 license:bsd-3 license:cc0
                   license:public-domain license:expat license:asl2.0
                   (license:x11-style "https://dejavu-fonts.github.io/License.html"
                                      "Bitstream Vera and Arev font licenses")))))
