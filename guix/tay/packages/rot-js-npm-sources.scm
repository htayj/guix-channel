;;; Locked npm source closure for rot.js's offline upstream build.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages rot-js-npm-sources)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (%rot-js-npm-sources %rot-js-npm-paths
            %rot-js-npm-path-keys))

;; Every location of rot.js 46782e2's package-lock.json except the five below
;; is replayed.  All 260 npm tarballs matched their upstream lock SHA512
;; integrity during the source audit and are fixed here by SHA256.
;;
;; Excluded locations:
;;   node_modules/fsevents -- macOS-only optional watcher with install script;
;;   node_modules/google-closure-compiler-java -- prebuilt compiler.jar, which
;;     is replaced by the source-built (tay packages rot-js-compiler) jar;
;;   node_modules/google-closure-compiler-{linux,osx,windows} -- native images.
;; The google-closure-compiler JavaScript wrapper itself remains.
;;
;; Published editable JavaScript is preserved: TypeDoc and shiki run from
;; their published, readable JavaScript.  The build-time binary object used
;; by TypeDoc's Node highlighter is vscode-oniguruma@1.7.0 release/onig.wasm,
;; SHA256 fd885c2d12e5951e59d761ebd4a006e06254b1491fd6f530c92b69fb4d8d77d9.
;; Its NOTICES.txt identifies Oniguruma 6.9.5_rev1 (BSD-2-Clause), with the
;; Microsoft MIT wrapper.  It is pinned, not rebuilt here, and is never
;; installed in rot-js.  shiki@0.9.15 also contains an unused browser WASM
;; object (different hash); the staging helper removes it, so only the
;; exactly attributed vscode-oniguruma object enters the docs build.
(define %rot-js-npm-records
  (string-append
    "@babel/cli\t7.16.0\thttps://registry.npmjs.org/@babel/cli/-/cli-7.16.0.tgz\t1zx6pyvszdwkql10js30dl9ysab06r7rjv7py0pvy2fsm9fj30ph\n"
    "@babel/code-frame\t7.18.6\thttps://registry.npmjs.org/@babel/code-frame/-/code-frame-7.18.6.tgz\t0xwrf9g8ch9h426km3kni374yiaiqvrfpligsw7ypj6pb9k49586\n"
    "@babel/compat-data\t7.21.0\thttps://registry.npmjs.org/@babel/compat-data/-/compat-data-7.21.0.tgz\t1m93jbywsyrz662cfv2wl2isqvghvkpqpcp7wpjx608g2fp2jbvq\n"
    "@babel/core\t7.16.5\thttps://registry.npmjs.org/@babel/core/-/core-7.16.5.tgz\t1b6569r2y7j4fw11casx927x3vncahagdk7lra55jksmac24zlpd\n"
    "@babel/generator\t7.21.3\thttps://registry.npmjs.org/@babel/generator/-/generator-7.21.3.tgz\t0q8iga99skqsmh65lwx8ra93xkdw7i9hprgi266aqaac5w0379bv\n"
    "@babel/helper-annotate-as-pure\t7.18.6\thttps://registry.npmjs.org/@babel/helper-annotate-as-pure/-/helper-annotate-as-pure-7.18.6.tgz\t01mila24h30156kc70ralpdx1ka4vpw6z81a7imwysqlp333n5c7\n"
    "@babel/helper-builder-binary-assignment-operator-visitor\t7.18.9\thttps://registry.npmjs.org/@babel/helper-builder-binary-assignment-operator-visitor/-/helper-builder-binary-assignment-operator-visitor-7.18.9.tgz\t0m8kc7jkq0yvj34kdmqpkp2ds5cq4myvv8c520ssdf096qmcii2d\n"
    "@babel/helper-compilation-targets\t7.20.7\thttps://registry.npmjs.org/@babel/helper-compilation-targets/-/helper-compilation-targets-7.20.7.tgz\t0am351w0avg328csc570ihxba1pkk9ck3sj18ldd5czz34qsf2r4\n"
    "@babel/helper-create-class-features-plugin\t7.21.0\thttps://registry.npmjs.org/@babel/helper-create-class-features-plugin/-/helper-create-class-features-plugin-7.21.0.tgz\t0lbhii1xzpkbbxcvfix5fgjv5qjncrag2fjcbfv0h3w88anrarp3\n"
    "@babel/helper-create-regexp-features-plugin\t7.21.0\thttps://registry.npmjs.org/@babel/helper-create-regexp-features-plugin/-/helper-create-regexp-features-plugin-7.21.0.tgz\t0qiwm8p854kjmckkc55saz2kjr9v95gcjmld4by4k50sqppycjvb\n"
    "@babel/helper-define-polyfill-provider\t0.3.3\thttps://registry.npmjs.org/@babel/helper-define-polyfill-provider/-/helper-define-polyfill-provider-0.3.3.tgz\t0zsl099145h4872xwck1c3q4zsa7vhc1d10w1kml1kbwhv4lcccq\n"
    "@babel/helper-environment-visitor\t7.18.9\thttps://registry.npmjs.org/@babel/helper-environment-visitor/-/helper-environment-visitor-7.18.9.tgz\t1wssai2gzphhza5wd1yf43n52b33v4y864vsy1fy26972wpirah0\n"
    "@babel/helper-explode-assignable-expression\t7.18.6\thttps://registry.npmjs.org/@babel/helper-explode-assignable-expression/-/helper-explode-assignable-expression-7.18.6.tgz\t0cb53z9f908q7mky783r4avyq34i1dnswpxzwjv2l15f9jbmbi6i\n"
    "@babel/helper-function-name\t7.21.0\thttps://registry.npmjs.org/@babel/helper-function-name/-/helper-function-name-7.21.0.tgz\t0nwfky9x9f14s5z3brplvs0zay55bi73dka32nzl10xq8qmykaa0\n"
    "@babel/helper-hoist-variables\t7.18.6\thttps://registry.npmjs.org/@babel/helper-hoist-variables/-/helper-hoist-variables-7.18.6.tgz\t1v074w48527pb5ifyj7304lclnaxzbgrbhwqcyg0ickgz2pad4fd\n"
    "@babel/helper-member-expression-to-functions\t7.21.0\thttps://registry.npmjs.org/@babel/helper-member-expression-to-functions/-/helper-member-expression-to-functions-7.21.0.tgz\t1d1isnxfpc69k0cmmhkwbyp9hb3q6j3q8xmjkm31irid908nmlsn\n"
    "@babel/helper-module-imports\t7.18.6\thttps://registry.npmjs.org/@babel/helper-module-imports/-/helper-module-imports-7.18.6.tgz\t0s35ikbih4rx15cf76p9j970vfbbc2z82jfp29g3k1jx8ja0wicv\n"
    "@babel/helper-module-transforms\t7.21.2\thttps://registry.npmjs.org/@babel/helper-module-transforms/-/helper-module-transforms-7.21.2.tgz\t0cn9kjphzsvpyc48315x7kgwwsha37dbk4slk12wh3gakvp3rg6d\n"
    "@babel/helper-optimise-call-expression\t7.18.6\thttps://registry.npmjs.org/@babel/helper-optimise-call-expression/-/helper-optimise-call-expression-7.18.6.tgz\t1dz56ba5vn7cpc5mkbninf2d065dmjy1b1j709xxc7igir0xcjz8\n"
    "@babel/helper-plugin-utils\t7.20.2\thttps://registry.npmjs.org/@babel/helper-plugin-utils/-/helper-plugin-utils-7.20.2.tgz\t17wamw98bq242cq6scrcqr0q3gs2pjr00ahf01gj3q1zsxzkimm8\n"
    "@babel/helper-remap-async-to-generator\t7.18.9\thttps://registry.npmjs.org/@babel/helper-remap-async-to-generator/-/helper-remap-async-to-generator-7.18.9.tgz\t0bjw6j6999xw4cwlrjxn6kj9xzhhkf5i2c8ck31nkc2xrwciq2zl\n"
    "@babel/helper-replace-supers\t7.20.7\thttps://registry.npmjs.org/@babel/helper-replace-supers/-/helper-replace-supers-7.20.7.tgz\t029ph1fdifnlvv6ws57m4l56hfqmzckbx4qgqqcai72s7bzg5x8r\n"
    "@babel/helper-simple-access\t7.20.2\thttps://registry.npmjs.org/@babel/helper-simple-access/-/helper-simple-access-7.20.2.tgz\t0f3mn0xsq5xm4ajq3026m7bx3c0ai8librlyar67zaam0dg9039v\n"
    "@babel/helper-skip-transparent-expression-wrappers\t7.20.0\thttps://registry.npmjs.org/@babel/helper-skip-transparent-expression-wrappers/-/helper-skip-transparent-expression-wrappers-7.20.0.tgz\t0xx1maf313cpsgj6f8kll465jk9k888b4gnpglbzc02qhhbkwx6w\n"
    "@babel/helper-split-export-declaration\t7.18.6\thttps://registry.npmjs.org/@babel/helper-split-export-declaration/-/helper-split-export-declaration-7.18.6.tgz\t1xaqdwbrzl2gkn99jvma3pvjnnmhr9pfxrpvjxqqhhvx12ygp1d9\n"
    "@babel/helper-string-parser\t7.19.4\thttps://registry.npmjs.org/@babel/helper-string-parser/-/helper-string-parser-7.19.4.tgz\t0k0v7xhxx5galbaib49brnzm5xc0192ksxpwwf0ihhns4m9vwr1q\n"
    "@babel/helper-validator-identifier\t7.19.1\thttps://registry.npmjs.org/@babel/helper-validator-identifier/-/helper-validator-identifier-7.19.1.tgz\t1lssbvsz0sl2czmzh53jg315bwvwll3xlw4xv9jwsnv7qhfd5c3p\n"
    "@babel/helper-validator-option\t7.21.0\thttps://registry.npmjs.org/@babel/helper-validator-option/-/helper-validator-option-7.21.0.tgz\t0bw5aj8jwz55d9lpbcbdxsw6ilhsd06vv3s20ms4s13hgilyhh23\n"
    "@babel/helper-wrap-function\t7.20.5\thttps://registry.npmjs.org/@babel/helper-wrap-function/-/helper-wrap-function-7.20.5.tgz\t1qshad8pkrblgckxpj28gmc2cj631zdi708wv3vh7szxmicz8x7q\n"
    "@babel/helpers\t7.21.0\thttps://registry.npmjs.org/@babel/helpers/-/helpers-7.21.0.tgz\t1dx6yc77hh3wfx2a75f83sgv7z6hmh1x6bhp8d4f561wwfn3cka5\n"
    "@babel/highlight\t7.18.6\thttps://registry.npmjs.org/@babel/highlight/-/highlight-7.18.6.tgz\t0r56rg6npzy9kcffim5ibinx4q1m1wpyxaa4swyic6q6v886qkpm\n"
    "@babel/parser\t7.21.3\thttps://registry.npmjs.org/@babel/parser/-/parser-7.21.3.tgz\t1bfnzip2b6bxsa85w4xjv14k98g6ylw6b5c3g0cxs627hkcpijfq\n"
    "@babel/plugin-bugfix-safari-id-destructuring-collision-in-function-expression\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-bugfix-safari-id-destructuring-collision-in-function-expression/-/plugin-bugfix-safari-id-destructuring-collision-in-function-expression-7.18.6.tgz\t0xhplrjs49ki8n9amv51zzf740xa9irsjzdbdys29gp67i9fblhk\n"
    "@babel/plugin-bugfix-v8-spread-parameters-in-optional-chaining\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-bugfix-v8-spread-parameters-in-optional-chaining/-/plugin-bugfix-v8-spread-parameters-in-optional-chaining-7.20.7.tgz\t0k5ginh1zxkhnk39d9lkmywdkc591qnb1v6dzksmlkd677d79idc\n"
    "@babel/plugin-proposal-async-generator-functions\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-proposal-async-generator-functions/-/plugin-proposal-async-generator-functions-7.20.7.tgz\t0hyc5f7y8f915m8i11qy5ziyay0cp9gqgx3r7l3a3vyi15xsivqc\n"
    "@babel/plugin-proposal-class-properties\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-class-properties/-/plugin-proposal-class-properties-7.18.6.tgz\t037jxjhbg8j44s3n8a616ikhv1kkmykcf2bbqw9ib124lfz2lzk6\n"
    "@babel/plugin-proposal-class-static-block\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-proposal-class-static-block/-/plugin-proposal-class-static-block-7.21.0.tgz\t0cnhrkmbiza1clqysbcxj3vrs1pjcld5l2j232knfja1gq7cagn1\n"
    "@babel/plugin-proposal-dynamic-import\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-dynamic-import/-/plugin-proposal-dynamic-import-7.18.6.tgz\t1pkixzsaqjh4m3d5bbapyg56bc96cpij8zskg4srr283hnrdydn4\n"
    "@babel/plugin-proposal-export-namespace-from\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-proposal-export-namespace-from/-/plugin-proposal-export-namespace-from-7.18.9.tgz\t0y4n45z53wjbf61yg367pc23akapgpil0qdl437y9cywilkqj9g0\n"
    "@babel/plugin-proposal-json-strings\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-json-strings/-/plugin-proposal-json-strings-7.18.6.tgz\t1wifis1x5d5y63b6ika4srqv6cgai9w6y6myps3cz7rizn157x1q\n"
    "@babel/plugin-proposal-logical-assignment-operators\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-proposal-logical-assignment-operators/-/plugin-proposal-logical-assignment-operators-7.20.7.tgz\t044b1mldgzjafnmnvakvmf9hzlldj45s7pr3028g85zpz2793ysy\n"
    "@babel/plugin-proposal-nullish-coalescing-operator\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-nullish-coalescing-operator/-/plugin-proposal-nullish-coalescing-operator-7.18.6.tgz\t0n2pycphssbdsl4bx3v218hgmb8i41xw0cfzf87db7l62rz7zvyn\n"
    "@babel/plugin-proposal-numeric-separator\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-numeric-separator/-/plugin-proposal-numeric-separator-7.18.6.tgz\t03vn80zvpzsayi47cx7mxsrnwb0xaj68sl340mi3w925vcxs91mc\n"
    "@babel/plugin-proposal-object-rest-spread\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-proposal-object-rest-spread/-/plugin-proposal-object-rest-spread-7.20.7.tgz\t0lsjrfp73kd94v87745xkh1rv345qgi0kn31qi3amgpxw00fjzd5\n"
    "@babel/plugin-proposal-optional-catch-binding\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-optional-catch-binding/-/plugin-proposal-optional-catch-binding-7.18.6.tgz\t0w3clx3nbfl9xxi2lcvdbw1zn4fbwwg793bvqz54xihy4w04kikk\n"
    "@babel/plugin-proposal-optional-chaining\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-proposal-optional-chaining/-/plugin-proposal-optional-chaining-7.21.0.tgz\t1hsy0xaqa5fiyzm6by6fx40675c79n4sx805zh7mqn3hfa7vzi6p\n"
    "@babel/plugin-proposal-private-methods\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-private-methods/-/plugin-proposal-private-methods-7.18.6.tgz\t0r29ljkncgs298h8mh36vn1lzk56jvz96a0yfjzd0c2qiafm54hj\n"
    "@babel/plugin-proposal-private-property-in-object\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-proposal-private-property-in-object/-/plugin-proposal-private-property-in-object-7.21.0.tgz\t0fgrmr7aj6sqndkz1fiqqlpi1mavjan1n7c45c1nksvs7jy2jzq2\n"
    "@babel/plugin-proposal-unicode-property-regex\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-proposal-unicode-property-regex/-/plugin-proposal-unicode-property-regex-7.18.6.tgz\t04pav6kmk17y0zk0gp5j25yd3aj1s0pirvh1r7y37xq1qjnwj3rp\n"
    "@babel/plugin-syntax-async-generators\t7.8.4\thttps://registry.npmjs.org/@babel/plugin-syntax-async-generators/-/plugin-syntax-async-generators-7.8.4.tgz\t173f36ic59mxj1yq02syr4vagkn3rzyi0dy2c64z36r5dpli069l\n"
    "@babel/plugin-syntax-class-properties\t7.12.13\thttps://registry.npmjs.org/@babel/plugin-syntax-class-properties/-/plugin-syntax-class-properties-7.12.13.tgz\t129qm1c80wh9b0ccsd4akrqq2c55yk43yvpkd09k0f0dwlzpjrqj\n"
    "@babel/plugin-syntax-class-static-block\t7.14.5\thttps://registry.npmjs.org/@babel/plugin-syntax-class-static-block/-/plugin-syntax-class-static-block-7.14.5.tgz\t0mhlcmf64cgzahmqai6fga4zd2bxya5s8gimkv19czpbb4l1ydrb\n"
    "@babel/plugin-syntax-dynamic-import\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-dynamic-import/-/plugin-syntax-dynamic-import-7.8.3.tgz\t19s5hnxdb02y9w0h6mdwl828rss4igybvnmam6r5qh5kgb2d6pq9\n"
    "@babel/plugin-syntax-export-namespace-from\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-export-namespace-from/-/plugin-syntax-export-namespace-from-7.8.3.tgz\t0iz3qbfdyqxm29yl3i2a4yqx1kn5wf5kpn6h2040svl5svfh0l5k\n"
    "@babel/plugin-syntax-json-strings\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-json-strings/-/plugin-syntax-json-strings-7.8.3.tgz\t03gjjpcmlxrsg48nb21wqygr39nd7m7lyvpz49ppdpfmsyawq6sa\n"
    "@babel/plugin-syntax-logical-assignment-operators\t7.10.4\thttps://registry.npmjs.org/@babel/plugin-syntax-logical-assignment-operators/-/plugin-syntax-logical-assignment-operators-7.10.4.tgz\t0afk3kd2zwf32q6j4zd11i1xvjpdrjqpg4v04052mic8hmb2m34g\n"
    "@babel/plugin-syntax-nullish-coalescing-operator\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-nullish-coalescing-operator/-/plugin-syntax-nullish-coalescing-operator-7.8.3.tgz\t1qijfhjrc79g96gqdqk2l5jqpgpf83q77xyxjb8gc3h93kd15ws1\n"
    "@babel/plugin-syntax-numeric-separator\t7.10.4\thttps://registry.npmjs.org/@babel/plugin-syntax-numeric-separator/-/plugin-syntax-numeric-separator-7.10.4.tgz\t0icp40jlijif4kaq431kimqsg35cvryy9j3lszxhwqxad5hbp30s\n"
    "@babel/plugin-syntax-object-rest-spread\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-object-rest-spread/-/plugin-syntax-object-rest-spread-7.8.3.tgz\t0ckdr3y5ns0cxpn0vw9qn4qmp2wmk1vxwk2pcyhxbsn38p8hn9s2\n"
    "@babel/plugin-syntax-optional-catch-binding\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-optional-catch-binding/-/plugin-syntax-optional-catch-binding-7.8.3.tgz\t19zvb2jzfhxa15i7ff1p0pnw3bfg2fp0f1yqa3f29mw89g2r51cl\n"
    "@babel/plugin-syntax-optional-chaining\t7.8.3\thttps://registry.npmjs.org/@babel/plugin-syntax-optional-chaining/-/plugin-syntax-optional-chaining-7.8.3.tgz\t1r1yd6zfagk3nhwn3zy25sbdlfwzfwpn4jqz1qhp5hvs3pgxr5zm\n"
    "@babel/plugin-syntax-private-property-in-object\t7.14.5\thttps://registry.npmjs.org/@babel/plugin-syntax-private-property-in-object/-/plugin-syntax-private-property-in-object-7.14.5.tgz\t1pjlz6yczp89g50bjnjja8rlkrhc359qw1kyvfw0q2msgq2aks9g\n"
    "@babel/plugin-syntax-top-level-await\t7.14.5\thttps://registry.npmjs.org/@babel/plugin-syntax-top-level-await/-/plugin-syntax-top-level-await-7.14.5.tgz\t16j74zrvrvffqxncgpy9rks920wdqp52gq47ik46qnib4jq4qaff\n"
    "@babel/plugin-transform-arrow-functions\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-transform-arrow-functions/-/plugin-transform-arrow-functions-7.20.7.tgz\t1nxyml3xd1r2r3jdwx951ysf2yk7vncg2lxifjzdi6rqymrha5j0\n"
    "@babel/plugin-transform-async-to-generator\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-transform-async-to-generator/-/plugin-transform-async-to-generator-7.20.7.tgz\t0p4qxdnjb9vdbnkgvjnp6m0jx5z2lr1pycd30k4frn9d1sg6fmvh\n"
    "@babel/plugin-transform-block-scoped-functions\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-block-scoped-functions/-/plugin-transform-block-scoped-functions-7.18.6.tgz\t1rs7p2n3qi0zjk3lf3a7g3y8vrckx2g78ja10byzagb1h2zab95r\n"
    "@babel/plugin-transform-block-scoping\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-transform-block-scoping/-/plugin-transform-block-scoping-7.21.0.tgz\t0ysrfgqlhmwnb89ij4y7a8p2np7a6d593yi8aig074isqb0fb3mn\n"
    "@babel/plugin-transform-classes\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-transform-classes/-/plugin-transform-classes-7.21.0.tgz\t1ilxcha10p50qw0rd94lcdkhzhwwl8x1158h9hjsbpnrfl1yhi4c\n"
    "@babel/plugin-transform-computed-properties\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-transform-computed-properties/-/plugin-transform-computed-properties-7.20.7.tgz\t1si1lckzc3kbvr4csw8hsd670ng64g2q1pxa5ljxypjm8x83wdvv\n"
    "@babel/plugin-transform-destructuring\t7.21.3\thttps://registry.npmjs.org/@babel/plugin-transform-destructuring/-/plugin-transform-destructuring-7.21.3.tgz\t1jpdnlhsy06n3byli6fn8kvd9gkn8m6vnhx8plcjqxka9gfiiy3w\n"
    "@babel/plugin-transform-dotall-regex\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-dotall-regex/-/plugin-transform-dotall-regex-7.18.6.tgz\t0b5wckk55k4ja4i905r9vbsf2h5jz9hmzminv9mc0xk81m2s65kw\n"
    "@babel/plugin-transform-duplicate-keys\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-transform-duplicate-keys/-/plugin-transform-duplicate-keys-7.18.9.tgz\t02dv8k1pw41nkzwi2dniqvczh4xw5lqdsmqdi47pv54csmcfkckc\n"
    "@babel/plugin-transform-exponentiation-operator\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-exponentiation-operator/-/plugin-transform-exponentiation-operator-7.18.6.tgz\t01w690wd3whmhjidw35fkrpj34vzrn1jaxvhgszpsc90w66b76ji\n"
    "@babel/plugin-transform-for-of\t7.21.0\thttps://registry.npmjs.org/@babel/plugin-transform-for-of/-/plugin-transform-for-of-7.21.0.tgz\t1yhl8ycfjxr5mcbasr654a64wh2bfz3284cdz45gxcf9pw9dgppd\n"
    "@babel/plugin-transform-function-name\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-transform-function-name/-/plugin-transform-function-name-7.18.9.tgz\t012nlda48ch93fnxmgmpy8mpg6d91wyb0njq2arx2dvh5xmx5xzz\n"
    "@babel/plugin-transform-literals\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-transform-literals/-/plugin-transform-literals-7.18.9.tgz\t15kgwzra7czyfpsxrsa3c3wslv1lvddi9is8v3h6i85z3dy1d190\n"
    "@babel/plugin-transform-member-expression-literals\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-member-expression-literals/-/plugin-transform-member-expression-literals-7.18.6.tgz\t0d67bfxwj2zn1vcslf110wls2w9hydxam36kkl4qkw8arh2qqh1k\n"
    "@babel/plugin-transform-modules-amd\t7.20.11\thttps://registry.npmjs.org/@babel/plugin-transform-modules-amd/-/plugin-transform-modules-amd-7.20.11.tgz\t0y766dmnmhsnp7c1ybr3p767i6dga2b0r7vwzvv7dv7lbq80gqwb\n"
    "@babel/plugin-transform-modules-commonjs\t7.21.2\thttps://registry.npmjs.org/@babel/plugin-transform-modules-commonjs/-/plugin-transform-modules-commonjs-7.21.2.tgz\t0l74b5p2bqg0n9pl4rma6zwgrvwblcr1kgs44z8w5snv9l66rq0b\n"
    "@babel/plugin-transform-modules-systemjs\t7.20.11\thttps://registry.npmjs.org/@babel/plugin-transform-modules-systemjs/-/plugin-transform-modules-systemjs-7.20.11.tgz\t1mfn6c1k3bvxqpq82pr5j6zvapwiap0my8zr88yiajh1ghr5yc74\n"
    "@babel/plugin-transform-modules-umd\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-modules-umd/-/plugin-transform-modules-umd-7.18.6.tgz\t07bk22v1004l2n2kj5v2a0a84760h8ph4wfkfnp7xga83x5mqrc4\n"
    "@babel/plugin-transform-named-capturing-groups-regex\t7.20.5\thttps://registry.npmjs.org/@babel/plugin-transform-named-capturing-groups-regex/-/plugin-transform-named-capturing-groups-regex-7.20.5.tgz\t0g91b3vwxwn0l7xyj7zacmdiqf1n0da6qcbwphc2qwhymsgmrqr7\n"
    "@babel/plugin-transform-new-target\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-new-target/-/plugin-transform-new-target-7.18.6.tgz\t02lxp42ls2wpgimhnbqkl2ppdirhyps7igy6qwxv4ipgv6i9wmmw\n"
    "@babel/plugin-transform-object-super\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-object-super/-/plugin-transform-object-super-7.18.6.tgz\t0d7ms82bifk5agahw6190x52dzkhakzdwb37g5sraiyavp4z3ax2\n"
    "@babel/plugin-transform-parameters\t7.21.3\thttps://registry.npmjs.org/@babel/plugin-transform-parameters/-/plugin-transform-parameters-7.21.3.tgz\t0a805n0lvjpib8g6l1yda04kyywakjk5m17xbi3ngn8p0bqyld63\n"
    "@babel/plugin-transform-property-literals\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-property-literals/-/plugin-transform-property-literals-7.18.6.tgz\t0fflx6zgy7h2cvr5pq2ivsny5vfw9v2q7v8l4snpkv3k96jn0y4r\n"
    "@babel/plugin-transform-regenerator\t7.20.5\thttps://registry.npmjs.org/@babel/plugin-transform-regenerator/-/plugin-transform-regenerator-7.20.5.tgz\t1gq5qb2dp58zfcg4m9bmj77jd8fvnbi919rfm8ams8n9i1bavd63\n"
    "@babel/plugin-transform-reserved-words\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-reserved-words/-/plugin-transform-reserved-words-7.18.6.tgz\t0igmqpnsd8j1vsq3sdw0grjakscx6s3q2jhll3cqcdh9gp3aa3kz\n"
    "@babel/plugin-transform-shorthand-properties\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-shorthand-properties/-/plugin-transform-shorthand-properties-7.18.6.tgz\t042rbbi2pdgxfhh3fkizad2d4khlfikvzb0mr797m1plk74bnlxk\n"
    "@babel/plugin-transform-spread\t7.20.7\thttps://registry.npmjs.org/@babel/plugin-transform-spread/-/plugin-transform-spread-7.20.7.tgz\t0p1y9b1bbh8yngbbrlj42qz35vmppzdiyywvmxfy31p1r8ahws9r\n"
    "@babel/plugin-transform-sticky-regex\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-sticky-regex/-/plugin-transform-sticky-regex-7.18.6.tgz\t029dw74a3xp13y6pwap5j5jk0dh60d3fki9yhc5id9kdkgg8kam4\n"
    "@babel/plugin-transform-template-literals\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-transform-template-literals/-/plugin-transform-template-literals-7.18.9.tgz\t15awhj3gxd31p153sbhvhk5qlaxcnj7whfvq6ng3gi3yndc5gz16\n"
    "@babel/plugin-transform-typeof-symbol\t7.18.9\thttps://registry.npmjs.org/@babel/plugin-transform-typeof-symbol/-/plugin-transform-typeof-symbol-7.18.9.tgz\t0nsjij0mf7ssj9cljbrijpglnfa6mga80g4xzif8g5ff5m2y3y0n\n"
    "@babel/plugin-transform-unicode-escapes\t7.18.10\thttps://registry.npmjs.org/@babel/plugin-transform-unicode-escapes/-/plugin-transform-unicode-escapes-7.18.10.tgz\t0a7qf69n04n2843w0ccjvbm1appljkwq0csmg8l997if9isv5g0f\n"
    "@babel/plugin-transform-unicode-regex\t7.18.6\thttps://registry.npmjs.org/@babel/plugin-transform-unicode-regex/-/plugin-transform-unicode-regex-7.18.6.tgz\t05grz31n6rmrf7j9rvf6nxc5c064adnwspq5j4vjnpl66g50a29q\n"
    "@babel/preset-env\t7.16.5\thttps://registry.npmjs.org/@babel/preset-env/-/preset-env-7.16.5.tgz\t0rq7sglfrc40xrj93s3x80flsr25bhpj0q47gbn4p4bn0wqvszrs\n"
    "@babel/preset-modules\t0.1.5\thttps://registry.npmjs.org/@babel/preset-modules/-/preset-modules-0.1.5.tgz\t1vvp60vqbhw937qizl4ylad8hrw1b7iic3bwkdv8g6k0cs9b3yds\n"
    "@babel/regjsgen\t0.8.0\thttps://registry.npmjs.org/@babel/regjsgen/-/regjsgen-0.8.0.tgz\t1j0y6jipdnv7xkdx3jjjf31w4q3m1gyp0r04v2cghlw5z8cwd45v\n"
    "@babel/runtime\t7.21.0\thttps://registry.npmjs.org/@babel/runtime/-/runtime-7.21.0.tgz\t19ji5781dznj4f5hlxn865djrkzkp5s61b84cm46q28hq6jlhvxl\n"
    "@babel/template\t7.20.7\thttps://registry.npmjs.org/@babel/template/-/template-7.20.7.tgz\t00mza8lm7kpwwm2q459la7ibl2a62p7l568yi2gxf82cg20h4gsm\n"
    "@babel/traverse\t7.21.3\thttps://registry.npmjs.org/@babel/traverse/-/traverse-7.21.3.tgz\t0cmhk1vq632arbsr9slqgyi4yqb6sizxhhvwxjy9ydh8dsih2sii\n"
    "@babel/types\t7.21.3\thttps://registry.npmjs.org/@babel/types/-/types-7.21.3.tgz\t0r1lrmh7h9yfqhwcs8iira4hhxzw7i8wqjn1w6bimmlz1wk99cxc\n"
    "@jridgewell/gen-mapping\t0.3.2\thttps://registry.npmjs.org/@jridgewell/gen-mapping/-/gen-mapping-0.3.2.tgz\t1zf6rzj64c6yiqyhlc5d2sbyvpcp831gqdqnx3pxs19jcvczlxl1\n"
    "@jridgewell/resolve-uri\t3.1.0\thttps://registry.npmjs.org/@jridgewell/resolve-uri/-/resolve-uri-3.1.0.tgz\t1c0nxqsc2pjm4d5glk03s0a8q7fq5a2hi7kdj8kkp0dl72mv4k7y\n"
    "@jridgewell/set-array\t1.1.2\thttps://registry.npmjs.org/@jridgewell/set-array/-/set-array-1.1.2.tgz\t1zq7ws2fnaqgs6dzg9nnd9li45drq1bk76cabq7m1309j8r7g1bm\n"
    "@jridgewell/sourcemap-codec\t1.4.14\thttps://registry.npmjs.org/@jridgewell/sourcemap-codec/-/sourcemap-codec-1.4.14.tgz\t0h9rqnq874vq3py92vrzmaw266cc0s1vfi0s8i1bmbh4if00whxp\n"
    "@jridgewell/trace-mapping\t0.3.17\thttps://registry.npmjs.org/@jridgewell/trace-mapping/-/trace-mapping-0.3.17.tgz\t1h2xd91z6w9lbyd4a4alb69wwi8dpiy0m7izmlikxafjxld8iclg\n"
    "@nicolo-ribaudo/chokidar-2\t2.1.8-no-fsevents.3\thttps://registry.npmjs.org/@nicolo-ribaudo/chokidar-2/-/chokidar-2-2.1.8-no-fsevents.3.tgz\t1zgk3zr54kg43b2qc63030icid8kjdr11lznks5fyw5qn2jq7jid\n"
    "@types/node\t17.0.2\thttps://registry.npmjs.org/@types/node/-/node-17.0.2.tgz\t0byky81wcg4zg83sdw8h0sdj7ba4f75520ak24gmkip0qb51ffws\n"
    "@types/yauzl\t2.10.0\thttps://registry.npmjs.org/@types/yauzl/-/yauzl-2.10.0.tgz\t1z0nlhr1gj3mf765fjq3cg5sw124rihw8prks4s0fm643hq1rhvv\n"
    "agent-base\t6.0.2\thttps://registry.npmjs.org/agent-base/-/agent-base-6.0.2.tgz\t0cg85gngrap12xzz8ibdjw98hcfhgcidg2w7ll7whsrf59ps0vdw\n"
    "ansi-styles\t3.2.1\thttps://registry.npmjs.org/ansi-styles/-/ansi-styles-3.2.1.tgz\t1wqd08glq159q724kvpi6nnf87biajr749a7r9c84xm639g6463k\n"
    "anymatch\t3.1.3\thttps://registry.npmjs.org/anymatch/-/anymatch-3.1.3.tgz\t13zpp0hqd1racg5vwp8qpfh1y5igpyi6ff32y4ks2wrbhdn9sqmv\n"
    "babel-plugin-polyfill-corejs2\t0.3.3\thttps://registry.npmjs.org/babel-plugin-polyfill-corejs2/-/babel-plugin-polyfill-corejs2-0.3.3.tgz\t1srhh3q09d281n4q36n21igqh4d0502js6lmcgjj1lrnar8l1fpv\n"
    "babel-plugin-polyfill-corejs3\t0.4.0\thttps://registry.npmjs.org/babel-plugin-polyfill-corejs3/-/babel-plugin-polyfill-corejs3-0.4.0.tgz\t1jaafn0lqgm39vc7064l7yip4kj2p0rybgwx711m011jq1k0didb\n"
    "babel-plugin-polyfill-regenerator\t0.3.1\thttps://registry.npmjs.org/babel-plugin-polyfill-regenerator/-/babel-plugin-polyfill-regenerator-0.3.1.tgz\t108m8wx9kfia53pxzp6pv38j1xip59q1y40zdlyay8cfqy31vfv6\n"
    "balanced-match\t1.0.0\thttps://registry.npmjs.org/balanced-match/-/balanced-match-1.0.0.tgz\t1bgzp9jp8ws0kdfgq8h6w3qz8cljyzgcrmxypxkgbknk28n615i8\n"
    "base64-js\t1.5.1\thttps://registry.npmjs.org/base64-js/-/base64-js-1.5.1.tgz\t118a46skxnrgx5bdd68ny9xxjcvyb7b1clj2hf82d196nm2skdxi\n"
    "binary-extensions\t2.2.0\thttps://registry.npmjs.org/binary-extensions/-/binary-extensions-2.2.0.tgz\t08ynqw2044jlg0vmxgrmzrppirahd8734i2a67ql917410igm08g\n"
    "bl/node_modules/readable-stream\t3.6.2\thttps://registry.npmjs.org/readable-stream/-/readable-stream-3.6.2.tgz\t0pdb0mrh95ks672ikgj8frx9nh078bfyngknj70ak2iibv06dn7d\n"
    "bl\t4.1.0\thttps://registry.npmjs.org/bl/-/bl-4.1.0.tgz\t1jx7lm4mr80nzdw0k873llpl1x6i1n0m422v1scwla8qml4vkpl3\n"
    "brace-expansion\t1.1.11\thttps://registry.npmjs.org/brace-expansion/-/brace-expansion-1.1.11.tgz\t1nlmjvlwlp88knblnayns0brr7a9m2fynrlwq425lrpb4mcn9gc4\n"
    "braces\t3.0.2\thttps://registry.npmjs.org/braces/-/braces-3.0.2.tgz\t1kpaa113m54qc1n2zvs0p1ika4s9dzvcczlw8q66xkyliy982n3k\n"
    "browserslist\t4.21.5\thttps://registry.npmjs.org/browserslist/-/browserslist-4.21.5.tgz\t168iyzh1y9lwdjf2w9d2z7v9p17zw1q1p16mbgp3jd7l6fyc25iw\n"
    "buffer-crc32\t0.2.13\thttps://registry.npmjs.org/buffer-crc32/-/buffer-crc32-0.2.13.tgz\t0vf6adpqimbz921y729mf91pvghihj44js2ck5ci44zh4x21bl97\n"
    "buffer\t5.7.1\thttps://registry.npmjs.org/buffer/-/buffer-5.7.1.tgz\t1g60az00dzb1grcszyg12gyrl9jr9bwvrk2y9xjdwym3nxasrgwq\n"
    "caniuse-lite\t1.0.30001467\thttps://registry.npmjs.org/caniuse-lite/-/caniuse-lite-1.0.30001467.tgz\t1pkmhnhgg7pr8yckws0bvdg3i7fjfxiz2dps7m6jaxzhwgqn1ibz\n"
    "chalk\t2.4.2\thttps://registry.npmjs.org/chalk/-/chalk-2.4.2.tgz\t0wf6hln5gcjb2n8p18gag6idghl6dfq4if6pxa6s1jqnwr94x26h\n"
    "chokidar\t3.5.3\thttps://registry.npmjs.org/chokidar/-/chokidar-3.5.3.tgz\t06jwjf2v28r36s7v5zwbm32q4f1605gfcqghfvg631lr2wrd5jrf\n"
    "chownr\t1.1.4\thttps://registry.npmjs.org/chownr/-/chownr-1.1.4.tgz\t0gl3b5fqhvgq3glfdq341jmkyi7hmw4kdg4wd3pis0sdsc2kx1kj\n"
    "clone-buffer\t1.0.0\thttps://registry.npmjs.org/clone-buffer/-/clone-buffer-1.0.0.tgz\t0v4mnbc5gp5c6pvnsg2z28q67p7pimzm2mnxmcrryss2h674v1f9\n"
    "clone-stats\t1.0.0\thttps://registry.npmjs.org/clone-stats/-/clone-stats-1.0.0.tgz\t11gskhkvkmzp1ddamqkfzgflfgkvq8kh6ds1mm6s62pvikf0bxfa\n"
    "clone\t2.1.2\thttps://registry.npmjs.org/clone/-/clone-2.1.2.tgz\t0gg90kb5jpm6bcmqfhvmfbx8dralysv5v9ph8b38a89ni9hkmxkx\n"
    "cloneable-readable\t1.1.2\thttps://registry.npmjs.org/cloneable-readable/-/cloneable-readable-1.1.2.tgz\t0lr5ml5sxbfz5hbxv5l2iajqj3cgirjpch01g1a8gxc81v9s2500\n"
    "color-convert\t1.9.3\thttps://registry.npmjs.org/color-convert/-/color-convert-1.9.3.tgz\t1ahbdssv1qgwlzvhv7731hpfgz8wny0619x97b7n5x9lckj17i0j\n"
    "color-name\t1.1.3\thttps://registry.npmjs.org/color-name/-/color-name-1.1.3.tgz\t0kkq17s5yg6lg8ncg2nls6asih58qafn7wbrcgmwnqr5zdqk7vxh\n"
    "commander\t4.1.1\thttps://registry.npmjs.org/commander/-/commander-4.1.1.tgz\t1cxp6ibyy2y3756dl7bnab5wji64a73bg88v70n0w4gz1g54fh6x\n"
    "concat-map\t0.0.1\thttps://registry.npmjs.org/concat-map/-/concat-map-0.0.1.tgz\t0qa2zqn9rrr2fqdki44s4s2dk2d8307i4556kv25h06g43b2v41m\n"
    "convert-source-map\t1.9.0\thttps://registry.npmjs.org/convert-source-map/-/convert-source-map-1.9.0.tgz\t0l5hs8bf8dy2gkw5i4gfr7w1rhhla2hclmms819j7i4i5x9bjwm1\n"
    "core-js-compat\t3.29.1\thttps://registry.npmjs.org/core-js-compat/-/core-js-compat-3.29.1.tgz\t0vx3qmfcd3ck3ql1b40i390b7dyhzc46g5i4z2mmqbbyswd3k3r4\n"
    "core-util-is\t1.0.2\thttps://registry.npmjs.org/core-util-is/-/core-util-is-1.0.2.tgz\t164k94d9bdzw1335kzakj7hflhnnixpx4n6ydbhf7vbrcnmlv954\n"
    "debug\t4.3.4\thttps://registry.npmjs.org/debug/-/debug-4.3.4.tgz\t1kwbyb5m63bz8a2bvhy4gsnsma6ks5wa4w5qya6qb9ip5sdjr4h4\n"
    "devtools-protocol\t0.0.937139\thttps://registry.npmjs.org/devtools-protocol/-/devtools-protocol-0.0.937139.tgz\t1jx6qihkaqcbyq4nb5g5jv0gbk78p6y4n1csk4795wxyxqsjjjkd\n"
    "electron-to-chromium\t1.4.332\thttps://registry.npmjs.org/electron-to-chromium/-/electron-to-chromium-1.4.332.tgz\t1kxz0v6m9mll5mkas86qlk3inja3pm34386r7b94h22nii1lgaph\n"
    "end-of-stream\t1.4.4\thttps://registry.npmjs.org/end-of-stream/-/end-of-stream-1.4.4.tgz\t1d8dvwmq5krcjakr2s7b2dwh8x6zgs8qj8mdwkgxsvx7rgqfr2qb\n"
    "escalade\t3.1.1\thttps://registry.npmjs.org/escalade/-/escalade-3.1.1.tgz\t17d7icirlarj6mjx321z04klpvjsxwga8c8svai2547bid131y30\n"
    "escape-string-regexp\t1.0.5\thttps://registry.npmjs.org/escape-string-regexp/-/escape-string-regexp-1.0.5.tgz\t0iy3jirnnslnfwk8wa5xkg56fnbmg7bsv5v2a1s0qgbnfqp7j375\n"
    "esutils\t2.0.3\thttps://registry.npmjs.org/esutils/-/esutils-2.0.3.tgz\t03v4y32k50mbxwv70prr7ghwg59vd5gyxsdsbdikqnj919rvvbf5\n"
    "extract-zip\t2.0.1\thttps://registry.npmjs.org/extract-zip/-/extract-zip-2.0.1.tgz\t1d6sffrprp0na74i7yaprqhdhlr2n3znws509jv7nqgscypf1d2r\n"
    "fd-slicer\t1.1.0\thttps://registry.npmjs.org/fd-slicer/-/fd-slicer-1.1.0.tgz\t08w8mwdkaadagyhh61cppma7a4l9z13rlbrxz14ys6r7xfp26s6c\n"
    "fill-range\t7.0.1\thttps://registry.npmjs.org/fill-range/-/fill-range-7.0.1.tgz\t0wp93mwfgzcddi6ii62qx7gb082jgh0rfq6pgvv2xndjyaygvk98\n"
    "find-up\t4.1.0\thttps://registry.npmjs.org/find-up/-/find-up-4.1.0.tgz\t1sr6b86slwxig85zcvjpgmvaqljb6il8n21719gf1lh6ad9v1a9k\n"
    "fs-constants\t1.0.0\thttps://registry.npmjs.org/fs-constants/-/fs-constants-1.0.0.tgz\t1yn5qyvxf9i3zrfly77wgmi3j9fl61gh1i0jjgamnir43dz6v4z7\n"
    "fs-readdir-recursive\t1.1.0\thttps://registry.npmjs.org/fs-readdir-recursive/-/fs-readdir-recursive-1.1.0.tgz\t05xaksggvbircbhba33jq93f0pyj8gy9f51rha9df693vx4rvwga\n"
    "fs.realpath\t1.0.0\thttps://registry.npmjs.org/fs.realpath/-/fs.realpath-1.0.0.tgz\t174g5vay9jnd7h5q8hfdw6dnmwl1gdpn4a8sz0ysanhj2f3wp04y\n"
    "function-bind\t1.1.1\thttps://registry.npmjs.org/function-bind/-/function-bind-1.1.1.tgz\t10p0s9ypggwmazik4azdhywjnnayagnjxk10cjzsrhxlk1y2wm9d\n"
    "gensync\t1.0.0-beta.2\thttps://registry.npmjs.org/gensync/-/gensync-1.0.0-beta.2.tgz\t1j8piprq5pvns7j60gm0jkrdmnm8zrfl2wwarf94ypd34vpr57yz\n"
    "get-stream\t5.2.0\thttps://registry.npmjs.org/get-stream/-/get-stream-5.2.0.tgz\t077iv0jqfgqyxw6jb0iradw9idjcmphmrc58zj050vf58yx0bzkr\n"
    "glob-parent\t5.1.2\thttps://registry.npmjs.org/glob-parent/-/glob-parent-5.1.2.tgz\t1mfna9lpp82lapng0qq5x4x5j10nhimcx36lg4m5k4wbs7msy5ln\n"
    "glob\t7.2.3\thttps://registry.npmjs.org/glob/-/glob-7.2.3.tgz\t10a336nxv867xkjs3ipgbharwdzp5lnz7wr8viawn1lc66qqx8zh\n"
    "globals\t11.12.0\thttps://registry.npmjs.org/globals/-/globals-11.12.0.tgz\t1xjsxgvvvksbp04c7010xmcnpnnrdbj84xl0vfjdqzw5q92qr99q\n"
    "google-closure-compiler\t20211201.0.0\thttps://registry.npmjs.org/google-closure-compiler/-/google-closure-compiler-20211201.0.0.tgz\t06gh3v9xlxg4lcmpkn4sdal7ll3c0bzc68wdj3jwx07wxk7vczvl\n"
    "has-flag\t3.0.0\thttps://registry.npmjs.org/has-flag/-/has-flag-3.0.0.tgz\t1sp0m48zavms86q7vkf90mwll9z2bqi11hk3s01aw8nw40r72jzd\n"
    "has\t1.0.3\thttps://registry.npmjs.org/has/-/has-1.0.3.tgz\t0wsmn2vcbqb23xpbzxipjd7xcdljid2gwnwl7vn5hkp0zkpgk363\n"
    "https-proxy-agent\t5.0.0\thttps://registry.npmjs.org/https-proxy-agent/-/https-proxy-agent-5.0.0.tgz\t1a7mbscj5g23bcprp7psn5f82dhqz09sdris931dwkazq8gfparq\n"
    "ieee754\t1.2.1\thttps://registry.npmjs.org/ieee754/-/ieee754-1.2.1.tgz\t1b4xiyr6fmgl05cjgc8fiyfk2jagf7xq2y5rknw9scvy76dlpwcf\n"
    "inflight\t1.0.6\thttps://registry.npmjs.org/inflight/-/inflight-1.0.6.tgz\t16w864087xsh3q7f5gm3754s7bpsb9fq3dhknk9nmbvlk3sxr7ss\n"
    "inherits\t2.0.4\thttps://registry.npmjs.org/inherits/-/inherits-2.0.4.tgz\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\n"
    "is-binary-path\t2.1.0\thttps://registry.npmjs.org/is-binary-path/-/is-binary-path-2.1.0.tgz\t1vsdqq8808l3f4230y54mhix50njfbc3z46y2wn0h0dxql1v4xm0\n"
    "is-core-module\t2.11.0\thttps://registry.npmjs.org/is-core-module/-/is-core-module-2.11.0.tgz\t1i2dnckq99aqism5rppxwlrc3md5i1rbksmqp4000awhgm3dwk0h\n"
    "is-extglob\t2.1.1\thttps://registry.npmjs.org/is-extglob/-/is-extglob-2.1.1.tgz\t06dwa2xzjx6az40wlvwj11vican2w46710b9170jzmka2j344pcc\n"
    "is-glob\t4.0.3\thttps://registry.npmjs.org/is-glob/-/is-glob-4.0.3.tgz\t1imyq6pjl716cjc1ypmmnn0574rh28av3pq50mpqzd9v37xm7r1z\n"
    "is-number\t7.0.0\thttps://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz\t07nmmpplsj1gxzng6fxhnnyfkif9fvhvxa89d5lrgkwqf42w2xbv\n"
    "isarray\t1.0.0\thttps://registry.npmjs.org/isarray/-/isarray-1.0.0.tgz\t11qcjpdzigcwcprhv7nyarlzjcwf3sv5i66q75zf08jj9zqpcg72\n"
    "jasmine-core\t3.10.1\thttps://registry.npmjs.org/jasmine-core/-/jasmine-core-3.10.1.tgz\t1s5vfpvsv1g871dwrc92za3br5nr4v7sl0h4ic8y3z8fvrvyqa5q\n"
    "jasmine\t3.10.0\thttps://registry.npmjs.org/jasmine/-/jasmine-3.10.0.tgz\t18y62p7l32mkrvhp14rw72scav7f6allmcq7k196gyr032xllhn8\n"
    "js-tokens\t4.0.0\thttps://registry.npmjs.org/js-tokens/-/js-tokens-4.0.0.tgz\t0lrw3qvcfmxrwwi7p7ng4r17yw32ki7jpnbj2a65ddddv2icg16q\n"
    "jsesc\t2.5.2\thttps://registry.npmjs.org/jsesc/-/jsesc-2.5.2.tgz\t12r5ijjqqj5ajj1bp97hjvnhr9wd5xlw620y7wkn4j74apdjnnmf\n"
    "json5\t2.2.3\thttps://registry.npmjs.org/json5/-/json5-2.2.3.tgz\t0yrpsb1frqahc48n6w2jzvhd7m8r9w2w9ylqkg41zl80nqyv7bq8\n"
    "jsonc-parser\t3.2.0\thttps://registry.npmjs.org/jsonc-parser/-/jsonc-parser-3.2.0.tgz\t0v9k1yzkh7r48ah12i9x33fx8yc63ibf7v549jgdp2cjwfzpabzy\n"
    "locate-path\t5.0.0\thttps://registry.npmjs.org/locate-path/-/locate-path-5.0.0.tgz\t1dsk824x6gzp2n7s0f9z7iwxsc4nyllxmix8h4588dd4c29ingdf\n"
    "lodash.debounce\t4.0.8\thttps://registry.npmjs.org/lodash.debounce/-/lodash.debounce-4.0.8.tgz\t180bk3h6nm2kvnn4f6phvcr0qyg5kj30ixrgflng352ndx63h655\n"
    "lru-cache\t5.1.1\thttps://registry.npmjs.org/lru-cache/-/lru-cache-5.1.1.tgz\t0nj8d71w5yb3rmiaxby5scwfl0n1jdaplr0p6dp619j4jn0ph7mi\n"
    "lunr\t2.3.9\thttps://registry.npmjs.org/lunr/-/lunr-2.3.9.tgz\t0c4hd5i3rxbchgmav86c7cdypzm6wq3hxzp7wpifv9rr8gffg1nq\n"
    "make-dir/node_modules/semver\t5.7.1\thttps://registry.npmjs.org/semver/-/semver-5.7.1.tgz\t0vdmbm9s15r8m8n65qs9fhccn5a6v1ln8crlx312iz17m8rgpwpy\n"
    "make-dir\t2.1.0\thttps://registry.npmjs.org/make-dir/-/make-dir-2.1.0.tgz\t0r2nss2nf54q616nf0s5228bnymv830kx6nf94mz5sypaqllfy3l\n"
    "marked\t3.0.8\thttps://registry.npmjs.org/marked/-/marked-3.0.8.tgz\t1936ka43c7wlmkrq60qgnb5n63sfrmknqqs6zrwj8fz45dx6y1in\n"
    "minimatch\t3.1.2\thttps://registry.npmjs.org/minimatch/-/minimatch-3.1.2.tgz\t0kd3h6q90kvmzzw1v7cc3dr911gjkb9s547cdvfncfqanq84p5hk\n"
    "minimist\t1.2.5\thttps://registry.npmjs.org/minimist/-/minimist-1.2.5.tgz\t0l23rq2pam1khc06kd7fv0ys2cq0mlgs82dxjxjfjmlksgj0r051\n"
    "mkdirp-classic\t0.5.3\thttps://registry.npmjs.org/mkdirp-classic/-/mkdirp-classic-0.5.3.tgz\t0ijj0y0ajccyfxfck4iq5yfkhlwcqipg2i1z9idlmk5mz56v9g19\n"
    "ms\t2.1.2\thttps://registry.npmjs.org/ms/-/ms-2.1.2.tgz\t0j7vrqxzg2fxip3q0cws360wk3cz2nprr8zkragipziz1piscmqi\n"
    "node-fetch\t2.6.5\thttps://registry.npmjs.org/node-fetch/-/node-fetch-2.6.5.tgz\t14r4s7n976fp3xmih66ac5n6mcchw25ip7qggwnx6zx3ammw6p1p\n"
    "node-releases\t2.0.10\thttps://registry.npmjs.org/node-releases/-/node-releases-2.0.10.tgz\t0n1vashq59fm92vqz2n9i7gbaqr8ay9gk4kllsrjc40pdxk26p19\n"
    "normalize-path\t3.0.0\thttps://registry.npmjs.org/normalize-path/-/normalize-path-3.0.0.tgz\t1zl49w6pdbgi96sgxpzr0gizcj261v6mxv8rx70csmf5ap53r60b\n"
    "once\t1.4.0\thttps://registry.npmjs.org/once/-/once-1.4.0.tgz\t1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg\n"
    "p-limit\t2.3.0\thttps://registry.npmjs.org/p-limit/-/p-limit-2.3.0.tgz\t15djin88kfxjdvzd7f2gnwblgclqljzqxiidm1pmrsyg14j4ajrq\n"
    "p-locate\t4.1.0\thttps://registry.npmjs.org/p-locate/-/p-locate-4.1.0.tgz\t1w55dykp8ysc41xx4cl8ln3gxsxvqfhvsl62n3g6gng3cbj6lnnr\n"
    "p-try\t2.2.0\thttps://registry.npmjs.org/p-try/-/p-try-2.2.0.tgz\t141pf5z1f3xmm5c0fdrfddsf7xfigjxfl103zh59bpwrk2wb5453\n"
    "path-exists\t4.0.0\thttps://registry.npmjs.org/path-exists/-/path-exists-4.0.0.tgz\t0p3pzdvfy2il8p0dvpp1l688in68bh2zzqzcfzvv7s9c634kbdfv\n"
    "path-is-absolute\t1.0.1\thttps://registry.npmjs.org/path-is-absolute/-/path-is-absolute-1.0.1.tgz\t0p7p04xxd8q495qhxmxydyjgzcf762dp1hp2wha2b52n3agp0vbf\n"
    "path-parse\t1.0.7\thttps://registry.npmjs.org/path-parse/-/path-parse-1.0.7.tgz\t18vkai53yyiv1c1rimsh2whiymxnz9xj6a39c6b65097ly61jym0\n"
    "pend\t1.2.0\thttps://registry.npmjs.org/pend/-/pend-1.2.0.tgz\t0zvd8cli24vpvgsf9ldmm5ibivmx02njp2d9a85p3px94ndjfbx1\n"
    "picocolors\t1.0.0\thttps://registry.npmjs.org/picocolors/-/picocolors-1.0.0.tgz\t10zk2pciqiyxjapg6yp7n02nbvvyy00a6k8sz7jibsh6lhmyqqk0\n"
    "picomatch\t2.3.1\thttps://registry.npmjs.org/picomatch/-/picomatch-2.3.1.tgz\t07y1h9gbbdyjdpwb461x7dai0yg7hcyijxrcnpbr1h37r2gfw50v\n"
    "pify\t4.0.1\thttps://registry.npmjs.org/pify/-/pify-4.0.1.tgz\t0jvbj1w7dn2kz3v3i1jsziyhcgpnsp497fq2a6z1kf34aq1mszwa\n"
    "pkg-dir\t4.2.0\thttps://registry.npmjs.org/pkg-dir/-/pkg-dir-4.2.0.tgz\t0k92ac0qyrxqg086cd3h133vi33k3kxaaapk546xfwfmjih4bx57\n"
    "process-nextick-args\t2.0.0\thttps://registry.npmjs.org/process-nextick-args/-/process-nextick-args-2.0.0.tgz\t0klwkva2pp5wkf97v7ffwi2dg3fgl52mcvc1pkll757jg8djgv4f\n"
    "progress\t2.0.3\thttps://registry.npmjs.org/progress/-/progress-2.0.3.tgz\t191ax3hag867ggjsn6wh1b00bp5iippxsml7fyxf7h7nizhna63h\n"
    "proxy-from-env\t1.1.0\thttps://registry.npmjs.org/proxy-from-env/-/proxy-from-env-1.1.0.tgz\t03yy2xm903581x3vmklhp06dlxgipz10d4vhx69sqg2xy1a2824l\n"
    "pump\t3.0.0\thttps://registry.npmjs.org/pump/-/pump-3.0.0.tgz\t1vq58w7663jdwlsks9qbzga0bsca11il5x04w9q2q0qlllb14k41\n"
    "puppeteer-core/node_modules/debug\t4.3.2\thttps://registry.npmjs.org/debug/-/debug-4.3.2.tgz\t1fx7gy0slvrpr7sijfx863fbmbwnkv7k9gz80c0420nwf62bkd86\n"
    "puppeteer-core\t13.0.0\thttps://registry.npmjs.org/puppeteer-core/-/puppeteer-core-13.0.0.tgz\t0gc85mz3qza5qaby121al0bkqbdbi8cv4xp28ddxlvrgdr59hwkk\n"
    "readable-stream\t2.3.6\thttps://registry.npmjs.org/readable-stream/-/readable-stream-2.3.6.tgz\t0xswqhcra34iff36l2ycrslcr1rz7dcd3wdvbgq01cqgvih5n80g\n"
    "readdirp\t3.6.0\thttps://registry.npmjs.org/readdirp/-/readdirp-3.6.0.tgz\t1jlrf2knpx8y6b6pmlr0ljqpyz81lfzrnyw20w7imwd98vqvdlzi\n"
    "regenerate-unicode-properties\t10.1.0\thttps://registry.npmjs.org/regenerate-unicode-properties/-/regenerate-unicode-properties-10.1.0.tgz\t1h99a7hsbsza6war99a0626zgwllky3vadkc64sggc6n0h9bw4rb\n"
    "regenerate\t1.4.2\thttps://registry.npmjs.org/regenerate/-/regenerate-1.4.2.tgz\t07km6in83r5da81jn43ps2gll0gpdykcy0aa94v3vlwh83ygqy33\n"
    "regenerator-runtime\t0.13.11\thttps://registry.npmjs.org/regenerator-runtime/-/regenerator-runtime-0.13.11.tgz\t131b9kq9m176s787asppci2kihmpvmhdqxfp2zbjqgdqrr4si84n\n"
    "regenerator-transform\t0.15.1\thttps://registry.npmjs.org/regenerator-transform/-/regenerator-transform-0.15.1.tgz\t16i7639k5nsxwp9sf3kyq8q3236m3bak8x8vhrdggh2c86anyvqy\n"
    "regexpu-core\t5.3.2\thttps://registry.npmjs.org/regexpu-core/-/regexpu-core-5.3.2.tgz\t0a2daarc3gg2jn9gwvm3nj8gg9w8bbjnhkwpciqaybyq2q65zm8f\n"
    "regjsparser/node_modules/jsesc\t0.5.0\thttps://registry.npmjs.org/jsesc/-/jsesc-0.5.0.tgz\t0x365wjgs65s1xa7zad9rbg5izayxbh2mfgsjgqm7zl0gi3116iy\n"
    "regjsparser\t0.9.1\thttps://registry.npmjs.org/regjsparser/-/regjsparser-0.9.1.tgz\t18m7kyiw7yifpdnnh30ydl3qy1ar7rznfvvl9prxil8a92fxijzv\n"
    "remove-trailing-separator\t1.1.0\thttps://registry.npmjs.org/remove-trailing-separator/-/remove-trailing-separator-1.1.0.tgz\t08b3msz9s5kw1alivgn9saaz6w04grjqppkdk3qbr7blk38l04sf\n"
    "replace-ext\t1.0.0\thttps://registry.npmjs.org/replace-ext/-/replace-ext-1.0.0.tgz\t1am1c2j180g9586jhh2svfj2snfzhlba0q4cq3wjgdgymwhf7f37\n"
    "resolve\t1.22.1\thttps://registry.npmjs.org/resolve/-/resolve-1.22.1.tgz\t1shj5plxx1pnv896yxwsb5v23jhwdrch927yih1lvv82i3aaammm\n"
    "rimraf\t3.0.2\thttps://registry.npmjs.org/rimraf/-/rimraf-3.0.2.tgz\t0lkzjyxjij6ssh5h2l3ncp0zx00ylzhww766dq2vf1s7v07w4xjq\n"
    "rollup\t2.61.1\thttps://registry.npmjs.org/rollup/-/rollup-2.61.1.tgz\t1xzs7y0ps4505jr7jnv3i5gld8zia8mc6762frvdnbgn1fm02dck\n"
    "safe-buffer\t5.1.2\thttps://registry.npmjs.org/safe-buffer/-/safe-buffer-5.1.2.tgz\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\n"
    "semver\t6.3.0\thttps://registry.npmjs.org/semver/-/semver-6.3.0.tgz\t0ib79jd27krndmai3hg1rzr6nzwcj4crbnff4qjvchrq6grlmwbb\n"
    "shiki\t0.9.15\thttps://registry.npmjs.org/shiki/-/shiki-0.9.15.tgz\t0b7fm28fh8zhk67m244g1qypfrg53a0clkkifi3zzrpki65kdnv6\n"
    "slash\t2.0.0\thttps://registry.npmjs.org/slash/-/slash-2.0.0.tgz\t1qnsq29m6qyz15c214bw48m90hlbigs9rwfkpr48s7g06r9y4gpl\n"
    "source-map\t0.5.7\thttps://registry.npmjs.org/source-map/-/source-map-0.5.7.tgz\t0rvb24j4kfib26w3cjyl6yan2dxvw1iy7d0wl404y5ckqjdjipp1\n"
    "string_decoder\t1.1.1\thttps://registry.npmjs.org/string_decoder/-/string_decoder-1.1.1.tgz\t0fln2r91b8gj845j7jl76fvsp7nij13fyzvz82985yh88m1n50mg\n"
    "supports-color\t5.5.0\thttps://registry.npmjs.org/supports-color/-/supports-color-5.5.0.tgz\t1ap0lk4n0m3948cnkfmyz71pizqlzjdfrhs0f954pksg4jnk52h5\n"
    "supports-preserve-symlinks-flag\t1.0.0\thttps://registry.npmjs.org/supports-preserve-symlinks-flag/-/supports-preserve-symlinks-flag-1.0.0.tgz\t1ygp0kk7p6df5p6p2q1csdshilklhfbh49g7h90m6i2kmxh13nlp\n"
    "tar-fs\t2.1.1\thttps://registry.npmjs.org/tar-fs/-/tar-fs-2.1.1.tgz\t1vhg71ld9i4pwqccn8byx585ywlm3l0hzbpfjx47fjv3c4z8xaxl\n"
    "tar-stream/node_modules/readable-stream\t3.6.2\thttps://registry.npmjs.org/readable-stream/-/readable-stream-3.6.2.tgz\t0pdb0mrh95ks672ikgj8frx9nh078bfyngknj70ak2iibv06dn7d\n"
    "tar-stream\t2.2.0\thttps://registry.npmjs.org/tar-stream/-/tar-stream-2.2.0.tgz\t0nrrl6sgl5yazgllc8ryxpg083432xwqvqbrlqdl16sfszgq73rs\n"
    "through\t2.3.8\thttps://registry.npmjs.org/through/-/through-2.3.8.tgz\t0gjpaj9lwd6s356z2lljj2yj0pxwvdr8sckb6lkmfgmi1y67mchn\n"
    "to-fast-properties\t2.0.0\thttps://registry.npmjs.org/to-fast-properties/-/to-fast-properties-2.0.0.tgz\t10q99rgk8nfl8k7q0aqmik4wkbm8zp4z0rpwbm8b0gr4pi4gw4y7\n"
    "to-regex-range\t5.0.1\thttps://registry.npmjs.org/to-regex-range/-/to-regex-range-5.0.1.tgz\t1ms2bgz2paqfpjv1xpwx67i3dns5j9gn99il6cx5r4qaq9g2afm6\n"
    "tr46\t0.0.3\thttps://registry.npmjs.org/tr46/-/tr46-0.0.3.tgz\t02ia19bsjr545jlkgv35psmzzr5avic96zxw3dam78yf6bmy2jhn\n"
    "typedoc\t0.22.10\thttps://registry.npmjs.org/typedoc/-/typedoc-0.22.10.tgz\t0yrjjws7kxgvg90zgzmss7gxwyg8vcnggby4pq6yvp7f3z3y7idp\n"
    "typescript\t4.5.4\thttps://registry.npmjs.org/typescript/-/typescript-4.5.4.tgz\t1fiwn2ppf8mlfwjp44w2vyb4lal85z1qrvbwbmhx96kg9m602asv\n"
    "unbzip2-stream\t1.4.3\thttps://registry.npmjs.org/unbzip2-stream/-/unbzip2-stream-1.4.3.tgz\t17vavbr2mdscixs9z5dxqjqc71fsbrrmxjs6jpn5z0hrp42jlxhf\n"
    "unicode-canonical-property-names-ecmascript\t2.0.0\thttps://registry.npmjs.org/unicode-canonical-property-names-ecmascript/-/unicode-canonical-property-names-ecmascript-2.0.0.tgz\t11k4z0098c9r7c0mignfdbislxn3b9ds0mwbgsmrpr3liwa0zw3j\n"
    "unicode-match-property-ecmascript\t2.0.0\thttps://registry.npmjs.org/unicode-match-property-ecmascript/-/unicode-match-property-ecmascript-2.0.0.tgz\t13bzxipaxf66i2xvlmmfv8yhc2db6ndv05xgrxinspypiq3z469a\n"
    "unicode-match-property-value-ecmascript\t2.1.0\thttps://registry.npmjs.org/unicode-match-property-value-ecmascript/-/unicode-match-property-value-ecmascript-2.1.0.tgz\t04rsxphw84cbc7qqywcr7xh39ryhswfrzix0ycf8h3qnrm1x9p5m\n"
    "unicode-property-aliases-ecmascript\t2.1.0\thttps://registry.npmjs.org/unicode-property-aliases-ecmascript/-/unicode-property-aliases-ecmascript-2.1.0.tgz\t12dd3gla04q1cxssqf2bzqqwdvvz5fir4kjral3hvm7g9p49rm3n\n"
    "update-browserslist-db\t1.0.10\thttps://registry.npmjs.org/update-browserslist-db/-/update-browserslist-db-1.0.10.tgz\t1ax0zvfwkl6fp68lp2sjwrm6ndpg7l3pfzjyjjcsd5a61zajx3rl\n"
    "util-deprecate\t1.0.2\thttps://registry.npmjs.org/util-deprecate/-/util-deprecate-1.0.2.tgz\t1rd3qbgdrwkmcrf7vqx61sh7icma7jvxcmklqj032f8v7jcdx8br\n"
    "vinyl-sourcemaps-apply\t0.2.1\thttps://registry.npmjs.org/vinyl-sourcemaps-apply/-/vinyl-sourcemaps-apply-0.2.1.tgz\t04qw1fiygq9hqadykdjhqbfaa88wk1qm8wyz50kh5h5m2l0ggjbh\n"
    "vinyl\t2.2.0\thttps://registry.npmjs.org/vinyl/-/vinyl-2.2.0.tgz\t0341dmh4i477rw3101269vdazk3yqwm7hbmd48jag29cp9wlcrlf\n"
    "vscode-oniguruma\t1.7.0\thttps://registry.npmjs.org/vscode-oniguruma/-/vscode-oniguruma-1.7.0.tgz\t0zv5jx89ij1qxj6m9vi7hfnmz4rwbwgkrjk1q7c5am27zpl8s343\n"
    "vscode-textmate\t5.2.0\thttps://registry.npmjs.org/vscode-textmate/-/vscode-textmate-5.2.0.tgz\t1j796ipb4ahbp0z67y10p4k5j977ibgldkzaf2y9gvrqylfamivl\n"
    "webidl-conversions\t3.0.1\thttps://registry.npmjs.org/webidl-conversions/-/webidl-conversions-3.0.1.tgz\t1a1dwb1ga1cj2s7av9r46b4xmx11vsk5zncc0gq2qz4l815w7pz4\n"
    "whatwg-url\t5.0.0\thttps://registry.npmjs.org/whatwg-url/-/whatwg-url-5.0.0.tgz\t1lvyrf4ry4bgl2jgpim2pkdmrbv2vb0vh0irmkp7da3kymqw97dh\n"
    "wrappy\t1.0.2\thttps://registry.npmjs.org/wrappy/-/wrappy-1.0.2.tgz\t1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg\n"
    "ws\t8.2.3\thttps://registry.npmjs.org/ws/-/ws-8.2.3.tgz\t1rs9h8095dnqgkhqgsxs0lykjj5c433n7f7d6vd0rqwg706gqjkn\n"
    "yallist\t3.1.1\thttps://registry.npmjs.org/yallist/-/yallist-3.1.1.tgz\t016afm3iv7pfrg9nj7952dph6sg00lryk8wv4nr0qdp8rzk4mwah\n"
    "yauzl\t2.10.0\thttps://registry.npmjs.org/yauzl/-/yauzl-2.10.0.tgz\t1cbcq82bafcifhliglwjzp6b898qawrzng8315rh0r3vbn1k23sm\n"
    ))

(define %rot-js-npm-path-keys
  '(
    ("node_modules/@babel/cli" . "@babel/cli@7.16.0")
    ("node_modules/@babel/code-frame" . "@babel/code-frame@7.18.6")
    ("node_modules/@babel/compat-data" . "@babel/compat-data@7.21.0")
    ("node_modules/@babel/core" . "@babel/core@7.16.5")
    ("node_modules/@babel/generator" . "@babel/generator@7.21.3")
    ("node_modules/@babel/helper-annotate-as-pure" . "@babel/helper-annotate-as-pure@7.18.6")
    ("node_modules/@babel/helper-builder-binary-assignment-operator-visitor" . "@babel/helper-builder-binary-assignment-operator-visitor@7.18.9")
    ("node_modules/@babel/helper-compilation-targets" . "@babel/helper-compilation-targets@7.20.7")
    ("node_modules/@babel/helper-create-class-features-plugin" . "@babel/helper-create-class-features-plugin@7.21.0")
    ("node_modules/@babel/helper-create-regexp-features-plugin" . "@babel/helper-create-regexp-features-plugin@7.21.0")
    ("node_modules/@babel/helper-define-polyfill-provider" . "@babel/helper-define-polyfill-provider@0.3.3")
    ("node_modules/@babel/helper-environment-visitor" . "@babel/helper-environment-visitor@7.18.9")
    ("node_modules/@babel/helper-explode-assignable-expression" . "@babel/helper-explode-assignable-expression@7.18.6")
    ("node_modules/@babel/helper-function-name" . "@babel/helper-function-name@7.21.0")
    ("node_modules/@babel/helper-hoist-variables" . "@babel/helper-hoist-variables@7.18.6")
    ("node_modules/@babel/helper-member-expression-to-functions" . "@babel/helper-member-expression-to-functions@7.21.0")
    ("node_modules/@babel/helper-module-imports" . "@babel/helper-module-imports@7.18.6")
    ("node_modules/@babel/helper-module-transforms" . "@babel/helper-module-transforms@7.21.2")
    ("node_modules/@babel/helper-optimise-call-expression" . "@babel/helper-optimise-call-expression@7.18.6")
    ("node_modules/@babel/helper-plugin-utils" . "@babel/helper-plugin-utils@7.20.2")
    ("node_modules/@babel/helper-remap-async-to-generator" . "@babel/helper-remap-async-to-generator@7.18.9")
    ("node_modules/@babel/helper-replace-supers" . "@babel/helper-replace-supers@7.20.7")
    ("node_modules/@babel/helper-simple-access" . "@babel/helper-simple-access@7.20.2")
    ("node_modules/@babel/helper-skip-transparent-expression-wrappers" . "@babel/helper-skip-transparent-expression-wrappers@7.20.0")
    ("node_modules/@babel/helper-split-export-declaration" . "@babel/helper-split-export-declaration@7.18.6")
    ("node_modules/@babel/helper-string-parser" . "@babel/helper-string-parser@7.19.4")
    ("node_modules/@babel/helper-validator-identifier" . "@babel/helper-validator-identifier@7.19.1")
    ("node_modules/@babel/helper-validator-option" . "@babel/helper-validator-option@7.21.0")
    ("node_modules/@babel/helper-wrap-function" . "@babel/helper-wrap-function@7.20.5")
    ("node_modules/@babel/helpers" . "@babel/helpers@7.21.0")
    ("node_modules/@babel/highlight" . "@babel/highlight@7.18.6")
    ("node_modules/@babel/parser" . "@babel/parser@7.21.3")
    ("node_modules/@babel/plugin-bugfix-safari-id-destructuring-collision-in-function-expression" . "@babel/plugin-bugfix-safari-id-destructuring-collision-in-function-expression@7.18.6")
    ("node_modules/@babel/plugin-bugfix-v8-spread-parameters-in-optional-chaining" . "@babel/plugin-bugfix-v8-spread-parameters-in-optional-chaining@7.20.7")
    ("node_modules/@babel/plugin-proposal-async-generator-functions" . "@babel/plugin-proposal-async-generator-functions@7.20.7")
    ("node_modules/@babel/plugin-proposal-class-properties" . "@babel/plugin-proposal-class-properties@7.18.6")
    ("node_modules/@babel/plugin-proposal-class-static-block" . "@babel/plugin-proposal-class-static-block@7.21.0")
    ("node_modules/@babel/plugin-proposal-dynamic-import" . "@babel/plugin-proposal-dynamic-import@7.18.6")
    ("node_modules/@babel/plugin-proposal-export-namespace-from" . "@babel/plugin-proposal-export-namespace-from@7.18.9")
    ("node_modules/@babel/plugin-proposal-json-strings" . "@babel/plugin-proposal-json-strings@7.18.6")
    ("node_modules/@babel/plugin-proposal-logical-assignment-operators" . "@babel/plugin-proposal-logical-assignment-operators@7.20.7")
    ("node_modules/@babel/plugin-proposal-nullish-coalescing-operator" . "@babel/plugin-proposal-nullish-coalescing-operator@7.18.6")
    ("node_modules/@babel/plugin-proposal-numeric-separator" . "@babel/plugin-proposal-numeric-separator@7.18.6")
    ("node_modules/@babel/plugin-proposal-object-rest-spread" . "@babel/plugin-proposal-object-rest-spread@7.20.7")
    ("node_modules/@babel/plugin-proposal-optional-catch-binding" . "@babel/plugin-proposal-optional-catch-binding@7.18.6")
    ("node_modules/@babel/plugin-proposal-optional-chaining" . "@babel/plugin-proposal-optional-chaining@7.21.0")
    ("node_modules/@babel/plugin-proposal-private-methods" . "@babel/plugin-proposal-private-methods@7.18.6")
    ("node_modules/@babel/plugin-proposal-private-property-in-object" . "@babel/plugin-proposal-private-property-in-object@7.21.0")
    ("node_modules/@babel/plugin-proposal-unicode-property-regex" . "@babel/plugin-proposal-unicode-property-regex@7.18.6")
    ("node_modules/@babel/plugin-syntax-async-generators" . "@babel/plugin-syntax-async-generators@7.8.4")
    ("node_modules/@babel/plugin-syntax-class-properties" . "@babel/plugin-syntax-class-properties@7.12.13")
    ("node_modules/@babel/plugin-syntax-class-static-block" . "@babel/plugin-syntax-class-static-block@7.14.5")
    ("node_modules/@babel/plugin-syntax-dynamic-import" . "@babel/plugin-syntax-dynamic-import@7.8.3")
    ("node_modules/@babel/plugin-syntax-export-namespace-from" . "@babel/plugin-syntax-export-namespace-from@7.8.3")
    ("node_modules/@babel/plugin-syntax-json-strings" . "@babel/plugin-syntax-json-strings@7.8.3")
    ("node_modules/@babel/plugin-syntax-logical-assignment-operators" . "@babel/plugin-syntax-logical-assignment-operators@7.10.4")
    ("node_modules/@babel/plugin-syntax-nullish-coalescing-operator" . "@babel/plugin-syntax-nullish-coalescing-operator@7.8.3")
    ("node_modules/@babel/plugin-syntax-numeric-separator" . "@babel/plugin-syntax-numeric-separator@7.10.4")
    ("node_modules/@babel/plugin-syntax-object-rest-spread" . "@babel/plugin-syntax-object-rest-spread@7.8.3")
    ("node_modules/@babel/plugin-syntax-optional-catch-binding" . "@babel/plugin-syntax-optional-catch-binding@7.8.3")
    ("node_modules/@babel/plugin-syntax-optional-chaining" . "@babel/plugin-syntax-optional-chaining@7.8.3")
    ("node_modules/@babel/plugin-syntax-private-property-in-object" . "@babel/plugin-syntax-private-property-in-object@7.14.5")
    ("node_modules/@babel/plugin-syntax-top-level-await" . "@babel/plugin-syntax-top-level-await@7.14.5")
    ("node_modules/@babel/plugin-transform-arrow-functions" . "@babel/plugin-transform-arrow-functions@7.20.7")
    ("node_modules/@babel/plugin-transform-async-to-generator" . "@babel/plugin-transform-async-to-generator@7.20.7")
    ("node_modules/@babel/plugin-transform-block-scoped-functions" . "@babel/plugin-transform-block-scoped-functions@7.18.6")
    ("node_modules/@babel/plugin-transform-block-scoping" . "@babel/plugin-transform-block-scoping@7.21.0")
    ("node_modules/@babel/plugin-transform-classes" . "@babel/plugin-transform-classes@7.21.0")
    ("node_modules/@babel/plugin-transform-computed-properties" . "@babel/plugin-transform-computed-properties@7.20.7")
    ("node_modules/@babel/plugin-transform-destructuring" . "@babel/plugin-transform-destructuring@7.21.3")
    ("node_modules/@babel/plugin-transform-dotall-regex" . "@babel/plugin-transform-dotall-regex@7.18.6")
    ("node_modules/@babel/plugin-transform-duplicate-keys" . "@babel/plugin-transform-duplicate-keys@7.18.9")
    ("node_modules/@babel/plugin-transform-exponentiation-operator" . "@babel/plugin-transform-exponentiation-operator@7.18.6")
    ("node_modules/@babel/plugin-transform-for-of" . "@babel/plugin-transform-for-of@7.21.0")
    ("node_modules/@babel/plugin-transform-function-name" . "@babel/plugin-transform-function-name@7.18.9")
    ("node_modules/@babel/plugin-transform-literals" . "@babel/plugin-transform-literals@7.18.9")
    ("node_modules/@babel/plugin-transform-member-expression-literals" . "@babel/plugin-transform-member-expression-literals@7.18.6")
    ("node_modules/@babel/plugin-transform-modules-amd" . "@babel/plugin-transform-modules-amd@7.20.11")
    ("node_modules/@babel/plugin-transform-modules-commonjs" . "@babel/plugin-transform-modules-commonjs@7.21.2")
    ("node_modules/@babel/plugin-transform-modules-systemjs" . "@babel/plugin-transform-modules-systemjs@7.20.11")
    ("node_modules/@babel/plugin-transform-modules-umd" . "@babel/plugin-transform-modules-umd@7.18.6")
    ("node_modules/@babel/plugin-transform-named-capturing-groups-regex" . "@babel/plugin-transform-named-capturing-groups-regex@7.20.5")
    ("node_modules/@babel/plugin-transform-new-target" . "@babel/plugin-transform-new-target@7.18.6")
    ("node_modules/@babel/plugin-transform-object-super" . "@babel/plugin-transform-object-super@7.18.6")
    ("node_modules/@babel/plugin-transform-parameters" . "@babel/plugin-transform-parameters@7.21.3")
    ("node_modules/@babel/plugin-transform-property-literals" . "@babel/plugin-transform-property-literals@7.18.6")
    ("node_modules/@babel/plugin-transform-regenerator" . "@babel/plugin-transform-regenerator@7.20.5")
    ("node_modules/@babel/plugin-transform-reserved-words" . "@babel/plugin-transform-reserved-words@7.18.6")
    ("node_modules/@babel/plugin-transform-shorthand-properties" . "@babel/plugin-transform-shorthand-properties@7.18.6")
    ("node_modules/@babel/plugin-transform-spread" . "@babel/plugin-transform-spread@7.20.7")
    ("node_modules/@babel/plugin-transform-sticky-regex" . "@babel/plugin-transform-sticky-regex@7.18.6")
    ("node_modules/@babel/plugin-transform-template-literals" . "@babel/plugin-transform-template-literals@7.18.9")
    ("node_modules/@babel/plugin-transform-typeof-symbol" . "@babel/plugin-transform-typeof-symbol@7.18.9")
    ("node_modules/@babel/plugin-transform-unicode-escapes" . "@babel/plugin-transform-unicode-escapes@7.18.10")
    ("node_modules/@babel/plugin-transform-unicode-regex" . "@babel/plugin-transform-unicode-regex@7.18.6")
    ("node_modules/@babel/preset-env" . "@babel/preset-env@7.16.5")
    ("node_modules/@babel/preset-modules" . "@babel/preset-modules@0.1.5")
    ("node_modules/@babel/regjsgen" . "@babel/regjsgen@0.8.0")
    ("node_modules/@babel/runtime" . "@babel/runtime@7.21.0")
    ("node_modules/@babel/template" . "@babel/template@7.20.7")
    ("node_modules/@babel/traverse" . "@babel/traverse@7.21.3")
    ("node_modules/@babel/types" . "@babel/types@7.21.3")
    ("node_modules/@jridgewell/gen-mapping" . "@jridgewell/gen-mapping@0.3.2")
    ("node_modules/@jridgewell/resolve-uri" . "@jridgewell/resolve-uri@3.1.0")
    ("node_modules/@jridgewell/set-array" . "@jridgewell/set-array@1.1.2")
    ("node_modules/@jridgewell/sourcemap-codec" . "@jridgewell/sourcemap-codec@1.4.14")
    ("node_modules/@jridgewell/trace-mapping" . "@jridgewell/trace-mapping@0.3.17")
    ("node_modules/@nicolo-ribaudo/chokidar-2" . "@nicolo-ribaudo/chokidar-2@2.1.8-no-fsevents.3")
    ("node_modules/@types/node" . "@types/node@17.0.2")
    ("node_modules/@types/yauzl" . "@types/yauzl@2.10.0")
    ("node_modules/agent-base" . "agent-base@6.0.2")
    ("node_modules/ansi-styles" . "ansi-styles@3.2.1")
    ("node_modules/anymatch" . "anymatch@3.1.3")
    ("node_modules/babel-plugin-polyfill-corejs2" . "babel-plugin-polyfill-corejs2@0.3.3")
    ("node_modules/babel-plugin-polyfill-corejs3" . "babel-plugin-polyfill-corejs3@0.4.0")
    ("node_modules/babel-plugin-polyfill-regenerator" . "babel-plugin-polyfill-regenerator@0.3.1")
    ("node_modules/balanced-match" . "balanced-match@1.0.0")
    ("node_modules/base64-js" . "base64-js@1.5.1")
    ("node_modules/binary-extensions" . "binary-extensions@2.2.0")
    ("node_modules/bl" . "bl@4.1.0")
    ("node_modules/bl/node_modules/readable-stream" . "bl/node_modules/readable-stream@3.6.2")
    ("node_modules/brace-expansion" . "brace-expansion@1.1.11")
    ("node_modules/braces" . "braces@3.0.2")
    ("node_modules/browserslist" . "browserslist@4.21.5")
    ("node_modules/buffer" . "buffer@5.7.1")
    ("node_modules/buffer-crc32" . "buffer-crc32@0.2.13")
    ("node_modules/caniuse-lite" . "caniuse-lite@1.0.30001467")
    ("node_modules/chalk" . "chalk@2.4.2")
    ("node_modules/chokidar" . "chokidar@3.5.3")
    ("node_modules/chownr" . "chownr@1.1.4")
    ("node_modules/clone" . "clone@2.1.2")
    ("node_modules/clone-buffer" . "clone-buffer@1.0.0")
    ("node_modules/clone-stats" . "clone-stats@1.0.0")
    ("node_modules/cloneable-readable" . "cloneable-readable@1.1.2")
    ("node_modules/color-convert" . "color-convert@1.9.3")
    ("node_modules/color-name" . "color-name@1.1.3")
    ("node_modules/commander" . "commander@4.1.1")
    ("node_modules/concat-map" . "concat-map@0.0.1")
    ("node_modules/convert-source-map" . "convert-source-map@1.9.0")
    ("node_modules/core-js-compat" . "core-js-compat@3.29.1")
    ("node_modules/core-util-is" . "core-util-is@1.0.2")
    ("node_modules/debug" . "debug@4.3.4")
    ("node_modules/devtools-protocol" . "devtools-protocol@0.0.937139")
    ("node_modules/electron-to-chromium" . "electron-to-chromium@1.4.332")
    ("node_modules/end-of-stream" . "end-of-stream@1.4.4")
    ("node_modules/escalade" . "escalade@3.1.1")
    ("node_modules/escape-string-regexp" . "escape-string-regexp@1.0.5")
    ("node_modules/esutils" . "esutils@2.0.3")
    ("node_modules/extract-zip" . "extract-zip@2.0.1")
    ("node_modules/fd-slicer" . "fd-slicer@1.1.0")
    ("node_modules/fill-range" . "fill-range@7.0.1")
    ("node_modules/find-up" . "find-up@4.1.0")
    ("node_modules/fs-constants" . "fs-constants@1.0.0")
    ("node_modules/fs-readdir-recursive" . "fs-readdir-recursive@1.1.0")
    ("node_modules/fs.realpath" . "fs.realpath@1.0.0")
    ("node_modules/function-bind" . "function-bind@1.1.1")
    ("node_modules/gensync" . "gensync@1.0.0-beta.2")
    ("node_modules/get-stream" . "get-stream@5.2.0")
    ("node_modules/glob" . "glob@7.2.3")
    ("node_modules/glob-parent" . "glob-parent@5.1.2")
    ("node_modules/globals" . "globals@11.12.0")
    ("node_modules/google-closure-compiler" . "google-closure-compiler@20211201.0.0")
    ("node_modules/has" . "has@1.0.3")
    ("node_modules/has-flag" . "has-flag@3.0.0")
    ("node_modules/https-proxy-agent" . "https-proxy-agent@5.0.0")
    ("node_modules/ieee754" . "ieee754@1.2.1")
    ("node_modules/inflight" . "inflight@1.0.6")
    ("node_modules/inherits" . "inherits@2.0.4")
    ("node_modules/is-binary-path" . "is-binary-path@2.1.0")
    ("node_modules/is-core-module" . "is-core-module@2.11.0")
    ("node_modules/is-extglob" . "is-extglob@2.1.1")
    ("node_modules/is-glob" . "is-glob@4.0.3")
    ("node_modules/is-number" . "is-number@7.0.0")
    ("node_modules/isarray" . "isarray@1.0.0")
    ("node_modules/jasmine" . "jasmine@3.10.0")
    ("node_modules/jasmine-core" . "jasmine-core@3.10.1")
    ("node_modules/js-tokens" . "js-tokens@4.0.0")
    ("node_modules/jsesc" . "jsesc@2.5.2")
    ("node_modules/json5" . "json5@2.2.3")
    ("node_modules/jsonc-parser" . "jsonc-parser@3.2.0")
    ("node_modules/locate-path" . "locate-path@5.0.0")
    ("node_modules/lodash.debounce" . "lodash.debounce@4.0.8")
    ("node_modules/lru-cache" . "lru-cache@5.1.1")
    ("node_modules/lunr" . "lunr@2.3.9")
    ("node_modules/make-dir" . "make-dir@2.1.0")
    ("node_modules/make-dir/node_modules/semver" . "make-dir/node_modules/semver@5.7.1")
    ("node_modules/marked" . "marked@3.0.8")
    ("node_modules/minimatch" . "minimatch@3.1.2")
    ("node_modules/minimist" . "minimist@1.2.5")
    ("node_modules/mkdirp-classic" . "mkdirp-classic@0.5.3")
    ("node_modules/ms" . "ms@2.1.2")
    ("node_modules/node-fetch" . "node-fetch@2.6.5")
    ("node_modules/node-releases" . "node-releases@2.0.10")
    ("node_modules/normalize-path" . "normalize-path@3.0.0")
    ("node_modules/once" . "once@1.4.0")
    ("node_modules/p-limit" . "p-limit@2.3.0")
    ("node_modules/p-locate" . "p-locate@4.1.0")
    ("node_modules/p-try" . "p-try@2.2.0")
    ("node_modules/path-exists" . "path-exists@4.0.0")
    ("node_modules/path-is-absolute" . "path-is-absolute@1.0.1")
    ("node_modules/path-parse" . "path-parse@1.0.7")
    ("node_modules/pend" . "pend@1.2.0")
    ("node_modules/picocolors" . "picocolors@1.0.0")
    ("node_modules/picomatch" . "picomatch@2.3.1")
    ("node_modules/pify" . "pify@4.0.1")
    ("node_modules/pkg-dir" . "pkg-dir@4.2.0")
    ("node_modules/process-nextick-args" . "process-nextick-args@2.0.0")
    ("node_modules/progress" . "progress@2.0.3")
    ("node_modules/proxy-from-env" . "proxy-from-env@1.1.0")
    ("node_modules/pump" . "pump@3.0.0")
    ("node_modules/puppeteer-core" . "puppeteer-core@13.0.0")
    ("node_modules/puppeteer-core/node_modules/debug" . "puppeteer-core/node_modules/debug@4.3.2")
    ("node_modules/readable-stream" . "readable-stream@2.3.6")
    ("node_modules/readdirp" . "readdirp@3.6.0")
    ("node_modules/regenerate" . "regenerate@1.4.2")
    ("node_modules/regenerate-unicode-properties" . "regenerate-unicode-properties@10.1.0")
    ("node_modules/regenerator-runtime" . "regenerator-runtime@0.13.11")
    ("node_modules/regenerator-transform" . "regenerator-transform@0.15.1")
    ("node_modules/regexpu-core" . "regexpu-core@5.3.2")
    ("node_modules/regjsparser" . "regjsparser@0.9.1")
    ("node_modules/regjsparser/node_modules/jsesc" . "regjsparser/node_modules/jsesc@0.5.0")
    ("node_modules/remove-trailing-separator" . "remove-trailing-separator@1.1.0")
    ("node_modules/replace-ext" . "replace-ext@1.0.0")
    ("node_modules/resolve" . "resolve@1.22.1")
    ("node_modules/rimraf" . "rimraf@3.0.2")
    ("node_modules/rollup" . "rollup@2.61.1")
    ("node_modules/safe-buffer" . "safe-buffer@5.1.2")
    ("node_modules/semver" . "semver@6.3.0")
    ("node_modules/shiki" . "shiki@0.9.15")
    ("node_modules/slash" . "slash@2.0.0")
    ("node_modules/source-map" . "source-map@0.5.7")
    ("node_modules/string_decoder" . "string_decoder@1.1.1")
    ("node_modules/supports-color" . "supports-color@5.5.0")
    ("node_modules/supports-preserve-symlinks-flag" . "supports-preserve-symlinks-flag@1.0.0")
    ("node_modules/tar-fs" . "tar-fs@2.1.1")
    ("node_modules/tar-stream" . "tar-stream@2.2.0")
    ("node_modules/tar-stream/node_modules/readable-stream" . "tar-stream/node_modules/readable-stream@3.6.2")
    ("node_modules/through" . "through@2.3.8")
    ("node_modules/to-fast-properties" . "to-fast-properties@2.0.0")
    ("node_modules/to-regex-range" . "to-regex-range@5.0.1")
    ("node_modules/tr46" . "tr46@0.0.3")
    ("node_modules/typedoc" . "typedoc@0.22.10")
    ("node_modules/typescript" . "typescript@4.5.4")
    ("node_modules/unbzip2-stream" . "unbzip2-stream@1.4.3")
    ("node_modules/unicode-canonical-property-names-ecmascript" . "unicode-canonical-property-names-ecmascript@2.0.0")
    ("node_modules/unicode-match-property-ecmascript" . "unicode-match-property-ecmascript@2.0.0")
    ("node_modules/unicode-match-property-value-ecmascript" . "unicode-match-property-value-ecmascript@2.1.0")
    ("node_modules/unicode-property-aliases-ecmascript" . "unicode-property-aliases-ecmascript@2.1.0")
    ("node_modules/update-browserslist-db" . "update-browserslist-db@1.0.10")
    ("node_modules/util-deprecate" . "util-deprecate@1.0.2")
    ("node_modules/vinyl" . "vinyl@2.2.0")
    ("node_modules/vinyl-sourcemaps-apply" . "vinyl-sourcemaps-apply@0.2.1")
    ("node_modules/vscode-oniguruma" . "vscode-oniguruma@1.7.0")
    ("node_modules/vscode-textmate" . "vscode-textmate@5.2.0")
    ("node_modules/webidl-conversions" . "webidl-conversions@3.0.1")
    ("node_modules/whatwg-url" . "whatwg-url@5.0.0")
    ("node_modules/wrappy" . "wrappy@1.0.2")
    ("node_modules/ws" . "ws@8.2.3")
    ("node_modules/yallist" . "yallist@3.1.1")
    ("node_modules/yauzl" . "yauzl@2.10.0")
    ))

(define %rot-js-npm-paths (map car %rot-js-npm-path-keys))

(define (record->source record)
  (let* ((fields (string-split record #\tab))
         (name (list-ref fields 0))
         (version (list-ref fields 1)))
    (cons (string-append name "@" version)
          (origin
            (method url-fetch)
            (uri (list-ref fields 2))
            (file-name (string-append
                        "rot-js-"
                        (string-map
                         (lambda (c)
                           (if (or (char=? c #\/) (char=? c #\@)) #\- c))
                         name)
                        "-" version ".tar.gz"))
            (sha256 (base32 (list-ref fields 3)))))))

(define %rot-js-npm-sources
  (map record->source
       (remove string-null? (string-split %rot-js-npm-records #\newline))))
