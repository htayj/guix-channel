;;; Free ASCII KeeperRL; the commercial tiles, audio and SDK are not included.
(define-module (tay packages keeperrl)
  #:use-module (tay packages auxiliary)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages xiph)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

(define-public keeperrl
  (package
    (name "keeperrl")
    (version "1.3.0-1.95d2be4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/miki151/keeperrl/tar.gz/"
             "95d2be4e97db2243210a71918e36a533ad94dcd1"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1nr9hrgdilv0yqixlq0pcrjhijyq9d0cipbmsjz64sag3p6hz9s0"))
       (patches
        (list (search-tay-package-file "patches/keeperrl-no-steam.patch")
              (search-tay-package-file "patches/keeperrl-equipment-value.patch")
              (search-tay-package-file "patches/keeperrl-obsolete-balance-test.patch")))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Do not retain even independently licensed contrib fonts: use
           ;; packaged fonts instead.  The proprietary data tree and SDK are
           ;; absent at this revision; keep that boundary explicit.
           (for-each
            (lambda (path)
              (when (file-exists? path) (delete-file-recursively path)))
            '("data" "data_contrib" "extern/steamworks"))
           ;; Modern libstdc++ already provides std::quoted.  Remove this old
           ;; vendored copy, including its GCC runtime exception obligations.
           (substitute* '("layout_renderer.cpp" "main_loop.cpp"
                          "pretty_archive.h" "text_serialization.h")
             (("#include \"extern/iomanip.h\"") "#include <iomanip>"))
           (delete-file "extern/iomanip.h")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags
      #~(list "GCC=g++" "RELEASE=true" "OPT=true" "NO_STEAMWORKS=true"
              "NO_RPATH=true" "OBJDIR=obj-opt"
              "EXTRA_CFLAGS=-DKEEPERRL_RUN_TESTS"
              (string-append "DATA_DIR=" #$output "/share/keeperrl"))
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 textual-ports)
                  (ice-9 popen))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "Makefile"
                (("-I/usr/include/SDL2 -Iextern/steamworks/public")
                 (string-append "$(EXTRA_CFLAGS) -I"
                                (assoc-ref inputs "sdl2") "/include/SDL2"))
                (("-L/usr/local/lib -L/usr/lib/x86_64-linux-gnu") ""))
              ;; These translation units instantiate Translations and need
              ;; its complete type when compiled without Clang's PCH.
              (substitute* '("main.cpp" "main_loop.cpp")
                (("#include \"main_loop.h\"")
                 "#include \"main_loop.h\"\n#include \"translations.h\""))
              (substitute* "renderer.cpp"
                (("auto textFont = fontPath.file\\(\"Lato-Bol.ttf\"\\);")
                 (string-append "auto textFont = FilePath::fromFullPath(\""
                                (search-input-file inputs
                                 "/share/fonts/truetype/DejaVuSans-Bold.ttf")
                                "\");"))
                (("auto symbolFont = fontPath.file\\(\"Symbola.ttf\"\\);")
                 (string-append "auto symbolFont = FilePath::fromFullPath(\""
                                (search-input-file inputs
                                 "/share/fonts/truetype/DejaVuSans.ttf")
                                "\");")))
              ;; Release archives lack .git; do not query the clock or Git.
              (call-with-output-file "gen_version.sh"
                (lambda (port)
                  (display
                   (string-append
                    "#!/bin/sh\ncat > version.h <<'EOF'\n"
                    "#define BUILD_VERSION \"95d2be4\"\n"
                    "#define BUILD_DATE \"2025-10-27\"\nEOF\n")
                   port)))
              (chmod "gen_version.sh" #o755)
              ;; gen_version and keeper are sibling Make prerequisites, so
              ;; prepare the header before parallel compilation can include it.
              (invoke "sh" "./gen_version.sh")
              (substitute* "appconfig.txt"
                (("\"steamworks\"[[:space:]]+\"1\"")
                 "\"steamworks\"     \"0\""))
              ;; Local-first: online dungeon exchange remains an opt-in;
              ;; telemetry starts disabled.  Crash interception is disabled
              ;; by the launcher, and unsolicited messages by the patch.
              (substitute* "options.cpp"
                (("[{]OptionId::ONLINE, 1[}]") "{OptionId::ONLINE, 0}")
                (("[{]OptionId::GAME_EVENTS, 1[}]")
                 "{OptionId::GAME_EVENTS, 0}"))
              (mkdir-p "obj-opt/extern")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Upstream --run_tests is normally a release no-op.  The
                ;; KEEPERRL_RUN_TESTS guard compiles the actual upstream suite.
                (let* ((pipe (open-pipe* OPEN_READ "bash" "-c"
                                         (string-append
                                          "exec ./keeper --run_tests "
                                          "--no_crash_reports --stderr 2>&1")))
                       (text (get-string-all pipe))
                       (status (close-pipe pipe)))
                  (display text)
                  (unless (and (zero? status)
                               (string-contains text "-----===== OK =====-----"))
                    (error "KeeperRL upstream test suite did not pass"))))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/keeperrl"))
                     (data (string-append out "/share/keeperrl"))
                     (doc (string-append out "/share/doc/keeperrl"))
                     (notices (string-append doc "/notices")))
                (mkdir-p bin)
                (install-file "keeper" libexec)
                (copy-recursively "data_free" (string-append data "/data_free"))
                (install-file "appconfig.txt" data)
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING.txt" "COPYING-MEDIA.txt" "LICENSE"
                            "LICENSE_THEORAPLAY.txt" "README.md"))
                ;; Preserve verbatim attribution-bearing source headers, not
                ;; abbreviated license labels.  These are documentation only.
                (copy-recursively "extern" (string-append notices "/extern"))
                (for-each (lambda (file) (install-file file notices))
                          '("fontstash.h" "fontstash.cpp" "stb_truetype.h"
                            "stb_truetype.cpp" "gzstream.h" "gzstream.cpp"
                            "unzip.cpp" "unzip.h" "ioapi.cpp" "ioapi.h"
                            "miniunz.cpp" "miniunz.h" "theoraplay.cpp"
                            "theoraplay.h" "theoraplay_cvtrgb.h" "video.cpp"))
                (install-file
                 #$(local-file
                    (search-tay-package-file "keeperrl-notices.txt")) doc)
                (install-file
                 #$(local-file
                    (search-tay-package-file "keeperrl-LGPL-2.1.txt")) doc)
                (call-with-output-file (string-append bin "/keeper")
                  (lambda (port)
                    (format port "#!~a/bin/bash\nset -eu\n" #$bash-minimal)
                    (display
                     (string-append
                      "if test -n \"${XDG_DATA_HOME:-}\"; then\n"
                      "  state=$XDG_DATA_HOME/KeeperRL\nelse\n"
                      "  state=${HOME:?HOME or XDG_DATA_HOME must be set}"
                      "/.local/share/KeeperRL\nfi\n") port)
                    ;; The upstream suite reads data_free/game_config relative
                    ;; to its cwd and returns before creating gameplay state.
                    (format port
                            (string-append
                             "for arg do\n"
                             "  if test \"$arg\" = --run_tests; then\n"
                             "    cd -- ~a\n    exec ~a/keeper \"$@\"\n"
                             "  fi\ndone\n")
                            data libexec)
                    ;; Reserve native data/state options so no caller can
                    ;; accidentally select the immutable tree for saves.
                    (display
                     (string-append
                      "for arg do\n  case $arg in\n"
                      "    --data_dir|--data_dir=*|--user_dir|--user_dir=*)\n"
                      "      echo 'keeper: data and state directories are "
                      "managed by the launcher' >&2; exit 64;;\n"
                      "  esac\ndone\n") port)
                    (format port
                            (string-append
                             "~a/bin/mkdir -p -- \"$state\"\n"
                             "cd -- \"$state\"\nexec ~a/keeper --free_mode "
                             "--no_crash_reports --data_dir ~a "
                             "--user_dir \"$state\" \"$@\"\n")
                            #$coreutils-minimal
                            libexec data)))
                (chmod (string-append bin "/keeper") #o555)))))))
    (native-inputs (list pkg-config))
    (inputs
     (list bash-minimal coreutils-minimal font-dejavu
           sdl2 sdl2-image openal libvorbis libtheora libogg curl openssl zlib mesa))
    (home-page "https://keeperrl.com/")
    (synopsis "Dungeon management roguelike in free ASCII mode")
    (description
     "KeeperRL combines dungeon management and turn-based exploration.  This
build uses the free ASCII game data and DejaVu fonts, without the commercial
artwork, music or Steam SDK.  Saves and settings live in the user's XDG data
home.  Online features and game-event reporting start disabled, unsolicited
personal-message downloads are removed, and crash reports are disabled by the
launcher.  Online dungeon exchange can be enabled explicitly in the settings.")
    (license
     (list license:gpl2+ license:cc-by-sa2.0 license:bsd-3 license:expat
           license:boost1.0 license:zlib license:lgpl2.1+ license:cc0
           license:public-domain))))
