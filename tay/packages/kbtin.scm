;;; GNU Guix package for KBtin, a terminal MUD client.

(define-module (tay packages kbtin)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls))

(define-public kbtin
  (package
    (name "kbtin")
    ;; There is no upstream release tag.  This is the commit date of the
    ;; immutable master commit below; the full commit remains in the source
    ;; reference for unambiguous updates.
    (version "0-20260801")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/kilobyte/kbtin")
             (commit "9151634296e0591d918a4fd39e743fb9bef68f16")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "09q0kr230sr6inv76rwj9xisxsvwzjc9icyq9ymn54043jil0qyz"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; git-fetch removes .git from the fixed-output checkout.  Populate the
      ;; tracked VERSION file so --version and the in-client version command
      ;; identify this package instead of reporting the source fallback
      ;; "UNKNOWN".
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'install-ca-bundle
            (lambda _
              (use-modules (guix build utils)
                           (rnrs io ports))
              ;; Guix's nss-certs output contains the Mozilla roots as
              ;; individual PEM files.  Assemble the deterministic bundle
              ;; into this package's output so the client does not depend on
              ;; an absent /etc/ssl hierarchy at runtime.
              (let* ((nss #$nss-certs)
                     (certs (find-files (string-append nss "/etc/ssl/certs")
                                        "\\.pem$"))
                     (bundle (string-append #$output
                                            "/etc/ssl/certs/"
                                            "ca-certificates.crt")))
                (mkdir-p (dirname bundle))
                (call-with-output-file bundle
                  (lambda (port)
                    (for-each
                     (lambda (file)
                       (call-with-input-file file
                         (lambda (input)
                           (display (get-string-all input) port)
                           (newline port))))
                     certs))))))
          (add-before 'configure 'patch-tls-trust
            (lambda _
              ;; Load the package-owned Mozilla bundle explicitly.  An
              ;; optional SSL_CERT_FILE is additive, allowing administrators
              ;; and the offline smoke test to add a private CA without
              ;; replacing the packaged public roots.
              (substitute* "ssl.cc"
                (("gnutls_certificate_set_x509_system_trust\\(ssl_cred\\)")
                 (string-append
                  "gnutls_certificate_set_x509_trust_file(ssl_cred, \""
                  #$output
                  "/etc/ssl/certs/ca-certificates.crt\", "
                  "GNUTLS_X509_FMT_PEM)"))
                (("tintin_eprintf.*can't find system CAs.*gnutls_strerror.*")
                 (string-append
                  "tintin_eprintf(oldses, \"#Warning: can't find system CAs: %s\", "
                  "gnutls_strerror(ret));\n"
                  "        const char *extra_ca = getenv(\"SSL_CERT_FILE\");\n"
                  "        if (extra_ca && *extra_ca\n"
                  "            && (ret = gnutls_certificate_set_x509_trust_file(\n"
                  "                ssl_cred, extra_ca, GNUTLS_X509_FMT_PEM)) < 0)\n"
                  "            tintin_eprintf(oldses, "
                  "\"#Warning: can't find extra CA file: %s\",\n"
                  "                gnutls_strerror(ret));")))))
          (add-before 'configure 'patch-shell-path
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The upstream #system/#run implementation hard-codes the
              ;; Filesystem Hierarchy Standard shell path.  Guix's build and
              ;; runtime environments do not provide /bin/sh; use the
              ;; declared Bash input instead.
              (let ((bash (assoc-ref inputs "bash-minimal")))
                (substitute* "run.cc"
                  (("/bin/sh")
                   (string-append bash "/bin/sh"))))))
          (add-before 'configure 'set-release-version
            (lambda _
              (call-with-output-file "VERSION"
                (lambda (port)
                  (display #$version port)
                  (newline port)))))
          (add-after 'install 'install-documentation
            (lambda _
              (use-modules (guix build utils))
              (let ((doc (string-append #$output "/share/doc/kbtin")))
                (mkdir-p doc)
                ;; Install the complete upstream notices and accompanying
                ;; project documentation; the source's COPYING is GPL-2.0
                ;; only, while small historical source snippets retain their
                ;; own notices in the distributed source tree.
                (for-each (lambda (file) (install-file file doc))
                          (map (lambda (file) (string-append "../source/" file))
                               '("COPYING" "AUTHORS" "BUGS" "ChangeLog" "FAQ"
                                 "KEYPAD" "OLDNEWS" "README.md")))))))
      #:configure-flags
      #~(list
         ;; Build the protocol compression and native GnuTLS support that the
         ;; upstream CMake project provides.  SIMD is optional and is kept off
         ;; explicitly so no host hyperscan installation changes the result.
         "-DMCCP=ON"
         "-DSSL=ON"
         "-DSIMD=OFF"
         "-DCMAKE_INSTALL_DOCDIR=share/doc/kbtin")))
    (native-inputs
     (list coreutils perl pkg-config which))
    (inputs
     (list bash-minimal gnutls zlib))
    (synopsis "TinTin-compatible terminal MUD client")
    (description
     "KBtin is a TinTin-compatible terminal client for MUD servers.  It
supports aliases, actions, substitutions, highlights, shortest-path routing,
TELNET, MCCP compression, UTF-8 and IPv6, and native TLS through GnuTLS.  The
package builds the upstream CMake project offline with Guix-provided zlib and
GnuTLS; mutable profiles, logs, certificates, and scripts remain in
caller-selected directories outside the store.  A package-owned Mozilla CA
bundle is used for TLS verification, with @env{SSL_CERT_FILE} available for
an additive private CA.  The upstream GPL-2.0-only
license and project notices are installed under @file{share/doc/kbtin}.")
    (home-page "https://github.com/kilobyte/kbtin")
    (license license:gpl2)))
