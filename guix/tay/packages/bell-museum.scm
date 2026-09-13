;;; Guix package for the Bell Labs Software Museum.

(define-module (tay packages bell-museum)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages projects)
  #:use-module (gnu packages python))

(define-public bell-museum
  (package
    (name "bell-museum")
    (version "20260726-1.15f0093")
    ;; This is the commit-pinned, non-recursive origin from projects.scm.
    ;; Do not set `recursive?' here: the Inferno 1e1 gitlink names an SSH
    ;; submodule and its tree has a materially different licensing record.
    ;; The renderer instead accepts an explicitly supplied local checkout.
    (source (package-source htayj-bell-museum-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (delete 'build)
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; The complete upstream test suite requires the excluded
                ;; Inferno gitlink.  Check the dependency-free renderer and
                ;; the exact source commitment recorded by the museum instead.
                (invoke "python3" "scripts/render-inferno-specimens.py"
                        "--help")
                (invoke "python3" "-c"
                        (string-append
                         "import json; "
                         "manifest = json.load(open('docs/assets/"
                         "inferno-specimens.json')); "
                         "assert manifest['source_commit'] == "
                         "'a3c06a9d046c66c83120a4eed91b82dc674719f6'; "
                         "assert len(manifest['outputs']) == 7")))))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/bell-museum"))
                     (bin (string-append #$output "/bin"))
                     (renderer (string-append
                                data "/scripts/render-inferno-specimens.py")))
                (mkdir-p bin)
                (copy-recursively "docs" (string-append data "/docs"))
                (copy-recursively "scripts" (string-append data "/scripts"))
                (for-each (lambda (file)
                            (install-file file data))
                          '("LICENSE" "README.md"))
                ;; The upstream renderer already offers --source and --output.
                ;; Keeping it unmodified makes this command work with an
                ;; independently acquired checkout without packaging it.
                (call-with-output-file
                    (string-append bin "/bell-museum-render-inferno-specimens")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/python3~%import os~%import sys~%"
                             "os.execv(sys.executable, [sys.executable, ~s, "
                             "*sys.argv[1:]])~%")
                            #$python renderer)))
                (chmod (string-append bin
                                      "/bell-museum-render-inferno-specimens")
                       #o755))))
          (add-after 'install 'check-installed-renderer
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke (string-append #$output
                                       "/bin/bell-museum-render-inferno-specimens")
                        "--help")))))))
    (inputs (list python))
    (synopsis "Source-grounded Bell Labs software museum documentation")
    (description
     "Bell Museum installs source-grounded documentation and deterministic
Inferno 1e1 specimen-rendering tooling.  The command
@command{bell-museum-render-inferno-specimens} takes @option{--source} and
@option{--output} arguments, so it can render from a separately obtained local
Inferno checkout without accessing the network.  The historical Inferno source
tree is deliberately not included because its pinned checkout contains both a
default MIT notice and a separate limited-use license file; users must resolve
that source's licensing before supplying it to the renderer.")
    (home-page "https://github.com/htayj/bell-museum")
    (license license:expat)))
