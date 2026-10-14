;;; Test-only PowerMock closure matching AsciiPanel's upstream Maven dependency.
(define-module (tay packages eversector-test-libraries)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java))

(define-public java-eversector-powermock-mockito
  (package
    (name "java-eversector-powermock-mockito")
    (version "1.6.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/powermock/powermock/tar.gz/refs/tags/"
             "powermock-" version))
       (file-name (string-append "powermock-" version ".tar.gz"))
       (sha256
        (base32 "0id7z7bib1lcrlfyby5bnvv75s7pf5jyyr4jm96j4kfq24j1rf3q"))
       (modules '((guix build utils)))
       (snippet
        #~(for-each delete-file (find-files "." "\\.(jar|class)$")))))
    (build-system gnu-build-system)
    (properties '((hidden? . #t)))
    (native-inputs
     (list (list "icedtea:jdk" icedtea-8 "jdk")
           (list "zip" zip)))
    ;; Mockito 1.10.19 is the version selected by PowerMock 1.6.5 itself.
    ;; Propagate the entire public runtime closure for the unchanged upstream
    ;; AsciiPanel tests; never put a second PowerMock version on this classpath.
    (propagated-inputs
     (list java-mockito-1 java-cglib java-jboss-javassist java-objenesis
           java-junit-4.13.2 java-hamcrest-core))
    (arguments
     (list
      ;; PowerMock's own test suite also requires its separate examples and
      ;; EasyMock/TestNG APIs.  This private test dependency is exercised by the
      ;; consumer's complete, unchanged AsciiPanelTest suite instead.
      #:tests? #f
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-source
            (lambda _
              (setenv "TZ" "UTC")
              (setenv "SOURCE_DATE_EPOCH" "315532800")
              (mkdir-p "original-source")
              (for-each
               (lambda (module)
                 (copy-recursively module
                                   (string-append "original-source/" module)))
               '("reflect" "core" "api/support" "api/mockito-common"
                 "api/mockito" "modules/module-impl/junit4-common"
                 "modules/module-impl/junit4"))
              ;; Guix's Mockito 1 package uses its source-built public CGLIB,
              ;; rather than Mockito's bundled, relocated copy.  Use the same
              ;; namespace in PowerMock's genuine Mockito adapter sources.
              (substitute* (find-files "api/mockito/src/main/java" "\\.java$")
                (("org\\.mockito\\.cglib") "net.sf.cglib"))
              ;; Give javac 8 a single captured Runner type before calling
              ;; Whitebox's generic constructor helper.  The selected delegate
              ;; class and constructor arguments are unchanged.
              (substitute*
                  (string-append
                   "modules/module-impl/junit4/src/main/java/"
                   "org/powermock/modules/junit4/internal/impl/"
                   "DelegatingPowerMockRunner.java")
                (("return Whitebox\\.invokeConstructor\\([[:space:]]*$")
                 "final Class<? extends Runner> delegateClass =\n")
                ((": PowerMockRunnerDelegate\\.DefaultJUnitRunner\\.class,")
                 (string-append
                  ": PowerMockRunnerDelegate.DefaultJUnitRunner.class;\n"
                  "                    return "
                  "Whitebox.invokeConstructor(delegateClass,")))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((modules
                      '("reflect" "core" "api/support" "api/mockito-common"
                        "api/mockito" "modules/module-impl/junit4-common"
                        "modules/module-impl/junit4"))
                     (sources
                      (sort
                       (append-map
                        (lambda (module)
                          (find-files (string-append module "/src/main/java")
                                      "\\.java$"))
                        modules)
                       string<?))
                     (classpath
                      (string-join
                       (append-map
                        (lambda (input)
                          (if (string-prefix? "java-" (car input))
                              (find-files (cdr input) "\\.jar$") '()))
                        inputs)
                       ":")))
                (mkdir-p "build/classes")
                (apply invoke
                       (string-append (assoc-ref inputs "icedtea:jdk")
                                      "/bin/javac")
                       "-source" "8" "-target" "8" "-encoding" "UTF-8"
                       "-classpath" classpath "-d" "build/classes" sources)
                (for-each
                 (lambda (module)
                   (let ((resources (string-append module "/src/main/resources")))
                     (when (file-exists? resources)
                       (copy-recursively resources "build/classes"))))
                 modules)
                (for-each (lambda (file) (utime file 315532800 315532800))
                          (find-files "build/classes" ".*"))
                (let ((jar (string-append (getcwd)
                                         "/build/powermock-mockito-1.6.5.jar")))
                  (with-directory-excursion "build/classes"
                    (apply invoke "zip" "-X" "-q" jar
                           (sort (find-files "." ".*") string<?)))))))
          (replace 'install
            (lambda _
              (let ((source (string-append
                             #$output "/share/eversector-source/powermock")))
                (install-file "build/powermock-mockito-1.6.5.jar"
                              (string-append #$output "/share/java"))
                (copy-recursively "original-source" source)
                (install-file "pom.xml" source)
                (install-file "LICENSE.txt" source)
                (install-file "LICENSE.txt"
                              (string-append #$output "/share/doc/"
                                             #$name))
                (copy-recursively
                 "modules/module-impl/junit4/src/main"
                 (string-append source "/built-junit4/src/main"))
                (copy-recursively
                 "api/mockito/src/main"
                 (string-append source "/built-api-mockito/src/main"))))))))
    (home-page "https://github.com/powermock/powermock")
    (synopsis "PowerMock Mockito adapter and JUnit runner for AsciiPanel tests")
    (description
     "This test-only package builds PowerMock's reflection, core, API support,
Mockito common and Mockito 1 adapter, and JUnit 4 runner modules from the 1.6.5
release selected by AsciiPanel.  The upstream Mockito plugin resources are
included, and the unmodified source modules and license are installed alongside
the compiled jar.  Runtime dependencies are source-built Guix libraries.")
    (license license:asl2.0)))
