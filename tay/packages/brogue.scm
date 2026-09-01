;;; GNU Guix package for Brogue Community Edition.

(define-module (tay packages brogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages sdl))

(define-public brogue
  (package
    (name "brogue")
    (version "1.15.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/tmewett/BrogueCE")
             (commit "1ba4240b7a928ddf0ffb772717bf1d433cd63804")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the tracked v1.15.1 tag tree.  Git metadata is
       ;; excluded from this value.
       (sha256
        (base32 "031qj38vnsjgc9qjkkqa8z6z3vkfm5zx2djk25hdrash31l37s3b"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream regression harness refers to recording directories that
      ;; are not shipped in this release.  The available seed-catalog checks
      ;; are run against a copied build tree by the channel smoke workflow.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'install-license-files)
          (replace 'build
            (lambda _
              (invoke "make"
                      "CC=gcc"
                      "RELEASE=YES"
                      "GRAPHICS=YES"
                      "TERMINAL=YES"
                      (string-append "CPPFLAGS=-I"
                                     #$(file-append sdl2-image "/include/SDL2"))
                      (string-append "DATADIR=" #$output "/share/brogue")
                      "bin/brogue")))
          (add-after 'build 'check-seed-catalogs
            (lambda _
              ;; The upstream comparison helper writes its generated catalog
              ;; in the current directory and expects ./brogue.  Run it from
              ;; a copy so the source checkout remains a clean test input.
              (let* ((source (getcwd))
                     (copy (string-append source "-seed-catalog-check")))
                (copy-recursively source copy)
                (chdir copy)
                (copy-file "bin/brogue" "brogue")
                (chmod "brogue" #o555)
                (invoke #$(file-append python "/bin/python3")
                        "test/compare_seed_catalog.py"
                        "test/seed_catalogs/seed_catalog_brogue.txt"
                        "40")
                (invoke #$(file-append python "/bin/python3")
                        "test/compare_seed_catalog.py"
                        "test/seed_catalogs/seed_catalog_rapid_brogue.txt"
                        "10"
                        "--extra_args=--variant rapid_brogue"))))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/brogue"))
                     (assets (string-append data "/assets"))
                     (doc (string-append out "/share/doc/brogue"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/brogue"))
                     (runner (string-append libexec
                                            "/brogue-smoke-runner.py"))
                     (launcher (string-append bin "/brogue")))
                (mkdir-p assets)
                (mkdir-p doc)
                (mkdir-p libexec)
                (mkdir-p bin)
                ;; Keep the binary immutable and private to the wrapper.  The
                ;; program receives the immutable data directory explicitly.
                ;; install-file takes a destination directory, so place the
                ;; executable directly in libexec rather than creating a
                ;; directory named after it.
                (install-file "bin/brogue" libexec)
                (for-each (lambda (file)
                            (install-file file assets))
                          '("bin/assets/tiles.png" "bin/assets/tiles.bin"))
                (install-file "bin/keymap.txt" data)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("README.md" "CHANGELOG.md" "LICENSE.txt"))
                (install-file "bin/assets/LICENSE.txt"
                              (string-append doc "/assets"))
                ;; This helper is only used by the package-owned smoke mode;
                ;; it drives the installed terminal frontend through a PTY.
                (call-with-output-file runner
                  (lambda (port)
                    (format port "#!~a~%"
                            #$(file-append python "/bin/python3"))
                    (display "import errno\nimport fcntl\nimport os\n" port)
                    (display "import pty\nimport select\nimport signal\n" port)
                    (display "import struct\nimport sys\nimport termios\n" port)
                    (display "import re\nimport time\nfrom pathlib import Path\n\n" port)
                    (display "program, *args = sys.argv[1:]\n" port)
                    (display "pid, master = pty.fork()\n" port)
                    (display "if pid == 0:\n" port)
                    (display "    os.execv(program, [program, *args])\n\n" port)
                    ;; Brogue's fixed terminal layout is 100 columns by 34
                    ;; rows.  Setting the PTY size prevents a host terminal
                    ;; from changing the exercised UI.
                    (display "fcntl.ioctl(master, termios.TIOCSWINSZ,\n" port)
                    (display "             struct.pack('HHHH', 34, 100, 0, 0))\n" port)
                    (display "seen = bytearray()\nstage = bytearray()\n" port)
                    (display "visible_stage = bytearray()\n" port)
                    (display "evidence = bytearray()\n" port)
                    (display "sent_move = False\nsent_quit = False\n" port)
                    (display "sent_confirm = False\nsent_continue = False\n" port)
                    (display "sent_record = False\n" port)
                    (display "sent_final = False\nsent_menu_quit = False\n" port)
                    (display "menu_seen_new = False\nmenu_seen_quit = False\n" port)
                    (display "deadline = time.monotonic() + 20\n" port)
                    (display "move_at = None\n\n" port)
                    (display "reaped = False\n" port)
                    (display "def fail(message):\n" port)
                    (display "    try:\n        os.kill(pid, signal.SIGTERM)\n" port)
                    (display "    except ProcessLookupError:\n        pass\n" port)
                    (display "    os.waitpid(pid, 0)\n" port)
                    (display "    raise SystemExit(message)\n\n" port)
                    (display "def visible(data):\n" port)
                    (display "    return re.sub(rb'\\x1b(?:\\[[0-?]*[ -/]*[@-~]|[()][0-9A-Za-z]+)', b'', data)\n\n" port)
                    (display "while True:\n" port)
                    (display "    if time.monotonic() >= deadline:\n" port)
                    (display "        fail('Brogue PTY smoke timed out')\n" port)
                    (display "    ready, _, _ = select.select([master], [], [], 0.2)\n" port)
                    (display "    if ready:\n" port)
                    (display "        try:\n            chunk = os.read(master, 8192)\n" port)
                    (display "        except OSError as error:\n" port)
                    (display "            if error.errno == errno.EIO:\n                break\n" port)
                    (display "            raise\n" port)
                    (display "        if not chunk:\n            break\n" port)
                    (display "        os.write(1, chunk)\n" port)
                    (display "        seen.extend(chunk)\n" port)
                    (display "        del seen[:-65536]\n" port)
                    (display "        if len(evidence) < 65536:\n" port)
                    (display "            evidence.extend(chunk[:65536 - len(evidence)])\n" port)
                    (display "        stage.extend(chunk)\n" port)
                    (display "        del stage[:-65536]\n" port)
                    (display "        visible_stage.extend(visible(chunk))\n" port)
                    (display "        del visible_stage[:-65536]\n" port)
                    (display "    lower = bytes(seen).lower()\n" port)
                    (display "    stage_lower = bytes(stage).lower()\n" port)
                    (display "    visible_lower = bytes(visible_stage).lower()\n" port)
                    ;; HP and Depth occur only after the actual dungeon
                    ;; screen is displayed; l is a legal Brogue movement key.
                    (display "    if (not sent_move and (b'hp' in lower or b'health' in lower)\n" port)
                    (display "            and (b'depth' in lower or b'level' in lower)):\n" port)
                    (display "        os.write(master, b'l')\n" port)
                    (display "        sent_move = True\n" port)
                    (display "        move_at = time.monotonic()\n" port)
                    (display "        stage.clear()\n" port)
                    (display "        visible_stage.clear()\n" port)
                    (display "    if (sent_move and not sent_quit\n" port)
                    (display "            and time.monotonic() - move_at >= 0.4):\n" port)
                    (display "        os.write(master, b'Q')\n" port)
                    (display "        sent_quit = True\n" port)
                    (display "        stage.clear()\n" port)
                    (display "        visible_stage.clear()\n" port)
                    (display "    if (sent_quit and not sent_confirm\n" port)
                    (display "            and all(word in visible_lower\n" port)
                    (display "                    for word in (b'quit', b'abandon', b'game'))):\n" port)
                    (display "        os.write(master, b'y')\n" port)
                    (display "        sent_confirm = True\n" port)
                    ;; A successful quit with a positive score shows the
                    ;; high-score page before asking where to save the
                    ;; recording.  Acknowledge that normal screen too.
                    (display "    if (sent_confirm and not sent_continue\n" port)
                    (display "            and b'space to continue' in visible_lower):\n" port)
                    (display "        os.write(master, b' ')\n" port)
                    (display "        sent_continue = True\n" port)
                    (display "    if (sent_continue and not sent_record\n" port)
                    (display "            and b'save recording as' in visible_lower):\n" port)
                    (display "        os.write(master, b'\\r')\n" port)
                    (display "        sent_record = True\n" port)
                    (display "        stage.clear()\n" port)
                    (display "        visible_stage.clear()\n" port)
                    ;; The recording is followed by another high-score page;
                    ;; acknowledge it and then leave the main menu so the
                    ;; smoke process has a deterministic successful exit.
                    (display "    if (sent_record and not sent_final\n" port)
                    (display "            and b'space to continue' in visible_lower):\n" port)
                    (display "        os.write(master, b' ')\n" port)
                    (display "        sent_final = True\n" port)
                    (display "        stage.clear()\n" port)
                    (display "        visible_stage.clear()\n" port)
                    (display "    if sent_final:\n" port)
                    (display "        menu_seen_new = menu_seen_new or b'new game' in visible_lower\n" port)
                    (display "        menu_seen_quit = menu_seen_quit or b'quit' in visible_lower\n" port)
                    (display "    if (sent_final and not sent_menu_quit\n" port)
                    (display "            and menu_seen_new and menu_seen_quit):\n" port)
                    (display "        os.write(master, b'Q')\n" port)
                    (display "        sent_menu_quit = True\n" port)
                    (display "        stage.clear()\n" port)
                    (display "        visible_stage.clear()\n" port)
                    (display "    finished, status = os.waitpid(pid, os.WNOHANG)\n" port)
                    (display "    if finished:\n        reaped = True\n        break\n\n" port)
                    (display "if not reaped:\n    _, status = os.waitpid(pid, 0)\n" port)
                    (display "os.close(master)\n" port)
                    (display "if not (sent_move and sent_quit and sent_confirm\n" port)
                    (display "        and sent_continue\n" port)
                    (display "        and sent_record and sent_final\n" port)
                    (display "        and sent_menu_quit):\n" port)
                    (display "    raise SystemExit('Brogue PTY smoke missed an input state')\n" port)
                    (display "if not os.WIFEXITED(status) or os.WEXITSTATUS(status):\n" port)
                    (display "    raise SystemExit('Brogue exited unsuccessfully')\n" port)
                    (display "text = (bytes(evidence) + bytes(seen)).decode('utf-8', 'replace')\n" port)
                    (display "assert 'Dungeons of Doom' in text, text[-4096:]\n" port)
                    (display "assert ('HP' in text or 'Health' in text), text[-4096:]\n" port)
                    (display "assert ('Depth' in text or 'Level' in text), text[-4096:]\n" port)
                    (display "assert '@' in text, text[-4096:]\n" port)
                    (display "recordings = list(Path.cwd().rglob('*.broguerec'))\n" port)
                    (display "assert recordings, 'no recording was created'\n" port)
                    (display "root = Path.cwd().resolve()\n" port)
                    (display "assert all(path.resolve().is_relative_to(root)\n" port)
                    (display "               for path in recordings), recordings\n" port)))
                (chmod runner #o555)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%"
                            #$bash-minimal)
                    (format port "program=~s~%data=~s~%keymap=~s~%output=~s~%"
                            program data (string-append data "/keymap.txt") out)
                    (format port "cp=~s~%mkdir=~s~%mktemp=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp"))
                    (format port "python=~s~%runner=~s~%"
                            #$(file-append python "/bin/python3") runner)
                    (display "state=\"${XDG_STATE_HOME:-${HOME:?HOME or XDG_STATE_HOME must be set}/.local/state}/brogue\"\n" port)
                    (display "if test \"${1:-}\" = --guix-smoke && test \"$#\" -eq 1; then\n" port)
                    (display "  scratch=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/brogue-smoke.XXXXXXXX\")\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\" \"$scratch/cache\"\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/data\" \"$scratch/state\" \"$scratch/runtime\" \"$scratch/tmp\"\n" port)
                    (display "  export HOME=\"$scratch/home\"\n" port)
                    (display "  export XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display "  export XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display "  export XDG_DATA_HOME=\"$scratch/data\"\n" port)
                    (display "  export XDG_STATE_HOME=\"$scratch/state\"\n" port)
                    (display "  export XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display "  export TMPDIR=\"$scratch/tmp\" TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  \"$mkdir\" -p \"$XDG_STATE_HOME/brogue\"\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$XDG_STATE_HOME/brogue/keymap.txt\"\n" port)
                    (display "  cd \"$XDG_STATE_HOME/brogue\"\n" port)
                    (display "  if ! \"$python\" \"$runner\" \"$program\" -t -s 1 -n --data-dir \"$data\" >\"$scratch/ui.raw\"; then\n" port)
                    (display "    if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n" port)
                    (display "      \"$cp\" \"$scratch/ui.raw\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "    fi\n" port)
                    (display "    exit 1\n" port)
                    (display "  fi\n" port)
                    (display "  test -s \"$scratch/ui.raw\"\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n" port)
                    (display "    \"$cp\" \"$scratch/ui.raw\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    (display "  test ! -w \"$output\"\n" port)
                    (display "  printf '%s\\n' 'brogue isolated smoke passed'\n" port)
                    (display "  exit 0\nfi\n" port)
                    ;; Always append the immutable path so an argument cannot
                    ;; redirect the graphical resource lookup elsewhere.
                    (display "\"$mkdir\" -p \"$state\"\n" port)
                    (display "if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$state/keymap.txt\"\nfi\n" port)
                    (display "cd \"$state\"\n" port)
                    (display "exec \"$program\" \"$@\" --data-dir \"$data\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list diffutils gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal ncurses python sdl2
                  sdl2-image))
    (home-page "https://github.com/tmewett/BrogueCE")
    (synopsis "Turn-based dungeon exploration game")
    (description
     "Brogue Community Edition is a minimalist turn-based dungeon exploration
game.  This package builds the fixed upstream source with both its graphical
SDL2 frontend and its ncurses terminal frontend.  The launcher keeps saves,
recordings, scores, run history, and diagnostics in an XDG state directory,
copies the user-editable keymap there, and passes the immutable packaged asset
directory explicitly to the binary.  The web frontend is not built and the
package performs no updater, telemetry, runtime-download, or network action.")
    ;; The engine and variants carry AGPL-3.0-or-later; the platform files
    ;; explicitly carry GPL-3.0-or-later.  tiles.png and its derived cache are
    ;; covered by bin/assets/LICENSE.txt under CC BY-SA 4.0.
    (license (list license:agpl3+ license:gpl3+ license:cc-by-sa4.0))))
