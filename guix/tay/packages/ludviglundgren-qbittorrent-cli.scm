;;; Canonical Ludvig Lundgren client, distinct from the same-named Python client.

(define-module (tay packages ludviglundgren-qbittorrent-cli)
  #:use-module (guix build-system go)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages golang)
  #:use-module (srfi srfi-1)
  #:use-module (tay packages starred-i-m)
  #:use-module (tay packages ludviglundgren-qbittorrent-cli-go-sources))

(define-public ludviglundgren-qbittorrent-cli
  (package
    (name "ludviglundgren-qbittorrent-cli")
    (version "2.3.0")
    ;; Reuse the canonical source-only origin, not another qbittorrent-cli.
    (source (package-source ludviglundgren-qbittorrent-cli-source))
    (build-system go-build-system)
    (arguments
     (list
      #:go go-1.25
      #:import-path "github.com/ludviglundgren/qbittorrent-cli/cmd/qbt"
      #:unpack-path "github.com/ludviglundgren/qbittorrent-cli"
      #:install-source? #f
      ;; GOPATH unions symlink module resources; Go's embed requires files.
      #:embed-files #~'("children" "nodes" "text")
      #:parallel-build? #f
      #:parallel-tests? #f
      #:build-flags
      #~(list "-p=1"
              (string-append
               "-ldflags=-s -w -buildid= -X main.version=" #$version
               " -X main.commit=7b5f87de149d699c0bd955867fe5d57418b6ec68"
               " -X main.date=1970-01-01T00:00:00Z"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'setup-go-environment 'require-offline-toolchain
            (lambda _
              ;; Guix assembles the exact source graph in GOPATH.  Do not let
              ;; upstream module or toolchain directives initiate downloads.
              (setenv "GOPROXY" "off")
              (setenv "GOSUMDB" "off")
              (setenv "GOTOOLCHAIN" "local")
              (setenv "GOTELEMETRY" "off")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "go" "test" "-p=1"
                        "github.com/ludviglundgren/qbittorrent-cli/..."))))
          (add-after 'install 'install-alias-and-documentation
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (srfi srfi-1))
              (let* ((source "src/github.com/ludviglundgren/qbittorrent-cli")
                     (doc (string-append #$output
                                         "/share/doc/ludviglundgren-qbittorrent-cli"))
                     (licenses (string-append doc "/licenses"))
                     (retained-source-names
                      '#$(map package-name
                              (filter
                               (lambda (package)
                                 (assq-ref (package-properties package)
                                           'retain-source?))
                               %ludviglundgren-qbittorrent-cli-go-modules))))
                (symlink "qbt" (string-append #$output "/bin/qbittorrent-cli"))
                (for-each
                 (lambda (file) (install-file (string-append source "/" file) doc))
                 '("LICENSE" "README.md" "go.mod" "go.sum"))
                (copy-recursively (string-append source "/docs/src/content/docs")
                                  (string-append doc "/commands"))
                ;; Every source node installs all root and nested notices
                ;; without flattening filenames.  Preserve them in the static
                ;; application's output, not just its build inputs.
                (for-each
                 (lambda (input)
                   (let ((label (car input)) (directory (cdr input)))
                     (when (string-prefix? "go-qbt-" label)
                       (copy-recursively (string-append directory "/share/doc/" label)
                                         (string-append licenses "/" label)))
                     ;; MPL-covered files must remain available alongside the
                     ;; executable.  Keep the complete exact source module.
                     (when (member label retained-source-names)
                       (copy-recursively (string-append directory "/src")
                                         (string-append doc "/sources/" label)))))
                 inputs)
                ;; The linked Go runtime and standard library have their own
                ;; notices, including third-party subtrees in the source tree.
                (let* ((go (assoc-ref inputs "go"))
                       (go-doc (string-append go "/share/doc"))
                       (go-source (string-append go "/share/go/src")))
                  (for-each
                   (lambda (file)
                     (let ((target (string-append licenses "/go-toolchain"
                                                  (substring file
                                                             (string-length go-doc)))))
                       (mkdir-p (dirname target))
                       (copy-file file target)))
                   (find-files
                    go-doc
                    "(COPYING|LICENSE|NOTICE|PATENTS|AUTHORS)([-.][[:alnum:]_-]+)?$"))
                  (for-each
                   (lambda (file)
                     (let ((target (string-append licenses "/go-standard-library"
                                                  (substring file
                                                             (string-length go-source)))))
                       (mkdir-p (dirname target))
                       (copy-file file target)))
                   (find-files
                    go-source
                    "(COPYING|LICENSE|NOTICE|PATENTS)([-.][[:alnum:]_-]+)?$")))))))))
    (inputs %ludviglundgren-qbittorrent-cli-go-modules)
    (synopsis "Command-line management of qBittorrent")
    (description
     "This is Ludvig Lundgren's Go command-line client for the qBittorrent
Web API.  It provides torrent, category, tag, transfer and application
management commands, as well as local bencode and torrent metadata tools.
The upstream command is @command{qbt}; @command{qbittorrent-cli} names the
same executable.  This package builds the exact release module graph offline
and installs its redistribution notices and required corresponding sources.
It does not install a server or create a client configuration.")
    (home-page "https://github.com/ludviglundgren/qbittorrent-cli")
    ;; The client itself is MIT; installed static libraries, notices, and
    ;; corresponding source also retain their upstream free licenses.
    (license (list license:expat license:mpl2.0 license:asl2.0
                   license:bsd-0 license:bsd-2 license:bsd-3
                   license:public-domain license:cc-by4.0 license:cc0))))