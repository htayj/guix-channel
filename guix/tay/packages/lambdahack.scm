;;; LambdaHack's native SDL game and its release-specific Haskell closure.

(define-module (tay packages lambdahack)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system haskell)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (srfi srfi-1)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl))

;; Cabal 2.4 (GHC 8.6.5) calls static archives vanilla libraries.  Retain the
;; standard shared-library and static-executable policy without the newer
;; --enable-static option.  Setup.hs uses the fixed package database only.
(define %release-haskell-configure
  #~(lambda* (#:key outputs inputs tests? (configure-flags '())
              (extra-directories '()) #:allow-other-keys)
      (use-modules (srfi srfi-1))
      (let* ((out (assoc-ref outputs "out"))
             (doc (assoc-ref outputs "doc"))
             (lib (assoc-ref outputs "lib"))
             (directories (filter-map
                           (lambda (name) (assoc-ref inputs name))
                           extra-directories))
             (run-setuphs (@@ (guix build haskell-build-system) run-setuphs))
             (database (@@ (guix build haskell-build-system) %tmp-db-dir)))
        (unsetenv "GHC_PACKAGE_PATH")
        (when (file-exists? "configure") (setenv "CONFIG_SHELL" "sh"))
        (run-setuphs "configure"
          (append
           (list (string-append "--prefix=" out)
                 (string-append "--libdir=" (or lib out) "/lib")
                 (string-append "--docdir=" (or doc out) "/share/doc/"
                                (strip-store-file-name out))
                 "--libsubdir=$compiler/$pkg-$version"
                 (string-append "--package-db=" database) "--global"
                 "--enable-shared" "--enable-library-vanilla"
                 "--disable-executable-dynamic" "--ghc-option=-fPIC"
                 "--ghc-option=-split-sections")
           (map (lambda (directory)
                  (string-append "--extra-include-dirs=" directory))
                (search-path-as-list '("include") directories))
           (map (lambda (directory)
                  (string-append "--extra-lib-dirs=" directory))
                (search-path-as-list '("lib") directories))
           (if tests? '("--enable-tests") '())
           configure-flags)))))

;; All libraries use the upstream lts-13.18 compiler ABI, never the channel's
;; default GHC.  Their optional test harnesses are not game dependencies; the
;; game's complete original test suite is enabled below.
(define* (release-haskell upstream version hash inputs
                          #:key (license license:bsd-3)
                          (native-inputs '()) (flags '())
                          (extra-directories '()) (notices '("LICENSE"))
                          (revision #f))
  (package
    (name (string-append "ghc-" (string-downcase upstream)
                         "-for-lambdahack"))
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://hackage-content.haskell.org/package/"
                           upstream "-" version "/"
                           upstream "-" version ".tar.gz"))
       (sha256 (base32 hash))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-8.6
           #:tests? #f
           #:haddock? #f
           #:cabal-revision revision
           #:configure-flags #~'#$flags
           #:extra-directories extra-directories
           #:phases
           #~(modify-phases %standard-phases
               (replace 'configure #$%release-haskell-configure)
               (add-before 'configure 'isolated-home
                 (lambda _ (setenv "HOME" (getcwd))))
               (add-after 'install 'install-notices
                 (lambda _
                   (let ((doc (string-append #$output "/share/doc/"
                                             #$(string-downcase upstream))))
                     (for-each (lambda (file) (install-file file doc))
                               '#$notices)))))))
    (inputs inputs)
    (native-inputs native-inputs)
    (properties `((hidden? . #t) (upstream-name . ,upstream)))
    (home-page (string-append "https://hackage.haskell.org/package/" upstream))
    (synopsis (string-append "Release-specific " upstream " library"))
    (description
     (string-append "This private " upstream " library supplies the pinned "
                    "source dependency closure of LambdaHack.  It is built "
                    "with the same compiler as the native game."))
    (license license)))

;; Versions and necessary Cabal revisions follow lts-13.18.  Revisions
;; only fix declared bounds for the GHC 8.6/Cabal 2.4 boot libraries.

(define lh-text
  (release-haskell "text" "1.2.3.1"
    "19j725g8xma1811avl3nz2vndwynsmpx3sqf6bd7iwh1bm6n4q43"
    '()
    #:license license:bsd-2))

(define lh-stm
  (release-haskell "stm" "2.5.0.0"
    "1illcj8zgzmpl91hzgk0j74ha436a379gw13siq4gifbcrf6iqsr"
    '()))

(define lh-semigroups
  (release-haskell "semigroups" "0.18.5"
    "17g29h62g1k51ghhvzkw72zksjgi6vs6bfipkj81pqw1dsprcamb"
    '()))

(define lh-hashable
  (release-haskell "hashable" "1.2.7.0"
    "1gra8gq3kb7b2sd845h55yxlrfqx3ii004c6vjhga8v0b30fzdgc"
    (list lh-text)
    #:revision '("1" "197063dpl0wn67dp7a06yc2hxp81n24ykk7klbjx0fndm5n87dh3")))

(define lh-unordered-containers
  (release-haskell "unordered-containers" "0.2.9.0"
    "0l4264p0av12cc6i8gls13q8y27x12z2ar4x34n3x59y99fcnc37"
    (list lh-hashable)))

(define lh-primitive
  (release-haskell "primitive" "0.6.4.0"
    "0r0cda7acvplgwaxy69kviv4jp7kkfi038by68gj4yfx4iwszgjc"
    '()
    #:revision '("1" "18a14k1yiam1m4l29rin9a0y53yp3nxvkz358nysld8aqwy2qsjv")))

(define lh-vector
  (release-haskell "vector" "0.12.0.2"
    "1wy0pfa3ks6s2dkp1fwrl1s9d3wjmqy9d09icnwfs2zimyn9vs2j"
    (list lh-primitive)))

(define lh-vector-binary-instances
  (release-haskell "vector-binary-instances" "0.2.5.1"
    "04n5cqm1v95pw1bp68l9drjkxqiy2vswxdq0fy1rqcgxisgvji9r"
    (list lh-vector)))

(define lh-random
  (release-haskell "random" "1.1"
    "0nis3lbkp8vfx8pkr6v7b7kr5m334bzb0fk9vxqklnp2aw8a865p"
    '()))

(define lh-base-compat
  (release-haskell "base-compat" "0.10.5"
    "0hgvlqcr852hfp52jp99snhbj550mvxxpi8qn15d8ml9aqhyl2lr"
    '()
    #:license license:expat))

(define lh-transformers-compat
  (release-haskell "transformers-compat" "0.6.4"
    "036f7qnzhxjbflypgggkd3v0gjpbcqbb1ryagyiknlrnsrav8zxd"
    '()))

(define lh-tagged
  (release-haskell "tagged" "0.8.6"
    "1pciqzxf9ncv954v4r527xkxkn7r5hcr13mfw5dg1xjci3qdw5md"
    '()))

(define lh-base-orphans
  (release-haskell "base-orphans" "0.8.1"
    "1nwr9av27i9p72k0sn96mw3ywdczw65dy5gd5wxpabhhxlxdcas4"
    '()
    #:license license:expat))

(define lh-th-abstraction
  (release-haskell "th-abstraction" "0.2.11.0"
    "0340w34cqa42m0b9hdys9bfphi13swdp7xc8cwzbj9fq6764p22i"
    '()
    #:license license:isc))

(define lh-statevar
  (release-haskell "StateVar" "1.1.1.1"
    "08r2iw0gdmfs4f6wraaq19vfmkjdbics3dbhw39y7mdjd98kcr7b"
    (list lh-stm)))

(define lh-contravariant
  (release-haskell "contravariant" "1.5"
    "1hn31wl0jai2jrwc6cz19aflbv9xbyl3m5ab57zzysddjav6gw3f"
    (list lh-statevar)))

(define lh-cabal-doctest
  (release-haskell "cabal-doctest" "1.0.6"
    "0bgd4jdmzxq5y465r4sf4jv2ix73yvblnr4c9wyazazafddamjny"
    '()
    #:revision '("2" "1kbiwqm4fxrsdpcqijdq98h8wzmxydcvxd03f1z8dliqzyqsbd60")))

(define lh-distributive
  (release-haskell "distributive" "0.6"
    "1m61ppv851nifid98fimvpml0z0j3ximj7nxd72hshrslr0i7bx4"
    (list lh-base-orphans lh-tagged)
    #:native-inputs (list lh-cabal-doctest)))

(define lh-comonad
  (release-haskell "comonad" "5.0.4"
    "09g870c4flp4k3fgbibsd0mmfjani1qcpbcl685v8x89kxzrva3q"
    (list lh-semigroups lh-tagged lh-transformers-compat lh-contravariant lh-distributive)
    #:native-inputs (list lh-cabal-doctest)))

(define lh-bifunctors
  (release-haskell "bifunctors" "5.5.3"
    "1jn9rxg643xnlhrknmjz88nblcpsr45xwjkwwnn5nxpasa7m4d6l"
    (list lh-base-orphans lh-comonad lh-th-abstraction lh-tagged lh-semigroups)))

(define lh-semigroupoids
  (release-haskell "semigroupoids" "5.3.2"
    "01cxdcflfzx674bhdclf6c7lwgjpbj5yqv8w1fi9dvipyhyj3a31"
    (list lh-base-orphans lh-bifunctors lh-transformers-compat lh-contravariant lh-distributive lh-comonad lh-tagged lh-hashable lh-unordered-containers)
    #:native-inputs (list lh-cabal-doctest)))

(define lh-profunctors
  (release-haskell "profunctors" "5.3"
    "1dx3nkc27yxsrbrhh3iwhq7dl1xn6bj7n62yx6nh8vmpbg62lqvl"
    (list lh-bifunctors lh-comonad lh-contravariant lh-distributive lh-semigroups lh-tagged lh-base-orphans)))

(define lh-transformers-base
  (release-haskell "transformers-base" "0.4.5.2"
    "1s256bi0yh0x2hp2gwd30f3mg1cv53zz397dv1yhfsnfzmihrj6h"
    (list lh-base-orphans lh-stm lh-transformers-compat)))

(define lh-mtl
  (release-haskell "mtl" "2.2.2"
    "1xmy5741h8cyy0d91ahvqdz2hykkk20l8br7lg1rccnkis5g80w8"
    '()))

(define lh-exceptions
  (release-haskell "exceptions" "0.10.1"
    "17fz74bi6qy3w7li7ifkcvsy3f9zyj69956jvaqvl5diyqnh791v"
    (list lh-stm lh-transformers-compat lh-mtl)))

(define lh-free
  (release-haskell "free" "5.1"
    "117axvibwyz429ixdws6mm3sk5vm0jygdxf45456m8yyh9f4shkh"
    (list lh-comonad lh-distributive lh-mtl lh-profunctors lh-semigroupoids lh-transformers-base lh-exceptions)))

(define lh-keys
  (release-haskell "keys" "3.12.1"
    "1yqm4gpshsgswx6w78z64c83gpydh6jhgslx2lnc10nzhy0s9kkz"
    (list lh-comonad lh-free lh-hashable lh-semigroupoids lh-semigroups lh-tagged lh-transformers-compat lh-unordered-containers)))

(define lh-enummapset
  (let ((library
         (release-haskell "enummapset" "0.6.0.1"
           "0nljpb5fxk4piwl5mh1v23ps9bzhxxcybfhd8mmb66k20gxxxf7q"
           (list lh-semigroups))))
    (package
      (inherit library)
      (arguments
       (substitute-keyword-arguments (package-arguments library)
         ((#:phases phases)
          #~(modify-phases #$phases
              (replace 'unpack
                (lambda* (#:key source #:allow-other-keys)
                  (use-modules (rnrs io ports) (rnrs bytevectors))
                  ;; Hackage's fixed archive contains a complete CRC-checked
                  ;; gzip member followed by this 42-byte MIME upload boundary.
                  ;; Validate the exact pinned layout; tar/gzip still checks the
                  ;; retained member normally.  Never ignore extraction errors.
                  (let* ((bytes (call-with-input-file source get-bytevector-all
                                 #:binary #t))
                         (boundary
                          (string->utf8
                           "\r\n-----------------------------15981274075")))
                    (unless (and (= (bytevector-length bytes) 12878)
                                 (let loop ((index 0))
                                   (or (= index 42)
                                       (and (= (bytevector-u8-ref boundary index)
                                               (bytevector-u8-ref bytes
                                                                  (+ 12836 index)))
                                            (loop (+ index 1))))))
                      (error "unexpected enummapset gzip upload trailer"))
                    (call-with-output-file "enummapset-member.tar.gz"
                      (lambda (port) (put-bytevector port bytes 0 12836))
                      #:binary #t))
                  (invoke "tar" "xvf" "enummapset-member.tar.gz")
                  (chdir "enummapset-0.6.0.1"))))))))))

(define lh-minimorph
  (release-haskell "minimorph" "0.2.1.0"
    "1phpsd0j8c987sw99p4hyywr4ydcxf5aq4h6xqdl3acwi0dv4zhj"
    '()))

(define lh-miniutter
  (release-haskell "miniutter" "0.5.0.0"
    "0hgsk54s07497rsgsck8lhpfbrxavx1chq90hsw14w3ggr1xnc7f"
    (list lh-minimorph lh-text)))

(define lh-haskell-lexer
  (release-haskell "haskell-lexer" "1.0.2"
    "1wyxd8x33x4v5vxyzkhm610pl86gbkc8y439092fr1735q9g7kfq"
    '()))

(define lh-pretty-show
  (release-haskell "pretty-show" "1.9.5"
    "0gs2pabi4qa4b0r5vffpf9b1cf5n9y2939a3lljjw7cmg6xvx5dh"
    (list lh-haskell-lexer)
    #:license license:expat
    #:native-inputs (list ghc-happy)))

(define lh-assert-failure
  (release-haskell "assert-failure" "0.1.2.2"
    "17aapnal893awjwfjw8lfk1n688sfkpckpvfb0rnjkvvabyid57n"
    (list lh-text lh-pretty-show)))

(define lh-parsec
  (release-haskell "parsec" "3.1.13.0"
    "1wc09pyn70p8z6llink10c8pqbh6ikyk554911yfwxv1g91swqbq"
    (list lh-mtl lh-text)
    #:revision '("2" "032sizm03m2vdqshkv4sdviyka05gqf8gs6r4hqf9did177i0qnm")))

(define lh-hsini
  (release-haskell "hsini" "0.5.1.2"
    "1r6qksnrmk18ndxs5zaga8b7kvmk34kp0kh5hwqmq797qrlax9pa"
    (list lh-mtl lh-parsec)))

(define lh-colour
  (release-haskell "colour" "2.3.4"
    "1sy51nz096sv91nxqk6yk7b92b5a40axv9183xakvki2nc09yhqg"
    '()
    #:license license:expat))

(define lh-ansi-terminal
  (release-haskell "ansi-terminal" "0.8.2"
    "147ss9wz03ww6ypbv6yh5vi1wfrfcaqm8r6nxh50vnp7254359wh"
    (list lh-colour)))

(define lh-ansi-wl-pprint
  (release-haskell "ansi-wl-pprint" "0.6.8.2"
    "0gnb4mkqryv08vncxnj0bzwcnd749613yw3cxfzw6y3nsldp4c56"
    (list lh-ansi-terminal)))

(define lh-optparse-applicative
  (release-haskell "optparse-applicative" "0.14.3.0"
    "0qvn1s7jwrabbpmqmh6d6iafln3v3h9ddmxj2y4m0njmzq166ivj"
    (list lh-transformers-compat lh-ansi-wl-pprint)))

(define lh-sdl2
  (release-haskell "sdl2" "2.4.1.0"
    "0p4b12fmxps0sbnkqdfy0qw19s355yrkw7fgw6xz53wzq706k991"
    (list lh-exceptions lh-statevar lh-text lh-vector sdl2)
    #:native-inputs (list pkg-config)
    #:flags '("-fno-linear")
    #:extra-directories '("sdl2")))

(define lh-sdl2-ttf
  (release-haskell "sdl2-ttf" "2.1.0"
    "1xw05jgv6x9xplahwf3jjdq6v3mha4s7bb27kn8x66764glnyrf7"
    (list lh-sdl2 lh-text sdl2 sdl2-ttf)
    #:native-inputs (list pkg-config)
    #:extra-directories '("sdl2-ttf")))

(define lh-async
  (release-haskell "async" "2.2.1"
    "09whscli1q5z7lzyq9rfk0bq1ydplh6pjmc6qv0x668k5818c2wg"
    (list lh-hashable lh-stm)
    #:revision '("1" "0lg8c3iixm7vjjq2nydkqswj78i4iyx2k83hgs12z829yj196y31")))

(define lh-zlib
  (release-haskell "zlib" "0.6.2"
    "1vbzf0awb6zb456xf48za1kl22018646cfzq4frvxgb9ay97vk0d"
    (list zlib)
    #:extra-directories '("zlib")))

(define lh-libraries
  (list lh-assert-failure lh-async lh-base-compat lh-enummapset
        lh-hashable lh-hsini lh-keys lh-miniutter
        lh-optparse-applicative lh-pretty-show lh-primitive lh-random
        lh-stm lh-text lh-unordered-containers lh-vector
        lh-vector-binary-instances lh-sdl2 lh-sdl2-ttf lh-zlib))

;; Static Haskell archives lose runtime references to their library packages.
;; Walk ordinary inputs, not only propagated edges, to retain every notice.
(define lh-notice-packages
  (let loop ((pending lh-libraries) (seen '()))
    (if (null? pending)
        (reverse seen)
        (let ((library (car pending)))
          (if (memq library seen)
              (loop (cdr pending) seen)
              (loop
               (append (filter (lambda (input)
                                 (and (package? input)
                                      (string-suffix? "-for-lambdahack"
                                                      (package-name input))))
                               (map cadr (package-inputs library)))
                       (cdr pending))
               (cons library seen)))))))

(define-public lambdahack
  (package
    (name "lambdahack")
    (version "0.9.5.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/LambdaHack/LambdaHack")
             (commit "aa894089399abe1a564a1ae6160a4751b6c61004")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "06dx7qm0m9d3k39swrz2mwjmxcipqf15x86kfpsl9ffx88nm07xh"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-8.6
           #:haddock? #f
           #:configure-flags #~'("-fsdl" "-f-vty" "-f-curses" "-f-gtk"
                                  "-f-jsaddle")
           #:phases
           #~(modify-phases %standard-phases
               (replace 'configure #$%release-haskell-configure)
               (add-before 'configure 'isolated-test-state
                 (lambda _
                   (let ((home (string-append (getcwd) "/test-home")))
                     (mkdir-p home)
                     (setenv "HOME" home)
                     (setenv "XDG_CONFIG_HOME" (string-append home "/config"))
                     (setenv "XDG_DATA_HOME" (string-append home "/data"))
                     (setenv "XDG_CACHE_HOME" (string-append home "/cache")))))
               ;; RuleKind uses Template Haskell to embed the configured font
               ;; directory.  Run the original suite after copy so its second
               ;; SDL initialization test reads the real installed font path.
               ;; Setting LambdaHack_datadir while compiling would instead
               ;; embed a temporary build directory in the shipped game.
               (delete 'check)
               (add-after 'install 'check
                 (assoc-ref %standard-phases 'check))
               (add-after 'install 'relocate-internal-library-runpaths
                 (lambda _
                   (use-modules (ice-9 popen) (ice-9 textual-ports)
                                (srfi srfi-1) (srfi srfi-13))
                   ;; Cabal 2.4 leaves internal sublibrary build directories in
                   ;; shared-library RUNPATHs.  Those libraries are installed
                   ;; beside each other, not in their old dist/build locations.
                   (let ((internal (map (lambda (name)
                                          (string-append (getcwd)
                                                         "/dist/build/" name))
                                        '("this-game-content" "definition"))))
                     (for-each
                      (lambda (file)
                        (let* ((pipe (open-pipe* OPEN_READ "patchelf"
                                                "--print-rpath" file))
                               (path (string-trim-right (get-string-all pipe))))
                          (unless (zero? (close-pipe pipe))
                            (error "cannot read shared-library RUNPATH" file))
                          (invoke "patchelf" "--set-rpath"
                                  (string-join
                                   (delete-duplicates
                                    (map (lambda (entry)
                                           (if (member entry internal)
                                               (dirname file) entry))
                                         (string-split path #\:)))
                                   ":") file)))
                      (find-files (string-append #$output "/lib") "\\.so$")))))
               (add-after 'check 'install-complete-notices
                 (lambda _
                   (let ((doc (string-append #$output "/share/doc/lambdahack")))
                     (for-each (lambda (file) (install-file file doc))
                               '("LICENSE" "COPYLEFT" "CREDITS" "README.md"
                                 "CHANGELOG.md" "GameDefinition/PLAYING.md"))
                     (copy-recursively "GameDefinition/fonts"
                                       (string-append doc "/fonts"))
                     (for-each
                      (lambda (directory)
                        (copy-recursively directory
                         (string-append doc "/dependencies/"
                                        (basename directory))))
                      '#$(map (lambda (input)
                                (file-append input "/share/doc/"
                                 (string-downcase
                                  (assoc-ref (package-properties input)
                                             'upstream-name))))
                              lh-notice-packages))
                     ;; Boot libraries are static as well.  Preserve relative
                     ;; paths in the compiler's original license tree.
                     (mkdir "compiler-notices")
                     (with-directory-excursion "compiler-notices"
                       (invoke "tar" "xf" #+(package-source ghc-8.6)
                               "--wildcards" "*LICENSE*")
                       (copy-recursively "."
                                         (string-append doc "/dependencies/ghc"))))
                   ;; getProgName determines upstream ~/.LambdaHack state.
                   ;; Both public spellings must execute the original basename.
                   (call-with-output-file
                       (string-append #$output "/bin/lambdahack")
                     (lambda (port)
                       (format port "#!~a\nexec ~a/bin/LambdaHack \"$@\"\n"
                               #$(file-append bash-minimal "/bin/sh")
                               #$output)))
                   (chmod (string-append #$output "/bin/lambdahack") #o555))))))
    (inputs lh-libraries)
    (native-inputs (list patchelf))
    (home-page "https://lambdahack.github.io")
    (synopsis "Tactical squad roguelike dungeon crawler")
    (description
     "LambdaHack is a fantasy dungeon crawler with tactical squad combat.
Explore procedurally generated levels, collect equipment, and direct a party
of adventurers.  This package builds the independently playable Haskell game
from its pinned source with the default SDL frontend, bundled fonts, original
campaigns, and native saving and restoring.")
    ;; COPYLEFT lists GPL-2-or-later for the bitmap fonts; CREDITS grants
    ;; LambdaHack's modifications GPL version 2 only.  Keep both notices and
    ;; conservatively describe those unmodified shipped fonts as GPL-2-only.
    (license (list license:bsd-3 license:gpl2 license:silofl1.1))))
