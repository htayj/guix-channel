;;; GNU Guix package for aap/pdp11 host CPU emulators.

(define-module (tay packages pdp11)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (tay packages larsbrinkhoff-n-s)
  #:use-module ((guix licenses) #:prefix license:))

(define-public pdp11
  (package
    (name "pdp11")
    (version "0-5b5b734")
    (source (package-source larsbrinkhoff-pdp11-source))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream makefile has no CC assignment.  Always pass the Guix
      ;; compiler explicitly, including to the selected custom build phase.
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          ;; The upstream default also builds network/display console targets
          ;; that require the deliberately unpopulated lodepng submodule.
          (replace 'build
            (lambda _
              (invoke "make" (string-append "CC=" #$(cc-for-target))
                      "pdp1105" "pdp1120" "pdp1140" "pdp1145")))
          (delete 'check)
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output "/share/doc/pdp11-"
                                        #$version)))
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each (lambda (program) (install-file program bin))
                          '("pdp1105" "pdp1120" "pdp1140" "pdp1145"))
                (install-file "LICENSE" doc)))))))
    (synopsis "Host emulators for selected PDP-11 CPU models")
    (description
     "PDP11 provides native host emulators for the PDP-11/05, PDP-11/20,
PDP-11/40, and PDP-11/45.  It intentionally excludes the upstream network
and graphical console targets, disk images, and mutable runtime fixtures.")
    (home-page "https://github.com/aap/pdp11")
    (license license:expat)))
