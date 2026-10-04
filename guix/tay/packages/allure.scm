;;; Allure of the Stars and its matching native LambdaHack engine.

(define-module (tay packages allure)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system haskell)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages allure-dependencies))

(define %font-licenses
  (list license:gpl2 license:silofl1.1 license:expat
        license:public-domain
        (license:x11-style "file://COPYLEFT" "Bitstream Vera License")))

(define %isolated-test-state
  #~(lambda _
      (let ((home (string-append (getcwd) "/test-home")))
        (mkdir-p home)
        (setenv "HOME" home)
        (setenv "XDG_CONFIG_HOME" (string-append home "/config"))
        (setenv "XDG_DATA_HOME" (string-append home "/data"))
        (setenv "XDG_CACHE_HOME" (string-append home "/cache")))))

;; Direct Setup.hs commands use Guix's fixed package database; neither this
;; build nor any library invokes cabal-install or resolves a registry.
(define %upstream-check
  #~(lambda* (#:key tests? #:allow-other-keys)
      (when tests?
        ((@@ (guix build haskell-build-system) run-setuphs)
         "test" '("--show-details=direct")))))

;; Extract only notice files, preserving paths within each pinned archive.
;; FreeType's primary grant has a nonstandard filename (docs/FTL.TXT).
(define %install-source-notices
  #~(lambda (source destination extra-names)
      (use-modules (ice-9 popen) (ice-9 rdelim)
                   (srfi srfi-1) (srfi srfi-13))
      (let* ((pipe (open-pipe* OPEN_READ "tar" "tf" source))
             (files
              (let loop ((result '()))
                (let ((line (read-line pipe)))
                  (if (eof-object? line)
                      (reverse result)
                      (let ((name (string-downcase (basename line))))
                        (loop
                         (if (and
                              (not (string-suffix? "/" line))
                              (or (member name extra-names)
                                  (any (lambda (prefix)
                                         (string-prefix? prefix name))
                                       '("license" "copying" "copyright"
                                         "notice" "authors"))))
                             (cons line result) result))))))))
        (unless (zero? (close-pipe pipe))
          (error "cannot list source license notices" source))
        (when (null? files)
          (error "source contains no license notices" source))
        (mkdir-p destination)
        (with-directory-excursion destination
          (apply invoke "tar" "xf" source files)))))

(define allure-engine
  (package
    (name "ghc-lambdahack-for-allure")
    (version "0.11.0.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/LambdaHack/LambdaHack/tar.gz/1399d5bd0f6a4c104249375a2968b314ca1a60d4")
       (file-name "LambdaHack-0.11.0.1.tar.gz")
       (sha256
        (base32 "0by0xgzgjjyb7sknb9akj56pqgfk77rmlm20n4wzmsz1c4a73xwx"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-9.0
           #:haddock? #f
           ;; Native GHC selects the SDL2 and ANSI branches.  The only
           ;; alternate frontend flag in this release is jsaddle.
           #:configure-flags #~'("-f-jsaddle" "-f-supportNodeJS")
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'library-only
                 (lambda _
                   (substitute* "LambdaHack.cabal"
                     (("^executable LambdaHack$")
                      "executable LambdaHack\n  buildable: False"))))
               (add-before 'configure 'isolated-test-state
                 #$%isolated-test-state)
               (replace 'check #$%upstream-check)
               (add-after 'install 'install-engine-notices
                 (lambda _
                   (let ((doc (string-append #$output
                                             "/share/doc/lambdahack")))
                     (for-each (lambda (file) (install-file file doc))
                               '("LICENSE" "COPYLEFT" "CREDITS" "README.md"
                                 "CHANGELOG.md" "GameDefinition/PLAYING.md"
                                 "GameDefinition/InGameHelp.txt"))
                     (copy-recursively "GameDefinition/fonts"
                                       (string-append doc "/fonts"))))))))
    (inputs allure-libraries)
    (native-inputs allure-test-libraries)
    (properties '((hidden? . #t) (upstream-name . "LambdaHack")))
    (home-page "https://lambdahack.github.io")
    (synopsis "Native LambdaHack engine for Allure of the Stars")
    (description
     "This private package builds the matching LambdaHack engine library for
Allure of the Stars, with SDL2 support and the original engine test suite.
It does not install the separate LambdaHack example-game executable.")
    (license (cons license:bsd-3 %font-licenses))))

(define-public allure
  (package
    (name "allure")
    (version "0.11.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/AllureOfTheStars/Allure/tar.gz/"
             "0ec5296bec777c399e21d6fed44b5366dda95f84"))
       (file-name "Allure-0.11.0.0.tar.gz")
       (sha256
        (base32 "0vjjvvpqmwd8m8b075mdlsbr6dj5faikyyqg47bhcj7l2anlhxhy"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-9.0
           #:haddock? #f
           #:configure-flags #~'("-f-supportNodeJS")
           #:phases
           #~(modify-phases %standard-phases
               (add-before 'configure 'isolated-test-state
                 #$%isolated-test-state)
               ;; Screen.hs embeds all fonts with Template Haskell.  The
               ;; original suite exercises five AI frames and initializes
               ;; every SDL fontset without requiring a graphics display.
               (replace 'check #$%upstream-check)
               (add-after 'install 'install-complete-notices
                 (lambda _
                   (use-modules (ice-9 popen) (ice-9 rdelim)
                                (srfi srfi-1) (srfi srfi-13))
                   (let ((doc (string-append #$output "/share/doc/allure")))
                     (for-each (lambda (file) (install-file file doc))
                               '("LICENSE" "COPYLEFT" "CREDITS" "README.md"
                                 "CHANGELOG.md" "GameDefinition/PLAYING.md"
                                 "GameDefinition/InGameHelp.txt"))
                     (copy-recursively "GameDefinition/fonts"
                                       (string-append doc "/fonts"))
                     ;; Haskell is linked statically: retain notices even
                     ;; when the corresponding library store references
                     ;; disappear from the installed executable.
                     (for-each
                      (lambda (directory)
                        (copy-recursively directory
                         (string-append doc "/dependencies/"
                                        (basename directory))))
                      '#$(map
                          (lambda (library)
                            (file-append library "/share/doc/"
                             (string-downcase
                              (assoc-ref (package-properties library)
                                         'upstream-name))))
                          (cons allure-engine allure-notice-packages)))
                     ;; Include the RTS and every compiler boot-library
                     ;; notice from the exact source used for this ABI.
                     (#$%install-source-notices
                      #+(package-source ghc-9.0)
                      (string-append doc "/dependencies/ghc")
                      '("xxhash.c" "xxhash.h" "execvpe.c" "fpstring.c"))
                     ;; These native libraries render the embedded fonts,
                     ;; shape text and compress saves.  Keep their actual
                     ;; pinned source grants, not just package metadata.
                     (for-each
                      (lambda (entry)
                        (#$%install-source-notices
                         (cadr entry)
                         (string-append doc "/dependencies/" (car entry))
                         (caddr entry)))
                      (list
                       (list "sdl2" #$(package-source sdl2)
                             '("imkstoucs.c" "imkstoucs.h" "edid-parse.c"
                               "khrplatform.h" "sdl_opengles2_khrplatform.h"
                               "sdl_opengl_glext.h" "sdl_egl.h"
                               "sdl_opengl.h"))
                       (list "sdl2-ttf" #$(package-source sdl2-ttf) '())
                       (list "zlib" #$(package-source zlib)
                             '("zlib.h" "readme"))
                       (list "freetype" #$(package-source freetype)
                             '("ftl.txt" "gplv2.txt" "readme" "zlib.h"
                               "ft-hb.c" "ft-hb.h" "fthash.c" "fthash.h"
                               "md5.c" "md5.h"))
                       (list "harfbuzz" #$(package-source harfbuzz)
                             '())))
                     ;; Upstream COPYLEFT points at Debian's common-license
                     ;; directory for GPL-2.  Supply the complete FSF text
                     ;; from the verified FreeType source instead.
                     (mkdir-p (string-append doc "/licenses"))
                     (copy-file
                      (string-append doc "/dependencies/freetype/freetype-"
                                     #$(package-version freetype)
                                     "/docs/GPLv2.TXT")
                      (string-append doc "/licenses/GPL-2.txt"))))))))
    (inputs (cons allure-engine allure-libraries))
    (native-inputs allure-test-libraries)
    (home-page "https://allureofthestars.com")
    (synopsis "Science-fiction roguelike with tactical squad combat")
    (description
     "Allure of the Stars is a near-future science-fiction roguelike with
tactical squad combat.  Explore procedurally generated levels and direct a
party through the game's scenarios.  This package builds the complete native
SDL2 game, content and embedded fonts from source with its matching LambdaHack
engine.  The executable retains its upstream Allure basename and stores
configuration, scores and saves in the user's ~/.Allure directory.")
    ;; COPYLEFT says GPL-2-or-later, but CREDITS specifies version 2 for
    ;; LambdaHack's font modifications.  Retain both and use GPL-2 here.
    (license (append (list license:agpl3+ license:bsd-3) %font-licenses))))
