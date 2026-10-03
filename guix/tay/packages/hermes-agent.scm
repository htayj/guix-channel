;;; Hermes backend with an explicit pinned, binary-assisted Python closure.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hermes-agent)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (srfi srfi-1)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module ((gnu packages bootstrap) #:select (glibc-dynamic-linker))
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages node)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xiph)
  #:use-module (tay packages hermes-python)
  #:use-module (tay packages hermes-python-policy)
  #:use-module (tay packages hermes-python-native)
  #:use-module (tay packages hermes-python-wake)
  #:use-module (tay packages hermes-python-runpath)
  #:use-module (tay packages hermes-python-wheels))

(define-public hermes-agent-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/NousResearch/hermes-agent")
          (commit "f97608f178d1ffeca59860195ab7da295f7c8e5f")))
    (file-name "hermes-agent-2026.9.24-checkout")
    (sha256
     (base32 "1wfgjy7a8jpk90pmn5y5kn3girqms5x0av0lhw7y62c7dyh5m8yb"))))

;; Replace vendor wheels with exact source releases and source-built codecs.
(define %hermes-runtime-wheels
  (filter (lambda (entry) (not (member (car entry) '("av" "pillow-heif" "pillow"))))
          %hermes-python-wheels))

(define-public hermes-agent
  (package
    (name "hermes-agent")
    (version "0.21.5")
    (source hermes-agent-source)
    (build-system gnu-build-system)
    ;; Native wheels are selected from the immutable uv.lock for this ABI.
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:tests? #f ; upstream tests require provider services and mutable installs
      #:strip-binaries? #f ; do not modify licensed vendor aggregates
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (guix build gremlin)
                  (ice-9 ftw) (ice-9 match) (ice-9 regex)
                  (ice-9 textual-ports) (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (add-after 'unpack 'guix-runtime-policy
            #$hermes-guix-policy-phase)
          (add-after 'guix-runtime-policy 'user-supplied-wake-assets
            #$hermes-guix-wake-phase)
          (replace 'validate-runpath #$hermes-runtime-runpath-phase)
          (replace 'install
            (lambda _
              (let* ((root (string-append #$output "/share/hermes-agent"))
                     (bin (string-append #$output "/bin"))
                     (site (string-append #$output "/lib/python3.11/site-packages"))
                     (runtime (string-append bin "/hermes-python"))
                     (python #$(file-append python-3.11 "/bin/python3"))
                     (libraries
                      (string-join
                       (list (string-append
                              (ungexp gcc "lib") "/lib")
                             #$(file-append glibc "/lib")
                             #$(file-append zlib "/lib")
                             #$(file-append libffi "/lib")
                             #$(file-append openssl "/lib")
                             #$(file-append opus "/lib")
                             #$(file-append portaudio "/lib")
                             #$(file-append libsndfile "/lib")) ":")))
                (mkdir-p bin)
                (setenv "HERMES_GLIBC_LOADER"
                        #$(file-append glibc (glibc-dynamic-linker)))
                (invoke python #$%hermes-wheel-installer #$output runtime
                        libraries #$@(map cdr %hermes-runtime-wheels))
                ;; Five Alibaba SDK helpers publish only source archives.  Build
                ;; those exact releases against the already installed lock closure.
                (setenv "PYTHONPATH" site)
                (for-each
                 (lambda (archive)
                   (mkdir-p "sdk-source")
                   (invoke "tar" "-xf" archive "-C" "sdk-source"
                           "--strip-components=1")
                   (with-directory-excursion "sdk-source"
                     (invoke python "setup.py" "build")
                     (invoke python "setup.py" "install" "--skip-build"
                             "--single-version-externally-managed"
                             "--record=installed-files"
                             (string-append "--install-lib=" site)
                             (string-append "--prefix=" #$output)))
                   (delete-file-recursively "sdk-source"))
                 (list #$@(map cdr %hermes-python-sources)))
                (for-each
                 (lambda (name)
                   (delete-file (string-append "tools/wakewords/" name)))
                 '("hey_hermes.onnx" "hey_hermes.tflite"))
                ;; Build and install Hermes itself with its original metadata,
                ;; not a fabricated dist-info directory.  Its sealed-build guard
                ;; uses this flag for the upstream Nix package as well.
                (setenv "HERMES_NIX_BUILD" "1")
                (invoke python "setup.py" "build")
                (invoke python "setup.py" "install" "--skip-build"
                        "--single-version-externally-managed"
                        "--record=hermes-installed-files"
                        (string-append "--install-lib=" site)
                        (string-append "--prefix=" #$output))
                (delete-file-recursively "build")
                ;; Source layout is load-bearing for plugins, skills, catalogs,
                ;; locales and other data outside wheels.  Wake models are user-
                ;; supplied because their redistribution grant is unverified.
                (copy-recursively "." root)
                (call-with-output-file (string-append root "/.install_method")
                  (lambda (port) (display "guix\n" port)))
                (substitute* (string-append site "/sounddevice.py")
                  (("_find_library\\(_libname\\)")
                   (format #f "~s" #$(file-append portaudio "/lib/libportaudio.so"))))
                (substitute* (string-append site "/discord/opus.py")
                  (("ctypes.util.find_library\\('opus'\\)")
                   (format #f "~s" #$(file-append opus "/lib/libopus.so"))))
                ;; Imports during setup.py create timestamp-based caches before
                ;; its own hash-based compilation.  Normalize existing caches
                ;; after all source substitutions without compiling wheel data.
                (setenv "PYTHONDONTWRITEBYTECODE" "1")
                (invoke python #$%hermes-bytecode-normalizer site)
                (call-with-output-file runtime
                  (lambda (port)
                    (format port "#!~a/bin/bash\n" #$bash-minimal)
                    (display (string-append
                              "export HERMES_MANAGED=false\n"
                              "export PYTHONDONTWRITEBYTECODE=1\n") port)
                    (format port
                            (string-append "export PYTHONPATH=~s:~s:~s:~s:~s"
                                           "${PYTHONPATH:+:$PYTHONPATH}\n")
                            root site
                            #$(file-append hermes-python-av
                                           "/lib/python3.11/site-packages")
                            #$(file-append hermes-python-pillow-heif
                                           "/lib/python3.11/site-packages")
                            #$(file-append hermes-python-pillow
                                           "/lib/python3.11/site-packages"))
                    (format port
                            "export HERMES_PYTHON=~s\nexport HERMES_BIN=~s\n"
                            runtime (string-append bin "/hermes"))
                    (format port "export HERMES_NODE=~s\n"
                            #$(file-append node-lts "/bin/node"))
                    (display
                     (string-append
                      "export HERMES_REVISION="
                      "f97608f178d1ffeca59860195ab7da295f7c8e5f\n"
                      "export HERMES_DISABLE_LAZY_INSTALLS=1\n"
                      ": ${HERMES_LAZY_INSTALL_TARGET:="
                      "${HERMES_HOME:-$HOME/.hermes}/lazy-packages}\n"
                      "export HERMES_LAZY_INSTALL_TARGET\n") port)
                    (for-each
                     (lambda (entry)
                       (format port "export ~a=~s\n" (car entry)
                               (string-append root "/" (cdr entry))))
                     '(("HERMES_BUNDLED_SKILLS" . "skills")
                       ("HERMES_OPTIONAL_SKILLS" . "optional-skills")
                       ("HERMES_BUNDLED_PLUGINS" . "plugins")
                       ("HERMES_BUNDLED_LOCALES" . "locales")
                       ("HERMES_OPTIONAL_MCPS" . "optional-mcps")))
                    (format port
                            ": ${SSL_CERT_FILE:=~s}\nexport SSL_CERT_FILE\n"
                            (string-append site "/certifi/cacert.pem"))
                    (format port "export PATH=~s:$PATH\n"
                            (string-join
                             (list bin #$(file-append coreutils-minimal "/bin")
                                   #$(file-append bash-minimal "/bin")
                                   #$(file-append git "/bin")
                                   #$(file-append openssh "/bin")
                                   #$(file-append ffmpeg "/bin")
                                   #$(file-append ripgrep "/bin")
                                   #$(file-append uv "/bin")
                                   #$(file-append node-lts "/bin")
                                   #$(file-append wl-clipboard "/bin")
                                   #$(file-append xclip "/bin")) ":"))
                    (format port "exec ~s \"$@\"\n" python)))
                (chmod runtime #o755)
                (for-each
                 (lambda (entry)
                   (let ((file (string-append bin "/" (car entry))))
                     (call-with-output-file file
                       (lambda (port)
                         (format port "#!~a/bin/bash\nexec ~s -c ~s \"$@\"\n"
                                 #$bash-minimal runtime
                                 (string-append "import sys; from " (cdr entry)
                                                " import main; sys.exit(main())"))))
                     (chmod file #o755)))
                 '(("hermes" . "hermes_cli.main")
                   ("hermes-agent" . "agent.legacy_cli")
                   ("hermes-acp" . "acp_adapter.entry")))
                (for-each
                 (lambda (entry)
                   (install-file (cdr entry)
                                 (string-append #$output
                                                "/share/doc/hermes-agent/third-party/"
                                                (car entry))))
                 '(#$@(map (lambda (entry) #~(#$(car entry) . #$(cdr entry)))
                           %hermes-python-notices)))
                (install-file "LICENSE"
                              (string-append #$output "/share/doc/hermes-agent"))))))))
    (native-inputs
     (append (list python-3.11 patchelf)
             (map cdr %hermes-runtime-wheels)
             (map cdr %hermes-python-sources)
             (map cdr %hermes-python-notices)))
    (inputs
     `(("python" ,python-3.11)
       ("bash-minimal" ,bash-minimal)
       ("coreutils-minimal" ,coreutils-minimal)
       ("git" ,git)
       ("openssh" ,openssh)
       ("ffmpeg" ,ffmpeg)
       ("ripgrep" ,ripgrep)
       ("uv" ,uv)
       ("node" ,node-lts)
       ("wl-clipboard" ,wl-clipboard)
       ("xclip" ,xclip)
       ("gcc:lib" ,gcc "lib")
       ("glibc" ,glibc)
       ("zlib" ,zlib)
       ("libffi" ,libffi)
       ("openssl" ,openssl)
       ("portaudio" ,portaudio)
       ("libsndfile" ,libsndfile)
       ("opus" ,opus)
       ("python-av" ,hermes-python-av)
       ("python-pillow-heif" ,hermes-python-pillow-heif)
       ("python-pillow" ,hermes-python-pillow)))
    (home-page "https://github.com/NousResearch/hermes-agent")
    (synopsis "Hermes agent backend and complete desktop Python runtime")
    (description
     "Hermes provides the headless JSON-RPC and WebSocket backend used by its
native desktop application, alongside CLI tools, provider SDKs, voice and wake
engines, plugins, skills and locale catalogs.  Its application source and
CPython interpreter are built from source; its exact Linux Python dependencies
include pinned upstream binary wheels.  This package is not fully source-built.
User state remains writable while in-place store updates are delegated to Guix.
Vendor redistribution notices and required corresponding sources are retained
with their distributions.  Wake engines remain available, but their model and
Picovoice native engine paths must point at separately licensed, user-supplied
assets; this package never downloads those assets automatically.")
    (license
     (list license:expat license:asl2.0 license:bsd-0 license:bsd-2 license:bsd-3
           license:isc license:psfl license:mpl2.0 license:lgpl2.1+
           license:lgpl3+ license:gpl2+ license:gpl3+ license:agpl3+
           license:zlib license:cc0 license:silofl1.1
           license:bsd-1 license:boost1.0 license:unlicense
           license:expat-0 license:cddl1.0 license:ncsa
           (license:license
            "Unicode-DFS-2016"
            "https://www.unicode.org/license.txt"
            "Unicode data license; versioned full text is retained with sources.")
           (license:license
            "CDLA-Permissive-2.0"
            "https://cdla.dev/permissive-2-0/"
            "Permissive data license; full text is retained with source-only materials.")
           (license:license
            "Unicode License v3"
            "https://www.unicode.org/license.txt"
            "Permissive Unicode data and software license; full text is retained.")
           (license:license
            "Apache-2.0 WITH LLVM-exception"
            "https://llvm.org/LICENSE.txt"
            "Apache 2.0 with the LLVM exceptions; full text is retained.")
           (license:license
            "GPL-3.0-or-later WITH GCC-exception-3.1"
            "https://www.gnu.org/licenses/gcc-exception-3.1.html"
            (string-append "Bundled GCC runtime libraries; corresponding "
                           "sources and notices are retained."))
           (license:license
            "Intel Simplified Software License (October 2022)"
            (string-append
             "https://www.intel.com/content/www/us/en/developer/articles/"
             "license/end-user-license-agreement.html")
            (string-append "Nonfree binary redistribution license; preserve "
                           "notices and do not modify Intel software."))
           (license:license
            "NVIDIA CUDA Toolkit 12.8 EULA"
            "https://docs.nvidia.com/cuda/archive/12.8.0/eula/index.html"
            (string-append "Nonfree CUDA redistributables subject to "
                           "Attachment A and GPU-use restrictions."))))))
