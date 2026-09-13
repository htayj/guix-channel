;;; GNU Guix package for alexispurslane/treesit-sexp.

(define-module (tay packages treesit-sexp)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages starred-a-c))

(define-public emacs-treesit-sexp
  (package
    (name "emacs-treesit-sexp")
    ;; The source snapshot is the channel's immutable version identifier.
    (version (package-version alexispurslane-treesit-sexp-source))
    (source (package-source alexispurslane-treesit-sexp-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; There is no upstream Makefile.  Exercise the no-grammar fallback and
      ;; the bundled offline structural-editing ERT suite directly with Emacs.
      #:test-command
      #~(list "emacs" "--batch" "-Q" "-L" "."
              "--eval"
              "(progn
                 (require 'treesit-sexp)
                 (with-temp-buffer
                   (insert \"(a b)\")
                   (goto-char (point-min))
                   (treesit-sexp-forward 1)
                   (unless (= (point) (point-max))
                     (error \"treesit-sexp fallback navigation failed\"))))"
              "-l" "test-structural-editing.el"
              "-f" "ert-run-tests-batch-and-exit")
      ;; Keep the test fixture in the build tree without installing it as a
      ;; runtime library.
      #:exclude #~(cons "^test-structural-editing\\.el$" %default-exclude)))
    (home-page "https://github.com/alexispurslane/treesit-sexp")
    (synopsis "Tree-sitter based structural editing for Emacs")
    (description
     "This package makes Emacs's built-in S-expression navigation and
structural editing commands understand tree-sitter syntax trees.  It works
with any tree-sitter-enabled language without language-specific queries, and
falls back to the standard Emacs commands when no parser is available.")
    (license license:bsd-0)))
