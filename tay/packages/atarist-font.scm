;;; Installable Atari ST bitmap font.

(define-module (tay packages atarist-font)
  #:use-module (guix build-system font)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages starred-n-r))

(define-public atarist-font
  (package
    (name "atarist-font")
    (version (package-version ntwk-atarist-font-source))
    ;; Reuse the already pinned, immutable source snapshot rather than
    ;; introducing a second origin or hash for the same upstream archive.
    (source (package-source ntwk-atarist-font-source))
    (build-system font-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'fix-glyph-count
            (lambda _
              ;; The pinned BDF contains 322 glyph records, but its header
              ;; incorrectly declares 324.  Correct only that declaration;
              ;; no glyph data is added or removed.
              (let ((bdf (car (find-files "." "^atarist-normal\\.bdf$"))))
                (substitute* bdf
                  (("CHARS 324") "CHARS 322")))))
          (add-before 'install 'check-and-build-pcf
            (lambda _
              ;; Besides producing the optional format documented upstream,
              ;; bdftopcf rejects malformed BDF input and validates the
              ;; corrected installed font source.
              (let* ((bdf (car (find-files "." "^atarist-normal\\.bdf$")))
                     (pcf (string-append (dirname bdf) "/atarist-normal.pcf")))
                (invoke "bdftopcf" "-o" pcf bdf)))))))
    (native-inputs (list bdftopcf))
    (home-page "https://github.com/ntwk/atarist-font")
    (synopsis "Atari ST bitmap font")
    (description
     "Atarist is an 8x16 monospaced bitmap font based on the high-resolution
system font of the Atari ST home computer.  This package includes the
Unicode-encoded BDF font, extended with Cyrillic glyphs.")
    (license license:bsd-3)))
