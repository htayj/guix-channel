;;; GNU Guix package for the B00merang Azurra GTK theme.

(define-module (tay packages azurra)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages web)
  #:use-module (tay packages starred-a-c)
  #:use-module ((guix licenses) #:prefix license:))

(define-public azurra-gtk-theme
  (package
    (name "azurra-gtk-theme")
    (version "4.2.7")
    (source (package-source b00merang-project-azurra-framework-source))
    (build-system gnu-build-system)
    (native-inputs (list sassc))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "sassc" "Azurra/gtk.scss" "Azurra/gtk.css")
              (invoke "sassc" "Azurra/gtk-dark.scss" "Azurra/gtk-dark.css")))
          (delete 'check)
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let ((theme (string-append #$output "/share/themes/Azurra")))
                (mkdir-p theme)
                (for-each (lambda (file) (install-file file theme))
                          '("Azurra/gtk.css" "Azurra/gtk-dark.css"
                            "Azurra/theme.conf"))
                (copy-recursively "Azurra/assets"
                                  (string-append theme "/assets"))
                (copy-recursively "Azurra/assets-dark"
                                  (string-append theme "/assets-dark"))
                ;; The upstream stylesheets also select backdrop variants of
                ;; selected check/radio icons, but the archive omits those
                ;; otherwise-identical links.  Materialize the missing links
                ;; from the committed selected assets without invoking the
                ;; upstream SVG renderer.
                (for-each
                 (lambda (asset-directory)
                   (for-each
                    (lambda (base)
                      (for-each
                       (lambda (suffix)
                         (symlink (string-append base "-selected" suffix)
                                  (string-append asset-directory "/"
                                                 base "-unfocused-selected"
                                                 suffix)))
                       '(".png" "@2.png")))
                    '("checkbox-unchecked" "checkbox-unchecked-insensitive"
                      "checkbox-checked" "checkbox-checked-insensitive"
                      "checkbox-mixed" "checkbox-mixed-insensitive"
                      "radio-unchecked" "radio-unchecked-insensitive"
                      "radio-checked" "radio-checked-insensitive"
                      "radio-mixed" "radio-mixed-insensitive")))
                 (list (string-append theme "/assets")
                       (string-append theme "/assets-dark")))))))))
    (synopsis "Azurra theme for GTK 3 applications")
    (description
     "Azurra GTK Theme provides the Azurra GTK 3 stylesheet and its committed
light and dark image assets.  It installs only the finished theme, without
unrelated upstream themes, source stylesheets, asset-rendering scripts, or
runtime launchers.")
    (home-page "https://github.com/B00merang-Project/Azurra_framework")
    (license license:gpl2)))
