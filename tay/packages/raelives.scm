;;; GNU Guix package for Intelligence: Rae Lives.

(define-module (tay packages raelives)
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
  #:use-module (gnu packages python))

(define %raelives-commit
  "2085fa6f55abf53ea1a07bb348f99a720763bbbd")

;; This helper is only reachable through the package-owned --smoke mode.  It
;; keeps PTY handling out of the shell wrapper while leaving the actual game
;; executable private under libexec.
(define %raelives-smoke-runner
  (local-file "raelives-smoke.py"))

(define-public raelives
  (package
    (name "raelives")
    (version "0.0.1-0.20140305")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/littleglassdiode/irl")
             (commit %raelives-commit)))
       (file-name (git-file-name name version))
       ;; SHA-256 Guix recursive source hash of the fixed upstream checkout.
       (sha256
        (base32 "130jgksgz6dflm5r0w60lylkphw5xbrr5synpcv134c4gciicwpk"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no configure script or test target.  Its ldt.sh script
      ;; is deliberately not used: it stamps the source tree and constructs
      ;; compiler commands without quoting.
      #:tests? #f
      #:make-dynamic-linker-cache? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              (setenv "GUIX_LD_WRAPPER_DISABLE_RPATH" "1")
              (invoke "gcc" "-Wall" "-std=c99" "-o" "raelives"
                      "src/actor.c" "src/ai.c" "src/input.c"
                      "src/level.c" "src/load.c" "src/main.c"
                      "src/vector.c"
                      (string-append "-L" #$ncurses "/lib")
                      (string-append "-Wl,-rpath," #$ncurses "/lib")
                      "-lm" "-lncurses")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/raelives"))
                     (program (string-append libexec "/raelives"))
                     (runner (string-append libexec
                                             "/raelives-smoke.py"))
                     (launcher (string-append bin "/raelives"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (install-file "raelives" libexec)
                (copy-file #$%raelives-smoke-runner runner)
                (substitute* runner
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod runner #o555)
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "AUTHORS" "README" "TODO"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port "real=~s\nrunner=~s\npython=~s\n"
                            program runner python)
                    (format port "mkdir=~s\nmktemp=~s\nterminfo=~s\n"
                            mkdir mktemp terminfo)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}/raelives\"\n"
                      "if test \"${1-}\" = --smoke; then\n"
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: raelives [--smoke]' >&2; exit 64; }\n"
                      "  \"$mkdir\" -p \"$state_root\"\n"
                      "  work=$(\"$mktemp\" -d \"$state_root/smoke.XXXXXXXX\")\n"
                      "  export TERM=xterm-256color\n"
                      "  export COLUMNS=80 LINES=24 LC_ALL=C\n"
                      "  exec \"$python\" \"$runner\" \"$real\" \"$work\"\n"
                      "fi\n"
                      "\"$mkdir\" -p \"$state_root\"\n"
                      "cd \"$state_root\"\n"
                      "exec \"$real\" \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal ncurses python-minimal))
    (home-page "https://github.com/littleglassdiode/irl")
    (synopsis "ASCII terminal roguelike game")
    (description
     "Rae Lives is a small C99 ncurses terminal roguelike.  This package
builds the fixed upstream revision directly from all of its C sources, keeps
the rebuilt executable private under @file{libexec}, and installs the
upstream MIT notice and project documentation.  The launcher provides an
isolated @option{--smoke} mode that drives the real game through a 24x80 PTY,
checks a legal movement and clean quit, and leaves no state in the package
output.  No bundled libraries, opaque binaries, test fixtures, build-time
downloads, or runtime network access are included.")
    (license license:expat)))
