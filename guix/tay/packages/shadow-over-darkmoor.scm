;;; GNU Guix package for The Shadow Over Darkmoor.

(define-module (tay packages shadow-over-darkmoor)
  #:use-module (guix build-system ant)
  #:use-module (guix build-system clojure)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages java))

;; These three codeload archives are the complete source graph used at run
;; time.  Keeping the historical Clojure runtime separate avoids silently
;; substituting the host Guix's newer Clojure package.
(define clojure-spec-alpha-0.2.176-source
  (origin
    (method url-fetch)
    (uri "https://codeload.github.com/clojure/spec.alpha/tar.gz/e55884e47619d713f068ea9e814b8a28f60e4c5d")
    (file-name "clojure-spec.alpha-e55884e.tar.gz")
    (sha256
     (base32 "187srv39qaz0hscbg6k5279b3pwx2ywdpp36ch5dwqrilsb66bql"))))

(define clojure-core-specs-alpha-0.2.44-source
  (origin
    (method url-fetch)
    (uri "https://codeload.github.com/clojure/core.specs.alpha/tar.gz/fe35eda79773a31955e9b555ef943f4105a036bc")
    (file-name "clojure-core.specs.alpha-fe35eda.tar.gz")
    (sha256
     (base32 "162f3la9ywkrnzmm008dixc82kkzvm8hia8dhpcwl94h997yc160"))))

(define clojure-1.10
  (package
    (name "clojure-1.10")
    (version "1.10.0-0.e72ffdc")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/clojure/clojure/tar.gz/e72ffdcd039189e3fe230d160e093ae6ba8f24cf")
       (file-name "clojure-e72ffdc.tar.gz")
       (sha256
        (base32 "1d1q1hswdv3blfjl4iy69ksiy7kp9q7fq4hd4ff5807fqfk3mkx7"))))
    (build-system ant-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          ;; Clojure 1.10 distributes its two runtime spec libraries as Maven
          ;; dependencies.  Unpack their reviewed source trees instead, so
          ;; Ant cannot consult Maven or any network service.
          (add-after 'unpack 'unpack-runtime-spec-sources
            (lambda* (#:key inputs #:allow-other-keys)
              (for-each
               (lambda (input)
                 (let ((source-dir (string-append "runtime-sources/" input)))
                   (mkdir-p source-dir)
                   (invoke "tar" "-xf" (assoc-ref inputs input)
                           "-C" source-dir "--strip-components=1")
                   (copy-recursively
                    (string-append source-dir "/src/main/clojure")
                    "src/clj/")))
               '("clojure-spec-alpha-source"
                 "clojure-core-specs-alpha-source"))))
          (add-after 'unpack-runtime-spec-sources 'fix-manifest-classpath
            (lambda _
              (substitute* "build.xml"
                (("<attribute name=\"Class-Path\" value=\".\"/>") ""))))
          ;; Ant otherwise leaves this Maven property unexpanded even though
          ;; the source build has no Maven compile dependencies.
          (add-before 'build 'empty-maven-compile-classpath
            (lambda _
              (call-with-output-file "maven-classpath.properties"
                (lambda (port)
                  (display "maven.compile.classpath=\n" port)))))
          ;; The upstream jar target creates both a versioned jar and the
          ;; clojure.jar convenience copy.  Install only one so consumers
          ;; cannot accidentally assemble an ambiguous runtime classpath.
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((share (string-append (assoc-ref outputs "out")
                                          "/share/java")))
                (mkdir-p share)
                (install-file "clojure-1.10.0.jar" share)
                #t)))
          ;; The Clojure readme documents the bundled ASM and Guava notices;
          ;; install it alongside the exact EPL text for the final package.
          (add-after 'install 'install-runtime-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((doc (string-append (assoc-ref outputs "out")
                                        "/share/doc/clojure-1.10")))
                (mkdir-p doc)
                (install-file "readme.txt" doc)
                (install-file "epl-v10.html" doc)))))))
    (native-inputs
     (list `("tar" ,tar)
           `("clojure-spec-alpha-source"
             ,clojure-spec-alpha-0.2.176-source)
           `("clojure-core-specs-alpha-source"
             ,clojure-core-specs-alpha-0.2.44-source)))
    (home-page "https://clojure.org/")
    (synopsis "Clojure 1.10 runtime for Shadow Over Darkmoor")
    (description
     "This private package builds the exact Clojure runtime required by Shadow
Over Darkmoor entirely from source, including its pinned runtime spec libraries.")
    ;; Clojure itself is EPL-1.0; readme.txt also carries the notices for its
    ;; bundled ASM code and Guava Murmur3 implementation.
    (license (list license:epl1.0 license:bsd-3 license:asl2.0))))

(define-public shadow-over-darkmoor
  (package
    (name "shadow-over-darkmoor")
    (version "0.2.0-0.fe7d296")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/catspook/Shadow_Over_Darkmoor/tar.gz/fe7d29690ecbefa01bd641d2179d27c6d16a105e")
       (file-name "Shadow_Over_Darkmoor-fe7d296.tar.gz")
       (sha256
        (base32 "0hd05jbc6asbmbz02lhdgp7dxzjmfv9kr8h6a84j2wgn0mkffr1c"))))
    (build-system clojure-build-system)
    (arguments
     (list
      #:clojure clojure-1.10
      #:jdk icedtea
      #:source-dirs #~'("src")
      #:test-dirs #~'("test")
      #:tests? #t
      #:main-class #~'darkmoor.core
      ;; Upstream has one entry namespace; the other source files are scripts
      ;; which switch into it with `in-ns` and are loaded by darkmoor.core.
      ;; Compiling those scripts as independent namespaces leaves clojure.core
      ;; un-referred, so AOT only the true entry point.
      #:aot-include
      #~'(darkmoor.core)
      #:phases
      #~(modify-phases %standard-phases
          ;; Documentation is installed explicitly below; this upstream
          ;; project has no conventional Clojure documentation directories.
          (delete 'install-doc)
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (jar-dir (string-append out "/share/java"))
                     (data-dir (string-append out
                                              "/share/shadow-over-darkmoor"))
                     (doc-dir (string-append out
                                             "/share/doc/shadow-over-darkmoor"))
                     (clojure-dir (string-append (assoc-ref inputs "clojure")
                                                 "/share/java"))
                     (clojure-jars (find-files clojure-dir "\\.jar$")))
                (unless (= (length clojure-jars) 1)
                  (error "expected one Clojure runtime jar" clojure-jars))
                (mkdir-p jar-dir)
                (mkdir-p data-dir)
                (mkdir-p doc-dir)
                (copy-recursively "resources" (string-append data-dir
                                                               "/resources"))
                (copy-recursively "resources" "jar-resources/resources")
                (mkdir-p "runtime")
                (with-directory-excursion "runtime"
                  (invoke "jar" "xf" (car clojure-jars))
                  (delete-file-recursively "META-INF"))
                ;; Merge every archive member into one tree before invoking
                ;; jar.  Passing runtime, compiled classes, and sources as
                ;; separate trees creates duplicate directory entries.
                (copy-recursively "classes/darkmoor" "runtime/darkmoor")
                (copy-recursively "src/darkmoor" "runtime/darkmoor")
                (copy-recursively "resources" "runtime/resources")
                ;; This is deliberately an uberjar rather than a classpath
                ;; wrapper: every runtime class, source file, and resource is
                ;; fixed in the output and no Leiningen/Maven resolution runs.
                (invoke "jar" "cfe"
                        (string-append jar-dir "/shadow-over-darkmoor.jar")
                        "darkmoor.core"
                        "-C" "runtime" ".")
                (for-each
                 (lambda (file) (install-file file doc-dir))
                 '("LICENSE" "README.md" "CHANGELOG.md"))
                (let ((clojure-doc (string-append (assoc-ref inputs "clojure")
                                                  "/share/doc/clojure-1.10")))
                  (copy-recursively clojure-doc
                                    (string-append doc-dir
                                                   "/clojure-runtime-notices")))
                (let ((bin (string-append out "/bin")))
                  (mkdir-p bin)
                  (call-with-output-file
                      (string-append bin "/shadow-over-darkmoor")
                    (lambda (port)
                      (format port "#!~a/bin/sh~%set -eu~%~
state=\"${XDG_STATE_HOME:-$HOME/.local/state}/shadow-over-darkmoor\"~%
if test ! -d \"$state/resources\"; then~%
  ~a/bin/mkdir -p \"$state\"~%
  ~a/bin/cp -R \"~a/resources\" \"$state/resources\"~%
fi~%
cd \"$state\"~%
exec ~a/bin/java -jar ~a/share/java/shadow-over-darkmoor.jar \"$@\"~%"
                              #$bash-minimal
                              #$coreutils-minimal
                              #$coreutils-minimal
                              (string-append out "/share/shadow-over-darkmoor")
                              (assoc-ref inputs "icedtea")
                              out)))
                  (chmod (string-append bin "/shadow-over-darkmoor") #o555))
                #t))))))
    (inputs
     (list `("bash" ,bash-minimal)
           `("coreutils" ,coreutils-minimal)
           `("icedtea" ,icedtea "jdk")))
    (home-page "https://github.com/catspook/Shadow_Over_Darkmoor")
    (synopsis "Text-based roguelike adventure game")
    (description
     "The Shadow Over Darkmoor is a text-based roguelike adventure game.  Its
wrapper copies the packaged text resources into XDG state before starting, so
the game's filesystem-relative reads never touch the immutable store or the
caller's current directory.")
    ;; project.clj declares EPL-2.0 OR GPL-2.0-or-later WITH the GNU
    ;; Classpath Exception.  The exception is an additional permission not
    ;; represented separately in Guix's license database.
    (license (list license:epl2.0 license:gpl2+))))
