;;; emacs-mentor-pinned-smoke.el --- Offline installed-client proof -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'ert)
(require 'url)
;; Load the installed activation file just as Guix's Emacs site-start does.
(load "mentor-pinned-autoloads" nil t)
(require 'mentor)

(defun mentor-smoke-prohibit-io (&rest _)
  (error "External I/O prohibited during the Mentor offline fixture"))

;; A separate network namespace in the shell launcher is the hard boundary.
;; These guards also catch accidental daemon startup or RPC in the fixture.
(dolist (function '(xml-rpc-method-call url-retrieve url-retrieve-synchronously
                    make-network-process open-network-stream
                    start-process make-process))
  (advice-add function :override #'mentor-smoke-prohibit-io))

(ert-deftest mentor-smoke-configuration ()
  (let* ((root (make-temp-file "mentor-conf-" t))
         (config (expand-file-name "rtorrent.rc" root))
         (socket (expand-file-name "rtorrent.rpc" root))
         (downloads (expand-file-name "downloads" root))
         (session (expand-file-name "session" root))
         (mentor-rtorrent-external-rpc socket)
         (mentor-rpc--rtorrent-url nil)
         (mentor-rtorrent-download-directory downloads)
         (mentor-rtorrent-keep-session t)
         (mentor--rtorrent-session-directory session)
         (mentor-rtorrent-use-system-daemon t)
         (mentor-rtorrent-extra-conf "network.max_open_files = 128"))
    (unwind-protect
        (progn
          ;; External endpoint setup only normalizes configuration: it does
          ;; not connect, start rTorrent, or create the socket.
          (mentor-setup-rtorrent)
          (should (equal mentor-rpc--rtorrent-url (concat "scgi://" socket)))
          (should-not (file-exists-p socket))
          (should (equal (mentor-normalize-rpc-url "https://example.invalid/RPC2")
                         "https://example.invalid/RPC2"))
          (mentor-rtorrent-create-conf config socket)
          (with-temp-buffer
            (insert-file-contents config)
            (dolist (line (list (concat "scgi_local = " socket)
                               (concat "directory = " downloads)
                               (concat "session = " session)
                               "system.daemon = true"
                               "encoding.add = utf8"
                               "network.max_open_files = 128"))
              (should (member line (split-string (buffer-string) "\n")))))
          ;; Config generation must not materialize daemon/session state.
          (should-not (file-exists-p downloads))
          (should-not (file-exists-p session)))
      (delete-directory root t))))

(defun mentor-smoke-populate-local-view ()
  "Populate the current Mentor buffer from local data, without RPC.
This same fixture can be displayed in an interactive Emacs for visual proof."
  (mentor-mode)
  (setq-local mentor-view-torrent-list nil)
  (setq-local mentor-rtorrent-client-version "offline-fixture")
  (setq-local mentor-rtorrent-library-version "offline-fixture")
  (setq-local mentor-rtorrent-name "isolated local data")
  (setq-local mentor-view-columns
              '(((mentor-download-state-column) -2 "State" mentor-download-state)
                ((mentor-download-progress-column) -4 "Cmp" mentor-download-progress)
                (name -24 "Name" mentor-download-name)
                ((mentor-download-tracker-name-column) -20 "Tracker" mentor-tracker-name)
                (directory -32 "Directory")))
  (mentor-init-header-line)
  (mentor-view-torrent-list-clear)
  (let ((methods '(local_id hash name bytes_done size_bytes hashing
                   is_active is_open directory))
        (trackers '(t_url t_is_enabled)))
    (mentor-data-download-update-from
     methods trackers
     '(2 "bbbbbbbb" "Zulu example.iso" 1024 2048 0 0 0
         "/fixture/stopped" "https://tracker.example.org/announce#1#") t)
    (mentor-data-download-update-from
     methods trackers
     '(1 "aaaaaaaa" "Alpha example.iso" 1024 4096 0 1 1
         "/fixture/active" "https://tracker.example.org/announce#1#") t))
  (mentor-redisplay)
  (goto-char (point-min)))

(ert-deftest mentor-smoke-client-fixture ()
  ;; Fixed rTorrent-shaped values exercise the real parser, item storage,
  ;; visible view, sorting, navigation, marking and refresh logic.  No RPC
  ;; function is replaced with an echo or a mock response.
  (with-temp-buffer
    (mentor-smoke-populate-local-view)
    (should (eq (lookup-key mentor-mode-map (kbd "T"))
                'mentor-tracker-open-view-at-point))
      (should (= (hash-table-count mentor-items) 2))
      (should (equal (mentor-item-property 't_url (mentor-get-item 1))
                     '("https://tracker.example.org/announce")))
      (should (equal (mentor-download-progress-column (mentor-get-item 1)) "25%"))
      (should (equal (mentor-download-state-column (mentor-get-item 2)) "SC"))
      (mentor-redisplay)
      (goto-char (point-min))
      (should (= (mentor-item-id-at-point) 1))
      (should (string-match-p "Alpha example.iso" (buffer-string)))
      (should (string-match-p "Zulu example.iso" (buffer-string)))
      (should (string-match-p "example.org" (buffer-string)))
      (mentor-next-item)
      (should (= (mentor-item-id-at-point) 2))
      (mentor-previous-item)
      (should (= (mentor-item-id-at-point) 1))
      (mentor-mark)
      (goto-char (point-min))
      (should (= (char-after) ?*))
      (mentor-unmark)
      (goto-char (point-min))
      (should (= (char-after) ?\s))
      ;; Sparse refresh updates the existing object and preserves its name.
      (mentor-view-torrent-list-clear)
      (mentor-data-download-update-from '(local_id bytes_done) nil '(1 4096))
      (should (equal (mentor-item-property 'name (mentor-get-item 1))
                     "Alpha example.iso"))
      (should (equal (mentor-download-progress-column (mentor-get-item 1)) ""))
      (mentor-redisplay)
      (should (string-match-p "Alpha example.iso" (buffer-string)))
      (should-not (string-match-p "Zulu example.iso" (buffer-string)))
      (should-not (string-match-p "25%" (buffer-string)))
      ;; New downloads in a sparse update require full initialization.
      (should-error
       (mentor-data-download-update-from '(local_id bytes_done) nil '(99 1))
       :type 'mentor-need-init)))

(defun mentor-smoke--evidence (file text)
  (with-temp-file (expand-file-name file (getenv "MENTOR_SMOKE_EVIDENCE"))
    (insert text)))

(defun mentor-smoke-tty-scene ()
  "Render the genuine guarded local client fixture before terminal restore."
  (condition-case err
      (progn
        (switch-to-buffer "*Mentor offline client*")
        (mentor-smoke-populate-local-view)
        (setq-local mode-line-format
                    '(" Mentor offline client | sorted local data | no RPC "))
        (delete-other-windows)
        (goto-char (point-min))
        ;; Exercise real local navigation and marking in the visible buffer.
        (mentor-next-item)
        (unless (= (mentor-item-id-at-point) 2)
          (error "Mentor scene navigation did not select Zulu"))
        (mentor-mark)
        (goto-char (point-min))
        (setq inhibit-startup-screen t)
        (message "Mentor offline client: parsed, sorted, navigated and marked locally")
        (redisplay t)
        (run-at-time
         1.5 nil
         (lambda ()
           (condition-case err
               (progn
                 (redisplay t)
                 (let* ((log (getenv "MENTOR_SMOKE_TTY_LOG"))
                        (size (progn (sleep-for 0.5)
                                     (file-attribute-size (file-attributes log)))))
                   (sleep-for 0.5)
                   (unless (= size (file-attribute-size (file-attributes log)))
                     (error "Mentor terminal output still changing at frame export"))
                   (mentor-smoke--evidence "tty-frame.bytes" (format "%d\n" size)))
                 (mentor-smoke--evidence "tty-scene.ok" "ok\n")
                 (kill-emacs 0))
             (error
              (mentor-smoke--evidence "tty-scene.err"
                                      (concat (error-message-string err) "\n"))
              (kill-emacs 1))))))
    (error
     (mentor-smoke--evidence "tty-scene.err" (concat (error-message-string err) "\n"))
     (kill-emacs 1))))

;;; emacs-mentor-pinned-smoke.el ends here
