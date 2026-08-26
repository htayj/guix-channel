;;; GNU Guix package for aap/blincolnlights.

(define-module (tay packages blincolnlights)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl))

(define-public blincolnlights
  (package
    (name "blincolnlights")
    ;; Upstream has no releases.  This commit was selected after auditing the
    ;; host emulators and virtual panels below.  The Lua gitlink is deliberately
    ;; not fetched: none of the selected programs needs it.
    (version "0-932d2ce")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/aap/blincolnlights")
             (commit "932d2cedfaec3368d6e1890b15645decc4815429")
             (recursive? #f)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1dq8h2y8hc7avszsb36b5war8cahkiyyig3z1fx7f1fhxb6246s9"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;Upstream has no test suite.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'use-guix-toolchain
            (lambda _
              ;; Only the SDL virtual panels need SDL2_image.  Obtain its
              ;; include and library flags through pkg-config rather than
              ;; embedding host paths in the derivation.
              (for-each
               (lambda (makefile)
                 (substitute* makefile
                   (("\\$\\(CC\\) -g -I\\.\\. -o \\$@ \\$\\^ -lSDL2 -lSDL2_image")
                    (string-append
                     "$(CC) $(shell pkg-config --cflags sdl2 SDL2_image)"
                     " -g -I.. -o $@ $^"
                     " $(shell pkg-config --libs sdl2 SDL2_image)"))))
               '("vpanel_b18/Makefile" "vpanel_pdp1/Makefile"
                 "vpanel_whirlwind/Makefile"))
              ;; These Makefiles spell the compiler literally as `cc`.
              (for-each
               (lambda (makefile)
                 (substitute* makefile
                   (("cc -") "$(CC) -")))
               '("pdp1/Makefile" "pdp5/Makefile" "tx0/Makefile"
                 "whirlwind/Makefile"))))
          (replace 'build
            (lambda _
              ;; Do not call the root Makefile: it also builds GPIO, Raspberry
              ;; Pi, peripheral, and Lua-dependent targets that are outside
              ;; this package.
              (for-each
               (lambda (directory)
                 (invoke "make" "-C" directory
                         (string-append "CC=" #$(cc-for-target))))
               '("vpanel_b18" "vpanel_pdp1" "vpanel_whirlwind" "pdp1"
                 "pdp5" "tx0" "whirlwind" "tools"))))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec/blincolnlights"))
                     (data (string-append #$output "/share/blincolnlights/pdp1"))
                     (doc (string-append #$output "/share/doc/blincolnlights")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                ;; PNG artwork is compiled into these three panel binaries.
                (install-file "vpanel_b18/panel_b18" bin)
                (rename-file (string-append bin "/panel_b18")
                             (string-append bin "/blincolnlights-panel-b18"))
                (install-file "vpanel_pdp1/panel_pdp1" bin)
                (rename-file (string-append bin "/panel_pdp1")
                             (string-append bin "/blincolnlights-panel-pdp1"))
                (install-file "vpanel_whirlwind/panel_whirlwind" bin)
                (rename-file (string-append bin "/panel_whirlwind")
                             (string-append bin "/blincolnlights-panel-whirlwind"))
                (for-each
                 (lambda (spec)
                   (install-file (car spec) libexec)
                   (rename-file (string-append libexec "/" (basename (car spec)))
                                (string-append libexec "/" (cdr spec))))
                 '(("pdp1/pdp1" . "pdp1")
                   ("pdp1/pdp1_b18" . "pdp1-b18")
                   ("pdp5/pdp5" . "pdp5")
                   ("tx0/tx0_pdp1" . "tx0-pdp1")
                   ("tx0/tx0_b18" . "tx0-b18")
                   ("whirlwind/whirlwind" . "whirlwind")
                   ("whirlwind/whirlwind_b18" . "whirlwind-b18")))
                (for-each (lambda (program) (install-file program bin))
                          '("tools/mkptyfl" "tools/mkptyfio"))
                (copy-recursively "pdp1/maindec" (string-append data "/maindec"))
                (copy-recursively "pdp1/tapes" (string-append data "/tapes"))
                ;; pdp1/main.c names dpys5.rim, while the fixed source ships
                ;; its compatible ddt.rim image under that name only.
                (symlink "ddt.rim" (string-append data "/tapes/dpys5.rim"))
                (install-file "LICENSE" doc)
                (install-file "README.md" doc)
                (call-with-output-file (string-append doc "/README.guix")
                  (lambda (port)
                    (display
                     "Host emulators run in per-user XDG state directories.\n\
Their panel files are the shared fixed paths /tmp/b18_panel, /tmp/pdp1_panel,\n\
and /tmp/whirlwind_panel.  Their documented TCP ports are not isolated; run a\n\
single compatible user/session per panel and port.\n"
                     port)))
                ;; These emulators write coremem and/or punch.out relative to
                ;; their working directory.  Keep that state out of the store
                ;; and make the packaged PDP-1 data visible at its expected
                ;; relative paths for every launcher.
                (for-each
                 (lambda (spec)
                   (let ((launcher (string-append bin "/blincolnlights-" (car spec)))
                         (program (string-append libexec "/" (cdr spec))))
                     (call-with-output-file launcher
                       (lambda (port)
                         (format port "#!~a~%" #$(file-append bash "/bin/sh"))
                         (display
                          "state_root=\"${XDG_STATE_HOME:-$HOME/.local/state}\"\n"
                         port)
                         (format port
                                 (string-append
                                  "state=\"$state_root/blincolnlights/"
                                  "blincolnlights-~a\"~%")
                                 (car spec))
                         (format port "~a -p \"$state\"~%"
                                 #$(file-append coreutils "/bin/mkdir"))
                         (format port "~a -sfn ~s \"$state/maindec\"~%"
                                 #$(file-append coreutils "/bin/ln")
                                 (string-append data "/maindec"))
                         (format port "~a -sfn ~s \"$state/tapes\"~%"
                                 #$(file-append coreutils "/bin/ln")
                                 (string-append data "/tapes"))
                         (display "cd \"$state\"\n" port)
                         (format port "exec ~s \"$@\"~%" program)))
                     (chmod launcher #o555)))
                 '(("pdp1" . "pdp1")
                   ("pdp1-b18" . "pdp1-b18")
                   ("pdp5" . "pdp5")
                   ("tx0-pdp1" . "tx0-pdp1")
                   ("tx0-b18" . "tx0-b18")
                   ("whirlwind" . "whirlwind")
                   ("whirlwind-b18" . "whirlwind-b18")))))))))
    (native-inputs (list pkg-config))
    (inputs (list sdl2 sdl2-image))
    (synopsis "Virtual front panels and emulators for historic computers")
    (description
     "Blincolnlights provides SDL virtual front panels for the Blincolnlights
18, PDP-1, and Whirlwind, together with host emulators for the Whirlwind,
TX-0, PDP-1, and PDP-5.  The host-emulator launchers keep mutable core and
punch state in @code{$XDG_STATE_HOME/blincolnlights}; each also exposes the
packaged PDP-1 tapes and diagnostics there.  Panels communicate through the
fixed shared files @file{/tmp/b18_panel}, @file{/tmp/pdp1_panel}, and
@file{/tmp/whirlwind_panel}; the emulators also use fixed TCP ports.  They are
therefore intended for a single user/session at a time and do not provide
network isolation.")
    (home-page "https://github.com/aap/blincolnlights")
    (license license:expat)))
