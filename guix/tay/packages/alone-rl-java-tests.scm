;;; Independently pinned, source-built JUnit closure for AloneRL.

(define-module (tay packages alone-rl-java-tests)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages alone-rl-java-build))

(define (maven-source group artifact version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://repo.maven.apache.org/maven2/" group "/"
                        artifact "/" version "/" artifact "-" version
                        "-sources.jar"))
    (file-name (string-append artifact "-" version "-sources.jar"))
    (sha256 (base32 hash))))

(define-public alone-rl-opentest4j
  (alone-rl-java-package
   #:name "alone-rl-opentest4j"
   #:version "1.3.0"
   #:source (maven-source "org/opentest4j" "opentest4j" "1.3.0"
                         "1cpbq7ak977mb3x8yi321kjp32k32nd3h4clmkmxarw2lvij8jkj")
   #:source-roots '("org")
   ;; The Maven source jar omits the descriptor that upstream compiles into
   ;; its JPMS jar; use the exact r1.3.0 src/module descriptor.
   #:module-info
   (origin
     (method url-fetch)
     (uri (string-append "https://raw.githubusercontent.com/ota4j-team/opentest4j/"
                         "r1.3.0/src/module/java/org.opentest4j/module-info.java"))
     (file-name "opentest4j-1.3.0-module-info.java")
     (sha256
      (base32 "13nms7amz8mrwrqdp07z13agzajn5nkqlmv3i549rjhdpc8vqrns")))
   ;; The published source jar contains copyright headers but no full license.
   #:legal-origins
   (list (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/ota4j-team/opentest4j/r1.3.0/LICENSE")
           (file-name "opentest4j-1.3.0-LICENSE")
           (sha256
            (base32 "025sjaymdv4kb09wb57gyv69xdkkj7xldj1nwy5w30c5psvnwnf6"))))
   #:license license:asl2.0
   #:home-page "https://github.com/ota4j-team/opentest4j"
   #:synopsis "Pinned Open Test Alliance exceptions for AloneRL"))

(define-public alone-rl-apiguardian-api
  (alone-rl-java-package
   #:name "alone-rl-apiguardian-api"
   #:version "1.1.2"
   #:source (maven-source "org/apiguardian" "apiguardian-api" "1.1.2"
                         "0bayd1xs45syys5hpw5zbvlj2ri7qx6k4nv5nsz1fa212m1plyi7")
   #:source-roots '("org")
   #:module-info #t
   #:resources '("META-INF/LICENSE")
   #:legal-files '("META-INF/LICENSE")
   #:license license:asl2.0
   #:home-page "https://github.com/apiguardian-team/apiguardian"
   #:synopsis "Pinned API stability annotations for AloneRL"))

(define-public alone-rl-jspecify
  (alone-rl-java-package
   #:name "alone-rl-jspecify"
   #:version "1.0.0"
   #:source (maven-source "org/jspecify" "jspecify" "1.0.0"
                         "15h2nzki0wy2yd00g5ja5hlr9wpl4qc9gflj67xkfnfmj60qkw5d")
   #:source-roots '("org")
   ;; Upstream ships this v1.0.0 src/java9 descriptor as a multi-release
   ;; module-info.class without a module version; the source jar omits it.
   #:module-info
   (origin
     (method url-fetch)
     (uri (string-append "https://raw.githubusercontent.com/jspecify/jspecify/"
                         "v1.0.0/src/java9/java/module-info.java"))
     (file-name "jspecify-1.0.0-module-info.java")
     (sha256
      (base32 "0b8szsp5mhsr7dnc9my7w559flz6sngkmcx8km591966338v0nb0")))
   #:module-version #f
   #:legal-origins
   (list (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/jspecify/jspecify/v1.0.0/LICENSE")
           (file-name "jspecify-1.0.0-LICENSE")
           (sha256
            (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))
   #:license license:asl2.0
   #:home-page "https://jspecify.dev/"
   #:synopsis "Pinned Java nullness annotations for AloneRL"))

;; All six 6.1.3 POMs pin API Guardian 1.1.2 and JSpecify 1.0.0.
;; Jupiter API and Platform Engine additionally pin OpenTest4J 1.3.0;
;; inter-JUnit dependencies are 6.1.3 throughout.  The module paths
;; below include their transitive Java API dependencies, not Maven binaries.
;; Sources contain no generated Version class or multi-release source roots;
;; Package.getImplementationVersion uses the constructor's package manifest.
;; Java-only consumers do not need the .kt Jupiter extension source files.
;; Each JUnit jar is the upstream named module compiled from its own unmodified
;; module-info.java (JLS 8.1.6: sealed hierarchies across packages require a
;; named module).  Kotlin modules appear only in `requires static' clauses.
(define %junit-kotlin-modules
  '("kotlin.stdlib" "kotlin.reflect" "kotlinx.coroutines.core"))
(define %junit-legal-files '("META-INF/LICENSE.md" "META-INF/LICENSE-notice.md"))

(define-public alone-rl-junit-platform-commons
  (alone-rl-java-package
   #:name "alone-rl-junit-platform-commons"
   #:version "6.1.3"
   #:source (maven-source "org/junit/platform" "junit-platform-commons" "6.1.3"
                         "14vrm7bs5by7zg6c85hdianc5xy8v7kc59zm7b0yamih78d8ckxi")
   #:source-roots '("org")
   #:module-info #t
   #:compile-only-modules %junit-kotlin-modules
   #:inputs (list alone-rl-apiguardian-api alone-rl-jspecify)
   ;; Upstream compiles this bridge against Kotlin stdlib/reflect 2.3.21 and
   ;; coroutines 1.11.0 as compileOnly dependencies (not present in its POM).
   ;; There is no source-bootstrapped Kotlin compiler in the current channel.
   ;; Adapt only this bridge's invocation mechanism: reflection retains its
   ;; optional runtime behavior and unmodified KotlinReflectionUtils guards.
   #:prepare
   #~(begin
       (use-modules (guix build utils))
       (mkdir-p "source-notices")
       (copy-file "org/junit/platform/commons/util/KotlinFunctionUtils.java"
                  "source-notices/KotlinFunctionUtils.upstream.java")
       (call-with-output-file "source-notices/SOURCE-NOTICE"
         (lambda (port)
           (display
            "JUnit Platform Commons 6.1.3 source modification (2026-10-03)\n\nThe original KotlinFunctionUtils.java from the pinned Maven Central source jar is retained beside this notice.  The installed implementation changes direct compile-only Kotlin calls to reflection and a LambdaMetafactory Function2 lambda.  KotlinReflectionUtils and its optional dependency availability checks remain upstream source.  The adapter is intended to preserve Kotlin callable return-type mapping, argument mapping, accessibility, coroutine continuation handling, and exception propagation without introducing a prebuilt Kotlin bootstrap.\n\nUpstream compile-only versions are Kotlin stdlib/reflect 2.3.21 and kotlinx-coroutines-core 1.11.0.  These optional runtime libraries are not installed by this Java-only package.  Optional Kotlin interoperability has not been runtime-exercised; Java test acceptance does not verify Kotlin reflection or coroutine semantics.  The source remains under Eclipse Public License 2.0 with the upstream copyright notice.\n"
            port)))
       (copy-file
        #$(local-file
           (search-tay-package-file "auxiliary/alone-rl-kotlin-function-utils.java"))
        "org/junit/platform/commons/util/KotlinFunctionUtils.java"))
   #:resources %junit-legal-files
   #:legal-files
   (append %junit-legal-files
           '("org/junit/platform/commons/util/KotlinFunctionUtils.java"
             "source-notices/KotlinFunctionUtils.upstream.java"
             "source-notices/SOURCE-NOTICE"))
   #:license license:epl2.0
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Platform common utilities for AloneRL"))

(define-public alone-rl-junit-platform-engine
  (alone-rl-java-package
   #:name "alone-rl-junit-platform-engine"
   #:version "6.1.3"
   #:source (maven-source "org/junit/platform" "junit-platform-engine" "6.1.3"
                         "02ix6cj47kb2wb45vpzczlwmvrx37ahipcr1dysj39133id7x7hy")
   #:source-roots '("org")
   #:module-info #t
   #:inputs (list alone-rl-opentest4j alone-rl-junit-platform-commons
                  alone-rl-apiguardian-api alone-rl-jspecify)
   #:resources
   (append %junit-legal-files
           '("META-INF/services/org.junit.platform.engine.discovery.DiscoverySelectorIdentifierParser"
             "META-INF/native-image/org.junit.platform/junit-platform-engine/reachability-metadata.json"))
   #:legal-files %junit-legal-files
   #:license license:epl2.0
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Platform engine contract for AloneRL"))

(define-public alone-rl-junit-platform-launcher
  (alone-rl-java-package
   #:name "alone-rl-junit-platform-launcher"
   #:version "6.1.3"
   #:source (maven-source "org/junit/platform" "junit-platform-launcher" "6.1.3"
                         "1yh9q6wv7sj6bbri383p5s665wndpai5cac1j9bls8jcgqg7y36k")
   #:source-roots '("org")
   #:module-info #t
   #:inputs (list alone-rl-junit-platform-engine alone-rl-junit-platform-commons
                  alone-rl-opentest4j alone-rl-apiguardian-api alone-rl-jspecify)
   #:resources
   (append %junit-legal-files
           '("META-INF/services/org.junit.platform.launcher.TestExecutionListener"))
   #:legal-files %junit-legal-files
   #:license license:epl2.0
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Platform test launcher for AloneRL"))

(define-public alone-rl-junit-jupiter-api
  (alone-rl-java-package
   #:name "alone-rl-junit-jupiter-api"
   #:version "6.1.3"
   #:source (maven-source "org/junit/jupiter" "junit-jupiter-api" "6.1.3"
                         "1q0ibpgx4fyn67wbmz520akii4c9a5xciqr2ibwcd8xkdk73wixb")
   #:source-roots '("org")
   #:module-info #t
   #:compile-only-modules '("kotlin.stdlib")
   #:inputs (list alone-rl-opentest4j alone-rl-junit-platform-commons
                  alone-rl-apiguardian-api alone-rl-jspecify)
   #:exclude '("\\.kt$")
   #:resources %junit-legal-files
   #:legal-files %junit-legal-files
   #:license license:epl2.0
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Jupiter Java API for AloneRL"))

;; junit-framework r6.1.3 gradle/libs.versions.toml pins de.siegmar:fastcsv
;; 4.2.0; jupiter-params declares it `shadowed' and its shadowJar relocates
;; de.siegmar.fastcsv to org.junit.jupiter.params.shadow.de.siegmar.fastcsv,
;; bundling it inside the params module (no module requires) together with
;; FastCSV's META-INF/LICENSE renamed to META-INF/LICENSE-fastcsv.
(define fastcsv-source
  (maven-source "de/siegmar" "fastcsv" "4.2.0"
                "1h7mf3vv18b8yjxcgj48a2cpj23yglx52fj9h62652ixqw02zqfa"))

;; Byte-identical to upstream params' META-INF/LICENSE-fastcsv; FastCSV's
;; source jar omits it.
(define fastcsv-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/osiegmar/FastCSV/v4.2.0/LICENSE")
    (file-name "fastcsv-4.2.0-LICENSE")
    (sha256 (base32 "0n579fjd3dgwb8rxyiqi8pmngac7zd0mjgl0f987ajkjp15c78s4"))))

(define-public alone-rl-junit-jupiter-params
  (alone-rl-java-package
   #:name "alone-rl-junit-jupiter-params"
   #:version "6.1.3"
   #:source (maven-source "org/junit/jupiter" "junit-jupiter-params" "6.1.3"
                         "03rjfdw2gmhpaqmhf8mri4w30103ahh311asqzmhi036fvjxv473")
   #:source-roots '("org")
   #:module-info #t
   #:inputs (list alone-rl-junit-jupiter-api alone-rl-junit-platform-commons
                  alone-rl-opentest4j alone-rl-apiguardian-api alone-rl-jspecify)
   #:extra-sources (list (cons "fastcsv" fastcsv-source))
   ;; Reproduce shadowJar's relocation at source level: FastCSV 4.2.0 source
   ;; compiles inside the params module under the identical relocated
   ;; packages.  Shadow also rewrites the matching string constant
   ;; (CsvReader's "de.siegmar.fastcsv.relaxed" system property), as does
   ;; this whole-name substitution.  JUnit's three CSV providers import it.
   #:prepare
   #~(let ((shadow "org/junit/jupiter/params/shadow/de/siegmar/fastcsv"))
       (copy-recursively "extra-source/fastcsv/de/siegmar/fastcsv" shadow)
       (substitute*
           (append (find-files shadow "\\.java$")
                   (map (lambda (file)
                          (string-append "org/junit/jupiter/params/provider/"
                                         file))
                        '("CsvArgumentsProvider.java"
                          "CsvFileArgumentsProvider.java"
                          "CsvReaderFactory.java")))
         (("de\\.siegmar\\.fastcsv")
          "org.junit.jupiter.params.shadow.de.siegmar.fastcsv"))
       (copy-file #$fastcsv-license "META-INF/LICENSE-fastcsv"))
   #:exclude '("\\.kt$")
   #:resources (append %junit-legal-files '("META-INF/LICENSE-fastcsv"))
   #:legal-files (append %junit-legal-files '("META-INF/LICENSE-fastcsv"))
   #:license (list license:epl2.0 license:expat)
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Jupiter parameterized tests for AloneRL"))

(define-public alone-rl-junit-jupiter-engine
  (alone-rl-java-package
   #:name "alone-rl-junit-jupiter-engine"
   #:version "6.1.3"
   #:source (maven-source "org/junit/jupiter" "junit-jupiter-engine" "6.1.3"
                         "15rrj1xmhrms7a7ffkcssmxc1nvph3rdwn5rrif77xajncq773mz")
   #:source-roots '("org")
   #:module-info #t
   #:inputs (list alone-rl-junit-platform-engine alone-rl-junit-jupiter-api
                  alone-rl-junit-platform-commons alone-rl-opentest4j
                  alone-rl-apiguardian-api alone-rl-jspecify)
   #:resources
   (append %junit-legal-files
           '("META-INF/services/org.junit.platform.engine.TestEngine"))
   #:legal-files %junit-legal-files
   #:license license:epl2.0
   #:home-page "https://junit.org/"
   #:synopsis "Pinned JUnit Jupiter execution engine for AloneRL"))

(define-public alone-rl-java-tests
  (list alone-rl-opentest4j alone-rl-apiguardian-api alone-rl-jspecify
        alone-rl-junit-platform-commons alone-rl-junit-platform-engine
        alone-rl-junit-platform-launcher alone-rl-junit-jupiter-api
        alone-rl-junit-jupiter-params alone-rl-junit-jupiter-engine))
