;;; Installable Zsh aliases from the archived aptitude-custom-aliases project.

(define-module (tay packages aptitude-custom-aliases)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (tay packages projects))

(define-public aptitude-custom-aliases
  (package
    (name "aptitude-custom-aliases")
    ;; Keep the installable package tied to the same immutable revision as the
    ;; channel's corresponding source-preservation package.
    (version (package-version htayj-aptitude-custom-aliases-source))
    (source (package-source htayj-aptitude-custom-aliases-source))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("init.zsh" "share/zsh/plugins/aptitude-custom-aliases/")
          ("README.md" "share/doc/aptitude-custom-aliases/"))))
    (synopsis "Zsh aliases for common Aptitude commands")
    (description
     "This package installs the @file{init.zsh} module from the archived
aptitude-custom-aliases project under Guix's conventional Zsh plugin
directory.  Source it from a Zsh startup file, or link its directory into a
Zprezto modules directory, to provide mnemonic aliases for common Aptitude
operations.  The aliases invoke the host's @command{aptitude} and
@command{sudo}; this package does not provide either command.  The upstream
repository has no explicit license, so redistribution remains subject to a
separate rights review.")
    (home-page "https://github.com/htayj/aptitude-custom-aliases")
    (license
     (license:non-copyleft "https://choosealicense.com/no-permission/"
                           (string-append
                            "No explicit license was found; redistribution "
                            "permission is not granted.")))))
