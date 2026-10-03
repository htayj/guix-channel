;;; Official, pinned ECA release.  The Maven/AOT closure is supplied upstream,
;;; not rebuilt from source here; no dependency resolution occurs in the build.

(define-module (tay packages editor-code-assistant-eca)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

(define %eca-commit "52b6f015b3857d60920f7edbe9ed5692db0ba57d")

(define %eca-release-jar
  (origin
    (method url-fetch)
    (uri "https://github.com/editor-code-assistant/eca/releases/download/0.154.0/eca.jar")
    (file-name "eca-0.154.0.jar")
    (sha256
     (base32 "18abg5r79sbb8qzq8pahbc21fpxfmzbn4cnrldsgg8ahgixqckm4"))))

(define-public eca
  (package
    (name "eca")
    (version "0.154.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/editor-code-assistant/eca/tar.gz/"
                           %eca-commit))
       (file-name (string-append "eca-" %eca-commit ".tar.gz"))
       (sha256
        (base32 "17zpc2dk7dinw138rjza5nx70v8fa3w21bvlb7zhqimbgmrc9qyz"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (setenv "HOME" (getcwd))
                (invoke (string-append #$openjdk24:jdk "/bin/java")
                        "-jar" #$%eca-release-jar "--version")
                (invoke (string-append #$openjdk24:jdk "/bin/java")
                        "-jar" #$%eca-release-jar "--help"))))
          (replace 'install
            (lambda _
              (let* ((share (string-append #$output "/share/eca"))
                     (doc (string-append #$output "/share/doc/eca"))
                     (bin (string-append #$output "/bin")))
                (mkdir-p share)
                (mkdir-p doc)
                (mkdir-p bin)
                (copy-file #$%eca-release-jar (string-append share "/eca.jar"))
                ;; Preserve the exact preferred source, lockfile and release
                ;; build workflow, rather than implying a local Maven rebuild.
                (copy-file #$source (string-append doc "/source.tar.gz"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md" "PRIVACY.md" "CHANGELOG.md"
                            "deps.edn" "deps-lock.json" "build.clj"))
                (install-file ".github/workflows/release.yml" doc)
                ;; The complete JAR (including every original notice and POM)
                ;; is retained.  Also expose its legal material for readers.
                (mkdir-p (string-append doc "/bundled-notices"))
                (with-directory-excursion (string-append doc "/bundled-notices")
                  (invoke "unzip" "-q" #$%eca-release-jar
                          "*LICENSE*" "*NOTICE*" "META-INF/maven/*"))
                (call-with-output-file (string-append doc "/PROVENANCE")
                  (lambda (port)
                    (format port
                            (string-append
                             "Official ECA 0.154.0 AOT uberjar; not rebuilt by Guix.~%"
                             "Source commit: ~a~%"
                             "Release: https://github.com/editor-code-assistant/eca/"
                             "releases/tag/0.154.0~%"
                             "Jar SHA256: a44e867b7c50a1f774a3d93262d7afae"
                             "5f17045b505d843f466be97472794ba1~%"
                             "Runtime: separately packaged Guix OpenJDK 24; "
                             "no Oracle GraalVM native image.~%"
                             "Dependency notices and Maven provenance: "
                             "bundled-notices/ and eca.jar.~%")
                            #$%eca-commit)))
                (call-with-output-file (string-append bin "/eca")
                  (lambda (port)
                    (format port "#!~a~%exec ~a -jar ~a \"$@\"~%"
                            #$(file-append bash-minimal "/bin/bash")
                            (string-append #$openjdk24:jdk "/bin/java")
                            (string-append share "/eca.jar"))))
                (chmod (string-append bin "/eca") #o555)))))))
    (native-inputs (list unzip))
    (inputs `(("bash-minimal" ,bash-minimal) ("openjdk:jdk" ,openjdk24 "jdk")))
    (home-page "https://eca.dev")
    (synopsis "Editor-agnostic code assistant server")
    (description
     "ECA provides an editor-agnostic JSON-RPC code assistant server and CLI.
This package installs the official, hash-pinned 0.154.0 AOT release JAR with
its bundled Maven dependency closure and a separately packaged OpenJDK 24
runtime.  It is not a Guix source rebuild.  The exact release source,
dependency lockfile, build workflow, and bundled license notices are retained.
No Maven resolution or server download occurs during installation or startup.
Use @code{eca server} with an editor client such as @code{eca-emacs}.
Provider credentials, network access, model services, optional plugins and
MCP servers are user-controlled runtime concerns; local JSON-RPC session
operations do not require provider credentials.")
    ;; ECA is Apache-2.0.  The unchanged uberjar also bundles Clojure/EPL,
    ;; Jetty/Servlet EPL-or-Apache, MIT, BSD and CDDL code; Javassist selects
    ;; its Apache alternative.  The OpenJDK runtime has its own package license.
    (license (list license:asl2.0 license:epl1.0 license:epl2.0
                   license:expat license:bsd-2 license:cddl1.1))))
