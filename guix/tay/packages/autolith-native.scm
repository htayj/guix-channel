;;; Native libraries and execution helpers pinned by Autolith v0.66.0.

(define-module (tay packages autolith-native)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages rust)
  #:use-module (tay packages autolith-rust-crates))

(define-public autolith-colorlisp-native
  (package
    (name "autolith-colorlisp-native")
    (version "0.0.0-0.2654ae0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/lambda-symbolics/colorlisp/tar.gz/"
             "2654ae0fa34aee42cff401693b5a80a86f0942c4"))
       (file-name (string-append "colorlisp-" version ".tar.gz"))
       (sha256
        (base32 "17gr7n3w0rrqrv2p1c1zjx40pr9avg0i21gcy969gv8g4wvlqwxj"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f ; No standalone native test harness; Lisp tests exercise it.
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; Match upstream nix/package.nix: compile the shim, vendored
              ;; runtime and every parser/scanner together, hiding everything
              ;; except the shim's explicit COLORLISP_PUBLIC API.
              (let ((grammars
                     (sort (filter (lambda (path)
                                     (eq? 'directory (stat:type (stat path))))
                                   (map (lambda (name)
                                          (string-append "vendor/grammars/" name))
                                        (scandir "vendor/grammars"
                                                 (lambda (name)
                                                   (not (member name '("." "..")))))))
                           string<?)))
                (apply invoke "gcc"
                       (append
                        '("-shared" "-fPIC" "-O2" "-std=gnu11"
                          "-fvisibility=hidden"
                          "-I" "vendor/tree-sitter/include"
                          "-I" "vendor/tree-sitter/src")
                        (append-map (lambda (path) (list "-I" path)) grammars)
                        '("-o" "libcolorlisp-tree-sitter.so"
                          "native/colorlisp-tree-sitter.c"
                          "vendor/tree-sitter/src/lib.c")
                        (sort (find-files "vendor/grammars" "^parser\\.c$")
                              string<?)
                        (sort (find-files "vendor/grammars" "^scanner\\.c$")
                              string<?))))))
          (replace 'install
            (lambda _
              (install-file "libcolorlisp-tree-sitter.so"
                            (string-append #$output "/lib"))
              (let ((doc (string-append #$output
                                        "/share/doc/autolith-colorlisp-native")))
                (install-file "LICENSE" doc)
                (copy-recursively "vendor/licenses"
                                  (string-append doc "/licenses/grammars"))
                (install-file "vendor/tree-sitter/src/unicode/LICENSE"
                              (string-append doc "/licenses/unicode"))))))))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/lambda-symbolics/colorlisp")
    (synopsis "Tree-sitter syntax highlighting library for Colorlisp")
    (description
     "This package builds Colorlisp's C interface, vendored Tree-sitter runtime,
and complete set of vendored language grammars into a shared library.  It is
used by Autolith for syntax highlighting.  The upstream shim, grammar, runtime
and Unicode notices are retained separately.")
    ;; Shim: ISC.  Runtime/grammars: MIT, except Clojure's CC0 grammar;
    ;; the runtime's vendored Unicode tables retain their ICU notice.
    (license (list license:isc license:expat license:cc0 license:unicode))))

(define-public autolith-sandbox-helper
  (package
    (name "autolith-sandbox-helper")
    (version "0.1.0-0.684e840")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/lambda-symbolics/cl-exec-sandbox/tar.gz/"
             "684e840c7f6de632048e38dcf63279da19ebc2fe"))
       (file-name (string-append "cl-exec-sandbox-" version ".tar.gz"))
       (sha256
        (base32 "1i0im5w9bjm35sqazja6sn1z9q1rz18hl1zxycqyw9f5a3r0jjwk"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f ; The ASDF package owns the integration tests.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; The pinned build-helper uses C11, -O2, -Wall, -Wextra,
              ;; -Werror and -pedantic for both Linux helpers.
              (setenv "CC" "gcc")
              (unsetenv "AUTOLITH_BUILD_STATIC_NATIVE")
              (invoke "bash" "scripts/build-helper")))
          (replace 'install
            (lambda _
              (for-each
               (lambda (name)
                 (install-file (string-append "build/" name)
                               (string-append #$output "/libexec")))
               '("cl-exec-sandbox-process-group" "cl-exec-sandbox-helper"))
              (install-file "LICENSE"
                            (string-append #$output
                                           "/share/doc/autolith-sandbox-helper")))))))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/lambda-symbolics/cl-exec-sandbox")
    (synopsis "Process-group and Linux sandbox helpers for Common Lisp")
    (description
     "This package provides the process-group supervisor used for full-access
execution and the Linux seccomp and network-namespace helper used by
cl-exec-sandbox.  Both helpers are compiled from the exact source revision
selected by Autolith.")
    (license license:isc)))

(define-public autolith-fff-c
  (package
    (name "autolith-fff-c")
    (version "0.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/dmtrKovalenko/fff/tar.gz/"
             "95fd777c2529fc7b4d7572dabff64cc07268f2c5"))
       (file-name (string-append "fff-" version ".tar.gz"))
       (sha256
        (base32 "0r3cx85k1k3q42r91wn0d3lz0x7rjq5jll3b8wiinmvjqiy6vnfj"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:rust rust
      #:install-source? #f
      ;; Preserve upstream's default ripgrep backend.  Selecting zlob instead
      ;; would change the ABI library's behavior and require Zig.
      #:cargo-build-flags ''("--release" "--locked" "-p" "fff-c")
      #:cargo-test-flags ''("--locked" "-p" "fff-c")
      #:modules '((guix build cargo-build-system)
                  (guix build utils)
                  (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'preserve-upstream-lockfile
            (lambda _
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-before 'configure 'remove-irrelevant-target-configuration
            (lambda _
              ;; Only macOS, musl and Android linker flags live here.  GNU/Linux
              ;; uses none of them; Guix writes the authoritative vendor config.
              (delete-file ".cargo/config.toml")))
          (add-before 'check-for-pregenerated-files 'remove-unused-target-binaries
            (lambda _
              ;; Keep every locked crate and its metadata, but discard opaque
              ;; Windows import libraries and native/WASM test fixtures.  None
              ;; is used by fff-c on the supported GNU/Linux targets.  The real
              ;; pregenerated-file checker still examines the remaining tree.
              (for-each
               (lambda (entry)
                 (let ((name (car entry)))
                   (when (or (string-prefix? "windows_" name)
                             (string-prefix? "winapi-" name)
                             (member name '("vcpkg" "libloading"
                                            "wit-bindgen" "wit-component"
                                            "wit-parser")))
                     (for-each
                      delete-file
                      (find-files
                       (string-append "guix-vendor/rust-" name "-"
                                      (cadr entry) ".tar.gz")
                       "\\.(a|lib|o|so|wasm|dll|dylib|exe)$")))))
               '#$%autolith-fff-locked-crates)))
          (add-after 'patch-cargo-checksums 'restore-locked-offline-graph
            (lambda _
              (setenv "CARGO_NET_OFFLINE" "true")
              (setenv "RUSTDOC" (string-append #+rust "/bin/rustdoc"))
              ;; Guix's configure phase removes Cargo.lock.  Restore it after
              ;; its vendor checksum phase, including every original package
              ;; checksum, so --locked checks the real upstream graph.
              (for-each
               (lambda (entry)
                 (let ((directory
                        (string-append "guix-vendor/rust-"
                                       (list-ref entry 0) "-"
                                       (list-ref entry 1) ".tar.gz")))
                   (unless (file-exists? (string-append directory "/Cargo.toml"))
                     (error "missing locked FFF registry crate" entry))
                   (call-with-output-file
                       (string-append directory "/.cargo-checksum.json")
                     (lambda (port)
                       (format port "{\"files\":{},\"package\":~s}"
                               (list-ref entry 3))))))
               '#$%autolith-fff-locked-crates)
              (copy-file ".guix-Cargo.lock" "Cargo.lock")))
          (replace 'install
            (lambda _
              (install-file "target/release/libfff_c.so"
                            (string-append #$output "/lib"))
              (install-file "crates/fff-c/include/fff.h"
                            (string-append #$output "/include"))
              (let ((doc (string-append #$output "/share/doc/autolith-fff-c")))
                (install-file "LICENSE" doc)
                (install-file "Cargo.lock" doc)
                (for-each
                 (lambda (entry)
                   (let* ((id (car entry))
                          (directory (string-append "guix-vendor/rust-"
                                                    id ".tar.gz"))
                          (destination (string-append doc "/licenses/" id)))
                     (for-each
                      (lambda (file)
                        (let ((target (string-append destination "/" file)))
                          (mkdir-p (dirname target))
                          (copy-file (string-append directory "/" file) target)))
                      (cadr entry))))
                 '#$%autolith-fff-crate-notices)
                (for-each
                 (lambda (entry)
                   (let ((target (string-append doc "/licenses/"
                                                (car entry) "/" (cadr entry))))
                     (mkdir-p (dirname target))
                     (copy-file (caddr entry) target)))
                 '#$%autolith-fff-supplemental-notices)
                ;; Windows import-library archives omit their own notices;
                ;; they share the grant in the locked winapi 0.3.9 crate.
                (for-each
                 (lambda (id)
                   (for-each
                    (lambda (file)
                      (install-file
                       (string-append "guix-vendor/rust-winapi-0.3.9.tar.gz/" file)
                       (string-append doc "/licenses/" id)))
                    '("LICENSE-APACHE" "LICENSE-MIT")))
                 '("winapi-i686-pc-windows-gnu-0.4.0"
                   "winapi-x86_64-pc-windows-gnu-0.4.0"))
                ;; The linked libgit2 keeps its GPL2 linking exception;
                ;; include its complete corresponding vendored source.
                (copy-recursively
                 "guix-vendor/rust-libgit2-sys-0.18.7+1.9.6.tar.gz/libgit2"
                 (string-append doc "/sources/libgit2"))
                ;; Supply corresponding source for the MPL-licensed component.
                (copy-recursively "guix-vendor/rust-option-ext-0.2.0.tar.gz"
                                  (string-append doc "/sources/option-ext-0.2.0"))))))))
    (native-inputs (list cmake-minimal pkg-config))
    (inputs (cons zlib %autolith-fff-cargo-inputs))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/dmtrKovalenko/fff")
    (synopsis "C interface to the FFF fuzzy file finder")
    (description
     "This package builds the FFF file finder's C ABI shared library from source
for Autolith.  It uses the upstream ripgrep backend and pinned workspace
lockfile, with all registry sources supplied offline.  Complete nested crate
license notices, missing upstream notice files and the MPL component's source
are installed alongside the library.")
    ;; FFF: MIT.  The registry closure is principally MIT/Apache-2.0.
    ;; libgit2's COPYING grants an unrestricted linking exception to GPL2;
    ;; its nested notices are retained.  LMDB uses OpenLDAP 2.8.  The LGPL
    ;; choices in r-efi are alternatives, not mandatory combined grants.
    (license (list license:expat license:asl2.0 license:bsd-2 license:bsd-3
                   license:cc0 license:isc license:unicode license:mpl2.0
                   license:zlib license:boost1.0 license:openldap2.8
                   license:gpl2))))
