;;; Autolith -- source-built live Common Lisp agent.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages autolith)
  #:use-module (guix build-system asdf)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages virtualization)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages autolith-dependencies)
  #:use-module (tay packages autolith-native))

(define (autolith-file name)
  (local-file (search-tay-package-file (string-append "files/autolith-" name))))

(define-public autolith
  ;; Every Lisp library, including transitive Guix libraries, must use the
  ;; pinned runtime.  FASLs made by the channel's default SBCL are incompatible.
  (autolith-lisp-package
   (package
     (name "autolith")
     (version "0.66.0")
     (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://codeload.github.com/lambda-symbolics/autolith/tar.gz/"
              "68db763eaae60f5e930c195eba4c76ac029b0781"))
        (file-name (string-append "autolith-" version ".tar.gz"))
        (patches
         (list (search-tay-package-file "files/autolith-tests.patch")))
        (sha256
         (base32 "00xa6ikpz0a783iasql98nkbp8gacfvyw9rldk8i68hg8zk87cw4"))))
     (build-system asdf-build-system/sbcl)
     (arguments
      (list
       #:lisp sbcl-autolith-runtime
       #:asd-systems
       ''("autolith" "autolith/tests" "autolith/structural" "autolith/debug"
          "autolith/release-server" "autolith/structural/tests"
          "autolith/debug/tests")
       #:phases
       #~(modify-phases %standard-phases
           ;; The real check runs below, after installed provenance and image
           ;; construction; the ordinary early ASDF test-op lacks those inputs.
           (delete 'check)
           (replace 'build
             (lambda args
               ;; Keep the standard ASDF build and compiler.  Only this
               ;; invocation loads the SBCL 2.6.6 metadata-order repair;
               ;; neither the wrapper nor the hook enters the runtime image.
               (use-modules (guix build lisp-utils))
               (let ((wrapper (string-append (getcwd) "/.autolith-compile-sbcl")))
                 (call-with-output-file wrapper
                   (lambda (port)
                     (format port "#!~a~%exec ~a --load ~a \"$@\"~%"
                             #$(file-append bash-minimal "/bin/sh")
                             (%lisp)
                             #$(autolith-file "compile.lisp"))))
                 (chmod wrapper #o555)
                 (dynamic-wind
                   (const #t)
                   (lambda ()
                     (parameterize ((%lisp wrapper))
                       (apply (assoc-ref %standard-phases 'build) args)))
                   (lambda () (delete-file wrapper))))))
           (add-before 'copy-source 'prepare-guix-source
             (lambda _
               (mkdir-p ".qlot")
               (copy-file #$(autolith-file "setup.lisp") ".qlot/setup.lisp")
               ;; Retain upstream's immutable installation protocol rather than
               ;; accidentally treating /gnu/store as a writable checkout.
               (substitute* "bin/autolith"
                 (("/nix/store/\\*") "/gnu/store/*"))
               ;; patch-shebangs cannot see interpreter paths inside Lisp
               ;; strings used to generate executable fixtures or spawn pipes.
               ;; Apply the same POSIX shell selection to those real commands;
               ;; do not change or bypass any behavioral assertions.
               (substitute* (cons "src/core/platform-posix.lisp"
                                  (find-files "tests" "\\.lisp$"))
                 (("/bin/sh") #$(file-append bash-minimal "/bin/sh")))
               ;; These fixture wrappers deliberately bypass PATH to avoid
               ;; recursively invoking themselves.  Preserve that property
               ;; while selecting their actual Guix coreutils executables.
               (substitute* "tests/release-script-tests.lisp"
                 (("/usr/bin/readlink")
                  #$(file-append coreutils-minimal "/bin/readlink"))
                 (("/bin/chmod")
                  #$(file-append coreutils-minimal "/bin/chmod"))
                 (("/bin/mv")
                  #$(file-append coreutils-minimal "/bin/mv"))
                 (("/bin/rm")
                  #$(file-append coreutils-minimal "/bin/rm")))
               ;; Bootstrap fixtures intentionally exclude the real SBCL from
               ;; PATH.  Supply only the mundane command directories they
               ;; formerly expected in /bin and /usr/bin, retaining fake SBCL
               ;; and uname precedence and the missing-host-compiler tests.
               (substitute* "tests/release-script-tests.lisp"
                 (("~A:/bin:/usr/bin")
                  (string-append "~A:"
                                 #$(file-append coreutils-minimal "/bin") ":"
                                 #$(file-append grep "/bin") ":"
                                 #$(file-append bash-minimal "/bin"))))
               ;; Release tooling probes the shell's libc too.  The packaged
               ;; source must not assume an FHS shell exists on the host.
               (substitute* '("bin/autolith-release" "script/install"
                              "script/build-release-runtime"
                              "script/build-static-release-runtime"
                              "script/ci-package-release"
                              "server/release-archive.lisp")
                 (("ldd /bin/sh")
                  (string-append "ldd "
                                 #$(file-append bash-minimal "/bin/sh"))))
               (substitute* "src/state/updates.lisp"
                 (("\\(uiop:string-prefix-p \"/nix/store/\" name\\)")
                  "(or (uiop:string-prefix-p \"/nix/store/\" name) (uiop:string-prefix-p \"/gnu/store/\" name))"))
               (substitute* '("src/application/commands.lisp"
                              "src/startup/main.lisp")
                 (("installed through Nix") "installed through Guix")
                 (("Installed through Nix") "Installed through Guix")
                 (("the flake or profile") "the Guix channel and profile")
                 (("source or Nix updates") "source or Guix updates")
                 (("Nix installations") "Guix installations")
                 (("their flake or Nix profile") "their Guix channel and profile"))
               (substitute* "script/launcher-cli.sh"
                 (("Update this Nix installation through your flake or Nix profile\\.")
                  "Update this Guix installation through your Guix channel and profile.")
                 (("Nix installations: update through your flake or Nix profile\\.")
                  "Guix installations: update through your Guix channel and profile.")
                 (("Remove the package from your flake or Nix profile to finish\\.")
                  "Remove the package from your Guix profile to finish.")
                 (("current-generation.sexp update-state.sexp")
                  "guix current-generation.sexp update-state.sexp"))))
           (add-before 'build 'set-native-helper-environment
             (lambda _
               (setenv "COLORLISP_NATIVE_LIBRARY"
                       #$(file-append autolith-colorlisp-native
                                      "/lib/libcolorlisp-tree-sitter.so"))
               (setenv "AUTOLITH_FFF_LIBRARY"
                       #$(file-append autolith-fff-c "/lib/libfff_c.so"))
               (setenv "CL_EXEC_SANDBOX_PROCESS_GROUP_HELPER"
                       #$(file-append autolith-sandbox-helper
                                      "/libexec/cl-exec-sandbox-process-group"))
               (setenv "CL_EXEC_SANDBOX_HELPER"
                       #$(file-append autolith-sandbox-helper
                                      "/libexec/cl-exec-sandbox-helper"))
               (setenv "CL_EXEC_SANDBOX_BWRAP"
                       #$(file-append bubblewrap "/bin/bwrap"))))
           (add-after 'create-asdf-configuration 'install-guix-launcher
             (lambda _
               (let* ((out #$output)
                      (source (string-append
                               out "/share/common-lisp/sbcl/autolith"))
                      (libexec (string-append out "/libexec"))
                      (runtime-path
                       (string-join
                        (list (string-append #$bash-minimal "/bin")
                              (string-append #$coreutils-minimal "/bin")
                              (string-append #$git-minimal "/bin")
                              (string-append #$grep "/bin")
                              (string-append #$gawk "/bin")
                              (string-append #$ast-grep "/bin")
                              (string-append #$openssl "/bin")
                              (string-append #$util-linux "/bin")
                              (string-append #$bubblewrap "/bin")
                              (string-append #$sbcl-autolith-runtime "/bin"))
                        ":")))
                 (mkdir-p libexec)
                 (mkdir-p (string-append out "/bin"))
                 (for-each
                  (lambda (template target)
                    (copy-file template target)
                    (substitute* target
                      (("@bash@") #$(file-append bash-minimal "/bin/bash"))
                      (("@out@") out)
                      (("@source@") source)
                      (("@identity@") (basename out))
                      (("@runtime-path@") runtime-path)
                      (("@sbcl@") #$(file-append sbcl-autolith-runtime "/bin/sbcl"))
                      (("@sbcl-source@") #$autolith-sbcl-source-tree)
                      (("@colorlisp@") #$autolith-colorlisp-native)
                      (("@fff@") #$autolith-fff-c)
                      (("@sandbox@") #$autolith-sandbox-helper)
                      (("@bwrap@") #$bubblewrap)
                      (("@ast-grep@") #$(file-append ast-grep "/bin/ast-grep"))
                      (("@flock@") #$(file-append util-linux "/bin/flock")))
                    (chmod target #o555))
                  (list #$(autolith-file "environment.sh")
                        #$(autolith-file "materialize.sh")
                        #$(autolith-file "launcher.sh"))
                  (list (string-append libexec "/autolith-environment.sh")
                        (string-append libexec "/autolith-materialize")
                        (string-append out "/bin/autolith")))
                 (copy-file #$(autolith-file "check.lisp")
                            (string-append libexec "/autolith-check.lisp"))
                 (install-file "LICENSE" (string-append out "/share/doc/autolith")))))
           ;; Run after Guix's shebang rewriting, so provenance describes the
           ;; installed tree exactly.  No SBCL core is ever a store artifact.
           (add-after 'patch-shebangs 'record-source-provenance
             (lambda _
               (let ((source (string-append
                              #$output "/share/common-lisp/sbcl/autolith")))
                 (with-directory-excursion source
                   (setenv "GIT_CONFIG_NOSYSTEM" "1")
                   (setenv "GIT_CONFIG_GLOBAL" "/dev/null")
                   (setenv "GIT_AUTHOR_DATE" "2000-01-01T00:00:00Z")
                   (setenv "GIT_COMMITTER_DATE" "2000-01-01T00:00:00Z")
                   (invoke "git" "init" "--quiet" "--initial-branch=master")
                   (invoke "git" "config" "user.name" "Autolith Guix build")
                   (invoke "git" "config" "user.email" "guix-build@localhost")
                   (invoke "git" "config" "gc.auto" "0")
                   (invoke "git" "config" "maintenance.auto" "false")
                   (invoke "git" "add" "--all")
                   (invoke "git" "commit" "--quiet" "--message"
                           "Autolith v0.66.0 source 68db763eaae60f5e930c195eba4c76ac029b0781")
                   ;; Eliminate build-host stat information from the index.
                   (delete-file ".git/index")
                   (invoke "git" "read-tree" "HEAD")
                   (invoke "git" "gc" "--quiet" "--prune=now")))))
           (add-after 'record-source-provenance 'validate-transient-images
             (lambda* (#:key tests? #:allow-other-keys)
               (let ((work (string-append (getcwd) "/.image-validation"))
                     (out #$output))
                 (mkdir-p work)
                 (dynamic-wind
                   (lambda () #t)
                   (lambda ()
                     (invoke
                      #$(file-append bash-minimal "/bin/bash") "-eu" "-c"
                      (string-append
                       "source \"$1/libexec/autolith-environment.sh\"\n"
                       "export AUTOLITH_ASDF_CACHE=\"$2/asdf-cache\"\n"
                       "mkdir -p \"$AUTOLITH_ASDF_CACHE\" \"$2/images\"\n"
                       "mkdir -p \"$2/home\" \"$2/config\" \"$2/data\" \"$2/state\" \"$2/cache\"\n"
                       "export HOME=\"$2/home\" XDG_CONFIG_HOME=\"$2/config\" XDG_DATA_HOME=\"$2/data\" XDG_STATE_HOME=\"$2/state\" XDG_CACHE_HOME=\"$2/cache\"\n"
                       "\"$1/libexec/autolith-materialize\" \"$2/images\" \"$2/images/validated\"\n"
                       "export AUTOLITH_ACTIVE_CORE=\"$2/images/validated/active/autolith-active.core\"\n"
                       "export AUTOLITH_RECOVERY_CORE=\"$2/images/validated/recovery/autolith-recovery.core\"\n"
                       (if tests?
                           "\"$AUTOLITH_SBCL\" --script \"$1/libexec/autolith-check.lisp\"\n"
                           ""))
                      "autolith-image-validation" out work)
                     (call-with-output-file
                         (string-append out "/share/doc/autolith/image-validation")
                       (lambda (port)
                         (display "Active and recovery image construction and probes validated.\n"
                                  port))))
                   (lambda () (delete-file-recursively work)))))))))
     (native-inputs (list git-minimal))
     (inputs
      (append
       (list bash-minimal coreutils-minimal git-minimal grep gawk util-linux bubblewrap
             ast-grep openssl
             sbcl-autolith-runtime autolith-sbcl-source-tree
             autolith-colorlisp-native autolith-sandbox-helper autolith-fff-c)
       %autolith-lisp-inputs))
     (supported-systems '("x86_64-linux" "aarch64-linux"))
     (home-page "https://github.com/lambda-symbolics/autolith")
     (synopsis "Live self-modifying Common Lisp agent")
     (description
      "Autolith is a live Common Lisp terminal agent with structural editing,
provider integrations, native syntax highlighting, sandboxed tools, a debugger,
and persistent mutation and recovery images.  This package builds pinned Git
Lisp dependencies and Guix libraries from source with SBCL 2.6.6, without Qlot
network bootstrap.
The immutable store contains sources and reproducible compiled Lisp files, not
saved cores.  Active and pristine recovery cores are validated during the build
and materialized on first use under XDG_STATE_HOME/autolith/guix, keyed by the
Guix derivation identity.  Conversations and private mutation history retain
their upstream XDG locations.  Upstream's nix installation kind supplies the
immutable-package behavior; Guix channel/profile operations manage upgrades.")
     (license license:isc))))
