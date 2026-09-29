;;; Source-built Python dependencies for the pinned Fontra editor.

(define-module (tay packages fontra-python)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages check)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-check)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (srfi srfi-1))

;; Keep Guix's generally useful definitions unchanged.  These variants meet
;; Fontra 2026.9.0's requirements without modifying its dependency metadata.

(define-public python-unicodedata2-fontra
  (package
    (inherit python-unicodedata2)
    (name "python-unicodedata2-fontra")
    (version "17.0.1")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/44/cb/"
            "520721a715da85530e21c71953b9b9a85a44e0d80d3b34bf9303c422d208/"
            "unicodedata2-17.0.1.tar.gz"))
      (sha256
       (base32 "0fxdwqmdh8jkqznb7vgw6zd4n64535hyr9am7yzbzxpmag8l76fp"))))))

(define-public python-fonttools-fontra
  (package
    (inherit python-fonttools)
    (name "python-fonttools-fontra")
    (version "4.63.0")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/84/69/"
            "c97f2c18e0db87d2c7b15da1974dace76ae938f1cfa22e2727a648b7ed43/"
            "fonttools-4.63.0.tar.gz"))
      (sha256
       (base32 "1q64p5k26vs66j3li26gcvxfvav2xssaikb59dlqw5mmxqymisya"))))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-fonttools)
       (delete "python-unicodedata2")
       (prepend python-unicodedata2-fontra)))))

;; Rewriting both full and bootstrap FontTools prevents old copies from
;; leaking into the UFO compiler through booleanoperations, fontmath or cffsubr.
(define with-fontra-fonttools
  (package-input-rewriting
   (list (cons python-fonttools python-fonttools-fontra)
         (cons python-fonttools-minimal python-fonttools-fontra))
   identity #:deep? #f))

(define-public python-ufolib2-fontra
  (package
    (inherit (with-fontra-fonttools python-ufolib2))
    (name "python-ufolib2-fontra")))

;; cffsubr invokes ADFKO's tx as a separate executable.  Replacing its Python
;; dependency only avoids rebuilding the unrelated ADFKO tooling subtree.
(define python-cffsubr-fontra
  (package
    (inherit python-cffsubr)
    (propagated-inputs (list python-fonttools-fontra))))

(define-public python-compreffor-fontra
  (package
    (inherit python-compreffor)
    (name "python-compreffor-fontra")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://files.pythonhosted.org/packages/67/77/"
             "57ce491ad29073f4b8cfa6226d8b7cba310327d71a7e7db4e2e000b08ed8/"
             "compreffor-0.6.0.tar.gz"))
       (sha256
        (base32 "1a0vn65d7d9961y61sz2dj16zcrbmh70900l5xrpik2r1jjk983y"))))
    (propagated-inputs (list python-fonttools-fontra))))

(define-public python-skia-pathops-fontra
  (package
    (inherit python-skia-pathops)
    (name "python-skia-pathops-fontra")
    ;; The minimum accepted post-release retains the system-Skia interface.
    (version "0.8.0.post1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://files.pythonhosted.org/packages/37/15/"
             "fa6de52d9cb3a44158431d4cce870e7c2a56cdccedc8fa1262cbf61d4e1e/"
             "skia-pathops-0.8.0.post1.zip"))
       (sha256
        (base32 "1fsw9031cka01r2r2370mrwbhdka7i8mbvmr2r8sa7znwafj8mm0"))
       (modules '((guix build utils)))
       (snippet #~(delete-file-recursively "src/cpp"))))
    (native-inputs
     (modify-inputs (package-native-inputs python-skia-pathops)
       (prepend python-setuptools)))))

(define-public python-ufo2ft-fontra
  (package
    (inherit python-ufo2ft)
    (name "python-ufo2ft-fontra")
    (version "3.9.0")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/d3/b2/"
            "f7c2cc5989b862c79215c587839b40a7074e2f3eea32019c2ff740db113b/"
            "ufo2ft-3.9.0.tar.gz"))
      (sha256
       (base32 "0b9yprzpq8mmyy0c8xncafzl7j5hbyp98bzgqw0gqy0sclykdsig"))))
    ;; 3.x no longer requires cu2qu, defcon or compreffor.  Pathops is an
    ;; optional backend used by Fontra; ufoLib2 supplies the test UFO objects.
    (propagated-inputs
     (list (with-fontra-fonttools python-booleanoperations)
           python-cffsubr-fontra
           (with-fontra-fonttools python-fontmath)
           python-fonttools-fontra
           python-skia-pathops-fontra))
    (native-inputs
     (modify-inputs (package-native-inputs python-ufo2ft)
       (delete "python-wheel")
       (prepend python-ufolib2-fontra python-syrupy python-py
                python-compreffor-fontra
                (with-fontra-fonttools python-defcon))))
    ;; Drop the old 2.x-only exclusions; the 3.x source has its own snapshots.
    (arguments (list))))

(define-public python-glyphslib-fontra
  (package
    (inherit python-glyphslib)
    (name "python-glyphslib-fontra")
    (version "6.14.0")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/71/8d/"
            "d37b2552817fbf61d927329d5d4b65257668e9780e800db6d9e23d098ece/"
            "glyphslib-6.14.0.tar.gz"))
      (sha256
       (base32 "0alg47id36j0iv2xnhvl13f6hazf5y4ric0amgbwjs2qk8kdlnr7"))))
    (native-inputs
     (modify-inputs (package-native-inputs python-glyphslib)
       (prepend python-py
                (with-fontra-fonttools python-defcon)
                python-ufo2ft-fontra
                (with-fontra-fonttools python-ufonormalizer))))
    (propagated-inputs
     (list python-fonttools-fontra python-openstep-plist
           python-ufolib2-fontra))))

(define-public python-ufomerge
  (package
    (name "python-ufomerge")
    (version "1.9.7")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/c1/2b/"
            "921ca4b725e860e95157ad1f7cea2c074867a9095845c4db339e280c6c84/"
            "ufomerge-1.9.7.tar.gz"))
      (sha256
       (base32 "14w3q13xwbhf3a6qwnx54hcn5bq6nba06fnhl392ylb0sylq51yb"))))
    (build-system pyproject-build-system)
    ;; The upstream suite imports fontFeatures, which Guix does not package.
    (arguments (list #:tests? #f))
    (native-inputs
     (list python-pytest python-setuptools python-setuptools-scm))
    (propagated-inputs
     (list python-fonttools-fontra python-ufolib2-fontra))
    (home-page "https://github.com/simoncozens/ufomerge")
    (synopsis "Merge source fonts in UFO format")
    (description
     "UFOMerge merges glyphs, kerning and OpenType layout features from
one Unified Font Object source font into another.")
    (license license:asl2.0)))

(define-public python-pillow-fontra
  (package
    (inherit python-pillow)
    (name "python-pillow-fontra")
    (version "12.3.0")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/1c/3d/"
            "bb7fca845737cf9d7dbde16ed1843984665ff2e0a518f5db43e77ec540b9/"
            "pillow-12.3.0.tar.gz"))
      (sha256
       (base32 "1kkw54q5ianvy2dmf7y7l0cqicfnr178pqip4q0alpk8cskq509v"))))
    (native-inputs
     (modify-inputs (package-native-inputs python-pillow)
       (prepend python-packaging python-pytest-timeout python-pytest-xdist)))
    (arguments
     (substitute-keyword-arguments (package-arguments python-pillow)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'bound-fuzz-test-memory
              (lambda _
                ;; The fuzz corpus contains ~84-million-pixel images.  Use a
                ;; 256MiB address-space budget only for these adversarial
                ;; inputs; their existing MemoryError handler accepts resource
                ;; exhaustion.  Restore the process limit for normal tests.
                (substitute* "Tests/oss-fuzz/test_fuzzers.py"
                  (("import subprocess") "import resource\nimport subprocess")
                  (("    fuzzers.enable_decompressionbomb_error\\(\\)")
                   (string-append
                    "    memory_limit = resource.getrlimit(resource.RLIMIT_AS)\n"
                    "    soft, hard = memory_limit\n"
                    "    bound = 256 * 1024 * 1024\n"
                    "    if soft != resource.RLIM_INFINITY:\n"
                    "        bound = min(bound, soft)\n"
                    "    resource.setrlimit(resource.RLIMIT_AS, (bound, hard))\n"
                    "    fuzzers.enable_decompressionbomb_error()"))
                  (("        fuzzers.disable_decompressionbomb_error\\(\\)")
                   (string-append
                    "        fuzzers.disable_decompressionbomb_error()\n"
                    "        resource.setrlimit(resource.RLIMIT_AS, memory_limit)")))))
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  (setenv "HOME" (getcwd))
                  (invoke "python" "selftest.py" "--installed")
                  ;; Pillow has no large-memory test switch.  These WebP
                  ;; cases allocate 15000x15000 RGB and 16384x16384 L images;
                  ;; retain the rest of the suite in memory-limited builds.
                  (invoke "python" "-m" "pytest" "-vv" "-k"
                          (string-append
                           "not test_write_encoding_error_message and "
                           "not test_write_encoding_error_bad_dimension")))))
            (replace 'patch-ldconfig
              (lambda _
                (substitute* "setup.py"
                  (("args = \\[ldconfig, \"-p\"\\]")
                   "args = ['true']"))))))))))

(define-public python-aiohttp-fontra
  (package
    (inherit python-aiohttp)
    (name "python-aiohttp-fontra")
    (version "3.14.3")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/58/d9/"
            "22ce5786ac0c1653ae8b6c23bded02c1686d11f0dbb45b31ce128e0df985/"
            "aiohttp-3.14.3.tar.gz"))
      (sha256
       (base32 "1g24g27kl8nvvdw0h98nqrn3n82v9d1mynzx1ak292d86mjik4cl"))))
    ;; The sdist pins generated llhttp 9.4.2 C sources and its MIT license.
    ;; Guix's llhttp 9.1.3 cannot parse the QUERY method required by this
    ;; aiohttp release.  Compile the pinned parser without Node generators.
    (arguments
     (substitute-keyword-arguments (package-arguments python-aiohttp)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'set-libllhtp-pkgconfig)
            (add-after 'fix-pytest-config 'remove-unused-coverage-filter
              (lambda _
                ;; Coverage is not loaded by the Guix test invocation.
                (substitute* "setup.cfg"
                  (((string-append
                     "^[[:space:]]*ignore:Couldn't import C tracer:"
                     "coverage[.]exceptions[.]CoverageWarning.*"))
                   ""))))
            (replace 'pre-build
              (lambda _
                (unsetenv "AIOHTTP_USE_SYSTEM_DEPS")
                (unsetenv "USE_SYSTEM_DEPS")))))))
    (native-inputs
     (modify-inputs (package-native-inputs python-aiohttp)
       (prepend python-pytest-timeout)))
    (inputs (list))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-aiohttp)
       (prepend python-typing-extensions)))
    (license (list license:asl2.0 license:expat))))

;; Watchfiles 1.2 updates PyO3, quote and target-lexicon.  All other origins
;; below match its Cargo.lock; remove obsolete crates from the inherited set.
(define %watchfiles-updated-crates
  (list
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/pyo3/pyo3-0.28.3.crate")
     (file-name "rust-pyo3-0.28.3.tar.gz")
     (sha256
      (base32 "04hwqcrfx9w3f67pnhjcg28y0iq1srpwv0drgwbd23mmlcw8xzci")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.28.3.crate")
     (file-name "rust-pyo3-build-config-0.28.3.tar.gz")
     (sha256
      (base32 "07k16mnxn220x4aw0axzcss4mn4gckhknf7qlyyck67bzpfyfs73")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.28.3.crate")
     (file-name "rust-pyo3-ffi-0.28.3.tar.gz")
     (sha256
      (base32 "07k5bxh8h2ax3v6gmb43x09wsgm003lar7pnyz57q7qbz05f2abz")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.28.3.crate")
     (file-name "rust-pyo3-macros-0.28.3.tar.gz")
     (sha256
      (base32 "04wqy9knmxkf2m12dfwbj4817p959chxhzgwsabmki27zw754vnz")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.28.3.crate")
     (file-name "rust-pyo3-macros-backend-0.28.3.tar.gz")
     (sha256
      (base32 "1jrsh65i0vwinp5k6blbvypv8idgg0h853rkqa0qywrmv0cc5kf4")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/quote/quote-1.0.45.crate")
     (file-name "rust-quote-1.0.45.tar.gz")
     (sha256
      (base32 "095rb5rg7pbnwdp6v8w5jw93wndwyijgci1b5lw8j1h5cscn3wj1")))
   (origin
     (method url-fetch)
     (uri "https://static.crates.io/crates/target-lexicon/target-lexicon-0.13.5.crate")
     (file-name "rust-target-lexicon-0.13.5.tar.gz")
     (sha256
      (base32 "1jm6lmf9hsn7ri2d6v9gg6fy24lylhskh6pbxh71f82wdxd97dmd")))))


(define-public python-watchfiles-fontra
  (package
    (inherit python-watchfiles)
    (name "python-watchfiles-fontra")
    (version "1.2.0")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://files.pythonhosted.org/packages/cd/41/"
            "5e1a4bb12aac5f1493fa1bdc11154eca3b258ca4eba65d39c473fe19d8e9/"
            "watchfiles-1.2.0.tar.gz"))
      (sha256
       (base32 "0f38syn8qn9cv2ixa38kl38sbxsc53lkd4hg14prkspifykzp5f9"))))
    (native-inputs
     (map (lambda (input)
            ;; Guix labels both rust outputs "rust"; identify cargo by output.
            (if (and (string=? (car input) "rust")
                     (equal? (cddr input) '("cargo")))
                (cons "rust:cargo" (cdr input))
                input))
          (package-native-inputs python-watchfiles)))
    (inputs
     (append
      (filter (lambda (input)
                (not (or (string-prefix? "rust-pyo3-" (car input))
                         (string-prefix? "rust-quote-" (car input))
                         (string-prefix? "rust-target-lexicon-" (car input))
                         (member (car input)
                                 '("rust-autocfg-1.3.0.tar.gz"
                                   "rust-indoc-2.0.5.tar.gz"
                                   "rust-memoffset-0.9.1.tar.gz"
                                   "rust-unindent-0.2.3.tar.gz")))))
              (package-inputs python-watchfiles))
      (map (lambda (source)
             (list (origin-file-name source) source))
           %watchfiles-updated-crates)))))
