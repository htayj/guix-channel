;;; Immutable source snapshot for drbeefsupreme/qyron-teensy.

(define-module (tay packages drbeefsupreme qyron-teensy)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define-public drbeefsupreme-qyron-teensy-source
  (package
    (name "drbeefsupreme-qyron-teensy-source")
    (version "20241014-1.ae98439")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/qyron-teensy")
             (commit "ae98439139ab80404b0d4620f2ceb392b7515fe0")
             (recursive? #f)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0r73fxfni9ssqvqz8g91faw31fq0q4hvb3c619gsqjxx9qw20rxg"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Preserve the fetched checkout's source bytes.  Do not rewrite
      ;; shebangs, strip files, add guessed license metadata, or otherwise
      ;; mutate this source snapshot.
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/qyron-teensy"))
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
    (synopsis "Source snapshot of the drbeefsupreme qyron-teensy project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/qyron-teensy repository under
@file{share/drbeefsupreme/projects/qyron-teensy}.  It preserves the upstream
files as source data and does not claim to provide a standalone application.
The upstream repository records no explicit license, so redistribution
permission is not granted by this package definition.")
    (home-page "https://github.com/drbeefsupreme/qyron-teensy")
    (license %no-permission-license)))
