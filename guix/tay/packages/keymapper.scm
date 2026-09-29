;;; GNU Guix package for houmain/keymapper.

(define-module (tay packages keymapper)
  #:use-module (tay packages starred-d-h)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define-public keymapper
  (package
    (name "keymapper")
    ;; The channel's immutable snapshot pins commit 2ddd5cc, two commits after
    ;; the upstream 5.6.0 tag (d780e03); neither later commit changes Linux
    ;; behaviour (a Timeout.h include fix and a Windows-only spawn change).
    (version "5.6.0-0.2ddd5cc")
    (source (package-source houmain-keymapper-source))
    (build-system cmake-build-system)
    (arguments
     (list
      #:build-type "Release"
      #:configure-flags
      ;; Upstream derives VERSION from `git describe --tags`, which is not
      ;; available in an archive build; supply that command's exact result
      ;; for the pinned commit.  Every Linux integration is enabled
      ;; explicitly instead of relying on pkg-config discovery defaults.
      #~(list "-DVERSION=5.6.0-2-g2ddd5cc"
              "-DENABLE_TEST=ON"
              "-DENABLE_ADDRESS_SANITIZER=OFF"
              "-DENABLE_XKBCOMMON=ON"
              "-DENABLE_X11=ON"
              "-DENABLE_DBUS=ON"
              "-DENABLE_WAYLAND=ON"
              "-DENABLE_APPINDICATOR=ON")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'use-store-paths
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Notifications, "open configuration/help" and mapped
              ;; terminal commands would otherwise depend on whatever the
              ;; caller's PATH or /bin/sh happens to provide.
              (substitute* "src/client/unix/main.cpp"
                (("notify-send -a keymapper")
                 (string-append (search-input-file inputs "bin/notify-send")
                                " -a keymapper"))
                (("\"xdg-open \"")
                 (string-append "\"" (search-input-file inputs "bin/xdg-open")
                                " \""))
                (("execl\\(\"/bin/sh\"")
                 (string-append "execl(\""
                                (search-input-file inputs "bin/sh") "\"")))
              ;; Upstream installs the autostart entry to ../etc relative to
              ;; its /usr prefix.  $out/etc/xdg would be on XDG_CONFIG_DIRS
              ;; in a profile and start the client at every login, so keep
              ;; the entry as an inert template for users to copy instead.
              (substitute* "CMakeLists.txt"
                (("DESTINATION \\.\\./etc") "DESTINATION share/keymapper"))
              ;; systemd requires an absolute ExecStart, and the autostart
              ;; template must not depend on the session PATH.
              (substitute* "extra/lib/systemd/system/keymapperd.service"
                (("ExecStart=keymapperd")
                 (string-append "ExecStart=" #$output "/bin/keymapperd")))
              (substitute* "extra/xdg/autostart/keymapper.desktop"
                (("Exec=keymapper")
                 (string-append "Exec=" #$output "/bin/keymapper")))))
          (replace 'check
            ;; Upstream registers no CTest tests; its Catch suite is the
            ;; test-keymapper executable.  It exercises the parser, matcher
            ;; and server state machine in memory, without uinput or any
            ;; input device.
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "./test-keymapper" "--durations" "yes"))))
          (add-after 'install 'install-notices
            ;; The generated Wayland protocol code linked into keymapper is
            ;; under the permission notice embedded in this protocol file.
            (lambda _
              (let ((xml "wlr-foreign-toplevel-management-unstable-v1.xml"))
                ;; The source directory is named after the snapshot, so
                ;; locate the protocol file from the build directory.
                (install-file
                 (car (find-files ".." (lambda (file stat)
                                         (string=? (basename file) xml))))
                 (string-append #$output "/share/doc/keymapper"))))))))
    (native-inputs (list pkg-config wayland))
    (inputs (list bash-minimal
                  dbus
                  eudev
                  gtk+
                  libappindicator
                  libnotify
                  libusb
                  libx11
                  libxkbcommon
                  wayland
                  xdg-utils))
    (home-page "https://github.com/houmain/keymapper")
    (synopsis "Context-aware keyboard and mouse remapper")
    (description
     "Keymapper remaps keys, key sequences and mouse buttons according to a
text configuration file, and can select mappings by the focused window, its
title, path or input device.  The package provides @command{keymapperd}, which
grabs input devices and needs explicit uinput and input-device permission at
runtime; @command{keymapper}, the per-user client that loads the configuration
and tracks context through X11, Wayland or D-Bus; and @command{keymapperctl},
which controls a running client.  Installation activates nothing: no udev rule
or service is enabled, and the login autostart entry is only provided as a
template under @file{share/keymapper/xdg/autostart}.")
    ;; README and the about text say "GNU GPLv3"/"version 3" with no
    ;; or-later grant; the Catch test header is Boost-1.0 and the linked
    ;; Wayland protocol code carries an HPND permission notice.
    (license (list license:gpl3 license:boost1.0 license:hpnd))))
