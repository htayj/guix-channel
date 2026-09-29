;;; Slang shader compiler, needed to build Kitty 0.49's shaders.
;;;
;;; Kitty 0.49 compiles its Slang shaders to SPIR-V and GLSL at build time
;;; (kitty/shaders/slang.py), so kitty-bitmap needs `slangc' as a native
;;; input.  No Guix revision packages Slang.  The version matches the one
;;; Kitty's own bypy bundle builds (bypy/sources.json: "slang 2026.14.1").
;;;
;;; Only the compiler is built: the slangc driver, libslang-compiler, the
;;; embedded core module, the GLSL module and slang-glslang (glslang and
;;; SPIRV-Tools, which slangc loads for SPIR-V optimisation, linking and
;;; validation).  The configure flags mirror Kitty's bypy Slang build and
;;; additionally switch off everything that would download prebuilt binaries
;;; (slang-llvm, DXC, slang-rhi backends) or build GPU runtimes, tools,
;;; tests and examples.
;;;
;;; miniz and unordered_dense come from Guix.  lz4 stays bundled because
;;; Guix's lz4 is built with its Makefile and installs no CMake package
;;; configuration, which Slang's find_package(lz4) needs.  SPIRV-Headers,
;;; SPIRV-Tools and glslang stay bundled: Slang 2026.14.1 emits SPIR-V
;;; opcodes (e.g. OpAbortKHR, OpConstantSizeOfEXT) that the SPIRV-Headers
;;; in Guix (1.4.335.0) does not define, and SPIRV-Tools and glslang must
;;; match those headers.  cmark (Swift fork), fast_float, Lua and
;;; Vulkan-Headers stay bundled as Slang consumes them from its source tree.

(define-module (tay packages shader-slang)
  #:use-module (guix build-system cmake)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages python))

(define-public shader-slang
  (package
    (name "shader-slang")
    (version "2026.14.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/shader-slang/slang")
             ;; v2026.14.1 is an annotated tag
             ;; (object 3f3f71bbe639d93a886310a39dcfbeb26882aef5);
             ;; this is the commit it dereferences to.
             (commit "7c58a326b1f3812411a204b19cb01e323d8f6010")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "021y8yx3bcdkskgwf01k24ycjgx3xx9jlnmsf2x79k2cqrdgd28g"))
       (modules '((guix build utils)))
       (snippet
        ;; Drop submodules this build does not use, including the non-free
        ;; OptiX SDK headers and prebuilt Windows binaries in mimalloc,
        ;; imgui and tinyobjloader, plus those replaced by Guix inputs.
        #~(for-each (lambda (dir)
                      (delete-file-recursively
                       (string-append "external/" dir)))
                    '("WindowsToolchain" "glm" "imgui" "mimalloc" "miniz"
                      "optix-dev" "slang-rhi" "tinyobjloader"
                      "unordered_dense")))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list
         ;; The source has no Git metadata to derive the version from.
         (string-append "-DSLANG_VERSION_NUMERIC=" #$version)
         (string-append "-DSLANG_VERSION_FULL=" #$version)
         ;; Never download prebuilt components.
         "-DSLANG_SLANG_LLVM_FLAVOR=DISABLE"
         "-DSLANG_ENABLE_DXIL=OFF"
         "-DSLANG_ENABLE_SLANG_RHI=OFF"
         ;; Compiler only: no GPU runtimes, tools, tests or examples.
         "-DSLANG_ENABLE_CUDA=OFF"
         "-DSLANG_ENABLE_OPTIX=OFF"
         "-DSLANG_ENABLE_NVAPI=OFF"
         "-DSLANG_ENABLE_AFTERMATH=OFF"
         "-DSLANG_ENABLE_XLIB=OFF"
         "-DSLANG_ENABLE_GFX=OFF"
         "-DSLANG_ENABLE_SLANGD=OFF"
         "-DSLANG_ENABLE_SLANGI=OFF"
         "-DSLANG_ENABLE_SLANGRT=OFF"
         "-DSLANG_ENABLE_REPLAYER=OFF"
         "-DSLANG_ENABLE_TESTS=OFF"
         "-DSLANG_ENABLE_EXAMPLES=OFF"
         "-DSLANG_ENABLE_SPLIT_DEBUG_INFO=OFF"
         "-DSLANG_USE_SYSTEM_MINIZ=ON"
         "-DSLANG_USE_SYSTEM_UNORDERED_DENSE=ON")
      #:phases
      #~(modify-phases %standard-phases
          ;; The upstream test suite needs slang-rhi and GPU backends; instead
          ;; exercise the installed compiler the way Kitty's build uses it.
          (delete 'check)
          (add-after 'install 'check-slangc
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let ((slangc (string-append #$output "/bin/slangc")))
                  (call-with-output-file "smoke.slang"
                    (lambda (port)
                      (display "\
struct VOut { float4 pos : SV_Position; };
[shader(\"vertex\")]
VOut vmain(uint vid : SV_VertexID)
{ VOut o; o.pos = float4(float(vid), 0.0, 0.0, 1.0); return o; }
[shader(\"fragment\")]
float4 fmain() : SV_Target { return float4(1.0, 0.0, 0.0, 1.0); }
" port)))
                  (invoke slangc "-version")
                  ;; SPIR-V output at the default optimisation level loads
                  ;; slang-glslang (SPIRV-Tools).
                  (invoke slangc "-warnings-as-errors" "all" "smoke.slang"
                          "-entry" "fmain" "-target" "spirv"
                          "-profile" "glsl_450" "-capability" "vk_mem_model"
                          "-fvk-use-entrypoint-name" "-o" "smoke.spv"
                          "-reflection-json" "smoke.spv.json")
                  (invoke slangc "-warnings-as-errors" "all" "smoke.slang"
                          "-entry" "vmain" "-line-directive-mode" "none"
                          "-target" "glsl" "-profile" "glsl_330"
                          "-o" "smoke.vert.glsl")
                  (for-each (lambda (file)
                              (unless (and (file-exists? file)
                                           (positive? (stat:size (stat file))))
                                (error "slangc produced no output:" file)))
                            '("smoke.spv" "smoke.spv.json"
                              "smoke.vert.glsl")))))))))
    (native-inputs (list python))
    (inputs (list miniz unordered-dense))
    (home-page "https://shader-slang.org/")
    (synopsis "Shading language and compiler for modular shaders")
    (description
     "Slang is a shading language that extends HLSL with modules, generics
and interfaces.  Its compiler, @command{slangc}, translates Slang shaders to
targets such as SPIR-V and GLSL.  This package provides the compiler and its
libraries only, without the GPU runtime, language server or interpreter.")
    ;; Slang itself is Apache-2.0 WITH LLVM-exception.  Bundled parts: glslang
    ;; (BSD-3, Expat, Apache-2.0), SPIRV-Tools, SPIRV-Headers and
    ;; Vulkan-Headers (Apache-2.0, Expat), lz4's library (BSD-2), cmark
    ;; (BSD-2), fast_float (Apache-2.0, Expat or Boost-1.0) and Lua (Expat).
    (license (list license:asl2.0 license:bsd-2 license:bsd-3
                   license:expat license:boost1.0))))
