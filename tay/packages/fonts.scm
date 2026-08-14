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

(define (cadr-fonts-package group
                            hash
                            source-count
                            runtime-count
                            synopsis
                            description)
  (let* ((version "0.1.2")
         (tag (string-append "v" version))
         (archive (string-append "CADR-fonts-" group "-" tag ".tar.gz")))
    (package
      (name (string-append "cadr-fonts-" group))
      (version version)
      (source
       (release-origin "CADR-fonts" tag archive hash))
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
                (let* ((font-root (string-append #$output
                                                 "/share/fonts/cadr-fonts/"
                                                 #$group))
                       (data-root (string-append #$output "/share/cadr-fonts/"
                                                 #$group))
                       (doc-root (string-append #$output
                                                "/share/doc/cadr-fonts-"
                                                #$group)))
                  (copy-recursively "fonts/unicode/source"
                                    (string-append font-root "/bdf/source"))
                  (copy-recursively "fonts/unicode/runtime"
                                    (string-append font-root "/bdf/runtime"))
                  (copy-recursively "fonts/otb/source"
                                    (string-append font-root "/otb/source"))
                  (copy-recursively "fonts/otb/runtime"
                                    (string-append font-root "/otb/runtime"))
                  (copy-recursively "metadata"
                                    (string-append data-root "/metadata"))
                  (for-each (lambda (file)
                              (install-file file data-root))
                            '("RELEASE-MANIFEST.json" "SHA256SUMS"))
                  (for-each (lambda (file)
                              (install-file file doc-root))
                            '("LICENSE.project" "LICENSE.source"
                              "README.release.md"))
                  (unless (and (= (length (find-files (string-append font-root
                                                       "/bdf/source")
                                                      "\\.bdf$"))
                                  #$source-count)
                               (= (length (find-files (string-append font-root
                                                       "/bdf/runtime")
                                                      "\\.bdf$"))
                                  #$runtime-count))
                    (error "installed CADR font profile counts changed"))))))))
      (synopsis synopsis)
      (description description)
      (home-page "https://github.com/htayj/CADR-fonts")
      (license license:bsd-3))))

(define-public cadr-fonts-latin
  (cadr-fonts-package "latin"
   "14r0srddw0zmlzs26bzws85cncr081fz36ifpq1sl10jvyk1hr4w"
   118
   42
   "CADR bitmap fonts containing visible Basic Latin glyphs"
   "CADR Fonts recovers bitmap fonts from the MIT CADR source and System 46
runtime.  This package contains the complete source and runtime artifacts that
have at least one visible Basic Latin letter.  It installs ISO 10646-1 BDF
fonts and display-equivalent OTB wrappers while retaining the two historical
profiles as separate directories."))

(define-public cadr-fonts-symbols
  (cadr-fonts-package "symbols"
   "0y8sij4wpka4vl8y88k7lk0hrir9ihm0is0i0r7f77691yn0cgl5"
   33
   7
   "CADR specialty bitmap fonts without visible Basic Latin letters"
   "CADR Fonts recovers bitmap fonts from the MIT CADR source and System 46
runtime.  This package contains the complementary specialty set, including
drawing, symbol, APL, Cyrillic, Greek, mathematical, music, and sprite
families.  It installs ISO 10646-1 BDF fonts and display-equivalent OTB
wrappers while retaining the two historical profiles as separate
directories."))

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
  (let* ((version "0.1.1")
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
                      "https://github.com/htayj/genera-fonts/blob/v0.1.1/NOTICE.md"
                      "Typeface redistribution basis; not a license grant."))))))

(define-public genera-fonts-latin
  (genera-fonts-package "latin"
   "1kxk2p4x15zj8k0wsjnlxpkb7c8mywy2v8yla6kqnhbcxnlzlb57"
   "Genera bitmap fonts containing visible Basic Latin glyphs"
   "This package contains complete Genera 8.5 resident fonts selected by
visible Basic Latin glyph content.  It installs ISO 10646-1 BDF typefaces and
display-equivalent OTB conversions, with required provenance and notices."))

(define-public genera-fonts-symbols
  (genera-fonts-package "symbols"
   "1s46s7pmw1v3cdbzwvp6v1nhkrzv987gryp7vvlvvjif5959i45l"
   "Genera specialty bitmap fonts without visible Basic Latin glyphs"
   "This package contains the complementary Genera 8.5 resident specialty
fonts without visible Basic Latin letters.  It installs ISO 10646-1 BDF
typefaces and display-equivalent OTB conversions, with required provenance and
notices."))
