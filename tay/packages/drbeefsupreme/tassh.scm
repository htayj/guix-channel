;;; Immutable source snapshot for drbeefsupreme/tassh.

(define-module (tay packages drbeefsupreme tassh)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public drbeefsupreme-tassh-source
  (package
    (name "drbeefsupreme-tassh-source")
    (version "20260228-1.672569a")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/tassh")
             (commit "672569a55e6f2a0ae4274103a99b8b9abac87f4d")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1r14hx37jz04cvjljc8vy063qy10sy8lmlaxsn2ckmxafl6qhw7y"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add license metadata, or otherwise mutate it.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/tassh"))
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
    (synopsis "Source snapshot of the drbeefsupreme tassh project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/tassh repository under
@file{share/drbeefsupreme/projects/tassh}.  It preserves the upstream files as
source data and does not claim to provide a standalone application.  The
upstream repository identifies its code as MIT licensed.")
    (home-page "https://github.com/drbeefsupreme/tassh")
    (license license:expat)))
