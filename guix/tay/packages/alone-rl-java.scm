;;; Independently source-built Java runtime and test closure for AloneRL.
(define-module (tay packages alone-rl-java)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages alone-rl-java-build)
  #:use-module (tay packages alone-rl-java-jackson)
  #:use-module (tay packages alone-rl-java-logging)
  #:use-module (tay packages alone-rl-java-tests)
  #:re-export (alone-rl-java-tests
               alone-rl-jackson-annotations alone-rl-jackson-core
               alone-rl-jackson-databind alone-rl-jackson-dataformat-yaml
               alone-rl-jackson-module-parameter-names alone-rl-snakeyaml
               alone-rl-logback-core alone-rl-logback-classic alone-rl-slf4j-api
               alone-rl-junit-platform-commons alone-rl-junit-platform-engine
               alone-rl-junit-platform-launcher alone-rl-junit-jupiter-api
               alone-rl-junit-jupiter-params alone-rl-junit-jupiter-engine
               alone-rl-opentest4j alone-rl-apiguardian-api alone-rl-jspecify))

(define-public alone-rl-rlforj-alt
  (alone-rl-java-package
   #:name "alone-rl-rlforj-alt" #:version "0.4.0"
   #:source
   (origin
     (method url-fetch)
     (uri "https://codeload.github.com/fabio-t/rlforj-alt/tar.gz/4bc00f6a1439f09fe6e7e27e181fd04ee5d5a6d3")
     (file-name "alone-rl-rlforj-alt-0.4.0.tar.gz")
     (sha256 (base32 "0fwqsxd2f3789idzy76i30fwq0xkvxpsd01pb9mi7zvzd2glfax6")))
   #:source-roots '("src/main/java")
   #:legal-files '("LICENSE")
   #:license license:bsd-3
   #:home-page "https://github.com/fabio-t/rlforj-alt"
   #:synopsis "Roguelike field-of-view and pathfinding library"))

(define-public alone-rl-artemis-odb
  (alone-rl-java-package
   #:name "alone-rl-artemis-odb" #:version "2.3.0"
   #:source
   (origin
     (method url-fetch)
     (uri "https://repo.maven.apache.org/maven2/net/onedaybeard/artemis/artemis-odb/2.3.0/artemis-odb-2.3.0-sources.jar")
     (file-name "alone-rl-artemis-odb-2.3.0-sources.jar")
     (sha256 (base32 "10zmjyc78vkqsxv4b421xf8razk0rgsrmcqvj4001n2kvmw42ird")))
   #:source-roots '("com" "net")
   #:legal-origins
   (list
    (origin
      (method url-fetch)
      (uri "https://codeload.github.com/junkdog/artemis-odb/tar.gz/refs/tags/artemis-odb-2.3.0")
      (file-name "alone-rl-artemis-odb-2.3.0-legal.tar.gz")
      (sha256 (base32 "1rwn9vh26j6bq7dlmk884nd5vxrxd5djlg8i204jh7f7n0hdf722"))))
   ;; The release preserves both original Artemis BSD and libGDX Apache texts.
   #:license (list license:bsd-2 license:asl2.0)
   #:home-page "https://github.com/junkdog/artemis-odb"
   #:synopsis "Entity component system for Java"))

(define-public alone-rl-artemis-contrib-core
  (alone-rl-java-package
   #:name "alone-rl-artemis-contrib-core" #:version "2.5.0"
   #:source
   (origin
     (method url-fetch)
     (uri "https://repo.maven.apache.org/maven2/net/mostlyoriginal/artemis-odb/contrib-core/2.5.0/contrib-core-2.5.0-sources.jar")
     (file-name "alone-rl-artemis-contrib-core-2.5.0-sources.jar")
     (sha256 (base32 "05v6bdap9pxpif3q8dbl67mf9f16xp1868k58kbdv7bpak437ri7")))
   #:inputs (list alone-rl-artemis-odb)
   #:source-roots '("net")
   #:legal-origins
   (list
    (origin
      (method url-fetch)
      (uri "https://codeload.github.com/DaanVanYperen/artemis-odb-contrib/tar.gz/refs/tags/artemis-odb-contrib-2.5.0")
      (file-name "alone-rl-artemis-contrib-core-2.5.0-legal.tar.gz")
      (sha256 (base32 "0dgl66yvy46s55vlyfpvybxkl4281w48s5dmqhsf1hb1l1x1ynqp"))))
   #:license (list license:expat license:asl2.0)
   #:home-page "https://github.com/DaanVanYperen/artemis-odb-contrib"
   #:synopsis "Core utilities and systems for Artemis ODB"))

;; Consumers enumerate all jars from these packages' share/java directories.
;; JDK and terrain binding are selected separately by the game package.
(define-public alone-rl-java-runtime
  (append (list alone-rl-rlforj-alt alone-rl-artemis-odb
                alone-rl-artemis-contrib-core)
          alone-rl-java-jackson-runtime alone-rl-java-logging-runtime))
