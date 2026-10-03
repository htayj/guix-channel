;;; GNU Guix package for the native oh-my-opencode-slim companion.

(define-module (tay packages oh-my-opencode-slim-companion)
  #:use-module (ice-9 match)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define %companion-version "0.1.3")
(define %companion-build-commit
  "5a4a81a647572141b1be20f72c0948c4601ac4ce")

(define (companion-release-origin)
  ;; These official assets are also pinned in companion-manifest.json at plugin
  ;; commit 6faaed283f33ca5467a7909fa786d1c563fb81ad.  Release workflow run
  ;; 27580998354 built %companion-build-commit on 2026-06-15.  The release tag
  ;; companion-v0.1.3 points to its child 04cdef5cf28c00fb1b932836f4e0b52b515e2383,
  ;; whose only changes are in src/cli/config-io{,.test}.ts, not companion/.
  ;; https://github.com/alvinunreal/oh-my-opencode-slim/actions/runs/27580998354
  (match (or (%current-target-system) (%current-system))
    ((or "x86_64-linux" "aarch64-linux")
     (let* ((x86? (string=? (or (%current-target-system) (%current-system))
                           "x86_64-linux"))
            (target (if x86? "x86_64-unknown-linux-gnu"
                        "aarch64-unknown-linux-gnu"))
            (archive (string-append "oh-my-opencode-slim-companion-v"
                                    %companion-version "-" target ".tar.gz")))
       (origin
         (method url-fetch)
         (uri (string-append
               "https://github.com/alvinunreal/oh-my-opencode-slim/releases/download/"
               "companion-v" %companion-version "/" archive))
         (file-name archive)
         (sha256
          (base32
           (if x86?
               "0r5p0wdiy5halg5wdn4dp8qrbjh476qyzrcijc0ml5c0di5zvx9k"
               "19dcnyk7n8sh43xi65w89nxwbfx3d9mjww7akf6agsp1hg2zyz7d"))))))
    (system (error "unsupported companion binary system" system))))

(define-public oh-my-opencode-slim-companion
  (package
    (name "oh-my-opencode-slim-companion")
    (version %companion-version)
    ;; Preserve the exact release source, MIT notice, Cargo lock and sprite
    ;; sheets.  This installs an upstream prebuilt, not a Guix source rebuild.
    ;; Hash pinning establishes artifact identity, not binary reproducibility
    ;; or an independent audit of its statically linked Rust dependencies.
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/alvinunreal/oh-my-opencode-slim/tar.gz/"
             %companion-build-commit))
       (file-name (string-append name "-" version "-source.tar.gz"))
       (sha256
        (base32 "1nln9svqvbj4p83xqzh6g8qksj2nwdd9fsczwkma93dr8g8mazgw"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:install-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          ;; dlopen dependencies are handled by the wrapper; the foreign ELF
          ;; has a normal Guix RUNPATH for its libc and libgcc DT_NEEDED entries.
          (delete 'make-dynamic-linker-cache)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((bin (string-append #$output "/bin"))
                     (program (string-append bin
                                            "/oh-my-opencode-slim-companion"))
                     (doc (string-append #$output
                                         "/share/doc/oh-my-opencode-slim-companion")))
                (invoke "tar" "-xzf" (assoc-ref inputs "companion-binary"))
                (install-file "oh-my-opencode-slim-companion" bin)
                (chmod program #o755)
                (invoke "patchelf" "--set-interpreter"
                        (search-input-file inputs #$(glibc-dynamic-linker))
                        program)
                (invoke "patchelf" "--set-rpath"
                        (string-append #$glibc "/lib:" #$gcc:lib "/lib")
                        program)
                (install-file "LICENSE" doc)
                (copy-recursively "companion" (string-append doc "/source"))
                (copy-file ".github/workflows/companion-release.yml"
                           (string-append doc "/companion-release.yml")))))
          (add-after 'install 'wrap-graphical-libraries
            (lambda _
              ;; winit/glutin load these libraries by soname rather than link
              ;; them into DT_NEEDED.  Keep Wayland and X11 support available;
              ;; do not force a display backend or change the user's session.
              (wrap-program
                  (string-append #$output "/bin/oh-my-opencode-slim-companion")
                `("LD_LIBRARY_PATH" ":" prefix
                  ,(map (lambda (input) (string-append input "/lib"))
                        (list #$mesa #$libx11 #$libxcursor
                              #$libxrandr #$libxi #$libxinerama #$libxcb
                              #$libxkbcommon #$wayland #$dbus)))
                `("XKB_CONFIG_ROOT" =
                  (,(string-append #$xkeyboard-config "/share/X11/xkb")))))))))
    (native-inputs
     `(("companion-binary" ,(companion-release-origin))
       ("patchelf" ,patchelf)))
    (inputs
     `(("bash-minimal" ,bash-minimal)
       ("glibc" ,glibc)
       ("gcc:lib" ,gcc "lib")
       ("mesa" ,mesa)
       ("libx11" ,libx11)
       ("libxcursor" ,libxcursor)
       ("libxrandr" ,libxrandr)
       ("libxi" ,libxi)
       ("libxinerama" ,libxinerama)
       ("libxcb" ,libxcb)
       ("libxkbcommon" ,libxkbcommon)
       ("xkeyboard-config" ,xkeyboard-config)
       ("wayland" ,wayland)
       ("dbus" ,dbus)))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Native animated desktop companion for OpenCode sessions")
    (description
     "This package provides the eframe/egui desktop companion for
@code{oh-my-opencode-slim}.  It renders embedded agent animations from local
OpenCode session state, with draggable windows and a size picker.  It installs
the official companion-v0.1.3 Linux executable, also selected by the plugin's
pinned companion manifest, patched and wrapped for Guix graphical libraries.
The exact companion release source, MIT notice, Cargo lock, and animation
sheets are retained.  Upstream supplies no separate third-party binary notice
bundle.  The binary is not rebuilt from the later plugin source commit.

A graphical X11 or Wayland session and the
@code{OH_MY_OPENCODE_SLIM_COMPANION_SESSION_ID} environment variable are
required.  The matching session must appear in
@code{$XDG_DATA_HOME/opencode/storage/oh-my-opencode-slim/companion-state.json}.
The companion itself performs no model-provider calls.  Optional Niri window
positioning uses the user's @code{niri} executable and @code{NIRI_SOCKET};
other compositors do not require Niri.")
    (home-page "https://github.com/alvinunreal/oh-my-opencode-slim")
    (license license:expat)))
