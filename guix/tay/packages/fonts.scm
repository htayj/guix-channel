;;; Installable font releases published by htayj projects.

(define-module (tay packages fonts)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define (release-origin repository tag file hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/htayj/"
                        repository
                        "/releases/download/"
                        tag
                        "/"
                        file))
    (sha256 (base32 hash))))

(define-public dec-fonts
  (let* ((version "0.1.0-alpha.2")
         (tag (string-append "v" version))
         (archive (string-append "DEC-Fonts-" tag ".tar.gz")))
    (package
      (name "dec-fonts")
      (version version)
      (source
       (release-origin "DEC-Fonts" tag archive
                       "11byrh7jlkwjgajslxxjgi1aphifkzgfn3gfr71179nh99gdcsv4"))
      (build-system gnu-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (delete 'bootstrap)
            (delete 'configure)
            (delete 'build)
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (unless (and (= (length (find-files "dist/fonts/bdf"
                                                      "\\.bdf$")) 12)
                               (= (length (find-files "dist/fonts/otb"
                                                      "\\.otb$")) 3)
                               (= (length (find-files "dist/fonts/psf"
                                                      "\\.psf$")) 3))
                    (error "DEC font release profile counts changed")))))
            (replace 'install
              (lambda _
                (let ((font-root (string-append #$output
                                                "/share/fonts/dec-fonts"))
                      (console-root (string-append #$output
                                     "/share/consolefonts/dec-fonts"))
                      (data-root (string-append #$output "/share/dec-fonts"))
                      (doc-root (string-append #$output "/share/doc/dec-fonts")))
                  (copy-recursively "dist/fonts/bdf"
                                    (string-append font-root "/bdf"))
                  (copy-recursively "dist/fonts/otb"
                                    (string-append font-root "/otb"))
                  (copy-recursively "dist/fonts/psf" console-root)
                  (install-file "dist/dec.set" data-root)
                  (for-each (lambda (file)
                              (install-file file doc-root))
                            '("LICENSE" "README.org" "THIRD_PARTY_NOTICES.md"))))))))
      (synopsis "DEC VT220 bitmap fonts")
      (description
       "DEC Fonts provides bitmap fonts generated from a DEC VT220 ROM
recreation.  The package includes BDF and OTB fonts for Fontconfig and X core
font users, plus PSF fonts for the Linux console.")
      (home-page "https://github.com/htayj/DEC-Fonts")
      (license license:expat))))

(define (genera-fonts-package group hash synopsis description)
  (let* ((version "0.1.3")
         (tag (string-append "v" version))
         (archive (string-append "Genera-fonts-" group "-" tag ".tar.gz")))
    (package
      (name (string-append "genera-fonts-" group))
      (version version)
      (source
       (release-origin "genera-fonts" tag archive hash))
      (build-system gnu-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (delete 'bootstrap)
            (delete 'configure)
            (delete 'build)
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (invoke "sha256sum" "--check" "SHA256SUMS"))))
            (replace 'install
              (lambda _
                (let ((font-root (string-append #$output
                                                "/share/fonts/genera-fonts/"
                                                #$group))
                      (data-root (string-append #$output
                                                "/share/genera-fonts/"
                                                #$group))
                      (doc-root (string-append #$output
                                               "/share/doc/genera-fonts-"
                                               #$group)))
                  (copy-recursively "fonts" font-root)
                  (copy-recursively "metadata"
                                    (string-append data-root "/metadata"))
                  (for-each (lambda (file)
                              (install-file file data-root))
                            '("RELEASE-MANIFEST.json" "SHA256SUMS"))
                  (for-each (lambda (file)
                              (install-file file doc-root))
                            '("LICENSE" "NOTICE.md" "README.release.md"))))))))
      (synopsis synopsis)
      (description description)
      (home-page "https://github.com/htayj/genera-fonts")
      (license (list license:bsd-3
                     (license:non-copyleft
                      "https://github.com/htayj/genera-fonts/blob/v0.1.3/NOTICE.md"
                      "Typeface redistribution basis; not a license grant."))))))

(define-public genera-fonts-latin
  (genera-fonts-package "latin"
   "0rxfq8a6hr68axbcv008s3zx3imqigj0f6s8q4fdchrry0mzh0bh"
   "Genera bitmap fonts containing visible Basic Latin glyphs"
   "This package contains complete Genera 8.5 resident fonts selected by
visible Basic Latin glyph content.  It installs ISO 10646-1 BDF typefaces and
display-equivalent OTB conversions, with required provenance and notices."))

(define-public genera-fonts-symbols
  (genera-fonts-package "symbols"
   "0xpjhsmd7pw2flwaj7bwy178maq99l9z9b7xwy4xbgkhp8w1jzp7"
   "Genera specialty bitmap fonts without visible Basic Latin glyphs"
   "This package contains the complementary Genera 8.5 resident specialty
fonts without visible Basic Latin letters.  It installs ISO 10646-1 BDF
typefaces and display-equivalent OTB conversions, with required provenance and
notices."))
