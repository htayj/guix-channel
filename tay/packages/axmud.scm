;;; GNU Guix package for Axmud, a Perl/Gtk3 MUD client.

(define-module (tay packages axmud)
  #:use-module (guix build-system perl)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages perl-compression)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages web))

;; Guix 1.5 does not provide these four CPAN prerequisites.  They remain
;; private to Axmud so that building the package never invokes CPAN.  Each
;; source's README is installed as its license notice: two older releases
;; declare the license only there, rather than in CPAN metadata.
(define perl-goocanvas2
  (package
    (name "perl-goocanvas2")
    (version "0.06")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "mirror://cpan/authors/id/P/PE/PERLMAX/GooCanvas2-"
             version ".tar.gz"))
       (sha256
        (base32
         "0l1vsvyv9hjxhsxrahq4h64axh7qmk50kiz2spa3s1hr7s3qfk72"))))
    (build-system perl-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/perl-goocanvas2")))
                (mkdir-p doc)
                (install-file "README" doc)))))))
    (propagated-inputs (list goocanvas perl-gtk3))
    (synopsis "Perl binding for the GooCanvas2 widget")
    (description
     "GooCanvas2 provides Perl bindings for the GooCanvas2 widget through
GObject introspection.")
    (home-page "https://metacpan.org/release/GooCanvas2")
    (license license:perl-license)))

(define perl-module-load
  (package
    (name "perl-module-load")
    (version "0.36")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "mirror://cpan/authors/id/B/BI/BINGOS/Module-Load-"
             version ".tar.gz"))
       (sha256
        (base32
         "1q7nprvnc0p470cwks6a5w3qnhzr73c28kjjz64hw8hbq05049fq"))))
    (build-system perl-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/perl-module-load")))
                (mkdir-p doc)
                (install-file "README" doc)))))))
    (synopsis "Load Perl modules in a DWIM style")
    (description
     "Module::Load provides a simple interface for loading Perl modules.")
    (home-page "https://metacpan.org/release/Module-Load")
    (license license:perl-license)))

(define perl-net-openssh
  (package
    (name "perl-net-openssh")
    (version "0.84")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "mirror://cpan/authors/id/S/SA/SALVA/Net-OpenSSH-"
             version ".tar.gz"))
       (sha256
        (base32
         "1y1r2mwvq6n93zllpgik481rp57l9z4hbdww7js0vkxi04pyd047"))))
    (build-system perl-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/perl-net-openssh")))
                (mkdir-p doc)
                (install-file "README" doc)))))))
    (synopsis "Perl SSH client built on OpenSSH")
    (description
     "Net::OpenSSH is a Perl SSH client implemented on top of OpenSSH.")
    (home-page "https://metacpan.org/release/Net-OpenSSH")
    (license license:perl-license)))

(define perl-regexp-ipv6
  (package
    (name "perl-regexp-ipv6")
    (version "0.03")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "mirror://cpan/authors/id/S/SA/SALVA/Regexp-IPv6-"
             version ".tar.gz"))
       (sha256
        (base32
         "1qicf4k3m1x34w6lmk89qiasfn0b1vd5c8dsx0fn74yffmyx2hnm"))))
    (build-system perl-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notice
            (lambda _
              (let ((doc (string-append #$output
                                        "/share/doc/perl-regexp-ipv6")))
                (mkdir-p doc)
                (install-file "README" doc)))))))
    (synopsis "Regular expression for IPv6 addresses")
    (description
     "Regexp::IPv6 provides a regular expression for IPv6 addresses.")
    (home-page "https://metacpan.org/release/Regexp-IPv6")
    (license license:perl-license)))

(define-public axmud
  (package
    (name "axmud")
    (version "2.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             ;; GitHub permanently redirects its web URL with a .git suffix.
             (url "https://github.com/axcore/axmud")
             ;; v2.0.0 resolves to this release commit.  Pin the commit, not
             ;; the mutable tag name.
             (commit "3dbbd963baa9555c10a0c7ae3e4b007f53f6585a")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1l1nvv23ifkj5nqyacz0qpzlqiyjydsg87qj3nf6c0xwgwiw368w"))))
    (build-system perl-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'disable-mxp-remote-media-by-default
            (lambda _
              ;; MXP content can request network downloads.  Retain Axmud's
              ;; per-profile preference, but default both download capabilities
              ;; to false so a user must explicitly opt in.
              (substitute* "lib/Games/Axmud/Client.pm"
                (("allowMxpLoadImageFlag[[:space:]]*=>[[:space:]]*TRUE")
                 "allowMxpLoadImageFlag       => FALSE")
                (("allowMxpLoadSoundFlag[[:space:]]*=>[[:space:]]*TRUE")
                 "allowMxpLoadSoundFlag       => FALSE"))
              (invoke "grep" "-F"
                      "allowMxpLoadImageFlag       => FALSE"
                      "lib/Games/Axmud/Client.pm")
              (invoke "grep" "-F"
                      "allowMxpLoadSoundFlag       => FALSE"
                      "lib/Games/Axmud/Client.pm")))
          (add-after 'install 'install-documentation-and-license-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/axmud")))
                (mkdir-p doc)
                ;; COPYING is GPL-3.0-or-later; COPYING.LESSER and the
                ;; component notices below retain the source's mixed-media
                ;; attribution record.
                (for-each (lambda (file) (install-file file doc))
                          '("AUTHORS" "CHANGES" "COPYING" "COPYING.LESSER"
                            "README.rst" "META.json"))
                (copy-recursively "share/docs/COPYING"
                                  (string-append doc "/docs-COPYING"))
                (copy-recursively "share/help/COPYING"
                                  (string-append doc "/help-COPYING"))
                (copy-recursively "share/icons/COPYING"
                                  (string-append doc "/icons-COPYING"))
                (copy-recursively "share/images/COPYING"
                                  (string-append doc "/images-COPYING"))
                (copy-recursively "share/items/sounds/COPYING"
                                  (string-append doc "/sounds-COPYING")))))
          (add-after 'install-documentation-and-license-notices
              'wrap-launchers
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The executable is launched directly from the store, so it
              ;; must not rely on a user profile to populate PERL5LIB.  The
              ;; complete input set includes propagated Perl prerequisites;
              ;; harmless non-Perl entries simply contribute nonexistent
              ;; search directories.
              (let ((perl5lib
                     (cons (string-append #$output "/lib/perl5/site_perl")
                           (map (lambda (input)
                                  (string-append (cdr input)
                                                 "/lib/perl5/site_perl"))
                                inputs)))
                    (typelib-path
                     (map (lambda (input)
                            (string-append (cdr input)
                                           "/lib/girepository-1.0"))
                          inputs)))
                (for-each
                 (lambda (program)
                   (wrap-program (string-append #$output "/bin/" program)
                     `("PERL5LIB" ":" prefix ,perl5lib)
                     `("GI_TYPELIB_PATH" ":" prefix ,typelib-path)
                     `("PATH" ":" prefix
                       ,(list (string-append #$openssh "/bin")))))
                 '("axmud.pl" "baxmud.pl"))))))))
    (native-inputs
     (list perl-path-tiny))
    (inputs
     (list bash-minimal
           openssh
           perl-archive-extract
           perl-archive-zip
           perl-file-copy-recursive
           perl-file-homedir
           perl-file-sharedir
           perl-file-sharedir-install
           perl-glib
           perl-goocanvas2
           perl-gtk3
           perl-io-socket-ssl
           perl-ipc-run
           perl-json
           perl-math-round
           perl-module-load
           perl-net-openssh
           perl-regexp-ipv6))
    (synopsis "Graphical MUD client written in Perl and GTK3")
    (description
     "Axmud is a graphical Multi-User Dungeon client written in Perl and
Gtk3.  It supports Telnet, SSH and TLS connections; ANSI, xterm and RGB
colour; MXP and GMCP; triggers, aliases, timers, scripts and an automapper.
The installed program and supplied resources are immutable.  On first run it
creates profiles, logs, maps, scripts and optional plugin state below
@file{$HOME/axmud-data}; bundled plugins are not loaded unless the user's
state explicitly requests them.  Network downloads are available only through
explicit client commands, never during the build or initial startup.")
    (home-page "https://github.com/axcore/axmud")
    ;; The executable/client implementation is GPL-3.0-or-later.  Shared
    ;; Games::Axmud/Axbasic code and the modified Telnet object are
    ;; LGPL-3.0-or-later; the bundled docs/help are GFDL-1.3-or-later,
    ;; icons CC-BY-3.0, viewer image CC-BY-2.0 and sounds public domain.
    ;; Their notices are retained under share/doc/axmud.
    (license (list license:gpl3+ license:lgpl3+ license:fdl1.3+
                   license:cc-by3.0 license:cc-by2.0 license:public-domain))))
