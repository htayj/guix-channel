;;; Immutable source snapshot for drbeefsupreme/flaghack-infinity.

(define-module (tay packages drbeefsupreme flaghack-infinity)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-flaghack-infinity-source
  (package
    (name "drbeefsupreme-flaghack-infinity-source")
    (version "20260220-1.4827c2d")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/flaghack-infinity")
             (commit "4827c2df1fb7975c1e64f12596fe2db12f5f3a1d")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "11ijr4f5mdc7ll7vidgn6a5gw43c9dw0hyf53yarp8xxq2p7gkvl"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/flaghack-infinity"))
      #:phases
      #~(modify-phases %standard-phases
          ;; Keep this package a byte-for-byte source snapshot.  These
          ;; application-oriented phases can rewrite source files or metadata.
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (delete 'patch-shebangs)
          (delete 'strip)
          (delete 'delete-info-dir-file)
          (delete 'patch-dot-desktop-files)
          (delete 'make-dynamic-linker-cache)
          (delete 'install-license-files)
          (delete 'reset-gzip-timestamps)
          (delete 'compress-documentation))))
    (synopsis "Source snapshot of the Flaghack Infinity archive")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/flaghack-infinity repository under
@file{share/drbeefsupreme/projects/flaghack-infinity}.  It preserves the
upstream files as source data and does not claim to provide a standalone
application.  The upstream repository records no explicit license, so
redistribution remains subject to a separate rights review.")
    (home-page "https://github.com/drbeefsupreme/flaghack-infinity")
    (license %no-permission-license)))
