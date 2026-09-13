;;; GNU Guix package for brouhaha/tapeutils.

(define-module (tay packages tapeutils)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages larsbrinkhoff-t-z))

(define-public tapeutils
  (package
    (name "tapeutils")
    ;; Upstream's Makefile identifies this fixed revision as version 0.6.
    ;; Reuse the channel's reviewed codeload origin rather than adding a
    ;; second source fetch for the same immutable tree.
    (version "0.6-0.84a3a78")
    (source
     (origin
       (inherit (package-source larsbrinkhoff-tapeutils-source))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-after 'unpack 'make-uname-assignment-portable
            (lambda _
              ;; This BSD make shell assignment is the only incompatible
              ;; construct in the fixed upstream Makefile.
              (substitute* "Makefile"
                (("UNAME != uname") "UNAME := $(shell uname)"))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output "/share/doc/tapeutils")))
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each (lambda (program)
                            (install-file program bin))
                          '("tapecopy" "tapedump" "taperead" "tapewrite"
                            "t10backup" "read20" "tapex"))
                (install-file "COPYING" doc)))))))
    (synopsis "Read, write, and inspect magnetic-tape image files")
    (description
     "Tapeutils provides command-line programs for reading, writing, copying,
and inspecting magnetic tapes and Wilson-format tape image files.  A pathname
that does not name a device is handled as a local tape image, allowing the
programs to operate entirely offline.  The package installs no service,
network configuration, device rule, or runtime wrapper.")
    (home-page "https://github.com/brouhaha/tapeutils")
    (license license:gpl2)))
