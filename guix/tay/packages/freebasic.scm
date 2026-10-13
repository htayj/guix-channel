;;; FreeBASIC bootstrapped from generated C, then rebuilt from BASIC.

(define-module (tay packages freebasic)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages xorg))

(define-public freebasic
  (package
    (name "freebasic")
    (version "1.10.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://sourceforge/fbc/FreeBASIC-" version
                           "/Source/FreeBASIC-" version
                           "-source-bootstrap.tar.xz"))
       ;; Generated C compiler sources, not a binary compiler seed.  SHA-256:
       ;; 2fae2c66b435240d4de11bb534843baa188574508a8a5bdaa5020bf729bf0a3e
       (sha256
        (base32 "0ghapwlzf2q2lpd5p2laa1s8a65a7f239d8vw56hs91mnik2rbig"))
       (modules '((guix build utils) (ice-9 ftw)))
       (snippet
        #~(begin
            ;; Ship the complete compiler-owned BASIC/runtime API, not the
            ;; optional foreign-library bindings.  BASS/BASSMOD are explicitly
            ;; noncommercial, PDFlib is Aladdin-licensed, and old CRT and other
            ;; bindings prohibit redistribution without authorization.
            (let ((keep '("datetime.bi" "dir.bi" "fbc-int" "fbgfx.bi"
                          "fbio.bi" "fblimits.bi" "fbprng.bi" "fbthread.bi"
                          "file.bi" "string.bi" "utf_conv.bi" "vbcompat.bi")))
              (for-each
               (lambda (name)
                 (unless (or (member name '("." "..")) (member name keep))
                   (delete-file-recursively (string-append "inc/" name))))
               (scandir "inc")))
            ;; Unused external-library examples, non-Linux import definitions,
            ;; and the bundled Windows SWIG executable are not build inputs.
            (for-each delete-file-recursively
                      '("examples" "contrib/swig" "contrib/djgpp"
                        "lib/win32"))))))
    (build-system gnu-build-system)
    ;; This bootstrap's linux-x86_64 payload has been inspected as textual C.
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:make-flags
      #~(list (string-append "prefix=" #$output)
              "ENABLE_PREFIX=1" "ENABLE_STRIPALL=0"
              (string-append "CC=" #$gcc-toolchain-14 "/bin/gcc")
              (string-append "AR=" #$gcc-toolchain-14 "/bin/ar")
              (string-append "AS=" #$gcc-toolchain-14 "/bin/as"))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          ;; Run the compiler tests through its installed toolchain wrapper.
          (delete 'check)
          (add-after 'unpack 'use-store-libraries
            (lambda _
              ;; fbc invokes ld directly rather than linking through GCC.
              ;; Its usual Linux interpreter paths do not exist in Guix.
              (substitute* "src/compiler/fbc.bas"
                (("/lib64/ld-linux-x86-64\\.so\\.2")
                 (string-append #$gcc-toolchain-14
                                "/lib/ld-linux-x86-64.so.2")))
              ;; These dlopen calls otherwise depend on ambient search paths.
              ;; The static runtime/gfx archives retain the store references.
              (substitute* '("src/rtlib/linux/io_multikey.c"
                             "src/rtlib/unix/io_xfocus.c")
                (("\"libX11\\.so\"")
                 (string-append "\"" #$libx11 "/lib/libX11.so\"")))
              (substitute* "src/rtlib/linux/io_mouse.c"
                (("\"libgpm\\.so\\.2\"")
                 (string-append "\"" #$gpm "/lib/libgpm.so.2\"")))
              (substitute* "src/gfxlib2/unix/gfx_driver_opengl_x11.c"
                (("\"libGL\\.so\\.1\"")
                 (string-append "\"" #$mesa "/lib/libGL.so.1\"")))))
          (replace 'build
            (lambda* (#:key make-flags parallel-build? #:allow-other-keys)
              (let* ((jobs (if parallel-build? (number->string (parallel-job-count)) "1"))
                     (libpaths
                      (map (lambda (input) (string-append input "/lib"))
                           (list #$gcc-toolchain-14 #$ncurses #$libffi
                                 #$libx11 #$libxext #$libxpm #$libxrandr
                                 #$libxrender)))
                     (bootstrap-flags
                      (string-append
                       " -i " (getcwd) "/inc -prefix " (getcwd)
                       (apply string-append
                              (map (lambda (dir) (string-append " -p " dir)) libpaths))
                       " -Wl -dynamic-linker,"
                       #$gcc-toolchain-14 "/lib/ld-linux-x86-64.so.2")))
                (for-each
                 (lambda (tool)
                   (setenv (string-upcase tool)
                           (string-append #$gcc-toolchain-14 "/bin/" tool)))
                 '("gcc" "as" "ar" "ld"))
                ;; Stage 1: GCC builds the generated C and a minimal rtlib.
                (apply invoke "make" "bootstrap-minimal" "-j" jobs make-flags)
                ;; Keep bootstrap/fbc, but discard EVERY minimal runtime object,
                ;; including PIC and MT variants, so stage 2 has X11/FFI/GPM.
                (delete-file-recursively "src/rtlib/obj")
                (delete-file-recursively "lib/freebasic/linux-x86_64")
                (delete-file "bin/fbc")
                ;; Stage 2: every compiler module is compiled from its .bas
                ;; source by the source-built bootstrap; rtlib and gfx are full.
                ;; The upstream compiler target does not depend on rtlib, so
                ;; build the complete link libraries before its parallel link.
                (apply invoke "make" "rtlib" "gfxlib2" "-j" jobs make-flags)
                (apply invoke "make" "compiler" "-j" jobs
                       (string-append "FBC=" (getcwd) "/bootstrap/fbc"
                                      bootstrap-flags)
                       make-flags))))
          (add-after 'install 'install-notices-and-font
            (lambda _
              (let ((doc (string-append #$output "/share/doc/freebasic")))
                (for-each (lambda (file) (install-file file doc))
                          '("readme.txt" "changelog.txt" "doc/gpl.txt"
                            "doc/lgpl.txt" "doc/fdl-1.2.txt"
                            "doc/libffi-license.txt")))
              (install-file "doc/fbc.1" (string-append #$output "/share/man/man1"))
              (install-file "src/gfxlib2/gfxdata/fnt08x08.fnt"
                            (string-append #$output "/share/freebasic"))))
          (add-after 'install-notices-and-font 'provide-native-toolchain
            (lambda _
              ;; Normal fbc discovers headers and rtlib through ENABLE_PREFIX,
              ;; tools through GCC/AS/AR/LD, and CRT objects by querying GCC.
              ;; Supply library -p paths as well: ld does not use LIBRARY_PATH.
              ;; Guix's ld wrapper adds RUNPATH for the libraries actually used.
              (let* ((program (string-append #$output "/bin/fbc"))
                     (real (string-append #$output "/libexec/fbc"))
                     (toolchain (string-append #$gcc-toolchain-14 "/bin/"))
                     (libpaths
                      (map (lambda (input) (string-append input "/lib"))
                           (list #$gcc-toolchain-14 #$ncurses #$libffi
                                 #$libx11 #$libxext #$libxpm #$libxrandr
                                 #$libxrender))))
                (mkdir-p (dirname real))
                (rename-file program real)
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a~%set -eu~%"
                            #$(file-append bash-minimal "/bin/sh"))
                    (for-each
                     (lambda (tool)
                       (format port ": \"${~a:=~a~a}\"~%export ~a~%"
                               (string-upcase tool) toolchain tool
                               (string-upcase tool)))
                     '("gcc" "as" "ar" "ld"))
                    (format port "exec ~s" real)
                    (for-each (lambda (dir) (format port " -p ~s" dir)) libpaths)
                    (display " \"$@\"\n" port)))
                (chmod program #o555))))
          (add-after 'provide-native-toolchain 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (setenv "FBC" (string-append #$output "/bin/fbc"))
                (with-directory-excursion "tests"
                  ;; fbcunit is bundled, but itself requires the omitted CRT
                  ;; bindings.  Run the four upstream dialect log suites,
                  ;; including their compile-and-run and multi-module cases.
                  ;; Upstream otherwise records failures without failing make.
                  (invoke "make" "log-tests"
                          (string-append "FBC=" (getenv "FBC"))
                          "ABORT_CMD=false")
                  (for-each
                   (lambda (suite)
                     (with-directory-excursion suite
                       (copy-recursively "r/linux-x86_64" "expected")
                       ;; Only this native target's snapshot is relevant.
                       (substitute* "test.sh"
                         (("run_tests (dos|linux-x86|win32|win64)\n") ""))
                       (invoke "bash" "test.sh")
                       (invoke "diff" "-ru" "expected" "r/linux-x86_64")))
                   '("warnings" "syntax")))))))))
    (inputs (list bash-minimal gcc-toolchain-14 ncurses libffi gpm mesa
                  libx11 libxext libxpm libxrandr libxrender))
    (home-page "https://www.freebasic.net/")
    (synopsis "BASIC compiler and runtime libraries")
    (description
     "FreeBASIC is a native BASIC compiler with C interoperability.  This
package builds the release's generated C bootstrap with GCC, then rebuilds the
compiler from its BASIC sources.  It includes the runtime, X11 graphics static
libraries, the compiler-owned BASIC include files, and a native Guix toolchain
configuration.  Optional third-party C-library bindings are omitted: some are
nonfree or carry unresolved redistribution restrictions.  The native BASIC
API, including graphics and Visual Basic compatibility, is retained.")
    ;; readme.txt:115-142 states the static-linking exception for rtlib/gfxlib2;
    ;; that exception and the original notices are installed without alteration.
    (license (list license:gpl2+ license:lgpl2.0+ license:fdl1.2+))))
