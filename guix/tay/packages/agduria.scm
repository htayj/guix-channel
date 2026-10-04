;;; Agduria: the upstream terminal game, built entirely from pinned source.

(define-module (tay packages agduria)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages ncurses))

(define-public agduria
  (package
    (name "agduria")
    (version "0.0.1-0.92c20b1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/paulpekkarinen/Agduria/tar.gz/"
             "92c20b10724dcd7ba6ca3ccbf794600d8df01b7c"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0y7w5r575ppdf466xlb8pc1w95jz1641hs9fvqzksmwa3d45h0mh"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no automated check target; its interactive T command is
      ;; exercised by the external native PTY consumer in tests/.
      #:tests? #f
      #:make-flags #~(list (string-append "CXX=" #$(cxx-for-target))
                          "CXXFLAGS=-O2 -g -Wall -std=c++20")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'fix-link-order
            (lambda _
              ;; Libraries must follow objects with --as-needed linkers.
              (substitute* "makefile"
                (("\\$\\(CXX\\) \\$\\(LIBS\\) -o \\$@ \\$\\^")
                 "$(CXX) -o $@ $^ $(LIBS)"))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (private (string-append #$output "/libexec"))
                    (doc (string-append #$output "/share/doc/agduria")))
                (install-file "agduria" private)
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE.md" "README.md"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/agduria")
                  (lambda (port)
                    (display
                     (string-append
                      "#!" #$bash-minimal "/bin/sh\n"
                      "set -eu\n"
                      "if [ \"${1-}\" = --version ]; then\n"
                      "  printf 'Agduria 0.0.1\\n'\n"
                      "  exit 0\n"
                      "fi\n"
                      "export TERMINFO_DIRS=" #$ncurses "/share/terminfo\n"
                      "exec " private "/agduria \"$@\"\n")
                     port)))
                (chmod (string-append bin "/agduria") #o555)))))))
    (inputs (list ncurses bash-minimal))
    (home-page "https://www.kriceland.fi/agduria/index.html")
    (synopsis "Terminal roguelike with procedurally generated dungeons")
    (description
     "Agduria is a standalone terminal roguelike using ncurses for colored
ASCII graphics.  This early version provides dungeon exploration and an
interactive creature-system demonstration.  It requires an
80 by 24 color terminal.  The upstream game has no save or load implementation
and does not create user files.")
    (license license:expat)))
