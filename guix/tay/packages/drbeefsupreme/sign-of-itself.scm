;;; Immutable source snapshot for drbeefsupreme/sign-of-itself.

(define-module (tay packages drbeefsupreme sign-of-itself)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-sign-of-itself-source
  (package
    (name "drbeefsupreme-sign-of-itself-source")
    (version "20260702-1.55821ee")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/sign-of-itself")
             (commit "55821ee9d606e111091f697327fbb8d677155331")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1q44c5ybxlkw3gixxi6ifr8cdyhilrnmlfxka38qcd9kk8qcms7n"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/sign-of-itself"))
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
    (synopsis "Source snapshot of the sign-of-itself project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/sign-of-itself repository under
@file{share/drbeefsupreme/projects/sign-of-itself}.  It preserves the upstream
files as source data and does not claim to provide a standalone application.
The upstream repository records no explicit license, so redistribution
permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/sign-of-itself")
    (license %no-permission-license)))
