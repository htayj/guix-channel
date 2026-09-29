;;; GNU Guix package for the hosted Modus Common Lisp implementation.

(define-module (tay packages modus)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages lisp))

(define-public modus
  (let ((commit "501f2ee2069e98210627e53ce487f23eabca9032")
        (revision "0"))
    (package
      (name "modus")
      ;; modus.asd declares version 0.2.0 at this default-branch revision.
      (version (git-version "0.2.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/modus-lisp/modus")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "15mryl2w1jl2wpada90rl67lraj7jb5jngbfbrbsbsqxlvi3r5fj"))))
      (build-system gnu-build-system)
      (arguments
       (list
        ;; The executable is a hand-assembled static ELF image (one RWE LOAD
        ;; segment whose memory size far exceeds its file size) with no
        ;; dynamic section.  Binutils must not rewrite it, and there is no
        ;; RUNPATH to validate.
        #:strip-binaries? #f
        #:validate-runpath? #f
        #:phases
        #~(modify-phases %standard-phases
            (delete 'configure)
            (add-after 'unpack 'use-store-chmod
              (lambda _
                ;; The image writer marks its output executable through a
                ;; hard-coded FHS path that does not exist in the build
                ;; environment.
                (substitute* "mvm/build-generic-cli.lisp"
                  (("\"/bin/chmod\"")
                   (string-append "\"" (which "chmod") "\"")))))
            (replace 'build
              (lambda _
                ;; Upstream's canonical hosted x86-64 Linux image build.  SBCL
                ;; cross-compiles Modus's own sources into a standalone ELF.
                ;; MODUS_NO_JIT is upstream's documented rollback to the
                ;; pure-interpreter image: the default JIT image prints its
                ;; translator initialization diagnostics on stdout at every
                ;; start, which breaks the SBCL-faithful silent --eval and
                ;; exact script output.  The interpreter build is
                ;; byte-for-byte reproducible.
                (setenv "MODUS_NO_JIT" "1")
                (setenv "MODUS_CLI_OUT" (string-append (getcwd) "/modus-cli"))
                (invoke "sbcl" "--dynamic-space-size" "4096"
                        "--script" "mvm/build-generic-cli.lisp")))
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                ;; Upstream's test suites boot images under QEMU.  Instead,
                ;; require the freshly built evaluator to compute a result and
                ;; exit successfully; an --eval error exits nonzero.
                (when tests?
                  (invoke "./modus-cli" "--noinform" "--no-userinit"
                          "--no-sysinit" "--non-interactive" "--eval"
                          "(unless (= (+ 1 2) 3) (error \"self-check failed\"))"))))
            (delete 'install-license-files)
            (replace 'install
              (lambda _
                (let* ((out #$output)
                       (bin (string-append out "/bin"))
                       (share (string-append out "/share/modus/"))
                       (setup (string-append share
                                             "modus-quicklisp/setup.lisp"))
                       (doc (string-append out "/share/doc/modus"))
                       (notices (string-append doc "/third-party-notices"))
                       (unpacked "sha1-notice"))
                  (mkdir-p bin)
                  (copy-file "modus-cli" (string-append bin "/modus"))
                  (chmod (string-append bin "/modus") #o555)
                  ;; The documented runtime Quicklisp step loads this setup
                  ;; file, which reads the bundled offline systems/*.tar.
                  ;; Upstream resolves both relative to the process working
                  ;; directory (the repository root); default the root to the
                  ;; installed assets instead.  It remains a DEFVAR, so a
                  ;; caller may still bind another root first.
                  (install-file "modus-quicklisp/setup.lisp"
                                (string-append share "modus-quicklisp"))
                  (install-file "systems/sha1.tar"
                                (string-append share "systems"))
                  (substitute* setup
                    (("^\\(defvar \\*modus-quicklisp-root\\* \"\"\\)")
                     (string-append "(defvar *modus-quicklisp-root* \""
                                    share "\")")))
                  (mkdir-p doc)
                  (for-each (lambda (file) (install-file file doc))
                            '("LICENSE" "README.md" "QUICKLOAD.md"))
                  ;; The bundled sha1 system carries its own Apache notice.
                  (mkdir-p unpacked)
                  (invoke "tar" "-C" unpacked "-xf" "systems/sha1.tar"
                          "sha1-20211020-git/LICENSE.txt")
                  (mkdir-p notices)
                  (copy-file (string-append
                              unpacked "/sha1-20211020-git/LICENSE.txt")
                             (string-append notices "/sha1-LICENSE.txt"))))))))
      (native-inputs (list sbcl))
      ;; The build emits an x86-64 Linux ELF image only.
      (supported-systems '("x86_64-linux"))
      (home-page "https://github.com/modus-lisp/modus")
      (synopsis "Self-hosting Common Lisp implementation with a hosted CLI")
      (description
       "Modus is a Common Lisp implementation that compiles to its own MVM
bytecode and native code and can rebuild itself.  This package builds the
hosted x86-64 Linux @command{modus} executable from source with SBCL.  The
executable runs as an ordinary process with an SBCL-style command line
(@option{--eval}, @option{--load}, @option{--script}, @option{--non-interactive})
and an interactive REPL.  As with SBCL, @option{--eval} prints nothing unless
the evaluated form writes output.  The offline Quicklisp-style loader and its
bundled @code{sha1} system are installed under @file{share/modus}.  QEMU and
bare-metal images are not included.")
      ;; Modus is MIT (Expat); the installed systems/sha1.tar is Apache 2.0.
      (license (list license:expat license:asl2.0)))))
