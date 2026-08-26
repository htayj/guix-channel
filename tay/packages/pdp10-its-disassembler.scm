;;; GNU Guix package for larsbrinkhoff/pdp10-its-disassembler.

(define-module (tay packages pdp10-its-disassembler)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:))

(define-public pdp10-its-disassembler
  (package
    (name "pdp10-its-disassembler")
    ;; Upstream has no releases.  This revision includes the lodepng gitlink
    ;; used by tvpic, so the source must be fetched recursively rather than
    ;; reusing the channel's non-recursive source-preservation snapshot.
    (version "0-c745bb5")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/larsbrinkhoff/pdp10-its-disassembler")
             (commit "c745bb51e6b38f89b2d0ce95edb45833dbdd937d")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0fcz4vsmkklhda7258my5kf9bwjp1qw14gil1blq8kqlvqllfdwq"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "AR=" #$(ar-for-target)))
      ;; Upstream's all target lists `check' as a peer of dis10 even though
      ;; check.sh executes dis10.  A serial default build preserves that
      ;; target while avoiding the resulting make dependency race.
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          ;; check.sh reports comparison failures but deliberately exits zero
          ;; so that exploratory upstream runs can continue.  Require every
          ;; pinned expected transcript explicitly for package correctness.
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "sh" "check.sh")
                (for-each
                 (lambda (expected)
                   (invoke "cmp" (string-append "out/" expected)
                           (string-append "test/" expected)))
                 '("@.its.dasm" "@.midas.dasm" "arc.code.list"
                   "atsign.tcp.dasm" "boot.exb.dasm" "cerber.sav.dasm"
                   "chars.pub.oct.sail" "chars.pub.sail.ascii"
                   "dart.dmp.dasm" "dart.tape.dart" "dired.dmp.dasm"
                   "eftp.sav.dasm" "its.bin.dasm" "its.rp06.dasm"
                   "l.bin.dump" "linum-1.txt-a" "linum-1.txt-df"
                   "linum-2.txt-af" "linum-2.txt-df" "linum-3.txt-d"
                   "logo.ptp.dump" "macro.low.dasm" "nswit.bin.dump"
                   "pt.rim.dasm" "pt.rim.dump" "srccom.exe.dasm"
                   "stink.-ipak-.ipak" "supdup.bin.dump" "system.dmp.dasm"
                   "system.dmp.dump" "ts.ksfedr.dasm" "ts.name.dasm"
                   "ts.obs.dasm" "ts.srccom.dasm" "ts.srccom.dump"
                   "two.tapes.dasm" "visib1.bin.dasm" "visib2.bin.dasm"
                   "visib3.bin.dasm"))
                ;; Unlike its transcript tests, upstream's scrmbl checks
                ;; print a failure without failing the shell script.  Repeat
                ;; those byte-for-byte comparisons with checked commands.
                (for-each
                 (lambda (mode)
                   (let ((scrambled (string-append "out/" mode ".scrmbl"))
                         (unscrambled (string-append "out/" mode ".unscrm")))
                     (invoke "./scrmbl" "-Wbin" mode "samples/zeros.scrmbl"
                             scrambled)
                     (invoke "sh" "-c"
                             (string-append "./cat36 -Wits -Xbin " scrambled
                                            " | cmp - samples/zeros." mode
                                            ".scrmbl"))
                     (invoke "./scrmbl" "-d" "-Wits" mode scrambled
                             unscrambled)
                     (invoke "sh" "-c"
                             (string-append "./cat36 -Wits -Xbin " unscrambled
                                            " | cmp - samples/zeros.scrmbl"))))
                 '("thirty" "sixbit" "pdpten" "aaaaaa" "0s")))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (doc (string-append #$output
                                        "/share/doc/pdp10-its-disassembler")))
                (mkdir-p bin)
                (mkdir-p doc)
                (for-each (lambda (program) (install-file program bin))
                          '("dis10" "acct" "calcomp" "cat36"
                            "classify-tape" "constantinople" "cross" "dart"
                            "decdmp" "dskdmp" "dump" "dumper" "failsafe"
                            "harscntopbm" "ipak" "itsarc" "kldcp" "klfedr"
                            "linum" "macdmp" "macro-tapes" "magdmp" "magfrm"
                            "mini-dumper" "od10" "old-cpio" "palx" "plt"
                            "scrmbl" "tape-dir" "tendmp" "tito" "tvpic"
                            "unscr"))
                (for-each (lambda (file) (install-file file doc))
                          '("README" "README.md" "COPYING" "tito.doc"))
                ;; tvpic compiles this bundled submodule.  Retain its notice
                ;; alongside the GPL-2.0-only upstream notice.
                (copy-file "lodepng/LICENSE"
                           (string-append doc "/LODEPNG-LICENSE"))))))))
    (synopsis "Disassemble and manipulate PDP-10 ITS files")
    (description
     "PDP10 ITS Disassembler provides @command{dis10} together with utilities
for inspecting, extracting, converting, and manipulating PDP-10 ITS tapes,
dumps, archives, and word-format files.  The default upstream Makefile targets
are built and tested entirely from the recursively fetched source tree; no
network service, mutable runtime data directory, wrapper, or hardware device
is required.")
    (home-page "https://github.com/larsbrinkhoff/pdp10-its-disassembler")
    ;; COPYING is GPL-2.0-only.  tvpic includes lodepng, whose bundled LICENSE
    ;; is the zlib license; its notice is installed with the package.
    (license (list license:gpl2 license:zlib))))
