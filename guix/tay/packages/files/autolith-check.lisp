;;; Run upstream's complete catalog plus both optional feature suites.
(require :asdf)
(let* ((source (uiop:ensure-directory-pathname
                (or (uiop:getenv "AUTOLITH_NIX_SOURCE_ROOT")
                    (error "Autolith source root is not set.")))))
  (load (merge-pathnames ".qlot/setup.lisp" source))
  ;; Keep upstream process isolation, fixture cleanup, result validation and
  ;; recovery checks rather than substituting a smaller package-only suite.
  (setf (symbol-value (intern "*CHECK-SCRIPT-LIBRARY-MODE*" '#:cl-user)) t)
  (load (merge-pathnames "script/check.lisp" source))
  (let ((status (funcall (symbol-function (find-symbol "CHECK-MAIN" '#:cl-user))
                         '("--jobs" "1") source)))
    (unless (zerop status) (uiop:quit status)))
  ;; The ordinary process workers load autolith/tests.  Feature-specific test
  ;; systems extend the catalog separately and use their upstream test-op.
  (asdf:test-system :autolith/structural/tests)
  (asdf:test-system :autolith/debug/tests))
