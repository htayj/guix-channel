;;; GNU Guix package for the bcrawl terminal roguelike.

(define-module (tay packages bcrawl)
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
  #:use-module (gnu packages linux)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages sqlite))

(define-public bcrawl
  (package
    (name "bcrawl")
    ;; The bcrawl-1.42.1 tag, published on 2025-01-13.
    (version "1.42.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/b-crawl/bcrawl")
             (commit "d9800d219b5e0ab840c8065e44f875fa19dd63ff")))
       (file-name (git-file-name name version))
       ;; Recursive hash of the tracked tag tree.  Git metadata and gitlink
       ;; contents are absent: the terminal build uses Guix libraries.
       (sha256
        (base32 "1jn7qf3pjzq0rvzggdknnzc6krkj0d8fqppgfggfq975mkxlnnvx"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The source suite requires fake_pty and diagnostic options.  The
      ;; installed game is exercised by tests/bcrawl-smoke.sh instead.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _
              (chdir "crawl-ref/source")
              ;; git-fetch supplies no .git directory, so give Makefile's
              ;; documented version fallback the fixed upstream tag.
              (call-with-output-file "util/release_ver"
                (lambda (port) (display "bcrawl-1.42.1\n" port)))))
          (replace 'build
            (lambda _
              ;; TILES is empty: no SDL, font, or tile source/asset is used.
              ;; The old SQLite probe assumes /usr/include, so set its input.
              (invoke "make" "crawl"
                      (string-append "DATADIR=" #$output "/share/bcrawl")
                      (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
                      "FORCE_CC=gcc" "FORCE_CXX=g++"
                      ;; Guix's Lua 5.1 input exports lua-5.1.pc.
                      "LUA_PACKAGE=lua-5.1" "TILES="
                      "NO_TRY_LLD=YesPlease" "NO_TRY_GOLD=YesPlease")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/bcrawl"))
                     (doc (string-append #$output "/share/doc/bcrawl"))
                     (libexec (string-append #$output "/libexec"))
                     (bin (string-append #$output "/bin"))
                     (program (string-append libexec "/bcrawl"))
                     (smoke-runner
                      (string-append libexec "/bcrawl-smoke-runner.py"))
                     (launcher (string-append bin "/bcrawl")))
                ;; Upstream install also manages mutable paths.  install-data
                ;; only copies immutable console assets and documentation.
                (invoke "make" "install-data"
                        ;; Upstream refuses install-data without a staging
                        ;; prefix, even though DATADIR is absolute.
                        (string-append "prefix=" #$output)
                        (string-append "DATADIR=" data)
                        (string-append "SQLITE_INCLUDE_DIR=" #$sqlite "/include")
                        "FORCE_CC=gcc" "FORCE_CXX=g++"
                        "LUA_PACKAGE=lua-5.1" "TILES="
                        "NO_TRY_LLD=YesPlease" "NO_TRY_GOLD=YesPlease")
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
                    (display "seen = b''\nsent_continue = False\n" port)
                    (display "deadline = time.monotonic() + 25\nwhile True:\n" port)
                    (display "    remaining = deadline - time.monotonic()\n" port)
                    (display "    if remaining <= 0:\n" port)
                    (display "        os.kill(pid, signal.SIGTERM)\n" port)
                    (display "        os.waitpid(pid, 0)\n        sys.exit(1)\n" port)
                    (display "    ready, _, _ = select.select(" port)
                    (display "[master], [], [], remaining)\n" port)
                    (display "    if not ready:\n        continue\n" port)
                    (display "    try:\n        data = os.read(master, 4096)\n" port)
                    (display "    except OSError as error:\n" port)
                    (display "        if error.errno == errno.EIO:\n" port)
                    (display "            break\n        raise\n" port)
                    (display "    if not data:\n        break\n" port)
                    (display "    os.write(1, data)\n" port)
                    (display "    seen = (seen + data)[-4096:]\n" port)
                    ;; The arena exits after a key acknowledges Bcrawl's
                    ;; final-score popup.  It is sent only after the actual
                    ;; deterministic combat result is visible.
                    (display "    if not sent_continue and " port)
                    (display "b'Final score:' in seen:\n" port)
                    (display "        os.write(master, b' ')\n" port)
                    (display "        sent_continue = True\n" port)
                    (display "_, status = os.waitpid(pid, 0)\n" port)
                    (display "if not os.WIFEXITED(status) or " port)
                    (display "os.WEXITSTATUS(status):\n" port)
                    (display "    sys.exit(1)\n" port)))
                (chmod smoke-runner #o555)
                ;; LICENSE applies to the program as a whole.  CREDITS and
                ;; the compatible component notices cover installed assets.
                (install-file "../../LICENSE" doc)
                (install-file "../CREDITS.txt" doc)
                (copy-recursively "../docs/license"
                                  (string-append doc "/license"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port "program=~s~%output=~s~%" program #$output)
                    (format port "mkdir=~s~%mktemp=~s~%rm=~s~%"
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            #$(file-append coreutils-minimal "/bin/mktemp")
                            #$(file-append coreutils-minimal "/bin/rm"))
                    (format port "python=~s~%runner=~s~%"
                            #$(file-append python "/bin/python3") smoke-runner)
                    (format port "terminfo=~s~%"
                            #$(file-append ncurses "/share/terminfo"))
                    (display "set -eu\nprepare_environment() {\n" port)
                    (display "  state=\"${XDG_DATA_HOME:-${HOME:?HOME or " port)
                    (display "XDG_DATA_HOME must be set}/.local/share}/bcrawl\"\n"
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
                    (display " \"${TMPDIR:-/tmp}/bcrawl-smoke.XXXXXXXX\")\n" port)
                    (display "  trap '\"$rm\" -rf \"$scratch\"' EXIT HUP INT TERM\n" port)
                    (display "  \"$mkdir\" -p \"$scratch/home\" \"$scratch/config\"" port)
                    (display " \"$scratch/cache\" \"$scratch/data\"" port)
                    (display " \"$scratch/state\"" port)
                    (display " \"$scratch/runtime\"\n" port)
                    (display "  export HOME=\"$scratch/home\"" port)
                    (display " XDG_CONFIG_HOME=\"$scratch/config\"" port)
                    (display " XDG_CACHE_HOME=\"$scratch/cache\"" port)
                    (display " XDG_DATA_HOME=\"$scratch/data\"" port)
                    (display " XDG_STATE_HOME=\"$scratch/state\"" port)
                    (display " XDG_RUNTIME_DIR=\"$scratch/runtime\"" port)
                    (display " TERM=xterm-256color LC_ALL=C\n" port)
                    (display "  prepare_environment\n" port)
                    ;; The arena is an upstream terminal gameplay/stress mode.
                    ;; A single trial is deterministic and exits on completion.
                    (display "  cd \"$scratch\"\n" port)
                    (display "  \"$python\" \"$runner\" \"$program\" -seed 285" port)
                    (display " -no-save -no-throttle -name goocastle-smoke" port)
                    (display " -arena" port)
                    (display " 'rat v rat arena:small_deep_pool delay:0 t:1'" port)
                    (display " >\"$scratch/arena.tty\"\n" port)
                    (display "  test -s \"$scratch/arena.tty\"" port)
                    (display " && test -s \"$scratch/arena.result\"\n" port)
                    ;; One completed trial reports a non-tie score.  A failed
                    ;; arena parse instead writes an "err:" receipt.
                    (display "  case $(<\"$scratch/arena.result\") in" port)
                    (display "  1-0|0-1) ;; *) exit 1 ;; esac\n" port)
                    ;; Bcrawl builds its databases under CRAWL_DIR even with
                    ;; -no-save.  Check that this mutable state is confined
                    ;; to the fresh XDG directory, never the package output.
                    (display "  test -d \"$scratch/data/bcrawl/saves\"" port)
                    (display " && test ! -w \"$output\"\n" port)
                    (display "  printf '%s\\n'" port)
                    (display " 'bcrawl smoke: arena gameplay OK; no store writes'\n" port)
                    (display "  exit 0\nfi\n" port)
                    (display "run_game \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list bison flex perl pkg-config python-pyyaml which))
    (inputs (list bash-minimal coreutils-minimal lua-5.1 ncurses
                  python sqlite zlib))
    (home-page "https://github.com/b-crawl/bcrawl")
    (synopsis "Terminal fork of Dungeon Crawl Stone Soup")
    (description
     "Bcrawl is an independently playable fork of Dungeon Crawl Stone Soup.
This package builds and installs only its terminal frontend; it does not fetch,
build, or install tile, sound, SDL, or font submodules.  The launcher keeps
mutable saves and scores in @file{$XDG_DATA_HOME/bcrawl}, falling back to
@file{$HOME/.local/share/bcrawl}.  It has no updater, telemetry, runtime
download, or webtiles component.")
    ;; The root GPL-2 license applies to the combined program.  The
    ;; terminal binary includes CC0 data plus BSD, MIT, Apache-2.0 and zlib
    ;; components; the copied notices also record LGPL-2.1 and the
    ;; FSDG-compatible libpng terms.
    (license (list license:gpl2 license:cc0 license:bsd-2 license:bsd-3
                   license:expat license:asl2.0 license:zlib
                   (license:fsdg-compatible
                    "https://www.libpng.org/pub/png/src/libpng-LICENSE.txt")
                   license:lgpl2.1+))))
