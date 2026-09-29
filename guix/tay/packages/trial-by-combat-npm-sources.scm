;;; Fixed source archives for the trial-by-combat npm lock closure.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages trial-by-combat-npm-sources)
  #:export (%trial-by-combat-npm-sources)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13))

;; Each line records npm name, exact version, and SHA-256 in Guix base32.
;; These 70 archives materialize the runtime half of upstream's
;; package-lock.json, whose 79 locked entries also cover 9 development-only
;; nodes: @biomejs/biome 2.4.13 and its eight platform-specific children.
;; Biome is a linter and is deliberately absent, so no prebuilt platform
;; binary enters the build.  Every hash below was verified against the
;; matching "integrity" field of the lockfile before use.  License metadata
;; was read from each locked origin: 66 nodes are MIT, 2 ISC (inherits 2.0.4
;; and setprototypeof 1.2.0), and 2 BSD-3-Clause (qs 6.14.2 and the
;; body-parser-nested qs 6.15.1).
(define %trial-by-combat-npm-records
  (string-append
    "accepts\t1.3.8\t0xbds0r4v51s5lprkr6snag2xr5ssbavh9hmqygj4y427z59l65z\n"
    "array-flatten\t1.1.1\t1v96cj6w6f7g61c7fjfkxpkbbfkxl2ksh5zm7y5mfp96xivi5jhs\n"
    "body-parser\t1.20.5\t06dlvnscw3l5qrjb7dxai1cfmzirffnlxl3qbhs8pdn7g1nnp0lg\n"
    "bytes\t3.1.2\t10f5wgg4izi14lc425v7ljr1ayk28ycdjckfxpm4bnj0bankfpl3\n"
    "call-bind-apply-helpers\t1.0.2\t0b3xqfkmcxhancq8h4cd3282ryg9h5rnf2h2530zbvdbvgwrygh7\n"
    "call-bound\t1.0.4\t0cmxdglg3lrrz7apqgvqbkd57jicr98fxwhi92rvkwgd5x4ny21j\n"
    "content-disposition\t0.5.4\t0ljl6r5vqhyscjb723f8ddlzrzg66zlh9q01xahjrhlanskwi574\n"
    "content-type\t1.0.5\t1j0jpnlxjrdpbnq7s1h1xga2n8562j5g6612f7fl40jz82cd0cdc\n"
    "cookie-signature\t1.0.7\t0s8xzk42w14hpamyvfvaz7a8yg7hfh5b0ymki45vi4ky12znk39b\n"
    "cookie\t0.7.2\t084ymsdgqj3jc00gh39cbfbmh1vval1wy2ifd88hlqqw4pw61cbn\n"
    "debug\t2.6.9\t160wvc74r8aypds7pym3hq4qpa786hpk4vif58ggiwcqcv34ibil\n"
    "depd\t2.0.0\t19yl2piwl0ci2lvn5j5sk0z4nbldj6apsrqds3ql2d09aqh8m998\n"
    "destroy\t1.2.0\t1a6gf6hn9zc4g6v3dqdcsc3v1n22qbv1s5xmdakljjgmdkl2gzcd\n"
    "dunder-proto\t1.0.1\t1nyg4r9qjc33kmgixdi5xpb0qsjivy2dcn8wjbwhvhc2ihi444zd\n"
    "ee-first\t1.1.1\t175r500n567a04qmswzw5hkgdnika3dvn63n284jlar2gvmyhj2i\n"
    "encodeurl\t2.0.0\t0agvpr5psd2nymhp51l5502fzifkshxxlnixl7kzkf2ii25l2blv\n"
    "es-define-property\t1.0.1\t1xw50gnqd3d7nyfcl5a5lzrhxa0sjq7qyzaw1n5hld1166qvi1jr\n"
    "es-errors\t1.3.0\t14q935xgv4cblmy8lk3brx4ypwxpgrid77r1lfnbilsbbg1x2kfi\n"
    "es-object-atoms\t1.1.1\t1kkrwpp6nz2nc32zxin52xnngyg7qg38c5ljy5xyx2l1azby861y\n"
    "escape-html\t1.0.3\t0rh35dvab1wbp87dy1m6rynbcb9rbs5kry7jk17ixyxx7if1a0d1\n"
    "etag\t1.8.1\t1bqgznlsrqcmxnhmnqkhwzcrqfaalxmfxzly1ikaplkkm5w6ragn\n"
    "express\t4.22.1\t0bym8l4nkr7p5him9rkbppzaill7aqs5dx4lhqh99zq2q5vs3b20\n"
    "finalhandler\t1.3.2\t1z814w9awa9yb4v339d9gl83yzbgpz285diaxj4y4q727xrk4bac\n"
    "forwarded\t0.2.0\t168w8dhfqp12llh2w802dm3z1fcarsacsksyvdccnpxqbzlmsnlv\n"
    "fresh\t0.5.2\t0k44badcxkwy202kz404w078l660f65jaijg473xv38ay3wpdri5\n"
    "function-bind\t1.1.2\t1ah7x13hmwwfslk72h2rs21c5vqnsxyzqifl2x7lb8823djh4i3h\n"
    "get-intrinsic\t1.3.0\t0i05g3xvqgv16ss19k3jprfnkqsln2n4m7wgn3xldzh09vjjfbk6\n"
    "get-proto\t1.0.1\t1086swsp92367j7m6canvgf6zwghh0iqr9f2bwndh7qzzcmcab7b\n"
    "gopd\t1.2.0\t10nskxn4cwbfd9i9nzy2r7pf0zm46j9z7dzvd0adr1fj9pgd0dnm\n"
    "has-symbols\t1.1.0\t1ig7dbwgg0kbjg2wc7arp7a28g6l2rwc27lsvhnxzf185x9wfq24\n"
    "hasown\t2.0.3\t1l4i4x6bcgc8dr57ph88w4rbmjyl3yiq1hj5g7yifni56vgcxcxh\n"
    "http-errors\t2.0.1\t0qbc38g805qi9bcywg082sz8kdgxkq4fssgjlfcrc1xg3fqvnqmd\n"
    "iconv-lite\t0.4.24\t0da6ff7dlx6lfhdafsd9sv0h09sicpfakms8bqylrm4f17r68v2p\n"
    "inherits\t2.0.4\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\n"
    "ipaddr.js\t1.9.1\t1vlg9vgdlx13dvh6h6sg3rgdbp04lkljmn6gxih43zk77xidjhbl\n"
    "math-intrinsics\t1.1.0\t19s3yi9ziz007ymq0r1k2xk1nrg2m5lc9kw8vy3c0ga9fmaw7hmq\n"
    "media-typer\t0.3.0\t07vlmddn91j0bbrxr2br320dnkxw96dp7hqmvidj5ydl84adiyid\n"
    "merge-descriptors\t1.0.3\t1bidz6yhi4a01y886wr89h5ggmw1jc416bsxj32b4rxwjdlf0dcf\n"
    "methods\t1.1.2\t0g50ci0gc8r8kq1i06q078gw7azkakp7j3yw5qfi6gq2qk8hdlnz\n"
    "mime-db\t1.52.0\t0fwyiyqi3w03w3xwy2jhm8rsa0y9wgkc0j6q3q6mvk9asns0prxq\n"
    "mime-types\t2.1.35\t1hyi043kcqyfz82w19s357klvj54f0s94d40rymbms86i74lyws9\n"
    "mime\t1.6.0\t16iprk4h6nh780mvfv0p93k3yvj7jrq2qs92niaw6yk11qwi0li1\n"
    "ms\t2.0.0\t1jrysw9zx14av3jdvc3kywc3xkjqxh748g4s6p1iy634i2mm489n\n"
    "ms\t2.1.3\t1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn\n"
    "negotiator\t0.6.3\t04sjfqwmsamf29a67zwrjdi3h62avc3y6a9y6a74zsgpl1xnhbli\n"
    "object-inspect\t1.13.4\t1gwh5vk75w4crskqjsn4ps9z8hqqpjp58d8y82q4b2px79x9c943\n"
    "on-finished\t2.4.1\t02mxvpahgv07xaih7lmpn8wic9v4jph3fir0qpd6qf4w0kql4kgn\n"
    "parseurl\t1.3.3\t06h2bx1rilkdir3v9jlg94r1q2fn895s0vxjjs0wx5z027x4pvsn\n"
    "path-to-regexp\t0.1.13\t1chxz9qvf52habl6v6dpm8i721kqa1dpx0d5rqk0m0122rv6kq8p\n"
    "proxy-addr\t2.0.7\t1na6xrmlga7qjd55gfhnp7m8qg43nynzg5ds54s76kkd9zrvdld0\n"
    "qs\t6.14.2\t0x592jj33npg8hkrdprkn9bs20k5rj9lhphzpv0m2aiyxr68mv2s\n"
    "qs\t6.15.1\t1l9l2000rdh3xqjn3d7wf2x67d2n0nyd72l1wy72zabvmk57x2n6\n"
    "range-parser\t1.2.1\t09prs852snwqr9cfcrybm7ysl0z1wka9dh4dwc4v1415cvi6cllh\n"
    "raw-body\t2.5.3\t0krxp5c5ilkplpyxwn7c35hja97yyx2g3i0q260m5xqwc61f3kv0\n"
    "safe-buffer\t5.2.1\t1s5kvjpwqsc682zcy71h9c6pxla21sysfwj270x6jjkca421h62x\n"
    "safer-buffer\t2.1.2\t1cx383s7vchfac8jlg3mnb820hkgcvhcpfn9w4f0g61vmrjjz0bq\n"
    "send\t0.19.2\t147rachimgfd44nzjh5ld863va72ylmcrakfa622j7fb4sqjbkcv\n"
    "serve-static\t1.16.3\t12fgppcvx6mcvpql6y6ssqsp19wpbb5j5pk6nz02fxisdzns42yp\n"
    "setprototypeof\t1.2.0\t1qnzx8bl8h1vga28pf59mjd52wvh1hf3ma18d4zpwmijlrpcqfy8\n"
    "side-channel-list\t1.0.1\t1xvlmx2r27q14gg1qzns3fy8r2sp0r281y25f1sp5rsv46n98g3r\n"
    "side-channel-map\t1.0.1\t1mhnf4m2zdv1ikvjk74v6d7fhr2bzn41a6w95nbcq2rh45j6n99v\n"
    "side-channel-weakmap\t1.0.2\t0vnhs2whvv59nkqdsfpmd1fwrcjzh2ka5z8giy68kbg7qpq58aiv\n"
    "side-channel\t1.1.0\t11d40rvhvkj4r1dis1vmzi0gc6qnvw90jkc2ppz2w90bk5xyg4w4\n"
    "statuses\t2.0.2\t1q4zjhjprvhdjc32px6b4b0i3ffn1mbqygp7yilbb204f4j0m06a\n"
    "toidentifier\t1.0.1\t021fp42m51qbqbqabwhxky8bkfkkwza65lqiz7d2gqwd91vwqvqq\n"
    "type-is\t1.6.18\t1bn3gl9vd67cq3wl2cvq686zskl2xx6lxz5kp9w47qc06f2vbnll\n"
    "unpipe\t1.0.0\t1dnzbqfmchls4jyvkw0wnkc09pig98y66zzsy3lizgyls435xyrd\n"
    "utils-merge\t1.0.1\t0djhmrfzxpdhscg4pkgnsd39cddpwpkkw1w2f8mp2xfsxn7mvnfy\n"
    "vary\t1.1.2\t0wbf4kmfyzc23dc0vjcmymkd1ks50z5gvv23lkkkayipf438cy3k\n"
    "ws\t8.20.0\t0s9sznj0g5xwjgx367sih4dkz0c1shwhy5g7z74b2ykcn1zxjyxw\n"
    ))

(define (npm-archive-uri name version)
  (let ((base (last (string-split name #\/))))
    (string-append "https://registry.npmjs.org/" name "/-/" base "-"
                   version ".tgz")))

(define (safe-file-name name)
  (string-map (lambda (character)
                (if (or (char=? character #\/) (char=? character #\@))
                    #\_
                    character))
              name))

(define (npm-source record)
  (match (string-tokenize record)
    ((name version hash)
     (cons (string-append name "@" version)
           (origin
             (method url-fetch)
             (uri (npm-archive-uri name version))
             (file-name (string-append (safe-file-name name) "-" version ".tgz"))
             (sha256 (base32 hash)))))))

(define %trial-by-combat-npm-sources
  (map npm-source
       (remove string-null?
               (string-split %trial-by-combat-npm-records #\newline))))
