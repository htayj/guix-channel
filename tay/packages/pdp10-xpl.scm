;;; GNU Guix packages for the PDP-10 XPL cross compiler.

(define-module (tay packages pdp10-xpl)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages bash)
  #:use-module (tay packages pdp10-t-z)
  #:use-module ((guix licenses) #:prefix license:))

;; Both upstream trees carry the Free Public License 1.0.0.  It is
;; permissive, but is not one of Guix's named SPDX-derived license records.
(define free-public-license
  (license:non-copyleft
   "https://opensource.org/license/fpl-1-0"
   "Free Public License 1.0.0"))

;; This stays private: it is an implementation input for the historical
;; PDP-10 compiler, not an independently supported end-user package.
(define xpl-bootstrap
  (package
    (name "xpl-bootstrap")
    (version "1.4")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/xpl-compiler/code")
             (commit "643907731538b4e2256f11c48e3166bf5bb2609c")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "10pf9s43wrhv7xb7ajagwkgdxnbayllzvlf53lzq48yv8m6k2c0a"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          ;; The minimal native toolchain deliberately provides `gcc' but not
          ;; the unqualified `cc' compatibility command assumed upstream.
          (replace 'build
            (lambda _
              (invoke "make" (string-append "CC=" #$(cc-for-target)))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (lib (string-append #$output "/lib"))
                    (include (string-append #$output "/include")))
                (mkdir-p bin)
                (mkdir-p lib)
                (mkdir-p include)
                (install-file "xpl" bin)
                (install-file "libxpl.a" lib)
                (install-file "xpl.h" include)))))))
    (synopsis "XPL-to-C bootstrap translator")
    (description "This private build input provides the XPL-to-C translator
needed to compile the PDP-10 XPL compiler port.")
    (home-page "https://sourceforge.net/projects/xpl-compiler/")
    (license free-public-license)))

(define-public pdp10-xpl-pdp-10
  (package
    (name "pdp10-xpl-pdp-10")
    (version "0-0e57cbd")
    (source (package-source pdp10-xpl-pdp-10-source))
    (build-system gnu-build-system)
    (inputs (list bash-minimal))
    (native-inputs (list xpl-bootstrap))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (replace 'build
            (lambda _
              ;; The upstream makefile records the maintainer's macOS path.
              ;; Point it solely at the immutable bootstrap input instead.
              (substitute* "port/makefile"
                (("XPLDIR=/Users/linda/xpl")
                 (string-append "XPLDIR=" #$xpl-bootstrap))
                (("CFLAGS= -I \\$\\(XPLDIR\\)")
                 "CFLAGS= -I $(XPLDIR)/include")
                (("XPL=\\$\\(XPLDIR\\)/xpl")
                 "XPL=$(XPLDIR)/bin/xpl")
                (("LIBXPL=\\$\\(XPLDIR\\)/libxpl.a")
                 "LIBXPL=$(XPLDIR)/lib/libxpl.a"))
              (invoke "make" "-C" "port"
                      (string-append "CC=" #$(cc-for-target)))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec/pdp10-xpl"))
                    (data (string-append #$output "/share/pdp10-xpl")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (install-file "port/xpl" libexec)
                (install-file "port/xpl.lib" data)
                (install-file "port/hello.xpl" data)
                (install-file "COPYING" data)
                (call-with-output-file (string-append bin "/xpl")
                  (lambda (port)
                    (format port
                            "#!~a/bin/sh\nexec ~s -l ~s \"$@\"\n"
                            #$bash-minimal
                            (string-append libexec "/xpl")
                            (string-append data "/xpl.lib"))))
                (chmod (string-append bin "/xpl") #o555)))))))
    (synopsis "PDP-10 XPL compiler port")
    (description "PDP-10 XPL is a host compiler for the historical PDP-10
XPL dialect.  It is built with an isolated XPL-to-C bootstrap translator and
runs without a source checkout or network access.")
    (home-page "https://github.com/PDP-10/xpl-pdp-10")
    (license free-public-license)))
