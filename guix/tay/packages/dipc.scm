;;; GNU Guix package for doprz/dipc.

(define-module (tay packages dipc)
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages starred-d-h))

;; These are the exact registry sources selected by dipc's Cargo.lock at the
;; reviewed snapshot.  Keeping every locked version available allows the
;; cargo-build-system to vendor and build entirely offline.
(define dipc-cargo-inputs
  (list
   (crate-source "adler" "1.0.2"
                 "1zim79cvzd5yrkzl3nyfx0avijwgk9fqv3yrscdy1cc79ih02qpj")
   (crate-source "allocator-api2" "0.2.21"
                 "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8")
   (crate-source "anstream" "0.3.0"
                 "0wbkjbadikzg2y7kk1gmfpcssgjy00h8ppv8h8mbq6j7a9vrlmwy")
   (crate-source "anstyle" "1.0.0"
                 "0zbazbfqs4mfw93573f61iy8c78vbbv824m3w206bbljpy39mva1")
   (crate-source "anstyle-parse" "0.2.0"
                 "1vjprf080adyxxpls9iwwny3g7irawfns9s2cj9ngq28dqhzsrg7")
   (crate-source "anstyle-query" "1.0.0"
                 "0js9bgpqz21g0p2nm350cba1d0zfyixsma9lhyycic5sw55iv8aw")
   (crate-source "anstyle-wincon" "1.0.0"
                 "1zc8x98wwvnk0z123yhcjzzv9mqxa328p1qq1v3qmpa0lf8q5kab")
   (crate-source "atty" "0.2.14"
                 "1s7yslcs6a28c5vz7jwj63lkfgyx8mx99fdirlhi9lbhhzhrpcyr")
   (crate-source "autocfg" "1.1.0"
                 "1ylp3cb47ylzabimazvbz9ms6ap784zhb6syaz6c1jqpmcmq0s6l")
   (crate-source "bit_field" "0.10.2"
                 "0qav5rpm4hqc33vmf4vc4r0mh51yjx5vmd9zhih26n9yjs3730nw")
   (crate-source "bitflags" "1.3.2"
                 "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy")
   (crate-source "bitflags" "2.10.0"
                 "1lqxwc3625lcjrjm5vygban9v8a6dlxisp1aqylibiaw52si4bl1")
   (crate-source "bumpalo" "3.12.0"
                 "0damxqdgqqzp3zyfwvbrg5hzx39kqgxnxl3yyq3kk4ald0jiw9hd")
   (crate-source "bytemuck" "1.13.1"
                 "1sifp93886b552fwbywmp5f4gysar7z62mhh4y8dh5gxhkkbrzhp")
   (crate-source "byteorder" "1.4.3"
                 "0456lv9xi1a5bcm32arknf33ikv76p3fr9yzki4lb2897p2qkh8l")
   (crate-source "cassowary" "0.3.0"
                 "0lvanj0gsk6pc1chqrh4k5k0vi1rfbgzmsk46dwy3nmrqyw711nz")
   (crate-source "castaway" "0.2.4"
                 "0nn5his5f8q20nkyg1nwb40xc19a08yaj4y76a8q2y3mdsmm3ify")
   (crate-source "cc" "1.0.79"
                 "07x93b8zbf3xc2dggdd460xlk1wg8lxm6yflwddxj8b15030klsh")
   (crate-source "cfg-if" "1.0.0"
                 "1za0vb97n4brpzpv8lsbnzmq5r8f2b0cpqqr0sy8h5bn751xxwds")
   (crate-source "clap" "4.2.2"
                 "0npfnm1n9mx4jndjdjygzha219nyxdra8jr25fqcv8gkma2jv04v")
   (crate-source "clap_builder" "4.2.2"
                 "1dip3qk9wj3a0dlgvfnpkhjfh3f6z4d8wjvsi0w9649jymcai88l")
   (crate-source "clap_derive" "4.2.0"
                 "1i65yn9n1hydvwrimqp9civ67h1iwd9v1y4yi6z7vf6nav6l95iz")
   (crate-source "clap_lex" "0.4.1"
                 "18dyxyc0g5xrazj8k6mdjd8v3fvka8z3b9k8yl13avlczskdabca")
   (crate-source "color_quant" "1.1.0"
                 "12q1n427h2bbmmm1mnglr57jaz2dj9apk0plcxw7nwqiai7qjyrx")
   (crate-source "colorchoice" "1.0.0"
                 "1ix7w85kwvyybwi2jdkl3yva2r2bvdcc3ka2grjfzfgrapqimgxc")
   (crate-source "compact_str" "0.8.1"
                 "0cmgp61hw4fwaakhilwznfgncw2p4wkbvz6dw3i7ibbckh3c8y9v")
   (crate-source "console" "0.15.5"
                 "0q5dwppyn1zsj5h9zjxfzah8l91y7cyw270m6hz7x9vhi6z9zmy3")
   (crate-source "crc32fast" "1.3.2"
                 "03c8f29yx293yf43xar946xbls1g60c207m9drf8ilqhr25vsh5m")
   (crate-source "crossbeam-channel" "0.5.8"
                 "004jz4wxp9k26z657i7rsh9s7586dklx2c5aqf1n3w1dgzvjng53")
   (crate-source "crossbeam-deque" "0.8.3"
                 "1vqczbcild7nczh5z116w8w46z991kpjyw7qxkf24c14apwdcvyf")
   (crate-source "crossbeam-epoch" "0.9.14"
                 "15anryfq33mhxnlw95ajixnzznxays3gpvaas6lraci7hlzmzga6")
   (crate-source "crossbeam-utils" "0.8.15"
                 "0jwq8srmjcwvq9q883k9zyb26qqznaj4jjqdxmvw7xcmrkc3q1iw")
   (crate-source "crossterm" "0.28.1"
                 "1im9vs6fvkql0sr378dfr4wdm1rrkrvr22v4i8byz05k1dd9b7c2")
   (crate-source "crossterm_winapi" "0.9.1"
                 "0axbfb2ykbwbpf1hmxwpawwfs8wvmkcka5m561l7yp36ldi7rpdc")
   (crate-source "crunchy" "0.2.2"
                 "1dx9mypwd5mpfbbajm78xcrg5lirqk7934ik980mmaffg3hdm0bs")
   (crate-source "darling" "0.20.11"
                 "1vmlphlrlw4f50z16p4bc9p5qwdni1ba95qmxfrrmzs6dh8lczzw")
   (crate-source "darling_core" "0.20.11"
                 "0bj1af6xl4ablnqbgn827m43b8fiicgv180749f5cphqdmcvj00d")
   (crate-source "darling_macro" "0.20.11"
                 "1bbfbc2px6sj1pqqq97bgqn6c8xdnb2fmz66f7f40nrqrcybjd7w")
   (crate-source "deltae" "0.3.1"
                 "0lws5fg4gjvm8g60lk8hwy6d34ivsdlaqff8asxbk253q3i13wry")
   (crate-source "either" "1.8.1"
                 "14bdy4qsxlfnm4626z4shwaiffi8l5krzkn7ykki1jgqzsrapjkz")
   (crate-source "encode_unicode" "0.3.6"
                 "07w3vzrhxh9lpjgsg2y5bwzfar2aq35mdznvcp3zjl0ssj7d4mx3")
   (crate-source "equivalent" "1.0.2"
                 "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7")
   (crate-source "errno" "0.3.14"
                 "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir")
   (crate-source "exr" "1.6.3"
                 "1d1mpcd9bk8kag5gyl2ajh5dbqyw7qnnch260ldajh81f8midlmx")
   (crate-source "fdeflate" "0.3.0"
                 "045fyccqx0wbfrh36sgcf79za5qg95vpihmbklj0dvhlqpmbsafk")
   (crate-source "flate2" "1.0.25"
                 "0hg8ih51lx5xkz2zlzpsy1j1xka8gs8vhk2964ppgj5ighwxp8m8")
   (crate-source "flume" "0.10.14"
                 "0xvm1wpzkjvf99jxy9jp3dxw5nipa9blg7j0ngvxj0rl3i2b8mqn")
   (crate-source "fnv" "1.0.7"
                 "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz")
   (crate-source "foldhash" "0.1.5"
                 "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r")
   (crate-source "futures-core" "0.3.28"
                 "137fdxy5amg9zkpa1kqnj7bnha6b94fmddz59w973x96gqxmijjb")
   (crate-source "futures-sink" "0.3.28"
                 "0vkv4frf4c6gm1ag9imjz8d0xvpnn22lkylsls0rffx147zf8fzl")
   (crate-source "getrandom" "0.2.9"
                 "1r6p47dd9f9cgiwlxmksammbfwnhsv5hjkhd0kjsgnzanad1spn8")
   (crate-source "gif" "0.12.0"
                 "0ibhjyrslfv9qm400gp4hd50v9ibva01j4ab9bwiq1aycy9jayc0")
   (crate-source "half" "2.2.1"
                 "1l1gdlzxgm7wc8xl5fxas20kfi1j35iyb7vfjkghbdzijcvazd02")
   (crate-source "hashbrown" "0.12.3"
                 "1268ka4750pyg2pbgsr43f0289l5zah4arir2k4igx5a8c6fg7la")
   (crate-source "hashbrown" "0.15.5"
                 "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj")
   (crate-source "heck" "0.4.1"
                 "1a7mqsnycv5z4z5vnv1k34548jzmc0ajic7c1j8jsaspnhw5ql4m")
   (crate-source "heck" "0.5.0"
                 "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113")
   (crate-source "hermit-abi" "0.1.19"
                 "0cxcm8093nf5fyn114w8vxbrbcyvv91d4015rdnlgfll7cs6gd32")
   (crate-source "hermit-abi" "0.2.6"
                 "1iz439yz9qzk3rh9pqx2rz5c4107v3qbd7bppfsbzb1mzr02clgf")
   (crate-source "hermit-abi" "0.3.1"
                 "11j2v3q58kmi5mhjvh6hfrb7il2yzg7gmdf5lpwnwwv6qj04im7y")
   (crate-source "ident_case" "1.0.1"
                 "0fac21q6pwns8gh1hz3nbq15j8fi441ncl6w4vlnd1cmc55kiq5r")
   (crate-source "image" "0.24.6"
                 "0fhaypwc4ngal4pjq30knl4hymb5lx1i8lh392jc62p2h6m0jyaj")
   (crate-source "indexmap" "1.9.3"
                 "16dxmy7yvk51wvnih3a3im6fp5lmx0wx76i03n06wyak6cwhw1xx")
   (crate-source "indicatif" "0.17.3"
                 "0ad70n05p6k6p3lsyws3hkq3rbq4ap9k83bgfpb68f67kfm0kxff")
   (crate-source "indoc" "2.0.7"
                 "01np60qdq6lvgh8ww2caajn9j4dibx9n58rvzf7cya1jz69mrkvr")
   (crate-source "instability" "0.3.10"
                 "170dsap2il7fpx85dylb4q979czrbj77ay6v77vpvvpgdqcv0y37")
   (crate-source "io-lifetimes" "1.0.10"
                 "08625nsz0lgbd7c9lly6b6l45viqpsnj9jbsixd9mrz7596wfrlw")
   (crate-source "is-terminal" "0.4.7"
                 "07xyfla3f2jjb666s72la5jvl9zq7mixbqkjvyfi5j018rhr7kxd")
   (crate-source "is_ci" "1.1.1"
                 "1ywra2z56x6d4pc02zq24a4x7gvpixynh9524icbpchbf9ydwv31")
   (crate-source "itertools" "0.13.0"
                 "11hiy3qzl643zcigknclh446qb9zlg4dpdzfkjaa9q9fqpgyfgj1")
   (crate-source "itoa" "1.0.6"
                 "19jc2sa3wvdc29zhgbwf3bayikq4rq18n20dbyg9ahd4hbsxjfj5")
   (crate-source "jobserver" "0.1.26"
                 "1hkprvh1zp5s3qwjjwwhw7rcpivczcbf6q60rcxr0m8158hzsv4k")
   (crate-source "jpeg-decoder" "0.3.0"
                 "0gkv0zx95i4fr40fj1a10d70lqi6lfyia8r5q8qjxj8j4pj0005w")
   (crate-source "js-sys" "0.3.61"
                 "0c075apyc5fxp2sbgr87qcvq53pcjxmp05l47lzlhpn5a0hxwpa4")
   (crate-source "lab" "0.11.0"
                 "13ymsn5cwl5i9pmp5mfmbap7q688dcp9a17q82crkvb784yifdmz")
   (crate-source "lazy_static" "1.4.0"
                 "0in6ikhw8mgl33wjv6q6xfrb5b9jr16q8ygjy803fay4zcisvaz2")
   (crate-source "lebe" "0.5.2"
                 "1j2l6chx19qpa5gqcw434j83gyskq3g2cnffrbl3842ymlmpq203")
   (crate-source "libc" "0.2.178"
                 "1490yks6mria93i3xdva1gm05cjz824g14mbv0ph32lxma6kvj9p")
   (crate-source "libwebp-sys" "0.4.2"
                 "1gvjaqhjpzdskx8x4q1lfgw24jnbjgkx4s6dxpkkg2d2ba4d37s3")
   (crate-source "linux-raw-sys" "0.3.1"
                 "0brj1kcwch9i2hiwi971mwn8wwak5s5bqmpvfbld4lr805sqr7fm")
   (crate-source "linux-raw-sys" "0.4.15"
                 "1aq7r2g7786hyxhv40spzf2nhag5xbw2axxc1k8z5k1dsgdm4v6j")
   (crate-source "lock_api" "0.4.14"
                 "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2")
   (crate-source "log" "0.4.17"
                 "0biqlaaw1lsr8bpnmbcc0fvgjj34yy79ghqzyi0ali7vgil2xcdb")
   (crate-source "lru" "0.12.5"
                 "0f1a7cgqxbyhrmgaqqa11m3azwhcc36w0v5r4izgbhadl3sg8k13")
   (crate-source "memoffset" "0.8.0"
                 "1qcdic88dhgw76pafgndpz04pig8il4advq978mxdxdwrydp276n")
   (crate-source "miniz_oxide" "0.6.2"
                 "1yp8z6yll5ypz1ldmgnv7zi0r78kbvmqmn2mii77jzmk5069axdj")
   (crate-source "miniz_oxide" "0.7.1"
                 "1ivl3rbbdm53bzscrd01g60l46lz5krl270487d8lhjvwl5hx0g7")
   (crate-source "mio" "1.1.1"
                 "1z2phpalqbdgihrcjp8y09l3kgq6309jnhnr6h11l9s7mnqcm6x6")
   (crate-source "nanorand" "0.7.0"
                 "1hr60b8zlfy7mxjcwx2wfmhpkx7vfr3v9x12shmv1c10b0y32lba")
   (crate-source "num-integer" "0.1.45"
                 "1ncwavvwdmsqzxnn65phv6c6nn72pnv9xhpmjd6a429mzf4k6p92")
   (crate-source "num-rational" "0.4.1"
                 "1c0rb8x4avxy3jvvzv764yk7afipzxncfnqlb10r3h53s34s2f06")
   (crate-source "num-traits" "0.2.15"
                 "1kfdqqw2ndz0wx2j75v9nbjx7d3mh3150zs4p5595y02rwsdx3jp")
   (crate-source "num_cpus" "1.15.0"
                 "0fsrjy3arnbcl41vz0gppya8d7d24cpkjgfflr3v8pivl4nrxb0g")
   (crate-source "number_prefix" "0.4.0"
                 "1wvh13wvlajqxkb1filsfzbrnq0vrmrw298v2j3sy82z1rm282w3")
   (crate-source "once_cell" "1.17.1"
                 "1lrsy9c5ikf2iwxr4iwgd3rlq9mg8alh0np1g8abnvp1k4151rdp")
   (crate-source "owo-colors" "3.5.0"
                 "0vyvry6ba1xmpd45hpi6savd8mbx09jpmvnnwkf6z62pk6s4zc61")
   (crate-source "parking_lot" "0.12.5"
                 "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck")
   (crate-source "parking_lot_core" "0.9.12"
                 "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896")
   (crate-source "paste" "1.0.15"
                 "02pxffpdqkapy292harq6asfjvadgp1s005fip9ljfsn9fvxgh2p")
   (crate-source "pin-project" "1.0.12"
                 "1k3f9jkia3idxl2pqxamszwnl89dk52fa4jqj3p7zmmwnq4scadd")
   (crate-source "pin-project-internal" "1.0.12"
                 "0maa6icn7rdfy4xvgfaq7m7bwpw9f19wg76f1ncsiixd0lgdp6q6")
   (crate-source "png" "0.17.8"
                 "1apfid4dppkvhh9d5qzibvdqba9agxkfpgzksd8c3lp7z58vrvma")
   (crate-source "portable-atomic" "0.3.19"
                 "02x09r2zl5ybkazi6k5pfrz8pzs0yzpyxp5d84r5lhrfgjwagxi6")
   (crate-source "proc-macro2" "1.0.103"
                 "1s29bz20xl2qk5ffs2mbdqknaj43ri673dz86axdbf47xz25psay")
   (crate-source "qoi" "0.4.1"
                 "00c0wkb112annn2wl72ixyd78mf56p4lxkhlmsggx65l3v3n8vbz")
   (crate-source "quote" "1.0.42"
                 "0zq6yc7dhpap669m27rb4qfbiywxfah17z6fwvfccv3ys90wqf53")
   (crate-source "ratatui" "0.29.0"
                 "0yqiccg1wmqqxpb2sz3q2v3nifmhsrfdsjgwhc2w40bqyg199gga")
   (crate-source "rayon" "1.7.0"
                 "0fzh8w5ds1qjhilll4rkpd3kimw70zi5605wprxcig1pdqczab8x")
   (crate-source "rayon-core" "1.11.0"
                 "13dymrhhdilzpbfh3aylv6ariayqdfk614b3frvwixb6d6yrb3sb")
   (crate-source "redox_syscall" "0.5.18"
                 "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd")
   (crate-source "rgb" "0.8.36"
                 "0ncgzkgifbyfx7vpnygfl4mgpdhhbaywxybx6pnjraf77wz2vv10")
   (crate-source "rustix" "0.37.11"
                 "0xszzgz8jr22jknmgrf245r10rbkzs7knyx4lvmxs51rz1hpsnc5")
   (crate-source "rustix" "0.38.44"
                 "0m61v0h15lf5rrnbjhcb9306bgqrhskrqv7i1n0939dsw8dbrdgx")
   (crate-source "rustversion" "1.0.22"
                 "0vfl70jhv72scd9rfqgr2n11m5i9l1acnk684m2w83w0zbqdx75k")
   (crate-source "ryu" "1.0.13"
                 "0hchlxvjmsz51l06c7r8zwj45pm8bhc3x3czcih27rkx8v03j4zr")
   (crate-source "scopeguard" "1.1.0"
                 "1kbqm85v43rq92vx7hfiay6pmcga03vrjbbfwqpyj3pwsg3b16nj")
   (crate-source "serde" "1.0.160"
                 "0v11q6pjdjivw24cv98zv9dkdx50d6h9748lgvdbrqxwr1q3fbxv")
   (crate-source "serde_json" "1.0.96"
                 "1waj3qwpa610vmksnzcmkll6vaw7nf7v3ckj4v0wlfs0a153jz85")
   (crate-source "signal-hook" "0.3.18"
                 "1qnnbq4g2vixfmlv28i1whkr0hikrf1bsc4xjy2aasj2yina30fq")
   (crate-source "signal-hook-mio" "0.2.5"
                 "1k20rr76ngvmzr6kskkl7dv8iyb84cbydpjbjk3mpcj0lykijnmp")
   (crate-source "signal-hook-registry" "1.4.7"
                 "1bgdimrfqcldbplryknv87gywcdj9v29l3nwqbybs5p6p2ca0r3n")
   (crate-source "simd-adler32" "0.3.5"
                 "0bsj39d3xrqlcxjwj8i6fzh6ks38idh6b14nml8534f1fyxvz2i3")
   (crate-source "smallvec" "1.10.0"
                 "1q2k15fzxgwjpcdv3f323w24rbbfyv711ayz85ila12lg7zbw1x5")
   (crate-source "spin" "0.9.8"
                 "0rvam5r0p3a6qhc18scqpvpgb3ckzyqxpgdfyjnghh8ja7byi039")
   (crate-source "static_assertions" "1.1.0"
                 "0gsl6xmw10gvn3zs1rv99laj5ig7ylffnh71f9l34js4nr4r7sx2")
   (crate-source "strsim" "0.10.0"
                 "08s69r4rcrahwnickvi0kq49z524ci50capybln83mg6b473qivk")
   (crate-source "strsim" "0.11.1"
                 "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x")
   (crate-source "strum" "0.26.3"
                 "01lgl6jvrf4j28v5kmx9bp480ygf1nhvac8b4p7rcj9hxw50zv4g")
   (crate-source "strum_macros" "0.26.4"
                 "1gl1wmq24b8md527cpyd5bw9rkbqldd7k1h38kf5ajd2ln2ywssc")
   (crate-source "supports-color" "1.3.1"
                 "0vqdhwc3yf1bv1xbaz5d8p2brmlv1ap4fhwg8pfjzr3yrbrgm9lb")
   (crate-source "supports-color" "2.0.0"
                 "0m5kayz225f23k5jyjin82sfkrqhfdq3j72ianafkazz9cbyfl29")
   (crate-source "syn" "1.0.109"
                 "0ds2if4600bd59wsv7jjgfkayfzy3hnazs394kz6zdkmna8l3dkj")
   (crate-source "syn" "2.0.111"
                 "11rf9l6435w525vhqmnngcnwsly7x4xx369fmaqvswdbjjicj31r")
   (crate-source "tiff" "0.8.1"
                 "0wg4a6w8sakyy0mggblg340mx8bgglx9hwsxsn8g5fpjkx7k6jbl")
   (crate-source "unicode-ident" "1.0.8"
                 "1x4v4v95fv9gn5zbpm23sa9awjvmclap1wh1lmikmw9rna3llip5")
   (crate-source "unicode-segmentation" "1.12.0"
                 "14qla2jfx74yyb9ds3d2mpwpa4l4lzb9z57c6d2ba511458z5k7n")
   (crate-source "unicode-truncate" "1.1.0"
                 "1gr7arjjhrhy8dww7hj8qqlws97xf9d276svr4hs6pxgllklcr5k")
   (crate-source "unicode-width" "0.1.10"
                 "12vc3wv0qwg8rzcgb9bhaf5119dlmd6lmkhbfy1zfls6n7jx3vf0")
   (crate-source "unicode-width" "0.2.0"
                 "1zd0r5vs52ifxn25rs06gxrgz8cmh4xpra922k0xlmrchib1kj0z")
   (crate-source "utf8parse" "0.2.1"
                 "02ip1a0az0qmc2786vxk2nqwsgcwf17d3a38fkf0q7hrmwh9c6vi")
   (crate-source "wasi" "0.11.0+wasi-snapshot-preview1"
                 "08z4hxwkpdpalxjps1ai9y7ihin26y9f476i53dv98v45gkqg3cw")
   (crate-source "wasm-bindgen" "0.2.84"
                 "0fx5gh0b4n6znfa3blz92wn1k4bbiysyq9m95s7rn3gk46ydry1i")
   (crate-source "wasm-bindgen-backend" "0.2.84"
                 "1ffc0wb293ha56i66f830x7f8aa2xql69a21lrasy1ncbgyr1klm")
   (crate-source "wasm-bindgen-macro" "0.2.84"
                 "1idlq28awqhq8rclb22rn5xix82w9a4rgy11vkapzhzd1dygf8ac")
   (crate-source "wasm-bindgen-macro-support" "0.2.84"
                 "1xm56lpi0rihh8ny7x085dgs3jdm47spgqflb98wghyadwq83zra")
   (crate-source "wasm-bindgen-shared" "0.2.84"
                 "0pcvk1c97r1pprzfaxxn359r0wqg5bm33ylbwgjh8f4cwbvzwih0")
   (crate-source "webp" "0.2.2"
                 "1bhw6xp7vg4rx7flxgzvdzk21q2dx1bsn06h0yj7jq0n3y12y0ng")
   (crate-source "weezl" "0.1.7"
                 "1frdbq6y5jn2j93i20hc80swpkj30p1wffwxj1nr4fp09m6id4wi")
   (crate-source "winapi" "0.3.9"
                 "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw")
   (crate-source "winapi-i686-pc-windows-gnu" "0.4.0"
                 "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc")
   (crate-source "winapi-x86_64-pc-windows-gnu" "0.4.0"
                 "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki")
   (crate-source "windows-link" "0.2.1"
                 "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h")
   (crate-source "windows-sys" "0.42.0"
                 "19waf8aryvyq9pzk0gamgfwjycgzk4gnrazpfvv171cby0h1hgjs")
   (crate-source "windows-sys" "0.48.0"
                 "1aan23v5gs7gya1lc46hqn9mdh8yph3fhxmhxlw36pn6pqc28zb7")
   (crate-source "windows-sys" "0.59.0"
                 "0fw5672ziw8b3zpmnbp9pdv1famk74f1l9fcbc3zsrzdg56vqf0y")
   (crate-source "windows-sys" "0.61.2"
                 "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf")
   (crate-source "windows-targets" "0.48.0"
                 "1mfzg94w0c8h4ya9sva7rra77f3iy1712af9b6bwg03wrpqbc7kv")
   (crate-source "windows-targets" "0.52.6"
                 "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv")
   (crate-source "windows_aarch64_gnullvm" "0.42.2"
                 "1y4q0qmvl0lvp7syxvfykafvmwal5hrjb4fmv04bqs0bawc52yjr")
   (crate-source "windows_aarch64_gnullvm" "0.48.0"
                 "1g71yxi61c410pwzq05ld7si4p9hyx6lf5fkw21sinvr3cp5gbli")
   (crate-source "windows_aarch64_gnullvm" "0.52.6"
                 "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j")
   (crate-source "windows_aarch64_msvc" "0.42.2"
                 "0hsdikjl5sa1fva5qskpwlxzpc5q9l909fpl1w6yy1hglrj8i3p0")
   (crate-source "windows_aarch64_msvc" "0.48.0"
                 "1wvwipchhywcjaw73h998vzachf668fpqccbhrxzrz5xszh2gvxj")
   (crate-source "windows_aarch64_msvc" "0.52.6"
                 "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09")
   (crate-source "windows_i686_gnu" "0.42.2"
                 "0kx866dfrby88lqs9v1vgmrkk1z6af9lhaghh5maj7d4imyr47f6")
   (crate-source "windows_i686_gnu" "0.48.0"
                 "0hd2v9kp8fss0rzl83wzhw0s5z8q1b4875m6s1phv0yvlxi1jak2")
   (crate-source "windows_i686_gnu" "0.52.6"
                 "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf")
   (crate-source "windows_i686_gnullvm" "0.52.6"
                 "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf")
   (crate-source "windows_i686_msvc" "0.42.2"
                 "0q0h9m2aq1pygc199pa5jgc952qhcnf0zn688454i7v4xjv41n24")
   (crate-source "windows_i686_msvc" "0.48.0"
                 "004fkyqv3if178xx9ksqc4qqv8sz8n72mpczsr2vy8ffckiwchj5")
   (crate-source "windows_i686_msvc" "0.52.6"
                 "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294")
   (crate-source "windows_x86_64_gnu" "0.42.2"
                 "0dnbf2xnp3xrvy8v9mgs3var4zq9v9yh9kv79035rdgyp2w15scd")
   (crate-source "windows_x86_64_gnu" "0.48.0"
                 "1cblz5m6a8q6ha09bz4lz233dnq5sw2hpra06k9cna3n3xk8laya")
   (crate-source "windows_x86_64_gnu" "0.52.6"
                 "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl")
   (crate-source "windows_x86_64_gnullvm" "0.42.2"
                 "18wl9r8qbsl475j39zvawlidp1bsbinliwfymr43fibdld31pm16")
   (crate-source "windows_x86_64_gnullvm" "0.48.0"
                 "0lxryz3ysx0145bf3i38jkr7f9nxiym8p3syklp8f20yyk0xp5kq")
   (crate-source "windows_x86_64_gnullvm" "0.52.6"
                 "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94")
   (crate-source "windows_x86_64_msvc" "0.42.2"
                 "1w5r0q0yzx827d10dpjza2ww0j8iajqhmb54s735hhaj66imvv4s")
   (crate-source "windows_x86_64_msvc" "0.48.0"
                 "12ipr1knzj2rwjygyllfi5mkd0ihnbi3r61gag5n2jgyk5bmyl8s")
   (crate-source "windows_x86_64_msvc" "0.52.6"
                 "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq")
   (crate-source "zune-inflate" "0.2.53"
                 "1y5aklf5sc1cmghidci8wzm0g0y3hq1v3abfhi5jwi66b7yhh2j4")))

(define-public dipc
  (package
    (name "dipc")
    (version "1.2.0")
    (source (package-source doprz-dipc-source))
    (build-system cargo-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          ;; The output is the command-line program; do not copy a second
          ;; Cargo source tree into the runtime output.
          (delete 'install)
          ;; cargo-build-system normally removes Cargo.lock so that a
          ;; package can resolve from its vendored inputs.  This application
          ;; is packaged from a reviewed lockfile; retain that exact graph.
          (add-after 'unpack 'preserve-cargo-lock
            (lambda _
              (use-modules (guix build utils))
              (copy-file "Cargo.lock" "Cargo.lock.guix")
              ;; Guix's vendored crates deliberately use empty checksum
              ;; manifests.  Keep lockfile versions/dependency edges while
              ;; removing only Cargo's registry checksum metadata, which
              ;; otherwise conflicts with the vendored source replacement.
              (substitute* "Cargo.lock.guix"
                (("^checksum = .*$") ""))))
          (add-after 'configure 'restore-cargo-lock
            (lambda _
              (copy-file "Cargo.lock.guix" "Cargo.lock")))
          ;; Cargo's package/check phases may rewrite or remove the lockfile;
          ;; restore the reviewed graph before cargo install runs.
          (add-after 'check 'restore-cargo-lock-for-install
            (lambda _
              (copy-file "Cargo.lock.guix" "Cargo.lock")))
          (add-after 'restore-cargo-lock-for-install 'install-dipc
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                (invoke "cargo" "install" "--offline" "--locked"
                        "--no-track" "--path" "." "--root" out)))))
      #:install-source? #f))
    (inputs dipc-cargo-inputs)
    (synopsis "Convert images using color palettes and themes")
    (description
     "Dipc is a command-line image palette converter.  It maps image colors
to built-in or user-supplied palettes using CIELAB DeltaE methods, supports
PNG, JPEG, and other formats provided by its image codecs, and can process
files or stdin/stdout pipelines.  The package builds the exact dependency
graph recorded by the upstream Cargo.lock without network access.")
    (home-page "https://github.com/doprz/dipc")
    (license (list license:expat license:asl2.0))))
