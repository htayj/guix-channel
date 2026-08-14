;;; Immutable source snapshot of drbeefsupreme/dotfiles.

(define-module (tay packages drbeefsupreme dotfiles)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public drbeefsupreme-dotfiles-source
  (package
    (name "drbeefsupreme-dotfiles-source")
    (version "20230327-1.2cd1262")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/dotfiles")
             (commit "2cd12623a39280c6126d569d9298ab038ddec611")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "17fsdm32y693phxs3dhb9s5m91svdrr06vrl87fphy3zr9v71idj"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Install the complete checkout as data.  Disable every standard copy
      ;; phase that rewrites source bytes, permissions, or metadata.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/dotfiles/"))
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
    (synopsis "Source snapshot of the drbeefsupreme dotfiles project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme dotfiles repository under
@file{share/drbeefsupreme/projects/dotfiles}.  The snapshot is intended for
development and preservation; it does not provide an activation mechanism.
The upstream repository contains no explicit license, so redistribution
permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/dotfiles")
    (license
     (license:non-copyleft "https://choosealicense.com/no-permission/"
                           (string-append
                            "No explicit license was found; redistribution "
                            "permission is not granted.")))))
