;;; Loader-context validation for the immutable Hermes Python runtime.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hermes-python-runpath)
  #:use-module (guix gexp)
  #:export (hermes-runtime-runpath-phase))

;; The Intel-containing aggregate cannot be rewritten.  Its MIT extension
;; supplies inherited DT_RPATH instead; all other output ELFs must pass Guix's
;; ordinary, independent DT_RUNPATH validation.
(define hermes-runtime-runpath-phase
  #~(lambda* (#:key outputs
              (elf-directories '("lib" "lib64" "libexec" "bin" "sbin"))
              #:allow-other-keys)
      (use-modules (guix build gremlin)
                   (guix build utils)
                   (ice-9 match)
                   (ice-9 regex)
                   (srfi srfi-1)
                   (srfi srfi-13))

      (define (same-file? left right)
        (let ((left (stat left)) (right (stat right)))
          (and (= (stat:dev left) (stat:dev right))
               (= (stat:ino left) (stat:ino right)))))

      (define (dynamic-info file)
        (or (file-dynamic-info file)
            (error "CTranslate2 loader-context file has no dynamic information"
                   file)))

      (define (store-directories file entries)
        ;; Normalize $ORIGIN/../... before checking the store boundary.  Do not
        ;; accept relative paths, unknown loader variables, or host directories.
        (delete-duplicates
         (map (lambda (entry)
                (let ((expanded (expand-origin entry (dirname file))))
                  (unless (and (string-prefix? "/" expanded)
                               (not (string-contains expanded "$"))
                               (directory-exists? expanded))
                    (error "Invalid CTranslate2 loader-context search directory"
                           file entry))
                  (let ((directory (canonicalize-path expanded)))
                    (unless (store-file-name? directory)
                      (error "Non-store CTranslate2 loader-context directory"
                             file directory))
                    directory)))
              entries)))

      (define (resolve-needed file info directories)
        ;; Unlike Gremlin's default libc exemption, this context checks every
        ;; DT_NEEDED name, including libc, against actual canonical store files.
        (let ((resolved '()) (valid? #t))
          (for-each
           (lambda (needed)
             (let ((found (and (not (string-contains needed "/"))
                               (search-path directories needed))))
               (if found
                   (let ((canonical (canonicalize-path found)))
                     (unless (and (store-file-name? canonical)
                                  (elf-file? canonical))
                       (error "Invalid CTranslate2 loader-context dependency"
                              file needed canonical))
                     (set! resolved (cons canonical resolved)))
                   (begin
                     (format (current-error-port)
                             "~a: error: DT_NEEDED ~s cannot be found in CTranslate2 loader context ~s~%"
                             file needed directories)
                     (set! valid? #f)))))
           (elf-dynamic-info-needed info))
          (unless valid?
            (error "CTranslate2 loader-context dependency validation failed"
                   file))
          (reverse resolved)))

      (let* ((out (or (assoc-ref outputs "out")
                      (error "Hermes runtime has no out output")))
             (site (string-append out "/lib/python3.11/site-packages"))
             (extension-directory (string-append site "/ctranslate2"))
             (aggregate-directory (string-append site "/ctranslate2.libs"))
             (directories
              (append-map
               (match-lambda
                 (("debug" . _) '())
                 ((_ . output)
                  (filter directory-exists?
                          (map (lambda (directory)
                                 (string-append output "/" directory))
                               elf-directories))))
               outputs))
             (files (append-map
                     (lambda (directory)
                       (find-files directory
                                   (lambda (file stat) (elf-file? file))))
                     directories))
             (extensions
              (filter (lambda (file)
                        (string-match "/ctranslate2/_ext[^/]*$" file))
                      files))
             (aggregates
              (filter (lambda (file)
                        (string-match "/ctranslate2\\.libs/libctranslate2-[^/]*$"
                                      file))
                      files)))
        (unless (and (= (length extensions) 1) (= (length aggregates) 1))
          (error "Expected exactly one CTranslate2 extension and protected aggregate"
                 extensions aggregates))
        (let* ((extension (car extensions))
               (aggregate (car aggregates))
               (aggregate-name (basename aggregate)))
          (unless (and (string=? (dirname extension) extension-directory)
                       (string=? (basename extension)
                                 "_ext.cpython-311-x86_64-linux-gnu.so")
                       (string=? (dirname aggregate) aggregate-directory)
                       (string=? aggregate-name
                                 "libctranslate2-5a650b64.so.4.7.1")
                       (string=? extension (canonicalize-path extension))
                       (string=? aggregate (canonicalize-path aggregate)))
            (error "Unexpected CTranslate2 loader-context paths"
                   extension aggregate))

          ;; Keep the standard traversal, inode deduplication, and non-short-
          ;; circuiting diagnostics for every ELF except these exact two files.
          (unless
              (every*
               (lambda (directory)
                 (let ((ordinary
                        (delete-duplicates
                         (remove (lambda (file)
                                   (or (string=? file extension)
                                       (string=? file aggregate)))
                                 (find-files directory
                                             (lambda (file stat)
                                               (elf-file? file))))
                         same-file?)))
                   (format (current-error-port)
                           "validating RUNPATH of ~a binaries in ~s...~%"
                           (length ordinary) directory)
                   (every* validate-needed-in-runpath ordinary)))
               directories)
            (error "RUNPATH validation failed"))

          (let* ((extension-info (dynamic-info extension))
                 (aggregate-info (dynamic-info aggregate))
                 (rpath (elf-dynamic-info-rpath extension-info)))
            (unless (and (pair? rpath)
                         (null? (elf-dynamic-info-runpath extension-info))
                         (= (count (lambda (needed)
                                     (string=? needed aggregate-name))
                                   (elf-dynamic-info-needed extension-info))
                            1)
                         (null? (elf-dynamic-info-rpath aggregate-info))
                         (null? (elf-dynamic-info-runpath aggregate-info)))
              (error "CTranslate2 extension must directly load the unchanged aggregate through inherited DT_RPATH"
                     extension aggregate))
            (let* ((inherited (store-directories extension rpath))
                   (selected (search-path inherited aggregate-name))
                   (visited (list extension)))
              (define (validate-closure file ancestors)
                (unless (member file visited)
                  (set! visited (cons file visited))
                  (let* ((info (dynamic-info file))
                         (runpath (elf-dynamic-info-runpath info))
                         (rpath (elf-dynamic-info-rpath info))
                         ;; DT_RUNPATH suppresses this object's RPATH ancestry
                         ;; for its direct children and is not itself inherited.
                         (own-rpath (if (null? runpath)
                                        (store-directories file rpath)
                                        '()))
                         (child-ancestors (append own-rpath ancestors))
                         (search (if (null? runpath)
                                     child-ancestors
                                     (store-directories file runpath))))
                    (for-each (lambda (dependency)
                                (validate-closure dependency child-ancestors))
                              (resolve-needed file info search)))))
              (unless (and selected
                           (string=? (canonicalize-path selected) aggregate))
                (error "CTranslate2 DT_RPATH selects a different aggregate"
                       extension selected aggregate))
              ;; Validate the extension's complete direct dependency set too;
              ;; then follow every selected dependency with its own loader rules.
              (for-each (lambda (dependency)
                          (validate-closure dependency inherited))
                        (resolve-needed extension extension-info inherited))
              (format (current-error-port)
                      "CTranslate2 loader context validated: ~a -> ~a (~a dependency ELFs); protected aggregate is not validated as an isolated object. Runtime import proof is required separately.~%"
                      extension aggregate (- (length visited) 1))))
          #t))))
