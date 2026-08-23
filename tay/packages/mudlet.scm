;;; GNU Guix package for Mudlet.

(define-module (tay packages mudlet)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system qt)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages hunspell)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xml))

(define %mudlet-commit
  "eff918604d141a75d19a3977d746195d70347dd3")

;; These are intentionally non-recursive origins.  The source checkout carries
;; submodule gitlinks, but each required submodule is fetched, hashed, and
;; placed explicitly below so a build never performs a network fetch.
(define %mudlet-edbee-lib-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/Mudlet/edbee-lib.git")
          (commit "a3ae51bbb82158366b3d5c4030a54981db688892")))
    (file-name (git-file-name "mudlet-edbee-lib" "a3ae51b"))
    (sha256
     (base32 "1barsyaldz5m28am2pjsiwjnjl3h42nk4sjrhbvnssi708zyp8by"))))

(define %mudlet-lua-code-formatter-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/martin-eden/lua_code_formatter.git")
          (commit "4aa25029eae867840e6c06c7b075f4b690dd2ec2")))
    (file-name (git-file-name "mudlet-lua-code-formatter" "4aa2502"))
    (sha256
     (base32 "1cjibxl2fmsbig56gdsrfvm6ck3j3gjzkh0kr1xl542gjd0mmxlw"))))

(define %mudlet-qt-tags-widget-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/julian-go/qt-tags-widget.git")
          (commit "26f177cbcebe66fdc3e8daed4d0984a7f60f3431")))
    (file-name (git-file-name "mudlet-qt-tags-widget" "26f177c"))
    (sha256
     (base32 "0dh86rf5qq816s12ap0l1r39hrqq6pjr6vh57arrmf6jxw7chgv9"))))

;; Mudlet loads this Lua C module at run time (rather than linking it into the
;; executable).  It is not packaged separately in Guix, so keep the small,
;; exact upstream binding private to this package module.
(define mudlet-lua-yajl
  (package
    (name "mudlet-lua-yajl")
    (version "2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/brimworks/lua-yajl")
             (commit "078e48147e89d34b8224a07129675aa9b5820630")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0hk044kffc07a1135qfi8a10xinil8p6khkd81n9cxrk6n6msj7x"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list (string-append "-DINSTALL_CMOD=" #$output "/share/lua/cmod"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output "/share/doc/lua-yajl")))
                (mkdir-p doc)
                (copy-file "../source/README" (string-append doc "/LICENSE"))
                #t))))))
    (inputs (list lua-5.1 yajl))
    (home-page "https://github.com/brimworks/lua-yajl")
    (synopsis "Lua 5.1 bindings for YAJL")
    (description "This private dependency supplies Mudlet with its required
@code{yajl} Lua module.")
    (license license:expat)))

;; These bindings are installed by Mudlet's release packaging, but are not all
;; available as Lua 5.1 packages in Guix.  Keep their source, ABI, and notices
;; explicit here: Mudlet loads them dynamically as part of its Lua bootstrap.
(define mudlet-lua-utf8
  (package
    (name "mudlet-lua-utf8")
    (version "0.1.7")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/starwing/luautf8")
             (commit "d65ebfa4a00d6e582970ab729013bb2a629e74c9")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0i4ccxnps82q1y4wcggvkpyjbk1f48jy9hdypiw874p26wqfvwsi"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "gcc" "-shared" "-fPIC"
                      (string-append "-I" #$lua-5.1 "/include")
                      "lutf8lib.c" "-o" "lua-utf8.so")))
          (replace 'install
            (lambda _
              (let ((module-dir (string-append #$output "/lib/lua/5.1"))
                    (doc (string-append #$output "/share/doc/lua-utf8")))
                (mkdir-p module-dir)
                (mkdir-p doc)
                (copy-file "lua-utf8.so" (string-append module-dir "/lua-utf8.so"))
                (copy-file "../source/LICENSE" (string-append doc "/LICENSE"))
                #t))))))
    (inputs (list lua-5.1))
    (home-page "https://github.com/starwing/luautf8")
    (synopsis "Unicode-aware UTF-8 module for Lua 5.1")
    (description "This private dependency provides Mudlet's @code{utf8} Lua
module.")
    (license license:expat)))

(define mudlet-lua-zip
  (package
    (name "mudlet-lua-zip")
    (version "0.2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/brimworks/lua-zip")
             (commit "e01fac77e7ebf1feceed8f95a5de96aa2758e06f")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "18pjh7n987ydmgjzjyixyp9yhjb6g4rd3cyk6gshvb6z29i61bx6"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; The upstream CTest assumes its fixture archive is in the build
      ;; directory; exercise the installed module directly below instead.
      #:tests? #f
      #:configure-flags
      #~(list (string-append "-DINSTALL_CMOD=" #$output "/lib/lua/5.1"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output "/share/doc/lua-zip")))
                (mkdir-p doc)
                (copy-file "../source/README.txt" (string-append doc "/LICENSE"))
                #t))))))
    (inputs (list libzip lua-5.1))
    (home-page "https://github.com/brimworks/lua-zip")
    (synopsis "ZIP archive module for Lua 5.1")
    (description "This private dependency provides Mudlet's
@code{brimworks.zip} Lua module.")
    (license license:expat)))

(define mudlet-lrexlib-pcre2
  (package
    (name "mudlet-lrexlib-pcre2")
    (version "2.9.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/rrthomas/lrexlib")
             ;; rel-2-9-4 is an annotated tag; pin its peeled source commit.
             (commit "d2bae6c69b0c1ce5442eab103b9782c9d13ba479")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0x3kmndgsashrd4wsyrxq0kfyk2m8pg3kmvp0z89ryi6f2pz0skz"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "gcc" "-shared" "-fPIC" "-std=gnu99"
                      "-DPCRE2_CODE_UNIT_WIDTH=8"
                      "-DVERSION=\"2.9.4\""
                      (string-append "-I" #$lua-5.1 "/include")
                      (string-append "-I" #$pcre2 "/include")
                      "src/common.c" "src/pcre2/lpcre2.c"
                      "src/pcre2/lpcre2_f.c"
                      (string-append "-L" #$lua-5.1 "/lib")
                      (string-append "-L" #$pcre2 "/lib")
                      "-llua" "-lpcre2-8" "-o" "rex_pcre2.so")))
          (replace 'install
            (lambda _
              (let ((module-dir (string-append #$output "/lib/lua/5.1"))
                    (doc (string-append #$output "/share/doc/lrexlib")))
                (mkdir-p module-dir)
                (mkdir-p doc)
                (copy-file "rex_pcre2.so" (string-append module-dir "/rex_pcre2.so"))
                (copy-file "../source/LICENSE" (string-append doc "/LICENSE"))
                #t))))))
    (inputs (list lua-5.1 pcre2))
    (home-page "https://github.com/rrthomas/lrexlib")
    (synopsis "PCRE2 regular-expression module for Lua 5.1")
    (description "This private dependency provides Mudlet's @code{rex_pcre2}
Lua module.")
    (license license:expat)))

(define mudlet-luasql-sqlite3
  (package
    (name "mudlet-luasql-sqlite3")
    (version "2.8.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/lunarmodules/luasql")
             (commit "550d8244ac5362c8e8bf18e5b0e89000d1d20574")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1srb6q98znjnk5vjaaj70y3fjaj3kwcsgr1dwv4f7k7iady3vkcw"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "gcc" "-shared" "-fPIC" "-std=gnu99"
                      "-DLUASQL_VERSION_NUMBER=\"2.8.1\""
                      (string-append "-I" #$lua-5.1 "/include")
                      (string-append "-I" #$sqlite "/include")
                      "src/luasql.c" "src/ls_sqlite3.c"
                      (string-append "-L" #$lua-5.1 "/lib")
                      (string-append "-L" #$sqlite "/lib")
                      "-llua" "-lsqlite3" "-o" "sqlite3.so")))
          (replace 'install
            (lambda _
              (let ((module-dir (string-append #$output "/lib/lua/5.1/luasql"))
                    (doc (string-append #$output "/share/doc/luasql-sqlite3")))
                (mkdir-p module-dir)
                (mkdir-p doc)
                (copy-file "sqlite3.so" (string-append module-dir "/sqlite3.so"))
                (copy-file "../source/doc/us/license.html"
                           (string-append doc "/LICENSE.html"))
                #t))))))
    (inputs (list lua-5.1 sqlite))
    (home-page "https://lunarmodules.github.io/luasql/")
    (synopsis "SQLite3 database module for Lua 5.1")
    (description "This private dependency provides Mudlet's
@code{luasql.sqlite3} Lua module.")
    (license license:expat)))

(define-public mudlet
  (package
    (name "mudlet")
    (version "4.22.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Mudlet/Mudlet.git")
             (commit %mudlet-commit)
             (recursive? #f)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0r8jxl3rcz8fvas119jrm7g8ay7r74nnmvri4dlrld7y1wd96zna"))))
    (build-system qt-build-system)
    (arguments
     (list
      ;; qt-build-system otherwise selects its Qt5 default for qt-wrap.
      #:qtbase qtbase
      #:build-type "Release"
      #:configure-flags
      #~(list "-DWITH_SENTRY=OFF"
              "-DSENTRY_SEND_DEBUG=OFF"
              "-DUSE_UPDATER=OFF"
              "-DUSE_3DMAPPER=OFF"
              ;; Keep the system font configuration at run time rather than
              ;; embedding Vera, Ubuntu, and Noto Color Emoji font files.
              "-DUSE_FONTS=OFF"
              "-DUSE_SANITIZER="
              "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'restore-required-submodules
            (lambda _
              (copy-recursively #$%mudlet-edbee-lib-source
                                "3rdparty/edbee-lib")
              (copy-recursively #$%mudlet-lua-code-formatter-source
                                "3rdparty/lcf")
              (copy-recursively #$%mudlet-qt-tags-widget-source
                                "3rdparty/qt-tags-widget")
              ;; edbee's CMake uses this vendored Oniguruma only as a fallback.
              ;; Removing it makes the exact Guix 6.9.10 dependency mandatory.
              (delete-file-recursively "3rdparty/edbee-lib/vendor/oniguruma")
              ;; The upstream checkout contains prebuilt Discord libraries for
              ;; other platforms.  Mudlet's Linux build does not link them.
              (for-each delete-file
                        '("3rdparty/discord/rpc/lib/libdiscord-rpc.so"
                          "3rdparty/discord/rpc/lib/libdiscord-rpc.dylib"
                          "3rdparty/discord/rpc/lib/discord-rpc64.dll"
                          "3rdparty/discord/rpc/lib/discord-rpc32.dll"))
              #t))
          (add-after 'restore-required-submodules 'make-version-reproducible
            (lambda _
              ;; The source origin has no .git directory.  Pin the version
              ;; metadata which CMake normally obtains from the developer's
              ;; checkout, rather than embedding a build-local revision.
              (setenv "BUILD_COMMIT" #$%mudlet-commit)
              (setenv "MUDLET_VERSION_BUILD" "")
              (setenv "WITH_UPDATER" "NO")
              (setenv "WITH_FONTS" "NO")
              #t))
          (add-after 'qt-wrap 'wrap-lua-c-modules
            (lambda _
              ;; Extend the Qt wrapper (which establishes plugin, QML, and
              ;; XDG search paths) with every module Mudlet loads at runtime.
              (wrap-program (string-append #$output "/bin/mudlet")
                `("QT_PLUGIN_PATH" ":" prefix
                  (,(string-append #$qtbase "/lib/qt6/plugins")
                   ,(string-append #$qtmultimedia "/lib/qt6/plugins")))
                `("LUA_CPATH" ";" prefix
                  (,(string-append #$lua5.1-filesystem "/lib/lua/5.1/?.so")
                   ,(string-append #$lua5.1-lpeg "/lib/lua/5.1/?.so")
                   ,(string-append #$mudlet-lua-yajl "/share/lua/cmod/?.so")
                   ,(string-append #$mudlet-lua-utf8 "/lib/lua/5.1/?.so")
                   ,(string-append #$mudlet-lua-zip "/lib/lua/5.1/?.so")
                   ,(string-append #$mudlet-lrexlib-pcre2 "/lib/lua/5.1/?.so")
                   ,(string-append #$mudlet-luasql-sqlite3 "/lib/lua/5.1/?.so")))
                `("LUA_PATH" ";" prefix
                  (,(string-append #$lua5.1-lpeg "/share/lua/5.1/?.lua"))))))
          (add-after 'install 'install-license-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/mudlet")))
                (mkdir-p doc)
                (for-each
                 (lambda (notice)
                   (copy-file (car notice) (string-append doc "/" (cdr notice))))
                 '(("../source/COPYING" . "Mudlet-GPL-2.0-or-later.txt")
                   ("../source/3rdparty/communi/LICENSE" . "Communi-BSD-3-Clause.txt")
                   ("../source/3rdparty/edbee-lib/LICENSE" . "edbee-lib-MIT.txt")
                   ("../source/3rdparty/lcf/LICENSE" . "lua-code-formatter-GPL-3.0.txt")
                   ("../source/3rdparty/qt-tags-widget/LICENSE"
                    . "qt-tags-widget-MIT.txt")
                   ("../source/3rdparty/qt-tags-widget/COPYING"
                    . "qt-tags-widget-COPYING")
                   ("../source/3rdparty/qt-tags-widget/COPYING.LESSER"
                    . "qt-tags-widget-COPYING.LESSER")
                   (#$(file-append oniguruma "/share/doc/oniguruma-6.9.10/COPYING")
                    . "Oniguruma-BSD-2-Clause.txt")))
                #t)))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; A private X server runs GUI-sensitive CTest cases without
                ;; exposing a TCP listener or relying on a desktop session.
                ;; Several upstream tests persist passwords and profiles via
                ;; QStandardPaths.  Guix deliberately makes HOME point at the
                ;; unwritable /homeless-shelter, so provide a disposable,
                ;; writable XDG home for the test process.
                (let* ((home (string-append (getcwd) "/test-home"))
                       (config (string-append home "/config"))
                       (data (string-append home "/data"))
                       (cache (string-append home "/cache")))
                  (for-each mkdir-p (list home config data cache))
                  (setenv "HOME" home)
                  (setenv "XDG_CONFIG_HOME" config)
                  (setenv "XDG_DATA_HOME" data)
                  (setenv "XDG_CACHE_HOME" cache)
                  (setenv "LUA_PATH"
                          (string-append #$lua5.1-lpeg "/share/lua/5.1/?.lua"))
                  (setenv "LUA_CPATH"
                          (string-append #$lua5.1-filesystem "/lib/lua/5.1/?.so;"
                                         #$lua5.1-lpeg "/lib/lua/5.1/?.so;"
                                         #$mudlet-lua-yajl "/share/lua/cmod/?.so;"
                                         #$mudlet-lua-utf8 "/lib/lua/5.1/?.so;"
                                         #$mudlet-lua-zip "/lib/lua/5.1/?.so;"
                                         #$mudlet-lrexlib-pcre2 "/lib/lua/5.1/?.so;"
                                         #$mudlet-luasql-sqlite3 "/lib/lua/5.1/?.so"))
                  (let ((pid (primitive-fork)))
                    (if (zero? pid)
                      (begin
                        (execlp "Xvfb" "Xvfb" ":1" "-screen" "0"
                                "1024x768x24" "-nolisten" "tcp")
                        (primitive-exit 127))
                      (dynamic-wind
                        (lambda _
                          (setenv "DISPLAY" ":1")
                          (setenv "QT_QPA_PLATFORM" "xcb")
                          (sleep 1))
                        (lambda _
                          (invoke "ctest" "--output-on-failure"
                                  "--no-tests=error" "-j" "1"))
                        (lambda _
                          (kill pid 15)
                          (waitpid pid))))))))))))
    (native-inputs
     (list git-minimal pkg-config xorg-server))
    (inputs
     (list bash-minimal
           boost
           hunspell
           libzip
           lua-5.1
           lua5.1-filesystem
           lua5.1-lpeg
           mudlet-lrexlib-pcre2
           mudlet-lua-utf8
           mudlet-lua-yajl
           mudlet-lua-zip
           mudlet-luasql-sqlite3
           oniguruma
           pcre2
           pugixml
           qt5compat
           qtbase
           qtdeclarative
           qtkeychain-qt6
           qtmultimedia
           qttools
           zlib))
    (home-page "https://www.mudlet.org/")
    (synopsis "Graphical client for text-based multi-user dungeons")
    (description
     "Mudlet is a graphical client for text-based multi-user dungeons.  It
provides Telnet connections, triggers, aliases, timers, Lua scripting,
mapping, media support, MXP and GMCP protocol support, and profile management.
This package uses Guix libraries where practical, disables the updater and
Sentry crash reporting, and never downloads submodules during the build.")
    ;; Mudlet is GPL-2.0-or-later.  Its installed Lua code formatter is GPL-3.0,
    ;; while the linked edbee and qt-tags-widget components are MIT and the
    ;; bundled Communi IRC library is BSD-3-Clause.  All corresponding notices
    ;; remain in the source and are installed below with the application notice.
    (license (list license:gpl2+ license:gpl3 license:expat license:bsd-2
                   license:bsd-3))))
