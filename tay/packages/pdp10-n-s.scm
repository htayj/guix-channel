;;; PDP-10 public source snapshots, N--S.

(define-module (tay packages pdp10-n-s)
  #:use-module (tay packages source-snapshot)
  #:export (pdp10-old-bits-source pdp10-panda-source pdp10-rogue-source
            pdp10-rsh-source pdp10-rutgers-common-lisp-source
            pdp10-rutgers-elisp-source pdp10-rutgers-pascal-source
            pdp10-sitbol-source pdp10-snyder-c-compiler-source
            pdp10-spacewar-source pdp10-stacken-source pdp10-suds-source
            pdp10-supdup-source pdp10-suppty-source pdp10-sri-nic-source
            pdp10-system1022-source))

;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-old-bits-source (make-github-source-snapshot "pdp10-old-bits-source" "pdp10" "PDP-10" "old-bits" "60251c8e27fd8d929bdffe4e6b20e404dc9b639f" "0h9vcvl6lxvhn5cs614fcydi3nv9dym41x2hsr8y5hq1j59qya53" "Source snapshot of ancient PDP-10 code" "https://github.com/PDP-10/old-bits" #f))
(define-public pdp10-panda-source (make-github-source-snapshot "pdp10-panda-source" "pdp10" "PDP-10" "panda" "378f05b83532948c9c294c359b1fb47e5e6f417e" "0k9qfr0kr0bg4hib5iazrik0j97zfrwlx7sxdk4xij729fqpigys" "Source snapshot of the Panda TOPS-20 distribution" "https://github.com/PDP-10/panda" #f))
;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-rogue-source (make-github-source-snapshot "pdp10-rogue-source" "pdp10" "PDP-10" "Rogue" "87a45aefb13ec4f7ef5d998c2fae3f729e60b982" "1wwqvq1shq07wiz1ca9skvvs5jzji1fhpn4wr2m4i6p71jj6k4p8" "Source snapshot of ECL Rogue" "https://github.com/PDP-10/Rogue" #f))
(define-public pdp10-rsh-source (make-github-source-snapshot "pdp10-rsh-source" "pdp10" "PDP-10" "rsh" "eb120e076edd9edb9bbc38e420a0594ddd4ebbea" "1kl68zzg24k7byibykf5mvi3rlf7zsc006g6mc9l67xxylgaynwv" "Source snapshot of TOPS-20 remote shell support" "https://github.com/PDP-10/rsh" #f))
(define-public pdp10-rutgers-common-lisp-source (make-github-source-snapshot "pdp10-rutgers-common-lisp-source" "pdp10" "PDP-10" "rutgers-common-lisp" "eea89786584cd85051c6dea4162a42755dc28a1f" "1i797bwrdmva0xxar2zvkcsql9xf9mpkbmjjcyl0x4pdfyxqyqkl" "Source snapshot of Rutgers TOPS-20 Common Lisp" "https://github.com/PDP-10/rutgers-common-lisp" #f))
(define-public pdp10-rutgers-elisp-source (make-github-source-snapshot "pdp10-rutgers-elisp-source" "pdp10" "PDP-10" "rutgers-elisp" "e841eeeb945f3cd390c9419eb3f16a3affc068c2" "09cighxiwkf461bw12lhv7s2yl76a2ndliyxmg4rd38xs3padh3w" "Source snapshot of Rutgers extended Lisp" "https://github.com/PDP-10/rutgers-elisp" #f))
(define-public pdp10-rutgers-pascal-source (make-github-source-snapshot "pdp10-rutgers-pascal-source" "pdp10" "PDP-10" "rutgers-pascal" "09610603ff9d302df905cb04d61c3c069ca08563" "0jwkxxlqc7q9934y1iyvrbpqsknf800lq27y3pjj0ali6nm14l7i" "Source snapshot of Rutgers Pascal" "https://github.com/PDP-10/rutgers-pascal" #f))
(define-public pdp10-sitbol-source (make-github-source-snapshot "pdp10-sitbol-source" "pdp10" "PDP-10" "sitbol" "0310c13c121d4d2f66ef9583d3c1e237ee21aded" "182y3cxxdspvj9kbbi2xh0k039kzi1ld3ibrh87vc5c1jj2az48i" "Source snapshot of SITBOL" "https://github.com/PDP-10/sitbol" #f))
(define-public pdp10-snyder-c-compiler-source (make-github-source-snapshot "pdp10-snyder-c-compiler-source" "pdp10" "PDP-10" "Snyder-C-compiler" "ab08e9afcf676461843cfe5f1a65c058a4214ccb" "1jyirnm65dw78j3s9xc0ik5yqdhjwwq43ga54h88ry20c7bf02r4" "Source snapshot of the Snyder C compiler" "https://github.com/PDP-10/Snyder-C-compiler" #f))
(define-public pdp10-spacewar-source (make-github-source-snapshot "pdp10-spacewar-source" "pdp10" "PDP-10" "Spacewar" "84e7955e0adf08d3a0b1b0b9d30b33c4759a6a74" "1rwfcmbv9jlanyfx91z0cgr1i7x64jkrnniigwji5bz4jgpkl5cp" "Source snapshot of Spacewar for PDP-6 and PDP-10" "https://github.com/PDP-10/Spacewar" #f))
(define-public pdp10-stacken-source (make-github-source-snapshot "pdp10-stacken-source" "pdp10" "PDP-10" "stacken" "6e18f5ebefd9acb0d718ef31a08f33a60fc9fca2" "160y42rwjiicmwk5kchm92dmc7xww52frrjj8vjza6r8hng4b1m9" "Source snapshot of Stacken computer-club material" "https://github.com/PDP-10/stacken" #f))
(define-public pdp10-suds-source (make-github-source-snapshot "pdp10-suds-source" "pdp10" "PDP-10" "SUDS" "a167729a953680a1442f057b517485035aecb734" "0sjksxjqdzbgfs7k9yn5322425dnnxwgrrff1qcsiya64cnwz894" "Source snapshot of the Stanford University Drawing System" "https://github.com/PDP-10/SUDS" #f))
(define-public pdp10-supdup-source (make-github-source-snapshot "pdp10-supdup-source" "pdp10" "PDP-10" "supdup" "9658d1f2a9f823334f116655f452f0df93f5d35c" "1rynvs49xlqqillj7ih3n3b0gz5w4ff97ggbh7r8gdp8dll1akvg" "Source snapshot of the SUPDUP client" "https://github.com/PDP-10/supdup" #f))
(define-public pdp10-suppty-source (make-github-source-snapshot "pdp10-suppty-source" "pdp10" "PDP-10" "SUPPTY" "2da0135f2f3069db4b692155887d4076e67d6fac" "18mzn29b1pkngp1zxsc7vhaxf8vvyykagrqk8qvy85yhrg5p78a5" "Source snapshot of the SUPDUP PuTTY client" "https://github.com/PDP-10/SUPPTY" #f))
(define-public pdp10-sri-nic-source (make-github-source-snapshot "pdp10-sri-nic-source" "pdp10" "PDP-10" "sri-nic" "888264aa2d4e03c487ba9370543e2d7ca22d1d4b" "1pl118mv3frln03sjkg4rv2izl25q8xa1wgg7py0sr8g309l3g2s" "Source snapshot of the SRI-NIC backup" "https://github.com/PDP-10/sri-nic" #f))
(define-public pdp10-system1022-source (make-github-source-snapshot "pdp10-system1022-source" "pdp10" "PDP-10" "System1022" "5b3a35c82d17d34b30773948db60e526283f4eeb" "1d0svh9899g3bwprll63w1m327ayhfmm1x4x145m52jg9f8kh808" "Source snapshot of System 1022" "https://github.com/PDP-10/System1022" #f))
