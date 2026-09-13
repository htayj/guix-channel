;;; GNU Guix package for aap/pdp6's local SDL console emulator.

(define-module (tay packages pdp6)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages bash)
  #:use-module (tay packages larsbrinkhoff-n-s)
  #:use-module ((guix licenses) #:prefix license:))

(define-public pdp6
  (package
    (name "pdp6")
    (version "0-2645ed9")
    (source (package-source larsbrinkhoff-pdp6-source))
    (build-system gnu-build-system)
    (inputs (list sdl2 sdl2-image bash-minimal))
    (native-inputs (list pkg-config))
    (arguments
     (list
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              (invoke "make" "-C" "emu" (string-append "CC=" #$(cc-for-target))
                      "pdp6")))
          (delete 'check)
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((runtime (string-append #$output "/libexec/pdp6"))
                     (bin (string-append #$output "/bin"))
                     (launcher (string-append bin "/pdp6")))
                (mkdir-p runtime)
                (mkdir-p bin)
                (install-file "emu/pdp6" runtime)
                (call-with-output-file (string-append runtime "/init.ini")
                  (lambda (port)
                    (display (string-append
                              "mkdev apr apr166\nmkdev tty tty626\nmkdev ptr ptr760\n"
                              "mkdev ptp ptp761\nmkdev dc dc136\nmkdev dt0 dt551\n"
                              "mkdev dx0 dx555\nmkdev fmem fmem162 0\nmkdev mem0 moby\n"
                              "connectdev dc dt0\nconnectdev dt0 dx0 1\n"
                              "connectio tty apr\nconnectio ptr apr\nconnectio ptp apr\n"
                              "connectio dc apr\nconnectio dt0 apr\n"
                              "connectmem fmem 0 apr -1\nconnectmem mem0 0 apr 0\n")
                             port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh\ncd ~s\nexec ./pdp6 \"$@\"\n"
                            #$bash-minimal runtime)))
                (chmod launcher #o555)))))))
    (synopsis "Local SDL console emulator for the PDP-6")
    (description "PDP6 provides the upstream graphical PDP-6 emulator with a
controlled local-device configuration.  Network, serial, FPGA, and hardware
panel paths are deliberately excluded.")
    (home-page "https://github.com/aap/pdp6")
    (license license:expat)))
