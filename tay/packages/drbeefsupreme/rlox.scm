;;; Immutable source snapshot for drbeefsupreme/rlox.

(define-module (tay packages drbeefsupreme rlox)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-rlox-source
  (package
    (name "drbeefsupreme-rlox-source")
    (version "20230427-1.257d07e")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/rlox")
             (commit "257d07ec0b8a245d729aee7afb7dc857ef2f5c67")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0ik2iaij2wyyhxdadgk273lhispk3p504scbrbgkqgprvl8r7wqz"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/rlox"))
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
    (synopsis "Source snapshot of the drbeefsupreme rlox project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/rlox repository under
@file{share/drbeefsupreme/projects/rlox}.  It preserves the upstream files as
source data and does not claim to provide a standalone application.  The
upstream repository records no explicit license, so redistribution permission
is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/rlox")
    (license %no-permission-license)))
