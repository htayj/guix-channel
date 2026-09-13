;;; Immutable source snapshot for drbeefsupreme/ghostty-vexillomancy.

(define-module (tay packages drbeefsupreme ghostty-vexillomancy)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-ghostty-vexillomancy-source
  (package
    (name "drbeefsupreme-ghostty-vexillomancy-source")
    (version "20260313-1.c7de206")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/ghostty-vexillomancy")
             (commit "c7de206efd50d74a729a7b039bf24d1b15bbf839")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0phs91nyzp1vxbrxnafp7rlmndnikd8rp80v64qg321cpaxm3gjy"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  In particular, do
      ;; not rewrite shebangs, strip files, or add guessed license metadata.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/ghostty-vexillomancy"))
      #:phases
      #~(modify-phases %standard-phases
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
    (synopsis "Source snapshot of the ghostty-vexillomancy project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/ghostty-vexillomancy repository under
@file{share/drbeefsupreme/projects/ghostty-vexillomancy}.  It preserves the
upstream files as source data and does not claim to provide a standalone
application.  The upstream repository records no explicit license, so
redistribution permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/ghostty-vexillomancy")
    (license %no-permission-license)))
