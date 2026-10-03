;;; Native, self-hosted lbForth with its pinned Lisp bootstrap.

(define-module (tay packages lbforth)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages lisp))

(define-public lbforth
  (package
    (name "lbforth")
    (version "0-20230213")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/larsbrinkhoff/lbForth")
             (commit "912433b150b64252070116a5fd5c1a29ff29b26d")
             ;; forth-metacompiler: 40b99c09628f616d94649009ba9894340088d77c.
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0g7jzaw3yijnm8rkgqsrhhx63r3v45700mp1ycyh50hs5awqh7in"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-offline-bootstrap
            (lambda _
              ;; The recursive origin supplies the bootstrap.  Never let make
              ;; fetch it, even if an input is unexpectedly incomplete.
              (substitute* "targets/c/bootstrap.mk"
                (("git submodule update --init")
                 "test -f lisp/meta.lisp"))
              (substitute* "targets/c/forth.mk"
                (("echo .*: sysdir.* >> \\$@")
                 "echo ': sysdir s\" $(sysdir)/\" ;' >> $@"))
              ;; Search-path entries are dictionary names, truncated to 15
              ;; bytes on this target.  Open SYSDir directly so an absolute
              ;; store path is not truncated or resolved relative to cwd.
              (substitute* "src/kernel.fth"
                (("   s\" src/\" searched.*") "")
                (("   sysdir searched") "")
                ((": search-file .* ;")
                 (string-append
                  ": search-file 2dup sysdir here 0 +string +string "
                  "r/o open-file ?include if "
                  "['] search-paths ['] ?open traverse-wordlist ?error "
                  "else drop then ;")))
              (setenv "HOME" (getcwd))))
          (replace 'build
            (lambda _
              ;; The bootstrap must load the unpacked sources.  Its makefile
              ;; removes generated target.fth before the self-hosting stage,
              ;; which then embeds the final absolute runtime source path.
              (invoke "make" "b-forth" "TARGET=c" "M32=" "sysdir=src")
              (invoke "make" "c-forth" "TARGET=c" "M32="
                      (string-append "sysdir=" #$output "/share/lbForth"))))
          (delete 'check)
          (replace 'install
            (lambda _
              (let ((share (string-append #$output "/share/lbForth")))
                (install-file "c-forth" (string-append #$output "/bin"))
                (rename-file (string-append #$output "/bin/c-forth")
                             (string-append #$output "/bin/forth"))
                (copy-recursively "src" share)
                (copy-recursively "lib" (string-append share "/lib"))
                (copy-recursively "targets" (string-append share "/targets"))
                (for-each
                 (lambda (file)
                   (install-file file
                                 (string-append #$output "/share/doc/lbforth")))
                 '("LICENSE" "README.md" "INSTALL")))))
          (add-after 'install 'check-installed-host
            (lambda* (#:key tests? #:allow-other-keys)
              ;; The self-hosted kernel now loads the installed share files.
              ;; This is the native host suite, not cross-target executables.
              (when tests?
                (invoke "make" "test-standard" "test-image" "test-lib"
                        "TARGET=c" "M32="
                        (string-append "sysdir=" #$output "/share/lbForth"))))))))
    (native-inputs (list sbcl))
    (home-page "https://github.com/larsbrinkhoff/lbForth")
    (synopsis "Self-hosted Forth interpreter")
    (description
     "lbForth implements a subset of Forth94 and can regenerate its kernel
from Forth source.  This package bootstraps the portable C target with the
pinned Common Lisp metacompiler, then builds the self-hosted interpreter.
The installed @command{forth} loads its system wordsets from its immutable
store directory and can run from outside the source checkout.")
    (license license:gpl3)))
