;;; GNU Guix package for Frostbite, a DragonRealms MUD client.

(define-module (tay packages frostbite)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages ruby))

(define-public frostbite
  (package
    (name "frostbite")
    (version "1.18.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/matoom/frostbite")
             (commit "21e6306d0600dcc0301bc66c3c886d56056827d2")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1swfvihr9if6hqwim6bd26y7s113p24v5zvgj6if3dw3nxfjks4y"))
       (patches
        (search-patches "tay/packages/patches/frostbite-xdg-state.patch"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; Building the top-level qmake project builds both the client
              ;; and the separately-defined tests/testxml executable.  Debug
              ;; suppresses upstream's release-bundle copier: that copier
              ;; vendors Qt libraries and a second mutable application tree.
              (invoke #$(file-append qtbase-5 "/bin/qmake")
                      "FrostBite.pro" "CONFIG+=debug" "CONFIG-=release")
              (invoke "make" "-j2")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "env" "QT_QPA_PLATFORM=offscreen" "tests/testxml"))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (share (string-append out "/share/frostbite"))
                     (doc (string-append out "/share/doc/frostbite"))
                     (licenses (string-append doc "/licenses")))
                (mkdir-p bin)
                (install-file "Frostbite" bin)
                (rename-file (string-append bin "/Frostbite")
                             (string-append bin "/frostbite"))

                ;; These are program resources.  The XDG patch copies only
                ;; the initial profile and client configuration to user paths.
                (copy-recursively "deploy/common/scripts"
                                  (string-append share "/scripts"))
                (copy-recursively "deploy/common/maps"
                                  (string-append share "/maps"))
                (copy-recursively "deploy/common/sounds"
                                  (string-append share "/sounds"))
                (copy-recursively "deploy/common/security"
                                  (string-append share "/security"))
                (copy-recursively "deploy/linux/profiles"
                                  (string-append share "/profiles"))
                (mkdir-p (string-append share "/config"))
                (install-file "deploy/common/client.ini"
                              (string-append share "/config"))
                (install-file "deploy/common/log.ini" share)

                (mkdir-p (string-append out "/share/applications"))
                (call-with-output-file
                    (string-append out "/share/applications/frostbite.desktop")
                  (lambda (port)
                    (display "[Desktop Entry]\n" port)
                    (display "Name=Frostbite\n" port)
                    (display "Comment=DragonRealms MUD client\n" port)
                    (display "Exec=frostbite\nIcon=frostbite\n" port)
                    (display "Terminal=false\nType=Application\n" port)
                    (display "Categories=Game;RolePlaying;\n" port)))
                (let ((icons (string-append out
                                             "/share/icons/hicolor/64x64/apps")))
                  (mkdir-p icons)
                  (copy-file "gui/images/shield_64.png"
                             (string-append icons "/frostbite.png")))

                ;; The upstream repository's README is its MIT notice.  The
                ;; bundled Log4Qt, Qt Solutions, and Cleanlooks source carries
                ;; the Apache-2.0, BSD-3-Clause, and Qt license notices.
                (mkdir-p licenses)
                (install-file "README.md" doc)
                (install-file "log4qt/LICENSE-2.0.txt" licenses)
                (install-file "log4qt/NOTICE.txt" licenses)
                (install-file "singleapp/qtlocalpeer.cpp" licenses)
                (install-file "cleanlooks/qcleanlooksstyle.cpp" licenses))))
          (add-after 'install 'wrap-runtime
            (lambda _
              (wrap-program (string-append #$output "/bin/frostbite")
                `("FROSTBITE_RESOURCE_DIR" =
                  (,(string-append #$output "/share/frostbite")))
                `("PATH" prefix
                  (,(string-append #$ruby "/bin")))))))))
    (native-inputs
     (list qtbase-5))
    (inputs
     (list bash-minimal qtbase-5 qtmultimedia-5 ruby))
    (home-page "https://github.com/matoom/frostbite")
    (synopsis "Qt MUD client for DragonRealms")
    (description
     "Frostbite is a graphical MUD client for DragonRealms.  It provides
windowed game output, scripting through Ruby, sound notifications, profiles,
logging, maps, and snapshots.  The package installs immutable resources below
@file{share/frostbite}; client configuration, profiles, logs, API settings,
and snapshots are kept in the XDG user directories.")
    ;; Frostbite identifies itself as MIT in README.md.  It bundles Apache-2.0
    ;; Log4Qt, BSD-3-Clause Qt Solutions single-application code, and
    ;; Cleanlooks source offered under LGPL-2.1 with the Qt exception or GPL-3.
    (license (list license:expat license:asl2.0 license:bsd-3
                   license:lgpl2.1 license:gpl3))))
