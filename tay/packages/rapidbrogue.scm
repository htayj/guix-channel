;;; GNU Guix package for RapidBrogue.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages rapidbrogue)
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

(define-public rapidbrogue
  (package
    (name "rapidbrogue")
    (version "1.4.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/flend/RapidBrogue")
             (commit "02e6715fd81c4c9da1546943700da7b2b3ed482a")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the immutable rapid_brogue-v1.4.0 tag tree.
       (sha256
        (base32 "1j8qs94zgdf0rrn5j99r97q20xg27iivl5m27wnlga0iknzb9rhh"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream checkout has no self-contained non-interactive test
      ;; suite.  The installed terminal program is exercised by the
      ;; rapidbrogue-smoke.sh package proof.
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
                      "TERMINAL=YES"
                      "GRAPHICS=NO"
                      "WEBBROGUE=NO"
                      "RAPIDBROGUE=YES"
                      (string-append "DATADIR=" #$output "/share/rapidbrogue")
                      "bin/brogue")))
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/rapidbrogue"))
                     (doc (string-append out "/share/doc/rapidbrogue"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (program (string-append libexec "/rapidbrogue"))
                     (runner (string-append libexec
                                             "/rapidbrogue-smoke-runner.py"))
                     (launcher (string-append bin "/rapidbrogue")))
                (mkdir-p data)
                (mkdir-p doc)
                (mkdir-p libexec)
                (mkdir-p bin)
                ;; The terminal binary is private to the wrapper.  This keeps
                ;; the resource directory immutable and makes the working
                ;; directory used for mutable game state explicit.
                (install-file "bin/brogue" libexec)
                (rename-file (string-append libexec "/brogue") program)
                (install-file "bin/keymap.txt" data)
                (for-each (lambda (file)
                            (install-file file doc))
                          '("BUILD.md" "README.md" "CHANGELOG.md"
                            "LICENSE.txt"))
                ;; The graphical tile/icon files are deliberately omitted,
                ;; but their upstream provenance notice is retained.
                (install-file "bin/assets/LICENSE.txt"
                              (string-append doc "/assets"))
                ;; This helper is used only by --guix-smoke.  It drives the
                ;; actual terminal frontend in a fixed-size PTY and checks
                ;; the full quit/save lifecycle.
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
                    ;; RapidBrogue uses Brogue's fixed 100 by 34 terminal
                    ;; layout.  Do not let the host terminal affect it.
                    (display "fcntl.ioctl(master, termios.TIOCSWINSZ,\n" port)
                    (display "             struct.pack('HHHH', 34, 100, 0, 0))\n" port)
                    (display "seen = bytearray()\npost_quit = bytearray()\n" port)
                    (display "sent_move = False\nsent_quit = False\n" port)
                    (display "sent_confirm = False\nsent_continue = False\n" port)
                    (display "sent_record = False\nsent_final = False\n" port)
                    (display "sent_menu_quit = False\nreaped = False\n" port)
                    (display "sent_prompt_reply = False\n" port)
                    (display "move_at = None\ndeadline = time.monotonic() + 30\n\n" port)
                    (display "def fail(message):\n" port)
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
                    (display "        fail('RapidBrogue PTY smoke timed out')\n" port)
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
                    (display "    lower = bytes(seen).lower()\n" port)
                    (display "    quit_lower = visible(bytes(post_quit)).lower()\n" port)
                    ;; HP/health and depth/level appear on the actual dungeon
                    ;; screen.  h is one legal movement onto the floor tile
                    ;; immediately left of the fixed-seed starting position.
                    (display "    if (not sent_move and b'dungeons of doom' in lower\n" port)
                    (display "            and (b'hp' in lower or b'health' in lower)\n" port)
                    (display "            and (b'depth' in lower or b'level' in lower)):\n" port)
                    (display "        os.write(master, b'h')\n        sent_move = True\n" port)
                    (display "        move_at = time.monotonic()\n\n" port)

                    ;; The fixed seed can place the first step on a pressure
                    ;; plate.  Answer the resulting safe prompt so quit is
                    ;; handled by the gameplay screen rather than ignored.
                    (display "    if (sent_move and not sent_prompt_reply\n" port)
                    (display "            and b'step onto the pressure plate?' in lower):\n" port)
                    (display "        os.write(master, b'n')\n        sent_prompt_reply = True\n\n" port)
                    (display "    if (sent_move and not sent_quit\n" port)
                    (display "            and time.monotonic() - move_at >= 0.5):\n" port)
                    ;; Uppercase Q reaches the gameplay quit command in the
                    ;; upstream keymap and asks for confirmation.
                    (display "        os.write(master, b'Q')\n        sent_quit = True\n" port)
                    (display "        post_quit.clear()\n\n" port)
                    (display "    if (sent_quit and not sent_confirm\n" port)
                    (display "            and all(word in quit_lower for word in\n" port)
                    (display "                    (b'quit', b'abandon', b'game'))):\n" port)
                    (display "        os.write(master, b'y')\n        sent_confirm = True\n\n" port)
                    ;; A positive score first shows the high-score page and
                    ;; then asks where to save the recording.
                    (display "    if (sent_confirm and not sent_continue\n" port)
                    (display "            and b'space to continue' in quit_lower):\n" port)
                    (display "        os.write(master, b' ')\n        sent_continue = True\n\n" port)
                    (display "    if (sent_continue and not sent_record\n" port)
                    (display "            and b'save recording as' in quit_lower):\n" port)
                    (display "        os.write(master, b'\\r')\n        sent_record = True\n\n" port)
                    ;; The recording prompt is followed by another score page;
                    ;; acknowledge it before quitting the title menu.
                    (display "    if (sent_record and not sent_final\n" port)
                    (display "            and b'space to continue' in quit_lower):\n" port)
                    (display "        os.write(master, b' ')\n        sent_final = True\n\n" port)
                    (display "    if sent_final and not sent_menu_quit:\n" port)
                    (display "        menu = visible(bytes(seen)).lower()\n" port)
                    (display "        if b'new game' in menu and b'quit' in menu:\n" port)
                    (display "            os.write(master, b'Q')\n            sent_menu_quit = True\n\n" port)
                    (display "    finished, status = os.waitpid(pid, os.WNOHANG)\n" port)
                    (display "    if finished:\n        reaped = True\n        break\n\n" port)
                    (display "if not reaped:\n    _, status = os.waitpid(pid, 0)\n" port)
                    (display "os.close(master)\n" port)
                    (display "if not (sent_move and sent_quit and sent_confirm\n" port)
                    (display "        and sent_continue and sent_record and sent_final\n" port)
                    (display "        and sent_menu_quit):\n" port)
                    (display "    raise SystemExit('RapidBrogue PTY smoke missed an input state')\n" port)
                    (display "if not os.WIFEXITED(status) or os.WEXITSTATUS(status):\n" port)
                    (display "    raise SystemExit('RapidBrogue exited unsuccessfully')\n" port)
                    (display "root = Path.cwd().resolve()\n" port)
                    (display "recordings = list(root.rglob('*.broguerec'))\n" port)
                    (display "assert recordings, 'no recording was created'\n" port)
                    (display "for path in recordings:\n" port)
                    (display "    assert path.resolve().is_relative_to(root), recordings\n" port)
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
                    (display "state=\"$state_root/rapidbrogue\"\n" port)
                    (display "prepare_environment() {\n" port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n" port)
                    (display "}\n" port)
                    (display "if test \"${1:-}\" = --guix-smoke && test \"$#\" -eq 1; then\n" port)
                    (display "  scratch=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/rapidbrogue-smoke.XXXXXXXX\")\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\" \"$scratch/data\"\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/cache\" \"$scratch/state\" \"$scratch/runtime\" \"$scratch/tmp\"\n" port)
                    (display "  export HOME=\"$scratch/home\" XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display "  export XDG_DATA_HOME=\"$scratch/data\" XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display "  export XDG_STATE_HOME=\"$scratch/state\" XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display "  export TMPDIR=\"$scratch/tmp\" TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  state=\"$XDG_STATE_HOME/rapidbrogue\"\n" port)
                    (display "  prepare_environment\n" port)
                    (display "  if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "    \"$cp\" \"$keymap\" \"$state/keymap.txt\"\n" port)
                    (display "  fi\n  cd \"$state\"\n" port)
                    ;; Keep this child invocation exact: the proof exercises
                    ;; the package's fixed seed and new-game lifecycle.
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
                    (display "  printf '%s\\n' 'RAPIDBROGUE_GUIX_SMOKE_OK'\n" port)
                    (display "  exit 0\nfi\n" port)
                    (display "prepare_environment\n" port)
                    (display "if test ! -e \"$state/keymap.txt\"; then\n" port)
                    (display "  \"$cp\" \"$keymap\" \"$state/keymap.txt\"\nfi\n" port)
                    (display "cd \"$state\"\n" port)
                    ;; Put the immutable data option last on normal runs too.
                    (display "exec \"$program\" \"$@\" --data-dir \"$data\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list gcc-toolchain gnu-make))
    (inputs (list bash-minimal coreutils-minimal findutils ncurses python))
    (home-page "https://github.com/flend/RapidBrogue")
    (synopsis "Ten-level rapid variant of the Brogue terminal roguelike")
    (description
     "RapidBrogue is a Brogue Community Edition variant that compresses the
game into ten levels.  This package builds the fixed RapidBrogue source with
its ncurses terminal frontend only.  The launcher keeps the editable keymap,
saves, recordings, high scores, and RNG logs in an XDG state directory and
always passes the immutable packaged data directory.  It performs no network
or runtime downloads.  Graphical assets are omitted; their upstream
Creative Commons notice is retained in the documentation.")
    ;; The game sources include AGPL-3.0 and GPL-3.0 platform files.  The
    ;; omitted graphical assets carry the separate CC BY-SA 4.0 notice.
    (license (list license:agpl3+ license:gpl3+ license:cc-by-sa4.0))))
