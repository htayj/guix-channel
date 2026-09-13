;;; Immutable source snapshot for drbeefsupreme/qyron.

(define-module (tay packages drbeefsupreme qyron)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-qyron-source
  (package
    (name "drbeefsupreme-qyron-source")
    (version "20230304-1.0615830")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/qyron")
             (commit "061583026431b28db7379c08481c66b27a4b4caa")
             (recursive? #f)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0p4n9vylc9nvwlr691bknj45shdwjgw8i6qjka3pny493402h64w"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/qyron"))
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
    (synopsis "Source snapshot of the drbeefsupreme qyron project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/qyron repository under
@file{share/drbeefsupreme/projects/qyron}.  It preserves the upstream files
as source data and does not claim to provide a standalone application.  The
upstream repository records no explicit license, so redistribution permission
is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/qyron")
    (license %no-permission-license)))
