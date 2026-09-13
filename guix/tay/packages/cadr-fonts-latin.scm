;;; CADR bitmap fonts with visible Basic Latin glyphs.

(define-module (tay packages cadr-fonts-latin)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

;; This module intentionally owns its complete definition.  In particular it
;; does not import (tay packages fonts), whose historical module also contains
;; a package with this name.  That keeps direct module loading unambiguous.
(define-public cadr-fonts-latin
  (let* ((version "0.1.2")
         (tag (string-append "v" version))
         (archive (string-append "CADR-fonts-latin-" tag ".tar.gz")))
    (package
      (name "cadr-fonts-latin")
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
           "14r0srddw0zmlzs26bzws85cncr081fz36ifpq1sl10jvyk1hr4w"))))
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
                  ;; The release checksum file covers every payload file,
                  ;; including the generated OTB conversions and metadata.
                  (invoke "sha256sum" "--check" "SHA256SUMS")
                  (unless (and
                           (= (length (find-files "fonts/unicode/source"
                                                  "\\.bdf$"))
                              118)
                           (= (length (find-files "fonts/unicode/runtime"
                                                  "\\.bdf$"))
                              42)
                           (= (length (find-files "fonts/otb/source"
                                                  "\\.otb$"))
                              118)
                           (= (length (find-files "fonts/otb/runtime"
                                                  "\\.otb$"))
                              42))
                    (error "CADR Latin release profile counts changed")))))
            (replace 'install
              (lambda _
                (let* ((font-root (string-append #$output
                                                 "/share/fonts/cadr-fonts/latin"))
                       (data-root (string-append #$output
                                                 "/share/cadr-fonts/latin"))
                       (doc-root (string-append #$output
                                                "/share/doc/cadr-fonts-latin")))
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
                              118)
                           (= (length (find-files
                                       (string-append font-root "/bdf/runtime")
                                       "\\.bdf$"))
                              42)
                           (= (length (find-files
                                       (string-append font-root "/otb/source")
                                       "\\.otb$"))
                              118)
                           (= (length (find-files
                                       (string-append font-root "/otb/runtime")
                                       "\\.otb$"))
                              42)
                           (not (file-exists?
                                 (string-append font-root "/raw"))))
                    (error "installed CADR Latin font assets changed"))))))))
      (synopsis "CADR bitmap fonts containing visible Basic Latin glyphs")
      (description
       "CADR Fonts recovers bitmap fonts from the MIT CADR source and System
46 runtime.  This package contains the complete source and runtime artifacts
that have at least one visible Basic Latin letter.  It installs ISO 10646-1
BDF fonts and deterministic OpenType Bitmap conversions while retaining the
two historical profiles as separate directories.")
      (home-page "https://github.com/htayj/CADR-fonts")
      (license license:bsd-3))))
