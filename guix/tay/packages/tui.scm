;;; GNU Guix package for pmatiello's Clojure terminal UI library.

(define-module (tay packages tui)
  #:use-module (guix build-system clojure)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages clojure)
  #:use-module (gnu packages java)
  #:use-module (tay packages starred-n-r))

(define-public tui
  (package
    (name "tui")
    (version "0.2.0-0.e435b1b")
    ;; Preserve the reviewed snapshot's exact commit and fixed archive hash.
    (source (package-source pmatiello-tui-source))
    (build-system clojure-build-system)
    (arguments
     (list
      #:clojure clojure
      #:jdk icedtea
      #:source-dirs #~'("src")
      #:test-dirs #~'("test")
      #:doc-dirs #~'()
      #:jar-names #~'("tui.jar")
      ;; clojure.test is part of the Guix runtime.  Run every upstream test
      ;; directly, without downloading the deps.edn Git test-runner alias.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-consumer-runtime
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (share (string-append out "/share/tui"))
                     (doc (string-append out "/share/doc/tui"))
                     (runtime-jars
                      (sort (find-files
                             (string-append #$clojure "/share/java")
                             "\\.jar$") string<?))
                     (classpath
                      (string-join
                       (cons (string-append out "/share/java/tui.jar")
                             runtime-jars) ":")))
                (when (null? runtime-jars)
                  (error "Guix Clojure runtime has no installed jars"))
                (mkdir-p bin)
                (mkdir-p doc)
                ;; Keep the tests available for an installed-jar proof.  They
                ;; are not merged into the runtime jar or changed at build time.
                (copy-recursively "test" (string-append share "/tests"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README.md" "CHANGELOG.md"
                            "deps.edn" "build.clj"))
                (call-with-output-file (string-append bin "/tui-clojure")
                  (lambda (port)
                    (format port
                            (string-append
                             "#!~a/bin/sh~%"
                             "exec ~a/bin/java -Dfile.encoding=UTF-8 "
                             "-Djava.io.tmpdir=\"${TMPDIR:-/tmp}\" "
                             "-Duser.home=\"${HOME:-/tmp}\" "
                             "-cp '~a'${CLASSPATH:+:\"$CLASSPATH\"} "
                             "clojure.main \"$@\"~%")
                            #$bash-minimal #$icedtea:jdk
                            classpath)))
                (chmod (string-append bin "/tui-clojure") #o555)))))))
    (inputs (list (list "bash-minimal" bash-minimal)
                  (list "icedtea:jdk" icedtea "jdk")))
    ;; The pinned Guix Clojure jar already includes spec.alpha and
    ;; core.specs.alpha; upstream declares no other runtime dependencies.
    (propagated-inputs (list clojure))
    (home-page "https://github.com/pmatiello/tui")
    (synopsis "Styled terminal text and line input for Clojure")
    (description
     "Tui provides page rendering, ANSI-styled text output, flushing and
line-oriented standard input for Clojure programs.  This package preserves the
complete upstream library and provides an offline @command{tui-clojure}
launcher for local consumers.  It does not implement a cursor-addressed screen
or raw keyboard input.  No Maven, Clojars or Git dependency resolution occurs
at build time or runtime.")
    (license license:epl2.0)))
