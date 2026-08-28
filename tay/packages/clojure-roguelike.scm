;;; GNU Guix package for Clojure-Roguelike.

(define-module (tay packages clojure-roguelike)
  #:use-module (guix build-system ant)
  #:use-module (guix build-system clojure)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages java))

;; Clojure-Roguelike declares an exact Clojure 1.8.0 dependency.  Keep this
;; runtime private so that it cannot be confused with the channel's current
;; Clojure package, and build it only from the canonical Clojure source tree.
(define clojure-1.8
  (package
    (name "clojure-1.8")
    (version "1.8.0-0.4ff4623")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/clojure/clojure/tar.gz/4ff462372c29ff2bc22b4d39962ad526f7e2c73d")
       (file-name "clojure-4ff4623.tar.gz")
       (sha256
        (base32 "17vlf227fiimdkzlmff65xry35fd1mqlzl9hn5ims26bvb6qyby9"))))
    (build-system ant-build-system)
    (arguments
     (list
      ;; The fixed POM's extra artifacts are provided or test-only.  Its Ant
      ;; jar target needs no Maven resolution when this property is empty.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'build 'empty-maven-compile-classpath
            (lambda _
              (call-with-output-file "maven-classpath.properties"
                (lambda (port)
                  (display "maven.compile.classpath=\n" port)))))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((share (string-append (assoc-ref outputs "out")
                                          "/share/java")))
                (mkdir-p share)
                (install-file "clojure-1.8.0.jar" share)
                #t)))
          ;; readme.txt contains the embedded ASM BSD-3-Clause and Guava
          ;; Murmur3 Apache-2.0 notices; retain them with Clojure's EPL text.
          (add-after 'install 'install-runtime-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((doc (string-append (assoc-ref outputs "out")
                                        "/share/doc/clojure-1.8")))
                (mkdir-p doc)
                (install-file "readme.txt" doc)
                (install-file "epl-v10.html" doc)))))))
    (home-page "https://clojure.org/")
    (synopsis "Clojure 1.8 runtime for Clojure-Roguelike")
    (description
     "This private package builds the exact Clojure runtime required by
Clojure-Roguelike entirely from source, without Maven or network resolution.")
    (license (list license:epl1.0 license:bsd-3 license:asl2.0))))

(define-public clojure-roguelike
  (package
    (name "clojure-roguelike")
    (version "0.1.0-0.16102d6")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/charlesrosenbauer/Clojure-Roguelike/tar.gz/16102d6123a19dbac03f457a13e8b9f1e181f577")
       (file-name "Clojure-Roguelike-16102d6.tar.gz")
       (sha256
        (base32 "0qr8frwyig2qjmm0b3mzrzy9j8c782wkkxjc48pdfi3lyryj8l3l"))))
    (build-system clojure-build-system)
    (arguments
     (list
      #:clojure clojure-1.8
      #:jdk icedtea
      #:source-dirs #~'("src")
      #:test-dirs #~'("test")
      ;; The sole upstream test is named "FIXME, I fail" and asserts (= 0 1).
      ;; Do not claim that known-invalid test as a passing package test.
      #:tests? #f
      #:main-class #~'roguelike.core
      #:aot-include #~'(roguelike.core)
      #:phases
      #~(modify-phases %standard-phases
          (delete 'install-doc)
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (jar-dir (string-append out "/share/java"))
                     (doc-dir (string-append out
                                             "/share/doc/clojure-roguelike"))
                     (clojure-dir (string-append (assoc-ref inputs "clojure")
                                                 "/share/java"))
                     (clojure-jars (find-files clojure-dir "\\.jar$")))
                (unless (= (length clojure-jars) 1)
                  (error "expected one Clojure runtime jar" clojure-jars))
                (mkdir-p jar-dir)
                (mkdir-p doc-dir)
                ;; Merge source and AOT output with exactly the pinned Clojure
                ;; runtime.  Discard both input manifests before writing the
                ;; application's single deterministic executable uberjar.
                (mkdir-p "runtime")
                (with-directory-excursion "runtime"
                  (invoke "jar" "xf" (car clojure-jars))
                  (invoke "jar" "xf" "../clojure-roguelike.jar")
                  (delete-file-recursively "META-INF"))
                (invoke "jar" "cfe"
                        (string-append jar-dir "/clojure-roguelike.jar")
                        "roguelike.core"
                        "-C" "runtime" ".")
                (for-each
                 (lambda (file) (install-file file doc-dir))
                 '("LICENSE" "README.md" "CHANGELOG.md"))
                (copy-recursively
                 (string-append (assoc-ref inputs "clojure")
                                "/share/doc/clojure-1.8")
                 (string-append doc-dir "/clojure-runtime-notices"))
                (let ((bin (string-append out "/bin")))
                  (mkdir-p bin)
                  (call-with-output-file (string-append bin
                                                        "/clojure-roguelike")
                    (lambda (port)
                      (format port "#!~a/bin/sh~%exec ~a/bin/java -jar ~a/share/java/clojure-roguelike.jar \"$@\"~%"
                              (assoc-ref inputs "bash")
                              (assoc-ref inputs "icedtea")
                              out)))
                  (chmod (string-append bin "/clojure-roguelike") #o555))
                #t))))))
    (inputs
     (list `("bash" ,bash-minimal)
           `("icedtea" ,icedtea "jdk")))
    (home-page "https://github.com/charlesrosenbauer/Clojure-Roguelike")
    (synopsis "Minimal terminal roguelike written in Clojure")
    (description
     "Clojure-Roguelike renders a small room in a terminal.  This package
contains one executable jar built from the pinned application and Clojure 1.8
sources, without Leiningen, Maven, or runtime downloads.")
    (license license:epl1.0)))
