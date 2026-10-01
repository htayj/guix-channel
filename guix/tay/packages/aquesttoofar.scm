;;; GNU Guix package for Geoffrey White's A Quest Too Far.

(define-module (tay packages aquesttoofar)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages sdl))

(define-public aquesttoofar
  (package
    (name "aquesttoofar")
    (version "1.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://www.randomstuff.org.uk/~geoffrey/roguelikes/"
                           "AQuestTooFar1.3-091010.zip"))
       ;; Fixed upstream release dated 2010-10-09.  SHA-256:
       ;; 377b99a0b59b85c966c85b7f0dc287db09293db39a157c7af1889fadddc79b9c
       (sha256
        (base32 "174vqzfsv7w8y5x7q5csncyjj2fvhz10szsvr1kck1cvnnh9jyrp"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;upstream has no test target
      ;; The makefile's Build directory prerequisite is not shared by its
      ;; object rules, so parallel make can compile before mkdir finishes.
      #:parallel-build? #f
      #:make-flags #~(list (string-append "CC=" #$(cxx-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'remove-prebuilt-files
            (lambda _
              ;; Never retain or run the opaque Windows distribution.
              (for-each delete-file (find-files "." "\\.(exe|dll)$"))))
          (add-before 'build 'fix-link-order
            (lambda _
              ;; With --as-needed, libraries must follow the objects that
              ;; reference them.  No gameplay source changes are required.
              (substitute* "makefile"
                (("\\$\\(CC\\) \\$\\(LDFLAGS\\) \\$\\(OBJECTS\\) -o \\$\\(EXEC\\)")
                 "$(CC) $(OBJECTS) -o $(EXEC) $(LDFLAGS)"))))
          (replace 'install
            (lambda _
              (let* ((program (string-append #$output "/libexec/AQuestTooFar"))
                     (data (string-append #$output "/share/aquesttoofar"))
                     (doc (string-append #$output "/share/doc/aquesttoofar"))
                     (launcher (string-append #$output "/bin/aquesttoofar")))
                (install-file "AQuestTooFar" (dirname program))
                (for-each
                 (lambda (file) (install-file file (string-append data "/Data")))
                 '("Data/icon32.bmp" "Data/tiles_ascii.bmp"))
                (for-each (lambda (file) (install-file file doc))
                          '("readme.txt" "gpl-3.0.txt"))
                ;; main.cpp resolves both bitmaps relative to its working
                ;; directory.  The game has no save/configuration writes.
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%cd ~s~%exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh") data program)))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal sdl12-compat))
    (home-page "https://www.randomstuff.org.uk/~geoffrey/roguelikes/aquesttoofar.html")
    (synopsis "Dungeon adventure starring an aging hero")
    (description
     "A Quest Too Far is a graphical ASCII roguelike in which a retired hero
returns to the dungeon to rescue his grandchildren.  Every turn accumulates
physical decline instead of experience, making careful use of the hero's
remaining strength essential.  This package builds the original C++ game and
its bundled CharLib from source, with SDL 1.2 compatibility support.")
    ;; readme.txt grants GPL-3.0-or-later for the game and its bitmap assets.
    ;; The bundled SDL.dll is excluded; SDL comes from the Guix input.
    (license license:gpl3+)))
