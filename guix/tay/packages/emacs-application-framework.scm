(define-module (tay packages emacs-application-framework)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system emacs)
  #:use-module (guix build-system pyproject)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages starred-d-h))

(define-public python-eaf-tld
  (package
    (name "python-eaf-tld")
    (version "0.13.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tld" version))
       (sha256
        (base32 "0l532wnfgyxhnn91a30gxz2bch1l6q9igi31fgv69xdwdj9h1v3m"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The sdist has no tests; upstream's suite also updates the suffix list
      ;; over the network.  Keep the shipped, dated list rather than fetching.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-notices
            (lambda _
              (for-each
               (lambda (file)
                 (install-file file
                               (string-append #$output "/share/doc/python-eaf-tld")))
               '("LICENSE.rst" "LICENSE_GPL2.0.txt" "LICENSE_LGPL_2.1.txt"
                 "LICENSE_MPL_1.1.txt")))))))
    (native-inputs (list python-setuptools python-setuptools-scm python-wheel))
    (home-page "https://github.com/barseghyanartur/tld")
    (synopsis "Extract top-level domains with a fixed public suffix list")
    (description "This library extracts top-level domain names from URLs using
its bundled public suffix list.  EAF uses it for browser domain handling.  The
list is installed without running the network-based updater.")
    ;; Select LGPL from the upstream tri-license; suffix data is MPL 2.0.
    (license (list license:lgpl2.1+ license:mpl2.0))))

(define eaf-demo-source
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/emacs-eaf/eaf-demo/tar.gz/"
                        "d210ef3834b2e4726299c99a4e2284dd0659e84c"))
    (file-name "eaf-demo-d210ef3.tar.gz")
    (sha256
     (base32 "0ngpd2l6x4j3jbdzj9vf9mnckw6b0936pyr3k7mffi9m0v7qz0v3"))))

(define eaf-python-inputs
  (list python-epc python-sexpdata python-pyqt-6 python-pyqtwebengine-6
        python-pyqt6-sip python-eaf-tld python-lxml python-qrcode python-requests))

(define eaf-python-search-path
  (map (lambda (input)
         (file-append
          (cadr input)
          (string-append "/lib/python"
                         (version-major+minor (package-version python))
                         "/site-packages")))
       (append (map (lambda (input) (list (package-name input) input))
                    eaf-python-inputs)
               (apply append
                      (map package-transitive-propagated-inputs
                           eaf-python-inputs)))))

(define-public emacs-eaf-emacs-application-framework
  (package
    (name "emacs-eaf-emacs-application-framework")
    (version "0-0.5fe1a6c")
    (source (package-source emacs-eaf-emacs-application-framework-source))
    (build-system emacs-build-system)
    (arguments
     (list
      ;; Keep upstream's relative layout: eaf.el locates Python, EPC, the app
      ;; catalog and apps beside itself.  Optional Emacs extensions (evil etc.)
      ;; and the imperative pip/npm/git installer are not installed.
      #:include #~'("^eaf\\.el$" "^eaf\\.py$" "^applications\\.json$"
                    "^core/" "^app/demo/(eaf-demo\\.el|buffer\\.py)$"
                    "^reinput/reinput$")
      #:tests? #f ; no upstream core test suite; native GUI proof lives in tests/
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'install-pinned-demo-and-runtime-path
            (lambda _
              (mkdir-p "app/demo")
              (invoke "tar" "xf" #$eaf-demo-source "--strip-components=1"
                      "-C" "app/demo")
              ;; The supported demo predates the core's symbol-valued registry.
              ;; Adapt only its registration, not its actual PyQt application.
              (substitute* "app/demo/eaf-demo.el"
                ((";;; Code:") ";;; Code:\n(require 'eaf)")
                (("\\(setq eaf-demo-module-path")
                 (string-append
                  "(defvar eaf-demo-keybinding nil)\n"
                  "(add-to-list 'eaf-app-binding-alist "
                  "'(\"demo\" . eaf-demo-keybinding))\n"
                  "(setq eaf-demo-module-path")))
              (substitute* "eaf.el"
                (("\\(defcustom eaf-python-command [^\n]*")
                 (string-append "(defcustom eaf-python-command \""
                                #$output "/bin/eaf-python\""))
                (("\"wmctrl") (string-append "\"" #$wmctrl "/bin/wmctrl"))
                (("\\$\\(wmctrl ")
                 (string-append "$(" #$wmctrl "/bin/wmctrl "))
                (("\\| awk ") (string-append "| " #$gawk "/bin/awk "))
                (("\"rm ")
                 (string-append "\"" #$coreutils-minimal "/bin/rm "))
                (("\"xdg-open")
                 (string-append "\"" #$xdg-utils "/bin/xdg-open")))))
          (add-before 'install 'build-reinput
            (lambda _
              ;; No capabilities, setuid bits or device access are granted.
              ;; Native Wayland users must arrange their own input permissions.
              (invoke "gcc" "reinput/main.c" "-o" "reinput/reinput"
                      "-pthread" "-I" (string-append #$libevdev "/include/libevdev-1.0")
                      "-I" (string-append #$libinput "/include")
                      "-I" (string-append #$eudev "/include")
                      "-L" (string-append #$libevdev "/lib")
                      "-L" (string-append #$libinput "/lib")
                      "-L" (string-append #$eudev "/lib")
                      (string-append "-Wl,-rpath," #$libevdev "/lib")
                      (string-append "-Wl,-rpath," #$libinput "/lib")
                      (string-append "-Wl,-rpath," #$eudev "/lib")
                      "-levdev" "-linput" "-ludev")))
          (add-after 'install 'install-python-wrapper-and-notices
            (lambda _
              (use-modules (srfi srfi-1))
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output
                         "/share/doc/emacs-eaf-emacs-application-framework")))
                (mkdir-p bin)
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md" "dependencies.json"))
                (install-file "app/demo/LICENSE" (string-append doc "/demo"))
                (install-file "app/demo/README.md" (string-append doc "/demo"))
                (call-with-output-file (string-append bin "/eaf-python")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/sh~%"
                             "export GUIX_PYTHONPATH=~s~%"
                             "export PYTHONDONTWRITEBYTECODE=1~%"
                             "export QT_PLUGIN_PATH=~s~%"
                             "exec ~a/bin/python3 \"$@\"~%")
                            #$bash-minimal
                            (string-join (delete-duplicates
                                          (list #$@eaf-python-search-path)) ":")
                            (string-append #$qtbase "/lib/qt6/plugins")
                            #$python)))
                (chmod (string-append bin "/eaf-python") #o555)))))))
    (native-inputs (list gcc-toolchain pkg-config))
    (inputs (append (list bash-minimal python wmctrl xdg-utils
                          coreutils-minimal gawk libinput libevdev eudev
                          qtbase qtwebengine)
                    eaf-python-inputs))
    (home-page "https://github.com/emacs-eaf/emacs-application-framework")
    (synopsis "Embed Qt applications in Emacs through a Python EPC bridge")
    (description "EAF is the Emacs Application Framework: an Emacs Lisp and
Python/Qt bridge that embeds applications in graphical Emacs.  This package
installs the pinned core, its native input helper, Python dependency closure,
and the separately pinned upstream Qt demo.  Load @code{eaf}, then
@code{eaf-demo}, and run @code{eaf-open-demo} to exercise the local application.
Other apps are separate upstream projects and are not included; browser, media
and provider integrations need their own dependencies and configuration.  The
imperative network installer is excluded, and user state remains outside the
immutable package tree.  Native Wayland input access is not granted by this
package.")
    (license (list license:gpl3+ license:bsd-3))))
