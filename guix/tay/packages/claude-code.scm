;;; GNU Guix package definition for the proprietary Claude Code CLI.

(define-module (tay packages claude-code)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-11)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (nonguix build-system binary)
  #:use-module ((nonguix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash))

(define %claude-code-version "2.1.233")

(define (claude-code-origin system)
  (let-values (((architecture hash)
                (match system
                  ((? target-x86-64?)
                   (values
                    "amd64"
                    "0l2k63kjlidq1d39ljdncri9av6p63xd1qsw95kv41za3gkkrjvc"))
                  ((? target-aarch64?)
                   (values
                    "arm64"
                    "1pdmn7qjhv9zifyy1wrmvmd7b2vdyznzbz9v3wplzkjdhi1schyr"))
                  (_
                   (values
                    "unsupported"
                    "0000000000000000000000000000000000000000000000000000")))))
    (origin
      (method url-fetch)
      (uri
       (string-append
        "https://downloads.claude.ai/claude-code/apt/latest/pool/main/c/"
        "claude-code/claude-code_" %claude-code-version "-1_"
        architecture ".deb"))
      (file-name
       (string-append "claude-code-" %claude-code-version "-"
                      architecture ".deb"))
      (sha256 (base32 hash)))))

(define-public claude-code
  (package
    (name "claude-code")
    (version %claude-code-version)
    (source
     (claude-code-origin
      (or (%current-target-system) (%current-system))))
    (build-system binary-build-system)
    (arguments
     (list
      ;; Anthropic publishes a Bun-compiled native executable rather than
      ;; buildable application source.  Preserve that executable intact apart
      ;; from its dynamic loader and the wrapper below.
      #:substitutable? #f
      #:strip-binaries? #f
      #:patchelf-plan #~'(("usr/bin/claude" ("glibc")))
      #:install-plan
      #~'(("usr/bin/claude" "/libexec/claude")
          ("usr/share/doc/claude-code/copyright"
           "/share/doc/claude-code/copyright"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-launcher
            (lambda _
              (let ((bin (string-append #$output "/bin")))
                (mkdir-p bin)
                (symlink (string-append #$output "/libexec/claude")
                         (string-append bin "/claude"))
                (wrap-program (string-append bin "/claude")
                  ;; Disable both background and explicitly requested binary
                  ;; replacement.  Releases remain managed by Guix.
                  '("DISABLE_UPDATES" = ("1"))))))
          (add-after 'install-launcher 'check-installed-launcher
            (lambda _
              (let ((program (string-append #$output "/bin/claude"))
                    (notice (string-append #$output
                                           "/share/doc/claude-code/copyright")))
                (unless (and (access? program X_OK)
                             (file-exists? notice))
                  (error "Claude Code installation is incomplete"))))))))
    (inputs (list bash-minimal glibc))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Agentic coding assistant for the terminal")
    (description
     "Claude Code is Anthropic's proprietary agentic coding command-line
application.  It reads and edits local projects, runs commands, and connects
to Claude using an eligible account or supported API provider.  This package
installs Anthropic's architecture-specific native Linux release, selects
its bundled @command{ripgrep}, and disables all application update paths.
Authentication credentials, configuration, plugins, MCP servers, and session
data remain mutable per-user runtime state outside the Guix store.")
    (home-page "https://code.claude.com/docs/en/overview")
    (license
     (license:undistributable
      "https://code.claude.com/docs/en/legal-and-compliance"
      "Use is governed by Anthropic's applicable consumer or commercial terms."))))
