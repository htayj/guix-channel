;;; GNU Guix package for the Gruesome console roguelike.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages gruesome)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pascal))

(define-public gruesome
  (package
    (name "gruesome")
    (version "0.0.3")
    (source
     (origin
       (method url-fetch)
       (uri "http://www.gamesofgrey.com/games/gruesome/gruesome0.0.3.zip")
       (sha256
        (base32
         "1w482gxkvh8ln3d9hyyq7b9akhzr3s3mi6d37a4s79jlb7afxm1g"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The archive contains a single Free Pascal program and no upstream
      ;; configure or check targets.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              (mkdir-p "build/units")
              (invoke #$(file-append fpc "/bin/fpc")
                      "-O2" "-g-"
                      "-FUbuild/units" "-FEbuild"
                      "-obuild/gruesome-real" "source.pas")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (real-dir (string-append out "/libexec"))
                     (real (string-append real-dir "/gruesome-real"))
                     (doc (string-append out "/share/doc/gruesome"))
                     (launcher (string-append bin "/gruesome")))
                (mkdir-p bin)
                (mkdir-p real-dir)
                (mkdir-p doc)
                (install-file "build/gruesome-real" real-dir)
                ;; These are the complete upstream notices.  The archive's
                ;; Windows executable is intentionally not installed.
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "readme.txt" "history.txt"
                            "source.pas"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/bash~%set -eu~%"
                            #$(file-append bash-minimal))
                    (format port "exec ~s \"$@\"~%" real)))
                (chmod launcher #o555)))))))
    (native-inputs
     (list fpc unzip))
    (inputs
     (list bash-minimal))
    (home-page "http://www.gamesofgrey.com/games/gruesome/")
    (properties
     '((upstream-name . "gruesome")
       (release-monitoring-url
        . "http://www.gamesofgrey.com/games/gruesome/")
       ;; Upstream joins the project name and version without a separator.
       ;; The generic updater requires exactly one capture for the version.
       (release-file-regexp . "^gruesome([0-9]+\\.[0-9]+\\.[0-9]+)\\.zip$")))
    (synopsis "Console roguelike about a grue in procedurally generated caves")
    (description
     "Gruesome is a console roguelike in which the player controls a grue
that explores randomly generated caverns, avoids torchlight, and hunts
adventurers.  This package builds the pinned upstream Pascal source with Free
Pascal, installs the complete upstream documentation and GPL notice, and
does not install the opaque Windows executable shipped in the archive.  The
launcher runs the native game directly in the player's terminal.")
    (license license:gpl3+)))
