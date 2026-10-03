;;; SPDX-License-Identifier: GPL-3.0-or-later
(require :asdf)

;; Read only Guix's compiled closure, never user/Quicklisp registries.  The
;; generated fragments contain (:TREE ...) and source-to-FASL translations.
(let* ((root (uiop:ensure-directory-pathname (uiop:getenv "COTD_ASDF_CONFIG")))
       (registry (directory (merge-pathnames "source-registry.conf.d/*.conf" root)))
       (translations (directory (merge-pathnames "asdf-output-translations.conf.d/*.conf" root))))
  (flet ((forms (files)
           (mapcar (lambda (file)
                     (with-open-file (stream file)
                       (let ((*read-eval* nil)) (read stream))))
                   files)))
    (asdf:initialize-source-registry
     (append (list :source-registry) (forms registry)
             (list :ignore-inherited-configuration)))
    (asdf:initialize-output-translations
     (append (list :output-translations) (forms translations)
             (list :ignore-inherited-configuration)))))

(asdf:load-system :cotd)
(cotd::cotd-exec)
