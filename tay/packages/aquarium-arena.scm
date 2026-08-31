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
       (uri "https://codeload.github.com/valrak/AquariumRL/tar.gz/6d494cee8d45f734eaecd56237f33aaec37a0ed8")
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
                (("deltax / 2") "deltax // 2"))
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
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/CreatureTiles.png\")")
                (("\"resources/img/BigCreatureTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/BigCreatureTiles.png\")")
                (("\"resources/img/EffectTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/EffectTiles.png\")")
                (("\"resources/img/ItemTiles.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/ItemTiles.png\")")
                (("\"resources/img/UI.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/UI.png\")")
                (("\"resources/img/watch.png\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/img/watch.png\")")
                (("\"\\./resources/fonts/FreeMonoBold\\.ttf\"")
                 "os.path.join(gameEngine.DATA_ROOT, \"resources/fonts/FreeMonoBold.ttf\")")
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
                    "        root = os.path.join(os.path.expanduser('~'), '.local', 'share')\n"
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
                (("def __init__\\(self\\):") "def __init__(self, smoke=False):")
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
                  "        import random\n"
                  "        random.seed(656)\n"
                  "        player = self.initgame()\n"
                  "        self.deepblue = 0\n"
                  "        self.draw()\n"
                  "        pygame.image.load(os.path.join(DATA_ROOT, 'resources/img/helpscreen.png'))\n"
                  "        pygame.font.Font(os.path.join(DATA_ROOT, 'resources/fonts/LiberationMono-Bold.ttf'), 16)\n"
                  "        start = player.getposition()\n"
                  "        for delta in ((1, 0), (-1, 0), (0, 1), (0, -1)):\n"
                  "            target = (start[0] + delta[0], start[1] + delta[1])\n"
                  "            if self.mapfield.ispassable(target):\n"
                  "                player.action(target)\n"
                  "                break\n"
                  "        else:\n"
                  "            raise RuntimeError('smoke arena has no adjacent passable tile')\n"
                  "        if player.getposition() == start:\n"
                  "            raise RuntimeError('smoke player action did not move')\n"
                  "        self.passturn()\n"
                  "        if self.turns != 1:\n"
                  "            raise RuntimeError('smoke action did not execute a turn')\n"
                  "        if not savehiscore(17, loadhiscore()) or str(loadhiscore()).strip() != '17':\n"
                  "            raise RuntimeError('smoke high score did not persist')\n"
                  "        screenshot = os.environ.get('AQUARIUM_ARENA_SMOKE_SCREENSHOT')\n"
                  "        if screenshot:\n"
                  "            pygame.image.save(self.graphicshandler.finalscreen, screenshot)\n"
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
                ;; This is the exact historical Liberation 1.7 license text.
                (call-with-output-file (string-append doc "/LiberationMono-LICENSE")
                  (lambda (port)
                    (display "LICENSE AGREEMENT AND LIMITED PRODUCT WARRANTY\nLIBERATION FONT SOFTWARE\n\nThis agreement governs the use of the Software and any updates to the Software, regardless of the delivery mechanism. Subject to the following terms, Red Hat, Inc. (\"Red Hat\") grants to the user (\"Client\") a license to this work pursuant to the GNU General Public License v.2 with the exceptions set forth below and such other terms as are set forth in this End User License Agreement.\n\n 1. The Software and License Exception. LIBERATION font software  (the \"Software\") consists of TrueType-OpenType formatted font software for rendering LIBERATION typefaces in sans-serif, serif, and monospaced character styles. You are licensed to use, modify, copy, and distribute the Software pursuant to the GNU General Public License v.2 with the following exceptions:  \n\n  (a) As a special exception, if you create a document which uses this font, and embed this font or unaltered portions of this font into the document, this font does not by itself cause the resulting document to be covered by the GNU General Public License. This exception does not however invalidate any other reasons why the document might be covered by the GNU General Public License. If you modify this font, you may extend this exception to your version of the font, but you are not obligated to do so. If you do not wish to do so, delete this exception statement from your version.\n\n  (b) As a further exception, any distribution of the object code of the Software in a physical product must provide you the right to access and modify the source code for the Software and to reinstall that modified version of the Software in object code form on the same physical product on which you received it.\n\n 2. Intellectual Property Rights. The Software and each of its components, including the source code, documentation, appearance, structure and organization are owned by Red Hat and others and are protected under copyright and other laws. Title to the Software and any component, or to any copy, modification, or merged portion shall remain with the aforementioned, subject to the applicable license. The \"LIBERATION\" trademark is a trademark of Red Hat, Inc. in the U.S. and other countries. This agreement does not permit Client to distribute modified versions of the Software using Red Hat's trademarks. If Client makes a redistribution of a modified version of the Software, then Client must modify the files names to remove any reference to the Red Hat trademarks and must not use the Red Hat trademarks in any way to reference or promote the modified Software. \n\n 3. Limited Warranty. To the maximum extent permitted under applicable law, the Software is provided and licensed \"as is\" without warranty of any kind, expressed or implied, including the implied warranties of merchantability, non-infringement or fitness for a particular purpose. Red Hat does not warrant that the functions contained in the Software will meet Client's requirements or that the operation of the Software will be entirely error free or appear precisely as described in the accompanying documentation. \n\n 4. Limitation of Remedies and Liability. To the maximum extent permitted by applicable law, Red Hat or any Red Hat authorized dealer will not be liable to Client for any incidental or consequential damages, including lost profits or lost savings arising out of the use or inability to use the Software, even if Red Hat or such dealer has been advised of the possibility of such damages. \n\n 5. General. If any provision of this agreement is held to be unenforceable, that shall not affect the enforceability of the remaining provisions. This agreement shall be governed by the laws of the State of North Carolina and of the United States, without regard to any conflict of laws provisions, except that the United Nations Convention on the International Sale of Goods shall not apply.\nCopyright © 2007-2011 Red Hat, Inc. All rights reserved. LIBERATION is a trademark of Red Hat, Inc.\n" port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\n"
                      "case \"$#\" in\n"
                      "  0) ;;\n"
                      "  1) test \"$1\" = --guix-smoke || { echo 'usage: aquarium-arena [--guix-smoke]' >&2; exit 64; } ;;\n"
                      "  *) echo 'usage: aquarium-arena [--guix-smoke]' >&2; exit 64 ;;\n"
                      "esac\n"
                      "export PYTHONDONTWRITEBYTECODE=1 PYTHONNOUSERSITE=1 PYGAME_HIDE_SUPPORT_PROMPT=1\n"
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
