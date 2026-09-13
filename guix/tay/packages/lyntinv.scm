;;; GNU Guix package for Lyntin V (the lyntinv PyPI distribution).

(define-module (tay packages lyntinv)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python-build))

(define-public lyntin
  (package
    (name "lyntin")
    (version "5.0.1")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://files.pythonhosted.org/packages/db/ba/"
         "5cf625b1d669f023ca0c52d4dad2e461e06f054d9f1148c0b0eed28ac8ea/"
         "lyntinv-5.0.1.tar.gz"))
       (sha256
        (base32 "12x9nrpjc7gs16ziq7y9cx74av3psj4lz7wbl59s9daz3lqzlp6j"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The release includes a standalone unittest script rather than a
      ;; standard pytest/unittest test layout.  Run that script explicitly;
      ;; disable the generic discovery runner, which imports helper modules
      ;; using the source tree's historical top-level paths.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'sync-upstream-version
            (lambda _
              (use-modules (guix build utils))
              ;; Lyntin V's 5.0.1 distribution metadata was released with
              ;; stale 5.0 values in the runtime module.
              (substitute* "lyntin/__init__.py"
                (("__version__ = '5\\.0'")
                 "__version__ = '5.0.1'")
                (("__version_tuple__ = \\(5, 0, 0\\)")
                 "__version_tuple__ = (5, 0, 1)"))))
          (add-after 'unpack 'preserve-cli-exit-status
            (lambda _
              (use-modules (guix build utils))
              ;; The upstream main function catches its own SystemExit and
              ;; turns successful --help/--version requests into status 1.
              ;; Return normally for only those two completed requests.
              (substitute* "lyntin/engine.py"
                (("        sys\\.exit\\(0\\)")
                 "        return"))))
          (add-before 'check 'run-upstream-tests
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let ((python (search-input-file inputs "bin/python3")))
                ;; The test script assumes it is run from the tools
                ;; directory so that its ../ path points at the source tree.
                (with-directory-excursion "tools"
                  (invoke python "lyntinunittest.py")))))
          ;; Install after the generic Python wrapping phase.  The generic
          ;; wrapper adds every native input (including Hatchling) to
          ;; GUIX_PYTHONPATH; this launcher needs only its own site directory.
          (add-after 'wrap 'install-command
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (python (search-input-file inputs "bin/python3"))
                     (bin (string-append out "/bin"))
                     (command (string-append bin "/lyntin")))
                (mkdir-p bin)
                (copy-file "scripts/runlyntin.py" command)
                ;; The sdist's historical launcher starts with ``##!`` rather
                ;; than a valid shebang, so fix it for the installed command.
                (substitute* command
                  (("##!/usr/bin/env python")
                   (string-append "#!" python)))
                (chmod command #o555)
                (let ((site-packages
                       (car (find-files (string-append out "/lib")
                                        "site-packages"
                                        #:directories? #t))))
                  (wrap-program command
                    `("GUIX_PYTHONPATH" ":" prefix (,site-packages))))))))))
    (native-inputs
     (list python-hatchling))
    (inputs
     (list bash-minimal))
    (synopsis "MUD client with text-based interface")
    (description
     "Lyntin V is a Python MUD client with text, curses, and Tk user
interfaces.  It provides aliases, triggers, scripting, and a module API for
customizing sessions.  The package installs the upstream text-mode launcher
as the @command{lyntin} command; configuration and session files remain in
the user's home directory rather than the store.")
    (home-page "https://pypi.org/project/lyntinv/")
    (license license:gpl3+)))
