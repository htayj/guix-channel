;;; Medley -- pinned historical Lisp environment with source-built Maiko.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages interlisp-medley)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages linux)
  #:use-module (tay packages maiko))

;; This is an upstream boot-image input, NOT the Medley source origin.
;; The source repository deliberately does not contain full/lisp.sysout.
(define medley-upstream-loadups
  (origin
    (method url-fetch)
    (uri "https://github.com/Interlisp/medley/releases/download/medley-260810-634d092e_260319-9259716e/medley-260810-634d092e-loadups.tgz")
    (file-name "medley-260810-634d092e-loadups.tgz")
    (sha256
     (base32 "0b6pnpckdsfxlxf2m7i9w6aj6s5618yhlvdqpz3ldm2aq1zqdw19"))))

(define-public interlisp-medley
  (package
    (name "interlisp-medley")
    (version "2026.08.10")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Interlisp/medley")
             (commit "634d092ed802314ada447878418686fbfeeb3048")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1d3dmhwcbwqi060679a9dsxsw45r37ppjskfn3a6n8d61h83bl95"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ; Native acceptance is external.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (delete 'build)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((out #$output)
                     (tree (string-append out "/libexec/medley"))
                     (doc (string-append out "/share/doc/interlisp-medley"))
                     (bin (string-append out "/bin")))
                ;; Narrow audited free runtime scope.  Keep file-level notices;
                ;; never copy the vendor Unicode or random/private font trees.
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append tree "/" directory)))
                 '("sources" "CLTL2" "library" "lispusers" "clos" "rooms"
                   "greetfiles" "scripts/medley" "doctools" "docs/dinfo"))
                (mkdir-p (string-append tree "/internal"))
                (for-each
                 (lambda (file)
                   (when (string=? (dirname file) "internal")
                     (install-file file (string-append tree "/internal"))))
                 (find-files "internal" ".*"))
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append tree "/" directory)))
                 '("fonts/medleydisplayfonts" "fonts/postscriptfonts/c0"))
                (mkdir-p (string-append tree "/unicode/xerox"))
                (for-each
                 (lambda (file)
                   (when (string=? (dirname file) "unicode/xerox")
                     (install-file file (string-append tree "/unicode/xerox"))))
                 (find-files "unicode/xerox" "\\.(TXT|txt)$"))
                ;; Extract only the two audited boot images; apps.sysout has
                ;; optional applications outside this package's source scope.
                (mkdir-p "../upstream-boot")
                (invoke "tar" "-C" "../upstream-boot"
                        "-xzf" #$medley-upstream-loadups
                        "medley/loadups/full.sysout"
                        "medley/loadups/lisp.sysout")
                (copy-recursively "../upstream-boot/medley/loadups"
                                  (string-append tree "/loadups"))
                (symlink #$maiko (string-append out "/libexec/maiko"))
                (install-file "LICENSE" tree)
                (install-file "LICENSE" doc)
                (copy-file (string-append #$maiko "/share/doc/maiko/LICENSE")
                           (string-append doc "/Maiko-LICENSE"))
                (copy-file (string-append #$maiko "/share/doc/maiko/NOTICE")
                           (string-append doc "/Maiko-NOTICE"))
                (call-with-output-file (string-append doc "/PROVENANCE")
                  (lambda (port)
                    (display
                     (string-append
                      "Medley source: "
                      "634d092ed802314ada447878418686fbfeeb3048\n"
                      "Maiko source-built VM: "
                      "9259716e9a797fefcdb59b6418b00f434c48dc40\n"
                      "Boot images: upstream medley-260810-634d092e-loadups.tgz, "
                      "release medley-260810-634d092e_260319-9259716e\n"
                      "Boot archive SHA256: "
                      "29f0867fc04ad446c7bfb86d0a3d0aa6"
                      "682395e1299e2a5ca7dde936d9b5d72c\n"
                      "full.sysout and lisp.sysout are upstream-built images, "
                      "not source-bootstrapped by this package.\n"
                      "Maiko uses X11, release 351, no Ethernet/Nethub; "
                      "only x86_64-linux.\n"
                      "Medley MIT LICENSE and Maiko MIT LICENSE/NOTICE "
                      "cover the shipped runtime; historical file-level "
                      "notices are retained.\n"
                      "Excluded: apps.sysout, Notecards, LOOPS, "
                      "vendor/eastasia/iso8859 Unicode, XCCStoUni binary, "
                      "Xerox PDF and unaudited font trees; "
                      "Maiko legacy build metadata is not installed.\n")
                     port)))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/medley")
                  (lambda (port)
                    (format port "#!~a\nset -eu\n"
                            #$(file-append bash-minimal "/bin/sh"))
                    ;; Upstream medley_usage also calls which to select PAGER;
                    ;; keep that runtime dependency available in a clean PATH.
                    (format port "export PATH=~s${PATH:+:$PATH}\n"
                            (string-append #$coreutils-minimal "/bin:"
                                           #$grep "/bin:" #$sed "/bin:"
                                           #$gawk "/bin:" #$procps "/bin:"
                                           #$ncurses "/bin:" #$which "/bin"))
                    ;; HOME and LOGINDIR are intentionally not overridden.
                    (format port "exec ~s --maikodir ~s --full \"$@\"\n"
                            (string-append tree "/scripts/medley/medley.command")
                            (string-append out "/libexec/maiko"))))
                (chmod (string-append bin "/medley") #o555)))))))
    (inputs
     (list maiko bash-minimal coreutils-minimal grep sed gawk procps ncurses
           which))
    (supported-systems '("x86_64-linux"))
    (home-page "https://interlisp.org")
    (synopsis "Medley Interlisp environment with a source-built Maiko VM")
    (description
     "Medley is a graphical Interlisp and Common Lisp development environment
with the historical Lisp machine interface.  This package builds its Maiko X11
virtual machine from source and installs the pinned Medley sources and free
runtime assets.  Its full and lisp boot images are the hash-pinned upstream
release images, not images bootstrapped from source by Guix.  User virtual
memory and configuration remain writable under the user's HOME or LOGINDIR.
The launcher starts a fresh full image by default; pass @option{--continue}
to resume saved virtual memory instead.
Optional applications and Maiko Ethernet/Nethub support are not included.
Native Lisp socket primitives remain available; an external network namespace
is used for offline acceptance.")
    (license license:expat)))
