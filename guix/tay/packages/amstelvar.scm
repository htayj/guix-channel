;;; GNU Guix package for the Amstelvar variable font family.

(define-module (tay packages amstelvar)
  #:use-module (guix build-system font)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-d-h))

(define %amstelvar-smoke
  (local-file (search-tay-package-file "amstelvar-smoke.py")))

(define-public amstelvar
  (package
    (name "amstelvar")
    ;; Tag v1.001 of googlefonts/amstelvar (now served as amstelvar-beta)
    ;; is commit f44f670affec72a37c69a1bf103bddc044020f49, the pinned
    ;; commit of the shared source snapshot.
    (version "1.001")
    (source (package-source googlefonts-amstelvar-source))
    (build-system font-build-system)
    (arguments
     (list
      #:modules '((guix build font-build-system)
                  (guix build utils)
                  (ice-9 match))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            ;; The 280 MB snapshot also carries UFO masters, proofs, and 88
            ;; historical TTFs under fonts/old and elsewhere.  Extract only
            ;; the two v1.001 variable fonts and the project notices, so the
            ;; install phase cannot pick up any other binary font.
            (lambda* (#:key source #:allow-other-keys)
              (mkdir "source")
              (chdir "source")
              (invoke "tar" "-xzf" source "--strip-components=1"
                      "--wildcards" "--no-wildcards-match-slash"
                      "*/OFL.txt" "*/COPYRIGHT.md" "*/AUTHORS.txt"
                      "*/CONTRIBUTORS.txt" "*/FONTLOG.md" "*/README.md"
                      "*/fonts/Amstelvar-Roman*.ttf"
                      "*/fonts/Amstelvar-Italic*.ttf")
              (match (find-files "." "\\.ttf$")
                ((_ _) #t)
                (fonts (error "expected exactly two Amstelvar fonts" fonts)))))
          (add-after 'install 'install-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/"
                                        #$name "-" #$version)))
                (for-each (lambda (file) (install-file file doc))
                          '("AUTHORS.txt" "CONTRIBUTORS.txt" "FONTLOG.md"
                            "README.md")))))
          (add-after 'install-notices 'install-smoke
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec/amstelvar"))
                     (helper (string-append libexec "/amstelvar-smoke.py"))
                     (launcher (string-append bin "/amstelvar-smoke"))
                     (fonts (string-append #$output "/share/fonts/truetype")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-file #$%amstelvar-smoke helper)
                (chmod helper #o444)
                (call-with-output-file launcher
                  (lambda (port)
                    ;; Pin the interpreter and module path; -I ignores the
                    ;; caller's PYTHON* variables and user site directory,
                    ;; and -B keeps bytecode out of every writable location.
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (format port "export GUIX_PYTHONPATH=~s~%"
                            (getenv "GUIX_PYTHONPATH"))
                    (format port "case $# in~%  0) ;;~%")
                    (format port "  2) test \"$1\" = --specimen || ~
{ echo 'usage: amstelvar-smoke [--specimen PNG]' >&2; exit 64; } ;;~%")
                    (format port "  *) echo 'usage: amstelvar-smoke ~
[--specimen PNG]' >&2; exit 64 ;;~%esac~%")
                    (format port "exec ~a/bin/python3 -I -B ~s --font-dir ~s \
\"$@\"~%"
                            #$python helper fonts)))
                (chmod launcher #o555))))
          (add-after 'install-smoke 'check-installed-fonts
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "python3" "-I" "-B"
                        (string-append #$output
                                       "/libexec/amstelvar/amstelvar-smoke.py")
                        "--build-check"
                        "--font-dir"
                        (string-append #$output "/share/fonts/truetype")
                        "--specimen" "specimen.png")))))))
    ;; Python, fontTools, and Pillow (with FreeType) run only the installed
    ;; amstelvar-smoke proof; the fonts themselves have no runtime inputs.
    (inputs (list bash-minimal python python-fonttools python-pillow))
    (home-page "https://github.com/googlefonts/amstelvar")
    (synopsis "Parametric variable serif font family")
    (description
     "Amstelvar is a serif typeface inspired by Dutch and Belgian types from
the sixteenth century onward and the first public demonstration of the Type
Network parametric-axes approach to OpenType variable fonts.  This package
installs the upstream v1.001 Roman variable font, with twelve axes (weight,
width, optical size, grade, and eight parametric axes), and the Italic
variable font, with nine axes.

Upstream's pinned 2018 fontmake toolchain cannot be built from the retained
sources with current Python, and the v1.001 release fixes exist only in the
committed binaries, so the fonts are the upstream OFL-licensed release files
from the pinned commit rather than a rebuild.  The @command{amstelvar-smoke}
command loads the installed fonts with fontTools, checks their names, style
bits, variation axes, and glyph outlines, renders them with FreeType, and can
write a PNG specimen with @option{--specimen}.")
    (license license:silofl1.1)))
