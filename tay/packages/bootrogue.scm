;;; GNU Guix package for nanochess/bootRogue.

(define-module (tay packages bootrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix build utils)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages assembly)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages virtualization))

;; The repository has no release tags.  This is the only ref published by
;; upstream, pinned to the final master commit reported by git ls-remote.
(define %bootrogue-commit
  "118e1cb7818fdd152b4f008548408ed0ed45e06f")

(define-public bootrogue
  (package
    (name "bootrogue")
    (version "0-118e1cb")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/nanochess/bootRogue/archive/"
             %bootrogue-commit ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256: 06999ef0fd01d17b5eb8812f4951bd7ee9fc0cb493ddafdde0b7ea9f36b16040
       (sha256
        (base32 "0h30n4v9zsmpw3fszpcknh6grsbypm8ljbw1p1g7pl81zpq9x686"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream has no configure or non-interactive test target.  The
      ;; installed launcher is covered by tests/bootrogue-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              ;; Build both outputs documented by upstream.  The COM file is
              ;; a source-build proof only; the boot sector is the installed
              ;; runtime asset.
              (invoke "nasm" "-f" "bin" "rogue.asm"
                      "-l" "rogue.lst" "-o" "rogue.img")
              (invoke "nasm" "-f" "bin" "rogue.asm"
                      "-Dcom_file=1" "-o" "rogue.com")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/bootrogue"))
                     (doc (string-append #$output "/share/doc/bootrogue"))
                     (bin (string-append #$output "/bin"))
                     (launcher (string-append bin "/bootrogue"))
                     (qemu #$(file-append qemu-minimal
                                          "/bin/qemu-system-i386"))
                     (sh #$(file-append bash-minimal "/bin/sh"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (printf #$(file-append coreutils-minimal "/bin/printf"))
                     (od #$(file-append coreutils-minimal "/bin/od"))
                     (tr #$(file-append coreutils-minimal "/bin/tr"))
                     (sort #$(file-append coreutils-minimal "/bin/sort"))
                     (wc #$(file-append coreutils-minimal "/bin/wc"))
                     (head #$(file-append coreutils-minimal "/bin/head")))
                (mkdir-p data)
                (mkdir-p doc)
                (mkdir-p bin)
                (install-file "rogue.img" data)
                (install-file "LICENSE" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%qemu=~s~%image=~s~%~%
mktemp=~s~%rm=~s~%sleep=~s~%printf=~s~%od=~s~%tr=~s~%sort=~s~%wc=~s~%head=~s~%"
                            sh qemu (string-append data "/rogue.img")
                            mktemp rm sleep printf od tr sort wc head)
                    (display "if test \"$#\" -eq 0; then\n" port)
                    (display (string-append
                              "  exec \"$qemu\" -no-user-config -nic none "
                              "-snapshot \\\n")
                             port)
                    (display "    -drive \"file=$image,format=raw,if=floppy," port)
                    (display "readonly=on\"\n" port)
                    (display "fi\n" port)
                    (display "if test \"${1:-}\" != --smoke || " port)
                    (display "test \"$#\" -ne 1; then\n" port)
                    (display "  echo 'usage: bootrogue [--smoke]' >&2\n" port)
                    (display "  exit 64\nfi\n" port)
                    (display "scratch=$(\"$mktemp\" -d " port)
                    (display "\"${TMPDIR:-/tmp}/bootrogue-smoke.XXXXXXXX\")\n" port)
                    (display "trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n" port)
                    (display "screenshot=\"${BOOTROGUE_SMOKE_SCREENSHOT:-" port)
                    (display "$scratch/rogue.ppm}\"\n" port)
                    (display "case \"$screenshot\" in\n" port)
                    (display "  *[!A-Za-z0-9_./-]*)\n" port)
                    (display "    echo 'bootrogue: unsafe screenshot path' >&2\n" port)
                    (display "    exit 2;;\n" port)
                    (display "esac\n" port)
                    (display "\"$rm\" -f \"$screenshot\"\n" port)
                    (display "report_failure () {\n" port)
                    (display "  \"$head\" -c 4096 \"$scratch/monitor.log\" >&2\n" port)
                    (display "  exit 1\n}\n" port)
                    (display "if ! {\n" port)
                    (display "  \"$sleep\" 2\n" port)
                    (display "  \"$printf\" '%s\\n' 'sendkey right' 'sendkey down' " port)
                    (display "'sendkey left' 'sendkey up'\n" port)
                    (display "  \"$sleep\" 1\n" port)
                    (display "  \"$printf\" '%s\\n' \"screendump $screenshot\"\n" port)
                    (display "  \"$sleep\" 1\n" port)
                    (display "  \"$printf\" '%s\\n' 'quit'\n" port)
                    (display "} | \"$qemu\" -display none -monitor stdio " port)
                    (display "-serial none \\\n" port)
                    (display "    -nic none -snapshot -no-user-config \\\n" port)
                    (display "    -drive \"file=$image,format=raw,if=floppy," port)
                    (display "readonly=on\" \\\n" port)
                    (display "    >\"$scratch/monitor.log\" 2>&1; then\n" port)
                    (display "  report_failure\nfi\n" port)
                    (display "if test ! -s \"$screenshot\"; then\n" port)
                    (display "  report_failure\nfi\n" port)
                    (display "if test \"$($head -c 2 " port)
                    (display "\"$screenshot\")\" != P6; then\n" port)
                    (display "  report_failure\nfi\n" port)
                    (display "pixel_values=$(\"$od\" -An -v -tu1 -j 15 " port)
                    (display "\"$screenshot\" | \"$tr\" -s ' ' '\\n' | " port)
                    (display "\"$sort\" -nu | \"$wc\" -l)\n" port)
                    ;; Numeric sorting collapses od's empty field with zero,
                    ;; so a uniformly black frame has one unique value.
                    (display "if test \"$pixel_values\" -le 1; then\n" port)
                    (display "  report_failure\nfi\n" port)
                    (display "printf '%s\\n' BOOTROGUE_RUNTIME_OK\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list nasm))
    (inputs (list qemu-minimal bash-minimal coreutils-minimal))
    (supported-systems '("x86_64-linux" "i686-linux"))
    (home-page "https://github.com/nanochess/bootRogue")
    (synopsis "Roguelike game that fits in a boot sector")
    (description
     "BootRogue is a 510-byte 8086 real-mode roguelike game.  This package
assembles the fixed upstream source with NASM and installs its raw boot image
under @file{share/bootrogue}.  The @command{bootrogue} launcher runs the image
in QEMU's i386 system emulator as a read-only, snapshot-backed floppy with no
network.  Its @code{--smoke} mode drives a safe arrow-key sequence through the
QEMU monitor and verifies a nonblank VGA screendump.  No prebuilt upstream
binaries or screenshots are installed.")
    (license license:bsd-2)))
