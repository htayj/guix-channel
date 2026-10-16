;;; GNU Guix package for Experienced Pixel Dungeon's final 2.19 release.
;;; SPDX-License-Identifier: GPL-3.0-or-later
(define-module (tay packages experienced-pixel-dungeon)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages java)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages exppd-controllers)
  #:use-module (tay packages exppd-font)
  #:use-module (tay packages exppd-gdx)
  #:use-module (tay packages exppd-lwjgl))

(define %game-build-helper
  (local-file (canonicalize-path
               (search-tay-package-file
                "experienced-pixel-dungeon-build.scm"))))

(define %apache-license
  (origin
    (method url-fetch)
    (uri "https://www.apache.org/licenses/LICENSE-2.0.txt")
    (file-name "Apache-2.0.txt")
    (sha256
     (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))

;; JSON-java 20170516's "Good, not Evil" condition is nonfree.  The 20240303
;; release instead says "Public Domain." and implements the same org.json API.
;; Keep this desktop substitution private; Bundle's old-save fallback is intact.
(define java-exppd-json
  (package
    (name "java-exppd-json")
    (version "20240303")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/stleary/JSON-java/tar.gz/"
             "f9b5587c87aaf02e4a5ed1991d48d6c05993624a"))
       (file-name "JSON-java-20240303-source.tar.gz")
       (sha256
        (base32 "0qa6zn3q4mamvmsw44j00sn5zy1ihy8w1xnkp7kns3207zn7g1rj"))
       (modules '((guix build utils)))
       (snippet
        #~(for-each delete-file (find-files "." "\\.(jar|class)$")))))
    (build-system gnu-build-system)
    (native-inputs (list (list "openjdk:jdk" openjdk17 "jdk")))
    (arguments
     (list
      ;; The upstream suite needs JUnit/Mockito; game save compatibility is
      ;; exercised separately by the consuming package's acceptance procedure.
      #:tests? #f
      #:modules '((guix build gnu-build-system) (guix build utils))
      #:phases
      #~(begin
          (save-module-excursion
           (lambda () (primitive-load #$%game-build-helper)))
          (let* ((helper (resolve-module
                          '(tay packages experienced-pixel-dungeon-build)))
                 (exppd-build-json (module-ref helper 'exppd-build-json))
                 (exppd-install-json (module-ref helper 'exppd-install-json)))
            (modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (replace 'build
            (lambda _
              (exppd-build-json #$openjdk17:jdk)))
          (replace 'install
            (lambda _ (exppd-install-json #$output))))))))
    (home-page "https://github.com/stleary/JSON-java")
    (synopsis "Public-domain JSON-java for Experienced Pixel Dungeon")
    (description
     "This private package compiles JSON-java's 20240303 org.json implementation
from source.  It replaces the game's nonfree 20170516 desktop dependency without
changing the existing Bundle save reader and its legacy JSON fallback.")
    (license license:public-domain)))

(define-public experienced-pixel-dungeon
  (package
    (name "experienced-pixel-dungeon")
    (version "2.19")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/TrashboxBobylev/"
             "Experienced-Pixel-Dungeon-Redone/tar.gz/"
             "7a71df6a56b371a6b0efffcbe6210dbcfaf8611d"))
       (file-name "experienced-pixel-dungeon-2.19-source.tar.gz")
       (sha256
        (base32 "0s5aglnsh62q46mmmswahp5dj9fapl3g6jhd28bn5s3f41ypahij"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; droid_sans.ttf is a manually edited derivative without an exact
            ;; derivation/license map.  Replace it with the declared composite,
            ;; including in corresponding sources; do not redistribute it.
            (delete-file "desktop/src/main/assets/fonts/droid_sans.ttf")
            (for-each
             delete-file
             (find-files
              "." (string-append
                   "\\.(jar|class|zip|so|dll|dylib|jnilib|a|o|obj|exe|lib|pdb|bc)"
                   "(\\.[0-9]+)*$")))))))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs (list (list "openjdk:jdk" openjdk17 "jdk")))
    (inputs
     (list (list "bash-minimal" bash-minimal)
           (list "openjdk" openjdk17)
           (list "java-exppd-gdx" java-exppd-gdx)
           (list "java-exppd-lwjgl" java-exppd-lwjgl)
           (list "java-exppd-controllers" java-exppd-controllers)
           (list "java-exppd-json" java-exppd-json)
           (list "font-exppd-unicode" font-exppd-unicode)
           (list "zenity" zenity)
           (list "xdg-utils" xdg-utils)
           (list "which" which)))
    (arguments
     (list
      ;; No Gradle wrapper, Maven resolver, binary release or network bootstrap.
      ;; Real graphics/save/controller acceptance is run by the channel consumer.
      #:tests? #f
      #:parallel-build? #f
      #:modules '((guix build gnu-build-system) (guix build utils))
      #:phases
      #~(begin
          (save-module-excursion
           (lambda () (primitive-load #$%game-build-helper)))
          (let* ((helper (resolve-module
                          '(tay packages experienced-pixel-dungeon-build)))
                 (exppd-prepare-game (module-ref helper 'exppd-prepare-game))
                 (exppd-build-game (module-ref helper 'exppd-build-game))
                 (exppd-install-game (module-ref helper 'exppd-install-game)))
            (modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-offline-desktop
            (lambda _
              (exppd-prepare-game
               #$(local-file (search-tay-package-file
                              "patches/experienced-pixel-dungeon-offline.patch"))
               #$font-exppd-unicode)))
          (replace 'build
            (lambda _
              (exppd-build-game #$openjdk17:jdk
                                #$java-exppd-gdx #$java-exppd-lwjgl
                                #$java-exppd-controllers #$java-exppd-json)))
          (replace 'install
            (lambda _
              (exppd-install-game
               #$output #$(file-append openjdk17 "/bin/java")
               #$(file-append bash-minimal "/bin/sh")
               #$java-exppd-gdx #$java-exppd-lwjgl #$java-exppd-controllers
               #$java-exppd-json #$font-exppd-unicode #$zenity #$xdg-utils
               #$which
               #$(local-file (search-tay-package-file
                              "experienced-pixel-dungeon-wrapper.sh"))
               #$(local-file (search-tay-package-file
                              "experienced-pixel-dungeon-notices.txt"))
               #$%apache-license
               #$(local-file (search-tay-package-file
                              "experienced-pixel-dungeon.scm"))
               #$(local-file (search-tay-package-file
                              "experienced-pixel-dungeon-build.scm"))
               #$(local-file (search-tay-package-file
                              "patches/experienced-pixel-dungeon-offline.patch"))))))))))
    (home-page "https://github.com/TrashboxBobylev/Experienced-Pixel-Dungeon-Redone")
    (synopsis "Experienced Pixel Dungeon roguelike with expanded progression")
    (description
     "Experienced Pixel Dungeon Redone is a graphical, turn-based dungeon
crawler derived from Shattered Pixel Dungeon.  This package builds the final
2.19 release's complete desktop Java game and assets from source, using
source-built LibGDX, LWJGL and controller bindings.  Guix manages updates, so
the GitHub update checker is not registered; all twelve built-in guide articles
remain available offline.  Saves and settings use the upstream
@file{$XDG_DATA_HOME/.trashboxbobylev/experienced-pixel-dungeon} directory,
falling back to @file{$HOME/.local/share} as the XDG base.  The original desktop
outline font is deliberately replaced by the licensed Noto/Droid composite
ExpPD Unicode Sans; typography differs.  The original pixel font, game rules,
assets, audio, translations, and guide content are retained.")
    (license (list license:gpl3+ license:asl2.0 license:silofl1.1
                   (license:license
                    "CC-BY (version unspecified in upstream credits)"
                    "https://creativecommons.org/licenses/by/"
                    "See AboutScene.java for the inherited sample attributions.")
                   license:cc0))))
