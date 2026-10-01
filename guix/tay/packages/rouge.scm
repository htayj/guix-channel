;;; The Rougelike! -- the original Wikipedia-satire roguelike.

(define-module (tay packages rouge)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system asdf)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages ncurses))

(define-public rouge
  (package
    (name "rouge")
    (version "1.61")
    ;; The 2007-04-16 Linux/source release, not the Windows 1.6 binary.
    (source
     (origin
       (method url-fetch)
       (uri "https://common-lisp.net/project/lifp/rouge-src.zip")
       (file-name (string-append "rouge-" version ".zip"))
       (sha256
        (base32 "0z8xa7lmvy1wcn7w77a0n94np72q5rla05fsv2c3sgkkvlv96173"))))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("rouge")
      #:tests? #f                     ;No upstream automated test system.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-runtime
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The ZIP has root documentation and a single SRC directory;
              ;; the standard unpack phase changes into SRC automatically.
              (copy-file "../readme.txt" "readme.txt")
              ;; Upstream's source ZIP uses DOS line endings.
              (substitute* '("rouge.lisp" "curses.lisp" "rouge.asd"
                             "controls.cfg")
                (("\r") ""))
              (invoke "patch" "-p1" "--no-backup-if-mismatch" "--input"
                      #$(local-file
                         (search-tay-package-file
                          "patches/rouge-guix-runtime.patch")))
              (substitute* "curses.lisp"
                (("@GUIX_NCURSES@")
                 (search-input-file inputs "/lib/libncurses.so.6")))
              (substitute* "rouge.lisp"
                (("@GUIX_CONTROLS@")
                 (string-append #$output "/share/rouge/controls.cfg")))))
          (add-after 'create-asdf-configuration 'install-game
            (lambda _
              (let* ((data (string-append #$output "/share/rouge"))
                     (doc (string-append #$output "/share/doc/rouge"))
                     (launcher (string-append #$output "/bin/rouge")))
                (install-file "controls.cfg" data)
                (for-each (lambda (file) (install-file file doc))
                          '("license.txt" "GNU-GPL" "readme.txt"))
                (call-with-output-file
                    (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display
                     "The Rougelike! 1.61, copyright 2006 Timofei Shatrov.
rouge.lisp: GNU GPL version 2 or later (license.txt and GNU-GPL).
curses.lisp: public domain; license.txt permits use for any purpose.
controls.cfg and readme.txt: original source-release project material.
No external tiles, fonts, sounds, maps or prebuilt executables are installed.

Runtime dependencies are separate, source-built Guix packages:
SBCL: public domain and BSD terms; see its installed COPYRIGHT.
Ncurses: X11 license; see its installed COPYING.
CFFI: MIT/Expat license; see its installed source COPYRIGHT.
CL-MD5: public domain; see its installed source md5.lisp.
trivial-gray-streams: X11/MIT license; see its installed source LICENSE.
CFFI's transitive Lisp and libffi inputs retain their Guix license notices.
"
                     port)))
                ;; Load the precompiled ASDF system rather than dumping an
                ;; entropy- and timestamp-bearing SBCL core.  The normal ASDF
                ;; phases normalize source mtimes before producing FASLs.
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (format port
                            (string-append
                             "export XDG_CONFIG_DIRS=~a/etc/xdg"
                             "${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}~%")
                            #$output)
                    (format port
                            (string-append
                             "exec ~a/bin/sbcl --noinform --no-userinit"
                             " --no-sysinit --non-interactive"
                             " --eval '(require :asdf)'"
                             " --eval '(asdf:load-system :rouge)'"
                             " --eval '(rougelike::start-game)' \"$@\"~%")
                            #$sbcl)))
                (chmod launcher #o555)))))))
    (native-inputs (list unzip))
    (inputs (list bash-minimal ncurses sbcl sbcl-cffi sbcl-md5
                  sbcl-trivial-gray-streams))
    (home-page "https://common-lisp.net/project/lifp/rouge.htm")
    (synopsis "Wikipedia-satire roguelike with a curses interface")
    (description
     "The Rougelike! is a turn-based roguelike in which a rogue Wikipedia
administrator earns Rouge points through outrageous actions, while karma
influences other users.  The original curses interface includes articles,
vandals, trolls, administrators and a banhammer.  User control overrides are
read from the XDG configuration directory, and high scores are kept in the
XDG state directory, with standard home-directory fallbacks.")
    (license (list license:gpl2+ license:public-domain))))
