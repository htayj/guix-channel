(define-module (tay packages manna-cadet)
  #:use-module (guix build-system gnu)
  #:use-module (guix build utils)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages xorg))

(define-public manna-cadet
  (package
    (name "manna-cadet")
    (version "20260809-1.e5f7e81")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/htayj/manna-cadet")
             (commit "e5f7e81cdb6e30a7735cdcab622ede29007e379b")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "01iszhj84pmhz3iyfii4plqyap24p816lm9xhihkyfvbd3h2j33m"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (delete 'build)
          (replace 'check
            (lambda* (#:key tests? inputs #:allow-other-keys)
              (when tests?
                ;; Exercise the converter against the primary layered layout.
                ;; PyYAML is an input rather than a bundled copy, so make its
                ;; site directory visible to this build-time check explicitly.
                (let* ((pyyaml (assoc-ref inputs "python-pyyaml"))
                       (site (car (find-files pyyaml "site-packages"
                                              #:directories? #t)))
                       (output "manna-cadet-check.yaml"))
                  (setenv "GUIX_PYTHONPATH" site)
                  (invoke "python3" "draw-kanata-keymap.py"
                          "--kanata"
                          "kanata/kinesis.advantage2.layered.kanata.kbd"
                          "--xkb" "xkb/symbols/spacecadet"
                          "--qmk-info-json" "kinesis.qmk.json"
                          "--output-yaml" output)
                  (unless (file-exists? output)
                    (error "keymap converter did not create YAML output"))
                  (delete-file output)))))
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (pyyaml (assoc-ref inputs "python-pyyaml"))
                     (xkbcomp (assoc-ref inputs "xkbcomp"))
                     (site (car (find-files pyyaml "site-packages"
                                            #:directories? #t)))
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec/manna-cadet"))
                     (data (string-append out "/share/manna-cadet"))
                     (doc (string-append out "/share/doc/manna-cadet-"
                                         #$version)))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-recursively "kanata" (string-append data "/kanata"))
                (copy-recursively "xkb" (string-append data "/xkb"))
                (copy-recursively "drawings"
                                  (string-append data "/drawings"))
                (install-file "kinesis.qmk.json" data)
                (install-file "draw-kanata-keymap.py" libexec)
                (install-file "reload-spacecadet-xkb.sh" libexec)
                (chmod (string-append libexec "/reload-spacecadet-xkb.sh") #o755)
                (call-with-output-file
                    (string-append bin "/manna-cadet-draw-keymap")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!/bin/sh~%export GUIX_PYTHONPATH=\"~a"
                             "${GUIX_PYTHONPATH:+:$GUIX_PYTHONPATH}\"~%"
                             "exec ~a \"$@\"~%")
                            site
                            (string-append libexec "/draw-kanata-keymap.py"))))
                (chmod (string-append bin "/manna-cadet-draw-keymap") #o755)
                ;; Keep the upstream helper as the implementation, but give
                ;; the installed command useful immutable defaults instead of
                ;; assuming that the repository was copied into $HOME.
                (call-with-output-file
                    (string-append bin "/manna-cadet-reload-spacecadet-xkb")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!/bin/sh~%export PATH=\"~a"
                             "${PATH:+:$PATH}\"~%"
                             "exec ~a \"${1:-~a}\" \"${2:-~a}\"~%")
                            (string-append xkbcomp "/bin")
                            (string-append libexec "/reload-spacecadet-xkb.sh")
                            (string-append data "/xkb/keymap/spacecadet.xkb")
                            (string-append data "/xkb"))))
                (chmod (string-append bin
                                      "/manna-cadet-reload-spacecadet-xkb")
                       #o755)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("LICENSE" "README.md"
                            "space-cadet-layered-mnemonics.md"))))))))
    (inputs (list bash-minimal python python-pyyaml xkbcomp))
    (synopsis "Space Cadet keyboard layouts and tools for Kinesis keyboards")
    (description
     "Manna Cadet provides Space Cadet-inspired Kanata layouts and XKB files
for Kinesis Advantage 2 and Advantage 360 keyboards.  It includes the
@command{manna-cadet-draw-keymap} converter for generating keymap-drawer YAML,
the @command{manna-cadet-reload-spacecadet-xkb} helper for applying the bundled
XKB keymap, layered-layout mnemonic notes, and generated reference drawings.")
    (home-page "https://github.com/htayj/manna-cadet")
    (license license:expat)))
