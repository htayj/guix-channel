;;; PDP-10 public source snapshots, A--F.

(define-module (tay packages pdp10-a-f)
  #:use-module (tay packages source-snapshot)
  #:export (pdp10-amis-source
            pdp10-bbn-logo-source
            pdp10-bsys-source
            pdp10-bygg-source
            pdp10-cmu-extended-pcl-source
            pdp10-dart-source
            pdp10-decwar-source
            pdp10-documents-source
            pdp10-emacs-source
            pdp10-essex-bcpl-source
            pdp10-f40-source
            pdp10-fine-source
            pdp10-foonex-source
            pdp10-foonly-source))

(define-public pdp10-amis-source
  (make-github-source-snapshot
   "pdp10-amis-source" "pdp10" "PDP-10" "amis"
   "c83f08848405606b3533dcf4fc4d8f2bb4911d15"
   "1p72a0h1l3s78jfgmzp8g0n56k0vfhraqn7ni39vbjn0iirlwscc"
   "Source snapshot of the PDP-10 AMIS editor"
   "https://github.com/PDP-10/amis" #f))

(define-public pdp10-bbn-logo-source
  (make-github-source-snapshot
   "pdp10-bbn-logo-source" "pdp10" "PDP-10" "bbn-logo"
   "2b51f75a1bd106604963fd946ff52f60701a16bd"
   "0jnfw14ga46i82nwdq3fjy76al3m8i24d20xz6kyab5az1rnyyra"
   "Source snapshot of BBN Logo for PDP-10"
   "https://github.com/PDP-10/bbn-logo" #f))

(define-public pdp10-bsys-source
  (make-github-source-snapshot
   "pdp10-bsys-source" "pdp10" "PDP-10" "bsys"
   "238d7679eac2896c2b59a757e8cfbeda1ee41727"
   "1w9yppvfvzqdzw9w6mk6kglhg70d091xza58wpc1zd4ap6s9as7y"
   "Source snapshot of the TENEX BSYS tape tool"
   "https://github.com/PDP-10/bsys" #f))

(define-public pdp10-bygg-source
  (make-github-source-snapshot
   "pdp10-bygg-source" "pdp10" "PDP-10" "bygg"
   "2e6639b9565f91706c433d6739b3f875fd117b5e"
   "1dvq9s3xyp3r9bcbnx3q5aygbd9yzw3nbzc6vzjihhyayg4bkyjl"
   "Source snapshot of the bygg historical-computing archive"
   "https://github.com/PDP-10/bygg" #f))

(define-public pdp10-cmu-extended-pcl-source
  (make-github-source-snapshot
   "pdp10-cmu-extended-pcl-source" "pdp10" "PDP-10" "cmu-extended-pcl"
   "ab2318a29306ecd7fe3e55c9f21fbe81495c2baf"
   "147xqwswqqzxj3z8ryh1y9rx8jkqxr51zxvlr8nr4mz4ca7h6f1w"
   "Source snapshot of CMU extended PCL"
   "https://github.com/PDP-10/cmu-extended-pcl" #f))

(define-public pdp10-dart-source
  (make-github-source-snapshot
   "pdp10-dart-source" "pdp10" "PDP-10" "dart"
   "5bd0f50483be6ec328beaa056b84550ee0ea9377"
   "0rwgh98p9vq39n7z92ihz6rj8znm3wcbbnyh5fh8lsfgrs1bsmk3"
   "Source snapshot of the SAIL dump and restore tool"
   "https://github.com/PDP-10/dart" #f))

(define-public pdp10-decwar-source
  (make-github-source-snapshot
   "pdp10-decwar-source" "pdp10" "PDP-10" "decwar"
   "59f2b657400a4f628fe49a068e2ddfabaeba99e0"
   "1xf9r07g6wf1fs618mqvgl2rcylnxxsl46bmk0lgb794smrg46xp"
   "Source snapshot of DECwar"
   "https://github.com/PDP-10/decwar" #f))

(define-public pdp10-documents-source
  (make-github-source-snapshot
   "pdp10-documents-source" "pdp10" "PDP-10" "documents"
   "b2e12778a7c19c7ce4e895b223be0b461327f0c5"
   "0ighnv0711jk76zhd84xlgfdxbqlyhnyvdidj5isw79j5qy6njjh"
   "Source snapshot of PDP-10 documents"
   "https://github.com/PDP-10/documents" #f))

(define-public pdp10-emacs-source
  (make-github-source-snapshot
   "pdp10-emacs-source" "pdp10" "PDP-10" "emacs"
   "48a4fe4f9f70d324b2c2e588f7cec8a8f739117a"
   "0pb9gbdv3ipacrkq6mvqg7kfp3m7w716almj79hclb43fkskfvnw"
   "Source snapshot of TECO Emacs for TOPS-20"
   "https://github.com/PDP-10/emacs" #f))

(define-public pdp10-essex-bcpl-source
  (make-github-source-snapshot
   "pdp10-essex-bcpl-source" "pdp10" "PDP-10" "essex-bcpl"
   "3fe466d1327cbb5f583d7d79575dbf250d8aa461"
   "044cq5hyz11lskil3zcx9nvv8ixqad40j6750138skhqw50pvpdy"
   "Source snapshot of Essex BCPL for TOPS-10"
   "https://github.com/PDP-10/essex-bcpl" #f))

(define-public pdp10-f40-source
  (make-github-source-snapshot
   "pdp10-f40-source" "pdp10" "PDP-10" "f40"
   "5bcb82dae9dfa018d4e8194ad4acdc0399d81dbc"
   "1x7rp0zm5x82x007zpw5x2y2ydn0ga2r6gmfxmgpp3hykyj5aqyi"
   "Source snapshot of DEC Fortran IV"
   "https://github.com/PDP-10/f40" #f))

(define-public pdp10-fine-source
  (make-github-source-snapshot
   "pdp10-fine-source" "pdp10" "PDP-10" "fine"
   "17784b96ec14c3ae444cdc12873921e559f3a880"
   "0ibzhlhks4rgvbninhcm0a73yhqbklcvna1vq34hkl2hr9d8r7im"
   "Source snapshot of FINE, the PDP-10 editor"
   "https://github.com/PDP-10/fine" #f))

(define-public pdp10-foonex-source
  (make-github-source-snapshot
   "pdp10-foonex-source" "pdp10" "PDP-10" "FOONEX"
   "a541b791ac763791e8a1ce98ac985bf5a09dff15"
   "14qq15avwkgkmg29wzpaz5s2wlxyh954m7k9hmpj6lwmqsa4fxvb"
   "Source snapshot of FOONEX from Foonly"
   "https://github.com/PDP-10/FOONEX" #f))

(define-public pdp10-foonly-source
  (make-github-source-snapshot
   "pdp10-foonly-source" "pdp10" "PDP-10" "foonly"
   "11bfe55834eeb1d850fbbac14a7e9e4788d2ac41"
   "0vwprpz8apcs1bsk92sakp5arnlcg8q84m177s8zy8df7bfgxv6p"
   "Source snapshot of Foonly computer material"
   "https://github.com/PDP-10/foonly" #f))
