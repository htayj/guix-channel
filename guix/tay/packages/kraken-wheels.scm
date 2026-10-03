;;; Official CPython 3.12 CPU wheels; no dependency resolution at build time.
(define-module (tay packages kraken-wheels)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:export (%kraken-wheels))

(define %kraken-wheels
  (list
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/71/43/1947f06babed6b3f1d7f38b0c767f52df66bfb2bc10b468c4a7de9eceff2/aiohappyeyeballs-2.7.1-py3-none-any.whl")
     (file-name "aiohappyeyeballs-2.7.1-py3-none-any.whl")
     (sha256 (base32 "0wk46zny7ci6112132ivdhaigh3gham5v3in87mm14p2c4v22hwj")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/52/b7/7cd31f29d6055bd711ae6e669367fba6f5ae9de463910a793e30556a8db7/aiohttp-3.14.3-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "aiohttp-3.14.3-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0hnvv325malkn0iixzq621slcbgshfdv2v87jndr47gv4z0hcfal")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/fb/76/641ae371508676492379f16e2fa48f4e2c11741bd63c48be4b12a6b09cba/aiosignal-1.4.0-py3-none-any.whl")
     (file-name "aiosignal-1.4.0-py3-none-any.whl")
     (sha256 (base32 "0bp81wd9xc9z1xxmkq5v1q5wzw4zhc596qwyji8hb69bp7w46ch5")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/98/53/6864ee88ca91a6b1ecc0c0dff9fb6114628a416f3786e0dd80bddbce207f/atpublic-8.0.1-py3-none-any.whl")
     (file-name "atpublic-8.0.1-py3-none-any.whl")
     (sha256 (base32 "0z7p90lgix68a31rv6lv199x78av963m93nc46jqwz7c4rdzx5l6")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/64/b4/17d4b0b2a2dc85a6df63d1157e028ed19f90d4cd97c36717afef2bc2f395/attrs-26.1.0-py3-none-any.whl")
     (file-name "attrs-26.1.0-py3-none-any.whl")
     (sha256 (base32 "02f37822ygdqm0vhl9id7gkg8dnw5pk1zrx47hrxkfnz295aliy6")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/ad/9b/9fb3585dabcd73a1b2a6267f63f62649347c9e6d072c9fde365b105abb2c/build-1.6.1-py3-none-any.whl")
     (file-name "build-1.6.1-py3-none-any.whl")
     (sha256 (base32 "1rzlph6b5nkxgr79db56mvacgja3f5lafi52mgmajdcxpsj53lzc")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/e8/cf/22794a399d99480486120e26e879ef008e21f5e85274c2ed591d568bb326/cattrs-26.2.1-py3-none-any.whl")
     (file-name "cattrs-26.2.1-py3-none-any.whl")
     (sha256 (base32 "095cpr0ghdn7qdcw8x95ip8iwhmp12gig4sjh4x673ywacsalam1")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/0b/a7/71ac2cff56fec219ed242bb11b8efb69fcc4bec75db06fb7bfe35de520e6/certifi-2026.7.22-py3-none-any.whl")
     (file-name "certifi-2026.7.22-py3-none-any.whl")
     (sha256 (base32 "0x9p90l2k6ccprp1mgg7ialf5mx8i1jp0srb980k66lanm12gwk2")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/7f/c5/38806a25ab5e65fc178f39affeda20858efafede2fce1ffc2556cfc9fe73/charset_normalizer-3.5.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "charset_normalizer-3.5.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0jfnprz0r630q5x8p81qsizaqg7pbxajl6vvggabh2h99622jc9x")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/85/32/10bb5764d90a8eee674e9dc6f4db6a0ab47c8c4d0d83c27f7c39ac415a4d/click-8.2.1-py3-none-any.whl")
     (file-name "click-8.2.1-py3-none-any.whl")
     (sha256 (base32 "0ax1fm8ivvyn0mh8cqzrf2k3bkgqqw4k22vx662hp1afj5djd8v1")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/88/39/799be3f2f0f38cc727ee3b4f1445fe6d5e4133064ec2e4115069418a5bb6/cloudpickle-3.1.2-py3-none-any.whl")
     (file-name "cloudpickle-3.1.2-py3-none-any.whl")
     (sha256 (base32 "0jmz3yz0dcjws9kl3j565zs5zw3jnh0vhfzr3pf60gypmzv4gjws")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b5/87/add15e7b4537765bef9cb47ffbd6a5d48493e65181df9864afeffa13b99b/coremltools-9.0-cp312-none-manylinux1_x86_64.whl")
     (file-name "coremltools-9.0-cp312-none-manylinux1_x86_64.whl")
     (sha256 (base32 "0gw4b9zx8njix6m3ayjgml36lgibgp0i9r8q3jgxw6brb84038cr")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/01/4f/83454fafd628e1e7e1726d74e44fb2332be5969d04c6182ca1fecb6c580e/filelock-4.0.9-py3-none-any.whl")
     (file-name "filelock-4.0.9-py3-none-any.whl")
     (sha256 (base32 "1svy3yc76mrggi9j1s1hk0dqm0606hqahady0996x04sp5hzv1wj")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/8a/92/2637a88ec1d4779e1c900bbfbb71e5689de166a2a036fe25095722570dc6/flufl_lock-9.2.0-py3-none-any.whl")
     (file-name "flufl_lock-9.2.0-py3-none-any.whl")
     (sha256 (base32 "1nbffq7f6cjq5171xp4k7xfv31wx7z2b33pg2rz1nnrp3yrlp7si")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/6a/bd/d91c5e39f490a49df14320f4e8c80161cfcce09f1e2cde1edd16a551abb3/frozenlist-1.8.0-cp312-cp312-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
     (file-name "frozenlist-1.8.0-cp312-cp312-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
     (sha256 (base32 "10s30zbnnw5dksqrgj7fjjbnnrbf4ski70g7w12bm5y5n595jjj9")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/6c/c0/a98505f18594f1bce828bb159cec0fcf9860562f1a2c85913409fc8f3d9e/fsspec-2026.9.0-py3-none-any.whl")
     (file-name "fsspec-2026.9.0-py3-none-any.whl")
     (sha256 (base32 "0pybbz85c9qy7xkxr9r3jkbl5916npk4ayprhnyq58wyx53fdmld")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/5f/80/91f51f439c05d4ec4623c22928ce16a938d6d793bf709477830823497859/hatchling-1.32.4-py3-none-any.whl")
     (file-name "hatchling-1.32.4-py3-none-any.whl")
     (sha256 (base32 "0b2afcnb8y553lzxr4r04jvp30kvwrqhrmqkybkhb0mlixaggv08")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/87/fb/de40c65528c3353b4e3983588e6c643310dd4b51adb11511d8e19aff5c08/htrmopo-0.6-py3-none-any.whl")
     (file-name "htrmopo-0.6-py3-none-any.whl")
     (sha256 (base32 "09mr6fsfkqsil1zgjcw0pa7x6ikxn7cfprgzp0z5xxw19lb8vjdd")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/58/a2/bb081bab032533a855d44de1d56f8e8426114ff1ba5d1f07a438a0a654f8/idna-3.20-py3-none-any.whl")
     (file-name "idna-3.20-py3-none-any.whl")
     (sha256 (base32 "0b2q2hfbhvc9dm0pc0pgq4dwvck0m7hikfdxy1q36mbl549ffymb")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/ba/4b/87a794e51d150f62a55715c453c9afbf6103fe24afef6db26a929a8480b7/imageio-2.38.0-py3-none-any.whl")
     (file-name "imageio-2.38.0-py3-none-any.whl")
     (sha256 (base32 "1z7bgjxxgg2cyk2gpr9551xfrv5a282g3mw15phfiq1nksis6kj7")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/cb/b1/3846dd7f199d53cb17f49cba7e651e9ce294d8497c8c150530ed11865bb8/iniconfig-2.3.0-py3-none-any.whl")
     (file-name "iniconfig-2.3.0-py3-none-any.whl")
     (sha256 (base32 "04mz7zawgv17cd002cavys6wjn9qzycrqm6hs222pia85i6w0cgn")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/26/48/bedf3ba4163e7db392c9d4cbdfc8217423196c8fccbe5a404a0f094fde63/installer-1.0.1-py3-none-any.whl")
     (file-name "installer-1.0.1-py3-none-any.whl")
     (sha256 (base32 "12yrdwa7rvfm24nhz6d7rl7a93a1whmf99z3vpbwwm5rz1fh8781")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/6b/c7/f6fd3db6c33a164631c39dce2ca26a3794e3abf91b875cc99a43a5565d88/iso639_lang-2.6.3-py3-none-any.whl")
     (file-name "iso639_lang-2.6.3-py3-none-any.whl")
     (sha256 (base32 "1fsgp6xqpvaj675a94yz5k7bq0zkh240k2zlqw6iijlxffgzphm6")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/62/a1/3d680cbfd5f4b8f15abc1d571870c5fc3e594bb582bc3b64ea099db13e56/jinja2-3.1.6-py3-none-any.whl")
     (file-name "jinja2-3.1.6-py3-none-any.whl")
     (sha256 (base32 "0rrgdp707wfs11wk8prswvx6ma418sk16z6xql9hqba93x2y9v45")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/18/53/84099323c2ec4be98d935f63c033ac4151ee83836ca1050ede3b3aadf155/joblib-1.6.0-py3-none-any.whl")
     (file-name "joblib-1.6.0-py3-none-any.whl")
     (sha256 (base32 "1fksxzmz4zip380jza6p678r0qzyh3lhhil5gcss54mmwkvgkfrx")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/69/90/f63fb5873511e014207a475e2bb4e8b2e570d655b00ac19a9a0ca0a385ee/jsonschema-4.26.0-py3-none-any.whl")
     (file-name "jsonschema-4.26.0-py3-none-any.whl")
     (sha256 (base32 "1kjhmcnmylpvznwdwwzvb6an41jzlz1v8r3y73w01lmqcd9g32fl")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/41/45/1a4ed80516f02155c51f51e8cedb3c1902296743db0bbc66608a0db2814f/jsonschema_specifications-2025.9.1-py3-none-any.whl")
     (file-name "jsonschema_specifications-2025.9.1-py3-none-any.whl")
     (sha256 (base32 "1zn61hhky48v2lw2h3qan2cgy6x4m3yjji54mkn7dvhi7bp2z04q")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/23/93/4e45e37f26c820216704b36b8e67cc55c490a7abd287a78a26a2c0e21386/lazy_loader-0.6-py3-none-any.whl")
     (file-name "lazy_loader-0.6-py3-none-any.whl")
     (sha256 (base32 "0mnhivakhvq2rzhsi70smxq49idncgb5n40n1r5141hv77ikn9bp")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/4a/6d/42640e15a8c34b57dc7ea922152440c0c6692214a08d5282b6e3eb46ddf4/lightning-2.6.1-py3-none-any.whl")
     (file-name "lightning-2.6.1-py3-none-any.whl")
     (sha256 (base32 "0c4dk122dzdp8sgzz6mwg8dkgcgcfayl31cjccv72k004fnavq9h")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/25/f4/ead6e0e37209b07c9baa3e984ccdb0348ca370b77cea3aaea8ddbb097e00/lightning_utilities-0.15.3-py3-none-any.whl")
     (file-name "lightning_utilities-0.15.3-py3-none-any.whl")
     (sha256 (base32 "14az7jkzb05x6p9lv14yj2jzx85kwjbdl6m4xb5s3100wyzg2mbc")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/0a/20/e022dbc6b4753a9bc9fc5fb28a27163430c1731b9913997f6544c1b2518c/lxml-6.1.3-cp312-cp312-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "lxml-6.1.3-cp312-cp312-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0315vkdfm9svzyjdphjq0apzvp0cqrgjhrv31msgfldhgf94x7wh")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/ec/1e/32971905a7ab47f8b66866ed949fa48b104ba1c4a6fa57794c4f2c4b2cb8/markdown-3.11-py3-none-any.whl")
     (file-name "markdown-3.11-py3-none-any.whl")
     (sha256 (base32 "17ki12a14xlk86qk1h5ciczs826ja9d22wyn5qrqp31hxgkqjv6d")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b3/81/4da04ced5a082363ecfa159c010d200ecbd959ae410c10c0264a38cac0f5/markdown_it_py-4.2.0-py3-none-any.whl")
     (file-name "markdown_it_py-4.2.0-py3-none-any.whl")
     (sha256 (base32 "0jhwcj9818zrpjiw6vsbsbw86387q6bysfj54r14jngy2k6vnzlz")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/4f/a7/aeedb5140afa41fc74c225e9184ab96723a6e873b6ee1c9fede7283456d8/markupsafe-3.0.4-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "markupsafe-3.0.4-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "109mc677bxc28q0gx5l8vdwkb7cnjs1f6a1p0kb33y468ybly4lf")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b3/38/89ba8ad64ae25be8de66a6d463314cf1eb366222074cfda9ee839c56a4b4/mdurl-0.1.2-py3-none-any.whl")
     (file-name "mdurl-0.1.2-py3-none-any.whl")
     (sha256 (base32 "1y5qjqhmq2nm7xj6w5rrp503r7jhj7zr2qcnr6gs858nwm0ql044")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/43/e3/7d92a15f894aa0c9c4b49b8ee9ac9850d6e63b03c9c32c0367a13ae62209/mpmath-1.3.0-py3-none-any.whl")
     (file-name "mpmath-1.3.0-py3-none-any.whl")
     (sha256 (base32 "0b4dr3jkanrgw306r0hx90nliywcfc433wbzcjk83kdvh3zbkcm0")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/ed/5b/db08419c1e1f7c9d60cfd2787b2b517d7ae4ebbda8281b48a33eb5141467/multidict-6.9.1-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "multidict-6.9.1-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0vd03x2smm5ffsgjfs43gqpmdnwadlwqvlrigpb7iv39kmldfvwp")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/7e/cd/fe58041e9011f307c490e3e17dd48cc516448f7c698a3f2d9d9d65d7e6a8/networkx-3.7-py3-none-any.whl")
     (file-name "networkx-3.7-py3-none-any.whl")
     (sha256 (base32 "1c51zipangvrz2vpzx4bllb7z9lqhmzqs39l8qvywk41lw9jrzg3")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/8c/3d/1e1db36cfd41f895d266b103df00ca5b3cbe965184df824dec5c08c6b803/numpy-2.2.6-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (file-name "numpy-2.2.6-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (sha256 (base32 "0jb2mjcsixxr9m0brzq62363xighg3302lpd3lzp7256509c10zx")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/63/34/ba1c580383c9eada3711951fef0795c80b829a078d72188184bcab9dd527/packaging-26.3-py3-none-any.whl")
     (file-name "packaging-26.3-py3-none-any.whl")
     (sha256 (base32 "076d4fdk71rwap5l9bfh1bx1c3pk1bwjn9p0zm2g94sfiry3y6fp")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/f1/d9/7fb5aa316bc299258e68c73ba3bddbc499654a07f151cba08f6153988714/pathspec-1.1.1-py3-none-any.whl")
     (file-name "pathspec-1.1.1-py3-none-any.whl")
     (sha256 (base32 "12di42dhpbympdw8q4jkvyzzii1b45b80c9j753pzgvpym1fc350")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/84/21/a35af28dcc61f37ed850a2d64c65c701321dfbf25085e469d5559360cbbf/pillow-12.3.0-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "pillow-12.3.0-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "14axlhvckmnx90712098r1i2mf9kc0pi5zbmigzvhnm3cml2rjvq")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/d0/89/446044f33aba0348d35e433f56d12206d010a5281a1df54054d4cfb82388/platformdirs-4.12.2-py3-none-any.whl")
     (file-name "platformdirs-4.12.2-py3-none-any.whl")
     (sha256 (base32 "10v9hlzb6dd1f9zgjhhq7g4pjcnn2h5gnxffvdmvq065jrnz1nr9")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/54/20/4d324d65cc6d9205fabedc306948156824eb9f0ee1633355a8f7ec5c66bf/pluggy-1.6.0-py3-none-any.whl")
     (file-name "pluggy-1.6.0-py3-none-any.whl")
     (sha256 (base32 "0ij7vmsc72c3bnaf78r77g1k5jcldmbca2vw6zlrac41srnjf879")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/85/9f/83a07b6ec0e043c050cfdd35fb0cf1b7897b91d554d6eea293740309afe7/propcache-0.5.4-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "propcache-0.5.4-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0jy19bd7x9hg5l3hzb3izk2nq5qw9ny23ydhwjz8gx0qx3cfq518")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/d6/c6/c9deaa6e789b6fc41b88ccbdfe7a42d2b82663248b715f55aa77fbc00724/protobuf-4.25.8-cp37-abi3-manylinux2014_x86_64.whl")
     (file-name "protobuf-4.25.8-cp37-abi3-manylinux2014_x86_64.whl")
     (sha256 (base32 "1c01a4sqpayzg0vmdqaj5gw50f2gjby6wvmd5jlrddnjjd7fbrl3")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b5/70/5d8df3b09e25bce090399cf48e452d25c935ab72dad19406c77f4e828045/psutil-7.2.2-cp36-abi3-manylinux2010_x86_64.manylinux_2_12_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "psutil-7.2.2-cp36-abi3-manylinux2010_x86_64.manylinux_2_12_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "1yf6bg578msswkw8akh1r46sjgajb7q8kfpm8hb85m1zj8pjssh7")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/a6/26/3f05f9e3692853dff663913d5d62fb8df3f5640c8d70b06588c0b51ed953/pyaml-26.7.0-py3-none-any.whl")
     (file-name "pyaml-26.7.0-py3-none-any.whl")
     (sha256 (base32 "1b3pf0ny2lzpa6gp9xbmy5p8ah8aam6kjzdqd436dbj31iw858yg")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/60/c9/711ca85d79f1ec98f29a5eae2b051e25b4ecec5de3e3c0e2d5c5dcb15664/pyarrow-25.0.1-cp312-cp312-manylinux_2_28_x86_64.whl")
     (file-name "pyarrow-25.0.1-cp312-cp312-manylinux_2_28_x86_64.whl")
     (sha256 (base32 "1hz42g9zdm17swm3yq2dar4j4c72w7k205p3r4aibva7jkvwv2ak")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/71/46/17f022dd3e953bf20a04a028a21ec746d942f8d2af30fa0f124fa0e6a684/pygments-2.21.0-py3-none-any.whl")
     (file-name "pygments-2.21.0-py3-none-any.whl")
     (sha256 (base32 "1n9pf4vk9v3358psh89bk544i3s6svf31cd3in1praf4c6dwcqr3")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/85/11/044d1ae1b4ec0d7af88ee5bc91e081be1022533032b906a7bdabdbb60977/pyproject_hooks-1.3.3-py3-none-any.whl")
     (file-name "pyproject_hooks-1.3.3-py3-none-any.whl")
     (sha256 (base32 "02x285s812vkrn436g9slmw4sy5lj1gzns68rpxn7ggpr7d3ziaz")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/24/25/1de2678b631f5a49215c6c96fff41ba892b0a34df68d6d80292b1b48aa7f/pytest-9.1.1-py3-none-any.whl")
     (file-name "pytest-9.1.1-py3-none-any.whl")
     (sha256 (base32 "032gkhb865xjkq4zqa8k2srwml0qiqz0cjb4ldhpm95rxx2npa1p")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl")
     (file-name "python_dateutil-2.9.0.post0-py2.py3-none-any.whl")
     (sha256 (base32 "09q48zvsbagfa3w87zkd2c5xl54wmb9rf2hlr20j4a5fzxxvrcm8")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/0e/93/c8c361bf0a2fe50f828f32def460e8b8a14b93955d3fd302b1a9b63b19e4/pytorch_lightning-2.6.1-py3-none-any.whl")
     (file-name "pytorch_lightning-2.6.1-py3-none-any.whl")
     (sha256 (base32 "0ngxgzn39ynwv6zm2sc3gjj8cfl842iimkqnbw2y6af8grb1i08z")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/8b/9d/b3589d3877982d4f2329302ef98a8026e7f4443c765c46cfecc8858c6b4b/pyyaml-6.0.3-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "pyyaml-6.0.3-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "1p7wpshndnmzija51f0ab0k84m7484b58haqfznd5qndgj5c075s")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/2c/58/ca301544e1fa93ed4f80d724bf5b194f6e4b945841c5bfd555878eea9fcb/referencing-0.37.0-py3-none-any.whl")
     (file-name "referencing-0.37.0-py3-none-any.whl")
     (sha256 (base32 "0c92d73yqnl26l1wn7a6dvvlmnaasf8nhwb1jc3cja4nz6ljj4rq")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/26/83/d2fbd2e4e3afb1167daa825187d196f313cbaa1a4768f311fb041bb0e3d2/regex-2026.9.29-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "regex-2026.9.29-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "1l762lcfpv1zvzl6mwxczjf5gnw70g2sbv56p9larybiv6a5iarr")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/a0/f4/c67b0b3f1b9245e8d266f0f112c500d50e5b4e83cb6f3b71b6528104182a/requests-2.34.2-py3-none-any.whl")
     (file-name "requests-2.34.2-py3-none-any.whl")
     (sha256 (base32 "1q3qw83lj7q63jdr7jxm6y6miczkq034jmg466mwcfpqfb0n039a")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/0d/9b/63f4c7ebc259242c89b3acafdb37b41d1185c07ff0011164674e9076b491/rich-14.0.0-py3-none-any.whl")
     (file-name "rich-14.0.0-py3-none-any.whl")
     (sha256 (base32 "1q6pjp1qs1l3dqzrj57y7y95hknhwf748bylzz50kb0sjphr350w")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/04/8f/d2f3f532616be4d06c316ef119683e832bd3d41e112bf3a88f4151c95b17/rpds_py-2026.6.3-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (file-name "rpds_py-2026.6.3-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (sha256 (base32 "19lbi0awsjf6pnyhqm14phdm1fi7zbwg55wp1xlngs3dnsfxdazc")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/a0/60/429e9b1cb3fc651937727befe258ea24122d9663e4d5709a48c9cbfceecb/safetensors-0.7.0-cp38-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (file-name "safetensors-0.7.0-cp38-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (sha256 (base32 "0j0da469z4jlbx3vxqrn4bl4910ksdfqapkglkg6ssgh70ljbiys")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/6b/b5/b75527c0f9532dd8a93e8e7cd8e62e547b9f207d4c11e24f0006e8646b36/scikit_image-0.25.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (file-name "scikit_image-0.25.2-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (sha256 (base32 "0928dzk3y6y90m4cb0jbjj0nm6fsli1mdd8vsg00qrk2hpmifzm1")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/5c/d0/0c577d9325b05594fdd33aa970bf53fb673f051a45496842caee13cfd7fe/scikit_learn-1.7.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
     (file-name "scikit_learn-1.7.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
     (sha256 (base32 "02yvdadj5aakd0cx2yxcx4lcv2gz4l9ar4fzg1aacxgf1a9kvgz5")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/0b/1f/03f52c282437a168ee2c7c14a1a0d0781a9a4a8962d84ac05c06b4c5b555/scipy-1.15.3-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (file-name "scipy-1.15.3-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
     (sha256 (base32 "0jdvz63ag2y2jbizlz7r6c9yc75nv9zvb5ryxajrw525wq9kf7i7")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/95/9c/c510029fc6ef33a6275cd2c5d3cecd6613dfd6aa401d57c54f1c18852ccf/setuptools-84.0.0-py3-none-any.whl")
     (file-name "setuptools-84.0.0-py3-none-any.whl")
     (sha256 (base32 "0w66n0r134vq4qsx2rjijfczj6azsrmqfm4nc0mi17mrnf92b9ai")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b9/37/e781683abac55dde9771e086b790e554811a71ed0b2b8a1e789b7430dd44/shapely-2.1.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
     (file-name "shapely-2.1.2-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
     (sha256 (base32 "0jy5n30307csxhs0gh9jdgsv1cccqz3i5jkp8as8p932s9x4sz8y")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/59/c4/e98ed4dfc15f51245e17626dab983ffde53f9f03ef5100938bcb4996427f/Sickle-0.7.0-py3-none-any.whl")
     (file-name "Sickle-0.7.0-py3-none-any.whl")
     (sha256 (base32 "11dwsjc1x8jd3x9axjhd5mp04v2ykv2c5vxz1pz72rf73wfppkka")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl")
     (file-name "six-1.17.0-py2.py3-none-any.whl")
     (sha256 (base32 "0x1jdic712dylbnyiqdj4xyxrlx0gaacynmbmkfiym4hxn8z68a7")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/a2/09/77d55d46fd61b4a135c444fc97158ef34a095e5681d0a6c10b75bf356191/sympy-1.14.0-py3-none-any.whl")
     (file-name "sympy-1.14.0-py3-none-any.whl")
     (sha256 (base32 "1xfq3dkk8gybiha9djrmcr5dj1cv8zsjhww4l85il56jk4zcr4g0")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/32/d5/f9a850d79b0851d1d4ef6456097579a9005b31fea68726a4ae5f2d82ddd9/threadpoolctl-3.6.0-py3-none-any.whl")
     (file-name "threadpoolctl-3.6.0-py3-none-any.whl")
     (sha256 (base32 "1yx7qh9rzay3inj3w237i68hnj6qxsjl77h3200m0a19bbyvi823")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/05/bf/04f3e61cb20a03678ca43f29bae9a7d0b7d9f563b86f5f600b2d8fba9712/tifffile-2026.9.20-py3-none-any.whl")
     (file-name "tifffile-2026.9.20-py3-none-any.whl")
     (sha256 (base32 "1rn0al3vsrk149hp8yclsjb72q64qj348if0wzr5fspnp1kk34cv")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/13/bc/8c13eb66537dce1d2bd3a57132902f38d0e7f5bb46fa9f4daed9fe9d76ee/tomlkit-0.15.1-py3-none-any.whl")
     (file-name "tomlkit-0.15.1-py3-none-any.whl")
     (sha256 (base32 "0123na4lvnrjhg5d6xyl14pkb3bvnjmlii6kdwkab32srsp0ayhp")))
   (origin
     (method url-fetch)
     (uri "https://download.pytorch.org/whl/cpu/torch-2.9.1%2Bcpu-cp312-cp312-manylinux_2_28_x86_64.whl")
     (file-name "torch-2.9.1+cpu-cp312-cp312-manylinux_2_28_x86_64.whl")
     (sha256 (base32 "18cy7ghjshj5sqa5w1a60as3wal9dlf47jslar2x66gjcp2xh5vl")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/c3/a2/c7f6ebf546f8f644edf0f999aa98ece106986a77a7b922316bf6414ff825/torchmetrics-1.9.0-py3-none-any.whl")
     (file-name "torchmetrics-1.9.0-py3-none-any.whl")
     (sha256 (base32 "18cw5l6qws0kqcc6lnw4ia5v5i13kyrnwjdj9cvv75hxvprvzp5z")))
   (origin
     (method url-fetch)
     (uri "https://download.pytorch.org/whl/cpu/torchvision-0.24.1%2Bcpu-cp312-cp312-manylinux_2_28_x86_64.whl")
     (file-name "torchvision-0.24.1+cpu-cp312-cp312-manylinux_2_28_x86_64.whl")
     (sha256 (base32 "0pgwb7qppqlil458lyc8hcp4l8pgkrzm3nydflgjya8j91ll1zs8")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/a7/03/921a3d3c75785aca9ebfbfcabfbc3a1be12e2ab5265deb026d55a5a3f83e/tqdm-4.70.1-py3-none-any.whl")
     (file-name "tqdm-4.70.1-py3-none-any.whl")
     (sha256 (base32 "0wzspyvv28z1jg6ixsazpcqsm802vw94dz98hw7c5ygywqjyb4y2")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/30/81/0da8afb52a71d0a4f2bd3152357b1a441e393b286374802b9d3addab4ab5/trove_classifiers-2026.9.21.13-py3-none-any.whl")
     (file-name "trove_classifiers-2026.9.21.13-py3-none-any.whl")
     (sha256 (base32 "05vs9n2kli9q53jivn9w3s8k55xrb921wzy3f45h9cciq7wz87wb")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/49/d3/b8441a820a491ddfc024b0b0cf0393375b75ea13866d9c66727e54c2fc80/typing_extensions-4.16.0-py3-none-any.whl")
     (file-name "typing_extensions-4.16.0-py3-none-any.whl")
     (sha256 (base32 "1s62f1iqvmshyfrzx76f752pmxpijx7a3bbnn70i7s3l2d4al728")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/92/9d/c4e665119135114480843e7ab388fa94d8480650450e6f8e26b70d323a4c/urllib3-2.8.0-py3-none-any.whl")
     (file-name "urllib3-2.8.0-py3-none-any.whl")
     (sha256 (base32 "1qy6bb3qdfsy8zclfxnafjwir3rj25gv7pr8ddbsjsnkd3jwmwqc")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/1c/59/964ecb8008722d27d8a835baea81f56a91cea8e097b3be992bc6ccde6367/versioningit-3.3.0-py3-none-any.whl")
     (file-name "versioningit-3.3.0-py3-none-any.whl")
     (sha256 (base32 "0jrywlfbhc5jw2ipsw3iqk8f6qf28dkfrpdhssdyvkan8wydpc93")))
   (origin
     (method url-fetch)
     (uri "https://files.pythonhosted.org/packages/bc/7b/ca212cbe170ac8b96e45317ecbcf9c3c3ecf0cdec98d5b088a9c4088929b/yarl-1.25.1-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (file-name "yarl-1.25.1-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
     (sha256 (base32 "17bnhdc2lrqzfvxbjqrrny6byvkybg38nkkmwn4f3p12kmw1gwf6")))
   ))
