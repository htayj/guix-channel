;;; GNU Guix package for Pommersche92/durthang, a terminal MUD client.
;;; SPDX-License-Identifier: GPL-3.0-only
;;;
;;; Cargo 1.88 regenerates the v0.2.0 lockfile from the fully enumerated,
;;; hash-pinned vendor graph during the build.  That regeneration is offline;
;;; every build, test, and install invocation then uses the resulting lockfile
;;; with --offline --locked.
;;;
;;; Durthang's upstream keyring features are extended with keyring's
;;; crypto-openssl backend.  Secret Service transport therefore uses its
;;; negotiated encrypted session format rather than EncryptionType::Plain.
;;; A Secret Service daemon (for example gnome-keyring or KWallet) remains
;;; responsible for access control and persistent credential storage; no
;;; plaintext, mock, or file credential backend is enabled by this package.

(define-module (tay packages durthang)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages tls))

(define rust-aho-corasick-1.1.4
  (crate-source "aho-corasick" "1.1.4"
                "00a32wb2h07im3skkikc495jvncf62jl6s96vwc7bhi70h9imlyx"))

(define rust-allocator-api2-0.2.21
  (crate-source "allocator-api2" "0.2.21"
                "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8"))

(define rust-anstream-1.0.0
  (crate-source "anstream" "1.0.0"
                "13d2bj0xfg012s4rmq44zc8zgy1q8k9yp7yhvfnarscnmwpj2jl2"))

(define rust-anstyle-1.0.14
  (crate-source "anstyle" "1.0.14"
                "0030szmgj51fxkic1hpakxxgappxzwm6m154a3gfml83lq63l2wl"))

(define rust-anstyle-parse-1.0.0
  (crate-source "anstyle-parse" "1.0.0"
                "03hkv2690s0crssbnmfkr76kw1k7ah2i6s5amdy9yca2n8w7zkjj"))

(define rust-anstyle-query-1.1.5
  (crate-source "anstyle-query" "1.1.5"
                "1p6shfpnbghs6jsa0vnqd8bb8gd7pjd0jr7w0j8jikakzmr8zi20"))

(define rust-anstyle-wincon-3.0.11
  (crate-source "anstyle-wincon" "3.0.11"
                "0zblannm70sk3xny337mz7c6d8q8i24vhbqi42ld8v7q1wjnl7i9"))

(define rust-anyhow-1.0.102
  (crate-source "anyhow" "1.0.102"
                "0b447dra1v12z474c6z4jmicdmc5yxz5bakympdnij44ckw2s83z"))

(define rust-atomic-0.6.1
  (crate-source "atomic" "0.6.1"
                "0h43ljcgbl6vk62hs6yk7zg7qn3myzvpw8k7isb9nzhkbdvvz758"))

(define rust-autocfg-1.5.0
  (crate-source "autocfg" "1.5.0"
                "1s77f98id9l4af4alklmzq46f21c980v13z2r1pcxx6bqgw0d1n0"))

(define rust-aws-lc-rs-1.16.1
  (crate-source "aws-lc-rs" "1.16.1"
                "1gzlb3c82vv3b9adi15kqpk8wps699rjssc3ijkc42pidl0grgwl"))

(define rust-aws-lc-sys-0.38.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "aws-lc-sys" "0.38.0"
                "0bkqm9adn7f8c8hd3dnp16cgh39cgjckfzqs55ymmfw9xmlfa8a3"))

(define rust-base64-0.22.1
  (crate-source "base64" "0.22.1"
                "1imqzgh7bxcikp5vx3shqvw9j09g9ly0xr0jma0q66i52r7jbcvj"))

(define rust-bit-set-0.5.3
  (crate-source "bit-set" "0.5.3"
                "1wcm9vxi00ma4rcxkl3pzzjli6ihrpn9cfdi0c5b4cvga2mxs007"))

(define rust-bit-vec-0.6.3
  (crate-source "bit-vec" "0.6.3"
                "1ywqjnv60cdh1slhz67psnp422md6jdliji6alq0gmly2xm9p7rl"))

(define rust-bitflags-1.3.2
  (crate-source "bitflags" "1.3.2"
                "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy"))

(define rust-bitflags-2.11.0
  (crate-source "bitflags" "2.11.0"
                "1bwjibwry5nfwsfm9kjg2dqx5n5nja9xymwbfl6svnn8jsz6ff44"))

(define rust-block-buffer-0.10.4
  (crate-source "block-buffer" "0.10.4"
                "0w9sa2ypmrsqqvc20nhwr75wbb5cjr4kkyhpjm1z1lv2kdicfy1h"))

(define rust-bumpalo-3.20.2
  (crate-source "bumpalo" "3.20.2"
                "1jrgxlff76k9glam0akhwpil2fr1w32gbjdf5hpipc7ld2c7h82x"))

(define rust-bytemuck-1.25.0
  (crate-source "bytemuck" "1.25.0"
                "1v1z32igg9zq49phb3fra0ax5r2inf3aw473vldnm886sx5vdvy8"))

(define rust-bytes-1.11.1
  (crate-source "bytes" "1.11.1"
                "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y"))

(define rust-castaway-0.2.4
  (crate-source "castaway" "0.2.4"
                "0nn5his5f8q20nkyg1nwb40xc19a08yaj4y76a8q2y3mdsmm3ify"))

(define rust-cc-1.2.57
  (crate-source "cc" "1.2.57"
                "08q464b62d03zm7rgiixavkrh5lzfq18lwf884vgycj9735d23bs"))

(define rust-cfg-if-1.0.4
  (crate-source "cfg-if" "1.0.4"
                "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k"))

(define rust-cfg-aliases-0.2.1
  (crate-source "cfg_aliases" "0.2.1"
                "092pxdc1dbgjb6qvh83gk56rkic2n2ybm4yvy76cgynmzi3zwfk1"))

(define rust-clap-4.6.0
  (crate-source "clap" "4.6.0"
                "0l8k0ja5rf4hpn2g98bqv5m6lkh2q6b6likjpmm6fjw3cxdsz4xi"))

(define rust-clap-builder-4.6.0
  (crate-source "clap_builder" "4.6.0"
                "17q6np22yxhh5y5v53y4l31ps3hlaz45mvz2n2nicr7n3c056jki"))

(define rust-clap-derive-4.6.0
  (crate-source "clap_derive" "4.6.0"
                "0snapc468s7n3avr33dky4y7rmb7ha3qsp9l0k5vh6jacf5bs40i"))

(define rust-clap-lex-1.1.0
  (crate-source "clap_lex" "1.1.0"
                "1ycqkpygnlqnndghhcxjb44lzl0nmgsia64x9581030yifxs7m68"))

(define rust-cmake-0.1.57
  (crate-source "cmake" "0.1.57"
                "0zgg10qgykig4nxyf7whrqfg7fkk0xfxhiavikmrndvbrm23qi3m"))

(define rust-colorchoice-1.0.5
  (crate-source "colorchoice" "1.0.5"
                "0w75k89hw39p0mnnhlrwr23q50rza1yjki44qvh2mgrnj065a1qx"))

(define rust-compact-str-0.9.0
  (crate-source "compact_str" "0.9.0"
                "0ykhh2scg32lmzxak107pmby6fmnz7qbhsi9i8g9iknfl4ji7nrz"))

(define rust-convert-case-0.10.0
  (crate-source "convert_case" "0.10.0"
                "1fff1x78mp2c233g68my0ag0zrmjdbym8bfyahjbfy4cxza5hd33"))

(define rust-core-foundation-0.10.1
  (crate-source "core-foundation" "0.10.1"
                "1xjns6dqf36rni2x9f47b65grxwdm20kwdg9lhmzdrrkwadcv9mj"))

(define rust-core-foundation-sys-0.8.7
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "core-foundation-sys" "0.8.7"
                "12w8j73lazxmr1z0h98hf3z623kl8ms7g07jch7n4p8f9nwlhdkp"))

(define rust-cpufeatures-0.2.17
  (crate-source "cpufeatures" "0.2.17"
                "10023dnnaghhdl70xcds12fsx2b966sxbxjq5sxs49mvxqw5ivar"))

(define rust-crossterm-0.29.0
  (crate-source "crossterm" "0.29.0"
                "0yzqxxd90k7d2ac26xq1awsznsaq0qika2nv1ik3p0vzqvjg5ffq"))

(define rust-crossterm-winapi-0.9.1
  (crate-source "crossterm_winapi" "0.9.1"
                "0axbfb2ykbwbpf1hmxwpawwfs8wvmkcka5m561l7yp36ldi7rpdc"))

(define rust-crypto-common-0.1.7
  (crate-source "crypto-common" "0.1.7"
                "02nn2rhfy7kvdkdjl457q2z0mklcvj9h662xrq6dzhfialh2kj3q"))

(define rust-csscolorparser-0.6.2
  (crate-source "csscolorparser" "0.6.2"
                "1gxh11hajx96mf5sd0az6mfsxdryfqvcfcphny3yfbfscqq7sapb"))

(define rust-darling-0.23.0
  (crate-source "darling" "0.23.0"
                "179fj6p6ajw4dnkrik51wjhifxwy02x5zhligyymcb905zd17bi5"))

(define rust-darling-core-0.23.0
  (crate-source "darling_core" "0.23.0"
                "1c033vrks38vpw8kwgd5w088dsr511kfz55n9db56prkgh7sarcq"))

(define rust-darling-macro-0.23.0
  (crate-source "darling_macro" "0.23.0"
                "13fvzji9xyp304mgq720z5l0xgm54qj68jibwscagkynggn88fdc"))

(define rust-dbus-0.9.11
  (crate-source "dbus" "0.9.11"
                "0wxzld0baycxa4z6zrmnh68yy456b0f82j8wyp8wyymvj8ln0hmr"))

(define rust-dbus-secret-service-4.1.0
  (crate-source "dbus-secret-service" "4.1.0"
                "19jgbqb841kbzmfgaqnbbhsc5ijck7fzl3zvgqyyb2bqvyg512vh"))

(define rust-deltae-0.3.2
  (crate-source "deltae" "0.3.2"
                "1d3hw9hpvicl9x0x34jr2ybjk5g5ym1lhbyz6zj31110gq8zaaap"))

(define rust-deranged-0.5.8
  (crate-source "deranged" "0.5.8"
                "0711df3w16vx80k55ivkwzwswziinj4dz05xci3rvmn15g615n3w"))

(define rust-derive-more-2.1.1
  (crate-source "derive_more" "2.1.1"
                "0d5i10l4aff744jw7v4n8g6cv15rjk5mp0f1z522pc2nj7jfjlfp"))

(define rust-derive-more-impl-2.1.1
  (crate-source "derive_more-impl" "2.1.1"
                "1jwdp836vymp35d7mfvvalplkdgk2683nv3zjlx65n1194k9g6kr"))

(define rust-digest-0.10.7
  (crate-source "digest" "0.10.7"
                "14p2n6ih29x81akj097lvz7wi9b6b9hvls0lwrv7b6xwyy0s5ncy"))

(define rust-document-features-0.2.12
  (crate-source "document-features" "0.2.12"
                "0qcgpialq3zgvjmsvar9n6v10rfbv6mk6ajl46dd4pj5hn3aif6l"))

(define rust-dunce-1.0.5
  (crate-source "dunce" "1.0.5"
                "04y8wwv3vvcqaqmqzssi6k0ii9gs6fpz96j5w9nky2ccsl23axwj"))

(define rust-either-1.15.0
  (crate-source "either" "1.15.0"
                "069p1fknsmzn9llaizh77kip0pqmcwpdsykv2x30xpjyija5gis8"))

(define rust-equivalent-1.0.2
  (crate-source "equivalent" "1.0.2"
                "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"))

(define rust-errno-0.3.14
  (crate-source "errno" "0.3.14"
                "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir"))

(define rust-euclid-0.22.14
  (crate-source "euclid" "0.22.14"
                "01ksjl4vb8ms89laswnjpld3z4n6c1s7qlqq0djx3imiwdjm787i"))

(define rust-fancy-regex-0.11.0
  (crate-source "fancy-regex" "0.11.0"
                "18j0mmzfycibhxhhhfja00dxd1vf8x5c28lbry224574h037qpxr"))

(define rust-fastrand-2.5.0
  (crate-source "fastrand" "2.5.0"
                "08q2r30y62winysimnlpbvw9kiwn0rmdlidqlmzd6z90mv764z6s"))

(define rust-filedescriptor-0.8.3
  (crate-source "filedescriptor" "0.8.3"
                "0bb8qqa9h9sj2mzf09yqxn260qkcqvmhmyrmdjvyxcn94knmh1z4"))

(define rust-find-msvc-tools-0.1.9
  (crate-source "find-msvc-tools" "0.1.9"
                "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv"))

(define rust-finl-unicode-1.4.0
  (crate-source "finl_unicode" "1.4.0"
                "1md4j32sa8g6y7q9yphpslhhjdjxig1bczkjp8mxccz5lv1xsi4q"))

(define rust-fixedbitset-0.4.2
  (crate-source "fixedbitset" "0.4.2"
                "101v41amgv5n9h4hcghvrbfk5vrncx1jwm35rn5szv4rk55i7rqc"))

(define rust-fnv-1.0.7
  (crate-source "fnv" "1.0.7"
                "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz"))

(define rust-foldhash-0.1.5
  (crate-source "foldhash" "0.1.5"
                "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r"))

(define rust-foldhash-0.2.0
  (crate-source "foldhash" "0.2.0"
                "1nvgylb099s11xpfm1kn2wcsql080nqmnhj1l25bp3r2b35j9kkp"))

(define rust-foreign-types-0.3.2
  (crate-source "foreign-types" "0.3.2"
                "1cgk0vyd7r45cj769jym4a6s7vwshvd0z4bqrb92q1fwibmkkwzn"))

(define rust-foreign-types-shared-0.1.1
  (crate-source "foreign-types-shared" "0.1.1"
                "0jxgzd04ra4imjv8jgkmdq59kj8fsz6w4zxsbmlai34h26225c00"))

(define rust-fs-extra-1.3.0
  (crate-source "fs_extra" "1.3.0"
                "075i25z70j2mz9r7i9p9r521y8xdj81q7skslyb7zhqnnw33fw22"))

(define rust-generic-array-0.14.7
  (crate-source "generic-array" "0.14.7"
                "16lyyrzrljfq424c3n8kfwkqihlimmsg5nhshbbp48np3yjrqr45"))

(define rust-getrandom-0.2.17
  (crate-source "getrandom" "0.2.17"
                "1l2ac6jfj9xhpjjgmcx6s1x89bbnw9x6j9258yy6xjkzpq0bqapz"))

(define rust-getrandom-0.3.4
  (crate-source "getrandom" "0.3.4"
                "1zbpvpicry9lrbjmkd4msgj3ihff1q92i334chk7pzf46xffz7c9"))

(define rust-getrandom-0.4.2
  (crate-source "getrandom" "0.4.2"
                "0mb5833hf9pvn9dhvxjgfg5dx0m77g8wavvjdpvpnkp9fil1xr8d"))

(define rust-hashbrown-0.15.5
  (crate-source "hashbrown" "0.15.5"
                "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj"))

(define rust-hashbrown-0.16.1
  (crate-source "hashbrown" "0.16.1"
                "004i3njw38ji3bzdp9z178ba9x3k0c1pgy8x69pj7yfppv4iq7c4"))

(define rust-heck-0.5.0
  (crate-source "heck" "0.5.0"
                "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113"))

(define rust-hex-0.4.3
  (crate-source "hex" "0.4.3"
                "0w1a4davm1lgzpamwnba907aysmlrnygbqmfis2mqjx5m552a93z"))

(define rust-id-arena-2.3.0
  (crate-source "id-arena" "2.3.0"
                "0m6rs0jcaj4mg33gkv98d71w3hridghp5c4yr928hplpkgbnfc1x"))

(define rust-ident-case-1.0.1
  (crate-source "ident_case" "1.0.1"
                "0fac21q6pwns8gh1hz3nbq15j8fi441ncl6w4vlnd1cmc55kiq5r"))

(define rust-indexmap-2.13.0
  (crate-source "indexmap" "2.13.0"
                "05qh5c4h2hrnyypphxpwflk45syqbzvqsvvyxg43mp576w2ff53p"))

(define rust-indoc-2.0.7
  (crate-source "indoc" "2.0.7"
                "01np60qdq6lvgh8ww2caajn9j4dibx9n58rvzf7cya1jz69mrkvr"))

(define rust-instability-0.3.12
  (crate-source "instability" "0.3.12"
                "0wc98mr44w5k1y6pib2x0kydmhbff8gkfgiw36ls684ry47ddcjy"))

(define rust-is-terminal-polyfill-1.70.2
  (crate-source "is_terminal_polyfill" "1.70.2"
                "15anlc47sbz0jfs9q8fhwf0h3vs2w4imc030shdnq54sny5i7jx6"))

(define rust-itertools-0.14.0
  (crate-source "itertools" "0.14.0"
                "118j6l1vs2mx65dqhwyssbrxpawa90886m3mzafdvyip41w2q69b"))

(define rust-itoa-1.0.17
  (crate-source "itoa" "1.0.17"
                "1lh93xydrdn1g9x547bd05g0d3hra7pd1k4jfd2z1pl1h5hwdv4j"))

(define rust-jobserver-0.1.34
  (crate-source "jobserver" "0.1.34"
                "0cwx0fllqzdycqn4d6nb277qx5qwnmjdxdl0lxkkwssx77j3vyws"))

(define rust-js-sys-0.3.91
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "js-sys" "0.3.91"
                "171rzgq33wc1nxkgnvhlqqwwnrifs13mg3jjpjj5nf1z0yvib5xl"))

(define rust-kasuari-0.4.12
  (crate-source "kasuari" "0.4.12"
                "1688q59qh1mxa28k00lnddn73mh3jcdmj3yrc7l99k23c5yhbrdx"))

(define rust-keyring-3.6.3
  (crate-source "keyring" "3.6.3"
                "072mzc4rk2qffdlc8c5s9h38c6fifyr9xxmsix599ra4y2pw7g7f"))

(define rust-lab-0.11.0
  (crate-source "lab" "0.11.0"
                "13ymsn5cwl5i9pmp5mfmbap7q688dcp9a17q82crkvb784yifdmz"))

(define rust-lazy-static-1.5.0
  (crate-source "lazy_static" "1.5.0"
                "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"))

(define rust-leb128fmt-0.1.0
  (crate-source "leb128fmt" "0.1.0"
                "1chxm1484a0bly6anh6bd7a99sn355ymlagnwj3yajafnpldkv89"))

(define rust-libc-0.2.183
  (crate-source "libc" "0.2.183"
                "17c9gyia7rrzf9gsssvk3vq9ca2jp6rh32fsw6ciarpn5djlddmm"))

(define rust-libdbus-sys-0.2.7
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "libdbus-sys" "0.2.7"
                "0hzhq0dz6lfzmhsym9m95cfhjzrwq74qdg85xkpg2012sj4lg31j"))

(define rust-line-clipping-0.3.5
  (crate-source "line-clipping" "0.3.5"
                "0jlakbyjc5sh4j2lx2glyjar3wqq9mqifkdzbhvhkgyxk17f8kaz"))

(define rust-linux-keyutils-0.2.5
  (crate-source "linux-keyutils" "0.2.5"
                "142m9n38ldn8f4783wgkwv068yx7mppkb7qyqh3hf3grx4c0l9w3"))

(define rust-linux-raw-sys-0.12.1
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "linux-raw-sys" "0.12.1"
                "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij"))

(define rust-litrs-1.0.0
  (crate-source "litrs" "1.0.0"
                "14p0kzzkavnngvybl88nvfwv031cc2qx4vaxpfwsiifm8grdglqi"))

(define rust-lock-api-0.4.14
  (crate-source "lock_api" "0.4.14"
                "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2"))

(define rust-log-0.4.29
  (crate-source "log" "0.4.29"
                "15q8j9c8g5zpkcw0hnd6cf2z7fxqnvsjh3rw5mv5q10r83i34l2y"))

(define rust-lru-0.16.3
  (crate-source "lru" "0.16.3"
                "14z5yxcp3f63lgw8yxr486g9yz7cfqbmkadfwgw36vy0jbslgp51"))

(define rust-mac-address-1.1.8
  (crate-source "mac_address" "1.1.8"
                "00r3n18mxglq1dzshnm0vxk1fgsp3c2hd08w6hfcqdp8ymmv5bn0"))

(define rust-matchers-0.2.0
  (crate-source "matchers" "0.2.0"
                "1sasssspdj2vwcwmbq3ra18d3qniapkimfcbr47zmx6750m5llni"))

(define rust-memchr-2.8.0
  (crate-source "memchr" "2.8.0"
                "0y9zzxcqxvdqg6wyag7vc3h0blhdn7hkq164bxyx2vph8zs5ijpq"))

(define rust-memmem-0.1.1
  (crate-source "memmem" "0.1.1"
                "05ccifqgxdfxk6yls41ljabcccsz3jz6549l1h3cwi17kr494jm6"))

(define rust-memoffset-0.9.1
  (crate-source "memoffset" "0.9.1"
                "12i17wh9a9plx869g7j4whf62xw68k5zd4k0k5nh6ys5mszid028"))

(define rust-minimal-lexical-0.2.1
  (crate-source "minimal-lexical" "0.2.1"
                "16ppc5g84aijpri4jzv14rvcnslvlpphbszc7zzp6vfkddf4qdb8"))

(define rust-mio-1.1.1
  (crate-source "mio" "1.1.1"
                "1z2phpalqbdgihrcjp8y09l3kgq6309jnhnr6h11l9s7mnqcm6x6"))

(define rust-nix-0.29.0
  (crate-source "nix" "0.29.0"
                "0ikvn7s9r2lrfdm3mx1h7nbfjvcc6s9vxdzw7j5xfkd2qdnp9qki"))

(define rust-nom-7.1.3
  (crate-source "nom" "7.1.3"
                "0jha9901wxam390jcf5pfa0qqfrgh8li787jx2ip0yk5b8y9hwyj"))

(define rust-nu-ansi-term-0.50.3
  (crate-source "nu-ansi-term" "0.50.3"
                "1ra088d885lbd21q1bxgpqdlk1zlndblmarn948jz2a40xsbjmvr"))

(define rust-num-conv-0.2.0
  (crate-source "num-conv" "0.2.0"
                "0l4hj7lp8zbb9am4j3p7vlcv47y9bbazinvnxx9zjhiwkibyr5yg"))

(define rust-num-0.4.3
  (crate-source "num" "0.4.3"
                "08yb2fc1psig7pkzaplm495yp7c30m4pykpkwmi5bxrgid705g9m"))

(define rust-num-bigint-0.4.8
  (crate-source "num-bigint" "0.4.8"
                "0ry3xjal8f5xhdinani268ci13h14mf7j4w0y1gflfzhw3knk7n8"))

(define rust-num-complex-0.4.6
  (crate-source "num-complex" "0.4.6"
                "15cla16mnw12xzf5g041nxbjjm9m85hdgadd5dl5d0b30w9qmy3k"))

(define rust-num-integer-0.1.47
  (crate-source "num-integer" "0.1.47"
                "02z1p3azy6p10n99skrab4a6hhfd4amf2i9gm8sxqd1p9dfxkqkw"))

(define rust-num-iter-0.1.46
  (crate-source "num-iter" "0.1.46"
                "12q4x0lp9l6bvsak1p5q24lvfzl99ak9vzmwhqbwksm1d6yh0a69"))

(define rust-num-rational-0.4.2
  (crate-source "num-rational" "0.4.2"
                "093qndy02817vpgcqjnj139im3jl7vkq4h68kykdqqh577d18ggq"))

(define rust-num-derive-0.4.2
  (crate-source "num-derive" "0.4.2"
                "00p2am9ma8jgd2v6xpsz621wc7wbn1yqi71g15gc3h67m7qmafgd"))

(define rust-num-traits-0.2.19
  (crate-source "num-traits" "0.2.19"
                "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787"))

(define rust-num-threads-0.1.7
  (crate-source "num_threads" "0.1.7"
                "1ngajbmhrgyhzrlc4d5ga9ych1vrfcvfsiqz6zv0h2dpr2wrhwsw"))

(define rust-once-cell-1.21.4
  (crate-source "once_cell" "1.21.4"
                "0l1v676wf71kjg2khch4dphwh1jp3291ffiymr2mvy1kxd5kwz4z"))

(define rust-once-cell-polyfill-1.70.2
  (crate-source "once_cell_polyfill" "1.70.2"
                "1zmla628f0sk3fhjdjqzgxhalr2xrfna958s632z65bjsfv8ljrq"))

(define rust-openssl-probe-0.2.1
  (crate-source "openssl-probe" "0.2.1"
                "1gpwpb7smfhkscwvbri8xzbab39wcnby1jgz1s49vf1aqgsdx1vw"))

(define rust-openssl-0.10.81
  (crate-source "openssl" "0.10.81"
                "0ibsv2ppsjrp62jqyzprhay9vczk1bw9xvdr3h4h7fxsy0kkm0kp"))

(define rust-openssl-macros-0.1.1
  (crate-source "openssl-macros" "0.1.1"
                "173xxvfc63rr5ybwqwylsir0vq6xsj4kxiv4hmg4c3vscdmncj59"))

(define rust-openssl-sys-0.9.117
  (crate-source "openssl-sys" "0.9.117"
                "159nf6jsqnmsynkh6gjzx088q1ifll7v88sss8qdk363n9mpwzml"))

(define rust-ordered-float-4.6.0
  (crate-source "ordered-float" "4.6.0"
                "0ldrcgilsiijd141vw51fbkziqmh5fpllil3ydhirjm67wdixdvv"))

(define rust-parking-lot-0.12.5
  (crate-source "parking_lot" "0.12.5"
                "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck"))

(define rust-parking-lot-core-0.9.12
  (crate-source "parking_lot_core" "0.9.12"
                "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896"))

(define rust-pest-2.8.6
  (crate-source "pest" "2.8.6"
                "0qm6kpqsbn2p6vkd7v4j3g7wsjby2ip6di1h6kx7vlq921h8r170"))

(define rust-pest-derive-2.8.6
  (crate-source "pest_derive" "2.8.6"
                "0xzysvcyfs0pkn2801rg811y83jx2rvpqnjxs47c3ri1xbqqdx0i"))

(define rust-pest-generator-2.8.6
  (crate-source "pest_generator" "2.8.6"
                "0kzrcik2ww0qh84jlv8xqc0zmzgl3xy41vf1cfli1chkgdjc8h40"))

(define rust-pest-meta-2.8.6
  (crate-source "pest_meta" "2.8.6"
                "08126skq2lxysinp6v917niszhnnh6d6a9kg2i0a28b0sdlmr0c9"))

(define rust-phf-0.11.3
  (crate-source "phf" "0.11.3"
                "0y6hxp1d48rx2434wgi5g8j1pr8s5jja29ha2b65435fh057imhz"))

(define rust-phf-codegen-0.11.3
  (crate-source "phf_codegen" "0.11.3"
                "0si1n6zr93kzjs3wah04ikw8z6npsr39jw4dam8yi9czg2609y5f"))

(define rust-phf-generator-0.11.3
  (crate-source "phf_generator" "0.11.3"
                "0gc4np7s91ynrgw73s2i7iakhb4lzdv1gcyx7yhlc0n214a2701w"))

(define rust-phf-macros-0.11.3
  (crate-source "phf_macros" "0.11.3"
                "05kjfbyb439344rhmlzzw0f9bwk9fp95mmw56zs7yfn1552c0jpq"))

(define rust-phf-shared-0.11.3
  (crate-source "phf_shared" "0.11.3"
                "1rallyvh28jqd9i916gk5gk2igdmzlgvv5q0l3xbf3m6y8pbrsk7"))

(define rust-pin-project-lite-0.2.17
  (crate-source "pin-project-lite" "0.2.17"
                "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8"))

(define rust-pkg-config-0.3.33
  (crate-source "pkg-config" "0.3.33"
                "17jnqmcbxsnwhg9gjf0nh6dj5k0x3hgwi3mb9krjnmfa9v435w8r"))

(define rust-portable-atomic-1.13.1
  (crate-source "portable-atomic" "1.13.1"
                "0j8vlar3n5acyigq8q6f4wjx3k3s5yz0rlpqrv76j73gi5qr8fn3"))

(define rust-powerfmt-0.2.0
  (crate-source "powerfmt" "0.2.0"
                "14ckj2xdpkhv3h6l5sdmb9f1d57z8hbfpdldjc2vl5givq2y77j3"))

(define rust-prettyplease-0.2.37
  (crate-source "prettyplease" "0.2.37"
                "0azn11i1kh0byabhsgab6kqs74zyrg69xkirzgqyhz6xmjnsi727"))

(define rust-proc-macro2-1.0.106
  (crate-source "proc-macro2" "1.0.106"
                "0d09nczyaj67x4ihqr5p7gxbkz38gxhk4asc0k8q23g9n85hzl4g"))

(define rust-quote-1.0.45
  (crate-source "quote" "1.0.45"
                "095rb5rg7pbnwdp6v8w5jw93wndwyijgci1b5lw8j1h5cscn3wj1"))

(define rust-r-efi-5.3.0
  (crate-source "r-efi" "5.3.0"
                "03sbfm3g7myvzyylff6qaxk4z6fy76yv860yy66jiswc2m6b7kb9"))

(define rust-r-efi-6.0.0
  (crate-source "r-efi" "6.0.0"
                "1gyrl2k5fyzj9k7kchg2n296z5881lg7070msabid09asp3wkp7q"))

(define rust-rand-0.8.5
  (crate-source "rand" "0.8.5"
                "013l6931nn7gkc23jz5mm3qdhf93jjf0fg64nz2lp4i51qd8vbrl"))

(define rust-rand-core-0.6.4
  (crate-source "rand_core" "0.6.4"
                "0b4j2v4cb5krak1pv6kakv4sz6xcwbrmy2zckc32hsigbrwy82zc"))

(define rust-ratatui-0.30.0
  (crate-source "ratatui" "0.30.0"
                "1g36h96fnr8ay7bmwplxsfa5xzsp0pdaxny8s5a68i54igxngkni"))

(define rust-ratatui-core-0.1.0
  (crate-source "ratatui-core" "0.1.0"
                "14y2pv5njy7kpzjsfn20a8vmjbhnfq5vgbgppxrszjljkahdxy2y"))

(define rust-ratatui-crossterm-0.1.0
  (crate-source "ratatui-crossterm" "0.1.0"
                "1cslvh75a29gdmz84s5sjaqd61k4s0fkjsjwn8gi4k1bcngrnz2p"))

(define rust-ratatui-macros-0.7.0
  (crate-source "ratatui-macros" "0.7.0"
                "1x1nr4wyyhchms9chj10b3wk7ribfvmd14xps2wlngp82cm39wd7"))

(define rust-ratatui-termwiz-0.1.0
  (crate-source "ratatui-termwiz" "0.1.0"
                "0p2l7pymlcfv9n802pd32m604m145rrpc5hv6bq9ahpds05zwxhg"))

(define rust-ratatui-widgets-0.3.0
  (crate-source "ratatui-widgets" "0.3.0"
                "1nqjcrskazvfgjkmmsifliqrvap8bw6850rlap109rnl7h1gmnyp"))

(define rust-redox-syscall-0.5.18
  (crate-source "redox_syscall" "0.5.18"
                "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd"))

(define rust-regex-1.12.3
  (crate-source "regex" "1.12.3"
                "0xp2q0x7ybmpa5zlgaz00p8zswcirj9h8nry3rxxsdwi9fhm81z1"))

(define rust-regex-automata-0.4.14
  (crate-source "regex-automata" "0.4.14"
                "13xf7hhn4qmgfh784llcp2kzrvljd13lb2b1ca0mwnf15w9d87bf"))

(define rust-regex-syntax-0.8.10
  (crate-source "regex-syntax" "0.8.10"
                "02jx311ka0daxxc7v45ikzhcl3iydjbbb0mdrpc1xgg8v7c7v2fw"))

(define rust-ring-0.17.14
  (crate-source "ring" "0.17.14"
                "1dw32gv19ccq4hsx3ribhpdzri1vnrlcfqb2vj41xn4l49n9ws54"))

(define rust-rustc-version-0.4.1
  (crate-source "rustc_version" "0.4.1"
                "14lvdsmr5si5qbqzrajgb6vfn69k0sfygrvfvr2mps26xwi3mjyg"))

(define rust-rustix-1.1.4
  (crate-source "rustix" "1.1.4"
                "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn"))

(define rust-rustls-0.23.37
  (crate-source "rustls" "0.23.37"
                "193k5h0wcih6ghvkrxyzwncivr1bd3a8yw3lzp13pzfcbz5jb03m"))

(define rust-rustls-native-certs-0.8.3
  (crate-source "rustls-native-certs" "0.8.3"
                "0qrajg2n90bcr3bcq6j95gjm7a9lirfkkdmjj32419dyyzan0931"))

(define rust-rustls-pki-types-1.14.0
  (crate-source "rustls-pki-types" "1.14.0"
                "1p9zsgslvwzzkzhm6bqicffqndr4jpx67992b0vl0pi21a5hy15y"))

(define rust-rustls-webpki-0.103.9
  (crate-source "rustls-webpki" "0.103.9"
                "0lwg1nnyv7pp2lfwwjhy81bxm233am99jnsp3iymdhd6k8827pyp"))

(define rust-rustversion-1.0.22
  (crate-source "rustversion" "1.0.22"
                "0vfl70jhv72scd9rfqgr2n11m5i9l1acnk684m2w83w0zbqdx75k"))

(define rust-ryu-1.0.23
  (crate-source "ryu" "1.0.23"
                "0zs70sg00l2fb9jwrf6cbkdyscjs53anrvai2hf7npyyfi5blx4p"))

(define rust-schannel-0.1.29
  (crate-source "schannel" "0.1.29"
                "0ffrzz5vf2s3gnzvphgb5gg8fqifvryl07qcf7q3x1scj3jbghci"))

(define rust-scopeguard-1.2.0
  (crate-source "scopeguard" "1.2.0"
                "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l"))

(define rust-security-framework-3.7.0
  (crate-source "security-framework" "3.7.0"
                "07fd0j29j8yczb3hd430vwz784lx9knb5xwbvqna1nbkbivvrx5p"))

(define rust-security-framework-sys-2.17.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "security-framework-sys" "2.17.0"
                "1qr0w0y9iwvmv3hwg653q1igngnc5b74xcf0679cbv23z0fnkqkc"))

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

(define rust-serde-json-1.0.149
  (crate-source "serde_json" "1.0.149"
                "11jdx4vilzrjjd1dpgy67x5lgzr0laplz30dhv75lnf5ffa07z43"))

(define rust-serde-spanned-0.6.9
  (crate-source "serde_spanned" "0.6.9"
                "18vmxq6qfrm110caszxrzibjhy2s54n1g5w1bshxq9kjmz7y0hdz"))

(define rust-sha2-0.10.9
  (crate-source "sha2" "0.10.9"
                "10xjj843v31ghsksd9sl9y12qfc48157j1xpb8v1ml39jy0psl57"))

(define rust-sharded-slab-0.1.7
  (crate-source "sharded-slab" "0.1.7"
                "1xipjr4nqsgw34k7a2cgj9zaasl2ds6jwn89886kww93d32a637l"))

(define rust-shlex-1.3.0
  (crate-source "shlex" "1.3.0"
                "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg"))

(define rust-signal-hook-0.3.18
  (crate-source "signal-hook" "0.3.18"
                "1qnnbq4g2vixfmlv28i1whkr0hikrf1bsc4xjy2aasj2yina30fq"))

(define rust-signal-hook-mio-0.2.5
  (crate-source "signal-hook-mio" "0.2.5"
                "1k20rr76ngvmzr6kskkl7dv8iyb84cbydpjbjk3mpcj0lykijnmp"))

(define rust-signal-hook-registry-1.4.8
  (crate-source "signal-hook-registry" "1.4.8"
                "06vc7pmnki6lmxar3z31gkyg9cw7py5x9g7px70gy2hil75nkny4"))

(define rust-siphasher-1.0.2
  (crate-source "siphasher" "1.0.2"
                "13k7cfbpcm8qgj9p2n8dwg9skv9s0hxk5my30j5chy1p4l78bamj"))

(define rust-smallvec-1.15.1
  (crate-source "smallvec" "1.15.1"
                "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7"))

(define rust-socket2-0.6.3
  (crate-source "socket2" "0.6.3"
                "0gkjjcyn69hqhhlh5kl8byk5m0d7hyrp2aqwzbs3d33q208nwxis"))

(define rust-static-assertions-1.1.0
  (crate-source "static_assertions" "1.1.0"
                "0gsl6xmw10gvn3zs1rv99laj5ig7ylffnh71f9l34js4nr4r7sx2"))

(define rust-strsim-0.11.1
  (crate-source "strsim" "0.11.1"
                "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x"))

(define rust-strum-0.27.2
  (crate-source "strum" "0.27.2"
                "1ksb9jssw4bg9kmv9nlgp2jqa4vnsa3y4q9zkppvl952q7vdc8xg"))

(define rust-strum-macros-0.27.2
  (crate-source "strum_macros" "0.27.2"
                "19xwikxma0yi70fxkcy1yxcv0ica8gf3jnh5gj936jza8lwcx5bn"))

(define rust-subtle-2.6.1
  (crate-source "subtle" "2.6.1"
                "14ijxaymghbl1p0wql9cib5zlwiina7kall6w7g89csprkgbvhhk"))

(define rust-syn-1.0.109
  (crate-source "syn" "1.0.109"
                "0ds2if4600bd59wsv7jjgfkayfzy3hnazs394kz6zdkmna8l3dkj"))

(define rust-syn-2.0.117
  (crate-source "syn" "2.0.117"
                "16cv7c0wbn8amxc54n4w15kxlx5ypdmla8s0gxr2l7bv7s0bhrg6"))

(define rust-terminfo-0.9.0
  (crate-source "terminfo" "0.9.0"
                "0qp6rrzkxcg08vjzsim2bw7mid3vi29mizrg70dzbycj0q7q3snl"))

(define rust-termios-0.3.3
  (crate-source "termios" "0.3.3"
                "0sxcs0g00538jqh5xbdqakkzijadr8nj7zmip0c7jz3k83vmn721"))

(define rust-termwiz-0.23.3
  (crate-source "termwiz" "0.23.3"
                "1xzq6l7rx285ax57dz8gdh44kp1790x0knvfynmimgfc89rb6xj6"))

(define rust-thiserror-1.0.69
  (crate-source "thiserror" "1.0.69"
                "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn"))

(define rust-thiserror-2.0.18
  (crate-source "thiserror" "2.0.18"
                "1i7vcmw9900bvsmay7mww04ahahab7wmr8s925xc083rpjybb222"))

(define rust-thiserror-impl-1.0.69
  (crate-source "thiserror-impl" "1.0.69"
                "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg"))

(define rust-thiserror-impl-2.0.18
  (crate-source "thiserror-impl" "2.0.18"
                "1mf1vrbbimj1g6dvhdgzjmn6q09yflz2b92zs1j9n3k7cxzyxi7b"))

(define rust-thread-local-1.1.9
  (crate-source "thread_local" "1.1.9"
                "1191jvl8d63agnq06pcnarivf63qzgpws5xa33hgc92gjjj4c0pn"))

(define rust-time-0.3.47
  (crate-source "time" "0.3.47"
                "0b7g9ly2iabrlgizliz6v5x23yq5d6bpp0mqz6407z1s526d8fvl"))

(define rust-time-core-0.1.8
  (crate-source "time-core" "0.1.8"
                "1jidl426mw48i7hjj4hs9vxgd9lwqq4vyalm4q8d7y4iwz7y353n"))

(define rust-tokio-1.50.0
  (crate-source "tokio" "1.50.0"
                "0bc2c5kd57p2xd4l6hagb0bkrp798k5vw0f3xzzwy0sf6ws5xb97"))

(define rust-tokio-macros-2.6.1
  (crate-source "tokio-macros" "2.6.1"
                "172nwz3s7mmh266hb8l5xdnc7v9kqahisppqhinfd75nz3ps4maw"))

(define rust-tokio-rustls-0.26.4
  (crate-source "tokio-rustls" "0.26.4"
                "0qggwknz9w4bbsv1z158hlnpkm97j3w8v31586jipn99byaala8p"))

(define rust-toml-0.8.23
  (crate-source "toml" "0.8.23"
                "0qnkrq4lm2sdhp3l6cb6f26i8zbnhqb7mhbmksd550wxdfcyn6yw"))

(define rust-toml-datetime-0.6.11
  (crate-source "toml_datetime" "0.6.11"
                "077ix2hb1dcya49hmi1avalwbixmrs75zgzb3b2i7g2gizwdmk92"))

(define rust-toml-edit-0.22.27
  (crate-source "toml_edit" "0.22.27"
                "16l15xm40404asih8vyjvnka9g0xs9i4hfb6ry3ph9g419k8rzj1"))

(define rust-toml-write-0.1.2
  (crate-source "toml_write" "0.1.2"
                "008qlhqlqvljp1gpp9rn5cqs74gwvdgbvs92wnpq8y3jlz4zi6ax"))

(define rust-tracing-0.1.44
  (crate-source "tracing" "0.1.44"
                "006ilqkg1lmfdh3xhg3z762izfwmxcvz0w7m4qx2qajbz9i1drv3"))

(define rust-tracing-attributes-0.1.31
  (crate-source "tracing-attributes" "0.1.31"
                "1np8d77shfvz0n7camx2bsf1qw0zg331lra0hxb4cdwnxjjwz43l"))

(define rust-tracing-core-0.1.36
  (crate-source "tracing-core" "0.1.36"
                "16mpbz6p8vd6j7sf925k9k8wzvm9vdfsjbynbmaxxyq6v7wwm5yv"))

(define rust-tracing-log-0.2.0
  (crate-source "tracing-log" "0.2.0"
                "1hs77z026k730ij1a9dhahzrl0s073gfa2hm5p0fbl0b80gmz1gf"))

(define rust-tracing-subscriber-0.3.23
  (crate-source "tracing-subscriber" "0.3.23"
                "06fkr0qhggvrs861d7f74pn3i3a10h5jsp4n70jj9ys5b675fzyb"))

(define rust-typenum-1.19.0
  (crate-source "typenum" "1.19.0"
                "1fw2mpbn2vmqan56j1b3fbpcdg80mz26fm53fs16bq5xcq84hban"))

(define rust-ucd-trie-0.1.7
  (crate-source "ucd-trie" "0.1.7"
                "0wc9p07sqwz320848i52nvyjvpsxkx3kv5bfbmm6s35809fdk5i8"))

(define rust-unicode-ident-1.0.24
  (crate-source "unicode-ident" "1.0.24"
                "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76"))

(define rust-unicode-segmentation-1.12.0
  (crate-source "unicode-segmentation" "1.12.0"
                "14qla2jfx74yyb9ds3d2mpwpa4l4lzb9z57c6d2ba511458z5k7n"))

(define rust-unicode-truncate-2.0.1
  (crate-source "unicode-truncate" "2.0.1"
                "19g9af5v0a8xaigqbs9hi9csxkg1fff07ycilvwfaqw64fhq1cqn"))

(define rust-unicode-width-0.2.2
  (crate-source "unicode-width" "0.2.2"
                "0m7jjzlcccw716dy9423xxh0clys8pfpllc5smvfxrzdf66h9b5l"))

(define rust-unicode-xid-0.2.6
  (crate-source "unicode-xid" "0.2.6"
                "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb"))

(define rust-untrusted-0.9.0
  (crate-source "untrusted" "0.9.0"
                "1ha7ib98vkc538x0z60gfn0fc5whqdd85mb87dvisdcaifi6vjwf"))

(define rust-utf8parse-0.2.2
  (crate-source "utf8parse" "0.2.2"
                "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6"))

(define rust-uuid-1.22.0
  (crate-source "uuid" "1.22.0"
                "0dvsfn44sddhyhlhk7m3i559wyb125h86799fm5abky0067kr3d6"))

(define rust-valuable-0.1.1
  (crate-source "valuable" "0.1.1"
                "0r9srp55v7g27s5bg7a2m095fzckrcdca5maih6dy9bay6fflwxs"))

(define rust-version-check-0.9.5
  (crate-source "version_check" "0.9.5"
                "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb"))

(define rust-vtparse-0.6.2
  (crate-source "vtparse" "0.6.2"
                "1l5yz9650zhkaffxn28cvfys7plcw2wd6drajyf41pshn37jm6vd"))

(define rust-vcpkg-0.2.15
  (crate-source "vcpkg" "0.2.15"
                "09i4nf5y8lig6xgj3f7fyrvzd3nlaw4znrihw8psidvv5yk4xkdc"))

(define rust-wasi-0.11.1+wasi-snapshot-preview1
  (crate-source "wasi" "0.11.1+wasi-snapshot-preview1"
                "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc"))

(define rust-wasip2-1.0.2+wasi-0.2.9
  (crate-source "wasip2" "1.0.2+wasi-0.2.9"
                "1xdw7v08jpfjdg94sp4lbdgzwa587m5ifpz6fpdnkh02kwizj5wm"))

(define rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
  (crate-source "wasip3" "0.4.0+wasi-0.3.0-rc-2026-01-06"
                "19dc8p0y2mfrvgk3qw3c3240nfbylv22mvyxz84dqpgai2zzha2l"))

(define rust-wasm-bindgen-0.2.114
  (crate-source "wasm-bindgen" "0.2.114"
                "13nkhw552hpllrrmkd2x9y4bmcxr82kdpky2n667kqzcq6jzjck5"))

(define rust-wasm-bindgen-macro-0.2.114
  (crate-source "wasm-bindgen-macro" "0.2.114"
                "1rhq9kkl7n0zjrag9p25xsi4aabpgfkyf02zn4xv6pqhrw7xb8hq"))

(define rust-wasm-bindgen-macro-support-0.2.114
  (crate-source "wasm-bindgen-macro-support" "0.2.114"
                "1qriqqjpn922kv5c7f7627fj823k5aifv06j2gvwsiy5map4rkh3"))

(define rust-wasm-bindgen-shared-0.2.114
  (crate-source "wasm-bindgen-shared" "0.2.114"
                "05lc6w64jxlk4wk8rjci4z61lhx2ams90la27a41gvi3qaw2d8vm"))

(define rust-wasm-encoder-0.244.0
  (crate-source "wasm-encoder" "0.244.0"
                "06c35kv4h42vk3k51xjz1x6hn3mqwfswycmr6ziky033zvr6a04r"))

(define rust-wasm-metadata-0.244.0
  (crate-source "wasm-metadata" "0.244.0"
                "02f9dhlnryd2l7zf03whlxai5sv26x4spfibjdvc3g9gd8z3a3mv"))

(define rust-wasmparser-0.244.0
  (crate-source "wasmparser" "0.244.0"
                "1zi821hrlsxfhn39nqpmgzc0wk7ax3dv6vrs5cw6kb0v5v3hgf27"))

(define rust-wezterm-bidi-0.2.3
  (crate-source "wezterm-bidi" "0.2.3"
                "1v7kwmnxfplv9kgdmamn6csbn2ag5xjr0y6gs797slk0alsnw2hc"))

(define rust-wezterm-blob-leases-0.1.1
  (crate-source "wezterm-blob-leases" "0.1.1"
                "1dwf8bm3cwdi37fandwbk7nsfhn9spv4wm0l86gf551xv7vaybb9"))

(define rust-wezterm-color-types-0.3.0
  (crate-source "wezterm-color-types" "0.3.0"
                "15j29f60p1dc0msx50x940niyv9d5zpynavpcc6jf44hbkrixs3x"))

(define rust-wezterm-dynamic-0.2.1
  (crate-source "wezterm-dynamic" "0.2.1"
                "1b6mrk09xxiz66dj3912kmiq8rl7dqig6rwminkfmmhg287bcajz"))

(define rust-wezterm-dynamic-derive-0.1.1
  (crate-source "wezterm-dynamic-derive" "0.1.1"
                "0nspip7gwzmfn66fbnbpa2yik2sb97nckzmgir25nr4wacnwzh26"))

(define rust-wezterm-input-types-0.1.0
  (crate-source "wezterm-input-types" "0.1.0"
                "0zp557014d458a69yqn9dxfy270b6kyfdiynr5p4algrb7aas4kh"))

(define rust-winapi-0.3.9
  (crate-source "winapi" "0.3.9"
                "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw"))

(define rust-winapi-i686-pc-windows-gnu-0.4.0
  (crate-source "winapi-i686-pc-windows-gnu" "0.4.0"
                "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc"))

(define rust-winapi-x86-64-pc-windows-gnu-0.4.0
  (crate-source "winapi-x86_64-pc-windows-gnu" "0.4.0"
                "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki"))

(define rust-windows-link-0.2.1
  (crate-source "windows-link" "0.2.1"
                "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h"))

(define rust-windows-sys-0.52.0
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.52.0"
                "0gd3v4ji88490zgb6b5mq5zgbvwv7zx1ibn8v3x83rwcdbryaar8"))

(define rust-windows-sys-0.61.2
  ;; TODO REVIEW: Check bundled sources.
  (crate-source "windows-sys" "0.61.2"
                "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf"))

(define rust-windows-targets-0.52.6
  (crate-source "windows-targets" "0.52.6"
                "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv"))

(define rust-windows-aarch64-gnullvm-0.52.6
  (crate-source "windows_aarch64_gnullvm" "0.52.6"
                "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j"))

(define rust-windows-aarch64-msvc-0.52.6
  (crate-source "windows_aarch64_msvc" "0.52.6"
                "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09"))

(define rust-windows-i686-gnu-0.52.6
  (crate-source "windows_i686_gnu" "0.52.6"
                "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf"))

(define rust-windows-i686-gnullvm-0.52.6
  (crate-source "windows_i686_gnullvm" "0.52.6"
                "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf"))

(define rust-windows-i686-msvc-0.52.6
  (crate-source "windows_i686_msvc" "0.52.6"
                "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294"))

(define rust-windows-x86-64-gnu-0.52.6
  (crate-source "windows_x86_64_gnu" "0.52.6"
                "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl"))

(define rust-windows-x86-64-gnullvm-0.52.6
  (crate-source "windows_x86_64_gnullvm" "0.52.6"
                "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94"))

(define rust-windows-x86-64-msvc-0.52.6
  (crate-source "windows_x86_64_msvc" "0.52.6"
                "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq"))

(define rust-winnow-0.7.15
  (crate-source "winnow" "0.7.15"
                "0i9rkl2rqpbnnxlgs20gmkj3nd0b2k8q55mjmpc2ybb84xwxjyfz"))

(define rust-wit-bindgen-0.51.0
  (crate-source "wit-bindgen" "0.51.0"
                "19fazgch8sq5cvjv3ynhhfh5d5x08jq2pkw8jfb05vbcyqcr496p"))

(define rust-wit-bindgen-core-0.51.0
  (crate-source "wit-bindgen-core" "0.51.0"
                "1p2jszqsqbx8k7y8nwvxg65wqzxjm048ba5phaq8r9iy9ildwqga"))

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

(define rust-zeroize-1.8.2
  (crate-source "zeroize" "1.8.2"
                "1l48zxgcv34d7kjskr610zqsm6j2b4fcr2vfh9jm9j1jgvk58wdr"))

(define rust-zeroize-derive-1.4.3
  (crate-source "zeroize_derive" "1.4.3"
                "0bl5vd1lz27p4z336nximg5wrlw5j7jc8fxh7iv6r1wrhhav99c5"))

(define rust-zmij-1.0.21
  (crate-source "zmij" "1.0.21"
                "1amb5i6gz7yjb0dnmz5y669674pqmwbj44p4yfxfv2ncgvk8x15q"))

(define durthang-keyring-crypto-cargo-inputs
  ;; Cargo 1.88 records optional dependencies of keyring's transitive
  ;; Secret Service implementation in its lockfile.  These exact sources
  ;; permit the post-configure lock generation to remain fully offline.
  (map (lambda (entry) (apply crate-source entry))
       (list
        (list "async-broadcast" "0.7.2" "0ckmqcwyqwbl2cijk1y4r0vy60i89gqc86ijrxzz5f2m4yjqfnj3")
        (list "async-channel" "2.5.0" "1ljq24ig8lgs2555myrrjighycpx2mbjgrm3q7lpa6rdsmnxjklj")
        (list "async-io" "2.6.0" "1z16s18bm4jxlmp6rif38mvn55442yd3wjvdfhvx4hkgxf7qlss5")
        (list "async-lock" "3.4.2" "04c3xrrdrfrvh9v0ajxrangpy38qi76qq268zslphnxxjqjpy3r9")
        (list "async-process" "2.5.0" "0xfswxmng6835hjlfhv7k0jrfp7czqxpfj6y2s5dsp05q0g94l7w")
        (list "async-recursion" "1.1.1" "04ac4zh8qz2xjc79lmfi4jlqj5f92xjvfaqvbzwkizyqd4pl4hrv")
        (list "async-signal" "0.2.14" "11dlpb15la279r5cazppy18gbk2xzzl60ahzl19m1kr0l2psmdaj")
        (list "async-task" "4.7.1" "1pp3avr4ri2nbh7s6y9ws0397nkx1zymmcr14sq761ljarh3axcb")
        (list "async-trait" "0.1.92" "0rqn5iga1hlv2lm8xzav1zhar46jb4dvx89i6kfv93kb53maxxl2")
        (list "atomic-waker" "1.1.2" "1h5av1lw56m0jf0fd3bchxq8a30xv0b4wv8s4zkp4s0i7mfvs18m")
        (list "blocking" "1.6.2" "08bz3f9agqlp3102snkvsll6wc9ag7x5m1xy45ak2rv9pq18sgz8")
        (list "concurrent-queue" "2.5.0" "0wrr3mzq2ijdkxwndhf79k952cp4zkz35ray8hvsxl96xrx1k82c")
        (list "crossbeam-utils" "0.8.22" "05vwf7pmjq8c8f3fp5qqdm0z3cnk4p62wi8spf0jms5yjnh3v031")
        (list "endi" "1.1.1" "16a0076dx41vgrzzimm9clcym77h732czqjiajanmzvd1i1y5dv6")
        (list "enumflags2" "0.7.12" "1vzcskg4dca2jiflsfx1p9yw1fvgzcakcs7cpip0agl51ilgf9qh")
        (list "enumflags2_derive" "0.7.12" "09rqffacafl1b83ir55hrah9gza0x7pzjn6lr6jm76fzix6qmiv7")
        (list "event-listener" "5.4.2" "1lk9sv7r07l58jk263s18896l55mx9jv0g1rm4hj2mpi3paas8ss")
        (list "event-listener-strategy" "0.5.4" "14rv18av8s7n8yixg38bxp5vg2qs394rl1w052by5npzmbgz7scb")
        (list "futures-core" "0.3.34" "0pjgv4fx0np6hrs5sz5a2phabwv0z70yr51v03injbi44bjrkmlj")
        (list "futures-io" "0.3.34" "1v9z6wj92ra18kpv0xig21hgpzrvcwmcr8fszyzh64yyay0zmh2k")
        (list "futures-lite" "2.6.1" "1ba4dg26sc168vf60b1a23dv1d8rcf3v3ykz2psb7q70kxh113pp")
        (list "futures-macro" "0.3.34" "0i0czvcvsqq4hrccibq2f23004si5z34zjwdxfmqhlrmm15nbfcz")
        (list "futures-sink" "0.3.34" "07cfvrgc3vxk6sw5g8a8dnrm1mzg6d5mwy08ywa1sgyhyxml4i0r")
        (list "futures-task" "0.3.34" "1zfilqs8nwlfqz4prk7ihvpp5avvzins87ibzlxzq5fhs7ipshfd")
        (list "futures-util" "0.3.34" "1g3r9ghzq7c2fh34lis43i72xavk9p84npgfwgb5vfpqcwjajl0d")
        (list "hermit-abi" "0.5.2" "1744vaqkczpwncfy960j2hxrbjl1q01csm84jpd9dajbdr2yy3zw")
        (list "ordered-stream" "0.2.0" "0l0xxp697q7wiix1gnfn66xsss7fdhfivl2k7bvpjs4i3lgb18ls")
        (list "parking" "2.2.1" "1fnfgmzkfpjd69v4j9x737b1k8pnn054bvzcn5dm3pkgq595d3gk")
        (list "piper" "0.2.5" "1hd3j94mw5dwc457gs9ssb2r5b9iipywndf5srqx7pj38jd4fdf8")
        (list "polling" "3.11.0" "0622qfbxi3gb0ly2c99n3xawp878fkrd1sl83hjdhisx11cly3jx")
        (list "ppv-lite86" "0.2.21" "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5")
        (list "proc-macro-crate" "3.5.0" "0kv1g1d1zjwxlgcaba2qlshzyy32j03xic8rskqlcr5mnblsfyz6")
        (list "rand_chacha" "0.3.1" "123x2adin558xbhvqb8w4f6syjsdkmqff8cxwhmjacpsl1ihmhg6")
        (list "secret-service" "4.0.0" "1m5zkmmhg1wv67g4lr6pqjyqg3yrh3b8bgpw1ykf06qqkbcmmlz4")
        (list "serde_repr" "0.1.21" "01l987ghc17h1y9cf9xbzmcs77575mbrjf4ca2h70g15vqlicfwd")
        (list "sha1" "0.10.7" "1f632d529qzz95yrprr632w1fxqkrv6b6jksjc11vnzl049lay59")
        (list "slab" "0.4.12" "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c")
        (list "tempfile" "3.27.0" "1gblhnyfjsbg9wjg194n89wrzah7jy3yzgnyzhp56f3v9jd7wj9j")
        (list "toml_parser" "1.1.3+spec-1.1.0" "0mjdvihdkmjd4ykh574xgii71hpxw7ns7h4n4bisqpxrz4faqf0x")
        (list "uds_windows" "1.2.1" "0vidqwwfgn8wyzvbxiqil787b4wyqjia50zpdbbjqx7n8wlgpxpj")
        (list "xdg-home" "1.3.0" "1xm122zz0wjc8p8cmchij0j9nw34hwncb39jc7dc0mgvb2rdl77c")
        (list "zbus" "4.4.0" "09f7916lp7haxv1y5zgcg99ny15whi6dn3waf1afcafxx8mh35xv")
        (list "zbus_macros" "4.4.0" "0glqn6ddgv4ra734p343a41rrxb0phy1v13dljzhpsc1f10bjz96")
        (list "zbus_names" "3.0.0" "0v1f0ajwafj47bf11yp0xdgp26r93lslr9nb2v6624h2gppiz6sb")
        (list "zerocopy" "0.8.56" "1svmifchgdk0sm7v24lfwhhxis57gwa2lg21ingmmd5dhgjn8rsm")
        (list "zerocopy-derive" "0.8.56" "1hfz1hfxj86y1sgyia8gbisny9bl9bwlbahg4jypjmsp43y45azj")
        (list "zvariant" "4.2.0" "1zl1ika7zd9bxkd0bqc78h9bykvk6xc98965iz1p3i51p452k110")
        (list "zvariant_derive" "4.2.0" "0jf408h0s83krxwm7wl62fnssin1kcklmb1bcn83ls6sddabmqkk")
        (list "zvariant_utils" "2.1.0" "0h43h3jcw8rmjr390rdqnhkb9nn3913pgkvb75am1frxrkvwy6y5"))))

(define durthang-cargo-inputs
  (append durthang-keyring-crypto-cargo-inputs
          (list
   rust-aho-corasick-1.1.4
   rust-allocator-api2-0.2.21
   rust-anstream-1.0.0
   rust-anstyle-1.0.14
   rust-anstyle-parse-1.0.0
   rust-anstyle-query-1.1.5
   rust-anstyle-wincon-3.0.11
   rust-anyhow-1.0.102
   rust-atomic-0.6.1
   rust-autocfg-1.5.0
   rust-aws-lc-rs-1.16.1
   rust-aws-lc-sys-0.38.0
   rust-base64-0.22.1
   rust-bit-set-0.5.3
   rust-bit-vec-0.6.3
   rust-bitflags-1.3.2
   rust-bitflags-2.11.0
   rust-block-buffer-0.10.4
   rust-bumpalo-3.20.2
   rust-bytemuck-1.25.0
   rust-bytes-1.11.1
   rust-castaway-0.2.4
   rust-cc-1.2.57
   rust-cfg-if-1.0.4
   rust-cfg-aliases-0.2.1
   rust-clap-4.6.0
   rust-clap-builder-4.6.0
   rust-clap-derive-4.6.0
   rust-clap-lex-1.1.0
   rust-cmake-0.1.57
   rust-colorchoice-1.0.5
   rust-compact-str-0.9.0
   rust-convert-case-0.10.0
   rust-core-foundation-0.10.1
   rust-core-foundation-sys-0.8.7
   rust-cpufeatures-0.2.17
   rust-crossterm-0.29.0
   rust-crossterm-winapi-0.9.1
   rust-crypto-common-0.1.7
   rust-csscolorparser-0.6.2
   rust-darling-0.23.0
   rust-darling-core-0.23.0
   rust-darling-macro-0.23.0
   rust-dbus-0.9.11
   rust-dbus-secret-service-4.1.0
   rust-deltae-0.3.2
   rust-deranged-0.5.8
   rust-derive-more-2.1.1
   rust-derive-more-impl-2.1.1
   rust-digest-0.10.7
   rust-document-features-0.2.12
   rust-dunce-1.0.5
   rust-either-1.15.0
   rust-equivalent-1.0.2
   rust-errno-0.3.14
   rust-euclid-0.22.14
   rust-fancy-regex-0.11.0
   rust-fastrand-2.5.0
   rust-filedescriptor-0.8.3
   rust-find-msvc-tools-0.1.9
   rust-finl-unicode-1.4.0
   rust-fixedbitset-0.4.2
   rust-fnv-1.0.7
   rust-foldhash-0.1.5
   rust-foldhash-0.2.0
   rust-foreign-types-0.3.2
   rust-foreign-types-shared-0.1.1
   rust-fs-extra-1.3.0
   rust-generic-array-0.14.7
   rust-getrandom-0.2.17
   rust-getrandom-0.3.4
   rust-getrandom-0.4.2
   rust-hashbrown-0.15.5
   rust-hashbrown-0.16.1
   rust-heck-0.5.0
   rust-hex-0.4.3
   rust-id-arena-2.3.0
   rust-ident-case-1.0.1
   rust-indexmap-2.13.0
   rust-indoc-2.0.7
   rust-instability-0.3.12
   rust-is-terminal-polyfill-1.70.2
   rust-itertools-0.14.0
   rust-itoa-1.0.17
   rust-jobserver-0.1.34
   rust-js-sys-0.3.91
   rust-kasuari-0.4.12
   rust-keyring-3.6.3
   rust-lab-0.11.0
   rust-lazy-static-1.5.0
   rust-leb128fmt-0.1.0
   rust-libc-0.2.183
   rust-libdbus-sys-0.2.7
   rust-line-clipping-0.3.5
   rust-linux-keyutils-0.2.5
   rust-linux-raw-sys-0.12.1
   rust-litrs-1.0.0
   rust-lock-api-0.4.14
   rust-log-0.4.29
   rust-lru-0.16.3
   rust-mac-address-1.1.8
   rust-matchers-0.2.0
   rust-memchr-2.8.0
   rust-memmem-0.1.1
   rust-memoffset-0.9.1
   rust-minimal-lexical-0.2.1
   rust-mio-1.1.1
   rust-nix-0.29.0
   rust-nom-7.1.3
   rust-nu-ansi-term-0.50.3
   rust-num-conv-0.2.0
   rust-num-0.4.3
   rust-num-bigint-0.4.8
   rust-num-complex-0.4.6
   rust-num-derive-0.4.2
   rust-num-integer-0.1.47
   rust-num-iter-0.1.46
   rust-num-rational-0.4.2
   rust-num-traits-0.2.19
   rust-num-threads-0.1.7
   rust-once-cell-1.21.4
   rust-once-cell-polyfill-1.70.2
   rust-openssl-probe-0.2.1
   rust-openssl-0.10.81
   rust-openssl-macros-0.1.1
   rust-openssl-sys-0.9.117
   rust-ordered-float-4.6.0
   rust-parking-lot-0.12.5
   rust-parking-lot-core-0.9.12
   rust-pest-2.8.6
   rust-pest-derive-2.8.6
   rust-pest-generator-2.8.6
   rust-pest-meta-2.8.6
   rust-phf-0.11.3
   rust-phf-codegen-0.11.3
   rust-phf-generator-0.11.3
   rust-phf-macros-0.11.3
   rust-phf-shared-0.11.3
   rust-pin-project-lite-0.2.17
   rust-pkg-config-0.3.33
   rust-portable-atomic-1.13.1
   rust-powerfmt-0.2.0
   rust-prettyplease-0.2.37
   rust-proc-macro2-1.0.106
   rust-quote-1.0.45
   rust-r-efi-5.3.0
   rust-r-efi-6.0.0
   rust-rand-0.8.5
   rust-rand-core-0.6.4
   rust-ratatui-0.30.0
   rust-ratatui-core-0.1.0
   rust-ratatui-crossterm-0.1.0
   rust-ratatui-macros-0.7.0
   rust-ratatui-termwiz-0.1.0
   rust-ratatui-widgets-0.3.0
   rust-redox-syscall-0.5.18
   rust-regex-1.12.3
   rust-regex-automata-0.4.14
   rust-regex-syntax-0.8.10
   rust-ring-0.17.14
   rust-rustc-version-0.4.1
   rust-rustix-1.1.4
   rust-rustls-0.23.37
   rust-rustls-native-certs-0.8.3
   rust-rustls-pki-types-1.14.0
   rust-rustls-webpki-0.103.9
   rust-rustversion-1.0.22
   rust-ryu-1.0.23
   rust-schannel-0.1.29
   rust-scopeguard-1.2.0
   rust-security-framework-3.7.0
   rust-security-framework-sys-2.17.0
   rust-semver-1.0.27
   rust-serde-1.0.228
   rust-serde-core-1.0.228
   rust-serde-derive-1.0.228
   rust-serde-json-1.0.149
   rust-serde-spanned-0.6.9
   rust-sha2-0.10.9
   rust-sharded-slab-0.1.7
   rust-shlex-1.3.0
   rust-signal-hook-0.3.18
   rust-signal-hook-mio-0.2.5
   rust-signal-hook-registry-1.4.8
   rust-siphasher-1.0.2
   rust-smallvec-1.15.1
   rust-socket2-0.6.3
   rust-static-assertions-1.1.0
   rust-strsim-0.11.1
   rust-strum-0.27.2
   rust-strum-macros-0.27.2
   rust-subtle-2.6.1
   rust-syn-1.0.109
   rust-syn-2.0.117
   rust-terminfo-0.9.0
   rust-termios-0.3.3
   rust-termwiz-0.23.3
   rust-thiserror-1.0.69
   rust-thiserror-2.0.18
   rust-thiserror-impl-1.0.69
   rust-thiserror-impl-2.0.18
   rust-thread-local-1.1.9
   rust-time-0.3.47
   rust-time-core-0.1.8
   rust-tokio-1.50.0
   rust-tokio-macros-2.6.1
   rust-tokio-rustls-0.26.4
   rust-toml-0.8.23
   rust-toml-datetime-0.6.11
   rust-toml-edit-0.22.27
   rust-toml-write-0.1.2
   rust-tracing-0.1.44
   rust-tracing-attributes-0.1.31
   rust-tracing-core-0.1.36
   rust-tracing-log-0.2.0
   rust-tracing-subscriber-0.3.23
   rust-typenum-1.19.0
   rust-ucd-trie-0.1.7
   rust-unicode-ident-1.0.24
   rust-unicode-segmentation-1.12.0
   rust-unicode-truncate-2.0.1
   rust-unicode-width-0.2.2
   rust-unicode-xid-0.2.6
   rust-untrusted-0.9.0
   rust-utf8parse-0.2.2
   rust-uuid-1.22.0
   rust-valuable-0.1.1
   rust-version-check-0.9.5
   rust-vcpkg-0.2.15
   rust-vtparse-0.6.2
   rust-wasi-0.11.1+wasi-snapshot-preview1
   rust-wasip2-1.0.2+wasi-0.2.9
   rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06
   rust-wasm-bindgen-0.2.114
   rust-wasm-bindgen-macro-0.2.114
   rust-wasm-bindgen-macro-support-0.2.114
   rust-wasm-bindgen-shared-0.2.114
   rust-wasm-encoder-0.244.0
   rust-wasm-metadata-0.244.0
   rust-wasmparser-0.244.0
   rust-wezterm-bidi-0.2.3
   rust-wezterm-blob-leases-0.1.1
   rust-wezterm-color-types-0.3.0
   rust-wezterm-dynamic-0.2.1
   rust-wezterm-dynamic-derive-0.1.1
   rust-wezterm-input-types-0.1.0
   rust-winapi-0.3.9
   rust-winapi-i686-pc-windows-gnu-0.4.0
   rust-winapi-x86-64-pc-windows-gnu-0.4.0
   rust-windows-link-0.2.1
   rust-windows-sys-0.52.0
   rust-windows-sys-0.61.2
   rust-windows-targets-0.52.6
   rust-windows-aarch64-gnullvm-0.52.6
   rust-windows-aarch64-msvc-0.52.6
   rust-windows-i686-gnu-0.52.6
   rust-windows-i686-gnullvm-0.52.6
   rust-windows-i686-msvc-0.52.6
   rust-windows-x86-64-gnu-0.52.6
   rust-windows-x86-64-gnullvm-0.52.6
   rust-windows-x86-64-msvc-0.52.6
   rust-winnow-0.7.15
   rust-wit-bindgen-0.51.0
   rust-wit-bindgen-core-0.51.0
   rust-wit-bindgen-rust-0.51.0
   rust-wit-bindgen-rust-macro-0.51.0
   rust-wit-component-0.244.0
   rust-wit-parser-0.244.0
   rust-zeroize-1.8.2
   rust-zeroize-derive-1.4.3
           rust-zmij-1.0.21
           )))

(define-public durthang
  (package
    (name "durthang")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://crates.io/api/v1/crates/durthang/" version
                           "/download"))
       ;; The crates.io archive is a gzip-compressed tarball.  Use a tarball
       ;; suffix so the standard unpack phase extracts it before Cargo runs.
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "09p6zzvrfkqv2p8y5dkq30dvjj8fd2c5np481nsjb1xxppvrzmsf"))))
    (build-system cargo-build-system)
    ;; The keyring crate links the Secret Service implementation through
    ;; libdbus-sys and encrypts that transport through OpenSSL.  Keep both
    ;; libraries in the runtime closure and pkg-config available while their
    ;; build scripts discover the corresponding development files.
    (inputs (cons* bash-minimal dbus openssl durthang-cargo-inputs))
    (native-inputs (list pkg-config))
    (arguments
     (list
      ;; A terminal application does not need to install a second copy of its
      ;; Cargo source tree.  Its project license is installed explicitly below.
      #:install-source? #f
      ;; The reviewed v0.2.0 lockfile includes ratatui 0.30 and related crates
      ;; whose declared MSRV is 1.86-1.88.
      #:rust rust-1.88
      ;; Pass --locked to every Cargo build/test invocation as well as the
      ;; custom install below; cargo-build-system supplies --offline.
      #:cargo-build-flags ''("--release" "--locked")
      #:cargo-test-flags ''("--locked")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'enable-keyring-crypto
            (lambda _
              ;; keyring's default Secret Service transport deliberately uses
              ;; EncryptionType::Plain unless a crypto feature is selected.
              ;; crypto-openssl has a substantially smaller locked closure
              ;; than crypto-rust here while using Guix's audited OpenSSL.
              (substitute* "Cargo.toml"
                (("features = \\[\\n    \\\"linux-native\\\",")
                 "features = [\n    \"crypto-openssl\","))))
          ;; Cargo 1.88 expands the complete optional Secret Service graph in
          ;; Cargo.lock.  Generate that graph only after cargo-build-system
          ;; has installed the hash-pinned vendor tree, so it cannot consult a
          ;; registry.  Every subsequent Cargo invocation uses --locked.
          (add-after 'configure 'generate-cargo-lock
            (lambda _
              (use-modules (guix build cargo-utils))
              ;; cargo-build-system normally creates these source-directory
              ;; checksum manifests later.  Cargo needs them while resolving
              ;; this graph, so create them before the offline lock pass.
              (generate-all-checksums "guix-vendor")
              (invoke "cargo" "generate-lockfile" "--offline")
              ;; The vendored-source replacement has no registry checksums.
              (substitute* "Cargo.lock"
                (("^checksum = .*$")
                 ""))
              (copy-file "Cargo.lock" "Cargo.lock.guix")))
          ;; The stock cargo phase invokes `cargo install` without --locked,
          ;; which can rewrite the reviewed graph.  Install from the exact
          ;; lockfile and vendored sources instead.
          (delete 'install)
          (add-after 'check 'restore-cargo-lock-for-install
            (lambda _
              (copy-file "Cargo.lock.guix" "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*$")
                 ""))))
          (add-after 'restore-cargo-lock-for-install 'install-durthang
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                (invoke "cargo"
                        "install"
                        "--offline"
                        "--locked"
                        "--no-track"
                        "--path"
                        "."
                        "--root"
                        out))))
          (add-after 'install-durthang 'install-license
            (lambda _
              (let ((doc (string-append #$output "/share/doc/durthang")))
                (mkdir-p doc)
                (install-file "LICENSE" doc))))
          (add-after 'install-license 'wrap-tls-trust
            (lambda _
              ;; rustls loads native certificates; make that native trust
              ;; store explicit and package-owned rather than ambient.
              (wrap-program (string-append #$output "/bin/durthang")
                `("SSL_CERT_FILE" =
                  (,(string-append
                     #$nss-certs
                     "/etc/ssl/certs/ca-certificates.crt")))))))))
    (synopsis "Terminal MUD client with TLS and GMCP support")
    (description
     "Durthang is a terminal-based MUD client written in Rust.  It supports
plain TCP and TLS connections, Telnet negotiation, GMCP, ANSI rendering,
scrollback, shell-style input history, aliases, triggers, automapping, notes,
and configurable sidebar panels.  Passwords are stored through the operating
system keyring using the encrypted Secret Service API on Linux; no plaintext,
mock, or file credential backend is enabled.  A Secret Service daemon such as
GNOME Keyring or KWallet must be available when saving passwords.  The daemon
remains the credential-access-control boundary, while configuration, logs,
maps, and other mutable state remain outside the store.")
    (home-page "https://github.com/Pommersche92/durthang")
    (license license:gpl3)))
