;;; emacs-application-framework-smoke.el --- Native EAF GUI proof -*- lexical-binding: t; -*-

;; Load in graphical Emacs -Q with the installed EAF directory on load-path,
;; then schedule (run-with-timer 0.5 nil #'eaf-smoke-run).
;; EAF_SMOKE_IMPORT is the ImageMagick import executable, EAF_SMOKE_ARTIFACTS
;; is a writable artifact directory, and EAF_SMOKE_RESULT is the JSON filename.
;; This helper uses the installed upstream demo, never a substitute application.

(require 'cl-lib)
(require 'json)

(defvar eaf-smoke--running nil)
(defvar eaf-smoke--stage "setup")
(defvar eaf-smoke--artifacts nil)
(defvar eaf-smoke--result nil)
(defvar eaf-smoke--evidence nil)
(defconst eaf-smoke--timeout 20)

(defun eaf-smoke--check (condition description)
  (unless condition (error "EAF native smoke: %s" description)))

(defun eaf-smoke--wait (predicate description &optional timeout)
  "Wait boundedly for PREDICATE while servicing EPC, timers and redisplay."
  (let ((deadline (+ (float-time) (or timeout eaf-smoke--timeout)))
        satisfied)
    (while (and (not (setq satisfied (funcall predicate)))
                (< (float-time) deadline))
      (redisplay t)
      (accept-process-output nil 0.05))
    (eaf-smoke--check satisfied (concat "timeout: " description))))

(defun eaf-smoke--rpc (method &rest args)
  "Call a real METHOD with ARGS without EPC's unbounded synchronous wait."
  (let (done value failure)
    (eaf-deferred-error
     (eaf-deferred-nextc
      (apply #'eaf-call-async method args)
      (lambda (reply) (setq value reply done t)))
     (lambda (err) (setq failure err done t)))
    (eaf-smoke--wait (lambda () done) (concat "RPC " method))
    (when failure (error "EAF RPC %s failed: %S" method failure))
    value))

(defun eaf-smoke--image-info (path)
  "Return pixel dimensions and SHA256 for a decodable native image PATH."
  (when (and (file-exists-p path) (> (file-attribute-size (file-attributes path)) 100))
    (condition-case nil
        ;; Decode bytes, not a reused filename-backed image spec: Qt rewrites
        ;; <buffer-id>.jpeg and Emacs otherwise caches its first dimensions.
        (let* ((bytes (with-temp-buffer
                        (set-buffer-multibyte nil)
                        (insert-file-contents-literally path)
                        (buffer-string)))
               (image (create-image bytes nil t))
               (size (image-size image t)))
          (when (and (> (car size) 200) (> (cdr size) 100))
            (with-temp-buffer
              (set-buffer-multibyte nil)
              (insert-file-contents-literally path)
              (list (cons 'width (car size)) (cons 'height (cdr size))
                    (cons 'sha256 (secure-hash 'sha256 (current-buffer)))))))
      (error nil))))

(defun eaf-smoke--clip (id name &optional predicate)
  "Capture ID through native clip_buffer until PREDICATE accepts the image."
  (let ((source (expand-file-name (concat id ".jpeg") eaf-config-location))
        (target (expand-file-name name eaf-smoke--artifacts))
        (deadline (+ (float-time) eaf-smoke--timeout))
        info accepted)
    ;; clip_buffer schedules work on the Qt thread; its EPC reply alone is not
    ;; evidence of rendering.  Observe the freshly written JPEG instead.
    (while (and (not accepted) (< (float-time) deadline))
      (when (file-exists-p source) (delete-file source))
      (eaf-call-async "clip_buffer" id)
      (eaf-smoke--wait
       (lambda () (setq info (eaf-smoke--image-info source)))
       "native Qt view JPEG" (max 0.05 (- deadline (float-time))))
      (setq accepted (or (not predicate) (funcall predicate info)))
      (unless accepted (accept-process-output nil 0.1)))
    (eaf-smoke--check accepted (concat "native image transition: " name))
    (copy-file source target t)
    (push (cons (intern (file-name-base name))
                (cons (cons 'path target) info))
          eaf-smoke--evidence)
    info))

(defun eaf-smoke--root-shot (name executable)
  "Capture the actual X root using EXECUTABLE, with a bounded process wait."
  (let* ((target (expand-file-name name eaf-smoke--artifacts))
         (process (make-process :name "eaf-smoke-import"
                                :buffer (get-buffer-create "*eaf-smoke-import*")
                                :command (list executable "-window" "root" target)
                                :noquery t)))
    (unwind-protect
        (progn
          (eaf-smoke--wait (lambda () (not (process-live-p process)))
                           "root screenshot executable")
          (eaf-smoke--check (and (eq (process-status process) 'exit)
                                (zerop (process-exit-status process)))
                            "root screenshot failed; see import.log")
          (let ((info (eaf-smoke--image-info target)))
            (eaf-smoke--check info "root screenshot is not a decodable image")
            (push (cons (intern (file-name-base name))
                        (cons (cons 'path target) info))
                  eaf-smoke--evidence)))
      (when (process-live-p process) (delete-process process)))))

(defun eaf-smoke--save-logs ()
  (when eaf-smoke--artifacts
    (dolist (entry '(("*Messages*" . "emacs-messages.log")
                     ("*eaf*" . "eaf-python.log")
                     ("*eaf-deferred-log*" . "epc-deferred.log")
                     ("*eaf-epc-log*" . "epc-wire.log")
                     ("*eaf-smoke-import*" . "import.log")))
      (when-let* ((buffer (get-buffer (car entry))))
        (with-current-buffer buffer
          (write-region (max (point-min) (- (point-max) (* 1024 1024))) (point-max)
                        (expand-file-name (cdr entry) eaf-smoke--artifacts)
                        nil 'silent))))))

(defun eaf-smoke--write-result (status &optional failure)
  (when eaf-smoke--result
    (with-temp-file eaf-smoke--result
      (insert (json-encode
               `((status . ,status) (stage . ,eaf-smoke--stage)
                 (failure . ,(or failure json-null))
                 (evidence . ,(reverse eaf-smoke--evidence))))
              "\n"))))

(defun eaf-smoke--scenario ()
  (eaf-smoke--check (display-graphic-p) "graphical Emacs is required")
  (let ((import (getenv "EAF_SMOKE_IMPORT"))
        backend buffer id)
    (eaf-smoke--check (and import (file-executable-p import))
                      "EAF_SMOKE_IMPORT must name an executable")
    (setq eaf-start-python-process-when-require nil)
    (require 'eaf)
    (require 'eaf-demo)
    (setq eaf-config-location
          (file-name-as-directory (expand-file-name "eaf-config" eaf-smoke--artifacts))
          eaf-deferred-debug t
          eaf-epc-debug t)
    (make-directory eaf-config-location t)
    (eaf-smoke--check (not (eaf-epc-live-p eaf-epc-process))
                      "require unexpectedly started EPC")
    (delete-other-windows)
    (set-frame-parameter nil 'background-mode 'dark)
    (set-frame-parameter nil 'background-color "#182838")
    (set-frame-parameter nil 'foreground-color "#f0e0d0")
    (setq eaf-smoke--stage "open-demo")
    (let (opened open-error)
      (run-with-timer
       0 nil (lambda ()
               (condition-case err
                   (progn (eaf-open-demo) (setq opened t))
                 (error (setq open-error err opened t)))))
      (eaf-smoke--wait (lambda () opened) "eaf-open-demo timer")
      (when open-error (signal (car open-error) (cdr open-error))))
    (setq backend eaf-internal-process)
    (unwind-protect
        (progn
          (eaf-smoke--wait (lambda () (eaf-epc-live-p eaf-epc-process))
                           "native Python EPC handshake")
          (eaf-smoke--check (and (processp backend) (process-live-p backend))
                            "native Python backend is not running")
          (push (cons 'backend_pid (process-id backend)) eaf-smoke--evidence)
          (eaf-smoke--wait
           (lambda ()
             (setq buffer
                   (cl-find-if
                    (lambda (candidate)
                      (with-current-buffer candidate
                        (and (derived-mode-p 'eaf-mode)
                             (equal eaf--buffer-app-name "demo")
                             (equal eaf--buffer-url "eaf-demo"))))
                    (buffer-list))))
           "installed demo buffer")
          (switch-to-buffer buffer)
          (setq id (buffer-local-value 'eaf--buffer-id buffer))
          (eaf-smoke--wait
           (lambda ()
             (equal (eaf-smoke--rpc "execute_function" id "base_class_name") "Buffer"))
           "native AppBuffer construction")
          (eaf-smoke--check
           (equal (eaf-smoke--rpc "execute_function" id "get_url") "eaf-demo")
           "native demo URL differs")
          (push '(native_app . "demo: AppBuffer inherits Buffer; get_url=eaf-demo")
                eaf-smoke--evidence)
          (eaf-monitor-configuration-change)
          (setq eaf-smoke--stage "render-and-theme")
          (let ((before (eaf-smoke--clip id "demo-before.jpeg")))
            (set-frame-parameter nil 'background-color "#d8e8f8")
            (set-frame-parameter nil 'foreground-color "#102030")
            (set-frame-parameter nil 'background-mode 'light)
            (eaf-smoke--rpc "eval_function" id "update_theme" "")
            (eaf-smoke--clip
             id "demo-themed.jpeg"
             (lambda (after)
               (and (= (alist-get 'width before) (alist-get 'width after))
                    (= (alist-get 'height before) (alist-get 'height after))
                    (not (equal (alist-get 'sha256 before) (alist-get 'sha256 after)))))))
          (setq eaf-smoke--stage "python-title-callback")
          (let ((title "EAF Native Demo Renamed"))
            (eaf-smoke--check
             (not (equal (buffer-local-value 'eaf--bookmark-title buffer) title))
             "rename lacks an initial title transition")
            (eaf-smoke--rpc "execute_function_with_args" id "change_title" title)
            (eaf-smoke--wait
             (lambda ()
               (and (equal (buffer-name buffer) title)
                    (equal (buffer-local-value 'eaf--bookmark-title buffer) title)
                    (equal (buffer-local-value 'eaf--buffer-url buffer) "eaf-demo")))
             "Python -> Emacs title and bookmark metadata callback")
            (push (cons 'callback_title title) eaf-smoke--evidence))
          (setq eaf-smoke--stage "native-resize")
          (eaf-smoke--root-shot "root-before.png" import)
          (let* ((normal (eaf-smoke--clip id "demo-normal.jpeg"))
                 (demo-window (get-buffer-window buffer))
                 (normal-allocation (eaf-get-window-allocation demo-window))
                 (side-window (split-window demo-window nil 'right)))
            ;; Frame ConfigureNotify is GUI input, not EPC process output:
            ;; a timer's accept-process-output wait does not run the command
            ;; loop to settle an external frame resize.  Resize the real EAF
            ;; window synchronously instead, through native Emacs splitting.
            (set-window-buffer side-window (get-buffer-create "*EAF native layout*"))
            (select-window demo-window)
            (let ((resized-allocation (eaf-get-window-allocation demo-window)))
              (push `(resize_geometry
                       (before . ,(vconcat normal-allocation))
                       (after . ,(vconcat resized-allocation))
                       (frame_pixels . ,(vector (frame-pixel-width) (frame-pixel-height)))
                       (frame_geometry . ,(prin1-to-string (frame-geometry)))
                       (frame_left . ,(prin1-to-string (eaf--frame-left (selected-frame))))
                       (frame_top . ,(prin1-to-string (eaf--frame-top (selected-frame))))
                       (monitor_enabled . ,(if eaf--monitor-configuration-p t json-false))
                       (same_eaf_frame . ,(if (equal (window-frame) eaf-emacs-frame) t json-false))
                       (selected_buffer . ,(buffer-name (window-buffer))))
                    eaf-smoke--evidence)
              (eaf-smoke--check (< (nth 2 resized-allocation) (nth 2 normal-allocation))
                                "native window allocation did not shrink"))
            (redisplay t)
            (eaf-monitor-configuration-change)
            (eaf-smoke--clip
             id "demo-resized.jpeg"
             (lambda (resized)
               (< (alist-get 'width resized) (alist-get 'width normal))))
            (eaf-smoke--root-shot "root-resized.png" import)
            (delete-window side-window)
            (eaf-smoke--check
             (equal (eaf-get-window-allocation demo-window) normal-allocation)
             "native window geometry did not restore")
            (push (cons 'restored_window_allocation
                        (vconcat (eaf-get-window-allocation demo-window)))
                  eaf-smoke--evidence)
            (kill-buffer "*EAF native layout*")
            (redisplay t)
            (eaf-monitor-configuration-change)
            (eaf-smoke--clip
             id "demo-restored.jpeg"
             (lambda (restored)
               (and (= (alist-get 'width normal) (alist-get 'width restored))
                    (= (alist-get 'height normal) (alist-get 'height restored))))))
          ;; A rejection is useful coverage, not proof that an app functions.
          ;; No file exists at this unsupported suffix: eaf-open must signal
          ;; user-error before any extension chooser or Python app creation.
          (setq eaf-smoke--stage "unsupported-input-rejection")
          (let ((unsupported (expand-file-name "absent.eaf-native-unsupported" eaf-smoke--artifacts))
                rejected)
            (eaf-smoke--check (not (file-exists-p unsupported))
                              "unsupported fixture must be absent")
            (condition-case err
                (eaf-open unsupported)
              (user-error (setq rejected (error-message-string err))))
            (eaf-smoke--check rejected "unsupported input did not signal user-error")
            (eaf-smoke--check (and (buffer-live-p buffer)
                                  (equal (eaf-smoke--rpc "execute_function" id "get_url")
                                         "eaf-demo"))
                              "unsupported input altered the functioning demo")
            (push (cons 'unsupported_input_user_error rejected) eaf-smoke--evidence))
          (setq eaf-smoke--stage "missing-module-rejection")
          (let* ((missing-id (eaf--generate-id))
                 (missing-source
                  (expand-file-name "no-such-EAF-app/buffer.py" eaf-smoke--artifacts))
                 (log (get-buffer eaf-name))
                 (start (with-current-buffer log (point-max))))
            (eaf-smoke--check (not (file-exists-p missing-source))
                              "missing-module fixture must be absent")
            ;; PostGui catches and prints the real import failure on the Qt
            ;; thread.  The scheduling reply is not an EPC error or app proof.
            (eaf-call-async "new_buffer" missing-id "local/noapp" missing-source "")
            (eaf-smoke--wait
             (lambda ()
               (with-current-buffer log
                 (let ((output (buffer-substring-no-properties start (point-max))))
                   (and (string-match-p "FileNotFoundError" output)
                        (string-match-p (regexp-quote missing-source) output)))))
             "actual missing-module traceback")
            (eaf-smoke--check
             (null (eaf-smoke--rpc "execute_function" missing-id "get_url"))
             "failed module import retained a native Python buffer")
            (eaf-smoke--check (not (eaf-get-buffer missing-id))
                              "missing module created an Emacs app buffer")
            (push (cons 'missing_module_error missing-source) eaf-smoke--evidence))
          (setq eaf-smoke--stage "native-close")
          (eaf-smoke--rpc "eval_function" id "close_buffer" "")
          (eaf-smoke--wait (lambda () (not (buffer-live-p buffer)))
                           "Python -> Emacs native close_buffer callback")
          (eaf-smoke--check (not (eaf-get-buffer id)) "closed Emacs app buffer remains")
          (eaf-smoke--wait
           (lambda () (null (eaf-smoke--rpc "execute_function" id "get_url")))
           "native Python buffer removed")
          (push '(native_close . t) eaf-smoke--evidence)
          (setq eaf-smoke--stage "native-stop")
          ;; Preserve Python output before upstream stop kills its log buffer.
          (eaf-smoke--save-logs)
          (eaf-stop-process)
          (eaf-smoke--wait
           (lambda () (and (not (process-live-p backend))
                           (not (eaf-epc-live-p eaf-epc-process))))
           "native eaf-stop-process terminates Python and EPC")
          (push '(native_stop . t) eaf-smoke--evidence))
      (eaf-smoke--save-logs)
      (when (process-live-p backend)
        (ignore-errors (eaf-stop-process))
        ;; Failure cleanup is not accepted as the native shutdown proof above.
        (when (process-live-p backend) (delete-process backend))))))

(defun eaf-smoke-run ()
  "Run the installed native GUI proof, record JSON, and exit Emacs 0 or 1.
Invoke from a timer after graphical Emacs startup; never use batch Emacs."
  (unless eaf-smoke--running
    (setq eaf-smoke--running t)
    (condition-case err
        (progn
          (setq eaf-smoke--artifacts (getenv "EAF_SMOKE_ARTIFACTS")
                eaf-smoke--result (getenv "EAF_SMOKE_RESULT"))
          (eaf-smoke--check (and eaf-smoke--artifacts eaf-smoke--result)
                            "EAF_SMOKE_ARTIFACTS and EAF_SMOKE_RESULT are required")
          (make-directory eaf-smoke--artifacts t)
          (eaf-smoke--scenario)
          (setq eaf-smoke--stage "complete")
          (eaf-smoke--write-result "ok")
          (message "EAF_NATIVE_RUNTIME_OK")
          (eaf-smoke--save-logs)
          (kill-emacs 0))
      (error
       (message "EAF native proof failed at %s: %s"
                eaf-smoke--stage (error-message-string err))
       (ignore-errors (eaf-smoke--save-logs))
       (ignore-errors (eaf-smoke--write-result "failed" (error-message-string err)))
       (kill-emacs 1)))))

(provide 'emacs-application-framework-smoke)
;;; emacs-application-framework-smoke.el ends here
