;;; GNU Guix package for the Qiling binary emulation framework.

(define-module (tay packages qiling)
  #:use-module ((tay packages starred-n-r) #:select (qilingframework-qiling-source))
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages base) #:select (binutils))
  #:use-module ((gnu packages bash) #:select (bash-minimal))
  #:use-module ((gnu packages check) #:select (python-pytest))
  #:use-module ((gnu packages emulators) #:select (python-keystone-engine unicorn))
  #:use-module ((gnu packages engineering) #:select (python-capstone))
  #:use-module ((gnu packages python-build)
                #:select (python-poetry-core python-setuptools
                          python-setuptools-scm python-wheel))
  #:use-module ((gnu packages python-xyz)
                #:select (python-click python-gevent python-jsonpath-ng
                          python-loguru python-multiprocess python-overrides
                          python-pefile python-prompt-toolkit python-pyelftools
                          python-pyyaml python-termcolor python-urwid-2))
  #:use-module ((gnu packages serialization) #:select (python-ruamel.yaml))
  #:use-module ((gnu packages xdisorg) #:select (python-pyperclip)))

;;; Qiling 1.4.10 pins "unicorn = 2.1.3" exactly; Guix provides 2.1.1.
(define unicorn-for-qiling
  (package
    (inherit unicorn)
    (version "2.1.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "unicorn" version))
       (sha256
        (base32 "0adplrxp2b5jykc34k3ydqpcxbm4mxk07irw03r2ihjhymn4a1hc"))
       (modules '((guix build utils)))
       ;; Drop the two prebuilt x86 regression binaries; they belong to the
       ;; C test suite, which the Python build never compiles or runs.
       (snippet
        #~(for-each delete-file
                    '("src/tests/regress/x86_self_modifying.elf"
                      "src/tests/regress/x86_vex")))))
    (arguments
     (list
      ;; Run the Python binding tests against the freshly built library.  The
      ;; auditing and shellcode samples define parameterised test_* helpers
      ;; that pytest cannot call without fixtures.
      #:test-flags
      #~(list "tests"
              "--ignore=tests/test_network_auditing.py"
              "--ignore=tests/test_shellcode.py")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'configure-library-build
            (lambda* (#:key parallel-build? #:allow-other-keys)
              ;; setuptools-scm looks for a Git root two levels up.
              (setenv "SETUPTOOLS_SCM_PRETEND_VERSION" #$version)
              ;; setup.py otherwise always runs "cmake --build -j4".
              (setenv "THREADS"
                      (if parallel-build?
                          (number->string (parallel-job-count))
                          "1")))))))
    ;; Without setuptools-scm the dynamic version silently becomes 0.0.0,
    ;; which cannot satisfy Qiling's "unicorn==2.1.3" requirement.
    (native-inputs
     (modify-inputs (package-native-inputs unicorn)
       (prepend python-pytest python-setuptools-scm)))))

(define python-registry
  (package
    (name "python-registry")
    (version "1.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "python-registry" version))
       (sha256
        (base32 "1chy7fsd86zz6hpqic3911sa3bk9awnr0m9yhkky66v0smkmy64r"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f                       ;the PyPI archive ships no tests
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'drop-python2-shims
            (lambda _
              ;; enum-compat and unicodecsv are Python 2 backports; the
              ;; library itself imports only the standard enum module.
              (substitute* "setup.py"
                (("install_requires=\\['enum-compat','unicodecsv'\\]")
                 "install_requires=[]")))))))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://github.com/williballenthin/python-registry")
    (synopsis "Read-only parser for Windows Registry hive files")
    (description
     "python-registry provides read-only access to the keys, values and
transaction logs of Windows NT Registry hive files.")
    (license license:asl2.0)))

;;; python-fx's generated JSONPath parser requires the 4.13 runtime; Guix
;;; provides 4.10.1.
(define python-antlr4-runtime-4.13
  (package
    (name "python-antlr4-runtime")
    (version "4.13.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "antlr4_python3_runtime" version))
       (sha256
        (base32 "05irxwjkzkcnd9jwr37rhnf92f1yjgrnsn5ch00vghig3mz696wh"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))      ;the PyPI archive ships no tests
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://www.antlr.org")
    (synopsis "ANTLR Python runtime library")
    (description
     "This package contains the Python runtime library used by parsers that
ANTLR generates for Python.")
    (license license:bsd-3)))

(define python-first
  (package
    (name "python-first")
    (version "2.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "first" version))
       (sha256
        (base32 "1gykyrm6zlrbf9iz318p57qwk594mx1jf0d79v79g32zql45na7z"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:test-backend #~'unittest
           #:test-flags #~(list "-v" "test_first")))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://github.com/hynek/first")
    (synopsis "Return the first true value of an iterable")
    (description
     "The @code{first} function returns the first element of an iterable that
is true, or that satisfies an optional key function.")
    (license license:expat)))

(define python-dacite
  (package
    (name "python-dacite")
    (version "1.9.2")
    ;; The PyPI archive omits tests/common.py, which the tests import.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/konradhalas/dacite")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1maananph172vi3v919zryhn9hswhcjb8w3srknkd4b9y1dfl0wq"))))
    (build-system pyproject-build-system)
    (arguments
     ;; Upstream's addopts enable pytest-benchmark for tests/performance.
     (list #:test-flags
           #~(list "-o" "addopts=" "--ignore=tests/performance" "tests")))
    (native-inputs (list python-pytest python-setuptools python-wheel))
    (home-page "https://github.com/konradhalas/dacite")
    (synopsis "Create Python data classes from dictionaries")
    (description
     "Dacite builds instances of Python data classes from plain dictionaries,
including nested data classes, optional fields, unions and collections.")
    (license license:expat)))

(define python-yamale
  (package
    (name "python-yamale")
    (version "5.3.0")
    ;; The PyPI archive omits the meta_test and command_line test fixtures.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/23andMe/Yamale")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0mw1ylzjwvnfzmiv0w591a7kassnji1mazq807n4kx09wp8gx0bx"))
       (modules '((guix build utils)))
       (snippet #~(delete-file "yamale.png"))))
    (build-system pyproject-build-system)
    (propagated-inputs (list python-pyyaml))
    (native-inputs
     (list python-pytest python-ruamel.yaml python-setuptools python-wheel))
    (home-page "https://github.com/23andMe/Yamale")
    (synopsis "Schema validator for YAML documents")
    (description
     "Yamale validates YAML documents against schemas that are themselves
written in YAML, and provides a @command{yamale} command-line validator.")
    (license license:expat)))

(define python-questionary
  (package
    (name "python-questionary")
    (version "2.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "questionary" version))
       (sha256
        (base32 "0ba1pp483cb0514ax28g7aw63ig3xv9qvikrmamhf0dvj819hzix"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))      ;the PyPI archive ships no tests
    (propagated-inputs (list python-prompt-toolkit))
    ;; setuptools lets the sanity-check phase verify requirements and imports.
    (native-inputs (list python-poetry-core python-setuptools))
    (home-page "https://github.com/tmbo/questionary")
    (synopsis "Interactive command-line prompts for Python")
    (description
     "Questionary builds interactive terminal prompts such as text input,
confirmations, selections and checkboxes on top of prompt_toolkit.")
    (license license:expat)))

(define python-fx
  (package
    (name "python-fx")
    (version "0.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "python_fx" version))
       (sha256
        (base32 "13ic7s7m3ravn11adqyq5f07495qx3y232jjaav7a57p0p2fgn75"))
       (modules '((guix build utils)))
       (snippet #~(delete-file "docs/demo.gif"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f                       ;the PyPI archive ships no tests
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'relax-requirements
            (lambda _
              ;; Declare only libraries the code imports, and accept the
              ;; newer first/dacite/jsonpath-ng releases that upstream's own
              ;; requirements.txt lock already uses.
              (substitute* "pyproject.toml"
                (("^\t\"(asciimatics|pillow|ply|pyfiglet|typing-extensions\
|wcwidth)[^\"]*\",\n") "")
                (("\"(first|dacite|jsonpath-ng)==" _ name)
                 (string-append "\"" name ">="))))))))
    (propagated-inputs
     (list python-antlr4-runtime-4.13 python-click python-dacite python-first
           python-jsonpath-ng python-loguru python-overrides python-pyperclip
           python-pyyaml python-urwid-2 python-yamale))
    (native-inputs (list python-setuptools python-wheel))
    (home-page "https://github.com/cielong/pyfx")
    (synopsis "Terminal JSON viewer")
    (description
     "pyfx is a terminal JSON viewer with collapsible trees, JSONPath
queries with auto-completion and configurable key maps.")
    (license license:expat)))

;;; Freestanding x86-64 Linux program assembled at build time; it is the
;;; guest binary that qiling-smoke emulates.
(define %qiling-hello-assembly
  "\t.section .rodata
message:
\t.ascii \"Hello, World!\\n\"
\t.set message_length, . - message

\t.text
\t.globl _start
_start:
\tmovl $1, %eax
\tmovl $1, %edi
\tleaq message(%rip), %rsi
\tmovl $message_length, %edx
\tsyscall
\tmovl $60, %eax
\txorl %edi, %edi
\tsyscall
\t.section .note.GNU-stack,\"\",@progbits
")

(define-public qiling
  (package
    (name "qiling")
    (version "1.4.10")
    ;; Reuse the channel's codeload archive of commit
    ;; da210f0757f3581de7e607b2b826b26eaa5aef66 (tag 1.4.10).
    (source
     (origin
       (inherit (package-source qilingframework-qiling-source))
       (modules '((guix build utils)))
       ;; examples/ holds prebuilt guest binaries, shellcode and fuzzing
       ;; corpora, and docs/ holds images; neither is part of the library.
       ;; The unlicensed examples/rootfs submodule is absent from the archive.
       (snippet
        #~(begin
            (delete-file-recursively "examples")
            (for-each delete-file (find-files "docs" "\\.png$"))))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; test_cpu_models checks Qiling's CPU models against Unicorn's
      ;; constants, proving the exact Unicorn pin.  test_shellcode emulates
      ;; inline Linux x86, x86-64, MIPS, ARM, Thumb and ARM64 shellcode with
      ;; the build directory as root filesystem; its execve of /bin/sh finds
      ;; no guest binary there and is stopped inside the emulator.  The
      ;; remaining upstream tests load guest programs from the unlicensed
      ;; examples/rootfs tree, which is not packaged.
      #:test-backend #~'unittest
      #:test-flags
      #~(list "-v" "tests.test_cpu_models" "tests.test_shellcode")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-programs
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (rootfs (string-append out "/share/qiling/rootfs"))
                     (hello (string-append rootfs "/bin/x8664_hello"))
                     (source (string-append out
                                            "/share/qiling/src/x8664_hello.S"))
                     (smoke (string-append bin "/qiling-smoke"))
                     (python (search-input-file inputs "/bin/python3"))
                     (sh (search-input-file inputs "/bin/bash")))
                ;; Upstream ships qltool and the qltui module it lazily
                ;; imports as scripts, which poetry-core does not install.
                (install-file "qltool" bin)
                (substitute* (string-append bin "/qltool")
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod (string-append bin "/qltool") #o555)
                (install-file "qltui.py" (site-packages inputs `(("out" . ,out))))
                ;; Assemble the guest program from source.
                (mkdir-p (dirname source))
                (mkdir-p (dirname hello))
                (call-with-output-file source
                  (lambda (port)
                    (display #$%qiling-hello-assembly port)))
                (invoke "as" "--64" "-o" "x8664_hello.o" source)
                (invoke "ld" "-static" "-nostdlib" "-e" "_start"
                        "--build-id=none" "-o" hello "x8664_hello.o")
                (delete-file "x8664_hello.o")
                (chmod hello #o555)
                (call-with-output-file smoke
                  (lambda (port)
                    (format port "#!~a
set -eu
if test \"$#\" -ne 0; then
    echo 'usage: qiling-smoke' >&2
    exit 64
fi
exec ~a run -f ~a --rootfs ~a --log-plain
" sh (string-append bin "/qltool") hello rootfs)))
                (chmod smoke #o555))))
          (add-after 'check 'check-smoke
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Emulate the fixture through the installed launcher.
                (let* ((port (open-input-pipe
                              (string-append #$output "/bin/qiling-smoke")))
                       (stdout (get-string-all port))
                       (status (close-pipe port)))
                  (unless (and (zero? status)
                               (string=? stdout "Hello, World!\n"))
                    (error "qiling-smoke failed" status stdout)))))))
      #:modules
      '((guix build pyproject-build-system)
        (guix build utils)
        (ice-9 popen)
        (ice-9 textual-ports))))
    (inputs (list bash-minimal))
    ;; setuptools lets the sanity-check phase verify requirements and imports.
    (native-inputs (list binutils python-poetry-core python-setuptools))
    (propagated-inputs
     (list python-capstone
           python-fx
           python-gevent
           python-keystone-engine
           python-multiprocess
           python-pefile
           python-pyelftools
           python-pyyaml
           python-questionary
           python-registry
           python-termcolor
           unicorn-for-qiling))
    (home-page "https://qiling.io")
    (synopsis "Multi-architecture binary emulation framework")
    (description
     "Qiling emulates executables and shellcode for Linux, Windows, macOS,
FreeBSD, DOS, UEFI and MCU targets on x86, ARM, MIPS, RISC-V and PowerPC,
building on the Unicorn CPU emulator.  It adds loaders, operating-system and
system-call layers, filesystem mapping, hooks, a debugger and code coverage.
This package provides the Python library, the @command{qltool} front end and
@command{qiling-smoke}, which emulates a freestanding x86-64 Linux program
assembled from source at build time.  It does not include upstream's example
root filesystems.")
    ;; The installed smoke guest is assembled with the build host's x86-64
    ;; GNU as and ld; Qiling itself is portable Python.
    (supported-systems '("x86_64-linux"))
    ;; README.md grants "version 2 of the License, or (at your option) any
    ;; later version"; COPYING carries the GPLv2 text.
    (license license:gpl2+)))
