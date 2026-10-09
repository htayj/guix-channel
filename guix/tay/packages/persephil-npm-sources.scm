;;; Fixed npm sources for Persephil 1.0.0.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages persephil-npm-sources)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-13)
  #:export (%persephil-npm-sources
            %persephil-extra-notices))

;; Derived from the complete lockfileVersion 1 package-lock.json at
;; cookinrelaxin/persephil commit 1e10afbbcb8c6f56d2cc22db0c915a9d64ecd8d6.
;; Lockfile SHA-256: cf7ce56f055fa00f038e4f4aca16e138ea42c387dc0fbe9a965ef647d7c4f677.
;; Its 196 top-level and 18 nested entries are 214 installation paths using
;; 204 distinct archives.  Every path, including the optional source-map
;; entry, is retained without version substitution or lifecycle execution.
;; Every archive was fetched, checked against every lock SRI and registry
;; SRI/SHA-1, and hashed over the actual downloaded bytes with guix hash.
;; Archive names, versions, and dependency declarations match the lock.
;; No native addons, compiled platform blobs, or install hooks were found.
;;
;; Actual grant texts were audited for all 204 archives, not merely their
;; manifest license fields.  Existing notices and README/source-header grants
;; are retained by materializing complete archives.  assert-plus and isarray
;; include full MIT notices in README files; omissions are repaired below.
;; JSZip's MIT option is selected while its complete dual notice is retained.
;; Pako includes both MIT and Zlib source-header grants, also retained in
;; the bundled browser distributions of ExcelJS and JSZip.  jsbn and the copy
;; bundled in ecc-jsbn carry Tom Wu's permissive retained-notice variant,
;; rather than exactly the Expat license claimed by their manifests.
;; bcrypt-pbkdf includes BSD-3-Clause and ISC components; fs.realpath includes
;; its ISC grant plus bundled Node.js MIT code.
;;
;; Each tab-separated record is installation path, npm name, exact version,
;; actual archive SHA-256 (Nix base32), and the audited license selection.
(define %persephil-npm-records
  (string-append
    "node_modules/@fast-csv/format\t@fast-csv/format\t4.3.5\t0s3xwz6p81qrlm87i3s9ln3qy0d9naj6dqpjhjp0bwkaq16fha4j\tMIT\n"
    "node_modules/@fast-csv/parse\t@fast-csv/parse\t4.3.6\t0br2g791x9pl0mkb0s70idahjvwfbx1rdjbyyz04h5q74lszmba6\tMIT\n"
    "node_modules/@sindresorhus/is\t@sindresorhus/is\t4.0.0\t1w0yf0a045fqimyx3nqsvwkz9mwcvl3kgz3ji7mc783iiv6gjifv\tMIT\n"
    "node_modules/@szmarczak/http-timer\t@szmarczak/http-timer\t4.0.5\t0mk3f5svsap1gagcplx6fas6vjx7wlvy6bknjb38in6aw5s2hxmy\tMIT\n"
    "node_modules/@types/cacheable-request\t@types/cacheable-request\t6.0.1\t16vy4rbbfqp8ycabpizkxld47ysmhnmg6zr9lfdwrf7cm5r5nc66\tMIT\n"
    "node_modules/@types/http-cache-semantics\t@types/http-cache-semantics\t4.0.0\t151xmhw5df8hmc1h9dawll7b3a7yb5c6mcy97d96vxpmirvh1i43\tMIT\n"
    "node_modules/@types/keyv\t@types/keyv\t3.1.1\t0c8rgji10f2plpscqcfavlrg0dw5azhq236nqspphs32ragm12s9\tMIT\n"
    "node_modules/@types/node\t@types/node\t14.14.21\t1rixa4xkrf86w68s0kvf1ahdn3r3sgvfvbp3xrjw6lvx5gfg8jzq\tMIT\n"
    "node_modules/@types/responselike\t@types/responselike\t1.0.0\t114lv93mq0g844i4r9vqnj1c1nzc3yv40v3s7rm9r1417s8l1b8s\tMIT\n"
    "node_modules/abab\tabab\t2.0.5\t0j51k6ibwnalbfk8zcwglm3wxa5y1s4c6fb825qs5ifdqj989azl\tBSD-3-Clause\n"
    "node_modules/acorn\tacorn\t7.4.1\t0yq7vkhy6nxbh5jp0iinqcbsqhh05wbzaqavh75ss00hy56m1w6s\tMIT\n"
    "node_modules/acorn-globals\tacorn-globals\t6.0.0\t0gx7r9jhzw3qa830shgrsphx7sa6721qa890zn6hgvvs409a437p\tMIT\n"
    "node_modules/acorn-walk\tacorn-walk\t7.2.0\t15k8gijbirgc0k7vlxaqy4jwyykr0d4y3pcx3hiv7gxyrqkb3jci\tMIT\n"
    "node_modules/ajv\tajv\t6.12.6\t0jhk2dnzrk188p3micnkh7126lhdbkj9iip0pywhky6vh1dk8xcr\tMIT\n"
    "node_modules/archiver\tarchiver\t5.2.0\t0xwgqvlrjwxhw27mpiw1jflbplh0g51l43csfmmfws38fcjpc0n4\tMIT\n"
    "node_modules/archiver-utils\tarchiver-utils\t2.1.0\t0i3ba81mik977a91nmhq5ziabzd6azn4id4qim8wpfnrwjn7vxr8\tMIT\n"
    "node_modules/archiver-utils/node_modules/readable-stream\treadable-stream\t2.3.7\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\tMIT\n"
    "node_modules/archiver-utils/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/asn1\tasn1\t0.2.4\t0fymjdkmd7kg4kyga0hssiwdz9jz5nv8fyndl3l1dr9q9jbl9971\tMIT\n"
    "node_modules/assert-plus\tassert-plus\t1.0.0\t1srkj0nyslz3rbfncj59sqbsllavmwik8gphd7jxwjshf52mras7\tMIT\n"
    "node_modules/async\tasync\t3.2.0\t0wb7236biqcl1rpvkddnplrx70khsp5wymdr5vzv9x4ix7gy3n3p\tMIT\n"
    "node_modules/asynckit\tasynckit\t0.4.0\t1kvxnmjbjwqc8gvp4ms7d8w8x7y41rcizmz4898694h7ywq4y9cc\tMIT\n"
    "node_modules/aws-sign2\taws-sign2\t0.7.0\t12bjw01pgh0nfyxi7vw6lvsapyvnazrnyn4qf87lclardjaz9yd8\tApache-2.0\n"
    "node_modules/aws4\taws4\t1.11.0\t1a9gd1wyx3k9agcprmgpfhp63w9v6cvf2kxfnijk77k6zcqqqjnd\tMIT\n"
    "node_modules/balanced-match\tbalanced-match\t1.0.0\t1bgzp9jp8ws0kdfgq8h6w3qz8cljyzgcrmxypxkgbknk28n615i8\tMIT\n"
    "node_modules/base64-js\tbase64-js\t1.5.1\t118a46skxnrgx5bdd68ny9xxjcvyb7b1clj2hf82d196nm2skdxi\tMIT\n"
    "node_modules/bcrypt-pbkdf\tbcrypt-pbkdf\t1.0.2\t09kqy1rjj0b1aavdssglrjj8ayf9vxvnnvlh5ah270j3bngrwgp1\tBSD-3+ISC\n"
    "node_modules/big-integer\tbig-integer\t1.6.48\t1faa99cm6lras5jw84w65gxlhiml4drvx9w142zf9cxc4g74bnbw\tUnlicense\n"
    "node_modules/binary\tbinary\t0.3.0\t02b9idb0bfzzhdncf0a23s41k9570lyvx89wds3pba5j1yscj2wl\tMIT\n"
    "node_modules/bl\tbl\t4.0.3\t1f3qvcsgql7gc2zm5lz9lsn0a2n0i06931yrczaijx9x5gvg76li\tMIT\n"
    "node_modules/bluebird\tbluebird\t3.4.7\t1pg2s95l855gcpfbip4zbpznah9li7kcmzd7n8v460i85p1ql8p9\tMIT\n"
    "node_modules/brace-expansion\tbrace-expansion\t1.1.11\t1nlmjvlwlp88knblnayns0brr7a9m2fynrlwq425lrpb4mcn9gc4\tMIT\n"
    "node_modules/browser-process-hrtime\tbrowser-process-hrtime\t1.0.0\t1srl044z6s42prb1jbq9v6fmgc0aq41jihhy981hys5bipkm79qj\tBSD-2-Clause\n"
    "node_modules/buffer\tbuffer\t5.7.1\t1g60az00dzb1grcszyg12gyrl9jr9bwvrk2y9xjdwym3nxasrgwq\tMIT\n"
    "node_modules/buffer-crc32\tbuffer-crc32\t0.2.13\t0vf6adpqimbz921y729mf91pvghihj44js2ck5ci44zh4x21bl97\tMIT\n"
    "node_modules/buffer-indexof-polyfill\tbuffer-indexof-polyfill\t1.0.2\t1j4x63gh145vlv4cfr7xfflrpf9g6gqc8688fmi5yg6mb08s696g\tMIT\n"
    "node_modules/buffers\tbuffers\t0.1.1\t0vgb3m22f4vlnwh35ijs733cxfvmfzcbb1wn5lc0aw261v34kppq\tMIT\n"
    "node_modules/cacheable-lookup\tcacheable-lookup\t5.0.4\t1346y7d3p5b4jmfc39k8csxks229nkmdmanmmzabqnya0vzan694\tMIT\n"
    "node_modules/cacheable-request\tcacheable-request\t7.0.1\t1xkjkfn2j0jckl0i10laz2s3pjjk1j7ffl16h8bjkwjyb0bx6lyv\tMIT\n"
    "node_modules/caseless\tcaseless\t0.12.0\t165fzm8s6qxapxk8xlb548q58xjav55k5nnychr234282irb2zjd\tApache-2.0\n"
    "node_modules/chainsaw\tchainsaw\t0.1.0\t1yvcjymlp04v3hi25b131zilyw7004nq4sgzgbh4l5yil5m6ln01\tX11\n"
    "node_modules/clone-response\tclone-response\t1.0.2\t1jyryzlw5ximj3sbg8dmwdp5fyjs655qllp5il8xzirz9awg8dmb\tMIT\n"
    "node_modules/combined-stream\tcombined-stream\t1.0.8\t04hm5rrkwda2qgy1afwhrz42asmflw5hxkbpxddn741ywnmmmgmn\tMIT\n"
    "node_modules/compress-commons\tcompress-commons\t4.0.2\t0k4x8hxgi13d8xp3fwlkvggymlwc0w8y350pwgh0zmdrhwlwd3ws\tMIT\n"
    "node_modules/concat-map\tconcat-map\t0.0.1\t0qa2zqn9rrr2fqdki44s4s2dk2d8307i4556kv25h06g43b2v41m\tMIT\n"
    "node_modules/core-util-is\tcore-util-is\t1.0.2\t164k94d9bdzw1335kzakj7hflhnnixpx4n6ydbhf7vbrcnmlv954\tMIT\n"
    "node_modules/crc-32\tcrc-32\t1.2.0\t0qndjw0lw3axa2n4vfp4i58gdd6bb0c9inpmzlsqb7zn8n4yn1c6\tApache-2.0\n"
    "node_modules/crc32-stream\tcrc32-stream\t4.0.1\t0m9df8g5ch6xq0qia1z3q9iw6p6ap92i7pnxwgnl1rrmas2liikk\tMIT\n"
    "node_modules/cssom\tcssom\t0.4.4\t17nwd1s7avgi7ry3ph65pqx9q3v4wb920hjka2n07jbdn716610p\tMIT\n"
    "node_modules/cssstyle\tcssstyle\t2.3.0\t0h2agjnzr4z6m4rbvd15ifsa66xfaa3lsklbsgqbp5jdhgy4fg1g\tMIT\n"
    "node_modules/cssstyle/node_modules/cssom\tcssom\t0.3.8\t0dq5z0asdnnvlpgjfc8ylzn78lpdkpqqd66djwdcdlnwp07d6d81\tMIT\n"
    "node_modules/dashdash\tdashdash\t1.14.1\t0h2kaml5wgx5x430wlbnjz3j6q1ppvndqckylfmi13xa33gfnycb\tMIT\n"
    "node_modules/data-urls\tdata-urls\t2.0.0\t05rjf9s8dj8vz6fz9xipid152vm2c6lyf8cnbgg0f6di6hd3bxa1\tMIT\n"
    "node_modules/dayjs\tdayjs\t1.10.3\t1p509qn6yr6r9ds6qjhigayhflxvbkxq7pvkc3pk36dpmxxzdg2b\tMIT\n"
    "node_modules/decimal.js\tdecimal.js\t10.2.1\t151kp5bqppd35645zvgy9r9lh39x8n1a2f4hb5vvwi4idwrzklnf\tMIT\n"
    "node_modules/decompress-response\tdecompress-response\t6.0.0\t0krv58fihkajrskzakm1i69kklv0ycabrjmlgk2a9kkv0idlqznm\tMIT\n"
    "node_modules/decompress-response/node_modules/mimic-response\tmimic-response\t3.1.0\t0m6xcg030cw88cja84avw63q3jkvqgbdp74xvs1p3m2w2my9n7ij\tMIT\n"
    "node_modules/deep-is\tdeep-is\t0.1.3\t11m7mds6valw8m5c5hgjnr83s104nirkvcnmclm38g02gvxf4rcq\tMIT\n"
    "node_modules/defer-to-connect\tdefer-to-connect\t2.0.0\t0wy6mv25annl04jing9va8r9f6nslr3lvjhnfi3kkvdn5s2a3l6s\tMIT\n"
    "node_modules/delayed-stream\tdelayed-stream\t1.0.0\t1lr98585rayrc5xfj599hg6mxqvks38diir74ivivyvx47jgqf5c\tMIT\n"
    "node_modules/domexception\tdomexception\t2.0.1\t1lazwin18388yh147cfqnmwivarcfqj6my25y9vrvffin7cyzwah\tMIT\n"
    "node_modules/domexception/node_modules/webidl-conversions\twebidl-conversions\t5.0.0\t0g93qy40qshrjf36a0y1g58003bixcvjbsgpnr1xxdb31wn7s0bh\tBSD-2-Clause\n"
    "node_modules/duplexer2\tduplexer2\t0.1.4\t0scvc51gwkvw22kfacgvnz4ppbwcdgql2x2idg5009icx2z613jz\tBSD-3-Clause\n"
    "node_modules/duplexer2/node_modules/readable-stream\treadable-stream\t2.3.7\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\tMIT\n"
    "node_modules/duplexer2/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/ecc-jsbn\tecc-jsbn\t0.1.2\t0x39lihzphr0h1fvh9p65k86vx3p7z6jrxgv4b402lvdrifd56k0\tMIT+Tom-Wu\n"
    "node_modules/end-of-stream\tend-of-stream\t1.4.4\t1d8dvwmq5krcjakr2s7b2dwh8x6zgs8qj8mdwkgxsvx7rgqfr2qb\tMIT\n"
    "node_modules/escodegen\tescodegen\t1.14.3\t12rngj20cpcnayic21ky3rkmkldbcvrzxzsr9y6a9diaf9lgldzj\tBSD-2-Clause\n"
    "node_modules/esprima\tesprima\t4.0.1\t0x6cjgh4452wa28yz562b4c2dad78rn3fxfzqns9bk5ykh7938fq\tBSD-2-Clause\n"
    "node_modules/estraverse\testraverse\t4.3.0\t1bpip5qvpq6f6prpn5dsxnqsaw3czx6hn8mps04v5vpqgla2n9kz\tBSD-2-Clause\n"
    "node_modules/esutils\tesutils\t2.0.3\t03v4y32k50mbxwv70prr7ghwg59vd5gyxsdsbdikqnj919rvvbf5\tBSD-2-Clause\n"
    "node_modules/exceljs\texceljs\t4.2.0\t0c3hii8pgrmbhiz5ibz1vdgvbxnxy52bmamnigy5d6bnq5n3h4nc\tMIT+Zlib\n"
    "node_modules/exceljs/node_modules/uuid\tuuid\t8.3.2\t0jljg4g6m0znnqm93ng9xwj9g63csbwdqbjlb9rir0m58wv70c7n\tMIT\n"
    "node_modules/exit-on-epipe\texit-on-epipe\t1.0.1\t0sfb0xwj9giar420zdlnzaldqpdvq14xdq24zmkr4j5yk30bkb03\tApache-2.0\n"
    "node_modules/extend\textend\t3.0.2\t1ckjrzapv4awrafybcvq3n5rcqm6ljswfdx97wibl355zaqd148x\tMIT\n"
    "node_modules/extsprintf\textsprintf\t1.3.0\t0i6hmr7mkg76rgrxs7f0xny48kha2xi03wj43mfik77m0lk3k6yg\tMIT\n"
    "node_modules/fast-csv\tfast-csv\t4.3.6\t1fzlm4j6cbg82kij96g63da504jdpv4j71382fjl4hkgms1c3x3w\tMIT\n"
    "node_modules/fast-deep-equal\tfast-deep-equal\t3.1.3\t13vvwib6za4zh7054n3fg86y127ig3jb0djqz31qsqr71yca06dh\tMIT\n"
    "node_modules/fast-json-stable-stringify\tfast-json-stable-stringify\t2.1.0\t11qnzlan5yd2hg9nqi9hdv48bq6kwvw9pxsxir22n2iyqhighb8y\tMIT\n"
    "node_modules/fast-levenshtein\tfast-levenshtein\t2.0.6\t0g5zgdlp38dli94qbbm8vhvmj90fh48sxpggfn2083wbdcq50jxv\tMIT\n"
    "node_modules/forever-agent\tforever-agent\t0.6.1\t1i86r2ip6ryrnpg3v7pf0ywddhsdlr809xycd3zm9gq7zphn5a7c\tApache-2.0\n"
    "node_modules/form-data\tform-data\t2.3.3\t1j1ka178syqqaycr1m3vqahbb3bi7qsks0mp0iqbd6y7yj1wz7p3\tMIT\n"
    "node_modules/fs-constants\tfs-constants\t1.0.0\t1yn5qyvxf9i3zrfly77wgmi3j9fl61gh1i0jjgamnir43dz6v4z7\tMIT\n"
    "node_modules/fs.realpath\tfs.realpath\t1.0.0\t174g5vay9jnd7h5q8hfdw6dnmwl1gdpn4a8sz0ysanhj2f3wp04y\tISC+MIT\n"
    "node_modules/fstream\tfstream\t1.0.12\t0r3m7cl7wqfgkm8wzrvm2fl4wl0dwzbz2yh6aw3gd2zka3jyg5vk\tISC\n"
    "node_modules/fstream/node_modules/rimraf\trimraf\t2.7.1\t0g1grvjh2bpjpalqszzprh6hvnlvab9pmqa137yslysbv6g4x7h0\tISC\n"
    "node_modules/get-stream\tget-stream\t5.2.0\t077iv0jqfgqyxw6jb0iradw9idjcmphmrc58zj050vf58yx0bzkr\tMIT\n"
    "node_modules/getpass\tgetpass\t0.1.7\t0ifl7rdzhkbwzb2pmi6mxvv92qd2ihbfbfkipw9nqvbn22x140wg\tMIT\n"
    "node_modules/glob\tglob\t7.1.6\t1hm62p225wxx15k5kw9b5byif2rdi4ivn2a595lfvv26niq53c2l\tISC\n"
    "node_modules/got\tgot\t11.8.1\t0q679rjgj44zjn4zkbla9zsppc2ksgm8rgyfdqnnkxf49r4h2rry\tMIT\n"
    "node_modules/graceful-fs\tgraceful-fs\t4.2.4\t0l8p8vjiymrhvzizwh3z59vfrasl0k0dr7cz8s8j16c2dhn5gb98\tISC\n"
    "node_modules/har-schema\thar-schema\t2.0.0\t09myh5q5225c53v39mw9n3a2kgf2pk0z9dfwbmm7rbb70npq8yrf\tISC\n"
    "node_modules/har-validator\thar-validator\t5.1.5\t02vymdr8s3x1cbsv15m9fq6bnbiajyjy8vdz0hl9vrv8xi5ay27f\tMIT\n"
    "node_modules/html-encoding-sniffer\thtml-encoding-sniffer\t2.0.1\t0syp1llr6i6dl1mvcgg9by9rylghy39z1q3flv8a0yyr6f92k1pw\tMIT\n"
    "node_modules/http-cache-semantics\thttp-cache-semantics\t4.1.0\t1j18fxbpdb6f43w7ndmqlmf7r0l9wv2m837mvvqi3y122xig0c0g\tBSD-2-Clause\n"
    "node_modules/http-signature\thttp-signature\t1.2.0\t1y856b84kxhq6wc9yiqcfhd4187nizr7lhxi9z69mwzavmpnvgk6\tMIT\n"
    "node_modules/http2-wrapper\thttp2-wrapper\t1.0.0-beta.5.2\t0gfi4pn17arr70imznry86s2wm3rxphndz39jmw52fr25ra76jd3\tMIT\n"
    "node_modules/iconv-lite\ticonv-lite\t0.4.24\t0da6ff7dlx6lfhdafsd9sv0h09sicpfakms8bqylrm4f17r68v2p\tMIT\n"
    "node_modules/ieee754\tieee754\t1.2.1\t1b4xiyr6fmgl05cjgc8fiyfk2jagf7xq2y5rknw9scvy76dlpwcf\tBSD-3-Clause\n"
    "node_modules/immediate\timmediate\t3.0.6\t04cxfcl4zm2qfsrrd19n5w4w8k8309wl1k2xq0c0ic2hjvrr5iwq\tMIT\n"
    "node_modules/inflight\tinflight\t1.0.6\t16w864087xsh3q7f5gm3754s7bpsb9fq3dhknk9nmbvlk3sxr7ss\tISC\n"
    "node_modules/inherits\tinherits\t2.0.4\t1bxg4igfni2hymabg8bkw86wd3qhhzhsswran47sridk3dnbqkfr\tISC\n"
    "node_modules/ip-regex\tip-regex\t2.1.0\t112mhkg5hppzm25njrb8asj9i99f5m8mq6qzgy3imijmmk0pk1fb\tMIT\n"
    "node_modules/is-potential-custom-element-name\tis-potential-custom-element-name\t1.0.0\t01k3vw2sj7lcsb716azr9ja0jfs3gi83cgclagwx5p4gqip96fnc\tMIT\n"
    "node_modules/is-typedarray\tis-typedarray\t1.0.0\t0i9qr2b79d0chhvpd1fc5pcp9bvirpg37f99d40alciqffmrfp0d\tMIT\n"
    "node_modules/isarray\tisarray\t1.0.0\t11qcjpdzigcwcprhv7nyarlzjcwf3sv5i66q75zf08jj9zqpcg72\tMIT\n"
    "node_modules/isstream\tisstream\t0.1.2\t0i0br6synccpj2ian2z5fnnna99qq4w73dbp46vnyi53l9w47bkr\tMIT\n"
    "node_modules/jsbn\tjsbn\t0.1.1\t08r3wxx18yixax4w9rs18ya1ggw6kgzjhw5vbsj7sb8a974lpi2s\tTom-Wu\n"
    "node_modules/jsdom\tjsdom\t16.4.0\t0v01cvr1x354gyrirpba1hsbzg6fv11n6v8b0f46wjzlsf7vxy9n\tMIT\n"
    "node_modules/json-buffer\tjson-buffer\t3.0.1\t19gmzrfyy4k7sckqgc3gsz5hpkjg6gg75nhrr5rmyg3ip56ldxyi\tMIT\n"
    "node_modules/json-schema\tjson-schema\t0.2.3\t0gwkxqmwlwb5nffgxsjf1rcd1lv21br555mxr5mcnc60zd9kq5p3\tBSD-3-Clause\n"
    "node_modules/json-schema-traverse\tjson-schema-traverse\t0.4.1\t0rf0pvm62k8g81vs7n7zx080p6sfylwk52vc149jx1216vcssdgp\tMIT\n"
    "node_modules/json-stringify-safe\tjson-stringify-safe\t5.0.1\t12ljc7ipy7cprz5zxzzds20ykw6z5616763ca5zx9xmzq1jvzyxp\tISC\n"
    "node_modules/jsprim\tjsprim\t1.4.1\t0ipc481jham9q4ayfl335zjdfmnxc1wcixx5qibfwl2ncz60gwqx\tMIT\n"
    "node_modules/jszip\tjszip\t3.5.0\t17s2xlixnqkyp80mvcqf61np6gpw53hn593f5m4dd35w2x8wydz5\tMIT+Zlib\n"
    "node_modules/jszip/node_modules/readable-stream\treadable-stream\t2.3.7\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\tMIT\n"
    "node_modules/jszip/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/keyv\tkeyv\t4.0.3\t0va2wmaqk66300c9k7r3g5mam10cscgrz7aqlas54ml54s3xc6is\tMIT\n"
    "node_modules/lazystream\tlazystream\t1.0.0\t1v7ph73zb6nv0fz9ipdx3ddximjr9d3n9zn8hlb5mnz61dwyw3qx\tMIT\n"
    "node_modules/lazystream/node_modules/readable-stream\treadable-stream\t2.3.7\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\tMIT\n"
    "node_modules/lazystream/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/levn\tlevn\t0.3.0\t094nf5lc3jk3gv0hs01nzgq2vw0h2y9cxaqsbgs0xc45in2kw0ds\tMIT\n"
    "node_modules/lie\tlie\t3.3.0\t0vm3wrzfrjmv2qjcf6fch7znad6k6kd5b34cb31jy3m1shf4df1d\tMIT\n"
    "node_modules/listenercount\tlistenercount\t1.0.1\t1kahapbdk5xi5njdjh93xsj17w4sykknq8yw7d9dnp32srnr6kyx\tISC\n"
    "node_modules/lodash\tlodash\t4.17.20\t1qpjahj6j8l9sag75f9sxfl85r6ab8f7v8w5axv9319wzim8ranj\tMIT\n"
    "node_modules/lodash.defaults\tlodash.defaults\t4.2.0\t1rpssxhnp61g6nz9nfvlc90i23rbj08ryvcl6g3vlcyvbh5266h8\tMIT\n"
    "node_modules/lodash.difference\tlodash.difference\t4.5.0\t0nbsibfwgiaja5x0mf46diyl51v42z4hj0dslxpk6a1wh3566rwy\tMIT\n"
    "node_modules/lodash.escaperegexp\tlodash.escaperegexp\t4.1.2\t0fj8ij578wkbyakvx7br0q42868rshmcvbmb2zckj6h3i119mr0p\tMIT\n"
    "node_modules/lodash.flatten\tlodash.flatten\t4.4.0\t1z112mf1hlshmqs37w8x1yfm13dxjd7l9yf7y5csjj2jig6snfww\tMIT\n"
    "node_modules/lodash.groupby\tlodash.groupby\t4.6.0\t1z9457xlzxqjm2yya99rzx1ypmy00im0nwvilwd2ks3qjk8wcxzy\tMIT\n"
    "node_modules/lodash.isboolean\tlodash.isboolean\t3.0.3\t17gfvibwm5bk7g0z4mrc3gmrl85qal1x37x7b05xqfykyla2198i\tMIT\n"
    "node_modules/lodash.isequal\tlodash.isequal\t4.5.0\t0y22hfws19nwmqg6jm9sqb9i7spsnjg7fmnf506avjl5ajjk9dd3\tMIT\n"
    "node_modules/lodash.isfunction\tlodash.isfunction\t3.0.9\t1l2y4p6cc4c0irc9iyp1f9f02v6xfj19g1j3qn00n2hf2q80bv23\tMIT\n"
    "node_modules/lodash.isnil\tlodash.isnil\t4.0.0\t1gnc24zadb7n2vw0ka04xjcdl5x2mnc05889l3kgypr3sjf8k0lq\tMIT\n"
    "node_modules/lodash.isplainobject\tlodash.isplainobject\t4.0.6\t1l3jmn7j4nzmv7pq24nawmjarb1gj647p786hjpjg5qkrvhj0r4q\tMIT\n"
    "node_modules/lodash.isundefined\tlodash.isundefined\t3.0.1\t1d8pc0qahmksawl6z32i60dmi831rxmjsny8949scddn7g8zrkik\tMIT\n"
    "node_modules/lodash.sortby\tlodash.sortby\t4.7.0\t0jjm2g5q17j1wrjxdci7vv1frm5vigmxgkm5a91p98qlbpzdd71j\tMIT\n"
    "node_modules/lodash.union\tlodash.union\t4.6.0\t03i0ka26sdfaw5vc2grvqcf5r9l6lsyl4wlqhkgqp1pkc5s8681g\tMIT\n"
    "node_modules/lodash.uniq\tlodash.uniq\t4.5.0\t0imzfaqamjkg9h84di7p8ji5cip2kh8hvk9wg9n84yjgi4qvqv0f\tMIT\n"
    "node_modules/lowercase-keys\tlowercase-keys\t2.0.0\t0l9vf2m7zz1hw8s0l2njhk3b128mq0z27z17dgpmk4ivcg181ij3\tMIT\n"
    "node_modules/mime-db\tmime-db\t1.45.0\t0bva1q84z8cjvh1nibqz4155ylyqan4yqx9a99mriz11swngdn23\tMIT\n"
    "node_modules/mime-types\tmime-types\t2.1.28\t0c60ajxcvvxmbgvpqzihhcj2bqa4dp75snvr9nnja8ri7wkhvr8w\tMIT\n"
    "node_modules/mimic-response\tmimic-response\t1.0.1\t1s4cran004criblxk656ajagx924cy3wps608ksssyxc1qn01wa2\tMIT\n"
    "node_modules/minimatch\tminimatch\t3.0.4\t0wgammjc9myx0k0k3n9r9cjnv0r1j33cwqiy2fxx7w5nkgbj8sj2\tISC\n"
    "node_modules/minimist\tminimist\t1.2.5\t0l23rq2pam1khc06kd7fv0ys2cq0mlgs82dxjxjfjmlksgj0r051\tMIT\n"
    "node_modules/mkdirp\tmkdirp\t0.5.5\t02mvn5hllnsxzli8yy0gkgkkxndbwd3fh302shadsag3c4db0njf\tMIT\n"
    "node_modules/moment\tmoment\t2.29.1\t0m9c1i494f6yxmb1md5s7idrhqwqbk35zz5fv539hzh2cjd0y622\tMIT\n"
    "node_modules/normalize-path\tnormalize-path\t3.0.0\t1zl49w6pdbgi96sgxpzr0gizcj261v6mxv8rx70csmf5ap53r60b\tMIT\n"
    "node_modules/normalize-url\tnormalize-url\t4.5.0\t1wm0h68c4i0psb9j8a1r3f2dlrhfxdww1s4r26jwyh9w49lbjcwp\tMIT\n"
    "node_modules/nwsapi\tnwsapi\t2.2.0\t0jbcp1q9razd2sck9fw2zql3x66s9yv1s4q92z9px4hpyafiaidc\tMIT\n"
    "node_modules/oauth-sign\toauth-sign\t0.9.0\t1g6rl2pv86pxcx4mv25qqv0w265mc5ardp3vxd2hqg80c4bsy5h0\tApache-2.0\n"
    "node_modules/once\tonce\t1.4.0\t1kygzk36kdcfiqz01dhql2dk75rl256m2vlpigv9iikhlc5lclfg\tISC\n"
    "node_modules/optionator\toptionator\t0.8.3\t0gdxsryh0g0vrbjqrgg8bvzjj2m98hf1rg8sksjmslspkr4fdvsi\tMIT\n"
    "node_modules/p-cancelable\tp-cancelable\t2.0.0\t1kl4ybdzpm7lb7559vr0mqcjavi5lln5bg1vc163z7gwva5nh17k\tMIT\n"
    "node_modules/pako\tpako\t1.0.11\t0h9rmpkzyav4qxpb185z89nrhi17gy8p5mxz1k1l19sj0gf2hh0d\tMIT+Zlib\n"
    "node_modules/parse5\tparse5\t5.1.1\t0x9yhqny7n39bsa1xy52xsc6yx1zs5v8mn79bv67x2mpf3zpwwlj\tMIT\n"
    "node_modules/path-is-absolute\tpath-is-absolute\t1.0.1\t0p7p04xxd8q495qhxmxydyjgzcf762dp1hp2wha2b52n3agp0vbf\tMIT\n"
    "node_modules/performance-now\tperformance-now\t2.1.0\t0ich517fgk1nhmcjs2mfv4dp70ppqvj3xgmv3syl25zixzfrk3q6\tMIT\n"
    "node_modules/prelude-ls\tprelude-ls\t1.1.2\t0msvwq9la3w6wm51s2p3j2dv6634sj7iydyx3iqw4y67vkj8zzgs\tMIT\n"
    "node_modules/printj\tprintj\t1.1.2\t0c5hrnv41f1j9py6chaac37gdb5qymcdab4xill8jcqs8hmv65h6\tApache-2.0\n"
    "node_modules/process-nextick-args\tprocess-nextick-args\t2.0.1\t16w8m2ycy5s4ykgdfg97qxa67gfvkh6x3vdwfsncafyj4p3zhns2\tMIT\n"
    "node_modules/psl\tpsl\t1.8.0\t03jj0mly8g6hrjaj8h77q0w02z3awgvy6ld051ph2k38fji3zdgb\tMIT\n"
    "node_modules/pump\tpump\t3.0.0\t1vq58w7663jdwlsks9qbzga0bsca11il5x04w9q2q0qlllb14k41\tMIT\n"
    "node_modules/punycode\tpunycode\t2.1.1\t0g7z0kdxs15jrcijwbka2jajgr4b7bvpa6xmrcs0wf82pxwx1k75\tMIT\n"
    "node_modules/qs\tqs\t6.5.2\t1w0n5rg0w76b97ds80svkhmcqzcn76c3g5z81sblvii89ww4k4sk\tBSD-3-Clause\n"
    "node_modules/quick-lru\tquick-lru\t5.1.1\t1prmggnyx8kw2f4fxbqpaj9hnlpkxaydmkgrvi7qv8h9la25i0xr\tMIT\n"
    "node_modules/readable-stream\treadable-stream\t3.6.0\t1fy6kya4g3zwjdc0xfg7gdzg9ynqnqzv9ay301ay174vvp9202ak\tMIT\n"
    "node_modules/readdir-glob\treaddir-glob\t1.1.1\t01422jh83h6wvib4fggc3334im2fv19lf5a2m0j7xf0gxzawsy65\tApache-2.0\n"
    "node_modules/request\trequest\t2.88.2\t0hj2f9qqn3hpzpvhsnbwhzjyn5f8aicjz5wn00q0mfc4824awvg8\tApache-2.0\n"
    "node_modules/request-promise-core\trequest-promise-core\t1.1.4\t1xp1z9iy6i9v2fvjs583dfjckg50f45zgas5ybih4bmjhcsdp7zm\tISC\n"
    "node_modules/request-promise-native\trequest-promise-native\t1.0.9\t02gjp77mcys7kh873mwm8277ipcqh5ac6jhzf34mpivk3z0bka0y\tISC\n"
    "node_modules/request-promise-native/node_modules/tough-cookie\ttough-cookie\t2.5.0\t0knsdm6l5mn88rh78hajzr2rrydal6wf97l2pbpqjq8ws4w8gazh\tBSD-3-Clause\n"
    "node_modules/request/node_modules/tough-cookie\ttough-cookie\t2.5.0\t0knsdm6l5mn88rh78hajzr2rrydal6wf97l2pbpqjq8ws4w8gazh\tBSD-3-Clause\n"
    "node_modules/resolve-alpn\tresolve-alpn\t1.0.0\t0hi6m2zxzxlmaxz8hljdajdwz95bqlmr650xk1b9rysxllbiq6lj\tMIT\n"
    "node_modules/responselike\tresponselike\t2.0.0\t02qrxhnlm519fxnkvbj5bpzhx1g8fy4vmawilbz809f2i9jismip\tMIT\n"
    "node_modules/rimraf\trimraf\t3.0.2\t0lkzjyxjij6ssh5h2l3ncp0zx00ylzhww766dq2vf1s7v07w4xjq\tISC\n"
    "node_modules/safe-buffer\tsafe-buffer\t5.2.1\t1s5kvjpwqsc682zcy71h9c6pxla21sysfwj270x6jjkca421h62x\tMIT\n"
    "node_modules/safer-buffer\tsafer-buffer\t2.1.2\t1cx383s7vchfac8jlg3mnb820hkgcvhcpfn9w4f0g61vmrjjz0bq\tMIT\n"
    "node_modules/saxes\tsaxes\t5.0.1\t0jx20jcw7pvpj79jgy0rlq2qh7mqq725sagv4qf9vhm84x3137fk\tISC\n"
    "node_modules/set-immediate-shim\tset-immediate-shim\t1.0.1\t15nnjkv6nbpyjy2yrd1hzxrmd2i9q1093m9hvy5l0i4rzbaphbfp\tMIT\n"
    "node_modules/setimmediate\tsetimmediate\t1.0.5\t17icj9sgsg9fcyclds1a8mlgmspza3fa6sidq11fsr43d4igrfaw\tMIT\n"
    "node_modules/source-map\tsource-map\t0.6.1\t11ib173i7xf5sd85da9jfrcbzygr48pppz5csl15hnpz2w6s3g5x\tBSD-3-Clause\n"
    "node_modules/sshpk\tsshpk\t1.16.1\t0f885dfxv4nhpgsin60z0iflnbr9wfax9lwbcv4i9j3s7shxsjjw\tMIT\n"
    "node_modules/stealthy-require\tstealthy-require\t1.1.1\t131x1qz4kky2kjsywjfws1sivnx12yw6cmdqmk81f59xsabip7py\tISC\n"
    "node_modules/string_decoder\tstring_decoder\t1.1.1\t0fln2r91b8gj845j7jl76fvsp7nij13fyzvz82985yh88m1n50mg\tMIT\n"
    "node_modules/string_decoder/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/symbol-tree\tsymbol-tree\t3.2.4\t1g2ap5vvjzp141idqnd5vpn3hzy3ihwr8vqivyxdn2yh00570sca\tMIT\n"
    "node_modules/tar-stream\ttar-stream\t2.2.0\t0nrrl6sgl5yazgllc8ryxpg083432xwqvqbrlqdl16sfszgq73rs\tMIT\n"
    "node_modules/tmp\ttmp\t0.2.1\t16llcfa2ic24ahfz5y3bp858p78r589gx3vggpzy4zxwdx7xfv3x\tMIT\n"
    "node_modules/tough-cookie\ttough-cookie\t3.0.1\t1ajq5hlmi86ckbmdn6irgygi4vjd2aq5sh4xikhd443vswjilgad\tBSD-3-Clause\n"
    "node_modules/tr46\ttr46\t2.0.2\t1fmprji0dkrwljvpxh0na3pq634g30n0vgl0mm0jaq909d7x9wc0\tMIT\n"
    "node_modules/traverse\ttraverse\t0.3.9\t0hh92qg7n1byqifbk31ly108fdlw26f8nrr94szqhy7wmnqzc4vq\tMIT\n"
    "node_modules/tunnel-agent\ttunnel-agent\t0.6.0\t04jhbjld99zavh1rvik2bayrgxwj2zx69xsbcm0gmlnna15c1qyk\tApache-2.0\n"
    "node_modules/tweetnacl\ttweetnacl\t0.14.5\t1mnzrxlww1sqwv493gn6ph9ak7n8l9w5qrahsa5kzn4vgbb37skc\tUnlicense\n"
    "node_modules/type-check\ttype-check\t0.3.2\t05iwxwj2sdbnxwp5lkxrdkbdcdvmkvq6zbq7lmsg20zbw3pyy56l\tMIT\n"
    "node_modules/unzipper\tunzipper\t0.10.11\t0cmdgadfmnwrcrpmphsdb2x7z4613zcg48s9i40isjwsqrac54y7\tMIT\n"
    "node_modules/unzipper/node_modules/readable-stream\treadable-stream\t2.3.7\t1ivp6i6kf0li6ak443prb3h8bjsznymjaaclmmmy5p55gb7px809\tMIT\n"
    "node_modules/unzipper/node_modules/safe-buffer\tsafe-buffer\t5.1.2\t08ma0a2a9j537bxl7qd2dn6sjcdhrclpdbslr19bkbyc1z30d4p0\tMIT\n"
    "node_modules/uri-js\turi-js\t4.4.1\t0bcdxkngap84iv7hpfa4r18i3a3allxfh6dmcqzafgg8mx9dw4jn\tBSD-2-Clause\n"
    "node_modules/util-deprecate\tutil-deprecate\t1.0.2\t1rd3qbgdrwkmcrf7vqx61sh7icma7jvxcmklqj032f8v7jcdx8br\tMIT\n"
    "node_modules/uuid\tuuid\t3.4.0\t1pgldpxvxyy2a9h437v0mflqxyc4w91b37iya2pcfd5wdlqcjxxs\tMIT\n"
    "node_modules/verror\tverror\t1.10.0\t0swyg46nvq95xlrrjjbhhmhjrdxg19yrc1aj69zipck0vi24b6q1\tMIT\n"
    "node_modules/w3c-hr-time\tw3c-hr-time\t1.0.2\t02ivjx0d0qcl2xql989hmjcwlswvraz68ndl41xhjbys2hdp4sjw\tMIT\n"
    "node_modules/w3c-xmlserializer\tw3c-xmlserializer\t2.0.0\t1mnf8i2vbny9cp80j2rihh6pddisavxwq40m30midrzyqlcp9v26\tMIT\n"
    "node_modules/webidl-conversions\twebidl-conversions\t6.1.0\t0vmy507i24ca0zs0fb9bdp3w6n14p7d974ff62k2lpfjkp9irncm\tBSD-2-Clause\n"
    "node_modules/whatwg-encoding\twhatwg-encoding\t1.0.5\t0n6a241xc18cjfm2dhhv00v19f5da6d90gyvygzdnqc8v0fzil24\tMIT\n"
    "node_modules/whatwg-mimetype\twhatwg-mimetype\t2.3.0\t1ysy27vwlm149n2kdx0p8mi39vfp9gvj7z1070czdq3xw5xhzns8\tMIT\n"
    "node_modules/whatwg-url\twhatwg-url\t8.4.0\t0j5qsk0q33jfxhv8hm0fxfz1vrnfbzvsdsbxkvrhqyw3a4whxnqq\tMIT\n"
    "node_modules/word-wrap\tword-wrap\t1.2.3\t1ngw3nglmfh9a90b4ckay43yw96h61mbxmhm5g1qvk1j6h1dmyv4\tMIT\n"
    "node_modules/wrappy\twrappy\t1.0.2\t1yzx63jf27yz0bk0m78vy4y1cqzm113d2mi9h91y3cdpj46p7wxg\tISC\n"
    "node_modules/ws\tws\t7.4.2\t0mnfd8qa7ywjzv2cghxj36krslpjcg9annlfxvf7yijgpxacjpxp\tMIT\n"
    "node_modules/xml-name-validator\txml-name-validator\t3.0.0\t1gaj2d1lzv0sdms1sn3avasy04d4j9bbizfdyl7p72m52n0d31c4\tApache-2.0\n"
    "node_modules/xmlchars\txmlchars\t2.2.0\t1a3daxxjcy0p0qbxcqp6d9z6h1czsab5xabanyavvr33i4lh1ydx\tMIT\n"
    "node_modules/zip-stream\tzip-stream\t4.0.4\t11angwcapmaf7ywsf6a2254b1dffkx0rx4lhx1b25f01rnsdql06\tMIT\n"
    ))

(define %tom-wu-license
  (license:non-copyleft
   "file://node_modules/jsbn/LICENSE"
   "Tom Wu permissive grant requiring an intact copyright notice and disclaimer."))

(define (record-license key)
  (match key
    ("MIT" license:expat)
    ("ISC" license:isc)
    ("X11" license:x11)
    ("Apache-2.0" license:asl2.0)
    ("BSD-2-Clause" license:bsd-2)
    ("BSD-3-Clause" license:bsd-3)
    ("Unlicense" license:unlicense)
    ("Tom-Wu" %tom-wu-license)
    ("MIT+Tom-Wu" (list license:expat %tom-wu-license))
    ("MIT+BSD-3" (list license:expat license:bsd-3))
    ("MIT+Zlib" (list license:expat license:zlib))
    ("BSD-3+ISC" (list license:bsd-3 license:isc))
    ("ISC+MIT" (list license:isc license:expat))))

(define (npm-source record)
  (match (string-tokenize record)
    ((path name version hash license-key)
     (let ((base (last (string-split name #\/)))
           (safe-name (string-map
                       (lambda (character)
                         (if (or (char=? character #\/)
                                 (char=? character #\@))
                             #\_
                             character))
                       name)))
       (list path
             (string-append name "-" version)
             (origin
               (method url-fetch)
               (uri (string-append "https://registry.npmjs.org/" name
                                   "/-/" base "-" version ".tgz"))
               (file-name (string-append "persephil-" safe-name "-"
                                         version ".tgz"))
               (sha256 (base32 hash)))
             (record-license license-key))))))

;; Public rows are (installation-path name-version origin license-or-list).
(define %persephil-npm-sources
  (map npm-source
       (remove string-null?
               (string-split %persephil-npm-records #\newline))))

;; The published buffers 0.1.1 archive equals every file in parent commit
;; 51ac8d0324008b0d0ed5759b1466402a77ff8dc8.  James Halliday's license commit
;; 1b745ee35d33eb166e15ef1866073a07c6d7de87 changes only package.json and the
;; README to declare MIT/X11; every code file remains unchanged.  Retain that
;; primary README grant separately: it names MIT/X11 but contains no full
;; permission notice.  The complete MIT text is retained from Debian's
;; version-pinned node-buffers 0.1.1-2 copyright file, which cites that exact
;; grant.  Its copyright year 2015 is Debian-authored metadata, not a year
;; supplied in the upstream 2012 license commit.  No newer npm code is used.
;; chainsaw's manifest grants MIT/X11; the full version-pinned Debian notice
;; is the X11 variant, including its name-in-advertising restriction.  Debian
;; explicitly notes that the upstream tarball does not state copyright
;; ownership.  Preserve that provenance rather than inventing an upstream
;; copyright year.  saxes' notice and AUTHORS come from the v5.0.1 commit;
;; the notice explicitly labels its unused historical Bynens MIT component.
;; set-immediate-shim's notice comes from its npm registry gitHead commit.
;; json-schema 0.2.3's README grants AFL or BSD; select BSD-3-Clause.  The
;; recovered full dual text is pinned to 4f3db68fb98d9444850fec0ef5ed981c8beacfb6:
;; its lib files equal the published code after CRLF/LF normalization (the
;; archive remains byte-for-byte unchanged).  The shipped stale MIT headers
;; are retained; upstream corrected them in 55a6a1bbcd6e425b317dce71dbb36d9733a32716.
;; binary 0.3.0's published README explicitly declares MIT and its manifest
;; identifies James Halliday.  Preserve both unchanged.  Neither that archive
;; nor its Software Heritage revision 21a98b1cf0ffe33e992886f28fb0a34ac0e8b3f7
;; includes a full authored notice.  LICENSE-MIT-TERMS is therefore only a
;; verbatim canonical terms reference from SPDX license-list-data v3.27.0,
;; not an upstream-authored copyright notice or a new grant.  Its template
;; year/holder markers deliberately remain unfilled; no year is invented.
;; Notice rows are (installation-path origin); every source is hash-pinned.
(define %persephil-extra-notices
  (list
   (list "node_modules/buffers/LICENSE-GRANT-MIT-X11"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/bitpay/node-buffers/1b745ee35d33eb166e15ef1866073a07c6d7de87/README.markdown")
           (file-name "persephil-buffers-0.1.1-MIT-X11-grant")
           (sha256
            (base32 "140c1hnp3k7j8lap5mif97bpnphfmlrabibmzv77iraf8hd9fhrx"))))
   (list "node_modules/buffers/LICENSE-MIT"
         (origin
           (method url-fetch)
           (uri "https://sources.debian.org/data/main/n/node-buffers/0.1.1-2/debian/copyright")
           (file-name "persephil-buffers-0.1.1-MIT-notice")
           (sha256
            (base32 "0mm0a9pxrd27yz5v79vnv8wg7csmzzpsfgxzwa6sjxj4ph1klhlp"))))
   (list "node_modules/chainsaw/LICENSE-MIT-X11"
         (origin
           (method url-fetch)
           (uri "https://sources.debian.org/data/main/n/node-chainsaw/0.1.0-2/debian/copyright")
           (file-name "persephil-chainsaw-0.1.0-MIT-X11-notice")
           (sha256
            (base32 "1rajm1g6bnbwlligzcnjpjsdwxcivbpxys1ra34qgwj2b4wiv676"))))
   (list "node_modules/saxes/LICENSE"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/lddubeau/saxes/6ef6a275b20f19cb67808daf0d8f64e06aaf5b0e/LICENSE")
           (file-name "persephil-saxes-5.0.1-LICENSE")
           (sha256
            (base32 "03hx0rzqj14zd886vl82bf9m570sf9bi0iahdcpb488671s27b0g"))))
   (list "node_modules/saxes/AUTHORS"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/lddubeau/saxes/6ef6a275b20f19cb67808daf0d8f64e06aaf5b0e/AUTHORS")
           (file-name "persephil-saxes-5.0.1-AUTHORS")
           (sha256
            (base32 "1k55w8mlfsg803zjxidzlx50a5wvk45cy6nwrgd8n2pds3hzx6sf"))))
   (list "node_modules/set-immediate-shim/LICENSE"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/sindresorhus/set-immediate-shim/4c50df7ade5a368e106fee82351ee0a378c990f7/license")
           (file-name "persephil-set-immediate-shim-1.0.1-LICENSE")
           (sha256
            (base32 "0k33p03ydnnfwvlrvqhnjgr62cp8j34yh1c8yr4nc3y22537bfbg"))))
   (list "node_modules/json-schema/LICENSE"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/kriszyp/json-schema/4f3db68fb98d9444850fec0ef5ed981c8beacfb6/LICENSE")
           (file-name "persephil-json-schema-0.2.3-LICENSE")
           (sha256
            (base32 "13lnjn2irjw16p9d29nlq492n37qxg54hpvl57g9fqqfyx3cjdwh"))))
   (list "node_modules/binary/LICENSE-MIT-TERMS"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/spdx/license-list-data/d46e94e2c78ceede1cfc63cfa0396472d2798d4c/text/MIT.txt")
           (file-name "persephil-binary-0.3.0-MIT-terms")
           (sha256
            (base32 "1dcjqlpj028h85q5nn92l91rjfsiahab291lnsx1crwfy7wqamxh"))))))
