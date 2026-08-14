;;; Installable package for happyhorseskull/you-can-datamosh-on-linux.

(define-module (tay packages you-can-datamosh-on-linux)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python)
  #:use-module (gnu packages video)
  #:use-module (tay packages starred-d-h))

(define-public you-can-datamosh-on-linux
  (package
    (name "you-can-datamosh-on-linux")
    ;; Keep the commands tied to the channel's immutable source snapshot.
    (version (package-version happyhorseskull-you-can-datamosh-on-linux-source))
    (source (package-source happyhorseskull-you-can-datamosh-on-linux-source))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("do_the_mosh.py" "bin/do-the-mosh")
          ("video_to_gif.py" "bin/video-to-gif")
          ("README.md" "share/doc/you-can-datamosh-on-linux/README.md")
          ("LICENSE.md" "share/doc/you-can-datamosh-on-linux/LICENSE.md"))
      #:phases
      #~(modify-phases %standard-phases
          ;; The snapshot intentionally preserves upstream's files without
          ;; shebangs.  Add the Guix Python interpreter to the installed
          ;; commands while leaving the source-preservation package unchanged.
          (add-after 'unpack 'add-python-shebangs
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let ((python (search-input-file inputs "bin/python3")))
                ;; Match each pinned script's unique first source line
                ;; explicitly.  A bare ^ regexp is line-oriented in
                ;; substitute* and would otherwise insert a shebang before
                ;; every source line.
                (substitute* "do_the_mosh.py"
                  (("start_sec = 0")
                   (string-append "#!" python "\nstart_sec = 0")))
                (substitute* "video_to_gif.py"
                  (("import os")
                   (string-append "#!" python "\nimport os"))))))
          ;; The upstream scripts concatenate paths and numeric options into
          ;; shell command strings.  Convert every FFmpeg invocation to an
          ;; argv list; this preserves the argument boundaries for spaces and
          ;; shell metacharacters in user filenames and options.
          (add-after 'add-python-shebangs 'harden-ffmpeg-invocations
            (lambda _
              (use-modules (guix build utils))
              (substitute* "do_the_mosh.py"
                (("subprocess\\.Popen\\(\"ffmpeg\",")
                 "subprocess.Popen([\"ffmpeg\"],")
                (("subprocess\\.call.*input_video.*")
                 (string-append
                  "subprocess.call(['ffmpeg', '-loglevel', 'error', "
                  "'-y', '-i', "
                  "input_video,"))
                (("^[[:space:]]*' -crf 0 -pix_fmt yuv420p -r '.*")
                 (string-append
                  "\t\t\t\t'-crf', '0', '-pix_fmt', 'yuv420p', "
                  "'-r', str(fps),"))
                (("^[[:space:]]*' -ss '.*start_sec.*")
                 "\t\t\t\t'-ss', str(start_sec), '-to', str(end_sec),")
                (("input_avi, shell[=]True\\)") "input_avi])")
                (("subprocess\\.call.*output_avi.*")
                 (string-append
                  "subprocess.call(['ffmpeg', '-loglevel', 'error', "
                  "'-y', '-i', "
                  "output_avi,"))
                (("^[[:space:]]*' -crf 18 -pix_fmt yuv420p.*")
                 (string-append
                  "\t\t\t\t'-crf', '18', '-pix_fmt', 'yuv420p', "
                  "'-vcodec', 'libx264', '-acodec', 'aac', '-r', str(fps),"))
                (("^[[:space:]]*' -vf \"scale=.*")
                 (string-append
                  "\t\t\t\t'-vf', 'scale=' + str(output_width) + "
                  "':-2:flags=lanczos',"))
                (("output_video, shell[=]True\\)") "output_video])"))
              (substitute* "video_to_gif.py"
                (("subprocess\\.call\\('ffmpeg -v error -ss '.*")
                 (string-append
                  "subprocess.call(['ffmpeg', '-v', 'error', '-ss', "
                  "str(start_time), '-t', str(duration), '-i', video,"))
                (("^[[:space:]]*' -vf \"'.*palettegen=.*")
                 (string-append
                  "\t\t\t\t'-vf', filters + ',palettegen=stats_mode=diff', "
                  "'-y', palette])"))
                (("subprocess\\.call\\('ffmpeg -v error  -ss '.*")
                 (string-append
                  "subprocess.call(['ffmpeg', '-v', 'error', '-ss', "
                  "str(start_time), '-t', str(duration), '-i', video,"))
                (("^[[:space:]]*' -i ' \\+ palette.*")
                 (string-append
                  "\t\t\t\t'-i', palette, '-lavfi', filters + "
                  "'[x]; [x][1:v] paletteuse', '-y',"))
                (("gif_file, shell[=]True\\)") "gif_file])"))))
          ;; Both upstream programs invoke ffmpeg by its command name.  Keep
          ;; that behavior, but make it deterministic in a Guix profile by
          ;; adding the package's ffmpeg input to PATH and making the copied
          ;; scripts executable.
          (add-after 'install 'wrap-ffmpeg
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let ((out (assoc-ref outputs "out"))
                    (ffmpeg (assoc-ref inputs "ffmpeg")))
                (for-each
                 (lambda (program)
                   (let ((path (string-append out "/bin/" program)))
                     (chmod path #o555)
                     (wrap-program path
                       `("PATH" ":" prefix
                         (,(string-append ffmpeg "/bin"))))))
                 '("do-the-mosh" "video-to-gif"))))))))
    (inputs
     (list bash-minimal ffmpeg python))
    (synopsis "Datamosh videos and convert videos to high-quality GIFs")
    (description
     "This package installs two command-line tools from
happyhorseskull/you-can-datamosh-on-linux.  @command{do-the-mosh} applies the
upstream AVI-frame datamoshing process and @command{video-to-gif} converts a
video to a palette-optimized GIF.  Both commands use the package's Guix
Python interpreter and FFmpeg runtime input, so they work outside the source
checkout.  Upstream's README and public-domain license are installed as
documentation.  The datamoshing script also identifies portions adapted from
MIT-licensed predecessors; those upstream attribution comments are retained
in the installed implementation, and the package records both licenses.")
    (home-page "https://github.com/happyhorseskull/you-can-datamosh-on-linux")
    (license (list license:unlicense license:expat))))
