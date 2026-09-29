;;; GNU Guix package for the Halloy IRC client's upstream Linux release.

(define-module (tay packages halloy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (nonguix build-system binary)
  #:use-module (gnu packages base)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

;; Halloy pins a git fork of iced plus a large Cargo graph; building it from
;; source would require vendoring every crate.  Upstream's GitHub Actions
;; release tarball is used instead.  Its SHA-256 matches the digest GitHub
;; records for the 2026.8 release asset.
(define-public halloy
  (package
    (name "halloy")
    (version "2026.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/squidowl/halloy/releases/download/"
                           version "/halloy-" version "-x86_64-linux.tar.gz"))
       (sha256
        (base32 "0mw0jlh1wjkv9fwh4gllblb6nf24qigih4i8h7g402rdrgf123vg"))))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      ;; DT_NEEDED covers ALSA, XCB, libgcc_s and glibc.  winit, glutin and
      ;; xkbcommon-dl dlopen the X11, Wayland, EGL and xkbcommon libraries by
      ;; soname, so their directories must also be on the RUNPATH to keep them
      ;; in the closure and resolvable without LD_LIBRARY_PATH.
      #:patchelf-plan
      #~'(("bin/halloy"
           ("alsa-lib" "gcc:lib" "glibc" "libx11" "libxcb" "libxcursor"
            "libxi" "libxkbcommon" "mesa" "wayland")))
      #:install-plan
      #~'(("bin/halloy" "bin/")
          ("share/applications" "share/")
          ("share/icons" "share/")
          ("share/metainfo" "share/"))
      #:phases
      #~(modify-phases %standard-phases
          ;; The tarball has top-level bin/ and share/ directories; the GNU
          ;; unpack phase would otherwise change into bin/.
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (mkdir "source")
              (chdir "source")
              (invoke "tar" "xf" source)))
          (add-after 'install 'use-absolute-desktop-exec
            (lambda _
              (substitute* (string-append
                            #$output
                            "/share/applications/org.squidowl.halloy.desktop")
                (("^Exec=halloy ")
                 (string-append "Exec=" #$output "/bin/halloy ")))))
          (add-after 'use-absolute-desktop-exec 'check-installed-binary
            (lambda _
              ;; --version returns before any window or network setup.
              (invoke (string-append #$output "/bin/halloy") "--version"))))))
    ;; Explicit labels: the patchelf plan refers to inputs by label, and
    ;; libgcc_s lives in gcc's "lib" output.
    (inputs
     `(("alsa-lib" ,alsa-lib)
       ("gcc:lib" ,gcc "lib")
       ("glibc" ,glibc)
       ("libx11" ,libx11)
       ("libxcb" ,libxcb)
       ("libxcursor" ,libxcursor)
       ("libxi" ,libxi)
       ("libxkbcommon" ,libxkbcommon)
       ("mesa" ,mesa)
       ("wayland" ,wayland)))
    (supported-systems '("x86_64-linux"))
    (synopsis "Graphical IRC client")
    (description
     "Halloy is a graphical IRC client written in Rust with the iced toolkit.
It supports multiple servers, split panes, IRCv3 capabilities, SASL, bouncer
connections and remappable keyboard shortcuts.  This package installs the
upstream x86_64 Linux release binary with its desktop entry and icons.")
    (home-page "https://halloy.chat")
    (license license:gpl3+)))
