;;; Hash-pinned official Bun runtime for Bun-based plugin builds.
(define-module (tay packages bun-runtime)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages base)
  #:use-module (gnu packages python)
  #:use-module (gnu packages compression)
  #:use-module (tay packages auxiliary))

(define %bun-commit "0d9b296af33f2b851fcbf4df3e9ec89751734ba4")

(define (bun-release-origin system)
  (let* ((arm? (target-aarch64? system))
         (archive (if arm? "bun-linux-aarch64" "bun-linux-x64-baseline"))
         (hash (if arm?
                   "0fwsl5rijcv53j17rhw8ig8xia3zw656cvqdds1pa0rim1iznzx2"
                   "1iz66qxxfr9xx3f0557vx2ydlggdrv3bv6wk23554y4bw2590qx0")))
    (origin
      (method url-fetch)
      (uri (string-append "https://github.com/oven-sh/bun/releases/download/"
                          "bun-v1.3.14/" archive ".zip"))
      (file-name (string-append archive "-1.3.14.zip"))
      (sha256 (base32 hash)))))

(define-public bun-runtime
  (package
    (name "bun-runtime")
    (version "1.3.14")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/oven-sh/bun/tar.gz/"
                           %bun-commit))
       (file-name "bun-1.3.14-source.tar.gz")
       (sha256 (base32 "1rfkg1lsz9k0n6qyn5k470i36fxbx9rqlba5v0gb8gnx7lgmq15a"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      ;; Preserve Bun's fixed-address ELF layout.  Shared libraries are supplied
      ;; by the inherited wrapper environment rather than a rewritten RUNPATH.
      ;; The exact DT_NEEDED set is checked against glibc and its loader verifies
      ;; the resulting ELF during install; ordinary RUNPATH validation does not
      ;; model this deliberately environment-supplied closure.
      #:validate-runpath? #f
      #:install-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((bin (string-append #$output "/bin"))
                    (raw (string-append #$output "/libexec/bun"))
                    (doc (string-append #$output "/share/doc/bun-runtime")))
                (mkdir-p "release")
                (invoke "unzip" "-q" (assoc-ref inputs "bun-binary") "-d" "release")
                (mkdir-p (dirname raw))
                (copy-file (car (find-files "release" "^bun$")) raw)
                (chmod raw #o755)
                ;; The bounded helper expands PT_INTERP across adjacent optional
                ;; ELF notes without moving any mapped segment or dynamic table.
                ;; Raw process.execPath children inherit the same libc search path.
                (invoke "python3"
                        #$(local-file (search-tay-package-file
                                       "files/bun-elf-interpreter.py"))
                        raw (search-input-file inputs #$(glibc-dynamic-linker)))
                ;; This is the independent loader check for the exact declared
                ;; DT_NEEDED closure validated by the ELF helper.
                (invoke (search-input-file inputs #$(glibc-dynamic-linker))
                        "--verify" raw)
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/bun")
                  (lambda (port)
                    (format port
                            (string-append "#!/bin/sh\n"
                                           "export LD_LIBRARY_PATH=~a/lib"
                                           "${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\n"
                                           "exec ~a \"$@\"\n")
                            (assoc-ref inputs "glibc") raw)))
                (chmod (string-append bin "/bun") #o555)
                (install-file "LICENSE.md" doc)
                ;; Retain all notices present in the exact release source,
                ;; preserving paths rather than conflating unrelated grants.
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/source-notices/" file)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 (find-files "." "^(LICENSE|COPYING|NOTICE)(\\..*)?$"))
                (call-with-output-file (string-append doc "/PROVENANCE")
                  (lambda (port)
                    (format port
                            (string-append
                             "Official Bun bun-v1.3.14 release executable.\n"
                             "Source commit: ~a\n"
                             "The executable is not rebuilt by Guix.\n"
                             "LICENSE.md records linked libraries and "
                             "upstream relinking instructions.\n"
                             "Upstream names its JavaScriptCore/WebKit "
                             "corresponding-source repository: "
                             "https://github.com/oven-sh/webkit\n"
                             "The release archive has no third-party notice "
                             "bundle or object files; this package retains "
                             "notices present in Bun source, not a complete "
                             "independently audited static-link closure.\n")
                            #$%bun-commit)))))))))
    (native-inputs (list unzip python-minimal))
    (inputs
     `(("bun-binary" ,(bun-release-origin (or (%current-target-system)
                                             (%current-system))))
       ("glibc" ,glibc)))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (synopsis "Official Bun JavaScript runtime and bundler")
    (description
     "This package installs the official, hash-pinned Bun 1.3.14 GNU/Linux
executable, using the x86-64 baseline variant where applicable.  It is not a
Guix source rebuild.  The exact release-source notices and upstream linked
library/relinking documentation are retained.  The release archive has no
third-party notice bundle or relinkable object files; this package does not
claim a complete independently audited static-link closure.  The interpreter
is replaced within existing optional ELF-note space without relocating mapped
segments.  The wrapper supplies glibc through an inherited library search path;
this may affect user-selected native child programs.  Bun includes JavaScriptCore
and other statically linked libraries.  Its package manager and network access
remain ordinary user-selected runtime capabilities.")
    (home-page "https://bun.sh/")
    (license (list license:expat license:lgpl2.0 license:lgpl2.1
                   license:bsd-2 license:bsd-3 license:asl2.0 license:zlib
                   license:isc))))
