;;; Fixed test-tool sources for ronami/meta-typing.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages meta-typing-npm-sources)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (%meta-typing-npm-sources
            %meta-typing-npm-layout
            meta-typing-typescript-source))

;; This is the transitive runtime closure of the yarn.lock-selected tsd 0.11.0,
;; plus the lock-selected standalone TypeScript 3.7.4 compiler.  The upstream
;; lint/watch development tools are not required by `yarn test`.  All 246
;; archives were fetched on 2026-10-06 and matched their recorded SHA-1/SHA-512
;; integrity values; the hashes below are SHA-256 of those same archive bytes.
;; tsd carries its own TypeScript 3.7.2 in libraries/typescript, used unchanged
;; for upstream assertions.  TypeScript 3.7.4 is the installed-consumer compiler.
;; None of these test tools are copied into the installed declaration package.
(define %meta-typing-npm-source-records
  (string-append
    "@mrmlnc/readdir-enhanced\t2.2.1\thttps://registry.npmjs.org/@mrmlnc/readdir-enhanced/-/readdir-enhanced-2.2.1.tgz\t0icnpkjqkq5dgz43wv0yx61vb5fnszwzs7fiw6x4sx5y7j87vrah\n"
    "@nodelib/fs.stat\t1.1.3\thttps://registry.npmjs.org/@nodelib/fs.stat/-/fs.stat-1.1.3.tgz\t15235shsmwcssr8ndh0jq6b6czip1pvnzi6z6cnljr27hmgzycy7\n"
    "@types/events\t3.0.0\thttps://registry.npmjs.org/@types/events/-/events-3.0.0.tgz\t18wizz3bmczfvbcqgzy1p0z06gvlpbkmp8n1wwhzzi4s7ip2s5i7\n"
    "@types/glob\t7.1.1\thttps://registry.npmjs.org/@types/glob/-/glob-7.1.1.tgz\t1bkk20gz7lzdrdpb0ksycm96gggp3bicxxh90xjcln785vma1r03\n"
    "@types/minimatch\t3.0.3\thttps://registry.npmjs.org/@types/minimatch/-/minimatch-3.0.3.tgz\t0xqnqvkc0h5hwizr7n28x6mxh070iyx3zqhb1xjxl7f4fcl53mvi\n"
    "@types/node\t13.1.2\thttps://registry.npmjs.org/@types/node/-/node-13.1.2.tgz\t0fkflrwqmm0r88x2d25jwc6p0xdjx2mcin3fbfs8d1kc5y13bf82\n"
    "ansi-align\t2.0.0\thttps://registry.npmjs.org/ansi-align/-/ansi-align-2.0.0.tgz\t1nk1hd3qbgjira2phxqdcyqq530c6hppvllpj3r5nga10bs5g6nn\n"
    "ansi-escapes\t2.0.0\thttps://registry.npmjs.org/ansi-escapes/-/ansi-escapes-2.0.0.tgz\t0l4rgd5fkagvplcy2b22gx5ba1137d3xr3rqyn1dckywaa369y74\n"
    "ansi-regex\t3.0.0\thttps://registry.npmjs.org/ansi-regex/-/ansi-regex-3.0.0.tgz\t0d9xwkpwak84xixi7f21bxvrbdgdpwm4pna73jkm8pfk6v8b1bdx\n"
    "ansi-styles\t3.2.1\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-3.2.1.tgz\t1wqd08glq159q724kvpi6nnf87biajr749a7r9c84xm639g6463k\n"
    "arr-diff\t4.0.0\thttps://registry.npmjs.org/arr-diff/-/arr-diff-4.0.0.tgz\t1735byq6vmrvqkv9n5400494mh9vd6x4knzkybgr55km5dgpdcyx\n"
    "arr-flatten\t1.1.0\thttps://registry.npmjs.org/arr-flatten/-/arr-flatten-1.1.0.tgz\t0amnq01y6y8j49rdcib9yh8n95wk2ajs3qcckccvv1x6bf6nfvay\n"
    "arr-union\t3.1.0\thttps://registry.npmjs.org/arr-union/-/arr-union-3.1.0.tgz\t1jrcfq6xnx3lbvnpl9pzfvc2v3bcgyir1vwcc7p0slhf6gglzd3p\n"
    "array-find-index\t1.0.2\thttps://registry.npmjs.org/array-find-index/-/array-find-index-1.0.2.tgz\t1iiv44clp2il3waph7vaz5b7jd81jcbq2jh022wkm1pq1aw6rsh5\n"
    "array-union\t1.0.2\thttps://registry.npmjs.org/array-union/-/array-union-1.0.2.tgz\t0ivr7ywdj40hdsqcnwyhdayx37sbrs0hdfjmf35b0x6qddqgm8w8\n"
    "array-uniq\t1.0.3\thttps://registry.npmjs.org/array-uniq/-/array-uniq-1.0.3.tgz\t1r3jdy6pw004czvcbamr08wh7g2nmwwlskdzf1wa6rbm63gbqnng\n"
    "array-unique\t0.3.2\thttps://registry.npmjs.org/array-unique/-/array-unique-0.3.2.tgz\t0bkrb481qri7qad5h4bzw9hq161wfqgxdj5g11a5bnlfylqczg9g\n"
    "arrify\t1.0.1\thttps://registry.npmjs.org/arrify/-/arrify-1.0.1.tgz\t0dw9ha2mwzfg0d5h0b8r3rkwqy0iz8qhsrz5br0wkw96yafxvblp\n"
    "assign-symbols\t1.0.0\thttps://registry.npmjs.org/assign-symbols/-/assign-symbols-1.0.0.tgz\t1lpcb6gzhdl4l9843kifsz9z48qwpk5gw6b1h6f6n7h5d8qp2xab\n"
    "atob\t2.1.2\thttps://registry.npmjs.org/atob/-/atob-2.1.2.tgz\t1nmrnfpzg9a99i4p88knw3470d5vcqmm3hyhavlln96wnza2lbg5\n"
    "balanced-match\t1.0.0\thttps://registry.npmjs.org/balanced-match/-/balanced-match-1.0.0.tgz\t1bgzp9jp8ws0kdfgq8h6w3qz8cljyzgcrmxypxkgbknk28n615i8\n"
    "base\t0.11.2\thttps://registry.npmjs.org/base/-/base-0.11.2.tgz\t0wh3b37238q4x15diq4vp2vx6d6zqh9z0559p0kk6xh0v9b95ca0\n"
    "boxen\t1.3.0\thttps://registry.npmjs.org/boxen/-/boxen-1.3.0.tgz\t0vi979qrla6z0mr57q4jr7z1ihai44ncwd7ls81mb2rax7snzz1l\n"
    "brace-expansion\t1.1.11\thttps://registry.npmjs.org/brace-expansion/-/brace-expansion-1.1.11.tgz\t1nlmjvlwlp88knblnayns0brr7a9m2fynrlwq425lrpb4mcn9gc4\n"
    "braces\t2.3.2\thttps://registry.npmjs.org/braces/-/braces-2.3.2.tgz\t10608dfl1pxajw0nwrsh69769q659yjyw88b0mrlprnn0z1wya1l\n"
    "cache-base\t1.0.1\thttps://registry.npmjs.org/cache-base/-/cache-base-1.0.1.tgz\t1iny3winp8x5ac39hx52baq60g2hsp4pcx95a634c83klawdaw78\n"
    "call-me-maybe\t1.0.1\thttps://registry.npmjs.org/call-me-maybe/-/call-me-maybe-1.0.1.tgz\t1vvgckz5abc1d1p092v6sxpnypw1dqbvhsdvi4f43am2b8gh66xs\n"
    "camelcase-keys\t4.2.0\thttps://registry.npmjs.org/camelcase-keys/-/camelcase-keys-4.2.0.tgz\t08zc215h9wmrizsvlqy4gggyhvhzwh5sbs2nkhmdnq3hyhdm73zx\n"
    "camelcase\t4.1.0\thttps://registry.npmjs.org/camelcase/-/camelcase-4.1.0.tgz\t1xcjfpd0w5rcg282ksk7h42mp5k7fb51xa4nipsvff55020gcfws\n"
    "capture-stack-trace\t1.0.1\thttps://registry.npmjs.org/capture-stack-trace/-/capture-stack-trace-1.0.1.tgz\t07xbdsfakbgdpilygsjhzpwn8r92rvlhv8ayvrkyxdgjxl6p79fs\n"
    "chalk\t2.4.2\thttps://registry.npmjs.org/chalk/-/chalk-2.4.2.tgz\t0wf6hln5gcjb2n8p18gag6idghl6dfq4if6pxa6s1jqnwr94x26h\n"
    "ci-info\t1.6.0\thttps://registry.npmjs.org/ci-info/-/ci-info-1.6.0.tgz\t1lfy9p0mlff437lrszcirp743rkxhynmljj66bmbky71cd7g24gj\n"
    "class-utils\t0.3.6\thttps://registry.npmjs.org/class-utils/-/class-utils-0.3.6.tgz\t0567alh9j9bl7rj91frmjdpb4q5zig9rydzkdm9pmij85h7sffjh\n"
    "cli-boxes\t1.0.0\thttps://registry.npmjs.org/cli-boxes/-/cli-boxes-1.0.0.tgz\t11wi5xzf5d1xaar0v2yqzffp9z729vsx9xdhal1adncvz8j1s4cq\n"
    "collection-visit\t1.0.0\thttps://registry.npmjs.org/collection-visit/-/collection-visit-1.0.0.tgz\t062q78a3fjfvk4vplkay9hd4rx6f1xw4r0438sa0hbv62jf5bc46\n"
    "color-convert\t1.9.3\thttps://registry.npmjs.org/color-convert/-/color-convert-1.9.3.tgz\t1ahbdssv1qgwlzvhv7731hpfgz8wny0619x97b7n5x9lckj17i0j\n"
    "color-name\t1.1.3\thttps://registry.npmjs.org/color-name/-/color-name-1.1.3.tgz\t0kkq17s5yg6lg8ncg2nls6asih58qafn7wbrcgmwnqr5zdqk7vxh\n"
    "component-emitter\t1.3.0\thttps://registry.npmjs.org/component-emitter/-/component-emitter-1.3.0.tgz\t0qc1qx0ngvah8lmkn0d784vlxmya2kr5gpjcpfikxlpwx5v3wr0h\n"
    "concat-map\t0.0.1\thttps://registry.npmjs.org/concat-map/-/concat-map-0.0.1.tgz\t0qa2zqn9rrr2fqdki44s4s2dk2d8307i4556kv25h06g43b2v41m\n"
    "configstore\t3.1.2\thttps://registry.npmjs.org/configstore/-/configstore-3.1.2.tgz\t1gh50a084ha1x30i7vp4g4aak9r977kyywi513gsxwcc9c4jh5s1\n"
    "copy-descriptor\t0.1.1\thttps://registry.npmjs.org/copy-descriptor/-/copy-descriptor-0.1.1.tgz\t1dmlg6g04hfn1kmjklw6l33va255gsml1mrlz07jfv2a4alz4470\n"
    "create-error-class\t3.0.2\thttps://registry.npmjs.org/create-error-class/-/create-error-class-3.0.2.tgz\t0hf1w42z48vy8ymk51krv7g1w4fan4796jva61mz2s0zspggkd2q\n"
    "cross-spawn\t5.1.0\thttps://registry.npmjs.org/cross-spawn/-/cross-spawn-5.1.0.tgz\t0vgzrj7qwzw49xv1yqx2axya667fbsbg12gp89plv9jxrpl0a24i\n"
    "crypto-random-string\t1.0.0\thttps://registry.npmjs.org/crypto-random-string/-/crypto-random-string-1.0.0.tgz\t1wgkfcxnh4kynyrcmw686pb66dzaik90qa0nd6l96k1b298dcqgm\n"
    "currently-unhandled\t0.4.1\thttps://registry.npmjs.org/currently-unhandled/-/currently-unhandled-0.4.1.tgz\t07fn2vm6wadzvzc75q06ws8n72vkgyyhfscn97xsm3dkfggvq80w\n"
    "debug\t2.6.9\thttps://registry.npmjs.org/debug/-/debug-2.6.9.tgz\t160wvc74r8aypds7pym3hq4qpa786hpk4vif58ggiwcqcv34ibil\n"
    "decamelize-keys\t1.1.0\thttps://registry.npmjs.org/decamelize-keys/-/decamelize-keys-1.1.0.tgz\t0ddnhx1dc389v1wlyx8w16r5f61yl59pb5kf3yz5hj01jxnq8qnd\n"
    "decamelize\t1.2.0\thttps://registry.npmjs.org/decamelize/-/decamelize-1.2.0.tgz\t0r187qd80plv8mm8riqk3xcmpip3zcpsgjrvf013m37323syzbdl\n"
    "decode-uri-component\t0.2.0\thttps://registry.npmjs.org/decode-uri-component/-/decode-uri-component-0.2.0.tgz\t1mhafchzv526marx5laflfrfz1dsz0mi61r9805rn96dhry44gha\n"
    "deep-extend\t0.6.0\thttps://registry.npmjs.org/deep-extend/-/deep-extend-0.6.0.tgz\t11hk1g7qjw9bj03c8y7v7n8p8mdfacpd9l8n57dga8qcj8s5zk0d\n"
    "define-property\t0.2.5\thttps://registry.npmjs.org/define-property/-/define-property-0.2.5.tgz\t1r2gws87mpwv0i1rl3l79bw8psgpz44vwyd9va9cr90bvkada5yk\n"
    "define-property\t1.0.0\thttps://registry.npmjs.org/define-property/-/define-property-1.0.0.tgz\t1547m4v074hgd28jzv4k82ig43pl7rgfnp0y832swxmlff4ra6m6\n"
    "define-property\t2.0.2\thttps://registry.npmjs.org/define-property/-/define-property-2.0.2.tgz\t0m8x3myy76d3w777c1jq94gafphxqrpj7sy3myxcvksfk0p8vpha\n"
    "dir-glob\t2.2.2\thttps://registry.npmjs.org/dir-glob/-/dir-glob-2.2.2.tgz\t1sbp8qgaysw0j2hcjx3wh4arkqnkhajhd7g4vi6z54j99vb7k54p\n"
    "dot-prop\t4.2.0\thttps://registry.npmjs.org/dot-prop/-/dot-prop-4.2.0.tgz\t14pz3w9mmnzs64w9wlxn96d3di8axj828gakd68976rxgz5cgkcd\n"
    "duplexer3\t0.1.4\thttps://registry.npmjs.org/duplexer3/-/duplexer3-0.1.4.tgz\t1hlf9psifncy60fb08zap7s4yl0raczd8i4hn8jqkp8dp0i6sjj6\n"
    "error-ex\t1.3.2\thttps://registry.npmjs.org/error-ex/-/error-ex-1.3.2.tgz\t12gyrmh6iqpx838bnb5iwcqm2447rnbxx1bvqn76l40fvr1aichs\n"
    "escape-string-regexp\t1.0.5\thttps://registry.npmjs.org/escape-string-regexp/-/escape-string-regexp-1.0.5.tgz\t0iy3jirnnslnfwk8wa5xkg56fnbmg7bsv5v2a1s0qgbnfqp7j375\n"
    "eslint-formatter-pretty\t1.3.0\thttps://registry.npmjs.org/eslint-formatter-pretty/-/eslint-formatter-pretty-1.3.0.tgz\t1nl3cpakqp0zv5vgjh07jbi7ivawnk92yin9kvxfmffdzcq90ab5\n"
    "execa\t0.7.0\thttps://registry.npmjs.org/execa/-/execa-0.7.0.tgz\t05jw6x4i9glhn4k5i2y5i0gkx24whcnpc4jzb9wmhgpfqlz3g2ys\n"
    "expand-brackets\t2.1.4\thttps://registry.npmjs.org/expand-brackets/-/expand-brackets-2.1.4.tgz\t0csxpxfx1xkf2dp10vpifynkrx8csx7md7gysvhy5xr094hdr3nq\n"
    "extend-shallow\t2.0.1\thttps://registry.npmjs.org/extend-shallow/-/extend-shallow-2.0.1.tgz\t09baxpl8w1rw3qmqmp7w23kyqrxks1hhbvpac0j82gbsgimrlz0v\n"
    "extend-shallow\t3.0.2\thttps://registry.npmjs.org/extend-shallow/-/extend-shallow-3.0.2.tgz\t02bickcbljfrxfix2rbvq5j2cdlwm0dqflxc2ky4l6jp97bcl6m0\n"
    "extglob\t2.0.4\thttps://registry.npmjs.org/extglob/-/extglob-2.0.4.tgz\t1wza438hvcr83b28zic65h8jq8k0p0v9iw9b1lfk1zhb5xrkp8sy\n"
    "fast-glob\t2.2.7\thttps://registry.npmjs.org/fast-glob/-/fast-glob-2.2.7.tgz\t16nz3vz2pxnj17jmy0s4ypd9kpslby41lli730pslllrwlgixqai\n"
    "fill-range\t4.0.0\thttps://registry.npmjs.org/fill-range/-/fill-range-4.0.0.tgz\t14kaakn1yhkfsclqds0pg1g87aibi8nkrwn0axvfasj495hv2wzx\n"
    "find-up\t2.1.0\thttps://registry.npmjs.org/find-up/-/find-up-2.1.0.tgz\t07dd6cbb6dj1ff52pkkga0zaisn1vfp8n615x6n7wjrkqzybzzz3\n"
    "find-up\t3.0.0\thttps://registry.npmjs.org/find-up/-/find-up-3.0.0.tgz\t0ln7mwc9b465l646xvjd0692yy6izi27xb4y7g8ffpvjl7s9fx4r\n"
    "for-in\t1.0.2\thttps://registry.npmjs.org/for-in/-/for-in-1.0.2.tgz\t0pm8dx9gvp9p91my9fqivajq7yhnxmn8scl391pgcv6d8h6s6zaf\n"
    "fragment-cache\t0.2.1\thttps://registry.npmjs.org/fragment-cache/-/fragment-cache-0.2.1.tgz\t114jfm5qpvz52127hf4ny4vz1qs7a597hql5lj0g2ncixn8sqg76\n"
    "fs.realpath\t1.0.0\thttps://registry.npmjs.org/fs.realpath/-/fs.realpath-1.0.0.tgz\t174g5vay9jnd7h5q8hfdw6dnmwl1gdpn4a8sz0ysanhj2f3wp04y\n"
    "get-stream\t3.0.0\thttps://registry.npmjs.org/get-stream/-/get-stream-3.0.0.tgz\t0vh08ligj02bzcp49hcvibilrhyv02r5hj2gzgx03a59hfs0apkp\n"
    "get-value\t2.0.6\thttps://registry.npmjs.org/get-value/-/get-value-2.0.6.tgz\t057wz0ya7zlgz59m08zbaasvzfdxjzgd6bzphd2xwsydhjwnw02l\n"
    "glob-parent\t3.1.0\thttps://registry.npmjs.org/glob-parent/-/glob-parent-3.1.0.tgz\t05d92ijvizlxlgss00d3qs5d9gj6ax39vhjhjacyidynl6dny7x9\n"
    "glob-to-regexp\t0.3.0\thttps://registry.npmjs.org/glob-to-regexp/-/glob-to-regexp-0.3.0.tgz\t0d14ajj41gii376an0x7jihiq6pvs29fj10l7y6sv66i1h4h97wa\n"
    "glob\t7.1.6\thttps://registry.npmjs.org/glob/-/glob-7.1.6.tgz\t1hm62p225wxx15k5kw9b5byif2rdi4ivn2a595lfvv26niq53c2l\n"
    "global-dirs\t0.1.1\thttps://registry.npmjs.org/global-dirs/-/global-dirs-0.1.1.tgz\t1kzb8klcnynl9pi803d68byvxx72dhwgfz8ch5px884f07z25dma\n"
    "globby\t9.2.0\thttps://registry.npmjs.org/globby/-/globby-9.2.0.tgz\t1pdj5lsm59h838f4l3j33cs9ps2zd5b39h41z5p31d8rvm7hvcff\n"
    "got\t6.7.1\thttps://registry.npmjs.org/got/-/got-6.7.1.tgz\t1jc9apz4qbnbx7jx0s03v5vqnz2ja0mzaljxa7zpvggar1lw5lwc\n"
    "graceful-fs\t4.2.3\thttps://registry.npmjs.org/graceful-fs/-/graceful-fs-4.2.3.tgz\t0y67gagnp7aqg3drlardvshhndmpbdfmgflbhvsbrjdn5fiknbcq\n"
    "has-flag\t3.0.0\thttps://registry.npmjs.org/has-flag/-/has-flag-3.0.0.tgz\t1sp0m48zavms86q7vkf90mwll9z2bqi11hk3s01aw8nw40r72jzd\n"
    "has-value\t0.3.1\thttps://registry.npmjs.org/has-value/-/has-value-0.3.1.tgz\t1h4dnzr9rszpj0a015529r1c9g8ysy4wym6ay99vc6dls02jhmny\n"
    "has-value\t1.0.0\thttps://registry.npmjs.org/has-value/-/has-value-1.0.0.tgz\t1ikpbff1imw3nqqp9q9siwh7p93r1pdigiv6kgryx6l8hwiwbxr9\n"
    "has-values\t0.1.4\thttps://registry.npmjs.org/has-values/-/has-values-0.1.4.tgz\t1lnp2ww5w0lxxiqrm3scyaddj7csdrd4ldsmsvapys4rdfgnx0m6\n"
    "has-values\t1.0.0\thttps://registry.npmjs.org/has-values/-/has-values-1.0.0.tgz\t19ggazh85imjwxnvvhabypdpmyl0q4mgm3frwfx2dx3ffq1g1bwc\n"
    "hosted-git-info\t2.8.5\thttps://registry.npmjs.org/hosted-git-info/-/hosted-git-info-2.8.5.tgz\t0y0sxyr279y79ncx58y4adw790ssixlfp31scrjrly0haa602s2b\n"
    "ignore\t4.0.6\thttps://registry.npmjs.org/ignore/-/ignore-4.0.6.tgz\t1ksjvh6kxz7qv5qmljnv5my2k2qm5kyphgszgzzaak0s5yha66kx\n"
    "import-lazy\t2.1.0\thttps://registry.npmjs.org/import-lazy/-/import-lazy-2.1.0.tgz\t1zb561xl5rw3a5gbvy0pm76kcrlxrrz63gcpgzq8kk068pi06p4j\n"
    "imurmurhash\t0.1.4\thttps://registry.npmjs.org/imurmurhash/-/imurmurhash-0.1.4.tgz\t0q6bf91h2g5dhvcdss74sjvp5irimd97hp73jb8p2wvajqqs08xc\n"
    "indent-string\t3.2.0\thttps://registry.npmjs.org/indent-string/-/indent-string-3.2.0.tgz\t11lhy255zb047706mijqaf3q6l5i2laa4b8nsp6hhwpd56yw61ls\n"
    "inflight\t1.0.6\thttps://registry.npmjs.org/inflight/-/inflight-1.0.6.tgz\t16w864087xsh3q7f5gm3754s7bpsb9fq3dhknk9nmbvlk3sxr7ss\n"
    "inherits\t2.0.4\thttps://registry.npmjs.org/inherits/-/inherits-2.0.4.tgz\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\n"
    "ini\t1.3.5\thttps://registry.npmjs.org/ini/-/ini-1.3.5.tgz\t0pbq8qv4yry4cr1m0nmrz0vz6gfq96y816687vmlwh47rj3vv3py\n"
    "irregular-plurals\t1.4.0\thttps://registry.npmjs.org/irregular-plurals/-/irregular-plurals-1.4.0.tgz\t05618cjs0fg7w0sqmc352ihlr1kpxnryjl601hgldi9jp8d7868s\n"
    "is-accessor-descriptor\t0.1.6\thttps://registry.npmjs.org/is-accessor-descriptor/-/is-accessor-descriptor-0.1.6.tgz\t1j9kc4m771w28kdrph25q8q62yfiazg2gi6frnbfd66xfmimhmi3\n"
    "is-accessor-descriptor\t1.0.0\thttps://registry.npmjs.org/is-accessor-descriptor/-/is-accessor-descriptor-1.0.0.tgz\t18ybls0d0q6y7gp8mzhypyr0vbrx1vr5agm07s201byvc5dfmxql\n"
    "is-arrayish\t0.2.1\thttps://registry.npmjs.org/is-arrayish/-/is-arrayish-0.2.1.tgz\t13734x7w9924g9pch6ywgz741hs5ir612k3578k9fy247vcib3c4\n"
    "is-buffer\t1.1.6\thttps://registry.npmjs.org/is-buffer/-/is-buffer-1.1.6.tgz\t03l8f9r41xy0lq5zjm790jg758r8wv3fcsfwsd8331w6l30dh6ix\n"
    "is-ci\t1.2.1\thttps://registry.npmjs.org/is-ci/-/is-ci-1.2.1.tgz\t1cw9cn91kwsv36slvh7zpw9vb1m9cmfr2kiyyqwwzm05gv3x6hdv\n"
    "is-data-descriptor\t0.1.4\thttps://registry.npmjs.org/is-data-descriptor/-/is-data-descriptor-0.1.4.tgz\t0grcjmph4r8s17dd24mbq3ax09q9qgm6vrpjwkmhsc87nv42m9s3\n"
    "is-data-descriptor\t1.0.0\thttps://registry.npmjs.org/is-data-descriptor/-/is-data-descriptor-1.0.0.tgz\t0b51kish7r330jy625yaz424kvawrh8vxnpajmkx364pw9hm9hi8\n"
    "is-descriptor\t0.1.6\thttps://registry.npmjs.org/is-descriptor/-/is-descriptor-0.1.6.tgz\t0smh1f833y06l7m1qasjms9kv9qjr11bzyaslpz0wq9qmbkl5mdh\n"
    "is-descriptor\t1.0.2\thttps://registry.npmjs.org/is-descriptor/-/is-descriptor-1.0.2.tgz\t1bbfdklsskykp1qw9h2mpxjk7hjh6685s1raq73lxbn2b6iyfppy\n"
    "is-extendable\t0.1.1\thttps://registry.npmjs.org/is-extendable/-/is-extendable-0.1.1.tgz\t12f91w1hcv9hw2jlrxf3831zhw7fb0bmzdybzsqb71h5phyjnd7b\n"
    "is-extendable\t1.0.1\thttps://registry.npmjs.org/is-extendable/-/is-extendable-1.0.1.tgz\t0n1610rd5qv9h43zkr464dvk6hns1afmfpzg1g7b7z6as3axkss2\n"
    "is-extglob\t2.1.1\thttps://registry.npmjs.org/is-extglob/-/is-extglob-2.1.1.tgz\t06dwa2xzjx6az40wlvwj11vican2w46710b9170jzmka2j344pcc\n"
    "is-fullwidth-code-point\t2.0.0\thttps://registry.npmjs.org/is-fullwidth-code-point/-/is-fullwidth-code-point-2.0.0.tgz\t0sx0mg720hlpxdcg3rpf5ck93bwzkvb5883686v2iwvbxvnx1l2c\n"
    "is-glob\t3.1.0\thttps://registry.npmjs.org/is-glob/-/is-glob-3.1.0.tgz\t0526r4sl578azyqaamrb6s08f7m3hc9y39cl5zj0r9ymjg82dm7x\n"
    "is-glob\t4.0.1\thttps://registry.npmjs.org/is-glob/-/is-glob-4.0.1.tgz\t035rbaadrqyx77bsn3ps3p8h7hf18zz0v5nb73xy26li0cs5cmwb\n"
    "is-installed-globally\t0.1.0\thttps://registry.npmjs.org/is-installed-globally/-/is-installed-globally-0.1.0.tgz\t0vmqw9b32qh8l16da3rclrw3kgas2hbr8vvyw2srfmgfc6bq5793\n"
    "is-npm\t1.0.0\thttps://registry.npmjs.org/is-npm/-/is-npm-1.0.0.tgz\t050bal75k37aqbw49qz9ji1idf0l1y3hk99fs9sxq2vwbqznp449\n"
    "is-number\t3.0.0\thttps://registry.npmjs.org/is-number/-/is-number-3.0.0.tgz\t19rpbi5ryx3y28bh0pwm99az1mridh0p2sinfdxkcbpbxfx5zbf4\n"
    "is-obj\t1.0.1\thttps://registry.npmjs.org/is-obj/-/is-obj-1.0.1.tgz\t13vfhhb7znp1b3brymbrkwwfijvy5hlnhqidw7qhhva2yb7acf9k\n"
    "is-path-inside\t1.0.1\thttps://registry.npmjs.org/is-path-inside/-/is-path-inside-1.0.1.tgz\t0xfv2zvarg6p72wwyxy3b8p6ymrnmww2kpmx4vgycrpawkc739qf\n"
    "is-plain-obj\t1.1.0\thttps://registry.npmjs.org/is-plain-obj/-/is-plain-obj-1.1.0.tgz\t1j17ai7dnfx23cr63whw91s7b0x096f82lfmsqz9y2p3q7wl9k5s\n"
    "is-plain-object\t2.0.4\thttps://registry.npmjs.org/is-plain-object/-/is-plain-object-2.0.4.tgz\t1ipx9y0c1kmq6irjxix6vcxfax6ilnns9pkgjc6cq8ygnyagv4s8\n"
    "is-redirect\t1.0.0\thttps://registry.npmjs.org/is-redirect/-/is-redirect-1.0.0.tgz\t1gjinm8w40k65dd8hc6izl2v08vr2ddkdbnr726gr14limqfbwrm\n"
    "is-retry-allowed\t1.2.0\thttps://registry.npmjs.org/is-retry-allowed/-/is-retry-allowed-1.2.0.tgz\t0s2rz0c9fj680dm32fdg0h5335iz0f5ldxn3qr6cb2w89jyj97m4\n"
    "is-stream\t1.1.0\thttps://registry.npmjs.org/is-stream/-/is-stream-1.1.0.tgz\t07rq3hqj1fnr9r4j6kj2jaimspyxlq52q70ajx0kcs8nbv3k7n4x\n"
    "is-windows\t1.0.2\thttps://registry.npmjs.org/is-windows/-/is-windows-1.0.2.tgz\t18iihzz6fs6sfrgq1bpvgkfk3cza6r9wrrgn7ahcbbra1lkjh4bv\n"
    "isarray\t1.0.0\thttps://registry.npmjs.org/isarray/-/isarray-1.0.0.tgz\t11qcjpdzigcwcprhv7nyarlzjcwf3sv5i66q75zf08jj9zqpcg72\n"
    "isexe\t2.0.0\thttps://registry.npmjs.org/isexe/-/isexe-2.0.0.tgz\t0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7\n"
    "isobject\t2.1.0\thttps://registry.npmjs.org/isobject/-/isobject-2.1.0.tgz\t14df1spjczhml90421sq645shkxwggrbbkgp1qgal29kslc7av32\n"
    "isobject\t3.0.1\thttps://registry.npmjs.org/isobject/-/isobject-3.0.1.tgz\t0dvx6rhjj5b9q7fcjg24lfy2nr3a1d2ypqy9zf9lqr2s00mwkiiw\n"
    "json-parse-better-errors\t1.0.2\thttps://registry.npmjs.org/json-parse-better-errors/-/json-parse-better-errors-1.0.2.tgz\t1j89a2mmkghaan76ilpcjr437gwdgbi65aab9i6amsr84pb6bg02\n"
    "kind-of\t3.2.2\thttps://registry.npmjs.org/kind-of/-/kind-of-3.2.2.tgz\t0isxns331nf5f4h8yj0vb4rj626bscxh1rh7j92vk8lbzcs2x93q\n"
    "kind-of\t4.0.0\thttps://registry.npmjs.org/kind-of/-/kind-of-4.0.0.tgz\t0afwg6007r7l0c9r7jghdk8pwvfffmykhybpwrs0nlks59d2ziym\n"
    "kind-of\t5.1.0\thttps://registry.npmjs.org/kind-of/-/kind-of-5.1.0.tgz\t0wkp161zwgg2jp5rjnkw7d7lgczbxj6bwvqvh4s8j68ghk0c8q2d\n"
    "kind-of\t6.0.2\thttps://registry.npmjs.org/kind-of/-/kind-of-6.0.2.tgz\t143y1awpq5s0nsrpmj78x58s256x1r8kdryss01rdyibm0p5fi5q\n"
    "latest-version\t3.1.0\thttps://registry.npmjs.org/latest-version/-/latest-version-3.1.0.tgz\t0hrgczdp0yfl950baanrlmp082m1srxjpngrq3xfpv77padp72r3\n"
    "load-json-file\t4.0.0\thttps://registry.npmjs.org/load-json-file/-/load-json-file-4.0.0.tgz\t0w0p7c5ykcyr3pkmgw2dg5qdzlxrxz4s40h5h9wkyplrhnvkkgxh\n"
    "locate-path\t2.0.0\thttps://registry.npmjs.org/locate-path/-/locate-path-2.0.0.tgz\t1hkjzakjwk6lix7yr73yx65hhlpf45rc8i2mj2c70fiab3zhzaxi\n"
    "locate-path\t3.0.0\thttps://registry.npmjs.org/locate-path/-/locate-path-3.0.0.tgz\t1ghmaifkp6r47h6ygdgkf7srvxhc5qwhgjwq00ia250kpxww5xdm\n"
    "log-symbols\t2.2.0\thttps://registry.npmjs.org/log-symbols/-/log-symbols-2.2.0.tgz\t02ww3c1afldv3ifix2q4i3y7xsqgkggf9alz60dxmng6k8rzzj6d\n"
    "loud-rejection\t1.6.0\thttps://registry.npmjs.org/loud-rejection/-/loud-rejection-1.6.0.tgz\t1yn327sb2h3xidf2w1nawr414cx1vn93zb1phzrxcp3sc8rid7pc\n"
    "lowercase-keys\t1.0.1\thttps://registry.npmjs.org/lowercase-keys/-/lowercase-keys-1.0.1.tgz\t1js2kblms2hf4zbn578y12rbv9vx3h2j2j0v9pd510ha8c6pks78\n"
    "lru-cache\t4.1.5\thttps://registry.npmjs.org/lru-cache/-/lru-cache-4.1.5.tgz\t1fdbhyf0d7pxg06qkzav7sz1mayvzbq31bxcshnfcyhihpd3bzf9\n"
    "make-dir\t1.3.0\thttps://registry.npmjs.org/make-dir/-/make-dir-1.3.0.tgz\t1gmm8zb675b8fmq0zy8nrlavka8ywrxl3qmrhxnizcaxcvnkzdn1\n"
    "map-cache\t0.2.2\thttps://registry.npmjs.org/map-cache/-/map-cache-0.2.2.tgz\t0gag01y8x17l2ffdmi5rgll24bw4cmyi3wksk45xpghirlkrkhj1\n"
    "map-obj\t1.0.1\thttps://registry.npmjs.org/map-obj/-/map-obj-1.0.1.tgz\t1rdkd9jsa1hdnhyrfq91dfyvzwzvsag67zmlvw4qjrn9679x4n43\n"
    "map-obj\t2.0.0\thttps://registry.npmjs.org/map-obj/-/map-obj-2.0.0.tgz\t1psw249095ydakcxmvbmhxr5nsa4i74fj2pwi5mc0j439kjmj70l\n"
    "map-visit\t1.0.0\thttps://registry.npmjs.org/map-visit/-/map-visit-1.0.0.tgz\t19fhyr0jmskx32s1s9b6p0jb96gmbxxnbmzx4sc42sxzwkfmqvpi\n"
    "meow\t5.0.0\thttps://registry.npmjs.org/meow/-/meow-5.0.0.tgz\t03w1isrh6rb71cdsh80iys6w3ppn5q8kcxsbfw2h0brpxbfdi41l\n"
    "merge2\t1.3.0\thttps://registry.npmjs.org/merge2/-/merge2-1.3.0.tgz\t0blj0zry82pklbby4k4is6nnz3ifsq48w70bxgl7jwzr4g53ry41\n"
    "micromatch\t3.1.10\thttps://registry.npmjs.org/micromatch/-/micromatch-3.1.10.tgz\t1j4m1y8x2sib8i5rfilml7yzpgs5njsg2nxzxwlb63997qlpb7p5\n"
    "minimatch\t3.0.4\thttps://registry.npmjs.org/minimatch/-/minimatch-3.0.4.tgz\t0wgammjc9myx0k0k3n9r9cjnv0r1j33cwqiy2fxx7w5nkgbj8sj2\n"
    "minimist-options\t3.0.2\thttps://registry.npmjs.org/minimist-options/-/minimist-options-3.0.2.tgz\t1g2sw1gpgh2zw02n856x38crvh8zg9ba76p8k1v5s7yp40933bw1\n"
    "minimist\t1.2.0\thttps://registry.npmjs.org/minimist/-/minimist-1.2.0.tgz\t0w7jll4vlqphxgk9qjbdjh3ni18lkrlfaqgsm7p14xl3f7ghn3gc\n"
    "mixin-deep\t1.3.2\thttps://registry.npmjs.org/mixin-deep/-/mixin-deep-1.3.2.tgz\t0kdw3h2r5cpfazjdfjzh9yac7c2gb1vrl3nxm0bhl7pb3yh276iq\n"
    "ms\t2.0.0\thttps://registry.npmjs.org/ms/-/ms-2.0.0.tgz\t1jrysw9zx14av3jdvc3kywc3xkjqxh748g4s6p1iy634i2mm489n\n"
    "nanomatch\t1.2.13\thttps://registry.npmjs.org/nanomatch/-/nanomatch-1.2.13.tgz\t1f4fxk7azvglyi6gfbkxmh91pd3n6i7av03y9bpizfn37xjf7g0z\n"
    "normalize-package-data\t2.5.0\thttps://registry.npmjs.org/normalize-package-data/-/normalize-package-data-2.5.0.tgz\t0yqy8wn6iz66nw5yi56xly07vg50j3wrmdxq9alsn8r2dz2mk6zc\n"
    "npm-run-path\t2.0.2\thttps://registry.npmjs.org/npm-run-path/-/npm-run-path-2.0.2.tgz\t1xz1f33ps8aqjjkvry886zb5nf4aznbx6axwn5nq76d0ica5cvb5\n"
    "object-copy\t0.1.0\thttps://registry.npmjs.org/object-copy/-/object-copy-0.1.0.tgz\t1b59pq32z0kdzhjkwphyk5h0m59gcc4qvmkvq7zb49yla00w5f0w\n"
    "object-visit\t1.0.1\thttps://registry.npmjs.org/object-visit/-/object-visit-1.0.1.tgz\t05qpsh7jyq40dk2mqm85hbcaapb4g4hyjcb4z6b2kcziqfiynpsl\n"
    "object.pick\t1.3.0\thttps://registry.npmjs.org/object.pick/-/object.pick-1.3.0.tgz\t02zfyg9vkizb5vanjy3d976cnbjnx4qrcjrd92z2ylyl4ih24040\n"
    "once\t1.4.0\thttps://registry.npmjs.org/once/-/once-1.4.0.tgz\t1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg\n"
    "p-finally\t1.0.0\thttps://registry.npmjs.org/p-finally/-/p-finally-1.0.0.tgz\t0hc8zfqhw1qnrbm62dxqb7a019r1vbsg2hx2hhm58c0kkvh89zgg\n"
    "p-limit\t1.3.0\thttps://registry.npmjs.org/p-limit/-/p-limit-1.3.0.tgz\t0l611k2j249zka517bgvylhzypfxz28fd1zqb3ps1iffk6zcpzf2\n"
    "p-limit\t2.2.1\thttps://registry.npmjs.org/p-limit/-/p-limit-2.2.1.tgz\t0qgr37q1ivp53rbdam3by5x8rbh1bvghnvzys6klg47yy2jjm50d\n"
    "p-locate\t2.0.0\thttps://registry.npmjs.org/p-locate/-/p-locate-2.0.0.tgz\t0ipv5a7kmwxbkn75bldn4lyah3269arpaixi9rdvy04qk97lpiq7\n"
    "p-locate\t3.0.0\thttps://registry.npmjs.org/p-locate/-/p-locate-3.0.0.tgz\t1fbvw7ka1lgrhr7kynsjv7iqw1sdqqrh088py2r4kyjhbl8xzq70\n"
    "p-try\t1.0.0\thttps://registry.npmjs.org/p-try/-/p-try-1.0.0.tgz\t1pjl0b25kqxzavp62l8jha7vk1zch98lkv9zrb1m4yx7q6ld9zlr\n"
    "p-try\t2.2.0\thttps://registry.npmjs.org/p-try/-/p-try-2.2.0.tgz\t141pf5z1f3xmm5c0fdrfddsf7xfigjxfl103zh59bpwrk2wb5453\n"
    "package-json\t4.0.1\thttps://registry.npmjs.org/package-json/-/package-json-4.0.1.tgz\t1zidcs3q94dlbva9y7wb7khkdb4xbjar49zycgxa2v6lb7kydaj1\n"
    "parse-json\t4.0.0\thttps://registry.npmjs.org/parse-json/-/parse-json-4.0.0.tgz\t03g1c0panv88rzqvb20qifcjxb2wa9b27654lgk1xqwqz1g25qbq\n"
    "pascalcase\t0.1.1\thttps://registry.npmjs.org/pascalcase/-/pascalcase-0.1.1.tgz\t0hd2yjrsfhw3183dxzs5045xnas07in2ww5sl0m5jx035zcrqv2m\n"
    "path-dirname\t1.0.2\thttps://registry.npmjs.org/path-dirname/-/path-dirname-1.0.2.tgz\t1g0kbsakjgvh0n070j3wm7i0yq4m6mlyq8mrlxcpin959p93nkyr\n"
    "path-exists\t3.0.0\thttps://registry.npmjs.org/path-exists/-/path-exists-3.0.0.tgz\t0b9j0s6mvbf7js1fsga1jx4k6c4k17yn9c1jlaiziqkmvi98gxyp\n"
    "path-is-absolute\t1.0.1\thttps://registry.npmjs.org/path-is-absolute/-/path-is-absolute-1.0.1.tgz\t0p7p04xxd8q495qhxmxydyjgzcf762dp1hp2wha2b52n3agp0vbf\n"
    "path-is-inside\t1.0.2\thttps://registry.npmjs.org/path-is-inside/-/path-is-inside-1.0.2.tgz\t17adl8ap5kvzaa1j27ciz5475g8f5cxfz8f900x6g28wra3kxvw8\n"
    "path-key\t2.0.1\thttps://registry.npmjs.org/path-key/-/path-key-2.0.1.tgz\t1w2fn5cgssfvg4wfgkf9mqz4slsv45aq6f8cgszvb4h78dm9hwgf\n"
    "path-parse\t1.0.6\thttps://registry.npmjs.org/path-parse/-/path-parse-1.0.6.tgz\t07x1wv7r4yky2hgcxl465a39a48hf5746840g9xkzggl3gb35ad4\n"
    "path-type\t3.0.0\thttps://registry.npmjs.org/path-type/-/path-type-3.0.0.tgz\t05jqjp1g4jxlyb62gmqdbcfhbana5nzb332ppjv36rh896avfq7y\n"
    "pify\t3.0.0\thttps://registry.npmjs.org/pify/-/pify-3.0.0.tgz\t0g04k40h8kzpjsw4mznd9a6y74k8zp59lc9wp9fydf3wjgwx272r\n"
    "pify\t4.0.1\thttps://registry.npmjs.org/pify/-/pify-4.0.1.tgz\t0jvbj1w7dn2kz3v3i1jsziyhcgpnsp497fq2a6z1kf34aq1mszwa\n"
    "plur\t2.1.2\thttps://registry.npmjs.org/plur/-/plur-2.1.2.tgz\t1amcxb54nv40g222bkc0f42lns6gzz22i8r4a3q7p2fgiiz6vhvc\n"
    "posix-character-classes\t0.1.1\thttps://registry.npmjs.org/posix-character-classes/-/posix-character-classes-0.1.1.tgz\t08c07ib7iaj34d1mnjhll0bq0yh3kb98q4mf334js2l4166y9rcr\n"
    "prepend-http\t1.0.4\thttps://registry.npmjs.org/prepend-http/-/prepend-http-1.0.4.tgz\t1lx9bq1mi0fn2cqnyqq62yz2sh88fs45h0cssbv9w1mp5kqiizhq\n"
    "pseudomap\t1.0.2\thttps://registry.npmjs.org/pseudomap/-/pseudomap-1.0.2.tgz\t13jv1dwki6m9w32bl2q44nqwf4xfqg91v7gc28a1dc69hws5ds87\n"
    "quick-lru\t1.1.0\thttps://registry.npmjs.org/quick-lru/-/quick-lru-1.1.0.tgz\t06cl3yjy1rp8s6ddhj5g1mb4w67x10ha8a76hdb3gsz4m1za8x8n\n"
    "rc\t1.2.8\thttps://registry.npmjs.org/rc/-/rc-1.2.8.tgz\t0fz9r8aphj84cvxv8k0m7g008gffz561r6ryvljb8gi0hpjgm983\n"
    "read-pkg-up\t3.0.0\thttps://registry.npmjs.org/read-pkg-up/-/read-pkg-up-3.0.0.tgz\t0drvlg293fz9cy28k5ng6y49ya6p8cfy8bq9ww416dziawcql56x\n"
    "read-pkg-up\t4.0.0\thttps://registry.npmjs.org/read-pkg-up/-/read-pkg-up-4.0.0.tgz\t1f9sbqb1m97gjnh0bfnzsyz066rfg4r7przb8p039d3r1j83w60j\n"
    "read-pkg\t3.0.0\thttps://registry.npmjs.org/read-pkg/-/read-pkg-3.0.0.tgz\t1qw5wa6lqn3cn6nscvwqj6vz8q8y2sm173hjp32gacpgz074gvwq\n"
    "redent\t2.0.0\thttps://registry.npmjs.org/redent/-/redent-2.0.0.tgz\t0a626gchxzavn1gmrl1hi4vb0x2ql3x829z1d1phabq45bachhnf\n"
    "regex-not\t1.0.2\thttps://registry.npmjs.org/regex-not/-/regex-not-1.0.2.tgz\t0xpjprkrk0c9fn6yhqay3bm8vw44k197smcfby89g3sfjsxlhi7s\n"
    "registry-auth-token\t3.4.0\thttps://registry.npmjs.org/registry-auth-token/-/registry-auth-token-3.4.0.tgz\t0cdkgcwykrybld0sy1lw3j1blkmna17cr3njx46bczw3v5l538zk\n"
    "registry-url\t3.1.0\thttps://registry.npmjs.org/registry-url/-/registry-url-3.1.0.tgz\t16haq71cc8fzfcq3g1b382djhxqdkqi9sb62mlpg15fmvrll7nkf\n"
    "repeat-element\t1.1.3\thttps://registry.npmjs.org/repeat-element/-/repeat-element-1.1.3.tgz\t1p71vsqclms9dxadcpnaajh8jkp3acxlkv6xic7f9x98dpdss8g6\n"
    "repeat-string\t1.6.1\thttps://registry.npmjs.org/repeat-string/-/repeat-string-1.6.1.tgz\t1zmlk22rp97i5yfxqlb9hix87zlznngd60pm8qwhcg6bssacpq8b\n"
    "resolve-url\t0.2.1\thttps://registry.npmjs.org/resolve-url/-/resolve-url-0.2.1.tgz\t090qal7agjs8d6x98jrf0wzgx5j85ksbkb3c85f14wv3idbwpsc8\n"
    "resolve\t1.14.1\thttps://registry.npmjs.org/resolve/-/resolve-1.14.1.tgz\t1xmam5qq3siyn6kjz33kdmmxp61lpl262yjpqb14znzc4q4ky792\n"
    "ret\t0.1.15\thttps://registry.npmjs.org/ret/-/ret-0.1.15.tgz\t1zk9xw3jzs7di9b31sxg3fi0mljac8w09k0q6m6y311i1fsn4x2a\n"
    "safe-buffer\t5.2.0\thttps://registry.npmjs.org/safe-buffer/-/safe-buffer-5.2.0.tgz\t1avkj16bydzzd33h8bjk0n59pj1ljxm5y1wvrh10wgsph760ykc1\n"
    "safe-regex\t1.1.0\thttps://registry.npmjs.org/safe-regex/-/safe-regex-1.1.0.tgz\t1lkcz58mjp3nfdiydh4iynpcfgxhf5mr339swzi5k05sikx8j4k2\n"
    "semver-diff\t2.1.0\thttps://registry.npmjs.org/semver-diff/-/semver-diff-2.1.0.tgz\t1sm1r11928539nj7nhwr4bydw0m5xwhs7ksyycrzxf0lcw6xvcpf\n"
    "semver\t5.7.1\thttps://registry.npmjs.org/semver/-/semver-5.7.1.tgz\t0vdmbm9s15r8m8n65qs9fhccn5a6v1ln8crlx312iz17m8rgpwpy\n"
    "set-value\t2.0.1\thttps://registry.npmjs.org/set-value/-/set-value-2.0.1.tgz\t0qbp2ndx2qmmn6i7y92lk8jaj79cv36gpv9lq29lgw52wr6jbrl0\n"
    "shebang-command\t1.2.0\thttps://registry.npmjs.org/shebang-command/-/shebang-command-1.2.0.tgz\t1xz1gpsia9137vsm4zx3jda6wl72641djg5nk5g8b9vzssp88rg5\n"
    "shebang-regex\t1.0.0\thttps://registry.npmjs.org/shebang-regex/-/shebang-regex-1.0.0.tgz\t0wf6hlgf5b2mn2zydi5nn23cpgpjkdpi6q9xaqdwa8b6ir714vv7\n"
    "signal-exit\t3.0.2\thttps://registry.npmjs.org/signal-exit/-/signal-exit-3.0.2.tgz\t1n6jbf6dq3ymdgc9k8bwfcbbpfyh4p0477aj4xf8x7yva380x46q\n"
    "slash\t2.0.0\thttps://registry.npmjs.org/slash/-/slash-2.0.0.tgz\t1qnsq29m6qyz15c214bw48m90hlbigs9rwfkpr48s7g06r9y4gpl\n"
    "snapdragon-node\t2.1.1\thttps://registry.npmjs.org/snapdragon-node/-/snapdragon-node-2.1.1.tgz\t0idm24bf2jvwgqi8fx1fkn1w78ylqnpm137s2m0g0ni43y19i97j\n"
    "snapdragon-util\t3.0.1\thttps://registry.npmjs.org/snapdragon-util/-/snapdragon-util-3.0.1.tgz\t0c4fcrilagmpsrhh4mjfj7ah0vdxwkm9a4h5658bj8m7machxm2f\n"
    "snapdragon\t0.8.2\thttps://registry.npmjs.org/snapdragon/-/snapdragon-0.8.2.tgz\t1anpibb0ajgw2yv400aq30bvvpcyi3yzyrp7fac2ia6r7ysxcgvq\n"
    "source-map-resolve\t0.5.3\thttps://registry.npmjs.org/source-map-resolve/-/source-map-resolve-0.5.3.tgz\t1a9ykfyqnzxmna8i3f20g9pqcjzwx1f3wqwaa0bn6jwgmvwcvdj4\n"
    "source-map-url\t0.4.0\thttps://registry.npmjs.org/source-map-url/-/source-map-url-0.4.0.tgz\t04ph8f65achmyf62g889xsvqbgq5qykzpy91rabjkpcma72zc924\n"
    "source-map\t0.5.7\thttps://registry.npmjs.org/source-map/-/source-map-0.5.7.tgz\t0rvb24j4kfib26w3cjyl6yan2dxvw1iy7d0wl404y5ckqjdjipp1\n"
    "spdx-correct\t3.1.0\thttps://registry.npmjs.org/spdx-correct/-/spdx-correct-3.1.0.tgz\t0kqn8vxnb7s2n1p395cxpg5idyx5acqgw7ihyrn0gghnfhq9jifi\n"
    "spdx-exceptions\t2.2.0\thttps://registry.npmjs.org/spdx-exceptions/-/spdx-exceptions-2.2.0.tgz\t1aybgrscfb8v8n6g539k2d6ff4v8zd34qig5byj803ds5md8d5xk\n"
    "spdx-expression-parse\t3.0.0\thttps://registry.npmjs.org/spdx-expression-parse/-/spdx-expression-parse-3.0.0.tgz\t057j9czqcm7lngldvmk0bgbivpl9x2z0iqma6z5g2zc7kk53136x\n"
    "spdx-license-ids\t3.0.5\thttps://registry.npmjs.org/spdx-license-ids/-/spdx-license-ids-3.0.5.tgz\t1bjd1d65gic7ndbrpp4qvd9620pg901j6pvfs8j40g3h15fvaahf\n"
    "split-string\t3.1.0\thttps://registry.npmjs.org/split-string/-/split-string-3.1.0.tgz\t1bx5n7bga42bd5d804w7y06wx96qk524gylxl4xi3i8nb8ch86na\n"
    "static-extend\t0.1.2\thttps://registry.npmjs.org/static-extend/-/static-extend-0.1.2.tgz\t1hwg7diq3kg6q7d2ymj423562yx6nfdqlym538s6ca02zxjgi7nl\n"
    "string-width\t2.1.1\thttps://registry.npmjs.org/string-width/-/string-width-2.1.1.tgz\t0b3rb6pbkyg411hvnzb5v5w2vckasgxvslwwijh0p410x46dqz12\n"
    "strip-ansi\t4.0.0\thttps://registry.npmjs.org/strip-ansi/-/strip-ansi-4.0.0.tgz\t0b90ys7pxxbavph56rhfmlymla8f8vaq7fy2pa91dq4r6r3sic5a\n"
    "strip-bom\t3.0.0\thttps://registry.npmjs.org/strip-bom/-/strip-bom-3.0.0.tgz\t1qiy06v3aqna30vc9cqzssvfjb13h29w06b9xdksiyppl48lq2a8\n"
    "strip-eof\t1.0.0\thttps://registry.npmjs.org/strip-eof/-/strip-eof-1.0.0.tgz\t0pcw45dhan54hnd8pkc9jkm5dz2nqhpqblfknvnl8b94445svgpj\n"
    "strip-indent\t2.0.0\thttps://registry.npmjs.org/strip-indent/-/strip-indent-2.0.0.tgz\t12lcw0gs0bh34kkzsy5wzb8d9b54n89v80z1bn27j1hm3z0jicmq\n"
    "strip-json-comments\t2.0.1\thttps://registry.npmjs.org/strip-json-comments/-/strip-json-comments-2.0.1.tgz\t16aq89q4gbs10fgy3a5n5miqphvs1sy44ckk4mf2dxqvmzmmzr6v\n"
    "supports-color\t5.5.0\thttps://registry.npmjs.org/supports-color/-/supports-color-5.5.0.tgz\t1ap0lk4n0m3948cnkfmyz71pizqlzjdfrhs0f954pksg4jnk52h5\n"
    "term-size\t1.2.0\thttps://registry.npmjs.org/term-size/-/term-size-1.2.0.tgz\t0kwdyn1r7sqy06xlvb4bankzixckddklq93glmzd1vfvqx9jqmcq\n"
    "timed-out\t4.0.1\thttps://registry.npmjs.org/timed-out/-/timed-out-4.0.1.tgz\t0hcqvmkn1vkklkj6pbc11nmymn0ysgd4kgbk18dxi1pifdlz65n9\n"
    "to-object-path\t0.3.0\thttps://registry.npmjs.org/to-object-path/-/to-object-path-0.3.0.tgz\t01n40v8xlqm635rp6cyz0jpw6295wm9fkr6m85nqcf457rfbqc68\n"
    "to-regex-range\t2.1.1\thttps://registry.npmjs.org/to-regex-range/-/to-regex-range-2.1.1.tgz\t0rw8mjvncwxhyg5m7mzwqg16ddpyq5qzdwds0v0jnskqhklh14bq\n"
    "to-regex\t3.0.2\thttps://registry.npmjs.org/to-regex/-/to-regex-3.0.2.tgz\t039l28qygjrjy10jz9cm3j066nw5fkfimzkp5ipq47w2pl2ii0w6\n"
    "trim-newlines\t2.0.0\thttps://registry.npmjs.org/trim-newlines/-/trim-newlines-2.0.0.tgz\t1mvxrfzrvys5jygbrxb571ayrcwwgsivlmfc3r0ngjlnjxqrnbf8\n"
    "tsd\t0.11.0\thttps://registry.npmjs.org/tsd/-/tsd-0.11.0.tgz\t1fh5cln4yn7b0mwwjjs3zr1p7wpfb1giw5zibfqmiybi58f1i9bz\n"
    "typescript\t3.7.4\thttps://registry.npmjs.org/typescript/-/typescript-3.7.4.tgz\t1bfs6n7xj0gnsib81ama7py3vml62ydr0ymmaq4fsscdzhz59wg4\n"
    "union-value\t1.0.1\thttps://registry.npmjs.org/union-value/-/union-value-1.0.1.tgz\t00rjw4hvxnj5vrji9qzbxn6y9rx6av1q3nv8ilyxpska3q0zpj75\n"
    "unique-string\t1.0.0\thttps://registry.npmjs.org/unique-string/-/unique-string-1.0.0.tgz\t02l5hp1j5ijsv4pagnsf3jjw81a39vj4138b56dz7vlyvmbpp82l\n"
    "unset-value\t1.0.0\thttps://registry.npmjs.org/unset-value/-/unset-value-1.0.0.tgz\t11jj8ggkz8c54sf0zyqwlnwv89i5gj572ywbry7ispy6lqa84qsk\n"
    "unzip-response\t2.0.1\thttps://registry.npmjs.org/unzip-response/-/unzip-response-2.0.1.tgz\t1c3fq6kpxf8qhpkyl8wkc2vz3qy320rqdli77v0hfawk54aa21d1\n"
    "update-notifier\t2.5.0\thttps://registry.npmjs.org/update-notifier/-/update-notifier-2.5.0.tgz\t0lfsq583ks1g1h279j3lxh7k5zmlk59y5kg38bdqqilhkqhy81np\n"
    "urix\t0.1.0\thttps://registry.npmjs.org/urix/-/urix-0.1.0.tgz\t19qmq8cra96cf7ji8d4ljfcgnazzrvw4lcxlf91jk1816ndx1pbm\n"
    "url-parse-lax\t1.0.0\thttps://registry.npmjs.org/url-parse-lax/-/url-parse-lax-1.0.0.tgz\t1nsxc07sjg8b70clwn0d40iz5mi7a55icymx9ng2j1avcckmsv50\n"
    "use\t3.1.1\thttps://registry.npmjs.org/use/-/use-3.1.1.tgz\t1nqrazqb927s0nma2qi2c3aambpy34krz8cgl6610n456zg5vjin\n"
    "validate-npm-package-license\t3.0.4\thttps://registry.npmjs.org/validate-npm-package-license/-/validate-npm-package-license-3.0.4.tgz\t137xfxkycbb0cp1gxxmc1mff6jrihkzzhx9avza338a19nryyrh1\n"
    "which\t1.3.1\thttps://registry.npmjs.org/which/-/which-1.3.1.tgz\t077d08k2zz1zhn5nc09m4vkiz2hjfk2lp02a3kphhianj3b26rcn\n"
    "widest-line\t2.0.1\thttps://registry.npmjs.org/widest-line/-/widest-line-2.0.1.tgz\t0qywlyhsqrfa9a6ii38x4qv6mpsgglmnzq4xfpasvjraqkiqljqh\n"
    "wrappy\t1.0.2\thttps://registry.npmjs.org/wrappy/-/wrappy-1.0.2.tgz\t1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg\n"
    "write-file-atomic\t2.4.3\thttps://registry.npmjs.org/write-file-atomic/-/write-file-atomic-2.4.3.tgz\t0zbyl63kwdczr9liivfl5q7r8dsjx2g5nq0c7k7iyga5lbn8q57n\n"
    "xdg-basedir\t3.0.0\thttps://registry.npmjs.org/xdg-basedir/-/xdg-basedir-3.0.0.tgz\t1dvdb9gqwfqs1zb6fwf1fqqqvgds60137cnaiz4ijwlb4s2v9vwc\n"
    "yallist\t2.1.2\thttps://registry.npmjs.org/yallist/-/yallist-2.1.2.tgz\t1cmhmkw7cf9h92pnv4pzm488zkdnrrc8xhj69cqifpjjsf211cy7\n"
    "yargs-parser\t10.1.0\thttps://registry.npmjs.org/yargs-parser/-/yargs-parser-10.1.0.tgz\t0cyrszwzxb6h96dxdb6b47k5j6a7aw8mqx3kv0bgbi0mcy6sixdz\n"))

;; These full upstream license texts fill omissions in the registry archives.
;; Preserve their original metadata, README attribution, and copyright notices.
;; Other packages keep their archived licenses or full terms in their README.
;; The SPDX identifiers data declares CC0; no replacement grant is supplied.
(define %meta-typing-license-supplements
  (list
    (cons "@nodelib/fs.stat@1.1.3"
          (origin
            (method url-fetch)
            (uri "https://raw.githubusercontent.com/nodelib/nodelib/0c16a4dda04dda66a7bbd0c9c83d84c48b8baa89/LICENSE")
            (file-name "meta-typing--nodelib-fs.stat-1.1.3-LICENSE.txt")
            (sha256
             (base32 "1pp2gsbp7chli4vs5d0pzhm4q2g27zy28p8sj21nvm21pxhd2qwk"))))
    (cons "is-npm@1.0.0"
          (origin
            (method url-fetch)
            (uri "https://raw.githubusercontent.com/sindresorhus/is-npm/a4643be4051a02f31227ebb70ad273f37e2fc2cc/license")
            (file-name "meta-typing-is-npm-1.0.0-LICENSE.txt")
            (sha256
             (base32 "1lw92z3f12anqr4q2syrq5dzblcbisj6z1aayrcbjjkb4n42v4sw"))))
    (cons "spdx-exceptions@2.2.0"
          (origin
            (method url-fetch)
            (uri "https://raw.githubusercontent.com/spdx/license-list-data/31ba1a50e5397e00a304dbadc76531740e89ee48/text/CC-BY-3.0.txt")
            (file-name "meta-typing-spdx-exceptions-2.2.0-LICENSE.txt")
            (sha256
             (base32 "0xlfif2cp7s4pbsl4d6mvaqv5g59m3jwkfk8yl4bf0278yf9xg76"))))
    ))

(define (record->source record)
  (let* ((fields (string-tokenize record))
         (name (list-ref fields 0))
         (version (list-ref fields 1))
         (key (string-append name "@" version))
         (supplement (assoc-ref %meta-typing-license-supplements key))
         (prune-foreign-binaries? (string=? name "term-size")))
    (cons key
          (origin
            (method url-fetch)
            (uri (list-ref fields 2))
            (file-name
             (string-append "meta-typing-"
                            (string-map (lambda (c)
                                          (if (or (char=? c #\/)
                                                  (char=? c #\@))
                                              #\- c))
                                        name)
                            "-" version ".tgz"))
            (sha256 (base32 (list-ref fields 3)))
            (modules '((guix build utils)))
            (snippet
             (and (or supplement prune-foreign-binaries?)
                  #~(begin
                      ;; term-size's Linux path uses terminal descriptors,
                      ;; resize/tput, or its own documented default dimensions.
                      ;; Its unused macOS/Windows executables have no source in
                      ;; the archive; retain the JS and MIT notice, not blobs.
                      (when #$prune-foreign-binaries?
                        (delete-file-recursively "vendor/macos")
                        (delete-file-recursively "vendor/windows"))
                      #$@(if supplement
                             (list #~(copy-file #$supplement
                                                "GUIX-LICENSE.txt"))
                             '()))))))))

(define %meta-typing-npm-sources
  (map record->source
       (remove string-null?
               (string-split %meta-typing-npm-source-records #\newline))))

(define meta-typing-typescript-source
  (assoc-ref %meta-typing-npm-sources "typescript@3.7.4"))

;; Deterministic breadth-first Node resolution layout, generated from the
;; pinned Yarn selectors above, not from current registry semver resolution.
;; A dependency is hoisted only if the nearest same-name ancestor is either
;; absent or exactly the required version; conflicts remain package-local.
;; Each pair names an extraction destination and its exact source key.
(define %meta-typing-npm-layout
  '(
    ("node_modules/tsd" . "tsd@0.11.0")
    ("node_modules/typescript" . "typescript@3.7.4")
    ("node_modules/eslint-formatter-pretty" . "eslint-formatter-pretty@1.3.0")
    ("node_modules/globby" . "globby@9.2.0")
    ("node_modules/meow" . "meow@5.0.0")
    ("node_modules/path-exists" . "path-exists@3.0.0")
    ("node_modules/read-pkg-up" . "read-pkg-up@4.0.0")
    ("node_modules/update-notifier" . "update-notifier@2.5.0")
    ("node_modules/ansi-escapes" . "ansi-escapes@2.0.0")
    ("node_modules/chalk" . "chalk@2.4.2")
    ("node_modules/log-symbols" . "log-symbols@2.2.0")
    ("node_modules/plur" . "plur@2.1.2")
    ("node_modules/string-width" . "string-width@2.1.1")
    ("node_modules/@types/glob" . "@types/glob@7.1.1")
    ("node_modules/array-union" . "array-union@1.0.2")
    ("node_modules/dir-glob" . "dir-glob@2.2.2")
    ("node_modules/fast-glob" . "fast-glob@2.2.7")
    ("node_modules/glob" . "glob@7.1.6")
    ("node_modules/ignore" . "ignore@4.0.6")
    ("node_modules/pify" . "pify@4.0.1")
    ("node_modules/slash" . "slash@2.0.0")
    ("node_modules/camelcase-keys" . "camelcase-keys@4.2.0")
    ("node_modules/decamelize-keys" . "decamelize-keys@1.1.0")
    ("node_modules/loud-rejection" . "loud-rejection@1.6.0")
    ("node_modules/minimist-options" . "minimist-options@3.0.2")
    ("node_modules/normalize-package-data" . "normalize-package-data@2.5.0")
    ("node_modules/meow/node_modules/read-pkg-up" . "read-pkg-up@3.0.0")
    ("node_modules/redent" . "redent@2.0.0")
    ("node_modules/trim-newlines" . "trim-newlines@2.0.0")
    ("node_modules/yargs-parser" . "yargs-parser@10.1.0")
    ("node_modules/find-up" . "find-up@3.0.0")
    ("node_modules/read-pkg" . "read-pkg@3.0.0")
    ("node_modules/boxen" . "boxen@1.3.0")
    ("node_modules/configstore" . "configstore@3.1.2")
    ("node_modules/import-lazy" . "import-lazy@2.1.0")
    ("node_modules/is-ci" . "is-ci@1.2.1")
    ("node_modules/is-installed-globally" . "is-installed-globally@0.1.0")
    ("node_modules/is-npm" . "is-npm@1.0.0")
    ("node_modules/latest-version" . "latest-version@3.1.0")
    ("node_modules/semver-diff" . "semver-diff@2.1.0")
    ("node_modules/xdg-basedir" . "xdg-basedir@3.0.0")
    ("node_modules/ansi-styles" . "ansi-styles@3.2.1")
    ("node_modules/escape-string-regexp" . "escape-string-regexp@1.0.5")
    ("node_modules/supports-color" . "supports-color@5.5.0")
    ("node_modules/irregular-plurals" . "irregular-plurals@1.4.0")
    ("node_modules/is-fullwidth-code-point" . "is-fullwidth-code-point@2.0.0")
    ("node_modules/strip-ansi" . "strip-ansi@4.0.0")
    ("node_modules/@types/events" . "@types/events@3.0.0")
    ("node_modules/@types/minimatch" . "@types/minimatch@3.0.3")
    ("node_modules/@types/node" . "@types/node@13.1.2")
    ("node_modules/array-uniq" . "array-uniq@1.0.3")
    ("node_modules/path-type" . "path-type@3.0.0")
    ("node_modules/@mrmlnc/readdir-enhanced" . "@mrmlnc/readdir-enhanced@2.2.1")
    ("node_modules/@nodelib/fs.stat" . "@nodelib/fs.stat@1.1.3")
    ("node_modules/glob-parent" . "glob-parent@3.1.0")
    ("node_modules/is-glob" . "is-glob@4.0.1")
    ("node_modules/merge2" . "merge2@1.3.0")
    ("node_modules/micromatch" . "micromatch@3.1.10")
    ("node_modules/fs.realpath" . "fs.realpath@1.0.0")
    ("node_modules/inflight" . "inflight@1.0.6")
    ("node_modules/inherits" . "inherits@2.0.4")
    ("node_modules/minimatch" . "minimatch@3.0.4")
    ("node_modules/once" . "once@1.4.0")
    ("node_modules/path-is-absolute" . "path-is-absolute@1.0.1")
    ("node_modules/camelcase" . "camelcase@4.1.0")
    ("node_modules/map-obj" . "map-obj@2.0.0")
    ("node_modules/quick-lru" . "quick-lru@1.1.0")
    ("node_modules/decamelize" . "decamelize@1.2.0")
    ("node_modules/decamelize-keys/node_modules/map-obj" . "map-obj@1.0.1")
    ("node_modules/currently-unhandled" . "currently-unhandled@0.4.1")
    ("node_modules/signal-exit" . "signal-exit@3.0.2")
    ("node_modules/arrify" . "arrify@1.0.1")
    ("node_modules/is-plain-obj" . "is-plain-obj@1.1.0")
    ("node_modules/hosted-git-info" . "hosted-git-info@2.8.5")
    ("node_modules/resolve" . "resolve@1.14.1")
    ("node_modules/semver" . "semver@5.7.1")
    ("node_modules/validate-npm-package-license" . "validate-npm-package-license@3.0.4")
    ("node_modules/meow/node_modules/read-pkg-up/node_modules/find-up" . "find-up@2.1.0")
    ("node_modules/indent-string" . "indent-string@3.2.0")
    ("node_modules/strip-indent" . "strip-indent@2.0.0")
    ("node_modules/locate-path" . "locate-path@3.0.0")
    ("node_modules/load-json-file" . "load-json-file@4.0.0")
    ("node_modules/ansi-align" . "ansi-align@2.0.0")
    ("node_modules/cli-boxes" . "cli-boxes@1.0.0")
    ("node_modules/term-size" . "term-size@1.2.0")
    ("node_modules/widest-line" . "widest-line@2.0.1")
    ("node_modules/dot-prop" . "dot-prop@4.2.0")
    ("node_modules/graceful-fs" . "graceful-fs@4.2.3")
    ("node_modules/make-dir" . "make-dir@1.3.0")
    ("node_modules/unique-string" . "unique-string@1.0.0")
    ("node_modules/write-file-atomic" . "write-file-atomic@2.4.3")
    ("node_modules/ci-info" . "ci-info@1.6.0")
    ("node_modules/global-dirs" . "global-dirs@0.1.1")
    ("node_modules/is-path-inside" . "is-path-inside@1.0.1")
    ("node_modules/package-json" . "package-json@4.0.1")
    ("node_modules/color-convert" . "color-convert@1.9.3")
    ("node_modules/has-flag" . "has-flag@3.0.0")
    ("node_modules/ansi-regex" . "ansi-regex@3.0.0")
    ("node_modules/path-type/node_modules/pify" . "pify@3.0.0")
    ("node_modules/call-me-maybe" . "call-me-maybe@1.0.1")
    ("node_modules/glob-to-regexp" . "glob-to-regexp@0.3.0")
    ("node_modules/glob-parent/node_modules/is-glob" . "is-glob@3.1.0")
    ("node_modules/path-dirname" . "path-dirname@1.0.2")
    ("node_modules/is-extglob" . "is-extglob@2.1.1")
    ("node_modules/arr-diff" . "arr-diff@4.0.0")
    ("node_modules/array-unique" . "array-unique@0.3.2")
    ("node_modules/braces" . "braces@2.3.2")
    ("node_modules/define-property" . "define-property@2.0.2")
    ("node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/extglob" . "extglob@2.0.4")
    ("node_modules/fragment-cache" . "fragment-cache@0.2.1")
    ("node_modules/kind-of" . "kind-of@6.0.2")
    ("node_modules/nanomatch" . "nanomatch@1.2.13")
    ("node_modules/object.pick" . "object.pick@1.3.0")
    ("node_modules/regex-not" . "regex-not@1.0.2")
    ("node_modules/snapdragon" . "snapdragon@0.8.2")
    ("node_modules/to-regex" . "to-regex@3.0.2")
    ("node_modules/wrappy" . "wrappy@1.0.2")
    ("node_modules/brace-expansion" . "brace-expansion@1.1.11")
    ("node_modules/array-find-index" . "array-find-index@1.0.2")
    ("node_modules/path-parse" . "path-parse@1.0.6")
    ("node_modules/spdx-correct" . "spdx-correct@3.1.0")
    ("node_modules/spdx-expression-parse" . "spdx-expression-parse@3.0.0")
    ("node_modules/meow/node_modules/read-pkg-up/node_modules/find-up/node_modules/locate-path" . "locate-path@2.0.0")
    ("node_modules/p-locate" . "p-locate@3.0.0")
    ("node_modules/parse-json" . "parse-json@4.0.0")
    ("node_modules/load-json-file/node_modules/pify" . "pify@3.0.0")
    ("node_modules/strip-bom" . "strip-bom@3.0.0")
    ("node_modules/execa" . "execa@0.7.0")
    ("node_modules/is-obj" . "is-obj@1.0.1")
    ("node_modules/make-dir/node_modules/pify" . "pify@3.0.0")
    ("node_modules/crypto-random-string" . "crypto-random-string@1.0.0")
    ("node_modules/imurmurhash" . "imurmurhash@0.1.4")
    ("node_modules/ini" . "ini@1.3.5")
    ("node_modules/path-is-inside" . "path-is-inside@1.0.2")
    ("node_modules/got" . "got@6.7.1")
    ("node_modules/registry-auth-token" . "registry-auth-token@3.4.0")
    ("node_modules/registry-url" . "registry-url@3.1.0")
    ("node_modules/color-name" . "color-name@1.1.3")
    ("node_modules/arr-flatten" . "arr-flatten@1.1.0")
    ("node_modules/braces/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/fill-range" . "fill-range@4.0.0")
    ("node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/repeat-element" . "repeat-element@1.1.3")
    ("node_modules/snapdragon-node" . "snapdragon-node@2.1.1")
    ("node_modules/split-string" . "split-string@3.1.0")
    ("node_modules/is-descriptor" . "is-descriptor@1.0.2")
    ("node_modules/assign-symbols" . "assign-symbols@1.0.0")
    ("node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/extglob/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/expand-brackets" . "expand-brackets@2.1.4")
    ("node_modules/extglob/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/map-cache" . "map-cache@0.2.2")
    ("node_modules/is-windows" . "is-windows@1.0.2")
    ("node_modules/safe-regex" . "safe-regex@1.1.0")
    ("node_modules/base" . "base@0.11.2")
    ("node_modules/debug" . "debug@2.6.9")
    ("node_modules/snapdragon/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/snapdragon/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/source-map" . "source-map@0.5.7")
    ("node_modules/source-map-resolve" . "source-map-resolve@0.5.3")
    ("node_modules/use" . "use@3.1.1")
    ("node_modules/balanced-match" . "balanced-match@1.0.0")
    ("node_modules/concat-map" . "concat-map@0.0.1")
    ("node_modules/spdx-license-ids" . "spdx-license-ids@3.0.5")
    ("node_modules/spdx-exceptions" . "spdx-exceptions@2.2.0")
    ("node_modules/meow/node_modules/read-pkg-up/node_modules/find-up/node_modules/locate-path/node_modules/p-locate" . "p-locate@2.0.0")
    ("node_modules/p-limit" . "p-limit@2.2.1")
    ("node_modules/error-ex" . "error-ex@1.3.2")
    ("node_modules/json-parse-better-errors" . "json-parse-better-errors@1.0.2")
    ("node_modules/cross-spawn" . "cross-spawn@5.1.0")
    ("node_modules/get-stream" . "get-stream@3.0.0")
    ("node_modules/is-stream" . "is-stream@1.1.0")
    ("node_modules/npm-run-path" . "npm-run-path@2.0.2")
    ("node_modules/p-finally" . "p-finally@1.0.0")
    ("node_modules/strip-eof" . "strip-eof@1.0.0")
    ("node_modules/create-error-class" . "create-error-class@3.0.2")
    ("node_modules/duplexer3" . "duplexer3@0.1.4")
    ("node_modules/is-redirect" . "is-redirect@1.0.0")
    ("node_modules/is-retry-allowed" . "is-retry-allowed@1.2.0")
    ("node_modules/lowercase-keys" . "lowercase-keys@1.0.1")
    ("node_modules/safe-buffer" . "safe-buffer@5.2.0")
    ("node_modules/timed-out" . "timed-out@4.0.1")
    ("node_modules/unzip-response" . "unzip-response@2.0.1")
    ("node_modules/url-parse-lax" . "url-parse-lax@1.0.0")
    ("node_modules/rc" . "rc@1.2.8")
    ("node_modules/braces/node_modules/extend-shallow/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/fill-range/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/is-number" . "is-number@3.0.0")
    ("node_modules/repeat-string" . "repeat-string@1.6.1")
    ("node_modules/to-regex-range" . "to-regex-range@2.1.1")
    ("node_modules/snapdragon-node/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/snapdragon-util" . "snapdragon-util@3.0.1")
    ("node_modules/is-accessor-descriptor" . "is-accessor-descriptor@1.0.0")
    ("node_modules/is-data-descriptor" . "is-data-descriptor@1.0.0")
    ("node_modules/is-plain-object" . "is-plain-object@2.0.4")
    ("node_modules/expand-brackets/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/expand-brackets/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/posix-character-classes" . "posix-character-classes@0.1.1")
    ("node_modules/extglob/node_modules/extend-shallow/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/ret" . "ret@0.1.15")
    ("node_modules/cache-base" . "cache-base@1.0.1")
    ("node_modules/class-utils" . "class-utils@0.3.6")
    ("node_modules/component-emitter" . "component-emitter@1.3.0")
    ("node_modules/base/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/mixin-deep" . "mixin-deep@1.3.2")
    ("node_modules/pascalcase" . "pascalcase@0.1.1")
    ("node_modules/ms" . "ms@2.0.0")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/snapdragon/node_modules/extend-shallow/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/atob" . "atob@2.1.2")
    ("node_modules/decode-uri-component" . "decode-uri-component@0.2.0")
    ("node_modules/resolve-url" . "resolve-url@0.2.1")
    ("node_modules/source-map-url" . "source-map-url@0.4.0")
    ("node_modules/urix" . "urix@0.1.0")
    ("node_modules/meow/node_modules/read-pkg-up/node_modules/find-up/node_modules/locate-path/node_modules/p-locate/node_modules/p-limit" . "p-limit@1.3.0")
    ("node_modules/p-try" . "p-try@2.2.0")
    ("node_modules/is-arrayish" . "is-arrayish@0.2.1")
    ("node_modules/lru-cache" . "lru-cache@4.1.5")
    ("node_modules/shebang-command" . "shebang-command@1.2.0")
    ("node_modules/which" . "which@1.3.1")
    ("node_modules/path-key" . "path-key@2.0.1")
    ("node_modules/capture-stack-trace" . "capture-stack-trace@1.0.1")
    ("node_modules/prepend-http" . "prepend-http@1.0.4")
    ("node_modules/deep-extend" . "deep-extend@0.6.0")
    ("node_modules/minimist" . "minimist@1.2.0")
    ("node_modules/strip-json-comments" . "strip-json-comments@2.0.1")
    ("node_modules/fill-range/node_modules/extend-shallow/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/is-number/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/snapdragon-util/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/expand-brackets/node_modules/extend-shallow/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/collection-visit" . "collection-visit@1.0.0")
    ("node_modules/get-value" . "get-value@2.0.6")
    ("node_modules/has-value" . "has-value@1.0.0")
    ("node_modules/set-value" . "set-value@2.0.1")
    ("node_modules/to-object-path" . "to-object-path@0.3.0")
    ("node_modules/union-value" . "union-value@1.0.1")
    ("node_modules/unset-value" . "unset-value@1.0.0")
    ("node_modules/arr-union" . "arr-union@3.1.0")
    ("node_modules/class-utils/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/static-extend" . "static-extend@0.1.2")
    ("node_modules/for-in" . "for-in@1.0.2")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/meow/node_modules/read-pkg-up/node_modules/find-up/node_modules/locate-path/node_modules/p-locate/node_modules/p-limit/node_modules/p-try" . "p-try@1.0.0")
    ("node_modules/pseudomap" . "pseudomap@1.0.2")
    ("node_modules/yallist" . "yallist@2.1.2")
    ("node_modules/shebang-regex" . "shebang-regex@1.0.0")
    ("node_modules/isexe" . "isexe@2.0.0")
    ("node_modules/is-buffer" . "is-buffer@1.1.6")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/map-visit" . "map-visit@1.0.0")
    ("node_modules/object-visit" . "object-visit@1.0.1")
    ("node_modules/has-values" . "has-values@1.0.0")
    ("node_modules/set-value/node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/set-value/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/to-object-path/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/union-value/node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/unset-value/node_modules/has-value" . "has-value@0.3.1")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/static-extend/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/object-copy" . "object-copy@0.1.0")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/snapdragon/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/expand-brackets/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/has-values/node_modules/kind-of" . "kind-of@4.0.0")
    ("node_modules/unset-value/node_modules/has-value/node_modules/has-values" . "has-values@0.1.4")
    ("node_modules/unset-value/node_modules/has-value/node_modules/isobject" . "isobject@2.1.0")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/copy-descriptor" . "copy-descriptor@0.1.1")
    ("node_modules/object-copy/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/object-copy/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/isarray" . "isarray@1.0.0")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/class-utils/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/static-extend/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor/node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/object-copy/node_modules/define-property/node_modules/is-descriptor/node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@3.2.2")
    ))
