;;; emacs-vim-region-smoke.el --- Installed region editing proof -*- lexical-binding: t; -*-

;; Loaded with -Q, only the installed package and its propagated dependencies,
;; an isolated HOME, an empty PATH, and no network access by the shell helper.
(require 'vim-region)

(defun vim-region-smoke--assert (condition format-string &rest args)
  (unless condition
    (error "vim-region smoke: %s" (apply #'format format-string args))))

(defun vim-region-smoke--text (expected)
  (vim-region-smoke--assert
   (equal (buffer-string) expected) "buffer %S, expected %S"
   (buffer-string) expected))

(defun vim-region-smoke--region (text point-position mark-position)
  (vim-region-smoke--assert mark-active "region is inactive")
  (vim-region-smoke--assert
   (and (= (point) point-position) (= (mark) mark-position)
        (equal (buffer-substring-no-properties (region-beginning) (region-end)) text))
   "region %S point=%d mark=%S, expected %S point=%d mark=%d"
   (buffer-substring-no-properties (region-beginning) (region-end))
   (point) (mark) text point-position mark-position))

(defun vim-region-smoke--mode (enabled)
  (vim-region-smoke--assert
   (and (eq (not (null vim-region-mode)) enabled)
        (eq (not (null local-vim-region-mode)) enabled))
   "global/local mode state %S/%S, expected %S"
   vim-region-mode local-vim-region-mode enabled))

(defun vim-region-smoke--keys (keys)
  "Use the active keymaps and the real pre/post-command hooks."
  (execute-kbd-macro (kbd keys)))

(defun vim-region-smoke--start (position)
  (vim-region-mode -1)
  (deactivate-mark)
  (goto-char position)
  (vim-region-mode 1)
  (vim-region-smoke--mode t))

(defmacro vim-region-smoke--with-buffer (text &rest body)
  (declare (indent 1))
  `(let ((buffer (generate-new-buffer " *vim-region semantics*")))
     (unwind-protect
         (save-window-excursion
           (switch-to-buffer buffer)
           (fundamental-mode)
           (insert ,text)
           (goto-char (point-min))
           (set-buffer-modified-p nil)
           ,@body)
       (vim-region-mode -1)
       (kill-buffer buffer))))

(defun vim-region-smoke--movement ()
  (vim-region-smoke--with-buffer "alpha beta\nkeep\n"
    (vim-region-smoke--start 1)
    (vim-region-smoke--region "" 1 1)
    (vim-region-smoke--keys "w")
    (vim-region-smoke--region "alpha" 6 1)
    (vim-region-smoke--keys "l")
    (vim-region-smoke--region "alpha " 7 1)
    (vim-region-smoke--keys "h")
    (vim-region-smoke--region "alpha" 6 1)
    (vim-region-smoke--keys "z")
    (vim-region-smoke--region "alpha" 1 6)
    (vim-region-smoke--keys "e")
    (vim-region-smoke--region " beta" 11 6)
    (vim-region-smoke--keys "b")
    (vim-region-smoke--region " " 7 6)
    (vim-region-smoke--keys "a")
    (vim-region-smoke--region "alpha" 1 6)
    (vim-region-smoke--keys "G")
    (vim-region-smoke--region " beta\nkeep\n" 17 6)
    (vim-region-smoke--keys "g")
    (vim-region-smoke--region "alpha" 1 6)
    (vim-region-smoke--mode t)
    (vim-region-smoke--text "alpha beta\nkeep\n")))

(defun vim-region-smoke--kill-ring ()
  (let ((kill-ring nil) (kill-ring-yank-pointer nil)
        (interprogram-cut-function nil) (interprogram-paste-function nil))
    (vim-region-smoke--with-buffer "alpha beta\nkeep\n"
      (vim-region-smoke--start 7)
      (vim-region-smoke--keys "w")
      (vim-region-smoke--region "beta" 11 7)
      (vim-region-smoke--keys "y")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--assert (equal (car kill-ring) "beta") "save lost beta")
      (vim-region-smoke--text "alpha beta\nkeep\n")
      (vim-region-smoke--assert (not (buffer-modified-p)) "save modified buffer")
      (vim-region-smoke--start 7)
      (vim-region-smoke--keys "w c")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--text "alpha betabeta\nkeep\n")
      (vim-region-smoke--assert
       (and (= (point) 15) (= (mark) 11) (equal (car kill-ring) "beta"))
       "copy did not insert the saved selection at its end"))
    (vim-region-smoke--with-buffer "alpha beta\nkeep\n"
      (vim-region-smoke--start 7)
      (vim-region-smoke--keys "w d")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--text "alpha \nkeep\n")
      (vim-region-smoke--assert
       (and (= (point) 7) (equal (car kill-ring) "beta")) "kill lost selection")
      (vim-region-smoke--start 7)
      (vim-region-smoke--keys "p")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--text "alpha beta\nkeep\n")
      (vim-region-smoke--assert
       (and (= (point) 11) (= (mark) 7)) "yank boundaries differ"))
    (vim-region-smoke--with-buffer "one tail\nnext\n"
      (vim-region-smoke--start 5)
      (vim-region-smoke--region "" 5 5)
      ;; An empty *active* region takes kill-region, not kill-line upstream.
      ;; Toggle it inactive to exercise the actual kill-line branch.
      (vim-region-smoke--keys "v")
      (vim-region-smoke--assert (not mark-active) "v did not deactivate mark")
      (vim-region-smoke--keys "d")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--text "one \nnext\n")
      (vim-region-smoke--assert
       (and (= (point) 5) (equal (car kill-ring) "tail")) "kill-line branch lost tail"))))

(defun vim-region-smoke--eternal ()
  (let ((kill-ring nil) (kill-ring-yank-pointer nil)
        (interprogram-cut-function nil) (interprogram-paste-function nil))
    (vim-region-smoke--with-buffer "alpha beta\nkeep\n"
      (vim-region-smoke--start 1)
      (vim-region-smoke--keys "q")
      (vim-region-smoke--assert
       (and vim-region-non-auto-quit (not mark-active)) "q did not enter eternal mode")
      (vim-region-smoke--keys "d")
      (vim-region-smoke--mode t)
      (vim-region-smoke--assert vim-region-non-auto-quit "d reset eternal mode")
      (vim-region-smoke--text "\nkeep\n")
      (vim-region-smoke--keys "q")
      (vim-region-smoke--assert (not vim-region-non-auto-quit) "q did not leave eternal mode")
      (vim-region-smoke--keys "x")
      (vim-region-smoke--mode t)
      (vim-region-smoke--text "keep\n")
      ;; Unlike x, self-insert is not on upstream's non-autoquit whitelist.
      (vim-region-smoke--keys "!")
      (vim-region-smoke--mode nil)
      (vim-region-smoke--text "!keep\n"))))

(defun vim-region-smoke--characters ()
  (vim-region-smoke--with-buffer "a x b x c x\n"
    (vim-region-smoke--start 1)
    ;; Explicit arguments avoid read-char and cover counted, backward, and
    ;; last-character navigation without rewriting the upstream keymap.
    (vim-region-forward-to-char 2 ?x)
    (vim-region-smoke--region "a x b x" 8 1)
    (vim-region-smoke--assert (eq vim-region-last-search-char ?x) "search char not remembered")
    (vim-region-backward-to-char 1 ?x)
    (vim-region-smoke--region "a " 3 1)
    (vim-region-forward-last-char)
    (vim-region-smoke--region "a x b x" 8 1)
    (vim-region-backward-last-char)
    (vim-region-smoke--region "a " 3 1)
    (vim-region-smoke--mode t)
    (vim-region-smoke--text "a x b x c x\n")))

(defun vim-region-smoke--symbol-and-expansion ()
  (vim-region-smoke--with-buffer "(outer inner-symbol)\n"
    (emacs-lisp-mode)
    (vim-region-smoke--start 11)
    (vim-region-smoke--keys "t")
    (vim-region-smoke--region "inner-symbol" 20 8)
    (vim-region-smoke--mode t)
    (vim-region-smoke--text "(outer inner-symbol)\n"))
  (vim-region-smoke--with-buffer "alpha beta\nkeep\n"
    (vim-region-smoke--start 3)
    (vim-region-smoke--keys "+")
    (vim-region-smoke--region "alpha" 1 6)
    (vim-region-smoke--mode t)
    (vim-region-smoke--text "alpha beta\nkeep\n")))

(defun vim-region-smoke--evidence (file text)
  (with-temp-file (expand-file-name file (getenv "VIM_REGION_SMOKE_EVIDENCE"))
    (insert text)))

(defun vim-region-smoke--final-state ()
  "Write evidence from the actual editing buffer, not a display caption."
  (vim-region-smoke--text "alpha gammabeta \nkeep this line\n")
  (vim-region-smoke--region "alpha" 6 1)
  (vim-region-smoke--mode t)
  (vim-region-smoke--assert (buffer-modified-p) "editing buffer is unmodified")
  (vim-region-smoke--evidence "final-buffer.txt" (buffer-string))
  (vim-region-smoke--evidence
   "final-state.txt"
   (format "mode=%s\nlocal-mode=%s\npoint=%d\nmark=%d\nregion=%s\nactive=%s\nmodified=%s\n"
           (if vim-region-mode "on" "off")
           (if local-vim-region-mode "on" "off") (point) (mark)
           (buffer-substring-no-properties (region-beginning) (region-end))
           (if mark-active "yes" "no") (if (buffer-modified-p) "yes" "no"))))

(defun vim-region-smoke--edit ()
  (let ((buffer (get-buffer-create "*vim-region editing proof*"))
        (kill-ring nil) (kill-ring-yank-pointer nil)
        (interprogram-cut-function nil) (interprogram-paste-function nil))
    (vim-region-mode -1)
    (switch-to-buffer buffer)
    (delete-other-windows)
    (fundamental-mode)
    (erase-buffer)
    (insert "alpha beta gamma\nkeep this line\n")
    (set-buffer-modified-p nil)
    (vim-region-smoke--start 7)
    (vim-region-smoke--keys "w l")
    (vim-region-smoke--region "beta " 12 7)
    (vim-region-smoke--keys "d")
    (vim-region-smoke--mode nil)
    (vim-region-smoke--text "alpha gamma\nkeep this line\n")
    (vim-region-smoke--assert (equal (car kill-ring) "beta ") "editing kill lost beta space")
    ;; d autoquits in the real pre-command hook; re-enable before e and p.
    (vim-region-smoke--start (point))
    (vim-region-smoke--keys "e p")
    (vim-region-smoke--mode nil)
    (vim-region-smoke--text "alpha gammabeta \nkeep this line\n")
    (vim-region-smoke--start 1)
    (vim-region-smoke--keys "w")
    (vim-region-smoke--final-state)
    buffer))

(defun vim-region-smoke-run ()
  "Exercise installed semantics, then retain the genuine edited buffer."
  (setq create-lockfiles nil enable-local-variables nil enable-local-eval nil
        inhibit-startup-screen t transient-mark-mode t)
  ;; Do not require expand-region here: the installed vim-region package must
  ;; load its propagated dependency itself, so + works immediately after require.
  (vim-region-smoke--assert
   (and (featurep 'expand-region) (commandp 'er/expand-region)
        (locate-library "expand-region"))
   "installed vim-region did not load its propagated expand-region dependency")
  (dolist (entry '((vim-region-mode . "VIM_REGION_SMOKE_PACKAGE_DIR")
                   (er/expand-region . "VIM_REGION_SMOKE_EXPAND_DIR")))
    (let ((file (symbol-file (car entry) 'defun))
          (directory (getenv (cdr entry))))
      (vim-region-smoke--assert
       (and file directory
            (file-in-directory-p (file-truename file) (file-truename directory)))
       "%S loaded from %S, not installed directory %S" (car entry) file directory)))
  (vim-region-smoke--movement)
  (vim-region-smoke--kill-ring)
  (vim-region-smoke--eternal)
  (vim-region-smoke--characters)
  (vim-region-smoke--symbol-and-expansion)
  (vim-region-smoke--edit))

(defun vim-region-smoke-tty-scene ()
  "Capture the real edited text, highlighted region, and minor-mode lighter."
  (condition-case err
      (progn
        (vim-region-smoke-run)
        (setq cursor-type 'box)
        (message nil)
        (redisplay t)
        (run-at-time
         1.5 nil
         (lambda ()
           (condition-case err
               (progn
                 ;; Recheck the retained buffer at capture time; no fake scene.
                 (vim-region-smoke--final-state)
                 (redisplay t)
                 (let* ((log (getenv "VIM_REGION_SMOKE_TTY_LOG"))
                        (size (progn (sleep-for 0.5)
                                     (file-attribute-size (file-attributes log)))))
                   (sleep-for 0.5)
                   (vim-region-smoke--assert
                    (= size (file-attribute-size (file-attributes log)))
                    "terminal output still changing at frame export")
                   (vim-region-smoke--evidence "tty-frame.bytes" (format "%d\n" size)))
                 (vim-region-smoke--evidence "tty-scene.ok" "ok\n")
                 (kill-emacs 0))
             (error
              (vim-region-smoke--evidence "tty-scene.err" (concat (error-message-string err) "\n"))
              (kill-emacs 1))))))
    (error
     (vim-region-smoke--evidence "tty-scene.err" (concat (error-message-string err) "\n"))
     (kill-emacs 1))))

;;; emacs-vim-region-smoke.el ends here
