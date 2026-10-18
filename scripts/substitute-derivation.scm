;;; Inspect every output of an exact derivation, or register an indirect root.
(use-modules (guix derivations) (guix store) (ice-9 format))

(let ((root (getenv "SUBSTITUTE_REGISTER_ROOT")))
  (if root
      (with-store store
        (add-indirect-root store root))
      (let ((drv (read-derivation-from-file
                  (or (getenv "SUBSTITUTE_DERIVATION")
                      (error "SUBSTITUTE_DERIVATION is required")))))
        (for-each
         (lambda (output)
           (format #t "~a\t~a~%" (car output)
                   (derivation-output-path (cdr output))))
         (sort (derivation-outputs drv)
               (lambda (a b) (string<? (car a) (car b))))))))
