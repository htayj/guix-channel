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
                                    "\\.so$")))))))
    (propagated-inputs
     (list python-tree-sitter
           python-tree-sitter-c-sharp
           python-tree-sitter-embedded-template
           python-tree-sitter-yaml))
    (native-inputs (list python-cython python-setuptools))
    (home-page "https://github.com/Goldziher/tree-sitter-language-pack")
    (synopsis "Source-built collection of Tree-sitter language bindings")
    (description "A source-built Tree-sitter language bundle with bundled parser sources.")
    (license (list license:expat license:asl2.0 license:bsd-2
                   license:bsd-3 license:cc0 license:isc license:artistic2.0
                   license:public-domain))))

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
              (delete-file-recursively "enterprise"))))))
    (propagated-inputs
     (list python-aiohttp python-click python-fastuuid python-httpx
           python-importlib-metadata python-jinja2 python-jsonschema
           python-openai python-pydantic python-dotenv python-tiktoken
           python-tokenizers))
    (native-inputs (list python-poetry-core))
    (home-page "https://github.com/BerriAI/litellm")
    (synopsis "Core Python client for multiple LLM providers")
    (description "LiteLLM is Emigo's optional core LLM provider client.")
    (license license:expat)))

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
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'apply-safety-and-launcher-patch
            (lambda _
              ;; Reject .. paths and symlink escapes before tool access.
              (substitute* "tools.py"
                (("return os.path.abspath\\(os.path.join\\(session_path, rel_path\\)\\)")
                 "root = os.path.realpath(session_path)\n    candidate = os.path.realpath(os.path.join(root, rel_path))\n    if os.path.commonpath((root, candidate)) != root:\n        raise ValueError(f\"Path escapes session root: {rel_path}\")\n    return candidate")
                (("abs_path = os.path.abspath\\(os.path.join\\(session.session_path, rel_path\\)\\)")
                 "abs_path = _resolve_path(session.session_path, rel_path)"))
              (substitute* "session.py"
                (("abs_path = os.path.abspath\\(os.path.join\\(self.session_path, rel_filename\\)\\)")
                 "root = os.path.realpath(self.session_path)\n            abs_path = os.path.realpath(os.path.join(root, rel_filename))\n            if os.path.commonpath((root, abs_path)) != root:\n                return False, f\"File is outside session directory: {rel_filename}\"")
                (("if not abs_path.startswith\\(os.path.abspath\\(self.session_path\\)\\):")
                 "if os.path.commonpath((os.path.realpath(self.session_path), abs_path)) != os.path.realpath(self.session_path):")
                (("abs_path = os.path.abspath\\(os.path.join\\(self.session_path, rel_path\\)\\)")
                 "root = os.path.realpath(self.session_path)\n        abs_path = os.path.realpath(os.path.join(root, rel_path))\n        if os.path.commonpath((root, abs_path)) != root:\n            raise ValueError(f\"Path escapes session root: {rel_path}\")"))
              ;; Replacements modify files, so they need the same explicit
              ;; approval as commands and writes.
              (substitute* "emigo.py"
                (("TOOL_EXECUTE_COMMAND, TOOL_WRITE_TO_FILE,")
                 "TOOL_EXECUTE_COMMAND, TOOL_WRITE_TO_FILE, TOOL_REPLACE_IN_FILE,")
                (("TOOL_WRITE_TO_FILE,\n            # Add other tools")
                 "TOOL_WRITE_TO_FILE,\n            TOOL_REPLACE_IN_FILE,\n            # Add other tools"))
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
              (let ((backend (string-append #$output "/share/emigo/backend"))
                    (data (string-append #$output "/share/emigo/queries"))
                    (doc (string-append #$output "/share/doc/emigo"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p backend)
                (mkdir-p data)
                (mkdir-p doc)
                (mkdir-p bin)
                (for-each (lambda (file) (install-file file backend))
                          (find-files "." "\\.py$"))
                ;; RepoMapper resolves its query files beside repomapper.py.
                (copy-recursively "queries" (string-append backend "/queries"))
                (for-each (lambda (file) (install-file file doc))
                          '("README.md" "LICENSE" "emigo-epc.el"))
                (call-with-output-file (string-append bin "/emigo-python")
                  (lambda (port)
                    (format port "#!~a/bin/sh~%export PYTHONPATH=\"~a:$(dirname \"$0\")/../lib/python3.12/site-packages:${GUIX_PYTHONPATH-}${PYTHONPATH:+:$PYTHONPATH}\"~%exec ~a/bin/python3 \"$@\"~%"
                            #$bash backend #$python)))
                (chmod (string-append bin "/emigo-python") #o555)))))))
    (propagated-inputs
     (list emacs-compat emacs-markdown-mode emacs-transient
           python-aiohttp python-click python-diskcache python-epc
           python-gitignore-parser python-grep-ast python-httpx
           python-importlib-metadata python-jinja2 python-jsonschema
           python-litellm python-networkx python-openai python-orjson
           python-pydantic python-pygments python-scipy python-sexpdata
           python-tiktoken python-tokenizers python-tqdm))
    (native-inputs (list python-cython python-poetry-core python-setuptools))
    (home-page "https://github.com/MatthewZMD/emigo")
    (synopsis "Emacs client for a local LLM coding-agent backend")
    (description "Emigo is an Emacs interface to a local coding-agent backend.")
    (license (list license:gpl3+ license:asl2.0 license:expat))))
