;;; GNU Guix package for robotfindskitten.

(define-module (tay packages robotfindskitten)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages texinfo))

(define %robotfindskitten-smoke
  (local-file "robotfindskitten-smoke.py"))

(define-public robotfindskitten
  (package
    (name "robotfindskitten")
    (version "3.0000000.726")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://codeberg.org/robotfindskitten/robotfindskitten/archive/"
         "471872786ca3a40db5b53f7baf96233a3793c45d.tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 6be0c9bab746e8484e29b2033bb915a59880cc1205c9f4ec3a377c62ca6cd5e7
       (sha256
        (base32
         "1rymdk564z1p7bng9j852b6816552nwkn0xj5574is26nyxckq3b"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The release has no test programs, but Automake supplies a check
      ;; target.  Leave Guix's check phase enabled so that target is exercised.
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'bootstrap
            (lambda _
              ;; The source archive intentionally contains no generated
              ;; configure script or Makefiles.
              (invoke "autoreconf" "-vfi")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (doc (string-append out "/share/doc/robotfindskitten"))
                     (installed
                      (string-append out "/games/robotfindskitten"))
                     (real (string-append libexec "/robotfindskitten-real"))
                     (helper (string-append libexec
                                             "/robotfindskitten-smoke.py"))
                     (launcher (string-append bin "/robotfindskitten"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (terminfo (string-append #$ncurses "/share/terminfo")))
                ;; Let the upstream install rules place the complete runtime
                ;; set: NKI data, man/info documentation, desktop metadata,
                ;; and both icon formats.
                (invoke "make" "install")
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p doc)
                (rename-file installed real)
                (rmdir (string-append out "/games"))
                ;; Keep the complete upstream license and REUSE information
                ;; beside every installed code and data asset.
                (for-each
                 (lambda (file) (install-file file doc))
                 '("AUTHORS" "BUGS" "ChangeLog" "COPYING" "NEWS"
                   "README.md" "REUSE.toml"))
                (install-file "LICENSES/GPL-2.0-or-later.txt" doc)
                (copy-file #$%robotfindskitten-smoke helper)
                (chmod helper #o555)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port
                            "#!~a/bin/sh~%set -eu~%real=~s~%helper=~s~%"
                            #$bash-minimal real helper)
                    (format port "python=~s~%terminfo=~s~%"
                            python terminfo)
                    ;; Do not inherit host terminfo paths into the proof.
                    (display
                     "export TERMINFO_DIRS=\"$terminfo\"\n"
                     port)
                    (display
                     "if test \"${1-}\" = --guix-smoke; then\n"
                     port)
                    (format port
                            "  test \"$#\" -eq 1 || { echo '~a' >&2; exit 64; }\n"
                            "usage: robotfindskitten [--guix-smoke]")
                    (display
                     "  exec \"$python\" \"$helper\" \"$real\"\n"
                     port)
                    (display "fi\nexec \"$real\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; Autoconf, Automake, and Libtool are needed to regenerate the release's
    ;; missing build machinery.  Texinfo is needed by doc/Makefile.am's
    ;; info_TEXINFOS target; no gnulib or TeX Live target is referenced.
    (native-inputs (list autoconf automake libtool texinfo))
    ;; Python is used only by the package-owned proof mode.  The normal game
    ;; is the unmodified ncurses binary and performs no network access.
    (inputs (list bash-minimal ncurses python-minimal))
    (home-page "https://robotfindskitten.org/")
    (synopsis "Zen simulation of a robot finding kitten")
    (description
     "robotfindskitten is a meditative terminal game in which a robot moves
around a field of non-kitten items while searching for kitten.  This package
builds the fixed Codeberg release from source with the declared Autotools and
ncurses toolchain, installs its data, documentation, desktop metadata, and
icons, and keeps the real executable in @file{libexec}.  The
@option{--guix-smoke} launcher mode drives the real ncurses program through a
private Python PTY with isolated HOME and XDG directories; normal arguments
are passed through unchanged.  No build-time or runtime downloads are used.")
    (license license:gpl2+)))
