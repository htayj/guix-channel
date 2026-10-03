;;; Aiwnios host compiler and its self-hosted HolyC runtime.

(define-module (tay packages aiwnios)
  #:use-module (gnu packages sdl)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix packages))


(define %aiwnios-commit "e155e87a4a4ddae4cd7f25685d9db8869fd45a40")

(define-public aiwnios
  (package
    (name "aiwnios")
    (version (git-version "0.9.0" "0" %aiwnios-commit))
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/aiwnios/Aiwnios/tar.gz/"
                           %aiwnios-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0j8hkb37l5pcphq2lw84a65cr3s190kdhw5qq3ik1s41bvvkvnzi"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags #~(list "-DBUILD_HCRT=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-host-build
            (lambda _
              ;; Upstream overrides the installation prefix and puts the ELF
              ;; in the source tree.  Keep both in Guix's designated directories.
              (substitute* "CMakeLists.txt"
                (("set\\(CMAKE_INSTALL_PREFIX \"/usr\"\\)") "")
                (("RUNTIME_OUTPUT_DIRECTORY \"\\$\\{CMAKE_CURRENT_SOURCE_DIR\\}\"")
                 "RUNTIME_OUTPUT_DIRECTORY \"${CMAKE_CURRENT_BINARY_DIR}\""))
              ;; The AOT copy includes 31 bytes after IET_END but upstream
              ;; initializes only 16, leaking 15 bytes of process heap into BIN.
              ;; Clear exactly that tail, not the entire 8 MiB scratch buffer.
              (substitute* "Src/CMain.HC"
                (("MemSet\\(ptr,0,16\\);") "MemSet(ptr,0,31);"))
              ;; Some source lines have no emitted instruction, and the
              ;; bytecode backend does not fill a native instruction line map.
              ;; The serializer treats zero as an absent line; uninitialized
              ;; entries otherwise leak heap addresses into HCRT2.DBG.Z.
              (substitute* "Src/AIWNIOS_CodeGen.HC"
                (("\\*info=MAlloc\\(\\(idx\\+2\\)\\*8\\+sizeof\\(CDbgInfo\\)\\)")
                 "*info=CAlloc((idx+2)*8+sizeof(CDbgInfo))"))
              ;; HolyC's AOT writer copies whole 64-bit words, rounding each
              ;; function up.  The bytecode allocator must therefore provide
              ;; the rounded, zero-filled extent, not just its logical length;
              ;; otherwise that copy reads up to seven bytes beyond the buffer.
              (substitute* "c/w_bytecode.c"
                (("bin = A_CALLOC\\(len, NULL\\);")
                 "bin = A_CALLOC((len + 7) & ~7LL, NULL);"))
              ;; Respect an explicitly isolated HOME instead of ignoring it in
              ;; favour of the passwd database.  Explicit -t still takes priority.
              (substitute* "c/main.c"
                (("if \\(pwd\\)")
                 "if (getenv(\"HOME\")) home = getenv(\"HOME\"); else if (pwd)"))))
          (add-before 'configure 'remember-source-directory
            (lambda _
              (setenv "AIWNIOS_SOURCE_DIRECTORY" (getcwd))))
          (add-after 'build 'bootstrap-holyc-runtime
            (lambda _
              ;; BUILD_HCRT's upstream ALL targets write into the source tree.
              ;; Execute their real bootstrap in a private build-tree boot drive
              ;; instead.  Neither bootstrapping nor registry initialization
              ;; needs an SDL display or the optional process debugger.
              (let* ((build (getcwd))
                     (source (getenv "AIWNIOS_SOURCE_DIRECTORY"))
                     (boot (string-append build "/boot"))
                     (exe (string-append build "/aiwnios")))
                (setenv "HOME" (string-append build "/home"))
                (mkdir-p (getenv "HOME"))
                (mkdir-p boot)
                (copy-recursively source boot)
                (with-directory-excursion boot
                  (for-each (lambda (file)
                              (when (file-exists? file) (delete-file file)))
                            '("HCRT2.BIN" "HCRT2.DBG.Z" "Registry.HC.Z"))
                  (invoke exe "-d" "-F" "-t" boot "-b")
                  (unless (file-exists? "HCRT2.BIN")
                    (error "Aiwnios bootstrap did not produce HCRT2.BIN"))
                  (invoke exe "-d" "-F" "-t" boot "-c" "FreshOnce.HC")))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let* ((build (getcwd))
                       (boot (string-append build "/boot")))
                  (call-with-output-file (string-append boot "/build-check.HC")
                    (lambda (port)
                      (display
                       (string-append
                        "I64 Square(I64 n) {return n*n;}\n"
                        "if (Square(7)!=49) ExitAiwnios(1);\n"
                        "Print(\"AIWNIOS_BUILD_OK\\n\");\n"
                        "ExitAiwnios(0);\n")
                       port)))
                  (invoke (string-append build "/aiwnios")
                          "-d" "-F" "-t" boot "-c" "build-check.HC")))))
          (replace 'install
            (lambda _
              (let ((data (string-append #$output "/share/aiwnios"))
                    (doc (string-append #$output "/share/doc/aiwnios")))
                (install-file "aiwnios" (string-append #$output "/bin"))
                (mkdir-p data)
                ;; Preserve resource paths used by HolyC, not the upstream
                ;; install loop's flattening of God/Vocab.DD and misc/Bible.
                (with-directory-excursion "boot"
                  (for-each
                   (lambda (directory)
                     (copy-recursively directory
                                       (string-append data "/" directory)))
                   '("AfterEgypt" "Doc" "Apps" "AiwniosHelp" "Src" "Demo"))
                  (for-each (lambda (file) (install-file file data))
                            '("HSNotes.DD" "PersonalMenu.DD" "HCRT2.BIN"))
                  (for-each
                   (lambda (file)
                     (when (file-exists? file) (install-file file data)))
                   '("HCRT2.DBG.Z" "Registry.HC.Z"))
                  (install-file "God/Vocab.DD" (string-append data "/God"))
                  (install-file "misc/Bible.TXT.Z" (string-append data "/misc"))
                  (install-file "README.MD" doc)
                  (mkdir-p (string-append doc "/licenses"))
                  (copy-file "LICENSE" (string-append doc "/licenses/Aiwnios"))
                  (copy-file "vendor/isocline/LICENSE"
                             (string-append doc "/licenses/isocline"))
                  (copy-file "vendor/argtable3/LICENSE"
                             (string-append doc "/licenses/argtable3")))))))))
    (inputs (list sdl2))
    (supported-systems '("x86_64-linux" "aarch64-linux" "riscv64-linux"))
    (home-page "https://github.com/aiwnios/Aiwnios")
    (synopsis "HolyC compiler and TempleOS-like host environment")
    (description
     "Aiwnios compiles and executes HolyC on a host operating system.  Its
self-hosted runtime includes the TempleOS-style DolDoc desktop, editor, graphics,
help, and example applications, as well as command-line and terminal modes.
The installed boot template is copied to a writable user directory on first
launch; @option{-t} selects an explicit boot directory.  This package does not
provide a bootable operating-system image or WebAssembly build.  HolyC runs as
native code with the user's authority and is not a security sandbox.")
    ;; Argtable's complete notice also covers its BSD-2 and Tcl-derived code.
    (license (list license:bsd-3 license:expat license:bsd-2 license:tcl/tk))))

(define-public aiwnios-bytecode
  (package
    (inherit aiwnios)
    (name "aiwnios-bytecode")
    (arguments
     (substitute-keyword-arguments (package-arguments aiwnios)
       ((#:configure-flags flags)
        #~(append #$flags (list "-DUSE_BYTECODE=ON")))))
    (synopsis "HolyC compiler and host environment using the bytecode backend")
    (description
     (string-append (package-description aiwnios)
                    "  This variant uses the upstream portable bytecode backend
instead of compiling HolyC to native machine code."))))
