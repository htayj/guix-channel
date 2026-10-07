;;; Imago image processing library for Common Lisp.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages imago)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages imago-dependencies)
  #:use-module ((tay packages auxiliary) #:select (search-tay-package-file))
  #:use-module (tay packages starred-s-z))

(define-public sbcl-imago
  (package
    (name "sbcl-imago")
    (version "0.11.0")
    (source (origin
              (inherit (package-source tokenrove-imago-source))
              (patches
               (list
                (search-tay-package-file
                 "patches/sbcl-imago-jupyter-png-api.patch")
                (search-tay-package-file
                 "patches/sbcl-imago-preserve-format-registry.patch")))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      ;; All six upstream systems in one output.  The test system is
      ;; loaded during the check phase against the full in-tree
      ;; fixture set; it is compiled only for testing and never
      ;; installed.
      #:asd-systems ''("imago" "imago/bit-io" "imago/jpeg-turbo"
                       "imago/libheif" "imago/libtiff" "imago/jupyter")
      #:asd-test-systems ''("imago/tests")
      #:phases
      #~(modify-phases %standard-phases
          ;; Run the complete upstream suite: the 5001x5001
          ;; distance-transform test keeps roughly 25 million cons
          ;; cells live at once and exhausts SBCL's default 3 GB
          ;; dynamic space; upstream CI builds with 8 GB, so start
          ;; the check SBCL with the same setting rather than
          ;; shrinking the fixture corpus.  Calling SBCL directly
          ;; here (instead of the build system's helper) is the only
          ;; way to pass that flag.
          (replace 'check
            (lambda* (#:key tests? inputs outputs #:allow-other-keys)
              (when tests?
                ;; Mirror the build system's test-system helper: point
                ;; ASDF's source registry ONLY at this package's
                ;; installed source tree (with inherited configuration
                ;; for compiled dependencies via CL_UNION), instead of
                ;; the host's default registry.
                (let* ((out (or (assoc-ref outputs "lib")
                                (assoc-ref outputs "out")))
                       (source-dir (string-append
                                    out "/share/common-lisp/sbcl/imago"))
                       (sbcl (search-input-file inputs "bin/sbcl")))
                  (invoke sbcl
                          "--dynamic-space-size" "8gb"
                          "--non-interactive"
                          "--eval" "(require :asdf)"
                          "--eval"
                          ;; Emit the registry as a literal Lisp config
                          ;; string (mirroring the build system's
                          ;; test-system helper shape) instead of a
                          ;; Scheme format object: no Guile symbol
                          ;; constructor runs in the build stratum.
                          (string-append
                           "(asdf:initialize-source-registry '(:source-registry"
                           " (:tree #p\"" source-dir "/\")"
                           " :inherit-configuration))")
                          ;; Load the test system and call upstream
                          ;; run-tests DIRECTLY (not via asdf:test-system,
                          ;; which discards the result): it returns
                          ;; NIL when any check fails, and FiveAM's
                          ;; `every' over suites short-circuits on the
                          ;; first failing suite, so any nonzero exit
                          ;; implies a genuine failure with the full
                          ;; suite chain examined up to that point.
                          ;; Exit nonzero on failure so the phase —
                          ;; and the build — fails; no suppression.
                          "--eval" "(asdf:load-system :imago/tests)"
                          "--eval"
                          (string-append
                           "(unless (uiop:symbol-call :imago/tests '#:run-tests)"
                           " (uiop:quit 1))")
                          "--eval" "(uiop:quit)")))))
          ;; The upstream tree ships docs/ and tests/ images with no
          ;; license grant anywhere in the repository, while the
          ;; tests/*.lisp files are LLGPL-covered like all sources.
          ;; The asdf build system installs sources under
          ;; <out>/share/common-lisp/<lisp>/<name> via the
          ;; 'copy-source phase (there is no 'install phase; the tree
          ;; is copied before compiling and renamed from source/ to
          ;; sbcl/), so scrub the output after 'check — which needs
          ;; the fixtures in place — removing the docs/ tree and every
          ;; non-Lisp file under tests/.  Only LLGPL-covered sources
          ;; remain installed; the pristine source snapshot package
          ;; retains the fixtures unaltered.
          (add-after 'check 'remove-unlicensed-assets
            (lambda _
              (let ((source-dir (string-append #$output
                                               "/share/common-lisp/sbcl/imago")))
                (let ((docs (string-append source-dir "/docs")))
                  (when (file-exists? docs)
                    (delete-file-recursively docs)))
                (for-each
                 (lambda (file)
                   (unless (string-suffix? ".lisp" file)
                     (delete-file file)))
                 (find-files (string-append source-dir "/tests")))))))))
    (inputs
     (list sbcl-alexandria
           sbcl-array-operations
           sbcl-cffi
           sbcl-cl-jpeg-imago
           sbcl-cl-libheif
           sbcl-cl-libtiff
           sbcl-flexi-streams
           sbcl-float-features
           sbcl-jpeg-turbo
           sbcl-pngload
           sbcl-serapeum
           sbcl-trivial-gray-streams
           sbcl-zlib
           sbcl-zpng))
    (native-inputs (list sbcl-fiveam))
    (propagated-inputs
     (list sbcl-cl-base64
           sbcl-common-lisp-jupyter-imago
           sbcl-flexi-streams))
    (home-page "https://github.com/tokenrove/imago")
    (synopsis "Image manipulation library for Common Lisp")
    (description
     "Imago reads, writes, converts and processes images in Common Lisp,
with support for PNG, JPEG (classic and turbojpeg), HEIF/HEIC, TIFF, PNM and
TGA formats, colour space conversions, convolution, morphology, resizing and
rotation.  This package builds all six upstream systems: @code{imago},
@code{imago/bit-io}, @code{imago/jpeg-turbo}, @code{imago/libheif},
@code{imago/libtiff} and @code{imago/jupyter}.")
    (license license:llgpl)))
