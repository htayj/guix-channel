;;; Encircled -- SRD's standalone 60-hour terminal roguelike.

(define-module (tay packages encircled)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ncurses))

(define-public encircled
  (package
    (name "encircled")
    ;; The author-linked archive's changelog and terminal-size check identify
    ;; 0.4.3.  Its separate readme's 0.2 is stale; latest globally is unverified.
    (version "0.4.3")
    (source
     (origin
       (method url-fetch)
       (uri "https://dl.dropbox.com/s/ldw5k988ryubtli/encircled.zip")
       (file-name (string-append name "-" version ".zip"))
       ;; SHA-256 of the exact 465808-byte author-linked ZIP:
       ;; 5fc3157c0b986b3af62c5d196201870168fcea048683626f5d028e1e385b99e2
       (sha256
        (base32 "1qlrbcw1x3h2bmpn50w60kmgqs01hw0n46ax5kv3lswq1dy1bhsz"))
       (modules '((guix build utils)))
       (snippet
        ;; Never use or redistribute the archive's opaque Windows binaries.
        #~(for-each delete-file
                    '("encircled.exe" "pdcurses.dll"
                      "libgcc_s_dw2-1.dll" "libstdc++-6.dll")))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated tests; the external native PTY consumer
      ;; exercises the actual interactive game and postmortem report.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'bound-report-filename
            (lambda _
              ;; The author ZIP uses CRLF.  Normalize only this source's line
              ;; endings before applying the exact, zero-fuzz input fix.
              (substitute* "encircled.cpp"
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1" "-i"
                      #$(local-file
                         (search-tay-package-file
                          "patches/encircled-bounded-report-filename.patch")))))
          (replace 'build
            (lambda _
              ;; Build the sole translation unit with the selected source
              ;; compiler.  Libraries follow the source for --as-needed.
              ;; Upstream's KILL_ESCAPE define is unused and is not retained.
              (invoke #$(cxx-for-target) "-std=c++11" "-O3"
                      "encircled.cpp" "-o" "encircled" "-lncurses")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              ;; No launcher or chdir: the only mutable file is an explicitly
              ;; requested postmortem report in the user's chosen directory.
              (install-file "encircled" (string-append #$output "/bin"))
              (let ((doc (string-append #$output "/share/doc/encircled")))
                (mkdir-p doc)
                (copy-file
                 #$(local-file
                    (search-tay-package-file
                     "files/encircled-source-notice.txt"))
                 (string-append doc "/SOURCE-NOTICE"))))))))
    (native-inputs (list unzip))
    (inputs (list ncurses))
    (home-page "https://kleinroguelikes.blogspot.com/p/games.html")
    (synopsis "Tactical positioning roguelike for a color terminal")
    (description
     "Encircled is a standalone ASCII roguelike written for a 60-hour
challenge.  Attacks happen automatically when the terrain around the wielder
and target matches the weapon's patterns.  Survive sixteen dungeon levels and
slay each level's quota of bosses.  The game includes a tutorial and several
alternative modes, and requires an 80 by 30 color terminal.  It can write an
explicitly requested postmortem adventure report, but has no resumable save
or load implementation.  All game text and maps are embedded in the source.")
    ;; encircled.cpp:46 grants the source to the public domain.  The copied
    ;; PDCurses core keypad constants are also public domain; see SOURCE-NOTICE.
    ;; The separate archive prose and prebuilt libraries are not installed.
    (license license:public-domain)))
