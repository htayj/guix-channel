;;; SUPPTY host client at the channel's audited immutable source revision.

(define-module (tay packages suppty)
  #:use-module (tay packages pdp10-n-s)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xorg))

(define-public pdp10-suppty
  (package
    (name "pdp10-suppty")
    (version (package-version pdp10-suppty-source))
    (source (package-source pdp10-suppty-source))
    (build-system gnu-build-system)
    (native-inputs (list autoconf automake halibut perl pkg-config))
    (inputs (list gtk+-2 libx11 mit-krb5))
    (arguments
     (list
      #:tests? #f                       ;Upstream has no check target.
      #:configure-flags #~(list "--with-gtk=2")
      ;; GTK 2 exposes deprecated APIs used by this original client.
      #:make-flags #~(list "WARNINGOPTS=-Wall")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'complete-supdup-build-recipe
            (lambda _
              ;; The backend is registered upstream but omitted from Recipe.
              ;; Regenerate every Unix object list rather than editing the
              ;; generated Makefile.am, which also lacks supdup.c.
              (substitute* "Recipe"
                (("NONSSH   = telnet raw rlogin ldisc pinger")
                 "NONSSH   = telnet raw rlogin ldisc pinger supdup"))
              ;; ldisc_send owns its terminal through Ldisc, unlike
              ;; ldisc_create's local parameter.  CLI ldiscs have no terminal
              ;; and only receive updates, never terminal input/echo.
              (substitute* "ldisc.c"
                (("if \\(term->supdup_mode\\)")
                 "if (ldisc->term && ldisc->term->supdup_mode)"))
              ;; The ITS/WAITS translator reads per-terminal charset state;
              ;; its sole caller already has the required terminal context.
              (substitute* "terminal.c"
                (("translate_supdup_extended_ascii\\(unsigned long in\\)")
                 "translate_supdup_extended_ascii(Terminal *term, unsigned long in)")
                (("translate_supdup_extended_ascii\\(c\\)")
                 "translate_supdup_extended_ascii(term, c)"))
              (substitute* "unix/uxplink.c"
                (("Usage: plink") "Usage: suppty-plink")
                (("\"plink:") "\"suppty-plink:"))
              (substitute* "unix/gtkwin.c"
                (("pterm option summary:") "suppty option summary:"))
              ;; Keep GSSAPI available with a store-resolved runtime library.
              (substitute* "unix/uxgss.c"
                (("\"libgssapi_krb5.so.2\"")
                 (string-append "\"" #$mit-krb5
                                "/lib/libgssapi_krb5.so.2\"")))))
          (replace 'bootstrap
            (lambda _
              ;; Perl 5.26 removed '.' from @INC.  mkfiles.pl changes into
              ;; charset and requires sbcsgen.pl; without this include path
              ;; its swallowed error leaves cwd there during source scanning.
              (invoke "perl" "-I." "mkfiles.pl")
              (invoke "sh" "mkauto.sh")))
          (replace 'build
            (lambda* (#:key make-flags parallel-build? #:allow-other-keys)
              (apply invoke "make" "putty" "plink"
                     (string-append "-j" (if parallel-build?
                                              (number->string (parallel-job-count))
                                              "1"))
                     make-flags)
              (invoke "make" "-C" "doc" "putty.1" "plink.1")))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (man (string-append #$output "/share/man/man1"))
                    (doc (string-append #$output "/share/doc/pdp10-suppty-"
                                        #$(package-version pdp10-suppty-source))))
                (mkdir-p bin)
                (mkdir-p man)
                ;; Only the host terminal client and its genuine command-line
                ;; frontend are installed, never PuTTY's colliding names or
                ;; unrelated file-transfer/key-generation programs.
                (copy-file "putty" (string-append bin "/suppty"))
                (copy-file "plink" (string-append bin "/suppty-plink"))
                (chmod (string-append bin "/suppty") #o755)
                (chmod (string-append bin "/suppty-plink") #o755)
                (substitute* "doc/putty.1" (("putty") "suppty"))
                (substitute* "doc/plink.1" (("plink") "suppty-plink"))
                (copy-file "doc/putty.1" (string-append man "/suppty.1"))
                (copy-file "doc/plink.1" (string-append man "/suppty-plink.1"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENCE" "README"))))))))
    (synopsis "SUPDUP-capable graphical and command-line host client")
    (description
     "SUPPTY extends the original PuTTY host terminal client with the SUPDUP
protocol and ITS/WAITS character sets.  The GTK 2 client is installed as
@command{suppty}, and its original command-line frontend as
@command{suppty-plink}, avoiding command and manual-page collisions with PuTTY.
The original SSH, Telnet, rlogin, raw TCP, serial, session configuration, proxy,
and terminal functionality remains available.  For command-line SUPDUP, use
@code{suppty-plink supdup,HOST}, or load a saved SUPDUP session.  The graphical
client provides SUPDUP terminal rendering; Plink forwards the protocol's display
bytes without terminal emulation.  No guest software or public service is
included.")
    (home-page "https://github.com/PDP-10/SUPPTY")
    ;; Pinned root LICENCE is MIT/Expat; README explicitly points to it.
    (license license:expat)))
