;;; GNU Guix package for Mushkin.

(define-module (tay packages mushkin)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages tls))

(define-public mushkin
  (package
    (name "mushkin")
    (version "0.5.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/justinpopa/mushkin")
             (commit "1199f8e68167eee07123f08983fdf5f775b7c5bd")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0i6h8500l5jsql25lfv5227vp6ylf04xmxapgs1klwlg4rmfmx7s"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list (string-append "-DCMAKE_C_COMPILER=" #$clang-21 "/bin/clang")
              (string-append "-DCMAKE_CXX_COMPILER=" #$clang-21 "/bin/clang++"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'normalize-upstream-line-endings
            (lambda _
              ;; The release commits these files with CRLF line endings.  Keep
              ;; the channel patch readable and apply it after normalization.
              (for-each
               (lambda (file)
                 (substitute* file (("\r") "")))
               '("CMakeLists.txt"
                 "src/main.cpp"
                 "src/utils/app_paths.cpp"
                 "src/utils/app_paths.h"
                 "src/world/script_engine.cpp"
                 "src/world/sound_manager.cpp"
                 "src/world/lua_api/world_info.cpp"
                 "tests/CMakeLists.txt"
                 "tests/test_lua_api_gtest.cpp"
                 "tests/test_telnet_parser_gtest.cpp"))
              (invoke "patch" "-p1" "-i"
                      #$(local-file "patches/mushkin-channel-runtime-security.patch"))))
          ;; CMake's gtest_discover_tests runs GUI test executables while the
          ;; build is still in progress, before the ordinary check phase.
          ;; Ensure that discovery is headless as well as the eventual CTest
          ;; run.
          (add-before 'build 'set-headless-test-environment
            (lambda _
              (setenv "QT_QPA_PLATFORM" "offscreen")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              ;; Upstream's full CTest suite is offline.  It creates Qt state,
              ;; so make that state local to the build directory.
              (when tests?
                (let ((state (string-append (getcwd) "/test-state")))
                  (mkdir-p state)
                  (setenv "HOME" state)
                  (setenv "XDG_CONFIG_HOME" (string-append state "/config"))
                  (setenv "XDG_DATA_HOME" (string-append state "/data"))
                  (setenv "XDG_CACHE_HOME" (string-append state "/cache"))
                  (setenv "QT_QPA_PLATFORM" "offscreen")
                  (invoke "ctest" "--output-on-failure" "--no-tests=error" "-j" "1")))))
          (add-after 'install 'install-runtime-and-notices
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (runtime (string-append out "/libexec/mushkin"))
                     (doc (string-append out "/share/doc/mushkin"))
                     (notices (string-append doc "/third-party-notices")))
                (mkdir-p runtime)
                (rename-file (string-append bin "/mushkin")
                             (string-append runtime "/mushkin"))
                ;; The complete Lua runtime is deliberately adjacent to the
                ;; real executable, not copied into a mutable user directory.
                (copy-recursively "lua" (string-append runtime "/lua"))
                (copy-recursively "lib" (string-append runtime "/lib"))
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("../source/LICENSE" "../source/README.md"
                            "../source/THIRD_PARTY_LICENSES.md"))
                ;; THIRD_PARTY_LICENSES.md is an index, but the recursive
                ;; submodule carries additional notices.  Install every source
                ;; notice rather than silently discarding those attributions.
                (for-each
                 (lambda (file)
                   (let* ((relative (string-drop file (string-length "../source/")))
                          (target (string-append notices "/" (dirname relative))))
                     (mkdir-p target)
                     (install-file file target)))
                 (find-files "../source" "(^|/)(LICENSE|COPYING|NOTICE)(\\..*)?$")))))
          (add-after 'install-runtime-and-notices 'install-desktop-entry
            (lambda _
              (let* ((out #$output)
                     (applications (string-append out "/share/applications"))
                     (icons (string-append out "/share/icons/hicolor/scalable/apps")))
                (mkdir-p applications)
                (mkdir-p icons)
                (install-file "../source/resources/icons/mushkin.svg" icons)
                (call-with-output-file (string-append applications "/mushkin.desktop")
                  (lambda (port)
                    (display "[Desktop Entry]\n\
Type=Application\n\
Name=Mushkin\n\
Comment=Graphical MUD client\n\
Exec=mushkin %f\n\
Icon=mushkin\n\
Categories=Network;Game;\n\
Terminal=false\n\
MimeType=application/x-mushclient-world;\n" port))))))
          (add-after 'install-runtime-and-notices 'install-launcher
            (lambda _
              (let ((wrapper (string-append #$output "/bin/mushkin"))
                    (real (string-append #$output "/libexec/mushkin/mushkin")))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a~%" (which "sh"))
                    (display "if [ -z \"${MUSHKIN_HOME:-}\" ]; then\n" port)
                    (display "  MUSHKIN_HOME=\"${XDG_DATA_HOME:-${HOME:-$PWD}/\
.local/share}/mushkin\"\n" port)
                    (display "fi\nexport MUSHKIN_HOME\n\
mkdir -p \"$MUSHKIN_HOME\"\n" port)
                    (format port "export QT_PLUGIN_PATH=~a:~a:~a\
${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}~%"
                            (string-append #$qtbase "/lib/qt6/plugins")
                            (string-append #$qtmultimedia "/lib/qt6/plugins")
                            (string-append #$qtsvg "/lib/qt6/plugins"))
                    (format port "exec ~a \"$@\"~%" real)))
                (chmod wrapper #o555)))))))
    (native-inputs (list clang-21 googletest pkg-config))
    (inputs
     (list libglvnd libssh luajit openssl pcre qtbase qtmultimedia qtsvg
           sqlite zlib))
    (home-page "https://github.com/justinpopa/mushkin")
    (synopsis "Graphical MUSHclient-compatible MUD client")
    (description
     "Mushkin is a Qt MUD client compatible with much of MUSHclient's Lua API
and world/plugin file formats.  It supports Telnet negotiation, MCCP, MXP,
GMCP, MSP, triggers, aliases, timers, LuaJIT scripting, and remote access over
SSH.  This package builds the application and its recursive YueScript, LuaSocket,
LuaSec, and llthreads2 sources without network access.  The launcher keeps all
mutable worlds, profiles, logs, plugin data, and cached MSP media under
@env{MUSHKIN_HOME}, or the XDG data directory by default; the Guix store holds
only the executable and its read-only Lua runtime.  Source and submodule license
notices are installed under @file{share/doc/mushkin}.  The upstream project does
not provide a command-line or headless client interface, so graphical use still
requires a functioning Qt display and multimedia backend.")
    (license license:expat)))
