;;; GNU Guix package for aap/vt05.

(define-module (tay packages vt05)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages sdl))

(define-public vt05
  (package
    (name "vt05")
    ;; Upstream has no release tags.  This is the last revision reviewed for
    ;; this package, and remains explicit to make the source provenance
    ;; reproducible.
    (version "0.1-1.934fe88")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/aap/vt05")
             (commit "934fe8898bd656749b323abbdab62939148cfe3e")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "02mwxyh88afcw8pwqcaykbn28rz13c4vygr3bn4knv4bz9k8w3l6"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;Upstream provides no test suite.
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (add-after 'unpack 'use-guix-compiler
            (lambda _
              ;; The small upstream Makefile spells the compiler as `cc`,
              ;; which is not exposed by Guix's compiler wrapper.
              (substitute* "Makefile"
                (("cc ") "$(CC) "))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output "/share/doc/vt05")))
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each (lambda (program) (install-file program bin))
                          '("vt05" "vt52" "vt50" "dp3300" "gecon"
                            "dm2500"))
                (install-file "LICENSE" doc)))))))
    ;; SDL2 supplies its headers, sdl2-config, and the runtime shared library.
    (inputs (list sdl2))
    (synopsis "SDL emulators for several classic text terminals")
    (description
     "VT05 provides SDL2 graphical emulators for the DEC VT05, VT50, and
VT52 terminals, the Datapoint 3300, the General Electric console terminal,
and the Datamedia Elite 2500.  Each program opens a local SDL window and
starts a command on a POSIX pseudo-terminal.  The programs set @code{TERM} to
the terminal type they emulate; they do not fetch data, install services, or
need a runtime wrapper.")
    (home-page "https://github.com/aap/vt05")
    (license license:expat)))
