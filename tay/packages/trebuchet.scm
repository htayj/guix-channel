;;; GNU Guix package for the Trebuchet Tk MUD client.

(define-module (tay packages trebuchet)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages tcl)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:))

(define-public trebuchet
  (package
    (name "trebuchet")
    ;; The upstream project has no release newer than v1081.  Master carries
    ;; the next revision number in Trebuchet.tcl, so retain that revision while
    ;; pinning the complete commit below.
    (version "1082")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/fuzzball-muck/trebuchet")
             (commit "1418ab604d870c154887adf2b0b6c8ec91457abe")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "138d5p4pmhgdnmgzn2fsmwvnj5a1sv8a32z6z4kdlqg4cy3x12n6"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Trebuchet is a Tcl/Tk source tree with no compilation step.  Keep the
      ;; complete tree, including its bundled images, CA bundle, help files,
      ;; and license notices, under a private runtime root.
      #:install-plan
      #~'(("." "libexec/trebuchet/"))
      #:phases
      #~(modify-phases %standard-phases
          ;; The source contains an intentionally portable "exec wish"
          ;; launcher and historical helper scripts.  Do not rewrite their
          ;; shebangs with build-time store paths; the installed command below
          ;; invokes the Guix Tk runtime directly.
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (delete 'patch-shebangs)
          (delete 'strip)
          (delete 'make-dynamic-linker-cache)
          (delete 'compress-documentation)
          (add-after 'unpack 'check-tcl-syntax
            (lambda _
              (use-modules (guix build utils))
              ;; The upstream Makefile's historical procheck dependency is
              ;; unavailable and would be an unnecessary network/build
              ;; input.  Tcl's parser still provides a useful offline check
              ;; for every application and library script.  The native Tcl
              ;; input is first on PATH in the build environment.
              (call-with-output-file "trebuchet-syntax-check.tcl"
                (lambda (port)
                  (display
                   (string-append
                    "set files [concat [glob -nocomplain -- *.tcl] "
                    "[glob -nocomplain -- lib/*.tcl]]\n")
                   port)
                  (display "set failed 0\n" port)
                  (display
                   (string-append
                    "foreach file $files {\n"
                    "  set fd [open $file r]\n"
                    "  set contents [read $fd]\n"
                    "  close $fd\n"
                    "  if {![info complete $contents]} {\n"
                    "    puts stderr [format {incomplete Tcl source: %s} "
                    "$file]\n"
                    "    set failed 1\n"
                    "  }\n"
                    "}\n")
                   port)
                  (display "exit $failed\n" port)))
              (invoke "tclsh" "trebuchet-syntax-check.tcl")
              (delete-file "trebuchet-syntax-check.tcl")))
          (add-after 'unpack 'harden-networking
            (lambda _
              (use-modules (guix build utils))
              ;; Keep the local control socket private to the local machine.
              ;; The original wildcard listener is unnecessary for the
              ;; launcher-to-client handoff and would expose a command socket.
              (substitute* "lib/remote.tcl"
                (("socket -server remote:connect \\$remote_port")
                 "socket -server remote:connect -myaddr 127.0.0.1 $remote_port")
                (("socket -async localhost \\$remote_port")
                 "socket -async 127.0.0.1 $remote_port"))
              ;; Do not trust the stale CA bundle shipped in the 2019 source
              ;; snapshot.  Use Guix's current, package-owned trust store for
              ;; both direct TLS and STARTTLS imports.
              (let ((cafile (string-append #$nss-certs
                                           "/etc/ssl/certs/ca-certificates.crt")))
                (substitute* "Trebuchet.tcl"
                  (("set cafile [^[:cntrl:]]*ca-bundle\\.crt[^[:cntrl:]]*")
                   (format #f "set cafile ~s" cafile))
                  (("-cafile \\$cafile -cadir \\$treb_cacerts_dir")
                   "-cafile $cafile")
                  ;; The historical -tls1 1 switch restricts OpenSSL to
                  ;; obsolete TLS 1.0 and prevents modern handshakes.
                  (("-tls1 1") "-tls1 0"))
                (substitute* "lib/secsupp.tcl"
                  (("-cadir \\$treb_cacerts_dir")
                   (format #f "-cafile ~s" cafile))
                  (("-tls1 1") "-tls1 0")
                  ;; Verification callbacks must fail closed for every
                  ;; non-success return code.  Keep the historical diagnostic
                  ;; switch below for provenance, but never reach its old
                  ;; permissive branches.
                  (("puts stderr \\$err")
                   "puts stderr $err\n                return 0")
                  ;; STARTTLS negotiation must never strip TLS and continue as
                  ;; plaintext after a handshake error.  Disable the old
                  ;; unimport/reconnect branch; its else arm disconnects.
                  (("if \\{\\[info commands ::tls::unimport\\] != \"\"\\} \\{")
                   "if {0} {")
                  (("tls::unimport \\$sok")
                   "# TLS remains imported after a failed handshake")
                  (("catch \\{/socket:connect \\$world 1\\}")
                   "# TLS failure: do not reconnect in plaintext" )
                  (("Falling back to unencrypted link\\.")
                   "Closing connection.")
                  (("Reconnecting with unencrypted link\\.")
                   "Closing connection.")
                  ;; Never turn a certificate validation error into an
                  ;; interactive trust decision.  The original function's
                  ;; remaining body is retained for source provenance, but
                  ;; this package policy returns rejection before it runs.
                  (("proc tls_error_query \\{world errtxt cert\\} \\{")
                   (string-append
                    "proc tls_error_query {world errtxt cert} {\n"
                    "    return \"no\"\n"
                    "    # Original interactive policy follows.\n"))))))
          (add-after 'install 'install-launcher
            (lambda _
              (use-modules (guix build utils))
              (let ((launcher (string-append #$output "/bin/treb")))
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port
                            "exec ~a/bin/wish ~a/libexec/trebuchet/Trebuchet.tcl \"$@\"~%"
                            #$tk #$output)))
                (chmod launcher #o555)
                ;; Tcl's package search path is a Tcl list (space-separated),
                ;; not a PATH-like colon list.  Include both required
                ;; tcllib/OptProc and optional TLS extension directories while
                ;; retaining any user-provided entries.
                (wrap-program launcher
                  `("TCLLIBPATH" " " prefix
                    (,(string-append #$tcllib "/lib/tcllib"
                                     #$(package-version tcllib))
                     ,(string-append #$tcl-tls "/lib/tcltls"
                                     #$(package-version tcl-tls)))))))))))
    (native-inputs
     (list tcl))
    (inputs
     (list bash-minimal
           tcllib
           tcl-tls
           tk))
    (synopsis "Tcl/Tk graphical MUD client")
    (description
     "Trebuchet is a graphical MUD, MUCK, and MUSH client written in Tcl/Tk.
It supports multiple simultaneous worlds, Telnet and optional TLS
connections, MCP/GUI requests, triggers, macros, logging, command history,
and user-authored Tcl scripts.  The package installs the complete upstream
runtime tree, including its help files, bundled CA bundle, images, and
license notices, under @file{libexec/trebuchet}.  The @command{treb}
launcher supplies Guix's Tk interpreter and Tcl library search paths;
profiles, logs, maps, plugins, and preferences remain in the user's home
directory rather than the store.  Builds and the package's Tcl syntax check
are offline and do not contact a MUD server.")
    (home-page "https://github.com/fuzzball-muck/trebuchet")
    ;; The main client is GPL-2.0-or-later.  The complete source tree also
    ;; retains LGPL-2.0-or-later library notices and public-domain widgets.
    (license (list license:gpl2+
                   license:lgpl2.0+
                   license:public-domain))))
