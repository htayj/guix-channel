;;; Immutable source snapshot for drbeefsupreme/flaghack3.

(define-module (tay packages drbeefsupreme flaghack3)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-flaghack3-source
  (package
    (name "drbeefsupreme-flaghack3-source")
    (version "20260218-1.f5fa683")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/flaghack3")
             (commit "f5fa6835434e40d6e0ead753cfb8978cf4b02bda")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "18a5s5v5105jnry3qbj33r5x4wlgkd6w60ww6cws961v0awi4hx6"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  In particular, do
      ;; not rewrite shebangs, strip files, or add guessed license metadata.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/flaghack3"))
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
    (synopsis "Source snapshot of the Flaghack3 game")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/flaghack3 repository under
@file{share/drbeefsupreme/projects/flaghack3}.  It preserves the upstream
files as source data and does not claim to provide a standalone application.
The upstream repository records no explicit license, so redistribution
permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/flaghack3")
    (license %no-permission-license)))
