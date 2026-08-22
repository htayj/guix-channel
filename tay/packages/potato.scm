;;; GNU Guix package for Potato, a graphical MUSH client.

(define-module (tay packages potato)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages tcl))

(define-public potato
  (package
    (name "potato")
    (version "2.0.0b19")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/potatomushclient/potato")
             ;; 2.0.0b19 is an annotated tag.  Pin the dereferenced release
             ;; commit so this package does not depend on a mutable ref.
             (commit "8f187da3ceddcc0e355f0f14d2060ed381d73bc3")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "17cbcrrraba9cn3zq9px1fls4188ifgxvhf4azgg1iydz95imb6w"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Potato is a Tcl/Tk source tree rather than a compiled project.  The
      ;; Linux launcher below supplies Guix's wish executable and the pinned
      ;; application tree remains under a private libexec directory.
      #:install-plan
      #~'(("potato.vfs/" "libexec/potato/")
          ("potato.vfs/tools/linux/potato.desktop"
           "share/applications/potato.desktop")
          ("potato.vfs/tools/linux/potato.png"
           "share/icons/hicolor/55x55/apps/potato.png"))
      #:phases
      #~(modify-phases %standard-phases
          ;; The upstream Starkit source includes Windows DLLs, macOS
          ;; dylibs, and a Linux linflash extension that compiles itself in a
          ;; user's profile.  TLS is disabled below because the available Tcl
          ;; TLS API cannot validate host names; Potato's own no-op
          ;; taskbar-flash fallback handles notifications.  Removing these
          ;; artifacts also keeps an
          ;; unsupported foreign binary out of the store closure.
          (add-after 'unpack 'remove-foreign-bundles
            (lambda _
              (use-modules (guix build utils))
              (for-each delete-file-recursively
                        '("potato.vfs/lib/app-potato/windows"
                          "potato.vfs/lib/app-potato/macosx"
                          "potato.vfs/lib/app-potato/linux"))))
          ;; A Guix package manager, rather than Potato's obsolete HTTP
          ;; version endpoint, is responsible for updates.  Keep manual
          ;; networking features available, but never schedule a background
          ;; request merely because the graphical client was launched.
          (add-after 'remove-foreign-bundles 'disable-background-update-check
            (lambda _
              (use-modules (guix build utils))
              (substitute* "potato.vfs/lib/potato-config.tcl"
                (("set misc\\(checkForUpdates\\) 1")
                 "set misc(checkForUpdates) 0"))
              ;; potato.custom and an existing potato.ini are read after the
              ;; defaults above.  Disable the scheduling site itself, which
              ;; occurs after those user-controlled files, so an old profile
              ;; cannot restore the obsolete cleartext-HTTP update request.
              (invoke "sed" "-i"
                      (string-append
                       "s|if { $misc(checkForUpdates) } {|if {0} { ;# "
                       "Guix package disables scheduled cleartext update checks|")
                      "potato.vfs/lib/potato.tcl")))
          ;; Upstream deliberately imports TLS with certificate validation
          ;; disabled.  Guix's Tcl TLS extension can validate a chain, but its
          ;; API has no hostname-validation operation for this client.  Do not
          ;; offer a transport that cannot authenticate the requested host.
          ;; Force the unavailable branch even if a user adds Tcl TLS to an
          ;; ambient Tcl search path, so there is no insecure fallback.
          (add-after 'disable-background-update-check 'disable-insecure-tls
            (lambda _
              (use-modules (guix build utils))
              ;; This source is ISO-8859-1 rather than UTF-8, which the
              ;; Scheme text substitution helper rejects.  GNU sed edits the
              ;; ASCII-only condition byte-for-byte.
              (invoke "sed" "-i"
                      (string-append
                       "s|if { \\[catch {package require tls 1.6.7-} "
                       "reqtls errdict\\] } {|if {1} { set reqtls {TLS "
                       "disabled by the Guix package: Tcl TLS lacks "
                       "hostname validation}; set errdict {}|")
                      "potato.vfs/lib/potato.tcl")))
          ;; Check every retained Tcl source/module without executing it or
          ;; contacting a network service.  This catches a truncated or
          ;; malformed source snapshot while leaving runtime behavior to the
          ;; installed Xvfb smoke test.
          (add-after 'disable-insecure-tls 'check-tcl-syntax
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let ((files (find-files "." "\\.(tcl|tm)$")))
                (call-with-output-file "potato-tcl-syntax-check.tcl"
                  (lambda (port)
                    (display
                     (string-append
                      "set failed 0\n"
                      "foreach file $argv {\n"
                      "  set fd [open $file r]\n"
                      "  fconfigure $fd -encoding utf-8\n"
                      "  set source [read $fd]\n"
                      "  close $fd\n"
                      "  if {![info complete $source]} {\n"
                      "    puts stderr [format {incomplete Tcl source: %s} $file]\n"
                      "    set failed 1\n"
                      "  }\n"
                      "}\n"
                      "exit $failed\n")
                     port)))
                (apply invoke
                       (append (list (search-input-file inputs "bin/tclsh")
                                     "potato-tcl-syntax-check.tcl")
                               files))
                (delete-file "potato-tcl-syntax-check.tcl"))))
          ;; The generic copy phases would rewrite source shebangs and the
          ;; upstream desktop file.  The launcher does not use the source
          ;; shebang, and preserving the desktop entry keeps its documented
          ;; Exec=potato/Icon=potato contract intact.
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (delete 'patch-shebangs)
          (delete 'patch-dot-desktop-files)
          (delete 'strip)
          (delete 'make-dynamic-linker-cache)
          (delete 'compress-documentation)
          (delete 'install-license-files)
          (add-after 'install 'install-launcher-and-notices
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((bin (string-append #$output "/bin"))
                     (launcher (string-append bin "/potato"))
                     (doc (string-append #$output "/share/doc/potato")))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     "if test \"${1-}\" = \"--version\"; then\n"
                     port)
                    (format port
                            "    printf '%s\\n' 'Potato MU* Client ~a'\n"
                            #$version)
                    (display
                     (string-append
                      "    exit 0\n"
                      "fi\n"
                      "exec " #$tk "/bin/wish " #$output
                      "/libexec/potato/main.tcl \"$@\"\n")
                     port)))
                (chmod launcher #o555)
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("README.md"
                            "potato.vfs/INSTALL"
                            "potato.vfs/MANIFEST"
                            "potato.vfs/LICENSE"))
                ;; base64-2.4.2.tm is vendored Tcllib code and points readers
                ;; at license.terms.  Install Guix tcllib's canonical Tcl/Tk
                ;; terms without reformatting or excerpting them.
                (copy-file
                 (search-input-file
                  inputs "share/doc/tcllib-1.19/license.terms")
                 (string-append doc "/tcllib-license.terms"))
                ;; Keep an explicit audit trail for the bundled Tcl code.  No
                ;; standalone license file was present for ListboxDnD or
                ;; treeviewUtils in the pinned upstream tree; their source
                ;; files remain under libexec/potato with their attribution
                ;; comments intact.
                (call-with-output-file
                    (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display
                     (string-append
                      "Potato bundled-component audit\n"
                      "===============================\n\n"
                      "The application is distributed under the MIT/Expat\n"
                      "license; see LICENSE.\n\n"
                      "base64-2.4.2.tm: Tcllib base64 implementation.  Its\n"
                      "source directs readers to license.terms; canonical\n"
                      "Tcl/Tk terms from Guix tcllib 1.19 are installed\n"
                      "verbatim as tcllib-license.terms.\n\n"
                      "crossplatform/listboxdnd/listboxdnd.tcl (ListboxDnD):\n"
                      "bundled Tcl\n"
                      "module; the pinned upstream tree contains no separate\n"
                      "license file, so the original source is retained\n"
                      "unchanged under libexec/potato.\n\n"
                      "treeviewUtils/treeviewUtils.tcl: modified Tcl widget\n"
                      "utility (the source credits Keith Vetter's Tcl Wiki\n"
                      "code); the pinned upstream tree contains no separate\n"
                      "license file, so the original source is retained\n"
                      "unchanged under libexec/potato.\n\n"
                      "Foreign Windows and macOS binary extensions and the\n"
                      "self-compiling Linux linflash source are excluded from\n"
                      "this Linux package.  TLS is disabled because the\n"
                      "available Tcl TLS API lacks hostname validation.\n")
                     port)))))))))
    (inputs
     (list bash-minimal
           tcl
           tk))
    (native-inputs
     (list tcllib))
    (synopsis "Graphical Tcl/Tk MUSH client")
    (description
     "Potato is a graphical MUSH client written in Tcl/Tk.  It supports
Telnet, scripting, triggers, aliases, events, logging, and multiple worlds.
This Linux package installs the pinned Tcl source
tree, runtime modules, desktop entry, icon, and license notices; Guix's Tcl
and Tk provide the runtime without downloading a Tclkit or plugin.  TLS is
disabled: the available Tcl TLS API cannot validate a server
host name, and upstream otherwise accepts invalid certificates.  The upstream
Windows and macOS binary extensions and self-compiling Linux
linflash helper are excluded.  Profiles, worlds, logs, plugins, and other
mutable state remain under the user's home directory outside the store.")
    (home-page "https://github.com/potatomushclient/potato")
    (license (list license:expat license:tcl/tk))))
