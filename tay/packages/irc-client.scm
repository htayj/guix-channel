;;; GNU Guix package for johnelse/ocaml-irc-client.

(define-module (tay packages irc-client)
  #:use-module (guix build-system dune)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages ocaml))

;; This is the commit containing the irc-client.0.7.1 release, followed only
;; by the README update in the upstream main branch.  Use GitHub's codeload
;; endpoint rather than a moving branch or an opam download.
(define %irc-client-commit
  "d6f8b2a2e044bf36cc77edaf2ca261facd950d98")

(define %irc-client-version
  (git-version "0.7.1" "1" %irc-client-commit))

(define %irc-client-source
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/johnelse/ocaml-irc-client/tar.gz/"
                        %irc-client-commit))
    (file-name (string-append "ocaml-irc-client-" %irc-client-version ".tar.gz"))
    ;; This is also recorded by the channel's immutable source-snapshot
    ;; package for the same canonical origin and commit.
    (sha256
     (base32 "0a7zpm1h25lvx14xb5xdyaaxc2hhlxfbrmqzjsqr422d92g2r6c8"))))

(define (irc-client-common-phases documentation-name)
  #~(modify-phases %standard-phases
      (add-after 'install 'install-upstream-notices
        (lambda _
          (let ((documentation
                 (string-append #$output "/share/doc/" #$documentation-name)))
            (mkdir-p documentation)
            (install-file "LICENSE" documentation)
            (install-file "README.md" documentation))))))

(define* (make-irc-client-package name dune-package synopsis description
                                   propagated-inputs
                                   #:key (native-inputs '()))
  (package
    (name name)
    (version %irc-client-version)
    (source %irc-client-source)
    (build-system dune-build-system)
    (arguments
     (list
      #:package dune-package
      #:phases (irc-client-common-phases "ocaml-irc-client")))
    (propagated-inputs propagated-inputs)
    (native-inputs native-inputs)
    (synopsis synopsis)
    (description description)
    (home-page "https://github.com/johnelse/ocaml-irc-client")
    (license license:expat)))

(define-public ocaml-irc-client
  (make-irc-client-package
   "ocaml-irc-client"
   "irc-client"
   "IRC client library core"
   "This package provides the transport-independent core of the OCaml IRC
client library.  It parses and formats IRC messages and exposes a functor for
implementing blocking or cooperative transports.  The source is pinned to the
upstream irc-client.0.7.1 release commit and builds without opam or network
access."
   (list ocaml-base64 ocaml-logs ocaml-result)
   #:native-inputs (list ocaml-ounit)))

(define-public ocaml-irc-client-unix
  (make-irc-client-package
   "ocaml-irc-client-unix"
   "irc-client-unix"
   "Unix blocking I/O backend for the OCaml IRC client"
   "This package provides the Unix blocking-I/O backend for the OCaml IRC
client library.  It extends the core irc-client package with Unix sockets and
keeps runtime state in the caller's environment."
   (list ocaml-irc-client)))

(define-public ocaml-irc-client-lwt
  (make-irc-client-package
   "ocaml-irc-client-lwt"
   "irc-client-lwt"
   "Lwt backend for the OCaml IRC client"
   "This package provides the cooperative Lwt backend for the OCaml IRC
client library.  It depends only on the core library and Guix's Lwt runtime."
   (list ocaml-irc-client ocaml-lwt)))

;; Guix currently provides the OpenSSL bindings but not the small lwt_ssl
;; adapter.  Package that adapter from its released source so the upstream
;; irc-client-lwt-ssl library remains source-built and does not resolve an
;; opam dependency at build time.
(define-public ocaml-lwt-ssl
  (package
    (name "ocaml-lwt-ssl")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ocsigen/lwt_ssl/releases/download/"
             version "/lwt_ssl-" version ".tbz"))
       (sha256
        (base32 "0xwsi140ahap2d8ncc443ycvmjvdnc40lx7jqghpgwzcgb90l0mk"))))
    (build-system dune-build-system)
    (arguments
     (list
      #:package "lwt_ssl"
      ;; lwt_ssl has no test target in its release archive.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-upstream-notice
            (lambda _
              (let ((documentation
                     (string-append #$output "/share/doc/ocaml-lwt-ssl")))
                (mkdir-p documentation)
                (install-file "COPYING" documentation)
                (install-file "README.md" documentation)))))))
    (propagated-inputs (list ocaml-lwt ocaml-ssl))
    (home-page "https://github.com/ocsigen/lwt_ssl")
    (synopsis "OpenSSL binding with concurrent Lwt I/O")
    (description
     "Lwt_ssl provides the concurrent Lwt adapter for OCaml's OpenSSL
bindings.  It is built from the upstream release archive without opam or
network access during the build.")
    ;; The upstream COPYING is LGPL-2.1 with an OpenSSL linking exception.
    (license license:lgpl2.1)))

(define-public ocaml-irc-client-lwt-ssl
  (make-irc-client-package
   "ocaml-irc-client-lwt-ssl"
   "irc-client-lwt-ssl"
   "Lwt OpenSSL backend for the OCaml IRC client"
   "This package provides the Lwt OpenSSL backend for the OCaml IRC client
library.  It has an exact split from the core and Lwt packages and uses
Guix's OCaml OpenSSL bindings plus the source-built lwt_ssl adapter."
   (list ocaml-irc-client ocaml-lwt ocaml-ssl ocaml-lwt-ssl)))

;;; The upstream irc-client-tls package uses tls-lwt, whose pure-OCaml TLS
;;; dependency closure is not present in the Guix revisions used by this
;;; channel.  Do not silently substitute OpenSSL for that API: the supported
;;; deliverables here are the core, Unix, Lwt, and Lwt+SSL libraries.
