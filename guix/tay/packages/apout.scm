;;; GNU Guix package for DoctorWkt/Apout.

(define-module (tay packages apout)
  #:use-module (tay packages larsbrinkhoff-a-f)
  #:use-module (guix build-system gnu)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public apout
  (package
    (name "apout")
    ;; Apout upstream calls the pinned tree 2.4.0, but the channel's
    ;; immutable source snapshot gives the revision-based package version.
    (version (package-version larsbrinkhoff-apout-source))
    (source (package-source larsbrinkhoff-apout-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;Upstream has no check target.
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              "APOUT_OPTIONS=-DEMU211 -DEMUV1 -DNATIVES -DAPOUT_DONT_ASSUME_ROOT")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'fix-v1-emulation-option
            (lambda _
              ;; This is a spelling error in the default Makefile option.
              ;; The source consistently tests EMUV1, not EMUv1.
              (substitute* "Makefile"
                (("-DEMUv1") "-DEMUV1"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "apout" make-flags)))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (man (string-append #$output "/share/man/man1"))
                    (doc (string-append #$output
                                        "/share/doc/apout-0-bd9af21")))
                (mkdir-p bin)
                (mkdir-p man)
                (mkdir-p doc)
                (install-file "apout" bin)
                (install-file "apout.1" man)
                (for-each (lambda (file) (install-file file doc))
                          '("README" "CHANGES" "LIMITATIONS" "TODO"
                            "LICENSE" "COPYRIGHT"))))))))
    (synopsis "Run PDP-11 Unix a.out binaries on a host system")
    (description
     "Apout emulates PDP-11 user-mode instructions and translates Unix
system calls for V1, V2, V5, V6, V7, 2.9BSD, and 2.11BSD a.out programs.
Set @code{APOUT_ROOT} to a user-owned guest root before use; an unset value is
rejected.  @code{APOUT_UNIX_VERSION} remains available for ambiguous 0407
a.out files.

Apout's native-program and trap support calls host filesystem, process, and
socket APIs directly.  @code{APOUT_ROOT} is a pathname prefix, not a security
sandbox, and this package does not provide network isolation or a guest
filesystem image.")
    (home-page "https://github.com/DoctorWkt/Apout")
    (license license:gpl3)))
