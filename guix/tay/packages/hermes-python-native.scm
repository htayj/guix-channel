;;; Source-built native media dependencies for the Hermes Python 3.11 runtime.

(define-module (tay packages hermes-python-native)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module ((guix build-system python) #:select (python-build-system))
  #:use-module (guix build-system pyproject)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages image)
  #:use-module (gnu packages image-processing)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (srfi srfi-1))

;; pyproject-build-system invokes the unversioned Python command.  Retain the
;; upstream wrapper implementation, but point it at the backend's interpreter.
(define hermes-python-wrapper
  (package
    (inherit python-wrapper)
    (version (package-version python-3.11))
    (propagated-inputs (list python-3.11))))

(define (python-build-package? package)
  (memq (package-build-system package)
        (list python-build-system pyproject-build-system)))

;; Guix's package-with-explicit-python currently cuts recursion at pyproject
;; packages.  Map both build systems so Cython, NumPy and the build backends are
;; rebuilt for 3.11 as well.  OpenCV and pybind11 use CMake but also install
;; Python modules; they must participate in the same ABI transformation.
(define with-hermes-python
  (package-mapping
   (lambda (package)
     (cond
      ((member (package-name package)
               '("python-wrapper" "python-sans-pip-wrapper"
                 "python-minimal-wrapper"))
       hermes-python-wrapper)
      ((member (package-name package) '("python" "python-sans-pip"
                                       "python-minimal"))
       python-3.11)
      ((string=? (package-name package) "python-lxml")
       (package/inherit package
         (arguments
          (substitute-keyword-arguments
              (ensure-keyword-arguments (package-arguments package)
                                        (list #:python hermes-python-wrapper))
            ((#:phases phases #~%standard-phases)
             #~(modify-phases #$phases
                 (add-before 'build 'reduce-generated-c-compiler-resources
                   (lambda _
                     ;; lxml's INSTALL.txt documents CFLAGS=-O0 for test
                     ;; environments.  Its generated etree.c was terminated
                     ;; externally while compiling at -O3 with debug info.
                     ;; The cause of that SIGTERM is unverified; retain all
                     ;; extensions and checks, but avoid optimization and
                     ;; debug-information overhead for this test dependency.
                     (setenv "CFLAGS"
                             (string-append (or (getenv "CFLAGS") "")
                                            " -O0 -g0"))))))))))
      ((string=? (package-name package) "python-xmlschema")
       (package/inherit package
         (arguments
          (substitute-keyword-arguments
              (ensure-keyword-arguments (package-arguments package)
                                        (list #:python hermes-python-wrapper))
            ((#:phases phases #~%standard-phases)
             #~(modify-phases #$phases
                 (replace 'check
                   (lambda* (#:key tests? #:allow-other-keys)
                     (when tests?
                       ;; unittest discovery retains imported modules and
                       ;; their class-level schema fixtures for the entire
                       ;; suite.  Run every discovered test module serially
                       ;; in a fresh interpreter to release those fixtures.
                       ;; Keep the default test*.py pattern and all cases,
                       ;; including the dynamically generated test classes.
                       (for-each
                        (lambda (file)
                          (invoke "python" "-m" "unittest" "-v" file))
                        (sort (find-files "tests" "^test.*\\.py$")
                              string<?)))))))))))
      ((python-build-package? package)
       (package/inherit package
         (arguments
          (ensure-keyword-arguments (package-arguments package)
                                    (list #:python hermes-python-wrapper)))))
      (else package)))
   (lambda (package)
     (not (or (python-build-package? package)
              ;; Meson and its bootstrap setuptools use GNU build phases,
              ;; but install interpreter-specific Python module metadata.
              (eq? package meson)
              (eq? package python-setuptools-bootstrap)
              (eq? package opencv)
              (eq? package pybind11))))))

(define-public hermes-python-pillow
  (with-hermes-python
   (package
     (inherit python-pillow)
     (version "12.3.0")
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "pillow" version))
        (sha256
         (base32 "1kkw54q5ianvy2dmf7y7l0cqicfnr178pqip4q0alpk8cskq509v"))))
     ;; Retain the Guix codec inputs and support the wheel's AVIF and complex
     ;; text-layout features with source-built libraries, not vendored binaries.
     (inputs (modify-inputs (package-inputs python-pillow)
               (append libavif libraqm)))
     (license (license:x11-style
               "https://github.com/python-pillow/Pillow/blob/12.3.0/LICENSE"
               "MIT-CMU License")))))

;; This new PyAV 17 fixture comes from the WebM Project's BSD-licensed libvpx
;; test-data corpus.  Its SHA-1 matches libvpx/test/test-data.sha1:
;; ce881e567fe1d0fbcb2d3e9e6281a1a8d74d82e0.
(define hermes-av-vp9-test-vector
  (origin
    (method url-fetch)
    (uri "https://fate.ffmpeg.org/fate-suite/vp9-test-vectors/vp90-2-00-quantizer-00.webm")
    (sha256
     (base32 "0vawha4whigmvlswrzic8xcv2z1vb5dyj1q8ifmnpd3n1mlnzwlj"))))

(define-public hermes-python-av
  (with-hermes-python
   (package
     (inherit python-av)
     (version "17.0.0")
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "av" version))
        (sha256
         (base32 "1py3x2nl5nh4h84lnsm2jbclkcbc5bbb5ivmqdiqfnkpfggqadn5"))))
     (arguments
      (substitute-keyword-arguments (package-arguments python-av)
        ((#:phases phases #~%standard-phases)
         #~(modify-phases #$phases
             (add-before 'check 'provide-vp9-test-vector
               (lambda _
                 ;; The inherited pre-check runs first and sets the original
                 ;; offline FATE corpus.  Extend a local copy of that corpus.
                 (let ((testdata (string-append (getcwd) "/hermes-testdata")))
                   (copy-recursively (getenv "PYAV_TESTDATA_DIR") testdata)
                   (mkdir-p (string-append testdata "/fate-suite/vp9-test-vectors"))
                   (copy-file #$hermes-av-vp9-test-vector
                              (string-append testdata
                                             "/fate-suite/vp9-test-vectors/vp90-2-00-quantizer-00.webm"))
                   (setenv "PYAV_TESTDATA_DIR" testdata))))
             (add-after 'unpack 'fix-remux-padding-oracle
               (lambda _
                 ;; FFmpeg can also attach skip_samples to the first packet
                 ;; for leading encoder delay, with no trailing padding.
                 ;; Measure the padding actually removed and require the
                 ;; decoded sample increase to match it, rather than pinning
                 ;; every side-data packet to the fixture's last-packet value.
                 (substitute* "tests/test_packet.py"
                   (("# Source file has skip_end=706 on last packet\\. Setting to 0 should")
                    "# Removing trailing padding should increase decoded samples.")
                   (("# result in 706 more decoded samples\\. And the file duration reported by")
                    "# The sample increase must equal the total padding removed,")
                   (("# the container should also increase\\.")
                    "# and the container duration should also increase.")
                   (("output_path = sandboxed\\(\"skip_samples_modified\\.mkv\"\\)")
                    "output_path = sandboxed(\"skip_samples_modified.mkv\")\n        removed_padding = 0")
                   (("assert skip_end == 706")
                    "removed_padding += skip_end")
                   (("assert modified_samples - original_samples == 706")
                    "assert removed_padding > 0\n        assert modified_samples - original_samples == removed_padding"))))))))
     ;; Keep the full Guix FFmpeg package (8.1.x), including GPL encoders.
     ;; setuptools 80.9 and Cython 3.2.5 satisfy the unmodified source's
     ;; requirements: setuptools >=77 and Cython >=3.1,<4.
     (native-inputs
      (modify-inputs (package-native-inputs python-av)
        (replace "python-pillow" hermes-python-pillow))))))

(define-public hermes-python-pillow-heif
  (with-hermes-python
   (package
     (inherit python-pillow-heif)
     (version "1.5.0")
     ;; The inherited recipe uses a pre-release commit; it is not this source.
     (properties '())
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "pillow_heif" version))
        (sha256
         (base32 "0r9hqlinwp8m27lrwf2cqaa93g8lrfspnlin5pd45zv2nwvimc8n"))))
     ;; Inherit libheif 1.23.1 with dav1d, libaom, libde265, libx264,
     ;; OpenH264 and x265.  No decoder-only or GPL-free feature cutover.
     (propagated-inputs (list hermes-python-pillow))
     (native-inputs
      (modify-inputs (package-native-inputs python-pillow-heif)
        (append pkg-config python-wheel))))))
