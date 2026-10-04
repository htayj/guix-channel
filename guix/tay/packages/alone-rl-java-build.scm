;;; Source-only, offline Java dependencies for AloneRL.
(define-module (tay packages alone-rl-java-build)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java)
  #:export (alone-rl-java-package))

;; Maven source archives are source inputs, never executable binary artifacts.
;; No Maven/Gradle invocation is made: the class path is exclusively store jars.
;;
;; MODULE-INFO selects named-module compilation, matching upstream JPMS jars:
;; #t compiles the source archive's own root module-info.java; a file-like
;; object supplies the pinned upstream descriptor when the source archive omits
;; it.  Dependencies are then resolved from --module-path, and the jar carries
;; module-info.class.  COMPILE-ONLY-MODULES names optional modules referenced
;; only by upstream `requires static' clauses (absent at run time by JPMS
;; definition).  Each gets an empty build-time descriptor, never installed, so
;; the upstream module-info.java compiles unmodified.
(define* (alone-rl-java-package #:key name version source
                              (source-roots '(".")) (inputs '())
                              license home-page synopsis
                              (exclude '()) (resources '()) (legal-files '())
                              (legal-origins '()) (extra-sources '())
                              (native-inputs '()) (release "21")
                              (module-info #f) (compile-only-modules '())
                              (module-version version)
                              (prepare #~#t) (finish #~#t))
  (define module-descriptor
    (cond ((not module-info) #f)
          ((eq? module-info #t) "module-info.java")
          (else module-info)))
  (package
    (name name)
    (version version)
    (source source)
    (build-system gnu-build-system)
    (native-inputs (append (list unzip) native-inputs))
    (inputs inputs)
    (arguments
     (list
      #:tests? #f
      #:modules '((guix build gnu-build-system) (guix build utils)
                  (ice-9 ftw) (ice-9 regex) (srfi srfi-1) (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (if (string-suffix? ".jar" source)
                  (begin (mkdir "source") (chdir "source")
                         (invoke "unzip" "-q" source))
                  (begin (invoke "tar" "xf" source)
                         (chdir (car (filter
                                      (lambda (entry)
                                        (and (not (member entry '("." "..")))
                                             (file-is-directory? entry)))
                                      (scandir "."))))))))
          (delete 'configure)
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (define (excluded? file)
                (or (string-match "^(\\./)?(build|extra-source|legal-source)/" file)
                    (any (lambda (pattern) (string-match pattern file))
                         '#$exclude)))
              (define (unpack-extra pair)
                (let ((root (getcwd)))
                  (mkdir-p (string-append "extra-source/" (car pair)))
                  (chdir (string-append "extra-source/" (car pair)))
                  (if (string-suffix? ".jar" (cdr pair))
                      (invoke "unzip" "-q" (cdr pair))
                      (invoke "tar" "xf" (cdr pair) "--strip-components=1"))
                  (chdir root)))
              (for-each unpack-extra
                        (list #$@(map (lambda (pair)
                                       #~(cons #$(car pair) #$(cdr pair)))
                                     extra-sources)))
              #$prepare
              (mkdir-p "build/classes")
              (let* ((descriptor #$module-descriptor)
                     (javac (string-append #$openjdk25:jdk "/bin/javac"))
                     (sources
                      (filter (lambda (file)
                                (and (not (excluded? file))
                                     (not (string=? (basename file) "module-info.java"))))
                              (delete-duplicates
                               (append-map (lambda (root)
                                             (find-files root "\\.java$"))
                                           '#$source-roots))))
                     (jars
                      (delete-duplicates
                       (append-map
                        (lambda (input)
                          (let ((dir (string-append (cdr input) "/share/java")))
                            (if (file-exists? dir) (find-files dir "\\.jar$") '())))
                        inputs)))
                     (compile-only
                      (map (lambda (module)
                             (let ((src (string-append "build/compile-only-src/"
                                                       module))
                                   (out (string-append "build/compile-only/"
                                                       module)))
                               (mkdir-p src)
                               (call-with-output-file
                                   (string-append src "/module-info.java")
                                 (lambda (port)
                                   (format port "module ~a {}~%" module)))
                               (invoke javac "--release" #$release "-d" out
                                       (string-append src "/module-info.java"))
                               out))
                           '#$compile-only-modules))
                     (module-path (append jars compile-only)))
                (unless (pair? sources) (error "empty Java source selection"))
                (when descriptor
                  (unless (string=? descriptor "module-info.java")
                    (copy-file descriptor "module-info.java"))
                  (unless (file-exists? "module-info.java")
                    (error "missing upstream module descriptor" #$name)))
                (call-with-output-file "build/sources.list"
                  (lambda (port)
                    (for-each (lambda (file) (format port "~s~%" file))
                              (if descriptor
                                  (cons "module-info.java" sources)
                                  sources))))
                (apply invoke javac
                       "--release" #$release "-encoding" "UTF-8" "-proc:none"
                       (append
                        (cond ((not descriptor)
                               (list "-classpath" (string-join jars ":")))
                              ((pair? module-path)
                               (append
                                (if #$module-version
                                    (list "--module-version" #$module-version)
                                    '())
                                (list "--module-path"
                                      (string-join module-path ":"))))
                              (else
                               (if #$module-version
                                   (list "--module-version" #$module-version)
                                   '())))
                        (list "-d" "build/classes" "@build/sources.list"))))
              (for-each
               (lambda (root)
                 (for-each
                  (lambda (file)
                    (unless (or (excluded? file)
                                (string-match
                                 "(\\.java|\\.class|\\.jar|\\.java\\.in|\\.so([.][0-9]+)*|\\.dll|\\.dylib|\\.jnilib)$"
                                 file)
                                (string-suffix? "META-INF/MANIFEST.MF" file))
                      (let ((target (string-append "build/classes/" file)))
                        (mkdir-p (dirname target))
                        (copy-file file target))))
                  (find-files root)))
               '#$source-roots)
              (for-each
               (lambda (entry)
                 (let* ((source (if (string? entry) entry (car entry)))
                        (relative (if (string? entry) entry (cadr entry)))
                        (target (string-append "build/classes/" relative)))
                   (if (file-is-directory? source)
                       (copy-recursively source target)
                       (begin (mkdir-p (dirname target))
                              (copy-file source target)))))
               '#$resources)
              #$finish
              (call-with-output-file "build/MANIFEST.MF"
                (lambda (port)
                  (format port "Manifest-Version: 1.0~%Implementation-Version: ~a~%~%"
                          #$version)))
              (invoke (string-append #$openjdk25:jdk "/bin/jar")
                      "--create" "--file" (string-append "build/" #$name ".jar")
                      "--date=1980-01-01T00:00:02Z"
                      "--manifest" "build/MANIFEST.MF" "-C" "build/classes" ".")))
          (replace 'install
            (lambda _
              (let ((doc (string-append #$output "/share/doc/" #$name)))
                (define (legal? file)
                  (string-match
                   "(^|/)(LICENSE|LICENCE|NOTICE|COPYING|COPYRIGHT|AUTHORS)([._-].*)?$"
                   file))
                (define (copy-legal source relative)
                  (let ((target (string-append doc "/" relative)))
                    (mkdir-p (dirname target))
                    (copy-file source target)))
                (mkdir-p doc)
                (install-file (string-append "build/" #$name ".jar")
                              (string-append #$output "/share/java"))
                (for-each (lambda (file) (copy-legal file file))
                          (delete-duplicates
                           (map (lambda (file)
                                  (if (string-prefix? "./" file)
                                      (string-drop file 2)
                                      file))
                                (append '#$legal-files
                                        (filter legal? (find-files "."))))))
                (for-each
                 (lambda (origin)
                   (let ((root (getcwd))
                         (base (strip-store-file-name origin)))
                     (mkdir-p (string-append "legal-source/" base))
                     (chdir (string-append "legal-source/" base))
                     (cond
                      ((string-suffix? ".jar" origin) (invoke "unzip" "-q" origin))
                      ((or (string-suffix? ".gz" origin)
                           (string-suffix? ".xz" origin)
                           (string-suffix? ".bz2" origin))
                       (invoke "tar" "xf" origin "--strip-components=1"))
                      (else (copy-file origin "LICENSE.external")))
                     (let ((files (filter legal? (find-files "."))))
                       (when (null? files)
                         (error "legal origin contains no legal texts" origin))
                       (for-each
                        (lambda (file)
                          (copy-legal file (string-append base "/" file))) files))
                     (chdir root)))
                 (list #$@legal-origins))
                (when (null? (find-files doc))
                  (error "package has no full legal texts" #$name))))))))
    (home-page home-page)
    (synopsis synopsis)
    (description
     "This package provides a pinned, independently source-built Java library
for AloneRL.  Compilation uses an explicit store-only class path and does not
resolve dependencies over the network.  Upstream legal texts are installed with
the library.")
    (license license)))
