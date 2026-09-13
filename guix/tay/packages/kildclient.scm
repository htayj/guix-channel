;;; GNU Guix package for KildClient, a GTK MUD client.

(define-module (tay packages kildclient)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls))

(define-public kildclient
  (package
    (name "kildclient")
    (version "3.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://sourceforge.net/projects/kildclient/files/kildclient/"
             version "/kildclient-" version ".tar.gz/download"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "18gw5yj8yh6yni7cz72yh9zl5mcqv3869lxs0bvisgcl0jx2j4z8"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-perl-path
            (lambda _
              (use-modules (guix build utils))
              ;; kildclient.pl is loaded by the installed client at startup,
              ;; and imports JSON from perl-json.  Keep that dependency in
              ;; the runtime closure and visible to the embedded Perl.
              (wrap-program
               (string-append #$output "/bin/kildclient")
               `("PERL5LIB" ":" prefix
                 (,(string-append #$perl-json "/lib/perl5/site_perl")))))))))
    (native-inputs
     (list (list "gettext-minimal" gettext-minimal)
           ;; glib-compile-resources is installed in GLib's bin output.
           (list "glib:bin" glib "bin")
           (list "pkg-config" pkg-config)))
    (inputs
     (list bash-minimal
           gnutls
           gtk+
           gtkspell3
           perl
           perl-json
           zlib))
    (synopsis "GTK MUD client with Perl scripting support")
    (description
     "KildClient is a MUD client using the GTK+ toolkit.  It supports Perl
scripting, triggers, gags, macros, aliases, timers, hooks, plugins, logging,
and several simultaneous worlds.  The package includes the upstream GTK
resources, plugins, help files, desktop entry, manual, and license notices.")
    (home-page "https://www.kildclient.org/")
    (license license:gpl2+)))
