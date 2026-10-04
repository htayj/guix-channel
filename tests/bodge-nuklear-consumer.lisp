;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Offline external consumer of the delivered compiled ASDF closure.
(require :asdf)

;; Same registry/translation initialization convention as cotd-entry.lisp.
;; Neither user configuration nor Quicklisp is inherited.
(let* ((roots (mapcar #'uiop:ensure-directory-pathname
                     (list (uiop:getenv "NUKLEAR_ASDF_CONFIG")
                           (uiop:getenv "NUKLEAR_BLOB_ASDF_CONFIG"))))
       (registry (loop for root in roots append
                     (directory (merge-pathnames "source-registry.conf.d/*.conf" root))))
       (translations (loop for root in roots append
                         (directory (merge-pathnames "asdf-output-translations.conf.d/*.conf" root)))))
  (assert registry)
  (assert translations)
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

;; Loading the blob must itself register and load the library.  Do not bypass
;; bodge-blobs-support with a direct CFFI load or support load-foreign-libraries.
(asdf:load-system :nuklear-blob)
(asdf:load-system :bodge-nuklear-bindings)
(asdf:load-system :bodge-nuklear)

(defpackage :bodge-nuklear.consumer (:use :cl :cffi-c-ref))
(in-package :bodge-nuklear.consumer)

(defvar *width-calls* 0)
(nk:define-text-width-callback consumer-text-width (handle height text)
  (incf *width-calls*)
  (* (length text) 8.0f0))

(defun slot-pointer (pointer record slot)
  (cffi:foreign-slot-pointer pointer (list :struct record) slot))

(defun slot-value-at (pointer record slot)
  (cffi:foreign-slot-value pointer (list :struct record) slot))

(defun command-labels (context)
  (let ((labels nil) (commands 0))
    (nk:docommands (command context)
      (incf commands)
      (assert (< commands 1000))
      (when (eq (nk:command-type command) :text)
        (let ((length (slot-value-at command '%nuklear:command-text '%nuklear::length)))
          (assert (<= 0 length 1024))
          (push (cffi:foreign-string-to-lisp
                 (slot-pointer command '%nuklear:command-text '%nuklear::string)
                 :count length :encoding :utf-8)
                labels))))
    (values (nreverse labels) commands)))

(let* ((expected (truename (uiop:getenv "NUKLEAR_NATIVE_LIBRARY")))
       (registered (bodge-blobs-support:list-registered-libraries))
       (loaded (find-if
                (lambda (library)
                  (let ((path (cffi:foreign-library-pathname library)))
                    (and path (equal (truename path) expected))))
                (cffi:list-foreign-libraries :loaded-only t))))
  (assert (typep (asdf:find-system :nuklear-blob) 'asdf/interface::bodge-blob-system))
  (assert (member expected registered :test #'equal :key #'truename))
  (assert (string= "libnuklear.so"
                   (bodge-blobs-support:find-loaded-library-name :nuklear-blob nil)))
  (assert loaded)
  (assert (cffi:foreign-library-loaded-p loaded))
  (let ((font (nk:make-user-font 16.0f0 'consumer-text-width))
        (context nil) (x 0) (y 0) (text-count 0) (command-count 0)
        (activations nil) (context-destroyed nil) (font-destroyed nil))
    (unwind-protect
         (progn
           (assert (not (cffi:null-pointer-p font)))
           (assert (= 16.0f0 (slot-value-at font '%nuklear:user-font '%nuklear::height)))
           (assert (cffi:pointer-eq
                    (slot-value-at font '%nuklear:user-font '%nuklear::width)
                    (cffi:get-callback 'consumer-text-width)))
           (setf context (nk:make-context font))
           (assert (not (cffi:null-pointer-p context)))
           (assert (= 1 (slot-value-at context '%nuklear:context '%nuklear::use-pool)))
           (assert (cffi:pointer-eq
                    (slot-value-at (slot-pointer context '%nuklear:context '%nuklear::style)
                                   '%nuklear:style '%nuklear::font)
                    font))
           (flet ((frame (down first-frame)
                    (%nuklear:input-begin context)
                    (%nuklear:input-motion context x y)
                    (%nuklear:input-button context :left x y down)
                    (%nuklear:input-end context)
                    (let* ((input (slot-pointer context '%nuklear:context '%nuklear::input))
                           (mouse (slot-pointer input '%nuklear:input '%nuklear::mouse))
                           (buttons (slot-pointer mouse '%nuklear:mouse '%nuklear::buttons)))
                      (assert (= down (slot-value-at buttons '%nuklear:mouse-button '%nuklear::down))))
                    (c-with ((bounds (:struct %nuklear:rect) :clear t)
                             (button (:struct %nuklear:rect) :clear t))
                      (assert (plusp
                               (%nuklear:begin context "Consumer"
                                               (%nuklear:rect (bounds &) 20.0f0 20.0f0 320.0f0 220.0f0)
                                               (nk:panel-mask :border :title :no-scrollbar))))
                      (unwind-protect
                           (progn
                             (%nuklear:layout-row-static context 32.0f0 140 1)
                             (%nuklear:widget-bounds (button &) context)
                             (when first-frame
                               (setf x (floor (+ (button :x) (/ (button :w) 2)))
                                     y (floor (+ (button :y) (/ (button :h) 2)))))
                             (push (%nuklear:button-label context "Activate") activations)
                             (%nuklear:layout-row-dynamic context 28.0f0 1)
                             (%nuklear:label context "Native consumer label"
                                             (cffi:foreign-enum-value '%nuklear:text-alignment :left)))
                        (%nuklear:end context)))
                    (assert (not (cffi:null-pointer-p (%nuklear:window-find context "Consumer"))))
                    (multiple-value-bind (labels commands) (command-labels context)
                      (assert (member "Activate" labels :test #'string=))
                      (assert (member "Native consumer label" labels :test #'string=))
                      (incf text-count (count "Native consumer label" labels :test #'string=))
                      (incf command-count commands))
                    (%nuklear:clear context)
                    (assert (cffi:null-pointer-p (%nuklear:command-list-begin context)))
                    (multiple-value-bind (labels commands) (command-labels context)
                      (assert (null labels))
                      (assert (zerop commands)))))
             (frame 0 t)
             (frame 1 nil)
             ;; Native configuration has NK_BUTTON_TRIGGER_ON_RELEASE: a
             ;; genuine down/up transition must activate only the third frame.
             (frame 0 nil))
           (assert (equal (nreverse activations) '(0 0 1)))
           (assert (= text-count 3))
           (assert (plusp *width-calls*)))
      (when context
        (nk:destroy-context context)
        (setf context-destroyed t))
      (nk:destroy-user-font font)
      (setf font-destroyed t))
    (assert (and context-destroyed font-destroyed))
    (with-open-file (stream (uiop:getenv "NUKLEAR_LISP_RECEIPT")
                            :direction :output :if-exists :supersede)
      (format stream "{~%  ~S: ~S,~%  ~S: true,~%  ~S: true,~%  ~S: [0, 0, 1],~%  ~S: ~D,~%  ~S: ~D,~%  ~S: ~D,~%  ~S: true,~%  ~S: true,~%  ~S: true~%}~%"
              "loaded_library" (namestring expected)
              "registered_by_bodge_blobs_support" "cffi_loaded"
              "button_frames" "label_commands" text-count
              "commands_traversed" command-count "font_width_calls" *width-calls*
              "clear_emptied_commands" "context_destroyed" "font_destroyed"))
    (format t "Installed nuklear-blob, bodge-nuklear-bindings and bodge-nuklear: native context/font, release-triggered button, label commands, clear and cleanup passed.~%")))
