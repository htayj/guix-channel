;;; GNU Guix package definition for the OpenCode Desktop application.

(define-module (tay packages opencode-desktop)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-11)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (nonguix build-system chromium-binary)
  #:use-module (gnu packages bash)
  #:use-module ((guix licenses) #:prefix license:))

(define %opencode-desktop-version "1.18.18")

(define %opencode-desktop-release-commit
  "31406ccc51b4bd2a4e1e086b2bcaa5f7f804f26d")

(define %opencode-desktop-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/anomalyco/opencode")
          (commit %opencode-desktop-release-commit)))
    (file-name
     (git-file-name "opencode-desktop" %opencode-desktop-version))
    (sha256
     (base32 "0saflrnjqjmwfxpfnmpj0hr0wnjfwa53sa0a1x9hhapxr2zmqddc"))))

(define (opencode-desktop-release-origin system)
  ;; These SHA-256 values correspond to the SHA-512 digests and sizes in
  ;; upstream's latest-linux{,-arm64}.yml release metadata.
  (let-values (((architecture hash)
                (match system
                  ((? target-x86-64?)
                   (values
                    "amd64"
                    "12nl2bhm4n84hxr2nigw1mpic7jg113lracqy06pznbwkimn8zbv"))
                  ((? target-aarch64?)
                   (values
                    "arm64"
                    "0lz83wgz6xz69zzaqnhjpw4kg8rzanlqj586sgqk6zc1pyjzd8zf"))
                  (_
                   (values
                    "unsupported"
                    "0000000000000000000000000000000000000000000000000000")))))
    (origin
      (method url-fetch)
      (uri
       (string-append
        "https://github.com/anomalyco/opencode/releases/download/v"
        %opencode-desktop-version
        "/opencode-desktop-linux-" architecture ".deb"))
      ;; The binary build system recognizes Debian archives by suffix.
      (file-name
       (string-append "opencode-desktop-" %opencode-desktop-version "-"
                      architecture ".deb"))
      (sha256 (base32 hash)))))

(define-public opencode-desktop
  (package
    (name "opencode-desktop")
    (version %opencode-desktop-version)
    ;; Guix does not currently package Bun, while this release requires Bun,
    ;; Electron 42.3.3, and the monorepo's native Node dependency closure.
    ;; Keep the exact source tag as the package source for provenance and its
    ;; license, but install the independently hashed official application.
    (source %opencode-desktop-source)
    (build-system chromium-binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      ;; The bundle contains native modules for multiple libc ABIs.  Only the
      ;; glibc variants used on Guix are patched and validated below.
      #:validate-runpath? #f
      #:wrapper-plan
      #~(let ((architecture #$(if (target-x86-64?) "x64" "arm64")))
          (map
           (lambda (file) (string-append "opt/OpenCode/" file))
           (append
            '("ai.opencode.desktop"
              "chrome-sandbox"
              "chrome_crashpad_handler"
              "libEGL.so"
              "libffmpeg.so"
              "libGLESv2.so"
              "libvk_swiftshader.so"
              "libvulkan.so.1")
            (list
             (string-append
              "resources/app.asar.unpacked/node_modules/@lydell/"
              "node-pty-linux-" architecture "/prebuilds/linux-"
              architecture "/pty.node")
             (string-append
              "resources/app.asar.unpacked/node_modules/@parcel/"
              "watcher-linux-" architecture "-glibc/watcher.node")
             (string-append
              "resources/app.asar.unpacked/node_modules/@msgpackr-extract/"
              "msgpackr-extract-linux-" architecture
              "/node.abi115.glibc.node")
             (string-append
              "resources/app.asar.unpacked/node_modules/@msgpackr-extract/"
              "msgpackr-extract-linux-" architecture
              "/node.napi.glibc.node")))))
      #:install-plan
      #~'(("opt/" "/share")
          ("usr/share/" "/share"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Feed the separately verified release artifact to Nonguix's
              ;; Debian-aware binary-unpack phase.
              (copy-file
               (assoc-ref inputs "desktop-binary")
               "opencode-desktop.deb")))
          (add-after 'binary-unpack 'disable-auto-updates
            (lambda _
              ;; Preserve every ASAR file offset by making this replacement
              ;; exactly the same length as the original expression.
              (let ((archive "opt/OpenCode/resources/app.asar"))
                (invoke
                 "sed" "-i"
                 (string-append
                  "s/app\\.isPackaged && CHANNEL !== \"dev\"/"
                  "false                              /")
                 archive)
                (invoke "grep" "-aF"
                        "const UPDATER_ENABLED = false                              ;"
                        archive))
              ;; electron-updater also cannot discover or download a
              ;; replacement without this provider configuration.
              (delete-file "opt/OpenCode/resources/app-update.yml")))
          (add-before 'install 'patch-desktop-entries
            (lambda _
              (for-each
               (lambda (desktop-file)
                 (substitute* desktop-file
                   (("^Exec=/opt/OpenCode/ai\\.opencode\\.desktop")
                    (string-append "Exec=" #$output
                                   "/bin/opencode-desktop"))))
               (find-files "usr/share/applications" "\\.desktop$"))))
          (add-after 'install 'install-source-license
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((documentation
                     (string-append #$output
                                    "/share/doc/opencode-desktop")))
                (mkdir-p documentation)
                (copy-file
                 (string-append (assoc-ref inputs "source") "/LICENSE")
                 (string-append documentation "/LICENSE")))))
          (add-after 'install 'install-runtime-icon
            (lambda _
              ;; The Debian release installs hicolor icons but omits the copy
              ;; Electron loads for its window at run time.
              (let ((icons
                     (string-append #$output
                                    "/share/OpenCode/resources/icons")))
                (mkdir-p icons)
                (copy-file
                 (string-append #$output
                                "/share/icons/hicolor/128x128/apps/"
                                "ai.opencode.desktop.png")
                 (string-append icons "/icon.png")))))
          (add-before 'install-wrapper 'symlink-entrypoint
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (entrypoint (string-append bin "/opencode-desktop"))
                     (application
                      (string-append #$output
                                     "/share/OpenCode/ai.opencode.desktop")))
                (mkdir-p bin)
                (symlink application entrypoint)
                ;; Electron loads its bundled FFmpeg and graphics libraries
                ;; from beside the application executable.
                (wrap-program entrypoint
                  `("LD_LIBRARY_PATH" ":" prefix
                    (,(string-append #$output "/share/OpenCode")))))))
          (add-after 'install-wrapper 'check-installed-launcher
            (lambda _
              (let ((root (string-append #$output "/share/OpenCode"))
                    (program
                     (string-append #$output "/bin/opencode-desktop")))
                (when (file-exists?
                       (string-append root "/resources/app-update.yml"))
                  (error "updater metadata remains installed"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? file)
                     (error "required desktop artifact is missing" file)))
                 (list program
                       (string-append #$output
                                      "/share/applications/"
                                      "ai.opencode.desktop.desktop")
                       (string-append #$output
                                      "/share/icons/hicolor/128x128/apps/"
                                      "ai.opencode.desktop.png")
                       (string-append #$output
                                      "/share/metainfo/"
                                      "ai.opencode.desktop.metainfo.xml")
                       (string-append root "/LICENSE.electron.txt")
                       (string-append root "/LICENSES.chromium.html")))
                ;; Keep the build-container check structural; the graphical
                ;; runtime is tested separately under a virtual X server.
                (unless (access? program X_OK)
                  (error "installed launcher is not executable" program))))))))
    (native-inputs
     `(("desktop-binary"
        ,(opencode-desktop-release-origin
          (or (%current-target-system) (%current-system))))))
    (inputs (list bash-minimal))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Graphical desktop client for OpenCode")
    (description
     "OpenCode Desktop is an Electron graphical interface for the OpenCode
coding agent.  It can open local projects and runs the bundled JavaScript
sidecar on the loopback interface for its application backend.  This package
installs upstream's architecture-specific Debian release, patched to use Guix
libraries, and removes the updater provider configuration so application
updates remain managed by Guix.  It preserves the canonical desktop entry,
@code{opencode:} URL handler, icons, AppStream metadata, Electron license, and
Chromium third-party notices.  Provider credentials and other user state stay
in the user's configuration and data directories.")
    (home-page "https://opencode.ai/download")
    (license license:expat)))
