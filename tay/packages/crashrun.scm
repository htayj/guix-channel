;;; GNU Guix package for crashRun.

(define-module (tay packages crashrun)
  #:use-module (guix build-system copy)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-graphics)
  #:use-module (gnu packages sdl))

(define crashrun-smoke-script
  (local-file "crashrun-smoke.py"))

(define-public crashrun
  (package
    (name "crashrun")
    (version "0.5.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DanaL/crashRun")
             (commit "9b95cc7dd2b8227a219769a95fcaee48e3371bec")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1mmznn1ly3dh9yd4hh6yfk7gysxwjn8q804b65zm6zxg0085kky8"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-python3
            (lambda _
              ;; This unused Python 2-only import prevents the otherwise
              ;; Python 3-compatible source tree from starting.
              (substitute* "crashRun.py"
                (("from sys import setcheckinterval") ""))
              ;; Guix's python-pysdl2 fixes SDL extension paths to store
              ;; objects.  PySDL2 0.9.17's directory scan needs the
              ;; containing directory when such a path is supplied.
              (substitute* "src/DisplayGuts.py"
                (("import sdl2\\.ext as sdl2ext")
                 (string-append
                  "import sdl2.dll as sdl2dll\n"
                  "_crashrun_original_finds_libs_at_path = "
                  "sdl2dll._finds_libs_at_path\n"
                  "def _crashrun_finds_libs_at_path(libnames, path, patterns):\n"
                  "    if os.path.isfile(path):\n"
                  "        path = os.path.dirname(path)\n"
                  "    return _crashrun_original_finds_libs_at_path("
                  "libnames, path, patterns)\n"
                  "sdl2dll._finds_libs_at_path = "
                  "_crashrun_finds_libs_at_path\n"
                  "import sdl2.ext as sdl2ext")))))
          (add-after 'prepare-python3 'check-python3
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (apply invoke
                       (append (list "python3" "-m" "py_compile")
                               (find-files "." "\\.py$"))))))
          (add-after 'check-python3 'remove-check-bytecode
            (lambda _
              (for-each delete-file-recursively
                        (find-files "." "__pycache__$" #:directories? #t))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/crashrun"))
                     (doc (string-append out "/share/doc/crashrun"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/crashrun")))
                (copy-recursively "." data)
                (mkdir-p doc)
                (mkdir-p bin)
                (copy-file "README" (string-append doc "/README"))
                (copy-file "license.txt" (string-append doc "/license.txt"))
                ;; The bundled VeraMono.ttf is the unmodified Bitstream Vera
                ;; font.  Install the exact notice shipped by Guix's
                ;; font-bitstream-vera package alongside it.
                (copy-file
                 (string-append #$font-bitstream-vera
                                "/share/doc/font-bitstream-vera-1.10/COPYRIGHT.TXT")
                 (string-append doc "/COPYRIGHT.TXT"))
                (copy-file #$crashrun-smoke-script
                           (string-append data "/crashrun-smoke.py"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display "set -eu\n" port)
                    (display
                     (string-append
                      "usage() { echo 'usage: crashrun [--smoke]' >&2; exit 64; }\n"
                      "case \"$#\" in\n"
                      "  0) ;;\n"
                      "  1) test \"$1\" = --smoke || usage ;;\n"
                      "  *) usage ;;\n"
                      "esac\n")
                     port)
                    (format port "data=~s~%python=~s~%mkdir=~s~%cp=~s~%"
                            data
                            #$(file-append python "/bin/python3")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/cp"))
                    (format port "export PYTHONDONTWRITEBYTECODE=1 PYTHONNOUSERSITE=1~%")
                    (format port "export PYTHONPATH=\"~a:~a\"~%"
                            data
                            #$(file-append python-pysdl2
                                             "/lib/python3.12/site-packages"))
                    (format port
                            (string-append
                             "export LD_LIBRARY_PATH=\"~a${LD_LIBRARY_PATH:+:"
                             "$LD_LIBRARY_PATH}\"~%")
                            (string-append #$sdl2 "/lib:" #$sdl2-ttf "/lib"))
                    (format port "export PYSDL2_DLL_PATH=~s~%"
                            (string-append #$sdl2 "/lib"))
                    (display
                     (string-append
                      "xdg_state=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}\"\n"
                      "export XDG_STATE_HOME=\"$xdg_state\"\n"
                      "state_root=\"$xdg_state/crashrun\"\n"
                      "\"$mkdir\" -p \"$state_root\"\n"
                      "resources='help.txt keys.txt rumours.txt ttd.txt VeraMono.ttf'\n"
                      "if test \"$#\" -eq 1; then\n"
                      "  smoke_state=\"$state_root/smoke-$$\"\n"
                      "  test ! -e \"$smoke_state\"\n"
                      "  \"$mkdir\" -p \"$smoke_state\"\n"
                      "  for resource in $resources; do\n"
                      "    \"$cp\" \"$data/$resource\" \"$smoke_state/$resource\"\n"
                      "  done\n"
                      "  smoke_script=\"$data/crashrun-smoke.py\"\n"
                      "  exec \"$python\" \"$smoke_script\" \"$data\" \"$smoke_state\"\n"
                      "fi\n"
                      "for resource in $resources; do\n"
                      "  if test ! -e \"$state_root/$resource\"; then\n"
                      "    \"$cp\" \"$data/$resource\" \"$state_root/$resource\"\n"
                      "  fi\n"
                      "done\n"
                      "cd \"$state_root\"\n"
                      "exec \"$python\" \"$data/crashRun.py\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (inputs
     (list bash-minimal coreutils-minimal font-bitstream-vera python
           python-pysdl2 sdl2 sdl2-ttf))
    (home-page "https://github.com/DanaL/crashRun")
    (synopsis "Cyberpunk roguelike game")
    (description
     "crashRun is a cyberpunk roguelike game written in Python with SDL2.
The package preserves the pinned upstream source and bundled game data, runs
from an XDG state directory, and uses PySDL2 with Guix's SDL2 libraries.")
    (license
     (list license:gpl3+
           (license:fsdg-compatible
            "https://spdx.org/licenses/Bitstream-Vera.html"
            "The bundled VeraMono.ttf is Bitstream Vera Sans Mono.")))))
