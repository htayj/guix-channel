;;; GNU Guix package for SecretPathway, a graphical MUD client.

(define-module (tay packages secretpathway)
  #:use-module (guix build-system ant)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages java))

(define-public secretpathway
  (let ((commit "2ea2e6bac49aa96781d726f7b3c14bd5fbc7c141")
        (revision "0"))
    (package
      (name "secretpathway")
      (version (git-version "1.0.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/mhahnFr/SecretPathway")
               (commit commit)
               (recursive? #t)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "122krjqldbv1m8dvdx30kvfdmawhkib1qvmdmm78vfa3r0slcz26"))))
      (build-system ant-build-system)
      (arguments
       (list
        #:jdk openjdk17
        #:jar-name "secretpathway.jar"
        #:main-class "mhahnFr.SecretPathway.SecretPathway"
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'prepare-offline-source
              (lambda _
                ;; The Gradle wrapper is neither needed nor safe to use in an
                ;; offline build.  Compile the pinned JUtilities submodule as
                ;; part of the same source tree instead.
                (delete-file "gradle/wrapper/gradle-wrapper.jar")
                ;; JUtilities calls Desktop.getDesktop() unconditionally for
                ;; global macOS menu handlers.  This aborts Swing startup on
                ;; Guix's Linux OpenJDK; JUtilities' ordinary Swing menu-bar
                ;; fallback works when that macOS-only path is bypassed.
                (substitute*
                    "JUtilities/src/mhahnFr/utils/gui/menu/MenuFactory.java"
                  (("    private MenuFactory\\(\\) \\{")
                   (string-append
                    "    private MenuFactory() {\n"
                    "        if (!System.getProperty(\"os.name\")"
                    ".toLowerCase().contains(\"mac\")\n"
                    "                || !Desktop.isDesktopSupported()) {\n"
                    "            menubar = false;\n"
                    "            return;\n"
                    "        }\n")))
                (copy-recursively "JUtilities/src/mhahnFr/utils"
                                  "src/mhahnFr/utils")))
            (replace 'check
              (lambda* (#:key tests? #:allow-other-keys)
                (when tests?
                  ;; Upstream has no test suite.  Load the finished jar in a
                  ;; separate JVM and check both its public version constant
                  ;; and a fail-closed connection-construction path.
                  (call-with-output-file "SecretPathwayCheck.java"
                    (lambda (port)
                      (display
                       "import mhahnFr.SecretPathway.core.Constants;\n\
import mhahnFr.SecretPathway.core.net.ConnectionFactory;\n\
public final class SecretPathwayCheck {\n\
  public static void main(String[] args) {\n\
    if (!\"1.0\".equals(Constants.VERSION))\n\
      throw new AssertionError(Constants.VERSION);\n\
    if (ConnectionFactory.create(\"127.0.0.1\", 0) != null)\n\
      throw new AssertionError(\"invalid endpoint accepted\");\n\
  }\n\
}\n"
                       port)))
                  (invoke "javac" "--release" "17"
                          "-cp" "build/jar/secretpathway.jar"
                          "SecretPathwayCheck.java")
                  (invoke "java" "-cp" "build/jar/secretpathway.jar:."
                          "SecretPathwayCheck"))))
            (add-after 'install 'install-launcher-and-metadata
              (lambda _
                (let* ((bin (string-append #$output "/bin"))
                       (launcher (string-append bin "/secretpathway"))
                       (applications
                        (string-append #$output "/share/applications"))
                       (doc (string-append #$output
                                           "/share/doc/secretpathway-"
                                           #$version)))
                  (mkdir-p bin)
                  (call-with-output-file launcher
                    (lambda (port)
                      ;; Java derives user.home from the account database and
                      ;; can ignore an isolated HOME.  Make the launcher's
                      ;; mutable Preferences tree follow HOME explicitly.
                      (format port
                              (string-append
                               "#!~a/bin/sh~%exec ~a/bin/java "
                               "-Duser.home=\"${HOME:-$PWD}\" -jar "
                               "~a/share/java/secretpathway.jar \"$@\"~%")
                              #$bash-minimal #$openjdk17 #$output)))
                  (chmod launcher #o555)
                  (mkdir-p applications)
                  (call-with-output-file
                      (string-append applications "/secretpathway.desktop")
                    (lambda (port)
                      (display
                       "[Desktop Entry]\n\
Type=Application\n\
Name=SecretPathway\n\
Comment=Connect to text-based MUD servers\n\
Exec=secretpathway\n\
Terminal=false\n\
Categories=Game;Network;\n"
                       port)))
                  (install-file "README.md" doc)
                  (install-file "LICENSE" doc)
                  (copy-file "JUtilities/LICENSE"
                             (string-append doc "/JUtilities-LICENSE"))))))))
      (inputs
       (list bash-minimal openjdk17))
      (home-page "https://github.com/mhahnFr/SecretPathway")
      (synopsis "Graphical MUD client with an LPC source editor")
      (description
       "SecretPathway is a graphical Java MUD client.  It supports Telnet,
ANSI colors, the SecretPathway protocol, and an integrated LPC source editor.
This package builds the client and its pinned JUtilities submodule entirely
offline and keeps Java preferences and other mutable user state outside the
store.")
      ;; README.md says GPL 3.0, but the copyright headers in both the main
      ;; source and the bundled JUtilities source explicitly grant version 3
      ;; or any later version.
      (license license:gpl3+))))
