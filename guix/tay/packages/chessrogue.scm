;;; GNU Guix package for ChessRogue.

(define-module (tay packages chessrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system haskell)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:select (bsd-3 gpl2+ lgpl2.1+))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages ncurses)
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
                      "-e" "s/import Control.Exception (catch)/import System.IO.Error (catchIOError)/"
                      "-e" "s/^  = catch$/  = catchIOError/"
                      "compiler/CodegenCPP.hs")
              (invoke "sed" "-i"
                      "-e" "/^import Control.Monad$/a\\import System.IO.Error (catchIOError)"
                      "-e" "s/catch (do startup <- getStartup prtype libdirs/catchIOError (do\\n             startup <- getStartup prtype libdirs/"
                      "-e" "s/^                 let pt =/             let pt =/"
                      "-e" "s/^                 compile newroot/             compile newroot/"
                      "compiler/Driver.hs")
              (invoke "sed" "-i"
                      "-e" "s/^import System.Directory$/import System.Directory hiding (findFile)/"
                      "compiler/Module.hs")
              ;; Current Boehm GC keeps the C++ bad-allocation helper in
              ;; libgccpp rather than libgc.  Kaya's historical linker template
              ;; names only libgc, which breaks allocation-using programs and
              ;; the upstream compiler regression tests.
              (substitute* "compiler/Driver.hs"
                (("-lgc") "-lgc -lgccpp"))
              (substitute* "rts/Makefile.in"
                (("-lgc") "-lgc -lgccpp"))
              (invoke "sed" "-i"
                      "-e" "/^import Control.Monad$/a\\import Control.Applicative (Alternative(..))"
                      "-e" "/^instance Monad Result where/i\\instance Functor Result where\\n    fmap f (Success x) = Success (f x)\\n    fmap _ (Failure err fn line) = Failure err fn line\\n\\ninstance Applicative Result where\\n    pure = Success\\n    (Success f) <*> (Success x) = Success (f x)\\n    (Failure err fn line) <*> _ = Failure err fn line\\n    _ <*> (Failure err fn line) = Failure err fn line\\n\\ninstance Alternative Result where\\n    empty = Failure \"Error\" \"(no file)\" 0\\n    Success x <|> _ = Success x\\n    Failure _ _ _ <|> y = y\\n"
                      "compiler/AbsSyntax.hs")
              (invoke "sed" "-i"
                      "-e" "s/^    popvals n (a+1) =/    popvals n a | a > 0 =/"
                      "-e" "s/popvals (n+1) a/popvals (n+1) (a-1)/"
                      "compiler/CodegenCPP.hs")
              ;; GnuTLS 3.8 removed the obsolete certificate-type priority
              ;; setter.  The preceding default priority setup retains the
              ;; supported certificate policy and is sufficient here.
              (substitute* "stdlib/tls_glue.cc"
                (("  const int cert_type_priority\\[3\\] = \\{ GNUTLS_CRT_X509, GNUTLS_CRT_OPENPGP, 0 \\};") "")
                (("  gnutls_certificate_type_set_priority\\(session,cert_type_priority\\);") ""))
              ;; Boehm GC 8.2 changed this setter from returning the old
              ;; divisor to returning void.  Keep Kaya's historical API by
              ;; providing a small compatibility wrapper that does return it.
              (substitute* "stdlib/Prelude.k"
                (("public Int gcSetFSD\\(Int fsd\\) = GC_set_free_space_divisor;")
                 "public Int gcSetFSD(Int fsd) = do_GC_set_free_space_divisor;"))
              (for-each
               (lambda (file)
                 (substitute* file
                   (("#include <gc/gc_cpp.h>" include)
                    (string-append "#define GC_INCLUDE_NEW\n" include))))
               '("rts/Heap.h" "rts/VMState.h" "rts/KayaAPI.h"
                 "rts/Array.h" "rts/Closure.h" "rts/VM.cc"))
              (substitute* "rts/stdfuns.h"
                (("void do_GC_enable_incremental\\(\\);" declaration)
                 (string-append declaration
                                "\nkint do_GC_set_free_space_divisor(kint);")))
              (substitute* "rts/stdfuns.cc"
                (("void runFn\\(void\\* obj, void\\* finalizer\\) \\{" run-fn)
                 (string-append
                  "kint do_GC_set_free_space_divisor(kint fsd) {\n"
                  "    kint old = GC_get_free_space_divisor();\n"
                  "    GC_set_free_space_divisor(fsd);\n"
                  "    return old;\n"
                  "}\n\n"
                  run-fn)))))
          (add-after 'configure 'patch-generated-repl
            (lambda _
              ;; Do not pull an unpinned optional readline Haskell package into
              ;; this historical compiler.  A plain line reader is sufficient
              ;; for kayac and keeps the compiler closure self-contained.
              (invoke "sed" "-i"
                      "-e" "s/^import List$/import Data.List/"
                      "-e" "s/^import CForeign$/import Foreign.C/"
                      "-e" "s/^import Ptr$/import Foreign.Ptr/"
                      "-e" "s/^import IO$/import System.IO/"
                      "-e" "/^import System.Console.*Readline$/d"
                      "-e" "/^import System.Directory$/a\\import System.IO.Error (catchIOError)\\nreadline :: String -> IO (Maybe String)\\nreadline prompt = do\\n  putStr prompt\\n  hFlush stdout\\n  atEnd <- isEOF\\n  if atEnd then return Nothing else fmap Just getLine\\n\\naddHistory :: String -> IO ()\\naddHistory _ = return ()"
                      "-e" "s/catch (runProg/catchIOError (runProg/"
                      "compiler/REPL.hs")))
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
                ;; The game build uses Kaya's -nortchecks mode, which selects
                ;; the optimized runtime archive rather than the default one.
                (for-each
                 (lambda (file)
                   (install-file file (string-append out "/lib/kaya")))
                 '("rts_opt/libkayavm-opt.a" "rts_fast/libkayavm-fast.a"))
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
       (uri (string-append
             "https://sourceforge.net/projects/chessrogue/files/chessrogue/"
             "0.3.1/chessrogue0.3.1-src.tgz/download"))
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
          (replace 'build
            (lambda _
              ;; Kaya otherwise embeds fresh /dev/urandom-derived secrets in
              ;; each generated executable.  Use its documented deterministic
              ;; seed mode so this source build is reproducible and byte-safe
              ;; under the builder's UTF-8 locale.
              (setenv "LC_ALL" "C")
              (substitute* "buildCurses.sh"
                (("kayac -force -nortchecks")
                 "kayac -force -nortchecks -seedkey chessrogue-0.3.1"))
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
                     (launcher (string-append bin "/chessrogue"))
                     (mkdir-bin (string-append #$coreutils-minimal "/bin/mkdir"))
                     (cp-bin (string-append #$coreutils-minimal "/bin/cp")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "chessrogue" libexec)
                (install-file "crkeymap.txt" data)
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
                (call-with-output-file launcher
                  (lambda (port)
                    (display "#!" port)
                    (display #$(file-append bash-minimal "/bin/sh") port)
                    (display "\nset -eu\n" port)
                    (format port "program=~s\n" program)
                    (format port "keymap=~s\n"
                            (string-append data "/crkeymap.txt"))
                    (display (string-append
                             "data_home=${XDG_DATA_HOME:-${HOME:?HOME is not "
                             "set}/.local/share}\n") port)
                    (display "state_root=$data_home/chessrogue\n" port)
                    (format port "mkdir=~s\n" mkdir-bin)
                    (format port "cp=~s\n" cp-bin)
                    (display "\"$mkdir\" -p \"$state_root\"\n" port)
                    (display (string-append
                             "if test ! -e \"$state_root/crkeymap.txt\"; then "
                             "\"$cp\" \"$keymap\" "
                             "\"$state_root/crkeymap.txt\"; fi\n") port)
                    (display "export HOME=$state_root\n" port)
                    (format port (string-append
                                  "export TERMINFO_DIRS=~s/share/terminfo"
                                  "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\n")
                            #$ncurses)
                    (display "cd \"$state_root\"\n" port)
                    (display "exec \"$program\" \"$@\"\n" port)))
                (chmod launcher #o555)))))))
    (native-inputs (list kaya-for-chessrogue gcc-toolchain))
    ;; Kaya does not propagate its C-library inputs.  Keep every library used
    ;; by the generated curses executable explicit in this consumer.
    (inputs (list bash-minimal coreutils-minimal gmp gnutls
                  libgcrypt libgc ncurses pcre zlib))
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
