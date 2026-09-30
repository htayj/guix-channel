;;; emacs-forth-mode-smoke.el --- Installed Forth editing proof -*- lexical-binding: t; -*-

;; Loaded by emacs-forth-mode-smoke.sh with only the installed package on
;; load-path, writable copied fixtures, an empty PATH, and no user init files.
(require 'cl-lib)
(require 'imenu)
(require 'forth-mode)
(require 'forth-block-mode)
(require 'forth-interaction-mode)

(defconst forth-mode-smoke--source
  "\\ OMP Forth editing proof\n: square ( n -- n*n )\ndup\n;\n\n: show-square ( n -- )\nsquare .\n.\" squared\"\n;\n")
(defconst forth-mode-smoke--edited
  "\\ OMP Forth editing proof\n: square ( n -- n*n )\n  dup *\n;\n\n: show-square ( n -- )\n  square .\n  .\" squared\"\n;\n")

(defun forth-mode-smoke--assert (condition format-string &rest args)
  (unless condition
    (error "forth-mode smoke: %s" (apply #'format format-string args))))

(defun forth-mode-smoke--fixtures ()
  (file-name-as-directory (getenv "FORTH_SMOKE_FIXTURES")))

(defun forth-mode-smoke--blocks ()
  (dolist (fixture '("test/noblock.fth" "test/block1.fth" "test/block2.fth"))
    (let ((buffer (find-file-noselect
                   (expand-file-name fixture (forth-mode-smoke--fixtures)))))
      (unwind-protect
          (with-current-buffer buffer
            (forth-mode-smoke--assert (eq major-mode 'forth-mode)
                                     "wrong major mode for %s" fixture)
            (forth-mode-smoke--assert
             (eq (not (null (bound-and-true-p forth-block-mode)))
                 (not (equal fixture "test/noblock.fth")))
             "wrong block mode for %s" fixture))
        (with-current-buffer buffer (set-buffer-modified-p nil))
        (kill-buffer buffer)))))

(defun forth-mode-smoke--face (word expected)
  (save-excursion
    (goto-char (point-min))
    (search-forward word)
    (let* ((position (- (point) (length word)))
           (face (or (get-text-property position 'face)
                     (get-text-property position 'font-lock-face))))
      (forth-mode-smoke--assert
       (or (eq face expected) (and (listp face) (memq expected face)))
       "%s has face %S, expected %S" word face expected))))

(defun forth-mode-smoke--edit ()
  "Visit a real .fth file, edit it, and check the resulting editing behavior."
  (let ((file (expand-file-name "editing-proof.fth" (forth-mode-smoke--fixtures))))
    (with-temp-file file (insert forth-mode-smoke--source))
    (let ((buffer (find-file-noselect file)))
      (switch-to-buffer buffer)
      (forth-mode-smoke--assert (eq major-mode 'forth-mode)
                               ".fth file did not select Forth mode")
      (goto-char (point-min))
      (search-forward "dup")
      ;; Invoke the ordinary editing command rather than substituting a
      ;; prepared expected buffer.  Then use the mode's indentation command.
      (dolist (character '(?\s ?*))
        (let ((last-command-event character))
          (call-interactively #'self-insert-command)))
      (indent-region (point-min) (point-max))
      (forth-mode-smoke--assert
       (equal (buffer-substring-no-properties (point-min) (point-max))
              forth-mode-smoke--edited)
       "indentation did not produce the expected two-space definition bodies")
      (font-lock-mode 1)
      (font-lock-ensure)
      (forth-mode-smoke--face "OMP Forth editing proof" 'font-lock-comment-face)
      (forth-mode-smoke--face "square" 'font-lock-function-name-face)
      (forth-mode-smoke--face "n -- n*n" 'font-lock-comment-face)
      (forth-mode-smoke--face "squared" 'font-lock-string-face)
      (goto-char (point-max))
      (beginning-of-defun)
      (forth-mode-smoke--assert (looking-at ": show-square")
                               "definition navigation missed show-square")
      (beginning-of-defun)
      (forth-mode-smoke--assert (looking-at ": square")
                               "definition navigation missed square")
      (let ((start (point)))
        (forward-sexp)
        (forth-mode-smoke--assert
         (equal (buffer-substring-no-properties start (point))
                ": square ( n -- n*n )\n  dup *\n;")
         "forward-sexp did not cross the complete colon definition"))
      (let* ((index (imenu--make-index-alist t))
             (words (cdr (assoc "Words" index))))
        (forth-mode-smoke--assert
         (and (assoc "square" words) (assoc "show-square" words))
         "definition index omitted edited Forth words: %S" index))
      (save-buffer)
      (goto-char (point-min))
      (princ "editing: inserted *; indentation, comment/string/name faces, definition and sexp navigation passed\n")
      buffer)))

(defun forth-mode-smoke--runtime (source)
  "Evaluate the edited definition with the packaged Gforth backend."
  (forth-mode-smoke--assert
   (equal forth-executable (getenv "FORTH_SMOKE_GFORTH"))
   "forth-executable was not set to the packaged Gforth")
  (let (process)
    (unwind-protect
        (progn
          (run-forth)
          (setq process (get-buffer-process forth-interaction-buffer))
          (forth-mode-smoke--assert (process-live-p process)
                                   "run-forth did not start a process")
          (let ((deadline (+ (float-time) 5)))
            (while (and (not forth-implementation) (< (float-time) deadline))
              (accept-process-output process 0.1)))
          (forth-mode-smoke--assert (eq forth-implementation 'gforth)
                                   "installed Gforth backend was not loaded")
          (forth-mode-smoke--assert
           (equal (car (process-command process)) forth-executable)
           "runtime used a different interpreter")
          (with-current-buffer source
            (goto-char (point-min))
            (search-forward ": square")
            (beginning-of-line)
            (let ((start (point)))
              (forward-sexp)
              (forth-interaction-send
               (buffer-substring-no-properties start (point)))))
          (let ((result (forth-interaction-send "7 square .")))
            (forth-mode-smoke--assert
             (string-match-p "\\_<49\\_>" result)
             "edited square did not evaluate to 49: %S" result))
          (with-temp-buffer
            (insert "2c")
            (forth-mode)
            (completion-at-point)
            (forth-mode-smoke--assert
             (equal (buffer-string) "2Constant")
             "Gforth completion did not expand 2c to 2Constant"))
          ;; Killing a live comint buffer sends SIGHUP (exit 129), which is
          ;; cleanup rather than a successful interpreter shutdown.  Ask
          ;; Gforth to exit normally first and keep its real sentinel visible.
          (comint-send-string process "bye\n")
          (let ((deadline (+ (float-time) 5)))
            (while (and (process-live-p process) (< (float-time) deadline))
              (accept-process-output process 0.1)))
          (forth-mode-smoke--assert
           (and (eq (process-status process) 'exit)
                (zerop (process-exit-status process)))
           "Gforth bye did not exit normally: status=%S exit=%S"
           (process-status process) (process-exit-status process))
          (princ "runtime: edited square(7) = 49; Gforth completion 2c -> 2Constant; bye exited 0\n"))
      (when (buffer-live-p forth-interaction-buffer) (forth-kill))
      (when (processp process)
        (let ((deadline (+ (float-time) 5)))
          (while (and (process-live-p process) (< (float-time) deadline))
            (accept-process-output process 0.1)))
        (forth-mode-smoke--assert (not (process-live-p process))
                                 "Gforth process remained live after cleanup")))))

(defun forth-mode-smoke-run ()
  "Run the installed-mode proof and retain its actual edited buffer."
  (setq create-lockfiles nil enable-local-variables nil enable-local-eval nil)
  (let ((default-directory (forth-mode-smoke--fixtures)))
    (forth-mode-smoke--blocks)
    (let ((source (forth-mode-smoke--edit)))
      (forth-mode-smoke--runtime source)
      (switch-to-buffer source)
      (delete-other-windows)
      (goto-char (point-min))
      source)))

(defun forth-mode-smoke--evidence (file text)
  (with-temp-file (expand-file-name file (getenv "FORTH_SMOKE_EVIDENCE"))
    (insert text)))

(defun forth-mode-smoke-tty-scene ()
  "Capture the genuine edited Forth buffer before terminal restoration."
  (condition-case err
      (progn
        (forth-mode-smoke-run)
        (setq inhibit-startup-screen t)
        (message "Editing + faces + indentation + navigation OK; square(7)=49")
        (redisplay t)
        (run-at-time
         1.5 nil
         (lambda ()
           (condition-case err
               (progn
                 (redisplay t)
                 (let* ((log (getenv "FORTH_SMOKE_TTY_LOG"))
                        (size (progn (sleep-for 0.5)
                                     (file-attribute-size (file-attributes log)))))
                   (sleep-for 0.5)
                   (forth-mode-smoke--assert
                    (= size (file-attribute-size (file-attributes log)))
                    "terminal output still changing at frame export")
                   (forth-mode-smoke--evidence "tty-frame.bytes" (format "%d\n" size)))
                 (forth-mode-smoke--evidence "tty-scene.ok" "ok\n")
                 (kill-emacs 0))
             (error
              (forth-mode-smoke--evidence "tty-scene.err" (concat (error-message-string err) "\n"))
              (kill-emacs 1))))))
    (error
     (forth-mode-smoke--evidence "tty-scene.err" (concat (error-message-string err) "\n"))
     (kill-emacs 1))))

;;; emacs-forth-mode-smoke.el ends here
