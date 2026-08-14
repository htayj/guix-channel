;;; PDP-10 public source snapshots, G--M.

(define-module (tay packages pdp10-g-m)
  #:use-module (tay packages source-snapshot)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (pdp10-harvard-ecl-source pdp10-harvard-ppl-source
            pdp10-hamburg-pascal-source pdp10-imsss-source
            pdp10-imp-77-source pdp10-interlisp-10-source
            pdp10-its-source pdp10-its-vault-source pdp10-itstar-source
            pdp10-kcc-source pdp10-kevin-cole-declibs-source
            pdp10-kldcp-source pdp10-klh10-source pdp10-kom-source
            pdp10-lds-1-source pdp10-macsyma-source pdp10-maxc-source
            pdp10-microcode-source pdp10-mimic-source pdp10-mud1-source
            pdp10-muddle-source))

(define-public pdp10-harvard-ecl-source (make-github-source-snapshot "pdp10-harvard-ecl-source" "pdp10" "PDP-10" "harvard-ecl" "bc7dd2953f76cdae3c75884f7e64c34d3a894a66" "0l1wfzvn3k683qxg93fc3c8w5fxsgpxmgrb50dzg4scc601i84wm" "Source snapshot of Harvard ECL" "https://github.com/PDP-10/harvard-ecl" #f))
(define-public pdp10-harvard-ppl-source (make-github-source-snapshot "pdp10-harvard-ppl-source" "pdp10" "PDP-10" "harvard-ppl" "c23af4ff24710e909dc5c121c0549da8d7ed8e07" "1lzdaj5db4qkzk02p982v5a4fjphplbr7kxh274c0aqjqdl2mn4g" "Source snapshot of Harvard PPL" "https://github.com/PDP-10/harvard-ppl" #f))
(define-public pdp10-hamburg-pascal-source (make-github-source-snapshot "pdp10-hamburg-pascal-source" "pdp10" "PDP-10" "hamburg-pascal" "4dd080c2040f9b7e9be089713bb5ce0f14dfdf44" "1xgca34mg4kmcw5d03naqvwbbzijlz5p6wq6r31qdxbzrhp1p78q" "Source snapshot of Hamburg Pascal" "https://github.com/PDP-10/hamburg-pascal" #f))
(define-public pdp10-imsss-source (make-github-source-snapshot "pdp10-imsss-source" "pdp10" "PDP-10" "imsss" "bf738dfbf7fc900910306ac79944addd95d1fceb" "11x29xh3f0kbls6rvlsjcz4sx2pz0nnphv20830rvk8bjs4k2k9f" "Source snapshot of IMSSS TENEX files" "https://github.com/PDP-10/imsss" #f))
(define-public pdp10-imp-77-source (make-github-source-snapshot "pdp10-imp-77-source" "pdp10" "PDP-10" "IMP-77" "3602490cf7b0c38070358ad6983ce711722be45e" "0jjkk9h8glsgbjbydas64rck0z1xm3kyw7rv6yzmp1v06sbp4nnr" "Source snapshot of Edinburgh IMP-77" "https://github.com/PDP-10/IMP-77" #f))
(define-public pdp10-interlisp-10-source (make-github-source-snapshot "pdp10-interlisp-10-source" "pdp10" "PDP-10" "Interlisp-10" "f2b26ec273b7662534b7d151af8b4e64b9264635" "0ccjr8nnwm8wicn8wmyp5qvm821jxyp7w77kbghwl99h5bsy8p6a" "Source snapshot of Interlisp-10" "https://github.com/PDP-10/Interlisp-10" #f))
(define-public pdp10-its-source (make-github-source-snapshot "pdp10-its-source" "pdp10" "PDP-10" "its" "6e2ff914f50160382015aeac3e33ace349df9ee5" "1c3rl688m7wnz07dfl72yr6i71dwdwnaxdlrrvmv5d1j5f2az6gy" "Source snapshot of the Incompatible Timesharing System" "https://github.com/PDP-10/its" #f))
(define-public pdp10-its-vault-source (make-github-source-snapshot "pdp10-its-vault-source" "pdp10" "PDP-10" "its-vault" "84a5e5b36c3e91ed8861615c2cd98e2a8819e544" "0p39dwl7v0hy4jyqpr1nza9r3b2wnqmhl26xkqi1bnkqr70rpyi9" "Source snapshot of the ITS vault" "https://github.com/PDP-10/its-vault" #f))
(define-public pdp10-itstar-source (make-github-source-snapshot "pdp10-itstar-source" "pdp10" "PDP-10" "itstar" "b709cd82ebcfa2cc78f79da8ca9e81c31f53a7c3" "0p2a430npwvf611nkzzja59qb0d0s19i1ahgvnqf0d6xyn6szccc" "Source snapshot of the ITS tape tool" "https://github.com/PDP-10/itstar" license:gpl3))
(define-public pdp10-kcc-source (make-github-source-snapshot "pdp10-kcc-source" "pdp10" "PDP-10" "kcc" "cc60d4946e03566c02aa5623effe12e04158e7cd" "1v3cs320hpjyx95dbddr2bhwqqgcsaf3brwxiyinaj81kf0q8925" "Source snapshot of Kok Chen C" "https://github.com/PDP-10/kcc" #f))
(define-public pdp10-kevin-cole-declibs-source (make-github-source-snapshot "pdp10-kevin-cole-declibs-source" "pdp10" "PDP-10" "Kevin-Cole-DEClibs" "e9389f32ea407ba04e4456ee2bd000e1175dfa2b" "0fykk4sd7rd5ag81rx7yqsxpj8is5r29gal3fz7dk3mdkv28yq24" "Source snapshot of Kevin Cole DEC libraries" "https://github.com/PDP-10/Kevin-Cole-DEClibs" license:gpl3))
(define-public pdp10-kldcp-source (make-github-source-snapshot "pdp10-kldcp-source" "pdp10" "PDP-10" "kldcp" "40152452f50a6f8f66040f571b14f77aa63daf30" "0aaahi4k332wa40h9sfqz8p229nbzsaiscjyh1jcypmh2iqn3djd" "Source snapshot of the KL10 diagnostic console" "https://github.com/PDP-10/kldcp" #f))
(define-public pdp10-klh10-source (make-github-source-snapshot "pdp10-klh10-source" "pdp10" "PDP-10" "klh10" "6d733f2a47644964492fd864454cbe1331655e53" "1kg68m8yyd3za3y4yjfi5lrbf1hipvamqqv3dq7m5kgb61x19br8" "Source snapshot of the KLH10 emulator" "https://github.com/PDP-10/klh10" #f))
(define-public pdp10-kom-source (make-github-source-snapshot "pdp10-kom-source" "pdp10" "PDP-10" "KOM" "a4c3c97f69e33331ef8e0c8e6f6d87718ffce074" "0qfklmz2avbqzhib6kk3zsjwwx5lx72ny97cmdanwyyw8nnfmpz6" "Source snapshot of KOM for TOPS-20" "https://github.com/PDP-10/KOM" #f))
(define-public pdp10-lds-1-source (make-github-source-snapshot "pdp10-lds-1-source" "pdp10" "PDP-10" "LDS-1" "a83a3e2f14d207e1f19a46ab010c51783fa1989c" "0vk2i8glxma5z7094hkr7plb40nx8jdc5l804vwgrar0q66llnjl" "Source snapshot of the LDS-1 system" "https://github.com/PDP-10/LDS-1" #f))
;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-macsyma-source (make-github-source-snapshot "pdp10-macsyma-source" "pdp10" "PDP-10" "macsyma" "b51fffd48301006f0ad46a2bc848609a9bab1ff3" "0vpcx6axvy2h4a7myf5k653yy82hv48ihm6z3p32g1midd11py8b" "Source snapshot of Macsyma" "https://github.com/PDP-10/macsyma" #f))
(define-public pdp10-maxc-source (make-github-source-snapshot "pdp10-maxc-source" "pdp10" "PDP-10" "maxc" "0922b8966a16eea44572a829bf0aaea816a3916a" "03yzl7b4gk0biznii65hdsvffmagbr3j81vbn4k2fjwp4m90v16y" "Source snapshot of Maxc historical material" "https://github.com/PDP-10/maxc" #f))
(define-public pdp10-microcode-source (make-github-source-snapshot "pdp10-microcode-source" "pdp10" "PDP-10" "microcode" "d5550efb39062cb3ac2cf1c2ecc37f0d4e9a6bb8" "09pb83nx29hfdq324g98xy8ax6yys9pgpzqwpglknv8cnlf2dfwd" "Source snapshot of PDP-10 microcode" "https://github.com/PDP-10/microcode" #f))
(define-public pdp10-mimic-source (make-github-source-snapshot "pdp10-mimic-source" "pdp10" "PDP-10" "MIMIC" "bbf063a8bfb1767f389fd45fd7c5f31ddf5154fc" "0br8alnqs0xgsxwzpvbdhjs3a1fqjb1w9kzp34zkwvnyvwjr816r" "Source snapshot of the MIMIC simulator" "https://github.com/PDP-10/MIMIC" #f))
(define-public pdp10-mud1-source (make-github-source-snapshot "pdp10-mud1-source" "pdp10" "PDP-10" "MUD1" "8d2ce6ee5ca1ae3d835538de20aeb87acaae3df1" "13b1qvsgy7ib0ccm82sh5zwfwxjwmvxdv2958j64ynw0z5plc85m" "Source snapshot of Essex MUD1" "https://github.com/PDP-10/MUD1" #f))
(define-public pdp10-muddle-source (make-github-source-snapshot "pdp10-muddle-source" "pdp10" "PDP-10" "muddle" "5d58427873da17c3301aa8a96cc379195455be5d" "1j2ysj6mrc2hbg1m27l7q8a4f65i9300qyd6dnwjgjjb8m5i7kcz" "Source snapshot of PDP-10 Muddle" "https://github.com/PDP-10/muddle" #f))
