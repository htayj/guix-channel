;;; Official Pi CLI/TUI, distinct from the omp fork and source snapshots.
(define-module (tay packages pi-coding-agent)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages rust-apps)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages bun-runtime)
  #:use-module (tay packages pi-coding-agent-npm-sources))

;; The reviewed b1efcf7 snapshot is four commits *after* this release tag.
;; Use the actual release's source, never attribute its executable to b1efcf7.
(define %pi-release-commit "914cf1472e715297caa30db4b9535d534a9eb718")

(define %pi-binary
  (origin
    (method url-fetch)
    (uri "https://github.com/earendil-works/pi/releases/download/v0.84.2/pi-linux-x64.tar.gz")
    (file-name "pi-coding-agent-0.84.2-linux-x64.tar.gz")
    (sha256
     (base32 "04qwxvwn8593bmwm3vy7yph60nnmn7ayprsgcanc89fjgxwbwvwh"))))

(define %pi-notice-collector
  (local-file (search-tay-package-file "files/pi-coding-agent-notices.py")))

(define-public pi-coding-agent
  (package
    (name "pi-coding-agent")
    (version "0.84.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/earendil-works/pi/releases/download/v0.84.2/"
             "pi-0.84.2-source.tar.gz"))
       (file-name "pi-coding-agent-0.84.2-source.tar.gz")
       (sha256
        (base32 "03j68g0m70jfrr1nav6hdjpkppanqcqgifv1ys4zm9lg4nnyzacn"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Bun's embedded payload must not be stripped or rewritten by patchelf.
      #:strip-binaries? #f
      #:validate-runpath? #f
      #:install-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((app (string-append #$output "/libexec/pi"))
                     (doc (string-append #$output "/share/doc/pi-coding-agent"))
                     (bin (string-append #$output "/bin"))
                     (libdir (string-append #$glibc "/lib"))
                     (gcc-lib (string-append #$gcc:lib "/lib")))
                (mkdir-p "release")
                (invoke "tar" "-xzf" #$%pi-binary "-C" "release")
                ;; Example extensions and their independent dependency graphs
                ;; are not part of the installed host application's closure.
                (delete-file-recursively "release/pi/examples")
                (copy-recursively "release/pi" app)
                ;; Only the standalone clipboard shared objects are rewritten.
                ;; Keep the complete upstream CLI, themes, WASM and HTML assets.
                (for-each
                 (lambda (file)
                   (invoke "patchelf" "--set-rpath"
                           (string-append libdir ":" gcc-lib) file))
                 (find-files app "\\.node$"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/pi")
                  (lambda (port)
                    (format port "#!~a~%" #$(file-append bash-minimal "/bin/bash"))
                    (display
                     (string-append
                      "case ${PI_OFFLINE-1} in\n"
                      "  0|false|no) unset PI_OFFLINE ;;\n"
                      "  *) export PI_OFFLINE=\"${PI_OFFLINE:-1}\" ;;\n"
                      "esac\ncase ${PI_SKIP_VERSION_CHECK-1} in\n"
                      "  0|false|no) unset PI_SKIP_VERSION_CHECK ;;\n"
                      "  *) export PI_SKIP_VERSION_CHECK=\""
                      "${PI_SKIP_VERSION_CHECK:-1}\" ;;\nesac\n"
                      "export PI_TELEMETRY=\"${PI_TELEMETRY:-0}\"\n"
                      "export PI_CODING_AGENT_DIR=\"${PI_CODING_AGENT_DIR:-"
                      "${XDG_STATE_HOME:-$HOME/.local/state}/pi/agent}\"\n")
                     port)
                    ;; PI_PACKAGE_DIR is a read-only asset root, NOT user state.
                    (format port "export PI_PACKAGE_DIR=~s~%" app)
                    (format port "export PATH=~s:~s:\"$PATH\"~%"
                            #$(file-append bash-minimal "/bin")
                            #$(file-append node-lts "/bin"))
                    (format port "export PATH=~s:~s:~s:~s:\"$PATH\"~%"
                            #$(file-append coreutils-minimal "/bin")
                            #$(file-append git-minimal "/bin")
                            #$(file-append ripgrep "/bin")
                            #$(file-append fd "/bin"))
                    (format port "exec ~a --library-path ~a:~a ~a/pi \"$@\"~%"
                            (search-input-file inputs #$(glibc-dynamic-linker))
                            libdir gcc-lib app)))
                (chmod (string-append bin "/pi") #o555)
                (mkdir-p doc)
                (install-file "LICENSE" doc)
                (copy-file #$(package-source this-package)
                           (string-append doc "/corresponding-source.tar.gz"))
                (copy-file "packages/coding-agent/install-lock/package-lock.json"
                           (string-append doc "/package-lock.json"))
                (apply invoke #$(file-append python "/bin/python3")
                       #$%pi-notice-collector
                       "packages/coding-agent/install-lock/package-lock.json"
                       (string-append doc "/npm-notices")
                       (map (lambda (entry)
                              (string-append (car entry) ":" (cadr entry)))
                            '#$%pi-coding-agent-npm-sources))
                ;; Bundled Bun 1.3.14 is supplied by upstream, not an external
                ;; Node process. Retain its exact source and linked-license map.
                (mkdir-p "bun-source")
                (invoke "tar" "-xzf" #$(package-source bun-runtime)
                        "--strip-components=1" "-C" "bun-source")
                (install-file "bun-source/LICENSE.md" (string-append doc "/bun"))
                (copy-file #$(package-source bun-runtime)
                           (string-append doc "/bun/corresponding-source.tar.gz"))
                (for-each
                 (lambda (file)
                   (let ((dest (string-append doc "/bun/source-notices/" file)))
                     (mkdir-p (dirname dest))
                     (copy-file file dest)))
                 (find-files "bun-source" "^(LICENSE|COPYING|NOTICE)(\\..*)?$"))
                (call-with-output-file (string-append doc "/PROVENANCE")
                  (lambda (port)
                    (format
                     port
                     (string-append
                      "Upstream: https://github.com/earendil-works/pi\n"
                      "Version: 0.84.2\nRelease source commit: ~a\n"
                      "Official GitHub release asset, built with Bun 1.3.14; "
                      "not rebuilt from source by Guix.\n"
                      "Research snapshot "
                      "b1efcf7d7c5d7394fbb12ede0174e04d39ee7004 is four commits "
                      "newer than this release.\n"
                      "Both release and corresponding source archives "
                      "are hash-pinned.\n"
                      "The install lock inventories npm dependencies; "
                      "it is not a reproducibility attestation for "
                      "the upstream executable.\n"
                      "Registry tarballs supply original licenses/notices, "
                      "not runtime installs; no npm lifecycle scripts or "
                      "registry requests occur during the build.\n"
                      "Bun LICENSE.md describes statically linked libraries "
                      "and LGPL relinking; WebKit corresponding source: "
                      "https://github.com/oven-sh/webkit.\n"
                      "No cryptographic upstream signature or independent "
                      "reproduction is claimed.\n"
                      "Example extensions are available in "
                      "corresponding-source.tar.gz, not installed or resolved.\n"
                      "Pi has no built-in filesystem/process/network/"
                      "credential sandbox. PI_OFFLINE disables startup "
                      "network operations, not provider calls.\n"
                      "Provider inference requires explicit user "
                      "configuration and credentials; no such calls "
                      "are claimed by offline acceptance.\n")
                     #$%pi-release-commit)))))))))
    (native-inputs (list patchelf python))
    (inputs
     `(("bash-minimal" ,bash-minimal)
       ("glibc" ,glibc)
       ("gcc:lib" ,gcc "lib")
       ("coreutils-minimal" ,coreutils-minimal)
       ("git-minimal" ,git-minimal)
       ("ripgrep" ,ripgrep)
       ("fd" ,fd)
       ("node" ,node-lts)))
    (supported-systems '("x86_64-linux"))
    (synopsis "Pi coding-agent CLI and TUI without a built-in sandbox")
    (description
     "Pi is the upstream earendil-works coding agent with an interactive
terminal interface, RPC mode, session persistence, extensible tools, image
processing and HTML export.  This package installs the official hash-pinned
0.84.2 Linux release, not the omp fork and not a Guix source rebuild.  Original
runtime assets and dependency notices are retained; optional example extension
workspaces are not installed.  Startup network activity and telemetry are
disabled by default.  Pi intentionally has no built-in filesystem, process,
network or credential sandbox.  Provider inference remains available with
explicit user credentials and configuration; offline mode is not a network
sandbox.")
    (home-page "https://github.com/earendil-works/pi")
    ;; Pi itself is MIT. The installed Bun runtime contains LGPL components;
    ;; npm notices record the individual SPDX grants rather than implying MIT
    ;; applies to every embedded component.
    (license
     (list license:expat license:asl2.0 license:bsd-0 license:bsd-2 license:bsd-3
           license:isc license:lgpl2.0 license:lgpl2.1 license:zlib
           (license:fsdg-compatible "https://blueoakcouncil.org/license/1.0.0")))))
