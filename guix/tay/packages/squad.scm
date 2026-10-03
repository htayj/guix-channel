;;; GNU Guix package for bradygaster/squad.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages squad)
  #:use-module (guix build-system node)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages node)
  #:use-module (gnu packages version-control)
  #:use-module (tay packages squad-npm-sources)
  #:use-module (tay packages starred-a-c))

(define-public squad
  (package
    (name "squad")
    (version "0.13.0")
    (source (package-source bradygaster-squad-source))
    (build-system node-build-system)
    (arguments
     (list
      #:node node-lts
      #:modules '((guix build node-build-system) (guix build utils)
                  (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'materialize-locked-node-modules
            (lambda _
              ;; The path keys preserve npm's nested resolution.  No registry
              ;; resolution, package-manager installation or lifecycle scripts.
              (for-each
               (lambda (path archive)
                 (mkdir-p path)
                 (invoke "tar" "xzf" archive "-C" path
                         "--strip-components=1"))
               '#$(map car %squad-npm-sources)
               (list #$@(map cdr %squad-npm-sources)))
              (for-each copy-file
                        (list #$@(map cdr %squad-extra-notices))
                        '#$(map car %squad-extra-notices))
              (mkdir-p "node_modules/@bradygaster")
              (symlink "../../packages/squad-sdk"
                       "node_modules/@bradygaster/squad-sdk")
              (symlink "../../packages/squad-cli"
                       "node_modules/@bradygaster/squad-cli")))
          (replace 'patch-dependencies (lambda _ #t))
          (delete 'delete-lockfiles)
          ;; Installation is a workspace-aware copy, not npm pack/install.
          (delete 'repack)
          (delete 'avoid-node-gyp-rebuild)
          (replace 'configure (lambda _ #t))
          (add-before 'build 'make-fresh-storage-copies-writable
            (lambda _
              ;; Node's copyFile preserves the immutable store source's mode.
              ;; User-owned templates must remain editable after first init.
              ;; Never change permissions on a pre-existing user destination.
              (substitute* "packages/squad-sdk/src/storage/fs-storage-provider.ts"
                (("copyFile \\} from 'fs/promises'")
                 "copyFile, chmod as fsChmod } from 'fs/promises'")
                (("copyFileSync, rmSync \\} from 'fs'")
                 "copyFileSync, rmSync, chmodSync as fsChmodSync } from 'fs'")
                (("^      await copyFile\\(safeSrc, safeDest\\);")
                 (string-append
                  "      const mode = fsExistsSync(safeDest)\n"
                  "        ? (await fsStat(safeDest)).mode : undefined;\n"
                  "      await copyFile(safeSrc, safeDest);\n"
                  "      await fsChmod(safeDest, mode ?? "
                  "((await fsStat(safeDest)).mode | 0o200));"))
                (("^      copyFileSync\\(safeSrc, safeDest\\);")
                 (string-append
                  "      const mode = fsExistsSync(safeDest)\n"
                  "        ? statSync(safeDest).mode : undefined;\n"
                  "      copyFileSync(safeSrc, safeDest);\n"
                  "      fsChmodSync(safeDest, mode ?? "
                  "(statSync(safeDest).mode | 0o200));")))))
          (add-before 'build 'fix-init-preset-errors
            (lambda _
              ;; Skipped charters are successful repeat initialization.  Report
              ;; each real error (including scaffold failures) with its reason,
              ;; rather than mislabeling every no-install result as not found.
              (substitute* "packages/squad-cli/src/cli-entry.ts"
                (("^        if \\(errors.length > 0 && installed.length === 0\\) \\{")
                 "        for (const error of errors) {")
                (("^          console.error\\(`❌ Preset.*available presets.`\\);")
                 (string-append
                  "          console.error(`❌ ${error.agent}: ${error.reason}`);\n"
                  "          process.exitCode = 1;")))))
          (replace 'build
            (lambda _
              (setenv "SKIP_BUILD_BUMP" "1")
              (setenv "HOME" (string-append (getcwd) "/.build-home"))
              (mkdir-p (getenv "HOME"))
              ;; Compile native runtime components against the packaged Node.
              ;; Never retain node-pty's platform prebuilds or download headers.
              (for-each
               (lambda (path)
                 (when (file-exists? path) (delete-file-recursively path)))
               '("node_modules/node-pty/prebuilds"
                 "node_modules/node-pty/third_party/conpty"))
              (mkdir-p "node_modules/node-pty/build/Release")
              (invoke "g++" "-shared" "-fPIC" "-std=c++17" "-O2"
                      "-pthread" "-DNAPI_CPP_EXCEPTIONS" "-DNAPI_VERSION=8"
                      (string-append "-I" #$node-lts "/include/node")
                      "-Inode_modules/node-addon-api"
                      "node_modules/node-pty/src/unix/pty.cc" "-lutil"
                      (string-append "-Wl,-rpath," (ungexp gcc "lib") "/lib")
                      "-o" "node_modules/node-pty/build/Release/pty.node")
              ;; Koffi ships the native sources, API headers and CMake driver.
              ;; --prebuild is deliberately absent: cnoke cannot fetch headers.
              (with-directory-excursion "node_modules/koffi"
                (invoke #$(file-append node-lts "/bin/node")
                        "cnoke.cjs" "-P" "." "-D" "src/koffi" "--release"))
              ;; cnoke copies the finished addon to the platform directory.
              ;; Its versioned CMake work tree is build-only and records random
              ;; compiler probe filenames, so never ship it in the npm closure.
              (for-each delete-file-recursively
                        (find-files "node_modules/koffi/build/koffi"
                                    "^v[0-9].*_native$" #:directories? #t))
              ;; Run only reviewed source transformations, not npm hooks.
              (invoke #$(file-append node-lts "/bin/node")
                      "scripts/sync-skill-templates.mjs")
              (invoke #$(file-append node-lts "/bin/node")
                      "scripts/sync-templates.mjs" "--sync")
              (invoke #$(file-append node-lts "/bin/node")
                      "packages/squad-cli/scripts/patch-esm-imports.mjs")
              (invoke #$(file-append node-lts "/bin/node")
                      "packages/squad-cli/scripts/patch-ink-rendering.mjs")
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/typescript/bin/tsc"
                      "-p" "packages/squad-sdk/tsconfig.json")
              (copy-recursively "packages/squad-sdk/src/presets/builtin"
                                "packages/squad-sdk/dist/presets/builtin")
              (for-each delete-file
                        (find-files "packages/squad-sdk/dist/presets/builtin"
                                    "\\.ts$"))
              (invoke #$(file-append node-lts "/bin/node")
                      "node_modules/typescript/bin/tsc"
                      "-p" "packages/squad-cli/tsconfig.json")
              (copy-recursively "packages/squad-cli/src/remote-ui"
                                "packages/squad-cli/dist/remote-ui")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Genuine offline project initialization; no Copilot client,
                ;; provider credentials, GitHub remote, or browser is involved.
                (let ((repository (string-append (getcwd) "/.check-project")))
                  (mkdir-p repository)
                  ;; The upstream standalone mode writes a real local MCP
                  ;; launcher instead of probing npm or writing an npx spec.
                  (call-with-output-file ".build-home/squad"
                    (lambda (port)
                      (format port "#!~a/bin/sh\nexec ~a/bin/node ~s \"$@\"\n"
                              #$bash-minimal #$node-lts
                              (string-append (getcwd)
                               "/packages/squad-cli/dist/cli-entry.js"))))
                  (chmod ".build-home/squad" #o555)
                  (setenv "SQUAD_STANDALONE_HOME"
                          (string-append (getcwd) "/.build-home"))
                  (with-directory-excursion repository
                    (invoke #$(file-append git-minimal "/bin/git") "init" "-q")
                    (setenv "NO_COLOR" "1")
                    (invoke #$(file-append node-lts "/bin/node")
                            "../packages/squad-cli/dist/cli-entry.js"
                            "init" "--preset" "default")
                    (unless (file-exists? ".squad/team.md")
                      (error "Squad did not initialize its team state")))))))
          (replace 'install
            (lambda _
              (let ((modules (string-append #$output "/lib/node_modules"))
                    (doc (string-append #$output "/share/doc/squad"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p modules)
                (for-each
                 (lambda (path)
                   (let ((target
                          (if (string-prefix? "packages/" path)
                              (string-append modules "/@bradygaster/"
                                             (substring path
                                                        (string-length "packages/")))
                              (string-append #$output "/lib/" path))))
                     (mkdir-p (dirname target))
                     (copy-recursively path target)))
                 '#$%squad-runtime-modules)
                (for-each
                 (lambda (workspace)
                   (let* ((source (string-append "packages/" workspace))
                          (target (string-append modules "/@bradygaster/"
                                                 workspace)))
                     (mkdir-p target)
                     (for-each
                      (lambda (directory)
                        (copy-recursively (string-append source "/" directory)
                                          (string-append target "/" directory)))
                      '("dist" "templates"))
                     (copy-file (string-append source "/package.json")
                                (string-append target "/package.json"))
                     (copy-file "LICENSE" (string-append target "/LICENSE"))))
                 '("squad-sdk" "squad-cli"))
                (mkdir-p doc)
                (for-each
                 (lambda (file) (copy-file file (string-append doc "/" file)))
                 '("LICENSE" "README.md" "package-lock.json"))
                (mkdir-p bin)
                ;; Keep normal user state and authentication semantics.  The
                ;; isolated HOME belongs in the consumer proof, not this CLI.
                (call-with-output-file (string-append bin "/squad")
                  (lambda (port)
                    (format port (string-append
                                  "#!~a/bin/sh\n"
                                  "export PATH=~a/bin:~a/bin:\"$PATH\"\n"
                                  "export SQUAD_STANDALONE_HOME=~s\n"
                                  "exec ~a/bin/node ~s \"$@\"\n")
                            #$bash-minimal #$git-minimal #$node-lts bin #$node-lts
                            (string-append modules
                             "/@bradygaster/squad-cli/dist/cli-entry.js"))))
                (chmod (string-append bin "/squad") #o555)
                (symlink #$(file-append node-lts "/bin/node")
                         (string-append bin "/squad-node"))))))))
    (native-inputs
     (append (list cmake-minimal gcc git-minimal) (map cdr %squad-npm-sources)
             (map cdr %squad-extra-notices)))
    (inputs `(("bash-minimal" ,bash-minimal)
              ("node" ,node-lts)
              ("git-minimal" ,git-minimal)
              ("gcc:lib" ,gcc "lib")))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://github.com/bradygaster/squad")
    (synopsis "Human-led multi-agent CLI and SDK for GitHub Copilot")
    (description
     "Squad provides a CLI and TypeScript SDK for human-led multi-agent teams,
project scaffolding, workflow templates, presets and durable local state.  This
package builds the pinned upstream CLI and SDK with an offline fixed npm closure,
including source-built PTY and FFI addons.  The official sql.js SQLite WebAssembly
runtime and Yoga's official MIT WebAssembly are bundled with their notices.
Development tools and proprietary Copilot
platform executables are not installed.  Actual Copilot sessions require an
external, user-provided Copilot CLI (COPILOT_CLI_PATH), authentication and network
access.  Squad's normal authorization and user state behavior is retained; the
package supplies no credential or filesystem sandbox.  Package-manager upgrades
should be performed with Guix rather than npm self-installation.")
    (license (list license:expat license:asl2.0 license:isc license:bsd-2
                   license:bsd-3 license:cc0 license:public-domain))))
