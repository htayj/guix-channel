;;; Legcord: source-built application with an explicitly approved binary runtime.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages legcord)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (nongnu packages electron)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages legcord-npm-sources)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages linux)
  #:use-module (tay packages legcord-venmic))
;; The upstream Linux executable, not source-built Electron.  The measured
;; SHA-256 also matches upstream v43.2.0/SHASUMS256.txt.
(define-public legcord-electron
  (package
    (inherit electron-40)
    (name "legcord-electron")
    (version "43.2.0")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append
             "https://github.com/electron/electron/releases/download/v"
             version "/electron-v" version "-linux-x64.zip"))
       (sha256
        (base32 "0s7ckm05wm5cy027vpjsf28f0snakd4ssmlvnq18gimvcznscz7p"))))
    (arguments
     (substitute-keyword-arguments (package-arguments electron-40)
       ((#:install-plan plan)
        #~(append #$plan
                  '(("snapshot_blob.bin" "share/electron/")
                    ("libvk_swiftshader.so" "share/electron/")
                    ("libvulkan.so.1" "share/electron/")
                    ("vk_swiftshader_icd.json" "share/electron/"))))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'install 'retain-vendor-notices
              (lambda _
                (for-each
                 (lambda (file)
                   (install-file file
                                 (string-append #$output
                                                "/share/doc/legcord-electron")))
                 '("LICENSE" "LICENSES.chromium.html"))))))))
    (synopsis "Pinned Electron runtime for Legcord")
    (description
     "This package adapts the upstream Electron 43.2.0 Linux executable using
Nonguix's Chromium binary build system.  It is not built from source.  Electron's
MIT license and the bundled Chromium redistribution notices are retained.
The Chromium sandbox is not disabled by the launcher.")
    (license license:expat)))

;; Legcord requires Node >=26.  This is the exact official host-tool binary,
;; authorized under the user's trusted pinned-component policy, not a claim of
;; source-built Node.  Its hash matches Node's v26.10.0/SHASUMS256.txt.
(define %legcord-node-corresponding-source
  (origin
    (method url-fetch)
    (uri "https://nodejs.org/dist/v26.10.0/node-v26.10.0.tar.xz")
    (sha256
     (base32 "1i90pbq6cgh3430y9rjkqpzxapsxpvh5fynx7fj1aznb6dnm8fkv"))))

(define-public legcord-node
  (package
    (name "legcord-node")
    (version "26.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://nodejs.org/dist/v" version
                           "/node-v" version "-linux-x64.tar.xz"))
       (sha256
        (base32 "08phb4pjknn72rwwagpxbwyg9mivbg0avcxb4aaqn16y97iyjw6a"))))
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:strip-binaries? #f
      #:install-plan #~'(("bin/node" "libexec/legcord-node/")
                         ("LICENSE" "share/doc/legcord-node/"))
      #:phases
      #~(modify-phases %standard-phases
          ;; The private wrapper explicitly inhibits caches and uses only its
          ;; fixed library roots; the vendor executable must remain unchanged.
          (delete 'make-dynamic-linker-cache)
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; Only the host executable and full redistribution notices are
              ;; used; do not extract unused npm and cross-platform headers.
              (invoke "tar" "-xJf" source "--strip-components=1"
                      "node-v26.10.0-linux-x64/bin/node"
                      "node-v26.10.0-linux-x64/LICENSE")))
          (add-after 'install 'install-loader-and-retain-source
            (lambda _
              (let ((wrapper (string-append #$output "/bin/node"))
                    (binary (string-append #$output "/libexec/legcord-node/node")))
                (mkdir-p (dirname wrapper))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/bash\n"
                             "unset LD_LIBRARY_PATH LD_PRELOAD LD_AUDIT\n"
                             "exec ~a --inhibit-cache --library-path "
                             "~a/lib:~a/lib ~a \"$@\"\n")
                            #$bash-minimal
                            #$(file-append glibc "/lib/ld-linux-x86-64.so.2")
                            #$glibc (ungexp gcc "lib") binary)))
                (chmod wrapper #o555)
                (invoke "cmp" "bin/node" binary))
              (copy-file #$%legcord-node-corresponding-source
                         (string-append #$output
                                        "/share/doc/legcord-node/"
                                        "node-v26.10.0-source.tar.xz"))))
          (replace 'validate-runpath
            (lambda _
              ;; An unchanged vendor ET_EXEC is intentionally loaded explicitly.
              ;; Validate its real resolved closure, not an absent embedded RUNPATH.
              (use-modules (ice-9 popen) (ice-9 textual-ports)
                           (ice-9 regex) (srfi srfi-1) (srfi srfi-13))
              (for-each unsetenv '("LD_LIBRARY_PATH" "LD_PRELOAD" "LD_AUDIT"))
              (let* ((binary (string-append #$output "/libexec/legcord-node/node"))
                     (loader #$(file-append glibc "/lib/ld-linux-x86-64.so.2"))
                     (roots (list (string-append #$glibc "/lib/")
                                  (string-append (ungexp gcc "lib") "/lib/")))
                     (pipe (open-pipe* OPEN_READ loader "--inhibit-cache"
                                       "--library-path"
                                       (string-append #$glibc "/lib:"
                                                      (ungexp gcc "lib") "/lib")
                                       "--list" binary))
                     (closure (get-string-all pipe))
                     (status (close-pipe pipe))
                     (paths (map (lambda (match) (match:substring match 1))
                                 (list-matches "=> (/[^[:space:]]+)" closure))))
                (display closure)
                (unless (and (zero? status) (pair? paths)
                             (every (lambda (path)
                                      (any (lambda (root) (string-prefix? root path))
                                           roots))
                                    paths))
                  (error "Node loader closure is unresolved or escapes its fixed inputs"))
                (invoke loader "--verify" binary)
                (invoke "cmp" "bin/node" binary)
                (invoke (string-append #$output "/bin/node") "--version")))))))
    (inputs `(("bash-minimal" ,bash-minimal) ("glibc" ,glibc)
              ("gcc:lib" ,gcc "lib")))
    (home-page "https://nodejs.org/")
    (synopsis "Pinned Node host tool for Legcord")
    (description
     "This package adapts the official Node 26.10.0 Linux executable for the
Legcord build contract.  It is a vendor binary, not compiled from source in this
recipe.  The complete bundled third-party license notices and exact corresponding
source release are retained.  The original executable is unchanged and invoked
through an explicit fixed-input loader wrapper; this is a private host tool,
not a general-purpose Node installation.  npm is not installed: the Legcord
dependency graph is assembled from fixed inputs without a network installation.")
    (license license:expat)))

(define %legcord-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://codeload.github.com/Legcord/Legcord/tar.gz/"
          "c8d91f61296019bb0c45f375535de8c93cf26ee1"))
    (file-name "legcord-1.3.0-c8d91f6.tar.gz")
    (sha256
     (base32 "09gqn9l82zl8xcji38w3p51a65wxga7d0i5l61i0gjzq2fvrhn4d"))))

(define %legcord-npm-helper
  (local-file (search-tay-package-file "files/legcord-npm.py")))

(define %legcord-store-helper
  (local-file (search-tay-package-file "files/legcord-store.py")))

(define %legcord-ancillary-gpl-license
  (origin
    (method url-fetch)
    (uri "https://www.gnu.org/licenses/gpl-3.0.txt")
    (sha256
     (base32 "11k9nggwk1mgsrkdwgdjz65avrradxlpdgrdkc7ryjgn8jbxqwir"))))

(define-public legcord
  (package
    (name "legcord")
    (version "1.3.0")
    (source %legcord-source)
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          ;; Build CLIs are invoked explicitly with Node.  Rewriting every
          ;; npm/retained-source shebang would capture host Node and Python in
          ;; the runtime closure even though those scripts are never executed.
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (add-after 'unpack 'prepare-store-application
            (lambda _
              (setenv "HOME" (string-append (getcwd) "/build-home"))
              (mkdir-p (getenv "HOME"))
              (setenv "ELECTRON_SKIP_BINARY_DOWNLOAD" "1")
              (invoke "python3" #$%legcord-store-helper (getcwd))
              ;; Capture the complete modified application source before build
              ;; artifacts and npm graph exist (OSL source availability).
              (mkdir-p "source-retained")
              (for-each
               (lambda (name)
                 (copy-recursively name (string-append "source-retained/" name)))
               (scandir "."
                        (lambda (name)
                          (not (member name '("." ".." "source-retained"
                                              "build-home"))))))
              (call-with-output-file "npm-inputs.json"
                (lambda (port)
                  (display "{" port)
                  (for-each
                   (lambda (entry index)
                     (unless (zero? index) (display "," port))
                     (format port "~s:~s" (car entry) (cdr entry)))
                   (list #$@(map (lambda (entry)
                                   #~(cons #$(car entry) #$(cdr entry)))
                                 %legcord-npm-sources))
                   (iota #$(length %legcord-npm-sources)))
                  (display "}" port)))
              (invoke "python3" #$%legcord-npm-helper "prepare"
                      (getcwd) "npm-inputs.json")
              ;; Lightning CSS exposes a Rust HashMap with randomized entry
              ;; order.  Sort before Lune serializes it into plugin JS/hashes;
              ;; the class names and CSS semantics remain unchanged.
              (substitute* "node_modules/@uwu/lune/dist/clibundle.cjs"
                (("Object.entries\\(exports \\?\\? \\{\\}\\).map")
                 (string-append
                  "Object.entries(exports ?? {}).sort(([a], [b]) => "
                  "a < b ? -1 : a > b ? 1 : 0).map")))
              ;; Native build-tool payloads are pinned npm artifacts, not a
              ;; claim that these host bindings are built from source.
              (for-each
               (lambda (file)
                 (when (string-contains file "linux-x64-gnu")
                   (invoke "patchelf" "--set-rpath"
                           (string-append (ungexp gcc "lib") "/lib") file)))
               (find-files "node_modules" "\\.node$"))))
          (replace 'build
            (lambda _
              ;; The Rust bundler's Rayon pool otherwise ignores Guix's
              ;; requested serial build execution.
              (setenv "RAYON_NUM_THREADS" "1")
              ;; Individual Lune builds propagate errors; upstream's `ci`
              ;; command catches them and can report success on failed plugins.
              (for-each
               (lambda (manifest)
                 (let* ((dir (dirname manifest))
                        (name (basename dir)))
                   (invoke "node" "node_modules/@uwu/lune/dist/clibundle.cjs"
                           "build" dir "--to"
                           (string-append "ts-out/plugins/" name))))
               (find-files "src/shelter" "^plugin\\.json$"))
              (invoke "node" "node_modules/rolldown/bin/cli.mjs"
                      "-c" "rolldown.config.ts")
              (copy-recursively "node_modules/monaco-editor/min/vs"
                                "ts-out/html/monaco/vs")
              ;; Replace copyVenmic's npm prebuild staging with the genuinely
              ;; source-built C++ addon.  No optional-feature fallback.
              (mkdir-p "dist")
              (copy-file #$(file-append legcord-venmic "/lib/venmic.node")
                         "dist/venmic-x64.node")))
          (replace 'install
            (lambda _
              (let* ((app (string-append #$output "/share/legcord"))
                     (bin (string-append #$output "/bin"))
                     (doc (string-append #$output "/share/doc/legcord")))
                (mkdir-p app)
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each
                 (lambda (name)
                   (copy-recursively name (string-append app "/" name)))
                 '("ts-out" "assets" "dist" "package.json" "license.txt"
                   "GUIX-MODIFICATIONS.txt"))
                (copy-recursively "source-retained" (string-append doc "/source"))
                (install-file "license.txt" doc)
                (install-file "GUIX-MODIFICATIONS.txt" doc)
                (copy-file #$%legcord-ancillary-gpl-license
                           (string-append doc "/source/COPYING.sandboxFix.GPL-3.0"))
                (copy-file #$%legcord-store-helper
                           (string-append doc "/legcord-store.py"))
                (copy-file #$%legcord-npm-helper
                           (string-append doc "/legcord-npm.py"))
                (copy-file #$(local-file
                              (search-tay-package-file "legcord.scm"))
                           (string-append doc "/legcord.scm"))
                (invoke "python3" #$%legcord-npm-helper "runtime" (getcwd) app)
                (invoke "python3" #$%legcord-npm-helper "notices"
                        (getcwd) doc "npm-inputs.json")
                (call-with-output-file (string-append bin "/legcord")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/bash~%"
                             "if [ \"${1-}\" = --guix-update-info ]; then~%"
                             "  printf '%s\\n' "
                             "'This Legcord installation is managed by Guix.' "
                             "'Run guix pull, then guix upgrade legcord.' "
                             "'Settings and runtime mod caches remain "
                             "in your user data directory.'~%"
                             "  exit 0~%fi~%"
                             "unset NODE_OPTIONS ELECTRON_RUN_AS_NODE~%"
                             "export ELECTRON_IS_DEV=0~%"
                             "exec ~s ~s \"$@\"~%")
                            #$bash-minimal
                            #$(file-append legcord-electron "/bin/electron") app)))
                (chmod (string-append bin "/legcord") #o755)
                (wrap-program (string-append bin "/legcord")
                  `("PATH" prefix (,(string-append #$xdg-utils "/bin")
                                     ,(string-append #$procps "/bin"))))
                (let ((icons (string-append #$output "/share/icons/hicolor/256x256/apps"))
                      (applications (string-append #$output "/share/applications")))
                  (mkdir-p icons)
                  (mkdir-p applications)
                  (copy-file "assets/desktop.png" (string-append icons "/legcord.png"))
                  (call-with-output-file (string-append applications "/legcord.desktop")
                    (lambda (port)
                      (format port
                              (string-append
                               "[Desktop Entry]~%Name=Legcord~%Type=Application~%"
                               "Comment=Custom Discord client~%Exec=~a/legcord %U~%"
                               "Icon=legcord~%Terminal=false~%"
                               "Categories=Network;InstantMessaging;~%"
                               "StartupWMClass=legcord~%"
                               "MimeType=x-scheme-handler/discord;~%"
                               "Actions=mute;deafen;leave;opensettings;~%") bin)
                      (for-each
                       (lambda (action name)
                         (format port
                                 (string-append "~%[Desktop Action ~a]~%Name=~a~%"
                                                "Exec=~a/legcord --~a~%")
                                 action name bin action))
                       '("mute" "deafen" "leave" "opensettings")
                       '("Toggle Mute" "Toggle Deafen"
                         "Leave Call" "Open Settings")))))))))))
    (native-inputs
     (append (list legcord-node python python-pyyaml patchelf)
             (map cdr %legcord-npm-sources)))
    (inputs
     `(("bash-minimal" ,bash-minimal)
       ("gcc:lib" ,gcc "lib")
       ("legcord-electron" ,legcord-electron)
       ("legcord-venmic" ,legcord-venmic)
       ("xdg-utils" ,xdg-utils)
       ("procps" ,procps)))
    (home-page "https://legcord.app/")
    (synopsis "Custom Discord desktop client")
    (description
     "Legcord is a custom Discord client.  Its main process, preloads, renderer
and Shelter plugins are compiled offline from the pinned stable source; its
Venmic audio addon is built from C++ source.  The modified application source,
complete OSL license, attribution and fixed npm sources are retained.  Guix
manages application updates; user settings, themes and runtime mod caches remain
writable in the ordinary user data directory.  The upstream mod-selection and
download behavior is preserved.  Chromium sandboxing and context isolation are
not disabled.  Electron, the Node host tool and npm native build-tool bindings
are pinned vendor binaries, so this package is explicitly not fully source-built.")
    (license (list (license:license "OSL-3.0"
                                    "https://opensource.org/license/osl-3-0"
                                    "https://www.gnu.org/licenses/license-list.html#OSL")
                   ;; Retained upstream AppImage build helper, not executed or
                   ;; bundled into the application in this recipe.
                   license:gpl3+))))
