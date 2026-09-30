;;; GNU Guix package for larsbrinkhoff/emacs-cl.

(define-module (tay packages emacs-cl)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (tay packages larsbrinkhoff-a-f))

(define-public emacs-cl
  (package
    (name "emacs-cl")
    (version (package-version larsbrinkhoff-emacs-cl-source))
    (source
     (origin
       (inherit (package-source larsbrinkhoff-emacs-cl-source))
       (patches
        (search-patches "tay/packages/patches/emacs-cl-emacs-30-compat.patch"))
       (patch-flags '("-p1" "--fuzz=0"))))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; The implementation lives below src/; COPYING remains at the root.
      #:lisp-directory "src"
      #:test-command
      #~(list
         "sh" "-c"
         (string-append
          "emacs --batch -Q -L . -l load-cl.el -l batch.el -l tests.el -f test-cl "
          "< /dev/null > test.log 2>&1; status=$?; cat test.log; "
          "test $status -eq 0; "
          "awk '\n"
          "  /^[[:space:]]*PASS:/ { pass = $2; summaries++ }\n"
          "  /^[[:space:]]*FAIL evaluation:/ { eval = $3; summaries++ }\n"
          "  /^[[:space:]]*FAIL compilation:/ { comp = $3; summaries++ }\n"
          "  /^[[:space:]]*FAIL execution:/ { exe = $3; summaries++ }\n"
          "  END { exit !(summaries == 4 && pass == 180 && "
          "eval == 0 && comp == 0 && exe == 0) }\n"
          "' test.log"))
      ;; tests.el is the upstream test driver, not installed runtime code.
      #:exclude #~(cons "^tests\\.el$" %default-exclude)
      #:phases
      #~(modify-phases %standard-phases
          ;; This predates ELPA and has no autoload declarations.
          (delete 'ensure-package-description)
          (delete 'make-autoloads)
          (delete 'validate-compiled-autoloads)
          ;; The upstream compile-cl step does not work with Emacs 30's
          ;; eager compiler macroexpansion.  Install evaluated sources;
          ;; load-cl-file evaluates top-level forms without eager expansion.
          (delete 'build)
          ;; lisp-directory leaves the build in src/.  Return to the root
          ;; so Guix installs the GPLv2 notice from COPYING.
          (add-before 'install-license-files 'leave-lisp-directory
            (lambda _ (chdir ".."))))))
    (home-page "https://github.com/larsbrinkhoff/emacs-cl")
    (synopsis "Common Lisp implemented in Emacs Lisp")
    (description
     "Emacs Common Lisp is an implementation of Common Lisp written in Emacs
Lisp.  Loading @file{load-cl.el} loads the interpreter, compiler, and Common
Lisp listener.  This package ports the original implementation to Emacs 30
without changing Emacs compiler or macroexpansion internals.")
    (license (package-license larsbrinkhoff-emacs-cl-source))))
