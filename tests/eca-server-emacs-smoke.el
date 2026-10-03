;;; eca-server-emacs-smoke.el --- Real installed ECA integration -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'eca)

(defvar eca-server-smoke--messages nil)

(defun eca-server-smoke--wait (predicate label)
  (let ((deadline (+ (float-time) 45)))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.05))
    (unless (funcall predicate)
      (error "Real ECA integration timeout: %s" label))))

(defun eca-server-smoke-run ()
  "Drive the installed client's public commands against the installed server."
  (let* ((workspace (file-name-as-directory (getenv "ECA_SMOKE_WORKSPACE")))
         (scratch (getenv "ECA_SMOKE_DIRECTORY"))
         (sample (find-file-noselect (expand-file-name "sample.txt" workspace)))
         (session nil)
         (process nil))
    ;; Observation only: never replace the transport, request handler or server.
    (advice-add 'eca--handle-message :before
                (lambda (_session message)
                  (push message eca-server-smoke--messages)))
    (setq eca-custom-command nil
          eca-find-root-for-buffer-function (lambda () workspace))
    (unwind-protect
        (progn
          (with-current-buffer sample (eca))
          (eca-server-smoke--wait
           (lambda ()
             (setq session (with-current-buffer sample (eca-session)))
             (and session (eq (eca--session-status session) 'started)))
           "initialize")
          (setq process (eca--session-process session))
          (unless (and (process-live-p process)
                       (equal (process-command process)
                              (list (executable-find "eca") "server")))
            (error "Client did not discover installed eca on PATH"))
          (let ((chat (eca-chat--get-last-buffer session)))
            (unless (and (buffer-live-p chat)
                         (with-current-buffer chat
                           (string-match-p "Welcome to ECA" (buffer-string))))
              (error "Real server welcome not rendered in client chat buffer"))
            (eca-server-smoke--wait
             (lambda ()
               (cl-some (lambda (message)
                          (equal (plist-get message :method) "config/updated"))
                        eca-server-smoke--messages))
             "capability/config notification")
            (with-current-buffer sample (eca-chat-send-prompt "/doctor"))
            (eca-server-smoke--wait
             (lambda ()
               (cl-some
                (lambda (message)
                  (and (equal (plist-get message :method) "chat/contentReceived")
                       (string-match-p
                        "ECA" (or (plist-get
                                   (plist-get (plist-get message :params) :content) :text)
                                  ""))))
                eca-server-smoke--messages))
             "real local /doctor command")
            (with-current-buffer chat
              (write-region (point-min) (point-max)
                            (expand-file-name "emacs-chat.txt" scratch) nil 'silent)))
          ;; A genuine application error is delivered through the real client
          ;; request machinery, not a canned fake-server error.
          (condition-case failure
              (progn
                (eca-api-request-sync session :method "chat/history"
                                      :params '(:chatId "missing"))
                (error "Missing chat unexpectedly succeeded"))
            (error
             (unless (string-match-p "chat_not_found" (error-message-string failure))
               (signal (car failure) (cdr failure)))))
          (let ((errors (get-buffer (eca--emacs-errors-buffer-name session))))
            (when (and errors (> (buffer-size errors) 0))
              (error "Client handler failure: %s"
                     (with-current-buffer errors (buffer-string)))))
          (with-current-buffer sample (eca-stop))
          (eca-server-smoke--wait (lambda () (not (process-live-p process))) "server exit")
          (unless (null (eca-vals eca--sessions))
            (error "Stopped client session retained"))
          (princ "eca-emacs: real PATH server, welcome rendering, local /doctor, application error, shutdown and cleanup passed\n"))
      (when (and session (process-live-p (eca--session-process session)))
        (eca-stop-session session)))))

(provide 'eca-server-emacs-smoke)
;;; eca-server-emacs-smoke.el ends here
