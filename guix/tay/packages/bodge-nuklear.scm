;;; bodge-nuklear -- Common Lisp wrapper over a source-built Nuklear library.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages bodge-nuklear)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages auxiliary))

(define %bodge-nuklear-commit "40adae40e144143a4c3e12a9f4b96d5e2bb25155")

(define %bodge-nuklear-version
  (git-version "1.0.0" "1" %bodge-nuklear-commit))

;; Recursive checkout: the native library is built from the pinned
;; vurtun/nuklear submodule 3e13d3667878747dcddc3fe970cf33e6fdae204e.
(define %bodge-nuklear-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/borodust/bodge-nuklear")
          (commit %bodge-nuklear-commit)
          (recursive? #t)))
    (file-name (git-file-name "bodge-nuklear" %bodge-nuklear-version))
    (sha256
     (base32 "1qg3m1b1b43gbrqwpy9ryc8pnwz92wpxsfrkqqp85lghcnpj3sza"))))

(define-public sbcl-nuklear-blob
  (package
    (name "sbcl-nuklear-blob")
    (version %bodge-nuklear-version)
    (source %bodge-nuklear-source)
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("nuklear-blob")
      #:tests? #f ; No upstream test system.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'build-native-library
            (lambda _
              (let ((include (string-append #$output "/include"))
                    (demo (string-append #$output
                                         "/share/bodge-nuklear/demo/x11"))
                    (doc (string-append #$output "/share/doc/nuklear-blob"))
                    (blob (string-append (dirname (getcwd)) "/nuklear-blob")))
                ;; Upstream's own Makefile: main.c plus the claw adapter that
                ;; exports the __claw_nk_* entry points used by the bindings.
                (with-directory-excursion "src/lib"
                  (invoke "make" (string-append "CC=" #$(cc-for-target))
                          "build"))
                (install-file "src/bodge_nuklear.h" include)
                (install-file "src/lib/nuklear/nuklear.h" include)
                ;; The unmodified upstream X11 demo for external consumers.
                (for-each (lambda (file)
                            (install-file
                             (string-append "src/lib/nuklear/demo/x11/" file)
                             demo))
                          '("main.c" "nuklear_xlib.h"))
                (mkdir-p doc)
                (copy-file "LICENSE"
                           (string-append doc "/LICENSE.bodge-nuklear"))
                (copy-file "src/lib/nuklear/src/LICENSE"
                           (string-append doc "/LICENSE.nuklear"))
                ;; Credits the embedded stb libraries and ProggyClean font.
                (copy-file "src/lib/nuklear/Readme.md"
                           (string-append doc "/README.nuklear.md"))
                (copy-file #$(local-file
                              (search-tay-package-file
                               "bodge-nuklear-blob-LICENSE.txt"))
                           (string-append doc "/LICENSE.nuklear-blob"))
                ;; ProggyClean.ttf is embedded by NK_INCLUDE_DEFAULT_FONT;
                ;; preserve its full permission notice as well as the credit.
                (copy-file #$(local-file
                              (search-tay-package-file
                               "bodge-nuklear-font-LICENSE.txt"))
                           (string-append doc "/LICENSE.ProggyClean"))
                ;; Only the system definition and native library go into the
                ;; ASDF tree, so bodge-nuklear.asd is not installed twice.
                (mkdir-p (string-append blob "/x86_64"))
                (copy-file "src/lib/libnuklear.so.bodged"
                           (string-append blob "/x86_64/libnuklear.so"))
                (chdir blob)
                ;; Adapted from borodust/nuklear-blob
                ;; 39eb9e8fff1105a7a745279eea363f09193869d4 (MIT) without its
                ;; prebuilt binaries, glad-blob dependency or non-Linux entries.
                (call-with-output-file "nuklear-blob.asd"
                  (lambda (port)
                    (display "\
(asdf:defsystem nuklear-blob
  :author \"Pavel Korolev\"
  :description \"Nuklear IM GUI foreign library built from bodge-nuklear\"
  :license \"MIT\"
  :defsystem-depends-on (:bodge-blobs-support)
  :class :bodge-blob-system
  :libraries (((:unix (:not :darwin) :x86-64) \"libnuklear.so\" \"x86_64/\")))
" port))))))
          (add-after 'create-asdf-configuration 'link-native-library
            (lambda _
              (let ((lib (string-append #$output "/lib/x86_64")))
                (mkdir-p lib)
                (symlink (string-append
                          #$output "/share/common-lisp/sbcl/nuklear-blob"
                          "/x86_64/libnuklear.so")
                         (string-append lib "/libnuklear.so"))))))))
    (inputs (list sbcl-bodge-blobs-support))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/borodust/bodge-nuklear")
    (synopsis "Source-built Nuklear native library for bodge-nuklear")
    (description
     "This package builds the Nuklear immediate-mode GUI library with the
bodge-nuklear configuration and C adapter, and provides the @code{nuklear-blob}
ASDF system that loads it through @code{bodge-blobs-support}.  It also installs
the library headers and the original Nuklear X11 demo sources.")
    (license (list license:expat license:unlicense license:public-domain))))

(define-public bodge-nuklear
  (package
    (name "bodge-nuklear")
    (version %bodge-nuklear-version)
    (source %bodge-nuklear-source)
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      ;; Only the delivered library systems are compiled.  The claw generator
      ;; and optional Bodge-host example have separate, unprovided closures.
      #:asd-systems ''("bodge-nuklear-bindings" "bodge-nuklear")
      #:tests? #f ; No upstream test system.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-wrapper-tree
            (lambda _
              (use-modules (ice-9 textual-ports))
              (let ((doc (string-append #$output "/share/doc/bodge-nuklear")))
                (install-file "LICENSE" doc)
                ;; Loading either delivered system must load its native ABI.
                (substitute* "bodge-nuklear-bindings.asd"
                  ((":depends-on \\(:uiop :cffi :claw-utils\\)")
                   ":depends-on (:uiop :cffi :claw-utils :nuklear-blob)"))
                ;; c-ref already translates the enum slot to a keyword.  A
                ;; second foreign-enum-keyword call rejects that keyword.
                (substitute* "src/nuklear.lisp"
                  (("  \\(cffi:foreign-enum-keyword '%nuklear:command-type") "")
                  (("\\(c-ref cmd \\(:struct %nuklear:command\\) :type\\)\\)\\)")
                   "(c-ref cmd (:struct %nuklear:command) :type))"))
                ;; Do not advertise optional systems whose sources and
                ;; native dependencies are not part of this output.
                (let* ((contents (call-with-input-file "bodge-nuklear.asd"
                                   get-string-all))
                       (end (string-contains
                             contents "(asdf:defsystem :bodge-nuklear/wrapper")))
                  (unless end (error "Upstream ASDF layout changed"))
                  (call-with-output-file "bodge-nuklear.asd"
                    (lambda (port) (display (substring contents 0 end) port))))
                (for-each delete-file
                          '("src/claw.lisp" "src/example.lisp"))
                (delete-file-recursively "util")
                ;; Native sources are built by sbcl-nuklear-blob.
                (delete-file-recursively "src/lib")))))))
    (inputs
     (list sbcl-alexandria
           sbcl-cffi
           sbcl-cffi-c-ref
           sbcl-claw-utils
           sbcl-nuklear-blob
           sbcl-trivial-features))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/borodust/bodge-nuklear")
    (synopsis "Common Lisp wrapper for the Nuklear immediate-mode GUI")
    (description
     "This package provides the @code{bodge-nuklear-bindings} foreign bindings
and the @code{bodge-nuklear} wrapper for the Nuklear immediate-mode GUI library:
contexts, user fonts, widgets, input and draw command traversal.  The native
library comes from the source-built @code{nuklear-blob} system.")
    (license (list license:expat license:public-domain))))
