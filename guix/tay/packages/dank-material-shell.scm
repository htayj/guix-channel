;;; DankMaterialShell variant respecting disabled external application theming.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages dank-material-shell)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((gnu packages) #:select (search-patches))
  #:use-module (gnu packages window-management))

(define-public dank-material-shell-shell-only
  (let ((patched-source
         (origin
           (inherit (package-source dank-material-shell))
           (patches
            (append (origin-patches (package-source dank-material-shell))
                    (search-patches
                     "tay/packages/patches/dank-material-shell-shell-only-icon-guard.patch")))
           ;; Do not silently accept changed QML context on an upstream update.
           (patch-flags '("-p1" "--fuzz=0")))))
    (package
      (inherit dank-material-shell)
      (name "dank-material-shell-shell-only")
      (source patched-source)
      (arguments
       (substitute-keyword-arguments (package-arguments dank-material-shell)
         ((#:phases phases)
          #~(modify-phases #$phases
              ;; Upstream captures its original source in this phase rather
              ;; than copying the unpacked tree.  Use our patched origin here.
              (replace 'install-config
                (lambda _
                  (let ((target (string-append #$output "/share/quickshell")))
                    (mkdir-p target)
                    (copy-recursively
                     (string-append #$patched-source "/quickshell")
                     target))))))))
      (synopsis "Desktop shell respecting external application theming settings")
      (description
       (string-append
        (package-description dank-material-shell)
        "  This variant honors disabled GTK and Qt theming settings and
DMS_DISABLE_MATUGEN when applying icon themes.  Icon changes never purge user
caches or signal unrelated applications.  The shell's icon selection setting
and normal icon resolution remain available; its Qt platform theme determines
application icon rendering.")))))
