;;; Kitty variant for native bitmap fonts and XKB Meta compatibility.

(define-module (tay packages kitty-bitmap)
  #:use-module (guix build-system go)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages golang)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages terminals)
  #:use-module (tay packages kitty-bitmap-go-deps)
  #:use-module (tay packages shader-slang))

(define %kitty-bitmap-version "0.49.1")
;; v0.49.1 is an annotated tag (object 83efa1fd445e1ef6c97f0deb2af7d253d9734d26);
;; this is the commit it dereferences to.
(define %kitty-bitmap-commit "c9896e8c002b32591a232dc5996def2493132aaf")

(define %kitty-bitmap-source
  (origin
    (method git-fetch)
    (uri (git-reference
           (url "https://github.com/kovidgoyal/kitty")
           (commit %kitty-bitmap-commit)))
    (file-name (git-file-name "kitty" %kitty-bitmap-version))
    (sha256
     (base32 "19sjlf44gq38r4fa8iivp2y4y494lynhm43mf1il0d7ck5yd6n31"))
    (patches
     (search-patches
      "tay/packages/patches/kitty-bitmap-fonts.patch"
      "tay/packages/patches/kitty-bitmap-charcell-fonts.patch"
      "tay/packages/patches/kitty-bitmap-raster-metrics.patch"
      "tay/packages/patches/kitty-bitmap-meta-as-alt.patch"))
    (modules '((guix build utils)))
    ;; Complete Kitty 0.49.1 source setup, frozen here instead of inherited
    ;; from the rolling Guix kitty origin.  Kitty 0.49.1's docs/Makefile
    ;; already invokes sphinx-build directly, and its docs use sphinx-design
    ;; instead of sphinx-inline-tabs, so neither older workaround applies.
    (snippet
     #~(begin
         ;; Fails to read /etc/machine-id in the build container.
         (delete-file "tools/utils/machine_id/api_test.go")
         (substitute* "docs/conf.py"
           (("(from kitty.constants import str_version)" imp)
            (string-append "sys.path.append(\"..\")\n" imp)))
         ;; Furo is not packaged in the pinned Guix revision.
         (substitute* "docs/conf.py"
           (("^html_theme = .*$") "html_theme = 'alabaster'\n"))))))

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
    ;; Version, source, snippet, build system, outputs, and version-sensitive
    ;; phases are frozen above and cannot follow a future Guix Kitty update.
    ;;
    ;; Kitty 0.49.1's go.mod requires go-github-com-emmansun-base64,
    ;; go-github-com-sgtdi-fswatcher and go-github-com-kovidgoyal-go-shm/v2.
    ;; Upstream Guix only added the first two to the `kitty' inputs on
    ;; 2026-08-26, so older Guix revisions (where the rolling `kitty' is
    ;; 0.46.2) leave kitty-bitmap's Go build unable to resolve them, and no
    ;; Guix revision packages go-shm/v2 yet.  Supply channel-local definitions
    ;; for all three modules and drop any same-named inherited input first, so
    ;; this stays correct when the consuming Guix eventually ships its own
    ;; copies.  The inherited go-shm v1 stays: kovidgoyal/imaging imports it.
    ;;
    ;; Kitty 0.49.1's docs replaced sphinx-inline-tabs with sphinx-design.
    ;;
    ;; Kitty 0.49 compiles its Slang shaders at build time with `slangc',
    ;; found through $SLANGC or $PATH, and no Guix revision packages it; use
    ;; the channel's shader-slang, again replacing any same-named input.
    (inherit kitty)
    (name "kitty-bitmap")
    (version %kitty-bitmap-version)
    (source %kitty-bitmap-source)
    (build-system go-build-system)
    (outputs '("out" "terminfo" "shell-integration" "kitten"))
    (arguments %kitty-bitmap-arguments)
    (native-inputs
     (modify-inputs (package-native-inputs kitty)
       (delete "go-github-com-emmansun-base64"
               "go-github-com-kovidgoyal-go-shm-v2"
               "go-github-com-sgtdi-fswatcher"
               "python-sphinx-design"
               "python-sphinx-inline-tabs"
               "shader-slang")
       (prepend kitty-bitmap-go-emmansun-base64
                kitty-bitmap-go-kovidgoyal-go-shm-v2
                kitty-bitmap-go-sgtdi-fswatcher
                python-sphinx-design
                shader-slang)))
    (properties
     `((kitty-upstream-tag . ,(string-append "v" %kitty-bitmap-version))
       (kitty-upstream-commit . ,%kitty-bitmap-commit)
       ,@(package-properties kitty)))
    (synopsis "GPU-based terminal emulator with native bitmap-font support")
    (description
     "This Kitty 0.49.1 variant has an explicitly pinned upstream source,
source snippet, version-sensitive build recipe, and the Go modules its
@code{go.mod} needs that Guix lacks, while continuing to inherit Guix's
generic dependency packages.  It changes Kitty's Fontconfig
defaults so native non-scalable bitmap fonts, including PCF and BDF faces, may
be selected for the primary terminal font.
Bitmap strikes are fixed-size and therefore do
not zoom or scale cleanly; use an available native font size and, where needed,
explicit line-height settings.

For an XKB layout where Meta and Alt are distinct, @code{kitty-bitmap} keeps
Meta available to Kitty shortcut matching but encodes it as conventional Alt
only for the child process.  This gives legacy terminal applications
ESC-prefixed Meta chords without remapping physical Alt or changing the XKB
layout.  The conversion applies to both Kitty's legacy and extended keyboard
protocol encodings.")))
