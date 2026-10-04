;;; Independently pinned, source-built logging closure for AloneRL.
;;; Versions below come from logback-parent 1.6.3, with Angus provider pins
;;; from org.eclipse.angus:all:2.0.4.  No Maven resolver or binary jar is used.
(define-module (tay packages alone-rl-java-logging)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (tay packages alone-rl-java-build)
  #:use-module (gnu packages java))

(define (logging-source group artifact version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://repo.maven.apache.org/maven2/" group "/"
                        artifact "/" version "/" artifact "-" version
                        "-sources.jar"))
    (sha256 (base32 hash))))

(define (logging-legal url name hash)
  (origin (method url-fetch) (uri url) (file-name name)
          (sha256 (base32 hash))))

(define logback-notice
  (logging-legal
   "https://raw.githubusercontent.com/qos-ch/logback/v_1.6.3/LICENSE.txt"
   "LICENSE-logback.txt"
   "1lk67xkx8ldgmm88pqrpdl9y1k8dqb80d6jlmvb03sdr5i7xzvpi"))

(define logback-epl
  (logging-legal
   "https://raw.githubusercontent.com/junit-team/junit-framework/f59f60d2cebdf2224235d81f781b1f310cbc8138/LICENSE.md"
   "LICENSE-EPL-2.0.md"
   "1w0v856xcv42by9dyrq1r0940j4aslvgxqn2s5wd3b8iq52cv92s"))

(define logback-lgpl
  (logging-legal
   "https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-14.2.0/COPYING.LIB"
   "LICENSE-LGPL-2.1.txt"
   "0qg8j2is0qxipsi87k5qk4gkny781rh61ws41fc1xpgc2rbdxgd9"))

(define xz-copying
  (logging-legal
   "https://raw.githubusercontent.com/tukaani-project/xz-java/v1.10/COPYING"
   "COPYING-xz"
   "0rl7z2pwaqvh8xjzq8mkqw6jg80ic4pvz77465jns8g5rqkfyxqy"))

(define xz-license
  (logging-legal
   "https://raw.githubusercontent.com/tukaani-project/xz-java/v1.10/LICENSES/0BSD.txt"
   "LICENSE-0BSD.txt"
   "1wabqz24r895rd394dxvj6h384168fvwz3885q7cs49rhmfn408b"))

(define servlet-license
  (logging-legal
   "https://raw.githubusercontent.com/jakartaee/servlet/5.0.0/LICENSE.md"
   "LICENSE-servlet.md"
   "0yycs9n9nqmgz2j72mjnvldgqvh5i861b6q18w3bw75qj8l007vf"))

(define servlet-notice
  (logging-legal
   "https://raw.githubusercontent.com/jakartaee/servlet/5.0.0/NOTICE.md"
   "NOTICE-servlet.md"
   "0izzmrgbf9zgr8iglf8384xmh16rhb0lc5h0j17iqcjc3957ndnw"))

(define graal-license
  (logging-legal
   "https://raw.githubusercontent.com/oracle/graal/vm-23.1.2/sdk/LICENSE.md"
   "LICENSE-graal-UPL.txt"
   "1zb3mgl85sgf8gvv9c8kfkgzsw80j7a244hw34vpj3843k8nj8vx"))

(define jansi-native-source
  (origin
    (method url-fetch)
    (uri "https://codeload.github.com/fusesource/jansi/tar.gz/refs/tags/jansi-2.4.0")
    (file-name "jansi-jansi-2.4.0.tar.gz")
    (sha256 (base32 "0lzmvj8rd8166sjfyr558l0fff41c2lasm128xphpfzff03wa65s"))))

(define jline-native-source
  (origin
    (method url-fetch)
    (uri "https://codeload.github.com/jline/jline3/tar.gz/refs/tags/4.3.1")
    (file-name "jline-4.3.1.tar.gz")
    (sha256 (base32 "1lr91pk2r360xhbzc5cfs7n5h7p9v9bhbv1ipr0m4sd242lmblz0"))))

;; The sources jars contain prebuilt native libraries but not their C source.
;; Discard ALL of those binaries and build the matching tagged C sources instead.
;; Resolve on the GNU/Linux build machine, not while importing this module:
;; --system can select a different builder than the evaluating host.  These
;; native phases use the builder's GCC; cross-compilation is not supported.
;; Match JVM OSInfo resource spellings, including ARM revisions and PPC endian.
(define linux-native-arch
  #~(let ((machine (utsname:machine (uname))))
      (cond ((member machine '("amd64" "x86_64")) "x86_64")
            ((member machine '("i386" "i486" "i586" "i686" "x86")) "x86")
            ((member machine '("aarch64" "arm64")) "arm64")
            ((string-prefix? "armv7" machine) "armv7")
            ((string-prefix? "armv6" machine) "armv6")
            ((string-prefix? "arm" machine) "arm")
            ((member machine '("ppc64le" "powerpc64le")) "ppc64le")
            ((member machine '("ppc64" "powerpc64")) "ppc64")
            ((string=? machine "riscv64") "riscv64")
            (else (error "unsupported logging JNI build architecture" machine)))))

(define-public alone-rl-slf4j-api
  (alone-rl-java-package
   #:name "alone-rl-slf4j-api"
   #:version "2.0.18"
   #:source (logging-source "org/slf4j" "slf4j-api" "2.0.18"
                            "0xch6biqlz3hm07vwggi05gfaz0bzhhlbr3l0pa43gpjyxy00bhr")
   #:release "25"
   #:license license:expat
   #:home-page "https://www.slf4j.org/"
   #:synopsis "SLF4J logging facade"))

(define alone-rl-xz
  (alone-rl-java-package
   #:name "alone-rl-xz"
   #:version "1.10"
   #:source (logging-source "org/tukaani" "xz" "1.10"
                            "0b1mdsnf1nzl4g4pjqks3crv551z61qglkim3zz26almir3sbiva")
   #:release "25"
   ;; Promote the Java 9 overrides for the single JDK 25 jar, rather than
   ;; compile duplicate base/override class names or lose optimized paths.
   #:prepare #~(begin
       (copy-recursively "META-INF/versions/9/org" "org")
       (delete-file-recursively "META-INF/versions"))
   #:legal-origins (list xz-copying xz-license)
   #:license license:bsd-0
   #:home-page "https://tukaani.org/xz/java.html"
   #:synopsis "XZ compression for Java"))

(define alone-rl-jakarta-activation-api
  (alone-rl-java-package
   #:name "alone-rl-jakarta-activation-api"
   #:version "2.1.4"
   #:source (logging-source "jakarta/activation" "jakarta.activation-api" "2.1.4"
                            "0py3krvalqrfdp93m8nlbr4bkhvs9m06jwj67f57g6q5anxa799a")
   #:release "25"
   #:license license:bsd-3
   #:home-page "https://github.com/jakartaee/jaf-api"
   #:synopsis "Jakarta Activation API"))

(define alone-rl-jakarta-mail-api
  (alone-rl-java-package
   #:name "alone-rl-jakarta-mail-api"
   #:version "2.1.5"
   #:source (logging-source "jakarta/mail" "jakarta.mail-api" "2.1.5"
                            "01s1dhrpjmkjpj8r0x6v0fhla7dp9wa3vby6z2b9rcwhm2ys7v8x")
   #:release "25"
   #:inputs (list alone-rl-jakarta-activation-api)
   #:license license:epl2.0
   #:home-page "https://github.com/jakartaee/mail-api"
   #:synopsis "Jakarta Mail API"))

(define alone-rl-jakarta-servlet-api
  (alone-rl-java-package
   #:name "alone-rl-jakarta-servlet-api"
   #:version "5.0.0"
   #:source (logging-source "jakarta/servlet" "jakarta.servlet-api" "5.0.0"
                            "1mb5jkhh04zs21nkj6lqg93jwwqdy3icl6246jxlh2mpwiw6s1rg")
   #:release "25"
   #:legal-origins (list servlet-license servlet-notice)
   #:license license:epl2.0
   #:home-page "https://github.com/jakartaee/servlet"
   #:synopsis "Jakarta Servlet API"))

;; Angus retains the optional Graal hosted feature classes.  Their actual
;; compile API is nativeimage + word, not graal-sdk's empty compatibility jar.
(define alone-rl-graal-word
  (alone-rl-java-package
   #:name "alone-rl-graal-word"
   #:version "23.1.2"
   #:source (logging-source "org/graalvm/sdk" "word" "23.1.2"
                            "108vk88ckwzab60sb70liyxqs70q543z6f8hpjca12zsb58m4iig")
   #:release "25"
   #:legal-origins (list graal-license)
   #:license license:upl
   #:home-page "https://github.com/oracle/graal"
   #:synopsis "Graal machine word API"))

(define alone-rl-graal-nativeimage
  (alone-rl-java-package
   #:name "alone-rl-graal-nativeimage"
   #:version "23.1.2"
   #:source (logging-source "org/graalvm/sdk" "nativeimage" "23.1.2"
                            "1nigwfph4anb45pyg48vwiqc5ajavb9v50alilwz50vspshjvs35")
   #:release "25"
   #:inputs (list alone-rl-graal-word)
   #:legal-origins (list graal-license)
   #:license license:upl
   #:home-page "https://github.com/oracle/graal"
   #:synopsis "Graal native image hosted API"))

(define alone-rl-angus-activation
  (alone-rl-java-package
   #:name "alone-rl-angus-activation"
   #:version "2.0.2"
   #:source (logging-source "org/eclipse/angus" "angus-activation" "2.0.2"
                            "0hbf6c22wn5xh8hzsyrmyw58zsznpnljw4nqcssi1xj6ypcxkxpq")
   #:release "25"
   #:inputs (list alone-rl-jakarta-activation-api alone-rl-graal-nativeimage alone-rl-graal-word)
   #:license license:bsd-3
   #:home-page "https://eclipse-ee4j.github.io/angus-activation/"
   #:synopsis "Jakarta Activation registry provider"))

(define alone-rl-angus-mail
  (alone-rl-java-package
   #:name "alone-rl-angus-mail"
   #:version "2.0.4"
   #:source (logging-source "org/eclipse/angus" "angus-mail" "2.0.4"
                            "0i52hsd0g32hffrx95l7bwcc974bdpgzjzayhp3bcwjva1zh4rja")
   #:release "25"
   #:inputs (list alone-rl-jakarta-mail-api alone-rl-jakarta-activation-api alone-rl-angus-activation alone-rl-graal-nativeimage alone-rl-graal-word)
   #:license license:epl2.0
   #:home-page "https://eclipse-ee4j.github.io/angus-mail/"
   #:synopsis "Jakarta Mail protocol providers"))

(define alone-rl-jansi
  (alone-rl-java-package
   #:name "alone-rl-jansi"
   #:version "2.4.0"
   #:source (logging-source "org/fusesource/jansi" "jansi" "2.4.0"
                            "0gdk1drdalh69hbf71bgsqfcdkphda6av96kh2xxahl3692p87a2")
   #:release "25"
   #:source-roots '("org" "META-INF")
   #:inputs (list glibc)
   #:native-inputs (list gcc-toolchain)
   #:extra-sources (list (cons "native" jansi-native-source))
   #:legal-files '("extra-source/native/license.txt")
   #:prepare #~(begin
       (delete-file-recursively "org/fusesource/jansi/internal/native")
       ;; Replace upstream's old bundled JNI headers (jni_md.h carries a
       ;; proprietary notice) with the independently source-built OpenJDK's.
       (let ((include (string-append #$openjdk25:jdk "/include"))
             (root "extra-source/native/src/main/native/inc_linux/"))
         (copy-file (string-append include "/jni.h")
                    (string-append root "jni.h"))
         (copy-file (string-append include "/linux/jni_md.h")
                    (string-append root "jni_md.h")))
       (substitute* "org/fusesource/jansi/jansi.properties"
         (("\\$\\{project.version\\}") "2.4.0")))
   #:finish #~(let* ((source "extra-source/native/src/main/native/")
             (target (string-append "build/classes/org/fusesource/jansi/internal/native/Linux/"
                                    #$linux-native-arch "/libjansi.so")))
       (mkdir-p (dirname target))
       (invoke "gcc" "-shared" "-fPIC" "-O2" "-fvisibility=hidden"
               (string-append "-I" source)
               (string-append source "jansi.c")
               (string-append source "jansi_isatty.c")
               (string-append source "jansi_structs.c")
               (string-append source "jansi_ttyname.c")
               "-lutil" (string-append "-Wl,-rpath," #$glibc "/lib")
               "-o" target))
   #:license license:asl2.0
   #:home-page "https://github.com/fusesource/jansi"
   #:synopsis "Jansi ANSI console and native backend"))

(define alone-rl-jline-native
  (alone-rl-java-package
   #:name "alone-rl-jline-native"
   #:version "4.3.1"
   #:source (logging-source "org/jline" "jline-native" "4.3.1"
                            "1kprrgiyzkns6rvd9xgcrg8j5k0k7kswjkyrym3vjbb0kx9x06dw")
   #:release "25"
   #:source-roots '("org" "META-INF")
   #:inputs (list glibc)
   #:native-inputs (list gcc-toolchain)
   #:extra-sources (list (cons "native" jline-native-source))
   #:legal-origins (list jline-native-source)
   #:prepare #~(begin
       (for-each
        (lambda (entry)
          (let ((path (string-append "org/jline/nativ/" entry)))
            (when (file-is-directory? path) (delete-file-recursively path))))
        '("FreeBSD" "Linux" "Mac" "Windows"))
       (substitute* "org/jline/nativ/jlinenative.properties"
         (("\\$\\{project.version\\}") "4.3.1")))
   #:finish #~(let* ((source "extra-source/native/native/src/main/native/")
             (jdk (string-append #$openjdk25:jdk "/include"))
             (target (string-append "build/classes/org/jline/nativ/Linux/"
                                    #$linux-native-arch "/libjlinenative.so")))
       (mkdir-p (dirname target))
       (invoke "gcc" "-shared" "-fPIC" "-O2" "-fvisibility=hidden"
               (string-append "-I" source)
               (string-append "-I" jdk) (string-append "-I" jdk "/linux")
               (string-append source "jlinenative.c")
               (string-append source "clibrary.c")
               (string-append source "kernel32.c")
               "-lutil" (string-append "-Wl,-rpath," #$glibc "/lib")
               "-o" target))
   #:license (list license:bsd-3 license:asl2.0)
   #:home-page "https://github.com/jline/jline3"
   #:synopsis "JLine source-built native terminal support"))

(define alone-rl-jline-terminal
  (alone-rl-java-package
   #:name "alone-rl-jline-terminal"
   #:version "4.3.1"
   #:source (logging-source "org/jline" "jline-terminal" "4.3.1"
                            "0b6p2mqcs33ps5ar5mr69xz23930sy92sj2zl57xibchs676944j")
   #:release "25"
   #:inputs (list alone-rl-jline-native)
   #:legal-origins (list jline-native-source)
   #:license (list license:bsd-3 license:asl2.0)
   #:home-page "https://github.com/jline/jline3"
   #:synopsis "JLine terminal API and providers"))

(define alone-rl-jline-terminal-jni
  (alone-rl-java-package
   #:name "alone-rl-jline-terminal-jni"
   #:version "4.3.1"
   #:source (logging-source "org/jline" "jline-terminal-jni" "4.3.1"
                            "0d65qi497nrlsmx2wbjl33fzj3x45b6qqq45djarw9qpf093hln7")
   #:release "25"
   #:inputs (list alone-rl-jline-terminal alone-rl-jline-native)
   #:legal-origins (list jline-native-source)
   #:license (list license:bsd-3 license:asl2.0)
   #:home-page "https://github.com/jline/jline3"
   #:synopsis "JLine JNI terminal provider"))

(define alone-rl-jline-terminal-ffm
  (alone-rl-java-package
   #:name "alone-rl-jline-terminal-ffm"
   #:version "4.3.1"
   #:source (logging-source "org/jline" "jline-terminal-ffm" "4.3.1"
                            "1jq5mk31q18g8wqkyrlwldlffs26pardkwzh72ff2bw8vmnn4qis")
   #:release "25"
   #:inputs (list alone-rl-jline-terminal alone-rl-jline-native)
   #:legal-origins (list jline-native-source)
   #:license (list license:bsd-3 license:asl2.0)
   #:home-page "https://github.com/jline/jline3"
   #:synopsis "JLine foreign function terminal provider"))

(define alone-rl-jansi-core
  (alone-rl-java-package
   #:name "alone-rl-jansi-core"
   #:version "4.3.1"
   #:source (logging-source "org/jline" "jansi-core" "4.3.1"
                            "01afpravm84z6q1mf5ny04zfchflnsm6svnh3mj19kz29zih850j")
   #:release "25"
   #:inputs (list alone-rl-jline-terminal alone-rl-jline-native)
   #:legal-origins (list jline-native-source)
   #:prepare #~(substitute* "org/jline/jansi/jansi.properties"
       (("\\$\\{project.version\\}") "4.3.1"))
   #:license license:bsd-3
   #:home-page "https://github.com/jline/jline3"
   #:synopsis "JLine Jansi console support"))

;; Both console integrations, XZ, SMTP, and servlet integration remain built.
;; No Logback Java source is excluded; the constructor ignores only JPMS
;; descriptors because AloneRL and these jars use an explicit class path.
(define-public alone-rl-logback-core
  (alone-rl-java-package
   #:name "alone-rl-logback-core"
   #:version "1.6.3"
   #:source (logging-source "ch/qos/logback" "logback-core" "1.6.3"
                            "1ynr96xssm3lgh8a0jhcsb8bgm29jw044n66y4wpbkf2lczj5zbs")
   #:release "25"
   #:inputs (list alone-rl-jansi alone-rl-jansi-core alone-rl-jline-terminal alone-rl-jline-native alone-rl-xz alone-rl-jakarta-mail-api alone-rl-jakarta-activation-api alone-rl-jakarta-servlet-api)
   #:legal-origins (list logback-notice logback-epl logback-lgpl)
   #:prepare #~(substitute* "ch/qos/logback/core/logback-core-version.properties"
       (("\\$\\{project.version\\}") "1.6.3"))
   #:license (list license:epl2.0 license:lgpl2.1)
   #:home-page "https://logback.qos.ch/"
   #:synopsis "Logback core logging framework"))

(define-public alone-rl-logback-classic
  (alone-rl-java-package
   #:name "alone-rl-logback-classic"
   #:version "1.6.3"
   #:source (logging-source "ch/qos/logback" "logback-classic" "1.6.3"
                            "12b95g703i3av5p4c3d0z0mp6rgq4pkndawhyr3d1rlmkhslrmml")
   #:release "25"
   #:inputs (list alone-rl-logback-core alone-rl-slf4j-api alone-rl-jakarta-mail-api alone-rl-jakarta-activation-api alone-rl-jakarta-servlet-api)
   #:legal-origins (list logback-notice logback-epl logback-lgpl)
   #:prepare #~(substitute* "ch/qos/logback/classic/logback-classic-version.properties"
       (("\\$\\{project.version\\}") "1.6.3"))
   #:license (list license:epl2.0 license:lgpl2.1)
   #:home-page "https://logback.qos.ch/"
   #:synopsis "Logback SLF4J implementation"))

;; Complete explicit class path: inputs are not transitively searched by
;; javac or the launcher.  Angus supplies the otherwise missing SMTP and
;; Activation service implementations.  FFM and rebuilt JNI providers coexist.
;; Launching on JDK 25 requires --enable-native-access=ALL-UNNAMED.
(define-public alone-rl-java-logging-runtime
  (list alone-rl-logback-core alone-rl-logback-classic alone-rl-slf4j-api
        alone-rl-xz alone-rl-jansi alone-rl-jansi-core
        alone-rl-jline-native alone-rl-jline-terminal
        alone-rl-jline-terminal-jni alone-rl-jline-terminal-ffm
        alone-rl-jakarta-servlet-api alone-rl-jakarta-mail-api
        alone-rl-jakarta-activation-api alone-rl-angus-mail
        alone-rl-angus-activation alone-rl-graal-nativeimage alone-rl-graal-word))
