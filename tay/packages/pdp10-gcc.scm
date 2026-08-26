;;; GNU Guix package for the PDP-10 GCC backend.

(define-module (tay packages pdp10-gcc)
  #:use-module (guix build-system gnu)
  #:use-module ((guix build utils)
                #:select (install-file invoke mkdir-p))
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages texinfo)
  #:use-module (tay packages larsbrinkhoff-n-s))

;; The bundled Boehm GC notice is a permissive license with a notice-retention
;; condition.  Guix has no more specific identifier for this historical text.
(define boehm-gc-license
  (license:non-copyleft
   "https://www.hboehm.info/gc/"
   "Boehm GC permissive license"))

(define-public pdp10-gcc
  (package
    (name "pdp10-gcc")
    ;; This is the version identified by gcc/version.c in the pinned upstream
    ;; tree, rather than the revision-only version of the preservation package.
    (version "3.2-20020416")
    ;; Reuse the channel's immutable codeload origin: revision
    ;; 3c67a2b56b8a02041bdfca00d012bcccbe4168e5.
    (source (package-source larsbrinkhoff-pdp10-gcc-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;No runnable PDP-10 test environment.
      #:configure-flags
      #~(list "--build=x86_64-linux"
              "--host=x86_64-linux"
              "--target=pdp10-unknown-tops20"
              "--enable-languages=c"
              "--disable-nls"
              "--disable-multilib"
              "--disable-shared"
              "--disable-threads"
              "--disable-libstdc++-v3"
              "--disable-libgcj"
              "--disable-checking"
              ;; This selects the bundled pdp10/gas.h output dialect only.
              ;; It neither provides nor searches for a target assembler.
              "--with-gnu-as")
      #:make-flags #~(list "all-gcc")
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda* (#:key configure-flags #:allow-other-keys)
              ;; GCC requires a separate build directory.  Use the older
              ;; bootstrap compiler explicitly; its toolchain also provides
              ;; the host binutils used to build the native compiler programs.
              (let ((toolchain
                     #$(this-package-native-input "gcc-toolchain-4.9")))
                (setenv "PATH" (string-append toolchain "/bin:" (getenv "PATH")))
                (setenv "CC" (string-append toolchain "/bin/gcc"))
                (setenv "CXX" (string-append toolchain "/bin/g++"))
                ;; Do not mix the default build-system GCC's search paths
                ;; with the selected GCC 4.9 bootstrap toolchain.
                (for-each unsetenv
                          '("CPATH" "C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"
                            "OBJC_INCLUDE_PATH" "OBJCPLUS_INCLUDE_PATH"
                            "LIBRARY_PATH"))
                (mkdir-p "build")
                (chdir "build")
                (apply invoke "../configure"
                       (string-append "--prefix=" #$output)
                       configure-flags))))
          (replace 'install
            (lambda _
              ;; Do not build target libraries: the upstream tree has no
              ;; target assembler, linker, libc, or runnable target system.
              (invoke "make" "install-gcc")))
          (delete 'install-license-files)
          (add-after 'install 'install-license-notices
            (lambda _
              ;; Keep every bundled license notice represented by installed
              ;; compiler material available without shipping a target runtime.
              (let ((doc (string-append #$output "/share/doc/pdp10-gcc-"
                                         #$version)))
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("../COPYING"
                            "../COPYING.LIB"
                            "../gcc/COPYING"
                            "../gcc/COPYING.LIB"
                            "../boehm-gc/doc/README"
                            "../libffi/LICENSE"
                            "../zlib/zlib.h"
                            "../libjava/LIBGCJ_LICENSE"))))))))
    (native-inputs
     (list gcc-toolchain-4.9 bison flex texinfo perl m4))
    (supported-systems '("x86_64-linux"))
    (synopsis "GCC C backend that emits PDP-10 TOPS-20 assembly")
    (description
     "This package provides the PDP-10 backend from GCC 3.2 for the
@code{pdp10-unknown-tops20} target.  It is a code-generation package: the
installed @command{pdp10-unknown-tops20-gcc} and @command{cpp} can preprocess
C and emit PDP-10 assembly with @option{-S}.  It deliberately does not provide
a PDP-10 assembler, linker, C library, target object files, guest operating
system, or executable runtime.  Consequently, assembly, linking, and execution
are unsupported and must not fall back to host tools.")
    (home-page "https://github.com/larsbrinkhoff/pdp10-gcc")
    (license (list license:gpl2 license:lgpl2.1 license:expat license:zlib
                   boehm-gc-license))))
