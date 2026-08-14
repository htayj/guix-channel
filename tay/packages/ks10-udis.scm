;;; Installable KS10 microcode disassembler.

(define-module (tay packages ks10-udis)
  #:use-module (guix build-system gnu)
  #:use-module ((guix build utils)
                #:select (install-file invoke mkdir-p))
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages larsbrinkhoff-g-m))

(define-public ks10-udis
  (package
    (name "ks10-udis")
    ;; Keep the executable tied to the exact revision used by the channel's
    ;; immutable source-preservation package.
    (version (package-version larsbrinkhoff-ks10-udis-source))
    (source (package-source larsbrinkhoff-ks10-udis-source))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream Makefile has no configure script or check target.  Its
      ;; bundled ram.262 image provides a deterministic, offline smoke test.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "sh" "-c" "./udis < ram.262 > udis-smoke.out")
                (unless (file-exists? "udis-smoke.out")
                  (error "udis smoke test produced no output"))
                (when (zero? (stat:size (stat "udis-smoke.out")))
                  (error "udis smoke test produced empty output")))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (data (string-append #$output "/share/ks10-udis"))
                    (doc (string-append #$output "/share/doc/ks10-udis-"
                                        #$version)))
                (mkdir-p bin)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "udis" bin)
                ;; Keep the fixture available for reproducible offline use of
                ;; the installed command.
                (install-file "ram.262" data)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("README" "AUTHOR" "COPYING"))))))))
    (synopsis "KS10 microcode disassembler")
    (description
     "KS10 UDIS is a disassembler for KS10 microcode.  The package installs
the @command{udis} executable and the upstream @file{ram.262} microcode
fixture under @file{share/ks10-udis} for offline inspection and smoke tests.")
    (home-page "https://github.com/larsbrinkhoff/ks10-udis")
    (license license:gpl2)))
