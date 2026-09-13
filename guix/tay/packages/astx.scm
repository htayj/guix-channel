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
                ;; pnpm's v3 store indexes imported tarballs by SHA-512.  The
                ;; three SHA-1 SRI records below name the identical, fixed
                ;; archives listed in %astx-npm-sources; normalize only their
                ;; SRI representation so offline installation can find them.
                (invoke "sed" "-i"
                        "-e" (string-append
                              "s|sha1-qCJQ3bABXponyoLoLqYDu/pF768=|"
                              "sha512-ZyznvL8k/FZeQHr2T6LzcJ/+vBApDnMNZvf"
                              "VFy3At0knswWd6rJ3/0Hhmpu8oqa6C92npmozs"
                              "890sX9Dl6q+"
                              "Qw==|g")
                        "-e" (string-append
                              "s|sha1-2Klr13/Wjfd5OnMDajug1UBdR3s=|"
                              "sha512-/Srv4dswyQNBfohGpz9o6Yb3Gz3SrUDqBH5r"
                              "TuhGR7ahtlbYKnVxw2bCFMRljaA7EXHaXZ8wsH"
                              "dodFvbkhKmqg==|g")
                        "-e" (string-append
                              "s|sha1-KbvZIHinOfC8zitO5B6DeVNSKSQ=|"
                              "sha512-AFBWBy9EVRTa/LhEcG8QDP3FvpwZqmvN2QF"
                              "DuJswFeaVhWnZMp8q3E6Zd90SR04PlIwfGdyVj"
                              "NyLPyen/ek5CQ==|g")
                        "pnpm-lock.yaml")
                (invoke "grep" "-q"
                        (string-append
                         "sha512-/Srv4dswyQNBfohGpz9o6Yb3Gz3SrUDqBH5r"
                         "TuhGR7ahtlbYKnVxw2bCFMRljaA7EXHaXZ8wsH"
                         "dodFvbkhKmqg==")
                        "pnpm-lock.yaml")
                (invoke "tar" "xzf" #$astx-pnpm)
                (setenv "ESBUILD_BINARY_PATH" #$(file-append astx-esbuild "/bin/esbuild"))
                (setenv "npm_config_update_notifier" "false")
                ;; Seed pnpm's content-addressed store from fixed source
                ;; inputs before asking it to resolve the frozen lockfile.
                (for-each
                 (lambda (archive)
                   (invoke #$(file-append node-lts "/bin/node") pnpm
                           "--reporter" "silent" "store" "add"
                           "--store-dir" store archive))
                 (list #$@(map cdr %astx-npm-sources)))
                (invoke #$(file-append node-lts "/bin/node") pnpm "install"
                        "--offline" "--frozen-lockfile" "--ignore-scripts"
                        "--no-optional" "--store-dir" store))))
          (replace 'build
            (lambda _
              ;; pnpm's shell shim derives its location from $0, which is the
              ;; top-level symlink when the toolchain invokes it.  Replace
              ;; that exposed shim with a direct wrapper to the real CLI.
              (let ((babel (car (find-files "node_modules/.pnpm"
                                             "babel\\.js$"))))
                (delete-file "node_modules/.bin/babel")
                (call-with-output-file "node_modules/.bin/babel"
                  (lambda (port)
                    (format port "#!~a/bin/sh~%exec ~a/bin/node ~s \"$@\"~%"
                            #$bash-minimal #$node-lts babel)))
                (chmod "node_modules/.bin/babel" #o555))
              (setenv "ESBUILD_BINARY_PATH"
                      #$(file-append astx-esbuild "/bin/esbuild"))
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/@jcoreio/toolchain/scripts/toolchain.cjs" "build")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (setenv "ESBUILD_BINARY_PATH"
                        #$(file-append astx-esbuild "/bin/esbuild"))
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
                (invoke #$(file-append node-lts "/bin/node") pnpm "prune" "--prod")
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
    ;; The upstream CLI is Expat.  The installed, lockfile-selected runtime
    ;; closure additionally contains the explicitly declared permissive
    ;; licenses below; its package license texts are retained under share/doc.
    (license (list license:expat license:isc license:bsd-2 license:bsd-3
                   license:asl2.0 license:cc0 license:cc-by4.0 license:wtfpl2
                   license:blue-oak1.0.0 license:psfl))))
