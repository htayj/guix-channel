;;; Enter the Roguelike Dimension: the original author's release-era sources.
(define-module (tay packages etrd)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages java)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages etrd-libraries))

(define %core-commit "ebd9259561f6f3a27ccb3ec6e08bb43b11cee780")
(define %assets-commit "79491379c463eede37b078a8aeb15894652d96d1")
(define %desktop-commit "1bcdec7e4f76b1a470ef32ed76deba6277be5bac")

;; The March tip is an unfinished 0.0021 refactor (missing Controls and empty
;; GameStats methods), not the February 27 release.  Keep each original project
;; at its last published source revision before that release, without mixing
;; rewritten game code or a successor project into the source closure.
(define (project-source repository commit hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/Lyeeedar/" repository
                        "/tar.gz/" commit))
    (file-name (string-append repository "-" commit ".tar.gz"))
    (sha256 (base32 hash))
    (modules '((guix build utils)))
    (snippet
     #~(for-each delete-file
                 (find-files "." "\\.(jar|class|so|dll|dylib|jnilib|apk|a|o|exe)$")))))

(define %assets
  (project-source "3DRoguelikeAssets" %assets-commit
                  "0cqp18wjjhc5n8l3rdl2whd5wx94m0sflxk7zz5d3sc43c95a71y"))

(define %desktop
  (project-source "3DRoguelikeDesktop" %desktop-commit
                  "1k0bcp9v1r3hlrs2knvjyf7wp1fndbvnawpbhg2cf1kv15ci7d08"))

(define %cc-by-3.0
  (origin
    (method url-fetch)
    (uri "https://creativecommons.org/licenses/by/3.0/legalcode.txt")
    (file-name "CC-BY-3.0.txt")
    (sha256 (base32 "0xlfif2cp7s4pbsl4d6mvaqv5g59m3jwkfk8yl4bf0278yf9xg76"))))

(define %asset-notice
  (plain-file
   "ASSET-NOTICES.txt"
   "Enter the Roguelike Dimension (EtRD)
Copyright (c) 2013 Philip Collin / Lyeeedar.
The original core license.txt grants GPL version 3 for this program and its
accompanying materials.  The author's companion desktop and Android asset
projects supply those accompanying materials; their roots contain no separate
license grant.  The author-edited EtRD article also identifies GPL3:
https://www.roguebasin.com/index.php?title=EtRD

Third-party material retains its own terms, not an invented blanket GPL grant:

Droid Sans bitmap fonts (default.fnt/default.png and droid-sans.fnt/png):
Copyright (c) 2005-2008, The Android Open Source Project.
Licensed under the Apache License, Version 2.0 (Apache-2.0.txt).
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an AS IS BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.
Original font notice:
https://android.googlesource.com/platform/frameworks/base/+/android-4.2.2_r1/data/fonts/NOTICE
The required default bitmap files are exact LibGDX 0.9.8 sample resources.
The original sample UI JSON also comes from LibGDX (Apache 2.0); see the installed
LibGDX AUTHORS and NOTICE.  The original game's UI image modifications remain.

Grasping claws, by Lorc:
https://game-icons.net/1x1/lorc/grasping-claws.html
Licensed Creative Commons Attribution 3.0 Unported:
https://creativecommons.org/licenses/by/3.0/ (CC-BY-3.0.txt).
The original game's grasping-claws.png is a reduced 50-pixel derivative.
The separate brown icon-claw.png is different original game art, not this icon;
both original files are retained.  No endorsement by Lorc is implied.

Delaunay triangulation: Copyright (c) 2005, 2007 L. Paul Chew.
The complete permissive copyright, permission and warranty notice is retained
in all six installed original Java source files under source/core/src and in
Delaunay-NOTICES.java alongside this notice.

Unused Arial/Verdana bitmap variants are omitted, not replaced or relicensed.
All needed original maps, models, XML, shaders, sky and gameplay icons remain.
"))

(define %level-unload-patch
  (local-file
   (search-tay-package-file "patches/etrd-game-level-unload.patch")))

(define-public etrd
  (package
    (name "etrd")
    (version (git-version "0.0019" "0" %core-commit))
    (source
     (project-source "3DRoguelike" %core-commit
                     "154c1bdfg5vig66hcgsii5mwa12rkwv0vgdl5fimx3bi5rq8744f"))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs (list (list "icedtea:jdk" icedtea-8 "jdk") (list "zip" zip)))
    (inputs (list (list "bash-minimal" bash-minimal)
                  (list "coreutils-minimal" coreutils-minimal)
                  (list "icedtea" icedtea-8)
                  (list "java-etrd-libraries" java-etrd-libraries)
                  (list "java-guava" java-guava)
                  (list "gcc:lib" gcc-14 "lib")))
    (arguments
     (list
      #:tests? #f                      ; Original sources have no test suite.
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-13))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'unpack-companion-sources
            (lambda _
              (define (unpack archive directory)
                (mkdir-p directory)
                (invoke "tar" "xf" archive "--strip-components=1" "-C" directory))
              (unpack #$%assets "companion-assets")
              (unpack #$%desktop "companion-desktop")
              ;; Static references select default.fnt; no source/XML/skin
              ;; references select these eight Arial or Verdana files.
              (for-each
               (lambda (file)
                 (delete-file (string-append "companion-assets/assets/data/skins/"
                                             file)))
               '("arial-15.fnt" "arial-15_00.png"
                 "verdana.fnt" "verdana.png"
                 "verdana39.fnt" "verdana39.png"
                 "verdana39distancefield.fnt" "verdana39distancefield.png"))))
          (add-after 'unpack-companion-sources 'fix-glsl-types
            (lambda _
              (let ((shaders "companion-assets/assets/data/shaders"))
                (copy-recursively shaders "original-shaders")
                ;; Desktop GLSL 1.10 does not implicitly promote integers in
                ;; float arithmetic or broadcast a scalar assignment to RGB.
                ;; Keep the original encoding/lighting formulas and renderers.
                (substitute* (string-append
                              shaders "/model/deferred_normals.fragment.glsl")
                  (("sqrt\\(8\\*n.z\\+8\\)")
                   "sqrt(8.0*n.z+8.0)"))
                (substitute*
                    (map (lambda (name) (string-append shaders "/model/" name))
                         '("deferred_lighting.fragment.glsl"
                           "normal_only.fragment.glsl"))
                  (("enc\\*4-2") "enc*4.0-2.0")
                  (("sqrt\\(1-f/4\\)") "sqrt(1.0-f/4.0)")
                  (("n.z = 1-f/2") "n.z = 1.0-f/2.0"))
                (substitute*
                    (map (lambda (name) (string-append shaders "/model/" name))
                         '("deferred_lighting.fragment.glsl"
                           "forward_vertex.vertex.glsl"))
                  (("attenuation = 1 /") "attenuation = 1.0 /")
                  (("l_attenuation / 10 \\*") "l_attenuation / 10.0 *"))
                (substitute* (string-append
                              shaders "/model/deferred_lighting.fragment.glsl")
                  (("light.rgb / 5;") "light.rgb / 5.0;"))
                (substitute* (string-append
                              shaders "/model/deferred_finalise.fragment.glsl")
                  (("lTexCoords\\).rgb \\* 5;") "lTexCoords).rgb * 5.0;"))
                (substitute* (string-append
                              shaders "/model/depth_only.fragment.glsl")
                  (("gl_FragColor.rgb = unpackHalf\\(colour.ba\\);")
                   "gl_FragColor.rgb = vec3(unpackHalf(colour.ba));")))))
          (add-before 'build 'port-wavefront-loader
            (lambda _
              (copy-recursively "src" "original-src")
              ;; LibGDX 0.9.8 returns a StillModel instead of the old Mesh.
              ;; Every pinned OBJ has exactly one face-bearing group; empty
              ;; object declarations are removed by its real loader.  Thus
              ;; this mesh contains every original face, without a shim or
              ;; copying/merging vertex buffers.  Both APIs default flipV off.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("import com.badlogic.gdx.graphics.g3d.loaders.obj.ObjLoader;")
                    (if (string-suffix? "/GameData.java" file)
                        (string-append
                         "import com.badlogic.gdx.graphics.g3d.loaders."
                         "wavefront.ObjLoader;")
                        ""))))
               (find-files "src" "\\.java$"))
              (substitute* "src/com/lyeeedar/Roguelike3D/Game/GameData.java"
                (((string-append "ObjLoader.loadObj\\(Gdx.files.internal"
                                 "\\(meshLocation\\).read\\(\\)\\)"))
                 (string-append "new ObjLoader().loadObj("
                                "Gdx.files.internal(meshLocation))"
                                ".subMeshes[0].mesh")))))
          (add-after 'port-wavefront-loader 'fix-minimap-projection
            (lambda _
              ;; SpriteBatch defaults to the window projection, while this
              ;; framebuffer's viewport is width*STEP by height*STEP.  The
              ;; paused-map crop also uses STEP pixels per tile.  Match those
              ;; real coordinate systems once before drawing the framebuffer.
              (substitute*
                  "src/com/lyeeedar/Roguelike3D/Game/Level/LevelGraphics.java"
                (("fB.begin\\(\\);")
                 (string-append
                  "// Guix: use minimap framebuffer pixel coordinates.\n"
                  "\t\tsB.setProjectionMatrix(new Matrix4()"
                  ".setToOrtho2D(0, 0, width*STEP, height*STEP));\n"
                  "\t\tfB.begin();")))))
          (add-after 'fix-minimap-projection 'fix-level-unload-lifetime
            (lambda _
              ;; Normalize only patch targets; the original snapshot is intact.
              (substitute*
                  (list "src/com/lyeeedar/Roguelike3D/Game/GameObject.java"
                    "src/com/lyeeedar/Roguelike3D/Game/Item/Equipment_HAND.java"
                    (string-append "src/com/lyeeedar/Roguelike3D/Graphics/"
                                   "Models/RiggedModels/RiggedModel.java")
                    (string-append "src/com/lyeeedar/Roguelike3D/Graphics/"
                                   "Models/RiggedModels/RiggedModelNode.java")
                    (string-append "src/com/lyeeedar/Roguelike3D/Graphics/"
                                   "ParticleEffects/ParticleEmitter.java")
                    (string-append "src/com/lyeeedar/Roguelike3D/Graphics/"
                                   "Screens/LevelLoadingScreen.java"))
                (("\r\n") "\n"))
              (invoke "patch" "--batch" "--fuzz=0" "-p1"
                      "--input" #$%level-unload-patch)))
          (add-after 'fix-level-unload-lifetime 'configure-normal-desktop-exit
            (lambda _
              (copy-recursively "companion-desktop/src" "original-desktop-src")
              ;; LibGDX 0.9.8 defaults to System.exit(-1) after normal cleanup.
              ;; Let its finished application thread return normally instead.
              (substitute*
                  (string-append
                   "companion-desktop/src/com/lyeeedar/Roguelike3D/"
                   "LwjglApplicationChanger.java")
                (("cfg.resizable = false;")
                 "cfg.resizable = false;\n\t\tcfg.forceExit = false;"))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((javac (search-input-file inputs "/bin/javac"))
                     (libraries (find-files
                                 (string-append #$java-etrd-libraries "/share/java")
                                 "\\.jar$"))
                     (guava (find-files #$java-guava "\\.jar$"))
                     (classpath (string-join (append libraries guava) ":"))
                     ;; This unused experimental XMLData has no callers and
                     ;; contains unfinished methods.  Keep its source, but do
                     ;; not invent missing game behavior to compile it.
                     (sources (append
                               (filter
                                (lambda (file)
                                  (not (string-suffix? "/XMLData.java" file)))
                                (find-files "src" "\\.java$"))
                               (find-files "companion-desktop/src" "\\.java$"))))
                (mkdir-p "build/classes")
                (apply invoke javac "-encoding" "UTF-8" "-source" "8" "-target" "8"
                       "-classpath" classpath "-d" "build/classes" sources)
                ;; JDK8 jar generates current-date manifest/directory entries.
                ;; Match the dependency package's reproducible ordinary ZIP
                ;; jars: no generated manifest is needed with an explicit -cp.
                (for-each (lambda (file) (utime file 315532800 315532800))
                          (find-files "build/classes" ".*"))
                (let ((jar (string-append (getcwd) "/build/etrd.jar")))
                  (with-directory-excursion "build/classes"
                    (apply invoke "zip" "-X" "-q" jar
                           (sort (find-files "." ".*") string<?)))))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((share (string-append #$output "/share/etrd"))
                     (doc (string-append #$output "/share/doc/etrd"))
                     (bin (string-append #$output "/bin"))
                     (natives (string-append #$java-etrd-libraries "/lib"))
                     (cxx-runtime (assoc-ref inputs "gcc:lib"))
                     (classpath
                      (string-join
                       (append (list (string-append #$output "/share/java/etrd.jar"))
                               (find-files (string-append #$java-etrd-libraries
                                                          "/share/java") "\\.jar$")
                               (find-files #$java-guava "\\.jar$")
                               (list (string-append share "/assets")))
                       ":")))
                (install-file "build/etrd.jar" (string-append #$output "/share/java"))
                (copy-recursively "companion-assets/assets"
                                  (string-append share "/assets"))
                (copy-recursively "original-src"
                                  (string-append share "/source/core/src"))
                (copy-recursively "src"
                                  (string-append share "/source/build/core/src"))
                (copy-recursively "original-desktop-src"
                                  (string-append share "/source/desktop/src"))
                (copy-recursively "companion-desktop/src"
                                  (string-append share "/source/build/desktop/src"))
                (copy-recursively "original-shaders"
                                  (string-append share "/source/assets/shaders"))
                (install-file "license.txt" doc)
                (install-file "README" doc)
                (install-file #$%asset-notice doc)
                (install-file #$%cc-by-3.0 doc)
                (copy-file
                 "src/com/lyeeedar/Roguelike3D/Game/Level/DelaunayTriangulation/Pnt.java"
                 (string-append doc "/Delaunay-NOTICES.java"))
                (copy-file
                 (string-append #$java-etrd-libraries
                                "/share/doc/java-etrd-libraries/notices/gdx/LICENSE")
                 (string-append doc "/Apache-2.0.txt"))
                (for-each
                 (lambda (file)
                   (copy-file
                    (string-append #$java-etrd-libraries
                                   "/share/doc/java-etrd-libraries/notices/gdx/" file)
                    (string-append doc "/LibGDX-" file)))
                 '("AUTHORS" "NOTICE"))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/etrd")
                  (lambda (port)
                    (display (string-append
                              "#!" #$bash-minimal "/bin/bash\n"
                              "set -eu\numask 077\n"
                              "state=\"${XDG_DATA_HOME:-$HOME/.local/share}/etrd\"\n"
                              #$coreutils-minimal "/bin/mkdir -p -- \"$state\"\n"
                              "cd -- \"$state\"\n"
                              "state=$PWD\n"
                              ;; OpenAL requires CXXABI_1.3.15; start the JVM
                              ;; with its matching C++ runtime before an older
                              ;; IcedTea dependency can claim that SONAME.
                              "export LD_LIBRARY_PATH="
                              cxx-runtime
                              "/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\n"
                              "exec " #$icedtea-8 "/bin/java "
                              "\"-Duser.home=$state\" "
                              "-Djava.library.path=" natives " "
                              "-Dorg.lwjgl.librarypath=" natives " "
                              "-Dnet.java.games.input.librarypath=" natives " "
                              "-cp " classpath
                              " com.lyeeedar.Roguelike3D.Main \"$@\"\n")
                             port)))
                (chmod (string-append bin "/etrd") #o755)))))))
    (home-page "https://www.roguebasin.com/index.php?title=EtRD")
    (synopsis "First-person real-time ASCII roguelike")
    (description
     "Enter the Roguelike Dimension (EtRD) is Philip Collin's first-person
real-time 3D ASCII roguelike, with spells, equipment, crafting and procedural
dungeons.  This package builds the original February 2013 core and desktop
sources, with their matching companion assets and source-built legacy LibGDX
and LWJGL libraries.  Immutable resources remain on the class path, while
preferences and native saves live in the user's XDG data directory.")
    (license (list license:gpl3 license:asl2.0 license:cc-by3.0
                   (license:non-copyleft
                    "https://www.cs.cornell.edu/Info/People/chew/Delaunay.html"
                    "L. Paul Chew's permissive Delaunay triangulation notice")))))
