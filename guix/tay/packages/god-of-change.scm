;;; God of Change's complete original 2011 release, built from C++ source.

(define-module (tay packages god-of-change)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression))

;; Reuse the same private, source-built 1.5.1 C/C++ API as FOR, with its full
;; historical SDL/OpenGL renderer and embedded codec, not a modern replacement.
(define god-of-change-libtcod
  (@@ (tay packages dwarftown) dwarftown-libtcod))

(define god-of-change-assets
  (origin
    (method url-fetch)
    (uri (string-append
          "https://storage.googleapis.com/google-code-archive-downloads/"
          "v2/code.google.com/godofchange/"
          "God%20of%20Change%20-%20Linux.tar.gz"))
    (file-name "god-of-change-original-assets.tar.gz")
    (sha256
     (base32 "1f733yhapirbcw02rdgmak3jxkys4cq8458gbz3zigyw1jwlna0r"))
    (modules '((guix build utils)))
    (snippet
     #~(begin
         ;; This origin contributes only the authentic font and notices.
         ;; Never use or retain the author's precompiled game or libraries.
         (for-each delete-file
                   '("GodOfChange" "libtcod.so" "libtcodxx.so"))))))

(define god-of-change-fonts-readme
  (origin
    (method url-fetch)
    (uri (string-append
          "https://raw.githubusercontent.com/libtcod/libtcod/"
          "468fcaa412843d79ac02ec035cd756cb5412367f/data/fonts/README.txt"))
    (file-name "god-of-change-libtcod-fonts-README.txt")
    (sha256
     (base32 "1w2v8chrbp12kw48q9i9h159apx7bb4db8ss7p8wy0qxp15rqsk7"))))

(define-public god-of-change
  (package
    (name "god-of-change")
    ;; The official unversioned release is dated 2011-03-12.  "1.0" appears
    ;; only in secondary packaging, not in the original release documents.
    (version "2011.03.12")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/google-code-archive-downloads/"
             "v2/code.google.com/godofchange/"
             "God%20of%20Change%20-%20Source.zip"))
       (file-name (string-append name "-" version "-source.zip"))
       (sha256
        (base32 "03j48bkmh5g4ff1w6536g4l5ma7q6m59v2028d608gdik95rgv3g"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                    ; upstream supplies no automated tests
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; The ZIP is flat and includes the original CP1252 readme.
              ;; Preserve document bytes; normalize only C++ line endings.
              (mkdir "source")
              (chdir "source")
              (invoke "unzip" source)
              (substitute* "GodOfChange.cpp"
                (("\r") ""))
              ;; The original 2011 runtime waited for PRESS only; the later
              ;; 1.5.1 legacy wrapper also returns RELEASE.  Preserve the
              ;; original input contract at every game wait, including targets.
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/god-of-change-pressed-input.patch")))
              (invoke "patch" "--fuzz=0" "-p1" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/god-of-change-font-path.patch")))
              (mkdir "assets")
              (invoke "tar" "xf" #$god-of-change-assets "-C" "assets")))
          (delete 'configure)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              ;; The entire game, including its fifth dungeon and ending,
              ;; lives in this one translation unit.  Upstream has no Makefile.
              (invoke #$(cxx-for-target) "-std=gnu++98" "-O2" "-g0"
                      (string-append "-I" #$god-of-change-libtcod "/include")
                      (string-append "-DGOD_OF_CHANGE_FONT=\"" #$output
                                     "/share/god-of-change/terminal.png\"")
                      "GodOfChange.cpp" "-o" "god-of-change"
                      (string-append "-L" #$god-of-change-libtcod "/lib")
                      (string-append "-Wl,-rpath,"
                                     #$god-of-change-libtcod "/lib")
                      "-ltcodxx" "-ltcod" "-lm")))
          (replace 'install
            (lambda _
              (let ((data (string-append #$output "/share/god-of-change"))
                    (doc (string-append #$output "/share/doc/god-of-change")))
                (install-file "god-of-change" (string-append #$output "/bin"))
                ;; Exact original 5011-byte PNG, not the renderer's later font.
                (install-file "assets/terminal.png" data)
                (for-each (lambda (file) (install-file file doc))
                          '("God of Change license.txt"
                            "God of Change readme.txt"))
                ;; Keep the historical notices accompanying the actual font
                ;; separately from the rebuilt renderer's own notices.
                (for-each
                 (lambda (file)
                   (copy-file (string-append "assets/" file)
                              (string-append doc "/bundled-" file)))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt" "README-SDL.txt"))
                (for-each
                 (lambda (file)
                   (install-file
                    (string-append #$god-of-change-libtcod
                                   "/share/doc/dwarftown-libtcod/" file) doc))
                 '("LIBTCOD-LICENSE.txt" "LIBTCOD-CREDITS.txt" "README-SDL.txt"
                   "lodepng.c" "lodepng.h"))
                (copy-file #$god-of-change-fonts-readme
                           (string-append doc "/libtcod-fonts-README.txt"))
                (copy-file
                 #$(local-file
                    (search-tay-package-file
                     "files/god-of-change-provenance.txt"))
                 (string-append doc "/god-of-change-provenance.txt"))))))))
    (native-inputs (list unzip))
    (inputs (list god-of-change-libtcod))
    (home-page "https://code.google.com/archive/p/godofchange/")
    (synopsis "Roguelike with evolving monsters and an antagonistic deity")
    (description
     "God of Change is Adam Gatt's 2011 roguelike in which monster species
acquire new abilities and behaviours as time passes.  Explore four randomly
generated dungeons, collect weapons, armour, wands and scrolls, and confront the
God of Change in the fifth dungeon.  This package builds the complete original
C++ game with the historical libtcod 1.5.1 renderer, preserving its original
font, keyboard controls and 95 by 61 cell display.  The game has no save system.")
    (license (list license:bsd-3 license:zlib))))
