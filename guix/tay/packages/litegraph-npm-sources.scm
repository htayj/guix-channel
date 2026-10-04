;;; Locked source closure for LiteGraph's offline Grunt build.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages litegraph-npm-sources)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (%litegraph-npm-sources %litegraph-npm-paths
            %litegraph-npm-path-keys))

;; npm tarballs are fixed by SHA256; all 114 also matched their upstream lock
;; SHA512 integrity during the source audit.  Esprima is compiled from its
;; matching source tag instead of using the npm archive's generated webpack
;; bundle.  Other runtime inputs are readable, editable JavaScript sources.
(define %litegraph-npm-records
  (string-append
    "abbrev\t1.1.1\thttps://registry.npmjs.org/abbrev/-/abbrev-1.1.1.tgz\t0vdsff38rgn0qylyj6x42n13bnxfqxb9ql34bzs4z9grlli9vh8c\n"
    "ansi-regex\t2.1.1\thttps://registry.npmjs.org/ansi-regex/-/ansi-regex-2.1.1.tgz\t0dw0pqvijj9q9rfll09g4chszmakl5zr62k3ir9szvk5i0aapf2j\n"
    "ansi-styles\t2.2.1\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-2.2.1.tgz\t07qj2dsg3ydpj79cc8j52hzzylw8jq6xbl4yzq1573p3lnzkqq4d\n"
    "ansi-styles\t4.3.0\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-4.3.0.tgz\t0zwqsx67hr7m4a8dpd0jzkp2rjm5v7938x4rhcqh7djsv139llrc\n"
    "argparse\t1.0.10\thttps://registry.npmjs.org/argparse/-/argparse-1.0.10.tgz\t03dc2n1i08nwyyl1l8pq0a5fckcw9rpdqlw3zh8pw6w1syf19akz\n"
    "array-each\t1.0.1\thttps://registry.npmjs.org/array-each/-/array-each-1.0.1.tgz\t1ak1p41jln966m6z0ssx6awrnwmb889zhnnpm3r2yxj197b9m1j0\n"
    "array-slice\t1.1.0\thttps://registry.npmjs.org/array-slice/-/array-slice-1.1.0.tgz\t0awki0f9n4zhabagxnp5frk7ay23f4w8628il581bkyqn2lnknhw\n"
    "async\t3.2.4\thttps://registry.npmjs.org/async/-/async-3.2.4.tgz\t0vr9k1k33d1wcg3x3qq8nmg22pjjdvygznb5iz7fliihf447p3f2\n"
    "balanced-match\t1.0.2\thttps://registry.npmjs.org/balanced-match/-/balanced-match-1.0.2.tgz\t1hdwrr7qqb37plj7962xbwjx1jvjz7ahl7iqrwh82yhcvnmzfm6q\n"
    "brace-expansion\t1.1.11\thttps://registry.npmjs.org/brace-expansion/-/brace-expansion-1.1.11.tgz\t1nlmjvlwlp88knblnayns0brr7a9m2fynrlwq425lrpb4mcn9gc4\n"
    "braces\t3.0.2\thttps://registry.npmjs.org/braces/-/braces-3.0.2.tgz\t1kpaa113m54qc1n2zvs0p1ika4s9dzvcczlw8q66xkyliy982n3k\n"
    "chalk\t1.1.3\thttps://registry.npmjs.org/chalk/-/chalk-1.1.3.tgz\t0pa4ajfiq9prr608wldd6y6w7asmgravbbx63qz6yj7s6d49r5rk\n"
    "chalk\t4.1.2\thttps://registry.npmjs.org/chalk/-/chalk-4.1.2.tgz\t02prgl8d52k2vgxnssx06ha2sjm2vp6v6s6kqgkar1ryllx68k78\n"
    "color-convert\t2.0.1\thttps://registry.npmjs.org/color-convert/-/color-convert-2.0.1.tgz\t1qbw9rwfzcp7y0cpa8gmwlj7ccycf9pwn15zvf2s06f070ss83wj\n"
    "color-name\t1.1.4\thttps://registry.npmjs.org/color-name/-/color-name-1.1.4.tgz\t020p7x7k8rlph38lhsqpqvkx0b70lzlmk6mgal9r9sz8c527qysh\n"
    "colors\t1.1.2\thttps://registry.npmjs.org/colors/-/colors-1.1.2.tgz\t02q6xz1c0v4w2wqxwh9sacbva7mgcyfj1habclyhjhzbxbs7zw40\n"
    "concat-map\t0.0.1\thttps://registry.npmjs.org/concat-map/-/concat-map-0.0.1.tgz\t0qa2zqn9rrr2fqdki44s4s2dk2d8307i4556kv25h06g43b2v41m\n"
    "dateformat\t3.0.3\thttps://registry.npmjs.org/dateformat/-/dateformat-3.0.3.tgz\t0pmkwx051fxy627xy9p7imq6hq7jw15jsy16wf2qx6pf19f4h3hq\n"
    "detect-file\t1.0.0\thttps://registry.npmjs.org/detect-file/-/detect-file-1.0.0.tgz\t0f98cmkihrk8fznrr9fvdalzqhxa1cy0bdxs8ybj81m16670cc92\n"
    "escape-string-regexp\t1.0.5\thttps://registry.npmjs.org/escape-string-regexp/-/escape-string-regexp-1.0.5.tgz\t0iy3jirnnslnfwk8wa5xkg56fnbmg7bsv5v2a1s0qgbnfqp7j375\n"
    "esprima\t4.0.1\thttps://codeload.github.com/jquery/esprima/tar.gz/refs/tags/4.0.1\t1dw4f6hp49xk0l2b9ldjr3lmy0bgsnwk13628zgr8d87g0jy8xa9\n"
    "eventemitter2\t0.4.14\thttps://registry.npmjs.org/eventemitter2/-/eventemitter2-0.4.14.tgz\t11y7vzr3gjfblwblq1mj6gx16w9qpmffi8l1k2ajvza9zq55rmfa\n"
    "exit\t0.1.2\thttps://registry.npmjs.org/exit/-/exit-0.1.2.tgz\t0h9ax37w49xq5cljxij0sg7svl32a4sc89l928c8zhir1750cps8\n"
    "expand-tilde\t2.0.2\thttps://registry.npmjs.org/expand-tilde/-/expand-tilde-2.0.2.tgz\t0931ha1jm9b4kc547qp2bp7ymr5yxkqmvfk4pk2k00nc5hqx4ji4\n"
    "extend\t3.0.2\thttps://registry.npmjs.org/extend/-/extend-3.0.2.tgz\t1ckjrzapv4awrafybcvq3n5rcqm6ljswfdx97wibl355zaqd148x\n"
    "fill-range\t7.0.1\thttps://registry.npmjs.org/fill-range/-/fill-range-7.0.1.tgz\t0wp93mwfgzcddi6ii62qx7gb082jgh0rfq6pgvv2xndjyaygvk98\n"
    "findup-sync\t0.3.0\thttps://registry.npmjs.org/findup-sync/-/findup-sync-0.3.0.tgz\t1j58i2v1p9vzrkhfcbh8zx9hgz3w6c313z3cvvgc8c7yga17w4xs\n"
    "findup-sync\t4.0.0\thttps://registry.npmjs.org/findup-sync/-/findup-sync-4.0.0.tgz\t1pqymkq8kxdbm9r6vhpa4kh5is9j6wq496n71nbn7z4j2mnf9nll\n"
    "fined\t1.2.0\thttps://registry.npmjs.org/fined/-/fined-1.2.0.tgz\t1qj9zx3aflvrnzb9pajz6b0hldhq1vc9dby7dmh7bh9a34iasy87\n"
    "flagged-respawn\t1.0.1\thttps://registry.npmjs.org/flagged-respawn/-/flagged-respawn-1.0.1.tgz\t10pv65qwx8b6z7cm5p30kgi50anay6l0gggijzjlpqvb5189q582\n"
    "for-in\t1.0.2\thttps://registry.npmjs.org/for-in/-/for-in-1.0.2.tgz\t0pm8dx9gvp9p91my9fqivajq7yhnxmn8scl391pgcv6d8h6s6zaf\n"
    "for-own\t1.0.0\thttps://registry.npmjs.org/for-own/-/for-own-1.0.0.tgz\t06jdzc50h2ma6g5psp95r7fg2g8gyp3cg3900ghvfpcnabdsqcss\n"
    "fs.realpath\t1.0.0\thttps://registry.npmjs.org/fs.realpath/-/fs.realpath-1.0.0.tgz\t174g5vay9jnd7h5q8hfdw6dnmwl1gdpn4a8sz0ysanhj2f3wp04y\n"
    "function-bind\t1.1.1\thttps://registry.npmjs.org/function-bind/-/function-bind-1.1.1.tgz\t10p0s9ypggwmazik4azdhywjnnayagnjxk10cjzsrhxlk1y2wm9d\n"
    "getobject\t1.0.2\thttps://registry.npmjs.org/getobject/-/getobject-1.0.2.tgz\t0768395p54gfwf5vzrabddb1ac88bs4p204dsg1nvf4209i24v7f\n"
    "glob\t5.0.15\thttps://registry.npmjs.org/glob/-/glob-5.0.15.tgz\t1ds8lkg2x4wczzrvd305xksggxh8xkg28xp8mcs4i0qhypd4bjg3\n"
    "glob\t7.1.7\thttps://registry.npmjs.org/glob/-/glob-7.1.7.tgz\t1vlv5r0ipznrq1c7ikqpbzgk7q31zz6m1wcy9cxsklb8vvfv6105\n"
    "global-modules\t1.0.0\thttps://registry.npmjs.org/global-modules/-/global-modules-1.0.0.tgz\t1rjf3gybhsgc66r44ikdw8b8qqp5pjr30c58zmvv4v432z9pb01l\n"
    "global-prefix\t1.0.2\thttps://registry.npmjs.org/global-prefix/-/global-prefix-1.0.2.tgz\t0sarygsknl8443r4kyq2mzlwz5pqpk5ard9yh2jcix65dvaxdmzi\n"
    "grunt-cli\t1.4.3\thttps://registry.npmjs.org/grunt-cli/-/grunt-cli-1.4.3.tgz\t1gc3mqfhnrcgpa7whbg3y81wypghpkykv4cq9vrrw0bxmmkw7zy7\n"
    "grunt-closure-tools\t1.0.0\thttps://registry.npmjs.org/grunt-closure-tools/-/grunt-closure-tools-1.0.0.tgz\t04mvrgzxx36ni78ac1hb4s1dhnkx0qcdnwy5q9npv18gxdh57wci\n"
    "grunt-contrib-concat\t1.0.1\thttps://registry.npmjs.org/grunt-contrib-concat/-/grunt-contrib-concat-1.0.1.tgz\t0myc1gjixafjfkiy4agdb4pzg19slrdixz75732dm6v34d1yyfvg\n"
    "grunt-known-options\t2.0.0\thttps://registry.npmjs.org/grunt-known-options/-/grunt-known-options-2.0.0.tgz\t1y8v6955ar095q4sk4f9aynqlxxyzx8a4png4vmsga9rkid44nv2\n"
    "grunt-legacy-log-utils\t2.1.0\thttps://registry.npmjs.org/grunt-legacy-log-utils/-/grunt-legacy-log-utils-2.1.0.tgz\t1vzrnhpb63h1qhyqvizskjmq4svbha24whm5i06b6qp0zzxv6jfz\n"
    "grunt-legacy-log\t3.0.0\thttps://registry.npmjs.org/grunt-legacy-log/-/grunt-legacy-log-3.0.0.tgz\t05pid2zb2mf689b224cbxaaskx6g9ml48nghkps7zi0kjgvzs41f\n"
    "grunt-legacy-util\t2.0.1\thttps://registry.npmjs.org/grunt-legacy-util/-/grunt-legacy-util-2.0.1.tgz\t0cf1p81iiafqqpzvgmmamvldwfz09jaax5yas2ql7n7x1d3ixdmx\n"
    "grunt\t1.5.3\thttps://registry.npmjs.org/grunt/-/grunt-1.5.3.tgz\t03dsrhxk41jc3lnqjz2nvm4id9mc53dgqq4cxknwbnbh79y8jcr3\n"
    "has-ansi\t2.0.0\thttps://registry.npmjs.org/has-ansi/-/has-ansi-2.0.0.tgz\t1va48dv32ighffpqr44dl8l5mm7kc5mylkd6drcd6y0y97mna0p3\n"
    "has-flag\t4.0.0\thttps://registry.npmjs.org/has-flag/-/has-flag-4.0.0.tgz\t1cdmvliwz8h02nwg0ipli0ydd1l82sz9s1m7bj5bn9yr24afp9vp\n"
    "has\t1.0.3\thttps://registry.npmjs.org/has/-/has-1.0.3.tgz\t0wsmn2vcbqb23xpbzxipjd7xcdljid2gwnwl7vn5hkp0zkpgk363\n"
    "homedir-polyfill\t1.0.3\thttps://registry.npmjs.org/homedir-polyfill/-/homedir-polyfill-1.0.3.tgz\t16p593jixgb20qdk1ji3lh92vswjg3h40awakff8pdmc9s7mvj04\n"
    "hooker\t0.2.3\thttps://registry.npmjs.org/hooker/-/hooker-0.2.3.tgz\t0jaqhzr8s89jwfif5brxr74sy3g2ps6cd7jv9i0gn69dnzcmb28w\n"
    "iconv-lite\t0.4.24\thttps://registry.npmjs.org/iconv-lite/-/iconv-lite-0.4.24.tgz\t0da6ff7dlx6lfhdafsd9sv0h09sicpfakms8bqylrm4f17r68v2p\n"
    "inflight\t1.0.6\thttps://registry.npmjs.org/inflight/-/inflight-1.0.6.tgz\t16w864087xsh3q7f5gm3754s7bpsb9fq3dhknk9nmbvlk3sxr7ss\n"
    "inherits\t2.0.4\thttps://registry.npmjs.org/inherits/-/inherits-2.0.4.tgz\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\n"
    "ini\t1.3.8\thttps://registry.npmjs.org/ini/-/ini-1.3.8.tgz\t0nk92bp5is23lsi1ip4qz5bjkzmjxkz9c1g79sx991ad212i37px\n"
    "interpret\t1.1.0\thttps://registry.npmjs.org/interpret/-/interpret-1.1.0.tgz\t10awrj9jzv49r5dca0z8zgvgyp42j7q3j2nc89k0dz5x50l3g0k0\n"
    "is-absolute\t1.0.0\thttps://registry.npmjs.org/is-absolute/-/is-absolute-1.0.0.tgz\t1n4297k5wr3scx7jiavci0ramfbfpzgxjrw72psdiyaxx6p7na6z\n"
    "is-core-module\t2.11.0\thttps://registry.npmjs.org/is-core-module/-/is-core-module-2.11.0.tgz\t1i2dnckq99aqism5rppxwlrc3md5i1rbksmqp4000awhgm3dwk0h\n"
    "is-extglob\t2.1.1\thttps://registry.npmjs.org/is-extglob/-/is-extglob-2.1.1.tgz\t06dwa2xzjx6az40wlvwj11vican2w46710b9170jzmka2j344pcc\n"
    "is-glob\t4.0.3\thttps://registry.npmjs.org/is-glob/-/is-glob-4.0.3.tgz\t1imyq6pjl716cjc1ypmmnn0574rh28av3pq50mpqzd9v37xm7r1z\n"
    "is-number\t7.0.0\thttps://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz\t07nmmpplsj1gxzng6fxhnnyfkif9fvhvxa89d5lrgkwqf42w2xbv\n"
    "is-plain-object\t2.0.4\thttps://registry.npmjs.org/is-plain-object/-/is-plain-object-2.0.4.tgz\t1ipx9y0c1kmq6irjxix6vcxfax6ilnns9pkgjc6cq8ygnyagv4s8\n"
    "is-relative\t1.0.0\thttps://registry.npmjs.org/is-relative/-/is-relative-1.0.0.tgz\t1wrkhkbfdpr0gfhshwylvfp6h9a3rlw7l6zlvldww4aqzsjg1f93\n"
    "is-unc-path\t1.0.0\thttps://registry.npmjs.org/is-unc-path/-/is-unc-path-1.0.0.tgz\t0qjxjsvv17kv8yqwzb11aaw6aqkx72zwmi96pdaqswdzagp6qmqk\n"
    "is-windows\t1.0.2\thttps://registry.npmjs.org/is-windows/-/is-windows-1.0.2.tgz\t18iihzz6fs6sfrgq1bpvgkfk3cza6r9wrrgn7ahcbbra1lkjh4bv\n"
    "isexe\t2.0.0\thttps://registry.npmjs.org/isexe/-/isexe-2.0.0.tgz\t0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7\n"
    "isobject\t3.0.1\thttps://registry.npmjs.org/isobject/-/isobject-3.0.1.tgz\t0dvx6rhjj5b9q7fcjg24lfy2nr3a1d2ypqy9zf9lqr2s00mwkiiw\n"
    "js-yaml\t3.14.1\thttps://registry.npmjs.org/js-yaml/-/js-yaml-3.14.1.tgz\t1jmy5pbvh80pc772pa4jhqnl6ax4p3w7npnqqk8z1md575cmynlk\n"
    "kind-of\t6.0.3\thttps://registry.npmjs.org/kind-of/-/kind-of-6.0.3.tgz\t1nk31q65n9hcmbp16mbn55siqnf44wn1x71rrqyjv9bcbcxl893c\n"
    "liftup\t3.0.1\thttps://registry.npmjs.org/liftup/-/liftup-3.0.1.tgz\t0yd2r9f0w1zy9ah5k2xw168sqdjywxlwlbvpc0ps4as914mn52k4\n"
    "lodash\t4.17.21\thttps://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz\t017qragyfl5ifajdx48lvz46wr0jc1llikgvc2fhqakhwp4pl23a\n"
    "make-iterator\t1.0.1\thttps://registry.npmjs.org/make-iterator/-/make-iterator-1.0.1.tgz\t0sskmpm8pmvwm4c0akdnp2nkyk42vpsklxlb7p769mvyi1r6589d\n"
    "map-cache\t0.2.2\thttps://registry.npmjs.org/map-cache/-/map-cache-0.2.2.tgz\t0gag01y8x17l2ffdmi5rgll24bw4cmyi3wksk45xpghirlkrkhj1\n"
    "micromatch\t4.0.5\thttps://registry.npmjs.org/micromatch/-/micromatch-4.0.5.tgz\t1axxwnl1i0mibpbir72nvz76dzi43cv8lhyzpxw95056mddnlmi0\n"
    "minimatch\t3.0.8\thttps://registry.npmjs.org/minimatch/-/minimatch-3.0.8.tgz\t1f7m9mniclrld96i3kayasdwm220m895z0skhxs0jmz3syk1l4iw\n"
    "mkdirp\t1.0.4\thttps://registry.npmjs.org/mkdirp/-/mkdirp-1.0.4.tgz\t06nqac14zbpar89jc7s574l1qpmamr1kzy0dr3qyhvxg8570f5qx\n"
    "nopt\t3.0.6\thttps://registry.npmjs.org/nopt/-/nopt-3.0.6.tgz\t1a59ksp9dnqscdffj1r2b96372amv1s8yzgm72iwvxpljgmv8q74\n"
    "nopt\t4.0.3\thttps://registry.npmjs.org/nopt/-/nopt-4.0.3.tgz\t1cci6agdbfjaynxzm6sg7n48lilwq69zcbgdr394kdlb0mljr7hb\n"
    "object.defaults\t1.1.0\thttps://registry.npmjs.org/object.defaults/-/object.defaults-1.1.0.tgz\t16nk98k1dd2pkpjvjg1lk0xk8zs7s2lijnbqz3nl4ybjn4mj16hz\n"
    "object.map\t1.0.1\thttps://registry.npmjs.org/object.map/-/object.map-1.0.1.tgz\t03q8hah8zvwkxm2rcqm01cbljjg1p5g705para31nn9snvkgqzdj\n"
    "object.pick\t1.3.0\thttps://registry.npmjs.org/object.pick/-/object.pick-1.3.0.tgz\t02zfyg9vkizb5vanjy3d976cnbjnx4qrcjrd92z2ylyl4ih24040\n"
    "once\t1.4.0\thttps://registry.npmjs.org/once/-/once-1.4.0.tgz\t1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg\n"
    "os-homedir\t1.0.2\thttps://registry.npmjs.org/os-homedir/-/os-homedir-1.0.2.tgz\t0xa4n9ybd93a20faw2f3lj5jz4aawnw7lpxnnxq2ndgcmz48bs0f\n"
    "os-tmpdir\t1.0.2\thttps://registry.npmjs.org/os-tmpdir/-/os-tmpdir-1.0.2.tgz\t12ddjb45wq0swr2159wiaxl2balnli8127if7sc89h3psz125rqk\n"
    "osenv\t0.1.5\thttps://registry.npmjs.org/osenv/-/osenv-0.1.5.tgz\t0j34a50i707jwxbz4mzap9awpsm0cyd75l0yadi55www26d4c6bx\n"
    "parse-filepath\t1.0.2\thttps://registry.npmjs.org/parse-filepath/-/parse-filepath-1.0.2.tgz\t07pb2ss7033a625gn2bbyz7zw18x3z2gp4nmy12vgxmvgmvj2gpa\n"
    "parse-passwd\t1.0.0\thttps://registry.npmjs.org/parse-passwd/-/parse-passwd-1.0.0.tgz\t1ww9sbaka5vy7g9k0dacmn2hvvxkhrx7qypp9hq15h0i2lx35mnw\n"
    "path-is-absolute\t1.0.1\thttps://registry.npmjs.org/path-is-absolute/-/path-is-absolute-1.0.1.tgz\t0p7p04xxd8q495qhxmxydyjgzcf762dp1hp2wha2b52n3agp0vbf\n"
    "path-parse\t1.0.7\thttps://registry.npmjs.org/path-parse/-/path-parse-1.0.7.tgz\t18vkai53yyiv1c1rimsh2whiymxnz9xj6a39c6b65097ly61jym0\n"
    "path-root-regex\t0.1.2\thttps://registry.npmjs.org/path-root-regex/-/path-root-regex-0.1.2.tgz\t1bqiw829qrpii91w1ba889xpd96wyfyws13xxpd342aiqdhyjk55\n"
    "path-root\t0.1.1\thttps://registry.npmjs.org/path-root/-/path-root-0.1.1.tgz\t10xjgafx4na34pqshzri0df545zygs542zgljbpfbags2j48z3ld\n"
    "picomatch\t2.3.1\thttps://registry.npmjs.org/picomatch/-/picomatch-2.3.1.tgz\t07y1h9gbbdyjdpwb461x7dai0yg7hcyijxrcnpbr1h37r2gfw50v\n"
    "rechoir\t0.7.1\thttps://registry.npmjs.org/rechoir/-/rechoir-0.7.1.tgz\t0w120s20q23mkh795cf8kj1kb8i9jgg80n7zfy89wdmyip44ahr4\n"
    "resolve-dir\t1.0.1\thttps://registry.npmjs.org/resolve-dir/-/resolve-dir-1.0.1.tgz\t1bzapdz97xgh7ahvap1c2n0lrh2mwra7jxfx4iym5d3mr4wc5a7j\n"
    "resolve\t1.22.1\thttps://registry.npmjs.org/resolve/-/resolve-1.22.1.tgz\t1shj5plxx1pnv896yxwsb5v23jhwdrch927yih1lvv82i3aaammm\n"
    "rimraf\t3.0.2\thttps://registry.npmjs.org/rimraf/-/rimraf-3.0.2.tgz\t0lkzjyxjij6ssh5h2l3ncp0zx00ylzhww766dq2vf1s7v07w4xjq\n"
    "safer-buffer\t2.1.2\thttps://registry.npmjs.org/safer-buffer/-/safer-buffer-2.1.2.tgz\t1cx383s7vchfac8jlg3mnb820hkgcvhcpfn9w4f0g61vmrjjz0bq\n"
    "source-map\t0.5.7\thttps://registry.npmjs.org/source-map/-/source-map-0.5.7.tgz\t0rvb24j4kfib26w3cjyl6yan2dxvw1iy7d0wl404y5ckqjdjipp1\n"
    "sprintf-js\t1.0.3\thttps://registry.npmjs.org/sprintf-js/-/sprintf-js-1.0.3.tgz\t10qsmbfw9hv4hahsvq79py6v0dddhckwynji2vsr1p18qfy2dyrs\n"
    "sprintf-js\t1.1.2\thttps://registry.npmjs.org/sprintf-js/-/sprintf-js-1.1.2.tgz\t096w09mnd0i35g3xcgqyl40aymisvxc13gcz1jvf3z236w234a6l\n"
    "strip-ansi\t3.0.1\thttps://registry.npmjs.org/strip-ansi/-/strip-ansi-3.0.1.tgz\t0fkrbfwig3d1i8s01pbj08pq1z6sn9xqvkjdz0a9b58q85d3i78w\n"
    "supports-color\t2.0.0\thttps://registry.npmjs.org/supports-color/-/supports-color-2.0.0.tgz\t1lwscnhhmxpi3fbclkva5zg411cw9p0mgabbk3mic3sfshjlnpbj\n"
    "supports-color\t7.2.0\thttps://registry.npmjs.org/supports-color/-/supports-color-7.2.0.tgz\t0jjyglzdzscmhgidn43zc218q5jf9h03hmaaq9h4wqil2vywlspi\n"
    "supports-preserve-symlinks-flag\t1.0.0\thttps://registry.npmjs.org/supports-preserve-symlinks-flag/-/supports-preserve-symlinks-flag-1.0.0.tgz\t1ygp0kk7p6df5p6p2q1csdshilklhfbh49g7h90m6i2kmxh13nlp\n"
    "task-closure-tools\t0.1.10\thttps://registry.npmjs.org/task-closure-tools/-/task-closure-tools-0.1.10.tgz\t0hbcfyp2zpyr9pv6gmfwbc2gz9pbpglk91sywyvnk3l3sax3a87y\n"
    "to-regex-range\t5.0.1\thttps://registry.npmjs.org/to-regex-range/-/to-regex-range-5.0.1.tgz\t1ms2bgz2paqfpjv1xpwx67i3dns5j9gn99il6cx5r4qaq9g2afm6\n"
    "unc-path-regex\t0.1.2\thttps://registry.npmjs.org/unc-path-regex/-/unc-path-regex-0.1.2.tgz\t1wchap1q8ffrpsj2gzw2swn769jmn8ayjjy1xby0yaa5yjhakfkb\n"
    "underscore.string\t3.3.6\thttps://registry.npmjs.org/underscore.string/-/underscore.string-3.3.6.tgz\t1lw3d7jam15vww7pysqpx5l21hpm6klpb0kz3zn6avgzwdkfal7w\n"
    "util-deprecate\t1.0.2\thttps://registry.npmjs.org/util-deprecate/-/util-deprecate-1.0.2.tgz\t1rd3qbgdrwkmcrf7vqx61sh7icma7jvxcmklqj032f8v7jcdx8br\n"
    "v8flags\t3.2.0\thttps://registry.npmjs.org/v8flags/-/v8flags-3.2.0.tgz\t1js0699gacmrr60krl5vbnr9lwp7j2z2gq7v6z2z33mcxarm6v7m\n"
    "which\t1.3.1\thttps://registry.npmjs.org/which/-/which-1.3.1.tgz\t077d08k2zz1zhn5nc09m4vkiz2hjfk2lp02a3kphhianj3b26rcn\n"
    "which\t2.0.2\thttps://registry.npmjs.org/which/-/which-2.0.2.tgz\t1p2fkm4lr36s85gdjxmyr6wh86dizf0iwmffxmarcxpbvmgxyfm1\n"
    "wrappy\t1.0.2\thttps://registry.npmjs.org/wrappy/-/wrappy-1.0.2.tgz\t1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg\n"
    ))

(define %litegraph-npm-path-keys
  '(
    ("node_modules/abbrev" . "abbrev@1.1.1")
    ("node_modules/ansi-regex" . "ansi-regex@2.1.1")
    ("node_modules/ansi-styles" . "ansi-styles@2.2.1")
    ("node_modules/grunt-legacy-log-utils/node_modules/ansi-styles" . "ansi-styles@4.3.0")
    ("node_modules/argparse" . "argparse@1.0.10")
    ("node_modules/array-each" . "array-each@1.0.1")
    ("node_modules/array-slice" . "array-slice@1.1.0")
    ("node_modules/async" . "async@3.2.4")
    ("node_modules/balanced-match" . "balanced-match@1.0.2")
    ("node_modules/brace-expansion" . "brace-expansion@1.1.11")
    ("node_modules/liftup/node_modules/braces" . "braces@3.0.2")
    ("node_modules/chalk" . "chalk@1.1.3")
    ("node_modules/grunt-legacy-log-utils/node_modules/chalk" . "chalk@4.1.2")
    ("node_modules/grunt-legacy-log-utils/node_modules/color-convert" . "color-convert@2.0.1")
    ("node_modules/grunt-legacy-log-utils/node_modules/color-name" . "color-name@1.1.4")
    ("node_modules/colors" . "colors@1.1.2")
    ("node_modules/concat-map" . "concat-map@0.0.1")
    ("node_modules/dateformat" . "dateformat@3.0.3")
    ("node_modules/detect-file" . "detect-file@1.0.0")
    ("node_modules/escape-string-regexp" . "escape-string-regexp@1.0.5")
    ("node_modules/esprima" . "esprima@4.0.1")
    ("node_modules/eventemitter2" . "eventemitter2@0.4.14")
    ("node_modules/exit" . "exit@0.1.2")
    ("node_modules/expand-tilde" . "expand-tilde@2.0.2")
    ("node_modules/extend" . "extend@3.0.2")
    ("node_modules/liftup/node_modules/fill-range" . "fill-range@7.0.1")
    ("node_modules/findup-sync" . "findup-sync@0.3.0")
    ("node_modules/liftup/node_modules/findup-sync" . "findup-sync@4.0.0")
    ("node_modules/fined" . "fined@1.2.0")
    ("node_modules/flagged-respawn" . "flagged-respawn@1.0.1")
    ("node_modules/for-in" . "for-in@1.0.2")
    ("node_modules/for-own" . "for-own@1.0.0")
    ("node_modules/fs.realpath" . "fs.realpath@1.0.0")
    ("node_modules/function-bind" . "function-bind@1.1.1")
    ("node_modules/getobject" . "getobject@1.0.2")
    ("node_modules/findup-sync/node_modules/glob" . "glob@5.0.15")
    ("node_modules/glob" . "glob@7.1.7")
    ("node_modules/global-modules" . "global-modules@1.0.0")
    ("node_modules/global-prefix" . "global-prefix@1.0.2")
    ("node_modules/grunt-cli" . "grunt-cli@1.4.3")
    ("node_modules/grunt-closure-tools" . "grunt-closure-tools@1.0.0")
    ("node_modules/grunt-contrib-concat" . "grunt-contrib-concat@1.0.1")
    ("node_modules/grunt-known-options" . "grunt-known-options@2.0.0")
    ("node_modules/grunt-legacy-log-utils" . "grunt-legacy-log-utils@2.1.0")
    ("node_modules/grunt-legacy-log" . "grunt-legacy-log@3.0.0")
    ("node_modules/grunt-legacy-util" . "grunt-legacy-util@2.0.1")
    ("node_modules/grunt" . "grunt@1.5.3")
    ("node_modules/has-ansi" . "has-ansi@2.0.0")
    ("node_modules/grunt-legacy-log-utils/node_modules/has-flag" . "has-flag@4.0.0")
    ("node_modules/has" . "has@1.0.3")
    ("node_modules/homedir-polyfill" . "homedir-polyfill@1.0.3")
    ("node_modules/hooker" . "hooker@0.2.3")
    ("node_modules/iconv-lite" . "iconv-lite@0.4.24")
    ("node_modules/inflight" . "inflight@1.0.6")
    ("node_modules/inherits" . "inherits@2.0.4")
    ("node_modules/ini" . "ini@1.3.8")
    ("node_modules/interpret" . "interpret@1.1.0")
    ("node_modules/is-absolute" . "is-absolute@1.0.0")
    ("node_modules/is-core-module" . "is-core-module@2.11.0")
    ("node_modules/is-extglob" . "is-extglob@2.1.1")
    ("node_modules/is-glob" . "is-glob@4.0.3")
    ("node_modules/liftup/node_modules/is-number" . "is-number@7.0.0")
    ("node_modules/is-plain-object" . "is-plain-object@2.0.4")
    ("node_modules/is-relative" . "is-relative@1.0.0")
    ("node_modules/is-unc-path" . "is-unc-path@1.0.0")
    ("node_modules/is-windows" . "is-windows@1.0.2")
    ("node_modules/isexe" . "isexe@2.0.0")
    ("node_modules/isobject" . "isobject@3.0.1")
    ("node_modules/js-yaml" . "js-yaml@3.14.1")
    ("node_modules/make-iterator/node_modules/kind-of" . "kind-of@6.0.3")
    ("node_modules/liftup" . "liftup@3.0.1")
    ("node_modules/lodash" . "lodash@4.17.21")
    ("node_modules/make-iterator" . "make-iterator@1.0.1")
    ("node_modules/map-cache" . "map-cache@0.2.2")
    ("node_modules/liftup/node_modules/micromatch" . "micromatch@4.0.5")
    ("node_modules/minimatch" . "minimatch@3.0.8")
    ("node_modules/mkdirp" . "mkdirp@1.0.4")
    ("node_modules/nopt" . "nopt@3.0.6")
    ("node_modules/grunt-cli/node_modules/nopt" . "nopt@4.0.3")
    ("node_modules/object.defaults" . "object.defaults@1.1.0")
    ("node_modules/object.map" . "object.map@1.0.1")
    ("node_modules/object.pick" . "object.pick@1.3.0")
    ("node_modules/once" . "once@1.4.0")
    ("node_modules/os-homedir" . "os-homedir@1.0.2")
    ("node_modules/os-tmpdir" . "os-tmpdir@1.0.2")
    ("node_modules/osenv" . "osenv@0.1.5")
    ("node_modules/parse-filepath" . "parse-filepath@1.0.2")
    ("node_modules/parse-passwd" . "parse-passwd@1.0.0")
    ("node_modules/path-is-absolute" . "path-is-absolute@1.0.1")
    ("node_modules/path-parse" . "path-parse@1.0.7")
    ("node_modules/path-root-regex" . "path-root-regex@0.1.2")
    ("node_modules/path-root" . "path-root@0.1.1")
    ("node_modules/picomatch" . "picomatch@2.3.1")
    ("node_modules/rechoir" . "rechoir@0.7.1")
    ("node_modules/resolve-dir" . "resolve-dir@1.0.1")
    ("node_modules/resolve" . "resolve@1.22.1")
    ("node_modules/grunt/node_modules/rimraf" . "rimraf@3.0.2")
    ("node_modules/safer-buffer" . "safer-buffer@2.1.2")
    ("node_modules/source-map" . "source-map@0.5.7")
    ("node_modules/sprintf-js" . "sprintf-js@1.0.3")
    ("node_modules/underscore.string/node_modules/sprintf-js" . "sprintf-js@1.1.2")
    ("node_modules/strip-ansi" . "strip-ansi@3.0.1")
    ("node_modules/supports-color" . "supports-color@2.0.0")
    ("node_modules/grunt-legacy-log-utils/node_modules/supports-color" . "supports-color@7.2.0")
    ("node_modules/supports-preserve-symlinks-flag" . "supports-preserve-symlinks-flag@1.0.0")
    ("node_modules/task-closure-tools" . "task-closure-tools@0.1.10")
    ("node_modules/liftup/node_modules/to-regex-range" . "to-regex-range@5.0.1")
    ("node_modules/unc-path-regex" . "unc-path-regex@0.1.2")
    ("node_modules/underscore.string" . "underscore.string@3.3.6")
    ("node_modules/util-deprecate" . "util-deprecate@1.0.2")
    ("node_modules/v8flags" . "v8flags@3.2.0")
    ("node_modules/global-prefix/node_modules/which" . "which@1.3.1")
    ("node_modules/which" . "which@2.0.2")
    ("node_modules/wrappy" . "wrappy@1.0.2")
    ))

(define %litegraph-npm-paths (map car %litegraph-npm-path-keys))

(define %litegraph-license-supplements
  (list
    ;; matching archive README license section; SHA256 824b23f3b782cd65a40a9fb90ea58a7570072f1dc2dac9d129f93b4c53b280e7
    (cons "eventemitter2@0.4.14" (plain-file "GUIX-LICENSE.txt" "(The MIT License)\n\nCopyright (c) 2011 hij1nx <http://www.twitter.com/hij1nx>\n\nPermission is hereby granted, free of charge, to any person obtaining a copy \nof this software and associated documentation files (the 'Software'), to deal \nin the Software without restriction, including without limitation the rights \nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell \ncopies of the Software, and to permit persons to whom the Software is furnished\nto do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS\nFOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR \nCOPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN\nAN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION \nWITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n"))
    ;; matching archive README license section; SHA256 a42aa746a2f9c1fdbdd5f533ade2693a098204e0022a53e7331448cda6af0c1e
    (cons "underscore.string@3.3.6" (plain-file "GUIX-LICENSE.txt" "The MIT License\n\nCopyright (c) 2011 Esa-Matti Suuronen esa-matti@suuronen.org\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in\nall copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\nTHE SOFTWARE.\n\n\n[d]: http://www.diveintojavascript.com/core-javascript-reference/the-string-object\n"))
    ;; cowboy/node-getobject/v1.0.2; SHA256 65bd93f75d6c0cdc1c9e1a39bd1814e2e34355c665e1564a1517f27c1523ab7e
    (cons "getobject@1.0.2" (plain-file "GUIX-LICENSE.txt" "Copyright (c) 2013 \"Cowboy\" Ben Alman\n\nPermission is hereby granted, free of charge, to any person\nobtaining a copy of this software and associated documentation\nfiles (the \"Software\"), to deal in the Software without\nrestriction, including without limitation the rights to use,\ncopy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the\nSoftware is furnished to do so, subject to the following\nconditions:\n\nThe above copyright notice and this permission notice shall be\nincluded in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES\nOF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT\nHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING\nFROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR\nOTHER DEALINGS IN THE SOFTWARE.\n"))
    ;; gruntjs/grunt-cli/v1.4.3; SHA256 042f58175bdf70fdbe8bd6a42ea6d8fc87df1187f12fa8ac9b925e2125315c38
    (cons "grunt-cli@1.4.3" (plain-file "GUIX-LICENSE.txt" "Copyright (c) 2016 Tyler Kellen, contributors\n\nPermission is hereby granted, free of charge, to any person\nobtaining a copy of this software and associated documentation\nfiles (the \"Software\"), to deal in the Software without\nrestriction, including without limitation the rights to use,\ncopy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the\nSoftware is furnished to do so, subject to the following\nconditions:\n\nThe above copyright notice and this permission notice shall be\nincluded in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES\nOF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT\nHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING\nFROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR\nOTHER DEALINGS IN THE SOFTWARE.\n"))
    ;; gruntjs/grunt-contrib-concat/v1.0.1; SHA256 d4f6a96abca1ff6106a57bd4682ee47821fc9ba702dbdd3242849e17bb1d9c32
    (cons "grunt-contrib-concat@1.0.1" (plain-file "GUIX-LICENSE.txt" "Copyright (c) 2016 \"Cowboy\" Ben Alman, contributors\n\nPermission is hereby granted, free of charge, to any person\nobtaining a copy of this software and associated documentation\nfiles (the \"Software\"), to deal in the Software without\nrestriction, including without limitation the rights to use,\ncopy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the\nSoftware is furnished to do so, subject to the following\nconditions:\n\nThe above copyright notice and this permission notice shall be\nincluded in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES\nOF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT\nHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING\nFROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR\nOTHER DEALINGS IN THE SOFTWARE.\n"))
    ;; gruntjs/grunt-legacy-log-utils/v2.1.0; SHA256 1fab35169ce5ee5358d9656175bce4a81d1945cdf8b21441a44fa38776c805bb
    (cons "grunt-legacy-log-utils@2.1.0" (plain-file "GUIX-LICENSE.txt" "Copyright (c) 2016 \"Cowboy\" Ben Alman\n\nPermission is hereby granted, free of charge, to any person\nobtaining a copy of this software and associated documentation\nfiles (the \"Software\"), to deal in the Software without\nrestriction, including without limitation the rights to use,\ncopy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the\nSoftware is furnished to do so, subject to the following\nconditions:\n\nThe above copyright notice and this permission notice shall be\nincluded in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\nEXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES\nOF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND\nNONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT\nHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,\nWHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING\nFROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR\nOTHER DEALINGS IN THE SOFTWARE.\n"))
    ))

(define (record->source record)
  (let* ((fields (string-tokenize record))
         (name (list-ref fields 0))
         (version (list-ref fields 1))
         (key (string-append name "@" version))
         (supplement (assoc-ref %litegraph-license-supplements key))
         (discard-dist?
          (member name '("async" "esprima" "hooker" "js-yaml" "source-map"
                         "sprintf-js" "underscore.string"))))
    (cons key
          (origin
            (method url-fetch)
            (uri (list-ref fields 2))
            (file-name (string-append "litegraph-" name "-" version ".tar.gz"))
            (sha256 (base32 (list-ref fields 3)))
            (modules '((guix build utils)))
            (snippet
             #~(begin
                 ;; None of the discarded browser bundles, source maps, minified
                 ;; copies or tests supplies a production Grunt module.
                 (for-each
                  (lambda (file)
                    (when (file-exists? file) (delete-file-recursively file)))
                  (append '("test" "tests" "coverage" "test-browser")
                          (if #$(if discard-dist? #t #f) '("dist") '())))
                 (for-each delete-file (find-files "." "\\.min\\.js$"))
                 (when #$supplement
                   (copy-file #$supplement "GUIX-LICENSE.txt"))))))))

(define %litegraph-npm-sources
  (map record->source
       (remove string-null? (string-split %litegraph-npm-records #\newline))))
