;;; Source-run SoundThread with its required Godot 4.4 engine.

(define-module (tay packages soundthread)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages speech)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-i-m))

;; Upstream SoundThread declares 4.4.  This private, fixed official editor
;; binary avoids silently substituting the incompatible moving Guix engine.
;; It is not represented as a local source build or a current security release.
(define %godot-4.4.1-notices
  (origin
    (method url-fetch)
    (uri "https://codeload.github.com/godotengine/godot/tar.gz/refs/tags/4.4.1-stable")
    (file-name "godot-4.4.1-stable-source.tar.gz")
    (sha256 (base32 "124qmpnl34fbfsn47bgqhn9g7y3p6n0va1x629lmn5af94iwb1m4"))))

(define %godot-runtime-libraries
  (list glibc alsa-lib pulseaudio dbus fontconfig eudev speech-dispatcher
        wayland libdecor libxkbcommon libx11 libxcursor libxext libxinerama
        libxi libxrandr libxrender mesa vulkan-loader))

(define %soundthread-godot
  (package
    (name "soundthread-godot")
    (version "4.4.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip")
       (sha256 (base32 "1ahjm1yyxkrmfy2c7dj44d50rlm0c6jqbx6161bgh68hagxq5qyn"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:strip-binaries? #f ; Preserve the exact trusted upstream executable.
      #:install-plan #~'(("Godot_v4.4.1-stable_linux.x86_64" "libexec/godot.bin"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-runtime
            (lambda _
              (let ((wrapper (string-append #$output "/libexec/godot")))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a/bin/sh~%exec ~s --library-path ~s ~s \"$@\"~%"
                            #$bash-minimal
                            #$(file-append glibc "/lib/ld-linux-x86-64.so.2")
                            (string-join
                             (list #$@(map (lambda (input)
                                            (file-append input "/lib"))
                                          %godot-runtime-libraries)) ":")
                            (string-append #$output "/libexec/godot.bin"))))
                (chmod wrapper #o555))))
          (replace 'validate-runpath
            (lambda* (#:key inputs #:allow-other-keys)
              ;; ET_EXEC rewriting corrupts Guix's ELF runpath reader for
              ;; this official executable. Preserve its bytes and validate
              ;; its actual fixed NEEDED closure plus the explicit loader.
              (use-modules (ice-9 popen) (ice-9 rdelim) (srfi srfi-1))
              (let* ((engine (string-append #$output "/libexec/godot.bin"))
                     (expected '("librt.so.1" "libpthread.so.0" "libdl.so.2"
                                 "libm.so.6" "libc.so.6" "ld-linux-x86-64.so.2"))
                     (port (open-pipe* OPEN_READ "readelf" "--dynamic" engine))
                     (needed
                      (let loop ((result '()))
                        (let ((line (read-line port)))
                          (if (eof-object? line) result
                              (loop
                               (if (string-contains line "(NEEDED)")
                                   (cons (substring line
                                           (+ 1 (string-index line #\[))
                                           (string-index line #\])) result)
                                   result)))))))
                (unless (zero? (close-pipe port))
                  (error "readelf failed"))
                (unless (equal? (sort needed string<?) (sort expected string<?))
                  (error "Unexpected Godot ELF dependencies" needed))
                (for-each (lambda (soname)
                            (search-input-file inputs (string-append "lib/" soname)))
                          expected)
                (invoke "cmp" engine "Godot_v4.4.1-stable_linux.x86_64")
                (invoke #$(file-append glibc "/lib/ld-linux-x86-64.so.2")
                        "--verify" engine))))
          (add-after 'wrap-runtime 'install-notices
            (lambda _
              (invoke "tar" "xf" #$%godot-4.4.1-notices)
              (let ((doc (string-append #$output "/share/doc/soundthread-godot")))
                (for-each (lambda (file)
                            (install-file
                             (string-append "godot-4.4.1-stable/" file) doc))
                          '("LICENSE.txt" "COPYRIGHT.txt" "AUTHORS.md"))
                ;; Retain per-component notices beyond the copyright summary.
                (for-each
                 (lambda (file)
                   (install-file file
                     (string-append doc "/source-notices/"
                                    (dirname (substring file
                                      (string-length "godot-4.4.1-stable/"))))))
                 (find-files
                  "godot-4.4.1-stable/thirdparty"
                  (lambda (file stat)
                    (let ((name (string-downcase (basename file))))
                      (or (string-prefix? "license" name)
                          (string-prefix? "copying" name)
                          (string-prefix? "copyright" name)
                          (string-prefix? "notice" name))))))))))))
    (native-inputs (list unzip binutils tar))
    (inputs (append (list bash-minimal) %godot-runtime-libraries))
    (supported-systems '("x86_64-linux"))
    (home-page "https://godotengine.org")
    (synopsis "Pinned official Godot engine for SoundThread")
    (description
     "This private runtime provides the official Godot 4.4.1 Linux editor
required by SoundThread, with a fixed archive digest and Guix library paths.
Matching source copyright and third-party notices accompany the binary.  This
is an older compatibility engine, not a source-built or security-audited engine.")
    (license
     (list license:expat license:asl2.0 license:bsd-2 license:bsd-3
           license:boost1.0 license:cc0 license:cc-by4.0 license:mpl2.0
           license:silofl1.1 license:freetype license:zlib license:unlicense
           (license:fsdg-compatible
            "https://github.com/godotengine/godot/blob/4.4.1-stable/COPYRIGHT.txt"
            "Additional glslang, HarfBuzz and Unicode component notices.")))))

(define-public soundthread
  (package
    (name "soundthread")
    (version "0.0.0-0.a33198a")
    (source (package-source j-p-higgins-soundthread-source))
    (build-system copy-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'replace-modified-bravura
            (lambda _
              ;; The bundled modified font retains OFL's reserved family name.
              ;; Use the unmodified, same-version font, not an RFN derivative.
              (let ((font (car (find-files #$font-bravura "^BravuraText\\.otf$"))))
                (delete-file "theme/BravuraText_SoundThread.otf")
                (copy-file font "theme/BravuraText_SoundThread.otf"))))
          (add-after 'replace-modified-bravura 'disable-auto-update-check
            (lambda _
              ;; Guix owns version selection. Keep explicit browser links,
              ;; but do not phone upstream on each application startup.
              (substitute* "scenes/Nodes/check_for_updates.gd"
                (("request\\(GITHUB_API_URL, \\[\"User-Agent: SoundThread0\"\\]\\)")
                 "# Automatic release check disabled by Guix."))))
          (add-before 'install 'check-project
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let ((check (string-append (getcwd) "/../soundthread-check"))
                      (home (string-append (getcwd) "/../soundthread-home")))
                  (copy-recursively "." check)
                  (mkdir-p home)
                  (setenv "HOME" home)
                  (setenv "XDG_DATA_HOME" (string-append home "/data"))
                  (setenv "XDG_CACHE_HOME" (string-append home "/cache"))
                  (setenv "XDG_CONFIG_HOME" (string-append home "/config"))
                  (invoke #$(file-append %soundthread-godot "/libexec/godot")
                          "--headless" "--audio-driver" "Dummy"
                          "--path" check "--editor" "--import")
                  (delete-file-recursively check)))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/soundthread"))
                     (doc (string-append #$output "/share/doc/soundthread"))
                     (bin (string-append #$output "/bin")))
                (copy-recursively "." data)
                (install-file "LICENSE" doc)
                (install-file
                 #$(local-file (search-tay-package-file
                                "files/soundthread-bravura-OFL.txt")) doc)
                (install-file
                 #$(local-file (search-tay-package-file
                                "files/soundthread-worksans-OFL.txt")) doc)
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/soundthread")
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%" #$bash-minimal)
                    (format port "engine=~s~%data=~s~%"
                            #$(file-append %soundthread-godot "/libexec/godot") data)
                    (format port "export LD_LIBRARY_PATH=~s~%"
                            (string-join
                             (list #$@(map (lambda (input)
                                            (file-append input "/lib"))
                                          %godot-runtime-libraries)) ":"))
                    (display
                     (string-append
                      "case \"$($engine --version)\" in 4.4.*) ;; *) "
                      "echo 'SoundThread requires Godot 4.4' >&2; "
                      "exit 1;; esac\n") port)
                    (format port
                            (string-append
                             "project=$(~a/bin/mktemp -d "
                             "\"${TMPDIR:-/tmp}/soundthread.XXXXXXXX\")~%")
                            #$coreutils-minimal)
                    (format port
                            "trap '~a/bin/rm -rf -- \"$project\"' EXIT HUP INT TERM~%"
                            #$coreutils-minimal)
                    (format port
                            "~a/bin/cp -R --no-preserve=mode \"$data/.\" \"$project/\"~%"
                            #$coreutils-minimal)
                    (format port
                            (string-append
                             "\"$engine\" --headless --audio-driver Dummy "
                             "--path \"$project\" --editor --import "
                             ">\"$project/import.log\" 2>&1 || { "
                             "~a/bin/cat \"$project/import.log\" >&2; exit 1; }~%")
                            #$coreutils-minimal)
                    (display "\"$engine\" --path \"$project\" \"$@\"\n" port)))
                (chmod (string-append bin "/soundthread") #o555)))))))
    (inputs (append (list %soundthread-godot bash-minimal coreutils-minimal)
                    %godot-runtime-libraries))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/j-p-higgins/SoundThread")
    (synopsis "Node-based audio interface for the Composers Desktop Project")
    (description
     "SoundThread is a Godot application for connecting audio files and CDP
commands in a graph.  The source project is copied to disposable writable state
for imports, leaving its installed files immutable.  CDP is an optional external
user integration and is neither bundled nor configured by this package.")
    (license (list license:expat license:silofl1.1))))
