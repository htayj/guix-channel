;;; Discover public package objects from the authenticated, locked tay channel.
;;; Invoke with the locked profile's `guix repl scripts/substitute-targets.scm'.
;;; Do not pass -L: module sources must come from that profile's store closure.
;;;
;;; stdout: headerless TSV, one row per distinct package object:
;;; module (space-separated symbols), binding, name, version,
;;; outputs (comma-separated), supported systems (comma-separated), location file,
;;; publication policy ("allowed" or the first deterministic blocker).
;;; Package aliases use the lexically first module/binding selector.  In
;;; particular, name/version pairs are metadata, never build selectors.
;;; stderr: module-import-error or export-error diagnostics.  Any such error
;;; makes discovery exit nonzero, even though the remaining modules are scanned.

(use-modules (guix discovery)
             ((gnu packages) #:select (%package-module-path))
             (guix packages)
             (guix diagnostics)
             ((guix licenses) #:select (license? license-uri))
             ((guix utils) #:select (%current-system %current-target-system))
             (ice-9 format)
             (ice-9 hash-table)
             (ice-9 match)
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

(define %no-permission-uri "https://choosealicense.com/no-permission/")
(define %publication-blockers (make-hash-table))

(define (restricted-package? package)
  ;; Do this before forcing any license or input fields: operator-supplied
  ;; artifacts must not be inspected as part of publication discovery.
  (or (member (package-name package) '("tern" "sentinelone"))
      (let ((file (tay-package-file package)))
        (and file (member (basename file) '("tern.scm" "sentinelone.scm"))))))

(define (no-permission-license? value)
  (and (license? value)
       (let ((uri (license-uri value)))
         (if (list? uri)
             (member %no-permission-uri uri)
             (equal? uri %no-permission-uri)))))

(define (explicitly-non-substitutable? package)
  ;; Inspect only the declared argument list; do not lower build arguments or
  ;; evaluate G-expressions.  An omitted flag is not a publication blocker.
  (let* ((arguments (package-arguments package))
         (flag (and (list? arguments) (memq #:substitutable? arguments))))
    (and flag (pair? (cdr flag)) (eq? #f (cadr flag)))))

(define (direct-publication-blocker package)
  (cond
   ((restricted-package? package) (cons "restricted-artifact" package))
   ((explicitly-non-substitutable? package) (cons "non-substitutable" package))
   (else
    (let ((license (package-license package)))
      (cond
       ((not license) (cons "absent-license" package))
       ((any no-permission-license? (if (list? license) license (list license)))
        (cons "no-permission-license" package))
       (else #f))))))

(define (package-publication-blocker package cache)
  ;; Guix's accessors force and normalize thunked input fields into labeled
  ;; tuples.  package-transitive-inputs follows only propagated edges below
  ;; those tuples; recurse over package-direct-inputs instead to include each
  ;; dependency's native, regular, and propagated inputs.  Cache each package
  ;; object once per system rather than recomputing every export's closure.
  (let ((cached (hashq-ref cache package 'unseen)))
    (cond
     ((eq? cached 'visiting)
      (error "cyclic package inputs during publication discovery"
             (package-name package)))
     ((not (eq? cached 'unseen)) cached)
     (else
      (hashq-set! cache package 'visiting)
      (catch #t
        (lambda ()
          (let ((blocker
                 (or (direct-publication-blocker package)
                     (any (match-lambda
                            ((_ (? package? input) _ ...)
                             (package-publication-blocker input cache))
                            (_ #f))
                          (package-direct-inputs package)))))
            (hashq-set! cache package blocker)
            blocker))
        (lambda (key . args)
          ;; Do not leave an in-progress marker in the shared cache when an
          ;; input thunk fails: other exports must see the actual error too.
          (hashq-remove! cache package)
          (apply throw key args)))))))

(define (publication-policy package)
  (let* ((systems (if (string=? (package-name package) "calcrogue")
                      '("x86_64-linux" "i686-linux")
                      '("x86_64-linux")))
         (blocker
          (or (direct-publication-blocker package)
              (any (lambda (system)
                     (and (member system (package-supported-systems package))
                          (let ((cache
                                 (or (hash-ref %publication-blockers system)
                                     (let ((cache (make-hash-table)))
                                       (hash-set! %publication-blockers system cache)
                                       cache))))
                            (parameterize ((%current-system system)
                                           (%current-target-system #f))
                              (package-publication-blocker package cache)))))
                   systems))))
    (if blocker
        (string-append
         (if (eq? package (cdr blocker)) "" "dependency-")
         (car blocker)
         (if (and (eq? package (cdr blocker))
                  (string=? (car blocker) "restricted-artifact"))
             ""
             (string-append
              ":" (string-map (lambda (character)
                                 (if (memv character '(#\tab #\newline #\return))
                                     #\space character))
                               (package-name (cdr blocker))))))
        "allowed")))

(define (target-publication-policy package module binding)
  (catch #t
    (lambda () (publication-policy package))
    (lambda (key . args)
      ;; Policy evaluation failures are per-target failures, not license
      ;; decisions or global discovery failures.  Preserve the export row so
      ;; the orchestrator can record the failure and continue other targets.
      (format (current-error-port)
              "substitute-targets: policy-evaluation-error ~s: ~s ~s~%"
              (list (module-name module) binding (package-name package))
              key args)
      (string-append
       "evaluation-failed:"
       (string-map (lambda (character)
                     (if (memv character '(#\tab #\newline #\return))
                         #\space character))
                   (if (symbol? key) (symbol->string key)
                       (format #f "~s" key)))))))

(define (emit-module-exports module seen)
  (for-each
   (lambda (binding)
     (catch #t
       (lambda ()
         (let* ((package (module-ref module binding))
                (file (and (package? package) (tay-package-file package))))
           (when (and file (not (hashq-ref seen package)))
             (format %output-port "~a\t~a\t~a\t~a\t~a\t~a\t~a\t~a~%"
                     (module-string module)
                     (symbol->string binding)
                     (package-name package)
                     (package-version package)
                     (string-join (package-outputs package) ",")
                     (string-join (package-supported-systems package) ",")
                     file
                     (target-publication-policy package module binding))
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
