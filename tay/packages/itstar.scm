;;; GNU Guix package for PDP-10/itstar.

(define-module (tay packages itstar)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages compression)
  #:use-module (tay packages pdp10-g-m)
  #:use-module ((guix licenses) #:prefix license:))

(define-public itstar
  (package
    (name "itstar")
    ;; The upstream README identifies this revision as V1.10; it has no
    ;; release tag, so retain the pinned source revision in the version.
    (version "1.10-0.b709cd8")
    (source (package-source pdp10-itstar-source))
    (build-system gnu-build-system)
    (inputs (list gzip))
    (arguments
     (list
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'make-portable
            (lambda _
              ;; The upstream Makefile uses BSD make's `!=' assignment and
              ;; hard-codes cc.  Neither is necessary for its local build.
              (substitute* "Makefile"
                (("UNAME != uname") "UNAME := Linux")
                (("cc") "$(CC)")
                (("strip itstar") "true"))
              ;; Guix deliberately delivers an offline, local-image tool.
              ;; The legacy host:device rmt path uses rexec(3), which is not
              ;; available on current GNU libc and would be unsafe here.
              (substitute* "tapeio.c"
                (("else .*rmt.*remote host.*")
                 (string-append
                  "else {\n\t\tfprintf(stderr, \"?Remote rmt tape paths "
                  "are unsupported in this build\\n\");\n\t\texit(1);\n#if 0"))
                (("free\\(host\\);") "free(host);\n#endif"))
              ;; zopen uses execve with an empty environment for compressed
              ;; files.  Invoke gzip itself, rather than its PATH-dependent
              ;; zcat wrapper, at its declared absolute store path.
              (substitute* "zopen.c"
                (("/bin/zcat") (string-append #$gzip "/bin/gzip"))
                (("\"zcat\", NULL") "\"gzip\", \"-d\", \"-c\", NULL"))))
          (delete 'check)
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output "/share/doc/itstar-"
                                        #$version)))
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "itstar" bin)
                (for-each (lambda (file) (install-file file doc))
                          '("README" "itstar.doc" "COPYING"
                            "Relicensing Permission.txt"))))))))
    (synopsis "Create, list, and extract PDP-10 ITS DUMP tape images")
    (description
     "ITSTAR creates, lists, and extracts local PDP-10 ITS DUMP tape image
files.  This package supports local files and compressed @file{.Z} input;
remote rmt tape paths and physical tape-device operation are intentionally
outside its offline, reproducible delivery scope.")
    (home-page "https://github.com/PDP-10/itstar")
    (license license:gpl3+)))
