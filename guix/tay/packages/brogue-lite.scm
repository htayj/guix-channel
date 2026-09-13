;;; GNU Guix package for Brogue Lite.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages brogue-lite)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python))

(define-public brogue-lite
  (package
    (name "brogue-lite")
    ;; Maintained master after the Lite-v1.11.1-RC2 tag.  This revision is
    ;; the Brogue CE 1.13 merge with the later Lite probability fixes.
    (version "1.13-0.20240105")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/HomebrewHomunculus/BrogueCE")
             (commit "8ee03a62f7787a796678553fd4f2d27a388f695f")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the fixed source checkout.  The separate git
       ;; archive hash is 5a39eb52bd093c37b1f2bdf983717feb30e9bbe3302b5ab6100e003e48bd792a.
       (sha256
        (base32 "014pvbb5q4znqmgky5wm9fi05x40mc5k5p19hn07kfl5jzwjvc0i"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Upstream ships only test/run_regression_tests.py at this revision;
      ;; its recording directory is not part of the source checkout.  The
      ;; installed terminal frontend is exercised by brogue-lite-smoke.sh.
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
                      "GRAPHICS=NO"
                      "TERMINAL=YES"
                      "WEBBROGUE=NO"
                      (string-append "DATADIR=" #$output "/share/brogue-lite")
                      "bin/brogue")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/brogue-lite"))
                     (doc (string-append out "/share/doc/brogue-lite"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/brogue-lite"))
                     (runner (string-append libexec
                                             "/brogue-lite-smoke-runner.py"))
                     (launcher (string-append bin "/brogue-lite")))
                (mkdir-p data)
                (mkdir-p doc)
                (mkdir-p libexec)
                (mkdir-p bin)
                ;; The terminal build has no graphical resource dependency.
                ;; Keep the executable private to the wrapper so every normal
                ;; invocation receives the immutable data directory explicitly.
                (install-file "bin/brogue" libexec)
                (rename-file (string-append libexec "/brogue") program)
                (install-file "bin/keymap.txt" data)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("README.md" "CHANGELOG.md" "CHANGELOG_LITE.md"
                            "LICENSE.txt"))
                ;; This notice documents the omitted CC BY-SA tile assets and
                ;; is retained with the other upstream licensing information.
                (install-file "bin/assets/LICENSE.txt"
                              (string-append doc "/assets"))
                ;; The smoke mode is package-owned and drives the real binary
                ;; through a fixed-size PTY.  It also verifies that a recording
                ;; is created below the private scratch tree.
                (call-with-output-file runner
                  (lambda (port)
                    (display "#!" port)
                    (display #$(file-append python "/bin/python3") port)
                    (display "\nimport errno\nimport fcntl\nimport os\n" port)
                    (display "import pty\nimport re\nimport select\n" port)
                    (display "import signal\nimport struct\nimport sys\n" port)
                    (display "import termios\nimport time\nfrom pathlib import Path\n\n" port)
                    (display "program, *args = sys.argv[1:]\n" port)
                    (display "pid, master = pty.fork()\n" port)
                    (display "if pid == 0:\n" port)
                    (display "    os.execv(program, [program, *args])\n\n" port)
                    ;; Brogue's terminal layout is 100 columns by 34 rows.
                    (display "fcntl.ioctl(master, termios.TIOCSWINSZ,\n" port)
                    (display "             struct.pack('HHHH', 34, 100, 0, 0))\n" port)
                    (display "seen = bytearray()\npost_quit = bytearray()\n" port)
                    (display "post_record = bytearray()\n" port)
                    (display "sent_move = False\nsent_quit = False\n" port)
                    (display "sent_confirm = False\nsent_continue = False\n" port)
                    (display "sent_record = False\nsent_menu_quit = False\n" port)
                    (display "reaped = False\nmove_at = None\n" port)
                    (display "deadline = time.monotonic() + 30\n\n" port)
                    (display "def terminate(message):\n" port)
                    (display "    if not reaped:\n" port)
                    (display "        try:\n            os.kill(pid, signal.SIGTERM)\n" port)
                    (display "        except ProcessLookupError:\n            pass\n" port)
                    (display "        try:\n            os.waitpid(pid, 0)\n" port)
                    (display "        except ChildProcessError:\n            pass\n" port)
                    (display "    raise SystemExit(message)\n\n" port)
                    (display "def visible(data):\n" port)
                    (display "    return re.sub(rb'\\x1b(?:\\[[0-?]*[ -/]*[@-~]|" port)
                    (display "[()][0-9A-Za-z]+)', b'', data)\n\n" port)
                    (display "while True:\n" port)
                    (display "    if time.monotonic() >= deadline:\n" port)
                    (display "        terminate('Brogue Lite PTY smoke timed out')\n" port)
                    (display "    ready, _, _ = select.select([master], [], [], 0.2)\n" port)
                    (display "    if ready:\n" port)
                    (display "        try:\n            chunk = os.read(master, 8192)\n" port)
                    (display "        except OSError as error:\n" port)
                    (display "            if error.errno == errno.EIO:\n                break\n" port)
                    (display "            raise\n" port)
                    (display "        if not chunk:\n            break\n" port)
                    (display "        os.write(1, chunk)\n" port)
                    (display "        seen.extend(chunk)\n        del seen[:-131072]\n" port)
                    (display "        if sent_quit:\n            post_quit.extend(chunk)\n" port)
                    (display "        if sent_record:\n            post_record.extend(chunk)\n" port)
                    (display "    lower = bytes(seen).lower()\n" port)
                    (display "    visible_lower = visible(bytes(seen)).lower()\n" port)
                    (display "    quit_lower = visible(bytes(post_quit)).lower()\n" port)
                    (display "    record_lower = visible(bytes(post_record)).lower()\n" port)
                    ;; Wait until the actual dungeon screen exists, then make
                    ;; one legal movement before quitting the game.
                    (display "    if (not sent_move and b'dungeons of doom' in lower\n" port)
                    (display "            and (b'hp' in lower or b'health' in lower)\n" port)
                    (display "            and (b'depth' in lower or b'level' in lower)):\n" port)
                    (display "        os.write(master, b'l')\n        sent_move = True\n" port)
                    (display "        move_at = time.monotonic()\n\n" port)
                    (display "    if (sent_move and not sent_quit and\n" port)
                    (display "            time.monotonic() - move_at >= 0.5):\n" port)
                    (display "        os.write(master, b'Q')\n        sent_quit = True\n" port)
                    (display "        post_quit.clear()\n\n" port)
                    (display "    if (sent_quit and not sent_confirm and\n" port)
                    (display "            b'quit and abandon this game' in quit_lower):\n" port)
                    (display "        os.write(master, b'y')\n        sent_confirm = True\n\n" port)
                    ;; Saving the score presents a high-score page first on
                    ;; this revision; support both that path and a direct save
                    ;; prompt if no score page is shown.
                    (display "    if (sent_confirm and not sent_continue and\n" port)
                    (display "            b'space to continue' in quit_lower):\n" port)
                    (display "        os.write(master, b' ')\n        sent_continue = True\n\n" port)
                    (display "    if (sent_confirm and not sent_record and\n" port)
                    (display "            b'save recording as' in quit_lower):\n" port)
                    (display "        os.write(master, b'\\r')\n        sent_record = True\n" port)
                    (display "        post_record.clear()\n\n" port)
                    ;; Return from the recording prompt to the title menu and
                    ;; quit there, proving the complete game-to-menu lifecycle.
                    (display "    if (sent_record and not sent_menu_quit and\n" port)
                    (display "            b'new game' in record_lower and\n" port)
                    (display "            b'quit' in record_lower):\n" port)
                    (display "        os.write(master, b'Q')\n        sent_menu_quit = True\n\n" port)
                    (display "    finished, status = os.waitpid(pid, os.WNOHANG)\n" port)
                    (display "    if finished:\n        reaped = True\n        break\n\n" port)
                    (display "if not reaped:\n    _, status = os.waitpid(pid, 0)\n" port)
                    (display "os.close(master)\n" port)
                    (display "if not (sent_move and sent_quit and sent_confirm\n" port)
                    (display "        and sent_record and sent_menu_quit):\n" port)
                    (display "    raise SystemExit('Brogue Lite PTY smoke missed an input state')\n" port)
                    (display "if not os.WIFEXITED(status) or os.WEXITSTATUS(status):\n" port)
                    (display "    raise SystemExit('Brogue Lite exited unsuccessfully')\n" port)
                    (display "root = Path.cwd().resolve()\n" port)
                    (display "recordings = list(root.rglob('*.broguerec'))\n" port)
                    (display "assert recordings, 'no recording was created'\n" port)
                    (display "for path in recordings:\n" port)
                    (display "    assert os.path.commonpath((str(root), str(path.resolve()))) == str(root)\n" port)
                    (display "text = visible(bytes(seen)).decode('utf-8', 'replace')\n" port)
                    (display "assert 'Dungeons of Doom' in text, text[-4096:]\n" port)
                    (display "assert '@' in text, text[-4096:]\n" port)))
                (chmod runner #o555)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%"
                            #$bash-minimal)
                    (format port "program=~s~%data=~s~%keymap=~s~%output=~s~%"
                            program data (string-append data "/keymap.txt") out)
                    (format port "cp=~s~%mkdir=~s~%mktemp=~s~%find=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append findutils "/bin/find"))
                    (format port "python=~s~%runner=~s~%terminfo=~s~%"
                            #$(file-append python "/bin/python3") runner
                            #$(file-append ncurses "/share/terminfo"))
                    (display "state_root=\"${XDG_STATE_HOME:-${HOME:?HOME or XDG_STATE_HOME must be set}/.local/state}\"\n" port)
                    (display "state=\"$state_root/brogue-lite\"\n" port)
                    (display "prepare_environment() {\n" port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n" port)
                    (display "}\n" port)
                    (display "if test \"${1:-}\" = --guix-smoke && test \"$#\" -eq 1; then\n" port)
                    (display "  scratch=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/brogue-lite-smoke.XXXXXXXX\")\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\" \"$scratch/data\"\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/cache\" \"$scratch/state\" \"$scratch/runtime\" \"$scratch/tmp\"\n" port)
                    (display "  export HOME=\"$scratch/home\" XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display "  export XDG_DATA_HOME=\"$scratch/data\" XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display "  export XDG_STATE_HOME=\"$scratch/state\" XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display "  export TMPDIR=\"$scratch/tmp\" TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  state=\"$XDG_STATE_HOME/brogue-lite\"\n" port)
                    (display "  prepare_environment\n" port)
                    (display "  if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "    \"$cp\" \"$keymap\" \"$state/keymap.txt\"\n" port)
                    (display "  fi\n  cd \"$state\"\n" port)
                    (display "  \"$python\" \"$runner\" \"$program\" -t -s 1 -n --data-dir \"$data\" >\"$scratch/terminal.raw\"\n" port)
                    (display "  test -s \"$scratch/terminal.raw\"\n" port)
                    (display "  test -n \"$(\"$find\" \"$scratch\" -type f \\\n" port)
                    (display "    \\( -name '*.broguerec' -o -name '*.broguesave' -o -name '*HighScores.txt' \\\n" port)
                    (display "    -o -name 'RNGLog.txt' \\) -print -quit)\"\n" port)
                    (display "  test -z \"$(\"$find\" \"$output\" -xdev -type f -perm /222 -print -quit)\"\n" port)
                    (display "  test ! -w \"$output\"\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n" port)
                    (display "    \"$cp\" \"$scratch/terminal.raw\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    (display "  printf '%s\\n' 'brogue lite isolated smoke passed'\n" port)
                    (display "  exit 0\nfi\n" port)
                    (display "prepare_environment\n" port)
                    (display "if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$state/keymap.txt\"\nfi\n" port)
                    (display "cd \"$state\"\n" port)
                    ;; Appending this option last makes the resource path
                    ;; immutable even when a caller supplies another one.
                    (display "exec \"$program\" \"$@\" --data-dir \"$data\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal findutils ncurses python))
    (home-page "https://github.com/HomebrewHomunculus/BrogueCE")
    (synopsis "Casual terminal roguelike dungeon game")
    (description
     "Brogue Lite is a casual variant of Brogue Community Edition.  This
package builds the fixed HomebrewHomunculus source with its ncurses terminal
frontend only.  The launcher copies the user-editable keymap into an XDG state
directory, keeps saves, recordings, high scores, and RNG logs outside the
store, and always passes the immutable packaged data directory.  It performs
no network or runtime downloads.")
    ;; Most sources are AGPL-3.0-or-later; the retained legacy platform
    ;; implementation is GPL-3.0-or-later.  Graphical tile assets are omitted;
    ;; their CC BY-SA 4.0 notice is installed for provenance.
    (license (list license:agpl3+ license:gpl3+ license:cc-by-sa4.0))))
