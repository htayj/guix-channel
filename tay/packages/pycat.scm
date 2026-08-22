;;; Guix package for cizra/pycat.

(define-module (tay packages pycat)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages python))

(define-public pycat
  (package
    (name "pycat")
    ;; Upstream does not publish releases.  Pin the latest upstream commit
    ;; rather than deriving a version from the moving master branch.
    (version "20240731-1.55c0389")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/cizra/pycat")
             (commit "55c0389b8be3d5623a707698c00a9baa1f393f4e")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "13mz62gbv07mz76fn5383pm490l05fx4h40r2yzmlhm0w3nxcqfa"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; This is the complete upstream unit suite.  Compile every
                ;; module as an additional Python-version compatibility check.
                (invoke "python3" "tests.py")
                (invoke "python3" "-m" "compileall" "-q" "."))))
          (add-after 'check 'remove-test-bytecode
            (lambda _
              ;; compileall is a check, not an upstream artifact to install.
              (for-each delete-file-recursively
                        (find-files "." "__pycache__$" #:directories? #t))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/pycat"))
                     (doc (string-append out "/share/doc/pycat"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/pycat")))
                (copy-recursively "." data)
                (mkdir-p doc)
                (mkdir-p bin)
                (copy-file "README.md" (string-append doc "/README.md"))
                (copy-file "LICENSE" (string-append doc "/LICENSE"))
                ;; Upstream is intentionally a collection of importable
                ;; modules, not a Python distribution.  Preserve its normal
                ;; `python3 ./pycat.py WORLD PORT` behavior while allowing
                ;; WORLD to be a user module in the invoking directory.
                (call-with-output-file launcher
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/python3~%"
                             "import os~%"
                             "import importlib.abc~%"
                             "import importlib.machinery~%"
                             "import importlib.util~%"
                             "import runpy~%"
                             "import sys~%"
                             "source = ~s~%"
                             "cwd = os.path.realpath(os.getcwd())~%"
                             "sys.path[:] = [source] + [entry for entry in sys.path~%"
                             (string-append
                              "                         if os.path.realpath("
                              "entry or cwd) != cwd~%")
                             "                         and entry != source]~%"
                             "world_name = sys.argv[1] if len(sys.argv) > 1 else None~%"
                             "if world_name and world_name.isidentifier():~%"
                             "    world_path = os.path.join(cwd,~%"
                             "                             world_name + '.py')~%"
                             "    if os.path.isfile(world_path):~%"
                             (string-append
                              "        class UserWorldLoader(importlib.machinery."
                              "SourceFileLoader):~%")
                             "            def exec_module(self, module):~%"
                             "                sys.path.insert(1, cwd)~%"
                             "                try:~%"
                             "                    super().exec_module(module)~%"
                             "                finally:~%"
                             "                    del sys.path[1]~%"
                             (string-append
                              "        class UserWorldFinder(importlib.abc."
                              "MetaPathFinder):~%")
                             (string-append
                              "            def find_spec(self, fullname, path=None, "
                              "target=None):~%")
                             "                if fullname == '_pycat_user_world':~%"
                             (string-append
                              "                    return importlib.util.spec_from_file_"
                              "location(~%")
                             "                        fullname, world_path,~%"
                             (string-append
                              "                        loader=UserWorldLoader(fullname, "
                              "world_path))~%")
                             "                return None~%"
                             "        sys.meta_path.insert(0, UserWorldFinder())~%"
                             "        sys.argv[1] = '_pycat_user_world'~%"
                             "runpy.run_path(os.path.join(source, 'pycat.py'), "
                             "run_name='__main__')~%")
                            #$python data)))
                (chmod launcher #o555)))))))
    (inputs (list python))
    (synopsis "modular Python MUD proxy client")
    (description
     "Pycat is a modular, hackable MUD client written in Python.  It connects
to a MUD server and offers an IPv6 loopback proxy for a conventional terminal
client, retaining output while that frontend reconnects.  Users can select a
world module from their current directory to provide server settings, triggers,
aliases, timers, and other client behavior.")
    (home-page "https://github.com/cizra/pycat")
    (license license:unlicense)))
