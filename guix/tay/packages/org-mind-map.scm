;;; Org graph export at the channel's requested post-0.4 revision.

(define-module (tay packages org-mind-map)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages graphviz)
  #:use-module (tay packages starred-s-z))

(define-public org-mind-map
  (package
    (inherit emacs-org-mind-map)
    ;; Guix's 0.4 is commit 477701b.  The channel's later fixed snapshot adds
    ;; local-image controls; keep this native variant distinct.
    (name "org-mind-map")
    (version "0.4-0.95347b2")
    (source
     (origin
       (inherit (package-source the-ted-org-mind-map-source))
       (modules '((guix build utils)))
       ;; Lena.png has no redistribution permission; example-8.png embeds it.
       ;; Conservatively omit raster demonstrations from the native source,
       ;; preserving Lisp, README, licenses, and text examples.  The snapshot
       ;; package keeps the unmodified upstream tree.
       (snippet
        #~(begin
            (for-each delete-file (find-files "examples" "\\.png$"))
            (delete-file "org-mind-map.el.pdf")))))
    (inputs (modify-inputs (package-inputs emacs-org-mind-map)
              (prepend graphviz)))
    (arguments
     (substitute-keyword-arguments (package-arguments emacs-org-mind-map)
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'bind-graphviz
              (lambda _
                ;; Graphviz 7's non-72 DPI SVG transform exceeds its viewBox.
                ;; Override only SVG; preserve bitmap resolution settings.
                (substitute* "org-mind-map.el"
                  (("org-mind-map-dot-command \" -T\"")
                   (string-append
                    "org-mind-map-dot-command\n"
                    "\t  (if (string= outputtype \"svg\")\n"
                    "\t      \" -Gdpi=72 -Gresolution=72\" \"\") \" -T\""))
                  (("org-mind-map-unflatten-command \"unflatten -l3\"")
                   (string-append "org-mind-map-unflatten-command \""
                                  #$(file-append graphviz "/bin/unflatten")
                                  " -l3\""))
                  (("org-mind-map-dot-command \"dot\"")
                   (string-append "org-mind-map-dot-command \""
                                  #$(file-append graphviz "/bin/dot") "\"")))))
            (add-after 'install 'install-documentation
              (lambda _
                (let ((doc (string-append #$output "/share/doc/org-mind-map")))
                  (install-file "LICENSE" doc)
                  (install-file "README.md" doc))))))))
    ;; Dash remains propagated by the inherited GNU Guix package.  Org ships
    ;; with Emacs; Graphviz is in the closure, not the user's PATH/profile.
    (home-page "https://github.com/the-ted/org-mind-map")
    (description
     "This package creates Graphviz directed graphs from Org files, including
heading hierarchies, tags, paragraph text, local PNG images, and optional
links between headings.  Whole-buffer, branch, and current-tree export commands
are available.  This variant supersedes Guix's older 0.4 source with the
channel's fixed post-release revision and binds Graphviz commands to store
paths.  Upstream's bundled demonstration images are not installed.")))