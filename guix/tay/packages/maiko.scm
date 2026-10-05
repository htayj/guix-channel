;;; Maiko -- native VM for the Medley Interlisp environment.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages maiko)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages libbsd)
  #:use-module (gnu packages build-tools)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xorg))

(define-public maiko
  (package
    (name "maiko")
    (version "2026.03.19")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Interlisp/maiko")
             (commit "9259716e9a797fefcdb59b6418b00f434c48dc40")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1sd8w4rfjmc485qkg8jm0qv7hfcfy6nvxaa240sin03fjb1w7992"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ; Upstream provides no CTest suite.
      #:generator "Ninja"
      #:parallel-build? #f
      #:configure-flags
      #~(list "-DMAIKO_DISPLAY_X11=ON" "-DMAIKO_DISPLAY_SDL=OFF"
              "-DMAIKO_NETWORK_TYPE=NONE")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'deterministic-version
            (lambda _
              ;; Upstream mkvdate uses wall-clock time and git status.  Neither
              ;; describes a fixed Guix source tree; emit immutable provenance.
              (call-with-output-file "bin/mkvdate"
                (lambda (port)
                  (format port "#!~a~%cat <<'EOF'~%"
                          #$(file-append bash-minimal "/bin/sh"))
                (display
                 (string-append
                  "#include <time.h>\n"
                  "extern const time_t MDate;\n"
                  "const time_t MDate = 1773956843;\n"
                  "extern const char *MaikoGitVersion;\n"
                  "const char *MaikoGitVersion = \"maiko git version: 9259716e\";\n"
                  "EOF\n")
                 port)))
              (chmod "bin/mkvdate" #o755)))
          (add-after 'unpack 'fixed-platform
            (lambda _
              ;; Only x86_64-linux is supported.  The installed discovery
              ;; helpers need no build-only GPL config.guess at runtime.
              (substitute* '("bin/osversion" "bin/machinetype")
                (("os=\\$\\{LDEARCH:.*")
                 "os=${LDEARCH:-x86_64-unknown-linux-gnu}\n"))))
          (add-before 'configure 'install-launcher-support-and-notices
            (lambda _
              (let ((support (string-append #$output "/bin"))
                    (doc (string-append #$output "/share/doc/maiko")))
                (for-each
                 (lambda (file)
                   (install-file file support))
                 '("bin/osversion" "bin/machinetype"))
                (install-file "LICENSE" doc)
                (install-file "NOTICE" doc)))))))
    (native-inputs (list ninja pkg-config))
    (inputs (list bash-minimal coreutils-minimal libbsd libx11))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/Interlisp/maiko")
    (synopsis "Native X11 virtual machine for Medley Interlisp")
    (description
     "Maiko emulates the Lisp machine instruction set used by Medley
Interlisp.  This package builds the lde launcher, ldex X11 virtual machine and
ldeinit bootstrap executable from the pinned upstream C sources.  Ethernet and
Nethub support are disabled.  Medley system images are supplied separately.")
    (license license:expat)))
