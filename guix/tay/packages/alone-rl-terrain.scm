;;; Source-built terrain-generator Java bindings and Rust FFI for AloneRL.

(define-module (tay packages alone-rl-terrain)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages java)
  #:use-module (tay packages alone-rl-terrain-crates))

;; Rustler 0.38.0 omits both license texts from its published crates.  The
;; matching monorepo commit also contains rustler_codegen 0.38.0; install its
;; full grants for both entries, including their original copyright notice.
(define (rustler-license name hash)
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/rusterlium/rustler/"
          "75610261debf4140cbf9134fa2656da32de7b931/" name))
    (file-name name)
    (sha256 (base32 hash))))

(define %rustler-license-apache
  (rustler-license "LICENSE-APACHE"
                  "1wjryx2xwdivr45rw96kb7819zj92irna1z0sxl1clqlfn0yl3m6"))
(define %rustler-license-mit
  (rustler-license "LICENSE-MIT"
                  "1ns79nyvfcgyzlsiphwswvbx2lxxsaafrryn9zhh6lw5bhbcvf56"))

(define-public alone-rl-terrain
  (package
    (name "alone-rl-terrain")
    (version "0.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/fabio-t/terrain-generator/tar.gz/"
             "bc32cf49ef7a6032c24819a4b9e4a1a39745717d"))
       (file-name (string-append "terrain-generator-" version ".tar.gz"))
       (sha256
        (base32 "099rhqlysx9facwnkcsi6cbr8jqw3sdxffbclsl4hmrxjrqj6vg5"))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; The pinned workspace declares MSRV 1.91.  The full channel Rust
      ;; package is 1.93 and supplies rustdoc in its default output; the
      ;; bootstrap-only rust-1.93 omits it, so Cargo doctests cannot run.
      #:rust rust
      #:features ''("terrain-generator/png")
      #:install-source? #f
      ;; FFI's dependency already disables the core's default CLI feature and
      ;; enables PNG.  Do not activate CLI or build the unrelated Elixir NIF.
      #:cargo-build-flags
      ''("--release" "--locked" "-p" "terrain_generator_ffi"
         "--no-default-features")
      #:cargo-test-flags
      ''("--locked" "-p" "terrain-generator" "-p" "terrain_generator_ffi"
         "--no-default-features")
      #:modules '((guix build cargo-build-system)
                  (guix build utils)
                  (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'select-matching-rustdoc
            (lambda _
              (setenv "RUSTDOC" (string-append #+rust "/bin/rustdoc"))))
          ;; Guix's Cargo build phase consumes #:features, but its check
          ;; phase does not.  Forward the same feature selection to tests
          ;; without turning on the terrain core's default CLI feature.
          (replace 'check
            (lambda* (#:key tests? parallel-build? parallel-tests?
                      features cargo-test-flags #:allow-other-keys)
              ((assoc-ref %standard-phases 'check)
               #:tests? tests?
               #:parallel-build? parallel-build?
               #:parallel-tests? parallel-tests?
               #:cargo-test-flags
               (append cargo-test-flags
                       (list "--features" (string-join features ","))))))
          (add-after 'unpack 'preserve-reviewed-lockfile
            (lambda _
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-after 'patch-cargo-checksums 'restore-locked-offline-graph
            (lambda _
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; Guix's configure removes Cargo.lock and its vendor phase
              ;; writes stub package checksums.  Restore the original graph
              ;; unchanged, with each verified registry checksum in its
              ;; source-replacement manifest, so --locked remains meaningful.
              (for-each
               (lambda (entry)
                 (let* ((base (string-append "guix-vendor/rust-"
                                            (list-ref entry 0) "-"
                                            (list-ref entry 1)))
                        (directory
                         (find (lambda (path)
                                 (file-exists?
                                  (string-append path "/Cargo.toml")))
                               (list (string-append base ".tar.gz")
                                     (string-append base ".tar.zst")))))
                   (unless directory
                     (error "locked terrain crate is missing" entry))
                   (call-with-output-file
                       (string-append directory "/.cargo-checksum.json")
                     (lambda (port)
                       (format port "{\"files\":{},\"package\":~s}"
                               (list-ref entry 3))))))
               '#$%alone-rl-terrain-locked-crates)
              (copy-file ".guix-Cargo.lock" "Cargo.lock")))
          (add-after 'build 'build-java-bindings
            (lambda _
              (mkdir-p "java/out/classes")
              (apply invoke "javac" "--release" "22"
                     "-d" "java/out/classes"
                     (find-files "java/com" "\\.java$"))
              (call-with-output-file "java/out/MANIFEST.MF"
                (lambda (port)
                  (format port
                          (string-append
                           "Manifest-Version: 1.0~%"
                           "Implementation-Title: terrain-generator~%"
                           "Implementation-Version: ~a~%"
                           "Implementation-Vendor: Fabio Ticconi~%~%")
                          #$(package-version this-package))))
              ;; Only our compiled Java classes: no released jar, Gradle
              ;; wrapper, or opaque native resource enters this artifact.
              (invoke "jar" "--create" "--file"
                      "java/out/terrain-generator-0.2.1.jar"
                      "--manifest" "java/out/MANIFEST.MF"
                      "--date=1980-01-01T00:00:02Z"
                      "-C" "java/out/classes" ".")))
          (add-after 'check 'check-java-bindings
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (mkdir-p "java/out/tests")
                (invoke "javac" "--release" "22" "-cp"
                        "java/out/terrain-generator-0.2.1.jar"
                        "-d" "java/out/tests"
                        "java/TerrainGeneratorTest.java")
                (invoke "java" "--enable-native-access=ALL-UNNAMED"
                        (string-append "-Dtergen.library=" (getcwd)
                                       "/target/release/libterrain_generator_ffi.so")
                        "-cp"
                        "java/out/terrain-generator-0.2.1.jar:java/out/tests"
                        "TerrainGeneratorTest"))))
          (replace 'install
            (lambda _
              (install-file "target/release/libterrain_generator_ffi.so"
                            (string-append #$output "/lib"))
              (install-file "java/out/terrain-generator-0.2.1.jar"
                            (string-append #$output "/share/java"))
              (install-file "include/terrain_generator.h"
                            (string-append #$output "/include"))
              (let ((doc (string-append #$output
                                        "/share/doc/alone-rl-terrain")))
                (install-file "LICENSE" (string-append doc "/licenses/terrain-generator"))
                (install-file "Cargo.lock" doc)
                (install-file "README.md" doc)
                (install-file "docs/java_api.md" doc)
                (install-file "docs/rust_api.md" doc)
                (for-each
                 (lambda (entry)
                   (let* ((id (car entry))
                          (base (string-append "guix-vendor/rust-" id))
                          (directory
                           (find (lambda (path)
                                   (file-exists?
                                    (string-append path "/Cargo.toml")))
                                 (list (string-append base ".tar.gz")
                                       (string-append base ".tar.zst"))))
                          (destination (string-append doc "/licenses/" id)))
                     (unless directory
                       (error "terrain license source is missing" id))
                     (for-each
                      (lambda (file)
                        (let ((target (string-append destination "/" file)))
                          (mkdir-p (dirname target))
                          (copy-file (string-append directory "/" file) target)))
                      (cadr entry))))
                 '#$%alone-rl-terrain-crate-licenses)
                (for-each
                 (lambda (crate)
                   (let ((destination (string-append doc "/licenses/" crate)))
                     (mkdir-p destination)
                     (copy-file #$%rustler-license-apache
                                (string-append destination "/LICENSE-APACHE"))
                     (copy-file #$%rustler-license-mit
                                (string-append destination "/LICENSE-MIT"))))
                 '("rustler-0.38.0" "rustler_codegen-0.38.0")))))
          (add-after 'install 'check-installed-java-bindings
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Repeat the real upstream FFM test against the delivered
                ;; jar and native path, the same loading route AloneRL uses.
                (invoke "java" "--enable-native-access=ALL-UNNAMED"
                        (string-append "-Dtergen.library=" #$output
                                       "/lib/libterrain_generator_ffi.so")
                        "-cp"
                        (string-append #$output
                                       "/share/java/terrain-generator-0.2.1.jar:"
                                       (getcwd) "/java/out/tests")
                        "TerrainGeneratorTest")))))))
    (native-inputs `(("openjdk:jdk" ,openjdk25 "jdk")))
    (inputs %alone-rl-terrain-cargo-inputs)
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/fabio-t/terrain-generator")
    (synopsis "Procedural terrain generator with Java and C interfaces")
    (description
     "This package provides source-built Java Foreign Function and Memory API
bindings and the Rust C ABI library for terrain-generator.  It generates
fractal heightmaps, hydraulic erosion and river layers, with PNG export.
The pinned Cargo graph is vendored and built offline without the CLI or Elixir
NIF.  Java consumers select the installed library with @code{tergen.library}
and enable native access; the jar contains no bundled native binaries.
Complete license and notice texts for the locked source closure are installed
alongside the upstream license.")
    ;; Core and bindings: Apache-2.0.  The linked Rust closure is principally
    ;; MIT/Apache-2.0; preserve every alternative grant and copyright text.
    ;; ISC and Unicode cover lock-only NIF/macro tooling whose notices we also
    ;; retain, though none of those crates enters the shipped FFI library.
    (license (list license:asl2.0 license:expat license:bsd-0
                   license:zlib license:isc license:unicode))))
