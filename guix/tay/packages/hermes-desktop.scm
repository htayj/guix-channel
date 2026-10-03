;;; Hermes Desktop: source-built application with explicitly pinned vendor runtime.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hermes-desktop)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (gnu packages xorg)
  #:use-module (nongnu packages electron)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages hermes-agent)
  #:use-module (tay packages hermes-desktop-npm-sources))

;; This is the upstream release executable, NOT a source-built Electron.
;; Its measured SHA-256 agrees with upstream's v40.10.2 SHASUMS256.txt.
(define-public hermes-desktop-electron
  (package
    (inherit electron-40)
    (name "hermes-desktop-electron")
    (version "40.10.2")
    (source
     (origin
       (method url-fetch/zipbomb)
       (uri (string-append
             "https://github.com/electron/electron/releases/download/v"
             version "/electron-v" version "-linux-x64.zip"))
       (sha256
        (base32 "15qyfd44x6rafd7qcax47drdpda5h1dg2dhsqn4w02k000a20ih2"))))
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
                                                "/share/doc/hermes-desktop-electron")))
                 '("LICENSE" "LICENSES.chromium.html"))))))))
    (synopsis "Pinned Electron runtime for Hermes Desktop")
    (description
     "This package adapts the upstream Electron 40.10.2 Linux executable for
Hermes Desktop using Nonguix's Chromium binary build system.  It is not built
from source.  Electron's MIT license and the bundled Chromium third-party
redistribution notices are retained in the output.")
    (license license:expat)))

(define %hermes-electron-headers
  (origin
    (method url-fetch)
    (uri "https://artifacts.electronjs.org/headers/dist/v40.10.2/node-v40.10.2-headers.tar.gz")
    (sha256
     (base32 "0qv561kbm7f482lwmyacf78x9ps8fgjw4hmm7sxwanj857q927fy"))))

(define %hermes-npm-sigstore-license
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/sigstore/sigstore-js/"
          "c1dc7d4778a450787fc72b083f2490ad02b714c6/LICENSE"))
    (sha256
     (base32 "1l6dw4brbcj934n8y0das3wv16wjqrgh8v8yxdbbsh535h6i6jin"))))

;; Keep npm's source distribution unmodified, including its bundled dependency
;; notices.  Hermes rejects npm 11.10 through 11.16 in its engine contract.
(define hermes-desktop-npm
  (package
    (name "hermes-desktop-npm")
    (version "11.17.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://registry.npmjs.org/npm/-/npm-"
                           version ".tgz"))
       (sha256
        (base32 "1fjbrvkszjmq2xc5b7z7kr6rqiy450gh9gpdhkpw6wlybfrvp45j"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (setenv "PATH" (string-append #$tar "/bin:" #$gzip "/bin"))
          (invoke "tar" "xzf" #$source)
          (let ((app (string-append #$output "/share/npm"))
                (bin (string-append #$output "/bin"))
                (doc (string-append #$output "/share/doc/hermes-desktop-npm")))
            (copy-recursively "package" app)
            (mkdir-p doc)
            (copy-file #$%hermes-npm-sigstore-license
                       (string-append doc "/sigstore-verify-Apache-2.0"))
            (call-with-output-file (string-append doc "/supplemental-notices.txt")
              (lambda (port)
                (display
                 (string-append
                  "npm 11.17.0 and its bundled source/metadata are unmodified.\n"
                  "Original license files and copyright headers are retained.\n\n"
                  "@npmcli/agent 4.0.2 declares ISC in package.json. Its pinned\n"
                  "upstream source supplies no standalone copyright/permission\n"
                  "notice. Its original author/declaration metadata is retained;\n"
                  "the following is supplemental standard ISC text, not a\n"
                  "recovered upstream copyright notice or invented holder.\n\n"
                  "Permission to use, copy, modify, and/or distribute this\n"
                  "software for any purpose with or without fee is hereby\n"
                  "granted, provided that the above copyright notice and this\n"
                  "permission notice appear in all copies.\n\n"
                  "THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS\n"
                  "ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL\n"
                  "IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO\n"
                  "EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,\n"
                  "INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER\n"
                  "RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN\n"
                  "ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,\n"
                  "ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE\n"
                  "OF THIS SOFTWARE.\n\n"
                  "spdx-exceptions 2.5.0: The Linux Foundation; contributor\n"
                  "Kyle E. Mitchell (https://kemitchell.com/). CC-BY-3.0:\n"
                  "https://creativecommons.org/licenses/by/3.0/\n"
                  "https://github.com/kemitchell/spdx-exceptions.json\n"
                  "spdx-license-ids 3.0.23: Shinnosuke Watanabe\n"
                  "(https://github.com/shinnn); source\n"
                  "https://github.com/jslicense/spdx-license-ids; CC0-1.0:\n"
                  "https://creativecommons.org/publicdomain/zero/1.0/\n"
                  "@sigstore/verify: original source headers are retained;\n"
                  "sigstore-verify-Apache-2.0 supplies the full project license.\n")
                 port)))
            (mkdir-p bin)
            (for-each
             (lambda (command)
               (let ((launcher (string-append bin "/" command)))
                 (call-with-output-file launcher
                   (lambda (port)
                     (format port "#!~a/bin/bash~%exec ~a/bin/node ~s \"$@\"~%"
                             #$bash-minimal #$node-lts
                             (string-append app "/bin/" command "-cli.js"))))
                 (chmod launcher #o555)))
             '("npm" "npx"))))))
    (native-inputs (list tar gzip))
    (inputs (list bash-minimal node-lts))
    (home-page "https://www.npmjs.com/")
    (synopsis "Pinned npm tool for the Hermes Desktop build")
    (description
     "This package provides the exact npm source distribution required by the
Hermes Desktop engine contract.  Its JavaScript and bundled dependency notices
are retained without rewriting them; store-bound launchers select Guix Node.")
    (license license:artistic2.0)))

(define %hermes-desktop-store-helper
  (local-file (search-tay-package-file "files/hermes-desktop-store.py")))

(define %hermes-desktop-npm-helper
  (local-file (search-tay-package-file "files/hermes-desktop-npm.py")))

(define %hermes-desktop-font-helper
  (local-file (search-tay-package-file "files/hermes-desktop-fonts.py")))

;; Main-process readiness uses a sandboxed Chromium renderer, never Node TLS.
(define %hermes-chromium-ws-probe
  (local-file (search-tay-package-file "files/hermes-chromium-ws-probe.ts")))

(define %hermes-chromium-ws-probe-tests
  (local-file (search-tay-package-file "files/hermes-chromium-ws-probe.test.ts")))

(define %hermes-ws-probe-page
  (local-file (search-tay-package-file "files/hermes-ws-probe.html")))

(define-public hermes-desktop
  (package
    (name "hermes-desktop")
    (version "2026.9.24")
    (source hermes-agent-source)
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      ;; Desktop validation and actual UI proof are separate from compilation;
      ;; upstream's suites launch browsers, fake services and external installers.
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-managed-desktop
            (lambda _
              (setenv "PATH" (string-append #$hermes-desktop-npm "/bin:"
                                            (getenv "PATH")))
              (setenv "HOME" (string-append (getcwd) "/build-home"))
              (mkdir-p (getenv "HOME"))
              (setenv "npm_config_offline" "true")
              (setenv "npm_config_ignore_scripts" "true")
              (setenv "npm_config_audit" "false")
              (setenv "npm_config_fund" "false")
              (setenv "ELECTRON_SKIP_BINARY_DOWNLOAD" "1")
              (setenv "PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD" "1")
              (invoke "python3" #$%hermes-desktop-npm-helper "prepare" (getcwd)
                      #$%hermes-desktop-ui-source)
              ;; Replace the obsolete Node socket helper AND its adapter tests.
              ;; Vite copies public/ to dist; install also retains public/.
              (copy-file #$%hermes-chromium-ws-probe
                         "apps/desktop/electron/gateway-ws-probe.ts")
              (copy-file #$%hermes-chromium-ws-probe-tests
                         "apps/desktop/electron/gateway-ws-probe.test.ts")
              (copy-file #$%hermes-ws-probe-page
                         "apps/desktop/public/hermes-ws-probe.html")
              (invoke "python3" #$%hermes-desktop-store-helper
                      (getcwd) #$hermes-agent #$output)))
          (add-before 'build 'install-offline-workspaces
            (lambda _
              (let ((cache (string-append (getcwd) "/npm-cache")))
                (for-each
                 (lambda (archive)
                   (invoke "npm" "cache" "add"
                           (if (string=? archive #$%hermes-desktop-ui-source)
                               (string-append
                                (getcwd) "/npm-inputs/nous-ui-0.18.2.tgz")
                               archive)
                           "--offline" "--ignore-scripts" "--cache" cache
                           "--no-audit" "--no-fund"))
                 (list #$@(map cdr %hermes-desktop-npm-sources)))
                (invoke "npm" "ci" "--offline" "--ignore-scripts"
                        "--workspace" "apps/desktop"
                        "--workspace" "apps/shared"
                        "--include-workspace-root=false"
                        "--cache" cache "--no-audit" "--no-fund"))
              (invoke "python3" #$%hermes-desktop-font-helper
                      (getcwd) #$font-ibm-plex #$font-gnu-unifont
                      #$font-jetbrains-mono)
              ;; These native JS build-tool binaries are upstream artifacts
              ;; authorized by the user, not a claim of source-built tools.
              (let ((rpath
                     (string-append (ungexp gcc "lib") "/lib")))
                ;; Only the GNU/Linux bindings are used by this build.  Other
                ;; platform payloads in npm tarballs are not ELF objects.
                (for-each
                 (lambda (file)
                   (when (string-contains file "linux-x64-gnu")
                     (invoke "patchelf" "--set-rpath" rpath file)))
                 (find-files "node_modules" "\\.node$")))
              (for-each
               patch-shebang
               (filter (lambda (file)
                         (eq? 'regular (stat:type (lstat file))))
                       (find-files "node_modules" ".*")))
              ;; esbuild's Go executable is statically linked.
              (setenv "ESBUILD_BINARY_PATH"
                      (string-append (getcwd)
                                     "/node_modules/@esbuild/linux-x64/bin/esbuild"))))
          (replace 'build
            (lambda _
              ;; Bound build-only V8 memory on shared workstations. The launcher
              ;; does not export this setting to the installed Electron app.
              (setenv "NODE_OPTIONS" "--max-old-space-size=2048")
              ;; Unlike npm Electron installation, this produces Hermes's real
              ;; renderer, preload and main-process code from the pinned source.
              (with-directory-excursion "apps/desktop"
                (mkdir-p "build")
                (call-with-output-file "build/install-stamp.json"
                  (lambda (port)
                    (display
                     (string-append
                      "{\"schemaVersion\":1,\"commit\":"
                      "\"f97608f178d1ffeca59860195ab7da295f7c8e5f\","
                      "\"branch\":\"v2026.9.24\",\"dirty\":false,\"source\":\"guix\"}\n")
                     port)))
                (invoke "../../node_modules/.bin/vite" "build")
                (invoke "node" "scripts/bundle-electron-main.mjs"))
              ;; node-pty's tarball prebuilds must never win over our build
              ;; against the exact running Electron headers.
              (when (file-exists? "node_modules/node-pty/prebuilds")
                (delete-file-recursively "node_modules/node-pty/prebuilds"))
              (mkdir-p "electron-headers")
              (invoke "tar" "-xf" #$%hermes-electron-headers
                      "-C" "electron-headers" "--strip-components=1")
              (invoke "node" "node_modules/node-gyp/bin/node-gyp.js"
                      "rebuild" "--directory=node_modules/node-pty"
                      "--build-from-source" "--runtime=electron"
                      "--target=40.10.2"
                      (string-append "--nodedir=" (getcwd) "/electron-headers")
                      "--disturl=" "--offline")
              (invoke "patchelf" "--set-rpath"
                      (string-append (ungexp gcc "lib") "/lib")
                      "node_modules/node-pty/build/Release/pty.node")
              (with-directory-excursion "apps/desktop"
                (invoke "node" "scripts/stage-native-deps.mjs" "linux" "x64"))))
          (replace 'install
            (lambda _
              (let* ((app (string-append #$output "/share/hermes-desktop"))
                     (bin (string-append #$output "/bin"))
                     (doc (string-append #$output "/share/doc/hermes-desktop")))
                (mkdir-p app)
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each
                 (lambda (dir)
                   (copy-recursively (string-append "apps/desktop/" dir)
                                     (string-append app "/" dir)))
                 '("dist" "assets" "public"))
                (copy-file "apps/desktop/package.json"
                           (string-append app "/package.json"))
                (mkdir-p (string-append app "/resources"))
                (copy-file "apps/desktop/build/install-stamp.json"
                           (string-append app "/resources/install-stamp.json"))
                (install-file "LICENSE" doc)
                (copy-recursively "apps/desktop/build/free-fonts-notices"
                                  (string-append doc "/fonts"))
                ;; Read original fixed archives, not only npm's selected files:
                ;; preserve every available redistribution notice and manifest.
                (apply invoke "python3" #$%hermes-desktop-npm-helper "notices"
                       (getcwd) (string-append doc "/npm")
                       (map
                        (lambda (archive)
                          (if (string=? archive #$%hermes-desktop-ui-source)
                              (string-append
                               (getcwd) "/npm-inputs/nous-ui-0.18.2.tgz")
                              archive))
                        (list #$@(map cdr %hermes-desktop-npm-sources))))
                (call-with-output-file (string-append bin "/hermes-desktop")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/bash~%"
                             "export HERMES_DESKTOP_MANAGED=guix~%"
                             "export HERMES_DESKTOP_HERMES=~s~%"
                             "export ELECTRON_IS_DEV=0~%"
                             "export PATH=~s:\"$PATH\"~%"
                             "exec ~s ~s \"$@\"~%")
                            #$bash-minimal
                            #$(file-append hermes-agent "/bin/hermes")
                            #$(file-append xprop "/bin")
                            #$(file-append hermes-desktop-electron "/bin/electron")
                            app)))
                (chmod (string-append bin "/hermes-desktop") #o755)
                (wrap-program (string-append bin "/hermes-desktop")
                  `("PATH" prefix (,(string-append #$xwininfo "/bin"))))
                (let ((icons (string-append #$output
                                           "/share/icons/hicolor/1024x1024/apps"))
                      (applications (string-append #$output "/share/applications")))
                  (mkdir-p icons)
                  (mkdir-p applications)
                  (copy-file "apps/desktop/assets/icon.png"
                             (string-append icons "/hermes.png"))
                  (invoke "python3" "-c"
                          (string-append
                           "import sys; sys.path.insert(0,'hermes_cli'); "
                           "from linux_desktop_entry import render_desktop_entry; "
                           "open(sys.argv[3],'w').write("
                           "render_desktop_entry(sys.argv[1],sys.argv[2]))")
                          (string-append bin "/hermes-desktop") "hermes"
                          (string-append applications "/hermes.desktop")))))))))
    (native-inputs
     (append (list node-lts hermes-desktop-npm python patchelf zstd
                   %hermes-electron-headers font-ibm-plex font-gnu-unifont
                   font-jetbrains-mono)
             (map cdr %hermes-desktop-npm-sources)))
    (inputs
     `(("bash-minimal" ,bash-minimal)
       ("gcc:lib" ,gcc "lib")
       ("hermes-desktop-electron" ,hermes-desktop-electron)
       ("hermes-agent" ,hermes-agent)
       ("xprop" ,xprop)
       ("xwininfo" ,xwininfo)))
    (home-page "https://github.com/NousResearch/hermes-agent")
    (synopsis "Native desktop interface for Hermes Agent")
    (description
     "Hermes Desktop is the upstream Electron application, with its renderer,
main process and preload code compiled offline from pinned Hermes sources.
Its terminal addon is compiled against the exact Electron runtime headers.
The launcher binds a packaged Hermes backend and directs updates to Guix,
without installing another backend into the user's home directory.  Chromium
sandboxing and renderer isolation remain enabled.  The pinned upstream Electron
runtime and npm native build-tool bindings are vendor binaries, so this package
is explicitly not fully source-built.  Proprietary bundled fonts are replaced
with redistributable IBM Plex and GNU Unifont while retaining typography roles.")
    (license license:expat)))
