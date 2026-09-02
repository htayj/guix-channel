;;; GNU Guix package for Martin Read's Cave Chop 7DRL.

(define-module (tay packages cavechop)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define-public cavechop
  (package
    (name "cavechop")
    ;; The upstream Makefile declares MAJVERS=1 and MINVERS=0.  The fixed
    ;; snapshot is commit ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692, which is
    ;; both the last master revision and the bugfix-release-1 tag.
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri "http://git.blackswordsonics.com/?p=cavechop-7drl;a=snapshot;h=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692;sf=tgz")
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 6c16c18125ebd6b3fd56402c0dd2094abfd716b7515700da2050be4a908aef97
       (sha256
        (base32 "15zgia84mgjh43d00msinwbdggsa1790sb20avyv7mpb4n0w25kc"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream tree has no automated test target.  The installed
      ;; terminal game is exercised by tests/cavechop-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-compressor-paths
            (lambda _
              ;; Cave Chop invokes these tools with system(), so a PATH-only
              ;; wrapper would leave the installed binary dependent on the
              ;; caller's environment.  Use the declared Guix input directly.
              (substitute* "main.c"
                (("\"gzip cavechop.sav\"" )
                 (string-append "\"" #$gzip "/bin/gzip cavechop.sav\""))
                (("\"gunzip cavechop.sav\"" )
                 (string-append "\"" #$gzip "/bin/gunzip cavechop.sav\"")))))
          (replace 'build
            (lambda _
              (invoke "make" "all" "CC=gcc")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/cavechop"))
                     (program (string-append libexec "/cavechop"))
                     (launcher (string-append bin "/cavechop")))
                ;; Keep the real binary private to the state-isolating
                ;; launcher.  notes.txt is the complete upstream notice and
                ;; license for the executable produced from this source tree.
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "cavechop" libexec)
                (install-file "notes.txt" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%~%
real=~a~%
state=\"${XDG_STATE_HOME:-${HOME:?}/.local/state}/cavechop\"~%
~a/bin/mkdir -p \"$state\"~%
export PATH=\"~a/bin:~a/bin${PATH:+:$PATH}\"~%
export TERMINFO_DIRS=\"~a/share/terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%
if test \"${1-}\" = --smoke; then~%
  test \"$#\" -eq 1~%
  work=\"$state/smoke\"~%
  ~a/bin/mkdir -p \"$work\"~%
  cd \"$state\"~%
  printf 'Matilda\\n...Sx' | ~a/bin/script -qefc \"~a/bin/stty rows 24 cols 80; exec $real\" /dev/null >\"$work/first.raw\"~%
  test -s \"$state/cavechop.sav.gz\"~%
  first=\"$(~a/bin/cat \"$work/first.raw\")\"~%
  case \"$first\" in~%
    *\"Welcome to Cave Chop, Princess Matilda.\"*) ;;~%
    *) echo \"cavechop smoke: first transcript missing welcome\" >&2; exit 1 ;;~%
  esac~%
  printf 'i.XYx' | ~a/bin/script -qefc \"~a/bin/stty rows 24 cols 80; exec $real\" /dev/null >\"$work/load.raw\"~%
  test ! -e \"$state/cavechop.sav.gz\"~%
  second=\"$(~a/bin/cat \"$work/load.raw\")\"~%
  case \"$second\" in~%
    *\"Game loaded.\"*) ;;~%
    *) echo \"cavechop smoke: load transcript missing Game loaded\" >&2; exit 1 ;;~%
  esac~%
  case \"$second\" in~%
    *\"You are carrying:\"*) ;;~%
    *) echo \"cavechop smoke: inventory transcript missing\" >&2; exit 1 ;;~%
  esac~%
  printf '%s\\n' CAVECHOP_RUNTIME_OK~%
  exit 0~%
fi~%
cd \"$state\"~%
exec \"$real\" \"$@\"~%"
                            #$(file-append bash-minimal)
                            program
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append gzip "/bin")
                            #$(file-append coreutils-minimal "/bin")
                            #$(file-append ncurses)
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append util-linux "/bin/script")
                            #$(file-append coreutils-minimal "/bin/stty")
                            #$(file-append coreutils-minimal "/bin/cat")
                            #$(file-append util-linux "/bin/script")
                            #$(file-append coreutils-minimal "/bin/stty")
                            #$(file-append coreutils-minimal "/bin/cat")))
                (chmod launcher #o555))))))))
    ;; gcc-toolchain is explicit because the upstream Makefile compiles the
    ;; complete C source tree directly.  util-linux supplies script for the
    ;; package-owned --smoke PTY path.
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses util-linux))
    (home-page "http://git.blackswordsonics.com/?p=cavechop-7drl;a=summary")
    (synopsis "Seven-day roguelike dungeon game")
    (description
     "Cave Chop is a terminal seven-day roguelike by Martin Read.  This
package builds the fixed upstream source snapshot with GNU make and ncurses,
and keeps saves, logs, and character dumps under
@file{$XDG_STATE_HOME/cavechop}, falling back to
@file{$HOME/.local/state/cavechop}.  The package provides a wrapper-owned
@option{--smoke} mode that exercises an isolated terminal save and load.  It
performs no build-time or runtime downloads.")
    (license license:bsd-2)))
