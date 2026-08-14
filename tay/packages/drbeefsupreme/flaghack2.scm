;;; Guix source snapshot for drbeefsupreme/flaghack2.

(define-module (tay packages drbeefsupreme flaghack2)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:))

(define-public drbeefsupreme-flaghack2-source
  (package
    (name "drbeefsupreme-flaghack2-source")
    (version "20260216-1.de4fe8f")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/flaghack2")
             (commit "de4fe8f6773cd726c95e8ca62c4ab00a26cdb82d")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1w7khx6hhb593bcdkskakxf0cz9hzibwpq7z8wh8xj5p3pjbz3c7"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Keep the installed tree byte-for-byte identical to the fetched
      ;; checkout.  In particular, do not rewrite shebangs, strip files, add
      ;; guessed license files, or otherwise mutate this source snapshot.
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
          (delete 'compress-documentation))
      #:install-plan
      #~'(("." "share/drbeefsupreme/projects/flaghack2"))))
    (synopsis "Source snapshot of the Flaghack2 game")
    (description
     "This package preserves an immutable source snapshot of the Flaghack2
game, including its Rust sources and image assets, under
@file{share/drbeefsupreme/projects/flaghack2}.  The upstream repository does
not record an explicit license, so redistribution permission is not granted.")
    (home-page "https://github.com/drbeefsupreme/flaghack2")
    (license
     (license:non-copyleft
      "https://choosealicense.com/no-permission/"
      "No explicit license was found; redistribution permission is not granted."))))
