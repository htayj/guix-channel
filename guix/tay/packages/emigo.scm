;;; GNU Guix package for MatthewZMD/emigo.

(define-module (tay packages emigo)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system emacs)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages tree-sitter))
;; These bindings have no standalone package in this Guix revision.  The
;; grammar sources are fixed-output Guix packages and retain their licenses.
(define (python-tree-sitter-binding grammar)
  (package
    (inherit grammar)
    (name (string-append "python-" (package-name grammar)))
    (source (origin (inherit (package-source grammar))
                    (snippet #f) (patches '())))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (propagated-inputs (list python-tree-sitter))
    (native-inputs (list python-setuptools))))

(define python-tree-sitter-c-sharp
  (python-tree-sitter-binding tree-sitter-c-sharp))

(define python-tree-sitter-embedded-template
  (python-tree-sitter-binding tree-sitter-embedded-template))

(define python-tree-sitter-yaml
  (python-tree-sitter-binding tree-sitter-yaml))

(define-public python-tree-sitter-language-pack
  (package
    (name "python-tree-sitter-language-pack")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri ((@ (guix build-system pyproject) pypi-uri)
             "tree_sitter_language_pack" version))
       (sha256
        (base32 "10fpg4v77zb72657ilrgwn8rv7nybm5sybh1sj5hdr1slrk0qqsj"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; Delete release-wheel extensions and rebuild bundled parser sources.
          (add-after 'unpack 'delete-prebuilt-extensions
            (lambda _
              (for-each delete-file
                        (find-files "tree_sitter_language_pack/bindings"
                                    "\\.so$"))))
          (add-after 'install 'install-parser-credits
            (lambda _
              (for-each (lambda (file)
                          (install-file file
                                        (string-append #$output
                                         "/share/doc/tree-sitter-language-pack")))
                        '("LICENSE" "README.md")))))))
    (propagated-inputs
     (list python-tree-sitter
           python-tree-sitter-c-sharp
           python-tree-sitter-embedded-template
           python-tree-sitter-yaml))
    (native-inputs
     (list python-cython python-setuptools python-typing-extensions))
    (home-page "https://github.com/Goldziher/tree-sitter-language-pack")
    (synopsis "Source-built collection of Tree-sitter language bindings")
    (description "A source-built Tree-sitter language bundle with bundled parser sources.")
    (license (list license:expat license:asl2.0 license:bsd-2
                   license:bsd-3 license:cc0 license:isc license:artistic2.0
                   license:unlicense license:wtfpl2))))

(define-public python-grep-ast
  (package
    (name "python-grep-ast")
    (version "0.9.0")
    (source
     (origin
       (method url-fetch)
       (uri ((@ (guix build-system pyproject) pypi-uri) "grep_ast" version))
       (sha256
        (base32 "1qrf9dfqdxlhrxnlm4plfj3iyrdf6k1adjfi709p5rlk8hm282k2"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (propagated-inputs (list python-pathspec python-tree-sitter-language-pack))
    (native-inputs (list python-setuptools))
    (home-page "https://github.com/paul-gauthier/grep-ast")
    (synopsis "Grep source files through their abstract syntax tree")
    (description "Grep-AST provides tree-aware source context extraction.")
    (license license:asl2.0)))

(define-public python-fastuuid
  (package
    (name "python-fastuuid")
    (version "0.13.5")
    (source
     (origin
       (method url-fetch)
       (uri ((@ (guix build-system pyproject) pypi-uri) "fastuuid" version))
       (sha256
        (base32 "18d1jmdkq4nadz06fh50z31m9m595349p8qy5ra42ka2mchni5yl"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:tests? #f
      #:imported-modules `(,@%cargo-build-system-modules
                           ,@%pyproject-build-system-modules)
      #:modules '((guix build cargo-build-system)
                  ((guix build pyproject-build-system) #:prefix py:)
                  (guix build utils))
      #:phases
      (with-extensions (list (pyproject-guile-json))
        #~(modify-phases %standard-phases
            (add-after 'build 'build-python-module
              (assoc-ref py:%standard-phases 'build))
            (add-after 'build-python-module 'install-python-module
              (assoc-ref py:%standard-phases 'install))))
      #:install-source? #f
    ;; Cargo.lock pins this complete source closure.  Each hash is the decoded
    ;; crate checksum from that lock file, imported by Guix as a crate source.
      #:cargo-inputs
     (list
      (list "rust-atomic-0.6.1" (@@ (gnu packages rust-crates) rust-atomic-0.6.1))
      (list "rust-autocfg-1.5.0" (@@ (gnu packages rust-crates) rust-autocfg-1.5.0))
      (list "rust-block-buffer-0.10.4" (@@ (gnu packages rust-crates) rust-block-buffer-0.10.4))
      (list "rust-bumpalo-3.19.0" (@@ (gnu packages rust-crates) rust-bumpalo-3.19.0))
      (list "rust-bytemuck-1.23.2" (@@ (gnu packages rust-crates) rust-bytemuck-1.23.2))
      (list "rust-cfg-if-1.0.3" (@@ (gnu packages rust-crates) rust-cfg-if-1.0.3))
      (list "rust-crypto-common-0.1.6" (@@ (gnu packages rust-crates) rust-crypto-common-0.1.6))
      (list "rust-digest-0.10.7" (@@ (gnu packages rust-crates) rust-digest-0.10.7))
      (list "rust-generic-array-0.14.7" (@@ (gnu packages rust-crates) rust-generic-array-0.14.7))
      (list "rust-getrandom-0.2.16" (@@ (gnu packages rust-crates) rust-getrandom-0.2.16))
      (list "rust-getrandom-0.3.3" (@@ (gnu packages rust-crates) rust-getrandom-0.3.3))
      (list "rust-heck-0.5.0" (@@ (gnu packages rust-crates) rust-heck-0.5.0))
      (list "rust-indoc-2.0.6" (@@ (gnu packages rust-crates) rust-indoc-2.0.6))
      (list "rust-js-sys-0.3.81" (@@ (gnu packages rust-crates) rust-js-sys-0.3.81))
      (list "rust-libc-0.2.176" (@@ (gnu packages rust-crates) rust-libc-0.2.176))
      (list "rust-log-0.4.28" (@@ (gnu packages rust-crates) rust-log-0.4.28))
      (list "rust-md-5-0.10.6" (@@ (gnu packages rust-crates) rust-md-5-0.10.6))
      (list "rust-memoffset-0.9.1" (@@ (gnu packages rust-crates) rust-memoffset-0.9.1))
      (list "rust-once-cell-1.21.3" (@@ (gnu packages rust-crates) rust-once-cell-1.21.3))
      (list "rust-portable-atomic-1.11.1" (@@ (gnu packages rust-crates) rust-portable-atomic-1.11.1))
      (list "rust-ppv-lite86-0.2.21" (@@ (gnu packages rust-crates) rust-ppv-lite86-0.2.21))
      (list "rust-proc-macro2-1.0.101" (@@ (gnu packages rust-crates) rust-proc-macro2-1.0.101))
      (list "rust-pyo3-0.22.6" (@@ (gnu packages rust-crates) rust-pyo3-0.22.6))
      (list "rust-pyo3-build-config-0.22.6" (@@ (gnu packages rust-crates) rust-pyo3-build-config-0.22.6))
      (list "rust-pyo3-ffi-0.22.6" (@@ (gnu packages rust-crates) rust-pyo3-ffi-0.22.6))
      (list "rust-pyo3-macros-0.22.6" (@@ (gnu packages rust-crates) rust-pyo3-macros-0.22.6))
      (list "rust-pyo3-macros-backend-0.22.6" (@@ (gnu packages rust-crates) rust-pyo3-macros-backend-0.22.6))
      (list "rust-quote-1.0.40" (@@ (gnu packages rust-crates) rust-quote-1.0.40))
      (list "rust-r-efi-5.3.0" (@@ (gnu packages rust-crates) rust-r-efi-5.3.0))
      (list "rust-rand-0.8.5" (@@ (gnu packages rust-crates) rust-rand-0.8.5))
      (list "rust-rand-chacha-0.3.1" (@@ (gnu packages rust-crates) rust-rand-chacha-0.3.1))
      (list "rust-rand-core-0.6.4" (@@ (gnu packages rust-crates) rust-rand-core-0.6.4))
      (list "rust-rustversion-1.0.22" (@@ (gnu packages rust-crates) rust-rustversion-1.0.22))
      (list "rust-sha1-smol-1.0.1" (@@ (gnu packages rust-crates) rust-sha1-smol-1.0.1))
      (list "rust-syn-2.0.106" (@@ (gnu packages rust-crates) rust-syn-2.0.106))
      (list "rust-target-lexicon-0.12.16" (@@ (gnu packages rust-crates) rust-target-lexicon-0.12.16))
      (list "rust-typenum-1.18.0" (@@ (gnu packages rust-crates) rust-typenum-1.18.0))
      (list "rust-unicode-ident-1.0.19" (@@ (gnu packages rust-crates) rust-unicode-ident-1.0.19))
      (list "rust-unindent-0.2.4" (@@ (gnu packages rust-crates) rust-unindent-0.2.4))
      (list "rust-uuid-1.18.1" (@@ (gnu packages rust-crates) rust-uuid-1.18.1))
      (list "rust-version-check-0.9.5" (@@ (gnu packages rust-crates) rust-version-check-0.9.5))
      (list "rust-wasi-0.11.1+wasi-snapshot-preview1" (@@ (gnu packages rust-crates) rust-wasi-0.11.1+wasi-snapshot-preview1))
      (list "rust-wasi-0.14.7+wasi-0.2.4" (@@ (gnu packages rust-crates) rust-wasi-0.14.7+wasi-0.2.4))
      (list "rust-wasip2-1.0.1+wasi-0.2.4" (@@ (gnu packages rust-crates) rust-wasip2-1.0.1+wasi-0.2.4))
      (list "rust-wasm-bindgen-0.2.104" (@@ (gnu packages rust-crates) rust-wasm-bindgen-0.2.104))
      (list "rust-wasm-bindgen-backend-0.2.104" (@@ (gnu packages rust-crates) rust-wasm-bindgen-backend-0.2.104))
      (list "rust-wasm-bindgen-macro-0.2.104" (@@ (gnu packages rust-crates) rust-wasm-bindgen-macro-0.2.104))
      (list "rust-wasm-bindgen-macro-support-0.2.104" (@@ (gnu packages rust-crates) rust-wasm-bindgen-macro-support-0.2.104))
      (list "rust-wasm-bindgen-shared-0.2.104" (@@ (gnu packages rust-crates) rust-wasm-bindgen-shared-0.2.104))
      (list "rust-wit-bindgen-0.46.0" (@@ (gnu packages rust-crates) rust-wit-bindgen-0.46.0))
      (list "rust-zerocopy-0.8.27" (@@ (gnu packages rust-crates) rust-zerocopy-0.8.27))
      (list "rust-zerocopy-derive-0.8.27" (@@ (gnu packages rust-crates) rust-zerocopy-derive-0.8.27)))))
    (inputs (list maturin))
    (native-inputs (list python-wrapper))
    (home-page "https://github.com/thedrow/fastuuid")
    (synopsis "Fast Python bindings to Rust UUID support")
    (description "FastUUID provides source-built Python bindings to Rust UUID support.")
    (license license:bsd-3)))

(define-public python-litellm
  (package
    (name "python-litellm")
    (version "1.78.0")
    (source
     (origin
       (method url-fetch)
       (uri ((@ (guix build-system pyproject) pypi-uri) "litellm" version))
       (sha256
        (base32 "0fqzsfzi9l7zz7yl18saf0rmrjwq3m66s5bb7axhjq71svh403h2"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; The fixed license grants MIT only outside enterprise/.
          (add-after 'unpack 'remove-nonfree-enterprise-code
            (lambda _
              (delete-file-recursively "enterprise")))
          (add-after 'unpack 'use-store-trust-bundle
            (lambda _
              ;; Never silently discard an explicit but invalid user CA file.
              ;; Guix Certifi points outside the store and may not exist in a
              ;; bare output or build container, so only its fallback changes.
              (substitute* "litellm/llms/custom_httpx/http_handler.py"
                (("isinstance\\(ssl_verify, str\\) and os.path.exists\\(ssl_verify\\)")
                 "isinstance(ssl_verify, str)")
                (("ssl_cert_file = os.getenv\\(\"SSL_CERT_FILE\"\\)")
                 (string-append
                  "ssl_cert_file = os.getenv(\"SSL_CERT_FILE\", "
                  "os.getenv(\"REQUESTS_CA_BUNDLE\"))"))
                (("if ssl_cert_file and os.path.exists\\(ssl_cert_file\\):")
                 "if ssl_cert_file is not None:")
                (("cafile = certifi.where\\(\\)")
                 (string-append
                  "cafile = None if os.getenv(\"SSL_CERT_DIR\") is not None else \""
                  #$output "/share/litellm/ca-certificates.crt\""))
                (("ssl.create_default_context\\(cafile=cafile\\)")
                 (string-append
                  "ssl.create_default_context(cafile=cafile, "
                  "capath=os.getenv(\"SSL_CERT_DIR\") "
                  "if cafile is None else None)")))))
          (add-after 'install 'install-store-trust-bundle
            (lambda _
              (use-modules (ice-9 rdelim))
              (let ((bundle (string-append #$output
                                          "/share/litellm/ca-certificates.crt")))
                (mkdir-p (dirname bundle))
                (call-with-output-file bundle
                  (lambda (port)
                    (for-each
                     (lambda (file)
                       (call-with-input-file file
                         (lambda (input)
                           (let loop ((line (read-line input)))
                             (unless (eof-object? line)
                               (display line port)
                               (newline port)
                               (loop (read-line input)))))))
                     (find-files (string-append #$nss-certs "/etc/ssl/certs")
                                 "\\.pem$"))))))))))
    (propagated-inputs
     (list python-aiohttp python-click python-fastuuid python-httpx
           python-importlib-metadata python-jinja2 python-jsonschema
           python-openai python-pydantic python-dotenv python-tiktoken
           ;; Dotprompt imports yaml unconditionally during import litellm,
           ;; although upstream lists it only under the proxy extra.
           python-pyyaml python-tokenizers))
    (inputs (list nss-certs))
    (native-inputs (list python-poetry-core python-wheel))
    (home-page "https://github.com/BerriAI/litellm")
    (synopsis "Core Python client for multiple LLM providers")
    (description "LiteLLM is Emigo's optional core LLM provider client.")
    (license license:expat)))

(define emigo-python-inputs
  (list python-diskcache python-epc python-gitignore-parser python-grep-ast
        python-litellm python-networkx python-orjson python-pygments
        python-scipy python-sexpdata python-tiktoken python-tqdm))

(define emigo-python-search-path
  (map (lambda (input)
         (file-append
          (cadr input)
          (string-append "/lib/python"
                         (version-major+minor (package-version python))
                         "/site-packages")))
       (append (map (lambda (input) (list (package-name input) input))
                    emigo-python-inputs)
               (apply append
                      (map package-transitive-propagated-inputs
                           emigo-python-inputs)))))

;; Session creation needs this BPE vocabulary even when no LLM is requested.
;; Tiktoken otherwise downloads it lazily into the user's cache.
(define emigo-cl100k-ranks
  (origin
    (method url-fetch)
    (uri "https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken")
    (sha256
     (base32 "19xjcplgzg0kl6bkbj8q3nshy47g7r8kixvzbfcxx6z9dsvj2f92"))))

(define emigo-tokenizer-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/openai/tiktoken/0.9.0/LICENSE")
    (sha256
     (base32 "11hxqp9da5ady31dq4wjxbi7nys3llri753r7mjqs4innjcv9321"))))

(define-public emigo
  (package
    (name "emigo")
    (version "0.5-0.91d122a")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/MatthewZMD/emigo")
             (commit "91d122a85cac1965e1a52185ed8711c5ef8f24c9")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1amplsqrdfw8djmam6j97sc82b474cpr3h9n1665h1ap6flsahy0"))))
    (build-system emacs-build-system)
    (arguments
     (list
      #:include #~'("^emigo\\.el$" "^emigo-epc\\.el$")
      #:tests? #t
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'apply-safety-and-launcher-patch
            (lambda _
              ;; Reject .. paths and symlink escapes before tool access.
              (substitute* "tools.py"
                (("return os.path.abspath\\(os.path.join\\(session_path, rel_path\\)\\)")
                 (string-append
                  "root = os.path.realpath(session_path)\n"
                  "    candidate = os.path.realpath(os.path.join(root, rel_path))\n"
                  "    if os.path.commonpath((root, candidate)) != root:\n"
                  "        raise ValueError(f\"Path escapes session root: "
                  "{rel_path}\")\n"
                  "    return candidate"))
                (((string-append
                   "abs_path = os.path.abspath\\(os.path.join\\("
                   "session.session_path, rel_path\\)\\)"))
                 "abs_path = _resolve_path(session.session_path, rel_path)"))
              (substitute* "session.py"
                (((string-append
                   "abs_path = os.path.abspath\\(os.path.join\\("
                   "self.session_path, rel_filename\\)\\)"))
                 (string-append
                  "root = os.path.realpath(self.session_path)\n"
                  "            abs_path = os.path.realpath("
                  "os.path.join(root, rel_filename))\n"
                  "            if os.path.commonpath((root, abs_path)) != root:\n"
                  "                return False, f\"File is outside session "
                  "directory: {rel_filename}\""))
                (((string-append
                   "if not abs_path.startswith\\(os.path.abspath\\("
                   "self.session_path\\)\\):"))
                 (string-append
                  "if os.path.commonpath((os.path.realpath(self.session_path), "
                  "abs_path)) != os.path.realpath(self.session_path):"))
                (((string-append
                   "abs_path = os.path.abspath\\(os.path.join\\("
                   "self.session_path, rel_path\\)\\)"))
                 (string-append
                  "root = os.path.realpath(self.session_path)\n"
                  "        abs_path = os.path.realpath(os.path.join(root, rel_path))\n"
                  "        if os.path.commonpath((root, abs_path)) != root:\n"
                  "            raise ValueError(f\"Path escapes session root: "
                  "{rel_path}\")")))
              ;; Guix ships tree-sitter 0.25: queries execute via QueryCursor.
              (substitute* "repomapper.py"
                (("from grep_ast import TreeContext, filename_to_lang")
                 (string-append
                  "from grep_ast import TreeContext, filename_to_lang\n"
                  "from tree_sitter import Query, QueryCursor"))
                (("query = language.query\\(query_scm\\)")
                 "query = Query(language, query_scm)")
                (("captures = query.captures\\(tree.root_node\\)")
                 "captures = QueryCursor(query).captures(tree.root_node)"))
              ;; Replacements modify files, so they need the same explicit
              ;; approval as commands and writes.
              (substitute* "emigo.py"
                (("TOOL_EXECUTE_COMMAND, TOOL_WRITE_TO_FILE,")
                 "TOOL_EXECUTE_COMMAND, TOOL_WRITE_TO_FILE, TOOL_REPLACE_IN_FILE,")
                (("TOOL_WRITE_TO_FILE,\n            # Add other tools")
                 (string-append
                  "TOOL_WRITE_TO_FILE,\n            TOOL_REPLACE_IN_FILE,\n"
                  "            # Add other tools")))
              ;; Use the installed backend and wrapper, not PATH or the build
              ;; directory.  llm_worker inherits this Python interpreter.
              (substitute* "emigo.el"
                (("\\(provide 'emigo\\)")
                 (string-append
                  "(setq emigo-python-file \"" #$output
                  "/share/emigo/backend/emigo.py\")\n"
                  "(setq emigo-python-command \"" #$output
                  "/bin/emigo-python\")\n\n(provide 'emigo)")))))
          (add-after 'install 'install-backend-data-and-notices
            (lambda _
              (use-modules (srfi srfi-1))
              (let ((backend (string-append #$output "/share/emigo/backend"))
                    (ranks (string-append #$output "/share/emigo/tiktoken"))
                    (doc (string-append #$output "/share/doc/emigo"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p backend)
                (mkdir-p ranks)
                (mkdir-p doc)
                (mkdir-p bin)
                (for-each (lambda (file) (install-file file backend))
                          (find-files "." "\\.py$"))
                ;; RepoMapper resolves its query files beside repomapper.py.
                (copy-recursively "queries" (string-append backend "/queries"))
                (copy-file #$emigo-cl100k-ranks
                           (string-append ranks
                            "/9b5ad71b2ce5302211f9c61530b329a4922fc6a4"))
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "LICENSE" "emigo-epc.el"))
                (copy-file #$emigo-tokenizer-license
                           (string-append doc "/TOKENIZER-LICENSE"))
                (call-with-output-file (string-append bin "/emigo-python")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/sh~%export PYTHONPATH=~s~%"
                             "export GUIX_PYTHONPATH=~s~%"
                             "export TIKTOKEN_CACHE_DIR=~s~%"
                             "export LITELLM_LOCAL_MODEL_COST_MAP=True~%"
                             "exec ~a/bin/python3 \"$@\"~%")
                            #$bash backend
                            (string-join (delete-duplicates
                                          (list #$@emigo-python-search-path)) ":")
                            ranks #$python)))
                (chmod (string-append bin "/emigo-python") #o555))))
          (delete 'check)
          (add-after 'install-backend-data-and-notices 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Installed-source mtimes differ between repeat builds; don't
                ;; write timestamp-based bytecode into the output while checking.
                (setenv "PYTHONDONTWRITEBYTECODE" "1")
                (with-directory-excursion
                    (string-append #$output "/share/emigo/backend")
                  (invoke (string-append #$output "/bin/emigo-python")
                          "test_setup.py")
                  (invoke (string-append #$output "/bin/emigo-python")
                          "repomapper.py" "--help"))))))))
    (propagated-inputs
     (append (list emacs-compat emacs-markdown-mode emacs-transient)
             emigo-python-inputs))
    (home-page "https://github.com/MatthewZMD/emigo")
    (synopsis "Emacs client for a local LLM coding-agent backend")
    (description "Emigo is an Emacs interface to a local coding-agent backend.
The installed Python launcher includes its dependency closure and the fixed
cl100k_base tokenizer vocabulary, so local context operations need no downloads.
Provider interactions require a separately configured model, endpoint and any
credentials required by that provider.  Tool writes, replacements and commands
require explicit approval.  Query data and upstream license notices are retained.")
    (license (list license:gpl3+ license:asl2.0 license:expat))))
