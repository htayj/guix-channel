;;; GNU Guix package for Input Remapper.

(define-module (tay packages input-remapper)
  #:use-module (guix build-system pyproject)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (tay packages starred-s-z)
  #:use-module ((guix licenses) #:prefix license:))

(define %input-remapper-commit "3b519a18fc39c4d3b4b3074ca96fbcd46585a9ac")

(define-public input-remapper
  (package
    (name "input-remapper")
    (version "2.2.1-0.3b519a1")
    (source (package-source sezanzeb-input-remapper-source))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:test-backend #~'unittest
      #:test-flags #~(list "discover" "-s" "tests/unit" "-t" ".")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'use-store-paths
            (lambda _
              (let ((bin (string-append #$output "/bin/")))
                (substitute* "inputremapper/installation_info.py"
                  (("^COMMIT_HASH = .*")
                   (string-append "COMMIT_HASH = \"" #$%input-remapper-commit
                                  "\"\n"))
                  (("^DATA_DIR = .*")
                   (string-append "DATA_DIR = \"" #$output
                                  "/share/input-remapper\"\n")))
                ;; Helper programs are started by name through os.system and
                ;; pkexec; pin them to this output.  pkexec itself stays a
                ;; PATH lookup because it must be the host's setuid program.
                (substitute* "inputremapper/bin/input_remapper_control.py"
                  (("f\"input-remapper-(reader-service|service)" _ program)
                   (string-append "f\"" bin "input-remapper-" program)))
                (substitute* '("inputremapper/daemon.py"
                               "inputremapper/gui/reader_service.py"
                               "tests/unit/test_reader.py")
                  (("input-remapper-control --command")
                   (string-append bin "input-remapper-control --command")))
                (substitute* "data/99-input-remapper.rules"
                  (("RUN\\+=\"/bin/input-remapper-control")
                   (string-append "RUN+=\"" bin "input-remapper-control")))
                (substitute* "data/input-remapper.service"
                  (("ExecStart=/usr/bin/")
                   (string-append "ExecStart=" bin)))
                (substitute* "data/input-remapper.policy"
                  (("/usr/bin/input-remapper-control")
                   (string-append bin "input-remapper-control")))
                (substitute* "data/input-remapper-autoload.desktop"
                  (("^Exec=.*")
                   (string-append "Exec=" #$bash-minimal "/bin/sh -c \""
                                  bin "input-remapper-control --command stop-all && "
                                  bin "input-remapper-control --command autoload\"\n")))
                (substitute* "data/input-remapper-gtk.desktop"
                  (("^Exec=input-remapper-gtk")
                   (string-append "Exec=" bin "input-remapper-gtk"))))))
          (add-after 'use-store-paths 'skip-environment-bound-tests
            (lambda _
              (define (skip-test file definition reason)
                (substitute* file
                  (((string-append "^( +)(" definition ")") _ indent def)
                   (string-append indent "@unittest.skip(\"" reason "\")\n"
                                  indent def))))
              ;; This test connects to the host's system D-Bus socket.
              (skip-test "tests/unit/test_daemon.py" "def test_connect\\("
                         "needs the system D-Bus")
              ;; These assert wall-clock upper bounds that fail on loaded
              ;; build machines; the remaining macro tests cover behavior.
              (for-each
               (lambda (file+test)
                 (skip-test (car file+test) (cdr file+test)
                            "wall-clock upper bound"))
               '(("tests/unit/test_macros/test_repeat.py"
                  . "async def test_1\\(")
                 ("tests/unit/test_macros/test_repeat.py"
                  . "async def test_2\\(")
                 ("tests/unit/test_macros/test_macros.py"
                  . "async def test_various\\(")
                 ("tests/unit/test_macros/test_wait.py"
                  . "async def test_wait_1_core\\(")))))
          (add-after 'install 'install-data
            (lambda _
              (let ((data (string-append #$output "/share/input-remapper"))
                    (libexec (string-append #$output "/libexec/input-remapper")))
                (define (install-into directory . files)
                  (for-each (lambda (file)
                              (install-file file (string-append #$output "/"
                                                                directory)))
                            files))
                ;; Mirror upstream's install/data_files.py below the output.
                (for-each (lambda (file) (install-file file data))
                          (find-files "data"))
                (install-into "share/applications"
                              "data/input-remapper-gtk.desktop")
                (install-into "share/metainfo"
                              "data/io.github.sezanzeb.input_remapper.metainfo.xml")
                (install-into "share/icons/hicolor/scalable/apps"
                              "data/input-remapper.svg")
                (install-into "share/polkit-1/actions" "data/input-remapper.policy")
                (install-into "lib/systemd/system" "data/input-remapper.service")
                (install-into "share/dbus-1/system.d"
                              "data/inputremapper.Control.conf")
                ;; An inert template: etc/xdg/autostart would start the
                ;; autoloader in every session of a profile that includes it.
                (install-into "share/input-remapper/xdg/autostart"
                              "data/input-remapper-autoload.desktop")
                (install-into "lib/udev/rules.d"
                              "data/69-input-remapper-forwarded.rules"
                              "data/99-input-remapper.rules")
                ;; Mirror upstream's install/language.py.
                (for-each
                 (lambda (po)
                   (let ((messages (string-append data "/lang/"
                                                  (basename po ".po")
                                                  "/LC_MESSAGES")))
                     (mkdir-p messages)
                     (invoke "msgfmt" "-o"
                             (string-append messages "/input-remapper.mo")
                             po)))
                 (find-files "po" "\\.po$"))
                ;; The real entry scripts keep their upstream names: the
                ;; service mode and process discovery depend on argv[0] and
                ;; the interpreter command line.
                (for-each (lambda (script) (install-file script libexec))
                          (find-files "bin" "^input-remapper-")))))
          (add-after 'wrap 'install-launchers
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec/input-remapper"))
                    ;; add-install-to-pythonpath already put this output first.
                    (python-path (getenv "GUIX_PYTHONPATH"))
                    (typelib-path (getenv "GI_TYPELIB_PATH"))
                    (tools (string-join
                            (list (string-append #$procps "/bin")
                                  (string-append #$coreutils-minimal "/bin")
                                  (string-append #$xmodmap "/bin")
                                  (string-append #$xset "/bin")
                                  (string-append #$numlockx "/bin"))
                            ":")))
                (mkdir-p bin)
                (for-each
                 (lambda (script)
                   (let ((launcher (string-append bin "/" (basename script))))
                     (call-with-output-file launcher
                       (lambda (port)
                         (format port "#!~a/bin/sh~%" #$bash-minimal)
                         (format port "export GUIX_PYTHONPATH=\"~a~a\"~%"
                                 python-path
                                 "${GUIX_PYTHONPATH:+:$GUIX_PYTHONPATH}")
                         (format port "export GI_TYPELIB_PATH=\"~a~a\"~%"
                                 typelib-path
                                 "${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}")
                         ;; Optional helpers stay overridable by host tools;
                         ;; pkexec must come from the host's setuid PATH.
                         (format port "export PATH=\"${PATH:+$PATH:}~a\"~%" tools)
                         (format port "exec ~a/bin/python3 ~a \"$@\"~%"
                                 #$python script)))
                     (chmod launcher #o555)))
                 (find-files libexec "^input-remapper-")))))
          (add-before 'check 'prepare-test-environment
            (lambda _
              (mkdir-p "/tmp/input-remapper-home")
              (setenv "HOME" "/tmp/input-remapper-home")
              ;; test_test.test_restore_os_environ deletes USER, which the
              ;; build environment does not set.
              (setenv "USER" (passwd:name (getpwuid (getuid)))))))))
    (native-inputs
     (list gettext-minimal gobject-introspection python-setuptools))
    (inputs
     (list bash-minimal
           coreutils-minimal
           gtk+
           gtksourceview-4
           numlockx
           procps
           python
           xmodmap
           xset))
    (propagated-inputs
     (list python-dasbus
           python-evdev
           python-packaging
           python-psutil
           python-pycairo
           python-pydantic
           python-pygobject))
    (home-page "https://github.com/sezanzeb/input-remapper")
    (synopsis "Remap input device buttons and axes")
    (description
     "Input Remapper maps keys, mouse buttons, gamepad axes and other evdev
input events to keys, macros or other events.  It provides the
@command{input-remapper-gtk} editor, the @command{input-remapper-service}
injection daemon, the @command{input-remapper-reader-service} helper and the
@command{input-remapper-control} command-line tool.

The output carries upstream's udev rules, D-Bus system policy, polkit action,
systemd unit with store paths, and the login autoload entry only as a template
under @file{share/input-remapper/xdg/autostart}; nothing is activated by
installing the package.  Using the daemon requires an administrator to add
these files to the system's udev, D-Bus and polkit configuration, run the
service, and grant access to @file{/dev/input} and @file{/dev/uinput}.")
    (license license:gpl3+)))
