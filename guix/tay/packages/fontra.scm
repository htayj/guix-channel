;;; Fontra -- browser-based font editor, built from pinned sources offline.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages fontra)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages check)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages fontra-npm-sources)
  #:use-module (tay packages fontra-python))

(define %fontra-lock-fixes
  (local-file (search-tay-package-file "fontra-npm-lock-fixes.json")))

(define-public fontra
  (package
    (name "fontra")
    (version "2026.9.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/fontra/fontra/tar.gz/"
             "cc0a3b40bcd9860d8b6382df1faf6122ec306a5b"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "18rqcn32iva08jql4xfpw6w8ax1i5z5a8q0pf9rr5lpjc1yr9x1g"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:test-backend #~'pytest
      #:test-flags #~(list "test-py")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-offline-build
            (lambda _
              ;; The source archive has no .git metadata.  Keep the VCS hook
              ;; that writes _version.py, but supply the reviewed tag version.
              (setenv "SETUPTOOLS_SCM_PRETEND_VERSION" #$version)
              (setenv "HOME" (string-append (getcwd) "/build-home"))
              (mkdir-p (getenv "HOME"))
              ;; Guix owns frontend compilation.  Remove only the upstream
              ;; network-install hook, preserving Hatch's wheel artifacts and
              ;; VCS version-file hook.
              (substitute* "pyproject.toml"
                (("\\[tool.hatch.build.hooks.custom\\]") "")
                (("path = \"scripts/bundler_build_hook.py\"") ""))
              ;; Webpack otherwise compiles 100 modules concurrently and its
              ;; default minimizer spawns workers for every host CPU.  Honor
              ;; Guix's job limit while retaining production minification.
              (substitute* "webpack.config.cjs"
                (("custom: \\{")
                 (string-append
                  "custom: { parallelism: Number(process.env.GUIX_BUILD_CORES),"))
                (("optimization: \\{")
                 (string-append
                  "optimization: { minimizer: [new "
                  "(require('minimizer-webpack-plugin'))({"
                  "parallel: Number(process.env.GUIX_BUILD_CORES),"
                  "terserOptions: {compress: {passes: 2}}})],")))
              ;; The build uses Guix's npm and Babel, not the unused npm12
              ;; developer tool or TypeScript's optional native compilers.
              ;; Prune their exclusive lock entries without resolving or
              ;; changing any remaining dependency version or workspace.
              ;; Complete missing registry metadata only after this pruning.
              (invoke "python" "-c"
                      (string-append
                       "import json,sys; "
                       "manifest=json.load(open('package.json')); "
                       "manifest['devDependencies'].pop('npm'); "
                       "open('package.json','w').write("
                       "json.dumps(manifest,indent=2)+'\\n'); "
                       "p='package-lock.json'; d=json.load(open(p)); "
                       "packages=d['packages']; "
                       "packages['']['devDependencies'].pop('npm'); "
                       "obsolete=[k for k in packages if k=='node_modules/npm' "
                       "or k.startswith('node_modules/npm/') "
                       "or k.startswith('node_modules/@typescript/typescript-')]; "
                       "[packages.pop(k) for k in obsolete]; "
                       "packages['node_modules/typescript'].pop("
                       "'optionalDependencies',None); "
                       "fixes=json.load(open(sys.argv[1])); "
                       "[packages[k].update(v) for k,v in fixes.items()]; "
                       "open(p,'w').write(json.dumps(d,indent=2)+'\\n')")
                      #$%fontra-lock-fixes)))
          (add-before 'build 'build-frontend
            (lambda _
              (let* ((node-bin #$(file-append node-lts "/bin"))
                     (npm (string-append node-bin "/npm"))
                     (cache (string-append (getcwd) "/npm-cache")))
                (setenv "PATH" (string-append node-bin ":" (getenv "PATH")))
                (setenv "GUIX_BUILD_CORES"
                        (number->string (parallel-job-count)))
                (setenv "npm_config_offline" "true")
                (setenv "npm_config_ignore_scripts" "true")
                (setenv "npm_config_audit" "false")
                (setenv "npm_config_fund" "false")
                (for-each
                 (lambda (tarball)
                   (invoke npm "cache" "add" tarball "--offline"
                           "--ignore-scripts" "--cache" cache
                           "--no-audit" "--no-fund"))
                 (list #$@(map cdr %fontra-npm-sources)))
                (invoke npm "ci" "--offline" "--ignore-scripts"
                        "--omit=optional" "--cache" cache
                        "--no-audit" "--no-fund")
                ;; Dependencies arrived after patch-source-shebangs.  npm's
                ;; .bin links are retained; patch their regular-file targets.
                (for-each patch-shebang
                          (find-files "node_modules"
                                      "\\.(js|cjs|mjs)$"))
                ;; Webpack transpiles TypeScript using Babel, not the native
                ;; TypeScript compiler distributed in the npm lock.
                (invoke npm "run" "bundle"))))
          (add-after 'check 'check-frontend
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke #$(file-append node-lts "/bin/npm") "test"))))
          (add-after 'install 'install-license
            (lambda _
              (let ((doc (string-append #$output "/share/doc/fontra")))
                (mkdir-p doc)
                (copy-file "LICENSE.txt" (string-append doc "/LICENSE"))
                ;; Minification must not discard redistribution notices for
                ;; the npm dependencies, including precompiled shaping WASM.
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/npm/" file)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 (find-files "node_modules"
                             (string-append
                              "^(LICENSE|License|license|LICENCE|licence|"
                              "COPYING|copying|NOTICE|notice)([.-].*)?$"))))))
          (add-after 'install 'check-installed-client
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let ((client (string-append (site-packages inputs outputs)
                                           "/fontra/client")))
                (for-each
                 (lambda (name)
                   (unless (file-exists? (string-append client "/" name))
                     (error "missing installed frontend document" name)))
                 '("landing.html" "editor.html" "fontoverview.html"
                   "fontinfo.html" "applicationsettings.html"))
                (unless (and (pair? (find-files client "\\.js$"))
                             (pair? (find-files client "\\.css$"))
                             (pair? (find-files client "\\.wasm$")))
                  (error "missing installed JS, CSS, or shaping WASM"))))))))
    (native-inputs
     (append (list node-lts python-hatchling python-hatch-vcs
                   python-pytest python-pytest-asyncio python-glyphslib-fontra)
             (map cdr %fontra-npm-sources)))
    (propagated-inputs
     (list python-aiohttp-fontra python-cattrs python-fonttools-fontra
           python-watchfiles-fontra python-pyyaml python-ufomerge
           python-skia-pathops-fontra python-pillow-fontra
           python-ufo2ft-fontra python-ufolib2-fontra))
    (home-page "https://fontra.xyz/")
    (synopsis "Browser-based font editor")
    (description
     "Fontra is a font editor with a browser-based interface and a local Python
server.  It edits variable and static font sources, supports UFO, Designspace
and Fontra projects, and includes font conversion and configurable workflow
commands.  Its frontend is compiled from the pinned sources without network
access during the build.")
    (license license:gpl3)))
