;;; Caelestia shell: Quickshell desktop shell, QML plugin, and its fonts.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages caelestia-shell)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system font)
  #:use-module (guix build-system qt)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages hardware)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages window-management)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages caelestia-cli)
  #:use-module (tay packages caelestia-dependencies))

(define-public font-material-symbols-rounded
  (let ((commit "bd8cb85bd4bad964fe6918f79665bb40c3a8efef"))
    (package
      (name "font-material-symbols-rounded")
      (version "2.972")
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://raw.githubusercontent.com/google/material-design-icons/"
               commit "/variablefont/"
               "MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"))
         (file-name "MaterialSymbolsRounded.ttf")
         (sha256
          (base32 "11kdrjjy7jgr4z82p12ss9vw4yjn48jwa493kv668pj96xijn662"))))
      (build-system font-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'add-license
              (lambda _
                (copy-file
                 #$(origin
                     (method url-fetch)
                     (uri (string-append
                           "https://raw.githubusercontent.com/google/"
                           "material-design-icons/" commit "/LICENSE"))
                     (file-name "material-design-icons-LICENSE")
                     (sha256
                      (base32
                       "1gfqk429ns1aw40spi0bdwbpssmyznnzrakc56paf2aizrzy3laq")))
                 "LICENSE"))))))
      (home-page "https://github.com/google/material-design-icons")
      (synopsis "Material Symbols Rounded variable icon font")
      (description
       "Material Symbols is Google's variable icon font.  This package
provides the Rounded style with fill, grade, optical size, and weight axes.")
      (license license:asl2.0))))

(define-public font-rubik
  (let ((commit "e337a5f69a9bea30e58d05bd40184d79cc099628")
        (base "https://raw.githubusercontent.com/googlefonts/rubik/"))
    (package
      (name "font-rubik")
      (version "2.300")
      (source
       (origin
         (method url-fetch)
         (uri (string-append base commit "/fonts/variable/Rubik%5Bwght%5D.ttf"))
         (file-name "Rubik.ttf")
         (sha256
          (base32 "122f3srqzwdwdl28jba9rrmbml9na06dcgkpbr30xy1ap8vp8fhv"))))
      (build-system font-build-system)
      (arguments
       (list
        #:license-file-regexp "^OFL\\.txt$"
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'add-italic-and-license
              (lambda _
                (copy-file
                 #$(origin
                     (method url-fetch)
                     (uri (string-append
                           base commit
                           "/fonts/variable/Rubik-Italic%5Bwght%5D.ttf"))
                     (file-name "Rubik-Italic.ttf")
                     (sha256
                      (base32
                       "0qlwnp9m3nxdi4zbsgw50sqypxkcwjbnid07fi8qpnjsi80w9ih8")))
                 "Rubik-Italic.ttf")
                (copy-file
                 #$(origin
                     (method url-fetch)
                     (uri (string-append base commit "/OFL.txt"))
                     (file-name "rubik-OFL.txt")
                     (sha256
                      (base32
                       "1ys3x3mf3kz64iiafrhcjpgv7x60nczb8r3qkhzgc7a44mybwb27")))
                 "OFL.txt"))))))
      (home-page "https://github.com/googlefonts/rubik")
      (synopsis "Sans-serif font family with slightly rounded corners")
      (description
       "Rubik is a sans-serif font family with slightly rounded corners,
provided here as upright and italic variable fonts with a weight axis.")
      (license license:silofl1.1))))

(define-public font-nerd-caskaydia-cove
  (package
    (name "font-nerd-caskaydia-cove")
    (version "3.5.1")
    (source
     (origin
       ;; A flat tarball.  url-fetch/tarbomb's extractor has no xz, so let
       ;; the unpack phase extract it into the build directory instead.
       (method url-fetch)
       (uri (string-append "https://github.com/ryanoasis/nerd-fonts/"
                           "releases/download/v" version
                           "/CascadiaCode.tar.xz"))
       (file-name (string-append name "-" version ".tar.xz"))
       (sha256
        (base32 "0sc3m8imzx4ii5vg0m2b9a20njg0bmqi6i9nxsinm17206a8wndf"))))
    (build-system font-build-system)
    (home-page "https://www.nerdfonts.com/")
    (synopsis "Cascadia Code patched with Nerd Fonts glyphs")
    (description
     "CaskaydiaCove is Microsoft's Cascadia Code patched with the Nerd Fonts
icon glyphs.  It provides the @code{CaskaydiaCove NF}, @code{CaskaydiaCove
NFM}, and @code{CaskaydiaCove NFP} families.")
    ;; Cascadia Code is OFL; the Nerd Fonts patcher and glyph sets are MIT.
    (license (list license:silofl1.1 license:expat))))

(define-public caelestia-shell
  (let ((commit "d999d4878ee4cec134168e60d913714566a8cfa6"))
    (package
      (name "caelestia-shell")
      (version "2.5.0")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/caelestia-dots/shell")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1yv4p8bcxy1irdkxx43nsplih61s59qdksb8n4fy9dkzfjhjnmix"))
         ;; Use the Guix login stack for the lock screen and absolute system
         ;; profile paths for the optional fprintd and howdy modules.  Port to
         ;; Qt 6.9: avoid QJsonObject::asKeyValueRange(), include <ranges>,
         ;; replace DoubleSpinBox with a scaled SpinBox, draw per-corner
         ;; Elevation shadows from quadrants, and rename the `char' QML id.
         ;; Add services.weatherEnabled (default true) so that weather and
         ;; IP geolocation requests can be switched off entirely.
         (patches
          (search-patches
           "tay/packages/patches/caelestia-shell-guix-pam.patch"
           "tay/packages/patches/caelestia-shell-qt-6.9-compat.patch"
           "tay/packages/patches/caelestia-shell-weather-toggle.patch"))
         ;; Do not silently accept changed context on an upstream update.
         (patch-flags '("-p1" "--fuzz=0"))))
      (build-system qt-build-system)
      (arguments
       (list
        #:qtbase qtbase
        #:tests? #f                     ;no test suite
        #:generator "Ninja"
        #:configure-flags
        #~(list #$(string-append "-DVERSION=" version)
                #$(string-append "-DGIT_REVISION=" commit)
                "-DDISTRIBUTOR=GNU Guix (tay channel)"
                "-DENABLE_MODULES=extras;plugin;shell"
                "-DINSTALL_LIBDIR=lib/caelestia"
                "-DINSTALL_QMLDIR=lib/qt6/qml"
                "-DINSTALL_QSCONFDIR=share/caelestia-shell")
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'patch-xkb-rules-path
              (lambda* (#:key inputs #:allow-other-keys)
                (substitute* "modules/bar/popouts/kblayout/KbLayoutModel.qml"
                  (("/usr/share/X11/xkb/rules/")
                   (string-append
                    (dirname (search-input-file
                              inputs "share/X11/xkb/rules/base.xml"))
                    "/")))))
            (add-after 'install 'install-launcher
              (lambda* (#:key inputs #:allow-other-keys)
                (let* ((bin (string-append #$output "/bin"))
                       (launcher (string-append bin "/caelestia-shell"))
                       (config (string-append #$output
                                              "/share/caelestia-shell"))
                       (sh (search-input-file inputs "bin/sh"))
                       (tool-dir (lambda (file)
                                   (dirname (search-input-file inputs file)))))
                  ;; The shell's terminal launch helper lives outside bin/,
                  ;; which patch-shebangs does not visit.
                  (substitute* (string-append config
                                              "/assets/wrap_term_launch.sh")
                    (("^#!.*") (string-append "#!" sh "\n")))
                  (mkdir-p bin)
                  ;; Quickshell's fontconfig otherwise looks for the absent
                  ;; /etc/fonts/fonts.conf; keep any FONTCONFIG_FILE the user
                  ;; has set.
                  (call-with-output-file launcher
                    (lambda (port)
                      (format port "#!~a~%~a~%exec ~a -p ~a \"$@\"~%"
                              sh
                              (string-append
                               "export FONTCONFIG_FILE=\"${FONTCONFIG_FILE:-"
                               (search-input-file inputs
                                                  "etc/fonts/fonts.conf")
                               "}\"")
                              (search-input-file inputs "bin/qs")
                              config)))
                  (chmod launcher #o755)
                  (wrap-program launcher
                    #:sh (search-input-file inputs "bin/bash")
                    ;; The shell runs `quickshell --version' and
                    ;; `caelestia --version'; the CLI calls caelestia-shell.
                    `("PATH" prefix
                      (,bin
                       ,(tool-dir "bin/caelestia")
                       ,(tool-dir "bin/qs")))
                    ;; Suffix, so that the user's compositor tools and the
                    ;; system's privileged ping/pkexec take precedence.
                    `("PATH" suffix
                      ,(map tool-dir
                            '("bin/sh" "bin/cat" "bin/fish" "bin/ddcutil"
                              "bin/brightnessctl" "bin/nmcli" "bin/swappy"
                              "bin/wl-copy" "bin/qalc" "bin/hyprctl"
                              "bin/xmllint" "bin/notify-send" "bin/pidof"
                              "sbin/ip" "bin/lspci" "bin/glxinfo")))
                    `("CAELESTIA_LIB_DIR" =
                      (,(string-append #$output "/lib/caelestia")))
                    `("CAELESTIA_XKB_RULES_PATH" =
                      (,(search-input-file inputs
                                           "share/X11/xkb/rules/base.lst")))
                    ;; Fontconfig scans $XDG_DATA_DIRS/fonts.
                    `("XDG_DATA_DIRS" prefix
                      ,(map (lambda (font)
                              (dirname (dirname (dirname
                                                 (search-input-file
                                                  inputs font)))))
                            (map (lambda (file)
                                   (string-append "share/fonts/truetype/" file))
                                 '("Rubik.ttf"
                                   "MaterialSymbolsRounded.ttf"
                                   "CaskaydiaCoveNerdFont-Regular.ttf")))))))))))
      (native-inputs
       (list pkg-config qtshadertools))
      (inputs
       (list aubio
             bash-minimal
             brightnessctl
             caelestia-cli
             coreutils-minimal
             ddcutil
             fftw
             fish
             fontconfig
             font-material-symbols-rounded
             font-nerd-caskaydia-cove
             font-rubik
             gmp
             hyprland
             iproute
             libcava
             libnotify
             libqalculate
             libxml2
             `(,lm-sensors "lib")
             m3shapes
             mesa-utils
             mpfr
             network-manager
             pciutils
             pipewire
             procps
             qtbase
             qtdeclarative
             qtimageformats
             quickshell-for-caelestia
             swappy
             wl-clipboard
             xkeyboard-config))
      (home-page "https://github.com/caelestia-dots/shell")
      (synopsis "Caelestia desktop shell for Hyprland, built on Quickshell")
      (description
       "Caelestia is a Quickshell-based desktop shell for Hyprland with a bar,
sidebar, dashboard, launcher, notifications, lock screen, and on-screen
displays drawn inside a single frame around the screen.  This package
includes the @code{Caelestia} QML plugin, the version helper used by
@command{caelestia}, the shell configuration, and a @command{caelestia-shell}
launcher that runs the pinned Quickshell on that configuration.")
      (license license:gpl3))))
