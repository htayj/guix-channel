;;; GNU Guix package for WeiDU.

(define-module (tay packages weidu)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages base)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages perl)
  #:use-module (tay packages starred-s-z))

;; WeiDU's makefiles invoke Elkhound to generate its GLR parsers.  Build the
;; generator from its fixed source rather than using upstream CI's moving,
;; prebuilt archive.
(define elkhound-for-weidu
  (package
    (name "elkhound-for-weidu")
    (version "0-b8f5589")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/WeiDUorg/elkhound")
             (commit "b8f5589de119c89b36b1fc21d2f51c4a942ee3a8")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "04hypc95nnvab8nzxy76vvsbf7061wajn3rh6kn5rvwq24m2sjgj"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      #:configure-flags #~(list "-DEXTRAS=OFF" "-DOCAML=OFF")
      #:phases
      #~(modify-phases %standard-phases
          ;; CMake's project root is the upstream src directory.
          (add-before 'configure 'enter-source-directory
            (lambda _ (chdir "src")))
          ;; Elkhound has no CMake install target.  Its sole required build
          ;; product is the parser generator used while compiling WeiDU.
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin")))
                (mkdir-p bin)
                (install-file "elkhound/elkhound" bin)))))))
    (native-inputs (list bison cmake-minimal flex gcc-toolchain))
    (home-page "https://github.com/WeiDUorg/elkhound")
    (synopsis "GLR parser generator for building WeiDU")
    (description
     "Elkhound is a GLR parser generator.  This private package builds only
the generator needed by WeiDU, without optional extras or OCaml tests.")
    ;; The root license is 3-clause BSD; src/smbase is public domain.
    (license license:bsd-3)))

;; WeiDU's fixed Makefile and its parser-generation scripts require OCaml's
;; historical mutable-string mode.  Rebuild Guix's pinned 4.14.3 source with
;; that upstream-supported mode rather than using a different compiler or a
;; downloaded binary.
(define ocaml-4.14-unsafe-string
  (package
    (inherit ocaml-4.14)
    (name "ocaml-4.14-unsafe-string")
    (arguments
     (substitute-keyword-arguments (package-arguments ocaml-4.14)
       ((#:tests? _ #t) #f)
       ((#:configure-flags flags #~'())
        #~(cons "--disable-force-safe-string" #$flags))))))

(define-public weidu
  (package
    (name "weidu")
    ;; src/version.ml identifies this fixed development revision as 252.01.
    (version "252.01")
    (source (package-source weiduorg-weidu-source))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no offline automated suite.  tests/weidu-smoke.sh
      ;; exercises the installed binary and an offline TP2 installation.
      #:tests? #f
      ;; The dependency file omits an edge from tlexer to the parser emitted
      ;; by Elkhound, so parallel make can race that generated module.
      #:parallel-build? #f
      #:make-flags #~(list "weidu")
      #:phases
      #~(modify-phases %standard-phases
          ;; This is a makefile-only project.
          (delete 'configure)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/weidu"))
                     (notices (string-append doc "/third-party-notices")))
                (mkdir-p bin)
                ;; The Linux make target deliberately produces just this one
                ;; executable.  Do not build the updater aliases, archives,
                ;; or documentation targets.
                (install-file "obj/x86_LINUX/weidu.asm.exe" bin)
                (chmod (string-append bin "/weidu.asm.exe") #o555)
                (rename-file (string-append bin "/weidu.asm.exe")
                             (string-append bin "/weidu"))
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "README.md" "README-WeiDU-Changes.txt"))
                ;; Preserve the separately identified bundled notices next
                ;; to the GPL notice.  The fcaseopen notice also remains in
                ;; the installed program's --licence output.
                (mkdir-p notices)
                (install-file "elkhound/license.txt" notices)
                (install-file "fcase/fcase.c" notices)))))))
    ;; WeiDU's pinned Makefile supplies its required -unsafe-string flags
    ;; itself and discovers the source-built Elkhound through PATH.
    (native-inputs (list elkhound-for-weidu ocaml-4.14-unsafe-string perl which))
    (home-page "https://github.com/WeiDUorg/weidu")
    (synopsis "Infinity Engine modding tool")
    (description
     "WeiDU is a command-line tool for installing, uninstalling, and
developing modifications for Infinity Engine games.  It reads game and mod
files from the current directory and writes its logs, backups, and generated
files there.  This package builds the upstream source with a pinned,
source-built Elkhound parser generator and installs only the @command{weidu}
executable; it includes no game data, updater, service, or network client.")
    (license (list license:gpl2 license:bsd-3 license:expat license:lgpl2.1))))
