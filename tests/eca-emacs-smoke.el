;;; eca-emacs-smoke.el --- Offline ECA client scenario  -*- lexical-binding: t; -*-

;; Loaded only by tests/eca-emacs-smoke.sh.  It drives the installed client's
;; real public commands against tests/eca-emacs-fake-server.bash over a local
;; pipe.  Observation advice records calls and then runs the original client
;; code; only URL/network entry points are replaced so that any attempt fails
;; closed and is recorded.

(require 'cl-lib)
(require 'subr-x)
(require 'eca)

(defvar eca-smoke--fake (getenv "ECA_SMOKE_FAKE"))
(defvar eca-smoke--log-dir (getenv "ECA_SMOKE_LOG"))
(defvar eca-smoke--workspace (file-name-as-directory (getenv "ECA_SMOKE_WORKSPACE")))
(defvar eca-smoke--sentinel-bin (getenv "ECA_SMOKE_SENTINEL_BIN"))
(defvar eca-smoke--path-bin (getenv "ECA_SMOKE_PATH_BIN"))

(defvar eca-smoke--messages nil "ECA user-visible messages, newest first.")
(defvar eca-smoke--received nil "JSON-RPC messages handed to the client, newest first.")
(defvar eca-smoke--network-calls nil "Blocked network/URL entry points.")

(defun eca-smoke--fail (format-string &rest args)
  (error "eca-emacs smoke: %s" (apply #'format format-string args)))

(dolist (fn '(eca-info eca-warn eca-error))
  (advice-add fn :filter-return
              (lambda (text) (push text eca-smoke--messages) text)
              '((name . eca-smoke-record))))

(advice-add 'eca--handle-message :before
            (lambda (_session json-data) (push json-data eca-smoke--received))
            '((name . eca-smoke-record)))

(dolist (fn '(url-retrieve url-retrieve-synchronously url-copy-file
              url-insert-file-contents make-network-process
              open-network-stream))
  (advice-add fn :override
              (let ((name fn))
                (lambda (&rest args)
                  (push (cons name args) eca-smoke--network-calls)
                  (error "Network access prohibited in eca-emacs smoke: %s" name)))
              '((name . eca-smoke-block))))

(defun eca-smoke--wait (predicate what &optional seconds)
  "Service subprocess output until PREDICATE holds, else fail naming WHAT."
  (let ((deadline (+ (float-time) (or seconds 10))))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.05))
    (unless (funcall predicate)
      (eca-smoke--fail "timed out waiting for %s; messages=%S" what
                       (reverse eca-smoke--messages)))))

(defun eca-smoke--message-p (regexp)
  (cl-some (lambda (text) (string-match-p regexp text)) eca-smoke--messages))

(defun eca-smoke--server-log ()
  (let ((file (expand-file-name "server.log" eca-smoke--log-dir)))
    (if (file-exists-p file)
        (with-temp-buffer (insert-file-contents file) (buffer-string))
      "")))

(defun eca-smoke--server-log-p (regexp)
  (string-match-p regexp (eca-smoke--server-log)))

(defun eca-smoke--live-processes ()
  (cl-remove-if-not #'process-live-p (process-list)))

(defun eca-smoke--sessions ()
  (eca-vals eca--sessions))

(defun eca-smoke--expect-user-error (regexp thunk what)
  (condition-case err
      (progn (funcall thunk) (eca-smoke--fail "%s was accepted" what))
    (user-error
     (unless (string-match-p regexp (error-message-string err))
       (eca-smoke--fail "%s raised unexpected message: %s"
                        what (error-message-string err))))))

(defun eca-smoke--workspace-buffer ()
  (find-file-noselect (expand-file-name "sample.txt" eca-smoke--workspace)))

(defun eca-smoke--start (mode)
  "Start the fake server in MODE through the real `eca' command."
  (setq eca-custom-command (list eca-smoke--fake "server" mode))
  (with-current-buffer (eca-smoke--workspace-buffer)
    (let ((default-directory eca-smoke--workspace))
      (eca))))

(defun eca-smoke--current-session ()
  (with-current-buffer (eca-smoke--workspace-buffer) (eca-session)))

(defun eca-smoke--wait-started (mode)
  (eca-smoke--wait
   (lambda ()
     (when-let* ((session (eca-smoke--current-session)))
       (eq (eca--session-status session) 'started)))
   (format "%s initialize response" mode))
  (let ((process (eca--session-process (eca-smoke--current-session))))
    (unless (and (process-live-p process)
                 (eq (process-type process) 'real)
                 (null (process-tty-name process))
                 (equal (process-command process)
                        (list eca-smoke--fake "server" mode)))
      (eca-smoke--fail "%s session is not the fake pipe: %S" mode
                       (and process (process-command process))))))

(defun eca-smoke--stop ()
  (with-current-buffer (eca-smoke--workspace-buffer)
    (eca-stop))
  (eca-smoke--wait (lambda () (null (eca-smoke--live-processes)))
                   "fake server termination")
  (eca-smoke--wait (lambda () (null (eca-smoke--sessions)))
                   "session removal"))

(defun eca-smoke--check-install-refused ()
  (eca-smoke--expect-user-error
   "this package does not download servers"
   #'eca-install-server "eca-install-server"))

(defun eca-smoke--check-credentials-absent ()
  (dolist (var '("OPENAI_API_KEY" "ANTHROPIC_API_KEY" "GEMINI_API_KEY"
                 "GOOGLE_API_KEY" "OPENROUTER_API_KEY" "DEEPSEEK_API_KEY"
                 "AZURE_OPENAI_API_KEY" "GITHUB_TOKEN" "GH_TOKEN"
                 "OLLAMA_API_BASE" "HTTP_PROXY" "HTTPS_PROXY" "http_proxy"
                 "https_proxy"))
    (when (getenv var)
      (eca-smoke--fail "provider/network variable %s leaked into smoke" var))))

(defun eca-smoke--missing-server ()
  "No custom command and no `eca' on PATH must fail without fetching."
  (let ((exec-path (list eca-smoke--sentinel-bin))
        (eca-custom-command nil))
    (let ((decision (eca-process--server-command)))
      (unless (eq (plist-get decision :decision) 'missing)
        (eca-smoke--fail "missing server resolved to %S" decision)))
    (with-current-buffer (eca-smoke--workspace-buffer)
      (let ((default-directory eca-smoke--workspace))
        (eca-smoke--expect-user-error
         "\\`ECA server not found\\. Install `eca` on PATH or set `eca-custom-command` to the server command\\.\\'"
         #'eca "starting ECA without a server"))))
  (when (eca-smoke--live-processes)
    (eca-smoke--fail "missing server started %S" (eca-smoke--live-processes)))
  ;; Upstream `eca' registers the session before starting its process.
  (mapc #'eca-delete-session (eca-smoke--sessions))
  (let ((exec-path (list eca-smoke--path-bin))
        (eca-custom-command nil))
    (let ((decision (eca-process--server-command)))
      (unless (equal decision
                     (list :decision 'system
                           :command (list (expand-file-name "eca" eca-smoke--path-bin)
                                          "server")))
        (eca-smoke--fail "PATH server resolved to %S" decision))))
  (princ "missing server: deterministic install/provide error, no process, no download\n"))

(defun eca-smoke--protocol-session ()
  "Initialize, then drive the real chat and completion commands."
  (eca-smoke--start "protocol")
  (eca-smoke--wait-started "protocol")
  (unless (eca-smoke--server-log-p "RECV .*\"method\":\"initialize\"")
    (eca-smoke--fail "initialize frame did not reach the fake pipe"))
  (unless (eca-smoke--server-log-p "RECV .*\"method\":\"initialized\"")
    (eca-smoke--wait (lambda () (eca-smoke--server-log-p
                                 "RECV .*\"method\":\"initialized\""))
                     "initialized notification"))
  (with-current-buffer (eca-smoke--workspace-buffer)
    (eca-chat-send-prompt "hello from the offline eca smoke"))
  (eca-smoke--wait
   (lambda ()
     (cl-some (lambda (json)
                (string-prefix-p "FAKE_CHAT_PROMPT_ERROR"
                                 (or (plist-get (plist-get json :error) :message) "")))
              eca-smoke--received))
   "chat/prompt JSON-RPC error delivery")
  (unless (eca-smoke--server-log-p
           "RECV .*\"method\":\"chat/prompt\".*hello from the offline eca smoke")
    (eca-smoke--fail "chat/prompt did not carry the prompt over the fake pipe"))
  (with-current-buffer (eca-smoke--workspace-buffer)
    (goto-char (point-max))
    (eca-complete))
  (eca-smoke--wait (lambda () (eca-smoke--message-p
                               "ECA :: FAKE_COMPLETION_ERROR: no provider in offline smoke"))
                   "completion error message")
  (unless (eca-smoke--server-log-p "RECV .*\"method\":\"completion/inline\".*sample\\.txt")
    (eca-smoke--fail "completion/inline did not reach the fake pipe"))
  (unless (process-live-p (eca--session-process (eca-smoke--current-session)))
    (eca-smoke--fail "protocol errors terminated the session"))
  (let ((errors (get-buffer (eca--emacs-errors-buffer-name (eca-smoke--current-session)))))
    (when (and errors (> (buffer-size errors) 0))
      (eca-smoke--fail "client logged handler failures: %s"
                       (with-current-buffer errors (buffer-string))))))

(defun eca-smoke--protocol ()
  (eca-smoke--protocol-session)
  (eca-smoke--stop)
  (unless (eca-smoke--server-log-p "RECV .*\"method\":\"shutdown\"")
    (eca-smoke--fail "shutdown request did not reach the fake pipe"))
  (princ "protocol: initialize ok; chat/prompt and completion/inline errors handled; server stopped\n"))

(defun eca-smoke--malformed ()
  (eca-smoke--start "malformed")
  (eca-smoke--wait-started "malformed")
  (unless (eca-smoke--message-p "Failed to parse the following chunk")
    (eca-smoke--fail "malformed frame was not reported"))
  (eca-smoke--stop)
  (princ "malformed: bad frame logged, following initialize accepted, server stopped\n"))

(defun eca-smoke--early-exit ()
  (eca-smoke--start "early-exit")
  (eca-smoke--wait (lambda ()
                     (and (null (eca-smoke--live-processes))
                          (null (eca-smoke--sessions))
                          (eca-smoke--message-p
                           "process has exited (exited abnormally with code 7)")))
                   "early-exit sentinel cleanup")
  (with-current-buffer (eca-smoke--workspace-buffer)
    (eca-smoke--expect-user-error "ECA must be running"
                                  (lambda () (eca-chat-send-prompt "after exit"))
                                  "chat prompt after server exit")
    (eca-smoke--expect-user-error "ECA must be running" #'eca-complete
                                  "completion after server exit"))
  (princ "early-exit: truncated frame and exit 7 cleaned up; later chat/completion refused\n"))

(defun eca-smoke-run ()
  "Run the full batch scenario."
  (eca-smoke--check-credentials-absent)
  (eca-smoke--check-install-refused)
  (eca-smoke--missing-server)
  (eca-smoke--protocol)
  (eca-smoke--malformed)
  (eca-smoke--early-exit)
  (when eca-smoke--network-calls
    (eca-smoke--fail "network entry points were called: %S" eca-smoke--network-calls))
  (when (eca-smoke--live-processes)
    (eca-smoke--fail "processes remain: %S" (eca-smoke--live-processes)))
  (princ "eca-emacs offline protocol smoke passed\n"))

(defun eca-smoke-tty-scene ()
  "Show the real chat buffer and ECA messages on a terminal frame."
  (condition-case err
      (progn
        (eca-smoke--check-credentials-absent)
        ;; Keep the chat in an ordinary window so the frame can be tiled.
        (setq eca-chat-window-side nil)
        (eca-smoke--protocol-session)
        (when eca-smoke--network-calls
          (eca-smoke--fail "network entry points were called"))
        (let ((chat (eca-chat--get-last-buffer (eca-smoke--current-session))))
          (delete-other-windows)
          (switch-to-buffer (eca-smoke--workspace-buffer))
          (let ((lower (split-window-below)))
            (set-window-buffer lower "*Messages*")
            (with-selected-window lower (goto-char (point-max)) (recenter -1)))
          (when (buffer-live-p chat)
            (let ((middle (split-window-below)))
              (set-window-buffer middle chat))))
        (redisplay t)
        (let ((chat (eca-chat--get-last-buffer (eca-smoke--current-session))))
          (unless (and (buffer-live-p chat) (get-buffer-window chat)
                       (get-buffer-window "*Messages*")
                       (get-buffer-window (eca-smoke--workspace-buffer)))
            (eca-smoke--fail "terminal frame lacks sample, chat, or Messages window")))
        (unless (eca-smoke--message-p
                 "ECA :: FAKE_COMPLETION_ERROR: no provider in offline smoke")
          (eca-smoke--fail "completion error not shown before frame export"))
        ;; Let the idle frame settle, then record where the PTY log ends while
        ;; the complete frame is on the alternate screen.  The shell exports
        ;; exactly that prefix, excluding later shutdown and terminal restore.
        (run-at-time 1.5 nil
                     (lambda ()
                       (redisplay t)
                       (let* ((log (getenv "ECA_SMOKE_TTY_LOG"))
                              (size (progn
                                      (sleep-for 0.5)
                                      (file-attribute-size (file-attributes log)))))
                         ;; The prefix must be complete: no bytes may still be
                         ;; arriving from the final redisplay.
                         (sleep-for 0.5)
                         (unless (= size (file-attribute-size (file-attributes log)))
                           (eca-smoke--fail "terminal output still changing at frame export"))
                         (with-temp-file (expand-file-name "tty-frame.bytes"
                                                           eca-smoke--log-dir)
                           (insert (format "%d\n" size))))
                       (with-temp-file (expand-file-name "tty-scene.ok" eca-smoke--log-dir)
                         (insert "ok\n"))
                       (with-current-buffer (eca-smoke--workspace-buffer)
                         (eca-stop))
                       (kill-emacs 0))))
    (error
     (with-temp-file (expand-file-name "tty-scene.err" eca-smoke--log-dir)
       (insert (error-message-string err) "\n"))
     (kill-emacs 1))))

(provide 'eca-emacs-smoke)
;;; eca-emacs-smoke.el ends here
