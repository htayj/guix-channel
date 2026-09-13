;;; GNU Guix package definition for the OpenCode terminal CLI/TUI.

(define-module (tay packages opencode)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-11)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression))

(define %opencode-version "1.18.18")

(define %opencode-release-commit
  "31406ccc51b4bd2a4e1e086b2bcaa5f7f804f26d")

(define (opencode-release-origin system)
  ;; Upstream publishes Bun-compiled executables.  Select the baseline x86_64
  ;; build because it does not require AVX2; the aarch64 release has no
  ;; separate baseline variant.  These hashes match the SHA-256 digests on the
  ;; upstream GitHub release page.
  (let-values (((archive hash)
                (match system
                  ((? target-x86-64?)
                   (values "opencode-linux-x64-baseline.tar.gz"
                           "1mskm2cyfmsgagkdz1xgdpif8rs9yzw8lanmy14an7achmald485"))
                  ((? target-aarch64?)
                   (values "opencode-linux-arm64.tar.gz"
                           "1fp47w41gbp8kgzl9bp51jg81wq3j8gh4q4mfj3kzd47avnbbcfw"))
                  (_
                   (values "opencode-unsupported-system.tar.gz"
                           "0000000000000000000000000000000000000000000000000000")))))
    (origin
      (method url-fetch)
      (uri (string-append
            "https://github.com/anomalyco/opencode/releases/download/v"
            %opencode-version "/" archive))
      (file-name archive)
      (sha256 (base32 hash)))))

(define-public opencode
  (package
    (name "opencode")
    (version %opencode-version)
    ;; Keep the exact tagged source as the package source for provenance and
    ;; for its license notice.  Building packages/opencode is not currently
    ;; practical in Guix: Bun is unavailable and the upstream build performs
    ;; network installs of platform-specific dependencies.  The independently
    ;; hashed official executable is supplied as a build input below.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/anomalyco/opencode")
             (commit %opencode-release-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0saflrnjqjmwfxpfnmpj0hr0wnjfwa53sa0a1x9hhapxr2zmqddc"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      ;; The release ELF retains its FHS interpreter and is run explicitly by
      ;; the wrapper through Guix's glibc loader.
      #:validate-runpath? #f
      #:install-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; Only the top-level notice is needed by this binary package.
              (copy-file (string-append source "/LICENSE") "LICENSE")))
          ;; The source input supplies provenance and LICENSE only.  Avoid
          ;; running mutation phases intended for installed source scripts.
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((binary-archive (assoc-ref inputs "opencode-binary"))
                     (bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (raw-program (string-append libexec "/opencode"))
                     (program (string-append bin "/opencode")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (invoke "tar" "-xzf" binary-archive "-C" libexec "opencode")
                (chmod raw-program #o555)
                ;; Invoking the Guix loader directly keeps the upstream Bun
                ;; executable byte-for-byte intact while supplying its glibc
                ;; dependencies without relying on FHS paths.
                (call-with-output-file program
                  (lambda (port)
                    (display
                     (string-append
                      "#!/bin/sh\n"
                      "exec "
                      (search-input-file inputs #$(glibc-dynamic-linker))
                      " --library-path " (assoc-ref inputs "glibc") "/lib "
                      raw-program " \"$@\"\n")
                     port)))
                (chmod program #o555))))
          (add-after 'patch-shebangs 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Guix build containers have no provider credentials or
                ;; network access.  These commands exercise the embedded CLI
                ;; without starting the interactive TUI.
                (let ((program (string-append #$output "/bin/opencode")))
                  (setenv "HOME" (getcwd))
                  (setenv "XDG_CACHE_HOME" (string-append (getcwd) "/.cache"))
                  (setenv "XDG_CONFIG_HOME" (string-append (getcwd) "/.config"))
                  (setenv "XDG_DATA_HOME" (string-append (getcwd) "/.local/share"))
                  (invoke program "--version")
                  (invoke program "--help"))))))))
    (native-inputs
     (list gzip tar))
    (inputs
     `(("opencode-binary"
        ,(opencode-release-origin
          (or (%current-target-system) (%current-system))))
       ("glibc" ,glibc)))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Terminal-based coding agent")
    (description
     "OpenCode is a terminal user interface and command-line coding agent.  It
supports multiple model providers, local and remote sessions, language-server
integration, and extensibility through tools and plugins.  This package uses
upstream's Bun-compiled GNU/Linux release executable and retains the upstream
MIT notice from the corresponding source tag.  Provider credentials, network
services, downloaded language servers, and optional integrations are not part
of the package and must be configured or obtained separately at run time.")
    (home-page "https://opencode.ai/")
    (license license:expat)))
