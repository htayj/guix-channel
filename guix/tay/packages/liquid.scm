;;; GNU Guix package for mogenslund's Liquid Clojure text editor.

(define-module (tay packages liquid)
  #:use-module (tay packages auxiliary)
  #:use-module ((tay packages starred-i-m) #:select (mogenslund-liquid-source))
  #:use-module (guix build-system clojure)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages clojure)
  #:use-module (gnu packages java)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages python))

;; Installed below libexec and reachable only through liquid-smoke.  It drives
;; the real editor through a PTY with a fixture file, then quits with :q.
(define %liquid-smoke-script
  (local-file (search-tay-package-file "liquid-smoke.py")))

(define %liquid-commit
  "045f587b3914485baf85d9eae4f97f968cbfafaa")

(define-public liquid
  (package
    (name "liquid")
    (version (git-version "2.1.2" "0" %liquid-commit))
    ;; Reuse the channel's preserved codeload archive of the pinned commit so
    ;; the build and the source snapshot share exactly one origin and hash.
    (source (package-source mogenslund-liquid-source))
    (build-system clojure-build-system)
    (arguments
     (list
      ;; Upstream pins Clojure 1.10.3 and data.json 0.2.6 through Maven.  Build
      ;; instead against Guix's source-built Clojure and data.json; Liquid uses
      ;; only data.json's stable read-str/write-str API.
      #:source-dirs #~'("src")
      #:test-dirs #~'("test")
      #:jar-names #~'("liquid.jar")
      #:main-class #~'liq.core
      #:doc-dirs #~'()
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-shell-paths
            (lambda _
              (let ((sh #$(file-append bash-minimal "/bin/sh"))
                    (stty #$(file-append coreutils-minimal "/bin/stty")))
                ;; Terminal setup, size queries and restoration run stty
                ;; through /bin/sh; neither exists at those paths on Guix.
                (substitute* '("src/liq/tty_input.clj"
                               "src/liq/tty_output.cljc")
                  (("\"/bin/sh\" \"-c\" \"stty ")
                   (string-append "\"" sh "\" \"-c\" \"" stty " ")))
                ;; The :! external-command feature also invokes /bin/sh.
                (substitute* "src/liq/commands.cljc"
                  (("\"/bin/sh\"")
                   (string-append "\"" sh "\""))))))
          (add-after 'build 'add-user-namespace-and-resources
            (lambda _
              ;; liq/core.cljc ends with (ns user ...).  AOT compiling liq.core
              ;; therefore emits user$... classes that liq.core__init loads,
              ;; but the standard build keeps only classes named after libs.
              ;; Also ship the help texts that help-mode reads as resources.
              (let ((user-classes
                     (find-files "classes" "^user\\$.*\\.class$")))
                (when (null? user-classes)
                  (error "no AOT classes for Liquid's user namespace"))
                (for-each
                 (lambda (class)
                   (unless (string=? (dirname class) "classes")
                     (error "unexpected nested user class" class))
                   (invoke "jar" "uf" "liquid.jar"
                           "-C" "classes" (basename class)))
                 user-classes)
                (invoke "jar" "uf" "liquid.jar" "-C" "resources" "help"))))
          (add-after 'install 'install-launchers
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (runner (string-append libexec "/liquid-smoke.py"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (unshare #$(file-append util-linux "/bin/unshare"))
                     (classpath
                      (string-join
                       (list (string-append out "/share/java/liquid.jar")
                             #$(file-append clojure "/share/java/clojure.jar")
                             #$(file-append clojure-data-json
                                            "/share/java/clojure-data-json.jar"))
                       ":")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-file #$%liquid-smoke-script runner)
                (substitute* runner
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod runner #o555)
                (call-with-output-file (string-append bin "/liquid")
                  (lambda (port)
                    (format port "#!~a~%" shell)
                    ;; Keep JVM performance data out of the shared /tmp and
                    ;; honor the caller's HOME and TMPDIR for ~/.liq and files.
                    (format port "exec ~a -XX:-UsePerfData \
${HOME:+\"-Duser.home=$HOME\"} ${TMPDIR:+\"-Djava.io.tmpdir=$TMPDIR\"} \
-cp ~a liq.core \"$@\"~%"
                            #$(file-append icedtea "/bin/java")
                            classpath)))
                (chmod (string-append bin "/liquid") #o555)
                (call-with-output-file (string-append bin "/liquid-smoke")
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    (display "test \"$#\" -eq 0 || \
{ echo 'usage: liquid-smoke' >&2; exit 64; }\n" port)
                    ;; Run the proof in a fresh, interface-less network
                    ;; namespace; the runner refuses any other namespace.
                    (display "if test \"${LIQUID_SMOKE_NETNS:-}\" != 1; then\n"
                             port)
                    (format port "    LIQUID_SMOKE_NETNS=1 exec ~a --user \
--map-current-user --net --fork \"$0\"~%" unshare)
                    (display "fi\n" port)
                    (format port "exec ~a ~a ~a/bin/liquid~%"
                            python runner out)))
                (chmod (string-append bin "/liquid-smoke") #o555)))))))
    (inputs
     (list bash-minimal clojure clojure-data-json coreutils-minimal icedtea
           python-minimal util-linux))
    (home-page "https://github.com/mogenslund/liquid")
    (synopsis "Modal terminal text editor written in Clojure")
    (description
     "Liquid is a Vim-like modal text editor for Clojure and Markdown files
that runs in a terminal and can be extended with Clojure code at runtime.
This package AOT-compiles the pinned upstream source against Guix's Clojure and
data.json libraries.  It provides @command{liquid} and @command{liquid-smoke},
which opens a fixture file in an isolated pseudo-terminal and quits.")
    (license license:epl1.0)))
