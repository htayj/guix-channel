;;; Kitty variant for native bitmap fonts and XKB Meta compatibility.

(define-module (tay packages kitty-bitmap)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages terminals))

(define-public kitty-bitmap
  (package
    (inherit kitty)
    (name "kitty-bitmap")
    (source
     (origin
       (inherit (package-source kitty))
       ;; The bitmap-font default is the AUR kitty-bitmap patch.  The raster
       ;; metrics and Meta child-encoding fixes are kept as separate patches
       ;; so their provenance and scope remain explicit.
       (patches
        (append (origin-patches (package-source kitty))
                (search-patches
                 "tay/packages/patches/kitty-bitmap-fonts.patch"
                 "tay/packages/patches/kitty-bitmap-charcell-fonts.patch"
                 "tay/packages/patches/kitty-bitmap-raster-metrics.patch"
                 "tay/packages/patches/kitty-bitmap-meta-as-alt.patch")))
       (snippet
        #~(begin
            #$(origin-snippet (package-source kitty))
            ;; sphinx-inline-tabs 2023.04 assumes Docutils always supplies a
            ;; backrefs attribute.  Docutils 0.22 may omit it, so initialize
            ;; it before the extension's visitor copies and removes it.
            (substitute* "docs/conf.py"
              (("^extensions = \\[.*$")
               "from sphinx_inline_tabs import _impl as _kitty_tabs_impl\n\
_kitty_tabs_visit = _kitty_tabs_impl._GeneralHTMLTagElement.visit\n\
def _kitty_safe_tabs_visit(translator, node):\n\
    node.attributes.setdefault('backrefs', [])\n\
    return _kitty_tabs_visit(translator, node)\n\
_kitty_tabs_impl._GeneralHTMLTagElement.visit = staticmethod(_kitty_safe_tabs_visit)\n\n\
extensions = [\n"))))))
    (synopsis "GPU-based terminal emulator with native bitmap-font support")
    (description
     "This variant of Kitty inherits the current Guix @code{kitty} package and
its dependency graph.  It changes Kitty's Fontconfig defaults so native
non-scalable bitmap fonts, including PCF and BDF faces, may be selected for
the primary terminal font.  Bitmap strikes are fixed-size and therefore do
not zoom or scale cleanly; use an available native font size and, where
needed, explicit line-height settings.

For an XKB layout where Meta and Alt are distinct, @code{kitty-bitmap} keeps
Meta available to Kitty shortcut matching but encodes it as conventional Alt
only for the child process.  This gives legacy terminal applications
ESC-prefixed Meta chords without remapping physical Alt or changing the XKB
layout.  The conversion applies to both Kitty's legacy and extended keyboard
protocol encodings.")))
