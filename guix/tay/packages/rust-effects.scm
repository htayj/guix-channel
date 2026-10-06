;;; Functional programming effects and typeclasses for Rust.

(define-module (tay packages rust-effects)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages rust)
  #:use-module (tay packages rust-effects-cargo-sources))

(define-public rust-effects
  (package
    (name "rust-effects")
    (version (git-version "0.1.0" "0"
                          "d7fe96deb196fed0a222d0d3b796145f78420f39"))
    ;; Keep the source ledger's canonical revision unchanged, using Git here
    ;; so the buildable package can participate in source archival.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/kitsuneninetails/rust-effects")
             (commit "d7fe96deb196fed0a222d0d3b796145f78420f39")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1z3a1g3wvqja9b5gsih5k6z88cx9jnnan96rqyy705x3vxf1lclb"))))
    (build-system cargo-build-system)
    (inputs rust-effects-cargo-inputs)
    (arguments
     (list
      ;; The bootstrap-only rust-1.86 omits rustdoc.  Use the channel's full
      ;; Rust toolchain so upstream doctests run with matching rustc/rustdoc.
      #:rust rust
      #:install-source? #t
      #:cargo-build-flags ''("--release" "--locked")
      #:cargo-test-flags ''("--locked")
      #:cargo-package-flags ''("--no-metadata" "--no-verify" "--locked")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'select-matching-rustdoc
            (lambda _
              (setenv "RUSTDOC" (string-append #+rust "/bin/rustdoc"))))
          (add-after 'unpack 'pin-dependencies
            (lambda _
              ;; Upstream's wildcard constraints must not re-resolve when the
              ;; installed library is used as an external path dependency.
              (substitute* "Cargo.toml"
                (("edition = \"2024\"")
                 (string-append "edition = \"2024\"\n"
                                "rust-version = \"1.86\"\n"
                                "license = \"MIT\"\n"
                                "exclude = [\"guix-vendor/**\"]"))
                (("futures-util = \"\\*\"")
                 "futures-util = \"=0.3.32\"")
                (("futures = \\{version = \"\\*\"")
                 "futures = {version = \"=0.3.32\"")
                (("tokio = \\{ version = \"\\*\"")
                 "tokio = { version = \"=1.52.3\""))))
          (add-after 'configure 'install-cargo-lock
            (lambda _
              ;; Configure deletes Cargo.lock.  Install our complete lock graph
              ;; afterwards, and use the standard Guix vendor checksum policy.
              (copy-file #$rust-effects-cargo-lock "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*") ""))
              (setenv "CARGO_NET_OFFLINE" "true")))
          (add-after 'install 'install-consumer-sources
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (share (string-append out "/share/rust-effects"))
                     (vendor (string-append share "/vendor"))
                     (sources (string-append out
                                            "/share/cargo/src/rust-effects-0.1.0"))
                     (doc (string-append out "/share/doc/rust-effects")))
                ;; The ordinary Cargo install phase has installed both the
                ;; actual library source and its .crate archive, not an rlib
                ;; tied to this compiler.  Ship its complete offline closure
                ;; separately so consumers need neither registry nor checkout.
                (copy-recursively "guix-vendor" vendor)
                (copy-file "Cargo.lock" (string-append sources "/Cargo.lock"))
                (call-with-output-file (string-append share "/cargo-config.toml")
                  (lambda (port)
                    (format port
                            (string-append
                             "[net]~%offline = true~%~%"
                             "[source.crates-io]~%"
                             "replace-with = 'guix-vendor'~%~%"
                             "[source.guix-vendor]~%directory = '~a'~%")
                            vendor)))
                (mkdir-p (string-append sources "/.cargo"))
                (copy-file (string-append share "/cargo-config.toml")
                           (string-append sources "/.cargo/config.toml"))
                (install-file "LICENSE" doc)
                (install-file "README.md" doc)))))))
    (synopsis "Functional programming typeclasses and free effects for Rust")
    (description
     "This library provides higher-kinded-type-style functional programming
abstractions for Rust, including functors, applicatives, monads, monoids, and
semigroups.  Its free-effect programs separate composition from interpretation,
and its shared futures support asynchronous computations.  The installed crate
source, pinned lockfile, and vendored dependency closure allow external Cargo
consumers to build offline.")
    (home-page "https://github.com/kitsuneninetails/rust-effects")
    (license license:expat)))