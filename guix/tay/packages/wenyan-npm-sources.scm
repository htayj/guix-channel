;;; Curated fixed registry sources for Wenyan 0.4.0.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages wenyan-npm-sources)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (%wenyan-npm-sources
            %wenyan-npm-paths
            %wenyan-npm-path-keys
            %wenyan-runtime-paths))

;; Selected from upstream's lockfileVersion 2 packages map, following each
;; dependency in its Node resolution context (including hoisted requires).
;; The roots are typescript, webpack, webpack-cli, ts-loader, raw-loader,
;; remove-strict-webpack-plugin, dts-bundle, @types/node, @types/webpack-env,
;; commander, consola, find-up, fs-extra, and sync-request.  Jest/lint/wiki
;; tooling is excluded; webpack-shell-plugin is unused by upstream configs.
;; These 416 archives cover 501 dependency locations.  The archive audit of
;; 2026-10-04 verified each lockfile SHA-1/SHA-512 integrity and calculated
;; the Guix SHA-256 below.  No ELF, PE, Mach-O, WASM, native Node modules,
;; or fonts occur in this closure.  Optional Darwin fsevents is not selected.
;; source-map 0.5.7 and 0.6.1 retain their BSD sources/licenses; neither has
;; the source-map 0.7 WASM backend.  Tests/coverage PNGs are pruned below.
;; Notices absent as standalone files are supplied from upstream READMEs,
;; exact upstream license texts, or explicitly identified metadata grants.
;; Original copyright notices, README files and package metadata remain.
;; TypeScript's CopyrightNotice.txt and ThirdPartyNoticeText.txt remain.

(define %wenyan-npm-source-records
  (string-append
    "@types/concat-stream\t1.6.0\thttps://registry.npmjs.org/@types/concat-stream/-/concat-stream-1.6.0.tgz\t1aqqlv87j15373rvaywdyq54pjfc0i1mxzr5qgap34vfz8jv5kvc\n"
    "@types/detect-indent\t0.1.30\thttps://registry.npmjs.org/@types/detect-indent/-/detect-indent-0.1.30.tgz\t116jxikhlqimpbq6jifl4bv6hxdhwr26ilmrcj3p50n79r0i10b2\n"
    "@types/form-data\t0.0.33\thttps://registry.npmjs.org/@types/form-data/-/form-data-0.0.33.tgz\t0wrn24pb7c6kx22ba8ss5f43d2mc0dk8zwwv4i9wshwr8k0a6b28\n"
    "@types/glob\t5.0.30\thttps://registry.npmjs.org/@types/glob/-/glob-5.0.30.tgz\t1ils24nc5cyc2m1aj1a3gq00dmrghfavwvfgc0pp9jj34c5m5zlh\n"
    "@types/json-schema\t7.0.7\thttps://registry.npmjs.org/@types/json-schema/-/json-schema-7.0.7.tgz\t1i566xl2p2admd46r00g4j1s9j9p73rsvc7cwmvp5z0rgb0a787i\n"
    "@types/minimatch\t3.0.4\thttps://registry.npmjs.org/@types/minimatch/-/minimatch-3.0.4.tgz\t0f8c3mdmcil19i25pijz56a4r8vmnzc6jik0bbr6h6r6bjrijiag\n"
    "@types/mkdirp\t0.3.29\thttps://registry.npmjs.org/@types/mkdirp/-/mkdirp-0.3.29.tgz\t1x0k7a9nlglahqnzninxili8r0cb2hs63mk9yv1kr8y2fvi04gbs\n"
    "@types/node\t10.17.60\thttps://registry.npmjs.org/@types/node/-/node-10.17.60.tgz\t1hqqv7fs73z0xjxqcp3351afd2nwx9akryz968m815mxiny84j3s\n"
    "@types/node\t15.12.2\thttps://registry.npmjs.org/@types/node/-/node-15.12.2.tgz\t0rpmlr8c0nhzzhcadpf09v10qc5sw6xaazi6szqdbqg67kqridc0\n"
    "@types/node\t8.0.0\thttps://registry.npmjs.org/@types/node/-/node-8.0.0.tgz\t07apcr0wng99sy25wsig1r9s8zd40g9xp99hf6h2vg8vzfrchfg8\n"
    "@types/node\t8.10.66\thttps://registry.npmjs.org/@types/node/-/node-8.10.66.tgz\t04k0wlgwwp0ryw95qphpg0767qhk2np1r4qaihmv3yh38c3w4flq\n"
    "@types/qs\t6.9.6\thttps://registry.npmjs.org/@types/qs/-/qs-6.9.6.tgz\t0z5pb6c29nr6sbww7fgcmbjk3cgxn6j46177fmz9zb78j37jm9dp\n"
    "@types/webpack-env\t1.16.0\thttps://registry.npmjs.org/@types/webpack-env/-/webpack-env-1.16.0.tgz\t0465jl559b3gpkk15drwxh2j961j2jk8rr7qjpfvgmx98wxbcx8y\n"
    "@webassemblyjs/ast\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/ast/-/ast-1.9.0.tgz\t0r46vq419bcbhm9kkxr3ack3l9kcwlbzp2k6f4nppwbnm07iknv0\n"
    "@webassemblyjs/floating-point-hex-parser\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/floating-point-hex-parser/-/floating-point-hex-parser-1.9.0.tgz\t092i3wv13lhacha6fhy7dwk2crmi6wiargbngliwqdn9g2p66sa0\n"
    "@webassemblyjs/helper-api-error\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-api-error/-/helper-api-error-1.9.0.tgz\t0fvdwmwrmj2vc19kyrb7lirh8kksd8lkhm6mqz0022gjz3a2d52y\n"
    "@webassemblyjs/helper-buffer\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-buffer/-/helper-buffer-1.9.0.tgz\t1cbgninlw7nx8wsvi4f264hjcf75prabsnj818mi449p1yahmppm\n"
    "@webassemblyjs/helper-code-frame\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-code-frame/-/helper-code-frame-1.9.0.tgz\t0kcd0ldwcv9qdvqrh1i8463mfb4bqp1n46hipkxmpnsh6vag80qp\n"
    "@webassemblyjs/helper-fsm\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-fsm/-/helper-fsm-1.9.0.tgz\t1w49jgha7iyfxwswjxa0f9mbz9bjrisxyxi94hh5w0pyl4jksbjy\n"
    "@webassemblyjs/helper-module-context\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-module-context/-/helper-module-context-1.9.0.tgz\t064n1p05v98q2gm1kpdajm4qcvrajcf1f2r6kwny9fnng1x84w5j\n"
    "@webassemblyjs/helper-wasm-bytecode\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-wasm-bytecode/-/helper-wasm-bytecode-1.9.0.tgz\t1fp5qax62ihqrhfd31d9jzm4cc0920dszv2sapfsrdxmbif4s68k\n"
    "@webassemblyjs/helper-wasm-section\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/helper-wasm-section/-/helper-wasm-section-1.9.0.tgz\t0va11v8lk5kgy70d3dw07kal3ki94n7j7rm14csgw7a3h6shs7dc\n"
    "@webassemblyjs/ieee754\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/ieee754/-/ieee754-1.9.0.tgz\t1g67ymaxnp8h9qzyc8v344fjn2xn237avdnwf32z5sjk1c6c240z\n"
    "@webassemblyjs/leb128\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/leb128/-/leb128-1.9.0.tgz\t0qv4nnrvky01swb09bsa3sjis0z75y4rsjikn7xya1l0i7h0x2i5\n"
    "@webassemblyjs/utf8\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/utf8/-/utf8-1.9.0.tgz\t0ncy542zbxxwzklz0jdqxk734crxhdi0aj56w2jwjvdk4w7350g6\n"
    "@webassemblyjs/wasm-edit\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wasm-edit/-/wasm-edit-1.9.0.tgz\t0jr70rywkbrxwy89ys5fw5k29zi3xgymjn2ks2nh267jfpmv0khh\n"
    "@webassemblyjs/wasm-gen\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wasm-gen/-/wasm-gen-1.9.0.tgz\t17k93x3p770n780z3iigcq30bq99d9q5qfaisbckc89dlhsk0s1d\n"
    "@webassemblyjs/wasm-opt\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wasm-opt/-/wasm-opt-1.9.0.tgz\t1jwbcs326hpm9ynfs3lkzqvnv64zvqfzk7w1ypjzr3i0hf98fl6j\n"
    "@webassemblyjs/wasm-parser\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wasm-parser/-/wasm-parser-1.9.0.tgz\t0c2wq4w9qjhicv911yxdhcrda6acjr58izvvdyaaf3z4b8246hds\n"
    "@webassemblyjs/wast-parser\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wast-parser/-/wast-parser-1.9.0.tgz\t10xh2vrhwb7jqsnhansngpfsl3gg8kg9vkaag0x9q5a31cc36kpl\n"
    "@webassemblyjs/wast-printer\t1.9.0\thttps://registry.npmjs.org/@webassemblyjs/wast-printer/-/wast-printer-1.9.0.tgz\t091dcj8gv4f78wpwqc3iakzymdcmyq9ya4m3wsk08lplc22amqc5\n"
    "@xtuc/ieee754\t1.2.0\thttps://registry.npmjs.org/@xtuc/ieee754/-/ieee754-1.2.0.tgz\t1v7d8f25im0dw94maw41c87lb4qfrafxyw717k2ahz8rgck1mjs2\n"
    "@xtuc/long\t4.2.2\thttps://registry.npmjs.org/@xtuc/long/-/long-4.2.2.tgz\t0q7n92kvf4k3gp6appy7gssjk1hn9j7spnwgxgvqramrn1nd52vw\n"
    "acorn\t6.4.2\thttps://registry.npmjs.org/acorn/-/acorn-6.4.2.tgz\t0q6wsid97jbwqdwigqh3ksmk3akm3wqxv3hcvx4r138qvdigbpsd\n"
    "ajv-errors\t1.0.1\thttps://registry.npmjs.org/ajv-errors/-/ajv-errors-1.0.1.tgz\t14261liqzlpxllm4lyyc9glfypiwhxr5507xy88n532h2qp964wd\n"
    "ajv-keywords\t3.5.2\thttps://registry.npmjs.org/ajv-keywords/-/ajv-keywords-3.5.2.tgz\t0h32h2f5vcj83cjprhhb9d55g2ijajdv04s9n8c8cja2v9a6dsxg\n"
    "ajv\t6.12.6\thttps://registry.npmjs.org/ajv/-/ajv-6.12.6.tgz\t0jhk2dnzrk188p3micnkh7126lhdbkj9iip0pywhky6vh1dk8xcr\n"
    "ansi-regex\t4.1.0\thttps://registry.npmjs.org/ansi-regex/-/ansi-regex-4.1.0.tgz\t0293nhq2i39ni46sphk3mjmfwnd1hv2z4rrbd2q9596nfmpj30w0\n"
    "ansi-styles\t3.2.1\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-3.2.1.tgz\t1wqd08glq159q724kvpi6nnf87biajr749a7r9c84xm639g6463k\n"
    "ansi-styles\t4.3.0\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-4.3.0.tgz\t0zwqsx67hr7m4a8dpd0jzkp2rjm5v7938x4rhcqh7djsv139llrc\n"
    "anymatch\t2.0.0\thttps://registry.npmjs.org/anymatch/-/anymatch-2.0.0.tgz\t1cj8jwy1k9mg7pmscs4dl6id8wg62fx3vfhw8snjbmbivzh9p7a0\n"
    "anymatch\t3.1.2\thttps://registry.npmjs.org/anymatch/-/anymatch-3.1.2.tgz\t052vx8z5fr7jpp947kp984lhik9hg9c5cldrqp89gvvymqy0ns6a\n"
    "aproba\t1.2.0\thttps://registry.npmjs.org/aproba/-/aproba-1.2.0.tgz\t17g0x3q0jy73db7n9x7aw9dazv7adhar5y7pyilkznq53v3niwss\n"
    "arr-diff\t4.0.0\thttps://registry.npmjs.org/arr-diff/-/arr-diff-4.0.0.tgz\t1735byq6vmrvqkv9n5400494mh9vd6x4knzkybgr55km5dgpdcyx\n"
    "arr-flatten\t1.1.0\thttps://registry.npmjs.org/arr-flatten/-/arr-flatten-1.1.0.tgz\t0amnq01y6y8j49rdcib9yh8n95wk2ajs3qcckccvv1x6bf6nfvay\n"
    "arr-union\t3.1.0\thttps://registry.npmjs.org/arr-union/-/arr-union-3.1.0.tgz\t1jrcfq6xnx3lbvnpl9pzfvc2v3bcgyir1vwcc7p0slhf6gglzd3p\n"
    "array-unique\t0.3.2\thttps://registry.npmjs.org/array-unique/-/array-unique-0.3.2.tgz\t0bkrb481qri7qad5h4bzw9hq161wfqgxdj5g11a5bnlfylqczg9g\n"
    "asap\t2.0.6\thttps://registry.npmjs.org/asap/-/asap-2.0.6.tgz\t1pnci76rf0dwsjlyafh1pygbzr3908y1gwfkhd3qsvgl9iv41d2s\n"
    "asn1.js\t5.4.1\thttps://registry.npmjs.org/asn1.js/-/asn1.js-5.4.1.tgz\t18f2z3cg0gljsv2ycv8gl6r8cbdhdx6mizn9xkl4w9aza45rxicw\n"
    "assert\t1.5.0\thttps://registry.npmjs.org/assert/-/assert-1.5.0.tgz\t0hk7b1waz2xisqp57k3s75x48y1kqv0afrmkjdydqzfz756wxrmr\n"
    "assign-symbols\t1.0.0\thttps://registry.npmjs.org/assign-symbols/-/assign-symbols-1.0.0.tgz\t1lpcb6gzhdl4l9843kifsz9z48qwpk5gw6b1h6f6n7h5d8qp2xab\n"
    "async-each\t1.0.3\thttps://registry.npmjs.org/async-each/-/async-each-1.0.3.tgz\t0qv3hchym99lkq4jsikkdirwxzs3kifdfpyrinazc543hipbhxla\n"
    "asynckit\t0.4.0\thttps://registry.npmjs.org/asynckit/-/asynckit-0.4.0.tgz\t1kvxnmjbjwqc8gvp4ms7d8w8x7y41rcizmz4898694h7ywq4y9cc\n"
    "atob\t2.1.2\thttps://registry.npmjs.org/atob/-/atob-2.1.2.tgz\t1nmrnfpzg9a99i4p88knw3470d5vcqmm3hyhavlln96wnza2lbg5\n"
    "balanced-match\t1.0.2\thttps://registry.npmjs.org/balanced-match/-/balanced-match-1.0.2.tgz\t1hdwrr7qqb37plj7962xbwjx1jvjz7ahl7iqrwh82yhcvnmzfm6q\n"
    "base64-js\t1.5.1\thttps://registry.npmjs.org/base64-js/-/base64-js-1.5.1.tgz\t118a46skxnrgx5bdd68ny9xxjcvyb7b1clj2hf82d196nm2skdxi\n"
    "base\t0.11.2\thttps://registry.npmjs.org/base/-/base-0.11.2.tgz\t0wh3b37238q4x15diq4vp2vx6d6zqh9z0559p0kk6xh0v9b95ca0\n"
    "big.js\t5.2.2\thttps://registry.npmjs.org/big.js/-/big.js-5.2.2.tgz\t09v47lh5b9h2x2aazlpf7ggwbmfcskxj2rq0360pvxk6ispadf0p\n"
    "binary-extensions\t1.13.1\thttps://registry.npmjs.org/binary-extensions/-/binary-extensions-1.13.1.tgz\t172h5sjqa46zwblrzbjqdr0v3jjcasfvsgm6zqq5jgd6xxjq2kkh\n"
    "binary-extensions\t2.2.0\thttps://registry.npmjs.org/binary-extensions/-/binary-extensions-2.2.0.tgz\t08ynqw2044jlg0vmxgrmzrppirahd8734i2a67ql917410igm08g\n"
    "bluebird\t3.7.2\thttps://registry.npmjs.org/bluebird/-/bluebird-3.7.2.tgz\t1p3dh022lvsrmsfyz37nr2x96g85y3356l4pgqkn32gm8hm0p2y6\n"
    "bn.js\t4.12.0\thttps://registry.npmjs.org/bn.js/-/bn.js-4.12.0.tgz\t0f32mdnrqd1xz1f4589y483isddjlmf0vpfxmdlb192581by1zmn\n"
    "bn.js\t5.2.0\thttps://registry.npmjs.org/bn.js/-/bn.js-5.2.0.tgz\t1jmjj4hpvxzhl0g09zcyb7wvb8gc151l35b9kz155rrvajrc2x4w\n"
    "brace-expansion\t1.1.11\thttps://registry.npmjs.org/brace-expansion/-/brace-expansion-1.1.11.tgz\t1nlmjvlwlp88knblnayns0brr7a9m2fynrlwq425lrpb4mcn9gc4\n"
    "braces\t2.3.2\thttps://registry.npmjs.org/braces/-/braces-2.3.2.tgz\t10608dfl1pxajw0nwrsh69769q659yjyw88b0mrlprnn0z1wya1l\n"
    "braces\t3.0.2\thttps://registry.npmjs.org/braces/-/braces-3.0.2.tgz\t1kpaa113m54qc1n2zvs0p1ika4s9dzvcczlw8q66xkyliy982n3k\n"
    "brorand\t1.1.0\thttps://registry.npmjs.org/brorand/-/brorand-1.1.0.tgz\t098jln7s6cqp4xrjfbikxr91lkvnvxp928nrjr56kx8jvdb0dpba\n"
    "browserify-aes\t1.2.0\thttps://registry.npmjs.org/browserify-aes/-/browserify-aes-1.2.0.tgz\t0s71laf6qx5n2ai2h92qn3f0l7831lvxlg4kc4pix1mdr42vlr4v\n"
    "browserify-cipher\t1.0.1\thttps://registry.npmjs.org/browserify-cipher/-/browserify-cipher-1.0.1.tgz\t1r06d9y349w34dimszb0bncd7kpw3xcky8m6d5dsx6g959f1aa1d\n"
    "browserify-des\t1.0.2\thttps://registry.npmjs.org/browserify-des/-/browserify-des-1.0.2.tgz\t08clvbmmpx5x1dppmygb6fnm9zzdg3czraqa1wximgdbb1m3nl5p\n"
    "browserify-rsa\t4.1.0\thttps://registry.npmjs.org/browserify-rsa/-/browserify-rsa-4.1.0.tgz\t0s1jikdg64xa1019wivqwz0y3rh6dmw0ajpkzinpapjmxh8yv728\n"
    "browserify-sign\t4.2.1\thttps://registry.npmjs.org/browserify-sign/-/browserify-sign-4.2.1.tgz\t16g1z7cxb6b9aal2xjr7kp6r2bqzc94jyrmigyishzzf1314nbbz\n"
    "browserify-zlib\t0.2.0\thttps://registry.npmjs.org/browserify-zlib/-/browserify-zlib-0.2.0.tgz\t0vm3pnw1nnj98849ai2xxrrm1v1alb7kiyh076l0n5hyi3rx1i7n\n"
    "buffer-from\t1.1.1\thttps://registry.npmjs.org/buffer-from/-/buffer-from-1.1.1.tgz\t17drzww1pyrh2m1c46i02090gvwhriq00qqy66yh3bcjwz0mh3hr\n"
    "buffer-xor\t1.0.3\thttps://registry.npmjs.org/buffer-xor/-/buffer-xor-1.0.3.tgz\t0jjgqva9x5i606fy8hr91zsnxbrybx18k152kl7njqhf81lb1vvb\n"
    "buffer\t4.9.2\thttps://registry.npmjs.org/buffer/-/buffer-4.9.2.tgz\t0bqwvwn2yf4bil2cw9dlna7dyp0n5axsv3yk8401czz7swz8ira9\n"
    "builtin-status-codes\t3.0.0\thttps://registry.npmjs.org/builtin-status-codes/-/builtin-status-codes-3.0.0.tgz\t1f4xnx0pav796sdr414cx51j8knpymxkxby4jasbzz2rx2b1hvii\n"
    "cacache\t12.0.4\thttps://registry.npmjs.org/cacache/-/cacache-12.0.4.tgz\t1akl3kf3hmj6pjq72i51ijkmp026zjf1asqzbi4x7i81f411d8bd\n"
    "cache-base\t1.0.1\thttps://registry.npmjs.org/cache-base/-/cache-base-1.0.1.tgz\t1iny3winp8x5ac39hx52baq60g2hsp4pcx95a634c83klawdaw78\n"
    "camelcase\t5.3.1\thttps://registry.npmjs.org/camelcase/-/camelcase-5.3.1.tgz\t15l68n2iq0ys0cf49h9adyvwk030kcqwrpalfcpmylc9p15342f6\n"
    "caseless\t0.12.0\thttps://registry.npmjs.org/caseless/-/caseless-0.12.0.tgz\t165fzm8s6qxapxk8xlb548q58xjav55k5nnychr234282irb2zjd\n"
    "chalk\t2.4.2\thttps://registry.npmjs.org/chalk/-/chalk-2.4.2.tgz\t0wf6hln5gcjb2n8p18gag6idghl6dfq4if6pxa6s1jqnwr94x26h\n"
    "chalk\t4.1.1\thttps://registry.npmjs.org/chalk/-/chalk-4.1.1.tgz\t0vvy5vy1j28fs1wvdv2nmbmiv4pfwipmn8p9nd37mifmsa4nanqg\n"
    "chokidar\t2.1.8\thttps://registry.npmjs.org/chokidar/-/chokidar-2.1.8.tgz\t1asn5mf5gda9lclqpdjwkr87rkz1vxj6wm2jrsjgqzk3qvf7fpn1\n"
    "chokidar\t3.5.1\thttps://registry.npmjs.org/chokidar/-/chokidar-3.5.1.tgz\t1iklfja0sc7vyikli3v64p1md6f1n4rbzc73mzddwli9i0p68naf\n"
    "chownr\t1.1.4\thttps://registry.npmjs.org/chownr/-/chownr-1.1.4.tgz\t0gl3b5fqhvgq3glfdq341jmkyi7hmw4kdg4wd3pis0sdsc2kx1kj\n"
    "chrome-trace-event\t1.0.3\thttps://registry.npmjs.org/chrome-trace-event/-/chrome-trace-event-1.0.3.tgz\t0khww2f29cl0197417vflsqncdf3wv0j388m1gyvbrry3z7gcmcr\n"
    "cipher-base\t1.0.4\thttps://registry.npmjs.org/cipher-base/-/cipher-base-1.0.4.tgz\t15gjpl7bqa9y47ck12nrf20bkk3dv6xd8hj9q1c25jkiyfj9j081\n"
    "class-utils\t0.3.6\thttps://registry.npmjs.org/class-utils/-/class-utils-0.3.6.tgz\t0567alh9j9bl7rj91frmjdpb4q5zig9rydzkdm9pmij85h7sffjh\n"
    "cliui\t5.0.0\thttps://registry.npmjs.org/cliui/-/cliui-5.0.0.tgz\t0sxcwv38f8zqf21appk4vp0n675xvl7p1gjqgx3lz53rgl47xxf6\n"
    "collection-visit\t1.0.0\thttps://registry.npmjs.org/collection-visit/-/collection-visit-1.0.0.tgz\t062q78a3fjfvk4vplkay9hd4rx6f1xw4r0438sa0hbv62jf5bc46\n"
    "color-convert\t1.9.3\thttps://registry.npmjs.org/color-convert/-/color-convert-1.9.3.tgz\t1ahbdssv1qgwlzvhv7731hpfgz8wny0619x97b7n5x9lckj17i0j\n"
    "color-convert\t2.0.1\thttps://registry.npmjs.org/color-convert/-/color-convert-2.0.1.tgz\t1qbw9rwfzcp7y0cpa8gmwlj7ccycf9pwn15zvf2s06f070ss83wj\n"
    "color-name\t1.1.3\thttps://registry.npmjs.org/color-name/-/color-name-1.1.3.tgz\t0kkq17s5yg6lg8ncg2nls6asih58qafn7wbrcgmwnqr5zdqk7vxh\n"
    "color-name\t1.1.4\thttps://registry.npmjs.org/color-name/-/color-name-1.1.4.tgz\t020p7x7k8rlph38lhsqpqvkx0b70lzlmk6mgal9r9sz8c527qysh\n"
    "combined-stream\t1.0.8\thttps://registry.npmjs.org/combined-stream/-/combined-stream-1.0.8.tgz\t04hm5rrkwda2qgy1afwhrz42asmflw5hxkbpxddn741ywnmmmgmn\n"
    "commander\t2.20.3\thttps://registry.npmjs.org/commander/-/commander-2.20.3.tgz\t0m9bcmcwgn2zj6hdqydnyx6d1c5y014ysazyqd6qva8pw0yr00iw\n"
    "commander\t4.1.1\thttps://registry.npmjs.org/commander/-/commander-4.1.1.tgz\t1cxp6ibyy2y3756dl7bnab5wji64a73bg88v70n0w4gz1g54fh6x\n"
    "commondir\t1.0.1\thttps://registry.npmjs.org/commondir/-/commondir-1.0.1.tgz\t1c2iqabm89b368173v6lik5zzll3b0b162ij90z956gpwhdqb2av\n"
    "component-emitter\t1.3.0\thttps://registry.npmjs.org/component-emitter/-/component-emitter-1.3.0.tgz\t0qc1qx0ngvah8lmkn0d784vlxmya2kr5gpjcpfikxlpwx5v3wr0h\n"
    "concat-map\t0.0.1\thttps://registry.npmjs.org/concat-map/-/concat-map-0.0.1.tgz\t0qa2zqn9rrr2fqdki44s4s2dk2d8307i4556kv25h06g43b2v41m\n"
    "concat-stream\t1.6.2\thttps://registry.npmjs.org/concat-stream/-/concat-stream-1.6.2.tgz\t1wa3gka91z4mdwi9yz2lri8lb2b1vhimkr6zckcjdj4bjxcw2iya\n"
    "consola\t2.15.3\thttps://registry.npmjs.org/consola/-/consola-2.15.3.tgz\t1bp834v18cn8i9j8wknvkai9v27y4fvhf1q0rinb4sbhf8x2ccy1\n"
    "console-browserify\t1.2.0\thttps://registry.npmjs.org/console-browserify/-/console-browserify-1.2.0.tgz\t0h0h5i9rvfswmy5qm9kyhqsc93hc6s08r1i0rxs930nmfdzqcv9f\n"
    "constants-browserify\t1.0.0\thttps://registry.npmjs.org/constants-browserify/-/constants-browserify-1.0.0.tgz\t0n8zjdpk4yrv2h86rxipsdmk5mq2c6gb99iwgr4ykp4xc3yhg4za\n"
    "copy-concurrently\t1.0.5\thttps://registry.npmjs.org/copy-concurrently/-/copy-concurrently-1.0.5.tgz\t0kpc7rkx2xp1cril8sznncv0441m2mcr770q150iln2f7iilvra4\n"
    "copy-descriptor\t0.1.1\thttps://registry.npmjs.org/copy-descriptor/-/copy-descriptor-0.1.1.tgz\t1dmlg6g04hfn1kmjklw6l33va255gsml1mrlz07jfv2a4alz4470\n"
    "core-util-is\t1.0.2\thttps://registry.npmjs.org/core-util-is/-/core-util-is-1.0.2.tgz\t164k94d9bdzw1335kzakj7hflhnnixpx4n6ydbhf7vbrcnmlv954\n"
    "create-ecdh\t4.0.4\thttps://registry.npmjs.org/create-ecdh/-/create-ecdh-4.0.4.tgz\t1q9wf40kj32qwi9wygxr0l0hvl981k6wksn5hl3jhkyzcb8840cr\n"
    "create-hash\t1.2.0\thttps://registry.npmjs.org/create-hash/-/create-hash-1.2.0.tgz\t1bab07i2b8j98wacjdzknsypv9dcial4j3sky7qwqcnr1d4pjh7y\n"
    "create-hmac\t1.1.7\thttps://registry.npmjs.org/create-hmac/-/create-hmac-1.1.7.tgz\t19vs6cvgdx0pyjjx955szg2fza80pbm621f3rkc6cidqc3wdlxzx\n"
    "cross-spawn\t6.0.5\thttps://registry.npmjs.org/cross-spawn/-/cross-spawn-6.0.5.tgz\t0g4wawds7l4j54sqpv4iipkf1h8cnfrkkwq951sn48xf0ai3xxjh\n"
    "crypto-browserify\t3.12.0\thttps://registry.npmjs.org/crypto-browserify/-/crypto-browserify-3.12.0.tgz\t023mrxhhndda75bbsmfs524rjzxi9s0lw4dpbsapczsaxqsfash4\n"
    "cyclist\t1.0.1\thttps://registry.npmjs.org/cyclist/-/cyclist-1.0.1.tgz\t03w6v04gzpcickbr092hf6hfvkl03lb8dzi140kr5x8f8mal8vxh\n"
    "debug\t2.6.9\thttps://registry.npmjs.org/debug/-/debug-2.6.9.tgz\t160wvc74r8aypds7pym3hq4qpa786hpk4vif58ggiwcqcv34ibil\n"
    "decamelize\t1.2.0\thttps://registry.npmjs.org/decamelize/-/decamelize-1.2.0.tgz\t0r187qd80plv8mm8riqk3xcmpip3zcpsgjrvf013m37323syzbdl\n"
    "decode-uri-component\t0.2.0\thttps://registry.npmjs.org/decode-uri-component/-/decode-uri-component-0.2.0.tgz\t1mhafchzv526marx5laflfrfz1dsz0mi61r9805rn96dhry44gha\n"
    "define-property\t0.2.5\thttps://registry.npmjs.org/define-property/-/define-property-0.2.5.tgz\t1r2gws87mpwv0i1rl3l79bw8psgpz44vwyd9va9cr90bvkada5yk\n"
    "define-property\t1.0.0\thttps://registry.npmjs.org/define-property/-/define-property-1.0.0.tgz\t1547m4v074hgd28jzv4k82ig43pl7rgfnp0y832swxmlff4ra6m6\n"
    "define-property\t2.0.2\thttps://registry.npmjs.org/define-property/-/define-property-2.0.2.tgz\t0m8x3myy76d3w777c1jq94gafphxqrpj7sy3myxcvksfk0p8vpha\n"
    "delayed-stream\t1.0.0\thttps://registry.npmjs.org/delayed-stream/-/delayed-stream-1.0.0.tgz\t1lr98585rayrc5xfj599hg6mxqvks38diir74ivivyvx47jgqf5c\n"
    "des.js\t1.0.1\thttps://registry.npmjs.org/des.js/-/des.js-1.0.1.tgz\t0yglmzdjdhc0m6di0l0f63rws4y9vyjx9514f5gqm1pq06g4prq4\n"
    "detect-file\t1.0.0\thttps://registry.npmjs.org/detect-file/-/detect-file-1.0.0.tgz\t0f98cmkihrk8fznrr9fvdalzqhxa1cy0bdxs8ybj81m16670cc92\n"
    "detect-indent\t0.2.0\thttps://registry.npmjs.org/detect-indent/-/detect-indent-0.2.0.tgz\t0mpjf5n7iqqbiqx7kncvl4a4v6p2bzdjy5j303b5xs6lsqspiibs\n"
    "diffie-hellman\t5.0.3\thttps://registry.npmjs.org/diffie-hellman/-/diffie-hellman-5.0.3.tgz\t0fp5zgad59kxl9pm0icf4dfm4cngzsplyk5f1mms2lskybh9m037\n"
    "domain-browser\t1.2.0\thttps://registry.npmjs.org/domain-browser/-/domain-browser-1.2.0.tgz\t0vw5nkp86jcclkkicjr7dlm7f5b7778fzhdbvcq7h7b2d4yqqw9w\n"
    "dts-bundle\t0.7.3\thttps://registry.npmjs.org/dts-bundle/-/dts-bundle-0.7.3.tgz\t0z6j84s8689dmvf3z5p7mkn08x19zppm0nlx3c26n9iljava437k\n"
    "duplexify\t3.7.1\thttps://registry.npmjs.org/duplexify/-/duplexify-3.7.1.tgz\t1ziglqhzdbn7kdwhxgak4008wkg99r03ycwasksw9vdz97w7sys6\n"
    "elliptic\t6.5.4\thttps://registry.npmjs.org/elliptic/-/elliptic-6.5.4.tgz\t1gn58lpc0q6s52cl6m4saayn81nk4041pcymlz01x25nzidcwd94\n"
    "emoji-regex\t7.0.3\thttps://registry.npmjs.org/emoji-regex/-/emoji-regex-7.0.3.tgz\t1dx47s67r2m5fk9hdk27h4k5bdk7jyv2l5jvnmrzwzjbpyvcnzg0\n"
    "emojis-list\t3.0.0\thttps://registry.npmjs.org/emojis-list/-/emojis-list-3.0.0.tgz\t1s6sqvi0w9yrd46kdnjl15nw0khgyz7bivn3kx6a3j7xnv2wx0wk\n"
    "end-of-stream\t1.4.4\thttps://registry.npmjs.org/end-of-stream/-/end-of-stream-1.4.4.tgz\t1d8dvwmq5krcjakr2s7b2dwh8x6zgs8qj8mdwkgxsvx7rgqfr2qb\n"
    "enhanced-resolve\t4.5.0\thttps://registry.npmjs.org/enhanced-resolve/-/enhanced-resolve-4.5.0.tgz\t047ndyvz5p03pi2p8ni4ylq93rhls9llx0niwsbc8jxk6jwbpzsh\n"
    "errno\t0.1.8\thttps://registry.npmjs.org/errno/-/errno-0.1.8.tgz\t1mgpciwnx09vay26c5x9cndpzja3zw302w02vk9qpf8y2ysmldav\n"
    "escape-string-regexp\t1.0.5\thttps://registry.npmjs.org/escape-string-regexp/-/escape-string-regexp-1.0.5.tgz\t0iy3jirnnslnfwk8wa5xkg56fnbmg7bsv5v2a1s0qgbnfqp7j375\n"
    "eslint-scope\t4.0.3\thttps://registry.npmjs.org/eslint-scope/-/eslint-scope-4.0.3.tgz\t0jyq9qzfhbbkpgybdq5njd3cmymv1irl2srd2inlbb3vdaham0zr\n"
    "esrecurse\t4.3.0\thttps://registry.npmjs.org/esrecurse/-/esrecurse-4.3.0.tgz\t0q9vg6dmzdcy4mmm6dnmz1d9dfrm1gvi32n8f2slfsr9sxq97kry\n"
    "estraverse\t4.3.0\thttps://registry.npmjs.org/estraverse/-/estraverse-4.3.0.tgz\t1bpip5qvpq6f6prpn5dsxnqsaw3czx6hn8mps04v5vpqgla2n9kz\n"
    "estraverse\t5.2.0\thttps://registry.npmjs.org/estraverse/-/estraverse-5.2.0.tgz\t00g0gmi62ibw13pjsl3inbizb9wq47rlmc6d0v6g7ikncrj0g1lv\n"
    "events\t3.3.0\thttps://registry.npmjs.org/events/-/events-3.3.0.tgz\t0jsk7gxx98816wg0nl4wfwljscbg7iv8ys68mbgrnaaq1dixsc1c\n"
    "evp_bytestokey\t1.0.3\thttps://registry.npmjs.org/evp_bytestokey/-/evp_bytestokey-1.0.3.tgz\t1qa0ghpk2w6gylbknlbb3mb90lw9sf1xafr7dy4gp17djrc182n1\n"
    "expand-brackets\t2.1.4\thttps://registry.npmjs.org/expand-brackets/-/expand-brackets-2.1.4.tgz\t0csxpxfx1xkf2dp10vpifynkrx8csx7md7gysvhy5xr094hdr3nq\n"
    "expand-tilde\t2.0.2\thttps://registry.npmjs.org/expand-tilde/-/expand-tilde-2.0.2.tgz\t0931ha1jm9b4kc547qp2bp7ymr5yxkqmvfk4pk2k00nc5hqx4ji4\n"
    "extend-shallow\t2.0.1\thttps://registry.npmjs.org/extend-shallow/-/extend-shallow-2.0.1.tgz\t09baxpl8w1rw3qmqmp7w23kyqrxks1hhbvpac0j82gbsgimrlz0v\n"
    "extend-shallow\t3.0.2\thttps://registry.npmjs.org/extend-shallow/-/extend-shallow-3.0.2.tgz\t02bickcbljfrxfix2rbvq5j2cdlwm0dqflxc2ky4l6jp97bcl6m0\n"
    "extglob\t2.0.4\thttps://registry.npmjs.org/extglob/-/extglob-2.0.4.tgz\t1wza438hvcr83b28zic65h8jq8k0p0v9iw9b1lfk1zhb5xrkp8sy\n"
    "fast-deep-equal\t3.1.3\thttps://registry.npmjs.org/fast-deep-equal/-/fast-deep-equal-3.1.3.tgz\t13vvwib6za4zh7054n3fg86y127ig3jb0djqz31qsqr71yca06dh\n"
    "fast-json-stable-stringify\t2.1.0\thttps://registry.npmjs.org/fast-json-stable-stringify/-/fast-json-stable-stringify-2.1.0.tgz\t11qnzlan5yd2hg9nqi9hdv48bq6kwvw9pxsxir22n2iyqhighb8y\n"
    "figgy-pudding\t3.5.2\thttps://registry.npmjs.org/figgy-pudding/-/figgy-pudding-3.5.2.tgz\t0v71zsmaisqr73bvmi3iqx973bwircb04yvfrmfqmn0lkxny2zcr\n"
    "fill-range\t4.0.0\thttps://registry.npmjs.org/fill-range/-/fill-range-4.0.0.tgz\t14kaakn1yhkfsclqds0pg1g87aibi8nkrwn0axvfasj495hv2wzx\n"
    "fill-range\t7.0.1\thttps://registry.npmjs.org/fill-range/-/fill-range-7.0.1.tgz\t0wp93mwfgzcddi6ii62qx7gb082jgh0rfq6pgvv2xndjyaygvk98\n"
    "find-cache-dir\t2.1.0\thttps://registry.npmjs.org/find-cache-dir/-/find-cache-dir-2.1.0.tgz\t1izfnb8r6sd5aj4j1mxs11665r79n0qdil918wp7aa1gqfj3ga4j\n"
    "find-up\t3.0.0\thttps://registry.npmjs.org/find-up/-/find-up-3.0.0.tgz\t0ln7mwc9b465l646xvjd0692yy6izi27xb4y7g8ffpvjl7s9fx4r\n"
    "find-up\t4.1.0\thttps://registry.npmjs.org/find-up/-/find-up-4.1.0.tgz\t1sr6b86slwxig85zcvjpgmvaqljb6il8n21719gf1lh6ad9v1a9k\n"
    "findup-sync\t3.0.0\thttps://registry.npmjs.org/findup-sync/-/findup-sync-3.0.0.tgz\t0x2mfm3b8fajaxavijjs6jd2jikcgdq69lk8ian61a0r9rsj78j8\n"
    "flush-write-stream\t1.1.1\thttps://registry.npmjs.org/flush-write-stream/-/flush-write-stream-1.1.1.tgz\t1wxiglns0pcq11rh9kjz8w66bc0zp879dwklci6iap737bkskjr2\n"
    "for-in\t1.0.2\thttps://registry.npmjs.org/for-in/-/for-in-1.0.2.tgz\t0pm8dx9gvp9p91my9fqivajq7yhnxmn8scl391pgcv6d8h6s6zaf\n"
    "form-data\t2.3.3\thttps://registry.npmjs.org/form-data/-/form-data-2.3.3.tgz\t1j1ka178syqqaycr1m3vqahbb3bi7qsks0mp0iqbd6y7yj1wz7p3\n"
    "fragment-cache\t0.2.1\thttps://registry.npmjs.org/fragment-cache/-/fragment-cache-0.2.1.tgz\t114jfm5qpvz52127hf4ny4vz1qs7a597hql5lj0g2ncixn8sqg76\n"
    "from2\t2.3.0\thttps://registry.npmjs.org/from2/-/from2-2.3.0.tgz\t1mlmr4kglwr6v6f75l6s6s9amh8hlwfsibbk8il9m7ryn4lf06w8\n"
    "fs-extra\t8.1.0\thttps://registry.npmjs.org/fs-extra/-/fs-extra-8.1.0.tgz\t0n5ibswj8njpw8w8igfqxklyips6m1y8cyk1zrd9llv9rirlgv00\n"
    "fs-write-stream-atomic\t1.0.10\thttps://registry.npmjs.org/fs-write-stream-atomic/-/fs-write-stream-atomic-1.0.10.tgz\t1imhs0xszgvz9l9yckhxn4sy8ahz1pyn9ckirkd6np3wnpl75k2q\n"
    "fs.realpath\t1.0.0\thttps://registry.npmjs.org/fs.realpath/-/fs.realpath-1.0.0.tgz\t174g5vay9jnd7h5q8hfdw6dnmwl1gdpn4a8sz0ysanhj2f3wp04y\n"
    "get-caller-file\t2.0.5\thttps://registry.npmjs.org/get-caller-file/-/get-caller-file-2.0.5.tgz\t0pwk4r8iyyq2j0xpxavdm3ldb4h4k4s4xb74m8dlrzs9374f24vv\n"
    "get-port\t3.2.0\thttps://registry.npmjs.org/get-port/-/get-port-3.2.0.tgz\t0ibnck62cyzc206ic6dc24vh5hmdizwqkskl3smwhigfhpj2xir9\n"
    "get-stdin\t0.1.0\thttps://registry.npmjs.org/get-stdin/-/get-stdin-0.1.0.tgz\t1jd35bfnk4r40r7jm1wgw7csqp929gfh7l8gmbkd626bh08vy1w0\n"
    "get-value\t2.0.6\thttps://registry.npmjs.org/get-value/-/get-value-2.0.6.tgz\t057wz0ya7zlgz59m08zbaasvzfdxjzgd6bzphd2xwsydhjwnw02l\n"
    "glob-parent\t3.1.0\thttps://registry.npmjs.org/glob-parent/-/glob-parent-3.1.0.tgz\t05d92ijvizlxlgss00d3qs5d9gj6ax39vhjhjacyidynl6dny7x9\n"
    "glob-parent\t5.1.2\thttps://registry.npmjs.org/glob-parent/-/glob-parent-5.1.2.tgz\t1mfna9lpp82lapng0qq5x4x5j10nhimcx36lg4m5k4wbs7msy5ln\n"
    "glob\t6.0.4\thttps://registry.npmjs.org/glob/-/glob-6.0.4.tgz\t0hr537g7wdip7s8x7l2qbkywgf79srczq971g03aaqampwwzcrd7\n"
    "glob\t7.1.7\thttps://registry.npmjs.org/glob/-/glob-7.1.7.tgz\t1vlv5r0ipznrq1c7ikqpbzgk7q31zz6m1wcy9cxsklb8vvfv6105\n"
    "global-modules\t1.0.0\thttps://registry.npmjs.org/global-modules/-/global-modules-1.0.0.tgz\t1rjf3gybhsgc66r44ikdw8b8qqp5pjr30c58zmvv4v432z9pb01l\n"
    "global-modules\t2.0.0\thttps://registry.npmjs.org/global-modules/-/global-modules-2.0.0.tgz\t06bfcdljzqql9pi4y8kjaljxzrxpn63q4lhsh4fp233hr11w2mr4\n"
    "global-prefix\t1.0.2\thttps://registry.npmjs.org/global-prefix/-/global-prefix-1.0.2.tgz\t0sarygsknl8443r4kyq2mzlwz5pqpk5ard9yh2jcix65dvaxdmzi\n"
    "global-prefix\t3.0.0\thttps://registry.npmjs.org/global-prefix/-/global-prefix-3.0.0.tgz\t0wssmhdi3k1436wkj5sfhwqviyilixj8qm7x973zwc90hlgl65v6\n"
    "graceful-fs\t4.2.6\thttps://registry.npmjs.org/graceful-fs/-/graceful-fs-4.2.6.tgz\t0dz5rck3zvvblkxq2234654axjslp6ackixnb5dsh9nzxm8l4cr5\n"
    "has-flag\t3.0.0\thttps://registry.npmjs.org/has-flag/-/has-flag-3.0.0.tgz\t1sp0m48zavms86q7vkf90mwll9z2bqi11hk3s01aw8nw40r72jzd\n"
    "has-flag\t4.0.0\thttps://registry.npmjs.org/has-flag/-/has-flag-4.0.0.tgz\t1cdmvliwz8h02nwg0ipli0ydd1l82sz9s1m7bj5bn9yr24afp9vp\n"
    "has-value\t0.3.1\thttps://registry.npmjs.org/has-value/-/has-value-0.3.1.tgz\t1h4dnzr9rszpj0a015529r1c9g8ysy4wym6ay99vc6dls02jhmny\n"
    "has-value\t1.0.0\thttps://registry.npmjs.org/has-value/-/has-value-1.0.0.tgz\t1ikpbff1imw3nqqp9q9siwh7p93r1pdigiv6kgryx6l8hwiwbxr9\n"
    "has-values\t0.1.4\thttps://registry.npmjs.org/has-values/-/has-values-0.1.4.tgz\t1lnp2ww5w0lxxiqrm3scyaddj7csdrd4ldsmsvapys4rdfgnx0m6\n"
    "has-values\t1.0.0\thttps://registry.npmjs.org/has-values/-/has-values-1.0.0.tgz\t19ggazh85imjwxnvvhabypdpmyl0q4mgm3frwfx2dx3ffq1g1bwc\n"
    "hash-base\t3.1.0\thttps://registry.npmjs.org/hash-base/-/hash-base-3.1.0.tgz\t07a6ixhabgidyhzy5xcc85hrlp38jp8iq3jvc7xsg14zi36gqxyg\n"
    "hash.js\t1.1.7\thttps://registry.npmjs.org/hash.js/-/hash.js-1.1.7.tgz\t19lccrqxgndiwfcpv1xzmapmwr74rydbzm2ynvnjy19kpl6gxbcf\n"
    "hmac-drbg\t1.0.1\thttps://registry.npmjs.org/hmac-drbg/-/hmac-drbg-1.0.1.tgz\t0qjrwdicm82v3amswcbjgfa3lvfy7kv29wffvz5mb6m473cp04rj\n"
    "homedir-polyfill\t1.0.3\thttps://registry.npmjs.org/homedir-polyfill/-/homedir-polyfill-1.0.3.tgz\t16p593jixgb20qdk1ji3lh92vswjg3h40awakff8pdmc9s7mvj04\n"
    "http-basic\t8.1.3\thttps://registry.npmjs.org/http-basic/-/http-basic-8.1.3.tgz\t07gag78djfbgwszyimx5h6cgfynzsrqnyj6q6nnxa0nr8nawy0pg\n"
    "http-response-object\t3.0.2\thttps://registry.npmjs.org/http-response-object/-/http-response-object-3.0.2.tgz\t1d6pri51i1hrm8b6f68r44l9njga8rlaf5f2yvm3q4b0c8fjin8l\n"
    "https-browserify\t1.0.0\thttps://registry.npmjs.org/https-browserify/-/https-browserify-1.0.0.tgz\t1g07h6f4jggajdsf0ijcdl8xnm935sxq3l6dl91hqg7dfq34vwfl\n"
    "ieee754\t1.2.1\thttps://registry.npmjs.org/ieee754/-/ieee754-1.2.1.tgz\t1b4xiyr6fmgl05cjgc8fiyfk2jagf7xq2y5rknw9scvy76dlpwcf\n"
    "iferr\t0.1.5\thttps://registry.npmjs.org/iferr/-/iferr-0.1.5.tgz\t0f0qh2v75nbwsaxwp01vqiyygjdkv5vv2hmaqh9gjg8mal7az4kj\n"
    "import-local\t2.0.0\thttps://registry.npmjs.org/import-local/-/import-local-2.0.0.tgz\t140nh81izygkmdfqyc7kbka0vdch8k850m6qzpy49kcgyr3n12dl\n"
    "imurmurhash\t0.1.4\thttps://registry.npmjs.org/imurmurhash/-/imurmurhash-0.1.4.tgz\t0q6bf91h2g5dhvcdss74sjvp5irimd97hp73jb8p2wvajqqs08xc\n"
    "infer-owner\t1.0.4\thttps://registry.npmjs.org/infer-owner/-/infer-owner-1.0.4.tgz\t0rc7is18a3558rkjkwc48a750f6zr44sgnpdzvpmgk8xhl2plyz5\n"
    "inflight\t1.0.6\thttps://registry.npmjs.org/inflight/-/inflight-1.0.6.tgz\t16w864087xsh3q7f5gm3754s7bpsb9fq3dhknk9nmbvlk3sxr7ss\n"
    "inherits\t2.0.1\thttps://registry.npmjs.org/inherits/-/inherits-2.0.1.tgz\t0agb1p073d0gdl48vfx4zyivj9w21alnaiil4n8z1bs2h4zlkmg0\n"
    "inherits\t2.0.3\thttps://registry.npmjs.org/inherits/-/inherits-2.0.3.tgz\t1pvc6l11w425i6k9zph3226gdakqw3cq8zkfg1jf51sfnplmhpvz\n"
    "inherits\t2.0.4\thttps://registry.npmjs.org/inherits/-/inherits-2.0.4.tgz\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\n"
    "ini\t1.3.7\thttps://registry.npmjs.org/ini/-/ini-1.3.7.tgz\t1yk11xw65vlnara9h33n7jjsyv6n9mm984i3vnqz8ikxyaadjhpx\n"
    "interpret\t1.4.0\thttps://registry.npmjs.org/interpret/-/interpret-1.4.0.tgz\t0yq848vkk6a11c3h00fh2pz9vmr6j4d9hh7b2915wlhn0kj26agp\n"
    "is-accessor-descriptor\t0.1.6\thttps://registry.npmjs.org/is-accessor-descriptor/-/is-accessor-descriptor-0.1.6.tgz\t1j9kc4m771w28kdrph25q8q62yfiazg2gi6frnbfd66xfmimhmi3\n"
    "is-accessor-descriptor\t1.0.0\thttps://registry.npmjs.org/is-accessor-descriptor/-/is-accessor-descriptor-1.0.0.tgz\t18ybls0d0q6y7gp8mzhypyr0vbrx1vr5agm07s201byvc5dfmxql\n"
    "is-binary-path\t1.0.1\thttps://registry.npmjs.org/is-binary-path/-/is-binary-path-1.0.1.tgz\t05ylaj9wal46fvlzz34fbfmb0v870bc69k1h9l0lqgkbs1091vpl\n"
    "is-binary-path\t2.1.0\thttps://registry.npmjs.org/is-binary-path/-/is-binary-path-2.1.0.tgz\t1vsdqq8808l3f4230y54mhix50njfbc3z46y2wn0h0dxql1v4xm0\n"
    "is-buffer\t1.1.6\thttps://registry.npmjs.org/is-buffer/-/is-buffer-1.1.6.tgz\t03l8f9r41xy0lq5zjm790jg758r8wv3fcsfwsd8331w6l30dh6ix\n"
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
    "is-number\t3.0.0\thttps://registry.npmjs.org/is-number/-/is-number-3.0.0.tgz\t19rpbi5ryx3y28bh0pwm99az1mridh0p2sinfdxkcbpbxfx5zbf4\n"
    "is-number\t7.0.0\thttps://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz\t07nmmpplsj1gxzng6fxhnnyfkif9fvhvxa89d5lrgkwqf42w2xbv\n"
    "is-plain-object\t2.0.4\thttps://registry.npmjs.org/is-plain-object/-/is-plain-object-2.0.4.tgz\t1ipx9y0c1kmq6irjxix6vcxfax6ilnns9pkgjc6cq8ygnyagv4s8\n"
    "is-windows\t1.0.2\thttps://registry.npmjs.org/is-windows/-/is-windows-1.0.2.tgz\t18iihzz6fs6sfrgq1bpvgkfk3cza6r9wrrgn7ahcbbra1lkjh4bv\n"
    "is-wsl\t1.1.0\thttps://registry.npmjs.org/is-wsl/-/is-wsl-1.1.0.tgz\t1nvwkhv30y0dnp7889wmw1z8pvixh2h7bi60k00f7j25aza55vch\n"
    "isarray\t1.0.0\thttps://registry.npmjs.org/isarray/-/isarray-1.0.0.tgz\t11qcjpdzigcwcprhv7nyarlzjcwf3sv5i66q75zf08jj9zqpcg72\n"
    "isexe\t2.0.0\thttps://registry.npmjs.org/isexe/-/isexe-2.0.0.tgz\t0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7\n"
    "isobject\t2.1.0\thttps://registry.npmjs.org/isobject/-/isobject-2.1.0.tgz\t14df1spjczhml90421sq645shkxwggrbbkgp1qgal29kslc7av32\n"
    "isobject\t3.0.1\thttps://registry.npmjs.org/isobject/-/isobject-3.0.1.tgz\t0dvx6rhjj5b9q7fcjg24lfy2nr3a1d2ypqy9zf9lqr2s00mwkiiw\n"
    "json-parse-better-errors\t1.0.2\thttps://registry.npmjs.org/json-parse-better-errors/-/json-parse-better-errors-1.0.2.tgz\t1j89a2mmkghaan76ilpcjr437gwdgbi65aab9i6amsr84pb6bg02\n"
    "json-schema-traverse\t0.4.1\thttps://registry.npmjs.org/json-schema-traverse/-/json-schema-traverse-0.4.1.tgz\t0rf0pvm62k8g81vs7n7zx080p6sfylwk52vc149jx1216vcssdgp\n"
    "json5\t1.0.1\thttps://registry.npmjs.org/json5/-/json5-1.0.1.tgz\t111vkf7ap9ijqgqsldfmvbllldhq5hg87gk1a253ih6lssjgbncc\n"
    "json5\t2.2.0\thttps://registry.npmjs.org/json5/-/json5-2.2.0.tgz\t1zmiq12f6wb8d98l87si6ys2qfnv16wwib27ymcdy5r4s4mmm1rp\n"
    "jsonfile\t4.0.0\thttps://registry.npmjs.org/jsonfile/-/jsonfile-4.0.0.tgz\t1s701cy3mlbvgyhhyy2ypqcy064w5990sk8x81gv0200yybrbfaz\n"
    "kind-of\t3.2.2\thttps://registry.npmjs.org/kind-of/-/kind-of-3.2.2.tgz\t0isxns331nf5f4h8yj0vb4rj626bscxh1rh7j92vk8lbzcs2x93q\n"
    "kind-of\t4.0.0\thttps://registry.npmjs.org/kind-of/-/kind-of-4.0.0.tgz\t0afwg6007r7l0c9r7jghdk8pwvfffmykhybpwrs0nlks59d2ziym\n"
    "kind-of\t5.1.0\thttps://registry.npmjs.org/kind-of/-/kind-of-5.1.0.tgz\t0wkp161zwgg2jp5rjnkw7d7lgczbxj6bwvqvh4s8j68ghk0c8q2d\n"
    "kind-of\t6.0.3\thttps://registry.npmjs.org/kind-of/-/kind-of-6.0.3.tgz\t1nk31q65n9hcmbp16mbn55siqnf44wn1x71rrqyjv9bcbcxl893c\n"
    "loader-runner\t2.4.0\thttps://registry.npmjs.org/loader-runner/-/loader-runner-2.4.0.tgz\t1l9mlz41ihknzsm2b69cjkskng9rv5i34z70p0qwdiasp22vdbf5\n"
    "loader-utils\t1.4.0\thttps://registry.npmjs.org/loader-utils/-/loader-utils-1.4.0.tgz\t1g3gma72cd33dfc1hmv8nmsa14y4ydr6zb0bsan0z67mpyja2j5p\n"
    "loader-utils\t2.0.0\thttps://registry.npmjs.org/loader-utils/-/loader-utils-2.0.0.tgz\t1ia7avp5im1sds8h2f1rn1bi059nn82hvs7hlsrjxbkzy1n13ngm\n"
    "locate-path\t3.0.0\thttps://registry.npmjs.org/locate-path/-/locate-path-3.0.0.tgz\t1ghmaifkp6r47h6ygdgkf7srvxhc5qwhgjwq00ia250kpxww5xdm\n"
    "locate-path\t5.0.0\thttps://registry.npmjs.org/locate-path/-/locate-path-5.0.0.tgz\t1dsk824x6gzp2n7s0f9z7iwxsc4nyllxmix8h4588dd4c29ingdf\n"
    "lru-cache\t5.1.1\thttps://registry.npmjs.org/lru-cache/-/lru-cache-5.1.1.tgz\t0nj8d71w5yb3rmiaxby5scwfl0n1jdaplr0p6dp619j4jn0ph7mi\n"
    "lru-cache\t6.0.0\thttps://registry.npmjs.org/lru-cache/-/lru-cache-6.0.0.tgz\t0pnziizgv8jpg708ykywcjby0syjz1l2ll1j727rdxhw0gmhvr2w\n"
    "make-dir\t2.1.0\thttps://registry.npmjs.org/make-dir/-/make-dir-2.1.0.tgz\t0r2nss2nf54q616nf0s5228bnymv830kx6nf94mz5sypaqllfy3l\n"
    "map-cache\t0.2.2\thttps://registry.npmjs.org/map-cache/-/map-cache-0.2.2.tgz\t0gag01y8x17l2ffdmi5rgll24bw4cmyi3wksk45xpghirlkrkhj1\n"
    "map-visit\t1.0.0\thttps://registry.npmjs.org/map-visit/-/map-visit-1.0.0.tgz\t19fhyr0jmskx32s1s9b6p0jb96gmbxxnbmzx4sc42sxzwkfmqvpi\n"
    "md5.js\t1.3.5\thttps://registry.npmjs.org/md5.js/-/md5.js-1.3.5.tgz\t00rxd4al8zl7cf9bq6i0nhnj54pnv0444vscmdawfa8jn1hpnxq6\n"
    "memory-fs\t0.4.1\thttps://registry.npmjs.org/memory-fs/-/memory-fs-0.4.1.tgz\t1ps63pk580528c89xdj0bbikbygwlfidnrn4d4nnb6zl59r1vn9b\n"
    "memory-fs\t0.5.0\thttps://registry.npmjs.org/memory-fs/-/memory-fs-0.5.0.tgz\t1jc1r4j7jb0izqj9b5qh4anvg7a7bny73zh88vphi6pa1bk24nms\n"
    "micromatch\t3.1.10\thttps://registry.npmjs.org/micromatch/-/micromatch-3.1.10.tgz\t1j4m1y8x2sib8i5rfilml7yzpgs5njsg2nxzxwlb63997qlpb7p5\n"
    "micromatch\t4.0.4\thttps://registry.npmjs.org/micromatch/-/micromatch-4.0.4.tgz\t01n3m0v97kgw0rlkg7nfb7g60hf4blj47cpggd73kji8g1na3i8r\n"
    "miller-rabin\t4.0.1\thttps://registry.npmjs.org/miller-rabin/-/miller-rabin-4.0.1.tgz\t1jdqss21v5cmp1n17qxvmd3lp118x9qsjd768sjh820mlkkldg2m\n"
    "mime-db\t1.48.0\thttps://registry.npmjs.org/mime-db/-/mime-db-1.48.0.tgz\t1nhd3kxlgmwa98v4gbm7ihjfaxbmm339wk54xnm9z2w8jx0x4bpn\n"
    "mime-types\t2.1.31\thttps://registry.npmjs.org/mime-types/-/mime-types-2.1.31.tgz\t0plrigsi1395k3r1w2yrq92a2fp7jcgrgbx0wlm7rfzgi6d5s02h\n"
    "minimalistic-assert\t1.0.1\thttps://registry.npmjs.org/minimalistic-assert/-/minimalistic-assert-1.0.1.tgz\t187k0gdixs2zqkfvv6lm72w90c15rin2kx2zkyly7nyn8z4j4rgi\n"
    "minimalistic-crypto-utils\t1.0.1\thttps://registry.npmjs.org/minimalistic-crypto-utils/-/minimalistic-crypto-utils-1.0.1.tgz\t1cwxzbk9zg7ha3pxcm4ghcy6j48jdpplisjgfvlddcp1xw16wpzk\n"
    "minimatch\t3.0.4\thttps://registry.npmjs.org/minimatch/-/minimatch-3.0.4.tgz\t0wgammjc9myx0k0k3n9r9cjnv0r1j33cwqiy2fxx7w5nkgbj8sj2\n"
    "minimist\t0.1.0\thttps://registry.npmjs.org/minimist/-/minimist-0.1.0.tgz\t0vfz0r6v8qcdar6rkapc9bvq3v4z21vnw7zrir9vv68mchjqgl6q\n"
    "minimist\t1.2.5\thttps://registry.npmjs.org/minimist/-/minimist-1.2.5.tgz\t0l23rq2pam1khc06kd7fv0ys2cq0mlgs82dxjxjfjmlksgj0r051\n"
    "mississippi\t3.0.0\thttps://registry.npmjs.org/mississippi/-/mississippi-3.0.0.tgz\t18xnaxvc8hrsiwys2q3r8sv574035wsq0kd62bq5ijs3yrdi1p5k\n"
    "mixin-deep\t1.3.2\thttps://registry.npmjs.org/mixin-deep/-/mixin-deep-1.3.2.tgz\t0kdw3h2r5cpfazjdfjzh9yac7c2gb1vrl3nxm0bhl7pb3yh276iq\n"
    "mkdirp\t0.5.5\thttps://registry.npmjs.org/mkdirp/-/mkdirp-0.5.5.tgz\t02mvn5hllnsxzli8yy0gkgkkxndbwd3fh302shadsag3c4db0njf\n"
    "move-concurrently\t1.0.1\thttps://registry.npmjs.org/move-concurrently/-/move-concurrently-1.0.1.tgz\t1v3182dha8421mcwa4azgnp64zmfz9hz0629vwddjjdq9wv0gvxh\n"
    "ms\t2.0.0\thttps://registry.npmjs.org/ms/-/ms-2.0.0.tgz\t1jrysw9zx14av3jdvc3kywc3xkjqxh748g4s6p1iy634i2mm489n\n"
    "nanomatch\t1.2.13\thttps://registry.npmjs.org/nanomatch/-/nanomatch-1.2.13.tgz\t1f4fxk7azvglyi6gfbkxmh91pd3n6i7av03y9bpizfn37xjf7g0z\n"
    "neo-async\t2.6.2\thttps://registry.npmjs.org/neo-async/-/neo-async-2.6.2.tgz\t1x3dxkdflv3ibgab2aj91pkrqpzj62c38dk3x0zvv2qpyh6p18a3\n"
    "nice-try\t1.0.5\thttps://registry.npmjs.org/nice-try/-/nice-try-1.0.5.tgz\t1ah3s4bpm93wh7ck6fm9vd1v65ssjhcn1s4znwj5pjag76cz4l5l\n"
    "node-libs-browser\t2.2.1\thttps://registry.npmjs.org/node-libs-browser/-/node-libs-browser-2.2.1.tgz\t0jlp3743xj2xqbkx4bvg7s7gj0nvb7sz01cfhrr7jl1ffnfxvs77\n"
    "normalize-path\t2.1.1\thttps://registry.npmjs.org/normalize-path/-/normalize-path-2.1.1.tgz\t1d82jyqqyqgk8qkzb4sk7vnz6sgf8xznlm55mazlp43fc6w100cj\n"
    "normalize-path\t3.0.0\thttps://registry.npmjs.org/normalize-path/-/normalize-path-3.0.0.tgz\t1zl49w6pdbgi96sgxpzr0gizcj261v6mxv8rx70csmf5ap53r60b\n"
    "object-assign\t4.1.1\thttps://registry.npmjs.org/object-assign/-/object-assign-4.1.1.tgz\t1v999sycxcp74j2pikdhyinm2d80p2bsy4nnrrnb59rv4rm74bbq\n"
    "object-copy\t0.1.0\thttps://registry.npmjs.org/object-copy/-/object-copy-0.1.0.tgz\t1b59pq32z0kdzhjkwphyk5h0m59gcc4qvmkvq7zb49yla00w5f0w\n"
    "object-visit\t1.0.1\thttps://registry.npmjs.org/object-visit/-/object-visit-1.0.1.tgz\t05qpsh7jyq40dk2mqm85hbcaapb4g4hyjcb4z6b2kcziqfiynpsl\n"
    "object.pick\t1.3.0\thttps://registry.npmjs.org/object.pick/-/object.pick-1.3.0.tgz\t02zfyg9vkizb5vanjy3d976cnbjnx4qrcjrd92z2ylyl4ih24040\n"
    "once\t1.4.0\thttps://registry.npmjs.org/once/-/once-1.4.0.tgz\t1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg\n"
    "os-browserify\t0.3.0\thttps://registry.npmjs.org/os-browserify/-/os-browserify-0.3.0.tgz\t0f5pc2ph02ls5xchf1nj0q65m7vkq3lsgpmpbxs5h96qw18nbybx\n"
    "p-limit\t2.3.0\thttps://registry.npmjs.org/p-limit/-/p-limit-2.3.0.tgz\t15djin88kfxjdvzd7f2gnwblgclqljzqxiidm1pmrsyg14j4ajrq\n"
    "p-locate\t3.0.0\thttps://registry.npmjs.org/p-locate/-/p-locate-3.0.0.tgz\t1fbvw7ka1lgrhr7kynsjv7iqw1sdqqrh088py2r4kyjhbl8xzq70\n"
    "p-locate\t4.1.0\thttps://registry.npmjs.org/p-locate/-/p-locate-4.1.0.tgz\t1w55dykp8ysc41xx4cl8ln3gxsxvqfhvsl62n3g6gng3cbj6lnnr\n"
    "p-try\t2.2.0\thttps://registry.npmjs.org/p-try/-/p-try-2.2.0.tgz\t141pf5z1f3xmm5c0fdrfddsf7xfigjxfl103zh59bpwrk2wb5453\n"
    "pako\t1.0.11\thttps://registry.npmjs.org/pako/-/pako-1.0.11.tgz\t0h9rmpkzyav4qxpb185z89nrhi17gy8p5mxz1k1l19sj0gf2hh0d\n"
    "parallel-transform\t1.2.0\thttps://registry.npmjs.org/parallel-transform/-/parallel-transform-1.2.0.tgz\t1dx278dzqzs3f1c1p0yys4wz5cd3v4c20xak2hk8q24fp6n0rjqj\n"
    "parse-asn1\t5.1.6\thttps://registry.npmjs.org/parse-asn1/-/parse-asn1-5.1.6.tgz\t0cdmcnhag70y0wv3z71jq8lmhs6raww43wcycv29nby62f9ngx3b\n"
    "parse-cache-control\t1.0.1\thttps://registry.npmjs.org/parse-cache-control/-/parse-cache-control-1.0.1.tgz\t07kwyr1mv6893s82skg66ykcnaajqm6qahccd161mjifjldm4n4p\n"
    "parse-passwd\t1.0.0\thttps://registry.npmjs.org/parse-passwd/-/parse-passwd-1.0.0.tgz\t1ww9sbaka5vy7g9k0dacmn2hvvxkhrx7qypp9hq15h0i2lx35mnw\n"
    "pascalcase\t0.1.1\thttps://registry.npmjs.org/pascalcase/-/pascalcase-0.1.1.tgz\t0hd2yjrsfhw3183dxzs5045xnas07in2ww5sl0m5jx035zcrqv2m\n"
    "path-browserify\t0.0.1\thttps://registry.npmjs.org/path-browserify/-/path-browserify-0.0.1.tgz\t06h1wc2j5h7mrq6aicrl0p8kgnclwqclagpqrca69yxz9cvxbqdk\n"
    "path-dirname\t1.0.2\thttps://registry.npmjs.org/path-dirname/-/path-dirname-1.0.2.tgz\t1g0kbsakjgvh0n070j3wm7i0yq4m6mlyq8mrlxcpin959p93nkyr\n"
    "path-exists\t3.0.0\thttps://registry.npmjs.org/path-exists/-/path-exists-3.0.0.tgz\t0b9j0s6mvbf7js1fsga1jx4k6c4k17yn9c1jlaiziqkmvi98gxyp\n"
    "path-exists\t4.0.0\thttps://registry.npmjs.org/path-exists/-/path-exists-4.0.0.tgz\t0p3pzdvfy2il8p0dvpp1l688in68bh2zzqzcfzvv7s9c634kbdfv\n"
    "path-is-absolute\t1.0.1\thttps://registry.npmjs.org/path-is-absolute/-/path-is-absolute-1.0.1.tgz\t0p7p04xxd8q495qhxmxydyjgzcf762dp1hp2wha2b52n3agp0vbf\n"
    "path-key\t2.0.1\thttps://registry.npmjs.org/path-key/-/path-key-2.0.1.tgz\t1w2fn5cgssfvg4wfgkf9mqz4slsv45aq6f8cgszvb4h78dm9hwgf\n"
    "pbkdf2\t3.1.2\thttps://registry.npmjs.org/pbkdf2/-/pbkdf2-3.1.2.tgz\t0pyndsscjfwy3fah6d9vsrg381dm0vnn25mwd3ljc9ynalxp7x9x\n"
    "picomatch\t2.3.0\thttps://registry.npmjs.org/picomatch/-/picomatch-2.3.0.tgz\t15imkbw2d0v1mxa03zai1bf6k58jica22rdyd51qnda6cnrwp0gc\n"
    "pify\t4.0.1\thttps://registry.npmjs.org/pify/-/pify-4.0.1.tgz\t0jvbj1w7dn2kz3v3i1jsziyhcgpnsp497fq2a6z1kf34aq1mszwa\n"
    "pkg-dir\t3.0.0\thttps://registry.npmjs.org/pkg-dir/-/pkg-dir-3.0.0.tgz\t0gy9l95clcha2kq09zq0502qc2rvbcim40c1q8q1czmvyk7zf51x\n"
    "posix-character-classes\t0.1.1\thttps://registry.npmjs.org/posix-character-classes/-/posix-character-classes-0.1.1.tgz\t08c07ib7iaj34d1mnjhll0bq0yh3kb98q4mf334js2l4166y9rcr\n"
    "process-nextick-args\t2.0.1\thttps://registry.npmjs.org/process-nextick-args/-/process-nextick-args-2.0.1.tgz\t16w8m2ycy5s4ykgdfg97qxa67gfvkh6x3vdwfsncafyj4p3zhns2\n"
    "process\t0.11.10\thttps://registry.npmjs.org/process/-/process-0.11.10.tgz\t1fz6fjkaldphhj1vphhk00d35k2gkw7x8c6n58amdc4w7jdmc43w\n"
    "promise-inflight\t1.0.1\thttps://registry.npmjs.org/promise-inflight/-/promise-inflight-1.0.1.tgz\t02ibq6bvxhmyx3lh4bz1ikrlb5n728nj0gshgf5bgqxjpijkphwl\n"
    "promise\t8.1.0\thttps://registry.npmjs.org/promise/-/promise-8.1.0.tgz\t0fvpr35a05ys1nipp6c7zijfhk7jlkf9d98hlkayz1907kdcv6r0\n"
    "prr\t1.0.1\thttps://registry.npmjs.org/prr/-/prr-1.0.1.tgz\t0lk79jdnx2prh4zw3jlmkpdllf1aw75kfpwfis9lwzsy71vkx3ib\n"
    "public-encrypt\t4.0.3\thttps://registry.npmjs.org/public-encrypt/-/public-encrypt-4.0.3.tgz\t0jq1q88z1g159pdj5c3s398g3i9sksphc1xia4s69gx76jhfq3kz\n"
    "pump\t2.0.1\thttps://registry.npmjs.org/pump/-/pump-2.0.1.tgz\t1avn9ffbq4ma8xpqssjzb959bmq62446k8zivycs10h5q4aql3am\n"
    "pump\t3.0.0\thttps://registry.npmjs.org/pump/-/pump-3.0.0.tgz\t1vq58w7663jdwlsks9qbzga0bsca11il5x04w9q2q0qlllb14k41\n"
    "pumpify\t1.5.1\thttps://registry.npmjs.org/pumpify/-/pumpify-1.5.1.tgz\t011f5vrafyngr4gp80ncdm4k77zvbgng3925pvsq29v3axrfhg3c\n"
    "punycode\t1.3.2\thttps://registry.npmjs.org/punycode/-/punycode-1.3.2.tgz\t171107x5m9g0i3sqwl2k160sw5rkl3cskdl3jbnb9prh1mv2h3am\n"
    "punycode\t1.4.1\thttps://registry.npmjs.org/punycode/-/punycode-1.4.1.tgz\t12gdim25jn0g82kqql0qb44kjf8gbwzhcy8wf53vq56ad5rwlas5\n"
    "punycode\t2.1.1\thttps://registry.npmjs.org/punycode/-/punycode-2.1.1.tgz\t0g7z0kdxs15jrcijwbka2jajgr4b7bvpa6xmrcs0wf82pxwx1k75\n"
    "qs\t6.5.2\thttps://registry.npmjs.org/qs/-/qs-6.5.2.tgz\t1w0n5rg0w76b97ds80svkhmcqzcn76c3g5z81sblvii89ww4k4sk\n"
    "querystring-es3\t0.2.1\thttps://registry.npmjs.org/querystring-es3/-/querystring-es3-0.2.1.tgz\t0gi8dwjxni9waygxwdp6jq2gv94ad1vsmhfn4aq7md477bz8k8z5\n"
    "querystring\t0.2.0\thttps://registry.npmjs.org/querystring/-/querystring-0.2.0.tgz\t0szhjxbrj3xyqnad5li731qc7hk1xk43z7jss1m7bgmpp2n5sj3r\n"
    "randombytes\t2.1.0\thttps://registry.npmjs.org/randombytes/-/randombytes-2.1.0.tgz\t1amws6pwpznpl6d58rsi3aa2cl779gkb1jysscm925r8agkd79mq\n"
    "randomfill\t1.0.4\thttps://registry.npmjs.org/randomfill/-/randomfill-1.0.4.tgz\t19jgfpgf0c0smavmwljk525drngzw0162q33jl9jwmvaazn2y31v\n"
    "raw-loader\t4.0.2\thttps://registry.npmjs.org/raw-loader/-/raw-loader-4.0.2.tgz\t0k67pin5pp8jhf17f0iiv8mgn2kwi2mq41dy84dsxlanajk7vcjw\n"
    "readable-stream\t2.3.7\thttps://registry.npmjs.org/readable-stream/-/readable-stream-2.3.7.tgz\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\n"
    "readable-stream\t3.6.0\thttps://registry.npmjs.org/readable-stream/-/readable-stream-3.6.0.tgz\t1fy6kya4g3zwjdc0xfg7gdzg9ynqnqzv9ay301ay174vvp9202ak\n"
    "readdirp\t2.2.1\thttps://registry.npmjs.org/readdirp/-/readdirp-2.2.1.tgz\t18vnhdirs6khbbzwfkclgff6yqdhb55gs0bp3p9k41lpq2fk18n9\n"
    "readdirp\t3.5.0\thttps://registry.npmjs.org/readdirp/-/readdirp-3.5.0.tgz\t0gn9cs4b35jrav862cjg27pdb664692jlnh1bqxnvvkysbaz2w8j\n"
    "regex-not\t1.0.2\thttps://registry.npmjs.org/regex-not/-/regex-not-1.0.2.tgz\t0xpjprkrk0c9fn6yhqay3bm8vw44k197smcfby89g3sfjsxlhi7s\n"
    "remove-strict-webpack-plugin\t0.1.2\thttps://registry.npmjs.org/remove-strict-webpack-plugin/-/remove-strict-webpack-plugin-0.1.2.tgz\t0y7ayjmbmbx6b68iva3xn3lvcjd9l3hl0c3n2yp3r2j1ch8ydazd\n"
    "remove-trailing-separator\t1.1.0\thttps://registry.npmjs.org/remove-trailing-separator/-/remove-trailing-separator-1.1.0.tgz\t08b3msz9s5kw1alivgn9saaz6w04grjqppkdk3qbr7blk38l04sf\n"
    "repeat-element\t1.1.4\thttps://registry.npmjs.org/repeat-element/-/repeat-element-1.1.4.tgz\t0iy9kfkd7dj9lh1pk7ffq8yxh4v0kb96azkj7yg0g9p34bab0vrn\n"
    "repeat-string\t1.6.1\thttps://registry.npmjs.org/repeat-string/-/repeat-string-1.6.1.tgz\t1zmlk22rp97i5yfxqlb9hix87zlznngd60pm8qwhcg6bssacpq8b\n"
    "require-directory\t2.1.1\thttps://registry.npmjs.org/require-directory/-/require-directory-2.1.1.tgz\t1j46ydacaai73mx5krskl0k78r32lnjx94l79bz860rn8h4fwfvh\n"
    "require-main-filename\t2.0.0\thttps://registry.npmjs.org/require-main-filename/-/require-main-filename-2.0.0.tgz\t004f896jmh9di8kd5ypszhpk6yzbdsx0lz5cqb3r2q7v31imdfy5\n"
    "resolve-cwd\t2.0.0\thttps://registry.npmjs.org/resolve-cwd/-/resolve-cwd-2.0.0.tgz\t1qmyxj0w9dg9avxyki81x4j5c1f554a3qjdgr80cmkbsqj0lqxj4\n"
    "resolve-dir\t1.0.1\thttps://registry.npmjs.org/resolve-dir/-/resolve-dir-1.0.1.tgz\t1bzapdz97xgh7ahvap1c2n0lrh2mwra7jxfx4iym5d3mr4wc5a7j\n"
    "resolve-from\t3.0.0\thttps://registry.npmjs.org/resolve-from/-/resolve-from-3.0.0.tgz\t1ghppacmmjwrw5xx80qr19ap1wpizrrl8dbljj0yn87mnn6pr98k\n"
    "resolve-url\t0.2.1\thttps://registry.npmjs.org/resolve-url/-/resolve-url-0.2.1.tgz\t090qal7agjs8d6x98jrf0wzgx5j85ksbkb3c85f14wv3idbwpsc8\n"
    "ret\t0.1.15\thttps://registry.npmjs.org/ret/-/ret-0.1.15.tgz\t1zk9xw3jzs7di9b31sxg3fi0mljac8w09k0q6m6y311i1fsn4x2a\n"
    "rimraf\t2.7.1\thttps://registry.npmjs.org/rimraf/-/rimraf-2.7.1.tgz\t0g1grvjh2bpjpalqszzprh6hvnlvab9pmqa137yslysbv6g4x7h0\n"
    "ripemd160\t2.0.2\thttps://registry.npmjs.org/ripemd160/-/ripemd160-2.0.2.tgz\t1flldwzwhvdbzlq40g6mazrq2yvm73z4vi5z9llpy5dq5r8kqja4\n"
    "run-queue\t1.0.3\thttps://registry.npmjs.org/run-queue/-/run-queue-1.0.3.tgz\t05dgwj5jdv0z4g3vxh9p7pgy0glgvvwv0yvv85x5d8hgpy469a0s\n"
    "safe-buffer\t5.1.2\thttps://registry.npmjs.org/safe-buffer/-/safe-buffer-5.1.2.tgz\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\n"
    "safe-buffer\t5.2.1\thttps://registry.npmjs.org/safe-buffer/-/safe-buffer-5.2.1.tgz\t1s5kvjpwqsc682zcy71h9c6pxla21sysfwj270x6jjkca421h62x\n"
    "safe-regex\t1.1.0\thttps://registry.npmjs.org/safe-regex/-/safe-regex-1.1.0.tgz\t1lkcz58mjp3nfdiydh4iynpcfgxhf5mr339swzi5k05sikx8j4k2\n"
    "safer-buffer\t2.1.2\thttps://registry.npmjs.org/safer-buffer/-/safer-buffer-2.1.2.tgz\t1cx383s7vchfac8jlg3mnb820hkgcvhcpfn9w4f0g61vmrjjz0bq\n"
    "schema-utils\t1.0.0\thttps://registry.npmjs.org/schema-utils/-/schema-utils-1.0.0.tgz\t0hmyhgs4xvqldc9c4y96xjaf2g3z22yirgpwk9lk6j7zxcq9chjx\n"
    "schema-utils\t3.0.0\thttps://registry.npmjs.org/schema-utils/-/schema-utils-3.0.0.tgz\t0r53kd86nfzwmddfmk058xa5r4fcyibnb49xm8zma32akpbmvfz1\n"
    "semver\t5.7.1\thttps://registry.npmjs.org/semver/-/semver-5.7.1.tgz\t0vdmbm9s15r8m8n65qs9fhccn5a6v1ln8crlx312iz17m8rgpwpy\n"
    "semver\t7.3.5\thttps://registry.npmjs.org/semver/-/semver-7.3.5.tgz\t17jrlrwq1fm80pl54lmra4zpj8crr3y7kj031fhq02g274j807xg\n"
    "serialize-javascript\t4.0.0\thttps://registry.npmjs.org/serialize-javascript/-/serialize-javascript-4.0.0.tgz\t0lnkd1hj3sdi0b5fvsphj4dv8v1kbl0s9idnw5c6fc28knxfza29\n"
    "set-blocking\t2.0.0\thttps://registry.npmjs.org/set-blocking/-/set-blocking-2.0.0.tgz\t0gb9mvv8bjfavsxlzq56189qis7z2lrp893px04xl2cyvgkswd6r\n"
    "set-value\t2.0.1\thttps://registry.npmjs.org/set-value/-/set-value-2.0.1.tgz\t0qbp2ndx2qmmn6i7y92lk8jaj79cv36gpv9lq29lgw52wr6jbrl0\n"
    "setimmediate\t1.0.5\thttps://registry.npmjs.org/setimmediate/-/setimmediate-1.0.5.tgz\t17icj9sgsg9fcyclds1a8mlgmspza3fa6sidq11fsr43d4igrfaw\n"
    "sha.js\t2.4.11\thttps://registry.npmjs.org/sha.js/-/sha.js-2.4.11.tgz\t0jbcsfw4xzr4vfdfaxa953pwigjh1xi0ixkcab3r7lzdyxyz5k53\n"
    "shebang-command\t1.2.0\thttps://registry.npmjs.org/shebang-command/-/shebang-command-1.2.0.tgz\t1xz1gpsia9137vsm4zx3jda6wl72641djg5nk5g8b9vzssp88rg5\n"
    "shebang-regex\t1.0.0\thttps://registry.npmjs.org/shebang-regex/-/shebang-regex-1.0.0.tgz\t0wf6hlgf5b2mn2zydi5nn23cpgpjkdpi6q9xaqdwa8b6ir714vv7\n"
    "snapdragon-node\t2.1.1\thttps://registry.npmjs.org/snapdragon-node/-/snapdragon-node-2.1.1.tgz\t0idm24bf2jvwgqi8fx1fkn1w78ylqnpm137s2m0g0ni43y19i97j\n"
    "snapdragon-util\t3.0.1\thttps://registry.npmjs.org/snapdragon-util/-/snapdragon-util-3.0.1.tgz\t0c4fcrilagmpsrhh4mjfj7ah0vdxwkm9a4h5658bj8m7machxm2f\n"
    "snapdragon\t0.8.2\thttps://registry.npmjs.org/snapdragon/-/snapdragon-0.8.2.tgz\t1anpibb0ajgw2yv400aq30bvvpcyi3yzyrp7fac2ia6r7ysxcgvq\n"
    "source-list-map\t2.0.1\thttps://registry.npmjs.org/source-list-map/-/source-list-map-2.0.1.tgz\t05y2x4d7sy6dsna49qi2kbwzk2myijiadpzz9dxvfanvpmyidnyl\n"
    "source-map-resolve\t0.5.3\thttps://registry.npmjs.org/source-map-resolve/-/source-map-resolve-0.5.3.tgz\t1a9ykfyqnzxmna8i3f20g9pqcjzwx1f3wqwaa0bn6jwgmvwcvdj4\n"
    "source-map-support\t0.5.19\thttps://registry.npmjs.org/source-map-support/-/source-map-support-0.5.19.tgz\t116k5r9cfgjs70j7xwf49n5gzh173sjmcmpam1823szma0fac54l\n"
    "source-map-url\t0.4.1\thttps://registry.npmjs.org/source-map-url/-/source-map-url-0.4.1.tgz\t10c201qd0ik7n9dyliaypczj4jraalg6lj3ky27y052kyngqa1cc\n"
    "source-map\t0.5.7\thttps://registry.npmjs.org/source-map/-/source-map-0.5.7.tgz\t0rvb24j4kfib26w3cjyl6yan2dxvw1iy7d0wl404y5ckqjdjipp1\n"
    "source-map\t0.6.1\thttps://registry.npmjs.org/source-map/-/source-map-0.6.1.tgz\t11ib173i7xf5sd85da9jfrcbzygr48pppz5csl15hnpz2w6s3g5x\n"
    "split-string\t3.1.0\thttps://registry.npmjs.org/split-string/-/split-string-3.1.0.tgz\t1bx5n7bga42bd5d804w7y06wx96qk524gylxl4xi3i8nb8ch86na\n"
    "ssri\t6.0.2\thttps://registry.npmjs.org/ssri/-/ssri-6.0.2.tgz\t037vzhsdys2hns4j4pd2986swrnysfvljs8dhf0yir65i6g1hqdl\n"
    "static-extend\t0.1.2\thttps://registry.npmjs.org/static-extend/-/static-extend-0.1.2.tgz\t1hwg7diq3kg6q7d2ymj423562yx6nfdqlym538s6ca02zxjgi7nl\n"
    "stream-browserify\t2.0.2\thttps://registry.npmjs.org/stream-browserify/-/stream-browserify-2.0.2.tgz\t0rqljbnx9mhx3cwm8pfl5vvvm0v8igcfk5r3c2lgg4gnxrb755qv\n"
    "stream-each\t1.2.3\thttps://registry.npmjs.org/stream-each/-/stream-each-1.2.3.tgz\t1yn78c1ny7fhsm1x4fnxh5vb3x3g961gdiy8h9w9zknqwrzk5rxs\n"
    "stream-http\t2.8.3\thttps://registry.npmjs.org/stream-http/-/stream-http-2.8.3.tgz\t1gl13d210vlhkv781qbf2ciqzh6fph3n1dp4djccnm4n26yynyn1\n"
    "stream-shift\t1.0.1\thttps://registry.npmjs.org/stream-shift/-/stream-shift-1.0.1.tgz\t198hlf0k8mjiym0hc0913h2c9y00zk7px28sakd4lg8dggddppyb\n"
    "string-width\t3.1.0\thttps://registry.npmjs.org/string-width/-/string-width-3.1.0.tgz\t0ghs9i7a6nfrkcasbaal1mnhr1dyyih6nvf1cbn8mdkx443jg8kb\n"
    "string_decoder\t1.1.1\thttps://registry.npmjs.org/string_decoder/-/string_decoder-1.1.1.tgz\t0fln2r91b8gj845j7jl76fvsp7nij13fyzvz82985yh88m1n50mg\n"
    "strip-ansi\t5.2.0\thttps://registry.npmjs.org/strip-ansi/-/strip-ansi-5.2.0.tgz\t0lkxswqbij14y7savki6k14wil1z1l0fy1y0jv1fjfk6lw5w797v\n"
    "supports-color\t5.5.0\thttps://registry.npmjs.org/supports-color/-/supports-color-5.5.0.tgz\t1ap0lk4n0m3948cnkfmyz71pizqlzjdfrhs0f954pksg4jnk52h5\n"
    "supports-color\t6.1.0\thttps://registry.npmjs.org/supports-color/-/supports-color-6.1.0.tgz\t005xd8wpqyqsn8payk6zxky526paa480pyd4qywf7s11vna54mf8\n"
    "supports-color\t7.2.0\thttps://registry.npmjs.org/supports-color/-/supports-color-7.2.0.tgz\t0jjyglzdzscmhgidn43zc218q5jf9h03hmaaq9h4wqil2vywlspi\n"
    "sync-request\t6.1.0\thttps://registry.npmjs.org/sync-request/-/sync-request-6.1.0.tgz\t13zbfnwvx94af4qn9y73rr4nk9pw5f4gvg773gssrk68vlpa2gny\n"
    "sync-rpc\t1.3.6\thttps://registry.npmjs.org/sync-rpc/-/sync-rpc-1.3.6.tgz\t1c5ad2m4nk9wmv1kz0vgxjzf04wqpbp3iwna19a14k6z5mm7jjfm\n"
    "tapable\t1.1.3\thttps://registry.npmjs.org/tapable/-/tapable-1.1.3.tgz\t0i40yykqy3slqw06v4s0pg5yl25bv5gn0144z2d23ssfy3305j3b\n"
    "terser-webpack-plugin\t1.4.5\thttps://registry.npmjs.org/terser-webpack-plugin/-/terser-webpack-plugin-1.4.5.tgz\t0xpb13xabfvy57g8zi7v0c26xn56r3kbsya6m0r8y38g0xxvlfhp\n"
    "terser\t4.8.0\thttps://registry.npmjs.org/terser/-/terser-4.8.0.tgz\t0wf5labb7fv684ajg2mf2rbj2h1va7f7cz0ks91gll6i7nc0fbgs\n"
    "then-request\t6.0.2\thttps://registry.npmjs.org/then-request/-/then-request-6.0.2.tgz\t1hn1kcs08axhql1xzhk2yzjw8dl88b6inm29qqdw9i03yk6kfvv6\n"
    "through2\t2.0.5\thttps://registry.npmjs.org/through2/-/through2-2.0.5.tgz\t1ff3m5b2lzy7v69dq1ab2wxpp38m6dw5yziqp7mp2spxmx7hg9wx\n"
    "timers-browserify\t2.0.12\thttps://registry.npmjs.org/timers-browserify/-/timers-browserify-2.0.12.tgz\t0chlg4h6s6hj6kgrsvwz7l2srx9p5ghld8x22mamcv7kn4lapmai\n"
    "to-arraybuffer\t1.0.1\thttps://registry.npmjs.org/to-arraybuffer/-/to-arraybuffer-1.0.1.tgz\t18jagcl8bl5lmw5b39fp0kq2gf6jz1kgxj54z4a3ghxdrpgqxbj9\n"
    "to-object-path\t0.3.0\thttps://registry.npmjs.org/to-object-path/-/to-object-path-0.3.0.tgz\t01n40v8xlqm635rp6cyz0jpw6295wm9fkr6m85nqcf457rfbqc68\n"
    "to-regex-range\t2.1.1\thttps://registry.npmjs.org/to-regex-range/-/to-regex-range-2.1.1.tgz\t0rw8mjvncwxhyg5m7mzwqg16ddpyq5qzdwds0v0jnskqhklh14bq\n"
    "to-regex-range\t5.0.1\thttps://registry.npmjs.org/to-regex-range/-/to-regex-range-5.0.1.tgz\t1ms2bgz2paqfpjv1xpwx67i3dns5j9gn99il6cx5r4qaq9g2afm6\n"
    "to-regex\t3.0.2\thttps://registry.npmjs.org/to-regex/-/to-regex-3.0.2.tgz\t039l28qygjrjy10jz9cm3j066nw5fkfimzkp5ipq47w2pl2ii0w6\n"
    "ts-loader\t8.3.0\thttps://registry.npmjs.org/ts-loader/-/ts-loader-8.3.0.tgz\t155pcqag2dj70mx961l2xpd573d7vjhnwk430v0xbvkllliwiqkg\n"
    "tty-browserify\t0.0.0\thttps://registry.npmjs.org/tty-browserify/-/tty-browserify-0.0.0.tgz\t0bhs32ld33fbpnvs2rm4l4y67byvsh6jmzplq4jvgrqny73084ii\n"
    "typedarray\t0.0.6\thttps://registry.npmjs.org/typedarray/-/typedarray-0.0.6.tgz\t022101ap05mryhpyw33phwyamk1i139qqpn2rs2lq72qm5slnciz\n"
    "typescript\t4.2.4\thttps://registry.npmjs.org/typescript/-/typescript-4.2.4.tgz\t00996d3lxnphx52rk5kvyc64wcc0qqm6a8p0fhqci4vd56a9gvbf\n"
    "union-value\t1.0.1\thttps://registry.npmjs.org/union-value/-/union-value-1.0.1.tgz\t00rjw4hvxnj5vrji9qzbxn6y9rx6av1q3nv8ilyxpska3q0zpj75\n"
    "unique-filename\t1.1.1\thttps://registry.npmjs.org/unique-filename/-/unique-filename-1.1.1.tgz\t1dcfh15m1cjiqm4fapjws8inzydklx3jhbaflma2qcx7s9ax14av\n"
    "unique-slug\t2.0.2\thttps://registry.npmjs.org/unique-slug/-/unique-slug-2.0.2.tgz\t1z85ywz4zz0g8b8l2mkcn70yli30w7zj424hlikdymxb5k6ifvxl\n"
    "universalify\t0.1.2\thttps://registry.npmjs.org/universalify/-/universalify-0.1.2.tgz\t0lykbpkmvjkjg0sqngrn086rxlyddgjkfnsi22r8hgixxzxb2alc\n"
    "unset-value\t1.0.0\thttps://registry.npmjs.org/unset-value/-/unset-value-1.0.0.tgz\t11jj8ggkz8c54sf0zyqwlnwv89i5gj572ywbry7ispy6lqa84qsk\n"
    "upath\t1.2.0\thttps://registry.npmjs.org/upath/-/upath-1.2.0.tgz\t040xl5lszqz6akkszybz4rnmm5s3x3fc59mcs8fvyxy6wzp9rvbk\n"
    "uri-js\t4.4.1\thttps://registry.npmjs.org/uri-js/-/uri-js-4.4.1.tgz\t0bcdxkngap84iv7hpfa4r18i3a3allxfh6dmcqzafgg8mx9dw4jn\n"
    "urix\t0.1.0\thttps://registry.npmjs.org/urix/-/urix-0.1.0.tgz\t19qmq8cra96cf7ji8d4ljfcgnazzrvw4lcxlf91jk1816ndx1pbm\n"
    "url\t0.11.0\thttps://registry.npmjs.org/url/-/url-0.11.0.tgz\t1rjnjgf6gn19lw94ksfsm8p9gbpra98lgg8rsqd8xa4fsqx2lkmw\n"
    "use\t3.1.1\thttps://registry.npmjs.org/use/-/use-3.1.1.tgz\t1nqrazqb927s0nma2qi2c3aambpy34krz8cgl6610n456zg5vjin\n"
    "util-deprecate\t1.0.2\thttps://registry.npmjs.org/util-deprecate/-/util-deprecate-1.0.2.tgz\t1rd3qbgdrwkmcrf7vqx61sh7icma7jvxcmklqj032f8v7jcdx8br\n"
    "util\t0.10.3\thttps://registry.npmjs.org/util/-/util-0.10.3.tgz\t1l6n7pmfwcnx5c9f920n6cy918nh12c1xwkvkn8w7cw1m703l0w8\n"
    "util\t0.11.1\thttps://registry.npmjs.org/util/-/util-0.11.1.tgz\t053virfmxmmi9c6dh04ipqgca6s9i3m9vp7y98577pcfhy3bbb9i\n"
    "v8-compile-cache\t2.3.0\thttps://registry.npmjs.org/v8-compile-cache/-/v8-compile-cache-2.3.0.tgz\t0gwiizwmwzlzaaazw4hn4xsdfrlqk19fqbqqad6i9xfayg16qzlj\n"
    "vm-browserify\t1.1.2\thttps://registry.npmjs.org/vm-browserify/-/vm-browserify-1.1.2.tgz\t0ihacds0jqql7zq97p1bg69a24fg526m57w6h2vhhv604cs3y4sn\n"
    "watchpack-chokidar2\t2.0.1\thttps://registry.npmjs.org/watchpack-chokidar2/-/watchpack-chokidar2-2.0.1.tgz\t1s9mf5vx729p8l6d2v9iwyflj5ph7zjz8f27ms0wvgkmiwz57p6l\n"
    "watchpack\t1.7.5\thttps://registry.npmjs.org/watchpack/-/watchpack-1.7.5.tgz\t1nwiy7cs8aw8q1alxinyxbna27qilvsk1hqkrqw8i4slly4gl5fs\n"
    "webpack-cli\t3.3.12\thttps://registry.npmjs.org/webpack-cli/-/webpack-cli-3.3.12.tgz\t1c9wbasv1jgaqyhqsj2yn5ig3aradh9p4z6yfkpmmxgj792pl9ph\n"
    "webpack-sources\t1.4.3\thttps://registry.npmjs.org/webpack-sources/-/webpack-sources-1.4.3.tgz\t18d4w9fzmm9ghcspr681w40wf2cjranzj7dyfkvf0iw3jby75pz8\n"
    "webpack\t4.46.0\thttps://registry.npmjs.org/webpack/-/webpack-4.46.0.tgz\t1h58zk22jycsr827ldcr27xnixdkn1qs7j8s8zhlan7jms1ji8lj\n"
    "which-module\t2.0.0\thttps://registry.npmjs.org/which-module/-/which-module-2.0.0.tgz\t1si822gi00hkvx9ny5mqb202jmi1xskk20hlrw53dygbw7xi5gsg\n"
    "which\t1.3.1\thttps://registry.npmjs.org/which/-/which-1.3.1.tgz\t077d08k2zz1zhn5nc09m4vkiz2hjfk2lp02a3kphhianj3b26rcn\n"
    "worker-farm\t1.7.0\thttps://registry.npmjs.org/worker-farm/-/worker-farm-1.7.0.tgz\t18v2ip8sjfg5cn5jib2pcrcgxkdzkwa4icmrx46j6fblpzdvr6z5\n"
    "wrap-ansi\t5.1.0\thttps://registry.npmjs.org/wrap-ansi/-/wrap-ansi-5.1.0.tgz\t16c4ff4ba7xpz78xf2pxva0lhfdyan0xl60xb9yxvxxz2bjm9vn1\n"
    "wrappy\t1.0.2\thttps://registry.npmjs.org/wrappy/-/wrappy-1.0.2.tgz\t1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg\n"
    "xtend\t4.0.2\thttps://registry.npmjs.org/xtend/-/xtend-4.0.2.tgz\t0j5s840a0a3mjzxixr95jpila80kbdvrxyixnmxvx6f78cfs08mx\n"
    "y18n\t4.0.3\thttps://registry.npmjs.org/y18n/-/y18n-4.0.3.tgz\t1kqfcsvcf3va9nsfs4c1x6jyk9svw01nz8i8fakrnhh1k1270jdw\n"
    "yallist\t3.1.1\thttps://registry.npmjs.org/yallist/-/yallist-3.1.1.tgz\t016afm3iv7pfrg9nj7952dph6sg00lryk8wv4nr0qdp8rzk4mwah\n"
    "yallist\t4.0.0\thttps://registry.npmjs.org/yallist/-/yallist-4.0.0.tgz\t0jadz9mh1lzfk19bvqqlrg40ggfk2yyfyrpgj5c62dk54ym7h358\n"
    "yargs-parser\t13.1.2\thttps://registry.npmjs.org/yargs-parser/-/yargs-parser-13.1.2.tgz\t170m69i81kvz7pky8gqmbylqj6ni0symjihyilz41l82ip6f6jng\n"
    "yargs\t13.3.2\thttps://registry.npmjs.org/yargs/-/yargs-13.3.2.tgz\t0zi8xw2m9zzn6f7mwyjnzwgn4nm512i3siv63n3gmw0kilb6r8z1\n"
    ))

;; Exact upstream dependency locations, not a flattening by package name.
(define %wenyan-npm-path-keys
  '(
    ("node_modules/@types/concat-stream" . "@types/concat-stream@1.6.0")
    ("node_modules/@types/detect-indent" . "@types/detect-indent@0.1.30")
    ("node_modules/@types/form-data" . "@types/form-data@0.0.33")
    ("node_modules/@types/glob" . "@types/glob@5.0.30")
    ("node_modules/@types/json-schema" . "@types/json-schema@7.0.7")
    ("node_modules/@types/minimatch" . "@types/minimatch@3.0.4")
    ("node_modules/@types/mkdirp" . "@types/mkdirp@0.3.29")
    ("node_modules/@types/node" . "@types/node@15.12.2")
    ("node_modules/@types/qs" . "@types/qs@6.9.6")
    ("node_modules/@types/webpack-env" . "@types/webpack-env@1.16.0")
    ("node_modules/@webassemblyjs/ast" . "@webassemblyjs/ast@1.9.0")
    ("node_modules/@webassemblyjs/floating-point-hex-parser" . "@webassemblyjs/floating-point-hex-parser@1.9.0")
    ("node_modules/@webassemblyjs/helper-api-error" . "@webassemblyjs/helper-api-error@1.9.0")
    ("node_modules/@webassemblyjs/helper-buffer" . "@webassemblyjs/helper-buffer@1.9.0")
    ("node_modules/@webassemblyjs/helper-code-frame" . "@webassemblyjs/helper-code-frame@1.9.0")
    ("node_modules/@webassemblyjs/helper-fsm" . "@webassemblyjs/helper-fsm@1.9.0")
    ("node_modules/@webassemblyjs/helper-module-context" . "@webassemblyjs/helper-module-context@1.9.0")
    ("node_modules/@webassemblyjs/helper-wasm-bytecode" . "@webassemblyjs/helper-wasm-bytecode@1.9.0")
    ("node_modules/@webassemblyjs/helper-wasm-section" . "@webassemblyjs/helper-wasm-section@1.9.0")
    ("node_modules/@webassemblyjs/ieee754" . "@webassemblyjs/ieee754@1.9.0")
    ("node_modules/@webassemblyjs/leb128" . "@webassemblyjs/leb128@1.9.0")
    ("node_modules/@webassemblyjs/utf8" . "@webassemblyjs/utf8@1.9.0")
    ("node_modules/@webassemblyjs/wasm-edit" . "@webassemblyjs/wasm-edit@1.9.0")
    ("node_modules/@webassemblyjs/wasm-gen" . "@webassemblyjs/wasm-gen@1.9.0")
    ("node_modules/@webassemblyjs/wasm-opt" . "@webassemblyjs/wasm-opt@1.9.0")
    ("node_modules/@webassemblyjs/wasm-parser" . "@webassemblyjs/wasm-parser@1.9.0")
    ("node_modules/@webassemblyjs/wast-parser" . "@webassemblyjs/wast-parser@1.9.0")
    ("node_modules/@webassemblyjs/wast-printer" . "@webassemblyjs/wast-printer@1.9.0")
    ("node_modules/@xtuc/ieee754" . "@xtuc/ieee754@1.2.0")
    ("node_modules/@xtuc/long" . "@xtuc/long@4.2.2")
    ("node_modules/ajv" . "ajv@6.12.6")
    ("node_modules/ajv-errors" . "ajv-errors@1.0.1")
    ("node_modules/ajv-keywords" . "ajv-keywords@3.5.2")
    ("node_modules/ansi-regex" . "ansi-regex@4.1.0")
    ("node_modules/ansi-styles" . "ansi-styles@3.2.1")
    ("node_modules/anymatch" . "anymatch@2.0.0")
    ("node_modules/aproba" . "aproba@1.2.0")
    ("node_modules/arr-diff" . "arr-diff@4.0.0")
    ("node_modules/arr-flatten" . "arr-flatten@1.1.0")
    ("node_modules/arr-union" . "arr-union@3.1.0")
    ("node_modules/array-unique" . "array-unique@0.3.2")
    ("node_modules/asap" . "asap@2.0.6")
    ("node_modules/asn1.js" . "asn1.js@5.4.1")
    ("node_modules/asn1.js/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/assert" . "assert@1.5.0")
    ("node_modules/assert/node_modules/inherits" . "inherits@2.0.1")
    ("node_modules/assert/node_modules/util" . "util@0.10.3")
    ("node_modules/assign-symbols" . "assign-symbols@1.0.0")
    ("node_modules/async-each" . "async-each@1.0.3")
    ("node_modules/asynckit" . "asynckit@0.4.0")
    ("node_modules/atob" . "atob@2.1.2")
    ("node_modules/balanced-match" . "balanced-match@1.0.2")
    ("node_modules/base" . "base@0.11.2")
    ("node_modules/base/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/base/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/base64-js" . "base64-js@1.5.1")
    ("node_modules/big.js" . "big.js@5.2.2")
    ("node_modules/binary-extensions" . "binary-extensions@2.2.0")
    ("node_modules/bluebird" . "bluebird@3.7.2")
    ("node_modules/bn.js" . "bn.js@5.2.0")
    ("node_modules/brace-expansion" . "brace-expansion@1.1.11")
    ("node_modules/braces" . "braces@2.3.2")
    ("node_modules/braces/node_modules/fill-range" . "fill-range@4.0.0")
    ("node_modules/braces/node_modules/is-number" . "is-number@3.0.0")
    ("node_modules/braces/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/brorand" . "brorand@1.1.0")
    ("node_modules/browserify-aes" . "browserify-aes@1.2.0")
    ("node_modules/browserify-cipher" . "browserify-cipher@1.0.1")
    ("node_modules/browserify-des" . "browserify-des@1.0.2")
    ("node_modules/browserify-rsa" . "browserify-rsa@4.1.0")
    ("node_modules/browserify-sign" . "browserify-sign@4.2.1")
    ("node_modules/browserify-sign/node_modules/readable-stream" . "readable-stream@3.6.0")
    ("node_modules/browserify-sign/node_modules/safe-buffer" . "safe-buffer@5.2.1")
    ("node_modules/browserify-zlib" . "browserify-zlib@0.2.0")
    ("node_modules/buffer" . "buffer@4.9.2")
    ("node_modules/buffer-from" . "buffer-from@1.1.1")
    ("node_modules/buffer-xor" . "buffer-xor@1.0.3")
    ("node_modules/builtin-status-codes" . "builtin-status-codes@3.0.0")
    ("node_modules/cacache" . "cacache@12.0.4")
    ("node_modules/cacache/node_modules/lru-cache" . "lru-cache@5.1.1")
    ("node_modules/cacache/node_modules/rimraf" . "rimraf@2.7.1")
    ("node_modules/cacache/node_modules/yallist" . "yallist@3.1.1")
    ("node_modules/cache-base" . "cache-base@1.0.1")
    ("node_modules/cache-base/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/camelcase" . "camelcase@5.3.1")
    ("node_modules/caseless" . "caseless@0.12.0")
    ("node_modules/chalk" . "chalk@2.4.2")
    ("node_modules/chokidar" . "chokidar@3.5.1")
    ("node_modules/chokidar/node_modules/anymatch" . "anymatch@3.1.2")
    ("node_modules/chokidar/node_modules/braces" . "braces@3.0.2")
    ("node_modules/chokidar/node_modules/fill-range" . "fill-range@7.0.1")
    ("node_modules/chokidar/node_modules/is-number" . "is-number@7.0.0")
    ("node_modules/chokidar/node_modules/normalize-path" . "normalize-path@3.0.0")
    ("node_modules/chokidar/node_modules/to-regex-range" . "to-regex-range@5.0.1")
    ("node_modules/chownr" . "chownr@1.1.4")
    ("node_modules/chrome-trace-event" . "chrome-trace-event@1.0.3")
    ("node_modules/cipher-base" . "cipher-base@1.0.4")
    ("node_modules/class-utils" . "class-utils@0.3.6")
    ("node_modules/class-utils/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/class-utils/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/class-utils/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/class-utils/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/class-utils/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/class-utils/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/cliui" . "cliui@5.0.0")
    ("node_modules/cliui/node_modules/emoji-regex" . "emoji-regex@7.0.3")
    ("node_modules/cliui/node_modules/is-fullwidth-code-point" . "is-fullwidth-code-point@2.0.0")
    ("node_modules/cliui/node_modules/string-width" . "string-width@3.1.0")
    ("node_modules/cliui/node_modules/wrap-ansi" . "wrap-ansi@5.1.0")
    ("node_modules/collection-visit" . "collection-visit@1.0.0")
    ("node_modules/color-convert" . "color-convert@1.9.3")
    ("node_modules/color-name" . "color-name@1.1.3")
    ("node_modules/combined-stream" . "combined-stream@1.0.8")
    ("node_modules/commander" . "commander@4.1.1")
    ("node_modules/commondir" . "commondir@1.0.1")
    ("node_modules/component-emitter" . "component-emitter@1.3.0")
    ("node_modules/concat-map" . "concat-map@0.0.1")
    ("node_modules/concat-stream" . "concat-stream@1.6.2")
    ("node_modules/consola" . "consola@2.15.3")
    ("node_modules/console-browserify" . "console-browserify@1.2.0")
    ("node_modules/constants-browserify" . "constants-browserify@1.0.0")
    ("node_modules/copy-concurrently" . "copy-concurrently@1.0.5")
    ("node_modules/copy-concurrently/node_modules/rimraf" . "rimraf@2.7.1")
    ("node_modules/copy-descriptor" . "copy-descriptor@0.1.1")
    ("node_modules/core-util-is" . "core-util-is@1.0.2")
    ("node_modules/create-ecdh" . "create-ecdh@4.0.4")
    ("node_modules/create-ecdh/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/create-hash" . "create-hash@1.2.0")
    ("node_modules/create-hmac" . "create-hmac@1.1.7")
    ("node_modules/cross-spawn" . "cross-spawn@6.0.5")
    ("node_modules/cross-spawn/node_modules/semver" . "semver@5.7.1")
    ("node_modules/crypto-browserify" . "crypto-browserify@3.12.0")
    ("node_modules/cyclist" . "cyclist@1.0.1")
    ("node_modules/decamelize" . "decamelize@1.2.0")
    ("node_modules/decode-uri-component" . "decode-uri-component@0.2.0")
    ("node_modules/define-property" . "define-property@2.0.2")
    ("node_modules/define-property/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/delayed-stream" . "delayed-stream@1.0.0")
    ("node_modules/des.js" . "des.js@1.0.1")
    ("node_modules/detect-file" . "detect-file@1.0.0")
    ("node_modules/detect-indent" . "detect-indent@0.2.0")
    ("node_modules/diffie-hellman" . "diffie-hellman@5.0.3")
    ("node_modules/diffie-hellman/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/domain-browser" . "domain-browser@1.2.0")
    ("node_modules/dts-bundle" . "dts-bundle@0.7.3")
    ("node_modules/dts-bundle/node_modules/@types/node" . "@types/node@8.0.0")
    ("node_modules/dts-bundle/node_modules/commander" . "commander@2.20.3")
    ("node_modules/dts-bundle/node_modules/glob" . "glob@6.0.4")
    ("node_modules/duplexify" . "duplexify@3.7.1")
    ("node_modules/elliptic" . "elliptic@6.5.4")
    ("node_modules/elliptic/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/emojis-list" . "emojis-list@3.0.0")
    ("node_modules/end-of-stream" . "end-of-stream@1.4.4")
    ("node_modules/enhanced-resolve" . "enhanced-resolve@4.5.0")
    ("node_modules/errno" . "errno@0.1.8")
    ("node_modules/escape-string-regexp" . "escape-string-regexp@1.0.5")
    ("node_modules/esrecurse" . "esrecurse@4.3.0")
    ("node_modules/esrecurse/node_modules/estraverse" . "estraverse@5.2.0")
    ("node_modules/estraverse" . "estraverse@4.3.0")
    ("node_modules/events" . "events@3.3.0")
    ("node_modules/evp_bytestokey" . "evp_bytestokey@1.0.3")
    ("node_modules/expand-brackets" . "expand-brackets@2.1.4")
    ("node_modules/expand-brackets/node_modules/debug" . "debug@2.6.9")
    ("node_modules/expand-brackets/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/expand-brackets/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/expand-brackets/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/expand-brackets/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/expand-brackets/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/expand-brackets/node_modules/ms" . "ms@2.0.0")
    ("node_modules/expand-tilde" . "expand-tilde@2.0.2")
    ("node_modules/extend-shallow" . "extend-shallow@2.0.1")
    ("node_modules/extglob" . "extglob@2.0.4")
    ("node_modules/extglob/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/fast-deep-equal" . "fast-deep-equal@3.1.3")
    ("node_modules/fast-json-stable-stringify" . "fast-json-stable-stringify@2.1.0")
    ("node_modules/figgy-pudding" . "figgy-pudding@3.5.2")
    ("node_modules/find-cache-dir" . "find-cache-dir@2.1.0")
    ("node_modules/find-cache-dir/node_modules/find-up" . "find-up@3.0.0")
    ("node_modules/find-cache-dir/node_modules/locate-path" . "locate-path@3.0.0")
    ("node_modules/find-cache-dir/node_modules/p-locate" . "p-locate@3.0.0")
    ("node_modules/find-cache-dir/node_modules/path-exists" . "path-exists@3.0.0")
    ("node_modules/find-cache-dir/node_modules/pkg-dir" . "pkg-dir@3.0.0")
    ("node_modules/find-up" . "find-up@4.1.0")
    ("node_modules/findup-sync" . "findup-sync@3.0.0")
    ("node_modules/flush-write-stream" . "flush-write-stream@1.1.1")
    ("node_modules/for-in" . "for-in@1.0.2")
    ("node_modules/form-data" . "form-data@2.3.3")
    ("node_modules/fragment-cache" . "fragment-cache@0.2.1")
    ("node_modules/from2" . "from2@2.3.0")
    ("node_modules/fs-extra" . "fs-extra@8.1.0")
    ("node_modules/fs-write-stream-atomic" . "fs-write-stream-atomic@1.0.10")
    ("node_modules/fs.realpath" . "fs.realpath@1.0.0")
    ("node_modules/get-caller-file" . "get-caller-file@2.0.5")
    ("node_modules/get-port" . "get-port@3.2.0")
    ("node_modules/get-stdin" . "get-stdin@0.1.0")
    ("node_modules/get-value" . "get-value@2.0.6")
    ("node_modules/glob" . "glob@7.1.7")
    ("node_modules/glob-parent" . "glob-parent@5.1.2")
    ("node_modules/global-modules" . "global-modules@2.0.0")
    ("node_modules/global-prefix" . "global-prefix@3.0.0")
    ("node_modules/global-prefix/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/graceful-fs" . "graceful-fs@4.2.6")
    ("node_modules/has-flag" . "has-flag@3.0.0")
    ("node_modules/has-value" . "has-value@1.0.0")
    ("node_modules/has-value/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/has-values" . "has-values@1.0.0")
    ("node_modules/has-values/node_modules/is-number" . "is-number@3.0.0")
    ("node_modules/has-values/node_modules/is-number/node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/has-values/node_modules/kind-of" . "kind-of@4.0.0")
    ("node_modules/hash-base" . "hash-base@3.1.0")
    ("node_modules/hash-base/node_modules/readable-stream" . "readable-stream@3.6.0")
    ("node_modules/hash-base/node_modules/safe-buffer" . "safe-buffer@5.2.1")
    ("node_modules/hash.js" . "hash.js@1.1.7")
    ("node_modules/hmac-drbg" . "hmac-drbg@1.0.1")
    ("node_modules/homedir-polyfill" . "homedir-polyfill@1.0.3")
    ("node_modules/http-basic" . "http-basic@8.1.3")
    ("node_modules/http-response-object" . "http-response-object@3.0.2")
    ("node_modules/http-response-object/node_modules/@types/node" . "@types/node@10.17.60")
    ("node_modules/https-browserify" . "https-browserify@1.0.0")
    ("node_modules/ieee754" . "ieee754@1.2.1")
    ("node_modules/iferr" . "iferr@0.1.5")
    ("node_modules/import-local" . "import-local@2.0.0")
    ("node_modules/import-local/node_modules/find-up" . "find-up@3.0.0")
    ("node_modules/import-local/node_modules/locate-path" . "locate-path@3.0.0")
    ("node_modules/import-local/node_modules/p-locate" . "p-locate@3.0.0")
    ("node_modules/import-local/node_modules/path-exists" . "path-exists@3.0.0")
    ("node_modules/import-local/node_modules/pkg-dir" . "pkg-dir@3.0.0")
    ("node_modules/imurmurhash" . "imurmurhash@0.1.4")
    ("node_modules/infer-owner" . "infer-owner@1.0.4")
    ("node_modules/inflight" . "inflight@1.0.6")
    ("node_modules/inherits" . "inherits@2.0.4")
    ("node_modules/ini" . "ini@1.3.7")
    ("node_modules/interpret" . "interpret@1.4.0")
    ("node_modules/is-accessor-descriptor" . "is-accessor-descriptor@1.0.0")
    ("node_modules/is-accessor-descriptor/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/is-binary-path" . "is-binary-path@2.1.0")
    ("node_modules/is-buffer" . "is-buffer@1.1.6")
    ("node_modules/is-data-descriptor" . "is-data-descriptor@1.0.0")
    ("node_modules/is-data-descriptor/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/is-descriptor" . "is-descriptor@1.0.2")
    ("node_modules/is-descriptor/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/is-extendable" . "is-extendable@0.1.1")
    ("node_modules/is-extglob" . "is-extglob@2.1.1")
    ("node_modules/is-glob" . "is-glob@4.0.1")
    ("node_modules/is-plain-object" . "is-plain-object@2.0.4")
    ("node_modules/is-plain-object/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/is-windows" . "is-windows@1.0.2")
    ("node_modules/is-wsl" . "is-wsl@1.1.0")
    ("node_modules/isarray" . "isarray@1.0.0")
    ("node_modules/isexe" . "isexe@2.0.0")
    ("node_modules/json-parse-better-errors" . "json-parse-better-errors@1.0.2")
    ("node_modules/json-schema-traverse" . "json-schema-traverse@0.4.1")
    ("node_modules/json5" . "json5@2.2.0")
    ("node_modules/json5/node_modules/minimist" . "minimist@1.2.5")
    ("node_modules/jsonfile" . "jsonfile@4.0.0")
    ("node_modules/kind-of" . "kind-of@3.2.2")
    ("node_modules/loader-runner" . "loader-runner@2.4.0")
    ("node_modules/loader-utils" . "loader-utils@2.0.0")
    ("node_modules/locate-path" . "locate-path@5.0.0")
    ("node_modules/lru-cache" . "lru-cache@6.0.0")
    ("node_modules/make-dir" . "make-dir@2.1.0")
    ("node_modules/make-dir/node_modules/semver" . "semver@5.7.1")
    ("node_modules/map-cache" . "map-cache@0.2.2")
    ("node_modules/map-visit" . "map-visit@1.0.0")
    ("node_modules/md5.js" . "md5.js@1.3.5")
    ("node_modules/memory-fs" . "memory-fs@0.5.0")
    ("node_modules/micromatch" . "micromatch@3.1.10")
    ("node_modules/micromatch/node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/micromatch/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/micromatch/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/miller-rabin" . "miller-rabin@4.0.1")
    ("node_modules/miller-rabin/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/mime-db" . "mime-db@1.48.0")
    ("node_modules/mime-types" . "mime-types@2.1.31")
    ("node_modules/minimalistic-assert" . "minimalistic-assert@1.0.1")
    ("node_modules/minimalistic-crypto-utils" . "minimalistic-crypto-utils@1.0.1")
    ("node_modules/minimatch" . "minimatch@3.0.4")
    ("node_modules/minimist" . "minimist@0.1.0")
    ("node_modules/mississippi" . "mississippi@3.0.0")
    ("node_modules/mixin-deep" . "mixin-deep@1.3.2")
    ("node_modules/mixin-deep/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/mkdirp" . "mkdirp@0.5.5")
    ("node_modules/mkdirp/node_modules/minimist" . "minimist@1.2.5")
    ("node_modules/move-concurrently" . "move-concurrently@1.0.1")
    ("node_modules/move-concurrently/node_modules/rimraf" . "rimraf@2.7.1")
    ("node_modules/nanomatch" . "nanomatch@1.2.13")
    ("node_modules/nanomatch/node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/nanomatch/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/nanomatch/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/neo-async" . "neo-async@2.6.2")
    ("node_modules/nice-try" . "nice-try@1.0.5")
    ("node_modules/node-libs-browser" . "node-libs-browser@2.2.1")
    ("node_modules/node-libs-browser/node_modules/punycode" . "punycode@1.4.1")
    ("node_modules/normalize-path" . "normalize-path@2.1.1")
    ("node_modules/object-assign" . "object-assign@4.1.1")
    ("node_modules/object-copy" . "object-copy@0.1.0")
    ("node_modules/object-copy/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/object-copy/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/object-copy/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/object-copy/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/object-copy/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/object-visit" . "object-visit@1.0.1")
    ("node_modules/object-visit/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/object.pick" . "object.pick@1.3.0")
    ("node_modules/object.pick/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/once" . "once@1.4.0")
    ("node_modules/os-browserify" . "os-browserify@0.3.0")
    ("node_modules/p-limit" . "p-limit@2.3.0")
    ("node_modules/p-locate" . "p-locate@4.1.0")
    ("node_modules/p-try" . "p-try@2.2.0")
    ("node_modules/pako" . "pako@1.0.11")
    ("node_modules/parallel-transform" . "parallel-transform@1.2.0")
    ("node_modules/parse-asn1" . "parse-asn1@5.1.6")
    ("node_modules/parse-cache-control" . "parse-cache-control@1.0.1")
    ("node_modules/parse-passwd" . "parse-passwd@1.0.0")
    ("node_modules/pascalcase" . "pascalcase@0.1.1")
    ("node_modules/path-browserify" . "path-browserify@0.0.1")
    ("node_modules/path-dirname" . "path-dirname@1.0.2")
    ("node_modules/path-exists" . "path-exists@4.0.0")
    ("node_modules/path-is-absolute" . "path-is-absolute@1.0.1")
    ("node_modules/path-key" . "path-key@2.0.1")
    ("node_modules/pbkdf2" . "pbkdf2@3.1.2")
    ("node_modules/picomatch" . "picomatch@2.3.0")
    ("node_modules/pify" . "pify@4.0.1")
    ("node_modules/posix-character-classes" . "posix-character-classes@0.1.1")
    ("node_modules/process" . "process@0.11.10")
    ("node_modules/process-nextick-args" . "process-nextick-args@2.0.1")
    ("node_modules/promise" . "promise@8.1.0")
    ("node_modules/promise-inflight" . "promise-inflight@1.0.1")
    ("node_modules/prr" . "prr@1.0.1")
    ("node_modules/public-encrypt" . "public-encrypt@4.0.3")
    ("node_modules/public-encrypt/node_modules/bn.js" . "bn.js@4.12.0")
    ("node_modules/pump" . "pump@3.0.0")
    ("node_modules/pumpify" . "pumpify@1.5.1")
    ("node_modules/pumpify/node_modules/pump" . "pump@2.0.1")
    ("node_modules/punycode" . "punycode@2.1.1")
    ("node_modules/qs" . "qs@6.5.2")
    ("node_modules/querystring" . "querystring@0.2.0")
    ("node_modules/querystring-es3" . "querystring-es3@0.2.1")
    ("node_modules/randombytes" . "randombytes@2.1.0")
    ("node_modules/randomfill" . "randomfill@1.0.4")
    ("node_modules/raw-loader" . "raw-loader@4.0.2")
    ("node_modules/readable-stream" . "readable-stream@2.3.7")
    ("node_modules/readdirp" . "readdirp@3.5.0")
    ("node_modules/regex-not" . "regex-not@1.0.2")
    ("node_modules/regex-not/node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/regex-not/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/remove-strict-webpack-plugin" . "remove-strict-webpack-plugin@0.1.2")
    ("node_modules/remove-trailing-separator" . "remove-trailing-separator@1.1.0")
    ("node_modules/repeat-element" . "repeat-element@1.1.4")
    ("node_modules/repeat-string" . "repeat-string@1.6.1")
    ("node_modules/require-directory" . "require-directory@2.1.1")
    ("node_modules/require-main-filename" . "require-main-filename@2.0.0")
    ("node_modules/resolve-cwd" . "resolve-cwd@2.0.0")
    ("node_modules/resolve-cwd/node_modules/resolve-from" . "resolve-from@3.0.0")
    ("node_modules/resolve-dir" . "resolve-dir@1.0.1")
    ("node_modules/resolve-dir/node_modules/global-modules" . "global-modules@1.0.0")
    ("node_modules/resolve-dir/node_modules/global-prefix" . "global-prefix@1.0.2")
    ("node_modules/resolve-url" . "resolve-url@0.2.1")
    ("node_modules/ret" . "ret@0.1.15")
    ("node_modules/ripemd160" . "ripemd160@2.0.2")
    ("node_modules/run-queue" . "run-queue@1.0.3")
    ("node_modules/safe-buffer" . "safe-buffer@5.1.2")
    ("node_modules/safe-regex" . "safe-regex@1.1.0")
    ("node_modules/safer-buffer" . "safer-buffer@2.1.2")
    ("node_modules/schema-utils" . "schema-utils@3.0.0")
    ("node_modules/semver" . "semver@7.3.5")
    ("node_modules/serialize-javascript" . "serialize-javascript@4.0.0")
    ("node_modules/set-blocking" . "set-blocking@2.0.0")
    ("node_modules/set-value" . "set-value@2.0.1")
    ("node_modules/setimmediate" . "setimmediate@1.0.5")
    ("node_modules/sha.js" . "sha.js@2.4.11")
    ("node_modules/shebang-command" . "shebang-command@1.2.0")
    ("node_modules/shebang-regex" . "shebang-regex@1.0.0")
    ("node_modules/snapdragon" . "snapdragon@0.8.2")
    ("node_modules/snapdragon-node" . "snapdragon-node@2.1.1")
    ("node_modules/snapdragon-node/node_modules/define-property" . "define-property@1.0.0")
    ("node_modules/snapdragon-node/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/snapdragon-util" . "snapdragon-util@3.0.1")
    ("node_modules/snapdragon/node_modules/debug" . "debug@2.6.9")
    ("node_modules/snapdragon/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/snapdragon/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/snapdragon/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/snapdragon/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/snapdragon/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/snapdragon/node_modules/ms" . "ms@2.0.0")
    ("node_modules/snapdragon/node_modules/source-map" . "source-map@0.5.7")
    ("node_modules/source-list-map" . "source-list-map@2.0.1")
    ("node_modules/source-map" . "source-map@0.6.1")
    ("node_modules/source-map-resolve" . "source-map-resolve@0.5.3")
    ("node_modules/source-map-support" . "source-map-support@0.5.19")
    ("node_modules/source-map-url" . "source-map-url@0.4.1")
    ("node_modules/split-string" . "split-string@3.1.0")
    ("node_modules/split-string/node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/split-string/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/ssri" . "ssri@6.0.2")
    ("node_modules/static-extend" . "static-extend@0.1.2")
    ("node_modules/static-extend/node_modules/define-property" . "define-property@0.2.5")
    ("node_modules/static-extend/node_modules/is-accessor-descriptor" . "is-accessor-descriptor@0.1.6")
    ("node_modules/static-extend/node_modules/is-data-descriptor" . "is-data-descriptor@0.1.4")
    ("node_modules/static-extend/node_modules/is-descriptor" . "is-descriptor@0.1.6")
    ("node_modules/static-extend/node_modules/is-descriptor/node_modules/kind-of" . "kind-of@5.1.0")
    ("node_modules/stream-browserify" . "stream-browserify@2.0.2")
    ("node_modules/stream-each" . "stream-each@1.2.3")
    ("node_modules/stream-http" . "stream-http@2.8.3")
    ("node_modules/stream-shift" . "stream-shift@1.0.1")
    ("node_modules/string_decoder" . "string_decoder@1.1.1")
    ("node_modules/strip-ansi" . "strip-ansi@5.2.0")
    ("node_modules/supports-color" . "supports-color@5.5.0")
    ("node_modules/sync-request" . "sync-request@6.1.0")
    ("node_modules/sync-rpc" . "sync-rpc@1.3.6")
    ("node_modules/tapable" . "tapable@1.1.3")
    ("node_modules/terser" . "terser@4.8.0")
    ("node_modules/terser-webpack-plugin" . "terser-webpack-plugin@1.4.5")
    ("node_modules/terser-webpack-plugin/node_modules/schema-utils" . "schema-utils@1.0.0")
    ("node_modules/terser/node_modules/commander" . "commander@2.20.3")
    ("node_modules/then-request" . "then-request@6.0.2")
    ("node_modules/then-request/node_modules/@types/node" . "@types/node@8.10.66")
    ("node_modules/through2" . "through2@2.0.5")
    ("node_modules/timers-browserify" . "timers-browserify@2.0.12")
    ("node_modules/to-arraybuffer" . "to-arraybuffer@1.0.1")
    ("node_modules/to-object-path" . "to-object-path@0.3.0")
    ("node_modules/to-regex" . "to-regex@3.0.2")
    ("node_modules/to-regex-range" . "to-regex-range@2.1.1")
    ("node_modules/to-regex-range/node_modules/is-number" . "is-number@3.0.0")
    ("node_modules/to-regex/node_modules/extend-shallow" . "extend-shallow@3.0.2")
    ("node_modules/to-regex/node_modules/is-extendable" . "is-extendable@1.0.1")
    ("node_modules/ts-loader" . "ts-loader@8.3.0")
    ("node_modules/ts-loader/node_modules/ansi-styles" . "ansi-styles@4.3.0")
    ("node_modules/ts-loader/node_modules/braces" . "braces@3.0.2")
    ("node_modules/ts-loader/node_modules/chalk" . "chalk@4.1.1")
    ("node_modules/ts-loader/node_modules/color-convert" . "color-convert@2.0.1")
    ("node_modules/ts-loader/node_modules/color-name" . "color-name@1.1.4")
    ("node_modules/ts-loader/node_modules/fill-range" . "fill-range@7.0.1")
    ("node_modules/ts-loader/node_modules/has-flag" . "has-flag@4.0.0")
    ("node_modules/ts-loader/node_modules/is-number" . "is-number@7.0.0")
    ("node_modules/ts-loader/node_modules/micromatch" . "micromatch@4.0.4")
    ("node_modules/ts-loader/node_modules/supports-color" . "supports-color@7.2.0")
    ("node_modules/ts-loader/node_modules/to-regex-range" . "to-regex-range@5.0.1")
    ("node_modules/tty-browserify" . "tty-browserify@0.0.0")
    ("node_modules/typedarray" . "typedarray@0.0.6")
    ("node_modules/typescript" . "typescript@4.2.4")
    ("node_modules/union-value" . "union-value@1.0.1")
    ("node_modules/unique-filename" . "unique-filename@1.1.1")
    ("node_modules/unique-slug" . "unique-slug@2.0.2")
    ("node_modules/universalify" . "universalify@0.1.2")
    ("node_modules/unset-value" . "unset-value@1.0.0")
    ("node_modules/unset-value/node_modules/has-value" . "has-value@0.3.1")
    ("node_modules/unset-value/node_modules/has-value/node_modules/isobject" . "isobject@2.1.0")
    ("node_modules/unset-value/node_modules/has-values" . "has-values@0.1.4")
    ("node_modules/unset-value/node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/upath" . "upath@1.2.0")
    ("node_modules/uri-js" . "uri-js@4.4.1")
    ("node_modules/urix" . "urix@0.1.0")
    ("node_modules/url" . "url@0.11.0")
    ("node_modules/url/node_modules/punycode" . "punycode@1.3.2")
    ("node_modules/use" . "use@3.1.1")
    ("node_modules/util" . "util@0.11.1")
    ("node_modules/util-deprecate" . "util-deprecate@1.0.2")
    ("node_modules/util/node_modules/inherits" . "inherits@2.0.3")
    ("node_modules/v8-compile-cache" . "v8-compile-cache@2.3.0")
    ("node_modules/vm-browserify" . "vm-browserify@1.1.2")
    ("node_modules/watchpack" . "watchpack@1.7.5")
    ("node_modules/watchpack-chokidar2" . "watchpack-chokidar2@2.0.1")
    ("node_modules/watchpack-chokidar2/node_modules/binary-extensions" . "binary-extensions@1.13.1")
    ("node_modules/watchpack-chokidar2/node_modules/chokidar" . "chokidar@2.1.8")
    ("node_modules/watchpack-chokidar2/node_modules/glob-parent" . "glob-parent@3.1.0")
    ("node_modules/watchpack-chokidar2/node_modules/glob-parent/node_modules/is-glob" . "is-glob@3.1.0")
    ("node_modules/watchpack-chokidar2/node_modules/is-binary-path" . "is-binary-path@1.0.1")
    ("node_modules/watchpack-chokidar2/node_modules/normalize-path" . "normalize-path@3.0.0")
    ("node_modules/watchpack-chokidar2/node_modules/readdirp" . "readdirp@2.2.1")
    ("node_modules/webpack" . "webpack@4.46.0")
    ("node_modules/webpack-cli" . "webpack-cli@3.3.12")
    ("node_modules/webpack-cli/node_modules/json5" . "json5@1.0.1")
    ("node_modules/webpack-cli/node_modules/loader-utils" . "loader-utils@1.4.0")
    ("node_modules/webpack-cli/node_modules/minimist" . "minimist@1.2.5")
    ("node_modules/webpack-cli/node_modules/supports-color" . "supports-color@6.1.0")
    ("node_modules/webpack-sources" . "webpack-sources@1.4.3")
    ("node_modules/webpack/node_modules/acorn" . "acorn@6.4.2")
    ("node_modules/webpack/node_modules/eslint-scope" . "eslint-scope@4.0.3")
    ("node_modules/webpack/node_modules/json5" . "json5@1.0.1")
    ("node_modules/webpack/node_modules/loader-utils" . "loader-utils@1.4.0")
    ("node_modules/webpack/node_modules/memory-fs" . "memory-fs@0.4.1")
    ("node_modules/webpack/node_modules/minimist" . "minimist@1.2.5")
    ("node_modules/webpack/node_modules/schema-utils" . "schema-utils@1.0.0")
    ("node_modules/which" . "which@1.3.1")
    ("node_modules/which-module" . "which-module@2.0.0")
    ("node_modules/worker-farm" . "worker-farm@1.7.0")
    ("node_modules/wrappy" . "wrappy@1.0.2")
    ("node_modules/xtend" . "xtend@4.0.2")
    ("node_modules/y18n" . "y18n@4.0.3")
    ("node_modules/yallist" . "yallist@4.0.0")
    ("node_modules/yargs" . "yargs@13.3.2")
    ("node_modules/yargs/node_modules/emoji-regex" . "emoji-regex@7.0.3")
    ("node_modules/yargs/node_modules/find-up" . "find-up@3.0.0")
    ("node_modules/yargs/node_modules/is-fullwidth-code-point" . "is-fullwidth-code-point@2.0.0")
    ("node_modules/yargs/node_modules/locate-path" . "locate-path@3.0.0")
    ("node_modules/yargs/node_modules/p-locate" . "p-locate@3.0.0")
    ("node_modules/yargs/node_modules/path-exists" . "path-exists@3.0.0")
    ("node_modules/yargs/node_modules/string-width" . "string-width@3.1.0")
    ("node_modules/yargs/node_modules/yargs-parser" . "yargs-parser@13.1.2")
    ))

(define %wenyan-npm-paths
  (map car %wenyan-npm-path-keys))

;; sync-request must remain external: sync-rpc locates its worker script
;; relative to __dirname.  Include its exact Node-resolved transitive tree.
(define %wenyan-runtime-paths
  '(
    "node_modules/@types/concat-stream"
    "node_modules/@types/form-data"
    "node_modules/@types/node"
    "node_modules/@types/qs"
    "node_modules/asap"
    "node_modules/asynckit"
    "node_modules/buffer-from"
    "node_modules/caseless"
    "node_modules/combined-stream"
    "node_modules/concat-stream"
    "node_modules/core-util-is"
    "node_modules/delayed-stream"
    "node_modules/form-data"
    "node_modules/get-port"
    "node_modules/http-basic"
    "node_modules/http-response-object"
    "node_modules/http-response-object/node_modules/@types/node"
    "node_modules/inherits"
    "node_modules/isarray"
    "node_modules/mime-db"
    "node_modules/mime-types"
    "node_modules/parse-cache-control"
    "node_modules/process-nextick-args"
    "node_modules/promise"
    "node_modules/qs"
    "node_modules/readable-stream"
    "node_modules/safe-buffer"
    "node_modules/string_decoder"
    "node_modules/sync-request"
    "node_modules/sync-rpc"
    "node_modules/then-request"
    "node_modules/then-request/node_modules/@types/node"
    "node_modules/typedarray"
    "node_modules/util-deprecate"
    ))

(define %wenyan-license-supplements
  (list
    ;; https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/LICENSE
    ;; Supplement SHA-256: 0a48f63d7d32a49d196dce4b2e0cbc236c2cc8fef42cb20e005e4d5f813cc8f6
    (cons "@types/concat-stream@1.6.0"
          (plain-file "GUIX-LICENSE.txt"
                      "This project is licensed under the MIT license.
Copyrights are respective of each contributor listed at the beginning of each definition file.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/LICENSE
    ;; Supplement SHA-256: 0a48f63d7d32a49d196dce4b2e0cbc236c2cc8fef42cb20e005e4d5f813cc8f6
    (cons "@types/detect-indent@0.1.30"
          (plain-file "GUIX-LICENSE.txt"
                      "This project is licensed under the MIT license.
Copyrights are respective of each contributor listed at the beginning of each definition file.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/LICENSE
    ;; Supplement SHA-256: 0a48f63d7d32a49d196dce4b2e0cbc236c2cc8fef42cb20e005e4d5f813cc8f6
    (cons "@types/form-data@0.0.33"
          (plain-file "GUIX-LICENSE.txt"
                      "This project is licensed under the MIT license.
Copyrights are respective of each contributor listed at the beginning of each definition file.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/LICENSE
    ;; Supplement SHA-256: 0a48f63d7d32a49d196dce4b2e0cbc236c2cc8fef42cb20e005e4d5f813cc8f6
    (cons "@types/glob@5.0.30"
          (plain-file "GUIX-LICENSE.txt"
                      "This project is licensed under the MIT license.
Copyrights are respective of each contributor listed at the beginning of each definition file.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/DefinitelyTyped/DefinitelyTyped/master/LICENSE
    ;; Supplement SHA-256: 0a48f63d7d32a49d196dce4b2e0cbc236c2cc8fef42cb20e005e4d5f813cc8f6
    (cons "@types/mkdirp@0.3.29"
          (plain-file "GUIX-LICENSE.txt"
                      "This project is licensed under the MIT license.
Copyrights are respective of each contributor listed at the beginning of each definition file.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/async-each/-/async-each-1.0.3.tgz#package/README.md
    ;; Supplement SHA-256: 559fca65ca851a3e64b10a781b51e3bd07a116d0c413e4e450213a8cea6d0a59
    (cons "async-each@1.0.3"
          (plain-file "GUIX-LICENSE.txt"
                      "The MIT License (MIT)

Copyright (c) 2016 Paul Miller [(paulmillr.com)](http://paulmillr.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/brorand/-/brorand-1.1.0.tgz#package/README.md
    ;; Supplement SHA-256: 7261b3ab93df04c6d8f3398f87275d28f0e87d88cbd0033b788fb50402de03c5
    (cons "brorand@1.1.0"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2014.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/chokidar/-/chokidar-2.1.8.tgz#package/README.md
    ;; Supplement SHA-256: a1130dc898436ca84a50eec3b59dec1dd84dc2a05fa578afc8a1093eb29afc96
    (cons "chokidar@2.1.8"
          (plain-file "GUIX-LICENSE.txt"
                      "The MIT License (MIT)

Copyright (c) 2012-2019 Paul Miller (https://paulmillr.com) & Elan Shanker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/nuxt/consola/abb016f568e8942a3c3222258757bfff14304f7c/LICENSE
    ;; Supplement SHA-256: 9ea8a12deea1b232d639881e35b0540f8678315ebcc27053a9d8359bd78ad040
    (cons "consola@2.15.3"
          (plain-file "GUIX-LICENSE.txt"
                      "MIT License

Copyright (c) 2018

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"))
    ;; https://registry.npmjs.org/constants-browserify/-/constants-browserify-1.0.0.tgz#package/README.md
    ;; Supplement SHA-256: 918684b30c1eb517d771e10779738b6886f6b1ccacb835d21891d3a480c08e3d
    (cons "constants-browserify@1.0.0"
          (plain-file "GUIX-LICENSE.txt"
                      "Copyright (c) 2013 Julian Gruber &lt;julian@juliangruber.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/des.js/-/des.js-1.0.1.tgz#package/README.md
    ;; Supplement SHA-256: 19013b952fdb26def8b78441a0a81a368de22c8d5b5cb166f80c144bf3d0c16e
    (cons "des.js@1.0.1"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2015.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/sindresorhus/detect-indent/v0.2.0/license
    ;; Supplement SHA-256: 6fb9754611c20f6649f68805e8c990e83261f29316e29de9e6cedae607b8634c
    (cons "detect-indent@0.2.0"
          (plain-file "GUIX-LICENSE.txt"
                      "The MIT License (MIT)

Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/elliptic/-/elliptic-6.5.4.tgz#package/README.md
    ;; Supplement SHA-256: 7261b3ab93df04c6d8f3398f87275d28f0e87d88cbd0033b788fb50402de03c5
    (cons "elliptic@6.5.4"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2014.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; archive:package/README.md
    ;; Supplement SHA-256: c84b4e899dd3bbdb716ac34366e36e7e1a114c4d26ca69f408d1d0dc0171b305
    (cons "errno@0.1.8"
          (plain-file "GUIX-LICENSE.txt"
                      "## Copyright & Licence

*Copyright (c) 2012-2015 [Rod Vagg](https://github.com/rvagg) ([@rvagg](https://twitter.com/rvagg))*

Made available under the MIT licence:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"))
    ;; archive:package/README.md
    ;; Supplement SHA-256: cb1764d4708e870cc694de13d499af2e6ee98d2751026e3a3f79de608f4f4ea0
    (cons "esrecurse@4.3.0"
          (plain-file "GUIX-LICENSE.txt"
                      "### License

Copyright (C) 2014 [Yusuke Suzuki](https://github.com/Constellation)
 (twitter: [@Constellation](https://twitter.com/Constellation)) and other contributors.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"))
    ;; https://raw.githubusercontent.com/sindresorhus/get-stdin/34c3534a109bbf04a62dab84fff50ddedd246a54/license
    ;; Supplement SHA-256: 6fb9754611c20f6649f68805e8c990e83261f29316e29de9e6cedae607b8634c
    (cons "get-stdin@0.1.0"
          (plain-file "GUIX-LICENSE.txt"
                      "The MIT License (MIT)

Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/hash.js/-/hash.js-1.1.7.tgz#package/README.md
    ;; Supplement SHA-256: 7261b3ab93df04c6d8f3398f87275d28f0e87d88cbd0033b788fb50402de03c5
    (cons "hash.js@1.1.7"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2014.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/hmac-drbg/-/hmac-drbg-1.0.1.tgz#package/README.md
    ;; Supplement SHA-256: 2587ff6443c524b3427871376cbf7d755bbd0512b9e8142e601f9e447c599f75
    (cons "hmac-drbg@1.0.1"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2017.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/imurmurhash/-/imurmurhash-0.1.4.tgz#package/README.md
    ;; Supplement SHA-256: 2f3de7ca97e07e9814e9a8dd61a561079ae6eb303579837e12d3d51f867ef7a6
    (cons "imurmurhash@0.1.4"
          (plain-file "GUIX-LICENSE.txt"
                      "Copyright (c) 2013 Gary Court, Jens Taylor

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the \"Software\"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/isarray/-/isarray-1.0.0.tgz#package/README.md
    ;; Supplement SHA-256: a1bd5deadb6a06dd74efa852c1b8b23f63b67f2214fbe9c8bd591da51da69268
    (cons "isarray@1.0.0"
          (plain-file "GUIX-LICENSE.txt"
                      "(MIT)

Copyright (c) 2013 Julian Gruber &lt;julian@juliangruber.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the \"Software\"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"))
    ;; archive:package/README.md + webpack@4.46.0/package/LICENSE
    ;; Supplement SHA-256: 4b953825897ded1e615367e375a4115d4b040bb4820d6cb3772d6947779cd533
    (cons "memory-fs@0.4.1"
          (plain-file "GUIX-LICENSE.txt"
                      "Copyright (c) 2012-2014 Tobias Koppers

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/miller-rabin/-/miller-rabin-4.0.1.tgz#package/README.md
    ;; Supplement SHA-256: 7261b3ab93df04c6d8f3398f87275d28f0e87d88cbd0033b788fb50402de03c5
    (cons "miller-rabin@4.0.1"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2014.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://registry.npmjs.org/minimalistic-crypto-utils/-/minimalistic-crypto-utils-1.0.1.tgz#package/README.md
    ;; Supplement SHA-256: 2587ff6443c524b3427871376cbf7d755bbd0512b9e8142e601f9e447c599f75
    (cons "minimalistic-crypto-utils@1.0.1"
          (plain-file "GUIX-LICENSE.txt"
                      "This software is licensed under the MIT License.

Copyright Fedor Indutny, 2017.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; archive:package/lib/zlib/deflate.js
    ;; Supplement SHA-256: 170d7d544d380b38d5f76ab5eda29475b44ef537f4564163d6d9bece85c51c13
    (cons "pako@1.0.11"
          (plain-file "GUIX-LICENSE.txt"
                      "// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
"))
    ;; https://raw.githubusercontent.com/spdx/license-list-data/v3.26.0/text/MIT.txt
    ;; Supplement SHA-256: e0d77e769fae93c228b44677cad541a5a14a9d3b451dc86cdc990a3acdfa9d7a
    (cons "remove-strict-webpack-plugin@0.1.2"
          (plain-file "GUIX-LICENSE.txt"
                      "Upstream package metadata declares MIT. Author metadata: Hendry Sadrak (https://www.hendrysadrak.com). Original metadata and source notices retained.

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the \"Software\"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO 
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ;; https://raw.githubusercontent.com/iarna/run-queue/c6cfe6af801fd6220a8e0414a45a7af7e3dfd1fe/LICENSE
    ;; Supplement SHA-256: 85e0578bb2af9cfb93d155bd18a9636b8f4070f90f7b9564ab599c6927a1dfb8
    (cons "run-queue@1.0.3"
          (plain-file "GUIX-LICENSE.txt"
                      "Copyright Rebecca Turner

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
"))
    ;; https://registry.npmjs.org/watchpack/-/watchpack-1.7.5.tgz#package/LICENSE
    ;; Supplement SHA-256: 9068a8782d2fb4c6e432cfa25334efa56f722822180570802bf86e71b6003b1e
    (cons "watchpack-chokidar2@2.0.1"
          (plain-file "GUIX-LICENSE.txt"
                      "Copyright JS Foundation and other contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"))
    ))

(define (record->source record)
  (let* ((fields (string-tokenize record))
         (name (list-ref fields 0))
         (version (list-ref fields 1))
         (url (list-ref fields 2))
         (hash (list-ref fields 3))
         (key (string-append name "@" version))
         (supplement (assoc-ref %wenyan-license-supplements key))
         (prune (cond ((string=? name "stream-http") "test")
                      ((string=? name "unique-filename") "coverage")
                      (else #f))))
    (cons key
          (origin
            (method url-fetch)
            (uri url)
            (file-name
             (string-append "wenyan-"
                            (string-map (lambda (c)
                                          (if (or (char=? c #\/)
                                                  (char=? c #\@))
                                              #\- c))
                                        name)
                            "-" version ".tgz"))
            (sha256 (base32 hash))
            (modules '((guix build utils)))
            (snippet
             (and (or supplement prune)
                  #~(begin
                      (when #$prune
                        ;; Unused test/coverage imagery is not part of the
                        ;; required production dependency source closure.
                        (delete-file-recursively #$prune))
                      (when #$supplement
                        (copy-file #$supplement "GUIX-LICENSE.txt")))))))))

(define %wenyan-npm-sources
  (map record->source
       (remove string-null?
               (string-split %wenyan-npm-source-records #\newline))))
