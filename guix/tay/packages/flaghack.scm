;;; GNU Guix package for htayj/flaghack.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages flaghack)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages node)
  #:use-module (gnu packages node-xyz)
  #:use-module (tay packages flaghack-npm-sources)
  #:use-module (tay packages flaghack-go-sources)
  #:use-module (tay packages projects))

;; This list was generated from the production dependency graph resolved by
;; pnpm 9.10.0 and its entries are verified as Guix SHA-256 origins.
(define %flaghack-npm-archives (map cdr %flaghack-npm-sources))
(define flaghack-pnpm
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/pnpm/-/pnpm-9.10.0.tgz")
    (file-name "pnpm-9.10.0.tgz")
    (sha256
     (base32 "04sbvrwfh4qzs15p5lk14zhqbpxmsr7vqfggzfz43bdnvfw8lnim"))))

(define flaghack-charm
  (package
    (name "flaghack-charm")
    (version "20260713-1.772c47e")
    (source (package-source htayj-flaghack-source))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.25 #:import-path "flaghack/charm"
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'select-charm-module
                 (lambda _
                   (let* ((dest "src/flaghack/charm")
                          (nested (string-append dest "/packages/cli/charm"))
                          (temporary "flaghack-charm-source"))
                     (copy-recursively nested temporary)
                     (delete-file-recursively dest)
                     (mkdir-p dest)
                     (copy-recursively temporary dest))))
               ;; Check the client itself.  Testing every imported source
               ;; package would also require their test-only module graphs.
               (replace 'check (lambda _ (invoke "go" "test" "flaghack/charm")))
               (add-after 'install 'rename-program
                 (lambda _
                   (rename-file (string-append #$output "/bin/charm")
                                (string-append #$output "/bin/flaghack")))))))
    (inputs %flaghack-charm-go-modules)
    (home-page "https://github.com/htayj/flaghack")
    (synopsis "Charm terminal client for Flag Hack")
    (description "The Flag Hack Charmbracelet terminal client, built from the
pinned upstream source and an offline Go module graph.")
    (license license:agpl3+)))

(define-public flaghack
  (package
    (name "flaghack")
    (version "20260713-1.772c47e")
    (source (package-source htayj-flaghack-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda _
              ;; All runtime archives, including tsx and esbuild, are fixed
              ;; Guix inputs.  This has no package-manager or network step.
              (mkdir-p "node_modules")
              (for-each
               (lambda (name tarball)
                 (let ((target (string-append "node_modules/" name)))
                   (mkdir-p target)
                   (invoke "tar" "xzf" tarball "-C" target
                           "--strip-components=1")))
               (list #$@(map car %flaghack-npm-sources))
               (list #$@(map cdr %flaghack-npm-sources)))))
          (delete 'build)
          (replace 'install
            (lambda _
              (let ((site (string-append #$output "/share/flaghack"))
                    (program (string-append #$output "/bin/flaghack-server"))
                    (charm (string-append #$output "/bin/flaghack")))
                (mkdir-p site)
                (copy-recursively "." site)
                (copy-recursively "node_modules" (string-append site "/node_modules"))
                (mkdir-p (dirname program))
                (copy-file #$(file-append flaghack-charm "/bin/flaghack") charm)
                (chmod charm #o555)
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh~%cd ~s~%exec ~a/bin/node --import ~a/node_modules/tsx/dist/loader.mjs packages/server/src/server.ts \"$@\"~%"
                            #$bash-minimal site #$node-lts site)))
                (chmod program #o555)
                (let ((doc (string-append #$output "/share/doc/flaghack")))
                  (mkdir-p doc)
                  (copy-file "LICENSE" (string-append doc "/LICENSE"))
                  (copy-file "packages/domain/LICENSE" (string-append doc "/domain-LICENSE"))
                  (copy-file "packages/server/LICENSE" (string-append doc "/server-LICENSE")))))))))
    (native-inputs
     (append (list flaghack-pnpm node-lts node-typescript bash-minimal flaghack-charm)
             %flaghack-npm-archives))
    (home-page "https://github.com/htayj/flaghack")
    (synopsis "Local Flag Hack HTTP game server")
    (description
     "Flag Hack is a local HTTP game server.  Its fixed pnpm lockfile selects
registry artifacts cached before an offline, frozen-lockfile installation.  The
installed launcher runs compiled JavaScript and keeps save data outside the
immutable store.")
    (license license:agpl3+)))
