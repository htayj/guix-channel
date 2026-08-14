;;; GNU Guix package for larsbrinkhoff/image-tape.

(define-module (tay packages image-tape)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (tay packages larsbrinkhoff-g-m))

(define-public image-tape
  (package
    (name "image-tape")
    (version (package-version larsbrinkhoff-image-tape-source))
    (source
     (origin
       (inherit (package-source larsbrinkhoff-image-tape-source))
       (patches
        (search-patches "tay/packages/patches/image-tape-safe-output.patch"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                (install-file "image-tape"
                             (string-append out "/bin"))))))))
    (synopsis "Read magnetic tape devices into image files")
    (description
     "Image-tape reads records from a magnetic tape device and writes them to
an image file using the upstream record framing format.  It accepts a tape
device and an optional output path, and is intended for offline preservation
of data from compatible tape hardware.  The upstream Makefile supplies no
test or install targets, so Guix installs the program after its normal C
build and leaves hardware-dependent operation to the user.")
    (home-page "https://github.com/larsbrinkhoff/image-tape")
    (license (package-license larsbrinkhoff-image-tape-source))))
