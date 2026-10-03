;;; GenEd -- legacy visual notation editor, ported to SBCL/McCLIM.
;;; SPDX-License-Identifier: GPL-3.0-only

(define-module (tay packages gened)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-i-m))

(define %gened-asd
  (local-file (search-tay-package-file "files/gened.asd")))
(define %gened-mcclim
  (local-file (search-tay-package-file "files/gened-mcclim.lisp")))
(define %gened-main
  (local-file (search-tay-package-file "files/gened-main.lisp")))
(define %gened-duplicates
  (local-file
   (search-tay-package-file "patches/gened-duplicate-definitions.patch")))

(define-public gened
  (package
    (name "gened")
    (version "0-0.0d847a3")
    (source (package-source lambdamikel-gened-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("gened")
      ;; Upstream provides no test system.  Exercise the installed editor's
      ;; ordinary GUI independently, including scene save and reopen.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'adapt-to-mcclim
            (lambda _
              (copy-file #$%gened-asd "gened.asd")
              (copy-file #$%gened-mcclim "gened-mcclim.lisp")
              (copy-file #$%gened-main "gened-main.lisp")
              (invoke "patch" "-p1" "--input" #$%gened-duplicates)
              ;; The old loader uses vendor defsystem and ~/define-system;
              ;; ASDF builds the complete enumerated source without CLASSIC.
              (substitute* "src/gened-packages.lisp"
                (("\\(:use clim-lisp") "(:use #:clim-lisp")
                (("^[[:space:]]*clim$") "        #:clim")
                (("#\\+:classic classic") "#+:classic #:classic")
                (("#\\+:classic krss-classic") "#+:classic #:krss-classic")
                (("\\(:shadowing-import-from classic")
                 "(:shadowing-import-from #:classic")
                (("\\(defpackage gened")
                 (string-append
                  "(defpackage gened\n"
                  "  (:import-from #:clim-extensions\n"
                  "    #:accept-values-pane #:accept-values-pane-displayer)")))
              ;; The portable OUTL definition is supplied before FRAME2.
              (substitute* "src/frame2.lisp"
                (("#\\+\\(or mcl lispworks\\)") "#+nil")
                ;; Property panes must rerun their displayer so accepted
                ;; values update the editor's mode and property slots.
                (("accept-values-pane-displayer")
                 "accept-values-pane-displayer :resynchronize-every-pass t")
                ;; CLIM completion names are strings, not the underlying
                ;; class symbols, numbers, or property lists themselves.
                ((":name-key identity") ":name-key princ-to-string"))
              ;; Vendor confirmation returned booleans; McCLIM returns an
              ;; action keyword.  Cancellation must not become truthy.
              (substitute* "src/main.lisp"
                (("yes-or-no \\(notify-user")
                 "yes-or-no (confirm-operation"))
              (substitute* "src/inout.lisp"
                (("not \\(notify-user") "not (confirm-operation"))
              ;; This direct-printer command exists only on Allegro.  Keep
              ;; portable PostScript export, without advertising a dead item.
              (substitute* "src/comtable.lisp"
                (("\\(\"Print Scene\" :command")
                 "#+allegro (\"Print Scene\" :command"))
              ;; CLIM 2 separates menu entries from command registration.
              (substitute* "src/undo.lisp"
                (("remove-command-from-command-table")
                 "remove-undo-menu-item")
                (("add-command-to-command-table") "add-undo-menu-item"))
              ;; Translator arglists begin with the presented object, then
              ;; pointer coordinates.  The blank-area object is an event.
              (let ((matches 0))
                (substitute* "src/creator.lisp"
                  (("^  \\(x y\\)")
                   (set! matches (+ matches 1))
                   "  (object x y)"))
                (unless (= matches 1)
                  (error "GenEd create translator adaptation mismatch"
                         matches)))
              ;; McCLIM's text-field gadget initializes its callback before
              ;; its output record is adopted.  Use the standard textual
              ;; dialog for text creation rather than that broken gadget.
              (substitute* "src/creator.lisp"
                ((":view 'gadget-dialog-view")
                 ":view 'textual-dialog-view"))
              ;; Guix's subsequent copy-source phase also normalizes all
              ;; source mtimes before compilation.
              (for-each (lambda (file) (utime file 0 0 0 0))
                        '("gened.asd" "gened-mcclim.lisp" "gened-main.lisp"))))
          (add-after 'create-asdf-configuration 'install-launcher
            (lambda _
              (let ((program (string-append #$output "/bin/gened")))
                (mkdir-p (dirname program))
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port
                            (string-append
                             "export XDG_CONFIG_DIRS=~a/etc/xdg"
                             "${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}~%")
                            #$output)
                    (format port
                            (string-append
                             "exec ~a/bin/sbcl --noinform --no-userinit --no-sysinit"
                             " --non-interactive --eval '(require :asdf)'"
                             " --eval '(asdf:load-system :gened)'"
                             " --eval '(gened:main)' \"$@\"~%")
                            #$sbcl)))
                (chmod program #o555)))))))
    (inputs (list sbcl sbcl-mcclim))
    (synopsis "Visual notation editor using Common Lisp and CLIM")
    (description
     "GenEd is a graphical editor for visual notations with geometric and
spatial relationships.  This package runs the complete upstream editor on
SBCL and McCLIM, including graphical primitives, text, object manipulation,
scene files and object libraries.  The CLASSIC description-logic integration
was disabled by upstream and is not included.  Example scenes, libraries and
label assets are initialized in writable XDG user data without overwriting
existing files.")
    (home-page "https://github.com/lambdamikel/GenEd")
    (license license:gpl3)))
