;;; GNU Guix package for Atlas Warriors.

(define-module (tay packages atlas-warriors)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages python))

(define-public atlas-warriors
  (package
    (name "atlas-warriors")
    ;; alpha-009 is the final tagged playable snapshot.  It is a lightweight
    ;; tag, so pin the commit rather than fetching a mutable branch or a
    ;; GitHub-generated archive.
    (version "0.0.9")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/lkingsford/AtlasWarriors")
             (commit "d5354adbe29884016aec2867c9ded52d15f9fcd1")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1c2m4i74d0iz7f9xx678k0m0ns0wnbxh1y9m0rsyzd0vygnp5mbq"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-runtime
            (lambda _
              (chdir "src")
              ;; These are Windows packaging helpers, not game runtime code.
              (delete-file "pygame2exe.py")
              (delete-file "setup.py")
              (delete-file "Assets/Thumbs.db")
              ;; The launcher does not change into the application directory.
              ;; Resolve every resource from immutable application data instead.
              (substitute* "rl.py"
                (("import traceback")
                 (string-append
                  "import traceback\n\nDATA_ROOT = "
                  (object->string
                   (string-append #$output "/share/atlas-warriors"))
                  "\n"))
                (("filename='error\\.log',")
                 "filename=os.path.join(state_directory, 'error.log'),")
                (("logging\\.basicConfig\\(")
                 (string-append
                  "state_directory = os.path.join(os.environ.get(\n"
                  "    'XDG_STATE_HOME', os.path.join(os.path.expanduser('~'), "
                  "'.local', 'state')), 'atlas-warriors')\n"
                  "os.makedirs(state_directory, exist_ok=True)\n"
                  "logging.basicConfig("))
                (("screen = pygame\\.display\\.set_mode")
                 "pygame.init()\nscreen = pygame.display.set_mode")
                (("if len\\(sys\\.argv\\) > 1:")
                 (string-append
                  "guix_smoke = sys.argv[1:] == ['--guix-smoke']\n"
                  "if guix_smoke:\n"
                  "    random.seed(281)\n"
                  "    action = 0\n"
                  "elif len(sys.argv) > 1:"))
                (("xml2object\\.parse\\('items\\.xml', item\\.Item\\)")
                 "xml2object.parse(os.path.join(DATA_ROOT, 'items.xml'), item.Item)")
                (("os\\.path\\.join\\('assets','back_level_")
                 "os.path.join(DATA_ROOT, 'assets', 'back_level_")
                (("tutorial\\.TriggerMessage\\(TUTORIAL_FIRSTRUN\\)")
                 (string-append
                  "if guix_smoke:\n"
                  "    tutorial.tutorial_settings = dict((i, True) for i in "
                  "range(17))\n"
                  "tutorial.TriggerMessage(TUTORIAL_FIRSTRUN)"))
                (("running = True")
                 (string-append
                  "if guix_smoke:\n"
                  "    pygame.font.Font(os.path.join(DATA_ROOT, 'DejaVuSans.ttf'), 12)\n"
                  "    start = (PC.x, PC.y)\n"
                  "    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):\n"
                  "        target = (start[0] + dx, start[1] + dy)\n"
                  "        if (PC.currentMap.Map[target[0]][target[1]].walkable and\n"
                  "                not any(c is not PC and c.x == target[0] and\n"
                  "                        c.y == target[1]\n"
                  "                        for c in PC.currentMap.characters)):\n"
                  "            PC.tryMove(target[0], target[1])\n"
                  "            break\n"
                  "    else:\n"
                  "        raise RuntimeError('smoke map has no adjacent "
                  "walkable tile')\n"
                  "    if (PC.x, PC.y) == start:\n"
                  "        raise RuntimeError('smoke player move did not "
                  "change position')\n"
                  "    PC.currentMap.Tick()\n"
                  "    if PC.currentMap.Turn != 1:\n"
                  "        raise RuntimeError('smoke map turn did not advance')\n"
                  "    DrawMap()\n"
                  "    surface.blit(hpFont.render('HP ' + str(PC.hp), True,\n"
                  "                                 (255, 255, 255)), (3, 560))\n"
                  "    win.update()\n"
                  "    screen.blit(surface, (0, 0))\n"
                  "    pygame.display.flip()\n"
                  "    screenshot = os.environ.get('ATLAS_WARRIORS_SMOKE_SCREENSHOT')\n"
                  "    if screenshot:\n"
                  "        pygame.image.save(surface, screenshot)\n"
                  "    tutorial.close()\n"
                  "    pygame.quit()\n"
                  "    print('atlas-warriors isolated smoke passed')\n"
                  "    sys.exit(0)\n\n"
                  "running = True")))
              ;; Keep every font lookup independent of the invoking directory.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("import pygame") "import pygame\nimport os")
                   (("\"DejaVuSansMono\\.ttf\"")
                    "os.path.join(os.path.dirname(__file__), \"DejaVuSansMono.ttf\")")
                   (("\"DejaVuSans\\.ttf\"")
                    "os.path.join(os.path.dirname(__file__), \"DejaVuSans.ttf\")")
                   (("\"DejaVuSerif\\.ttf\"")
                    "os.path.join(os.path.dirname(__file__), \"DejaVuSerif.ttf\")")))
               (find-files "." "\\.py$"))
              ;; Modern pygame identifies colors as pygame.color.Color rather
              ;; than the Python-2-era pygame.Color type string.
              (substitute* "pygcurse.py"
                (("    elif value in colornames:")
                 (string-append
                  "    elif isinstance(value, pygame.Color):\n"
                  "        return value\n"
                  "    elif value in colornames:")))
              ;; Tutorial state is mutable user state, never store data.
              (substitute* "tutorial.py"
                (("import json")
                 (string-append
                  "import json\nimport os\n\n"
                  "TUTORIAL_PATH = os.path.join(os.environ.get("
                  "'XDG_STATE_HOME', os.path.join(os.path.expanduser('~'), "
                  "'.local', 'state')), 'atlas-warriors', 'tutorial.json')"))
                (("open\\(\"tutorial\\.json\"") "open(TUTORIAL_PATH")
                (("        # Saves settings to tutorial\\.json ")
                 (string-append
                  "        # Saves settings to the user's XDG state directory\n"
                  "        os.makedirs(os.path.dirname(TUTORIAL_PATH), "
                  "exist_ok=True)")))
              ;; Do not leave menu choices that spawn a browser or contact a URL.
              (substitute* "mainmenu.py"
                (("import webbrowser\n") "")
                (("webbrowser\\.open_new_tab[^\n]*\n") "pass\n"))))
          (add-after 'prepare-runtime 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; The two omitted Windows-only helpers are the only files
                ;; that retain Python 2 syntax in this source snapshot.
                (apply invoke (append (list "python3" "-m" "py_compile")
                                      (find-files "." "\\.py$")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? file)
                     (error "missing Atlas Warriors runtime asset" file)))
                 '("items.xml"
                   "Assets/back_level_0.png"
                   "Assets/back_level_1.png"
                   "Assets/back_level_2.png"
                   "Assets/back_level_3.png")))))
          (add-after 'check 'remove-check-bytecode
            (lambda _
              (for-each delete-file-recursively
                        (find-files "." "__pycache__$" #:directories? #t))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/atlas-warriors"))
                     (assets (string-append data "/assets"))
                     (doc (string-append out "/share/doc/atlas-warriors"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/atlas-warriors"))
                     (font-root (string-append #$font-dejavu
                                               "/share/fonts/truetype")))
                (mkdir-p data)
                (mkdir-p assets)
                (mkdir-p doc)
                (mkdir-p bin)
                (for-each (lambda (file)
                            (copy-file file (string-append data "/" file)))
                          (find-files "." "\\.py$"))
                (copy-file "items.xml" (string-append data "/items.xml"))
                (for-each (lambda (number)
                            (copy-file
                             (string-append "Assets/back_level_" number ".png")
                             (string-append assets "/back_level_" number ".png")))
                          '("0" "1" "2" "3"))
                ;; Replace the unnotified upstream TTFs with exact files from
                ;; font-dejavu 2.37, whose X11-style notice is installed too.
                (for-each (lambda (font)
                            (copy-file (string-append font-root "/" font)
                                       (string-append data "/" font)))
                          '("DejaVuSans.ttf" "DejaVuSansMono.ttf" "DejaVuSerif.ttf"))
                (for-each (lambda (file)
                            (copy-file (string-append "../" file)
                                       (string-append doc "/" file)))
                          '("LICENSE" "README.md" "CHANGELOG.md"))
                (copy-file (string-append #$font-dejavu
                                          "/share/doc/font-dejavu-2.37/LICENSE")
                           (string-append doc "/DejaVu-LICENSE"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\n"
                      "case \"$#\" in\n"
                      "  0) ;;\n"
                      "  1) test \"$1\" = --guix-smoke || {\n"
                      "       echo 'usage: atlas-warriors [--guix-smoke]' >&2;\n"
                      "       exit 64; } ;;\n"
                      "  *) echo 'usage: atlas-warriors [--guix-smoke]' >&2;\n"
                      "     exit 64 ;;\n"
                      "esac\n"
                      "export PYTHONDONTWRITEBYTECODE=1 PYTHONNOUSERSITE=1\n"
                      "export PYGAME_HIDE_SUPPORT_PROMPT=1\n"
                      "export PYTHONPATH=" #$python-pygame
                      "/lib/python3.12/site-packages\n"
                      "exec " #$python "/bin/python3 " data "/rl.py \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal font-dejavu python python-pygame))
    (synopsis "Graphical fantasy roguelike")
    (description
     "Atlas Warriors is a graphical, turn-based fantasy roguelike.  This
package builds the final alpha-009 source snapshot, uses Guix's Pygame and
DejaVu inputs, keeps application data immutable, and saves logs and tutorial
state only below the user's XDG state directory.  Its installed menu performs
no browser, updater, or runtime download action.")
    (home-page "https://nerdygentleman.itch.io/atlas-warriors")
    ;; Project code/data is Expat; pygcurse.py is BSD-2; four modified Dark
    ;; Paper Pack backgrounds are CC-BY-3.0; installed DejaVu fonts are X11.
    ;; LICENSE, README attribution, and the DejaVu notice are installed in
    ;; share/doc/atlas-warriors.
    (license (list license:expat license:bsd-2 license:cc-by3.0 license:x11))))
