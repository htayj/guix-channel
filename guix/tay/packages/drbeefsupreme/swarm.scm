;;; Immutable source snapshot for drbeefsupreme/swarm.

(define-module (tay packages drbeefsupreme swarm)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-swarm-source
  (package
    (name "drbeefsupreme-swarm-source")
    (version "20211209-1.20c3b60")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/swarm")
             (commit "20c3b60f7cb6fffc2140bc9c9ccc0a66b20adcaf")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "06hxn98sxhwhflcbxlryk5l8xsyn65r1r7w0c8k4kmiikjsls52l"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/swarm"))
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
    (synopsis "Source snapshot of the drbeefsupreme swarm project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/swarm repository under
@file{share/drbeefsupreme/projects/swarm}.  It preserves the upstream files as
source data and does not claim to provide a standalone application.  The
upstream repository records no explicit license, so redistribution permission
is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/swarm")
    (license %no-permission-license)))
