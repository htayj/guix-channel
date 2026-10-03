;;; Source-built Kraken with explicitly binary-assisted CPU dependencies.
(define-module (tay packages kraken)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix search-paths)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages python)
  #:use-module (gnu packages compression)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-i-m)
  #:use-module (tay packages kraken-wheels))

(define %installer
  (local-file (search-tay-package-file "kraken-install-wheels.py")))

(define %provenance
  (local-file (search-tay-package-file "kraken-wheel-provenance.json")))

(define %asset-provenance
  (local-file (search-tay-package-file "kraken-asset-provenance.json")))

(define-public kraken-python-runtime
  (package
    (name "kraken-python-runtime")
    (version "7.1")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (setenv "PATH" (string-append #$patchelf "/bin:" #$coreutils "/bin"))
          (apply invoke
                 #$(file-append python "/bin/python3") #$%installer
                 #$output #$(file-append python "/bin/python3")
                 #$(file-append glibc "/lib/ld-linux-x86-64.so.2")
                 (string-append #$(file-append glibc "/lib") ":"
                                (string-append #$gcc:lib "/lib") ":"
                                #$(file-append zlib "/lib"))
                 (list #$@%kraken-wheels))
          (install-file #$%provenance
                        (string-append #$output "/share/doc/kraken-python-runtime")))))
    (native-search-paths
     (list (search-path-specification
            (variable "GUIX_PYTHONPATH")
            (files '("lib/python3.12/site-packages")))))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/mittagessen/kraken")
    (synopsis "Pinned CPU Python dependencies for Kraken")
    (description
     "This dependency closure installs official CPython 3.12 wheels from PyPI
and the PyTorch CPU repository, with hashes fixed in the channel.  It does not
rebuild their native extensions from source.  The complete bundled license and
third-party notice trees are preserved alongside a provenance inventory.
No CUDA dependencies or recognition-model downloads are included.")
    ;; Individual notices, including bundled BLAS/runtime dependencies, remain
    ;; in each dist-info license tree; the provenance inventory is not a relicensing.
    (license (list license:asl2.0 license:bsd-3 license:bsd-2 license:expat
                   license:psfl license:mpl2.0 license:cc0 license:zlib
                   license:wtfpl2 license:lgpl2.1+ license:gpl3+))))

(define-public kraken
  (package
    (name "kraken")
    (version "7.1")
    ;; This is a codeload archive hash, not a Git NAR hash.
    (source (package-source mittagessen-kraken-source))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:test-flags #~(list "tests/test_codec.py" "tests/test_binarization.py"
                           "tests/test_container.py")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'set-pinned-version
            (lambda _
              ;; Archives have no Git metadata; versioningit falls back to
              ;; the verified release tag for this exact commit.
              (substitute* "pyproject.toml"
                (("\\[tool.versioningit\\]")
                 "[tool.versioningit]\ndefault-version = \"7.1\""))
              (setenv "HOME" (getcwd))
              (setenv "OMP_NUM_THREADS" "1")))
          (add-after 'install 'install-offline-recognition-fixture
            (lambda _
              (let ((directory (string-append #$output "/share/kraken/fixtures")))
                (for-each (lambda (file)
                            (install-file (string-append "tests/resources/" file)
                                          directory))
                          '("overfit.mlmodel" "000236.png" "000236.gt.txt"))
                (copy-file #$%asset-provenance
                           (string-append directory "/provenance.json"))
                (install-file "LICENSE" directory)))))))
    ;; Backend and check tools reside in the pinned wheel closure, which
    ;; includes hatchling/versioningit, build, installer and pytest.  Runtime
    ;; packages are deliberately not taken from a mismatched host profile.
    (native-inputs (list kraken-python-runtime))
    (propagated-inputs (list kraken-python-runtime))
    (supported-systems '("x86_64-linux"))
    (home-page "https://kraken.re")
    (synopsis "OCR and handwriting recognition engine")
    (description
     "Kraken recognizes historical and contemporary printed and handwritten
text using neural networks.  This package builds the canonical Kraken source
and provides the upstream kraken and ketos commands, with an explicitly
binary-assisted, pinned CPU dependency closure.  The in-tree baseline segmenter
and a small Apache-2.0 recognition fixture are available offline.  Production
recognition requires a suitable separately chosen local model; model repository
commands contact external services only when explicitly invoked by the user.")
    (license license:asl2.0)))
