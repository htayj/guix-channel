;;; Pinned Jackson source closure for AloneRL; no Maven resolution at build time.

(define-module (tay packages alone-rl-java-jackson)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages alone-rl-java-build))

;; jackson-bom 2.22.2 explicitly selects annotations 2.22 (no patch
;; component), and 2.22.2 for core, databind, dataformat and module artifacts.
;; https://repo.maven.apache.org/maven2/com/fasterxml/jackson/jackson-bom/2.22.2/jackson-bom-2.22.2.pom
(define (maven-source group artifact version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://repo.maven.apache.org/maven2/" group "/"
                        artifact "/" version "/" artifact "-" version
                        "-sources.jar"))
    (file-name (string-append artifact "-" version "-sources.jar"))
    (sha256 (base32 hash))))

;; Core's published source jar is unshaded: its NumberInput and big-number
;; parsers import FastDoubleParser directly.  The original 2.22.2 core POM
;; pins 2.0.1, although the shaded artifact's dependency-reduced POM omits it.
;; Build the original parser as a separate jar rather than downloading the
;; binary shaded core jar or replacing its fast parsing paths.
(define alone-rl-fastdoubleparser
  (alone-rl-java-package
   #:name "alone-rl-fastdoubleparser"
   #:version "2.0.1"
   #:source (maven-source "ch/randelshofer" "fastdoubleparser" "2.0.1"
                         "0f1c9gcpn1jhd96brfvh0ng11fqvgwi4c2a6mhfkw4pm3ia1b23f")
   ;; FastDoubleSwar.java is supplied separately in this Java-9 source root;
   ;; the other classes are under ch/.  Do not compile module-info.java.
   #:source-roots '("ch" "ch.randelshofer.fastdoubleparser/ch")
   #:resources '("META-INF/LICENSE" "META-INF/NOTICE"
                 "META-INF/thirdparty-LICENSE")
   #:legal-files '("META-INF/LICENSE" "META-INF/NOTICE"
                   "META-INF/thirdparty-LICENSE")
   ;; NOTICE references this exact upstream Boost text, absent from the jar's
   ;; thirdparty-LICENSE.  Retain it as well as the MIT/BSD texts in the jar.
   #:legal-origins
   (list (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/lemire/fast_double_parser/07d9189a8fb815fe800cb15ca022e7a07093236e/LICENSE.BSL")
           (file-name "fastdoubleparser-2.0.1-LICENSE.BSL")
           (sha256
            (base32 "1g32vhwfxvdz46yjrqaplkw415anh7m1vmx12bq8a6z5pscyshy3"))))
   #:license (list license:expat license:bsd-2 license:boost1.0)
   #:home-page "https://github.com/wrandelshofer/FastDoubleParser"
   #:synopsis "Pinned fast number parser for AloneRL's Jackson core"))

(define-public alone-rl-jackson-annotations
  (alone-rl-java-package
   #:name "alone-rl-jackson-annotations"
   #:version "2.22"
   #:source (maven-source "com/fasterxml/jackson/core" "jackson-annotations" "2.22"
                         "1xy9629g2g0qkgzsxxh57zyl6iq7gl4fndwriy08big3drsmqdzm")
   #:source-roots '("com")
   #:resources '("META-INF/LICENSE" "META-INF/NOTICE")
   #:legal-files '("META-INF/LICENSE" "META-INF/NOTICE")
   #:license license:asl2.0
   #:home-page "https://github.com/FasterXML/jackson-annotations"
   #:synopsis "Pinned Jackson annotations for AloneRL"))

;; All four source jars below already contain upstream-generated
;; PackageVersion.java with version 2.22.2 and the correct Maven coordinates.
;; Compile those Java sources directly; their .java.in templates are not
;; inputs or resources.  No Maven replacer, Moditect or annotation processor
;; is needed.  Explicit META-INF resources retain ServiceLoader providers and
;; legal notices, not a stale source-jar manifest or dependency-reduced POM.
(define-public alone-rl-jackson-core
  (alone-rl-java-package
   #:name "alone-rl-jackson-core"
   #:version "2.22.2"
   #:source (maven-source "com/fasterxml/jackson/core" "jackson-core" "2.22.2"
                         "1r2dvrmmqcl4l136njv410b45y3y86jha2q9kvczjab183rjsksl")
   #:source-roots '("com")
   #:inputs (list alone-rl-fastdoubleparser)
   #:resources '("META-INF/LICENSE" "META-INF/jackson-core-LICENSE"
                 "META-INF/jackson-core-NOTICE" "META-INF/Schubfach-LICENSE"
                 "META-INF/FastDoubleParser-LICENSE"
                 "META-INF/FastDoubleParser-ThirdParty-LICENSE"
                 ("META-INF/jackson-core-NOTICE" "META-INF/NOTICE")
                 "META-INF/services/com.fasterxml.jackson.core.JsonFactory")
   #:legal-files '("META-INF/LICENSE" "META-INF/jackson-core-LICENSE"
                   "META-INF/jackson-core-NOTICE" "META-INF/Schubfach-LICENSE"
                   "META-INF/FastDoubleParser-LICENSE"
                   "META-INF/FastDoubleParser-ThirdParty-LICENSE")
   #:license (list license:asl2.0 license:expat)
   #:home-page "https://github.com/FasterXML/jackson-core"
   #:synopsis "Pinned Jackson streaming JSON API for AloneRL"))

(define-public alone-rl-jackson-databind
  (alone-rl-java-package
   #:name "alone-rl-jackson-databind"
   #:version "2.22.2"
   #:source (maven-source "com/fasterxml/jackson/core" "jackson-databind" "2.22.2"
                         "0k17wyamz7xxck230074cchbf4rgqnlq83r6mlhy3pdy53ypfkn1")
   #:source-roots '("com")
   #:inputs (list alone-rl-jackson-annotations alone-rl-jackson-core)
   #:resources '("META-INF/LICENSE" "META-INF/NOTICE"
                 "META-INF/services/com.fasterxml.jackson.core.ObjectCodec")
   #:legal-files '("META-INF/LICENSE" "META-INF/NOTICE")
   #:license license:asl2.0
   #:home-page "https://github.com/FasterXML/jackson-databind"
   #:synopsis "Pinned Jackson object mapping for AloneRL"))

(define-public alone-rl-snakeyaml
  (alone-rl-java-package
   #:name "alone-rl-snakeyaml"
   #:version "2.5"
   #:source (maven-source "org/yaml" "snakeyaml" "2.5"
                         "1b0935wcc4iv3nzfpyb62lrnjfhiba75l130k8hn65pym5y30zbs")
   #:source-roots '("org")
   ;; Maven's source jar omits LICENSE.txt and NOTICE.  The release tag
   ;; resolves to this immutable commit; its root contains LICENSE.txt and
   ;; no NOTICE.  The embedded Google escapers retain their copyright
   ;; headers, installed verbatim as additional attribution documents.
   #:legal-origins
   (list (origin
           (method url-fetch)
           (uri "https://api.bitbucket.org/2.0/repositories/snakeyaml/snakeyaml/src/225cf7b0166c7d8b25ed0000d03f2a02105347ee/LICENSE.txt")
           (file-name "snakeyaml-2.5-LICENSE.txt")
           (sha256
            (base32 "1y9zpxvyqsx28w1dywpldg4rybma1qy8f78b8mxgy31fr5dsijx6"))))
   #:legal-files
   '("org/yaml/snakeyaml/external/com/google/gdata/util/common/base/Escaper.java"
     "org/yaml/snakeyaml/external/com/google/gdata/util/common/base/PercentEscaper.java"
     "org/yaml/snakeyaml/external/com/google/gdata/util/common/base/UnicodeEscaper.java")
   #:license license:asl2.0
   #:home-page "https://bitbucket.org/snakeyaml/snakeyaml"
   #:synopsis "Pinned SnakeYAML parser for AloneRL"))

(define-public alone-rl-jackson-dataformat-yaml
  (alone-rl-java-package
   #:name "alone-rl-jackson-dataformat-yaml"
   #:version "2.22.2"
   #:source (maven-source "com/fasterxml/jackson/dataformat" "jackson-dataformat-yaml" "2.22.2"
                         "0xpqh2aciidpw1bn5995f06v9i1zc4h65pm6yxq5mpshv71ib2y0")
   #:source-roots '("com")
   #:inputs (list alone-rl-jackson-annotations alone-rl-jackson-core
                  alone-rl-jackson-databind alone-rl-snakeyaml)
   #:resources '("META-INF/LICENSE" "META-INF/NOTICE"
                 "META-INF/services/com.fasterxml.jackson.core.JsonFactory"
                 "META-INF/services/com.fasterxml.jackson.core.ObjectCodec")
   #:legal-files '("META-INF/LICENSE" "META-INF/NOTICE")
   #:license license:asl2.0
   #:home-page "https://github.com/FasterXML/jackson-dataformats-text"
   #:synopsis "Pinned Jackson YAML object mapping for AloneRL"))

(define-public alone-rl-jackson-module-parameter-names
  (alone-rl-java-package
   #:name "alone-rl-jackson-module-parameter-names"
   #:version "2.22.2"
   #:source (maven-source "com/fasterxml/jackson/module" "jackson-module-parameter-names" "2.22.2"
                         "1vf20p77rigngrd54rvxa4hv0ar9hi3xzl60aqpdm8wskpljz9f1")
   #:source-roots '("com")
   #:inputs (list alone-rl-jackson-annotations alone-rl-jackson-core
                  alone-rl-jackson-databind)
   #:resources '("META-INF/LICENSE" "META-INF/NOTICE"
                 "META-INF/services/com.fasterxml.jackson.databind.Module")
   #:legal-files '("META-INF/LICENSE" "META-INF/NOTICE")
   #:license license:asl2.0
   #:home-page "https://github.com/FasterXML/jackson-modules-java8"
   #:synopsis "Pinned Jackson constructor parameter-name support for AloneRL"))

;; Keep FastDoubleParser explicit: a consumer's classpath must contain the
;; unshaded core dependency, not only Guix's transitive store references.
(define-public alone-rl-java-jackson-runtime
  (list alone-rl-fastdoubleparser
        alone-rl-jackson-annotations
        alone-rl-jackson-core
        alone-rl-jackson-databind
        alone-rl-snakeyaml
        alone-rl-jackson-dataformat-yaml
        alone-rl-jackson-module-parameter-names))
