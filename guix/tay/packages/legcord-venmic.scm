;;; Source-built PipeWire audio addon for Legcord.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages legcord-venmic)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (tay packages legcord-npm-sources))

;; These are the versions requested by the actual 7.1.0 npm source archive,
;; including rohrkabel's transitive dependencies.  CPM first loads coco 4.7.2
;; for rohrkabel; ereignis's older coco request reuses that same target.
;; coco's v4.7.2 archive still says VERSION 4.7.1 in its CMakeLists.txt.
(define %venmic-cmake-sources
  '(("coco" "Curve/coco" "4.7.2"
     "0hiwvcjfnfg03p2h555kzkypdllx48a0hj1d48xn15vgf16ini2r")
    ("channel" "Curve/channel" "4.0.0"
     "01rnkgid1yb1s0cnj1fazshsplzfiwrlmyxp6z548bkk4xy6l10n")
    ("ereignis" "Curve/ereignis" "6.3.0"
     "0jf3kx9hmq0c1aq8vqa9z9i1sjvp507pkd0wpfc4bbqhpb6ib6p8")
    ("rohrkabel" "Curve/rohrkabel" "13.1.0"
     "0bkfx16dq2cj2nyhp7p8vjxjzyy7qbwhy9713bjlmcm4876mwrmh")
    ("glaze" "stephenberry/glaze" "7.9.1"
     "1qra9qxd2fsb00x1dbibyqq1z3zxwic61l1m5ikpalvg4y8y7pnn")
    ("spdlog" "gabime/spdlog" "1.17.0"
     "0i57sdy8agmi5xpdh454jwfv2a14bmhb307mnd35hknpqrajk1nq")))

(define (venmic-cmake-origin entry)
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/" (cadr entry)
                        "/tar.gz/refs/tags/v" (caddr entry)))
    (file-name (string-append (car entry) "-" (caddr entry) ".tar.gz"))
    (sha256 (base32 (cadddr entry)))))

(define %venmic-electron-headers
  (origin
    (method url-fetch)
    (uri "https://artifacts.electronjs.org/headers/dist/v43.2.0/node-v43.2.0-headers.tar.gz")
    (file-name "electron-43.2.0-headers.tar.gz")
    (sha256
     (base32 "1dpc6jr1yy9kqz3v9lxmym94a4wmbzpjjyr716zibb10a69xmydy"))))

;; Electron's exact header archive reports Node 24.18.0.  It contains public
;; headers of bundled libraries as well, so preserve the full Node notices.
(define %venmic-node-header-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/nodejs/node/v24.18.0/LICENSE")
    (file-name "node-24.18.0-LICENSE")
    (sha256
     (base32 "19bcas2hljmgkxb7b82a34khl83p61i9i4x24j935x1yhvvsr3hl"))))

(define-public legcord-venmic
  (package
    (name "legcord-venmic")
    (version "7.1.0")
    (source
     (origin
       (inherit (assoc-ref %legcord-npm-sources "@vencord/venmic@7.1.0"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Never compile, install or substitute an upstream native binary.
           (delete-file-recursively "prebuilds")))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:build-type "Release"
      ;; The published archive has no tests directory or CTest target; exercise
      ;; the addon in the pinned Electron runtime as part of app acceptance.
      #:tests? #f
      #:configure-flags
      #~(list "-Dvenmic_addon=ON" "-Dvenmic_server=OFF"
              "-Dvenmic_prefer_remote=OFF"
              "-DBUILD_SHARED_LIBS=OFF"
              "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
              "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
              "-Dcoco_install=OFF" "-Dchannel_install=OFF"
              "-Drohrkabel_install=OFF" "-Drohrkabel_prefer_remote=OFF"
              "-Dglaze_INSTALL=OFF" "-Dglaze_DEVELOPER_MODE=OFF"
              "-DSPDLOG_INSTALL=OFF" "-DSPDLOG_BUILD_EXAMPLE=OFF"
              "-DSPDLOG_BUILD_TESTS=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'supply-offline-sources
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "VENMIC_SOURCE_DIRECTORY" (getcwd))
              (copy-file (assoc-ref inputs "node-header-license")
                         "NODE-HEADER-LICENSE")
              (for-each
               (lambda (name)
                 (let ((directory (string-append "deps/" name)))
                   (mkdir-p directory)
                   (invoke "tar" "xf" (assoc-ref inputs name)
                           "--strip-components=1" "-C" directory)))
               '#$(append (map car %venmic-cmake-sources)
                          '("electron-headers" "node-addon-api")))))
          (add-after 'supply-offline-sources 'replace-network-build-driver
            (lambda _
              (use-modules (ice-9 regex) (ice-9 textual-ports))
              ;; Keep the upstream library targets, sources and link interfaces.
              ;; Only replace CPM's source acquisition and export-only helpers.
              (substitute* "CMakeLists.txt"
                (("include\\(\"cmake/cpm.cmake\"\\)")
                 (string-append
                  "add_subdirectory(deps/coco)\n"
                  "add_subdirectory(deps/channel)\n"
                  "add_subdirectory(deps/ereignis)\n"
                  "add_subdirectory(deps/rohrkabel)\n"
                  "add_subdirectory(deps/glaze)\n"
                  "add_subdirectory(deps/spdlog)")))
              (for-each
               (lambda (file)
                 (let* ((text (call-with-input-file file get-string-all))
                        (without-cpm
                         (regexp-substitute/global
                          #f "CPMFindPackage\\([^)]*\\)" text 'pre "" 'post))
                        (without-exports
                         (regexp-substitute/global
                          #f "packageProject\\([^)]*\\)" without-cpm
                          'pre "" 'post)))
                   (call-with-output-file file
                     (lambda (port) (display without-exports port))))
                 (substitute* file
                   (("include\\(\"cmake/cpm.cmake\"\\)") "")))
               '("CMakeLists.txt" "deps/coco/CMakeLists.txt"
                 "deps/channel/CMakeLists.txt" "deps/ereignis/CMakeLists.txt"
                 "deps/rohrkabel/CMakeLists.txt"))
              ;; The CMake.js driver only supplies headers/library paths here.
              ;; N-API 7 is retained; Linux resolves N-API symbols in Electron.
              (let* ((file "CMakeLists.txt")
                     (text (call-with-input-file file get-string-all)))
                (call-with-output-file file
                  (lambda (port)
                    (display
                     (regexp-substitute/global
                      #f
                      (string-append
                       "if \\(venmic_addon AND NOT CMAKE_JS_VERSION\\)"
                       "[^\n]*\n[^\n]*\nendif\\(\\)")
                      text 'pre "" 'post)
                     port))))
              (substitute* "CMakeLists.txt"
                (("PROJECT_IS_TOP_LEVEL AND NOT CMAKE_JS_VERSION")
                 "PROJECT_IS_TOP_LEVEL AND NOT venmic_addon"))
              (substitute* "addon/CMakeLists.txt"
                (((string-append
                   "target_link_libraries\\(\\$\\{PROJECT_NAME\\}"
                   " PUBLIC \\$\\{CMAKE_JS_LIB\\}\\)")) "")
                (((string-append
                   "target_include_directories\\(\\$\\{PROJECT_NAME\\}"
                   " PUBLIC \\$\\{CMAKE_JS_INC\\}\\)"))
                 (string-append
                  "target_include_directories(${PROJECT_NAME} PRIVATE "
                  "\"${CMAKE_SOURCE_DIR}/deps/electron-headers/include/node\" "
                  "\"${CMAKE_SOURCE_DIR}/deps/node-addon-api\")")))
              ;; All bootstrap CPM files are now unreachable and unnecessary.
              (for-each delete-file (find-files "." "^cpm\\.cmake$"))))
          (replace 'install
            (lambda _
              (let* ((lib (string-append #$output "/lib"))
                     (doc (string-append #$output "/share/doc/legcord-venmic"))
                     (source (getenv "VENMIC_SOURCE_DIRECTORY")))
                (mkdir-p lib)
                (copy-file "addon/venmic-addon.node"
                           (string-append lib "/venmic.node"))
                ;; Modified corresponding source and all original notices are
                ;; colocated with the binary, including statically linked fmt.
                (copy-recursively source (string-append doc "/sources"))
                (install-file (string-append source "/LICENSE") doc)
                (call-with-output-file (string-append doc "/SOURCE-NOTICE.txt")
                  (lambda (port)
                    (display
                     (string-append
                      "venmic 7.1.0: MPL-2.0; corresponding modified source "
                      "is in sources/.\n"
                      "Guix changes replace CPM downloads with pinned local "
                      "sources and CMake.js with pinned headers.\n"
                      "coco 4.7.2, channel 4.0.0, ereignis 6.3.0, "
                      "rohrkabel 13.1.0, glaze 7.9.1, spdlog 1.17.0: MIT.\n"
                      "Their complete sources and notices are in sources/deps/.\n"
                      "spdlog includes fmt 12.1.0; its MIT notice is in "
                      "sources/deps/spdlog/include/spdlog/fmt/bundled/"
                      "format.h.\n"
                      "node-addon-api 8.9.0: MIT; notice in "
                      "sources/deps/node-addon-api/LICENSE.md.\n"
                      "Electron 43.2.0 Node headers are retained in "
                      "sources/deps/electron-headers/; their bundled-library "
                      "licenses are in sources/NODE-HEADER-LICENSE.\n")
                     port)))))))))
    (native-inputs
     (append
      (list (list "gcc" gcc-15)
            (list "pkg-config" pkg-config)
            (list "electron-headers" %venmic-electron-headers)
            (list "node-header-license" %venmic-node-header-license)
            (list "node-addon-api"
                  (assoc-ref %legcord-npm-sources "node-addon-api@8.9.0")))
      (map (lambda (entry)
             (list (car entry) (venmic-cmake-origin entry)))
           %venmic-cmake-sources)))
    (inputs (list pipewire pulseaudio))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/Vencord/venmic")
    (synopsis "PipeWire screenshare audio addon built from source for Legcord")
    (description
     "Venmic supplies Linux screenshare audio routing through PipeWire, with
PulseAudio application discovery.  This package builds the native N-API 7 addon
from source with pinned local C++ dependencies and Electron headers, preserving
the upstream audio API.  It includes modified corresponding source and notices
and does not use the published native prebuilds.")
    ;; The bundled FindPulseAudio.cmake is BSD-3-Clause; all statically linked
    ;; Curve libraries, glaze, spdlog/fmt and node-addon-api are MIT/Expat.
    ;; Retained Node headers include V8 (BSD-3), libuv (MIT/BSD-2), and zlib.
    (license (list license:mpl2.0 license:expat license:bsd-3
                   license:bsd-2 license:zlib))))
