;;; Natron core host; optional OpenFX plugin repositories are not bundled.
(define-module (tay packages natron)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system cmake)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages auxiliary)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

;; Build only the Qt bindings used by this host, not unrelated WebEngine,
;; multimedia or QtQuick modules.  Source, Shiboken and Qt versions remain
;; exactly those of Guix's Qt-for-Python 6.9-compatible package stack.
(define python-pyside-6-natron
  (package
    (inherit python-pyside-6)
    (name "python-pyside-6-natron")
    (inputs (list qtbase))
    (arguments
     (substitute-keyword-arguments (package-arguments python-pyside-6)
       ((#:configure-flags flags)
        #~(append #$flags
                  '("-DMODULES=Core;Gui;Widgets;Network;Concurrent;OpenGL;OpenGLWidgets")))))))

(define-public natron
  (package
    (name "natron")
    (version "2.6.0-0.20260724")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/NatronGitHub/Natron")
             (commit "3763d805d7d277d10af10025ae41af677682b3e6")
             (recursive? #t)))
       (file-name (git-file-name "natron" version))
       ;; guix hash -x --serializer=nar of the recursively fetched exact tree.
       ;; Gitlinks: google-mock 17945db42c0b42496b2f3c6530307979f2e2a5ce;
       ;; google-test 50d6fc317c843a2e40dbf08c2efd3f068801ae6d;
       ;; OpenFX 2303ff811bee3ffe085287602f684fe5fe5357e0;
       ;; SequenceParsing 3c93fcc488632b0bdfeee3181586809932357598;
       ;; tinydir 64fb1d4376d7580aa1013fdbacddbbeba67bb085;
       ;; google-breakpad 9474c3f7f9939391f281d46c42bfe20cc0f0abd9.
       (sha256
        (base32 "0jmjjpk8lzw574q50iad36igdiy67sd3x426k7y2whiz1r30vg83"))
       (patches
        (list (search-tay-package-file "patches/natron-qt6-portability.patch")
              (search-tay-package-file "patches/natron-regular-expression-qt6.patch")
              (search-tay-package-file "patches/natron-qt6-gui-apis.patch")
              (search-tay-package-file "patches/natron-qt6-signals.patch")
              (search-tay-package-file "patches/natron-python-runtime.patch")))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:build-type "Release"
      #:configure-flags
      #~(list "-DNATRON_QT6=ON"
              "-DNATRON_SYSTEM_LIBS=OFF"
              "-DNATRON_BUILD_TESTS=ON"
              "-DCMAKE_CXX_STANDARD=17"
              (string-append "-DPython3_EXECUTABLE=" #$python "/bin/python3"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-host-environment
            (lambda _
              ;; The committed header records an older development tree;
              ;; report this immutable source, without calling Git at build time.
              (substitute* "Global/GitVersion.h"
                (("#define GIT_BRANCH \"[^\"]*\"") "#define GIT_BRANCH \"RB-2.6\"")
                (("#define GIT_COMMIT \"[^\"]*\"")
                 "#define GIT_COMMIT \"3763d805d7d277d10af10025ae41af677682b3e6\""))
              (setenv "HOME" (string-append (getcwd) "/.test-home"))
              (setenv "NATRON_SOURCE_DIRECTORY" (getcwd))
              (mkdir-p (getenv "HOME"))
              (setenv "QT_QPA_PLATFORM" "offscreen")
              (setenv "PYTHONHOME" #$python)
              (setenv "PYTHONPATH"
                      (string-join
                       (append
                        (find-files (string-append #$python-pyside-6-natron "/lib")
                                    "^site-packages$" #:directories? #t)
                        (find-files (string-append #$python-shiboken-6 "/lib")
                                    "^site-packages$" #:directories? #t))
                       ":"))))
          ;; BaseTest requires SeNoise/ReadOIIO/WriteOIIO, none of which is in
          ;; the parent repository.  Compile the complete Tests target, but
          ;; run the plugin-independent tests without any network fixture.
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "./Tests/Tests"
                        "--gtest_filter=-BaseTest.*:OSGLContext.*:GPUContextPool.*"))))
          (add-after 'install 'install-redistribution-notices
            (lambda _
              (let* ((source (getenv "NATRON_SOURCE_DIRECTORY"))
                     (licenses (string-append #$output "/share/doc/natron/licenses")))
                (copy-recursively (string-append source "/tools/license")
                                  (string-append licenses "/inventory"))
                ;; The Qt wildcard conversion port carries an independent
                ;; GPL-2.0-only alternative.  Retain its source attribution.
                (install-file (string-append source "/Global/QtCompat.h")
                              (string-append licenses "/qt-wildcard-port"))
                (for-each
                 (lambda (file)
                   (let* ((relative (substring file (+ 1 (string-length source))))
                          (target (string-append licenses "/source/" relative)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 (append
                  (find-files source
                              (string-append
                               "^(LICENSE[^/]*|license[^/]*|COPYING[^/]*|"
                               "COPYRIGHT[^/]*|NOTICE[^/]*|Copyright[^/]*|"
                               "copyright[^/]*|copying[^/]*|README\\.[Nn]atron[^/]*)$"))
                  (map (lambda (relative) (string-append source "/" relative))
                       (list
                        "Engine/Noise.h"
                        "libs/libtess/README"
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "lss/linux_syscall_support.h")
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "libdisasm/libdisasm.gyp")
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "mac_headers/architecture/byte_order.h")
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "mac_headers/mach-o/loader.h")
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "mac_headers/mach/i386/vm_param.h")
                        (string-append "libs/google-breakpad/src/third_party/"
                                       "mac_headers/mach/machine.h"))))))))
          (add-after 'install-redistribution-notices 'wrap-host-runtime
            (lambda _
              (let ((python-dirs
                     (append
                      (find-files (string-append #$python-pyside-6-natron "/lib")
                                  "^site-packages$" #:directories? #t)
                      (find-files (string-append #$python-shiboken-6 "/lib")
                                  "^site-packages$" #:directories? #t))))
                (for-each
                 (lambda (program)
                   (wrap-program (string-append #$output "/bin/" program)
                     `("PYTHONHOME" = (,#$python))
                     `("PYTHONPATH" ":" prefix ,python-dirs)
                     `("FONTCONFIG_PATH" ":" prefix
                       (,(string-append #$fontconfig "/etc/fonts")))
                     `("QT_PLUGIN_PATH" ":" prefix
                       (,(string-append #$qtbase "/lib/qt6/plugins")
                        ,(string-append #$qtwayland "/lib/qt6/plugins")))))
                 '("Natron" "NatronRenderer" "natron-python"))))))))
    (native-inputs (list pkg-config extra-cmake-modules))
    (inputs
     (list bash-minimal boost python python-pyside-6-natron python-shiboken-6
           qtbase qtwayland cairo fontconfig expat libx11 wayland))
    (home-page "https://natrongithub.github.io/")
    (synopsis "Node-based image compositing host")
    (description
     "Natron provides a native node-graph compositor and its headless
NatronRenderer, with embedded Python scripting and OpenFX plugin hosting.
This package builds the core host only.  It does not include the separately
maintained openfx-io, openfx-misc or openfx-arena plugin collections, FFmpeg,
OpenImageIO readers/writers, or an OCIO configuration.  Users may explicitly
compose separately packaged plugins with OFX_PLUGIN_PATH and provide OCIO.
The complete bundled-code license inventory is retained with the installed
redistribution notices.")
    (license
     (list license:gpl2+ license:gpl2 license:bsd-3 license:mpl2.0
           license:expat license:sgifreeb2.0
           (license:license
            "Apache-2.0 with modified trademark clause (SeExpr)"
            (string-append
             "https://github.com/NatronGitHub/Natron/blob/"
             "3763d805d7d277d10af10025ae41af677682b3e6/Engine/Noise.h")
            "Disney SeExpr-derived Noise code replaces Apache Section 6.")))))
