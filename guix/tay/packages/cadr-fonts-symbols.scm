;;; CADR specialty bitmap fonts without visible Basic Latin letters.

(define-module (tay packages cadr-fonts-symbols)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

;; This module intentionally owns its complete definition.  In particular it
;; does not import (tay packages fonts), whose historical module also contains
;; a package with this name.  That keeps direct module loading unambiguous.
(define-public cadr-fonts-symbols
  (let* ((version "0.1.2")
         (tag (string-append "v" version))
         (archive (string-append "CADR-fonts-symbols-" tag ".tar.gz")))
    (package
      (name "cadr-fonts-symbols")
      (version version)
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://github.com/htayj/CADR-fonts/releases/download/"
               tag "/" archive))
         ;; Verified with `guix download` against the immutable GitHub
         ;; release asset.
         (sha256
          (base32
           "0y8sij4wpka4vl8y88k7lk0hrir9ihm0is0i0r7f77691yn0cgl5"))))
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
                  ;; This checksum gate covers the generated BDF and OTB
                  ;; files.  It therefore verifies the release's deterministic
                  ;; BDF-to-OTB conversion without rebuilding it with a host
                  ;; toolchain of an unspecified version.
                  (invoke "sha256sum" "--check" "SHA256SUMS")
                  (unless (and
                           (= (length (find-files "fonts/unicode/source"
                                                  "\\.bdf$"))
                              33)
                           (= (length (find-files "fonts/unicode/runtime"
                                                  "\\.bdf$"))
                              7)
                           (= (length (find-files "fonts/otb/source"
                                                  "\\.otb$"))
                              33)
                           (= (length (find-files "fonts/otb/runtime"
                                                  "\\.otb$"))
                              7))
                    (error "CADR symbols release profile counts changed")))))
            (replace 'install
              (lambda _
                (let* ((font-root (string-append #$output
                                                 "/share/fonts/cadr-fonts/symbols"))
                       (data-root (string-append #$output
                                                 "/share/cadr-fonts/symbols"))
                       (doc-root (string-append #$output
                                                "/share/doc/cadr-fonts-symbols")))
                  ;; Install only Unicode BDFs and their deterministic OTB
                  ;; conversions; raw CADR-code BDFs remain provenance-only.
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
                  (unless (and
                           (= (length (find-files
                                       (string-append font-root "/bdf/source")
                                       "\\.bdf$"))
                              33)
                           (= (length (find-files
                                       (string-append font-root "/bdf/runtime")
                                       "\\.bdf$"))
                              7)
                           (= (length (find-files
                                       (string-append font-root "/otb/source")
                                       "\\.otb$"))
                              33)
                           (= (length (find-files
                                       (string-append font-root "/otb/runtime")
                                       "\\.otb$"))
                              7)
                           (not (file-exists?
                                 (string-append font-root "/raw"))))
                    (error "installed CADR symbols font assets changed"))))))))
      (synopsis "CADR specialty bitmap fonts without visible Basic Latin letters")
      (description
       "CADR Fonts recovers bitmap fonts from the MIT CADR source and System
46 runtime.  This package contains the complementary specialty set, including
drawing, symbol, APL, Cyrillic, Greek, mathematical, music, and sprite
families.  It installs ISO 10646-1 BDF fonts and deterministic OpenType Bitmap
conversions while retaining the two historical profiles as separate
directories.")
      (home-page "https://github.com/htayj/CADR-fonts")
      (license license:bsd-3))))
