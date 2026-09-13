;;; GNU Guix package for larsbrinkhoff/kbredir.

(define-module (tay packages kbredir)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages larsbrinkhoff-g-m))

(define-public kbredir
  (package
    (name "kbredir")
    ;; Upstream has no release tag.  configure.in declares 0.9 at the sole
    ;; commit in its master history, so retain that upstream version without
    ;; inventing a Guix revision.
    (version "0.9")
    ;; Retain the channel's reviewed codeload origin, including its fixed
    ;; commit and content hash, rather than introducing a second fetch.
    (source
     (origin
       (inherit (package-source larsbrinkhoff-kbredir-source))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream check target only rebuilds the six command-line tools;
      ;; exercising a reader would require changing a real console tty.
      #:tests? #f
      ;; The 2000-era source intentionally relies on GNU C89's declarations
      ;; for a few libc functions.  Keep its supported language mode explicit
      ;; as current GCC defaults advance beyond it.
      #:configure-flags #~(list "CFLAGS=-std=gnu89 -O2 -W -Wall -fomit-frame-pointer")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'patch-legacy-x11-library-path
            (lambda _
              ;; This Autotools-era path does not exist in Guix.  Configure
              ;; regenerates src/Makefile from Makefile.in, and patching the
              ;; checked-in Makefile as well keeps the source tree coherent.
              (substitute* '("src/Makefile.in" "src/Makefile")
                (("-L/usr/X11R6/lib ") ""))))
          (add-after 'install 'install-license
            (lambda _
              (install-file "COPYING"
                            (string-append #$output "/share/doc/kbredir")))))))
    (inputs
     (list libx11 libxtst linux-libre-headers))
    (synopsis "Redirect keyboard events between terminal and X11 protocols")
    (description
     "Kbredir provides small command-line tools that translate its line-based
@code{<key> down}/@code{<key> up} protocol between VT220 input or output,
Linux console raw-keyboard input, xev output, and X11 XSendEvent or XTEST
output.  @command{write_xtest} and @command{write_xsendevent} require an
authorized X display, optionally selected with @option{--display} and
@option{--window}.  @command{read_linux_console} reads standard input as its
controlling console tty, changes it to @code{K_MEDIUMRAW}, and can activate a
virtual terminal; it must never be used on an unintended terminal.  The
package installs no privilege escalation, device rules, service, or runtime
wrapper.  It builds solely from the pinned upstream C source using Guix's X11,
XTEST, and Linux kernel-header inputs.  The upstream GPL-2.0-only license is
installed under @file{share/doc/kbredir}.")
    (home-page "https://github.com/larsbrinkhoff/kbredir")
    (license (package-license larsbrinkhoff-kbredir-source))))
