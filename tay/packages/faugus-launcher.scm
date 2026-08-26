;;; GNU Guix package for Faugus Launcher.

(define-module (tay packages faugus-launcher)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages games)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (tay packages starred-d-h)
  #:use-module ((guix licenses) #:prefix license:))

(define python-icoextract
  (package
    (name "python-icoextract")
    (version "0.3.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "icoextract" version))
              (sha256
               (base32 "1v1qjbsvgp87rfh4g2g6xld3l20dsgzg5qs89a0n2bk6f535id4g"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (native-inputs (list python-setuptools))
    (propagated-inputs (list python-pefile python-pillow))
    (home-page "https://github.com/jlu5/icoextract")
    (synopsis "Extract icons from Windows executables")
    (description "Icoextract extracts icon resources from Windows executable
files.  Faugus Launcher uses its @command{icoextract} executable for optional
shortcut-icon extraction.")
    (license license:expat)))

(define-public faugus-launcher
  (package
    (name "faugus-launcher")
    (version "2.1.0-0.5b2316c")
    (source (package-source faugus-faugus-launcher-source))
    (build-system meson-build-system)
    (inputs
     (list bash-minimal cairo gdk-pixbuf glib gobject-introspection graphene gtk harfbuzz libadwaita libmanette pango python python-dbus
           python-icoextract python-pillow python-psutil python-pygobject
           python-requests python-vdf))
    (native-inputs (list gettext-minimal `(,gtk "bin")))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'disable-unattended-downloads
            (lambda _
              ;; An installed launcher must never fetch mutable game runtimes
              ;; merely because its user has no local components yet.
              (substitute* "faugus/runner.py"
                (("if not force_off or not self.components_exists:")
                 "if not force_off:")
                (("if self.proton_latest and \\(not force_off or not self.proton_exists\\):")
                 "if self.proton_latest and not force_off:"))))
          (add-before 'configure 'preserve-asset-license
            (lambda _
              (let ((licenses (string-append #$output "/share/licenses/faugus-launcher")))
                (mkdir-p licenses)
                (copy-file "assets/LICENSE" (string-append licenses "/ASSETS-LICENSE")))))
          (add-after 'install 'install-guix-wrapper
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (program (string-append bin "/faugus-launcher"))
                     (licenses (string-append #$output "/share/licenses/faugus-launcher"))
                     (python-path
                      (string-append #$output "/lib/python3.12/site-packages:"
                                     #$python-pygobject "/lib/python3.12/site-packages:"
                                     #$python-requests "/lib/python3.12/site-packages:"
                                     #$python-pillow "/lib/python3.12/site-packages:"
                                     #$python-vdf "/lib/python3.12/site-packages:"
                                     #$python-psutil "/lib/python3.12/site-packages:"
                                     #$python-dbus "/lib/python3.12/site-packages:"
                                     #$python-icoextract "/lib/python3.12/site-packages")))
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh\n" #$bash-minimal)
                    (display "if [ \"${1-}\" = --help ] || [ \"${1-}\" = -h ]; then\n  echo 'Usage: faugus-launcher [--shortcut FILE | --game FILE | --run COMMAND]'\n  exit 0\nfi\n" port)
                    (format port "export PYTHONPATH=~s\n" python-path)
                    (format port "export XDG_DATA_DIRS=~s\n" (string-append #$output "/share:" #$gtk "/share:" #$libadwaita "/share:" #$libmanette "/share"))
                    (format port "export GI_TYPELIB_PATH=~s\n" (string-append #$gtk "/lib/girepository-1.0:" #$libadwaita "/lib/girepository-1.0:" #$libmanette "/lib/girepository-1.0:" #$graphene "/lib/girepository-1.0:" #$pango "/lib/girepository-1.0:" #$gdk-pixbuf "/lib/girepository-1.0:" #$glib "/lib/girepository-1.0:" #$gobject-introspection "/lib/girepository-1.0:" #$cairo "/lib/girepository-1.0:" #$harfbuzz "/lib/girepository-1.0"))
                    (display "export FAUGUS_DISABLE_UPDATES=${FAUGUS_DISABLE_UPDATES:-1}\nexport UMU_RUNTIME_UPDATE=${UMU_RUNTIME_UPDATE:-0}\n" port)
                    (format port "exec ~a/bin/python3 -m faugus.tray_only \"$@\"\n" #$python)))
                (chmod program #o555)))))))
    (synopsis "GTK game launcher with opt-in runtime downloads")
    (description "Faugus Launcher is a GTK game launcher.  This package uses
only fixed free build inputs and disables unattended update and runtime
downloads by default; users may explicitly provide an external UMU runtime.")
    (home-page "https://github.com/Faugus/faugus-launcher")
    (license (list license:expat license:cc-by4.0 license:zlib license:cc0))))
