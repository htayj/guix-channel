;;; GNU Guix package for the Block Buzz desktop application.

(define-module (tay packages buzz)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages audio)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define %buzz-version "0.5.23")
(define %buzz-commit "b9392d9d78744df365f9276e1ffe8c1baa5ea903")

(define buzz-deb
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/block/buzz/releases/download/desktop-v"
          %buzz-version "/Buzz_" %buzz-version "_amd64.deb"))
    (file-name (string-append "buzz-" %buzz-version "-amd64.deb"))
    (sha256
     (base32 "1klw3h6d073kpy38vzp3ckd976dkla76mj38ymj8i3zq440fbwcl"))))

(define buzz-launcher
  (local-file "buzz-launcher.sh"))

(define-public buzz
  (package
    (name "buzz")
    (version %buzz-version)
    ;; Retain the exact tagged source for provenance, licensing, and auditing.
    ;; Upstream's independently hashed desktop release is installed below; a
    ;; native source build currently requires large pnpm and Cargo dependency
    ;; closures plus a separate sherpa-onnx C++ build.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/block/buzz")
             (commit %buzz-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1g8kmfnxgiqxsj70gg0pw5dbgjgcpj6s37bzfii2ybyvh9fhs3rk"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:install-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; Only the source notices are installed; the desktop payload is
              ;; the independently hashed release input handled below.
              (copy-file (string-append source "/LICENSE") "LICENSE")
              (copy-file (string-append source "/README.md") "README.md")))
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          ;; The launcher already supplies the foreign payload's complete
          ;; library search path.  Generating a Guix ld.so cache would scan
          ;; that large closure again without changing runtime resolution.
          (delete 'make-dynamic-linker-cache)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((deb (assoc-ref inputs "buzz-deb"))
                     (libexec (string-append #$output "/libexec/buzz"))
                     (bin (string-append #$output "/bin"))
                     (share (string-append #$output "/share"))
                     (doc (string-append share "/doc/buzz"))
                     ;; Guix's set-paths phase computes this from the complete
                     ;; transitive input closure.  A foreign ELF needs those
                     ;; propagated GTK/WebKit directories just as a linked
                     ;; Guix-built executable would record them in RUNPATH.
                     (library-path (getenv "LIBRARY_PATH"))
                     (gst-inputs
                      (map (lambda (name) (assoc-ref inputs name))
                           '("gstreamer" "gst-plugins-base" "gst-plugins-good"
                             "gst-plugins-bad" "gst-libav")))
                     (gst-path
                      (string-join
                       (map (lambda (input)
                              (string-append input "/lib/gstreamer-1.0"))
                            gst-inputs)
                       ":"))
                     (data-path
                      (string-append #$output "/share:"
                                     (or (getenv "XDG_DATA_DIRS") "")))
                     (runtime-path
                      (string-join
                       (map (lambda (name)
                              (string-append (assoc-ref inputs name) "/bin"))
                            '("bash-minimal" "coreutils-minimal" "xdg-utils"))
                       ":")))
                (invoke "ar" "x" deb)
                (invoke "tar" "-xzf" "data.tar.gz")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (copy-recursively "usr/bin" libexec)
                (copy-recursively "usr/share" share)
                (copy-file "LICENSE" (string-append doc "/LICENSE"))
                (copy-file "README.md" (string-append doc "/README.md"))
                (for-each
                 (lambda (program)
                   (invoke "patchelf" "--set-interpreter"
                           (search-input-file inputs #$(glibc-dynamic-linker))
                           program))
                 (find-files libexec ".*" #:directories? #f))
                (substitute* (string-append share "/applications/Buzz.desktop")
                  (("Exec=buzz-desktop") "Exec=buzz-desktop"))
                (copy-file #$buzz-launcher (string-append bin "/buzz-desktop"))
                (substitute* (string-append bin "/buzz-desktop")
                  (("@RAW_DESKTOP@") (string-append libexec "/buzz-desktop"))
                  (("@LD_LIBRARY_PATH@") library-path)
                  (("@GST_PLUGIN_PATH@") gst-path)
                  (("@GST_PLUGIN_SCANNER@")
                   (string-append (assoc-ref inputs "gstreamer")
                                  "/libexec/gstreamer-1.0/gst-plugin-scanner"))
                  (("@XDG_DATA_DIRS@") data-path)
                  (("@RUNTIME_PATH@") runtime-path)
                  (("@UNSHARE@")
                   (string-append (assoc-ref inputs "util-linux") "/bin/unshare"))
                  (("@MOUNT@")
                   (string-append (assoc-ref inputs "util-linux") "/bin/mount"))
                  (("@DBUS_RUN_SESSION@")
                   (string-append (assoc-ref inputs "dbus") "/bin/dbus-run-session"))
                  (("@XVFB@")
                   (string-append (assoc-ref inputs "xorg-server") "/bin/Xvfb"))
                  (("@XWININFO@")
                   (string-append (assoc-ref inputs "xwininfo") "/bin/xwininfo"))
                  (("@XDOTOOL@")
                   (string-append (assoc-ref inputs "xdotool") "/bin/xdotool"))
                  (("@IMPORT@")
                   (string-append (assoc-ref inputs "imagemagick") "/bin/import")))
                (chmod (string-append bin "/buzz-desktop") #o555)
                (call-with-output-file (string-append bin "/buzz")
                  (lambda (port)
                    (display
                     (string-append
                      "#!" (assoc-ref inputs "bash-minimal") "/bin/sh\n"
                      "export LD_LIBRARY_PATH='" library-path
                      "'${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\n"
                      "export PATH='" runtime-path "'${PATH:+:$PATH}\n"
                      "exec '" libexec "/buzz' \"$@\"\n")
                     port)))
                (chmod (string-append bin "/buzz") #o555)))))))
    (native-inputs
     (list binutils gzip patchelf))
    (inputs
     `(("buzz-deb" ,buzz-deb)
       ("alsa-lib" ,alsa-lib)
       ("bash-minimal" ,bash-minimal)
       ("coreutils-minimal" ,coreutils-minimal)
       ("dbus" ,dbus)
       ("gcc-toolchain" ,gcc-toolchain)
       ("glibc" ,glibc)
       ("gst-libav" ,gst-libav)
       ("gst-plugins-bad" ,gst-plugins-bad)
       ("gst-plugins-base" ,gst-plugins-base)
       ("gst-plugins-good" ,gst-plugins-good)
       ("gstreamer" ,gstreamer)
       ("gtk+" ,gtk+)
       ("imagemagick" ,imagemagick)
       ("libsecret" ,libsecret)
       ("openssl" ,openssl)
       ("util-linux" ,util-linux)
       ("webkitgtk-for-gtk3" ,webkitgtk-for-gtk3)
       ("xdg-utils" ,xdg-utils)
       ("xdotool" ,xdotool)
       ("xorg-server" ,xorg-server)
       ("xwininfo" ,xwininfo)))
    (supported-systems '("x86_64-linux"))
    (synopsis "Local-first desktop workspace for humans and AI agents")
    (description
     "Buzz is a local-first desktop workspace for teams of humans and AI
agents.  It combines encrypted Nostr-based collaboration, agent terminals,
voice huddles, and optional mesh inference in one Tauri application.  This
package installs upstream's official GNU/Linux desktop release and retains the
matching tagged source and Apache license for provenance.  The installed
@code{buzz-desktop --guix-smoke} path launches the real GUI without network
access or host user state and can capture runtime evidence.")
    (home-page "https://github.com/block/buzz")
    (license license:asl2.0)))
