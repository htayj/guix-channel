;;; Private source closure for Allure 0.11 and LambdaHack 0.11.0.1.

(define-module (tay packages allure-dependencies)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system haskell)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sdl)
  #:export (release-haskell allure-libraries allure-test-libraries
            allure-notice-packages))

;; Every Haskell input is built with the game's compiler, not the channel's
;; current default ABI.  Sources and Cabal metadata follow lts-19.33, except
;; the six release-specific pins documented with the game.  Setup.hs uses only
;; the fixed Guix package database; no Cabal/Stack registry is consulted.
(define* (release-haskell upstream version hash inputs
                          #:key (license license:bsd-3)
                          (native-inputs '()) (flags '())
                          (extra-directories '()) (notices '("LICENSE"))
                          (revision #f))
  (package
    (name (string-append "ghc-" (string-downcase upstream) "-for-allure"))
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
     (list #:haskell ghc-9.0
           #:tests? #f
           #:haddock? #f
           #:cabal-revision revision
           #:configure-flags #~'#$flags
           #:extra-directories extra-directories
           #:phases
           #~(modify-phases %standard-phases
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
                    "source dependency closure of Allure of the Stars.  It "
                    "uses the same GHC 9.0.2 ABI as the native game."))
    (license license)))

;; Boot libraries (base, text, stm, bytestring, containers, exceptions,
;; mtl, parsec, transformers, etc.) come from the pinned GHC 9.0.2 itself.
;; These are actual Hackage archive hashes, not Stackage Cabal hashes.

(define allure-haskell-lexer
  (release-haskell "haskell-lexer" "1.1"
    "1mb3np20ig0hbgnfxrzr3lczq7ya4p76g20lvnxch8ikck61afii"
    '()))

(define allure-happy
  (release-haskell "happy" "1.20.0"
    "1346r2x5ravs5fqma65bzjragqbb2g6v41wz9maknwm2jf7kl79v"
    '()
    #:license license:bsd-2
    #:revision '("1" "16dy1cv942rizxp8slnnbwi5l24ggsmy38madbin9scz38idqisx")))

(define allure-pretty-show
  (release-haskell "pretty-show" "1.10"
    "1lkgvbv00v1amvpqli6y4dzsbs25l4v3wlagvhwx8qxhw2390zrh"
    (list allure-haskell-lexer)
    #:license license:expat
    #:native-inputs (list allure-happy)))

(define allure-assert-failure
  (release-haskell "assert-failure" "0.1.3.0"
    "0lbx22agc2rq119yf2d0fy5cchfbgvjln1w147iiwgvrqd0xgyff"
    (list allure-pretty-show)))

(define allure-hashable
  (release-haskell "hashable" "1.3.5.0"
    "11lqw6xbjzc1gpn4qlrqzq9kjgaw5pr7dgmx2rq1j6r7shndiams"
    '()
    #:revision '("1" "1mwilvbc5f4myxz4vj95kx6cqqn7nfjy99v8cmqdxy90napywars")
    #:notices '("LICENSE" "cbits/fnv.c")))

(define allure-async
  (release-haskell "async" "2.2.4"
    "09d7w3krfhnmf9dp6yffa9wykinhw541wibnjgnlyv77w1dzhka8"
    (list allure-hashable)
    #:revision '("2" "1j93w1krkadqijn59yjiws1366yhcn2mad1irqrk50in6l10k51b")))

(define allure-base-compat
  (release-haskell "base-compat" "0.11.2"
    "1nyvkaij4m01jndw72xl8931czz1xp6jpnynpajabys2ahabb9jk"
    '()
    #:license license:expat
    #:revision '("1" "0h6vr19vr5bhm69w8rvswbvd4xgazggkcq8vz934x69www2cpgri")))

(define allure-base-compat-batteries
  (release-haskell "base-compat-batteries" "0.11.2"
    "08rh9nlm9ir28fm42xim06ga8qwdqdcvkbb5ckz99bwnmajndq1i"
    (list allure-base-compat)
    #:license license:expat))

(define allure-base-orphans
  (release-haskell "base-orphans" "0.8.7"
    "0iz4v4h2ydncdwfqzs8fd2qwl38dx0n94w5iymw2g4xy1mzxd3w8"
    '()
    #:license license:expat))

(define allure-time-compat
  (release-haskell "time-compat" "1.9.6.1"
    "103b3vpn277kkccv6jv54b2wpi5c00mpb01ndl9w4y4nxc0bn1xd"
    (list allure-base-orphans allure-hashable)
    #:revision '("4" "1n39yfk21xz8y1xvkh01651yysk2zp5qac22l5pq2hi7scczmxaw")))

(define allure-integer-logarithms
  (release-haskell "integer-logarithms" "1.0.3.1"
    "0zzapclfabc76g8jzsbsqwdllx2zn0gp4raq076ib6v0mfgry2lv"
    '()
    #:license license:expat
    #:revision '("3" "0z81yksgx20d0rva41blsjcp3jsp1qy9sy385fpig0l074fzv6ym")))

(define allure-primitive
  (release-haskell "primitive" "0.7.3.0"
    "1p01fmw8yi578rvwicrlpbfkbfsv7fbnzb88a7vggrhygykgs31w"
    '()
    #:revision '("2" "0xh1m8nybz760c71gm1w9fga25y2rys1211q77v6wagdsas634yf")))

(define allure-scientific
  (release-haskell "scientific" "0.3.7.0"
    "1aa3ngb71l2sh1x2829napnr1w285q0sn2f7z2wvi3ynng2238d3"
    (list allure-hashable allure-integer-logarithms allure-primitive)
    #:revision '("3" "1n67w1b64q59nn4845z3kr8rm0x0p7bi3cyp6n1dpnfs8k4l8x2i")))

(define allure-attoparsec
  (release-haskell "attoparsec" "0.14.4"
    "0v4yjz4qi8bwhbyavqxlhsfb1iv07v10gxi64khmsmi4hvjpycrz"
    (list allure-scientific)
    #:revision '("2" "00jyrn2asz1kp698l3fyh19xxxz4npf1993y041x9b9cq239smn0")))

(define allure-data-fix
  (release-haskell "data-fix" "0.3.2"
    "1k0rcbb6dzv0ggdxqa2bh4jr829y0bczjrg98mrk5733q0xjs5rs"
    (list allure-hashable)
    #:revision '("3" "0z77i9y86wlc13396akl8qxq39rwpkhhcs5fadzk47bwn7v1gsmx")))

(define allure-dlist
  (release-haskell "dlist" "1.0"
    "0581a60xw4gw7pmqlmg5w2hr4hm9yjgx4c2z6v63y5xv51rn6g8p"
    '()
    #:notices '("license.md")))

(define allure-indexed-traversable
  (release-haskell "indexed-traversable" "0.1.2"
    "13b91rkhs6wcshaz3dwx6x3xjpw5z5bm2riwp78zxccqf7p5hs2i"
    '()
    #:license license:bsd-2
    #:revision '("2" "0l2k9jrmixkkf7qzzq0bqgvk6axaqi9sxxkpb4dgj8frmc4bg8aj")))

(define allure-onetuple
  (release-haskell "OneTuple" "0.3.1"
    "1vry21z449ph9k61l5zm7mfmdwkwszxqdlawlhvwrd1gsn13d1cq"
    (list allure-base-orphans)
    #:revision '("3" "0g4siv8s6dlrdsivap2qy6ig08y5bjbs93jk192zmgkp8iscncpw")))

(define allure-splitmix
  (release-haskell "splitmix" "0.1.0.4"
    "1apck3nzzl58r0b9al7cwaqwjhhkl8q4bfrx14br2yjf741581kd"
    '()
    #:revision '("1" "1iqlg2d4mybqwzwp67c5a1yxzd47cbp4f7mrpa6d0ckypis2akl0")))

(define allure-random
  (release-haskell "random" "1.2.1.1"
    "0xlv1k4sj87akwvj54kq4nrfkzi6qcz1941bf78pnkbaxpvp44iy"
    (list allure-splitmix)))

(define allure-quickcheck
  (release-haskell "QuickCheck" "2.14.2"
    "1wrnrm9sq4s0bly0q58y80g4153q45iglqa34xsi2q3bd62nqyyq"
    (list allure-random allure-splitmix)))

(define allure-tagged
  (release-haskell "tagged" "0.8.6.1"
    "00kcc6lmj7v3xm2r3wzw5jja27m4alcw1wi8yiismd0bbzwzrq7m"
    '()
    #:revision '("3" "19klgkhkca9qgq2ylc41z85x7piagjh8wranriy48dcfkgraw94a")))

(define allure-transformers-compat
  (release-haskell "transformers-compat" "0.6.6"
    "1yd936az31g9995frc84g05rrb5b7w59ajssc5183lp6wm8h4bky"
    '()))

(define allure-distributive
  (release-haskell "distributive" "0.6.2.1"
    "14bb66qyfn43bj688igfvnfjw7iycjf4n2k38sm8rxbqw2916dfp"
    (list allure-base-orphans allure-tagged)
    #:revision '("1" "033890dfyd23dh7g7px863l0hr1b881jnhv4kgwaq16a3iagb68g")))

(define allure-comonad
  (release-haskell "comonad" "5.0.8"
    "04rxycp2pbkrvhjgpgx08jmsipjz4cdmhv59dbp47k4jq8ndyv7g"
    (list allure-tagged allure-transformers-compat allure-distributive allure-indexed-traversable)
    #:revision '("1" "0zlgkcd61cwsdbgjz03pfbjxhj6dc25792h7rwh0zy677vbsn6hz")
    #:notices '("LICENSE" "comonad.cabal")))

(define allure-th-abstraction
  (release-haskell "th-abstraction" "0.4.5.0"
    "09hm0famyqsq09lal2ylnhsb31hybj8zanldi7cqncky4i7y5m80"
    '()
    #:license license:isc))

(define allure-bifunctors
  (release-haskell "bifunctors" "5.5.13"
    "1myvlzxk9xrm6vf9863wnv8py3ccgfxqxyc0sqxz0v3rwfnjgk16"
    (list allure-base-orphans allure-comonad allure-th-abstraction allure-tagged)))

(define allure-assoc
  (release-haskell "assoc" "1.0.2"
    "0kqlizznjy94fm8zr1ng633yxbinjff7cnsiaqs7m33ix338v66q"
    (list allure-bifunctors allure-tagged)
    #:revision '("3" "0mrb12dx316q4gxyn68x2rl8jq0gd77zffd12r8j1r41l0xd9f4k")))

(define allure-these
  (release-haskell "these" "1.1.1.1"
    "027m1gd7i6jf2ppfkld9qrv3xnxg276587pmx10z9phpdvswk66p"
    (list allure-hashable allure-assoc)
    #:revision '("6" "12ll5l8m482qkb8zn79vx51bqlwc89fgixf8jv33a32b4qzc3499")))

(define allure-unordered-containers
  (release-haskell "unordered-containers" "0.2.17.0"
    "05ss6ys9gp7dx93glhrm19fxdl916m7yaqxi6p06ibka1dp3m7n4"
    (list allure-hashable)))

(define allure-vector
  (release-haskell "vector" "0.12.3.1"
    "0dczbcisxhhix859dng5zhxkn3xvlnllsq60apqzvmyl5g056jpv"
    (list allure-primitive)
    #:revision '("2" "0gkzrqcx5fymkxm92gy47qj0spj79ygv1vn7kfzdg7nn284x1yzz")))

(define allure-indexed-traversable-instances
  (release-haskell "indexed-traversable-instances" "0.1.1.1"
    "1c60vhf47y8ln33scyvwiffg24dvhm4aavya624vbqjr7l3fapl9"
    (list allure-indexed-traversable allure-onetuple allure-tagged allure-unordered-containers allure-vector)
    #:license license:bsd-2))

(define allure-statevar
  (release-haskell "StateVar" "1.2.2"
    "098q4lk60najzpbfal4bg4sh7izxm840aa5h4ycaamjn77d3jjsy"
    '()))

(define allure-contravariant
  (release-haskell "contravariant" "1.5.5"
    "1ynz89vfn7czxpa203zmdqknkvpylzzl9rlkpasx1anph1jxcbq6"
    (list allure-statevar)))

(define allure-semigroupoids
  (release-haskell "semigroupoids" "5.3.7"
    "169pjrm7lxjxrqj5q1iyl288bx5nj8n0pf2ri1cclxccqnvcsibd"
    (list allure-base-orphans allure-bifunctors allure-transformers-compat allure-contravariant allure-distributive allure-comonad allure-tagged allure-hashable allure-unordered-containers)
    #:license license:bsd-2))

(define allure-semialign
  (release-haskell "semialign" "1.2.0.1"
    "0ci1jpp37p1lzyjxc1bljd6zgg407qmkl9s36b50qjxf85q6j06r"
    (list allure-these allure-hashable allure-indexed-traversable allure-indexed-traversable-instances allure-tagged allure-unordered-containers allure-vector allure-semigroupoids)
    #:revision '("3" "0dbcdnksik508i12arh3s6bis6779lx5f1df0jkc0bp797inhd7f")))

(define allure-strict
  (release-haskell "strict" "0.4.0.1"
    "0hb24a09c3agsq7sdv8r2b2jc2f4g1blg2xvj4cfadynib0apxnz"
    (list allure-hashable allure-these allure-assoc)
    #:revision '("4" "0pdzqhy7z70m8gxcr54jf04qhncl1jbvwybigb8lrnxqirs5l86n")))

(define allure-text-short
  (release-haskell "text-short" "0.1.5"
    "1nid00c1rg5c1z7l9mwk3f2izc2sps2mip2hl30q985dwb6wcpm3"
    (list allure-hashable)
    #:revision '("1" "0gmmwwchy9312kz8kr5jhiamqrnjqxdqg1wkrww4289yfj1p7dzb")))

(define allure-uuid-types
  (release-haskell "uuid-types" "1.0.5"
    "1pd7xd6inkmmwjscf7pmiwqjks9y0gi1p8ahqbapvh34gadvhs5d"
    (list allure-hashable allure-random)
    #:revision '("3" "10hpjshw6z8xnjpga47cazfdd4i27qvy4ash13lza2lmwf36k9ww")))

(define allure-witherable
  (release-haskell "witherable" "0.4.2"
    "0121ic4xkv3k568j23zp22a5lrv0k11h94fq7cbijd18fjr2n3br"
    (list allure-base-orphans allure-hashable allure-unordered-containers allure-vector allure-indexed-traversable allure-indexed-traversable-instances)
    #:revision '("3" "1f2bvl41by904lnr0dk6qgasqwadq2w48l7fj51bp2h8bqbkdjyc")))

(define allure-aeson
  (release-haskell "aeson" "2.0.3.0"
    "09dk0j33n262dm75vff3y3i9fm6lh06dyqswwv7a6kvnhhmhlxhr"
    (list allure-base-compat-batteries allure-time-compat allure-attoparsec allure-data-fix allure-dlist allure-hashable allure-indexed-traversable allure-onetuple allure-primitive allure-quickcheck allure-scientific allure-semialign allure-strict allure-tagged allure-text-short allure-th-abstraction allure-these allure-unordered-containers allure-uuid-types allure-vector allure-witherable)
    #:revision '("1" "1zrgn63jzrpk3n3vd44zkzgw7kb5qxlvhx4nk6g3sswwrsz5j32i")
    #:notices '("LICENSE" "cbits/unescape_string.c")))

(define allure-enummapset
  (release-haskell "enummapset" "0.7.3.0"
    "0w3hvypj14j7k8kfzrahyv7v35yj60jjyjv4klvnbw05a10hbj3l"
    (list allure-aeson)
    #:notices '("LICENSE" "Data/EnumMap.hs" "Data/EnumSet.hs")))

(define allure-file-embed
  (release-haskell "file-embed" "0.0.15.0"
    "1pavxj642phrkq67620g10wqykjfhmm9yj2rm8pja83sadfvhrph"
    '()
    #:license license:bsd-2))

(define allure-hsini
  (release-haskell "hsini" "0.5.2.2"
    "1qnzrh7nn4j8y2qcvmliqnv07bqfq49wpxmgwrvb87bpp70gaq2c"
    '()))

(define allure-witch
  (release-haskell "witch" "1.1.6.1"
    "1n4kckgk5v63bpjgky3dfgyayl82hlnxzwaa99pzyxrcjkpql5ay"
    (list allure-tagged)
    #:license license:expat
    #:notices '("LICENSE.markdown")))

(define allure-transformers-base
  (release-haskell "transformers-base" "0.4.6"
    "146g69yxmlrmvqnzwcw4frxfl3z04lda9zqwcqib34dnkrlghfrj"
    (list allure-transformers-compat allure-base-orphans)))

(define allure-profunctors
  (release-haskell "profunctors" "5.6.2"
    "0an9v003ivxmjid0s51qznbjhd5fsa1dkcfsrhxllnjja1xmv5b5"
    (list allure-base-orphans allure-bifunctors allure-comonad allure-contravariant allure-distributive allure-tagged)
    #:revision '("2" "1dhg8bys9qnfbvhy4cm4fivanmnik4rg0spshkwyp9s3j88qadix")))

(define allure-free
  (release-haskell "free" "5.1.9"
    "1vlzis9sqxh7xrmh3habbgiw3skkhkn710bhqb6fnl45804i6x9f"
    (list allure-comonad allure-distributive allure-indexed-traversable allure-semigroupoids allure-th-abstraction allure-transformers-base allure-profunctors)
    #:revision '("1" "133nycxnzy7sgp2vib8hpp2jgzm8pxp31ljf7b4v91jn1gqg3kpl")))

(define allure-semigroups
  (release-haskell "semigroups" "0.19.2"
    "0h1sl3i6k8csy5zkkpy65rxzds9wg577z83aaakybr3n1gcv4855"
    '()
    #:revision '("2" "0pprwlsipdsshr2h83bk0xjkhq2bw88m9fn44fiyas3habg25ajf")))

(define allure-keys
  (release-haskell "keys" "3.12.3"
    "0ik6wsff306dnbz0v3gpiajlj5b558hrk9176fzcb2fclf4447nm"
    (list allure-comonad allure-free allure-hashable allure-semigroupoids allure-semigroups allure-tagged allure-transformers-compat allure-unordered-containers)
    #:revision '("2" "1sb7ii9mhx77rhviqbmdc5r6wlimkmadxi1pyk7k3imdqcdzgjlp")))

(define allure-minimorph
  (release-haskell "minimorph" "0.3.0.1"
    "05z2y36q2m7lvrqnv5q40r8nr09q7bfbjvi5nca62xlnzxw1gy0g"
    '()))

(define allure-miniutter
  (release-haskell "miniutter" "0.5.1.2"
    "04xpb9jyhvi8cs61xv3192kwis4nh1dib4s33c747j8yfg3q90m6"
    (list allure-minimorph)))

(define allure-open-browser
  (release-haskell "open-browser" "0.2.1.0"
    "0rna8ir2cfp8gk0rd2q60an51jxc08lx4gl0liw8wwqgh1ijxv8b"
    '()))

(define allure-colour
  (release-haskell "colour" "2.3.6"
    "0wgqj64mh2y2zk77kv59k3xb3dk4wmgfp988y74sp9a4d76mvlrc"
    '()
    #:license license:expat))

(define allure-ansi-terminal
  (release-haskell "ansi-terminal" "0.11.3"
    "0swy5alj4xvfsnjrfiwxdlgzdnggjy6lgbfwph2d7c8zyzn67mgl"
    (list allure-colour)))

(define allure-ansi-wl-pprint
  (release-haskell "ansi-wl-pprint" "0.6.9"
    "1b2fg8px98dzbaqyns10kvs8kn6cl1hdq5wb9saz40izrpkyicm7"
    (list allure-ansi-terminal)
    #:revision '("3" "1km10sx7ldyv1vfyljik1gqnrwl7bnq2s5m40w41gc930vm48891")))

(define allure-optparse-applicative
  (release-haskell "optparse-applicative" "0.16.1.0"
    "16nnrkmgd28h540f17nb017ziq4gbzgkxpdraqicaczkca1jf1b2"
    (list allure-transformers-compat allure-ansi-wl-pprint)
    #:revision '("2" "0ccpk2nb9fvj97z00w8cmlpw4fn94ayndg4ngm2ls4hrdbnj5321")))

(define allure-vector-binary-instances
  (release-haskell "vector-binary-instances" "0.2.5.2"
    "0kgmlb4rf89b18d348cf2k06xfhdpamhmvq7iz5pab5014hknbmp"
    (list allure-vector)
    #:revision '("2" "149gn5n722r2skj5w46av3944fbw3882qkaydq7asm6zx5kc0nj6")))

(define allure-th-lift
  (release-haskell "th-lift" "0.8.2"
    "1r2wrnrn6qwy6ysyfnlqn6xbfckw0b22h8n00pk67bhhg81jfn9s"
    (list allure-th-abstraction)
    #:revision '("2" "1s95i774zy3q8yzk18ygdzhzky6wfcr7g55hd2g8h8lc05xzcdgi")
    #:notices '("COPYING" "BSD3" "GPL-2")))

(define allure-th-lift-instances
  (release-haskell "th-lift-instances" "0.1.20"
    "0w6qc7xzyjymhh8hv72rlszh3n2xyzzamlfcl1hs9k6xbbww6czm"
    (list allure-th-lift allure-vector)))

(define allure-ghc-compact
  (release-haskell "ghc-compact" "0.1.0.0"
    "03sf8ap1ncjsibp9z7k9xgcsj9s0q3q6l4shf8k7p8dkwpjl1g2h"
    '()
    #:revision '("6" "1v4mbhxggd8nnl76nhgvi7sngb10pshblvw8a2b41fh5y0ips7pm")))

(define allure-zlib
  (release-haskell "zlib" "0.6.3.0"
    "1nh4xsm3kgsg76jmkcphvy7hhslg9hx1s75mpsskhi2ksjd9ialy"
    (list zlib)
    #:extra-directories '("zlib")))

(define allure-sdl2
  (release-haskell "sdl2" "2.5.3.0"
    "08l24cb92spnx3bn26bj0z2cszpsawhaa9vvhblvsr3d6z76065q"
    (list allure-statevar allure-vector sdl2)
    #:native-inputs (list pkg-config)
    #:flags '("-fno-linear")
    #:extra-directories '("sdl2")
    #:notices '("LICENSE" "src/SDL/Internal/Vect.hs")))

(define allure-sdl2-ttf
  (release-haskell "sdl2-ttf" "2.1.3"
    "0sm5lrdif5wmz3iah1658zlr7yr45d1hfihb2hdxdia4h7z1j0mn"
    (list allure-sdl2 allure-th-abstraction sdl2 sdl2-ttf)
    #:license (list license:bsd-3 license:expat)
    #:native-inputs (list pkg-config)
    #:extra-directories '("sdl2" "sdl2-ttf")))

(define allure-unbounded-delays
  (release-haskell "unbounded-delays" "0.1.1.1"
    "11b1vmlfv4pmmpl4kva58w7cf50xsj819cq3wzqgnbz3px9pxbar"
    '()))

(define allure-clock
  (release-haskell "clock" "0.8.3"
    "1l850pf1dxjf3i15wc47d64gzkpzgvw0bq13fd8zvklq9kdyap44"
    '()
    #:notices '("LICENSE" "clock.cabal")))

(define allure-wcwidth
  (release-haskell "wcwidth" "0.0.2"
    "1n1fq7v64b59ajf5g50iqj9sa34wm7s2j3viay0kxpmvlcv8gipz"
    '()))

(define allure-tasty
  (release-haskell "tasty" "1.4.2.3"
    "1inhrayiqhd3k14b9cnjcv5kdxb95sgk8b0ibbf37z4dlalsf569"
    (list allure-ansi-terminal allure-optparse-applicative allure-tagged allure-unbounded-delays allure-clock allure-wcwidth)
    #:license (list license:expat license:bsd-3)
    #:notices '("LICENSE" "Control/Concurrent/Async.hs"
                "Test/Tasty/Patterns/Expr.hs"
                "Test/Tasty/Runners/Reducers.hs")))

(define allure-call-stack
  (release-haskell "call-stack" "0.4.0"
    "0yxq6v37kcmgv6rrna4g1ipr8mhkgf00ng2p359ybxq46j5cy2s3"
    '()
    #:license license:expat))

(define allure-tasty-hunit
  (release-haskell "tasty-hunit" "0.10.0.3"
    "0gz6zz3w7s44pymw33xcxnawryl27zk33766sab96nz2xh91kvxp"
    (list allure-tasty allure-call-stack)
    #:license license:expat))

(define allure-tasty-quickcheck
  (release-haskell "tasty-quickcheck" "0.10.2"
    "1qnc6rdvjvlw08q6sln2n98rvj0s0pp689h6w4z58smjbn0lr25l"
    (list allure-quickcheck allure-optparse-applicative allure-random allure-tagged allure-tasty)
    #:license license:expat))

;; The union of both releases' direct libraries, including native SDL branches.
(define allure-libraries
  (list allure-assert-failure allure-async allure-base-compat allure-enummapset allure-file-embed allure-hashable allure-hsini allure-witch allure-keys allure-miniutter allure-open-browser allure-optparse-applicative allure-pretty-show allure-primitive allure-quickcheck allure-splitmix allure-unordered-containers allure-vector allure-vector-binary-instances allure-th-lift-instances allure-ghc-compact allure-zlib allure-sdl2 allure-sdl2-ttf allure-ansi-terminal))

(define allure-test-libraries
  (list allure-tasty allure-tasty-hunit allure-tasty-quickcheck))

;; Static Haskell archives erase references to library outputs.  Retain every
;; private runtime and build-helper copyright notice, including native edges.
(define allure-notice-packages
  (let loop ((pending (append allure-libraries allure-test-libraries))
             (seen '()))
    (if (null? pending)
        (reverse seen)
        (let ((library (car pending)))
          (if (memq library seen)
              (loop (cdr pending) seen)
              (loop
               (append
                (filter (lambda (input)
                          (and (package? input)
                               (string-suffix? "-for-allure"
                                               (package-name input))))
                        (map cadr
                             (append (package-inputs library)
                                     (package-native-inputs library)
                                     (package-propagated-inputs library))))
                (cdr pending))
               (cons library seen)))))))
