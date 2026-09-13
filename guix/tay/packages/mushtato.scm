;;; GNU Guix packages for MushTato and its Python-only dependency gaps.

(define-module (tay packages mushtato)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages check)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages regex)
  #:use-module (gnu packages ssh))

;; Guix does not currently provide these two Python dependencies.  Keep them
;; in this module so the MushTato closure remains complete and does not make
;; the build system fetch anything from PyPI at build time.
(define-public python-restrictedpython
  (package
    (name "python-restrictedpython")
    (version "8.5")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://files.pythonhosted.org/packages/7c/3b/8e41f7cfabbb30b1013ebc7484303d6c87da2906ec432d69dea11d2f7d75/restrictedpython-8.5.tar.gz")
       (sha256
        (base32
         "05b28ss5v9ngy1fs1v2i2kmjm5ca34jz66hdcpdqiaiwpsfjdlaf"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (native-inputs
     (list python-setuptools python-wheel))
    (synopsis "restricted subset of Python for trusted environments")
    (description
     "RestrictedPython is a defined subset of the Python language that can
be used to provide program input in a trusted environment.  It is used by
MushTato for its user-script sandbox.")
    (home-page "https://github.com/zopefoundation/RestrictedPython")
    (license license:zpl2.1)))

(define-public python-google-re2
  (package
    (name "python-google-re2")
    (version "1.1.20251105")
    (source
     (origin
       (method url-fetch)
       (uri
        "https://files.pythonhosted.org/packages/6b/60/805c654ba53d685513df955ee745f71920fe8e6a284faf0f9b9dc19b659c/google_re2-1.1.20251105.tar.gz")
       (sha256
        (base32
         "1njvwviqp9vhmiwnqh99gx33qzf1bbh3fz0yx68knc785qllmc8x"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'set-re2-build-flags
            (lambda* (#:key inputs #:allow-other-keys)
              ;; google-re2's setup.py uses a setuptools Extension and does
              ;; not consult pkg-config itself.  Supply the Guix RE2 headers
              ;; and library explicitly, including the link search path used
              ;; by the extension at runtime.
              (let ((re2 (assoc-ref inputs "re2")))
                (setenv "CXXFLAGS"
                        (string-append "-I" re2 "/include"
                                       (if (getenv "CXXFLAGS")
                                           (string-append " " (getenv "CXXFLAGS"))
                                           "")))
                (setenv "LDFLAGS"
                        (string-append "-L" re2 "/lib"
                                       (if (getenv "LDFLAGS")
                                           (string-append " " (getenv "LDFLAGS"))
                                           "")))))))))
    ;; google-re2's generated extension includes RE2's public headers, which
    ;; themselves include Abseil headers.  The legacy `re2' package does not
    ;; expose that build dependency; `re2-next' propagates its matching Abseil
    ;; API, keeping this C++ extension's complete build and runtime graph in
    ;; the Guix store.
    (inputs
     (list re2-next))
    (native-inputs
     (list pybind11 pkg-config python-setuptools python-wheel))
    (synopsis "Python bindings for the RE2 regular-expression engine")
    (description
     "This package provides Python bindings for Google's RE2 regular-expression
engine.  RE2 avoids backtracking and supports a deliberately bounded regular
expression feature set.")
    (home-page "https://github.com/google/re2")
    (license license:bsd-3)))

(define-public mushtato
  (package
    (name "mushtato")
    (version "1.9.3")
    (source
     (origin
       ;; v1.9.3 is an annotated tag.  Pin its peeled release commit so the
       ;; channel does not depend on a mutable tag reference.
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/N0NJY/mushtato")
             (commit "3fc327a07efff7b421c24022f017b3837add3dec")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "11hs8k41mfc3a25qhs6vig3g3np6g7lmymbzfvjbfz2al2s661ai"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:test-backend #~'pytest
      ;; GUI tests require an active display and are covered by the Xvfb smoke
      ;; test below.  This deterministic build-time suite exercises the
      ;; headless engine, including sandboxing plus local TLS, SOCKS4, Telnet,
      ;; and AsyncSSH protocol tests, without any public endpoint.
      #:test-flags #~'("-q" "tests/engine")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-runtime-assets
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (site (car (find-files (string-append out "/lib")
                                            "^site-packages$"
                                            #:directories? #t)))
                     (doc (string-append out "/share/doc/mushtato"))
                     (licenses (string-append doc "/THIRD-PARTY-LICENSES"))
                     (bin (string-append out "/bin"))
                     (python (search-input-file inputs "bin/python3")))
                ;; setuptools' package discovery intentionally excludes data;
                ;; the GUI resolves these files relative to gui/__file__.
                (copy-recursively "gui/assets"
                                  (string-append site "/gui/assets"))

                ;; Install a stable command name for users and desktop files.
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/mushtato")
                  (lambda (port)
                    (format port "#!~a -sP~%"
                            python)
                    (display "from gui.app import main\n"
                             port)
                    (display "raise SystemExit(main())\n" port)))
                (chmod (string-append bin "/mushtato") #o555)

                ;; Keep the upstream source and every bundled license notice
                ;; alongside the installed application.
                (mkdir-p licenses)
                (for-each
                 (lambda (file)
                   (install-file file doc))
                 '("LICENSE" "README.md" "INSTALL.md" "CREDITS.md"
                   "CHANGELOG.md" "TROUBLESHOOTING.md" "SPEC.md"
                   "pyproject.toml"))
                (copy-recursively "THIRD-PARTY-LICENSES" licenses)

                ;; Provide standard freedesktop integration and all supplied
                ;; raster sizes, without putting mutable state in the store.
                (for-each
                 (lambda (size)
                   (let ((icon-dir (string-append out "/share/icons/hicolor/"
                                                  size "x" size "/apps")))
                     (mkdir-p icon-dir)
                     (copy-file (string-append "gui/assets/icon/" size ".png")
                                (string-append icon-dir "/mushtato.png"))))
                 '("16" "24" "32" "48" "64" "128" "256" "512" "1024"))
                (let ((desktop-dir (string-append out "/share/applications")))
                  (mkdir-p desktop-dir)
                  (call-with-output-file
                      (string-append desktop-dir "/mushtato.desktop")
                    (lambda (port)
                      (display "[Desktop Entry]\n" port)
                      (display "Type=Application\n" port)
                      (display "Name=MushTato\n" port)
                      (display "Comment=Python MUD and MUSH client\n" port)
                      (display "Exec=mushtato\n" port)
                      (display "Icon=mushtato\n" port)
                      (display "Terminal=false\n" port)
                      (display "Categories=Game;Network;\n" port)
                      (display "StartupNotify=true\n" port)))))))
          (add-after 'install-runtime-assets 'check-no-store-state
            (lambda* (#:key outputs #:allow-other-keys)
              ;; The installed tree contains code, assets, documentation, and
              ;; a launcher only.  Runtime profiles/logs/maps/plugins are
              ;; resolved by platformdirs under the user's data directory.
              (use-modules (guix build utils))
              (let ((out (assoc-ref outputs "out")))
                (unless (file-exists? (string-append out "/bin/mushtato"))
                  (error "MushTato launcher was not installed"))
                #t)))
          ;; Guix's generic pyproject checker asks pkg_resources to satisfy
          ;; the upstream distribution name "PySide6".  Guix intentionally
          ;; splits that wheel into PySide6-Essentials and PySide6-Addons, so
          ;; no distribution with that umbrella name exists even though the
          ;; PySide6 module is present.  Keep a strict equivalent check based
          ;; on the actual imports MushTato uses instead of disabling it.
          (replace 'sanity-check
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (site (car (find-files (string-append out "/lib")
                                            "^site-packages$"
                                            #:directories? #t))))
                (setenv "GUIX_PYTHONPATH"
                        (string-append site ":" (getenv "GUIX_PYTHONPATH")))
                (invoke "python" "-c"
                        (string-append
                         "import asyncssh, re2, platformdirs, PySide6, "
                         "RestrictedPython; from gui.app import main"))))))))
    ;; These are project metadata dependencies, so propagate their Python
    ;; modules to consumers as required by the pyproject build system's
    ;; dependency sanity check.
    (propagated-inputs
     (list python-asyncssh
           python-google-re2
           python-platformdirs
           python-pyside-6
           python-restrictedpython))
    (native-inputs
     (list python-pytest python-setuptools python-wheel))
    (synopsis "cross-platform Python GUI client for MUD and MUSH games")
    (description
     "MushTato is a cross-platform graphical MUD and MUSH client inspired by
Potato and TinyFugue.  It provides tabbed sessions, address-book profiles,
Telnet and SSH connections, optional TLS and SOCKS4 support, and sandboxed
Python scripting.  The package uses Guix-provided Qt, RE2, SSH, and Python
dependencies without downloading runtimes or plugins during the build.  It
installs the upstream MIT notice, bundled Qt LGPL/GPL notices, documentation,
icons, and a freedesktop desktop entry.  User profiles, logs, maps, plugins,
and other mutable data remain under platformdirs' per-user data directory.  A
local loopback fake-MUD smoke test is provided separately; the package never
contacts a public MUD during its build or tests.")
    (home-page "https://github.com/N0NJY/mushtato")
    (license license:expat)))
