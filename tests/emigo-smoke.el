;;; emigo-smoke.el --- Installed Emigo local IPC scenario -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'emigo)

(defun emigo-smoke-check (condition description)
  (unless condition (error "Emigo smoke: %s" description)))

(defun emigo-smoke-wait (predicate description)
  (let ((deadline (+ (float-time) 20)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.05))
    (emigo-smoke-check (funcall predicate) description)))

;; No fake EPC server or provider response.  These guards only fail closed;
;; the outer network namespace allows the real two-way loopback EPC transport.
(dolist (function '(url-retrieve url-retrieve-synchronously url-copy-file))
  (advice-add function :override
              (lambda (&rest _) (error "Provider/download access prohibited"))))

(let* ((out (getenv "EMIGO_SMOKE_OUTPUT"))
       (root (file-name-as-directory (getenv "EMIGO_SMOKE_WORKSPACE")))
       (sample (expand-file-name "sample.py" root))
       (outside (expand-file-name "outside.py" (file-name-directory (directory-file-name root))))
       (buffer (get-buffer-create (emigo-get-buffer-name nil root)))
       (backend nil))
  (setq emigo-api-key "" emigo-model "" emigo-base-url "")
  (emigo-smoke-check
   (equal emigo-python-command (concat out "/bin/emigo-python"))
   "installed interpreter launcher not selected")
  (emigo-smoke-check
   (equal emigo-python-file (concat out "/share/emigo/backend/emigo.py"))
   "installed backend path not selected")
  (with-current-buffer buffer
    (setq-local emigo-session-path root))
  (unwind-protect
      (progn
        (emigo-start-process)
        (setq backend emigo-internal-process)
        (emigo-smoke-wait
         (lambda () (emigo-epc-live-p emigo-epc-process))
         "native Python -> Emacs -> Python handshake")
        (emigo-smoke-check
         (equal (process-command backend)
                (list emigo-python-command emigo-python-file
                      (number-to-string emigo-server-port)))
         "backend was not launched through installed contract")
        (emigo-smoke-check (null (emigo-call--sync "get_chat_files" root))
                           "new context must be empty")
        (emigo-smoke-check (emigo-call--sync "add_file_to_context" root sample)
                           "existing local file was rejected")
        (emigo-smoke-check
         (equal (emigo-call--sync "get_chat_files" root) '("sample.py"))
         "native context state did not retain the relative filename")
        (emigo-smoke-wait
         (lambda ()
           (with-current-buffer buffer
             (and emigo-chat-file-info
                  (string-match-p "1 file \\[[1-9][0-9]* tokens\\]"
                                  emigo-chat-file-info))))
         "Python tokenizer result did not reach the Emacs header")
        (emigo-smoke-check
         (null (emigo-call--sync "add_file_to_context" root sample))
         "duplicate context add should fail")
        (dolist (rejected (list (expand-file-name "missing.py" root)
                               outside (expand-file-name "escape.py" root)))
          (emigo-smoke-check
           (null (emigo-call--sync "add_file_to_context" root rejected))
           "missing/outside/symlink file should fail"))
        (emigo-smoke-check
         (equal (emigo-call--sync "get_chat_files" root) '("sample.py"))
         "failed operations mutated context")
        (emigo-smoke-check
         (emigo-call--sync "remove_file_from_context" root "sample.py")
         "remove existing context failed")
        (emigo-smoke-check (null (emigo-call--sync "get_chat_files" root))
                           "removed file remains in context")
        (emigo-smoke-wait
         (lambda () (with-current-buffer buffer
                      (equal emigo-chat-file-info "0 file [0 tokens]")))
         "remove callback did not reach Emacs")
        (emigo-smoke-check
         (null (emigo-call--sync "remove_file_from_context" root "sample.py"))
         "remove absent context should fail")
        (emigo-smoke-check (emigo-call--sync "clear_history" root)
                           "clear local history failed")
        (emigo-smoke-check (null (emigo-call--sync "get_history" root))
                           "local history unexpectedly contains provider interaction")
        ;; Synchronous cleanup completes before closing the EPC connection.
        (emigo-call--sync "cleanup")
        (emigo-kill-process)
        (emigo-smoke-wait (lambda () (not (process-live-p backend)))
                          "backend did not terminate")
        (princ "EMIGO_NATIVE_IPC_OK: context add/token header/reject/remove/cleanup\n"))
    (when (emigo-epc-live-p emigo-epc-process)
      (ignore-errors (emigo-call--sync "cleanup"))
      (ignore-errors (emigo-kill-process)))
    (when (and backend (process-live-p backend)) (delete-process backend))
    (when (process-live-p emigo-server) (delete-process emigo-server))
    (when (buffer-live-p buffer) (kill-buffer buffer))))
