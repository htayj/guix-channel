;;; GNU Guix package for ongaeshi/emacs-vim-region.

(define-module (tay packages vim-region)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-n-r))

(define-public emacs-vim-region
  (package
    (name "emacs-vim-region")
    (version (package-version ongaeshi-emacs-vim-region-source))
    (source (package-source ongaeshi-emacs-vim-region-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; Upstream has no test suite.  The isolated installed-package proof in
      ;; tests/emacs-vim-region-smoke.* exercises both batch and terminal Emacs.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'load-expand-region
            (lambda _
              ;; The upstream + binding names er/expand-region without loading
              ;; its declared dependency.  Keep every binding and command;
              ;; loading vim-region should also make that command available.
              (substitute* "vim-region.el"
                (("\\(require 'thingatpt\\)")
                 "(require 'thingatpt)\n(require 'expand-region)"))))
          (add-after 'install 'install-documentation
            (lambda _
              ;; There is no standalone LICENSE: the installed vim-region.el
              ;; retains the full GPL3+ grant and 2013 ongaeshi copyright header.
              (let ((doc (string-append #$output
                                        "/share/doc/emacs-vim-region")))
                (mkdir-p doc)
                (install-file "README.md" doc)
                (install-file "HISTORY.md" doc)))))))
    (propagated-inputs (list emacs-expand-region))
    (home-page "https://github.com/ongaeshi/emacs-vim-region")
    (synopsis "Select and edit regions with Vim-style commands")
    (description
     "This Emacs extension provides a global minor mode for selecting and
editing text regions with Vim-style movement keys.  It supports copying,
killing, pasting, character searches, symbol selection, query replacement,
line sorting, alignment, undo, and semantic selection via expand-region.
Use @code{vim-region-mode} to enter the mode; ordinary editing commands leave
it automatically unless its persistent-selection option is enabled.")
    (license license:gpl3+)))
