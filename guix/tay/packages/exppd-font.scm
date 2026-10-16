;;; Compose licensed font data for Experienced Pixel Dungeon.

(define-module (tay packages exppd-font)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (tay packages auxiliary))

;; This is the immutable tip of AOSP's gingerbread branch.  Its fallback font
;; retains the older CJK/Hangul repertoire needed by the game.  Later Android
;; fallback files with similar names do not necessarily cover those codepoints.
(define %droid-commit "9b19b93a5b0018414784cfdc070b462ea65451d8")

(define (%droid-url file)
  (string-append "https://raw.githubusercontent.com/aosp-mirror/"
                 "platform_frameworks_base/" %droid-commit "/data/fonts/" file))

(define %droid-fallback
  (origin
    (method url-fetch)
    (uri (%droid-url "DroidSansFallback.ttf"))
    (file-name (string-append "DroidSansFallback-" %droid-commit ".ttf"))
    (sha256
     (base32 "1ki4vb4v27wwq64jfrq4mwj3m3iwn4iqx08as0qjy3lis3r98dpn"))))

(define %droid-notice
  (origin
    (method url-fetch)
    (uri (%droid-url "NOTICE"))
    (file-name (string-append "DroidSansFallback-" %droid-commit "-NOTICE"))
    (sha256
     (base32 "06jnp6h85c04kkf5l321qhn9gyp7rfsq8lvg7vvj67ly712i4x9q"))))

;; The Guix font-google-noto output's installed top-level LICENSE is the
;; repository's Apache license, not fonts/LICENSE.  Fetch the actual OFL and
;; copyright notice for the font data from the same monthly release commit.
(define %noto-ofl
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/notofonts/notofonts.github.io/"
          "e3bdd5e75581e2b46d93343ec98594f3c89669c0/fonts/LICENSE"))
    (file-name "Noto-2026.01.01-OFL.txt")
    (sha256
     (base32 "1n0v0p8mw8axn1z0gvrf00zywawscz6jy496zsk272yhpq45n2gj"))))

(define-public font-exppd-unicode
  (package
    (name "font-exppd-unicode")
    (version "1")
    (source
     (local-file (search-tay-package-file "exppd-font-compose.py")))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; There is no separate upstream test suite for this composition.  The
      ;; composer checks preservation of the complete input cmap union.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (copy-file source "compose.py")))
          (delete 'bootstrap)
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "python3" "compose.py"
                      "--noto"
                      (string-append #$font-google-noto:ttf
                                     "/share/fonts/truetype/NotoSans-Regular.ttf")
                      "--noto-version" #$(package-version font-google-noto)
                      "--droid" #$%droid-fallback
                      "--noto-license" #$%noto-ofl
                      "--droid-notice" #$%droid-notice
                      "--output" "ExpPDUnicodeSans.ttf"
                      "--doc-dir" "notices")))
          (replace 'install
            (lambda _
              (install-file "ExpPDUnicodeSans.ttf"
                            (string-append #$output "/share/fonts/truetype"))
              (copy-recursively
               "notices"
               (string-append #$output "/share/doc/exppd-unicode-font")))))))
    (native-inputs
     (list (list "python" python)
           (list "python-fonttools" python-fonttools)
           (list "font-google-noto:ttf" font-google-noto "ttf")))
    (home-page "https://github.com/TrashboxBobylev/Experienced-Pixel-Dungeon")
    (synopsis "Composite Unicode font for Experienced Pixel Dungeon")
    (description
     "ExpPD Unicode Sans combines the complete Noto Sans Regular and AOSP
Gingerbread Droid Sans Fallback font data in one TrueType font.  Noto supplies
shared character mappings, while the fallback supplies its additional CJK and
Hangul repertoire.  The Droid data is rescaled from 256 to 1000 units per em
before merging.  The composite has a neutral family name and reproducible
font timestamps, and includes the original copyright and license notices.

This package composes declared upstream TrueType data with FontTools; it does
not compile the original outline-design sources.  Its typography differs from
the game's original font.  The modified font as a whole is distributed under
SIL OFL 1.1; the original Droid data retains its Apache 2.0 notices.")
    (license (list license:silofl1.1 license:asl2.0))))
