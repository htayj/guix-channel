;;; Kitty variant for native bitmap fonts and XKB Meta compatibility.

(define-module (tay packages kitty-bitmap)
  #:use-module (guix build-system go)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages golang)
  #:use-module (gnu packages terminals))

(define %kitty-bitmap-version "0.48.2")
(define %kitty-bitmap-commit "2cb1d95c3accadd536bd66ba6bda044973440177")

(define %kitty-bitmap-source
  (origin
    (method git-fetch)
    (uri (git-reference
           (url "https://github.com/kovidgoyal/kitty")
           (commit (string-append "v" %kitty-bitmap-version))))
    (file-name (git-file-name "kitty" %kitty-bitmap-version))
    (sha256
     (base32 "05861h7xyksphsbnkff8jphpk7xrjpsmcqxhklzwd6yckcz1bn58"))
    (patches
     (search-patches
      "tay/packages/patches/kitty-bitmap-fonts.patch"
      "tay/packages/patches/kitty-bitmap-charcell-fonts.patch"
      "tay/packages/patches/kitty-bitmap-raster-metrics.patch"
      "tay/packages/patches/kitty-bitmap-meta-as-alt.patch"))
    (modules '((guix build utils)))
    ;; Complete Kitty 0.48.2 source setup, frozen here instead of inherited
    ;; from the rolling Guix kitty origin.
    (snippet
     #~(begin
         ;; Fails to read /etc/machine-id in the build container.
         (delete-file "tools/utils/machine_id/api_test.go")
         (substitute* "docs/conf.py"
           (("(from kitty.constants import str_version)" imp)
            (string-append "sys.path.append(\"..\")\n" imp)))
         ;; Furo is not packaged in the pinned Guix revision.
         (substitute* "docs/conf.py"
           (("^html_theme = .*$") "html_theme = 'alabaster'\n"))
         (substitute* "docs/Makefile"
           (("^SPHINXBUILD[[:space:]]+= (python3.*)$")
            "SPHINXBUILD = sphinx-build\n"))
         ;; sphinx-inline-tabs 2023.04 assumes Docutils always supplies a
         ;; backrefs attribute.  Docutils 0.22 may omit it.
         (substitute* "docs/conf.py"
           (("^extensions = \\[.*$")
            "from sphinx_inline_tabs import _impl as _kitty_tabs_impl\n\
_kitty_tabs_visit = _kitty_tabs_impl._GeneralHTMLTagElement.visit\n\
def _kitty_safe_tabs_visit(translator, node):\n\
    node.attributes.setdefault('backrefs', [])\n\
    return _kitty_tabs_visit(translator, node)\n\
_kitty_tabs_impl._GeneralHTMLTagElement.visit = staticmethod(_kitty_safe_tabs_visit)\n\n\
extensions = [\n"))))))

(define %kitty-bitmap-arguments
  (list
   #:go go-1.26
   #:import-path "github.com/kovidgoyal/kitty/tools/cmd"
   #:unpack-path "github.com/kovidgoyal/kitty"
   #:embed-files #~(list ".*\\.xml" ".*\\.json" ".*\\.txt" ".*\\.css"
                         ".*\\.html" ".*\\.icc")
   #:phases
   #~(modify-phases %standard-phases
       (delete 'build)
       (add-after 'unpack 'setup-fonts
         (lambda* (#:key inputs #:allow-other-keys)
           (let ((fonts (string-append
                         (assoc-ref inputs "font-nerd-symbols")
                         "/share/fonts/truetype")))
             (setenv "HOME" "/tmp")
             (mkdir-p "fonts")
             (copy-recursively fonts "fonts"))))
       (add-after 'fix-embed-files 'build-kitty
         (lambda* (#:key inputs #:allow-other-keys)
           (with-directory-excursion "src/github.com/kovidgoyal/kitty"
             (for-each make-file-writable (find-files "kitty"))
             (apply invoke "python3" "setup.py" "linux-package"
                    "--update-check-interval=0"
                    "--shell-integration=enabled no-rc"
                    (map (lambda (pair)
                           (string-append "--" (car pair) "="
                                          (search-input-file inputs (cdr pair))))
                         '(("egl-library" . "/lib/libEGL.so.1")
                           ("startup-notification-library" . "/lib/libstartup-notification-1.so")
                           ("canberra-library" . "/lib/libcanberra.so")
                           ("fontconfig-library" . "/lib/libfontconfig.so"))))
             (invoke "python3" "setup.py" "build-launcher"))))
       (add-after 'build-kitty 'run-python-tests
         (lambda* (#:key tests? #:allow-other-keys)
           (with-directory-excursion "src/github.com/kovidgoyal/kitty"
             (when tests?
               (setenv "HOME" (getcwd))
               (mkdir-p "test-home")
               (setenv "XDG_CONFIG_HOME" (string-append (getcwd) "/test-home"))
               (setenv "TMPDIR" (string-append (getcwd) "/test-tmp"))
               (mkdir-p (getenv "TMPDIR"))
               (for-each (lambda (file)
                           (let ((path (string-append "kitty_tests/" file ".py")))
                             (when (file-exists? path) (delete-file path))))
                         '("check_build" "child" "glfw" "multicell"
                           "tui" "shell_integration" "ssh" "options"
                           "atexit" "shm" "file_transmission" "completion"))
               (invoke "python3" "test.py")))))
       (replace 'install
         (lambda _
           (with-directory-excursion "src/github.com/kovidgoyal/kitty"
             (let ((out #$output)
                   (terminfo #$output:terminfo)
                   (shell-integration #$output:shell-integration)
                   (kitten #$output:kitten))
               (copy-recursively "linux-package/bin" (string-append out "/bin"))
               (copy-recursively "linux-package/share" (string-append out "/share"))
               (copy-recursively "linux-package/lib" (string-append out "/lib"))
               (mkdir-p (string-append kitten "/bin"))
               (symlink (string-append out "/bin/kitten")
                        (string-append kitten "/bin/kitten"))
               (mkdir-p (string-append terminfo "/share"))
               (rename-file (string-append out "/share/terminfo")
                            (string-append terminfo "/share/terminfo"))
               (copy-recursively "shell-integration" shell-integration))))))))

(define-public kitty-bitmap
  (package
    ;; Generic dependency packages and metadata remain inherited.  The
    ;; version, source, snippets, build system, outputs, and version-sensitive
    ;; phases are frozen above and cannot follow a future Guix Kitty update.
    (inherit kitty)
    (name "kitty-bitmap")
    (version %kitty-bitmap-version)
    (source %kitty-bitmap-source)
    (build-system go-build-system)
    (outputs '("out" "terminfo" "shell-integration" "kitten"))
    (arguments %kitty-bitmap-arguments)
    (properties
     `((kitty-upstream-tag . "v0.48.2")
       (kitty-upstream-commit . ,%kitty-bitmap-commit)
       ,@(package-properties kitty)))
    (synopsis "GPU-based terminal emulator with native bitmap-font support")
    (description
     "This Kitty 0.48.2 variant has an explicitly pinned upstream source,
source snippet, and version-sensitive build recipe while continuing to inherit
Guix's generic dependency packages.  It changes Kitty's Fontconfig defaults so
native non-scalable bitmap fonts, including PCF and BDF faces, may be selected
for the primary terminal font.  Bitmap strikes are fixed-size and therefore do
not zoom or scale cleanly; use an available native font size and, where needed,
explicit line-height settings.

For an XKB layout where Meta and Alt are distinct, @code{kitty-bitmap} keeps
Meta available to Kitty shortcut matching but encodes it as conventional Alt
only for the child process.  This gives legacy terminal applications
ESC-prefixed Meta chords without remapping physical Alt or changing the XKB
layout.  The conversion applies to both Kitty's legacy and extended keyboard
protocol encodings.")))
