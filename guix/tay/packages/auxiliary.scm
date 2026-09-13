;;; Resolve auxiliary files shipped alongside tay package modules.

(define-module (tay packages auxiliary)
  #:export (search-tay-package-file))

(define (search-tay-package-file file)
  "Return the absolute name of FILE below tay/packages in the active load path."
  (let ((result (search-path %load-path
                             (string-append "tay/packages/" file))))
    (if result
        (canonicalize-path result)
        (error "tay package auxiliary file not found" file))))
