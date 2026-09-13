;;; GNU Guix package for MMapper, the MUME client and graphical mapper.

(define-module (tay packages mmapper)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages tls))

(define-public mmapper
  (package
    (name "mmapper")
    (version "26.06.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/MUME/MMapper")
             (commit "5773a7eac22f23ca71a28b9702ce5e6efa7a3831")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0b5442jaz131w9m0irqfi8sk6qr4bpqyj3i00la7jj413ak37mhh"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list
         "-DWITH_AUDIO=OFF"
         "-DWITH_IMAGES=OFF"
         "-DWITH_MAP=OFF"
         "-DWITH_QTKEYCHAIN=OFF"
         "-DWITH_UPDATER=OFF"
         "-DWITH_WEBSOCKET=OFF"
         ;; Guix's GLM 1.0.1 marks the gtx headers used by MMapper's
         ;; rendering code as experimental; upstream's older bundled GLM
         ;; accepted these headers without this opt-in.
         "-DCMAKE_CXX_FLAGS=-DGLM_ENABLE_EXPERIMENTAL"
         "-DCMAKE_INSTALL_DOCDIR=share/doc/mmapper"
         (string-append "-DCMAKE_INCLUDE_PATH=" #$glm "/include;"
                        #$immer "/include"))
      ;; Run each upstream Qt test exactly once and avoid CTest's host-load
      ;; throttle, which can wait indefinitely on a shared build machine.
      #:parallel-tests? #f
      #:test-repeat-until-pass? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'make-build-date-reproducible
            (lambda _
              ;; git-fetch deliberately omits .git.  Upstream otherwise embeds
              ;; CMake's current date in Version.cpp, making identical source
              ;; builds differ.  The fixed release commit is dated 2026-06-05.
              (substitute* "CMakeLists.txt"
                (("string\\(TIMESTAMP MMAPPER_BUILD_DATE \"%Y-%m-%d\"\\)")
                 "set(MMAPPER_BUILD_DATE \"2026-06-05\")"))))
          (add-after 'make-build-date-reproducible 'honor-guix-tls-trust
            (lambda _
              ;; Qt's OpenSSL backend does not reliably consume
              ;; SSL_CERT_FILE on its own.  Add that conventional bundle to
              ;; this socket's CA set so the package works with Guix-provided
              ;; trust roots and permits a fully local verified-TLS test.
              (substitute* "src/proxy/mumesocket.cpp"
                (("config.setPeerVerifyMode\\(QSslSocket::QueryPeer\\);")
                 (string-append
                  "config.setPeerVerifyMode(QSslSocket::QueryPeer);\n"
                  "        const auto addCaBundle = [&config](const char *name) {\n"
                  "            const auto path = qEnvironmentVariable(name);\n"
                  "            if (!path.isEmpty()) {\n"
                  "                config.addCaCertificates(\n"
                  "                    QSslCertificate::fromPath(path));\n"
                  "            }\n"
                  "        };\n"
                  "        addCaBundle(\"SSL_CERT_FILE\");\n"
                  "        addCaBundle(\"MMAPPER_EXTRA_CA_FILE\");")))))
          (add-before 'check 'use-headless-qt-platform
            (lambda _
              ;; Upstream's QtTest executables instantiate widgets.  The
              ;; Guix build container has no X server, while Qt's offscreen
              ;; platform plugin provides the required headless backend.
              (setenv "QT_QPA_PLATFORM" "offscreen")))
          (add-before 'install 'create-empty-assets-directory
            (lambda _
              ;; The upstream Linux install rule always installs the build
              ;; asset directory, even when all network-fetched asset options
              ;; are disabled.  Keep that directory empty rather than
              ;; enabling downloads during the build.
              (mkdir-p "assets")))
          (add-after 'install 'install-notices
            (lambda _
              ;; These notices are compiled into the About dialog.  Install
              ;; copies too, including the font notice that accompanies the
              ;; embedded DejaVu Sans Mono resource.
              (let ((doc (string-append #$output "/share/doc/mmapper")))
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("../source/COPYING.txt" "../source/AUTHORS.txt"
                            "../source/README.md" "../source/NEWS.md"))
                (for-each (lambda (file) (install-file file doc))
                          (map (lambda (file)
                                 (string-append "../source/src/resources/" file))
                               '("LICENSE.BOOST" "LICENSE.GLM" "LICENSE.LGPL"
                                 "LICENSE.OPENSSL" "LICENSE.QTKEYCHAIN")))
                (copy-file "../source/src/resources/fonts/LICENSE"
                           (string-append doc "/LICENSE.FONTS"))
                (copy-file (string-append #$font-abattis-cantarell
                                          "/share/doc/font-abattis-"
                                          "cantarell-0.303-0.e049149/COPYING")
                           (string-append doc "/LICENSE.CANTARELL")))))
          (add-after 'install-notices 'wrap-tls-trust
            (lambda _
              (wrap-program (string-append #$output "/bin/mmapper")
                `("SSL_CERT_FILE" =
                  (,(string-append #$nss-certs
                                   "/etc/ssl/certs/ca-certificates.crt")))))))))
    (native-inputs
     (list font-abattis-cantarell pkg-config))
    (inputs
     (list bash-minimal glm immer openssl qtbase qtsvg zlib))
    (synopsis "Graphical MUME client and mapper")
    (description
     "MMapper is a graphical client and mapper for the MUME multi-user dungeon.
It provides a local Telnet proxy, map editing and rendering, pathfinding, logs,
and configurable client behavior.  This package builds entirely from the
immutable upstream source with Guix-provided Qt 6, OpenSSL, zlib, GLM, and
Immer dependencies.  It deliberately disables upstream's update checker and
network-downloaded default Arda map, image, and audio assets, encrypted
QtKeychain credential storage and auto-login, the updater, and WebSocket
support.
It therefore starts with an empty map, which remains usable for local editing;
user maps, logs, and settings remain in user-selected directories outside the
store.")
    (home-page "https://github.com/MUME/MMapper")
    (license (list license:gpl2+ license:silofl1.1
                   (license:x11-style "http://dejavu-fonts.org/")))))
