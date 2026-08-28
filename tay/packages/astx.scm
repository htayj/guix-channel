;;; GNU Guix package for codemodsquad/astx.
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages astx)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages node)
  #:use-module (gnu packages web)
  #:use-module (tay packages astx-npm-sources)
  #:use-module (tay packages starred-a-c))

(define astx-pnpm
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/pnpm/-/pnpm-8.11.0.tgz")
    (file-name "pnpm-8.11.0.tgz")
    (sha256
     (base32 "12ffz8ddqhfl2qal71mx5f73amx9d0hnccsmkg4bwb197dn80n2q"))))

;; astx uses tsx to load user supplied TypeScript transforms.  Its npm package
;; normally downloads a platform-specific esbuild executable, so retain an
;; exact, source-built helper instead.
(define astx-esbuild
  (package
    (inherit esbuild)
    (name "astx-esbuild")
    (version "0.25.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/evanw/esbuild/tar.gz/e9174d671b1882758cd32ac5e146200f5bee3e45")
       (file-name "esbuild-0.25.0.tar.gz")
       (sha256
        (base32 "05zxcjz23djza5ivps7jyskc1ldh4l81jk8hjsxx2s3h8kzh8kkw"))))))

(define-public astx
  (package
    (name "astx")
    (version "0.0.0-development-0.9f0ee21")
    (source (package-source codemodsquad-astx-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              (let ((pnpm "package/bin/pnpm.cjs")
                    (store (string-append (getcwd) "/.pnpm-store")))
                (invoke "tar" "xzf" #$astx-pnpm)
                (setenv "ESBUILD_BINARY_PATH" #$(file-append astx-esbuild "/bin/esbuild"))
                (setenv "npm_config_update_notifier" "false")
                ;; Seed pnpm's content-addressed store from fixed source
                ;; inputs before asking it to resolve the frozen lockfile.
                (apply invoke #$(file-append node-lts "/bin/node") pnpm
                       "store" "add" "--store-dir" store
                       (list #$@(map cdr %astx-npm-sources)))
                (invoke #$(file-append node-lts "/bin/node") pnpm "install"
                        "--offline" "--frozen-lockfile" "--ignore-scripts"
                        "--no-optional" "--store-dir" store))))
          (replace 'build
            (lambda _
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/@jcoreio/toolchain/scripts/toolchain.cjs" "build")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke #$(file-append node-lts "/bin/node")
                        "node_modules/@jcoreio/toolchain/scripts/toolchain.cjs" "test"))))
          (replace 'install
            (lambda _
              ;; Keep only the runtime graph, while retaining every embedded
              ;; dependency license and notice in that graph.
              (let ((pnpm "package/bin/pnpm.cjs")
                    (module (string-append #$output "/lib/node_modules/astx"))
                    (doc (string-append #$output "/share/doc/astx"))
                    (program (string-append #$output "/bin/astx")))
                (invoke #$(file-append node-lts "/bin/node") pnpm "prune" "--prod"
                        "--offline" "--ignore-scripts")
                (mkdir-p module)
                (copy-recursively "dist" (string-append module "/dist"))
                (copy-recursively "node_modules" (string-append module "/node_modules"))
                (copy-file "package.json" (string-append module "/package.json"))
                (mkdir-p doc)
                (copy-file "LICENSE.md" (string-append doc "/LICENSE.md"))
                (copy-file "README.md" (string-append doc "/README.md"))
                (copy-recursively "node_modules"
                                  (string-append doc "/node-modules-notices"))
                (mkdir-p (dirname program))
                (call-with-output-file program
                  (lambda (port)
                    (format port
                            (string-append "#!~a/bin/sh~%"
                                           "ASTX_WORKERS=${ASTX_WORKERS:-1}~%"
                                           "export ASTX_WORKERS~%"
                                           "ESBUILD_BINARY_PATH=${ESBUILD_BINARY_PATH"
                                           ":-~a/bin/esbuild}~%"
                                           "export ESBUILD_BINARY_PATH~%"
                                           "exec ~a/bin/node ~a/dist/cli/index.js "
                                           "\"$@\"~%")
                            #$bash-minimal #$astx-esbuild #$node-lts module)))
                (chmod program #o555)))))))
    (native-inputs
     (append (list astx-pnpm node-lts bash-minimal astx-esbuild)
             (map cdr %astx-npm-sources)))
    (home-page "https://github.com/codemodsquad/astx")
    (synopsis "Structural JavaScript and TypeScript search-and-replace CLI")
    (description
     "Astx performs structural search and replace in JavaScript and TypeScript.
It is built from the pinned upstream source with pnpm's frozen lockfile and a
fixed offline registry archive closure.  TypeScript transforms use the matching
source-built esbuild helper, never npm's platform binary download.")
    (license license:expat)))
