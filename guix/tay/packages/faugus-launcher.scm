;;; GNU Guix package for Faugus Launcher.

(define-module (tay packages faugus-launcher)
  #:use-module (guix build-system meson)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages freedesktop)
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

;; assets/gamecontrollerdb.txt is the unmodified Git blob
;; 4f5607a1d29260368b37604962f309651aca9395 from SDL_GameControllerDB at
;; 513c72e34569e0f471dde7aa26eecb23946c3ef7.  Preserve its original LICENSE:
;; https://github.com/mdqinc/SDL_GameControllerDB/blob/
;; 513c72e34569e0f471dde7aa26eecb23946c3ef7/LICENSE
(define %gamecontrollerdb-license
  (plain-file
   "SDL_GameControllerDB-LICENSE"
   "Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>
  
This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
  
1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required. 
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

"))

(define-public faugus-launcher
  (package
    (name "faugus-launcher")
    (version "2.1.0-0.5b2316c")
    (source (package-source faugus-faugus-launcher-source))
    (build-system meson-build-system)
    (inputs
     ;; GObject Introspection supplies runtime cairo/fontconfig/freetype/xlib
     ;; typelibs needed by GTK and Pango; it is not just a build tool here.
     (list bash-minimal cairo gdk-pixbuf glib gobject-introspection graphene gtk
           harfbuzz libadwaita libmanette pango python python-dbus
           python-icoextract python-pillow python-psutil python-pygobject
           python-requests python-vdf shared-mime-info))
    (native-inputs
     (list (list "gettext-minimal" gettext-minimal)
           (list "gtk:bin" gtk "bin")))
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
                (((string-append "if self.proton_latest and "
                                 "\\(not force_off or not self.proton_exists\\):"))
                 "if self.proton_latest and not force_off:"))))
          (add-before 'configure 'preserve-asset-license
            (lambda _
              (let ((licenses
                     (string-append #$output "/share/licenses/faugus-launcher")))
                (mkdir-p licenses)
                (copy-file "assets/LICENSE"
                           (string-append licenses "/ASSETS-LICENSE"))
                (copy-file #$%gamecontrollerdb-license
                           (string-append licenses
                                          "/SDL_GameControllerDB-LICENSE")))))
          (add-after 'install 'install-guix-wrapper
            (lambda _
              (let* ((program (string-append #$output "/bin/faugus-launcher"))
                     (site-packages
                      (string-append #$output "/lib/python3.12/site-packages")))
                ;; Keep upstream's shortcut/game/run dispatch and tray bootstrap.
                ;; The bootstrap opens the GUI unless configured to start hidden.
                (substitute* program
                  (("^#!/bin/sh")
                   (string-append "#!" #$bash-minimal "/bin/sh"))
                  (("SCRIPT_DIR=.*")
                   (string-append "SCRIPT_DIR=" site-packages "\n"))
                  (("/usr/bin/python3")
                   (string-append #$python "/bin/python3"))
                  (("export GTK_IM_MODULE=.*" line)
                   (string-append
                    line
                    "export FAUGUS_DISABLE_UPDATES="
                    "${FAUGUS_DISABLE_UPDATES:-1}\n"
                    "export UMU_RUNTIME_UPDATE=${UMU_RUNTIME_UPDATE:-0}\n")))
                (wrap-program program
                  #:sh (string-append #$bash-minimal "/bin/bash")
                  `("PYTHONPATH" prefix
                    (,site-packages ,(getenv "GUIX_PYTHONPATH")))
                  `("PATH" prefix (,(string-append #$python-icoextract "/bin")))
                  ;; The Meson phase builds this combined raster/SVG cache,
                  ;; but its environment does not survive into installed runs.
                  `("GDK_PIXBUF_MODULE_FILE" =
                    (,(string-append #$output
                                     "/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache")))
                  `("XDG_DATA_DIRS" prefix
                    (,(string-append #$output "/share")
                     ,(string-append #$gtk "/share")
                     ,(string-append #$libadwaita "/share")
                     ,(string-append #$libmanette "/share")
                     ;; GdkPixbuf uses GIO MIME sniffing, including for its
                     ;; built-in PNG/JPEG decoders, not only loader signatures.
                     ,(string-append #$shared-mime-info "/share")))
                  `("GI_TYPELIB_PATH" prefix
                    (,(string-append #$gtk "/lib/girepository-1.0")
                     ,(string-append #$libadwaita "/lib/girepository-1.0")
                     ,(string-append #$libmanette "/lib/girepository-1.0")
                     ,(string-append #$graphene "/lib/girepository-1.0")
                     ,(string-append #$pango "/lib/girepository-1.0")
                     ,(string-append #$gdk-pixbuf "/lib/girepository-1.0")
                     ,(string-append #$glib "/lib/girepository-1.0")
                     ,(string-append #$gobject-introspection
                                     "/lib/girepository-1.0")
                     ,(string-append #$cairo "/lib/girepository-1.0")
                     ,(string-append #$harfbuzz "/lib/girepository-1.0"))))))))))
    (synopsis "GTK game launcher with opt-in runtime downloads")
    (description "Faugus Launcher is a GTK game launcher.  This package uses
only fixed free build inputs and disables unattended update and runtime
downloads by default; users may explicitly provide an external UMU runtime.")
    (home-page "https://github.com/Faugus/faugus-launcher")
    (license (list license:expat license:cc-by4.0 license:zlib license:cc0))))
