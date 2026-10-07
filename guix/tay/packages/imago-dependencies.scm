;;; Imago image library dependencies absent from Guix proper.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages imago-dependencies)
  #:use-module (guix build-system asdf)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages image)
  #:use-module (gnu packages lisp-xyz)
  #:use-module ((tay packages auxiliary) #:select (search-tay-package-file)))

;; The CFFI wrappers below resolve their foreign libraries through absolute
;; store paths patched in at build time, so loading never depends on the
;; dynamic linker cache.  On x86-64 cl-libheif also compiles and installs
;; the upstream tiny C wrapper, which is needed whenever the system loads.

;; Stock Guix in this channel pins libtiff 4.4.0 (soname libtiff.so.5), but
;; cl-libtiff v0.1 calls the libtiff >= 4.5 per-caller API (TIFFOpenOptionsAlloc,
;; TIFFOpenOptionsSetErrorHandlerExtR, TIFFOpenExt), not just soname 6.  Reuse
;; the current stable Guix recipe: upstream v4.7.2 built from git with the
;; autotools dev tools (Guix master does exactly this), inheriting the stock
;; package's inputs, outputs, tests and license.
(define-public libtiff/cl-libtiff
  (package
    (inherit libtiff)
    (name "libtiff")
    (version "4.7.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/libtiff/libtiff.git")
             (commit (string-append "v" version))))
       (file-name (git-file-name "tiff" version))
       (sha256
        (base32
         "0q6q1kzam5fki7biip3yhrhfb8p8h87m03pajhrn6zcijn1yjhpb"))))
    (native-inputs
     (list autoconf-2.72 automake libtool))))

(define-public sbcl-zlib
  (let ((commit "7e89e71b0f7b276b3c71dcdd9575d8d99ca75327")
        (revision "0"))
    (package
      (name "sbcl-zlib")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/sharplispers/zlib")
               (commit commit)))
         (file-name (git-file-name "cl-zlib" version))
         (sha256
          (base32 "1gz771h2q3xhw1yxpwki5zr9mqysa818vn21501w6fsi8wlmlffa"))))
      (build-system asdf-build-system/sbcl)
      (arguments (list #:asd-systems ''("zlib") #:tests? #f)) ;no test system
      (home-page "https://github.com/sharplispers/zlib")
      (synopsis "Pure Common Lisp implementation of the DEFLATE algorithm")
      (description
       "This is a Common Lisp implementation of zlib, i.e. it is not using
FFI.  It supports the ZLIB compress and uncompress functions using the
DEFLATE compression scheme.")
      (license license:llgpl))))

;; Stock Guix pins cl-jpeg to a revision predating the encoder export; Imago's
;; JPEG backend needs JPEG:ENCODE-IMAGE-STREAM, exported only from this later
;; upstream commit ("export encode-image-stream (#41)").
(define-public sbcl-cl-jpeg-imago
  (let ((commit "bef2c3bb64dd19cb31c26338dcbecbf2542a2619")
        (revision "0"))
    (package
      (inherit sbcl-cl-jpeg)
      (name "sbcl-cl-jpeg-imago")
      (version (git-version "2.8" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/sharplispers/cl-jpeg")
               (commit commit)))
         (file-name (git-file-name "cl-jpeg" version))
         (sha256
          (base32 "1xl1id4k1bdw6hf24ndkzr6nxi30yw7xlr1fhfmxnwjqwy5hcq14"))))
      ;; The renamed package must still build the upstream "cl-jpeg" system;
      ;; the ASDF build system would otherwise derive "cl-jpeg-imago".
      (arguments (list #:asd-systems ''("cl-jpeg") #:tests? #f)))))

;; The stock Jupyter ASDF component installs its prebuilt lab extension in
;; XDG_DATA_HOME during compilation.  A library load then creates newer
;; outputs outside the store and invalidates the installed FASLs.  Model
;; the files as static resources and install them here instead: Jupyter
;; discovers the intact extension through the profile's XDG_DATA_DIRS.
(define-public sbcl-common-lisp-jupyter-imago
  (package
    (inherit sbcl-common-lisp-jupyter)
    (name "sbcl-common-lisp-jupyter-imago")
    (source
     (origin
       (inherit (package-source sbcl-common-lisp-jupyter))
       (patches
        (append
         (origin-patches (package-source sbcl-common-lisp-jupyter))
         (list
          (search-tay-package-file
           "patches/sbcl-common-lisp-jupyter-imago-static-extension.patch"))))))
    (arguments
     (substitute-keyword-arguments
         (package-arguments sbcl-common-lisp-jupyter)
       ((#:asd-systems _ ''("common-lisp-jupyter"))
        ''("common-lisp-jupyter"))
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'install-jupyter-labextension
              (lambda _
                (copy-recursively
                 "debugger-restarts/prebuilt"
                 (string-append
                  #$output "/share/jupyter/labextensions/"
                  "debugger-restarts-clj"))))))))
    (native-search-paths
     (append
      (package-native-search-paths sbcl-common-lisp-jupyter)
      (list (search-path-specification
             (variable "XDG_DATA_DIRS")
             (files '("share"))))))))

(define-public sbcl-cl-libheif
  (package
    (name "sbcl-cl-libheif")
    (version "1.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/shamazmazum/cl-libheif")
             (commit "3f74c17b7313eeb179eefe87ffd00bcf54a53751"))) ;tag v1.1.0
       (file-name (git-file-name "cl-libheif" version))
       (sha256
        (base32 "1pv8qkqclmwmnsqyh657l1jaqf021sdsidmnky9nc6grk7vfgc5m"))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list #:asd-systems ''("cl-libheif")
           #:tests? #f               ;test deps not in Guix
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'use-store-libheif
                 (lambda* (#:key inputs #:allow-other-keys)
                   ;; Guix has no ld.so cache, so load the absolute store
                   ;; file instead of the soname.  The cwrapper ASDF
                   ;; component compiles tiny-wrapper.c with "cc" into the
                   ;; installed FASL directory at build time; provide "cc"
                   ;; from the native gcc and leave upstream's loading
                   ;; logic untouched.
                   (substitute* "src/library.lisp"
                     (("libheif.so.1" all)
                      #$(file-append libheif "/lib/libheif.so.1")))
                   (let ((shim (string-append (getcwd) "/cc-shim")))
                     (mkdir-p shim)
                     (symlink (search-input-file inputs "bin/gcc")
                              (string-append shim "/cc"))
                     (setenv "PATH" (string-append shim ":" (getenv "PATH"))))
                   (install-file "LICENSE"
                                 (string-append #$output "/share/doc/cl-libheif")))))))
    (native-inputs (list gcc))
    (inputs
     (list libheif
           sbcl-cffi
           sbcl-serapeum
           sbcl-split-sequence
           sbcl-trivial-octet-streams))
    (home-page "https://github.com/shamazmazum/cl-libheif")
    (synopsis "Common Lisp wrapper around libheif")
    (description
     "cl-libheif is a CFFI wrapper around the libheif library, providing
decoding and encoding of HEIF images, Exif and XMP metadata handling, and
color profile support.  On x86-64 a tiny C shim is compiled at build time
so CFFI can pass struct-returning callbacks to libheif.")
    (license license:bsd-2)))

(define-public sbcl-cl-libtiff
  (package
    (name "sbcl-cl-libtiff")
    (version "0.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/shamazmazum/cl-libtiff")
             (commit "14587dbb916dc4dad4e68bc66e4b5844b011d693"))) ;tag v0.1
       (file-name (git-file-name "cl-libtiff" version))
       (sha256
        (base32 "149im6hvn0k07jsfrvqjw0w38fpd69c1rw7jck9j8pzzjadlc6bn"))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list #:asd-systems ''("cl-libtiff")
           #:tests? #f                  ;test deps not in Guix
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'use-store-libtiff
                 (lambda _
                   ;; Point CFFI at the absolute store file; without an
                   ;; ld.so cache neither "libtiff.so.6" nor "libtiff.so"
                   ;; resolves.  libtiff/cl-libtiff 4.7.2 provides both
                   ;; SONAME 6 and the >= 4.5 API cl-libtiff calls.
                   (substitute* "src/libtiff.lisp"
                     (("libtiff.so.6" all)
                      #$(file-append libtiff/cl-libtiff
                                     "/lib/libtiff.so.6"))))))))
    (inputs
     (list libtiff/cl-libtiff sbcl-cffi sbcl-serapeum))
    (home-page "https://github.com/shamazmazum/cl-libtiff")
    (synopsis "Common Lisp wrapper around libtiff")
    (description
     "cl-libtiff is a CFFI wrapper around the libtiff library supporting
reading and writing TIFF images, including striped and tiled storage and
per-scanline access.")
    (license license:bsd-2)))
