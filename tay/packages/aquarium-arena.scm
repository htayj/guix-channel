;;; GNU Guix package for Aquarium Arena.

(define-module (tay packages aquarium-arena)
  #:use-module (guix build-system copy)
  #:use-module (guix build utils)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages python))

;; Exact Liberation Fonts 1.7 notice for the unmodified
;; LiberationMono-Bold.ttf shipped by the fixed upstream snapshot.
(define liberation-mono-license
  (local-file "../licenses/liberation-font-license-1.7.txt"))

(define-public aquarium-arena
  (package
    (name "aquarium-arena")
    ;; This is the 0.4 release commit.  Upstream's master points at the same
    ;; revision, but the codeload URL below is immutable and does not depend
    ;; on that mutable branch or the release's pre-built archives.
    (version "0.4-0.6d494c")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/valrak/AquariumRL/tar.gz/"
             "6d494cee8d45f734eaecd56237f33aaec37a0ed8"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "05sbb877kbp7qfa6pqh3ym6i70m41cl3bahiamdkzhc7mwvvljp2"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'port-to-python3
            (lambda _
              (use-modules (guix build utils))
              ;; This fixed snapshot is Python 2-era code.  These are the
              ;; complete syntax/API changes needed for Python 3.  The other
              ;; divisions deliberately retain floating point scale factors.
              (substitute* "mapField.py"
                (("except IndexError, e:") "except IndexError as e:")
                (("print \"index error at coordinates:\", coord, \"Exception: \", e")
                 "print(\"index error at coordinates:\", coord, \"Exception: \", e)")
                (("maxx \\* maxy / rockamountr") "maxx * maxy // rockamountr")
                (("maxx\\*maxy/95") "maxx*maxy//95")
                (("maxx\\*maxy/60") "maxx*maxy//60")
                (("maxx\\*maxy/70") "maxx*maxy//70")
                (("item\\.has_key\\(\"rarity\"\\)") "\"rarity\" in item"))
              (substitute* "gameEngine.py"
                (("params\\.has_key\\(\"flags\"\\)") "\"flags\" in params")
                (("params\\.has_key\\(\"upgradelevel\"\\)") "\"upgradelevel\" in params"))
              (substitute* "pathfinder.py"
                (("deltax / 2") "deltax // 2")
                (("is not 0") "!= 0"))
              (substitute* "mapField.py"
                (("monster.getparam\\(\\\"hp\\\"\\) <= 0")
                 "int(monster.getparam(\"hp\")) <= 0"))
              (substitute* "monster.py"
                (("int\\(weapon.getparam\\(\\\"damage\\\"\\) > 0\\)")
                 "int(weapon.getparam(\"damage\")) > 0")
                (("self.getparam\\(\\\"hp\\\"\\) <= 0")
                 "int(self.getparam(\"hp\")) <= 0"))
              (substitute* "graphicsHandler.py"
                (("bigtilestep / 2") "bigtilestep // 2")
                (("int\\(maxhp\\) / 5") "int(maxhp) // 5")
                (("RESOLUTIONX / 2") "RESOLUTIONX // 2"))))
          (add-after 'port-to-python3 'use-immutable-data-and-xdg-state
            (lambda _
              (use-modules (guix build utils))
              ;; Data is not found relative to the caller's directory: that
              ;; would make an installed game depend on a writable cwd.
              (substitute* "gameEngine.py"
                (("import sys") "import sys\nimport os")
                (("mapmaxx = 0")
                 (string-append "DATA_ROOT = " (object->string #$output)
                                " + \"/share/aquarium-arena\"\n\nmapmaxx = 0"))
                (("\"resources/data/creatures.jsn\"")
                 "os.path.join(DATA_ROOT, \"resources/data/creatures.jsn\")")
                (("\"resources/data/map.jsn\"")
                 "os.path.join(DATA_ROOT, \"resources/data/map.jsn\")")
                (("\"resources/data/effects.jsn\"")
                 "os.path.join(DATA_ROOT, \"resources/data/effects.jsn\")")
                (("\"resources/data/items.jsn\"")
                 "os.path.join(DATA_ROOT, \"resources/data/items.jsn\")")
                (("\"config/keystrokes.jsn\"")
                 "os.path.join(DATA_ROOT, \"config/keystrokes.jsn\")")
                (("\"config/settings.jsn\"")
                 "os.path.join(DATA_ROOT, \"config/settings.jsn\")")
                (("\"resources/texts/helpScreen.txt\"")
                 "os.path.join(DATA_ROOT, \"resources/texts/helpScreen.txt\")")
                (("\"resources/texts/helpBox.txt\"")
                 "os.path.join(DATA_ROOT, \"resources/texts/helpBox.txt\")")
                (("\"resources/maps/arena1.csv\"")
                 "os.path.join(DATA_ROOT, \"resources/maps/arena1.csv\")"))
              (substitute* "graphicsHandler.py"
                (("import pathfinder") "import pathfinder\nimport os")
                (("\"resources/img/MapTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/MapTiles.png\")")
                (("\"resources/img/CreatureTiles.png\"")
                 (string-append "os.path.join(gameEngine.DATA_ROOT, "
                                "\"resources/img/CreatureTiles.png\")"))
                (("\"resources/img/BigCreatureTiles.png\"")
                 (string-append "os.path.join(gameEngine.DATA_ROOT, "
                                "\"resources/img/BigCreatureTiles.png\")"))
                (("\"resources/img/EffectTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/EffectTiles.png\")")
                (("\"resources/img/ItemTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/ItemTiles.png\")")
                (("\"resources/img/UI.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/UI.png\")")
                (("\"resources/img/watch.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/watch.png\")")
                (("\"\\./resources/fonts/FreeMonoBold\\.ttf\"")
                 (string-append "os.path.join(gameEngine.DATA_ROOT, "
                                "\"resources/fonts/FreeMonoBold.ttf\")"))
                (("'resources/img/helpscreen\\.png'")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/helpscreen.png\")"))
              ;; The only mutable upstream file was a cwd-relative hiscore.
              ;; Keep it below XDG_DATA_HOME (or the normal XDG fallback),
              ;; never in the immutable application tree.
              (call-with-output-file "hiscore.py"
                (lambda (port)
                  (display
                   (string-append
                    "import os\n\n"
                    "def hiscore_path():\n"
                    "    root = os.environ.get('XDG_DATA_HOME')\n"
                    "    if not root:\n"
                    "        root = os.path.join(os.path.expanduser('~'), "
                    "'.local', 'share')\n"
                    "    directory = os.path.join(root, 'aquarium-arena')\n"
                    "    if not os.path.isdir(directory):\n"
                    "        os.makedirs(directory)\n"
                    "    return os.path.join(directory, 'hiscore')\n\n"
                    "def loadhiscore():\n"
                    "    try:\n"
                    "        with open(hiscore_path(), 'r') as score_file:\n"
                    "            return score_file.readline()\n"
                    "    except IOError:\n"
                    "        return 0\n\n"
                    "def savehiscore(score, hiscore):\n"
                    "    if score == '':\n"
                    "        score = 0\n"
                    "    if hiscore == '':\n"
                    "        hiscore = 0\n"
                    "    if int(hiscore) < int(score):\n"
                    "        with open(hiscore_path(), 'w') as score_file:\n"
                    "            score_file.write(str(score))\n"
                    "        return True\n"
                    "    return False\n")
                   port)))
              ;; The smoke entry point is intentionally inside the installed
              ;; program: it uses the same imports, data and pygame backend.
              (substitute* "AquariumArena.py"
                (("from gameEngine import GameEngine")
                 "from gameEngine import GameEngine\nimport sys")
                (("    ge = GameEngine\\(\\)")
                 (string-append
                  "    if sys.argv[1:] == ['--guix-smoke']:\n"
                  "        GameEngine(smoke=True)\n"
                  "        print('aquarium-arena isolated smoke passed')\n"
                  "    elif len(sys.argv) == 1:\n"
                  "        GameEngine()\n"
                  "    else:\n"
                  "        raise SystemExit('usage: aquarium-arena [--guix-smoke]')")))
              (substitute* "gameEngine.py"
                (("def __init__\\(self\\):")
                 (string-append
                  "def __init__(self, smoke=False):\n"
                  "        if smoke:\n"
                  "            import random\n"
                  "            random.seed(656)"))
                (("        self.cursorcoord = \\(1, 1\\)")
                 "        self.smoke = smoke\n        self.cursorcoord = (1, 1)")
                (("        self.mapfield.generatelevel\\(self.MAPMAXX, self.MAPMAXY\\)")
                 "        self.mapfield.generatelevel(self.MAPMAXX, self.MAPMAXY)")
                (("        self.graphicshandler = GraphicsHandler\\(self\\)")
                 "        self.graphicshandler = GraphicsHandler(self)")
                (("        self.messagehandler = MessageHandler\\(\\)" )
                 "        pygame.init()\n        self.messagehandler = MessageHandler()")
                (("        self.loop\\(\\)")
                 "        self._maybe_smoke_loop()")
                (("    def initgame\\(self\\):")
                 (string-append
                  "    def _maybe_smoke_loop(self):\n"
                  "        if self.smoke:\n"
                  "            self.run_smoke()\n"
                  "        else:\n"
                  "            self.loop()\n\n"
                  "    def run_smoke(self):\n"
                  "        player = self.initgame()\n"
                  "        self.deepblue = 0\n"
                  "        self.draw()\n"
                  "        pygame.image.load(os.path.join(DATA_ROOT, "
                  "'resources/img/helpscreen.png'))\n"
                  "        pygame.font.Font(os.path.join(DATA_ROOT, "
                  "'resources/fonts/LiberationMono-Bold.ttf'), 16)\n"
                  "        start = player.getposition()\n"
                  "        for delta in ((1, 0), (-1, 0), (0, 1), (0, -1)):\n"
                  "            target = (start[0] + delta[0], start[1] + delta[1])\n"
                  "            if self.mapfield.ispassable(target):\n"
                  "                player.action(target)\n"
                  "                break\n"
                  "        else:\n"
                  "            raise RuntimeError('smoke arena has no adjacent "
                  "passable tile')\n"
                  "        if player.getposition() == start:\n"
                  "            raise RuntimeError('smoke player action did not "
                  "move')\n"
                  "        self.passturn()\n"
                  "        if self.turns != 1:\n"
                  "            raise RuntimeError('smoke action did not execute "
                  "a turn')\n"
                  "        if not savehiscore(17, loadhiscore()) or "
                  "str(loadhiscore()).strip() != '17':\n"
                  "            raise RuntimeError('smoke high score did not "
                  "persist')\n"
                  "        screenshot = os.environ.get("
                  "'AQUARIUM_ARENA_SMOKE_SCREENSHOT')\n"
                  "        if screenshot:\n"
                  "            pygame.image.save(self.graphicshandler.finalscreen, "
                  "screenshot)\n"
                  "        pygame.quit()\n\n"
                  "    def initgame(self):")))))
          (add-after 'use-immutable-data-and-xdg-state 'check
            (lambda* (#:key tests? #:allow-other-keys)
              ;; Upstream has no test suite.  Compile every installed module
              ;; and verify the complete runtime asset set before installation.
              (when tests?
                (use-modules (guix build utils))
                (apply invoke
                       (append (list "python3" "-m" "py_compile")
                               (find-files "." "\\.py$")))
                (for-each (lambda (file)
                            (unless (file-exists? file)
                              (error "missing Aquarium Arena runtime asset" file)))
                          '("resources/img/BigCreatureTiles.png"
                            "resources/img/CreatureTiles.png"
                            "resources/img/EffectTiles.png"
                            "resources/img/ItemTiles.png"
                            "resources/img/MapTiles.png"
                            "resources/img/UI.png"
                            "resources/img/helpscreen.png"
                            "resources/img/watch.png"
                            "resources/fonts/FreeMonoBold.ttf"
                            "resources/fonts/LiberationMono-Bold.ttf"
                            "resources/data/creatures.jsn"
                            "resources/data/effects.jsn"
                            "resources/data/items.jsn"
                            "resources/data/map.jsn"
                            "config/keystrokes.jsn"
                            "config/settings.jsn")))))
          (add-after 'check 'remove-check-bytecode
            (lambda _
              ;; py_compile is a compatibility check, not an installed asset.
              (for-each delete-file-recursively
                        (find-files "." "__pycache__$" #:directories? #t))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/aquarium-arena"))
                     (doc (string-append out "/share/doc/aquarium-arena"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/aquarium-arena")))
                (copy-recursively "." data)
                (mkdir-p doc)
                (mkdir-p bin)
                (for-each (lambda (file) (copy-file file (string-append doc "/" file)))
                          '("LICENSE.md" "README.md" "changelog.txt"))
                ;; FreeMonoBold.ttf is the unmodified GNU FreeFont 20120503
                ;; file.  Install that source release's COPYING verbatim.
                (copy-file
                 (string-append #$font-gnu-freefont
                                "/share/doc/font-gnu-freefont-20120503/COPYING")
                 (string-append doc "/FreeMono-COPYING"))
                ;; LiberationMono-Bold.ttf is the unmodified 1.07.4 font.
                ;; Preserve its exact historical Liberation 1.7 license text.
                (copy-file #$liberation-mono-license
                           (string-append doc "/LiberationMono-LICENSE"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\n"
                      "case \"$#\" in\n"
                      "  0) ;;\n"
                      "  1) test \"$1\" = --guix-smoke || { echo 'usage: "
                      "aquarium-arena [--guix-smoke]' >&2; exit 64; } ;;\n"
                      "  *) echo 'usage: aquarium-arena [--guix-smoke]' >&2; "
                      "exit 64 ;;\n"
                      "esac\n"
                      "export PYTHONDONTWRITEBYTECODE=1 PYTHONNOUSERSITE=1 "
                      "PYGAME_HIDE_SUPPORT_PROMPT=1\n"
                      "export PYTHONPATH=" #$python-pygame
                      "/lib/python3.12/site-packages\n"
                      "exec " #$python "/bin/python3 " data "/AquariumArena.py \"$@\"\n")
                     port)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal python python-pygame))
    ;; The matching FreeFont 20120503 release supplies its exact COPYING;
    ;; it is copied into the package and is not a runtime dependency.
    (native-inputs (list font-gnu-freefont))
    (synopsis "Underwater arena roguelike")
    (description
     "Aquarium Arena is a graphical, turn-based roguelike set in an underwater
arena.  The package builds from the fixed 0.4 source snapshot, provides the
pygame runtime from Guix, installs its art and configuration as immutable data,
and stores only high scores in the user's XDG data directory.  It contains no
network updater or runtime download mechanism.")
    (home-page "https://github.com/valrak/AquariumRL")
    ;; The application and its repository-local art/data are GPL-2.0.  Its
    ;; unmodified FreeMono font is GPL-3.0-or-later with the GNU font
    ;; exception, and its unmodified Liberation Mono font is GPL-2.0 with the
    ;; documented embedding and physical-product exceptions; their notices
    ;; are installed in share/doc.
    (license (list license:gpl2 license:gpl3+))))
