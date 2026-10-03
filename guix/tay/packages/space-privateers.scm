;;; Source-native Space Privateers and its release-specific Haskell closure.

(define-module (tay packages space-privateers)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system haskell)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages ncurses))

;; Cabal 1.24 names static Haskell archives "vanilla libraries".  Guix's
;; modern --enable-static spelling is only accepted by later Cabal releases.
;; Keep the other standard configure semantics, including shared libraries
;; and statically linked executables, with the explicit legacy spelling.
(define %legacy-haskell-configure
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

;; This 2014 engine uses the pre-5 Vty API and the original random generator.
;; Keep one GHC 8.0 ABI throughout the private closure.  Setup.hs consumes only
;; these fixed archives and the compiler's boot libraries, never a Cabal index.
;; Private library test harnesses require additional obsolete Hackage packages;
;; the engine's own offline campaign test is enabled below.
(define* (private-haskell upstream version hash inputs
                          #:key (license license:bsd-3)
                          (native-inputs '()) (flags '()) (tests? #f)
                          (compatibility '()) (extra-directories '()))
  (package
    (name (string-append "ghc-" (string-downcase upstream)
                         "-for-space-privateers"))
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
     (list #:haskell ghc-8.0
           #:tests? tests?
           #:haddock? #f
           #:configure-flags #~'#$flags
           #:extra-directories extra-directories
           #:phases
           #~(modify-phases %standard-phases
               (replace 'configure #$%legacy-haskell-configure)
               (add-before 'configure 'compatibility-and-test-home
                 (lambda _
                   (setenv "HOME" (getcwd))
                   (for-each
                    (lambda (replacement)
                      (substitute* (find-files "." "\\.cabal$")
                        (((car replacement)) (cadr replacement))))
                    '#$compatibility)))
               (add-after 'install 'install-notices
                 (lambda _
                   (let ((doc (string-append #$output "/share/doc/"
                                             #$(string-downcase upstream))))
                     (for-each
                      (lambda (file)
                        (when (file-exists? file) (install-file file doc)))
                      '("LICENSE" "COPYING" "CREDITS" "AUTHORS"))))))))
    (inputs inputs)
    (native-inputs native-inputs)
    (properties `((hidden? . #t) (upstream-name . ,upstream)))
    (home-page (string-append "https://hackage.haskell.org/package/" upstream))
    (synopsis (string-append "Release-specific " upstream " library"))
    (description
     (string-append "This private " upstream " library supplies the pinned "
                    "source dependency closure of Space Privateers.  It is "
                    "built with the same compiler as its game engine."))
    (license license)))

(define sp-text
  (private-haskell "text" "1.2.2.2"
    "1y9d0zjs2ls0c574mr5xw7y3y49s62sd3wcn9lhpwz8a6q352iii" '()
    #:license license:bsd-2))
(define sp-mtl
  (private-haskell "mtl" "2.2.2"
    "1xmy5741h8cyy0d91ahvqdz2hykkk20l8br7lg1rccnkis5g80w8" '()))
(define sp-stm
  (private-haskell "stm" "2.4.4.1"
    "111kpy1d6f5c0bggh6hyfm86q5p8bq1qbqf6dw2x4l4dxnar16cg" '()))
(define sp-parsec
  (private-haskell "parsec" "3.1.11"
    "0vk7q9j2128q191zf1sg0ylj9s9djwayqk9747k0a5fin4f2b1vg"
    (list sp-mtl sp-text)))

(define sp-transformers-compat
  (private-haskell "transformers-compat" "0.5.1.4"
    "17yam0199fh9ndsn9n69jx9nvbsmymzzwbi23dck3dk4q57fz0fq" '()))
(define sp-tagged
  (private-haskell "tagged" "0.8.5"
    "16cdzh0bw16nvjnyyy5j9s60malhz4nnazw96vxb0xzdap4m2z74"
    (list sp-transformers-compat)))
(define sp-semigroups
  (private-haskell "semigroups" "0.18.3"
    "1jm9wnb5jmwdk4i9qbwfay69ydi76xi0qqi9zqp6wh3jd2c7qa9m" '()))
(define sp-base-orphans
  (private-haskell "base-orphans" "0.6"
    "03mdww5j0gwai7aqlx3m71ldmjcr99jzpkcclzjfclk6a6kjla67" '()
    #:license license:expat))
(define sp-cabal-doctest
  (private-haskell "cabal-doctest" "1.0.6"
    "0bgd4jdmzxq5y465r4sf4jv2ix73yvblnr4c9wyazazafddamjny" '()))
(define sp-void
  (private-haskell "void" "0.7.2"
    "0aygw0yb1h3yhmfl3bkwh5d3h0l4mmsxz7j53vdm6jryl1kgxzyk" '()))
(define sp-statevar
  (private-haskell "StateVar" "1.1.0.4"
    "1dzz9l0haswgag9x56q7n57kw18v7nhmzkjyr61nz9y9npn8vmks"
    (list sp-stm)))
(define sp-contravariant
  (private-haskell "contravariant" "1.4"
    "117fff8kkrvlmr8cb2jpj71z7lf2pdiyks6ilyx89mry6zqnsrp1"
    (list sp-transformers-compat sp-void sp-statevar sp-semigroups)))
(define sp-distributive
  (private-haskell "distributive" "0.5.3"
    "0y566r97sfyvhsmd4yxiz4ns2mqgwf5bdbp56wgxl6wlkidq0wwi"
    (list sp-base-orphans sp-transformers-compat sp-tagged)
    #:native-inputs (list sp-cabal-doctest)))
(define sp-comonad
  (private-haskell "comonad" "5.0.2"
    "115pai560rllsmym76bj787kwz5xx19y8bl6262005nddqwzxc0v"
    (list sp-semigroups sp-tagged sp-transformers-compat
          sp-contravariant sp-distributive)
    #:native-inputs (list sp-cabal-doctest)))
(define sp-bifunctors
  (private-haskell "bifunctors" "5.4.2"
    "13fwvw1102ik96pgi85i34kisz1h237vgw88ywsgifsah9kh4qiq"
    (list sp-base-orphans sp-comonad sp-transformers-compat
          sp-tagged sp-semigroups)))
(define sp-hashable
  (private-haskell "hashable" "1.2.7.0"
    "1gra8gq3kb7b2sd845h55yxlrfqx3ii004c6vjhga8v0b30fzdgc"
    (list sp-text)))
(define sp-unordered-containers
  (private-haskell "unordered-containers" "0.2.9.0"
    "0l4264p0av12cc6i8gls13q8y27x12z2ar4x34n3x59y99fcnc37"
    (list sp-hashable)))
(define sp-semigroupoids
  (private-haskell "semigroupoids" "5.2.1"
    "006jys6kvckkmbnhf4jc51sh64hamkz464mr8ciiakybrfvixr3r"
    (list sp-base-orphans sp-bifunctors sp-semigroups sp-transformers-compat
          sp-contravariant sp-distributive sp-comonad sp-tagged
          sp-hashable sp-unordered-containers)
    #:native-inputs (list sp-cabal-doctest)))
(define sp-profunctors
  (private-haskell "profunctors" "5.2.1"
    "0pcwjp813d3mrzb7qf7dzkspf85xnfj1m2snhjgnvwx6vw07w877"
    (list sp-base-orphans sp-bifunctors sp-comonad sp-contravariant
          sp-distributive sp-tagged)))
(define sp-prelude-extras
  (private-haskell "prelude-extras" "0.4.0.3"
    "0xzqdf3nl2h0ra4gnslm1m1nsxlsgc0hh6ky3vn578vh11zhifq9" '()))
(define sp-exceptions
  (private-haskell "exceptions" "0.8.3"
    "1gl7xzffsqmigam6zg0jsglncgzxqafld2p6kb7ccp9xirzdjsjd"
    (list sp-transformers-compat sp-stm sp-mtl)))
(define sp-free
  (private-haskell "free" "4.12.4"
    "1147s393442xf4gkpbq0rd1p286vmykgx85mxhk5d1c7wfm4bzn9"
    (list sp-bifunctors sp-comonad sp-distributive sp-prelude-extras
          sp-profunctors sp-semigroupoids sp-semigroups
          sp-transformers-compat sp-exceptions sp-mtl)))
(define sp-keys
  (private-haskell "keys" "3.11"
    "1cn45h27hxwb4ci1iyd2qn0fzyb2y85qq4821a9xm37bwsvrgwqc"
    (list sp-comonad sp-free sp-hashable sp-semigroupoids
          sp-semigroups sp-transformers-compat sp-unordered-containers)))
(define sp-enummapset-th
  (private-haskell "enummapset-th" "0.6.1.1"
    "0anmarswk8vvd9c8qhkhgwzmr5h2yq0bdx48ww5lbca1zf6h5hkw" '()))
(define sp-async
  (private-haskell "async" "2.1.1.1"
    "1qj4fp1ynwg0l453gmm27vgkzb5k5m2hzdlg5rdqi9kf8rqy90yd"
    (list sp-stm)))
(define sp-hsini
  (private-haskell "hsini" "0.5.1.2"
    "1r6qksnrmk18ndxs5zaga8b7kvmk34kp0kh5hwqmq797qrlax9pa"
    (list sp-mtl sp-parsec)))
(define sp-haskell-lexer
  (private-haskell "haskell-lexer" "1.0.1"
    "0rj3r1pk88hh3sk3mj61whp8czz5kpxhbc78xlr04bxwqjrjmm6p" '()
    #:license license:expat))
(define sp-pretty-show
  (private-haskell "pretty-show" "1.6.13"
    "1kbx72ybrpw0kh5zsd2kdw143qykbmd9lgmsvj57659y0k5l7fjm"
    (list sp-haskell-lexer)
    #:native-inputs (list ghc-happy)
    #:license license:expat))
(define sp-assert-failure
  (private-haskell "assert-failure" "0.1.1.0"
    "09djlhhyn9w822a5r41y7gk4cqk74a2fy7skzml2bah2an166gm1"
    (list sp-pretty-show sp-text)))
(define sp-minimorph
  (private-haskell "minimorph" "0.1.6.0"
    "17ds0bjpyz7ngsq7nnlqix6yjfr6clr7xkwgpg4fysii7qvymbkz"
    (list sp-text)))
(define sp-miniutter
  (let ((library
         (private-haskell "miniutter" "0.4.3.0"
           "0hslks4vr1738pczgzzcl0mrb9jqs1986vjgw4xpvzz9p3ki1n50"
           (list sp-minimorph sp-text))))
    (package
      (inherit library)
      (arguments
       (substitute-keyword-arguments (package-arguments library)
         ((#:phases phases)
          #~(modify-phases #$phases
              (add-before 'configure 'use-text-binary-instance
                (lambda _
                  ;; text 1.2 serializes the same UTF-8 ByteString as this
                  ;; obsolete orphan.  Valid save bytes are unchanged; its
                  ;; decoder reports malformed UTF-8 through Binary's Get.
                  (substitute* "NLP/Miniutter/English.hs"
                    (("import Data.Text.Encoding \\(decodeUtf8, encodeUtf8\\)") "")
                    (("instance Binary Text where") "")
                    (("   put = put . encodeUtf8") "")
                    (("   get = decodeUtf8 `fmap` get") "")))))))))))
(define sp-old-locale
  (private-haskell "old-locale" "1.0.0.7"
    "0l3viphiszvz5wqzg7a45zp40grwlab941q5ay29iyw8p3v8pbyv" '()
    #:compatibility '(("< 4.9" "< 4.10"))))
(define sp-old-time
  (private-haskell "old-time" "1.1.0.3"
    "1h9b26s3kfh2k0ih4383w90ibji6n0iwamxp6rfp2lbq1y5ibjqw"
    (list sp-old-locale)
    #:compatibility '(("< 4.9" "< 4.10"))))
(define sp-random
  (private-haskell "random" "1.1"
    "0nis3lbkp8vfx8pkr6v7b7kr5m334bzb0fk9vxqklnp2aw8a865p" '()
    #:tests? #t))
(define sp-primitive
  (private-haskell "primitive" "0.6.3.0"
    "0mcmbnj08wd6zfwn7xk6zf5hy5zwbla5v78pw0dpymqg9s0gzpnd" '()
    #:tests? #t))
(define sp-vector
  (private-haskell "vector" "0.12.0.1"
    "0yrx2ypiaxahvaz84af5bi855hd3107kxkbqc8km29nsp5wyw05i"
    (list sp-primitive)))
(define sp-vector-binary-instances
  (private-haskell "vector-binary-instances" "0.2.3.5"
    "0niad09lbxz3cj20qllyj92lwbc013ihw4lby8fv07x5xjx5a4p1"
    (list sp-vector)))
(define sp-zlib
  (private-haskell "zlib" "0.6.1.2"
    "1fx2k2qmgm2dj3fkxx2ry945fpdn02d4dkihjxma21xgdiilxsz4"
    (list zlib)
    #:extra-directories '("zlib")))
(define sp-parallel
  (private-haskell "parallel" "3.2.1.1"
    "05rw8zhpqhx31zi6vg7zpyciaarh24j7g2p613xrpyrnksybjfrj" '()))
(define sp-utf8-string
  (private-haskell "utf8-string" "0.3.8"
    "1h29dn0scsfkhmkg14ywq9178lw40ah1r36w249zfzqr02y7qxc0" '()
    #:compatibility '(("< 4.8" "< 4.10"))))
(define sp-vty
  (private-haskell "vty" "4.7.5"
    "0ahd5qjszfw1xbl5jxhzfw31mny8hp8clw9qciv15xn442prvvpr"
    (list sp-parallel sp-utf8-string sp-vector sp-mtl sp-parsec ncurses)
    #:compatibility
    '(("< 1.4" "< 1.5") ("< 2.2" "< 2.3")
      ;; This developer-only demonstration requires string-qq; it is not
      ;; part of the frontend library or the game.
      ("executable vty-interactive-terminal-test"
       "executable vty-interactive-terminal-test\n  buildable: False"))))

(define sp-libraries
  (list sp-assert-failure sp-async sp-enummapset-th sp-hashable sp-hsini
        sp-keys sp-miniutter sp-old-time sp-pretty-show sp-random
        sp-unordered-containers sp-vector sp-vector-binary-instances sp-zlib
        sp-vty sp-text sp-mtl sp-stm))

(define sp-lambdahack
  (let ((engine
         (private-haskell "LambdaHack" "0.2.14"
           "1nygyzrgzrv7qfr153xvkh50p0sjrbv3jbif7qmpam5jjlw26ahs"
           sp-libraries #:tests? #t #:flags '("-fvty"))))
    (package
      (inherit engine)
      (arguments
       (substitute-keyword-arguments (package-arguments engine)
         ((#:phases phases)
          #~(modify-phases #$phases
              (add-before 'configure 'retain-deepseq-1.3-default
                (lambda _
                  ;; deepseq 1.4 changed the default rnf to require Generic.
                  ;; Preserve the original 1.3 WHNF instance semantics.
                  (substitute* "Game/LambdaHack/Client/UI/Config.hs"
                    (("instance NFData Config")
                     "instance NFData Config where\n  rnf cfg = cfg `seq` ()"))
                  ;; G.stream now yields a Bundle rather than the old
                  ;; Stream.  Bundle.indexed and foldl1' preserve the strict
                  ;; left fold and last-tie selection without materializing
                  ;; an intermediate vector.
                  ;; Msg derives Overlay's Binary instance directly: import
                  ;; the same vector serializer already used by PointArray,
                  ;; rather than relying on accidental transitive visibility.
                  (substitute* "Game/LambdaHack/Common/Msg.hs"
                    (("import Data.Binary")
                     "import Data.Binary\nimport Data.Vector.Binary ()"))
                  ;; Part is not a Monoid: :> is upstream's no-space
                  ;; grammatical concatenation constructor (e.g. "10kg").
                  (substitute* "Game/LambdaHack/Common/ItemDescription.hs"
                    (("MU.Text scaledWeight <> unitWeight")
                     "MU.Text scaledWeight MU.:> unitWeight"))
                  (substitute* "Game/LambdaHack/Common/PointArray.hs"
                    (("Data.Vector.Fusion.Stream as Stream")
                     "Data.Vector.Fusion.Bundle as Bundle")
                    (("Stream.foldl1'") "Bundle.foldl1'")
                    (("Stream.indexed") "Bundle.indexed")))))))))))

;; Static linking requires keeping each library's redistribution notice with
;; the executable, even when its runtime store reference has been eliminated.
(define sp-notice-packages
  ;; package-transitive-inputs follows only propagated edges, whereas these
  ;; static Haskell libraries use ordinary inputs.  Visit every private
  ;; library's direct inputs so e.g. keys/free/comonad notices are retained.
  (let loop ((pending (list sp-lambdahack)) (seen '()))
    (if (null? pending)
        (reverse seen)
        (let ((library (car pending)))
          (if (memq library seen)
              (loop (cdr pending) seen)
              (loop
               (append (filter (lambda (input)
                                 (and (package? input)
                                      (string-suffix?
                                       "-for-space-privateers"
                                       (package-name input))))
                               (map cadr (package-inputs library)))
                       (cdr pending))
               (cons library seen)))))))

(define-public space-privateers
  (package
    (name "space-privateers")
    (version "0.1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://hackage-content.haskell.org/package/"
                           "SpacePrivateers-" version "/SpacePrivateers-"
                           version ".tar.gz"))
       (sha256
        (base32 "0gj709knv4lvz34900jigb1hiq35acbbl86iwa5yszibm8f0drkh"))))
    (build-system haskell-build-system)
    (arguments
     (list #:haskell ghc-8.0
           #:haddock? #f
           #:phases
           #~(modify-phases %standard-phases
               (replace 'configure #$%legacy-haskell-configure)
               (add-before 'configure 'accept-ghc-8-base
                 (lambda _
                   ;; No game API changed: permit the compiler's base 4.9.
                   (substitute* "SpacePrivateers.cabal"
                     (("<4.8") "<4.10"))))
               (add-after 'install 'install-game-and-engine-notices
                 (lambda _
                   (let ((doc (string-append #$output
                                             "/share/doc/space-privateers")))
                     (for-each (lambda (file) (install-file file doc))
                               '("LICENSE" "CREDITS" "README.md" "changelog"))
                     (install-file "GameDefinition/PLAYING.md" doc)
                     (copy-recursively
                      #$(file-append sp-lambdahack "/share/doc/lambdahack")
                      (string-append doc "/LambdaHack")))
                   (for-each
                    (lambda (directory)
                      (copy-recursively directory
                                        (string-append #$output
                                         "/share/doc/space-privateers/dependencies/"
                                         (basename directory))))
                    '#$(map (lambda (input)
                              (file-append input "/share/doc/"
                                           (string-downcase
                                            (assoc-ref (package-properties input)
                                                       'upstream-name))))
                            sp-notice-packages))
                   ;; GHC boot libraries are linked statically too.  Preserve
                   ;; every original license from the pinned compiler source,
                   ;; retaining relative paths to distinguish library notices.
                   (mkdir "compiler-notices")
                   (with-directory-excursion "compiler-notices"
                     (invoke "tar" "xf" #+(package-source ghc-8.0)
                             "--wildcards" "*LICENSE*")
                     (copy-recursively "."
                       (string-append #$output
                         "/share/doc/space-privateers/dependencies/ghc")))
                   ;; Execute the original basename so both public spellings
                   ;; use upstream ~/.SpacePrivateers, not ~/.space.
                   (call-with-output-file
                       (string-append #$output "/bin/space-privateers")
                     (lambda (port)
                       (format port "#!~a\nexec ~a/bin/SpacePrivateers \"$@\"\n"
                               #$(file-append bash-minimal "/bin/sh")
                               #$output)))
                   (chmod (string-append #$output "/bin/space-privateers")
                          #o555))))))
    (inputs (list sp-lambdahack sp-enummapset-th sp-text))
    (home-page "https://github.com/tuturto/space-privateers")
    (synopsis "Space pirate roguelike aboard a merchant city vessel")
    (description
     "Space Privateers is a squad-based roguelike set in the far future.
Explore a merchant city vessel, fight its inhabitants, and plunder loot before
escaping.  This package compiles the original Haskell game and its LambdaHack
0.2.14 engine with the interactive Vty terminal frontend.  Original campaign
content, configuration, high scores, and native saving and restoring are retained.")
    (license license:bsd-3)))
