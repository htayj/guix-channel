;;; GNU Guix package for KDE's KMuddy MUD client.

(define-module (tay packages kmuddy)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt))

(define %kmuddy-commit
  "e88c93646c21b31456072f75baf9738eacb9e5b6")

(define %kmuddy-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://invent.kde.org/games/kmuddy.git")
          ;; KMuddy has no current release tag.  This is the reviewed master
          ;; commit that introduced the Qt 6/KF 6 port and version 1.1.
          (commit %kmuddy-commit)))
    (file-name (git-file-name "kmuddy" "1.1"))
    (sha256
     (base32
      "09xi2ndjih05s6ilwdl5rzmnhgny37qc72dv5za4282v2sfcizfs"))))

;; Upstream does not build this bundled library from KMuddy's top-level CMake
;; project, but its optional MXP support locates a system libmxp.  Keep this
;; private implementation in the same source snapshot so no network fetch or
;; unreviewed plugin is introduced at build time.
(define libmxp
  (package
    (name "libmxp")
    (version "0.2.4")
    (source %kmuddy-source)
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ;No test target is defined upstream.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'enter-libmxp-source
            (lambda _
              (chdir "libmxp")))
          ;; CMake 4 no longer accepts the historical 2.3 minimum.  LibMXP
          ;; only uses basic target/install primitives, so 3.16 is adequate.
          (add-after 'enter-libmxp-source 'update-cmake-minimum
            (lambda _
              (substitute* "CMakeLists.txt"
                (("cmake_minimum_required\\(VERSION 2\\.3\\)")
                 "cmake_minimum_required(VERSION 3.16)"))))
          (add-after 'install 'install-license-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((doc (string-append (assoc-ref outputs "out")
                                        "/share/doc/libmxp")))
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("../libmxp/AUTHORS" "../libmxp/COPYING"
                            "../libmxp/COPYING.LIB" "../libmxp/NEWS"
                            "../libmxp/README" "../libmxp/TODO"))))))))
    (synopsis "library for parsing MUD Extension Protocol streams")
    (description
     "LibMXP parses MUD Extension Protocol (MXP) streams.  It is built from
the source bundled with KMuddy so KMuddy's optional MXP handling is available
without a build-time download.")
    (home-page "https://invent.kde.org/games/kmuddy")
    (license license:lgpl2.0+)))

(define-public kmuddy
  (package
    (name "kmuddy")
    (version "1.1")
    (source %kmuddy-source)
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ;No automated test target is provided.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((doc (string-append (assoc-ref outputs "out")
                                        "/share/doc/kmuddy")))
                (mkdir-p doc)
                ;; Retain the application GPL and bundled MXP LGPL notices.
                (install-file "../source/LICENSE" doc)
                (install-file "../source/libmxp/COPYING" doc)
                (install-file "../source/libmxp/COPYING.LIB" doc)))))))
    (native-inputs
     (list extra-cmake-modules pkg-config))
    (inputs
     (list karchive
           kcmutils
           kcodecs
           kcompletion
           kconfig
           kcoreaddons
           kiconthemes
           ki18n
           kio
           knotifications
           kservice
           kstatusnotifieritem
           ktextwidgets
           kwidgetsaddons
           kxmlgui
           libmxp
           qtbase
           qtdeclarative
           qtmultimedia
           zlib))
    (synopsis "KDE MUD client with scripting and protocol extensions")
    (description
     "KMuddy is a graphical MUD client for KDE.  It provides aliases,
triggers, timers, scripting, plugins, logging, automapping, MCCP compression,
MSP sound support, and MXP parsing.  User profiles, logs, maps, scripts, and
plugin settings are created through KDE's normal per-user configuration and
data directories; the package output contains only immutable program files.")
    (home-page "https://invent.kde.org/games/kmuddy")
    ;; Application source headers are GPL-2.0-or-later.  The optional bundled
    ;; libmxp component is LGPL-2.0-or-later and is represented separately by
    ;; the private libmxp input above.
    (license license:gpl2+)))
