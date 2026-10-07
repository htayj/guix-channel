;;; GNU Guix package for mmontone/pbui.

(define-module (tay packages pbui)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (tay packages starred-i-m))

(define-public emacs-pbui
  (package
    (name "emacs-pbui")
    ;; Upstream has no release tag; 0.1 is the version declared by pbui.el
    ;; at the fixed source revision used below.
    (version "0.1-0.19a606d")
    (source (package-source mmontone-pbui-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; All eight top-level libraries are installed and byte-compiled:
      ;; pbui, pbui-util, pbui-standard-commands, pbui-dired, pbui-org,
      ;; pbui-calendar, pbui-email and pbui-contacts-app.  The docs/ images,
      ;; TODO and README are not Lisp libraries.
      ;; Upstream ships no test suite.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; Upstream relies on libraries that happen to be loaded in the
          ;; author's session.  Require them where they are used so every
          ;; module compiles and loads in a fresh Emacs.
          (add-after 'unpack 'require-used-libraries
            (lambda _
              ;; defclass (eieio), hash-table-values (subr-x) and the
              ;; prop-match accessors (text-property-search) are not
              ;; autoloaded.
              (substitute* "pbui.el"
                (("^\\(require 'dash\\)" all)
                 (string-append all "\n(require 'eieio)"
                                "\n(require 'subr-x)"
                                "\n(require 'text-property-search)")))
              ;; The send-email command calls s-join.
              (substitute* "pbui-standard-commands.el"
                (("^\\(require 'pbui\\)" all)
                 (string-append all "\n(require 's)")))
              ;; contacts-app parses the HTTP response with
              ;; json-read-from-string.
              (substitute* "pbui-contacts-app.el"
                (("^\\(require 'request\\)" all)
                 (string-append all "\n(require 'json)")))
              ;; pbui-util uses presentation-at-point from pbui and
              ;; inspector-inspect from inspector, and lacks the feature
              ;; declaration needed by (require 'pbui-util).
              (substitute* "pbui-util.el"
                (("^\\(defun inspect-text-properties-at-point" all)
                 (string-append "(require 'pbui)\n(require 'inspector)\n\n"
                                all)))
              (let ((port (open-file "pbui-util.el" "a")))
                (display "\n(provide 'pbui-util)\n" port)
                (close-port port))))
          ;; The selected-presentations buffer button passes the selection
          ;; as the parameter but the body reads an unbound `sel'.
          (add-after 'require-used-libraries 'fix-goto-selected-presentation
            (lambda _
              (substitute* "pbui.el"
                (("^\\(defun pbui:goto-selected-presentation \\(selected-presentation\\)")
                 "(defun pbui:goto-selected-presentation (sel)"))))
          ;; Guix has no /usr/bin.  Resolve the desktop helpers through the
          ;; user's exec-path at run time, as the commands intend; they are
          ;; ambient desktop integration rather than package dependencies.
          (add-after 'require-used-libraries 'use-exec-path-programs
            (lambda _
              (substitute* '("pbui-standard-commands.el"
                             "pbui-contacts-app.el")
                (("\"/usr/bin/xdg-open\"") "\"xdg-open\"")
                (("\"/usr/bin/thunderbird\"") "\"thunderbird\""))))
          ;; There is no upstream LICENSE file; the GPL notices are retained
          ;; in the installed sources.  Keep the upstream README as docs.
          (add-after 'install 'install-readme
            (lambda _
              (install-file "README.org"
                            (string-append #$output
                                           "/share/doc/emacs-pbui")))))))
    ;; dash is required by pbui.el; s and request by the companion command
    ;; and demo modules; inspector supplies inspector-inspect for pbui-util
    ;; and the conditional inspect command in pbui-standard-commands.
    ;; eieio, subr-x, text-property-search, calendar, dired, org, mml, json
    ;; and outline are bundled with Emacs.
    (propagated-inputs
     (list emacs-dash emacs-inspector emacs-request emacs-s))
    (home-page "https://github.com/mmontone/pbui")
    (synopsis "Presentation-based user interface for Emacs")
    (description
     "PBUI attaches domain objects to their printed text in Emacs buffers as
@dfn{presentations}.  Users select presentations first, for example several
files and a directory, and then run a command whose argument types match the
selection.  The package provides @code{pbui-mode}, the modal
@code{pbui-modal-mode}, commands for selecting, visualizing and navigating
presentations, and @code{def-presentation-command} for defining commands.
Companion libraries present Dired files and directories, calendar dates, and
add file commands, Org link insertion, email attachment commands, inspector
helpers, and a contacts demo application that fetches sample users over the
network.  The mail and URL commands run @command{xdg-open} and
@command{thunderbird} from the user's @code{exec-path} when invoked.")
    ;; pbui.el, pbui-calendar.el, pbui-contacts-app.el, pbui-dired.el and
    ;; pbui-standard-commands.el state GPLv3-or-later.  The short companion
    ;; files pbui-email.el, pbui-org.el and pbui-util.el carry no notice of
    ;; their own and are covered by the project's notices.
    (license license:gpl3+)))
