;;; GNU Guix package for Blightmud.
;;;
;;; This module pins the v5.7.1 release and vendors every registry crate named
;;; in its reviewed Cargo.lock.  Keep the generated source declarations below
;;; in lockfile order: Cargo needs the complete graph even for features which
;;; are deliberately disabled by the package policy.

(define-module (tay packages blightmud)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control))

(define %blightmud-commit
  "653a83347c0bf40ccd4541c3c25892122f9dbc66")

;; Guix 1.5 exposes this package through the deprecated textutils alias,
;; whereas the channel-pinned Guix exports it from (gnu packages regex).
;; Resolve the preferred binding dynamically so merely enumerating this
;; channel remains compatible with both evaluators and avoids an alias warning
;; on current Guix.
(define %blightmud-oniguruma
  (let ((binding
         (or (module-variable (resolve-module '(gnu packages regex))
                              'oniguruma)
             (module-variable (resolve-module '(gnu packages textutils))
                              'oniguruma))))
    (if binding
        (variable-ref binding)
        (error "Guix does not provide an oniguruma package"))))

;; BEGIN LOCKFILE CRATE SOURCES
(define rust-addr2line-0.25.1
  (crate-source "addr2line" "0.25.1"
                "0jwb96gv17vdr29hbzi0ha5q6jkpgjyn7rjlg5nis65k41rk0p8v"))

(define rust-adler2-2.0.0
  (crate-source "adler2" "2.0.0"
                "09r6drylvgy8vv8k20lnbvwq8gp09h7smfn6h1rxsy15pgh629si"))

(define rust-aho-corasick-1.1.3
  (crate-source "aho-corasick" "1.1.3"
                "05mrpkvdgp5d20y2p989f187ry9diliijgwrs254fs9s1m1x6q4f"))

(define rust-aligned-0.4.3
  (crate-source "aligned" "0.4.3"
                "1186lhb3gb4x6spzw7ff0zcraa8cr9zqk4ldpm5g1vb2ijc0higf"))

(define rust-aligned-vec-0.6.4
  (crate-source "aligned-vec" "0.6.4"
                "16vnf78hvfix5cwzd5xs5a2g6afmgb4h7n6yfsc36bv0r22072fw"))

(define rust-alsa-0.11.0
  (crate-source "alsa" "0.11.0"
                "0pdx9k0766lfwnflia3vaxl89rfjc4v3riym5jl71mnwkq24fac1"))

(define rust-alsa-sys-0.4.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "alsa-sys" "0.4.0"
                "010yyg1wp3dijm6574s3m0r23azab1scxv7b0zvd6p96b846jxdd"))

(define rust-android-system-properties-0.1.5
  (crate-source "android_system_properties" "0.1.5"
                "04b3wrz12837j7mdczqd95b732gw5q7q66cv4yn4646lvccp57l1"))

(define rust-anstream-1.0.0
  (crate-source "anstream" "1.0.0"
                "13d2bj0xfg012s4rmq44zc8zgy1q8k9yp7yhvfnarscnmwpj2jl2"))

(define rust-anstyle-1.0.14
  (crate-source "anstyle" "1.0.14"
                "0030szmgj51fxkic1hpakxxgappxzwm6m154a3gfml83lq63l2wl"))

(define rust-anstyle-parse-1.0.0
  (crate-source "anstyle-parse" "1.0.0"
                "03hkv2690s0crssbnmfkr76kw1k7ah2i6s5amdy9yca2n8w7zkjj"))

(define rust-anstyle-query-1.1.3
  (crate-source "anstyle-query" "1.1.3"
                "1sgs2hq54wayrmpvy784ww2ccv9f8yhhpasv12z872bx0jvdx2vc"))

(define rust-anstyle-wincon-3.0.9
  (crate-source "anstyle-wincon" "3.0.9"
                "10n8mcgr89risdf35i73zc67aaa392bhggwzqlri1fv79297ags0"))

(define rust-anyhow-1.0.102
  (crate-source "anyhow" "1.0.102"
                "0b447dra1v12z474c6z4jmicdmc5yxz5bakympdnij44ckw2s83z"))

(define rust-arbitrary-1.4.2
  (crate-source "arbitrary" "1.4.2"
                "1wcbi4x7i3lzcrkjda4810nqv03lpmvfhb0a85xrq1mbqjikdl63"))

(define rust-arg-enum-proc-macro-0.3.4
  (crate-source "arg_enum_proc_macro" "0.3.4"
                "1sjdfd5a8j6r99cf0bpqrd6b160x9vz97y5rysycsjda358jms8a"))

(define rust-arrayref-0.3.9
  (crate-source "arrayref" "0.3.9"
                "1jzyp0nvp10dmahaq9a2rnxqdd5wxgbvp8xaibps3zai8c9fi8kn"))

(define rust-arrayvec-0.7.6
  (crate-source "arrayvec" "0.7.6"
                "0l1fz4ccgv6pm609rif37sl5nv5k6lbzi7kkppgzqzh1vwix20kw"))

(define rust-as-slice-0.2.1
  (crate-source "as-slice" "0.2.1"
                "05j52y1ws8kir5zjxnl48ann0if79sb56p9nm76hvma01r7nnssi"))

(define rust-autocfg-1.4.0
  (crate-source "autocfg" "1.4.0"
                "09lz3by90d2hphbq56znag9v87gfpd9gb8nr82hll8z6x2nhprdc"))

(define rust-av-scenechange-0.14.1
  (crate-source "av-scenechange" "0.14.1"
                "1543y7riwcy4mmsgcalxcm3bnb41hvwiqiz774nbj68fq9vischg"))

(define rust-av1-grain-0.2.5
  (crate-source "av1-grain" "0.2.5"
                "1y3p43i5xncbny0pfh8kw09am3l3mgyg82ln65r3f434443xpzcc"))

(define rust-avif-serialize-0.8.8
  (crate-source "avif-serialize" "0.8.8"
                "0gd5hr9vd2rkf9gn60f39rham6lzn8a4cdy0p57ihrxx0zq84l1p"))

(define rust-backtrace-0.3.76
  (crate-source "backtrace" "0.3.76"
                "1mibx75x4jf6wz7qjifynld3hpw3vq6sy3d3c9y5s88sg59ihlxv"))

(define rust-base64-0.22.1
  (crate-source "base64" "0.22.1"
                "1imqzgh7bxcikp5vx3shqvw9j09g9ly0xr0jma0q66i52r7jbcvj"))

(define rust-bincode-1.3.3
  (crate-source "bincode" "1.3.3"
                "1bfw3mnwzx5g1465kiqllp5n4r10qrqy88kdlp3jfwnq2ya5xx5i"))

(define rust-bindgen-0.61.0
  (crate-source "bindgen" "0.61.0"
                "16phlka8ykx28jlk7l637vlr9h01j8mh2s0d6km6z922l5c2w0la"))

(define rust-bindgen-0.71.1
  (crate-source "bindgen" "0.71.1"
                "1cynz43s9xwjbd1y03rx9h37xs0isyl8bi6g6yngp35nglyvyn2z"))

(define rust-bit-set-0.8.0
  (crate-source "bit-set" "0.8.0"
                "18riaa10s6n59n39vix0cr7l2dgwdhcpbcm97x1xbyfp1q47x008"))

(define rust-bit-vec-0.8.0
  (crate-source "bit-vec" "0.8.0"
                "1xxa1s2cj291r7k1whbxq840jxvmdsq9xgh7bvrxl46m80fllxjy"))

(define rust-bit-field-0.10.3
  (crate-source "bit_field" "0.10.3"
                "1ikhbph4ap4w692c33r8bbv6yd2qxm1q3f64845grp1s6b3l0jqy"))

(define rust-bitflags-1.3.2
  (crate-source "bitflags" "1.3.2"
                "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy"))

(define rust-bitflags-2.11.0
  (crate-source "bitflags" "2.11.0"
                "1bwjibwry5nfwsfm9kjg2dqx5n5nja9xymwbfl6svnn8jsz6ff44"))

(define rust-bitstream-io-4.9.0
  (crate-source "bitstream-io" "4.9.0"
                "0mqpwqy8cqnaqr4wkpk7qy7fjp4x6vxaf8z2hprbvimj3nfvvm30"))

(define rust-block-0.1.6
  (crate-source "block" "0.1.6"
                "16k9jgll25pzsq14f244q22cdv0zb4bqacldg3kx6h89d7piz30d"))

(define rust-block2-0.6.2
  (crate-source "block2" "0.6.2"
                "1xcfllzx6c3jc554nmb5qy6xmlkl6l6j5ib4wd11800n0n3rvsyd"))

(define rust-bstr-1.12.0
  (crate-source "bstr" "1.12.0"
                "195i0gd7r7jg7a8spkmw08492n7rmiabcvz880xn2z8dkp8i6h93"))

(define rust-built-0.8.0
  (crate-source "built" "0.8.0"
                "0r5f08lpjsr6j5ajkbmd0ymfmajpq8ddbfvi8ji8rx48y88qzbgl"))

(define rust-bumpalo-3.18.1
  (crate-source "bumpalo" "3.18.1"
                "1vmfniqr484l4ffkf0056g6hakncr7kdh11hyggh9kc7c5nvfgbr"))

(define rust-bytemuck-1.25.0
  (crate-source "bytemuck" "1.25.0"
                "1v1z32igg9zq49phb3fra0ax5r2inf3aw473vldnm886sx5vdvy8"))

(define rust-byteorder-lite-0.1.0
  (crate-source "byteorder-lite" "0.1.0"
                "15alafmz4b9az56z6x7glcbcb6a8bfgyd109qc3bvx07zx4fj7wg"))

(define rust-bytes-1.11.1
  (crate-source "bytes" "1.11.1"
                "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y"))

(define rust-cc-1.2.26
  (crate-source "cc" "1.2.26"
                "1b5g9ln7a2imwhrvfi77qbmj7gxsg0xihrlvarrg71wbk0hmwslm"))

(define rust-cesu8-1.1.0
  (crate-source "cesu8" "1.1.0"
                "0g6q58wa7khxrxcxgnqyi9s1z2cjywwwd3hzr5c55wskhx6s0hvd"))

(define rust-cexpr-0.6.0
  (crate-source "cexpr" "0.6.0"
                "0rl77bwhs5p979ih4r0202cn5jrfsrbgrksp40lkfz5vk1x3ib3g"))

(define rust-cfg-if-1.0.0
  (crate-source "cfg-if" "1.0.0"
                "1za0vb97n4brpzpv8lsbnzmq5r8f2b0cpqqr0sy8h5bn751xxwds"))

(define rust-cfg-aliases-0.2.1
  (crate-source "cfg_aliases" "0.2.1"
                "092pxdc1dbgjb6qvh83gk56rkic2n2ybm4yvy76cgynmzi3zwfk1"))

(define rust-chacha20-0.10.0
  (crate-source "chacha20" "0.10.0"
                "00bn2rn8l68qvlq93mhq7b4ns4zy9qbjsyjbb9kljgl4hqr9i3bg"))

(define rust-chrono-0.4.44
  (crate-source "chrono" "0.4.44"
                "1c64mk9a235271j5g3v4zrzqqmd43vp9vki7vqfllpqf5rd0fwy6"))

(define rust-clang-sys-1.8.1
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "clang-sys" "1.8.1"
                "1x1r9yqss76z8xwpdanw313ss6fniwc1r7dzb5ycjn0ph53kj0hb"))

(define rust-cocoa-foundation-0.1.2
  (crate-source "cocoa-foundation" "0.1.2"
                "1xwk1khdyqw3dwsl15vr8p86shdcn544fr60ass8biz4nb5k8qlc"))

(define rust-color-quant-1.1.0
  (crate-source "color_quant" "1.1.0"
                "12q1n427h2bbmmm1mnglr57jaz2dj9apk0plcxw7nwqiai7qjyrx"))

(define rust-colorchoice-1.0.4
  (crate-source "colorchoice" "1.0.4"
                "0x8ymkz1xr77rcj1cfanhf416pc4v681gmkc9dzb3jqja7f62nxh"))

(define rust-combine-4.6.7
  (crate-source "combine" "4.6.7"
                "1z8rh8wp59gf8k23ar010phgs0wgf5i8cx4fg01gwcnzfn5k0nms"))

(define rust-console-0.16.3
  (crate-source "console" "0.16.3"
                "11zwz1vnfr0nx6dyjx0gjymp8864y5hxwf01ynfd2s8kapsqlknn"))

(define rust-core-foundation-0.9.4
  (crate-source "core-foundation" "0.9.4"
                "13zvbbj07yk3b61b8fhwfzhy35535a583irf23vlcg59j7h9bqci"))

(define rust-core-foundation-sys-0.8.7
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "core-foundation-sys" "0.8.7"
                "12w8j73lazxmr1z0h98hf3z623kl8ms7g07jch7n4p8f9nwlhdkp"))

(define rust-core-graphics-types-0.1.3
  (crate-source "core-graphics-types" "0.1.3"
                "1bxg8nxc8fk4kxnqyanhf36wq0zrjr552c58qy6733zn2ihhwfa5"))

(define rust-core2-0.4.0
  (crate-source "core2" "0.4.0"
                "01f5xv0kf3ds3xm7byg78hycbanb8zlpvsfv4j47y46n3bpsg6xl"))

(define rust-core-maths-0.1.1
  (crate-source "core_maths" "0.1.1"
                "0c0dv11ixxpc9bsx5xasvl98mb1dlprzcm6qq6ls3nsygw0mwx3p"))

(define rust-coreaudio-rs-0.14.0
  (crate-source "coreaudio-rs" "0.14.0"
                "051rdxx1wfvc6fbf9xn7ppqz2ghbhjc3075dyww7j23wxqy3qp6i"))

(define rust-cpal-0.17.3
  (crate-source "cpal" "0.17.3"
                "1mq6lpmzfpnjs7gn8wv8qpnj951g7wk1dinasyaxiw60caijv56q"))

(define rust-cpufeatures-0.3.0
  (crate-source "cpufeatures" "0.3.0"
                "00fjhygsqmh4kbxxlb99mcsbspxcai6hjydv4c46pwb67wwl2alb"))

(define rust-crc32fast-1.4.2
  (crate-source "crc32fast" "1.4.2"
                "1czp7vif73b8xslr3c9yxysmh9ws2r8824qda7j47ffs9pcnjxx9"))

(define rust-crossbeam-deque-0.8.6
  (crate-source "crossbeam-deque" "0.8.6"
                "0l9f1saqp1gn5qy0rxvkmz4m6n7fc0b3dbm6q1r5pmgpnyvi3lcx"))

(define rust-crossbeam-epoch-0.9.18
  (crate-source "crossbeam-epoch" "0.9.18"
                "03j2np8llwf376m3fxqx859mgp9f83hj1w34153c7a9c7i5ar0jv"))

(define rust-crossbeam-utils-0.8.21
  (crate-source "crossbeam-utils" "0.8.21"
                "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh"))

(define rust-crunchy-0.2.4
  (crate-source "crunchy" "0.2.4"
                "1mbp5navim2qr3x48lyvadqblcxc1dm0lqr0swrkkwy2qblvw3s6"))

(define rust-dasp-sample-0.11.0
  (crate-source "dasp_sample" "0.11.0"
                "0zzw35akm3qs2rixbmlijk6h0l4g9ry6g74qc59zv1q8vs1f31qc"))

(define rust-data-url-0.3.2
  (crate-source "data-url" "0.3.2"
                "0xl30jidc8s3kh2z3nvnn1nyzhbq5b2wpiqwzj9gjdrndk50n7my"))

(define rust-deranged-0.5.5
  (crate-source "deranged" "0.5.5"
                "11z5939gv2klp1r1lgrp4w5fnlkj18jqqf0h9zxmia3vkrjwpv7c"))

(define rust-dispatch2-0.3.0
  (crate-source "dispatch2" "0.3.0"
                "1v1ak9w0s8z1g13x4mj2y5im9wmck0i2vf8f8wc9l1n6lqi9z849"))

(define rust-displaydoc-0.2.5
  (crate-source "displaydoc" "0.2.5"
                "1q0alair462j21iiqwrr21iabkfnb13d6x5w95lkdg21q2xrqdlp"))

(define rust-downcast-0.11.0
  (crate-source "downcast" "0.11.0"
                "1wa78ahlc57wmqyq2ncr80l7plrkgz57xsg7kfzgpcnqac8gld8l"))

(define rust-dyn-clonable-0.9.2
  (crate-source "dyn-clonable" "0.9.2"
                "01885xap4dmln3yspzyr0mmcwnm9mdhlp80ag0iig3nmpywznvm3"))

(define rust-dyn-clonable-impl-0.9.2
  (crate-source "dyn-clonable-impl" "0.9.2"
                "0fi1fy6r2zaq88n21yszlcdbm66iz3xi2dbgl8vrm5sq83ap31ky"))

(define rust-dyn-clone-1.0.19
  (crate-source "dyn-clone" "1.0.19"
                "01ahm5abl20480v48nxy4ffyx80cs6263q9zf0gnrxpvm6w8yyhw"))

(define rust-either-1.15.0
  (crate-source "either" "1.15.0"
                "069p1fknsmzn9llaizh77kip0pqmcwpdsykv2x30xpjyija5gis8"))

(define rust-encode-unicode-1.0.0
  (crate-source "encode_unicode" "1.0.0"
                "1h5j7j7byi289by63s3w4a8b3g6l5ccdrws7a67nn07vdxj77ail"))

(define rust-encoding-rs-0.8.35
  (crate-source "encoding_rs" "0.8.35"
                "1wv64xdrr9v37rqqdjsyb8l8wzlcbab80ryxhrszvnj59wy0y0vm"))

(define rust-env-filter-1.0.0
  (crate-source "env_filter" "1.0.0"
                "13rhwy5arjn626a0z3hvvkpf9w9pnll14c35vscyqx3jwp43q73s"))

(define rust-env-home-0.1.0
  (crate-source "env_home" "0.1.0"
                "1zn08mk95rjh97831rky1n944k024qrwjhbcgb0xv9zhrh94xy67"))

(define rust-env-logger-0.11.10
  (crate-source "env_logger" "0.11.10"
                "0smmk1hqzk7z91rg7fdq98d03gh9kidkd0ymim43zb4n457w0886"))

(define rust-equator-0.4.2
  (crate-source "equator" "0.4.2"
                "1z760z5r0haxjyakbqxvswrz9mq7c29arrivgq8y1zldhc9v44a7"))

(define rust-equator-macro-0.4.2
  (crate-source "equator-macro" "0.4.2"
                "1cqzx3cqn9rxln3a607xr54wippzff56zs5chqdf3z2bnks3rwj4"))

(define rust-equivalent-1.0.2
  (crate-source "equivalent" "1.0.2"
                "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"))

(define rust-errno-0.3.12
  (crate-source "errno" "0.3.12"
                "066ss2qln9z5q4816d3wcvq2bzasn7dajfkhcfqflfsy6pwlx8ff"))

(define rust-euclid-0.22.13
  (crate-source "euclid" "0.22.13"
                "0qzdj4xicyrsvd4cq6m5ndvfdrvvqrawy799qbaqhzw37r4byqfz"))

(define rust-exr-1.74.0
  (crate-source "exr" "1.74.0"
                "1gk3cc2qkfm0jqw4v1d7g4c356k9iz583bq17iiwp8kalm1y0023"))

(define rust-extended-0.1.0
  (crate-source "extended" "0.1.0"
                "0r830ak1a9775i9yl5lljm29zbnlncw7xlfz35mhgjrz43c775mg"))

(define rust-fancy-regex-0.16.2
  (crate-source "fancy-regex" "0.16.2"
                "0vy4c012f82xcg3gs068mq110zhsrnajh58fmq1jxr7vaijhb2wr"))

(define rust-fastrand-2.3.0
  (crate-source "fastrand" "2.3.0"
                "1ghiahsw1jd68df895cy5h3gzwk30hndidn3b682zmshpgmrx41p"))

(define rust-fax-0.2.6
  (crate-source "fax" "0.2.6"
                "1ax0jmvsszxd03hj6ga1kyl7gaqcfw0akg2wf0q6gk9pizaffpgh"))

(define rust-fax-derive-0.2.0
  (crate-source "fax_derive" "0.2.0"
                "0zap434zz4xvi5rnysmwzzivig593b4ng15vwzwl7js2nw7s3b50"))

(define rust-fdeflate-0.3.7
  (crate-source "fdeflate" "0.3.7"
                "130ga18vyxbb5idbgi07njymdaavvk6j08yh1dfarm294ssm6s0y"))

(define rust-filetime-0.2.25
  (crate-source "filetime" "0.2.25"
                "11l5zr86n5sr6g6k6sqldswk0jzklm0q95rzikxcns0yk0p55h1m"))

(define rust-flate2-1.1.9
  (crate-source "flate2" "1.1.9"
                "0g2pb7cxnzcbzrj8bw4v6gpqqp21aycmf6d84rzb6j748qkvlgw4"))

(define rust-float-cmp-0.9.0
  (crate-source "float-cmp" "0.9.0"
                "1i799ksbq7fj9rm9m82g1yqgm6xi3jnrmylddmqknmksajylpplq"))

(define rust-fnv-1.0.7
  (crate-source "fnv" "1.0.7"
                "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz"))

(define rust-foldhash-0.1.5
  (crate-source "foldhash" "0.1.5"
                "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r"))

(define rust-fontconfig-parser-0.5.8
  (crate-source "fontconfig-parser" "0.5.8"
                "0ijnbzg31sl6v49g7q2l7sl76hjj8z0hvlsz77cdvm029vi77ixv"))

(define rust-fontdb-0.23.0
  (crate-source "fontdb" "0.23.0"
                "0199vry9x8zn9ix4x4rqvv53dy2ryhy68l53jwr580hj7ndphzj5"))

(define rust-form-urlencoded-1.2.1
  (crate-source "form_urlencoded" "1.2.1"
                "0milh8x7nl4f450s3ddhg57a3flcv6yq8hlkyk6fyr3mcb128dp1"))

(define rust-fragile-2.0.1
  (crate-source "fragile" "2.0.1"
                "06g69s9w3hmdnjp5b60ph15v367278mgxy1shijrllarc2pnrp98"))

(define rust-fsevent-sys-4.1.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "fsevent-sys" "4.1.0"
                "1liz67v8b0gcs8r31vxkvm2jzgl9p14i78yfqx81c8sdv817mvkn"))

(define rust-futures-channel-0.3.31
  (crate-source "futures-channel" "0.3.31"
                "040vpqpqlbk099razq8lyn74m0f161zd0rp36hciqrwcg2zibzrd"))

(define rust-futures-core-0.3.31
  (crate-source "futures-core" "0.3.31"
                "0gk6yrxgi5ihfanm2y431jadrll00n5ifhnpx090c2f2q1cr1wh5"))

(define rust-futures-io-0.3.31
  (crate-source "futures-io" "0.3.31"
                "1ikmw1yfbgvsychmsihdkwa8a1knank2d9a8dk01mbjar9w1np4y"))

(define rust-futures-sink-0.3.31
  (crate-source "futures-sink" "0.3.31"
                "1xyly6naq6aqm52d5rh236snm08kw8zadydwqz8bip70s6vzlxg5"))

(define rust-futures-task-0.3.31
  (crate-source "futures-task" "0.3.31"
                "124rv4n90f5xwfsm9qw6y99755y021cmi5dhzh253s920z77s3zr"))

(define rust-futures-util-0.3.31
  (crate-source "futures-util" "0.3.31"
                "10aa1ar8bgkgbr4wzxlidkqkcxf77gffyj8j7768h831pcaq784z"))

(define rust-gethostname-1.1.0
  (crate-source "gethostname" "1.1.0"
                "1n6bj9gh503ggjblfjcai96gmxynxsrykaynljlrfdra34q95m0v"))

(define rust-getopts-0.2.24
  (crate-source "getopts" "0.2.24"
                "1pylvsmq7fillnxmd6g58r7igdrlby412q37ws41z39va2ngpr6g"))

(define rust-getrandom-0.2.16
  (crate-source "getrandom" "0.2.16"
                "14l5aaia20cc6cc08xdlhrzmfcylmrnprwnna20lqf746pqzjprk"))

(define rust-getrandom-0.3.3
  (crate-source "getrandom" "0.3.3"
                "1x6jl875zp6b2b6qp9ghc84b0l76bvng2lvm8zfcmwjl7rb5w516"))

(define rust-getrandom-0.4.1
  (crate-source "getrandom" "0.4.1"
                "1v7fm84f2jh6x7w3bd2ncl3sw29wnb0rhg7xya1pd30i02cg77hk"))

(define rust-gif-0.14.1
  (crate-source "gif" "0.14.1"
                "0pn3ldqjk0ng1vbc3r3zqqrnjkn6s3f3ndk96lhhrn0q82l2ppzm"))

(define rust-gimli-0.32.3
  (crate-source "gimli" "0.32.3"
                "1iqk5xznimn5bfa8jy4h7pa1dv3c624hzgd2dkz8mpgkiswvjag6"))

(define rust-git2-0.21.0
  (crate-source "git2" "0.21.0"
                "0bmqga9vlyx5sdlr0i28z0362s89xv9i4qcv20vvx9j54y9vzpfx"))

(define rust-glob-0.3.3
  (crate-source "glob" "0.3.3"
                "106jpd3syfzjfj2k70mwm0v436qbx96wig98m4q8x071yrq35hhc"))

(define rust-half-2.7.1
  (crate-source "half" "2.7.1"
                "0jyq42xfa6sghc397mx84av7fayd4xfxr4jahsqv90lmjr5xi8kf"))

(define rust-hashbrown-0.15.4
  (crate-source "hashbrown" "0.15.4"
                "1mg045sm1nm00cwjm7ndi80hcmmv1v3z7gnapxyhd9qxc62sqwar"))

(define rust-heck-0.5.0
  (crate-source "heck" "0.5.0"
                "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113"))

(define rust-home-0.5.11
  (crate-source "home" "0.5.11"
                "1kxb4k87a9sayr8jipr7nq9wpgmjk4hk4047hmf9kc24692k75aq"))

(define rust-http-1.3.1
  (crate-source "http" "1.3.1"
                "0r95i5h7dr1xadp1ac9453w0s62s27hzkam356nyx2d9mqqmva7l"))

(define rust-http-body-1.0.1
  (crate-source "http-body" "1.0.1"
                "111ir5k2b9ihz5nr9cz7cwm7fnydca7dx4hc7vr16scfzghxrzhy"))

(define rust-http-body-util-0.1.3
  (crate-source "http-body-util" "0.1.3"
                "0jm6jv4gxsnlsi1kzdyffjrj8cfr3zninnxpw73mvkxy4qzdj8dh"))

(define rust-httparse-1.10.1
  (crate-source "httparse" "1.10.1"
                "11ycd554bw2dkgw0q61xsa7a4jn1wb1xbfacmf3dbwsikvkkvgvd"))

(define rust-human-panic-2.0.8
  (crate-source "human-panic" "2.0.8"
                "0gfcr5s89gl08z5ppiq8ivj25f2h1qyhp5jkjw56wg3p9465v0g2"))

(define rust-hunspell-rs-0.4.0
  (crate-source "hunspell-rs" "0.4.0"
                "09zbazhsqrri12bg9idggz7bhvwbs0fnrrcs0cszmfb0jygy4b66"))

(define rust-hunspell-sys-0.3.1
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "hunspell-sys" "0.3.1"
                "1v3x1gicafv2jlq1vr9hf9vgsxaiinflzni0bizcnyp4ji9n0a4j"))

(define rust-hyper-1.6.0
  (crate-source "hyper" "1.6.0"
                "103ggny2k31z0iq2gzwk2vbx601wx6xkpjpxn40hr3p3b0b5fayc"))

(define rust-hyper-rustls-0.27.7
  (crate-source "hyper-rustls" "0.27.7"
                "0n6g8998szbzhnvcs1b7ibn745grxiqmlpg53xz206v826v3xjg3"))

(define rust-hyper-util-0.1.14
  (crate-source "hyper-util" "0.1.14"
                "1nqvf5azmv8p7hs5ghjlbgfya7xaafq377vppdazxbq8zzdxybyw"))

(define rust-iana-time-zone-0.1.63
  (crate-source "iana-time-zone" "0.1.63"
                "1n171f5lbc7bryzmp1h30zw86zbvl5480aq02z92lcdwvvjikjdh"))

(define rust-iana-time-zone-haiku-0.1.2
  (crate-source "iana-time-zone-haiku" "0.1.2"
                "17r6jmj31chn7xs9698r122mapq85mfnv98bb4pg6spm0si2f67k"))

(define rust-icu-collections-2.0.0
  (crate-source "icu_collections" "2.0.0"
                "0izfgypv1hsxlz1h8fc2aak641iyvkak16aaz5b4aqg3s3sp4010"))

(define rust-icu-locale-core-2.0.0
  (crate-source "icu_locale_core" "2.0.0"
                "02phv7vwhyx6vmaqgwkh2p4kc2kciykv2px6g4h8glxfrh02gphc"))

(define rust-icu-normalizer-2.0.0
  (crate-source "icu_normalizer" "2.0.0"
                "0ybrnfnxx4sf09gsrxri8p48qifn54il6n3dq2xxgx4dw7l80s23"))

(define rust-icu-normalizer-data-2.0.0
  (crate-source "icu_normalizer_data" "2.0.0"
                "1lvjpzxndyhhjyzd1f6vi961gvzhj244nribfpdqxjdgjdl0s880"))

(define rust-icu-properties-2.0.1
  (crate-source "icu_properties" "2.0.1"
                "0az349pjg8f18lrjbdmxcpg676a7iz2ibc09d2wfz57b3sf62v01"))

(define rust-icu-properties-data-2.0.1
  (crate-source "icu_properties_data" "2.0.1"
                "0cnn3fkq6k88w7p86w7hsd1254s4sl783rpz4p6hlccq74a5k119"))

(define rust-icu-provider-2.0.0
  (crate-source "icu_provider" "2.0.0"
                "1bz5v02gxv1i06yhdhs2kbwxkw3ny9r2vvj9j288fhazgfi0vj03"))

(define rust-id-arena-2.3.0
  (crate-source "id-arena" "2.3.0"
                "0m6rs0jcaj4mg33gkv98d71w3hridghp5c4yr928hplpkgbnfc1x"))

(define rust-idna-1.0.3
  (crate-source "idna" "1.0.3"
                "0zlajvm2k3wy0ay8plr07w22hxkkmrxkffa6ah57ac6nci984vv8"))

(define rust-idna-adapter-1.2.1
  (crate-source "idna_adapter" "1.2.1"
                "0i0339pxig6mv786nkqcxnwqa87v4m94b2653f6k3aj0jmhfkjis"))

(define rust-image-0.25.10
  (crate-source "image" "0.25.10"
                "0131b9fsd5grxf3lchfs2ci0rg8ga2mh1ygai7k2zh1k8cwq1aw5"))

(define rust-image-webp-0.2.4
  (crate-source "image-webp" "0.2.4"
                "1hz814csyi9283vinzlkix6qpnd6hs3fkw7xl6z2zgm4w7rrypjj"))

(define rust-imagesize-0.14.0
  (crate-source "imagesize" "0.14.0"
                "1725g398w4v35qrv9s3gl8gl5cqj5cwkamn7mvvl12y4niblxr89"))

(define rust-imgref-1.12.0
  (crate-source "imgref" "1.12.0"
                "1j3iwdal9mdkmyrsms3lz4n1bxxxjxss2jvbmh662fns63fcxig7"))

(define rust-indexmap-2.9.0
  (crate-source "indexmap" "2.9.0"
                "07m15a571yywmvqyb7ms717q9n42b46badbpsmx215jrg7dhv9yf"))

(define rust-inotify-0.11.0
  (crate-source "inotify" "0.11.0"
                "1wq8m657rl085cg59p38sc5y62xy9yhhpvxbkd7n1awi4zzwqzgk"))

(define rust-inotify-sys-0.1.5
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "inotify-sys" "0.1.5"
                "1syhjgvkram88my04kv03s0zwa66mdwa5v7ddja3pzwvx2sh4p70"))

(define rust-insta-1.47.2
  (crate-source "insta" "1.47.2"
                "0kh9gspras3vhvx8wkygnw2wzlwjln7gwzgks8g4194kxd464jkv"))

(define rust-interpolate-name-0.2.4
  (crate-source "interpolate_name" "0.2.4"
                "0q7s5mrfkx4p56dl8q9zq71y1ysdj4shh6f28qf9gly35l21jj63"))

(define rust-ipnet-2.11.0
  (crate-source "ipnet" "2.11.0"
                "0c5i9sfi2asai28m8xp48k5gvwkqrg5ffpi767py6mzsrswv17s6"))

(define rust-iri-string-0.7.8
  (crate-source "iri-string" "0.7.8"
                "1cl0wfq97wq4s1p4dl0ix5cfgsc5fn7l22ljgw9ab9x1qglypifv"))

(define rust-is-terminal-polyfill-1.70.1
  (crate-source "is_terminal_polyfill" "1.70.1"
                "1kwfgglh91z33kl0w5i338mfpa3zs0hidq5j4ny4rmjwrikchhvr"))

(define rust-itertools-0.13.0
  (crate-source "itertools" "0.13.0"
                "11hiy3qzl643zcigknclh446qb9zlg4dpdzfkjaa9q9fqpgyfgj1"))

(define rust-itertools-0.14.0
  (crate-source "itertools" "0.14.0"
                "118j6l1vs2mx65dqhwyssbrxpawa90886m3mzafdvyip41w2q69b"))

(define rust-itoa-1.0.15
  (crate-source "itoa" "1.0.15"
                "0b4fj9kz54dr3wam0vprjwgygvycyw8r0qwg7vp19ly8b2w16psa"))

(define rust-jiff-0.2.23
  (crate-source "jiff" "0.2.23"
                "0nc37n7jvgrzxdkcgc2hsfdf70lfagigjalh4igjrm5njvf4cd8s"))

(define rust-jiff-static-0.2.23
  (crate-source "jiff-static" "0.2.23"
                "192ss3cnixvg79cpa76clwkhn4mmz10vnwsbf7yjw8i484s8p31a"))

(define rust-jni-0.21.1
  (crate-source "jni" "0.21.1"
                "15wczfkr2r45slsljby12ymf2hij8wi5b104ghck9byjnwmsm1qs"))

(define rust-jni-sys-0.3.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "jni-sys" "0.3.0"
                "0c01zb9ygvwg9wdx2fii2d39myzprnpqqhy7yizxvjqp5p04pbwf"))

(define rust-jobserver-0.1.33
  (crate-source "jobserver" "0.1.33"
                "12jkn3cxvfs7jsb6knmh9y2b41lwmrk3vdqywkmssx61jzq65wiq"))

(define rust-js-sys-0.3.77
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "js-sys" "0.3.77"
                "13x2qcky5l22z4xgivi59xhjjx4kxir1zg7gcj0f1ijzd4yg7yhw"))

(define rust-kqueue-1.1.1
  (crate-source "kqueue" "1.1.1"
                "0sjrsnza8zxr1zfpv6sa0zapd54kx9wlijrz9apqvs6wsw303hza"))

(define rust-kqueue-sys-1.0.4
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "kqueue-sys" "1.0.4"
                "12w3wi90y4kwis4k9g6fp0kqjdmc6l00j16g8mgbhac7vbzjb5pd"))

(define rust-kurbo-0.13.0
  (crate-source "kurbo" "0.13.0"
                "1yrvgfqzi68wnshacgr1v6hfmahvn8i57j8b3wg7gmf0wc7yjr3m"))

(define rust-lazy-static-1.5.0
  (crate-source "lazy_static" "1.5.0"
                "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"))

(define rust-lazycell-1.3.0
  (crate-source "lazycell" "1.3.0"
                "0m8gw7dn30i0zjjpjdyf6pc16c34nl71lpv461mix50x3p70h3c3"))

(define rust-leb128fmt-0.1.0
  (crate-source "leb128fmt" "0.1.0"
                "1chxm1484a0bly6anh6bd7a99sn355ymlagnwj3yajafnpldkv89"))

(define rust-lebe-0.5.3
  (crate-source "lebe" "0.5.3"
                "1f459clndzzm35nyd15vj5dlasyagfasp7hcgl6lh2b658rs6ybs"))

(define rust-libc-0.2.183
  (crate-source "libc" "0.2.183"
                "17c9gyia7rrzf9gsssvk3vq9ca2jp6rh32fsw6ciarpn5djlddmm"))

(define rust-libfuzzer-sys-0.4.12
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "libfuzzer-sys" "0.4.12"
                "13ghagfsynmqda1pkpalila6kf0llqxh3214ynzi5knqgldnhapi"))

(define rust-libgit2-sys-0.18.4+1.9.3
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "libgit2-sys" "0.18.4+1.9.3"
                "1dqmkgxgxb937kkcsf05r93a9li385b92wfgxwi1p1z16mpzc9lv"))

(define rust-libloading-0.8.8
  (crate-source "libloading" "0.8.8"
                "0rw6q94psj3d6k0bi9nymqhyrz78lbdblryphhaszsw9p9ikj0q7"))

(define rust-libm-0.2.16
  (crate-source "libm" "0.2.16"
                "10brh0a3qjmbzkr5mf5xqi887nhs5y9layvnki89ykz9xb1wxlmn"))

(define rust-libmudtelnet-2.0.2
  (crate-source "libmudtelnet" "2.0.2"
                "0zgaagzz2hjyh820v21zsjzcfyd6yavyc1y3hxj026739fmv22m1"))

(define rust-libredox-0.1.3
  (crate-source "libredox" "0.1.3"
                "139602gzgs0k91zb7dvgj1qh4ynb8g1lbxsswdim18hcb6ykgzy0"))

(define rust-libz-sys-1.1.22
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "libz-sys" "1.1.22"
                "07b5wxh0ska996kc0g2hanjhmb4di7ksm6ndljhr4pi0vykyfw4b"))

(define rust-linked-hash-map-0.5.6
  (crate-source "linked-hash-map" "0.5.6"
                "03vpgw7x507g524nx5i1jf5dl8k3kv0fzg8v3ip6qqwbpkqww5q7"))

(define rust-linux-raw-sys-0.4.15
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "linux-raw-sys" "0.4.15"
                "1aq7r2g7786hyxhv40spzf2nhag5xbw2axxc1k8z5k1dsgdm4v6j"))

(define rust-linux-raw-sys-0.12.1
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "linux-raw-sys" "0.12.1"
                "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij"))

(define rust-litemap-0.8.0
  (crate-source "litemap" "0.8.0"
                "0mlrlskwwhirxk3wsz9psh6nxcy491n0dh8zl02qgj0jzpssw7i4"))

(define rust-lock-api-0.4.13
  (crate-source "lock_api" "0.4.13"
                "0rd73p4299mjwl4hhlfj9qr88v3r0kc8s1nszkfmnq2ky43nb4wn"))

(define rust-log-0.4.30
  (crate-source "log" "0.4.30"
                "1rd6sw3gv9hb93464w7x3sip99zf8sjagm662r2ckg14b1lcavk1"))

(define rust-loop9-0.1.5
  (crate-source "loop9" "0.1.5"
                "0qphc1c0cbbx43pwm6isnwzwbg6nsxjh7jah04n1sg5h4p0qgbhg"))

(define rust-lru-slab-0.1.2
  (crate-source "lru-slab" "0.1.2"
                "0m2139k466qj3bnpk66bwivgcx3z88qkxvlzk70vd65jq373jaqi"))

(define rust-lua-src-550.0.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "lua-src" "550.0.0"
                "1yx40j02a0835z2q95iz7r1n7l97va43l022ryywj1k8w65dqdp8"))

(define rust-luajit-src-210.6.1+f9140a6
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "luajit-src" "210.6.1+f9140a6"
                "1gslc1s1shq8fhcsn448i47cpxjwxg2xkh47lvzkli2r4wgx6fw1"))

(define rust-mach2-0.5.0
  (crate-source "mach2" "0.5.0"
                "1siskhk6qhhzw40k1gc23zg6irx0bqpi1bmm8ns5bv11ak6ra6va"))

(define rust-malloc-buf-0.0.6
  (crate-source "malloc_buf" "0.0.6"
                "1jqr77j89pwszv51fmnknzvd53i1nkmcr8rjrvcxhm4dx1zr1fv2"))

(define rust-maybe-rayon-0.1.1
  (crate-source "maybe-rayon" "0.1.1"
                "06cmvhj4n36459g327ng5dnj8d58qs472pv5ahlhm7ynxl6g78cf"))

(define rust-memchr-2.7.4
  (crate-source "memchr" "2.7.4"
                "18z32bhxrax0fnjikv475z7ii718hq457qwmaryixfxsl2qrmjkq"))

(define rust-memmap2-0.9.10
  (crate-source "memmap2" "0.9.10"
                "1qz0n4ch68pz2mp07sdwnk27imdjjqy6aqir3hp9j4g0iw19hh3i"))

(define rust-mime-0.3.17
  (crate-source "mime" "0.3.17"
                "16hkibgvb9klh0w0jk5crr5xv90l3wlf77ggymzjmvl1818vnxv8"))

(define rust-minimal-lexical-0.2.1
  (crate-source "minimal-lexical" "0.2.1"
                "16ppc5g84aijpri4jzv14rvcnslvlpphbszc7zzp6vfkddf4qdb8"))

(define rust-miniz-oxide-0.8.8
  (crate-source "miniz_oxide" "0.8.8"
                "0al9iy33flfgxawj789w2c8xxwg1n2r5vv6m6p5hl2fvd2vlgriv"))

(define rust-mio-1.2.0
  (crate-source "mio" "1.2.0"
                "1hanrh4fwsfkdqdaqfidz48zz1wdix23zwn3r2x78am0garfbdsh"))

(define rust-mlua-0.11.6
  (crate-source "mlua" "0.11.6"
                "1avghh274kzbcz6y9rjpwzp69i82scfhcyihs5bfxrlwlk7nmlyc"))

(define rust-mlua-sys-0.10.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "mlua-sys" "0.10.0"
                "1j6zqgr8agiv21gfqflxnjr9xcx35ym91za9wbn2f0jqqxzkl70g"))

(define rust-mlua-derive-0.11.0
  (crate-source "mlua_derive" "0.11.0"
                "1cnfvd2pbiwj56xc0zggld7jhjqxgklm0cjl1fsv6kjca7gdsns6"))

(define rust-mockall-0.14.0
  (crate-source "mockall" "0.14.0"
                "02v2gfdz5s927hqsz9qh6lchhiyh5wvyb6077nvcdyd5k109d3gm"))

(define rust-mockall-derive-0.14.0
  (crate-source "mockall_derive" "0.14.0"
                "1gvddfzazipxi8mcn0iqrljzqq2jxrwam1dki3hrnsnsdmqwwhfa"))

(define rust-mockall-double-0.3.1
  (crate-source "mockall_double" "0.3.1"
                "1s0k85929bf8afvdgq8m2vs8haqpkg9ysdimw7inl99mmkjrdjpi"))

(define rust-moxcms-0.8.1
  (crate-source "moxcms" "0.8.1"
                "0jz4fd5f7pdn1rngqc96lxriqjkym1lswdhdbjr037s8p9ac31dv"))

(define rust-ndk-0.9.0
  (crate-source "ndk" "0.9.0"
                "1m32zpmi5w1pf3j47k6k5fw395dc7aj8d0mdpsv53lqkprxjxx63"))

(define rust-ndk-context-0.1.1
  (crate-source "ndk-context" "0.1.1"
                "12sai3dqsblsvfd1l1zab0z6xsnlha3xsfl7kagdnmj3an3jvc17"))

(define rust-ndk-sys-0.6.0+11769913
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "ndk-sys" "0.6.0+11769913"
                "0wx8r6pji20if4xs04g73gxl98nmjrfc73z0v6w1ypv6a4qdlv7f"))

(define rust-new-debug-unreachable-1.0.6
  (crate-source "new_debug_unreachable" "1.0.6"
                "11phpf1mjxq6khk91yzcbd3ympm78m3ivl7xg6lg2c0lf66fy3k5"))

(define rust-nom-7.1.3
  (crate-source "nom" "7.1.3"
                "0jha9901wxam390jcf5pfa0qqfrgh8li787jx2ip0yk5b8y9hwyj"))

(define rust-nom-8.0.0
  (crate-source "nom" "8.0.0"
                "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz"))

(define rust-noop-proc-macro-0.3.0
  (crate-source "noop_proc_macro" "0.3.0"
                "1j2v1c6ric4w9v12h34jghzmngcwmn0hll1ywly4h6lcm4rbnxh6"))

(define rust-notify-8.0.0
  (crate-source "notify" "8.0.0"
                "0hz9ab68gsbkidms6kgl4v7capfqjyl40vpfdarcfsnnnc1q9vig"))

(define rust-notify-debouncer-mini-0.6.0
  (crate-source "notify-debouncer-mini" "0.6.0"
                "1f6cdmqxfmzcxwjfs0xbh9k73sl37387q27r4wbrlk8qc91fp2d6"))

(define rust-notify-types-2.0.0
  (crate-source "notify-types" "2.0.0"
                "0pcjm3wnvb7pvzw6mn89csv64ip0xhx857kr8jic5vddi6ljc22y"))

(define rust-ntapi-0.4.2
  (crate-source "ntapi" "0.4.2"
                "10ghcc1kmj5ygy4ls81as6s5akd1wflwcc0b1k3nf8ql46g223y7"))

(define rust-num-bigint-0.4.6
  (crate-source "num-bigint" "0.4.6"
                "1f903zd33i6hkjpsgwhqwi2wffnvkxbn6rv4mkgcjcqi7xr4zr55"))

(define rust-num-conv-0.2.0
  (crate-source "num-conv" "0.2.0"
                "0l4hj7lp8zbb9am4j3p7vlcv47y9bbazinvnxx9zjhiwkibyr5yg"))

(define rust-num-derive-0.4.2
  (crate-source "num-derive" "0.4.2"
                "00p2am9ma8jgd2v6xpsz621wc7wbn1yqi71g15gc3h67m7qmafgd"))

(define rust-num-integer-0.1.46
  (crate-source "num-integer" "0.1.46"
                "13w5g54a9184cqlbsq80rnxw4jj4s0d8wv75jsq5r2lms8gncsbr"))

(define rust-num-rational-0.4.2
  (crate-source "num-rational" "0.4.2"
                "093qndy02817vpgcqjnj139im3jl7vkq4h68kykdqqh577d18ggq"))

(define rust-num-traits-0.2.19
  (crate-source "num-traits" "0.2.19"
                "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787"))

(define rust-num-enum-0.7.3
  (crate-source "num_enum" "0.7.3"
                "0yai0vafhy85mvhknzfqd7lm04hzaln7i5c599rhy8mj831kyqaf"))

(define rust-num-enum-derive-0.7.3
  (crate-source "num_enum_derive" "0.7.3"
                "0mksna1jj87ydh146gn6jcqkvvs920c3dgh0p4f3xk184kpl865g"))

(define rust-numtoa-0.2.4
  (crate-source "numtoa" "0.2.4"
                "03yhkhjb3d1zx22m3pgcbpk8baj0zzvaxqc25c584sdq77jw98ka"))

(define rust-objc-0.2.7
  (crate-source "objc" "0.2.7"
                "1cbpf6kz8a244nn1qzl3xyhmp05gsg4n313c9m3567625d3innwi"))

(define rust-objc2-0.6.2
  (crate-source "objc2" "0.6.2"
                "1g3qa1vxp6nlh4wllll921z299d3s1is31m1ccasd8pklxxka7sn"))

(define rust-objc2-audio-toolbox-0.3.1
  (crate-source "objc2-audio-toolbox" "0.3.1"
                "01sckqqz6hi8r8zg5lv3xdaj5xdw73zbxy24lnpa884yhy6y3jqh"))

(define rust-objc2-avf-audio-0.3.1
  (crate-source "objc2-avf-audio" "0.3.1"
                "0479ihc5kd31k2fr8gvbdksl3nhrcy0gqfbpw7msf4f244ax3hdz"))

(define rust-objc2-core-audio-0.3.1
  (crate-source "objc2-core-audio" "0.3.1"
                "10jw08xrzd68fik0b1dl5g1b7xp3fdq4j8wgh0xk26cfi0g9ci6a"))

(define rust-objc2-core-audio-types-0.3.1
  (crate-source "objc2-core-audio-types" "0.3.1"
                "1qbfcvf4zm0wh15vjgkb0fxp2lm1nqyzip97cpdjvb87pfcwrwf0"))

(define rust-objc2-core-foundation-0.3.2
  (crate-source "objc2-core-foundation" "0.3.2"
                "0dnmg7606n4zifyjw4ff554xvjmi256cs8fpgpdmr91gckc0s61a"))

(define rust-objc2-encode-4.1.0
  (crate-source "objc2-encode" "4.1.0"
                "0cqckp4cpf68mxyc2zgnazj8klv0z395nsgbafa61cjgsyyan9gg"))

(define rust-objc2-foundation-0.3.1
  (crate-source "objc2-foundation" "0.3.1"
                "0g5hl47dxzabs7wndcg6kz3q137v9hwfay1jd2da1q9gglj3224h"))

(define rust-objc2-io-kit-0.3.2
  (crate-source "objc2-io-kit" "0.3.2"
                "05dvfcf97w39daaj5qsbfc399lw9hbx3s4h9nwgxrmlpjnizpyik"))

(define rust-objc-exception-0.1.2
  (crate-source "objc_exception" "0.1.2"
                "191cmdmlypp6piw67y4m8y5swlxf5w0ss8n1lk5xd2l1ans0z5xd"))

(define rust-object-0.37.3
  (crate-source "object" "0.37.3"
                "1zikiy9xhk6lfx1dn2gn2pxbnfpmlkn0byd7ib1n720x0cgj0xpz"))

(define rust-once-cell-1.21.3
  (crate-source "once_cell" "1.21.3"
                "0b9x77lb9f1j6nqgf5aka4s2qj0nly176bpbrv6f9iakk5ff3xa2"))

(define rust-once-cell-polyfill-1.70.1
  (crate-source "once_cell_polyfill" "1.70.1"
                "1bg0w99srq8h4mkl68l1mza2n2f2hvrg0n8vfa3izjr5nism32d4"))

(define rust-onig-6.5.1
  (crate-source "onig" "6.5.1"
                "1w63vbzamn2v9jpnlj3wkglapqss0fcvhhd8pqafzkis8iirqsrk"))

(define rust-onig-sys-69.9.1
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "onig_sys" "69.9.1"
                "1p17cxzqnpqzpzamh7aqwpagxlnbhzs6myxw4dgz2v9xxxp6ry67"))

(define rust-oxilangtag-0.1.5
  (crate-source "oxilangtag" "0.1.5"
                "1jwa1z5223hkfldjdwfrxb158w9y918667k9ldzzfsm82xvgiwr3"))

(define rust-parking-lot-0.12.4
  (crate-source "parking_lot" "0.12.4"
                "04sab1c7304jg8k0d5b2pxbj1fvgzcf69l3n2mfpkdb96vs8pmbh"))

(define rust-parking-lot-core-0.9.11
  (crate-source "parking_lot_core" "0.9.11"
                "19g4d6m5k4ggacinqprnn8xvdaszc3y5smsmbz1adcdmaqm8v0xw"))

(define rust-paste-1.0.15
  (crate-source "paste" "1.0.15"
                "02pxffpdqkapy292harq6asfjvadgp1s005fip9ljfsn9fvxgh2p"))

(define rust-pastey-0.1.1
  (crate-source "pastey" "0.1.1"
                "1v389jkifv757903flrrps67dvc6q6giwlyx3xi33hcfjmgjxyrm"))

(define rust-peeking-take-while-0.1.2
  (crate-source "peeking_take_while" "0.1.2"
                "16bhqr6rdyrp12zv381cxaaqqd0pwysvm1q8h2ygihvypvfprc8r"))

(define rust-percent-encoding-2.3.1
  (crate-source "percent-encoding" "2.3.1"
                "0gi8wgx0dcy8rnv1kywdv98lwcx67hz0a0zwpib5v2i08r88y573"))

(define rust-pico-args-0.5.0
  (crate-source "pico-args" "0.5.0"
                "05d30pvxd6zlnkg2i3ilr5a70v3f3z2in18m67z25vinmykngqav"))

(define rust-pin-project-lite-0.2.16
  (crate-source "pin-project-lite" "0.2.16"
                "16wzc7z7dfkf9bmjin22f5282783f6mdksnr0nv0j5ym5f9gyg1v"))

(define rust-pin-utils-0.1.0
  (crate-source "pin-utils" "0.1.0"
                "117ir7vslsl2z1a7qzhws4pd01cg2d3338c47swjyvqv2n60v1wb"))

(define rust-pkg-config-0.3.32
  (crate-source "pkg-config" "0.3.32"
                "0k4h3gnzs94sjb2ix6jyksacs52cf1fanpwsmlhjnwrdnp8dppby"))

(define rust-plist-1.7.1
  (crate-source "plist" "1.7.1"
                "07a5s06q03n7s9xsw39nsn0mabr0wc9w2hzf18zfb9h33jc6xhpa"))

(define rust-png-0.18.1
  (crate-source "png" "0.18.1"
                "0qca282xp8a6d7mikxrwji3f52mjn4vnqxz2v9iz5adj665rnxk0"))

(define rust-portable-atomic-1.11.1
  (crate-source "portable-atomic" "1.11.1"
                "10s4cx9y3jvw0idip09ar52s2kymq8rq9a668f793shn1ar6fhpq"))

(define rust-portable-atomic-util-0.2.4
  (crate-source "portable-atomic-util" "0.2.4"
                "01rmx1li07ixsx3sqg2bxqrkzk7b5n8pibwwf2589ms0s3cg18nq"))

(define rust-potential-utf-0.1.2
  (crate-source "potential_utf" "0.1.2"
                "11dm6k3krx3drbvhgjw8z508giiv0m09wzl6ghza37176w4c79z5"))

(define rust-powerfmt-0.2.0
  (crate-source "powerfmt" "0.2.0"
                "14ckj2xdpkhv3h6l5sdmb9f1d57z8hbfpdldjc2vl5givq2y77j3"))

(define rust-ppv-lite86-0.2.21
  (crate-source "ppv-lite86" "0.2.21"
                "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5"))

(define rust-predicates-3.1.3
  (crate-source "predicates" "3.1.3"
                "0wrm57acvagx0xmh5xffx5xspsr2kbggm698x0vks132fpjrxld5"))

(define rust-predicates-core-1.0.9
  (crate-source "predicates-core" "1.0.9"
                "1yjz144yn3imq2r4mh7k9h0r8wv4yyjjj57bs0zwkscz24mlczkj"))

(define rust-predicates-tree-1.0.12
  (crate-source "predicates-tree" "1.0.12"
                "0p223d9y02ywwxs3yl68kziswz4da4vabz67jfhp7yqx71njvpbj"))

(define rust-prettyplease-0.2.33
  (crate-source "prettyplease" "0.2.33"
                "0zba9hcp50rg52j4134px0pwkx9i9zjnbp9ylv3cbx232d993vlx"))

(define rust-proc-macro-crate-3.3.0
  (crate-source "proc-macro-crate" "3.3.0"
                "0d9xlymplfi9yv3f5g4bp0d6qh70apnihvqcjllampx4f5lmikpd"))

(define rust-proc-macro-error-attr2-2.0.0
  (crate-source "proc-macro-error-attr2" "2.0.0"
                "1ifzi763l7swl258d8ar4wbpxj4c9c2im7zy89avm6xv6vgl5pln"))

(define rust-proc-macro-error2-2.0.1
  (crate-source "proc-macro-error2" "2.0.1"
                "00lq21vgh7mvyx51nwxwf822w2fpww1x0z8z0q47p8705g2hbv0i"))

(define rust-proc-macro2-1.0.95
  (crate-source "proc-macro2" "1.0.95"
                "0y7pwxv6sh4fgg6s715ygk1i7g3w02c0ljgcsfm046isibkfbcq2"))

(define rust-profiling-1.0.17
  (crate-source "profiling" "1.0.17"
                "0wqp6i1bl7azy9270dp92srbbr55mgdh9qnk5b1y44lyarmlif1y"))

(define rust-profiling-procmacros-1.0.17
  (crate-source "profiling-procmacros" "1.0.17"
                "0nrxdh5r723raxbs136jmjx46p0c5qgai8jwz4j555mn0ad7ywaj"))

(define rust-pulldown-cmark-0.13.4
  (crate-source "pulldown-cmark" "0.13.4"
                "0kii5zdm7nvdjh7rjkjpvxd0sx1cyd21p0qijmgiq1z7m3mniw79"))

(define rust-pulldown-cmark-escape-0.11.0
  (crate-source "pulldown-cmark-escape" "0.11.0"
                "1bp13akkz52p43vh2ffpgv604l3xd9b67b4iykizidnsbpdqlz80"))

(define rust-pxfm-0.1.28
  (crate-source "pxfm" "0.1.28"
                "17bbi6r9jiz9rmlj9zwjcf3qrivr33l8vwjmj9y812ysagkl385m"))

(define rust-qoi-0.4.1
  (crate-source "qoi" "0.4.1"
                "00c0wkb112annn2wl72ixyd78mf56p4lxkhlmsggx65l3v3n8vbz"))

(define rust-quick-error-2.0.1
  (crate-source "quick-error" "2.0.1"
                "18z6r2rcjvvf8cn92xjhm2qc3jpd1ljvcbf12zv0k9p565gmb4x9"))

(define rust-quick-xml-0.32.0
  (crate-source "quick-xml" "0.32.0"
                "1hk9x4fij5kq1mnn7gmxz1hpv8s9wnnj4gx4ly7hw3mn71c6wfhx"))

(define rust-quinn-0.11.8
  (crate-source "quinn" "0.11.8"
                "1j02h87nfxww5mjcw4vjcnx8b70q0yinnc8xvjv82ryskii18qk2"))

(define rust-quinn-proto-0.11.14
  (crate-source "quinn-proto" "0.11.14"
                "1660jkxhzi1pnywzs13ifczwrlv6ds9qds111vsnxjciqpz44js3"))

(define rust-quinn-udp-0.5.12
  (crate-source "quinn-udp" "0.5.12"
                "0hm89bv7mm383lv2c8z5r9512pdgp1q26lsmazicajgrj6cm4kpf"))

(define rust-quote-1.0.40
  (crate-source "quote" "1.0.40"
                "1394cxjg6nwld82pzp2d4fp6pmaz32gai1zh9z5hvh0dawww118q"))

(define rust-r-efi-5.2.0
  (crate-source "r-efi" "5.2.0"
                "1ig93jvpqyi87nc5kb6dri49p56q7r7qxrn8kfizmqkfj5nmyxkl"))

(define rust-rand-0.9.4
  (crate-source "rand" "0.9.4"
                "1sknbxgs6nfg0nxdd7689lwbyr2i4vaswchrv4b34z8vpc3azia4"))

(define rust-rand-0.10.0
  (crate-source "rand" "0.10.0"
                "1y7g1zddjzhzwg0k1nddsfyfaq89a7igpcf7q44mqv6z2frnw9mw"))

(define rust-rand-chacha-0.9.0
  (crate-source "rand_chacha" "0.9.0"
                "1jr5ygix7r60pz0s1cv3ms1f6pd1i9pcdmnxzzhjc3zn3mgjn0nk"))

(define rust-rand-core-0.9.3
  (crate-source "rand_core" "0.9.3"
                "0f3xhf16yks5ic6kmgxcpv1ngdhp48mmfy4ag82i1wnwh8ws3ncr"))

(define rust-rand-core-0.10.0
  (crate-source "rand_core" "0.10.0"
                "1flazfw1q1hbvadwzmaliplz0xnnjijdnbmzxnzdqplhfzb0z38c"))

(define rust-rand-distr-0.6.0
  (crate-source "rand_distr" "0.6.0"
                "1n61c943yzpwxkirxmvagnwj5fwyyh1kq9a59pg2kwfc0ckiqhsd"))

(define rust-rav1e-0.8.1
  (crate-source "rav1e" "0.8.1"
                "0axk3ji3jmlr81svmsy5zvj8shmhpp8lz5nyghkq752xx1bdvdj3"))

(define rust-ravif-0.13.0
  (crate-source "ravif" "0.13.0"
                "0ifcpczxf6kcsqlky08vbjrvw9yd1m9mfszywxdhy6wpglci08z5"))

(define rust-rayon-1.11.0
  (crate-source "rayon" "1.11.0"
                "13x5fxb7rn4j2yw0cr26n7782jkc7rjzmdkg42qxk3xz0p8033rn"))

(define rust-rayon-core-1.13.0
  (crate-source "rayon-core" "1.13.0"
                "14dbr0sq83a6lf1rfjq5xdpk5r6zgzvmzs5j6110vlv2007qpq92"))

(define rust-redox-syscall-0.1.57
  (crate-source "redox_syscall" "0.1.57"
                "1kh59fpwy33w9nwd5iyc283yglq8pf2s41hnhvl48iax9mz0zk21"))

(define rust-redox-syscall-0.5.12
  (crate-source "redox_syscall" "0.5.12"
                "1by5k76jr4kjy37287ifn56dzw6jh6nrwnrjm29j615ayafcm3wj"))

(define rust-regex-1.12.3
  (crate-source "regex" "1.12.3"
                "0xp2q0x7ybmpa5zlgaz00p8zswcirj9h8nry3rxxsdwi9fhm81z1"))

(define rust-regex-automata-0.4.13
  (crate-source "regex-automata" "0.4.13"
                "070z0j23pjfidqz0z89id1fca4p572wxpcr20a0qsv68bbrclxjj"))

(define rust-regex-syntax-0.8.5
  (crate-source "regex-syntax" "0.8.5"
                "0p41p3hj9ww7blnbwbj9h7rwxzxg0c1hvrdycgys8rxyhqqw859b"))

(define rust-reqwest-0.12.28
  (crate-source "reqwest" "0.12.28"
                "0iqidijghgqbzl3bjg5hb4zmigwa4r612bgi0yiq0c90b6jkrpgd"))

(define rust-resvg-0.47.0
  (crate-source "resvg" "0.47.0"
                "10cfzm1ldb2vmwcrsdfjdzmb7f4814xh7j746dpsjsi1danq7qcv"))

(define rust-rgb-0.8.53
  (crate-source "rgb" "0.8.53"
                "1i0c55whln68zs6f5qqrkbg1mzai0p3qk1mwkwzdgr9i3dw4pcs7"))

(define rust-ring-0.17.14
  (crate-source "ring" "0.17.14"
                "1dw32gv19ccq4hsx3ribhpdzri1vnrlcfqb2vj41xn4l49n9ws54"))

(define rust-rodio-0.22.2
  (crate-source "rodio" "0.22.2"
                "1sq1xikp3phcisvb3kny2srqgsq2dhjd8k8syy70jnfvg6xkd9fh"))

(define rust-ron-0.12.1
  (crate-source "ron" "0.12.1"
                "1z68ps1v4kn7c0lsdc5f27qhb3baglph49wmx6hfq6gqyd9bjis1"))

(define rust-roxmltree-0.20.0
  (crate-source "roxmltree" "0.20.0"
                "15vw91ps91wkmmgy62khf9zb63bdinvm80957dascbsw7dwvc83c"))

(define rust-roxmltree-0.21.1
  (crate-source "roxmltree" "0.21.1"
                "1fxc3jgvl2rk05bw0hj86azqg6mzlijh06gyi9pw69b1qw84p5pi"))

(define rust-rs-complete-1.3.1
  (crate-source "rs-complete" "1.3.1"
                "0z64klz2mw048723s77wy5bssnksaf7nq4i0vi5cv08m2dadin8m"))

(define rust-rtrb-0.3.2
  (crate-source "rtrb" "0.3.2"
                "1fp3rjd8bzx89wdx5g7c42rxqzlyd4x2ds22wh3sh3ly3bm8i0xd"))

(define rust-rustc-demangle-0.1.24
  (crate-source "rustc-demangle" "0.1.24"
                "07zysaafgrkzy2rjgwqdj2a8qdpsm6zv6f5pgpk9x0lm40z9b6vi"))

(define rust-rustc-hash-1.1.0
  (crate-source "rustc-hash" "1.1.0"
                "1qkc5khrmv5pqi5l5ca9p5nl5hs742cagrndhbrlk3dhlrx3zm08"))

(define rust-rustc-hash-2.1.1
  (crate-source "rustc-hash" "2.1.1"
                "03gz5lvd9ghcwsal022cgkq67dmimcgdjghfb5yb5d352ga06xrm"))

(define rust-rustix-0.38.44
  (crate-source "rustix" "0.38.44"
                "0m61v0h15lf5rrnbjhcb9306bgqrhskrqv7i1n0939dsw8dbrdgx"))

(define rust-rustix-1.1.4
  (crate-source "rustix" "1.1.4"
                "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn"))

(define rust-rustls-0.23.40
  (crate-source "rustls" "0.23.40"
                "12qnv3ag4wrw7aj8jng74kgrilpjm2b1rfcjaac8h691frccv1pg"))

(define rust-rustls-pemfile-2.2.0
  (crate-source "rustls-pemfile" "2.2.0"
                "0l3f3mrfkgdjrava7ibwzgwc4h3dljw3pdkbsi9rkwz3zvji9qyw"))

(define rust-rustls-pki-types-1.12.0
  (crate-source "rustls-pki-types" "1.12.0"
                "0yawbdpix8jif6s8zj1p2hbyb7y3bj66fhx0y7hyf4qh4964m6i2"))

(define rust-rustls-webpki-0.103.13
  (crate-source "rustls-webpki" "0.103.13"
                "0vkm7z9pnxz5qz66p2kmyy2pwx0g4jnsbqk5xzfhs4czcjl2ki31"))

(define rust-rustversion-1.0.21
  (crate-source "rustversion" "1.0.21"
                "07bb1xx05hhwpnl43sqrhsmxyk5sd5m5baadp19nxp69s9xij3ca"))

(define rust-rustybuzz-0.20.1
  (crate-source "rustybuzz" "0.20.1"
                "00hp1gwykjfli258zs7lqg8p2zdh94dv2mw8zx7f73m0z2b7qg7x"))

(define rust-ryu-1.0.20
  (crate-source "ryu" "1.0.20"
                "07s855l8sb333h6bpn24pka5sp7hjk2w667xy6a0khkf6sqv5lr8"))

(define rust-same-file-1.0.6
  (crate-source "same-file" "1.0.6"
                "00h5j1w87dmhnvbv9l8bic3y7xxsnjmssvifw2ayvgx9mb1ivz4k"))

(define rust-scopeguard-1.2.0
  (crate-source "scopeguard" "1.2.0"
                "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l"))

(define rust-semver-1.0.27
  (crate-source "semver" "1.0.27"
                "1qmi3akfrnqc2hfkdgcxhld5bv961wbk8my3ascv5068mc5fnryp"))

(define rust-serde-1.0.228
  (crate-source "serde" "1.0.228"
                "17mf4hhjxv5m90g42wmlbc61hdhlm6j9hwfkpcnd72rpgzm993ls"))

(define rust-serde-core-1.0.228
  (crate-source "serde_core" "1.0.228"
                "1bb7id2xwx8izq50098s5j2sqrrvk31jbbrjqygyan6ask3qbls1"))

(define rust-serde-derive-1.0.228
  (crate-source "serde_derive" "1.0.228"
                "0y8xm7fvmr2kjcd029g9fijpndh8csv5m20g4bd76w8qschg4h6m"))

(define rust-serde-json-1.0.150
  (crate-source "serde_json" "1.0.150"
                "1ffgfhy9kndjnrz8lmy95pr758p2zk8dxv6yi99x0vkkni24w0g8"))

(define rust-serde-spanned-1.1.1
  (crate-source "serde_spanned" "1.1.1"
                "09jzk7i6wihn3d8i3wi4j4n98ghi93c3b8m8k64nxq0ijn3vaqk6"))

(define rust-serde-urlencoded-0.7.1
  (crate-source "serde_urlencoded" "0.7.1"
                "1zgklbdaysj3230xivihs30qi5vkhigg323a9m62k8jwf4a1qjfk"))

(define rust-shlex-1.3.0
  (crate-source "shlex" "1.3.0"
                "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg"))

(define rust-signal-hook-0.4.4
  (crate-source "signal-hook" "0.4.4"
                "0gdm8kmi1mcd30gkxcwagxiqiasq0fhdlvrfsnybv3chln6c585j"))

(define rust-signal-hook-registry-1.4.5
  (crate-source "signal-hook-registry" "1.4.5"
                "042lkqrpnlrgvrrcirgigxyp1zk70d8v0fsr5w7a18k3bw2vh0wj"))

(define rust-simd-adler32-0.3.7
  (crate-source "simd-adler32" "0.3.7"
                "1zkq40c3iajcnr5936gjp9jjh1lpzhy44p3dq3fiw75iwr1w2vfn"))

(define rust-simd-helpers-0.1.0
  (crate-source "simd_helpers" "0.1.0"
                "19idqicn9k4vhd04ifh2ff41wvna79zphdf2c81rlmpc7f3hz2cm"))

(define rust-similar-2.7.0
  (crate-source "similar" "2.7.0"
                "1aidids7ymfr96s70232s6962v5g9l4zwhkvcjp4c5hlb6b5vfxv"))

(define rust-similar-3.0.0
  (crate-source "similar" "3.0.0"
                "15jkqx8gm84z8vw41ncdcg56drr3k3la6w7rf03wmw2lp9pb1l16"))

(define rust-similar-asserts-2.0.0
  (crate-source "similar-asserts" "2.0.0"
                "1303j5r0d47a1yba8ha3hz6wlx0j1njm0zwzzirpjhwpisinqzlr"))

(define rust-simple-logging-2.0.2
  (crate-source "simple-logging" "2.0.2"
                "0hmm523f0ax76yljf3z178rn9cm0q6knwa52haqnnckmavl4h3dh"))

(define rust-simplecss-0.2.2
  (crate-source "simplecss" "0.2.2"
                "0v0kid7b2602kcka2x2xs9wwfjf8lnvpgpl8x287qg4wra1ni73s"))

(define rust-siphasher-1.0.2
  (crate-source "siphasher" "1.0.2"
                "13k7cfbpcm8qgj9p2n8dwg9skv9s0hxk5my30j5chy1p4l78bamj"))

(define rust-slab-0.4.9
  (crate-source "slab" "0.4.9"
                "0rxvsgir0qw5lkycrqgb1cxsvxzjv9bmx73bk5y42svnzfba94lg"))

(define rust-slotmap-1.1.1
  (crate-source "slotmap" "1.1.1"
                "0f20xf53zaysx9ydzkwwqm6hsjyb8lj2j6amhg57iln3jcy8rmdx"))

(define rust-smallvec-1.15.1
  (crate-source "smallvec" "1.15.1"
                "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7"))

(define rust-socket2-0.5.10
  (crate-source "socket2" "0.5.10"
                "0y067ki5q946w91xlz2sb175pnfazizva6fi3kfp639mxnmpc8z2"))

(define rust-socket2-0.6.3
  (crate-source "socket2" "0.6.3"
                "0gkjjcyn69hqhhlh5kl8byk5m0d7hyrp2aqwzbs3d33q208nwxis"))

(define rust-speech-dispatcher-0.16.0
  (crate-source "speech-dispatcher" "0.16.0"
                "0wi9xdchgc3n4frhxvngai4ag5pq7hh7vbc4fyhav9ab8wyda9sp"))

(define rust-speech-dispatcher-sys-0.7.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "speech-dispatcher-sys" "0.7.0"
                "139q20m6fksq79qzwmca9p4lrpry5ysl0fw1y49vpx5iyb6qlgkc"))

(define rust-stable-deref-trait-1.2.0
  (crate-source "stable_deref_trait" "1.2.0"
                "1lxjr8q2n534b2lhkxd6l6wcddzjvnksi58zv11f9y0jjmr15wd8"))

(define rust-strict-num-0.1.1
  (crate-source "strict-num" "0.1.1"
                "0cb7l1vhb8zj90mzm8avlk815k40sql9515s865rqdrdfavvldv6"))

(define rust-strip-ansi-escapes-0.2.1
  (crate-source "strip-ansi-escapes" "0.2.1"
                "0980min1s9f5g47rwlq8l9njks952a0jlz0v7yxrm5p7www813ra"))

(define rust-subtle-2.6.1
  (crate-source "subtle" "2.6.1"
                "14ijxaymghbl1p0wql9cib5zlwiina7kall6w7g89csprkgbvhhk"))

(define rust-svgtypes-0.16.1
  (crate-source "svgtypes" "0.16.1"
                "0gdw5a7znyv5sh4a575ddlhkvnvf45dd5grvkflsy78knf85fnv9"))

(define rust-symphonia-0.5.5
  (crate-source "symphonia" "0.5.5"
                "0fbhlmvf1m9rb5xdy057vzymvirmzx39gx4hl3x9p7d1630a8wsp"))

(define rust-symphonia-bundle-flac-0.5.5
  (crate-source "symphonia-bundle-flac" "0.5.5"
                "0xlrdil9prgbwds8j2rd0z8gy9i5h13ca459h2dmv8mfh3hna5f9"))

(define rust-symphonia-bundle-mp3-0.5.5
  (crate-source "symphonia-bundle-mp3" "0.5.5"
                "1vapgi7haxmi4fnf09rvc4z6q24136m5gsg3k73ymxbbnmmxswj8"))

(define rust-symphonia-codec-aac-0.5.5
  (crate-source "symphonia-codec-aac" "0.5.5"
                "1457ffg88inyb6x1s4cnid7icmbz9jjjj5wwhhb19246m92kh9jc"))

(define rust-symphonia-codec-pcm-0.5.5
  (crate-source "symphonia-codec-pcm" "0.5.5"
                "158x0g5v13qh1c4jyyrzd8kcz9rqim6cx4bwpqzash8mq0bdg2af"))

(define rust-symphonia-codec-vorbis-0.5.5
  (crate-source "symphonia-codec-vorbis" "0.5.5"
                "0wqwbnwb3ibwf14mx6irqm99bdap4950nxbjypz9zmlw61y869gh"))

(define rust-symphonia-core-0.5.5
  (crate-source "symphonia-core" "0.5.5"
                "1by293wrwb37as89fx8qzr1klvq6l5jw1pbyz1zvpxmpg57wq07a"))

(define rust-symphonia-format-isomp4-0.5.5
  (crate-source "symphonia-format-isomp4" "0.5.5"
                "19g060n3hjrnzisrc9csq3v9hy6c30yrz3dcinpivy0ibmc3jdr4"))

(define rust-symphonia-format-ogg-0.5.5
  (crate-source "symphonia-format-ogg" "0.5.5"
                "1jrrar1v3a2x7gkm3c5j35mfzywphg5093a2x25amlqygk35aj9b"))

(define rust-symphonia-format-riff-0.5.5
  (crate-source "symphonia-format-riff" "0.5.5"
                "0vx9247jsn9cjr0s3hay1ns04g77x831kn01hjvfz53x1vgw7my2"))

(define rust-symphonia-metadata-0.5.5
  (crate-source "symphonia-metadata" "0.5.5"
                "05kbkshrzqj83mlbkdwxkgkjzmhb3q99xm4rzid6xzlz5gs6yc1n"))

(define rust-symphonia-utils-xiph-0.5.5
  (crate-source "symphonia-utils-xiph" "0.5.5"
                "05lzmgxppqn647hmc1j9pgqsdqa2pxxcgvk8dd23i8wrnxdch9zf"))

(define rust-syn-1.0.109
  (crate-source "syn" "1.0.109"
                "0ds2if4600bd59wsv7jjgfkayfzy3hnazs394kz6zdkmna8l3dkj"))

(define rust-syn-2.0.101
  (crate-source "syn" "2.0.101"
                "1brwsh7fn3bnbj50d2lpwy9akimzb3lghz0ai89j8fhvjkybgqlc"))

(define rust-sync-wrapper-1.0.2
  (crate-source "sync_wrapper" "1.0.2"
                "0qvjyasd6w18mjg5xlaq5jgy84jsjfsvmnn12c13gypxbv75dwhb"))

(define rust-synstructure-0.13.2
  (crate-source "synstructure" "0.13.2"
                "1lh9lx3r3jb18f8sbj29am5hm9jymvbwh6jb1izsnnxgvgrp12kj"))

(define rust-syntect-5.3.0
  (crate-source "syntect" "5.3.0"
                "09f9j0hlsz5zmc0fkjdp64sjnyzcvp86pvxfk51p19cmbp04asv5"))

(define rust-sysinfo-0.38.4
  (crate-source "sysinfo" "0.38.4"
                "0bx5wjp16cyckr9c0fxzrfcx54g4aa15f1k47kmqsl7yicpnmawj"))

(define rust-temp-env-0.3.6
  (crate-source "temp-env" "0.3.6"
                "0l7hpkd0nhiy4w70j9xbygl1vjr9ipcfxii164n40iwg0ralhdwn"))

(define rust-tempfile-3.20.0
  (crate-source "tempfile" "3.20.0"
                "18fnp7mjckd9c9ldlb2zhp1hd4467y2hpvx9l50j97rlhlwlx9p8"))

(define rust-terminal-size-0.4.4
  (crate-source "terminal_size" "0.4.4"
                "0x4839vhhpzacc42rqj2wjhivlhlggzz3890b0c5pmyb3j11n2i3"))

(define rust-termion-4.0.6
  (crate-source "termion" "4.0.6"
                "1jsy8zakr7gjy4wddb1m1hrsfkgg2wjxh121y81gbw08mslkhhgl"))

(define rust-termtree-0.5.1
  (crate-source "termtree" "0.5.1"
                "10s610ax6nb70yi7xfmwcb6d3wi9sj5isd0m63gy2pizr2zgwl4g"))

(define rust-textwrap-0.16.2
  (crate-source "textwrap" "0.16.2"
                "0mrhd8q0dnh5hwbwhiv89c6i41yzmhw4clwa592rrp24b9hlfdf1"))

(define rust-thiserror-1.0.69
  (crate-source "thiserror" "1.0.69"
                "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn"))

(define rust-thiserror-2.0.12
  (crate-source "thiserror" "2.0.12"
                "024791nsc0np63g2pq30cjf9acj38z3jwx9apvvi8qsqmqnqlysn"))

(define rust-thiserror-impl-1.0.69
  (crate-source "thiserror-impl" "1.0.69"
                "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg"))

(define rust-thiserror-impl-2.0.12
  (crate-source "thiserror-impl" "2.0.12"
                "07bsn7shydaidvyyrm7jz29vp78vrxr9cr9044rfmn078lmz8z3z"))

(define rust-thread-id-3.3.0
  (crate-source "thread-id" "3.3.0"
                "1h90v19fjz3x9b25ywh68z5yf2zsmm6h5zb4rl302ckbsp4z9yy7"))

(define rust-tiff-0.11.3
  (crate-source "tiff" "0.11.3"
                "0lmw68ic77sixk17r4rl2vsv00rqhja3yj2h9p5bcd9x6krylgxn"))

(define rust-time-0.3.47
  (crate-source "time" "0.3.47"
                "0b7g9ly2iabrlgizliz6v5x23yq5d6bpp0mqz6407z1s526d8fvl"))

(define rust-time-core-0.1.8
  (crate-source "time-core" "0.1.8"
                "1jidl426mw48i7hjj4hs9vxgd9lwqq4vyalm4q8d7y4iwz7y353n"))

(define rust-time-macros-0.2.27
  (crate-source "time-macros" "0.2.27"
                "058ja265waq275wxvnfwavbz9r1hd4dgwpfn7a1a9a70l32y8w1f"))

(define rust-timer-0.2.0
  (crate-source "timer" "0.2.0"
                "0srhqyp7fr91d1i43aqs7wc6yn1i3kdkh1pm05bicdw961v23m1i"))

(define rust-tiny-skia-0.12.0
  (crate-source "tiny-skia" "0.12.0"
                "1sliba6ghl038ig7r4wds7aq9v5x1swmdqxh1xipylpmm9gfxzs7"))

(define rust-tiny-skia-path-0.12.0
  (crate-source "tiny-skia-path" "0.12.0"
                "1fgfzl0mzf2vfcqk3817wxynhmvcza05jg2r0rysdk5c7xf3djpd"))

(define rust-tinystr-0.8.1
  (crate-source "tinystr" "0.8.1"
                "12sc6h3hnn6x78iycm5v6wrs2xhxph0ydm43yyn7gdfw8l8nsksx"))

(define rust-tinyvec-1.9.0
  (crate-source "tinyvec" "1.9.0"
                "0w9w8qcifns9lzvlbfwa01y0skhr542anwa3rpn28rg82wgndcq9"))

(define rust-tinyvec-macros-0.1.1
  (crate-source "tinyvec_macros" "0.1.1"
                "081gag86208sc3y6sdkshgw3vysm5d34p431dzw0bshz66ncng0z"))

(define rust-tokio-1.45.1
  (crate-source "tokio" "1.45.1"
                "0yb7h0mr0m0gfwdl1jir2k37gcrwhcib2kiyx9f95npi7sim3vvm"))

(define rust-tokio-rustls-0.26.2
  (crate-source "tokio-rustls" "0.26.2"
                "16wf007q3584j46wc4s0zc4szj6280g23hka6x6bgs50l4v7nwlf"))

(define rust-toml-1.1.1+spec-1.1.0
  (crate-source "toml" "1.1.1+spec-1.1.0"
                "1vk8l3ms27rnawmqnska0rka87w01d8s9qmhp8s2prmswzcrajwr"))

(define rust-toml-datetime-0.6.11
  (crate-source "toml_datetime" "0.6.11"
                "077ix2hb1dcya49hmi1avalwbixmrs75zgzb3b2i7g2gizwdmk92"))

(define rust-toml-datetime-1.1.1+spec-1.1.0
  (crate-source "toml_datetime" "1.1.1+spec-1.1.0"
                "1mws2mkkf46l7inn77azhm0vdwxngv9vsbhbl0ah33p2c9gzcr9i"))

(define rust-toml-edit-0.22.27
  (crate-source "toml_edit" "0.22.27"
                "16l15xm40404asih8vyjvnka9g0xs9i4hfb6ry3ph9g419k8rzj1"))

(define rust-toml-writer-1.1.1+spec-1.1.0
  (crate-source "toml_writer" "1.1.1+spec-1.1.0"
                "1nwjhvvrxz8f4ck1qi4xcz2x9qhpci37nrknhxxf9sqk22dsyvbm"))

(define rust-tower-0.5.2
  (crate-source "tower" "0.5.2"
                "1ybmd59nm4abl9bsvy6rx31m4zvzp5rja2slzpn712y9b68ssffh"))

(define rust-tower-http-0.6.8
  (crate-source "tower-http" "0.6.8"
                "1y514jwzbyrmrkbaajpwmss4rg0mak82k16d6588w9ncaffmbrnl"))

(define rust-tower-layer-0.3.3
  (crate-source "tower-layer" "0.3.3"
                "03kq92fdzxin51w8iqix06dcfgydyvx7yr6izjq0p626v9n2l70j"))

(define rust-tower-service-0.3.3
  (crate-source "tower-service" "0.3.3"
                "1hzfkvkci33ra94xjx64vv3pp0sq346w06fpkcdwjcid7zhvdycd"))

(define rust-tracing-0.1.44
  (crate-source "tracing" "0.1.44"
                "006ilqkg1lmfdh3xhg3z762izfwmxcvz0w7m4qx2qajbz9i1drv3"))

(define rust-tracing-attributes-0.1.31
  (crate-source "tracing-attributes" "0.1.31"
                "1np8d77shfvz0n7camx2bsf1qw0zg331lra0hxb4cdwnxjjwz43l"))

(define rust-tracing-core-0.1.36
  (crate-source "tracing-core" "0.1.36"
                "16mpbz6p8vd6j7sf925k9k8wzvm9vdfsjbynbmaxxyq6v7wwm5yv"))

(define rust-try-lock-0.2.5
  (crate-source "try-lock" "0.2.5"
                "0jqijrrvm1pyq34zn1jmy2vihd4jcrjlvsh4alkjahhssjnsn8g4"))

(define rust-ttf-parser-0.25.1
  (crate-source "ttf-parser" "0.25.1"
                "0cbgqglcwwjg3hirwq6xlza54w04mb5x02kf7zx4hrw50xmr1pyj"))

(define rust-tts-0.26.3
  (crate-source "tts" "0.26.3"
                "1qisk2jdy1sgx9lyjwk05fvm8h1vinkycw7rg57gir4165mw89q7"))

(define rust-typeid-1.0.3
  (crate-source "typeid" "1.0.3"
                "0727ypay2p6mlw72gz3yxkqayzdmjckw46sxqpaj08v0b0r64zdw"))

(define rust-unicase-2.8.1
  (crate-source "unicase" "2.8.1"
                "0fd5ddbhpva7wrln2iah054ar2pc1drqjcll0f493vj3fv8l9f3m"))

(define rust-unicode-bidi-0.3.18
  (crate-source "unicode-bidi" "0.3.18"
                "1xcxwbsqa24b8vfchhzyyzgj0l6bn51ib5v8j6krha0m77dva72w"))

(define rust-unicode-bidi-mirroring-0.4.0
  (crate-source "unicode-bidi-mirroring" "0.4.0"
                "1zirs1z3ahlwy7swg7apnm3pc6vix1g15q0kn6fx8rmvc266xyjx"))

(define rust-unicode-ccc-0.4.0
  (crate-source "unicode-ccc" "0.4.0"
                "0gjhxwx27ywm3rcbb0m5q20w8zxi51440b3ps6swi6ywpj4d8qff"))

(define rust-unicode-ident-1.0.18
  (crate-source "unicode-ident" "1.0.18"
                "04k5r6sijkafzljykdq26mhjpmhdx4jwzvn1lh90g9ax9903jpss"))

(define rust-unicode-linebreak-0.1.5
  (crate-source "unicode-linebreak" "0.1.5"
                "07spj2hh3daajg335m4wdav6nfkl0f6c0q72lc37blr97hych29v"))

(define rust-unicode-properties-0.1.4
  (crate-source "unicode-properties" "0.1.4"
                "07fpm3sqq7lm9gmgpxa93z31q933h3c3ypfwy4cdh6l42g3miw3x"))

(define rust-unicode-script-0.5.8
  (crate-source "unicode-script" "0.5.8"
                "1vmifpgd0map3frmvhszhl96k82crcry083prv05wii7p45x8fiq"))

(define rust-unicode-segmentation-1.12.0
  (crate-source "unicode-segmentation" "1.12.0"
                "14qla2jfx74yyb9ds3d2mpwpa4l4lzb9z57c6d2ba511458z5k7n"))

(define rust-unicode-vo-0.1.0
  (crate-source "unicode-vo" "0.1.0"
                "151sha088v9jyfvbg5164xh4dk72g53b82xm4zzbf5dlagzqdlxi"))

(define rust-unicode-width-0.2.2
  (crate-source "unicode-width" "0.2.2"
                "0m7jjzlcccw716dy9423xxh0clys8pfpllc5smvfxrzdf66h9b5l"))

(define rust-unicode-xid-0.2.6
  (crate-source "unicode-xid" "0.2.6"
                "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb"))

(define rust-untrusted-0.9.0
  (crate-source "untrusted" "0.9.0"
                "1ha7ib98vkc538x0z60gfn0fc5whqdd85mb87dvisdcaifi6vjwf"))

(define rust-url-2.5.4
  (crate-source "url" "2.5.4"
                "0q6sgznyy2n4l5lm16zahkisvc9nip9aa5q1pps7656xra3bdy1j"))

(define rust-usvg-0.47.0
  (crate-source "usvg" "0.47.0"
                "1ph7khq3vp5h94i1pml964qbj2sw0ykwcfv9m6vkd3a9bxngjv6l"))

(define rust-utf8-iter-1.0.4
  (crate-source "utf8_iter" "1.0.4"
                "1gmna9flnj8dbyd8ba17zigrp9c4c3zclngf5lnb5yvz1ri41hdn"))

(define rust-utf8parse-0.2.2
  (crate-source "utf8parse" "0.2.2"
                "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6"))

(define rust-uuid-1.23.0
  (crate-source "uuid" "1.23.0"
                "1nbrzkdhwr4clshsks7flc2jq6lavjrsx65hyn63c9dd5vsbdj2s"))

(define rust-v-frame-0.3.9
  (crate-source "v_frame" "0.3.9"
                "1qkvb4ks33zck931vzqckjn36hkngj6l2cwmvfsnlpc7r0kpfsv6"))

(define rust-vcpkg-0.2.15
  (crate-source "vcpkg" "0.2.15"
                "09i4nf5y8lig6xgj3f7fyrvzd3nlaw4znrihw8psidvv5yk4xkdc"))

(define rust-version-check-0.9.5
  (crate-source "version_check" "0.9.5"
                "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb"))

(define rust-vte-0.14.1
  (crate-source "vte" "0.14.1"
                "0xy01fgkzb2080prh2ncd8949hm2248fc5wf1lryhdrhxzbxq7r3"))

(define rust-vte-0.15.0
  (crate-source "vte" "0.15.0"
                "1g9xgnw7q7zdwgfqa6zfcfsp92wn0j0h13kzsqy0dq3c80c414m5"))

(define rust-walkdir-2.5.0
  (crate-source "walkdir" "2.5.0"
                "0jsy7a710qv8gld5957ybrnc07gavppp963gs32xk4ag8130jy99"))

(define rust-want-0.3.1
  (crate-source "want" "0.3.1"
                "03hbfrnvqqdchb5kgxyavb9jabwza0dmh2vw5kg0dq8rxl57d9xz"))

(define rust-wasi-0.11.0+wasi-snapshot-preview1
  (crate-source "wasi" "0.11.0+wasi-snapshot-preview1"
                "08z4hxwkpdpalxjps1ai9y7ihin26y9f476i53dv98v45gkqg3cw"))

(define rust-wasi-0.14.2+wasi-0.2.4
  (crate-source "wasi" "0.14.2+wasi-0.2.4"
                "1cwcqjr3dgdq8j325awgk8a715h0hg0f7jqzsb077n4qm6jzk0wn"))

(define rust-wasip2-1.0.2+wasi-0.2.9
  (crate-source "wasip2" "1.0.2+wasi-0.2.9"
                "1xdw7v08jpfjdg94sp4lbdgzwa587m5ifpz6fpdnkh02kwizj5wm"))

(define rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
  (crate-source "wasip3" "0.4.0+wasi-0.3.0-rc-2026-01-06"
                "19dc8p0y2mfrvgk3qw3c3240nfbylv22mvyxz84dqpgai2zzha2l"))

(define rust-wasm-bindgen-0.2.100
  (crate-source "wasm-bindgen" "0.2.100"
                "1x8ymcm6yi3i1rwj78myl1agqv2m86i648myy3lc97s9swlqkp0y"))

(define rust-wasm-bindgen-backend-0.2.100
  (crate-source "wasm-bindgen-backend" "0.2.100"
                "1ihbf1hq3y81c4md9lyh6lcwbx6a5j0fw4fygd423g62lm8hc2ig"))

(define rust-wasm-bindgen-futures-0.4.50
  (crate-source "wasm-bindgen-futures" "0.4.50"
                "0q8ymi6i9r3vxly551dhxcyai7nc491mspj0j1wbafxwq074fpam"))

(define rust-wasm-bindgen-macro-0.2.100
  (crate-source "wasm-bindgen-macro" "0.2.100"
                "01xls2dvzh38yj17jgrbiib1d3nyad7k2yw9s0mpklwys333zrkz"))

(define rust-wasm-bindgen-macro-support-0.2.100
  (crate-source "wasm-bindgen-macro-support" "0.2.100"
                "1plm8dh20jg2id0320pbmrlsv6cazfv6b6907z19ys4z1jj7xs4a"))

(define rust-wasm-bindgen-shared-0.2.100
  (crate-source "wasm-bindgen-shared" "0.2.100"
                "0gffxvqgbh9r9xl36gprkfnh3w9gl8wgia6xrin7v11sjcxxf18s"))

(define rust-wasm-encoder-0.244.0
  (crate-source "wasm-encoder" "0.244.0"
                "06c35kv4h42vk3k51xjz1x6hn3mqwfswycmr6ziky033zvr6a04r"))

(define rust-wasm-metadata-0.244.0
  (crate-source "wasm-metadata" "0.244.0"
                "02f9dhlnryd2l7zf03whlxai5sv26x4spfibjdvc3g9gd8z3a3mv"))

(define rust-wasmparser-0.244.0
  (crate-source "wasmparser" "0.244.0"
                "1zi821hrlsxfhn39nqpmgzc0wk7ax3dv6vrs5cw6kb0v5v3hgf27"))

(define rust-web-sys-0.3.77
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "web-sys" "0.3.77"
                "1lnmc1ffbq34qw91nndklqqm75rasaffj2g4f8h1yvqqz4pdvdik"))

(define rust-web-time-1.1.0
  (crate-source "web-time" "1.1.0"
                "1fx05yqx83dhx628wb70fyy10yjfq1jpl20qfqhdkymi13rq0ras"))

(define rust-webpki-roots-1.0.7
  (crate-source "webpki-roots" "1.0.7"
                "17gblaqmp51znxd2c18c04k8yfnf7s77c04n6hdmzxbcr52fxxaj"))

(define rust-weezl-0.1.12
  (crate-source "weezl" "0.1.12"
                "122a1dhha6cib5az4ihcqlh60ns2bi6rskdv875p94lbvj6wk2m2"))

(define rust-which-4.4.2
  (crate-source "which" "4.4.2"
                "1ixzmx3svsv5hbdvd8vdhd3qwvf6ns8jdpif1wmwsy10k90j9fl7"))

(define rust-which-7.0.3
  (crate-source "which" "7.0.3"
                "0qj7lx7v98hcs0rfw4xqw1ssn47v6h7hhak0ai4bbrfk7z747mi4"))

(define rust-winapi-0.3.9
  (crate-source "winapi" "0.3.9"
                "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw"))

(define rust-winapi-i686-pc-windows-gnu-0.4.0
  (crate-source "winapi-i686-pc-windows-gnu" "0.4.0"
                "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc"))

(define rust-winapi-util-0.1.9
  (crate-source "winapi-util" "0.1.9"
                "1fqhkcl9scd230cnfj8apfficpf5c9vhwnk4yy9xfc1sw69iq8ng"))

(define rust-winapi-x86-64-pc-windows-gnu-0.4.0
  (crate-source "winapi-x86_64-pc-windows-gnu" "0.4.0"
                "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki"))

(define rust-windows-0.58.0
  (crate-source "windows" "0.58.0"
                "1dkjj94b0gn91nn1n22cvm4afsj98f5qrhcl3112v6f4jcfx816x"))

(define rust-windows-0.62.2
  (crate-source "windows" "0.62.2"
                "10457l9ihrbw8j79z2v4plyjxkf6xvb5npd0lqwmkh702gpaszsj"))

(define rust-windows-collections-0.3.2
  (crate-source "windows-collections" "0.3.2"
                "0436rjbkqn3j9m2v2lcmwwk0l3n2r57yvqb7fcy4m8d8y5ddkci3"))

(define rust-windows-core-0.58.0
  (crate-source "windows-core" "0.58.0"
                "16czypy425jzmiys4yb3pwsh7cm6grxn9kjp889iqnf2r17d99kb"))

(define rust-windows-core-0.61.2
  (crate-source "windows-core" "0.61.2"
                "1qsa3iw14wk4ngfl7ipcvdf9xyq456ms7cx2i9iwf406p7fx7zf0"))

(define rust-windows-core-0.62.2
  (crate-source "windows-core" "0.62.2"
                "1swxpv1a8qvn3bkxv8cn663238h2jccq35ff3nsj61jdsca3ms5q"))

(define rust-windows-future-0.3.2
  (crate-source "windows-future" "0.3.2"
                "1jq5qs2dwzf6rl60f8gr49z2mifxsrdh4y4yfdws467ya41gkmp1"))

(define rust-windows-implement-0.58.0
  (crate-source "windows-implement" "0.58.0"
                "16spr5z65z21qyv379rv2mb1s5q2i9ibd1p2pkn0dr9qr535pg9b"))

(define rust-windows-implement-0.60.2
  (crate-source "windows-implement" "0.60.2"
                "1psxhmklzcf3wjs4b8qb42qb6znvc142cb5pa74rsyxm1822wgh5"))

(define rust-windows-interface-0.58.0
  (crate-source "windows-interface" "0.58.0"
                "059mxmfvx3x88q74ms0qlxmj2pnidmr5mzn60hakn7f95m34qg05"))

(define rust-windows-interface-0.59.3
  (crate-source "windows-interface" "0.59.3"
                "0n73cwrn4247d0axrk7gjp08p34x1723483jxjxjdfkh4m56qc9z"))

(define rust-windows-link-0.1.3
  (crate-source "windows-link" "0.1.3"
                "12kr1p46dbhpijr4zbwr2spfgq8i8c5x55mvvfmyl96m01cx4sjy"))

(define rust-windows-link-0.2.1
  (crate-source "windows-link" "0.2.1"
                "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h"))

(define rust-windows-numerics-0.3.1
  (crate-source "windows-numerics" "0.3.1"
                "09hgbg8pf89r4090yyhh9q29ppi7yyxkgmga9ascshy19a240bkf"))

(define rust-windows-result-0.2.0
  (crate-source "windows-result" "0.2.0"
                "03mf2z1xcy2slhhsm15z24p76qxgm2m74xdjp8bihyag47c4640x"))

(define rust-windows-result-0.3.4
  (crate-source "windows-result" "0.3.4"
                "1il60l6idrc6hqsij0cal0mgva6n3w6gq4ziban8wv6c6b9jpx2n"))

(define rust-windows-result-0.4.1
  (crate-source "windows-result" "0.4.1"
                "1d9yhmrmmfqh56zlj751s5wfm9a2aa7az9rd7nn5027nxa4zm0bp"))

(define rust-windows-strings-0.1.0
  (crate-source "windows-strings" "0.1.0"
                "042dxvi3133f7dyi2pgcvknwkikk47k8bddwxbq5s0l6qhjv3nac"))

(define rust-windows-strings-0.4.2
  (crate-source "windows-strings" "0.4.2"
                "0mrv3plibkla4v5kaakc2rfksdd0b14plcmidhbkcfqc78zwkrjn"))

(define rust-windows-strings-0.5.1
  (crate-source "windows-strings" "0.5.1"
                "14bhng9jqv4fyl7lqjz3az7vzh8pw0w4am49fsqgcz67d67x0dvq"))

(define rust-windows-sys-0.45.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "windows-sys" "0.45.0"
                "1l36bcqm4g89pknfp8r9rl1w4bn017q6a8qlx8viv0xjxzjkna3m"))

(define rust-windows-sys-0.52.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "windows-sys" "0.52.0"
                "0gd3v4ji88490zgb6b5mq5zgbvwv7zx1ibn8v3x83rwcdbryaar8"))

(define rust-windows-sys-0.59.0
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "windows-sys" "0.59.0"
                "0fw5672ziw8b3zpmnbp9pdv1famk74f1l9fcbc3zsrzdg56vqf0y"))

(define rust-windows-sys-0.61.1
  ;; Lockfile source retained for complete offline vendoring; see package policy below.
  (crate-source "windows-sys" "0.61.1"
                "03vg2rxm0lyiyq64b5sm95lkg2x95sjdb0zb0y4q8g2avm0rw43g"))

(define rust-windows-targets-0.42.2
  (crate-source "windows-targets" "0.42.2"
                "0wfhnib2fisxlx8c507dbmh97kgij4r6kcxdi0f9nk6l1k080lcf"))

(define rust-windows-targets-0.52.6
  (crate-source "windows-targets" "0.52.6"
                "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv"))

(define rust-windows-targets-0.53.0
  (crate-source "windows-targets" "0.53.0"
                "12yakpjizhfpppz1i3zgcwxlbar8axrp9j87fmywpydarvlcgr5i"))

(define rust-windows-threading-0.2.1
  (crate-source "windows-threading" "0.2.1"
                "0dsvsy33vxs0153z4n39sqkzx382cjjkrd46rb3z3zfak5dvsj9r"))

(define rust-windows-aarch64-gnullvm-0.42.2
  (crate-source "windows_aarch64_gnullvm" "0.42.2"
                "1y4q0qmvl0lvp7syxvfykafvmwal5hrjb4fmv04bqs0bawc52yjr"))

(define rust-windows-aarch64-gnullvm-0.52.6
  (crate-source "windows_aarch64_gnullvm" "0.52.6"
                "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j"))

(define rust-windows-aarch64-gnullvm-0.53.0
  (crate-source "windows_aarch64_gnullvm" "0.53.0"
                "0r77pbpbcf8bq4yfwpz2hpq3vns8m0yacpvs2i5cn6fx1pwxbf46"))

(define rust-windows-aarch64-msvc-0.42.2
  (crate-source "windows_aarch64_msvc" "0.42.2"
                "0hsdikjl5sa1fva5qskpwlxzpc5q9l909fpl1w6yy1hglrj8i3p0"))

(define rust-windows-aarch64-msvc-0.52.6
  (crate-source "windows_aarch64_msvc" "0.52.6"
                "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09"))

(define rust-windows-aarch64-msvc-0.53.0
  (crate-source "windows_aarch64_msvc" "0.53.0"
                "0v766yqw51pzxxwp203yqy39ijgjamp54hhdbsyqq6x1c8gilrf7"))

(define rust-windows-i686-gnu-0.42.2
  (crate-source "windows_i686_gnu" "0.42.2"
                "0kx866dfrby88lqs9v1vgmrkk1z6af9lhaghh5maj7d4imyr47f6"))

(define rust-windows-i686-gnu-0.52.6
  (crate-source "windows_i686_gnu" "0.52.6"
                "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf"))

(define rust-windows-i686-gnu-0.53.0
  (crate-source "windows_i686_gnu" "0.53.0"
                "1hvjc8nv95sx5vdd79fivn8bpm7i517dqyf4yvsqgwrmkmjngp61"))

(define rust-windows-i686-gnullvm-0.52.6
  (crate-source "windows_i686_gnullvm" "0.52.6"
                "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf"))

(define rust-windows-i686-gnullvm-0.53.0
  (crate-source "windows_i686_gnullvm" "0.53.0"
                "04df1in2k91qyf1wzizvh560bvyzq20yf68k8xa66vdzxnywrrlw"))

(define rust-windows-i686-msvc-0.42.2
  (crate-source "windows_i686_msvc" "0.42.2"
                "0q0h9m2aq1pygc199pa5jgc952qhcnf0zn688454i7v4xjv41n24"))

(define rust-windows-i686-msvc-0.52.6
  (crate-source "windows_i686_msvc" "0.52.6"
                "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294"))

(define rust-windows-i686-msvc-0.53.0
  (crate-source "windows_i686_msvc" "0.53.0"
                "0pcvb25fkvqnp91z25qr5x61wyya12lx8p7nsa137cbb82ayw7sq"))

(define rust-windows-x86-64-gnu-0.42.2
  (crate-source "windows_x86_64_gnu" "0.42.2"
                "0dnbf2xnp3xrvy8v9mgs3var4zq9v9yh9kv79035rdgyp2w15scd"))

(define rust-windows-x86-64-gnu-0.52.6
  (crate-source "windows_x86_64_gnu" "0.52.6"
                "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl"))

(define rust-windows-x86-64-gnu-0.53.0
  (crate-source "windows_x86_64_gnu" "0.53.0"
                "1flh84xkssn1n6m1riddipydcksp2pdl45vdf70jygx3ksnbam9f"))

(define rust-windows-x86-64-gnullvm-0.42.2
  (crate-source "windows_x86_64_gnullvm" "0.42.2"
                "18wl9r8qbsl475j39zvawlidp1bsbinliwfymr43fibdld31pm16"))

(define rust-windows-x86-64-gnullvm-0.52.6
  (crate-source "windows_x86_64_gnullvm" "0.52.6"
                "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94"))

(define rust-windows-x86-64-gnullvm-0.53.0
  (crate-source "windows_x86_64_gnullvm" "0.53.0"
                "0mvc8119xpbi3q2m6mrjcdzl6afx4wffacp13v76g4jrs1fh6vha"))

(define rust-windows-x86-64-msvc-0.42.2
  (crate-source "windows_x86_64_msvc" "0.42.2"
                "1w5r0q0yzx827d10dpjza2ww0j8iajqhmb54s735hhaj66imvv4s"))

(define rust-windows-x86-64-msvc-0.52.6
  (crate-source "windows_x86_64_msvc" "0.52.6"
                "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq"))

(define rust-windows-x86-64-msvc-0.53.0
  (crate-source "windows_x86_64_msvc" "0.53.0"
                "11h4i28hq0zlnjcaqi2xdxr7ibnpa8djfggch9rki1zzb8qi8517"))

(define rust-winnow-0.7.10
  (crate-source "winnow" "0.7.10"
                "1v69byry8fyarzl83wij6f1h3zxnw69assp9kdfb10cdfk42hsf0"))

(define rust-winsafe-0.0.19
  (crate-source "winsafe" "0.0.19"
                "0169xy9mjma8dys4m8v4x0xhw2gkbhv2v1wsbvcjl9bhnxxd2dfi"))

(define rust-wit-bindgen-0.51.0
  (crate-source "wit-bindgen" "0.51.0"
                "19fazgch8sq5cvjv3ynhhfh5d5x08jq2pkw8jfb05vbcyqcr496p"))

(define rust-wit-bindgen-core-0.51.0
  (crate-source "wit-bindgen-core" "0.51.0"
                "1p2jszqsqbx8k7y8nwvxg65wqzxjm048ba5phaq8r9iy9ildwqga"))

(define rust-wit-bindgen-rt-0.39.0
  (crate-source "wit-bindgen-rt" "0.39.0"
                "1hd65pa5hp0nl664m94bg554h4zlhrzmkjsf6lsgsb7yc4734hkg"))

(define rust-wit-bindgen-rust-0.51.0
  (crate-source "wit-bindgen-rust" "0.51.0"
                "08bzn5fsvkb9x9wyvyx98qglknj2075xk1n7c5jxv15jykh6didp"))

(define rust-wit-bindgen-rust-macro-0.51.0
  (crate-source "wit-bindgen-rust-macro" "0.51.0"
                "0ymizapzv2id89igxsz2n587y2hlfypf6n8kyp68x976fzyrn3qc"))

(define rust-wit-component-0.244.0
  (crate-source "wit-component" "0.244.0"
                "1clwxgsgdns3zj2fqnrjcp8y5gazwfa1k0sy5cbk0fsmx4hflrlx"))

(define rust-wit-parser-0.244.0
  (crate-source "wit-parser" "0.244.0"
                "0dm7avvdxryxd5b02l0g5h6933z1cw5z0d4wynvq2cywq55srj7c"))

(define rust-writeable-0.6.1
  (crate-source "writeable" "0.6.1"
                "1fx29zncvbrqzgz7li88vzdm8zvgwgwy2r9bnjqxya09pfwi0bza"))

(define rust-xmlwriter-0.1.0
  (crate-source "xmlwriter" "0.1.0"
                "1fg0ldmkgiis6hnxpi1c9gy7v23y0lpi824bp8yp12fi3r82lypc"))

(define rust-y4m-0.8.0
  (crate-source "y4m" "0.8.0"
                "0j24y2zf60lpxwd7kyg737hqfyqx16y32s0fjyi6fax6w4hlnnks"))

(define rust-yaml-rust-0.4.5
  (crate-source "yaml-rust" "0.4.5"
                "118wbqrr4n6wgk5rjjnlrdlahawlxc1bdsx146mwk8f79in97han"))

(define rust-yoke-0.8.0
  (crate-source "yoke" "0.8.0"
                "1k4mfr48vgi7wh066y11b7v1ilakghlnlhw9snzz8vi2p00vnhaz"))

(define rust-yoke-derive-0.8.0
  (crate-source "yoke-derive" "0.8.0"
                "1dha5jrjz9jaq8kmxq1aag86b98zbnm9lyjrihy5sv716sbkrniq"))

(define rust-zerocopy-0.8.40
  (crate-source "zerocopy" "0.8.40"
                "1r9j2mlb54q1l9pgall3mk0gg6cprhdncvbbgsgxnxmmj3jcd2d7"))

(define rust-zerocopy-derive-0.8.40
  (crate-source "zerocopy-derive" "0.8.40"
                "0lsrhg5nvf0c40z644a014l2nrvh7xw0ff3i9744k9vif2d4hp7n"))

(define rust-zerofrom-0.1.6
  (crate-source "zerofrom" "0.1.6"
                "19dyky67zkjichsb7ykhv0aqws3q0jfvzww76l66c19y6gh45k2h"))

(define rust-zerofrom-derive-0.1.6
  (crate-source "zerofrom-derive" "0.1.6"
                "00l5niw7c1b0lf1vhvajpjmcnbdp2vn96jg4nmkhq2db0rp5s7np"))

(define rust-zeroize-1.8.1
  (crate-source "zeroize" "1.8.1"
                "1pjdrmjwmszpxfd7r860jx54cyk94qk59x13sc307cvr5256glyf"))

(define rust-zerotrie-0.2.2
  (crate-source "zerotrie" "0.2.2"
                "15gmka7vw5k0d24s0vxgymr2j6zn2iwl12wpmpnpjgsqg3abpw1n"))

(define rust-zerovec-0.11.2
  (crate-source "zerovec" "0.11.2"
                "0a2457fmz39k9vrrj3rm82q5ykdhgxgbwfz2r6fa6nq11q4fn1aa"))

(define rust-zerovec-derive-0.11.1
  (crate-source "zerovec-derive" "0.11.1"
                "13zms8hj7vzpfswypwggyfr4ckmyc7v3di49pmj8r1qcz9z275jv"))

(define rust-zmij-1.0.17
  (crate-source "zmij" "1.0.17"
                "0fc4x3gh0pjcq6vgpiz2zz5pw7bpx5ir71vffyagrak97zwf1ah2"))

(define rust-zune-core-0.5.1
  (crate-source "zune-core" "0.5.1"
                "1ya0zdqxlr5v57791j7bvm408ri2cfx81a4v6z85f560yw3hi2nb"))

(define rust-zune-inflate-0.2.54
  (crate-source "zune-inflate" "0.2.54"
                "00kg24jh3zqa3i6rg6yksnb71bch9yi1casqydl00s7nw8pk7avk"))

(define rust-zune-jpeg-0.5.12
  (crate-source "zune-jpeg" "0.5.12"
                "1zipxj775zwgnvarcx66w7x688f3v6wgsb0whgihkirlyv79w3j1"))


;; END LOCKFILE CRATE SOURCES

;; BEGIN LOCKFILE CARGO INPUTS
+(define blightmud-cargo-inputs
  (list
   rust-addr2line-0.25.1
   rust-adler2-2.0.0
   rust-aho-corasick-1.1.3
   rust-aligned-0.4.3
   rust-aligned-vec-0.6.4
   rust-alsa-0.11.0
   rust-alsa-sys-0.4.0
   rust-android-system-properties-0.1.5
   rust-anstream-1.0.0
   rust-anstyle-1.0.14
   rust-anstyle-parse-1.0.0
   rust-anstyle-query-1.1.3
   rust-anstyle-wincon-3.0.9
   rust-anyhow-1.0.102
   rust-arbitrary-1.4.2
   rust-arg-enum-proc-macro-0.3.4
   rust-arrayref-0.3.9
   rust-arrayvec-0.7.6
   rust-as-slice-0.2.1
   rust-autocfg-1.4.0
   rust-av-scenechange-0.14.1
   rust-av1-grain-0.2.5
   rust-avif-serialize-0.8.8
   rust-backtrace-0.3.76
   rust-base64-0.22.1
   rust-bincode-1.3.3
   rust-bindgen-0.61.0
   rust-bindgen-0.71.1
   rust-bit-set-0.8.0
   rust-bit-vec-0.8.0
   rust-bit-field-0.10.3
   rust-bitflags-1.3.2
   rust-bitflags-2.11.0
   rust-bitstream-io-4.9.0
   rust-block-0.1.6
   rust-block2-0.6.2
   rust-bstr-1.12.0
   rust-built-0.8.0
   rust-bumpalo-3.18.1
   rust-bytemuck-1.25.0
   rust-byteorder-lite-0.1.0
   rust-bytes-1.11.1
   rust-cc-1.2.26
   rust-cesu8-1.1.0
   rust-cexpr-0.6.0
   rust-cfg-if-1.0.0
   rust-cfg-aliases-0.2.1
   rust-chacha20-0.10.0
   rust-chrono-0.4.44
   rust-clang-sys-1.8.1
   rust-cocoa-foundation-0.1.2
   rust-color-quant-1.1.0
   rust-colorchoice-1.0.4
   rust-combine-4.6.7
   rust-console-0.16.3
   rust-core-foundation-0.9.4
   rust-core-foundation-sys-0.8.7
   rust-core-graphics-types-0.1.3
   rust-core2-0.4.0
   rust-core-maths-0.1.1
   rust-coreaudio-rs-0.14.0
   rust-cpal-0.17.3
   rust-cpufeatures-0.3.0
   rust-crc32fast-1.4.2
   rust-crossbeam-deque-0.8.6
   rust-crossbeam-epoch-0.9.18
   rust-crossbeam-utils-0.8.21
   rust-crunchy-0.2.4
   rust-dasp-sample-0.11.0
   rust-data-url-0.3.2
   rust-deranged-0.5.5
   rust-dispatch2-0.3.0
   rust-displaydoc-0.2.5
   rust-downcast-0.11.0
   rust-dyn-clonable-0.9.2
   rust-dyn-clonable-impl-0.9.2
   rust-dyn-clone-1.0.19
   rust-either-1.15.0
   rust-encode-unicode-1.0.0
   rust-encoding-rs-0.8.35
   rust-env-filter-1.0.0
   rust-env-home-0.1.0
   rust-env-logger-0.11.10
   rust-equator-0.4.2
   rust-equator-macro-0.4.2
   rust-equivalent-1.0.2
   rust-errno-0.3.12
   rust-euclid-0.22.13
   rust-exr-1.74.0
   rust-extended-0.1.0
   rust-fancy-regex-0.16.2
   rust-fastrand-2.3.0
   rust-fax-0.2.6
   rust-fax-derive-0.2.0
   rust-fdeflate-0.3.7
   rust-filetime-0.2.25
   rust-flate2-1.1.9
   rust-float-cmp-0.9.0
   rust-fnv-1.0.7
   rust-foldhash-0.1.5
   rust-fontconfig-parser-0.5.8
   rust-fontdb-0.23.0
   rust-form-urlencoded-1.2.1
   rust-fragile-2.0.1
   rust-fsevent-sys-4.1.0
   rust-futures-channel-0.3.31
   rust-futures-core-0.3.31
   rust-futures-io-0.3.31
   rust-futures-sink-0.3.31
   rust-futures-task-0.3.31
   rust-futures-util-0.3.31
   rust-gethostname-1.1.0
   rust-getopts-0.2.24
   rust-getrandom-0.2.16
   rust-getrandom-0.3.3
   rust-getrandom-0.4.1
   rust-gif-0.14.1
   rust-gimli-0.32.3
   rust-git2-0.21.0
   rust-glob-0.3.3
   rust-half-2.7.1
   rust-hashbrown-0.15.4
   rust-heck-0.5.0
   rust-home-0.5.11
   rust-http-1.3.1
   rust-http-body-1.0.1
   rust-http-body-util-0.1.3
   rust-httparse-1.10.1
   rust-human-panic-2.0.8
   rust-hunspell-rs-0.4.0
   rust-hunspell-sys-0.3.1
   rust-hyper-1.6.0
   rust-hyper-rustls-0.27.7
   rust-hyper-util-0.1.14
   rust-iana-time-zone-0.1.63
   rust-iana-time-zone-haiku-0.1.2
   rust-icu-collections-2.0.0
   rust-icu-locale-core-2.0.0
   rust-icu-normalizer-2.0.0
   rust-icu-normalizer-data-2.0.0
   rust-icu-properties-2.0.1
   rust-icu-properties-data-2.0.1
   rust-icu-provider-2.0.0
   rust-id-arena-2.3.0
   rust-idna-1.0.3
   rust-idna-adapter-1.2.1
   rust-image-0.25.10
   rust-image-webp-0.2.4
   rust-imagesize-0.14.0
   rust-imgref-1.12.0
   rust-indexmap-2.9.0
   rust-inotify-0.11.0
   rust-inotify-sys-0.1.5
   rust-insta-1.47.2
   rust-interpolate-name-0.2.4
   rust-ipnet-2.11.0
   rust-iri-string-0.7.8
   rust-is-terminal-polyfill-1.70.1
   rust-itertools-0.13.0
   rust-itertools-0.14.0
   rust-itoa-1.0.15
   rust-jiff-0.2.23
   rust-jiff-static-0.2.23
   rust-jni-0.21.1
   rust-jni-sys-0.3.0
   rust-jobserver-0.1.33
   rust-js-sys-0.3.77
   rust-kqueue-1.1.1
   rust-kqueue-sys-1.0.4
   rust-kurbo-0.13.0
   rust-lazy-static-1.5.0
   rust-lazycell-1.3.0
   rust-leb128fmt-0.1.0
   rust-lebe-0.5.3
   rust-libc-0.2.183
   rust-libfuzzer-sys-0.4.12
   rust-libgit2-sys-0.18.4+1.9.3
   rust-libloading-0.8.8
   rust-libm-0.2.16
   rust-libmudtelnet-2.0.2
   rust-libredox-0.1.3
   rust-libz-sys-1.1.22
   rust-linked-hash-map-0.5.6
   rust-linux-raw-sys-0.4.15
   rust-linux-raw-sys-0.12.1
   rust-litemap-0.8.0
   rust-lock-api-0.4.13
   rust-log-0.4.30
   rust-loop9-0.1.5
   rust-lru-slab-0.1.2
   rust-lua-src-550.0.0
   rust-luajit-src-210.6.1+f9140a6
   rust-mach2-0.5.0
   rust-malloc-buf-0.0.6
   rust-maybe-rayon-0.1.1
   rust-memchr-2.7.4
   rust-memmap2-0.9.10
   rust-mime-0.3.17
   rust-minimal-lexical-0.2.1
   rust-miniz-oxide-0.8.8
   rust-mio-1.2.0
   rust-mlua-0.11.6
   rust-mlua-sys-0.10.0
   rust-mlua-derive-0.11.0
   rust-mockall-0.14.0
   rust-mockall-derive-0.14.0
   rust-mockall-double-0.3.1
   rust-moxcms-0.8.1
   rust-ndk-0.9.0
   rust-ndk-context-0.1.1
   rust-ndk-sys-0.6.0+11769913
   rust-new-debug-unreachable-1.0.6
   rust-nom-7.1.3
   rust-nom-8.0.0
   rust-noop-proc-macro-0.3.0
   rust-notify-8.0.0
   rust-notify-debouncer-mini-0.6.0
   rust-notify-types-2.0.0
   rust-ntapi-0.4.2
   rust-num-bigint-0.4.6
   rust-num-conv-0.2.0
   rust-num-derive-0.4.2
   rust-num-integer-0.1.46
   rust-num-rational-0.4.2
   rust-num-traits-0.2.19
   rust-num-enum-0.7.3
   rust-num-enum-derive-0.7.3
   rust-numtoa-0.2.4
   rust-objc-0.2.7
   rust-objc2-0.6.2
   rust-objc2-audio-toolbox-0.3.1
   rust-objc2-avf-audio-0.3.1
   rust-objc2-core-audio-0.3.1
   rust-objc2-core-audio-types-0.3.1
   rust-objc2-core-foundation-0.3.2
   rust-objc2-encode-4.1.0
   rust-objc2-foundation-0.3.1
   rust-objc2-io-kit-0.3.2
   rust-objc-exception-0.1.2
   rust-object-0.37.3
   rust-once-cell-1.21.3
   rust-once-cell-polyfill-1.70.1
   rust-onig-6.5.1
   rust-onig-sys-69.9.1
   rust-oxilangtag-0.1.5
   rust-parking-lot-0.12.4
   rust-parking-lot-core-0.9.11
   rust-paste-1.0.15
   rust-pastey-0.1.1
   rust-peeking-take-while-0.1.2
   rust-percent-encoding-2.3.1
   rust-pico-args-0.5.0
   rust-pin-project-lite-0.2.16
   rust-pin-utils-0.1.0
   rust-pkg-config-0.3.32
   rust-plist-1.7.1
   rust-png-0.18.1
   rust-portable-atomic-1.11.1
   rust-portable-atomic-util-0.2.4
   rust-potential-utf-0.1.2
   rust-powerfmt-0.2.0
   rust-ppv-lite86-0.2.21
   rust-predicates-3.1.3
   rust-predicates-core-1.0.9
   rust-predicates-tree-1.0.12
   rust-prettyplease-0.2.33
   rust-proc-macro-crate-3.3.0
   rust-proc-macro-error-attr2-2.0.0
   rust-proc-macro-error2-2.0.1
   rust-proc-macro2-1.0.95
   rust-profiling-1.0.17
   rust-profiling-procmacros-1.0.17
   rust-pulldown-cmark-0.13.4
   rust-pulldown-cmark-escape-0.11.0
   rust-pxfm-0.1.28
   rust-qoi-0.4.1
   rust-quick-error-2.0.1
   rust-quick-xml-0.32.0
   rust-quinn-0.11.8
   rust-quinn-proto-0.11.14
   rust-quinn-udp-0.5.12
   rust-quote-1.0.40
   rust-r-efi-5.2.0
   rust-rand-0.9.4
   rust-rand-0.10.0
   rust-rand-chacha-0.9.0
   rust-rand-core-0.9.3
   rust-rand-core-0.10.0
   rust-rand-distr-0.6.0
   rust-rav1e-0.8.1
   rust-ravif-0.13.0
   rust-rayon-1.11.0
   rust-rayon-core-1.13.0
   rust-redox-syscall-0.1.57
   rust-redox-syscall-0.5.12
   rust-regex-1.12.3
   rust-regex-automata-0.4.13
   rust-regex-syntax-0.8.5
   rust-reqwest-0.12.28
   rust-resvg-0.47.0
   rust-rgb-0.8.53
   rust-ring-0.17.14
   rust-rodio-0.22.2
   rust-ron-0.12.1
   rust-roxmltree-0.20.0
   rust-roxmltree-0.21.1
   rust-rs-complete-1.3.1
   rust-rtrb-0.3.2
   rust-rustc-demangle-0.1.24
   rust-rustc-hash-1.1.0
   rust-rustc-hash-2.1.1
   rust-rustix-0.38.44
   rust-rustix-1.1.4
   rust-rustls-0.23.40
   rust-rustls-pemfile-2.2.0
   rust-rustls-pki-types-1.12.0
   rust-rustls-webpki-0.103.13
   rust-rustversion-1.0.21
   rust-rustybuzz-0.20.1
   rust-ryu-1.0.20
   rust-same-file-1.0.6
   rust-scopeguard-1.2.0
   rust-semver-1.0.27
   rust-serde-1.0.228
   rust-serde-core-1.0.228
   rust-serde-derive-1.0.228
   rust-serde-json-1.0.150
   rust-serde-spanned-1.1.1
   rust-serde-urlencoded-0.7.1
   rust-shlex-1.3.0
   rust-signal-hook-0.4.4
   rust-signal-hook-registry-1.4.5
   rust-simd-adler32-0.3.7
   rust-simd-helpers-0.1.0
   rust-similar-2.7.0
   rust-similar-3.0.0
   rust-similar-asserts-2.0.0
   rust-simple-logging-2.0.2
   rust-simplecss-0.2.2
   rust-siphasher-1.0.2
   rust-slab-0.4.9
   rust-slotmap-1.1.1
   rust-smallvec-1.15.1
   rust-socket2-0.5.10
   rust-socket2-0.6.3
   rust-speech-dispatcher-0.16.0
   rust-speech-dispatcher-sys-0.7.0
   rust-stable-deref-trait-1.2.0
   rust-strict-num-0.1.1
   rust-strip-ansi-escapes-0.2.1
   rust-subtle-2.6.1
   rust-svgtypes-0.16.1
   rust-symphonia-0.5.5
   rust-symphonia-bundle-flac-0.5.5
   rust-symphonia-bundle-mp3-0.5.5
   rust-symphonia-codec-aac-0.5.5
   rust-symphonia-codec-pcm-0.5.5
   rust-symphonia-codec-vorbis-0.5.5
   rust-symphonia-core-0.5.5
   rust-symphonia-format-isomp4-0.5.5
   rust-symphonia-format-ogg-0.5.5
   rust-symphonia-format-riff-0.5.5
   rust-symphonia-metadata-0.5.5
   rust-symphonia-utils-xiph-0.5.5
   rust-syn-1.0.109
   rust-syn-2.0.101
   rust-sync-wrapper-1.0.2
   rust-synstructure-0.13.2
   rust-syntect-5.3.0
   rust-sysinfo-0.38.4
   rust-temp-env-0.3.6
   rust-tempfile-3.20.0
   rust-terminal-size-0.4.4
   rust-termion-4.0.6
   rust-termtree-0.5.1
   rust-textwrap-0.16.2
   rust-thiserror-1.0.69
   rust-thiserror-2.0.12
   rust-thiserror-impl-1.0.69
   rust-thiserror-impl-2.0.12
   rust-thread-id-3.3.0
   rust-tiff-0.11.3
   rust-time-0.3.47
   rust-time-core-0.1.8
   rust-time-macros-0.2.27
   rust-timer-0.2.0
   rust-tiny-skia-0.12.0
   rust-tiny-skia-path-0.12.0
   rust-tinystr-0.8.1
   rust-tinyvec-1.9.0
   rust-tinyvec-macros-0.1.1
   rust-tokio-1.45.1
   rust-tokio-rustls-0.26.2
   rust-toml-1.1.1+spec-1.1.0
   rust-toml-datetime-0.6.11
   rust-toml-datetime-1.1.1+spec-1.1.0
   rust-toml-edit-0.22.27
   rust-toml-writer-1.1.1+spec-1.1.0
   rust-tower-0.5.2
   rust-tower-http-0.6.8
   rust-tower-layer-0.3.3
   rust-tower-service-0.3.3
   rust-tracing-0.1.44
   rust-tracing-attributes-0.1.31
   rust-tracing-core-0.1.36
   rust-try-lock-0.2.5
   rust-ttf-parser-0.25.1
   rust-tts-0.26.3
   rust-typeid-1.0.3
   rust-unicase-2.8.1
   rust-unicode-bidi-0.3.18
   rust-unicode-bidi-mirroring-0.4.0
   rust-unicode-ccc-0.4.0
   rust-unicode-ident-1.0.18
   rust-unicode-linebreak-0.1.5
   rust-unicode-properties-0.1.4
   rust-unicode-script-0.5.8
   rust-unicode-segmentation-1.12.0
   rust-unicode-vo-0.1.0
   rust-unicode-width-0.2.2
   rust-unicode-xid-0.2.6
   rust-untrusted-0.9.0
   rust-url-2.5.4
   rust-usvg-0.47.0
   rust-utf8-iter-1.0.4
   rust-utf8parse-0.2.2
   rust-uuid-1.23.0
   rust-v-frame-0.3.9
   rust-vcpkg-0.2.15
   rust-version-check-0.9.5
   rust-vte-0.14.1
   rust-vte-0.15.0
   rust-walkdir-2.5.0
   rust-want-0.3.1
   rust-wasi-0.11.0+wasi-snapshot-preview1
   rust-wasi-0.14.2+wasi-0.2.4
   rust-wasip2-1.0.2+wasi-0.2.9
   rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
   rust-wasm-bindgen-0.2.100
   rust-wasm-bindgen-backend-0.2.100
   rust-wasm-bindgen-futures-0.4.50
   rust-wasm-bindgen-macro-0.2.100
   rust-wasm-bindgen-macro-support-0.2.100
   rust-wasm-bindgen-shared-0.2.100
   rust-wasm-encoder-0.244.0
   rust-wasm-metadata-0.244.0
   rust-wasmparser-0.244.0
   rust-web-sys-0.3.77
   rust-web-time-1.1.0
   rust-webpki-roots-1.0.7
   rust-weezl-0.1.12
   rust-which-4.4.2
   rust-which-7.0.3
   rust-winapi-0.3.9
   rust-winapi-i686-pc-windows-gnu-0.4.0
   rust-winapi-util-0.1.9
   rust-winapi-x86-64-pc-windows-gnu-0.4.0
   rust-windows-0.58.0
   rust-windows-0.62.2
   rust-windows-collections-0.3.2
   rust-windows-core-0.58.0
   rust-windows-core-0.61.2
   rust-windows-core-0.62.2
   rust-windows-future-0.3.2
   rust-windows-implement-0.58.0
   rust-windows-implement-0.60.2
   rust-windows-interface-0.58.0
   rust-windows-interface-0.59.3
   rust-windows-link-0.1.3
   rust-windows-link-0.2.1
   rust-windows-numerics-0.3.1
   rust-windows-result-0.2.0
   rust-windows-result-0.3.4
   rust-windows-result-0.4.1
   rust-windows-strings-0.1.0
   rust-windows-strings-0.4.2
   rust-windows-strings-0.5.1
   rust-windows-sys-0.45.0
   rust-windows-sys-0.52.0
   rust-windows-sys-0.59.0
   rust-windows-sys-0.61.1
   rust-windows-targets-0.42.2
   rust-windows-targets-0.52.6
   rust-windows-targets-0.53.0
   rust-windows-threading-0.2.1
   rust-windows-aarch64-gnullvm-0.42.2
   rust-windows-aarch64-gnullvm-0.52.6
   rust-windows-aarch64-gnullvm-0.53.0
   rust-windows-aarch64-msvc-0.42.2
   rust-windows-aarch64-msvc-0.52.6
   rust-windows-aarch64-msvc-0.53.0
   rust-windows-i686-gnu-0.42.2
   rust-windows-i686-gnu-0.52.6
   rust-windows-i686-gnu-0.53.0
   rust-windows-i686-gnullvm-0.52.6
   rust-windows-i686-gnullvm-0.53.0
   rust-windows-i686-msvc-0.42.2
   rust-windows-i686-msvc-0.52.6
   rust-windows-i686-msvc-0.53.0
   rust-windows-x86-64-gnu-0.42.2
   rust-windows-x86-64-gnu-0.52.6
   rust-windows-x86-64-gnu-0.53.0
   rust-windows-x86-64-gnullvm-0.42.2
   rust-windows-x86-64-gnullvm-0.52.6
   rust-windows-x86-64-gnullvm-0.53.0
   rust-windows-x86-64-msvc-0.42.2
   rust-windows-x86-64-msvc-0.52.6
   rust-windows-x86-64-msvc-0.53.0
   rust-winnow-0.7.10
   rust-winsafe-0.0.19
   rust-wit-bindgen-0.51.0
   rust-wit-bindgen-core-0.51.0
   rust-wit-bindgen-rt-0.39.0
   rust-wit-bindgen-rust-0.51.0
   rust-wit-bindgen-rust-macro-0.51.0
   rust-wit-component-0.244.0
   rust-wit-parser-0.244.0
   rust-writeable-0.6.1
   rust-xmlwriter-0.1.0
   rust-y4m-0.8.0
   rust-yaml-rust-0.4.5
   rust-yoke-0.8.0
   rust-yoke-derive-0.8.0
   rust-zerocopy-0.8.40
   rust-zerocopy-derive-0.8.40
   rust-zerofrom-0.1.6
   rust-zerofrom-derive-0.1.6
   rust-zeroize-1.8.1
   rust-zerotrie-0.2.2
   rust-zerovec-0.11.2
   rust-zerovec-derive-0.11.1
   rust-zmij-1.0.17
   rust-zune-core-0.5.1
   rust-zune-inflate-0.2.54
   rust-zune-jpeg-0.5.12))
;; END LOCKFILE CARGO INPUTS

(define-public blightmud
  (package
    (name "blightmud")
    (version "5.7.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Blightmud/Blightmud")
             ;; The v5.7.1 tag was reviewed at this full commit.  Pinning
             ;; the object, rather than resolving a tag during a build, keeps
             ;; the source identity immutable.
             (commit %blightmud-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0g43amhvv7kqrhprblpn0sx3dijhhcpa5b9fcji9r0fhxw573mgh"))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; A terminal MUD client remains useful with Lua, Telnet, MCCP2, GMCP,
      ;; MSDP, and rustls TLS.  Audio/ALSA, native TTS, and bundled Hunspell
      ;; are optional upstream features and are deliberately not built: they
      ;; add platform-specific native code and, for spellchecking, no useful
      ;; Guix-managed dictionary.  Lua's pinned vendored C implementation is
      ;; retained because scripting is a core client function.
      #:install-source? #f
      ;; Cargo.lock contains time 0.3.47 and therefore requires Rust 1.88 or
      ;; newer.  Do not weaken that upstream requirement: use a current Guix
      ;; revision for this package rather than silently compiling a different
      ;; dependency graph or bypassing Cargo's MSRV guard.
      #:cargo-build-flags ''("--release" "--locked" "--no-default-features")
      #:cargo-test-flags ''("--locked" "--no-default-features")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'save-locked-cargo-graph
            (lambda _
              ;; The cargo configure phase normally deletes Cargo.lock.
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-after 'unpack 'make-release-build-hermetic
            (lambda _
              ;; git-fetch intentionally excludes .git.  Upstream's build
              ;; script otherwise probes a build host Git checkout and emits
              ;; an unstable fallback version.  Set the reviewed tag and
              ;; commit directly instead.
              (call-with-output-file "build.rs"
                (lambda (port)
                  (for-each (lambda (line) (display line port))
                            '("fn main() {\n"
                              "  println!(\"cargo:rustc-env=GIT_HASH=653a833\");\n"
                              "  println!(\"cargo:rustc-env=GIT_TAG=v5.7.1\");\n"
                              "  println!(\"cargo:rustc-env=CARGO_PKG_VERSION=5.7.1\");\n"
                              "  println!(\"cargo:rustc-env=GIT_DESCRIBE=\");\n"
                              "}\n"))))
              ;; The package manager, rather than the program, manages
              ;; upgrades.  This removes the otherwise automatic GitHub API
              ;; request at every startup; plugin cloning/updating stays an
              ;; explicit user Lua action in the user data directory.  Remove
              ;; both the call and its import, rather than merely changing a
              ;; condition, so an upstream control-flow refactor fails the
              ;; assertion below instead of reintroducing a request.
              (substitute* "src/lib.rs"
                (("use net::\\{check_latest_version, WakingSender\\};")
                 "use net::WakingSender;")
                (("check_latest_version\\(session\\.main_writer\\.clone\\(\\)\\);")
                 "info!(\"Package-managed update check disabled\");"))
              ;; Blightmud's compiled default roots are deliberately useful
              ;; for normal operation.  Honor SSL_CERT_FILE as an additive
              ;; per-user trust anchor so private MUD CAs can be verified
              ;; without weakening verification or modifying the store.
              (substitute* "Cargo.toml"
                (("webpki-roots = \"1\\.0\"")
                 "webpki-roots = \"1.0\"\nrustls-pemfile = \"2.2\"")
                (("\\[dev-dependencies\\]\nrustls-pemfile = \"2\\.2\"\n")
                 "[dev-dependencies]\n"))
              (substitute* "src/net/tls.rs"
                (("use std::sync::Arc;")
                 "use std::sync::Arc;\nuse std::fs::File;")
                (("    create_tls_connection_with_roots[(]host, validation,\
 default_root_certs[()][)][)]")
                 "    create_tls_connection_with_roots(host, validation,\
 user_root_certs(default_root_certs()))")
                (("/// here be dragons\\.")
                 (string-append
                  "fn user_root_certs(mut roots: RootCertStore) -> RootCertStore {\n"
                  "    if let Ok(path) = std::env::var(\"SSL_CERT_FILE\") {\n"
                  "        if let Ok(file) = File::open(path) {\n"
                  "            let mut reader = std::io::BufReader::new(file);\n"
                  "            for certificate in "
                  "rustls_pemfile::certs(&mut reader).flatten() {\n"
                  "                let _ = roots.add(certificate);\n"
                  "            }\n        }\n    }\n    roots\n}\n\n"
                  "/// here be dragons.")))
              (use-modules (ice-9 textual-ports))
              (let ((lib (call-with-input-file "src/lib.rs" get-string-all))
                    (manifest (call-with-input-file "Cargo.toml" get-string-all))
                    (tls (call-with-input-file "src/net/tls.rs" get-string-all)))
                (unless (not (string-contains lib "check_latest_version"))
                  (error "Blightmud update-call removal did not apply"))
                (unless (string-contains lib "Package-managed update check disabled")
                  (error "Blightmud update-removal diagnostic did not apply"))
                (unless (string-contains manifest "rustls-pemfile = \"2.2\"")
                  (error "Blightmud private-CA Cargo dependency patch did not apply"))
                (unless (and (string-contains tls "SSL_CERT_FILE")
                             (string-contains tls
                                              "user_root_certs(default_root_certs())"))
                  (error "Blightmud private-CA TLS patch did not apply")))))
          (add-after 'check-for-pregenerated-files
              'restore-locked-offline-cargo-graph
            (lambda _
              (use-modules (guix build cargo-utils))
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; cargo-build-system normally removes Cargo.lock.  Retain the
              ;; exact reviewed graph and generate vendor manifests before
              ;; Cargo reads it.  Registry checksums do not apply to directory
              ;; sources, so strip only those lockfile lines after vendoring.
              (generate-all-checksums "guix-vendor")
              (copy-file ".guix-Cargo.lock" "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*$") ""))))
          (delete 'install)
          (add-after 'check 'install-blightmud
            (lambda* (#:key outputs #:allow-other-keys)
              (invoke "cargo" "install" "--offline" "--locked" "--no-track"
                      "--path" "." "--no-default-features"
                      "--root" (assoc-ref outputs "out"))))
          (add-after 'install-blightmud 'install-license-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((doc (string-append (assoc-ref outputs "out")
                                         "/share/doc/blightmud"))
                     (third-party (string-append doc "/third-party-licenses")))
                ;; GPL-3.0-only application notice plus every matching
                ;; license/notice artifact in the exact vendored Cargo graph.
                ;; This includes native sources (vendored Lua, ring and
                ;; libgit2); optional audio, TTS and Hunspell sources are
                ;; retained as locked source inputs but not compiled.
                (mkdir-p doc)
                (install-file "LICENSE" doc)
                (for-each
                 (lambda (file)
                   (let ((destination
                          (string-append third-party "/"
                                         (basename (dirname file)))))
                     (mkdir-p destination)
                     (install-file file destination)))
                 (find-files
                  "guix-vendor"
                  (string-append
                   "(^|/)([Ll][Ii][Cc][Ee][Nn][Ss][Ee]|[Ll][Ii][Cc][Ee][Nn][Cc][Ee]|"
                   "[Cc][Oo][Pp][Yy][Ii][Nn][Gg]|[Nn][Oo][Tt][Ii][Cc][Ee]|"
                   "[Cc][Oo][Pp][Yy][Rr][Ii][Gg][Hh][Tt]|"
                   "[Uu][Nn][Ll][Ii][Cc][Ee][Nn][Ss][Ee])([-._].*)?$")))))))))
    ;; Oniguruma is required by syntect's onig_sys highlighter binding; its
    ;; build script deliberately requires the system library.  OpenSSL is used
    ;; by libgit2 for explicit plugin fetches.  The selected
    ;; Rustls client uses its reviewed, statically linked ring backend for MUD
    ;; TLS; no network access is permitted while building.
    (native-inputs (list pkg-config))
    (inputs (cons* libgit2 %blightmud-oniguruma openssl zlib blightmud-cargo-inputs))
    (synopsis "Terminal MUD client with Lua scripting and secure TLS")
    (description
     "Blightmud is a terminal client for MUDs with Telnet, MCCP2 compression,
GMCP, MSDP, Lua scripts, aliases, triggers, timers, and persistent per-user
state.  This package builds the immutable v5.7.1 tag and complete Cargo.lock
graph offline.  Lua, protocol handling, and rustls TLS are enabled.  Audio,
text-to-speech, and bundled Hunspell spellchecking are not enabled in this
initial package policy; they pull in platform-specific native interfaces and
Hunspell has no selected Guix-managed dictionary.

The package patches out Blightmud's automatic release check, so it never
contacts GitHub at startup.  Plugin clone and update operations remain explicit
user actions, and plugins execute as user-provided Lua code only from the
per-user data directory.  Configuration, scripts, plugin checkouts, logs, and
history are created below the user's XDG paths, never in the read-only store.
TLS connections verify the webpki root store by default; @code{--no-verify}
is an explicit upstream-dangerous override and is not exercised by this
package's normal runtime behavior.  @code{SSL_CERT_FILE} may add a per-user
private CA bundle to those compiled roots; unreadable or malformed entries are
ignored rather than weakening verification.  Upstream is GPL-3.0-only; the installed
documentation also preserves license and notice files found in every vendored
locked Cargo source, including sources not compiled by the minimal policy.")
    (home-page "https://github.com/Blightmud/Blightmud")
    (license license:gpl3)))
