;;; The Sewer Massacre -- pinned, source-built Common Lisp game.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages sewer-massacre)
  #:use-module (guix build-system asdf)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages auxiliary))

(define %default-controls
  ;; Independently bind the documented commands, rather than redistribute the
  ;; controls.cfg file, which has no explicit redistribution grant.
  (list
   "    (progn"
   "      (control-bind (make-instance 'move-to :dx 1 :dy 0) 261 54)"
   "      (control-bind (make-instance 'move-to :dx -1 :dy 0) 260 52)"
   "      (control-bind (make-instance 'move-to :dx 0 :dy -1) 259 56)"
   "      (control-bind (make-instance 'move-to :dx 0 :dy 1) 258 50)"
   "      (control-bind (make-instance 'move-to :dx 1 :dy 1) 51)"
   "      (control-bind (make-instance 'move-to :dx -1 :dy 1) 49)"
   "      (control-bind (make-instance 'move-to :dx 1 :dy -1) 57)"
   "      (control-bind (make-instance 'move-to :dx -1 :dy -1) 55)"
   "      (control-bind (make-instance 'wait) 53 46)"
   "      (control-bind (make-instance 'quit-game) 81)"
   "      (control-bind (make-instance 'next-message) 32)"
   "      (control-bind (make-instance 'recap) 8 263)"
   "      (control-bind (make-instance 'look-around) 108 120)"
   "      (control-bind (make-instance 'open-door-smart) 111)"
   "      (control-bind (make-instance 'close-door-smart) 99)"
   "      (control-bind (make-instance 'save-game) 83)"
   "      (control-bind (make-instance 'descend) 62 43)"
   "      (control-bind (make-instance 'ascend) 60 45)"
   "      (control-bind (make-instance 'get-item-on-spot) 44 103)"
   "      (control-bind (make-instance 'drop-item-menu) 100)"
   "      (control-bind (make-instance 'show-inventory) 105)"
   "      (control-bind (make-instance 'show-equipment) 101)"
   "      (control-bind (make-instance 'use-item-menu) 117)"
   "      nil)))"))

(define-public sewer-massacre
  (package
    (name "sewer-massacre")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri "http://common-lisp.net/project/lifp/sewers-src.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256: 817be571edb562c0a808455be2019e85b404b684b41e7eb7b0ec6e41e3982066
       (sha256
        (base32 "0ri0k3il2vpcn2vpw7mlhjv09d45kq0y4ns512lc0qmmxmqyayw1"))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("sewers")
      #:tests? #f                     ; No upstream test system.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-source
            (lambda _
              (delete-file "readme.txt")
              (delete-file "controls.cfg")
              (substitute* "curses.lisp"
                (("\"libncurses\\.so\\.5\"")
                 (string-append "\"" #$ncurses "/lib/libncurses.so.6\"")))
              ;; Match the expression, not the archive's CRLF/indentation.
              ;; The previous anchored pattern silently left :ERROR intact.
              (let ((replaced? #f))
                (substitute* "r2.lisp"
                  ((":error\\)\\)")
                   (set! replaced? #t)
                   (string-join '#$%default-controls "\n")))
                (unless replaced?
                  (error "upstream INIT-CONTROLS fallback not found")))))
          ;; Keep the ordinary ASDF FASLs: copy-source normalizes their source
          ;; timestamps and compiles at stable store paths.  Do not dump a core.
          ;; build-program creates an extra *-exec.lisp AFTER that normalization,
          ;; embedding its wall-clock mtime, plus the live SBCL process state.
          (add-after 'create-asdf-configuration 'install-launcher
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (launcher (string-append bin "/sewer-massacre")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-file #$(local-file
                              (search-tay-package-file
                               "sewer-massacre-entry.lisp"))
                           (string-append libexec "/sewer-massacre.lisp"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\numask 077\n"
                            #$(file-append bash-minimal "/bin/sh"))
                    (format port "export TERMINFO_DIRS=~s\n"
                            (string-append #$ncurses "/share/terminfo"))
                    ;; Guix creates the complete, compiled dependency registry
                    ;; here.  No ambient Quicklisp or user ASDF configuration.
                    (format port "export XDG_CONFIG_DIRS=~s\n"
                            (string-append #$output "/etc/xdg"))
                    (display
                     "unset CL_SOURCE_REGISTRY ASDF_OUTPUT_TRANSLATIONS\n"
                     port)
                    (display
                     (string-append
                      "state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME required}/.local/state}"
                      "/sewer-massacre\"\n")
                     port)
                    (format port "~a -p -- \"$state\"\ncd -- \"$state\"\n"
                            #$(file-append coreutils-minimal "/bin/mkdir"))
                    (format port
                            (string-append
                             "exec ~a --noinform --no-userinit --no-sysinit"
                             " --script ~a \"$@\"\n")
                            #$(file-append sbcl "/bin/sbcl")
                            (string-append libexec "/sewer-massacre.lisp"))))
                (chmod launcher #o555))))
          (add-after 'install-launcher 'install-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/sewer-massacre")))
                (install-file "license.txt" doc)
                (install-file "GNU-GPL" doc)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal coreutils-minimal ncurses sbcl sbcl-cffi
                  sbcl-cl-store sbcl-md5 sbcl-trivial-gray-streams))
    (home-page "http://common-lisp.net/project/lifp/sewers.htm")
    (synopsis "Terminal roguelike set in the sewers")
    (description
     "The Sewer Massacre is a Common Lisp roguelike in which a homeless person
collects money in the sewers and tries to escape alive.  The original curses
interface, random dungeons, equipment, monsters and saved games are preserved.
Mutable files live in XDG_STATE_HOME/sewer-massacre, falling back to
HOME/.local/state/sewer-massacre.  The --smoke command exercises real map
creation, movement and save/restore in a terminal.  Compiled ASDF systems are
loaded at launch instead of snapshotting a build-time Lisp process.")
    (license (list license:gpl2
                   (license:non-copyleft
                    "http://common-lisp.net/project/lifp/sewers-src.zip"
                    "license.txt permits use of curses.lisp for any purpose.")))))
