;;; Guix package for the offline Talmudifier document generator.

(define-module (tay packages talmudifier)
  #:use-module (guix build-system python)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages tex)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-s-z))

;; These separately fetched sources supply the redistribution notices absent
;; from the upstream font directories.  Culmus notices come from revision 68495
;; in the frozen TeX Live 2024 archive and match reviewed Culmus 1.1 verbatim.
(define %culmus-font-notices
  (origin
    (method url-fetch)
    (uri "https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2024/tlnet-final/archive/culmus.doc.r68495.tar.xz")
    (file-name "culmus-1.1-doc-r68495.tar.xz")
    (sha256
     (base32 "04n5f97xipii1vkr8wm4dawc78li66qvi0j25r2gwivfmjbxhxgq"))))

(define %mekorot-font-notices
  (origin
    (method url-fetch)
    (uri "https://sourceforge.net/projects/mekorot/files/Mekorot-Fonts/0.03/Mekorot-Fonts-0.03.tar.gz/download")
    (file-name "Mekorot-Fonts-0.03.tar.gz")
    (sha256
     (base32 "0x0w0n49xzbrsqflqdwgb6zqwi6glvg1lp66500falf2iqfahm2h"))))

(define-public talmudifier
  (package
    (name "talmudifier")
    (version "1.1.0-1.1f23206")
    (source (package-source subalterngames-talmudifier-source))
    (build-system python-build-system)
    (arguments
     (list
      ;; Upstream supplies a document-generation example, not a unit suite.
      ;; tests/talmudifier-smoke.sh exercises the installed command offline.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-python-package
            (lambda _
              (invoke "patch" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "talmudifier-pdf-writer.patch")))
              (invoke "patch" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file "talmudifier-api.patch")))
              ;; The pinned tree omits the marker needed by find_packages.
              (call-with-output-file "talmudifier/__init__.py"
                (lambda (port) #t))
              (substitute* "setup.py"
                (("'pyhyphen'") "'pyphen'"))
              (substitute* "talmudifier/word.py"
                (("from hyphen import Hyphenator") "from pyphen import Pyphen")
                (("Hyphenator\\('en_US'\\)") "Pyphen(lang='en_US', right=3)")
                ;; Pyphen iterates longest-first; retain upstream's ascending
                ;; split order and its existing pairs of styled Word objects.
                (("self.H.pairs\\(self.word\\)")
                 "reversed(list(self.H.iterate(self.word)))"))))
          (add-after 'install 'install-assets-and-launcher
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out #$output)
                     (data (string-append out "/share/talmudifier"))
                     (doc (string-append out "/share/doc/talmudifier"))
                     (modules (string-append (site-packages inputs outputs)
                                             "/talmudifier"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/talmudifier"))
                     (texmf
                      (string-join
                       (filter file-exists?
                               (map (lambda (input)
                                      (string-append (cdr input)
                                                     "/share/texmf-dist"))
                                    inputs))
                       ":")))
                ;; Explicitly install all modules and the resource omitted by
                ;; setup.py's package_data, without importing from the source.
                (for-each (lambda (file) (install-file file modules))
                          (find-files "talmudifier" "\\.py$"))
                (install-file "talmudifier/header.txt" modules)
                (copy-file
                 #$(local-file
                    (search-tay-package-file "talmudifier-runtime.py"))
                 (string-append modules "/runtime.py"))
                (substitute* (string-append modules "/runtime.py")
                  (("@DATA@") data)
                  (("@XELATEX@") (search-input-file inputs "/bin/xelatex"))
                  (("@TEXMF@") texmf))
                (copy-recursively "fonts" (string-append data "/fonts"))
                (install-file "recipes/default.json"
                              (string-append data "/recipes"))
                (install-file "test/test_input.md" (string-append data "/test"))
                (install-file "test_input_reader.py" data)
                (install-file "README.md" doc)
                (install-file "LICENSE" doc)
                (for-each
                 (lambda (font)
                   (let ((directory (string-append "fonts/" font)))
                     (for-each
                      (lambda (notice)
                        (install-file notice
                                      (string-append doc "/" directory)))
                      (find-files directory "(OFL\\.txt|Fell Types License\\.txt)$"))))
                 '("averia" "garamond" "fell_french_canon" "fell_flowers"))
                (mkdir-p "font-notices")
                (invoke "tar" "xf" #$%culmus-font-notices "-C" "font-notices")
                (invoke "tar" "xf" #$%mekorot-font-notices "-C" "font-notices")
                (for-each
                 (lambda (notice)
                   (install-file (string-append "font-notices/doc/fonts/culmus/" notice)
                                 (string-append doc "/fonts/culmus")))
                 '("README.md" "LICENSE" "LICENSE-BITSTREAM" "GNU-GPL"))
                (for-each
                 (lambda (notice)
                   (install-file
                    (string-append "font-notices/Mekorot-Fonts/Rashi/" notice)
                    (string-append doc "/fonts/rashi")))
                 '("License" "lppl.txt"))
                (mkdir-p bin)
                (copy-file
                 #$(local-file
                    (search-tay-package-file "talmudifier-launcher.py"))
                 launcher)
                (substitute* launcher
                  (("@PYTHON@") (search-input-file inputs "/bin/python3")))
                (chmod launcher #o555)))))))
    (inputs
     (list texlive-xetex texlive-geometry texlive-marginnote texlive-sectsty
           texlive-ragged2e texlive-lineno texlive-xcolor texlive-paracol
           texlive-fontspec texlive-koma-script
           ;; lineno requires kvoptions; Guix's kvoptions recipe has no
           ;; propagated inputs for its RequirePackage dependencies.
           texlive-kvoptions texlive-kvsetkeys texlive-ltxcmds))
    ;; setuptools remains a runtime dependency for pkg_resources.  Pyphen's
    ;; installed en_US dictionary is local and has no network bootstrap.
    (propagated-inputs
     (list python-pdfminer-six python-tqdm python-pyphen python-setuptools))
    (home-page "https://github.com/subalterngames/talmudifier")
    (synopsis "generate Talmud-style document layouts from local text")
    (description
     "Talmudifier turns three columns of Markdown-like text into a Talmud-style
page using bundled fonts and a JSON layout recipe.  Its Python API and an
installed command that typesets the bundled local example are available.  The
command uses a writable temporary workspace and copies the generated PDF and
TeX document into the caller's @file{Output} directory, without network access
or writes to installed assets.")
    ;; LICENSE-BITSTREAM is retained as historical Culmus documentation only;
    ;; it applies to unshipped David, not Frank-Ruehl.  Frank-Ruehl is GPL-2.0
    ;; without an embedding exception, including its PDF font subsets.
    (license
     (list license:expat license:silofl1.1 license:gpl2 license:lppl1.3c))))
