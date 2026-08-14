;;; hyprland-preview-share-picker -- GTK4 Hyprland screencopy picker.
;;;
;;; SPDX-License-Identifier: MIT

(define-module (tay packages hyprland-preview-share-picker)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages rust))

(define %hyprland-preview-share-picker-commit
  "e2f30ff85486e557018523da45ccbc846e3a499c")

(define (crate-source name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://crates.io/api/v1/crates/"
                        name "/" version "/download"))
    ;; The cargo build system identifies registry inputs by this conventional
    ;; rust-prefixed input label when Guix derives a label for an origin.
    (file-name (string-append "rust-" name "-" version ".crate"))
    (sha256 (base32 hash))))

;; Cargo's lock file contains several hundred exact registry packages.  Keep
;; every one as an immutable Guix input: cargo-build-system then vendors this
;; complete set and builds with --offline, including platform-conditional
;; entries that Cargo still needs while resolving the lock file.
(define %hyprland-preview-share-picker-cargo-inputs
  (list
    (crate-source "addr2line" "0.24.2" "1hd1i57zxgz08j6h5qrhsnm2fi0bcqvsh389fw400xm3arz2ggnz")
    (crate-source "adler2" "2.0.0" "09r6drylvgy8vv8k20lnbvwq8gp09h7smfn6h1rxsy15pgh629si")
    (crate-source "ahash" "0.8.11" "04chdfkls5xmhp1d48gnjsmglbqibizs3bpbj6rsj604m10si7g8")
    (crate-source "aho-corasick" "1.1.3" "05mrpkvdgp5d20y2p989f187ry9diliijgwrs254fs9s1m1x6q4f")
    (crate-source "aligned-vec" "0.5.0" "1lb8qjqfap028ylf8zap6rkwrnrqimc3v6h3cixycjrdx1y0vaaa")
    (crate-source "android-tzdata" "0.1.1" "1w7ynjxrfs97xg3qlcdns4kgfpwcdv824g611fq32cag4cdr96g9")
    (crate-source "android_system_properties" "0.1.5" "04b3wrz12837j7mdczqd95b732gw5q7q66cv4yn4646lvccp57l1")
    (crate-source "anstream" "0.6.18" "16sjk4x3ns2c3ya1x28a44kh6p47c7vhk27251i015hik1lm7k4a")
    (crate-source "anstyle" "1.0.10" "1yai2vppmd7zlvlrp9grwll60knrmscalf8l2qpfz8b7y5lkpk2m")
    (crate-source "anstyle-parse" "0.2.6" "1acqayy22fwzsrvr6n0lz6a4zvjjcvgr5sm941m7m0b2fr81cb9v")
    (crate-source "anstyle-query" "1.1.2" "036nm3lkyk43xbps1yql3583fp4hg3b1600is7mcyxs1gzrpm53r")
    (crate-source "anstyle-wincon" "3.0.7" "0kmf0fq4c8yribdpdpylzz1zccpy84hizmcsac3wrac1f7kk8dfa")
    (crate-source "anyhow" "1.0.95" "010vd1ki8w84dzgx6c81sc8qm9n02fxic1gkpv52zp4nwrn0kb1l")
    (crate-source "arbitrary" "1.4.1" "08zj2yanll5s5gsbmvgwvbq39iqzy3nia3yx3db3zwba08yhpqnx")
    (crate-source "arc-swap" "1.7.1" "0mrl9a9r9p9bln74q6aszvf22q1ijiw089jkrmabfqkbj31zixv9")
    (crate-source "arg_enum_proc_macro" "0.3.4" "1sjdfd5a8j6r99cf0bpqrd6b160x9vz97y5rysycsjda358jms8a")
    (crate-source "arrayvec" "0.7.6" "0l1fz4ccgv6pm609rif37sl5nv5k6lbzi7kkppgzqzh1vwix20kw")
    (crate-source "async-stream" "0.3.6" "0xl4zqncrdmw2g6241wgr11dxdg4h7byy6bz3l6si03qyfk72nhb")
    (crate-source "async-stream-impl" "0.3.6" "0kaplfb5axsvf1gfs2gk6c4zx6zcsns0yf3ssk7iwni7bphlvhn7")
    (crate-source "autocfg" "1.4.0" "09lz3by90d2hphbq56znag9v87gfpd9gb8nr82hll8z6x2nhprdc")
    (crate-source "av1-grain" "0.2.3" "1gvqdh21bm1cfqiwyiinbqi0mg7x2lg2fwgmphma8ijxijfr0y36")
    (crate-source "avif-serialize" "0.8.2" "0qnxpnwl5yn31xh3ymr546jbazj3xi1nzvay47502cf4j0908dg3")
    (crate-source "backtrace" "0.3.74" "06pfif7nwx66qf2zaanc2fcq7m64i91ki9imw9xd3bnz5hrwp0ld")
    (crate-source "bit_field" "0.10.2" "0qav5rpm4hqc33vmf4vc4r0mh51yjx5vmd9zhih26n9yjs3730nw")
    (crate-source "bitflags" "1.3.2" "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy")
    (crate-source "bitflags" "2.8.0" "0dixc6168i98652jxf0z9nbyn0zcis3g6hi6qdr7z5dbhcygas4g")
    (crate-source "bitstream-io" "2.6.0" "1cli390l1dhp9skygyjjnqvczp36b7f31mkx9ry3dg26330cv6b0")
    (crate-source "built" "0.7.6" "0k8yksxdcigaxsamlcqawqq4iacaywmnrpvss58i4fnnqm1qm13k")
    (crate-source "bumpalo" "3.17.0" "1gxxsn2fsjmv03g8p3m749mczv2k4m8xspifs5l7bcx0vx3gna0n")
    (crate-source "bytemuck" "1.21.0" "18wj81x9xhqcd6985r8qxmbik6szjfjfj62q3xklw8h2p3x7srgg")
    (crate-source "byteorder" "1.5.0" "0jzncxyf404mwqdbspihyzpkndfgda450l0893pz5xj685cg5l0z")
    (crate-source "byteorder-lite" "0.1.0" "15alafmz4b9az56z6x7glcbcb6a8bfgyd109qc3bvx07zx4fj7wg")
    (crate-source "bytes" "1.10.0" "1ybcmdrlxrsrn7lnl0xrjg10j7zb4r01jjs5b2sqhrcwh62aq7gn")
    (crate-source "cairo-rs" "0.20.7" "1xy02qa4mn9bwnhsbmkry4yjz230r66nvrkh4fn9dkw61m8val5f")
    (crate-source "cairo-sys-rs" "0.20.7" "1pwh4b4mdsipjl9lrg5p5bygbdk11kz6m5y7mbrb0ziwwjw6p2zi")
    (crate-source "cc" "1.2.13" "1nizaxd11q0a8n5fy0ajbbvcl36w42gs0d1r0cpc0634h50p6xy7")
    (crate-source "cfg-expr" "0.15.8" "00lgf717pmf5qd2qsxxzs815v6baqg38d6m5i6wlh235p14asryh")
    (crate-source "cfg-expr" "0.17.2" "12a7zr6ff4i6mfwcv711dll0w5pr3dw1lvkaf4c4a66i1gjacjwd")
    (crate-source "cfg-if" "1.0.0" "1za0vb97n4brpzpv8lsbnzmq5r8f2b0cpqqr0sy8h5bn751xxwds")
    (crate-source "chrono" "0.4.39" "09g8nf409lb184kl9j4s85k0kn8wzgjkp5ls9zid50b886fwqdky")
    (crate-source "clap" "4.5.28" "1zq53kp3lfcz9xr584i7r9bw8ivkcra53jvj6v046hnr7cjc6xry")
    (crate-source "clap_builder" "4.5.27" "1mys7v60lys8zkwpk49wif9qnja9zamm4dnrsbj40wdmni78h9hv")
    (crate-source "clap_derive" "4.5.28" "1vgigkhljp3r8r5lwdrn1ij93nafmjwh8cx77nppb9plqsaysk5z")
    (crate-source "clap_lex" "0.7.4" "19nwfls5db269js5n822vkc8dw0wjq2h1wf0hgr06ld2g52d2spl")
    (crate-source "color_quant" "1.1.0" "12q1n427h2bbmmm1mnglr57jaz2dj9apk0plcxw7nwqiai7qjyrx")
    (crate-source "colorchoice" "1.0.3" "1439m3r3jy3xqck8aa13q658visn71ki76qa93cy55wkmalwlqsv")
    (crate-source "core-foundation-sys" "0.8.7" "12w8j73lazxmr1z0h98hf3z623kl8ms7g07jch7n4p8f9nwlhdkp")
    (crate-source "crc32fast" "1.4.2" "1czp7vif73b8xslr3c9yxysmh9ws2r8824qda7j47ffs9pcnjxx9")
    (crate-source "crossbeam-deque" "0.8.6" "0l9f1saqp1gn5qy0rxvkmz4m6n7fc0b3dbm6q1r5pmgpnyvi3lcx")
    (crate-source "crossbeam-epoch" "0.9.18" "03j2np8llwf376m3fxqx859mgp9f83hj1w34153c7a9c7i5ar0jv")
    (crate-source "crossbeam-utils" "0.8.21" "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh")
    (crate-source "crunchy" "0.2.3" "0aa9k4izp962qlsn5ndgw2zq62mizcpnkns8bxscgz3gqr35knj3")
    (crate-source "derive_more" "1.0.0" "01cd8pskdjg10dvfchi6b8a9pa1ja1ic0kbn45dl8jdyrfwrk6sa")
    (crate-source "derive_more-impl" "1.0.0" "08mxyd456ygk68v5nfn4dyisn82k647w9ri2jl19dqpvmnp30wyb")
    (crate-source "dirs" "6.0.0" "0knfikii29761g22pwfrb8d0nqpbgw77sni9h2224haisyaams63")
    (crate-source "dirs-sys" "0.5.0" "1aqzpgq6ampza6v012gm2dppx9k35cdycbj54808ksbys9k366p0")
    (crate-source "downcast-rs" "1.2.1" "1lmrq383d1yszp7mg5i7i56b17x2lnn3kb91jwsq0zykvg2jbcvm")
    (crate-source "dyn-clone" "1.0.18" "0dag651ph5q0mcax74y4m1k9hyl737q1v03isck3mzxsfd7g9vpy")
    (crate-source "either" "1.13.0" "1w2c1mybrd7vljyxk77y9f4w9dyjrmp3yp82mk7bcm8848fazcb0")
    (crate-source "env_filter" "0.1.3" "1l4p6f845cylripc3zkxa0lklk8rn2q86fqm522p6l2cknjhavhq")
    (crate-source "env_logger" "0.11.6" "1q30cqb2dfs3qrs0s30qdmqwi7n2gz4pniwd8a9gvhygwgcf7bnw")
    (crate-source "equivalent" "1.0.1" "1malmx5f4lkfvqasz319lq6gb3ddg19yzf9s8cykfsgzdmyq0hsl")
    (crate-source "errno" "0.3.10" "0pgblicz1kjz9wa9m0sghkhh2zw1fhq1mxzj7ndjm746kg5m5n1k")
    (crate-source "exr" "1.73.0" "1q47yq78q9k210r6jy1wwrilxwwxqavik9l3l426rd17k7srfcgq")
    (crate-source "fastrand" "2.3.0" "1ghiahsw1jd68df895cy5h3gzwk30hndidn3b682zmshpgmrx41p")
    (crate-source "fdeflate" "0.3.7" "130ga18vyxbb5idbgi07njymdaavvk6j08yh1dfarm294ssm6s0y")
    (crate-source "field-offset" "0.3.6" "0zq5sssaa2ckmcmxxbly8qgz3sxpb8g1lwv90sdh1z74qif2gqiq")
    (crate-source "flate2" "1.0.35" "0z6h0wa095wncpfngx75wyhyjnqwld7wax401gsvnzjhzgdbydn9")
    (crate-source "futures-channel" "0.3.31" "040vpqpqlbk099razq8lyn74m0f161zd0rp36hciqrwcg2zibzrd")
    (crate-source "futures-core" "0.3.31" "0gk6yrxgi5ihfanm2y431jadrll00n5ifhnpx090c2f2q1cr1wh5")
    (crate-source "futures-executor" "0.3.31" "17vcci6mdfzx4gbk0wx64chr2f13wwwpvyf3xd5fb1gmjzcx2a0y")
    (crate-source "futures-io" "0.3.31" "1ikmw1yfbgvsychmsihdkwa8a1knank2d9a8dk01mbjar9w1np4y")
    (crate-source "futures-lite" "2.6.0" "0cmmgszlmkwsac9pyw5rfjakmshgx4wmzmlyn6mmjs0jav4axvgm")
    (crate-source "futures-macro" "0.3.31" "0l1n7kqzwwmgiznn0ywdc5i24z72zvh9q1dwps54mimppi7f6bhn")
    (crate-source "futures-task" "0.3.31" "124rv4n90f5xwfsm9qw6y99755y021cmi5dhzh253s920z77s3zr")
    (crate-source "futures-util" "0.3.31" "10aa1ar8bgkgbr4wzxlidkqkcxf77gffyj8j7768h831pcaq784z")
    (crate-source "gdk-pixbuf" "0.20.7" "0k1wawpp8dwhwv0ws22i9w2mvlqhng5p8sdd29xx6qvqbxqcgvxn")
    (crate-source "gdk-pixbuf-sys" "0.20.7" "0p0b3lrzamsz580dyrr5i99i32ppsjp6mfmvfrs9kgq2j9y5iwk7")
    (crate-source "gdk4" "0.9.5" "05cvi1h1xjxpfrhg8wygr64kmi4cyppp3abxzrqhz24g24h6f6fh")
    (crate-source "gdk4-sys" "0.9.5" "0q1b8p67v8ac72frj78bz2lg11axkvnrzwqch5w7lpni1csf3c30")
    (crate-source "getrandom" "0.2.15" "1mzlnrb3dgyd1fb84gvw10pyr8wdqdl4ry4sr64i1s8an66pqmn4")
    (crate-source "gif" "0.13.1" "1whrkvdg26gp1r7f95c6800y6ijqw5y0z8rgj6xihpi136dxdciz")
    (crate-source "gimli" "0.31.1" "0gvqc0ramx8szv76jhfd4dms0zyamvlg4whhiz11j34hh3dqxqh7")
    (crate-source "gio" "0.20.7" "0blfbnavb8vky1ngbsxlbpnq5b5pr3zg2ry6c2gvwx51i5sna5x5")
    (crate-source "gio-sys" "0.20.8" "016vhzy6bmn4xckscdjs3kg2zd1djy6p7h8233wbw3kkfnsdjil4")
    (crate-source "gl" "0.14.0" "015lgy3qpzdw7mnh59a4y4hdjq1fhv7nkqlmh1h6fzc212qxlkm9")
    (crate-source "gl_generator" "0.14.0" "0k8j1hmfnff312gy7x1aqjzcm8zxid7ij7dlb8prljib7b1dz58s")
    (crate-source "glib" "0.20.7" "1h4c9acag4i8p955hbpwcc6b427bz6v17ryd60d8538qi7qfssgr")
    (crate-source "glib-macros" "0.20.7" "0s6yik6pgqg5wydcz5v0x8m1jz57m5bsd50zkkpvlw9fy3w02mki")
    (crate-source "glib-sys" "0.20.7" "0lra1igygxf60vd1j6zfr4pwkjc8b1m5577pjn8fj7fpj07zyq5k")
    (crate-source "gobject-sys" "0.20.7" "08v4mkxsdn40hnk24d3ji1ik9qb403vkxcdbfpykp9kix4sn59b7")
    (crate-source "graphene-rs" "0.20.7" "167d1kqn5jgl9s6mmjdxx66p4gn0f9xjfvx5fhl9rz945v6kp7gk")
    (crate-source "graphene-sys" "0.20.7" "0fnjh55lnrd8mgladbapfxak44swlbafqb5pg7l41wsva4wqv9hi")
    (crate-source "gsk4" "0.9.5" "00l1dm4a2p1rp3fxn8s0cvprsicff4jp4vkbidq9w8d6n26iif9j")
    (crate-source "gsk4-sys" "0.9.5" "056f5wsjafpllz4radmpb1qbxp2ajd3qfggsira8llk8bp30z8dw")
    (crate-source "gtk4" "0.9.5" "0i5c9mrwywa6bgjhw1phvida8iqg498ikw3mrxm5yqinh69zz5xn")
    (crate-source "gtk4-layer-shell" "0.4.0" "1k6iisxb2ilczqjhq37mmrs8q9lfd0g6mylx135dgqvba6qy3qgk")
    (crate-source "gtk4-layer-shell-sys" "0.3.0" "01c13i6aymd7y37ciwpr1kl186bhd1jrbwa5kd56cbfv2z0ps1g3")
    (crate-source "gtk4-macros" "0.9.5" "169rqfxfczivcpz7019slsrpkx8crqjka43ymxmikp838xn7il8f")
    (crate-source "gtk4-sys" "0.9.5" "1kyf6p5ydp52ygns831ga9a25ksyx5viq7zrla3gglp5rs0bdx1s")
    (crate-source "half" "2.4.1" "123q4zzw1x4309961i69igzd1wb7pj04aaii3kwasrz3599qrl3d")
    (crate-source "hashbrown" "0.15.2" "12dj0yfn59p3kh3679ac0w1fagvzf4z2zp87a13gbbqbzw0185dz")
    (crate-source "heck" "0.5.0" "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113")
    (crate-source "humantime" "2.1.0" "1r55pfkkf5v0ji1x6izrjwdq9v6sc7bv99xj6srywcar37xmnfls")
    (crate-source "hyprland" "0.4.0-beta.2" "1f03rgrgalv0l56h97s4wix4kcih1r4pjd26wjr11zghnq9i976w")
    (crate-source "hyprland-macros" "0.4.0-beta.2" "10w9ymwh8yvrvynkcf24zykn87mdssg9mlkm242hh12ndvnwpqv9")
    (crate-source "iana-time-zone" "0.1.61" "085jjsls330yj1fnwykfzmb2f10zp6l7w4fhq81ng81574ghhpi3")
    (crate-source "iana-time-zone-haiku" "0.1.2" "17r6jmj31chn7xs9698r122mapq85mfnv98bb4pg6spm0si2f67k")
    (crate-source "image" "0.25.5" "0fsnfgg8hr66ag5nxipvb7d50kbg40qfpbsql59qkwa2ssp48vyd")
    (crate-source "image-webp" "0.2.1" "0zwg4gpnp69dpn8pdhgjy14mawwi3md02mp1162al6s64bl02zdp")
    (crate-source "imgref" "1.11.0" "0254wzkakm31fdix6diqng0fkggknibh0b1iv570ap0djwykl9nh")
    (crate-source "indexmap" "2.7.1" "0lmnm1zbr5gq3wic3d8a76gpvampridzwckfl97ckd5m08mrk74c")
    (crate-source "interpolate_name" "0.2.4" "0q7s5mrfkx4p56dl8q9zq71y1ysdj4shh6f28qf9gly35l21jj63")
    (crate-source "is_terminal_polyfill" "1.70.1" "1kwfgglh91z33kl0w5i338mfpa3zs0hidq5j4ny4rmjwrikchhvr")
    (crate-source "itertools" "0.12.1" "0s95jbb3ndj1lvfxyq5wanc0fm0r6hg6q4ngb92qlfdxvci10ads")
    (crate-source "itoa" "1.0.14" "0x26kr9m062mafaxgcf2p6h2x7cmixm0zw95aipzn2hr3d5jlnnp")
    (crate-source "jobserver" "0.1.32" "1l2k50qmj84x9mn39ivjz76alqmx72jhm12rw33zx9xnpv5xpla8")
    (crate-source "jpeg-decoder" "0.3.1" "1c1k53svpdyfhibkmm0ir5w0v3qmcmca8xr8vnnmizwf6pdagm7m")
    (crate-source "js-sys" "0.3.77" "13x2qcky5l22z4xgivi59xhjjx4kxir1zg7gcj0f1ijzd4yg7yhw")
    (crate-source "khronos_api" "3.1.0" "1p0xj5mlbagqyvvnv8wmv3cr7l9y1m153888pxqwg3vk3mg5inz2")
    (crate-source "lazy_static" "1.5.0" "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv")
    (crate-source "lebe" "0.5.2" "1j2l6chx19qpa5gqcw434j83gyskq3g2cnffrbl3842ymlmpq203")
    (crate-source "libc" "0.2.169" "02m253hs8gw0m1n8iyrsc4n15yzbqwhddi7w1l0ds7i92kdsiaxm")
    (crate-source "libfuzzer-sys" "0.4.9" "0xfwg8shqvysl2bma2lyfcswbbdljajphflp795diwhc80nzay6g")
    (crate-source "libredox" "0.1.3" "139602gzgs0k91zb7dvgj1qh4ynb8g1lbxsswdim18hcb6ykgzy0")
    (crate-source "linux-raw-sys" "0.4.15" "1aq7r2g7786hyxhv40spzf2nhag5xbw2axxc1k8z5k1dsgdm4v6j")
    (crate-source "log" "0.4.25" "17ydv5zhfv1zzygy458bmg3f3jx1vfziv9d74817w76yhfqgbjq4")
    (crate-source "loop9" "0.1.5" "0qphc1c0cbbx43pwm6isnwzwbg6nsxjh7jah04n1sg5h4p0qgbhg")
    (crate-source "maybe-rayon" "0.1.1" "06cmvhj4n36459g327ng5dnj8d58qs472pv5ahlhm7ynxl6g78cf")
    (crate-source "memchr" "2.7.4" "18z32bhxrax0fnjikv475z7ii718hq457qwmaryixfxsl2qrmjkq")
    (crate-source "memfd" "0.6.4" "0r5cm3wzyr1x7768h3hns77b494qbz0g05cb9wgpjvrcsm5gmkxj")
    (crate-source "memoffset" "0.9.1" "12i17wh9a9plx869g7j4whf62xw68k5zd4k0k5nh6ys5mszid028")
    (crate-source "minimal-lexical" "0.2.1" "16ppc5g84aijpri4jzv14rvcnslvlpphbszc7zzp6vfkddf4qdb8")
    (crate-source "miniz_oxide" "0.8.3" "093r1kd1r9dyf05cbvsibgmh96pxp3qhzfvpd6f15bpggamjqh5q")
    (crate-source "mio" "1.0.3" "1gah0h4ia3avxbwym0b6bi6lr6rpysmj9zvw6zis5yq0z0xq91i8")
    (crate-source "new_debug_unreachable" "1.0.6" "11phpf1mjxq6khk91yzcbd3ympm78m3ivl7xg6lg2c0lf66fy3k5")
    (crate-source "nom" "7.1.3" "0jha9901wxam390jcf5pfa0qqfrgh8li787jx2ip0yk5b8y9hwyj")
    (crate-source "nom" "8.0.0" "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz")
    (crate-source "nom-language" "0.1.0" "0abbzawam1nh75igvyn1vh5pgxgzm0wqj2y9jbpxmzhv8mdvrqid")
    (crate-source "noop_proc_macro" "0.3.0" "1j2v1c6ric4w9v12h34jghzmngcwmn0hll1ywly4h6lcm4rbnxh6")
    (crate-source "num-bigint" "0.4.6" "1f903zd33i6hkjpsgwhqwi2wffnvkxbn6rv4mkgcjcqi7xr4zr55")
    (crate-source "num-derive" "0.4.2" "00p2am9ma8jgd2v6xpsz621wc7wbn1yqi71g15gc3h67m7qmafgd")
    (crate-source "num-integer" "0.1.46" "13w5g54a9184cqlbsq80rnxw4jj4s0d8wv75jsq5r2lms8gncsbr")
    (crate-source "num-rational" "0.4.2" "093qndy02817vpgcqjnj139im3jl7vkq4h68kykdqqh577d18ggq")
    (crate-source "num-traits" "0.2.19" "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787")
    (crate-source "object" "0.36.7" "11vv97djn9nc5n6w1gc6bd96d2qk2c8cg1kw5km9bsi3v4a8x532")
    (crate-source "once_cell" "1.20.3" "0bp6rgrsri1vfdcahsimk08zdiilv14ppgcnpbiw8hqyp2j64m4l")
    (crate-source "option-ext" "0.2.0" "0zbf7cx8ib99frnlanpyikm1bx8qn8x602sw1n7bg6p9x94lyx04")
    (crate-source "pango" "0.20.7" "11z0an28p3q8l7jzaaxy0gw2l439ai346yq4xifa00qa4msbv2cy")
    (crate-source "pango-sys" "0.20.7" "16b6vwjsm9glnxdcsw38vlzlynj5vd59w9w9m3nsb6dl3407wy3i")
    (crate-source "paste" "1.0.15" "02pxffpdqkapy292harq6asfjvadgp1s005fip9ljfsn9fvxgh2p")
    (crate-source "phf" "0.11.3" "0y6hxp1d48rx2434wgi5g8j1pr8s5jja29ha2b65435fh057imhz")
    (crate-source "phf_generator" "0.11.3" "0gc4np7s91ynrgw73s2i7iakhb4lzdv1gcyx7yhlc0n214a2701w")
    (crate-source "phf_macros" "0.11.3" "05kjfbyb439344rhmlzzw0f9bwk9fp95mmw56zs7yfn1552c0jpq")
    (crate-source "phf_shared" "0.11.3" "1rallyvh28jqd9i916gk5gk2igdmzlgvv5q0l3xbf3m6y8pbrsk7")
    (crate-source "pin-project-lite" "0.2.16" "16wzc7z7dfkf9bmjin22f5282783f6mdksnr0nv0j5ym5f9gyg1v")
    (crate-source "pin-utils" "0.1.0" "117ir7vslsl2z1a7qzhws4pd01cg2d3338c47swjyvqv2n60v1wb")
    (crate-source "pkg-config" "0.3.31" "1wk6yp2phl91795ia0lwkr3wl4a9xkrympvhqq8cxk4d75hwhglm")
    (crate-source "png" "0.17.16" "09kmkms9fmkbkarw0lnf0scqvjwwg3r7riddag0i3q39r0pil5c2")
    (crate-source "ppv-lite86" "0.2.20" "017ax9ssdnpww7nrl1hvqh2lzncpv04nnsibmnw9nxjnaqlpp5bp")
    (crate-source "proc-macro-crate" "3.2.0" "0yzsqnavb3lmrcsmbrdjfrky9vcbl46v59xi9avn0796rb3likwf")
    (crate-source "proc-macro2" "1.0.93" "169dw9wch753if1mgyi2nfl1il77gslvh6y2q46qplprwml6m530")
    (crate-source "profiling" "1.0.16" "0kcz2xzg4qx01r5az8cf9ffjasi2srj56sna32igddh0vi7cggdg")
    (crate-source "profiling-procmacros" "1.0.16" "0c7y2k4mz5dp2ksj1h4zbxsxq4plmjzccscdaml3h1pizdh2wpx6")
    (crate-source "qoi" "0.4.1" "00c0wkb112annn2wl72ixyd78mf56p4lxkhlmsggx65l3v3n8vbz")
    (crate-source "quick-error" "2.0.1" "18z6r2rcjvvf8cn92xjhm2qc3jpd1ljvcbf12zv0k9p565gmb4x9")
    (crate-source "quick-xml" "0.37.2" "00y0qagwbxd3lqarr13j35d6kwmni176znf5jrxxcyazwplmjn0n")
    (crate-source "quote" "1.0.38" "1k0s75w61k6ch0rs263r4j69b7vj1wadqgb9dia4ylc9mymcqk8f")
    (crate-source "rand" "0.8.5" "013l6931nn7gkc23jz5mm3qdhf93jjf0fg64nz2lp4i51qd8vbrl")
    (crate-source "rand_chacha" "0.3.1" "123x2adin558xbhvqb8w4f6syjsdkmqff8cxwhmjacpsl1ihmhg6")
    (crate-source "rand_core" "0.6.4" "0b4j2v4cb5krak1pv6kakv4sz6xcwbrmy2zckc32hsigbrwy82zc")
    (crate-source "rav1e" "0.7.1" "1sawva6nmj2fvynydbcirr3nb7wjyg0id2hz2771qnv6ly0cx1yd")
    (crate-source "ravif" "0.11.11" "1ij51acd3pkl3rr2ha3r3nc7pvg649m49bvyngpcv98fpnbgs4r4")
    (crate-source "rayon" "1.10.0" "1ylgnzwgllajalr4v00y4kj22klq2jbwllm70aha232iah0sc65l")
    (crate-source "rayon-core" "1.12.1" "1qpwim68ai5h0j7axa8ai8z0payaawv3id0lrgkqmapx7lx8fr8l")
    (crate-source "redox_users" "0.5.0" "0awxx66izdw6kz97r3zxrl5ms5f6dqi5l0f58mlsvlmx8wyrsvyx")
    (crate-source "regex" "1.11.1" "148i41mzbx8bmq32hsj1q4karkzzx5m60qza6gdw4pdc9qdyyi5m")
    (crate-source "regex-automata" "0.4.9" "02092l8zfh3vkmk47yjc8d631zhhcd49ck2zr133prvd3z38v7l0")
    (crate-source "regex-syntax" "0.8.5" "0p41p3hj9ww7blnbwbj9h7rwxzxg0c1hvrdycgys8rxyhqqw859b")
    (crate-source "rgb" "0.8.50" "02ii3nsciska0sj23ggxaz8gj64ksw8nbpfjcwxlh037chb7sfap")
    (crate-source "rsass" "0.29.0" "11a1zy7dfyr4di9627h06nr6r0v4gbpz2pxlzgxf4qksh4cn5l18")
    (crate-source "rustc-demangle" "0.1.24" "07zysaafgrkzy2rjgwqdj2a8qdpsm6zv6f5pgpk9x0lm40z9b6vi")
    (crate-source "rustc_version" "0.4.1" "14lvdsmr5si5qbqzrajgb6vfn69k0sfygrvfvr2mps26xwi3mjyg")
    (crate-source "rustix" "0.38.44" "0m61v0h15lf5rrnbjhcb9306bgqrhskrqv7i1n0939dsw8dbrdgx")
    (crate-source "rustversion" "1.0.19" "1m39qd65jcd1xgqzdm3017ppimiggh2446xngwp1ngr8hjbmpi7p")
    (crate-source "ryu" "1.0.19" "1pg6a0b80m32ahygsdkwzs3bfydk4snw695akz4rqxj4lv8a58bf")
    (crate-source "schemars" "0.8.21" "14lyx04388wgbilgcm0nl75w6359nw16glswfqv7x2rpi9329h09")
    (crate-source "schemars_derive" "0.8.21" "03ncmrkldfmdc9skmlyysx2vqdlyyz91r5mbavw77zwaay4fbvmi")
    (crate-source "semver" "1.0.25" "00sy306qpi7vfand7dxm2vc76nlc8fkh1rrhdy0qh12v50nzx7gp")
    (crate-source "serde" "1.0.217" "0w2ck1p1ajmrv1cf51qf7igjn2nc51r0izzc00fzmmhkvxjl5z02")
    (crate-source "serde_derive" "1.0.217" "180r3rj5gi5s1m23q66cr5wlfgc5jrs6n1mdmql2njnhk37zg6ss")
    (crate-source "serde_derive_internals" "0.29.1" "04g7macx819vbnxhi52cx0nhxi56xlhrybgwybyy7fb9m4h6mlhq")
    (crate-source "serde_json" "1.0.138" "0j99hyp2plvdcyrfzdz0875d0dm04q5ngsd7dr5fk1x7glp1jd6l")
    (crate-source "serde_repr" "0.1.19" "1sb4cplc33z86pzlx38234xr141wr3cmviqgssiadisgl8dlar3c")
    (crate-source "serde_spanned" "0.6.8" "1q89g70azwi4ybilz5jb8prfpa575165lmrffd49vmcf76qpqq47")
    (crate-source "serde_yaml" "0.9.34+deprecated" "0isba1fjyg3l6rxk156k600ilzr8fp7crv82rhal0rxz5qd1m2va")
    (crate-source "shlex" "1.3.0" "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg")
    (crate-source "simd-adler32" "0.3.7" "1zkq40c3iajcnr5936gjp9jjh1lpzhy44p3dq3fiw75iwr1w2vfn")
    (crate-source "simd_helpers" "0.1.0" "19idqicn9k4vhd04ifh2ff41wvna79zphdf2c81rlmpc7f3hz2cm")
    (crate-source "siphasher" "1.0.1" "17f35782ma3fn6sh21c027kjmd227xyrx06ffi8gw4xzv9yry6an")
    (crate-source "slab" "0.4.9" "0rxvsgir0qw5lkycrqgb1cxsvxzjv9bmx73bk5y42svnzfba94lg")
    (crate-source "smallvec" "1.13.2" "0rsw5samawl3wsw6glrsb127rx6sh89a8wyikicw6dkdcjd1lpiw")
    (crate-source "socket2" "0.5.8" "1s7vjmb5gzp3iaqi94rh9r63k9cj00kjgbfn7gn60kmnk6fjcw69")
    (crate-source "strsim" "0.11.1" "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x")
    (crate-source "syn" "2.0.98" "1cfk0qqbl4fbr3dz61nw21d5amvl4rym6nxwnfsw43mf90d7y51n")
    (crate-source "system-deps" "6.2.2" "0j93ryw031n3h8b0nfpj5xwh3ify636xmv8kxianvlyyipmkbrd3")
    (crate-source "system-deps" "7.0.3" "01d0fllzpkfybzadyaq1vlx70imzj56dxs4rk9w2f4ikkypkmlk6")
    (crate-source "target-lexicon" "0.12.16" "1cg3bnx1gdkdr5hac1hzxy64fhw4g7dqkd0n3dxy5lfngpr1mi31")
    (crate-source "thiserror" "1.0.69" "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn")
    (crate-source "thiserror" "2.0.11" "1z0649rpa8c2smzx129bz4qvxmdihj30r2km6vfpcv9yny2g4lnl")
    (crate-source "thiserror-impl" "1.0.69" "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg")
    (crate-source "thiserror-impl" "2.0.11" "1hkkn7p2y4cxbffcrprybkj0qy1rl1r6waxmxqvr764axaxc3br6")
    (crate-source "tiff" "0.9.1" "0ghyxlz566dzc3scvgmzys11dhq2ri77kb8sznjakijlxby104xs")
    (crate-source "tokio" "1.43.0" "17pdm49ihlhfw3rpxix3kdh2ppl1yv7nwp1kxazi5r1xz97zlq9x")
    (crate-source "tokio-macros" "2.5.0" "1f6az2xbvqp7am417b78d1za8axbvjvxnmkakz9vr8s52czx81kf")
    (crate-source "toml" "0.8.20" "0j012b37iz1mihksr6a928s6dzszxvblzg3l5wxp7azzsv6sb1yd")
    (crate-source "toml_datetime" "0.6.8" "0hgv7v9g35d7y9r2afic58jvlwnf73vgd1mz2k8gihlgrf73bmqd")
    (crate-source "toml_edit" "0.22.24" "0x0lgp70x5cl9nla03xqs5vwwwlrwmd0djkdrp3h3lpdymgpkd0p")
    (crate-source "tracing" "0.1.41" "1l5xrzyjfyayrwhvhldfnwdyligi1mpqm8mzbi2m1d6y6p2hlkkq")
    (crate-source "tracing-attributes" "0.1.28" "0v92l9cxs42rdm4m5hsa8z7ln1xsiw1zc2iil8c6k7lzq0jf2nir")
    (crate-source "tracing-core" "0.1.33" "170gc7cxyjx824r9kr17zc9gvzx89ypqfdzq259pr56gg5bwjwp6")
    (crate-source "unicode-ident" "1.0.16" "0d2hji0i16naw43l02dplrz8fbv625n7475s463iqw4by1hd2452")
    (crate-source "unicode-xid" "0.2.6" "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb")
    (crate-source "unsafe-libyaml" "0.2.11" "0qdq69ffl3v5pzx9kzxbghzn0fzn266i1xn70y88maybz9csqfk7")
    (crate-source "utf8parse" "0.2.2" "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6")
    (crate-source "v_frame" "0.3.8" "0az9nd6qi1gyikh9yb3lhm453kf7d5isd6xai3j13kds4jm2mwyn")
    (crate-source "version-compare" "0.2.0" "12y9262fhjm1wp0aj3mwhads7kv0jz8h168nn5fb8b43nwf9abl5")
    (crate-source "version_check" "0.9.5" "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb")
    (crate-source "wasi" "0.11.0+wasi-snapshot-preview1" "08z4hxwkpdpalxjps1ai9y7ihin26y9f476i53dv98v45gkqg3cw")
    (crate-source "wasm-bindgen" "0.2.100" "1x8ymcm6yi3i1rwj78myl1agqv2m86i648myy3lc97s9swlqkp0y")
    (crate-source "wasm-bindgen-backend" "0.2.100" "1ihbf1hq3y81c4md9lyh6lcwbx6a5j0fw4fygd423g62lm8hc2ig")
    (crate-source "wasm-bindgen-macro" "0.2.100" "01xls2dvzh38yj17jgrbiib1d3nyad7k2yw9s0mpklwys333zrkz")
    (crate-source "wasm-bindgen-macro-support" "0.2.100" "1plm8dh20jg2id0320pbmrlsv6cazfv6b6907z19ys4z1jj7xs4a")
    (crate-source "wasm-bindgen-shared" "0.2.100" "0gffxvqgbh9r9xl36gprkfnh3w9gl8wgia6xrin7v11sjcxxf18s")
    (crate-source "wayland-backend" "0.3.8" "1gs7dw6s3lp9g6g0rhk4bh66wl41jnbkd27c6ynhv1x3xac8j85p")
    (crate-source "wayland-client" "0.31.8" "0gzpr9gdd8yk1crflxngg5iwa1szyyzp4i4zbgpslf1nsgihs4n2")
    (crate-source "wayland-protocols" "0.32.6" "1z0yahh48x8qzdbcallmxn5am5897hkk5d7p51ly6dwvhr3cz087")
    (crate-source "wayland-protocols-wlr" "0.3.6" "1cpqb0d4ryf87x2wgca5n71wilhvc0jjva0zasbdgalmypk052i4")
    (crate-source "wayland-scanner" "0.31.6" "110ldnyfxjqvjssir1jf3ndlci7xy9lpv4aqg775y518bpyxlvw9")
    (crate-source "wayland-sys" "0.31.6" "05b6i4lg2qrrz7l4h2b5fd7blkkvxq34i1yvlngsmmbpkhwvpknv")
    (crate-source "weezl" "0.1.8" "10lhndjgs6y5djpg3b420xngcr6jkmv70q8rb1qcicbily35pa2k")
    (crate-source "windows-core" "0.52.0" "1nc3qv7sy24x0nlnb32f7alzpd6f72l4p24vl65vydbyil669ark")
    (crate-source "windows-sys" "0.52.0" "0gd3v4ji88490zgb6b5mq5zgbvwv7zx1ibn8v3x83rwcdbryaar8")
    (crate-source "windows-sys" "0.59.0" "0fw5672ziw8b3zpmnbp9pdv1famk74f1l9fcbc3zsrzdg56vqf0y")
    (crate-source "windows-targets" "0.52.6" "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv")
    (crate-source "windows_aarch64_gnullvm" "0.52.6" "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j")
    (crate-source "windows_aarch64_msvc" "0.52.6" "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09")
    (crate-source "windows_i686_gnu" "0.52.6" "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf")
    (crate-source "windows_i686_gnullvm" "0.52.6" "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf")
    (crate-source "windows_i686_msvc" "0.52.6" "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294")
    (crate-source "windows_x86_64_gnu" "0.52.6" "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl")
    (crate-source "windows_x86_64_gnullvm" "0.52.6" "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94")
    (crate-source "windows_x86_64_msvc" "0.52.6" "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq")
    (crate-source "winnow" "0.7.2" "00znis68117jk13aw41g048wvvv3h0xw5jmhlg8rh8cg2vm0ssar")
    (crate-source "xml-rs" "0.8.25" "1i73ajf6scni5bi1a51r19xykgrambdx5fkks0fyg5jqqbml1ff5")
    (crate-source "zerocopy" "0.7.35" "1w36q7b9il2flg0qskapgi9ymgg7p985vniqd09vi0mwib8lz6qv")
    (crate-source "zerocopy-derive" "0.7.35" "0gnf2ap2y92nwdalzz3x7142f2b83sni66l39vxp2ijd6j080kzs")
    (crate-source "zune-core" "0.4.12" "0jj1ra86klzlcj9aha9als9d1dzs7pqv3azs1j3n96822wn3lhiz")
    (crate-source "zune-inflate" "0.2.54" "00kg24jh3zqa3i6rg6yksnb71bch9yi1casqydl00s7nw8pk7avk")
    (crate-source "zune-jpeg" "0.4.14" "0a70sbnxxkgfm777i1xjkhyn8mx07swg5cabbi083pyysywbm9cr")))

(define-public hyprland-preview-share-picker
  (package
    (name "hyprland-preview-share-picker")
    ;; The tagged upstream release is v0.2.1; this commit is nine commits
    ;; after that tag.  The requested codingismy11to7 fork has no fork-only
    ;; commits and is nine commits behind canonical WhySoBad at this revision.
    (version (git-version "0.2.1" "9"
                          %hyprland-preview-share-picker-commit))
    ;; Track canonical upstream, including its pinned hyprland-protocols
    ;; submodule.
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/WhySoBad/hyprland-preview-share-picker")
             (commit %hyprland-preview-share-picker-commit)
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1cvz0vjza2vxzng5zrddaq913q9c4kgbzx0q8kchz1qczq7r2kjw"))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; The upstream source uses let-chain syntax.  It was unstable in the
      ;; channel's default Rust 1.85 compiler; Rust 1.88 is the first stable
      ;; compiler in this channel that accepts it.
      #:rust rust-1.88
      ;; This is a binary desktop application; do not try to package its
      ;; non-workspace local helper crate as an installable Cargo source.
      #:install-source? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'provide-git-metadata
            (lambda _
              ;; The source build script obtains the displayed version and
              ;; commit subject by invoking git.  git metadata is intentionally
              ;; absent from Guix checkouts, so provide the exact immutable
              ;; tag-distance and subject recorded by the pinned commit.
              (mkdir-p "guix-build-bin")
              (call-with-output-file "guix-build-bin/git"
                (lambda (port)
                  (display "#!/bin/sh\n"
                           port)
                  (display "if test \"$1\" = describe; then\n"
                           port)
                  (display "  printf '%s\\n' 'v0.2.1-9-ge2f30ff'\n"
                           port)
                  (display "elif test \"$1\" = log; then\n"
                           port)
                  (display
                   (string-append
                    "  printf '%s\\n' '[merge: ignore disabled monitors "
                    "for offset calculation (#19)]'\n")
                   port)
                  (display "else\n  exit 1\nfi\n" port)))
              (chmod "guix-build-bin/git" #o755)
              (setenv "PATH"
                      (string-append (getcwd) "/guix-build-bin:"
                                     (or (getenv "PATH") "")))))
          (add-after 'install 'install-schema
            (lambda _
              ;; The schema subcommand prints JSON to stdout.  Capture it
              ;; directly at its final immutable destination rather than
              ;; relying on cargo's temporary build directory.
              (let ((schema-directory
                     (string-append #$output
                                    "/share/hyprland-preview-share-picker")))
                (mkdir-p schema-directory)
              (invoke "sh" "-c"
                      (string-append #$output
                                     "/bin/hyprland-preview-share-picker schema > "
                                     schema-directory
                                     "/schema.json"))))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (append (list glib gtk gtk4-layer-shell)
             %hyprland-preview-share-picker-cargo-inputs))
    (synopsis "GTK4 screencast picker with Hyprland window previews")
    (description
     "Hyprland Preview Share Picker is a GTK4 application used by the
Hyprland desktop portal as a screencast picker.  It presents previews of
windows and outputs, supports selecting a screen region, and can restore the
portal's share token.  The package includes the generated JSON schema for its
YAML configuration under @file{share/hyprland-preview-share-picker}.")
    (home-page
     "https://github.com/WhySoBad/hyprland-preview-share-picker")
    (license license:expat)))
