;;; GNU Guix package for the unrs-resolver Node-API package.
;;; SPDX-License-Identifier: GPL-3.0-or-later
;;;
;;; The native addon is compiled from the tagged upstream workspace with
;;; Cargo's locked registry closure from (tay packages
;;; unrs-resolver-cargo-sources); no @unrs/resolver-binding-* prebuilt npm
;;; package is used.

(define-module (tay packages unrs-resolver)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages node)
  #:use-module (gnu packages rust)
  #:use-module (ice-9 match)
  #:use-module (tay packages unrs-resolver-cargo-sources))

;; Four linked crates are published without their license text.  Each file
;; is taken from the upstream commit recorded in the crate's
;; .cargo_vcs_info.json.
(define (unrs-resolver-crate-license repository commit hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://raw.githubusercontent.com/" repository "/"
                        commit "/LICENSE"))
    (file-name (string-append (basename repository) "-"
                              (string-take commit 12) "-LICENSE"))
    (sha256 (base32 hash))))

(define %unrs-resolver-supplied-licenses
  (list
   (list "fast-glob" "1.0.1"
         (unrs-resolver-crate-license
          "oxc-project/fast-glob" "96fc2766c419687ae5b29a34c304538251535595"
          "0aqfd6qzld39k5vn07shnnscs7azcdxd2c4613d0qk7sd71va838"))
   (list "napi" "3.9.0"
         (unrs-resolver-crate-license
          "napi-rs/napi-rs" "e9c50bb430b7d34659c0541f600e1e323d37432a"
          "05bj571a6pif2qbmh7sckrjk9pghg05zrzfv5siz6b9h6djyc71z"))
   (list "napi-sys" "3.2.1"
         (unrs-resolver-crate-license
          "napi-rs/napi-rs" "be4b16ca00aa2cecd19be6ffe6de59495b471b14"
          "05bj571a6pif2qbmh7sckrjk9pghg05zrzfv5siz6b9h6djyc71z"))
   (list "nodejs-built-in-modules" "1.0.0"
         (unrs-resolver-crate-license
          "oxc-project/nodejs-built-in-modules"
          "9117efa38fe088325e8a1036a8ddea7f3546c1ac"
          "0a7h03z098f21vxbvpml04yb6rla03012zaa2r42v0dirxbq4lr0"))))

(define-public node-unrs-resolver
  (package
    (name "node-unrs-resolver")
    (version "1.12.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/unrs/unrs-resolver")
             ;; Tag v1.12.2.
             (commit "ccb26d205e2938b16069c64a28996b48ee97ff94")))
       (file-name (git-file-name "unrs-resolver" version))
       (sha256
        (base32 "02g39s74cszha0lgizp7pmkd04wfklrcxixhlf72b94hzdapliw8"))
       (modules '((guix build utils)))
       ;; A bundled minified Yarn release used only by a test fixture.
       (snippet
        '(delete-file-recursively "fixtures/yarn/.yarn"))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; Upstream pins rust-toolchain.toml to 1.95.0 for development; its
      ;; declared rust-version, and the highest of the locked crates, is 1.88.
      #:rust rust-1.94
      #:install-source? #f
      ;; Upstream's release build: `napi build --platform --release
      ;; --features allocator` on the napi workspace member.
      #:cargo-build-flags
      ''("--release" "--locked" "--package" "unrs_resolver_napi"
         "--features" "allocator")
      #:modules '((guix build cargo-build-system)
                  (guix build utils)
                  (ice-9 match)
                  (json)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'save-locked-cargo-graph
            (lambda _
              (copy-file "Cargo.lock" ".guix-Cargo.lock")
              ;; Its only rule for this target, -z nodelete for GNU, is also
              ;; emitted by napi-build; Guix's .cargo/config replaces it.
              (delete-file ".cargo/config.toml")))
          (add-after 'check-for-pregenerated-files
              'restore-locked-offline-cargo-graph
            (lambda _
              (setenv "CARGO_NET_OFFLINE" "true")
              (copy-file ".guix-Cargo.lock" "Cargo.lock")
              ;; Crates are vendored from the Guix origins, some of which
              ;; drop prebuilt files, so registry checksums do not apply.
              (substitute* "Cargo.lock" (("^checksum = .*$") ""))))
          ;; Upstream's Rust and Vitest suites need pnpm- and Yarn-installed
          ;; fixture node_modules trees; 'check-installed-package exercises
          ;; the delivered package through its own JavaScript loader.
          (delete 'check)
          (replace 'install
            (lambda _
              (let ((module (string-append #$output
                                           "/lib/node_modules/unrs-resolver"))
                    (licenses (string-append
                               #$output
                               "/share/doc/node-unrs-resolver/licenses")))
                (define (ordered value)
                  ;; guile-json returns object members in reverse order.
                  (cond ((vector? value) (vector-map ordered value))
                        ((and (pair? value) (pair? (car value)))
                         (reverse
                          (map (match-lambda
                                 ((key . item) (cons key (ordered item))))
                               value)))
                        (else value)))
                (define (vector-map proc vector)
                  (list->vector (map proc (vector->list vector))))
                (mkdir-p module)
                (copy-file "target/release/libunrs_resolver_napi.so"
                           (string-append module
                                          "/resolver.linux-x64-gnu.node"))
                (for-each (lambda (file)
                            (install-file (string-append "napi/" file) module))
                          '("index.js" "index.d.ts" "browser.js"))
                (for-each (lambda (file) (install-file file module))
                          '("LICENSE" "README.md"))
                ;; The published manifest, without its development fields,
                ;; postinstall hook and prebuilt binding dependency.
                (call-with-output-file (string-append module "/package.json")
                  (lambda (port)
                    (scm->json
                     (remove (match-lambda
                               ((key . _)
                                (member key '("scripts" "dependencies"
                                              "devDependencies"
                                              "packageManager"))))
                             (ordered (call-with-input-file "package.json"
                                        json->scm)))
                     port #:pretty #t)
                    (newline port)))
                (for-each
                 (match-lambda
                   ((id base files)
                    (let ((directory
                           (find (lambda (path)
                                   (file-exists?
                                    (string-append path "/Cargo.toml")))
                                 (map (lambda (suffix)
                                        (string-append "guix-vendor/" base
                                                       suffix))
                                      '(".tar.gz" ".tar.zst" ".crate" ""))))
                          (destination (string-append licenses "/" id)))
                      (unless directory
                        (error "crate license source is missing" id))
                      (for-each
                       (lambda (file)
                         (let ((target (string-append destination "/" file)))
                           (mkdir-p (dirname target))
                           (copy-file (string-append directory "/" file)
                                      target)))
                       files))))
                 '#$(map (match-lambda
                           ((crate version files)
                            (list (string-append crate "-" version)
                                  (string-append
                                   (crate-name->package-name crate)
                                   "-" version)
                                  files)))
                         %unrs-resolver-crate-licenses))
                (for-each
                 (match-lambda
                   ((id file)
                    (mkdir-p (string-append licenses "/" id))
                    (copy-file file (string-append licenses "/" id
                                                   "/LICENSE"))))
                 (list #$@(map (match-lambda
                                 ((crate version origin)
                                  #~(list #$(string-append crate "-" version)
                                          #$origin)))
                               %unrs-resolver-supplied-licenses))))))
          (add-after 'install 'check-installed-package
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (unsetenv "NAPI_RS_NATIVE_LIBRARY_PATH")
                (invoke "node" "-e" "
const assert = require('node:assert');
const path = require('node:path');
const [module, fixtures] = process.argv.slice(1);
const resolver = require(module);
const addon = path.join(module, 'resolver.linux-x64-gnu.node');
assert.ok(require.cache[addon], 'loader did not load ' + addon);
assert.strictEqual(resolver.sync(fixtures, './a').path,
                   path.join(fixtures, 'a.js'));
const factory = new resolver.ResolverFactory({ builtinModules: true });
assert.deepStrictEqual(factory.sync(fixtures, 'node:fs').builtin,
                       { resolved: 'node:fs', isRuntimeModule: true });
"
                        (string-append #$output
                                       "/lib/node_modules/unrs-resolver")
                        (string-append (getcwd)
                                       "/fixtures/enhanced-resolve/test/fixtures"))))))))
    (native-inputs (list cmake-minimal node-lts))
    (inputs %unrs-resolver-cargo-inputs)
    ;; The installed file name encodes the linux-x64-gnu platform triple that
    ;; upstream's JavaScript loader requests.
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/unrs/unrs-resolver")
    (synopsis "Node.js ESM and CommonJS module resolver (Node-API addon)")
    (description
     "unrs-resolver implements Node.js ESM and CommonJS module resolution,
with TypeScript @file{tsconfig.json} paths and Yarn Plug'n'Play support, in
Rust.  This package builds its Node-API addon from source, with the mimalloc
allocator, and installs the npm package as
@file{lib/node_modules/unrs-resolver} with
@file{resolver.linux-x64-gnu.node}.  The browser entry point re-exports the
WebAssembly binding package, which is not provided.")
    ;; unrs-resolver, napi-rs and mimalloc are MIT.  Linked crates are MIT,
    ;; Apache-2.0 or dual-licensed (with BSL-1.0, Unlicense, GPL-2.0 or
    ;; Apache-2.0 WITH LLVM-exception as further options), plus zlib in
    ;; zlib-rs, libz-rs-sys and foldhash, ISC in libloading, and BSD-2-Clause
    ;; in pnp.  Their license texts are installed under share/doc.
    (license (list license:expat license:asl2.0 license:zlib license:isc
                   license:bsd-2))))
