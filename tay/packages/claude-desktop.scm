;;; GNU Guix package definition for the proprietary Claude Desktop client.

(define-module (tay packages claude-desktop)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-11)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (nonguix build-system chromium-binary)
  #:use-module ((nonguix licenses) #:prefix license:))

(define %claude-desktop-version "1.30096.1")

(define (claude-desktop-origin system)
  (let-values (((architecture hash)
                (match system
                  ((? target-x86-64?)
                   (values
                    "amd64"
                    "1sfj9byy9mjndvkgbjy7a3a3mx3slzzlyv92pkjs0zmlllh1mr09"))
                  ((? target-aarch64?)
                   (values
                    "arm64"
                    "1j3kz2581rdasvrcdzz46xfm3vgq5902n6zb06yhcy1q0rf9z50n"))
                  (_
                   (values
                    "unsupported"
                    "0000000000000000000000000000000000000000000000000000")))))
    (origin
      (method url-fetch)
      (uri
       (string-append
        "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/"
        "claude-desktop/claude-desktop_" %claude-desktop-version "_"
        architecture ".deb"))
      (file-name
       (string-append "claude-desktop-" %claude-desktop-version "-"
                      architecture ".deb"))
      (sha256 (base32 hash)))))

(define-public claude-desktop
  (package
    (name "claude-desktop")
    (version %claude-desktop-version)
    (source
     (claude-desktop-origin
      (or (%current-target-system) (%current-system))))
    (build-system chromium-binary-build-system)
    (arguments
     (list
      ;; The application and its bundled Electron runtime are proprietary.
      ;; Do not publish a binary substitute from this package definition.
      #:substitutable? #f
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:wrapper-plan
      #~(let ((root "usr/lib/claude-desktop/")
              (architecture #$(if (target-x86-64?) "x64" "arm64")))
          (cons
           ;; Electron loads FFmpeg and its graphics libraries from beside
           ;; the installed application executable.
           (list (string-append root "claude-desktop")
                 '(("out" "/lib/claude-desktop")))
           (map
            (lambda (file) (string-append root file))
            (append
             '("chrome-sandbox"
              "chrome_crashpad_handler"
              "libEGL.so"
              "libffmpeg.so"
              "libGLESv2.so"
              "libvk_swiftshader.so"
              "libvulkan.so.1"
              "resources/chrome-native-host")
             (list
              (string-append
               "resources/app.asar.unpacked/node_modules/@ant/claude-native/"
               "claude-native-binding.node")
              (string-append
               "resources/app.asar.unpacked/node_modules/node-pty/prebuilds/"
               "linux-" architecture "/pty.node"))))))
      #:install-plan
      #~'(("usr/lib/claude-desktop/" "/lib/claude-desktop")
          ("usr/share/applications/" "/share/applications")
          ("usr/share/icons/" "/share/icons")
          ("usr/share/doc/claude-desktop/" "/share/doc/claude-desktop")
          ("usr/share/lintian/" "/share/lintian"))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'patchelf 'validate-native-resources
            (lambda _
              (let* ((root "usr/lib/claude-desktop")
                     (architecture #$(if (target-x86-64?) "x64" "arm64")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? file)
                     (error "required Claude Desktop artifact is missing"
                            file)))
                 (list
                  (string-append root "/resources/app.asar")
                  (string-append root "/resources/icon.png")
                  (string-append
                   root "/resources/app.asar.unpacked/node_modules/@ant/"
                   "claude-native/claude-native-binding.node")
                  (string-append
                   root "/resources/app.asar.unpacked/node_modules/node-pty/"
                   "prebuilds/linux-" architecture "/pty.node")
                  (string-append root "/resources/virtiofsd.LICENSE-APACHE")
                  (string-append root
                                 "/resources/virtiofsd.LICENSE-BSD-3-Clause"))))))
          (add-before 'install-wrapper 'symlink-entrypoint
            (lambda _
              (let ((bin (string-append #$output "/bin")))
                (mkdir-p bin)
                (symlink
                 (string-append #$output
                                "/lib/claude-desktop/claude-desktop")
                 (string-append bin "/claude-desktop")))))
          (add-after 'install-wrapper 'check-installed-launcher
            (lambda _
              (let ((root (string-append #$output "/lib/claude-desktop"))
                    (program
                     (string-append #$output "/bin/claude-desktop")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? file)
                     (error "required Claude Desktop installation is missing"
                            file)))
                 (list program
                       (string-append #$output
                                      "/share/applications/"
                                      "com.anthropic.Claude.desktop")
                       (string-append #$output
                                      "/share/icons/hicolor/256x256/apps/"
                                      "claude-desktop.png")
                       (string-append #$output
                                      "/share/doc/claude-desktop/copyright")
                       (string-append root "/LICENSES.chromium.html")
                       (string-append root
                                      "/resources/virtiofsd.LICENSE-APACHE")
                       (string-append root
                                      "/resources/"
                                      "virtiofsd.LICENSE-BSD-3-Clause")))
                (unless (access? program X_OK)
                  (error "Claude Desktop launcher is not executable"))))))))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Desktop application for Claude")
    (description
     "Claude Desktop is Anthropic's proprietary Electron client for Claude.
It provides chat, local Claude Code sessions for eligible accounts, desktop
extensions, and MCP integration.  This package installs Anthropic's official
architecture-specific Linux release and its standard desktop entry, icons,
Chromium notices, and virtiofsd licenses.  Electron automatically selects
Wayland or X11.  Authentication, extensions, configuration, and application
state remain in per-user directories.  The optional Cowork virtual-machine
mode additionally requires host KVM, QEMU, firmware, virtiofsd integration,
substantial mutable disk space, and is not configured by this package.")
    (home-page
     "https://support.claude.com/en/articles/10065433-install-claude-desktop")
    (license
     (license:undistributable
      "https://www.anthropic.com/legal/consumer-terms"
      "The Debian package identifies Claude Desktop itself as proprietary."))))
