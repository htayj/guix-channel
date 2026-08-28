;;; GNU Guix package for atsb/freelarn.

(define-module (tay packages freelarn)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses)
  #:use-module (tay packages starred-a-c))

;; No upstream release tags exist.  This is the canonical upstream commit from
;; 2022-07-25, retained as the fixed codeload origin in starred-a-c.scm.
(define %freelarn-version "0-8cd18cb")

(define-public freelarn
  (package
    (name "freelarn")
    (version %freelarn-version)
    (source (package-source atsb-freelarn-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;the upstream tree has no test target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; The upstream GNU makefile compiles all C++ sources directly.
              ;; Its warning policy predates supported GCC and Clang versions,
              ;; so retain its portability flags but do not make warnings fatal.
              (invoke "make"
                      "CC_FLAGS=-std=c++11 -Winline -fno-elide-constructors -pipe -Wall -pedantic-errors -Wpointer-arith -Woverloaded-virtual -Wshadow -Wmissing-declarations -fomit-frame-pointer -DNIX_LOCAL")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (libexec (string-append out "/libexec"))
                     (documentation (string-append out "/share/doc/freelarn"))
                     (documentation-history
                      (string-append documentation "/docs"))
                     (program (string-append libexec "/freelarn"))
                     (wrapper (string-append out "/bin/freelarn")))
                (mkdir-p libexec)
                (install-file "bin/freelarn" libexec)
                (mkdir-p documentation)
                ;; Keep the complete license and the upstream historical notices
                ;; alongside the installed executable.  bin/stub is deliberately
                ;; not installed: it is not the game executable.
                (for-each (lambda (file) (install-file file documentation))
                          '("LICENSE" "README.md"))
                (mkdir-p documentation-history)
                (for-each (lambda (file)
                            (install-file file documentation-history))
                          '("docs/LICENSE" "docs/HISTORY" "docs/CHANGELOG"))
                (mkdir-p (dirname wrapper))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~
state=\"${XDG_STATE_HOME:-$HOME/.local/state}/freelarn\"~%
~a -p \"$state\"~%
cd \"$state\"~%
exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/bash")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            program)))
                (chmod wrapper #o555)))))))
    ;; Ncurses is FreeLarn's only compiled library.  Bash and minimal Coreutils
    ;; are explicit runtime references of the state-isolating launcher.
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://github.com/atsb/freelarn")
    (synopsis "C++11 descendant of the Larn dungeon game")
    (description
     "FreeLarn is a C++11 descendant of the classic Larn dungeon game.  It is
built from a fixed upstream source archive with no build-time or runtime
downloads.  The launcher keeps saves, scores, and message logs under the
user's XDG state directory, rather than writing to the immutable Guix store or
the caller's current directory.")
    (license license:asl2.0)))
