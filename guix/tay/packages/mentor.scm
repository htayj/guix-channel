;;; Requested post-0.5 Mentor revision from issue #166.

(define-module (tay packages mentor)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-s-z))

(define-public emacs-mentor-pinned
  (package
    (inherit emacs-mentor)
    ;; Guix already provides the 0.5 release.  The requested revision adds
    ;; mentor-trackers.el and its tracker view/actions after that release;
    ;; keep a distinct name instead of shadowing the upstream package.
    (name "emacs-mentor-pinned")
    (version "0.5-0.ed42ae8")
    (source (package-source skangas-mentor-source))
    (arguments
     (list
      #:include
      #~'("^mentor\\.el$" "^mentor-data\\.el$" "^mentor-files\\.el$"
          "^mentor-rpc\\.el$" "^mentor-trackers\\.el$"
          "^mentor(-pinned)?-(autoloads|pkg)\\.el$")
      #:test-command
      #~(list
         "emacs" "-Q" "--batch" "-L" "." "--eval"
         "(progn
            (require 'url)
            (require 'xml-rpc)
            (defun mentor-build-prohibit-io (&rest _)
              (error \"external I/O prohibited during Mentor build checks\"))
            (dolist (function '(xml-rpc-method-call url-retrieve
                                url-retrieve-synchronously make-network-process
                                open-network-stream start-process make-process))
              (advice-add function :override #'mentor-build-prohibit-io)))"
         "-l" "test/mentor-tests.el" "-l" "test/mentor-rpc-tests.el"
         "-f" "ert-run-tests-batch-and-exit")
      #:phases
      #~(modify-phases %standard-phases
          ;; The pinned tracker library has neither a provide nor autoload
          ;; cookies and expects mentor-mode-map to exist.  Activate it only
          ;; after Mentor loads, through Guix's normal package autoload file.
          (add-after 'make-autoloads 'activate-tracker-view
            (lambda _
              (let ((port (open-file "mentor-pinned-autoloads.el" "a")))
                (display
                 "\n(with-eval-after-load 'mentor (load \"mentor-trackers\" nil t))\n"
                 port)
                (close-port port))))
          (add-before 'check 'set-test-home
            (lambda _
              (let ((home (string-append (getenv "TMPDIR") "/mentor-home")))
                (mkdir-p home)
                (setenv "HOME" home)
                (setenv "XDG_CONFIG_HOME" home)
                (setenv "XDG_DATA_HOME" home)
                (setenv "XDG_CACHE_HOME" home))))
          (add-after 'install 'install-license
            (lambda _
              (install-file "COPYING"
                            (string-append #$output
                                           "/share/doc/emacs-mentor-pinned")))))))
    ;; Inherit Guix's propagated async, url-scgi and xml-rpc dependencies.
    ;; rTorrent is deliberately not a build input or automatically started.
    (home-page "https://github.com/skangas/mentor")
    (synopsis "Emacs rTorrent frontend at the requested post-0.5 revision")
    (description
     "Mentor provides an Emacs frontend for the rTorrent BitTorrent client.
This variant packages the fixed post-0.5 revision requested in issue #166,
including its tracker detail view and tracker enable, disable, and announce
commands.  It does not replace Guix's release package @code{emacs-mentor}.
Users provide rTorrent separately or configure an external XML-RPC endpoint;
no torrent client is started during the build.")
    ;; mentor.el explicitly declares SPDX-License-Identifier:
    ;; GPL-3.0-or-later; the other shipped libraries carry the same grant.
    (license license:gpl3+)))
