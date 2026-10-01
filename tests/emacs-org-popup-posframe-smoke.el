;;; emacs-org-popup-posframe-smoke.el --- Isolated runtime proof -*- lexical-binding: t; -*-

(require 'org)
(require 'org-capture)
(require 'posframe)
(require 'org-popup-posframe)

(defun org-popup-smoke-assert (condition description)
  (unless condition (error "%s" description)))

(defun org-popup-smoke-report (format-string &rest arguments)
  ;; Graphical `message' writes to *Messages*, not the redirected stderr.
  ;; Emit proof/diagnostics to the driver's actual log, as batch Emacs does.
  (princ (concat (apply #'format format-string arguments) "\n")
         #'external-debugging-output))

(defun org-popup-smoke-advice-lifecycle ()
  (org-popup-posframe-mode 1)
  (dolist (entry '((org-capture . org-popup-posframe--org-capture-advice)
                   (org-insert-link . org-popup-posframe--org-insert-link-advice)))
    (org-popup-smoke-assert (advice-member-p (cdr entry) (car entry))
                            (format "Missing advice for %s" (car entry))))
  (org-popup-posframe-mode -1)
  (dolist (entry '((org-capture . org-popup-posframe--org-capture-advice)
                   (org-insert-link . org-popup-posframe--org-insert-link-advice)))
    (org-popup-smoke-assert (not (advice-member-p (cdr entry) (car entry)))
                            (format "Advice remained for %s" (car entry)))))

(defun org-popup-smoke-frame (buffer)
  (org-popup-smoke-assert (buffer-live-p buffer) "Popup buffer is missing")
  (let ((frame (buffer-local-value 'posframe--frame buffer)))
    (org-popup-smoke-assert (frame-live-p frame) "Popup child frame is not live")
    (org-popup-smoke-assert (frame-visible-p frame) "Popup child frame is hidden")
    (org-popup-smoke-assert (frame-parent frame) "Popup is not an Emacs child frame")
    (org-popup-smoke-assert (eq (window-buffer (frame-root-window frame)) buffer)
                            "Popup is displaying the wrong buffer")
    frame))

(defun org-popup-smoke-choose-capture ()
  ;; Called while Org's real read-char menu is waiting.  Do not replace Org's
  ;; selector, its reader, or posframe-show: capture the live menu, then type s.
  (condition-case failure
      (let ((menu (get-buffer "*Org Select*")))
        (org-popup-smoke-report "ORG_POPUP_MENU: entering live selector callback")
        (org-popup-smoke-frame menu)
        (org-popup-smoke-assert
         (with-current-buffer menu
           (string-match-p "Offline capture proof" (buffer-string)))
         "Org did not render the capture template choice")
        (redisplay t)
        (org-popup-smoke-assert
         (zerop (call-process (getenv "ORG_POPUP_SMOKE_IMPORT") nil nil nil
                             "-window" "root"
                             (concat "PNG:" (getenv "ORG_POPUP_SMOKE_PNG"))))
         "Failed to capture the actual Org menu")
        (setq unread-command-events (append unread-command-events (list ?s)))
        (org-popup-smoke-report "ORG_POPUP_MENU: captured rendered menu; selected s"))
    (error (org-popup-smoke-report "Org popup menu failed: %S" failure)
           (kill-emacs 1))))

(defun org-popup-smoke-gui ()
  (condition-case failure
      (progn
        (org-popup-smoke-report "ORG_POPUP_GUI: starting graphical operation")
        (org-popup-smoke-assert (and (display-graphic-p) (posframe-workable-p))
                                "Graphical posframe support is unavailable")
        (set-frame-size (selected-frame) 100 36)
        (set-face-attribute 'default nil :height 140)
        (setq inhibit-startup-screen t create-lockfiles nil make-backup-files nil
              auto-save-default nil org-popup-posframe-min-width 56
              org-popup-posframe-min-height 12)
        (switch-to-buffer (get-buffer-create "*Offline Org workspace*"))
        (org-mode)
        (insert "* Offline Org popup proof\n\nSelect a capture template in the child frame.\n")
        (let* ((destination (expand-file-name "captured.org" default-directory))
               (org-capture-templates
                `(("s" "Offline capture proof" entry (file ,destination)
                   "* TODO %?\n")
                  ("x" "Alternate capture" entry (file ,destination) "* %?\n")))
               (selector (run-at-time 0.8 nil #'org-popup-smoke-choose-capture)))
          (unwind-protect
              (progn
                (org-popup-posframe-mode 1)
                (org-capture)
                (org-popup-smoke-assert (bound-and-true-p org-capture-mode)
                                        "Real capture template was not entered")
                (insert "Completed isolated capture")
                (org-capture-finalize)
                (org-popup-smoke-report "ORG_POPUP_CAPTURE: selected template and finalized")
                (org-popup-smoke-assert
                 (with-temp-buffer
                   (insert-file-contents destination)
                   (string-match-p "^\\* TODO Completed isolated capture$"
                                   (buffer-string)))
                 "Org did not persist the finalized capture"))
            (cancel-timer selector)))
        ;; Exercise the documented direct show/hide path on an actual Org
        ;; buffer too, independently of the capture selector's lifetime.
        (let ((buffer (get-buffer-create "*Offline Org result*")))
          (with-current-buffer buffer
            (org-mode)
            (insert "* DONE Captured and finalized offline\n"))
          (org-popup-posframe--show-buffer buffer #'posframe-poshandler-frame-center)
          (redisplay t)
          (let ((frame (org-popup-smoke-frame buffer)))
            (posframe-hide buffer)
            (org-popup-smoke-assert (not (frame-visible-p frame))
                                    "Hidden popup remained visible")
            (posframe-delete buffer)
            (org-popup-smoke-assert (not (frame-live-p frame))
                                    "Deleted popup frame remained live"))
          (kill-buffer buffer))
        (posframe-delete-all)
        (org-popup-posframe-mode -1)
        (org-popup-smoke-assert
         (not (advice-member-p #'org-popup-posframe--org-mks-advice 'org-mks))
         "Temporary capture selector advice leaked")
        (org-popup-smoke-report "ORG_POPUP_GUI_OK: capture menu rendered, selected, finalized; show/hide/delete")
        (kill-emacs 0))
    (error (org-popup-smoke-report "Org popup GUI proof failed: %S" failure)
           (kill-emacs 1))))

(when noninteractive
  (condition-case failure
      (progn
        (org-popup-smoke-advice-lifecycle)
        (message "ORG_POPUP_BATCH_OK: advice installed and removed")
        (kill-emacs 0))
    (error (message "Org popup batch proof failed: %S" failure) (kill-emacs 1))))
