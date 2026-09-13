;;; Immutable source snapshot for drbeefsupreme/qyron-tui.

(define-module (tay packages drbeefsupreme qyron-tui)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-qyron-tui-source
  (package
    (name "drbeefsupreme-qyron-tui-source")
    (version "20231017-1.42d8596")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/qyron-tui")
             (commit "42d859691fe314e6a8ca7983ec83dc9fe09d755c")
             (recursive? #f)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1lg8pjigda6d2kxi3yrcdgva9f38iyk4cnxch8lzc7bnpa9zp77h"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  In particular, the
      ;; Cargo manifests' local-path declarations remain source data; this
      ;; package does not invent or resolve their absent sibling projects.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/qyron-tui"))
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
    (synopsis "Source snapshot of the drbeefsupreme qyron-tui project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/qyron-tui repository under
@file{share/drbeefsupreme/projects/qyron-tui}.  It preserves the upstream
files as source data and does not claim to provide a standalone application.
The upstream repository records no explicit license, so redistribution
permission is not granted by this package definition.  The Cargo manifests
retain their original local-path declarations, including references to
projects outside this repository.")
    (home-page "https://github.com/drbeefsupreme/qyron-tui")
    (license %no-permission-license)))
