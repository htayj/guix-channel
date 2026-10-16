;;; Offline source compilation and installation for Experienced Pixel Dungeon.
(define-module (tay packages experienced-pixel-dungeon-build)
  #:use-module (guix build utils)
  #:use-module (ice-9 format)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (exppd-compile-java exppd-build-json exppd-install-json
            exppd-prepare-game exppd-build-game exppd-install-game))

(define (exppd-compile-java jdk roots classpath)
  (mkdir-p "build/classes")
  (call-with-output-file "build/sources.list"
    (lambda (port)
      (for-each (lambda (file) (format port "~s~%" file))
                (sort (append-map (lambda (root) (find-files root "\\.java$"))
                                  roots)
                      string<?))))
  (invoke (string-append jdk "/bin/javac")
          "--release" "8" "-encoding" "UTF-8" "-proc:none"
          "-sourcepath" "" "-classpath" classpath
          "-d" "build/classes" "@build/sources.list"))

(define (exppd-jar jdk name manifest)
  (apply invoke (string-append jdk "/bin/jar")
         (append (list "--create" "--file" name
                       "--date=1980-01-01T00:00:02Z")
                 (if manifest (list "--manifest" manifest) '())
                 (list "-C" "build/classes" "."))))

(define (exppd-build-json jdk)
  (exppd-compile-java jdk '("src/main/java") "")
  (exppd-jar jdk "build/json.jar" #f))

(define (exppd-install-json out)
  (let ((doc (string-append out "/share/doc/java-exppd-json")))
    (install-file "build/json.jar" (string-append out "/share/java"))
    (install-file "LICENSE" doc)
    (copy-recursively "src" (string-append doc "/source/src"))
    (for-each (lambda (file) (install-file file (string-append doc "/source")))
              '("LICENSE" "README.md" "pom.xml"))))

(define (exppd-prepare-game patch font)
  ;; The origin has already removed the unproven desktop font and binary
  ;; wrapper. Preserve this original sanitized tree before local integration.
  (copy-recursively "." "../exppd-source-original")
  (invoke "patch" "--batch" "--fuzz=0" "-p1" "-i" patch)
  (copy-file (string-append font "/share/fonts/truetype/ExpPDUnicodeSans.ttf")
             "desktop/src/main/assets/fonts/droid_sans.ttf")
  (copy-recursively (string-append font "/share/doc/exppd-unicode-font")
                    "font-notices")
  (copy-recursively "." "../exppd-source-linux"))

(define (exppd-build-game jdk gdx lwjgl controllers json)
  (exppd-compile-java
   jdk
   '("SPD-classes/src/main/java" "core/src/main/java"
     "desktop/src/main/java" "services/src/main/java"
     "services/updates/githubUpdates/src/main/java"
     "services/news/ingameNews/src/main/java")
   (string-join
    (list (string-append gdx "/share/java/gdx.jar")
          (string-append lwjgl "/share/java/lwjgl.jar")
          (string-append controllers "/share/java/gdx-controllers.jar")
          (string-append json "/share/java/json.jar")) ":"))
  ;; Match desktop/processResources: every core and desktop asset is bundled.
  (copy-recursively "core/src/main/assets" "build/classes")
  (copy-recursively "desktop/src/main/assets" "build/classes")
  (call-with-output-file "build/MANIFEST.MF"
    (lambda (port)
      (display "Manifest-Version: 1.0\nMain-Class: com.shatteredpixel.shatteredpixeldungeon.desktop.DesktopLauncher\nSpecification-Title: Experienced Pixel Dungeon\nImplementation-Title: com.trashboxbobylev.experiencedpixeldungeon.redone\nSpecification-Version: ExpPD-2.19.0\nImplementation-Version: 666\nUpstream-Commit: 7a71df6a56b371a6b0efffcbe6210dbcfaf8611d\nUpstream-Source-SHA256: 3242757d206ee86217120d4af306bdca25d9ca858aeb5aab215818a82d7daa68\n\n" port)))
  (exppd-jar jdk "build/experienced-pixel-dungeon.jar" "build/MANIFEST.MF"))

(define (exppd-install-game out java shell gdx lwjgl controllers json font
                            zenity xdg which wrapper notices apache recipe helper patch)
  (let* ((share (string-append out "/share/experienced-pixel-dungeon"))
         (doc (string-append out "/share/doc/experienced-pixel-dungeon"))
         (launcher (string-append out "/bin/experienced-pixel-dungeon")))
    (install-file "build/experienced-pixel-dungeon.jar"
                  (string-append out "/share/java"))
    (copy-recursively "../exppd-source-original" (string-append share "/source-original"))
    (copy-recursively "../exppd-source-linux" (string-append share "/source-linux"))
    (mkdir-p doc)
    (copy-file notices (string-append doc "/NOTICES.txt"))
    (copy-file apache (string-append doc "/Apache-2.0.txt"))
    (install-file "LICENSE.txt" doc)
    (install-file "README.md" doc)
    (copy-file "core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/scenes/AboutScene.java"
               (string-append doc "/AboutScene.java"))
    (copy-recursively "font-notices" (string-append doc "/font"))
    ;; Keep dependency notices and complete corresponding sources reachable,
    ;; without copying executable jars or native binaries into source trees.
    (let ((dependencies (string-append doc "/dependencies")))
      (mkdir-p dependencies)
      (for-each
       (lambda (entry)
         (symlink (string-append (cdr entry) "/share/doc")
                  (string-append dependencies "/" (car entry))))
       (list (cons "libgdx" gdx) (cons "lwjgl" lwjgl)
             (cons "controllers" controllers) (cons "json" json)
             (cons "unicode-font" font))))
    (let ((integration (string-append share "/source-linux/guix")))
      (mkdir-p integration)
      (for-each
       (lambda (entry) (copy-file (cdr entry)
                                 (string-append integration "/" (car entry))))
       (list (cons "experienced-pixel-dungeon.scm" recipe)
             (cons "experienced-pixel-dungeon-build.scm" helper)
             (cons "experienced-pixel-dungeon-wrapper.sh" wrapper)
             (cons "experienced-pixel-dungeon-offline.patch" patch)
             (cons "NOTICES.txt" notices)
             (cons "Apache-2.0.txt" apache))))
    (mkdir-p (dirname launcher))
    (copy-file wrapper launcher)
    (substitute* launcher
      (("@SH@") shell)
      (("@JAVA@") java)
      (("@GAME@") (string-append out "/share/java/experienced-pixel-dungeon.jar"))
      (("@GDX@") gdx)
      (("@LWJGL@") lwjgl)
      (("@CONTROLLERS@") controllers)
      (("@ZENITY@") zenity)
      (("@XDG@") xdg)
      (("@WHICH@") which)
      (("@JSON@") json))
    (chmod launcher #o555)
    (let ((applications (string-append out "/share/applications"))
          (icons (string-append out "/share/icons/hicolor/256x256/apps")))
      (mkdir-p applications)
      (mkdir-p icons)
      (copy-file "desktop/src/main/assets/icons/icon_256.png"
                 (string-append icons "/experienced-pixel-dungeon.png"))
      (call-with-output-file
          (string-append applications "/experienced-pixel-dungeon.desktop")
        (lambda (port)
          (format port "[Desktop Entry]\nType=Application\nName=Experienced Pixel Dungeon\nComment=ExpPD 2.19 roguelike dungeon crawler\nExec=~a\nIcon=experienced-pixel-dungeon\nTerminal=false\nCategories=Game;RolePlaying;\n" launcher))))))
