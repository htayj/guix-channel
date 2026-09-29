;;; GNU Guix packages for the Caelestia command-line interface and the
;;; runtime programs it spawns.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages caelestia-cli)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages image)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages node)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

;;; Dart Sass, as published to npm: the dart2js build of the reference Sass
;;; implementation.  Caelestia compiles its Discord theme with the module
;;; system (`@use "colours" as c`), which libsass/sassc cannot parse.

(define (npm-tarball name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/" name "/-/"
                        name "-" version ".tgz"))
    (file-name (string-append "npm-" name "-" version ".tgz"))
    (sha256 (base32 hash))))

;; The runtime closure of sass.js and sass.node.js.  The optional
;; @parcel/watcher native module is omitted; sass loads it lazily, tolerates
;; its absence, and falls back to chokidar for --watch.
(define %dart-sass-node-modules
  (list (list "chokidar"
              (npm-tarball "chokidar" "5.0.0"
                           "1qzmyw8jg7gr3zj0f593phii9p4yqiy58g5b6g3q5r3ysnkpxl25"))
        (list "readdirp"
              (npm-tarball "readdirp" "5.1.1"
                           "19fm2ijz7kd44ifq0v9cbfkrkgka5ma5cjjf316a2pkijy0nhnlk"))
        (list "immutable"
              (npm-tarball "immutable" "5.1.9"
                           "0s1h7xqb5fckgb2fp5p15kbjb4zf90ii7y506clzh1wy40yd70cl"))
        (list "source-map-js"
              (npm-tarball "source-map-js" "1.2.1"
                           "0ls8kncpxm2wxd4da6b1jrx1hyajjlx8rjyq34ra91x4zkwsc9pi"))))

(define-public dart-sass
  (package
    (name "dart-sass")
    (version "1.105.0")
    (source (npm-tarball "sass" version
                         "0vy5i8p11h1fhv09792ikrjwr5m4g6gjvyc1qyvqfdiwdyjzfggk"))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." "lib/node_modules/sass/"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'add-node-modules
            (lambda _
              (for-each
               (lambda (entry)
                 (let ((directory (string-append "node_modules/" (car entry))))
                   (mkdir-p directory)
                   (invoke "tar" "xzf" (cadr entry) "-C" directory
                           "--strip-components=1")))
               (list #$@(map (lambda (entry)
                               #~(list #$(car entry) #$(cadr entry)))
                             %dart-sass-node-modules)))))
          (add-after 'add-node-modules 'patch-node-shebang
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "sass.js"
                (("^#!/usr/bin/env node")
                 (string-append "#!" (search-input-file inputs "bin/node"))))))
          (add-after 'install 'install-command
            (lambda _
              (let ((bin (string-append #$output "/bin")))
                (mkdir-p bin)
                (symlink "../lib/node_modules/sass/sass.js"
                         (string-append bin "/sass")))))
          (add-after 'install-command 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (call-with-output-file "_colours.scss"
                  (lambda (port)
                    (display "$surface: #0a0f0f;\n" port)))
                (call-with-output-file "check.scss"
                  (lambda (port)
                    (display "@use \"sass:color\";
@use \"colours\" as c;
a { color: color.change(c.$surface, $alpha: 0.5); }
" port)))
                (invoke (string-append #$output "/bin/sass")
                        "--no-source-map" "-I" "." "check.scss" "check.css")
                (let ((css (call-with-input-file "check.css"
                             (@ (ice-9 textual-ports) get-string-all))))
                  (unless (string-contains css "rgba(10, 15, 15, 0.5)")
                    (error "unexpected Dart Sass output" css)))))))))
    (inputs (list node-lts))
    (home-page "https://sass-lang.com/dart-sass")
    (synopsis "Reference implementation of the Sass stylesheet language")
    (description
     "Dart Sass is the primary implementation of Sass, compiled to JavaScript
and run with Node.js.  It supports the Sass module system (@code{@@use} and
@code{@@forward}) that libsass-based compilers such as sassc do not.")
    ;; sass and its bundled Dart runtime packages are MIT, BSD-3 and
    ;; Apache-2.0 (see LICENSE); chokidar, readdirp and immutable are MIT;
    ;; source-map-js is BSD-3.
    (license (list license:expat license:bsd-3 license:asl2.0))))

;;; GPU Screen Recorder, invoked by `caelestia record'.

(define-public gpu-screen-recorder
  (package
    (name "gpu-screen-recorder")
    (version "6.1.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://repo.dec05eba.com/gpu-screen-recorder")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0j9p6ivzjm3jmchfs060lfilyk55iaw0wjcccv3frwpn0mzq5dfm"))))
    (build-system meson-build-system)
    (arguments
     (list
      #:configure-flags
      ;; No systemd user unit, no NVIDIA modprobe file, and no setcap
      ;; post-install script, which cannot run in the build environment.
      #~(list "-Dsystemd=false"
              "-Dcapabilities=false"
              "-Dnvidia_suspend_fix=false"
              "-Dffmpeg_static=false")
      #:tests? #f                       ;no test suite
      #:phases
      #~(modify-phases %standard-phases
          ;; These libraries are loaded with dlopen at run time.  Mesa
          ;; provides the EGL, GL (including GLX) and GBM drivers directly;
          ;; libGLX.so.0 is optional and falls back to libGL.  NVIDIA
          ;; libraries (CUDA, NVENC, NvFBC) remain unresolved by design.
          (add-after 'unpack 'patch-dlopen-paths
            (lambda* (#:key inputs #:allow-other-keys)
              (define (library name)
                (search-input-file inputs (string-append "lib/" name)))
              (substitute* "src/egl.c"
                (("dlopen\\(\"(libgbm\\.so\\.1|libEGL\\.so\\.1|libGL\\.so\\.1)\""
                  _ name)
                 (string-append "dlopen(\"" (library name) "\"")))
              (substitute* "src/codec_query/vulkan.c"
                (("dlopen\\(\"libvulkan\\.so\\.1\"")
                 (string-append "dlopen(\"" (library "libvulkan.so.1") "\"")))
              (substitute* '("src/capture/v4l2.c" "src/image_writer.c")
                (("dlopen\\(\"libturbojpeg\\.so\\.0\"")
                 (string-append "dlopen(\""
                                (library "libturbojpeg.so.0") "\"")))))
          (add-after 'install 'check-installed-program
            (lambda _
              (invoke (string-append #$output "/bin/gpu-screen-recorder")
                      "--version"))))))
    (native-inputs (list pkg-config wayland))
    (inputs
     (list dbus
           ffmpeg
           libcap
           libdrm
           libjpeg-turbo
           libva
           libx11
           libxcomposite
           libxdamage
           libxfixes
           libxrandr
           mesa
           pipewire
           pulseaudio
           vulkan-headers
           vulkan-loader
           wayland))
    (home-page "https://git.dec05eba.com/gpu-screen-recorder/about/")
    (synopsis "Hardware-accelerated screen recorder for Wayland and X11")
    (description
     "GPU Screen Recorder captures monitors, windows, regions or portal
streams and encodes them on the GPU through VA-API or Vulkan.  Direct monitor
capture on Wayland uses the bundled @command{gsr-kms-server}, which needs
@code{CAP_SYS_ADMIN}; without that capability it is started through
@command{pkexec}.  NVIDIA encoding requires the proprietary driver libraries,
which are not provided.")
    ;; Bundled NVIDIA API headers are MIT; stb headers are public domain.
    (license (list license:gpl3 license:expat license:public-domain))))

;;; Caelestia CLI.

(define-public caelestia-cli
  (package
    (name "caelestia-cli")
    (version "1.1.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/caelestia-dots/cli")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "00pa5235cf24kxrjk6afhsb6arfffpc0pjiqarcvjaq1936ccngg"))
       ;; Run the Guix shell launcher instead of `qs -c caelestia', find the
       ;; shell's version helper beside that launcher, and accept Python
       ;; 3.12 (no 3.13-only language features or APIs are used).
       (patches
        (search-patches
         "tay/packages/patches/caelestia-cli-guix-integration.patch"))
       (patch-flags '("-p1" "--fuzz=0"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-fish-completion
            (lambda _
              (install-file "completions/caelestia.fish"
                            (string-append
                             #$output "/share/fish/vendor_completions.d"))))
          ;; Commands are spawned by name.  Put the programs this CLI needs
          ;; on its PATH, after the user's, without propagating them into
          ;; profiles.  caelestia-shell is deliberately absent: it depends
          ;; on this package and places itself on PATH in its launcher.
          (add-after 'wrap 'wrap-runtime-path
            (lambda* (#:key inputs #:allow-other-keys)
              (wrap-program (string-append #$output "/bin/caelestia")
                `("PATH" suffix
                  ,(map (lambda (command)
                          (dirname (search-input-file
                                    inputs (string-append "bin/" command))))
                        '("cliphist" "dbus-send" "dconf" "fuzzel" "gdbus"
                          "git" "gpu-screen-recorder" "grim" "killall"
                          "notify-send" "pidof" "pkill" "sass" "slurp"
                          "swappy" "which" "wl-copy" "xdg-open"))))))
          ;; Upstream has no test suite.  Exercise the installed, wrapped
          ;; command and its packaged scheme data, then apply a bundled scheme
          ;; with only Discord theming enabled: that compiles the module-based
          ;; SCSS template with the Sass found on the wrapper's PATH.  Theme
          ;; writers log rather than raise errors, so check the result.
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let ((caelestia (string-append #$output "/bin/caelestia"))
                      (config (string-append (getcwd) "/check-config"))
                      (theme "check-config/Vencord/themes/caelestia.theme.css"))
                  (setenv "HOME" (getcwd))
                  (setenv "XDG_CONFIG_HOME" config)
                  (setenv "XDG_STATE_HOME" (string-append (getcwd) "/check-state"))
                  (mkdir-p (string-append config "/caelestia"))
                  (call-with-output-file (string-append config "/caelestia/cli.json")
                    (lambda (port)
                      (display "{\"theme\": {\"enableTerm\": false,
 \"enableHypr\": false, \"enableDiscord\": true, \"enableSpicetify\": false,
 \"enablePandora\": false, \"enableFuzzel\": false, \"enableBtop\": false,
 \"enableNvtop\": false, \"enableHtop\": false, \"enableGtk\": false,
 \"enableQt\": false, \"enableWarp\": false, \"enableChromium\": false,
 \"enableZed\": false, \"enableCava\": false}}\n" port)))
                  (invoke caelestia "--help")
                  (invoke caelestia "scheme" "list" "-n")
                  (invoke caelestia "scheme" "set"
                          "-n" "caelestia" "-f" "default" "-m" "dark")
                  (unless (and (file-exists? theme)
                               (string-contains
                                (call-with-input-file theme
                                  (@ (ice-9 textual-ports) get-string-all))
                                "--bg-floating"))
                    (error "Discord theme was not compiled" theme)))))))))
    (native-inputs (list python-hatch-vcs python-hatchling))
    (inputs
     (list bash-minimal
           cliphist
           dart-sass
           dbus
           dconf
           fuzzel
           git-minimal
           ;; Runtime input, not native: the wrapper puts gdbus on PATH.
           (list glib "bin")
           gpu-screen-recorder
           grim
           libnotify
           procps
           psmisc
           slurp
           swappy
           which
           wl-clipboard
           xdg-utils))
    (propagated-inputs (list python-materialyoucolor python-pillow))
    (home-page "https://github.com/caelestia-dots/cli")
    (synopsis "Command-line interface for the Caelestia desktop shell")
    (description
     "The @command{caelestia} command controls the Caelestia Quickshell
desktop: it starts and messages the shell, generates Material You colour
schemes from wallpapers and applies them to supported applications, and
drives screenshots, screen recording, clipboard and emoji pickers.  Window
toggles, recording and the resizer talk to Hyprland's IPC socket.  The Arch
Linux @code{install} and @code{update} commands only manage packages when
@command{pacman} is present.")
    (license license:gpl3)))
