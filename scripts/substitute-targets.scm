;;; Discover public package objects from the authenticated, locked tay channel.
;;; Invoke with the locked profile's `guix repl scripts/substitute-targets.scm'.
;;; Do not pass -L: module sources must come from that profile's store closure.
;;;
;;; stdout: headerless TSV, one row per distinct package object:
;;; module (space-separated symbols), binding, name, version,
;;; outputs (comma-separated), supported systems (comma-separated), location file.
;;; Package aliases use the lexically first module/binding selector.  In
;;; particular, name/version pairs are metadata, never build selectors.
;;; stderr: module-import-error or export-error diagnostics.  Any such error
;;; makes discovery exit nonzero, even though the remaining modules are scanned.

(use-modules (guix discovery)
             ((gnu packages) #:select (%package-module-path))
             (guix packages)
             (guix diagnostics)
             (ice-9 format)
             (ice-9 hash-table)
             (srfi srfi-1)
             (srfi srfi-13))

(define %output-port (current-output-port))
(define %failed? #f)

(define (module-string module)
  (string-join (map symbol->string (module-name module)) " "))

(define (report-error kind selector details)
  (set! %failed? #t)
  (format (current-error-port) "substitute-targets: ~a ~s: ~s~%"
          kind selector details))

(define (locked-package-directory)
  ;; Loading (gnu packages) initializes the installed profile's channel paths.
  ;; %package-module-path includes channel source roots that are absent from
  ;; the initial %load-path; entries can be roots or (root . subdirectory).
  ;; Resolve symlinks before rejecting mutable package-path overrides.
  (let ((directory
         (any (lambda (entry)
                (let* ((root (if (pair? entry) (car entry) entry))
                       (candidate (string-append root "/tay/packages")))
                  ;; search-path looks for regular files, not directories.
                  (and (file-exists? candidate)
                       (eq? 'directory (stat:type (stat candidate)))
                       candidate)))
              (%package-module-path))))
    (unless directory
      (error "the locked Guix profile has no tay/packages source directory"))
    (let ((canonical (canonicalize-path directory)))
      (unless (string-prefix? "/gnu/store/" canonical)
        (error "refusing tay package modules outside the immutable store"
               canonical))
      canonical)))

(define (tay-package-file package)
  ;; Imported upstream reexports are not packages originating in this channel.
  ;; Factories and generated exports retain their tay/packages source location.
  (let* ((location (package-location package))
         (file (and location (location-file location))))
    (and file
         (or (string-prefix? "tay/packages/" file)
             (string-contains file "/tay/packages/"))
         file)))

(define (emit-module-exports module seen)
  (for-each
   (lambda (binding)
     (catch #t
       (lambda ()
         (let* ((package (module-ref module binding))
                (file (and (package? package) (tay-package-file package))))
           (when (and file (not (hashq-ref seen package)))
             (format %output-port "~a\t~a\t~a\t~a\t~a\t~a\t~a~%"
                     (module-string module)
                     (symbol->string binding)
                     (package-name package)
                     (package-version package)
                     (string-join (package-outputs package) ",")
                     (string-join (package-supported-systems package) ",")
                     file)
             (hashq-set! seen package #t))))
       (lambda args
         (report-error 'export-error
                       (list (module-name module) binding) args))))
   (sort (module-map (lambda (binding variable) binding) module)
         (lambda (left right)
           (string<? (symbol->string left) (symbol->string right))))))

(define (main)
  (let* ((directory (locked-package-directory))
         (root (dirname (dirname directory)))
         ;; all-modules scans Scheme sources recursively without the native
         ;; supported-systems filter used by package availability queries.
         ;; Redirect module-load output away from the machine-readable TSV.
         (modules
          (parameterize ((current-output-port (current-error-port)))
            (all-modules
             (list (cons root "tay/packages"))
             #:warn (lambda (file module exception)
                      (report-error 'module-import-error
                                    (list module file) exception)))))
         (seen (make-hash-table)))
    (parameterize ((current-output-port (current-error-port)))
      (for-each (lambda (module) (emit-module-exports module seen))
                (sort modules
                      (lambda (left right)
                        (string<? (module-string left)
                                  (module-string right))))))
    (if %failed? 1 0)))

(exit
 (catch #t
   main
   (lambda args
     (report-error 'discovery-error 'tay/packages args)
     1)))
