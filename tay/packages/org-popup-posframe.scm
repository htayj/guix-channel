;;; GNU Guix package for A7R7/org-popup-posframe.

(define-module (tay packages org-popup-posframe)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-a-c))

(define-public emacs-org-popup-posframe
  (package
    (name "emacs-org-popup-posframe")
    (version "0.0.1-0.d39cb7c")
    ;; Upstream has no release tag; this is the version declared by the
    ;; fixed source revision used below.
    (source (package-source a7r7-org-popup-posframe-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; Upstream ships no test suite; runtime behavior is covered by the
      ;; isolated batch and graphical smoke test in tests/.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; emacs-build-system installs the Elisp package and generated
          ;; metadata, but upstream's GPL notice needs an explicit doc path.
          ;; The source screenshots are deliberately not part of the install.
          (add-after 'install 'install-license
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/emacs-org-popup-posframe")))
                (mkdir-p doc)
                (install-file "LICENSE" doc)))))))
    ;; Org is bundled with supported Emacs releases.  Posframe is required by
    ;; the installed library, so it must be propagated to user profiles.
    (propagated-inputs (list emacs-posframe))
    (home-page "https://github.com/A7R7/org-popup-posframe")
    (synopsis "Show Org popup buffers in posframes")
    (description
     "This Emacs package displays selected Org-mode popup buffers in
posframes.  It provides @code{org-popup-posframe-mode}, which advises Org's
capture, link, export, attachment, structure-template, tag, and todo popup
commands.  The package uses the user's graphical Emacs session at run time;
in batch or non-graphical Emacs, posframe support intentionally leaves popup
display as a no-op.")
    (license license:gpl3+)))
