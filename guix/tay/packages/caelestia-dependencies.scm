;;; Libraries and toolkit pins required by the Caelestia desktop shell.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages caelestia-dependencies)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system qt)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages window-management))

(define-public libcava
  (package
    (name "libcava")
    (version "1.0.0")
    ;; Guix's cava package installs only the terminal program.  This fork
    ;; is the library origin used by Arch (libcava) and nixpkgs (libcava):
    ;; it installs libcava.so, <cava/cavacore.h>, and libcava.pc.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/LukashonakV/cava")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1gikp9jqsi0h1n0pv2xszbw4fvy41bbb8dcx9ck5gy7cch15mgnj"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:configure-flags
      ;; The default build target is the library only.  Drop the terminal
      ;; and SDL renderers and the console font, which only the program
      ;; uses, and keep the ALSA, PulseAudio, PipeWire, FIFO, and shared
      ;; memory capture backends that Guix's cava also provides.
      #~(list "-Dcava_font=false"
              "-Doutput_ncurses=disabled"
              "-Doutput_sdl=disabled"
              "-Doutput_sdl_glsl=disabled"
              "-Dinput_alsa=enabled"
              "-Dinput_pulse=enabled"
              "-Dinput_pipewire=enabled"
              "-Dinput_portaudio=disabled"
              "-Dinput_sndio=disabled"
              "-Dinput_oss=disabled")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'export-include-root
            (lambda _
              ;; Headers are included as <cava/cavacore.h>, and cava/common.h
              ;; includes "cava/config.h", but libcava.pc only lists
              ;; -I${includedir}/cava and its subdirectories.
              (substitute* "meson.build"
                (("subdirs: \\['cava', ")
                 "subdirs: ['.', 'cava', ")))))))
    (native-inputs (list pkg-config))
    ;; The public headers include no dependency headers, and the shared
    ;; library records these libraries in NEEDED and RUNPATH.
    (inputs (list alsa-lib fftw iniparser pipewire pulseaudio))
    (home-page "https://github.com/LukashonakV/cava")
    (synopsis "Audio spectrum analysis library from CAVA")
    (description
     "libcava builds the C.A.V.A. (Console-based Audio Visualizer for ALSA)
spectrum analysis core as a shared library.  Applications pass audio samples
to @code{cava_execute} and receive smoothed per-bar frequency magnitudes.  The
library also includes CAVA's ALSA, PulseAudio, PipeWire, FIFO, and shared
memory capture backends.  It does not install the @command{cava} program.")
    (license license:expat)))

(define-public m3shapes
  (let ((commit "32ad9ce328bb77ed349b40a3be10ee9ea610b8ab")
        (revision "1"))
    (package
      (name "m3shapes")
      (version (git-version "1.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/soramanew/m3shapes")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0yy60rkbjd1wl0v029i1x0wmn5yc93xy6mzb39q5752z8s0ab5v1"))))
      (build-system qt-build-system)
      (arguments
       (list
        #:qtbase qtbase
        #:tests? #f                     ;no test suite
        #:configure-flags
        #~(list "-DINSTALL_QMLDIR=lib/qt6/qml"
                "-DM3SHAPES_BUILD_EXAMPLES=OFF"
                ;; Guix's Qt does not give QML plugins an $ORIGIN runpath.
                ;; The plugin links the backing library installed beside it.
                (string-append "-DCMAKE_INSTALL_RPATH=" #$output
                               "/lib/qt6/qml/M3Shapes"))))
      (inputs (list qtdeclarative qtshadertools))
      (home-page "https://github.com/soramanew/m3shapes")
      (synopsis "Material 3 Expressive shapes for Qt Quick")
      (description
       "M3Shapes is a Qt 6 QML module providing Material 3 Expressive shapes.
Its @code{MaterialShape} item draws rounded polygons, morphs between them, and
renders them with analytic antialiasing shaders.  QML code imports it as
@code{M3Shapes}.")
      (license license:asl2.0))))

(define-public quickshell-for-caelestia
  ;; The quickshell commit pinned by the Caelestia shell 2.5.0 flake.lock.
  ;; It is 0.3.1 plus ten commits and carries crash fixes for ScriptModel,
  ;; session locks, FileView, and PAM, which Caelestia exercises.
  (let ((commit "2d3b3e9c70ef380dff751b61d334dc88df016c29")
        (revision "1"))
    (package
      (inherit quickshell)
      (name "quickshell-for-caelestia")
      (version (git-version "0.3.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://git.outfoxxed.me/quickshell/quickshell")
               (commit commit)))
         (file-name (git-file-name "quickshell" version))
         (sha256
          (base32 "0wj60ywakp7lw5bzax9gxibk6znqmrwzvnl3g5hmz8qb435ij9g9"))))
      (arguments
       (substitute-keyword-arguments (package-arguments quickshell)
         ((#:configure-flags flags)
         ;; The source checkout has no .git for `git rev-parse HEAD'.
         ;; The remaining flags lower compiler memory use, which the
         ;; Qt-heavy translation units otherwise exceed on small hosts.
         ;; Upstream's NO_PCH option skips precompiled headers.  Keeping
         ;; RelWithDebInfo's -O2 but dropping -g leaves code generation
         ;; unchanged and loses only file/line data in cpptrace crash
         ;; reports.  The GCC garbage-collector parameters make cc1plus
         ;; collect more often; they slow compilation but do not change
         ;; the generated code, so the output stays reproducible.
         #~(cons* #$(string-append "-DGIT_REVISION=" commit)
                  "-DNO_PCH=ON"
                  "-DCMAKE_C_FLAGS_RELWITHDEBINFO=-O2 -DNDEBUG"
                  "-DCMAKE_CXX_FLAGS_RELWITHDEBINFO=-O2 -DNDEBUG"
                  (string-append "-DCMAKE_CXX_FLAGS="
                                 "--param=ggc-min-expand=20 "
                                 "--param=ggc-min-heapsize=32768")
                  #$flags))))
      ;; Like upstream's quickshell.withModules, these inputs place the
      ;; image format plugins and the M3Shapes QML module on the search paths
      ;; set by the qs and quickshell wrappers.
      (inputs
       (modify-inputs (package-inputs quickshell)
         (append m3shapes qtimageformats)))
      (synopsis "QtQuick desktop shell toolkit, as pinned by Caelestia")
      (description
       (string-append
        (package-description quickshell)
        "  This build follows the development commit pinned by the Caelestia
shell and includes the Qt image format plugins and the M3Shapes QML module on
its QML and plugin search paths.")))))
