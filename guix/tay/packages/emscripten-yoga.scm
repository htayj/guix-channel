;;; The real Emscripten driver and sysroot for Yoga 3.2.1's JavaScript build.
(define-module (tay packages emscripten-yoga)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages commencement) #:select (gcc-toolchain-12))
  #:use-module ((gnu packages compression) #:select (zlib))
  #:use-module ((gnu packages java) #:select (icedtea-8))
  #:use-module ((gnu packages node) #:select (node-lts))
  #:use-module ((gnu packages node-xyz) #:select (node-acorn))
  #:use-module ((gnu packages perl) #:select (perl))
  #:use-module ((gnu packages python) #:select (python-3.11))
  #:use-module (tay packages emscripten-yoga-closure))

;; emsdk 3.1.28 resolves to emscripten-releases
;; 30b9e46ddcea66e91530559379089002d8b692cf.  Its immutable DEPS pins
;; these LLVM and Binaryen revisions.  LLVM is 16.0.0git, not the installed
;; Guix LLVM 16.0.6 release.  Build all three compiler/linker components
;; together, rather than mixing release libraries with development sources.
(define %llvm-revision "ea4be70cea8509520db8638bb17bcd7b5d8d60ac")
(define %binaryen-revision "2cb5cefb6392619d908ce2ab683815d7e22ac9a5")

(define-public llvm-for-emscripten-yoga
  (package-with-c-toolchain
   (package
     (name "llvm-for-emscripten-yoga")
     (version "16.0.0-emscripten-3.1.28")
     (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/llvm/llvm-project/archive/"
                            %llvm-revision ".tar.gz"))
        (file-name (string-append "llvm-project-" %llvm-revision ".tar.gz"))
        (sha256
         (base32 "1smad7sdbwjfl9ndpf2xwv8b47idmkfz1865xvlkdpphca5j9b7y"))))
     (build-system cmake-build-system)
     (arguments
      (list
       #:build-type "Release"
       #:tests? #f
       #:configure-flags
       #~(list "-DLLVM_ENABLE_PROJECTS=clang;lld"
               "-DLLVM_TARGETS_TO_BUILD=host;WebAssembly"
               "-DLLVM_BUILD_LLVM_DYLIB=ON"
               "-DLLVM_LINK_LLVM_DYLIB=ON"
               "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
               "-DLLVM_TOOLCHAIN_TOOLS=clang;clang++;lld;wasm-ld;llvm-ar;llvm-ranlib;llvm-nm;llvm-dwp;llvm-dwarfdump;llvm-objcopy;llvm-objdump;llvm-strip;llvm-readobj;llvm-size;llvm-strings;llvm-symbolizer;llvm-cxxfilt;llvm-addr2line"
               "-DLLVM_ENABLE_LIBXML2=OFF"
               "-DLLVM_ENABLE_TERMINFO=OFF"
               "-DLLVM_ENABLE_ZLIB=ON"
               "-DLLVM_ENABLE_BINDINGS=OFF"
               "-DLLVM_TOOL_LTO_BUILD=OFF"
               "-DLLVM_INCLUDE_EXAMPLES=OFF"
               "-DLLVM_INCLUDE_TESTS=OFF"
               "-DLLVM_ENABLE_ASSERTIONS=ON"
               "-DCLANG_ENABLE_ARCMT=OFF"
               "-DCLANG_ENABLE_STATIC_ANALYZER=OFF"
               ;; clang-ast-dump runs during ASTNodeAPI generation, before
               ;; libLLVM exists in the output.  Build tools live in bin beside
               ;; build/lib; resolve that location relative to the executable,
               ;; then let CMake replace it with the output RPATH on install.
               ;; A nonempty BUILD_RPATH also prevents AddLLVM from enabling
               ;; BUILD_WITH_INSTALL_RPATH on individual tool targets.
               "-DCMAKE_SKIP_BUILD_RPATH=OFF"
               "-DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF"
               ;; CMake treats Guix LIBRARY_PATH directories as implicit and
               ;; can omit their build RPATHs.  Explicit paths belong on every
               ;; executable and shared library: DT_RUNPATH is non-transitive,
               ;; so libLLVM itself must locate zlib and the compiler runtime.
               (string-append "-DCMAKE_BUILD_RPATH=$ORIGIN/../lib;"
                              #$zlib "/lib;" #$gcc-toolchain-12 "/lib")
               (string-append "-DCMAKE_INSTALL_RPATH=" #$output "/lib;"
                              #$zlib "/lib;" #$gcc-toolchain-12 "/lib")
               "-DLLVM_PARALLEL_LINK_JOBS=1")
       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'enter-llvm
             (lambda _
               (chdir "llvm")
               (setenv "SOURCE_LICENSE"
                       (string-append (getcwd) "/LICENSE.TXT"))))
           (add-after 'install 'install-source-license
             (lambda _
               (install-file (getenv "SOURCE_LICENSE")
                             (string-append #$output "/share/doc/"
                                            "llvm-for-emscripten-yoga")))))))
     (native-inputs (list python-3.11 perl))
     (inputs (list zlib))
     (supported-systems '("x86_64-linux"))
     (home-page "https://www.llvm.org")
     (synopsis "LLVM, Clang and LLD snapshot matching Emscripten 3.1.28")
     (description
      "This package builds the exact LLVM monorepo revision used by Emscripten
3.1.28, including Clang, the WebAssembly LLD linker, LLVM object utilities and
Clang's resource headers.  Its unmodified upstream WebAssembly target uses the
Emscripten sysroot, not the host C library or a substituted WASI runtime.")
     (license license:asl2.0)) ;With LLVM exception.
   `(("gcc-toolchain" ,gcc-toolchain-12))))

(define-public binaryen-for-emscripten-yoga
  (package-with-c-toolchain
   (package
     (name "binaryen-for-emscripten-yoga")
     (version "111-emscripten-3.1.28")
     (source
      (origin
        (method url-fetch)
        (uri (string-append "https://github.com/WebAssembly/binaryen/archive/"
                            %binaryen-revision ".tar.gz"))
        (file-name (string-append "binaryen-" %binaryen-revision ".tar.gz"))
        (sha256
         (base32 "0kisi81cybb72kgy8aw8gk2vvvadfrnsqznbz6kc3f5ajq7njhn6"))))
     (build-system cmake-build-system)
     (arguments
      (list
       #:build-type "Release"
       #:tests? #f
       #:configure-flags
       #~(list "-DBUILD_TESTS=OFF" "-DINSTALL_LIBS=OFF"
               "-DBUILD_STATIC_LIB=ON")
       #:phases
       #~(modify-phases %standard-phases
           (add-before 'configure 'remember-source-license
             (lambda _
               (setenv "SOURCE_LICENSE"
                       (string-append (getcwd) "/LICENSE"))))
           (add-after 'install 'install-source-license
             (lambda _
               (install-file (getenv "SOURCE_LICENSE")
                             (string-append #$output "/share/doc/"
                                            "binaryen-for-emscripten-yoga")))))))
     (supported-systems '("x86_64-linux"))
     (home-page "https://github.com/WebAssembly/binaryen")
     (synopsis "Binaryen optimizer snapshot matching Emscripten 3.1.28")
     (description
      "This package provides the source-built Binaryen 111 snapshot pinned by
Emscripten 3.1.28.  It includes wasm-opt and the other Binaryen command-line
programs used by the genuine Emscripten link and JavaScript generation pipeline.")
     (license license:asl2.0))
   `(("gcc-toolchain" ,gcc-toolchain-12))))

(define-public emscripten-yoga
  (package
    (name "emscripten-yoga")
    (version "3.1.28")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/emscripten-core/emscripten/"
                           "archive/refs/tags/" version ".tar.gz"))
       (sha256
        (base32 "00crqf3wi2qda53vn97n1gwivpcaj4mzlnswlh3m19djqp52b2qg"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      ;; GNU strip does not understand the sysroot's WebAssembly objects.
      #:strip-binaries? #f
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'install-driver-and-configure
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((root (string-append #$output "/share/emscripten"))
                     (config (string-append root "/.emscripten"))
                     (python #$(file-append python-3.11 "/bin/python3"))
                     (bash (search-input-file inputs "/bin/bash")))
                (mkdir-p root)
                ;; Use upstream's install selection without its git metadata
                ;; lookup: source is an immutable release archive, not a clone.
                (invoke python "-c"
                        (string-append "from tools.install import copy_emscripten; "
                                       "copy_emscripten(" (object->string root) ")"))
                ;; Upstream's distribution copies its tests; those include
                ;; precompiled fixture modules, not compiler runtime assets.
                (for-each
                 (lambda (directory)
                   (delete-file-recursively (string-append root "/" directory)))
                 '("test" "docs"))
                (call-with-output-file (string-append root "/emscripten-revision.txt")
                  (lambda (port)
                    (display "f11d6196dd4e8748a726f19895c859b40ff6a4f3\n" port)))
                (call-with-output-file (string-append root "/emscripten-version.txt")
                  (lambda (port) (display "3.1.28\n" port)))
                ;; acorn is compiled from its 8.7.1 sources by Guix; Terser and
                ;; the licensed Emscripten JS/Python runtime are upstream source.
                ;; Closure uses the separately source-built Java compiler, so
                ;; npm never downloads its native executable or bytecode jar.
                (mkdir-p (string-append root "/node_modules"))
                (symlink #$(file-append node-acorn "/lib/node_modules/acorn")
                         (string-append root "/node_modules/acorn"))
                (call-with-output-file config
                  (lambda (port)
                    (format port "LLVM_ROOT = ~s\n"
                            #$(file-append llvm-for-emscripten-yoga "/bin"))
                    (format port "BINARYEN_ROOT = ~s\n"
                            #$binaryen-for-emscripten-yoga)
                    (format port "NODE_JS = [~s]\n"
                            #$(file-append node-lts "/bin/node"))
                    (format port "CLOSURE_COMPILER = [~s, '-jar', ~s]\n"
                            #$(file-append icedtea-8 "/bin/java")
                            #$(file-append emscripten-yoga-closure-compiler
                                           "/share/java/closure-compiler.jar"))
                    (format port "CACHE = ~s\n" (string-append root "/cache"))
                    (display "FROZEN_CACHE = False\n" port)))
                (mkdir-p (string-append #$output "/bin"))
                (for-each
                 (lambda (command)
                   (let ((path (string-append root "/" command)))
                     ;; CMake also invokes the commands in the toolchain root,
                     ;; not only the bin directory.  Each entry point therefore
                     ;; has the same hermetic config and interpreter.
                     (call-with-output-file path
                       (lambda (port)
                         (format port "#!~a\n" bash)
                         (display "unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH CPATH C_PATH CXX_INCLUDE_PATH _PYTHON_SYSCONFIGDATA_NAME\n" port)
                         (format port "export EM_CONFIG=~s\n" config)
                         (format port "exec ~s -E ~s \"$@\"\n"
                                 python (string-append path ".py"))))
                     (chmod path #o555)
                     (symlink path (string-append #$output "/bin/" command))))
                 '("emcc" "em++" "emar" "emranlib" "emcmake" "emconfigure"
                   "emmake" "em-config" "embuilder" "emnm" "emdwp" "emstrip"
                   "emsize" "emsymbolizer" "emrun" "emdump" "emprofile" "emscons"))
                (setenv "EM_CONFIG" config)
                (setenv "EMSDK_PYTHON" python))))
          (replace 'build
            (lambda _
              (for-each unsetenv '("C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"
                                   "LIBRARY_PATH" "CPATH" "C_PATH"
                                   "CXX_INCLUDE_PATH"))
              (let* ((root (string-append #$output "/share/emscripten"))
                     (builder (string-append root "/embuilder")))
                ;; SYSTEM excludes downloadable ports.  Build the whole set of
                ;; genuine system variants, including C++ no-exceptions,
                ;; embind without RTTI and emmalloc, then the full-LTO set Yoga
                ;; uses.  Normal libraries also serve CMake's compiler probes.
                (invoke builder "build" "SYSTEM")
                (invoke builder "--lto" "build" "SYSTEM")
                (delete-file-recursively (string-append root "/cache/build"))
                (when (file-exists? (string-append root "/cache/cache.lock"))
                  (delete-file (string-append root "/cache/cache.lock")))
                ;; Consumers never mutate the store or fetch a missing port.
                ;; A missing sysroot artifact fails rather than rebuilding in
                ;; an undeclared user cache.
                (substitute* (string-append root "/.emscripten")
                  (("FROZEN_CACHE = False") "FROZEN_CACHE = True")))))
          (replace 'install
            (lambda _
              (install-file "LICENSE"
                            (string-append #$output "/share/doc/emscripten-yoga")))))))
    (inputs
     (list llvm-for-emscripten-yoga binaryen-for-emscripten-yoga
           node-lts node-acorn python-3.11 icedtea-8
           emscripten-yoga-closure-compiler))
    (supported-systems '("x86_64-linux"))
    (home-page "https://emscripten.org")
    (synopsis "Source-built Emscripten driver and sysroot for Yoga")
    (description
     "Emscripten 3.1.28 compiles C and C++ to WebAssembly and generates the
JavaScript glue required by embind.  This package builds its complete system
library and full-LTO sysroot caches from source, with the exact LLVM and Binaryen
snapshots pinned by emsdk and a source-built Closure Compiler.  Its emcc and
emcmake entry points support Yoga 3.2.1's C++20, embind, emmalloc, growable-memory,
modular ES module and single-file web build without installing a prebuilt SDK or
fetching dependencies during consumer builds.  Downloadable Emscripten ports and
unrelated HTML/wasm2c conversion tools are not provisioned.")
    (license (list license:expat license:ncsa))))
