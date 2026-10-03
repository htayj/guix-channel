;;; OpenCode plugin and installer, built from the reviewed immutable source.
(define-module (tay packages oh-my-opencode-slim)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages python)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages bun-runtime)
  #:use-module (tay packages opencode)
  #:use-module (tay packages starred-a-c)
  #:use-module (tay packages oh-my-opencode-slim-companion)
  #:use-module (tay packages oh-my-opencode-slim-npm-sources))

(define %npm-helper
  (local-file (search-tay-package-file "files/oh-my-opencode-slim-npm.py")))

(define-public oh-my-opencode-slim
  (package
    (name "oh-my-opencode-slim")
    (version "2.2.13")
    (source
     (origin
       (inherit (package-source alvinunreal-oh-my-opencode-slim-source))
       (patches (list (search-tay-package-file
                       "patches/oh-my-opencode-slim-store-companion.patch")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f ; Main exercises the installed CLI and real OpenCode consumer.
      #:strip-binaries? #f
      #:phases
      (with-extensions (list guile-json-4)
       #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (add-after 'unpack 'guix-managed-companion
            (lambda _
              ;; Both CLI installation and plugin startup resolve the packaged
              ;; companion; the installer never downloads another executable.
              (substitute* '("src/companion/updater.ts" "src/companion/manager.ts")
                (("@GUIX_COMPANION@")
                 #$(file-append oh-my-opencode-slim-companion
                                "/bin/oh-my-opencode-slim-companion")))))
          (add-before 'build 'materialize-offline-dependencies
            (lambda _
              (use-modules (json))
              (call-with-output-file "npm-archives.json"
                (lambda (port)
                  (scm->json
                   (list->vector
                    (map (lambda (name archive)
                           (vector name archive))
                         '#$(map car %oh-my-opencode-slim-npm-sources)
                         (list #$@(map cdr %oh-my-opencode-slim-npm-sources))))
                   port)))
              (setenv "GUIX_SYSTEM" #$(or (%current-target-system) (%current-system)))
              (invoke "python3" #$%npm-helper "npm-archives.json")))
          (replace 'build
            (lambda _
              (let ((bun #$(file-append bun-runtime "/bin/bun")))
                ;; These are the upstream executable bundle commands.  No
                ;; prepare/install hooks, registry requests or dev tools run.
                (invoke bun "run" "build:plugin")
                (invoke bun "run" "build:v2")
                (invoke bun "run" "build:cli")
                (invoke bun "run" "generate-schema"))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build gremlin))
              (let* ((module (string-append #$output "/share/oh-my-opencode-slim"))
                     (doc (string-append #$output "/share/doc/oh-my-opencode-slim"))
                     (bin (string-append #$output "/bin"))
                     (program (string-append bin "/oh-my-opencode-slim"))
                     (libpath (string-append #$glibc "/lib:"
                                             #$gcc:lib "/lib")))
                (mkdir-p module)
                (for-each (lambda (directory)
                            (copy-recursively directory
                                              (string-append module "/" directory)))
                          '("dist" "node_modules" "src/skills"))
                (mkdir-p (string-append module "/src/companion"))
                (copy-file "src/companion/companion-manifest.json"
                           (string-append module "/src/companion/"
                                          "companion-manifest.json"))
                (for-each (lambda (file)
                            (copy-file file (string-append module "/" file)))
                          '("package.json" "oh-my-opencode-slim.schema.json" "LICENSE"))
                (mkdir-p doc)
                (install-file "LICENSE" doc)
                (install-file "README.md" doc)
                (install-file "bun.lock" doc)
                (copy-recursively "npm-licenses" (string-append doc "/npm-licenses"))
                ;; Native npm artifacts are explicit fixed origins, not
                ;; lifecycle downloads.  Adapt their ELF ABI paths to Guix.
                (for-each
                 (lambda (file)
                   (when (elf-file? file)
                     (chmod file #o755)
                     (invoke "patchelf" "--set-rpath" libpath file)
                     (when (string=? (basename file) "ast-grep")
                       (invoke "patchelf" "--set-interpreter"
                               (search-input-file
                                inputs #$(glibc-dynamic-linker)) file))))
                 (find-files (string-append module "/node_modules")))
                (mkdir-p bin)
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh\n" #$bash-minimal)
                    (format port
                            "export PATH=~a/bin:~a/bin:~a/bin:~a/bin:${PATH:-}\n"
                            #$opencode #$bun-runtime
                            #$oh-my-opencode-slim-companion #$which)
                    (format port (string-append
                                  "export LD_LIBRARY_PATH=~a"
                                  "${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\n")
                            libpath)
                    (format port "exec ~a/bin/bun ~a/dist/cli/index.js \"$@\"\n"
                            #$bun-runtime module)))
                (chmod program #o555))))))))
    (native-inputs
     (append (list python-minimal patchelf)
             (map cdr %oh-my-opencode-slim-npm-sources)))
    (inputs
     `(("bun-runtime" ,bun-runtime)
       ("opencode" ,opencode)
       ("oh-my-opencode-slim-companion" ,oh-my-opencode-slim-companion)
       ("bash-minimal" ,bash-minimal)
       ("glibc" ,glibc)
       ("which" ,which)
       ("gcc:lib" ,gcc "lib")))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "OpenCode multi-agent plugin, installer and desktop companion")
    (description
     "Oh My OpenCode Slim provides multi-agent orchestration, tools, local
configuration and optional desktop session display for OpenCode.  The plugin
and CLI are built from commit 6faaed283f33ca5467a7909fa786d1c563fb81ad using
Bun and the exact offline Bun-lock production dependency closure.  Bun, native
npm dependencies and the companion use separately hash-pinned official
artifacts, not Guix source rebuilds.  Original source and supplied dependency
notices are retained; some native archives provide only package license
metadata, not separate third-party notices.  The installer registers this
immutable local package rather than an npm plugin name, and resolves the
packaged companion without downloading it.  Provider credentials, models,
network MCP services and user-selected
integrations are not included.  This is an agent plugin, not a security sandbox;
its enabled filesystem, process and network tools have the user's authority.")
    (home-page "https://github.com/alvinunreal/oh-my-opencode-slim")
    (license (list license:expat license:expat-0 license:asl2.0
                   license:bsd-2 license:bsd-3 license:isc license:cc0
                   license:cc-by4.0 license:zlib
                   (license:license "BlueOak-1.0.0"
                                    "https://blueoakcouncil.org/license/1.0.0"
                                    "Blue Oak Model License 1.0.0")))))
