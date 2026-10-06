;;; GNU Guix package for larsbrinkhoff/uc-explorer.
;;; The source and every crate archive below are pinned to the reviewed
;;; fc4f9f3324d3497f553512b661ad37cbdde89ccb Cargo.lock graph.  Cargo uses
;;; that lockfile unchanged and runs --offline --locked throughout the build,
;;; tests, and installation.
(define-module (tay packages uc-explorer)
  #:use-module (guix base16)
  #:use-module (guix base32)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (tay packages larsbrinkhoff-t-z)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (ice-9 match))

;; Every registry package in upstream's Cargo.lock, including the Windows
;; GNU import-library crates that Cargo needs to resolve the complete locked
;; graph although nothing here builds them for a Linux target.
(define %uc-explorer-crate-records
  '(("ansi_term" "0.11.0" "16wpvrghvd0353584i1idnsgm0r3vchg8fyrm0x8ayv1rgvbljgf")
    ("atty" "0.2.10" "1lfvh0nm0a5byaw9xwj2s8ci9y8sbj4821hg4n573h149jma3i1g")
    ("bitflags" "1.0.3" "12b75san2w67hhpfbnrdkzchp7b7ypdzrvlp27r6gialyjw4pifh")
    ("clap" "2.32.0" "0gidrrbcfwdbb3s5hy3jlzpwc68q0744liaz1pbvjqva9f7xhmxr")
    ("libc" "0.2.42" "1wdmgr8r82ywz548lcs2q5csjipqiry1i9q7vz5gql5rya6hi1dn")
    ("redox_syscall" "0.1.40" "1c8j05dgfyhj5ms5is5yy9sb857bmmrqjmqywjjfjhyg7qfyj562")
    ("redox_termios" "0.1.1" "0xhgvdh62mymgdl3jqrngl8hr4i8xwpnbsxnldq0l47993z1r2by")
    ("strsim" "0.7.0" "0l7mkwvdk4vgnml67b85mczk466074aj8yf25gjrjslj4l0khkxv")
    ("termion" "1.5.1" "15i0x5vcwb8bkd72g1vlafz3qza1g165rpw7pj9gsfdlmbgkp6k8")
    ("textwrap" "0.10.0" "1xnkk81wksg87mc7mj71m44g7h14jnd6ya34vaa1zrwkkj38cxih")
    ("unicode-width" "0.1.5" "09k5lipygardwy0660jhls08fsgknrazzivmn804gps53hiqc8w8")
    ("vec_map" "0.8.1" "06n8hw4hlbcz328a3gbpvmy0ma46vg1lc0r5wf55900szf3qdiq5")
    ("winapi" "0.3.5" "1z803zsdx7w8zw1qwxm9j2qc697z8bjh3w8g1n2psjzjqpfgjgkp")
    ("winapi-i686-pc-windows-gnu" "0.4.0" "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc")
    ("winapi-x86_64-pc-windows-gnu" "0.4.0" "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki")))

;; The two Windows GNU crates ship only prebuilt MinGW import libraries
;; under lib/, which their build scripts use solely for Windows GNU targets.
;; Guix verifies each archive against its pinned hash before this snippet
;; removes those libraries; their manifests and build scripts are kept so the
;; locked graph still resolves.
(define %uc-explorer-crate-snippets
  (map (lambda (name)
         (cons name '(for-each delete-file (find-files "lib" "\\.a$"))))
       '("winapi-i686-pc-windows-gnu" "winapi-x86_64-pc-windows-gnu")))

(define %uc-explorer-cargo-inputs
  (map (match-lambda
         ((name version hash)
          (crate-source name version hash
                        #:snippet
                        (assoc-ref %uc-explorer-crate-snippets name))))
       %uc-explorer-crate-records))

;; Pair each vendored origin with the SHA-256 recorded for it in the
;; [metadata] table of upstream's Cargo.lock.  Cargo.lock stores the digest
;; in hexadecimal; the pinned origin hash is the same digest in nix-base32.
(define %uc-explorer-locked-checksums
  #~(list
     #$@(map (lambda (record source)
               (match record
                 ((_ _ hash)
                  #~(cons #$source
                          #$(bytevector->base16-string
                             (nix-base32-string->bytevector hash))))))
             %uc-explorer-crate-records
             %uc-explorer-cargo-inputs)))

(define-public uc-explorer
  (package
    (name "uc-explorer")
    (version "0.1.0")
    (source (package-source larsbrinkhoff-uc-explorer-source))
    (build-system cargo-build-system)
    (arguments
     (list
      #:install-source? #f
      #:cargo-build-flags ''("--release" "--locked")
      #:cargo-test-flags ''("--locked")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'save-locked-cargo-graph
            (lambda _
              ;; The cargo-build-system configure phase deletes Cargo.lock.
              ;; Keep upstream's exact reviewed graph for every Cargo action.
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-after 'patch-cargo-checksums 'restore-locked-offline-cargo-graph
            (lambda _
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; patch-cargo-checksums gives every vendored crate a manifest
              ;; with no package checksum, which conflicts with the checksums
              ;; in upstream's lockfile.  Record each verified registry
              ;; checksum in its vendored source-replacement manifest and
              ;; restore the lockfile unchanged, so --locked stays meaningful.
              (for-each
               (lambda (entry)
                 (let ((directory
                        (string-append "guix-vendor/"
                                       (strip-store-file-name (car entry)))))
                   (unless (file-exists?
                            (string-append directory "/Cargo.toml"))
                     (error "locked crate is not vendored" (car entry)))
                   (call-with-output-file
                       (string-append directory "/.cargo-checksum.json")
                     (lambda (port)
                       (format port "{\"files\":{},\"package\":~s}"
                               (cdr entry))))))
               #$%uc-explorer-locked-checksums)
              (copy-file ".guix-Cargo.lock" "Cargo.lock")))
          ;; The generic installer omits --locked.  Install from the same
          ;; offline vendor tree and unchanged lockfile.
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (setenv "CARGO_TARGET_DIR" "./target")
              (invoke "cargo" "install" "--offline" "--locked" "--no-track"
                      "--path" "." "--root" (assoc-ref outputs "out")))))))
    (inputs %uc-explorer-cargo-inputs)
    (synopsis "Explore Lisp machine microcode")
    (description "UC Explorer reads local microcode files.")
    (home-page "https://github.com/larsbrinkhoff/uc-explorer")
    (license license:gpl3+)))
