;;; GNU Guix package for ChessRogue.

(define-module (tay packages chessrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system haskell)
  #:use-module (guix gexp)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages bdw-gc)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages base))

;; Kaya 0.4.4 predates the currently packaged random and splitmix releases.
;; Keep these compiler dependencies private so this historical bootstrap does
;; not alter the channel's public Haskell package set.
(define ghc-splitmix-for-kaya
  (package
    (name "ghc-splitmix-for-kaya")
    (version "0.1.0.4")
    (source
     (origin
       (method url-fetch)
       (uri "https://hackage.haskell.org/package/splitmix-0.1.0.4/splitmix-0.1.0.4.tar.gz")
       (sha256
        (base32 "1apck3nzzl58r0b9al7cwaqwjhhkl8q4bfrx14br2yjf741581kd"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-8.4
           #:tests? #f
           #:haddock? #f))
    (home-page "https://hackage.haskell.org/package/splitmix")
    (synopsis "Fast splittable pseudorandom number generator")
    (description
     "This private copy of splitmix supplies the old GHC-compatible random
library needed to bootstrap Kaya 0.4.4.")
    (license bsd-3)))

(define ghc-random-for-kaya
  (package
    (name "ghc-random-for-kaya")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://hackage.haskell.org/package/random-1.2.0/random-1.2.0.tar.gz")
       (sha256
        (base32 "1pmr7zbbqg58kihhhwj8figf5jdchhi7ik2apsyxbgsqq3vrqlg4"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-8.4
           #:tests? #f
           #:haddock? #f))
    (inputs (list ghc-splitmix-for-kaya))
    (home-page "https://hackage.haskell.org/package/random")
    (synopsis "Random number generation")
    (description
     "This private GHC-8.4-compatible random library is a compiler
dependency of Kaya 0.4.4.")
    (license bsd-3)))

(define kaya-for-chessrogue
  (package
    (name "kaya-for-chessrogue")
    (version "0.4.4")
    (source
     (origin
       (method url-fetch)
       (uri "https://sourceforge.net/projects/kaya/files/kaya-stable/0.4.4/kaya-0.4.4.tgz/download")
       (file-name "kaya-0.4.4.tgz")
       (sha256
        (base32 "0j4l6yk3b7znjhgbd27l99k2ry329vim3jc7qhj9283xbb4x4bl9"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list "--disable-postgres"
              "--disable-mysql"
              "--disable-sqlite"
              "--disable-gd"
              "--disable-sdl"
              "--disable-opengl"
              "--disable-ncursesw")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'patch-old-haskell-imports
            (lambda _
              (for-each
               (lambda (file)
                 (invoke "sed" "-i"
                         "-e" "s/^import List/import Data.List/"
                         "-e" "s/^import Char/import Data.Char/"
                         "-e" "s/^import Monad/import Control.Monad/"
                         "-e" "s/^import IO/import System.IO/"
                         "-e" "s/^import System.Cmd/import System.Process/"
                         "-e" "/^import System$/c\\import System.Environment\\nimport System.Exit\\nimport System.Process"
                         file))
               (cons "compiler/Parser.y"
                     (find-files "compiler" "\\.hs$")))
              (for-each
               (lambda (file)
                 (invoke "sed" "-i"
                         "-e" "/^import System.IO$/a\\import Control.Exception (catch)"
                         file))
               '("compiler/Portability64.hs" "compiler/CodegenCPP.hs"
                 "compiler/Module.hs"))
              (invoke "sed" "-i"
                      "-e" "s/import Control.Exception (catch)/import System.IO.Error (catchIOError)/"
                      "-e" "s/environment x = catch /environment x = catchIOError /"
                      "compiler/Portability64.hs")
              (invoke "sed" "-i"
                      "-e" "/^environment :: String -> IO (Maybe String)/,/^tempfile :: IO (FilePath, Handle)/c\\environment :: String -> IO (Maybe String)\\nenvironment x = catchIOError (do\\n  e <- getEnv x\\n  return (Just e)) (const (return Nothing))\\n\\ntempfile :: IO (FilePath, Handle)"
                      "compiler/Portability64.hs")
              (invoke "sed" "-i"
                      "-e" "/^import Inliner$/a\\import System.IO.Error (catchIOError)"
                      "-e" "s/^  = catch$/  = catchIOError/"
                      "compiler/Module.hs")
              (invoke "sed" "-i"
                      "-e" "s/^import System.Directory$/import System.Directory hiding (findFile)/"
                      "compiler/Module.hs")
              (invoke "sed" "-i"
                      "-e" "/^import Control.Monad$/a\\import Control.Applicative (Alternative(..))"
                      "-e" "/^instance Monad Result where/i\\instance Functor Result where\\n    fmap f (Success x) = Success (f x)\\n    fmap _ (Failure err fn line) = Failure err fn line\\n\\ninstance Applicative Result where\\n    pure = Success\\n    (Success f) <*> (Success x) = Success (f x)\\n    (Failure err fn line) <*> _ = Failure err fn line\\n    _ <*> (Failure err fn line) = Failure err fn line\\n\\ninstance Alternative Result where\\n    empty = Failure \"Error\" \"(no file)\" 0\\n    Success x <|> _ = Success x\\n    Failure _ _ _ <|> y = y\\n"
                      "compiler/AbsSyntax.hs")
              (invoke "sed" "-i"
                      "-e" "s/^    popvals n (a+1) =/    popvals n a | a > 0 =/"
                      "-e" "s/popvals (n+1) a/popvals (n+1) (a-1)/"
                      "compiler/CodegenCPP.hs")))
          (add-before 'configure 'patch-ncurses-link
            (lambda _
              ;; Kaya's probe and Curses library metadata use the historical
              ;; libcurses name.  Guix exposes the implementation as ncurses.
              (substitute* (list "configure.ac" "configure")
                (("AC_CHECK_LIB\\(curses,") "AC_CHECK_LIB(ncurses,")
                (("-lcurses") "-lncurses"))
              (substitute* "libs/Curses.head"
                (("%link \"curses\"") "%link \"ncurses\""))))
          (replace 'build
            (lambda _
              (invoke "make" "compiler" "rts" "stdlib" "posix" "libs"
                      "contrib")))
          (delete 'install-license-files)
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (doc (string-append out "/share/doc/kaya-0.4.4")))
                (for-each
                 (lambda (directory)
                   (invoke "make" "-C" directory "install"
                           (string-append "prefix=" out)
                           "DESTDIR="))
                 '("compiler" "rts" "stdlib" "posix" "libs" "contrib"))
                (mkdir-p doc)
                (install-file "COPYING" doc)
                (install-file "GPL2" doc)
                (install-file "GPL3" doc)
                (install-file "LGPL2.1" doc)
                (install-file "LGPL3" doc)
                (mkdir-p (string-append doc "/compiler"))
                (install-file "compiler/COPYING"
                              (string-append doc "/compiler"))))))))
    (native-inputs
     (list ghc-8.4 ghc-happy ghc-random-for-kaya gcc-toolchain pkg-config))
    (inputs
     (list gmp gnutls libgcrypt libgc ncurses pcre zlib))
    (home-page "https://www.kayalang.org/")
    (synopsis "Kaya compiler and runtime for ChessRogue")
    (description
     "This private Kaya 0.4.4 compiler and runtime is used to build the
historical ChessRogue curses game from source.  Its unrelated optional
database, SDL, OpenGL, GD, and wide-curses components are disabled.")
    (license (list gpl2+ lgpl2.1+))))

(define-public chessrogue
  (package
    (name "chessrogue")
    (version "0.3.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://sourceforge.net/projects/chessrogue/files/chessrogue/0.3.1/chessrogue0.3.1-src.tgz/download")
       (file-name "chessrogue0.3.1-src.tgz")
       (sha256
        (base32 "15qbvlyamnqjq5lkmbwba68l0n4yl2fxhawxb27xf5djvzfkfyf9"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'build-curses
            (lambda _
              (invoke "sh" "buildCurses.sh")))
          (delete 'install-license-files)
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (data (string-append out "/share/chessrogue"))
                     (doc (string-append out "/share/doc/chessrogue"))
                     (program (string-append libexec "/chessrogue"))
                     (runner (string-append libexec
                                             "/chessrogue-smoke-runner.py"))
                     (launcher (string-append bin "/chessrogue")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "chessrogue" program)
                (install-file "crkeymap.txt"
                              (string-append data "/crkeymap.txt"))
                (for-each
                 (lambda (file)
                   (install-file file doc))
                 '("COPYING.txt" "COPYING.pcre.txt" "COPYING.sdl.txt"
                   "README.txt" "INSTALL.txt" "CHANGELOG.txt" "HINTS.txt"
                   "crkeymap.txt"))
                (copy-recursively
                 (string-append #$kaya-for-chessrogue
                                "/share/doc/kaya-0.4.4")
                 (string-append doc "/kaya"))
                (call-with-output-file runner
                  (lambda (port)
                    (display "#!" port)
                    (display #$(file-append python "/bin/python3") port)
                    (display "\n" port)
                    (display "import fcntl\n" port)
                    (display "import os\n" port)
                    (display "from pathlib import Path\n" port)
                    (display "import pty\n" port)
                    (display "import re\n" port)
                    (display "import select\n" port)
                    (display "import signal\n" port)
                    (display "import struct\n" port)
                    (display "import sys\n" port)
                    (display "import termios\n" port)
                    (display "import time\n\n" port)
                    (display "program, raw_name, state_name = sys.argv[1:4]\n" port)
                    (display "state = Path(state_name).resolve()\n" port)
                    (display "pid, master = pty.fork()\n" port)
                    (display "if pid == 0:\n" port)
                    (display "    os.execv(program, [program])\n\n" port)
                    (display "fcntl.ioctl(master, termios.TIOCSWINSZ,\n" port)
                    (display "             struct.pack('HHHH', 32, 100, 0, 0))\n" port)
                    (display "captured = bytearray()\n" port)
                    (display "started = False\n" port)
                    (display "waited = False\n" port)
                    (display "wait_time = None\n" port)
                    (display "deadline = time.monotonic() + 20\n" port)
                    (display "ansi = re.compile(rb'\\x1b(?:\\[[0-?]*[ -/]*[@-~]|\\][^\\x07]*(?:\\x07|\\x1b\\\\))')\n" port)
                    (display "def visible(data):\n" port)
                    (display "    return ansi.sub(b'', data).lower()\n\n" port)
                    (display "try:\n" port)
                    (display "    while time.monotonic() < deadline:\n" port)
                    (display "        ready, _, _ = select.select([master], [], [], 0.2)\n" port)
                    (display "        if ready:\n" port)
                    (display "            try:\n" port)
                    (display "                chunk = os.read(master, 65536)\n" port)
                    (display "            except OSError:\n" port)
                    (display "                break\n" port)
                    (display "            if not chunk:\n" port)
                    (display "                break\n" port)
                    (display "            captured.extend(chunk)\n" port)
                    (display "        screen = visible(captured)\n" port)
                    (display "        if (not started and\n" port)
                    (display "                b'press any key to start playing' in screen):\n" port)
                    (display "            os.write(master, b' ')\n" port)
                    (display "            started = True\n" port)
                    (display "        if (started and not waited and\n" port)
                    (display "                b'level 1' in screen and b'moves' in screen\n" port)
                    (display "                and b'@' in screen):\n" port)
                    (display "            os.write(master, b'.')\n" port)
                    (display "            waited = True\n" port)
                    (display "            wait_time = time.monotonic()\n" port)
                    (display "        if waited and time.monotonic() - wait_time >= 0.5:\n" port)
                    (display "            break\n" port)
                    (display "    screen = visible(captured)\n" port)
                    (display "    if not started or not waited:\n" port)
                    (display "        raise RuntimeError('startup or wait input was not observed')\n" port)
                    (display "    if b'level 1' not in screen or b'moves' not in screen or b'@' not in screen:\n" port)
                    (display "        raise RuntimeError('level-one board was not rendered')\n" port)
                    (display "finally:\n" port)
                    (display "    try:\n" port)
                    (display "        os.kill(pid, signal.SIGTERM)\n" port)
                    (display "    except ProcessLookupError:\n" port)
                    (display "        pass\n" port)
                    (display "    try:\n" port)
                    (display "        os.waitpid(pid, 0)\n" port)
                    (display "    except ChildProcessError:\n" port)
                    (display "        pass\n" port)
                    (display "    with open(raw_name, 'wb') as raw:\n" port)
                    (display "        raw.write(captured)\n\n" port)
                    (display "save_names = {'.crsave', '.crscore'}\n" port)
                    (display "save_names.update(p.name for p in state.glob('score.*.txt'))\n" port)
                    (display "for path in Path(state.parent.parent).rglob('*'):\n" port)
                    (display "    if path.is_file() and path.name in save_names:\n" port)
                    (display "        if state not in path.resolve().parents:\n" port)
                    (display "            raise RuntimeError('save/report escaped state root')\n" port)
                    (display "if not (state / '.crsave').is_file():\n" port)
                    (display "    raise RuntimeError('practice save was not written')\n" port)))
                (chmod runner #o555)
                (call-with-output-file launcher
                  (lambda (port)
                    (display "#!" port)
                    (display #$(file-append bash-minimal "/bin/sh") port)
                    (display "\nset -eu\n" port)
                    (format port "program=~s\n" program)
                    (format port "runner=~s\n" runner)
                    (format port "keymap=~s\n"
                            (string-append data "/crkeymap.txt"))
                    (format port "output=~s\n" out)
                    (display "data_home=${XDG_DATA_HOME:-${HOME:?HOME is not set}/.local/share}\n" port)
                    (display "state_root=$data_home/chessrogue\n" port)
                    (display "mkdir -p \"$state_root\"\n" port)
                    (display "if test \"${1-}\" = --smoke; then\n" port)
                    (display "    smoke_root=$state_root/.smoke\n" port)
                    (display "    mkdir -p \"$smoke_root/home\" \"$smoke_root/data\" \"$smoke_root/config\" \"$smoke_root/cache\" \"$smoke_root/state\" \"$smoke_root/runtime\" \"$smoke_root/tmp\"\n" port)
                    (display "    export HOME=$smoke_root/home\n" port)
                    (display "    export XDG_CONFIG_HOME=$smoke_root/config\n" port)
                    (display "    export XDG_DATA_HOME=$smoke_root/data\n" port)
                    (display "    export XDG_CACHE_HOME=$smoke_root/cache\n" port)
                    (display "    export XDG_STATE_HOME=$smoke_root/state\n" port)
                    (display "    export XDG_RUNTIME_DIR=$smoke_root/runtime\n" port)
                    (display "    export TMPDIR=$smoke_root/tmp\n" port)
                    (display "    export TERM=${TERM:-xterm-256color}\n" port)
                    (display "    export LC_ALL=C\n" port)
                    (display "    mkdir -p \"$XDG_DATA_HOME/chessrogue\"\n" port)
                    (display "    cp \"$keymap\" \"$XDG_DATA_HOME/chessrogue/crkeymap.txt\"\n" port)
                    (display "    printf '%s\\n' '0|0|0|0|0|0|0|0|0|0|0|0' '0|0|0|0' '0' '-1|-1|-1' > \"$XDG_DATA_HOME/chessrogue/.crsave\"\n" port)
                    (display "    cd \"$XDG_DATA_HOME/chessrogue\"\n" port)
                    (display "    \"$runner\" \"$program\" \"$smoke_root/terminal.raw\" \"$XDG_DATA_HOME/chessrogue\"\n" port)
                    (display "    if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE:-}\"; then\n" port)
                    (display "        mkdir -p \"$(dirname \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"\n" port)
                    (display "        cp \"$smoke_root/terminal.raw\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"\n" port)
                    (display "    fi\n" port)
                    (display "    test -z \"$(find \"$output\" -xdev -type f -perm /222 -print -quit)\"\n" port)
                    (display "    printf '%s\\n' 'chessrogue isolated smoke passed'\n" port)
                    (display "    exit 0\n" port)
                    (display "fi\n" port)
                    (display "if test ! -e \"$state_root/crkeymap.txt\"; then cp \"$keymap\" \"$state_root/crkeymap.txt\"; fi\n" port)
                    (display "export HOME=$state_root\n" port)
                    (format port "export TERMINFO_DIRS=~s/share/terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\n"
                            #$ncurses)
                    (display "cd \"$state_root\"\n" port)
                    (display "exec \"$program\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list kaya-for-chessrogue python gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal findutils ncurses))
    (home-page "https://chessrogue.sourceforge.net/")
    (synopsis "Terminal chess-themed roguelike game")
    (description
     "ChessRogue is a historical standalone terminal roguelike from the
SourceForge project.  This package builds its curses frontend from the fixed
0.3.1 source archive with the private Kaya 0.4.4 compiler.  The launcher keeps
the game's save files and timestamped reports under
@env{XDG_DATA_HOME}/chessrogue, falling back to
@file{~/.local/share/chessrogue}; no SDL assets or runtime downloads are
included.")
    (license (list gpl2+ lgpl2.1+ bsd-3))))
