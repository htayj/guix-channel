;;; GNU Guix package for editor-code-assistant/eca-emacs.

(define-module (tay packages eca-emacs)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages starred-d-h))

(define-public eca-emacs
  (package
    (name "eca-emacs")
    (version "0.0.1-0.f145505")
    (source
     (origin
       (inherit (package-source editor-code-assistant-eca-emacs-source))
       (patches (search-patches "tay/packages/patches/eca-emacs-system-server.patch"))
       (patch-flags '("-p1" "--fuzz=0"))))
    (build-system emacs-build-system)
    (arguments
     (list
      #:include #~'("^eca.*\\.el$")
      ;; The patch removes the upstream server-download tests together with the
      ;; downloader; custom, PATH, and missing-server tests remain.
      #:test-command
      #~(list "emacs" "-Q" "--batch" "-L" "." "-L" "test"
              "--eval"
              "(progn (require 'buttercup)
                      (dolist (file (directory-files \"test\" t \"-test\\\\.el$\"))
                        (load file nil t))
                      (buttercup-run))")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'check 'isolate-home
            (lambda _
              (let ((home (string-append (getenv "TMPDIR") "/eca-home")))
                (mkdir-p home)
                (setenv "HOME" home)
                (setenv "XDG_CONFIG_HOME" home)
                (setenv "XDG_DATA_HOME" home)
                (setenv "XDG_CACHE_HOME" home))))
          (add-after 'install 'install-license
            (lambda _
              (let ((doc (string-append #$output "/share/doc/eca-emacs")))
                (mkdir-p doc)
                (install-file "LICENSE" doc)))))))
    (native-inputs (list emacs-buttercup))
    (propagated-inputs
     (list emacs-dash emacs-s emacs-f emacs-markdown-mode emacs-compat))
    (home-page "https://github.com/editor-code-assistant/eca-emacs")
    (synopsis "Emacs client for Editor Code Assistant")
    (description
     "ECA Emacs provides chat, inline completion, and editor integrations for
an external Editor Code Assistant server.  This package installs only the
Emacs Lisp client.  Install @code{eca} separately on @code{PATH}, or set
@code{eca-custom-command} to an explicit server command; the client never
downloads a server.  Network access, provider credentials, workspace state,
and MCP services are runtime concerns.  Optional integrations such as
@code{whisper.el}, Transient, LSP Mode, Flymake, Flycheck, and ht are not
required to load this package.")
    (license license:asl2.0)))
