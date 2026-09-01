;;; GNU Guix package for the Bloatcrawl 2 terminal roguelike.

(define-module (tay packages bloatcrawl2)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sqlite))

(define-public bloatcrawl2
  (package
    (name "bloatcrawl2")
    ;; The Bloatcrawl 2.2.0 tag, published on 2020-01-01.
    (version "2.2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Hellmonk/bloatcrawl2")
             (commit "ff89137ce52d26b891517517c0aec9013ed8bea5")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the tracked tag tree.  Git metadata and gitlink
       ;; contents are absent: the terminal build uses Guix libraries.
       (sha256
        ;; Guix's origin base32 field uses nix-base32; this is the same
        ;; recursive tag checkout as the researched base32 digest.
        (base32 "194d8n8nh5q1hpj07plp7ifm6d7j28hagk1566wwy7ljnz36kqa6"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream test suite needs its own test harness and diagnostic
      ;; options.  The installed game is exercised by tests/bloatcrawl2-smoke.sh.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "crawl-ref/source")
              ;; git-fetch supplies no .git directory, so give Makefile's
              ;; documented version fallback the fixed upstream release.
              (call-with-output-file "util/release_ver"
                (lambda (port) (display "2.2.0\n" port)))))
          (replace 'build
            (lambda _
              ;; An empty TILES value selects the console build and avoids
              ;; SDL, fonts, sound, and the tile source tree.
              (invoke "make" "crawl"
                      (string-append "DATADIR=" #$output "/share/bloatcrawl2")
                      (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
                      "FORCE_CC=gcc" "FORCE_CXX=g++"
                      "LUA_PACKAGE=lua-5.1" "TILES=")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/bloatcrawl2"))
                     (doc (string-append #$output "/share/doc/bloatcrawl2"))
                     (libexec (string-append #$output "/libexec"))
                     (bin (string-append #$output "/bin"))
                     (program (string-append libexec "/bloatcrawl2"))
                     (smoke-runner
                      (string-append libexec "/bloatcrawl2-smoke-runner.py"))
                     (launcher (string-append bin "/bloatcrawl2")))
                ;; Upstream install also manages mutable paths.  install-data
                ;; only copies the immutable console assets and documentation.
                (invoke "make" "install-data"
                        ;; Upstream refuses install-data without a staging
                        ;; prefix, even though DATADIR is absolute.
                        (string-append "prefix=" #$output)
                        (string-append "DATADIR=" data)
                        (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
                        "FORCE_CC=gcc" "FORCE_CXX=g++"
                        "LUA_PACKAGE=lua-5.1" "TILES=")
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "crawl" libexec)
                (rename-file (string-append libexec "/crawl") program)
                (call-with-output-file smoke-runner
                  (lambda (port)
                    (display "#!" port)
                    (display #$(file-append python "/bin/python3") port)
                    (display "\nimport errno\nimport os\nimport pty\n" port)
                    (display "import select\nimport signal\nimport sys\n" port)
                    (display "import time\n\n" port)
                    (display "program, *args = sys.argv[1:]\n" port)
                    (display "pid, master = pty.fork()\n" port)
                    (display "if pid == 0:\n    os.execv(program," port)
                    (display " [program, *args])\n\n" port)
                    (display "sent_weapon = False\nsent_play = False\n" port)
                    (display "sent_quit = False\nseen = b''\n" port)
                    (display "quit_after = None\ndeadline = time.monotonic() + 20\n" port)
                    (display "while True:\n" port)
                    (display "    remaining = deadline - time.monotonic()\n" port)
                    (display "    if remaining <= 0:\n" port)
                    (display "        os.kill(pid, signal.SIGTERM)\n" port)
                    (display "        os.waitpid(pid, 0)\n        sys.exit(1)\n" port)
                    (display "    timeout = min(remaining, 0.25)\n" port)
                    (display "    ready, _, _ = select.select([master], [], [], timeout)\n" port)
                    (display "    if ready:\n" port)
                    (display "        try:\n            data = os.read(master, 4096)\n" port)
                    (display "        except OSError as error:\n" port)
                    (display "            if error.errno == errno.EIO:\n" port)
                    (display "                break\n            raise\n" port)
                    (display "        if not data:\n            break\n" port)
                    (display "        os.write(1, data)\n" port)
                    (display "        seen = (seen + data)[-16384:]\n" port)
                    (display "        if (not sent_weapon and " port)
                    (display "b'choice of weapons' in seen):\n" port)
                    (display "            os.write(master, b'a')\n" port)
                    (display "            sent_weapon = True\n" port)
                    (display "        if (sent_weapon and not sent_play and " port)
                    (display "b'HP:' in seen):\n" port)
                    ;; A rest and a movement command prove that the new
                    ;; character has entered the playable dungeon state.
                    (display "            os.write(master, b'.l')\n" port)
                    (display "            sent_play = True\n" port)
                    (display "            quit_after = time.monotonic() + 0.25\n" port)
                    (display "    if (sent_play and not sent_quit and " port)
                    (display "quit_after is not None and time.monotonic() >= quit_after):\n" port)
                    ;; Ctrl-Q is the documented no-save quit command.  The
                    ;; trailing y handles a confirmation prompt if displayed.
                    (display "        os.write(master, b'\\x11y')\n" port)
                    (display "        sent_quit = True\n\n" port)
                    (display "_, status = os.waitpid(pid, 0)\n" port)
                    (display "if (not sent_weapon or not sent_play or not sent_quit\n" port)
                    (display "        or b'choice of weapons' not in seen or b'HP:' not in seen\n" port)
                    (display "        or not os.WIFEXITED(status) or os.WEXITSTATUS(status)):\n" port)
                    (display "    sys.exit(1)\n" port)))
                (chmod smoke-runner #o555)
                ;; LICENSE applies to the program as a whole.  CREDITS and
                ;; the compatible component notices cover installed assets.
                (install-file "../../LICENSE" doc)
                (install-file "../CREDITS.txt" doc)
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                ;; install-data does not include the source-side RLTiles
                ;; notice when tiles are disabled, but the source tree is
                ;; still covered by the release's licensing record.
                (install-file "rltiles/license.txt"
                              (string-append doc "/license"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port "program=~s~%output=~s~%" program #$output)
                    (format port "cp=~s~%mkdir=~s~%mktemp=~s~%rm=~s~%find=~s~%"
                            #$(file-append coreutils-minimal "/bin/cp")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm")
                            #$(file-append findutils "/bin/find"))
                    (format port "python=~s~%runner=~s~%"
                            #$(file-append python "/bin/python3") smoke-runner)
                    (format port "terminfo=~s~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display "set -eu\nprepare_environment() {\n" port)
                    (display "  state=\"${XDG_DATA_HOME:-${HOME:?HOME or " port)
                    (display "XDG_DATA_HOME must be set}/.local/share}/bloatcrawl2\"\n"
                             port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  export CRAWL_DIR=\"$state\"\n" port)
                    (display "  export TERMINFO_DIRS=\"$terminfo" port)
                    (display "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n" port)
                    (display "}\nrun_game() {\n  prepare_environment\n" port)
                    (display "  exec \"$program\" \"$@\"\n}\n" port)
                    (display "if test \"${1:-}\" = --smoke" port)
                    (display " && test \"$#\" -eq 1; then\n" port)
                    (display "  scratch=$(\"$mktemp\" -d" port)
                    (display " \"${TMPDIR:-/tmp}/bloatcrawl2-smoke.XXXXXXXX\")\n" port)
                    (display "  trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\"" port)
                    (display " \"$scratch/cache\" \"$scratch/data\"\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/state\" \"$scratch/runtime\"\n" port)
                    (display "  export HOME=\"$scratch/home\"\n" port)
                    (display "  XDG_CONFIG_HOME=\"$scratch/config\"\n" port)
                    (display "  XDG_CACHE_HOME=\"$scratch/cache\"\n" port)
                    (display "  XDG_DATA_HOME=\"$scratch/data\"\n" port)
                    (display "  XDG_STATE_HOME=\"$scratch/state\"\n" port)
                    (display "  XDG_RUNTIME_DIR=\"$scratch/runtime\"\n" port)
                    (display "  export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME" port)
                    (display " XDG_STATE_HOME XDG_RUNTIME_DIR\n" port)
                    (display "  export TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  prepare_environment\n" port)
                    ;; Capture the actual PTY stream for the runtime screenshot
                    ;; adapter before deleting the private smoke tree.
                    (display "  cd \"$scratch\"\n" port)
                    (display "  \"$python\" \"$runner\" \"$program\" -seed 285" port)
                    (display " -no-save -name Goocastle -species Hu" port)
                    (display " -background Fi >\"$scratch/ui.raw\"\n" port)
                    (display "  test -s \"$scratch/ui.raw\"\n" port)
                    (display "  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\";" port)
                    (display " then\n" port)
                    (display "    \"$cp\" \"$scratch/ui.raw\"" port)
                    (display " \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "  fi\n" port)
                    (display "  test -z \"$(\"$find\" \"$scratch/home\"" port)
                    (display " \"$scratch/config\" \"$scratch/cache\"" port)
                    (display " \"$scratch/state\" \"$scratch/runtime\"" port)
                    (display " -mindepth 1 -print -quit)\"\n" port)
                    (display "  test -d \"$scratch/data/bloatcrawl2\"\n" port)
                    (display "  test ! -w \"$output\"\n" port)
                    (display "  printf '%s\\n'" port)
                    (display " 'bloatcrawl2 smoke: terminal UI OK; no store writes'\n" port)
                    (display "  exit 0\nfi\n" port)
                    (display "run_game \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    ;; Upstream's generated-source scripts use the unversioned `python'
    ;; interpreter name; python-wrapper supplies that name in the build PATH.
    (native-inputs (list bison flex perl pkg-config python-pyyaml
                         python-wrapper which))
    (inputs (list bash-minimal coreutils-minimal findutils lua-5.1 ncurses
                  python sqlite zlib))
    (home-page "https://github.com/Hellmonk/bloatcrawl2")
    (synopsis "Terminal fork of Dungeon Crawl Stone Soup")
    (description
     "Bloatcrawl 2 is an independently playable fork of Dungeon Crawl Stone
Soup.  This package builds and installs only its terminal frontend; it does
not fetch, build, or install tile, sound, SDL, font, or webserver components.
The launcher keeps mutable saves and scores in
@file{$XDG_DATA_HOME/bloatcrawl2}, falling back to
@file{$HOME/.local/share/bloatcrawl2}.  It has no updater, telemetry, or
runtime download in the console path.")
    ;; The root license applies to the combined program.  The release also
    ;; includes compatible BSD, MIT, Apache-2.0, zlib, CC0/public-domain,
    ;; LGPL, and Boost-licensed components; their notices are installed.
    (license (list license:gpl2+ license:cc0 license:public-domain
                   license:bsd-2 license:bsd-3 license:expat license:asl2.0
                   license:zlib license:lgpl2.1+ license:boost1.0
                   (license:fsdg-compatible
                    "https://www.libpng.org/pub/png/src/libpng-LICENSE.txt")
                   (license:fsdg-compatible
                    "https://www.pcre.org/original/doc/html/pcre2license.html")))))
