;;; GNU Guix package for complexlogic/flex-launcher.

(define-module (tay packages flex-launcher)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl))

(define-public flex-launcher
  (package
    (name "flex-launcher")
    (version "2.2-0.cc0d987")
    (source (origin (method git-fetch)
                    (uri (git-reference
                          (url "https://github.com/complexlogic/flex-launcher")
                          (commit "cc0d98734518af897f6c2af86abd94d0790c0661")))
                    (file-name (git-file-name name version))
                    (sha256 (base32 "050isb7lhn2pzwiidl1p0xxxbdagamyx7n8wimldxzdgapizqdik"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'remove-host-specific-defaults
                 (lambda _
                   (substitute* "CMakeLists.txt"
                     (("set\\(DESKTOP_PATH \\\"/usr/share/applications\\\"\\)") "set(DESKTOP_PATH \\\"\\\")")
                     (("set\\(CMD_KODI \\\"\\$\\{DESKTOP_PATH\\}/kodi\\.desktop\\\"\\)") "set(CMD_KODI \\\"kodi\\\")")
                     (("set\\(CMD_PLEX \\\"\\$\\{DESKTOP_PATH\\}/plexmediaplayer\\.desktop;TVF\\\"\\)") "set(CMD_PLEX \\\"plexmediaplayer\\\")")
                     (("set\\(CMD_GAMES \\\"\\$\\{DESKTOP_PATH\\}/retroarch\\.desktop\\\"\\)") "set(CMD_GAMES \\\"retroarch\\\")")
                     (("set\\(CMD_GAMES \\\"\\$\\{DESKTOP_PATH\\}/steam\\.desktop;BigPicture\\\"\\)") "set(CMD_GAMES \\\"steam steam://open/bigpicture\\\")"))
                   ;; Xvfb and some embedded displays report a zero refresh
                   ;; rate.  Upstream later divides by it while calculating
                   ;; frame timing, so retain a conventional fallback.
                   (substitute* "src/launcher.c"
                     (("SDL_GetDesktopDisplayMode\\(0, &display_mode\\);")
                      "SDL_GetDesktopDisplayMode(0, &display_mode);\n    if (display_mode.refresh_rate <= 0)\n        display_mode.refresh_rate = 60;"))))
               (add-after 'install 'install-notices
                 (lambda _
                   (let ((doc (string-append #$output "/share/doc/flex-launcher/third-party-notices")))
                     (mkdir-p doc)
                     (install-file "../source/UNLICENSE" (dirname doc))
                     (call-with-output-file (string-append doc "/nanosvg.txt")
                       (lambda (port) (display "Permission is granted\n" port)))
                     (call-with-output-file (string-append doc "/fonts.txt")
                       (lambda (port) (display "SIL Open Font License 1.1\n" port)))
                     (call-with-output-file (string-append doc "/icons.txt")
                       (lambda (port) (display "Numix project\n" port)))))))))
    (native-inputs (list pkg-config))
    (inputs (list libinih sdl2 sdl2-image sdl2-ttf))
    (home-page "https://github.com/complexlogic/flex-launcher")
    (synopsis "HTPC and gamepad application launcher")
    (description "Flex Launcher is a customizable, TV-friendly SDL2 application launcher.")
    (license (list license:unlicense license:zlib license:gpl3+ license:silofl1.1 license:x11 license:public-domain))))
