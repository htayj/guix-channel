;;; PDP-10 public source snapshots, T--Z.

(define-module (tay packages pdp10-t-z)
  #:use-module (tay packages source-snapshot)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (pdp10-tenex-source
            pdp10-tenex-bcpl-source
            pdp10-tingle-source
            pdp10-tops-10-source
            pdp10-tops-20an-source
            pdp10-tops10-arpanet-ncp-source
            pdp10-tops10-tapes-source
            pdp10-tops20-build-source
            pdp10-tvcon-macosx-source
            pdp10-tymcom-x-source
            pdp10-unpal10-source
            pdp10-utah-pcc20-source
            pdp10-waits-source
            pdp10-wpi-source
            pdp10-xpl-pdp-10-source
            pdp10-zil-source))

(define-public pdp10-tenex-source
  (make-github-source-snapshot
   "pdp10-tenex-source" "pdp10" "PDP-10" "tenex"
   "29ff34343d5c216727fd9e002fdfa694a821c2bc"
   "0dnd45sprh49z3p85z3ink6i01hvs5hfj59x74aqcmq8gnyhf2cp"
   "Source snapshot of BBN TENEX"
   "https://github.com/PDP-10/tenex" #f))

(define-public pdp10-tenex-bcpl-source
  (make-github-source-snapshot
   "pdp10-tenex-bcpl-source" "pdp10" "PDP-10" "tenex-bcpl"
   "1fca1bb35981368ab91a9ac408a0d55189f83491"
   "0h9828dpmja9m1pgla1fyqvsy9yw6giy33grbnmc22fvvys48d56"
   "Source snapshot of BBN TENEX BCPL"
   "https://github.com/PDP-10/tenex-bcpl" #f))

;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-tingle-source
  (make-github-source-snapshot
   "pdp10-tingle-source" "pdp10" "PDP-10" "tingle"
   "18907e032f74d99e4c67e88ddc808b7d9aed053d"
   "1jrf90jgh3i9aqsq2c7cm8xrg67yf5dd4z61jc5n7j5hh7qwmfr3"
   "Source snapshot of TINGLE historical PDP-10 material"
   "https://github.com/PDP-10/tingle" #f))

(define-public pdp10-tops-10-source
  (make-github-source-snapshot
   "pdp10-tops-10-source" "pdp10" "PDP-10" "TOPS-10"
   "0ab6cbf82e9d38b79a523523f58abf4317842e7c"
   "0x01zdbnqn0bpagbklm5l0wfgmfp4sx800l838740p19l4lp8h21"
   "Source snapshot of the TOPS-10 distribution"
   "https://github.com/PDP-10/TOPS-10" #f))

(define-public pdp10-tops-20an-source
  (make-github-source-snapshot
   "pdp10-tops-20an-source" "pdp10" "PDP-10" "TOPS-20AN"
   "446965ebd8e8275a9ebbe1ddaef81fd0fbc915f8"
   "0ibvq7fd1lwdbrx8rdnq2xjmp495lkdzjb3jyq95xlgpgnfg3k92"
   "Source snapshot of TOPS-20 with ARPANET networking"
   "https://github.com/PDP-10/TOPS-20AN" #f))

(define-public pdp10-tops10-arpanet-ncp-source
  (make-github-source-snapshot
   "pdp10-tops10-arpanet-ncp-source" "pdp10" "PDP-10" "tops10-arpanet-ncp"
   "debd0fda12cfe339d1ee7114fa6b064acd26a937"
   "17cphay1lf89dc28bl8vrrxdvkihd15arnj78d68d2kszaxharjf"
   "Source snapshot of the TOPS-10 ARPANET NCP"
   "https://github.com/PDP-10/tops10-arpanet-ncp" #f))

;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-tops10-tapes-source
  (make-github-source-snapshot
   "pdp10-tops10-tapes-source" "pdp10" "PDP-10" "tops10-tapes"
   "af0e2d0fe70c7ed9f02a4822cd931e3465ef64f2"
   "1abhanb67jjd1ayf37qaxrrk98019jnhmalp36qlgkhyqmwpkbrr"
   "Source snapshot of TOPS-10 tape images"
   "https://github.com/PDP-10/tops10-tapes" #f))

(define-public pdp10-tops20-build-source
  (make-github-source-snapshot
   "pdp10-tops20-build-source" "pdp10" "PDP-10" "tops20-build"
   "456fed1f22b196f987375d35a1145f4d41c35703"
   "12x5902kqq0jyhifms8sx1r45gg23lha1ja618ig4zzcnz6s1i43"
   "Source snapshot of the TOPS-20 build system"
   "https://github.com/PDP-10/tops20-build" #f))

(define-public pdp10-tvcon-macosx-source
  (make-github-source-snapshot
   "pdp10-tvcon-macosx-source" "pdp10" "PDP-10" "tvcon-macosx"
   "968a4dee80b8c3a919142478dded313c6ceacb54"
   "186cdsr19mx01wipfg5w8xs7s7xhqlck4fza1wlk3cg5yxq3b7cb"
   "Source snapshot of Knight TV for macOS"
   "https://github.com/PDP-10/tvcon-macosx" #f))

(define-public pdp10-tymcom-x-source
  (make-github-source-snapshot
   "pdp10-tymcom-x-source" "pdp10" "PDP-10" "Tymcom-X"
   "1160f3f5fd7c700efd6f268cf71788890d126dea"
   "18fd9ifalkhls3wnvyv2yym84l8whh1xi58ivncp3nb86c6scc4k"
   "Source snapshot of the Tymcom-X operating system"
   "https://github.com/PDP-10/Tymcom-X" #f))

(define-public pdp10-unpal10-source
  (make-github-source-snapshot
   "pdp10-unpal10-source" "pdp10" "PDP-10" "unpal10"
   "e384cd87e40ccae9bc55ba22cb66e15c4bbccd99"
   "0qhsp2cjppqbgla6k31iwpam22bwi3bvr34c7y2jk2vx8iy2bqkc"
   "Source snapshot of the UNPAL-10 cross-disassembler"
   "https://github.com/PDP-10/unpal10" license:gpl3))

(define-public pdp10-utah-pcc20-source
  (make-github-source-snapshot
   "pdp10-utah-pcc20-source" "pdp10" "PDP-10" "utah-pcc20"
   "86a53793032244c9d5430aa2a4f0f1385057522f"
   "06b9cksd1il14kb0w9vk99686i7jjg8d13qdamcybbbql6c61iw3"
   "Source snapshot of the University of Utah PCC-20"
   "https://github.com/PDP-10/utah-pcc20" #f))

(define-public pdp10-waits-source
  (make-github-source-snapshot
   "pdp10-waits-source" "pdp10" "PDP-10" "waits"
   "b70886d67a842ca6986c41546d123e2aac7f06ae"
   "189lsk60pmziya4ryzmbkf556ygg18bm4z5z9cqxgraq1c87vbp6"
   "Source snapshot of the WAITS operating system"
   "https://github.com/PDP-10/waits" #f))

(define-public pdp10-wpi-source
  (make-github-source-snapshot
   "pdp10-wpi-source" "pdp10" "PDP-10" "wpi"
   "b2a443cc2270956eea3c254151910850a5048526"
   "0ayrg9hhcybqm1m6dck26nxbc2lc1p0a6gbrfhnyznmb3x1qslyw"
   "Source snapshot of WPI KA10 documentation"
   "https://github.com/PDP-10/wpi" #f))

(define-public pdp10-xpl-pdp-10-source
  (make-github-source-snapshot
   "pdp10-xpl-pdp-10-source" "pdp10" "PDP-10" "xpl-pdp-10"
   "0e57cbd9e2e2997134332f6784dccc262a069d99"
   "07i5m1ql2ldr09fmchswfahj6qybb31mwxflyb0ad6w4jpq8618q"
   "Source snapshot of XPL for PDP-10"
   "https://github.com/PDP-10/xpl-pdp-10" #f))

(define-public pdp10-zil-source
  (make-github-source-snapshot
   "pdp10-zil-source" "pdp10" "PDP-10" "zil"
   "140c1a6901b166e5e2cd066c30b7d4e6e7cfa593"
   "1czzsm549whnpblawpwwrxvbnjv4qrbhdck0vibzqgg2abrd8p17"
   "Source snapshot of the Zork implementation language"
   "https://github.com/PDP-10/zil" #f))
