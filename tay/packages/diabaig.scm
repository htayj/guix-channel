;;; GNU Guix package for conornally's Diabaig terminal roguelike.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages diabaig)
  #:use-module (guix build-system gnu)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages vim))

(define %diabaig-commit
  "b90d35847070d3de27d4656b3316e0e932884b25")

;; This helper is installed below libexec and is only reachable through the
;; package-owned --smoke mode.  It keeps the PTY orchestration in a small
;; reviewable Python file rather than depending on a host script utility.
(define %diabaig-smoke-script
  (local-file "diabaig-smoke.py"))

(define-public diabaig
  (package
    (name "diabaig")
    (version "1.0.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/conornally/diabaig")
             (commit %diabaig-commit)))
       (file-name (git-file-name name version))
       ;; SHA-256 Guix/Nix-base32 hash of the fixed upstream checkout.
       (sha256
        (base32 "1pw0c63bvn8yda694489547d8vw1bfddnacc04456i278rv45qdp"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no check target.  The installed terminal behavior is
      ;; covered by tests/diabaig-smoke.sh and the package's --smoke mode.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (add-before 'build 'fix-header-generation
            (lambda _
              ;; Bash does not interpret backslash escapes in echo's default
              ;; mode.  The upstream Makefile therefore emits literal "\\n"
              ;; sequences into this generated header in the Guix builder.
              (substitute* "Makefile"
                (("@echo \"//Auto generated header\" > \\$@")
                 "@printf '%s\\n' \"//Auto generated header\" > $@")
                (("@echo \"#ifndef DATAHEADER_H\">> \\$@")
                 "@printf '%s\\n' \"#ifndef DATAHEADER_H\" > $@")
                (("@echo \"#define DATAHEADER_H.* >> \\$@")
                 "@printf '%s\\n' \"#define DATAHEADER_H\" >> $@")
                (("@echo \".*#endif//DATAHEADER_H.* >> \\$@")
                 "@printf '%s\\n' \"#endif//DATAHEADER_H\" >> $@"))))
          (replace 'build
            (lambda _
              ;; The Linux toolchain generates build/data_embedded.h with xxd
              ;; and links the source-built game with ncurses and libm.
              (invoke "make" "all" "CC=gcc" "PLATFORM=linux")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/diabaig"))
                     (man (string-append out "/share/man/man6"))
                     (program (string-append libexec "/diabaig"))
                     (runner (string-append libexec
                                             "/diabaig-smoke-runner.py"))
                     (launcher (string-append bin "/diabaig"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (mkdir-p man)
                ;; Do not expose the real executable as a public store path.
                ;; The launcher controls its working directory and arguments.
                (install-file "diabaig" libexec)
                (copy-file #$%diabaig-smoke-script runner)
                (substitute* runner
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod runner #o555)
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "docs/README.md" "docs/guide.txt"
                            "res/credits.txt"))
                (substitute* "docs/debian/diabaig.6"
                  (("@VERSION@") #$version))
                (install-file "docs/debian/diabaig.6" man)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port "real=~s\nrunner=~s\npython=~s\n"
                            program runner python)
                    (format port "mkdir=~s\nterminfo=~s\n" mkdir terminfo)
                    (display
                     "export TERM=\"${TERM:-xterm-256color}\"\n"
                     port)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display
                     "if test \"${1-}\" = --smoke; then\n"
                     port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: diabaig [--smoke]' >&2; exit 64; }\n")
                     port)
                    (display "  exec \"$python\" \"$runner\" \"$real\"\n"
                             port)
                    (display "fi\n" port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-${HOME:?"
                      "HOME or XDG_STATE_HOME must be set}/.local/state}\"\n")
                     port)
                    (display "state=\"$state_root/diabaig\"\n" port)
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "exec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain xxd))
    (inputs (list bash-minimal coreutils-minimal ncurses python-minimal))
    (home-page "https://github.com/conornally/diabaig")
    (synopsis "Terminal roguelike game")
    (description
     "Diabaig is a traditional turn-based ASCII roguelike.  This package
builds the fixed upstream v1.0.1 source checkout with GCC, xxd, ncurses, and
libm, without using the upstream platform binaries or any network access at
build or runtime.  The public launcher keeps the rebuilt program private under
@file{libexec}, runs it from @file{$XDG_STATE_HOME/diabaig}, and provides a
package-owned @option{--smoke} mode that drives the real game through an
isolated PTY to verify movement, inventory, save, restore, and cleanup.")
    (license license:expat)))
