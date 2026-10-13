;;; Escape From Lab 42, built natively from Richard D. Clark's BASIC source.

(define-module (tay packages escape-from-lab-42)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (tay packages freebasic))

(define-public escape-from-lab-42
  (package
    (name "escape-from-lab-42")
    (version "0.2")
    (source
     (origin
       (method url-fetch)
       (uri "https://users.freebasic-portal.de/rdc/programs/lab4202win.zip")
       ;; SHA-256:
       ;; 0b5f03ac310a8ef5b180b9b4f5dff4a564277c49f11717035284f6b4e4cf978d
       (sha256
        (base32 "13cprzjb9xl4a81if5zi95y2fr55ykgzbd5rh2qzb3ha66n06pqb"))))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:tests? #f                       ;no upstream test suite
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              ;; Keep the root documents; the stock phase enters src/.
              (mkdir "source")
              (chdir "source")
              (invoke "unzip" source)))
          (delete 'configure)
          (add-after 'unpack 'remove-prebuilt-binary
            (lambda _
              (delete-file "lab42.exe")))
          (add-after 'remove-prebuilt-binary 'preserve-original-source
            (lambda _
              (mkdir "original-source")
              (for-each (lambda (file) (install-file file "original-source"))
                        (find-files "src" "\\.(bas|bi)$"))))
          (add-after 'preserve-original-source 'use-current-boolean-names
            (lambda _
              ;; FreeBASIC 1.10 reserves BOOLEAN and predefines TRUE/FALSE as
              ;; -1/0.  Rename the game's own 1/0 enum to keep its semantics.
              (substitute* (map (lambda (file) (string-append "src/" file))
                                '("lab42.bas" "labdata.bi" "labutils.bi"
                                  "labmap.bi" "labchar.bi"))
                (("\\<[Bb][Oo][Oo][Ll][Ee][Aa][Nn]\\>") "lab42_boolean")
                (("\\<[Bb][Oo][Oo][Ll]\\>") "lab42_bool")
                (("\\<[Tt][Rr][Uu][Ee]\\>") "LAB42_TRUE")
                (("\\<[Ff][Aa][Ll][Ss][Ee]\\>") "LAB42_FALSE"))))
          (add-after 'use-current-boolean-names 'preserve-timer-precision
            (lambda _
              ;; Unix fb_Timer returns epoch seconds as Double.  Single loses
              ;; sub-second precision at that magnitude, unlike the original
              ;; Windows counter.  Widen timer storage only; keep all delays
              ;; and comparisons unchanged.  The original snapshot is intact.
              (substitute* "src/labdata.bi"
                (("Dim As Single tdd = Timer") "Dim As Double tdd = Timer")
                (("zomtime As Single") "zomtime As Double"))
              (substitute* "src/labutils.bi"
                (("Dim As Single mt") "Dim As Double mt"))
              (substitute* "src/labmap.bi"
                (("Dim As Single tdiff") "Dim As Double tdiff"))))
          (replace 'build
            (lambda _
              ;; The upstream project used "-s gui" and a Windows resource;
              ;; neither applies to the native X11 executable.
              (with-directory-excursion "src"
                (invoke "fbc" "lab42.bas" "-x" "escape-from-lab-42"))))
          (replace 'install
            (lambda* (#:key native-inputs inputs #:allow-other-keys)
              (let* ((doc (string-append #$output
                                         "/share/doc/escape-from-lab-42"))
                     (source (string-append doc "/source")))
                (install-file "src/escape-from-lab-42"
                              (string-append #$output "/bin"))
                (for-each (lambda (file) (install-file file doc))
                          '("readme42.txt" "changelog42.txt"
                            "font_read_this.txt"))
                (for-each (lambda (file) (install-file file source))
                          (find-files "original-source"))
                ;; This 8x8 font comes from FreeBASIC's gfxlib2 (LGPL).
                (install-file
                 (search-input-file (or native-inputs inputs)
                                    "share/freebasic/fnt08x08.fnt")
                 source)
                ;; readme42.txt grants an unversioned GPL; ship GPLv2 text.
                (copy-file (search-input-file (or native-inputs inputs)
                                              "share/doc/freebasic/gpl.txt")
                           (string-append doc "/GPL-2.txt"))
                ;; The binary statically links FreeBASIC's runtime and gfx
                ;; libraries: LGPL text plus readme.txt's linking exception.
                (for-each
                 (lambda (file)
                   (install-file
                    (search-input-file (or native-inputs inputs)
                                       (string-append "share/doc/freebasic/"
                                                      file))
                    (string-append doc "/freebasic-runtime")))
                 '("lgpl.txt" "readme.txt"))))))))
    (native-inputs (list freebasic unzip))
    (home-page "https://users.freebasic-portal.de/rdc/")
    (synopsis "Graphical roguelike escape from a zombie laboratory")
    (description
     "Escape From Lab 42 is a graphical roguelike by Richard D. Clark.  The
player must escape a research laboratory overrun by zombies.  This package
builds the original 0.2 FreeBASIC source as a native X11 program.")
    ;; readme42.txt:157 grants the GPL without naming a version.
    (license license:gpl1+)))
