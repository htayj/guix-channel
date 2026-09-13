;;; Immutable source snapshot for drbeefsupreme/test-repo.

(define-module (tay packages drbeefsupreme test-repo)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-test-repo-source
  (package
    (name "drbeefsupreme-test-repo-source")
    (version "20231027-1.920e995")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/test-repo")
             (commit "920e995843a2a77a7804ec3924b3261622e2d60b")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "156q3hhx6xi0kklzjk7kqbh4nax3hc90w4b4akrd9x60x3krkh54"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add license metadata, or otherwise mutate it.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/test-repo"))
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
    (synopsis "Source snapshot of the drbeefsupreme test-repo project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/test-repo repository under
@file{share/drbeefsupreme/projects/test-repo}.  It preserves the upstream
files as source data and does not claim to provide a standalone application.
The upstream repository contains no explicit license, so redistribution
permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/test-repo")
    (license %no-permission-license)))
