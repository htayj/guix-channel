;;; Immutable source snapshot for drbeefsupreme/flags.

(define-module (tay packages drbeefsupreme flags)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-flags-source
  (package
    (name "drbeefsupreme-flags-source")
    (version "20260205-1.96b1df8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/flags")
             (commit "96b1df80bf75b28005330eaf67d427bf06d5b956")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "060rjgsip5ynz2z4giazc89yzllw789z2w2j0zlg6lqmmzvddl6b"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/flags"))
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
    (synopsis "Source snapshot of the drbeefsupreme flags project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/flags repository under
@file{share/drbeefsupreme/projects/flags}.  It preserves the upstream files
as source data and does not claim to provide a standalone application.  The
upstream repository records no explicit license, so redistribution permission
is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/flags")
    (license %no-permission-license)))
