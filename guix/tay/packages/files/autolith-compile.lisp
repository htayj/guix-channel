;;; Build-only repair for SBCL 2.6.6's inferred function type metadata.
;;;
;;; src/code/type-class.lisp assigns address-dependent CTYPE hashes, and
;;; src/code/type.lisp's UNION-UNPARSE preserves residual union order.
;;; src/compiler/entry.lisp:COMPUTE-ENTRY-INFO embeds the resulting equivalent
;;; but differently ordered type specifiers in FASLs.  Canonicalize only that
;;; metadata before the compiler dumps it; never rewrite FASL bytes, compiler
;;; inference, code, or the runtime.  Keep argument order and literal data.

(unless (string= (lisp-implementation-version) "2.6.6")
  (error "Autolith's entry-type compilation hook requires SBCL 2.6.6."))

(labels
    ((printable-p (value &optional ancestors)
       ;; Do not call application printers, or sort by allocation addresses or
       ;; uninterned symbol identities. Unknown type/literal objects stay put.
       (typecase value
         (symbol (not (null (symbol-package value))))
         ((or number character string) t)
         (cons (and (not (member value ancestors :test #'eq))
                    (let ((ancestors (cons value ancestors)))
                      (and (printable-p (car value) ancestors)
                           (printable-p (cdr value) ancestors)))))
         (t nil)))
     (key (value)
       (when (printable-p value)
         (handler-case
             (with-standard-io-syntax
               (let ((*package* (find-package "KEYWORD"))
                     (*print-readably* t)
                     (*print-circle* t))
                 (write-to-string value)))
           (print-not-readable () nil))))
     (ordered (values)
       (let ((keys (mapcar #'key values)))
         (if (every #'identity keys)
             (mapcar #'cdr
                     (stable-sort (mapcar #'cons keys values)
                                  #'string< :key #'car))
             values)))
     (arguments (values)
       ;; FUNCTION argument lists contain types, lambda markers, and keyword
       ;; pairs. Only the type position of a keyword pair may be transformed.
       (let ((keywords nil))
         (mapcar
          (lambda (value)
            (cond ((member value '(&optional &rest &key &allow-other-keys))
                   (when (eq value '&key) (setf keywords t))
                   value)
                  ((and keywords (consp value) (keywordp (car value))
                        (consp (cdr value)) (null (cddr value)))
                   (list (car value) (canonical (cadr value))))
                  (t (canonical value))))
          values)))
     (canonical (type)
       (if (atom type)
           type
           (case (car type)
             ((or and)
              (cons (car type) (ordered (mapcar #'canonical (cdr type)))))
             (member (cons 'member (ordered (copy-list (cdr type)))))
             ((function sb-int:sfunction)
              (if (and (consp (cdr type)) (consp (cddr type))
                       (null (cdddr type)))
                  (list (car type)
                        (if (listp (cadr type))
                            (arguments (cadr type))
                            (cadr type))
                        (canonical (caddr type)))
                  type))
             (values (cons 'values (arguments (cdr type))))
             ((cons not)
              (cons (car type) (mapcar #'canonical (cdr type))))
             ((array simple-array vector complex)
              (if (consp (cdr type))
                  (list* (car type) (canonical (cadr type)) (cddr type))
                  type))
             ;; EQL/MEMBER data, numeric bounds, SATISFIES predicates and
             ;; unknown extensions are not arbitrary trees of type forms.
             (t type)))))
  (sb-int:encapsulate
   'sb-c::compute-entry-info 'autolith-guix-entry-type
   (lambda (original function info)
     (multiple-value-prog1 (funcall original function info)
       (setf (sb-c::entry-info-type info)
             (canonical (sb-c::entry-info-type info)))))))
