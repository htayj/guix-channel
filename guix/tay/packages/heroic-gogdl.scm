;;; GNU Guix package for Heroic Games Launcher's GOG downloader.

(define-module (tay packages heroic-gogdl)
  #:use-module (guix build-system pyproject)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web))

(define-public heroic-gogdl
  (package
    (name "heroic-gogdl")
    (version "1.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Heroic-Games-Launcher/heroic-gogdl")
             (commit "4fe373914d625cbce75973e92f6c5c4faf9815e2")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0pcs9drldv48lqbdw7khf8x13law0xfx8h5sq3bycg7iwzb7hdxm"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The upstream checkout has no test suite.  The package-specific smoke
      ;; test exercises the installed command and its bundled C extension.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-license-notices
            (lambda _
              (let ((doc (string-append #$output
                                         "/share/doc/heroic-gogdl")))
                (mkdir-p doc)
                (copy-file "LICENSE" (string-append doc "/LICENSE"))
                (copy-file "xdelta3/xdelta3/LICENSE"
                           (string-append doc "/xdelta3-LICENSE"))))))))
    ;; `requests` is the only runtime dependency declared by pyproject.toml.
    ;; The standard pyproject wrapper retains GUIX_PYTHONPATH, including this
    ;; package's site-packages directory and its gogdl_xdelta3 ABI3 extension.
    (propagated-inputs (list python-requests))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://github.com/Heroic-Games-Launcher/heroic-gogdl")
    (synopsis "GOG downloader used by Heroic Games Launcher")
    (description
     "Heroic GOGDL is a command-line downloader and game-management helper for
GOG games, used by Heroic Games Launcher.  It is built from source and bundles
the xdelta3 patching extension; authentication remains an explicit user-supplied
token-file contract through @option{--auth-config-path}.")
    ;; The Python program is GPL-3.0-only; its bundled xdelta3 C component is
    ;; Apache-2.0, and both corresponding notices are installed above.
    (license (list license:gpl3 license:asl2.0))))
