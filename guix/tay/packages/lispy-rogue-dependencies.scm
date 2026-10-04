;;; Lispy Rogue -- pinned Common Lisp libraries absent from Guix.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages lispy-rogue-dependencies)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages swig))

(define-public sbcl-cl-astar
  (let ((commit "00d37d04187ce42211b2029402ee46a6813a5bce"))
    (package
      (name "sbcl-cl-astar")
      (version "0.0.4")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/lockie/cl-astar")
               (commit commit)))          ; tag 0.0.4
         (file-name (git-file-name "cl-astar" version))
         (sha256
          (base32 "1hx68wk2r290v1l5g4gp02rj33kc1zf7xbn5c5kmys83f9dq8j9f"))))
      (build-system asdf-build-system/sbcl)
      (arguments
       (list #:asd-systems ''("cl-astar")
             #:asd-test-systems ''("cl-astar/tests")
             #:phases
             #~(modify-phases %standard-phases
                 (add-after 'unpack 'make-invalid-test-values-opaque
                   (lambda _
                     ;; Invalid literal arguments to inline encoders cause
                     ;; compile-time type warnings in recent SBCL.  Exercise
                     ;; the same invalid inputs through non-inlined wrappers,
                     ;; preserving the runtime error assertions.
                     (substitute* "tests/coding.lisp"
                       (("^\\(in-package #:cl-astar/tests\\)")
                        (string-append
                         "(in-package #:cl-astar/tests)\n"
                         "(declaim (notinline invalid-integer-coordinates invalid-float-coordinates))\n"
                         "(defun invalid-integer-coordinates (x y) (encode-integer-coordinates x y))\n"
                         "(defun invalid-float-coordinates (x y) (encode-float-coordinates x y))"))
                       (("\\(fail \\(encode-integer-coordinates")
                        "(fail (invalid-integer-coordinates")
                       (("\\(fail \\(encode-float-coordinates")
                        "(fail (invalid-float-coordinates")
                       (("^   \\(encode-integer-coordinates 0 (.*)" line argument)
                        (if (string-contains argument
                                             "(ash 1 a*::+bits-per-coordinate+)")
                            (string-append
                             "   (invalid-integer-coordinates 0 " argument)
                            line))))))))
      (native-inputs (list sbcl-parachute))
      (inputs
       (list sbcl-alexandria
             sbcl-float-features
             sbcl-let-plus
             sbcl-trivial-adjust-simple-array))
      (home-page "https://gitlab.com/lockie/cl-astar")
      (synopsis "Optimized A* pathfinding for Common Lisp")
      (description
       "cl-astar provides a macro which defines heavily optimized A*
pathfinding functions with configurable coordinate encoding, neighbour
enumeration, cost and heuristic functions.")
      (license license:expat))))

;; Lispy Rogue needs ENSURE-LOADED and WITH-CURRENT-MOUSE-STATE, which the
;; older Guix pin does not export.  This full upstream version also includes
;; SBCL stream type fixes, without the later Allegro 5.2.11-only additions.
(define-public sbcl-cl-liballegro-compatible
  (let ((commit "f788b9245bc1391c82fdc3d0c6ba1f08ce7eb63d"))
    (package
      (inherit sbcl-cl-liballegro)
      (version "0.2.28")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/resttime/cl-liballegro")
               (commit commit)))
         (file-name (git-file-name "cl-liballegro" version))
         (sha256
          (base32 "0ap9gz6gvdprxrcbqvnkmk3jksrcddl58l5mmd6b58fxy73ds2vd"))))
      ;; CFFI supplies both cffi and cffi-libffi ASDF systems.
      (inputs
       (modify-inputs (package-inputs sbcl-cl-liballegro)
         (append sbcl-trivial-gray-streams))))))

(define-public sbcl-cl-liballegro-nuklear
  (let ((commit "eb45ded76be495c59c82bc743850db275119cb2a")
        (revision "0"))
    (package
      (name "sbcl-cl-liballegro-nuklear")
      (version (git-version "0.0.12" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/lockie/cl-liballegro-nuklear")
               (commit commit)))
         (file-name (git-file-name "cl-liballegro-nuklear" version))
         (sha256
          (base32 "1nk9fxq170zf28c0rflgaffy7565jqvq9j7c8b0dpnjnmq0gk49n"))))
      (build-system asdf-build-system/sbcl)
      (arguments
       (list
        #:asd-systems ''("cl-liballegro-nuklear"
                         "cl-liballegro-nuklear/declarative")
        #:tests? #f                     ; No upstream test system.
        #:phases
        #~(modify-phases %standard-phases
            ;; Build the C side before copy-source, so the installed system is
            ;; complete and immutable.  The committed interface.lisp is used:
            ;; SWIG 4 removed the CFFI module needed to regenerate it.
            (add-after 'unpack 'build-native-library
              (lambda _
                (let ((src (string-append (getcwd) "/src/"))
                      (lib (string-append #$output "/lib")))
                  (setenv "LDFLAGS"
                          (string-append "-Wl,-rpath," #$allegro "/lib"))
                  ;; Explicit targets retain upstream's committed CFFI
                  ;; interface while generating native offsets for this ABI.
                  (invoke "make" "-C" "src"
                          (string-append "CC=" #$(cc-for-target))
                          (string-append src "offsets.lisp")
                          (string-append src "liballegro_nuklear.so"))
                  (install-file (string-append src "liballegro_nuklear.so")
                                lib)
                  (install-file "LICENSE.md"
                                (string-append #$output
                                               "/share/doc/cl-liballegro-nuklear"))
                  (for-each delete-file
                            (list (string-append src "liballegro_nuklear.so")
                                  (string-append src "gen-offsets")))
                  ;; This font is used only by README/example code.
                  (delete-file "Roboto-Regular.ttf"))))
            (add-after 'build-native-library 'use-installed-native-library
              (lambda _
                (call-with-output-file "src/library.lisp"
                  (lambda (port)
                    (format port
                            "(in-package :cl-liballegro-nuklear)~%~%(cffi:define-foreign-library liballegro-nuklear~%  (t ~s))~%~%(cffi:use-foreign-library liballegro-nuklear)~%"
                            (string-append
                             #$output "/lib/liballegro_nuklear.so"))))
                ;; Drop the now-unused custom ASDF component class and methods.
                (let* ((text (call-with-input-file "cl-liballegro-nuklear.asd"
                               (@ (ice-9 textual-ports) get-string-all)))
                       (start (string-contains text "(asdf:defsystem")))
                  (unless start
                    (error "cl-liballegro-nuklear system declaration missing"))
                  (call-with-output-file "cl-liballegro-nuklear.asd"
                    (lambda (port)
                      (display (substring text start) port))))
                ;; Loading must not run make, uname or pkg-config at runtime.
                (let ((matches 0))
                  (substitute* "cl-liballegro-nuklear.asd"
                    (("\\(:makefile \"Makefile\"\\)")
                     (set! matches (+ matches 1))
                     ""))
                  (unless (= matches 1)
                    (error "cl-liballegro-nuklear makefile component mismatch"
                           matches))))))))
      ;; Keep the requested native tool closure explicit.  SWIG 4 has no CFFI
      ;; backend; the fixed upstream-generated interface is therefore retained.
      (native-inputs (list gnu-make gcc-toolchain pkg-config swig-4.0))
      (inputs
       (list allegro
             sbcl-alexandria
             sbcl-cffi
             sbcl-cl-liballegro-compatible
             sbcl-trivial-features))
      (home-page "https://github.com/lockie/cl-liballegro-nuklear")
      (synopsis "Nuklear immediate-mode GUI bindings for cl-liballegro")
      (description
       "cl-liballegro-nuklear provides CFFI bindings to the Nuklear immediate
mode graphical user interface library with its Allegro 5 rendering backend,
plus a declarative interface.  The bundled Nuklear and Allegro backend are
compiled into a shared library that the bindings load from this package.")
      ;; Bindings: Expat.  Bundled nuklear.h, nuklear_allegro5.h and stb code:
      ;; public domain, with an MIT alternative.
      (license (list license:expat license:public-domain)))))

(define-public sbcl-cl-tiled
  (let ((commit "80332bfbf18734f342c9c2c7b6228560f64a3d54")
        (revision "0"))
    (package
      (name "sbcl-cl-tiled")
      (version (git-version "0.2.2" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/Zulu-Inuoe/cl-tiled")
               (commit commit)))
         (file-name (git-file-name "cl-tiled" version))
         (sha256
          (base32 "1wmh9df35sl4wd4n4nd050p9489zk4vwg32a5hsj2qqyrh2qvi8b"))))
      (build-system asdf-build-system/sbcl)
      (arguments
       (list #:asd-systems ''("cl-tiled")
             #:tests? #f))              ; No upstream test system.
      (inputs
       (list sbcl-alexandria
             sbcl-chipz
             sbcl-cl-base64
             sbcl-cl-json
             sbcl-nibbles
             sbcl-parse-float
             sbcl-split-sequence
             sbcl-xmls))
      (home-page "https://github.com/Zulu-Inuoe/cl-tiled")
      (synopsis "Tiled map editor file loader for Common Lisp")
      (description
       "cl-tiled loads maps and tilesets saved by the Tiled map editor in its
XML and JSON formats, including embedded and compressed layer data.")
      (license license:zlib))))
