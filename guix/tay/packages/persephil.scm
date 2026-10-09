;;; GNU Guix package for cookinrelaxin/persephil.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages persephil)
  #:use-module (guix build-system node)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages node)
  #:use-module (srfi srfi-1)
  #:use-module (tay packages persephil-npm-sources)
  #:use-module (tay packages starred-a-c))

(define-public persephil
  (package
    (name "persephil")
    (version (git-version "1.0.0" "0"
                          "1e10afbbcb8c6f56d2cc22db0c915a9d64ecd8d6"))
    ;; Reuse the preservation origin without changing that package or its bytes.
    (source (package-source cookinrelaxin-persephil-source))
    (build-system node-build-system)
    (arguments
     (list
      #:node node-lts
      #:modules '((guix build node-build-system) (guix build utils))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'fix-exceljs-module-case
            (lambda _
              ;; npm's package name is lower-case, also on case-sensitive hosts.
              ;; This is the only change to the upstream program.
              (substitute* "main.js"
                (("require\\('excelJS'\\)") "require('exceljs')"))))
          (add-after 'fix-exceljs-module-case 'materialize-locked-node-modules
            (lambda _
              ;; Preserve every lock installation path, including nested versions.
              ;; Do not resolve ranges, install packages, or run lifecycle hooks.
              (for-each
               (lambda (path archive)
                 (mkdir-p path)
                 (invoke "tar" "xzf" archive "-C" path
                         "--strip-components=1"))
               '#$(map car %persephil-npm-sources)
               (list #$@(map (lambda (row) (list-ref row 2))
                            %persephil-npm-sources)))
              (for-each copy-file
                        (list #$@(map cadr %persephil-extra-notices))
                        '#$(map car %persephil-extra-notices))))
          (delete 'patch-dependencies)
          (delete 'delete-lockfiles)
          (delete 'configure)
          (delete 'repack)
          (delete 'avoid-node-gyp-rebuild)
          (replace 'build
            (lambda _
              ;; Plain JavaScript has no compilation or upstream build script.
              (invoke #$(file-append node-lts "/bin/node")
                      "--check" "main.js")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Upstream's npm test is an npm-init placeholder that exits 1.
                ;; These are real offline closure checks, not that test suite.
                (invoke #$(file-append node-lts "/bin/node") "-e"
                        (string-append
                         "for (const name of ['exceljs', 'got', 'jsdom', 'moment']) "
                         "require(name);"))
                (invoke
                 #$(file-append node-lts "/bin/node") "-e"
                 (string-append
                  "const assert = require('assert'); "
                  "for (let i = 1; i < process.argv.length; i += 2) { "
                  "const p = require('./' + process.argv[i] + '/package.json'); "
                  "assert.strictEqual(p.name + '-' + p.version, process.argv[i + 1]); }")
                 #$@(append-map (lambda (row) (list (car row) (cadr row)))
                                %persephil-npm-sources)))))
          (replace 'install
            (lambda _
              (let ((app (string-append #$output "/lib/node_modules/persephil"))
                    (doc (string-append #$output "/share/doc/persephil"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p app)
                ;; Retain dependency source, manifests and every archive notice.
                (copy-recursively "node_modules" (string-append app "/node_modules"))
                (for-each
                 (lambda (file) (copy-file file (string-append app "/" file)))
                 '("main.js" "package.json" "package-lock.json" "LICENSE"))
                (mkdir-p doc)
                (for-each
                 (lambda (file) (copy-file file (string-append doc "/" file)))
                 '("README.md" "LICENSE" "package-lock.json"))
                (mkdir-p bin)
                ;; No chdir: upstream writes its dated workbook in the caller's
                ;; working directory.  Pass the user's legacy HTML URL unchanged.
                (call-with-output-file (string-append bin "/persephil")
                  (lambda (port)
                    (format port "#!~a/bin/sh\nexec ~a/bin/node ~s \"$@\"\n"
                            #$bash-minimal #$node-lts
                            (string-append app "/main.js"))))
                (chmod (string-append bin "/persephil") #o555)))))))
    (native-inputs
     (append (map (lambda (row) (list-ref row 2)) %persephil-npm-sources)
             (map cadr %persephil-extra-notices)))
    (inputs (list bash-minimal node-lts))
    (home-page "https://github.com/cookinrelaxin/persephil")
    (synopsis "Export legacy PhiloLogic Latin search results to spreadsheets")
    (description
     "Persephil exports legacy PhiloLogic HTML search results to an XLSX
workbook.  It takes a search-results URL as its argument and writes a dated
workbook in the caller's working directory, preserving bold search matches and
work and passage references.  This package retains the pinned upstream HTML
parser; it does not implement the current PhiloLogic JSON API.  All locked npm
sources and their notices are installed without running npm lifecycle scripts.")
    ;; The authored LICENSE is GPLv3.  package.json's ISC field is the untouched
    ;; npm-init template, not the project's licensing intent.  Dependency licenses
    ;; are separately audited in persephil-npm-sources.scm and retained in situ.
    (license
     (delete-duplicates
      (cons license:gpl3
            (append-map (lambda (row)
                          (let ((license (list-ref row 3)))
                            (if (list? license) license (list license))))
                        %persephil-npm-sources))))))
