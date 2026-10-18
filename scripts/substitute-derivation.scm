;;; Inspect exact outputs, prewarm only their inputs, or register an indirect root.
(use-modules (guix derivations) (guix store) (ice-9 format))

(let ((root (getenv "SUBSTITUTE_REGISTER_ROOT")))
  (if root
      (with-store store
        (add-indirect-root store root))
      (let ((drv (read-derivation-from-file
                  (or (getenv "SUBSTITUTE_DERIVATION")
                      (error "SUBSTITUTE_DERIVATION is required")))))
        (if (getenv "SUBSTITUTE_PREWARM_INPUTS")
            (with-store store
              ;; These records preserve each input's requested output names,
              ;; including implicit builder/tool inputs omitted by package-inputs.
              ;; Raw sources are already store items, not necessarily .drv files.
              (set-build-options store
                                 #:use-substitutes? #t #:offload? #f
                                 #:build-cores 2 #:max-build-jobs 1
                                 #:timeout (string->number
                                            (getenv "SUBSTITUTE_BUILD_TIMEOUT"))
                                 #:max-silent-time 1800)
              (unless (build-derivations store
                                        (append (derivation-inputs drv)
                                                (derivation-sources drv)))
                (error "could not prewarm derivation inputs")))
            (for-each
             (lambda (output)
               (format #t "~a\t~a~%" (car output)
                       (derivation-output-path (cdr output))))
             (sort (derivation-outputs drv)
                   (lambda (a b) (string<? (car a) (car b)))))))))
