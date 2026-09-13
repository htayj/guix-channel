;;; GNU Guix package for drbeefsupreme/tassh.
;;;
;;; tassh is a source-built clipboard relay.  The installed program is built
;;; from the pinned upstream commit and every registry source selected by its
;;; reviewed Cargo.lock; Cargo is kept locked and offline throughout.

(define-module (tay packages drbeefsupreme tassh)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg))

(define %tassh-commit
  "672569a55e6f2a0ae4274103a99b8b9abac87f4d")

(define (crate-source name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://crates.io/api/v1/crates/"
                        name "/" version "/download"))
    (file-name (string-append "rust-" name "-" version ".crate"))
    (sha256 (base32 hash))))

;; All 181 external registry records in the upstream Cargo.lock, including
;; platform-conditional and duplicate name/version entries, are immutable
;; source inputs.  cargo-build-system vendors only these inputs.
(define %tassh-cargo-inputs
  (list
        (crate-source "adler2" "2.0.1" "1ymy18s9hs7ya1pjc9864l30wk8p2qfqdi7mhhcc5nfakxbij09j")
        (crate-source "aho-corasick" "1.1.4" "00a32wb2h07im3skkikc495jvncf62jl6s96vwc7bhi70h9imlyx")
        (crate-source "anstream" "0.6.21" "0jjgixms4qjj58dzr846h2s29p8w7ynwr9b9x6246m1pwy0v5ma3")
        (crate-source "anstyle" "1.0.13" "0y2ynjqajpny6q0amvfzzgw0gfw3l47z85km4gvx87vg02lcr4ji")
        (crate-source "anstyle-parse" "0.2.7" "1hhmkkfr95d462b3zf6yl2vfzdqfy5726ya572wwg8ha9y148xjf")
        (crate-source "anstyle-query" "1.1.5" "1p6shfpnbghs6jsa0vnqd8bb8gd7pjd0jr7w0j8jikakzmr8zi20")
        (crate-source "anstyle-wincon" "3.0.11" "0zblannm70sk3xny337mz7c6d8q8i24vhbqi42ld8v7q1wjnl7i9")
        (crate-source "anyhow" "1.0.102" "0b447dra1v12z474c6z4jmicdmc5yxz5bakympdnij44ckw2s83z")
        (crate-source "arboard" "3.6.1" "1byx6q5iipxkb0pyjp80k7c4akp4n5m7nsmqdbz4n7s9ak0a2j03")
        (crate-source "async-io" "2.6.0" "1z16s18bm4jxlmp6rif38mvn55442yd3wjvdfhvx4hkgxf7qlss5")
        (crate-source "async-pidfd" "0.1.5" "05qc4d15yr6m3j5zwprdvn8brwqnb2pkg540y6ip7xcn72i230wm")
        (crate-source "autocfg" "1.5.0" "1s77f98id9l4af4alklmzq46f21c980v13z2r1pcxx6bqgw0d1n0")
        (crate-source "bitflags" "2.11.0" "1bwjibwry5nfwsfm9kjg2dqx5n5nja9xymwbfl6svnn8jsz6ff44")
        (crate-source "block-buffer" "0.10.4" "0w9sa2ypmrsqqvc20nhwr75wbb5cjr4kkyhpjm1z1lv2kdicfy1h")
        (crate-source "bytemuck" "1.25.0" "1v1z32igg9zq49phb3fra0ax5r2inf3aw473vldnm886sx5vdvy8")
        (crate-source "byteorder-lite" "0.1.0" "15alafmz4b9az56z6x7glcbcb6a8bfgyd109qc3bvx07zx4fj7wg")
        (crate-source "bytes" "1.11.1" "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y")
        (crate-source "cc" "1.2.56" "1chvh9g2izhqad7vzy4cc7xpdljdvqpsr6x6hv1hmyqv3mlkbgxf")
        (crate-source "cfg-if" "1.0.4" "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k")
        (crate-source "chacha20" "0.10.0" "00bn2rn8l68qvlq93mhq7b4ns4zy9qbjsyjbb9kljgl4hqr9i3bg")
        (crate-source "clap" "4.5.60" "02h3nzznssjgp815nnbzk0r62y2iw03kdli75c233kirld6z75r7")
        (crate-source "clap_builder" "4.5.60" "0xk8mdizvmmn6w5ij5cwhy5pbgyac4w9pfvl6nqmjl7a5hql38i4")
        (crate-source "clap_derive" "4.5.55" "1r949xis3jmhzh387smd70vc8a3b9734ck3g5ahg59a63bd969x9")
        (crate-source "clap_lex" "1.0.0" "0c8888qi1l9sayqlv666h8s0yxn2qc6jr88v1zagk43mpjjjx0is")
        (crate-source "clipboard-win" "5.4.1" "1m44gqy11rq1ww7jls86ppif98v6kv2wkwk8p17is86zsdq3gq5x")
        (crate-source "colorchoice" "1.0.4" "0x8ymkz1xr77rcj1cfanhf416pc4v681gmkc9dzb3jqja7f62nxh")
        (crate-source "concurrent-queue" "2.5.0" "0wrr3mzq2ijdkxwndhf79k952cp4zkz35ray8hvsxl96xrx1k82c")
        (crate-source "cpufeatures" "0.2.17" "10023dnnaghhdl70xcds12fsx2b966sxbxjq5sxs49mvxqw5ivar")
        (crate-source "cpufeatures" "0.3.0" "00fjhygsqmh4kbxxlb99mcsbspxcai6hjydv4c46pwb67wwl2alb")
        (crate-source "crc32fast" "1.5.0" "04d51liy8rbssra92p0qnwjw8i9rm9c4m3bwy19wjamz1k4w30cl")
        (crate-source "crossbeam-utils" "0.8.21" "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh")
        (crate-source "crunchy" "0.2.4" "1mbp5navim2qr3x48lyvadqblcxc1dm0lqr0swrkkwy2qblvw3s6")
        (crate-source "crypto-common" "0.1.7" "02nn2rhfy7kvdkdjl457q2z0mklcvj9h662xrq6dzhfialh2kj3q")
        (crate-source "digest" "0.10.7" "14p2n6ih29x81akj097lvz7wi9b6b9hvls0lwrv7b6xwyy0s5ncy")
        (crate-source "dispatch2" "0.3.1" "0f5xmnbzpaz1g80m27kd804p75nswh0ikb6wvqh4ba3x9rz3c3hy")
        (crate-source "downcast-rs" "1.2.1" "1lmrq383d1yszp7mg5i7i56b17x2lnn3kb91jwsq0zykvg2jbcvm")
        (crate-source "equivalent" "1.0.2" "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7")
        (crate-source "errno" "0.3.14" "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir")
        (crate-source "error-code" "3.3.2" "0nacxm9xr3s1rwd6fabk3qm89fyglahmbi4m512y0hr8ym6dz8ny")
        (crate-source "fax" "0.2.6" "1ax0jmvsszxd03hj6ga1kyl7gaqcfw0akg2wf0q6gk9pizaffpgh")
        (crate-source "fax_derive" "0.2.0" "0zap434zz4xvi5rnysmwzzivig593b4ng15vwzwl7js2nw7s3b50")
        (crate-source "fdeflate" "0.3.7" "130ga18vyxbb5idbgi07njymdaavvk6j08yh1dfarm294ssm6s0y")
        (crate-source "find-msvc-tools" "0.1.9" "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv")
        (crate-source "fixedbitset" "0.5.7" "16fd3v9d2cms2vddf9xhlm56sz4j0zgrk3d2h6v1l7hx760lwrqx")
        (crate-source "flate2" "1.1.9" "0g2pb7cxnzcbzrj8bw4v6gpqqp21aycmf6d84rzb6j748qkvlgw4")
        (crate-source "foldhash" "0.1.5" "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r")
        (crate-source "futures-core" "0.3.32" "07bbvwjbm5g2i330nyr1kcvjapkmdqzl4r6mqv75ivvjaa0m0d3y")
        (crate-source "futures-io" "0.3.32" "063pf5m6vfmyxj74447x8kx9q8zj6m9daamj4hvf49yrg9fs7jyf")
        (crate-source "futures-lite" "2.6.1" "1ba4dg26sc168vf60b1a23dv1d8rcf3v3ykz2psb7q70kxh113pp")
        (crate-source "generic-array" "0.14.7" "16lyyrzrljfq424c3n8kfwkqihlimmsg5nhshbbp48np3yjrqr45")
        (crate-source "gethostname" "1.1.0" "1n6bj9gh503ggjblfjcai96gmxynxsrykaynljlrfdra34q95m0v")
        (crate-source "getrandom" "0.4.1" "1v7fm84f2jh6x7w3bd2ncl3sw29wnb0rhg7xya1pd30i02cg77hk")
        (crate-source "half" "2.7.1" "0jyq42xfa6sghc397mx84av7fayd4xfxr4jahsqv90lmjr5xi8kf")
        (crate-source "hashbrown" "0.15.5" "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj")
        (crate-source "hashbrown" "0.16.1" "004i3njw38ji3bzdp9z178ba9x3k0c1pgy8x69pj7yfppv4iq7c4")
        (crate-source "heck" "0.5.0" "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113")
        (crate-source "hermit-abi" "0.5.2" "1744vaqkczpwncfy960j2hxrbjl1q01csm84jpd9dajbdr2yy3zw")
        (crate-source "id-arena" "2.3.0" "0m6rs0jcaj4mg33gkv98d71w3hridghp5c4yr928hplpkgbnfc1x")
        (crate-source "image" "0.25.9" "06lwa4ag3zcmjzivl356q0qhgxxqpkp7qwda7x0mjrkq21n6ql76")
        (crate-source "indexmap" "2.13.0" "05qh5c4h2hrnyypphxpwflk45syqbzvqsvvyxg43mp576w2ff53p")
        (crate-source "is_terminal_polyfill" "1.70.2" "15anlc47sbz0jfs9q8fhwf0h3vs2w4imc030shdnq54sny5i7jx6")
        (crate-source "itoa" "1.0.17" "1lh93xydrdn1g9x547bd05g0d3hra7pd1k4jfd2z1pl1h5hwdv4j")
        (crate-source "lazy_static" "1.5.0" "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv")
        (crate-source "leb128fmt" "0.1.0" "1chxm1484a0bly6anh6bd7a99sn355ymlagnwj3yajafnpldkv89")
        (crate-source "libc" "0.2.182" "04k1w1mq9f4cxv520dbr5xw1i7xkbc9fcrvaggyjy25jdkdvl038")
        (crate-source "linux-raw-sys" "0.12.1" "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij")
        (crate-source "lock_api" "0.4.14" "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2")
        (crate-source "log" "0.4.29" "15q8j9c8g5zpkcw0hnd6cf2z7fxqnvsjh3rw5mv5q10r83i34l2y")
        (crate-source "matchers" "0.2.0" "1sasssspdj2vwcwmbq3ra18d3qniapkimfcbr47zmx6750m5llni")
        (crate-source "memchr" "2.8.0" "0y9zzxcqxvdqg6wyag7vc3h0blhdn7hkq164bxyx2vph8zs5ijpq")
        (crate-source "miniz_oxide" "0.8.9" "05k3pdg8bjjzayq3rf0qhpirq9k37pxnasfn4arbs17phqn6m9qz")
        (crate-source "mio" "1.1.1" "1z2phpalqbdgihrcjp8y09l3kgq6309jnhnr6h11l9s7mnqcm6x6")
        (crate-source "moxcms" "0.7.11" "15qa5znj029i7677l0hdv0lwmjggrg920bhjgs3cjvydb72mg5dc")
        (crate-source "nom" "8.0.0" "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz")
        (crate-source "nu-ansi-term" "0.50.3" "1ra088d885lbd21q1bxgpqdlk1zlndblmarn948jz2a40xsbjmvr")
        (crate-source "num-traits" "0.2.19" "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787")
        (crate-source "objc2" "0.6.4" "17x8qpl512frscfqbmgjr20kg3y4r0xdqxphja17dz5f0znsh4is")
        (crate-source "objc2-app-kit" "0.3.2" "132ijwni8lsi8phq7wnmialkxp46zx998fns3zq5np0ya1mr77nl")
        (crate-source "objc2-core-foundation" "0.3.2" "0dnmg7606n4zifyjw4ff554xvjmi256cs8fpgpdmr91gckc0s61a")
        (crate-source "objc2-core-graphics" "0.3.2" "01x8413pxq0m5rwidlaczni8v5cz9dc3xqzq8l9zlpl9cv8cj8p0")
        (crate-source "objc2-encode" "4.1.0" "0cqckp4cpf68mxyc2zgnazj8klv0z395nsgbafa61cjgsyyan9gg")
        (crate-source "objc2-foundation" "0.3.2" "0wijkxzzvw2xkzssds3fj8279cbykz2rz9agxf6qh7y2agpsvq73")
        (crate-source "objc2-io-surface" "0.3.2" "07fqx4fmwydf2arrc4xs4awv7zyzzxh60fyqdfmrpm9n148qh1qq")
        (crate-source "once_cell" "1.21.3" "0b9x77lb9f1j6nqgf5aka4s2qj0nly176bpbrv6f9iakk5ff3xa2")
        (crate-source "once_cell_polyfill" "1.70.2" "1zmla628f0sk3fhjdjqzgxhalr2xrfna958s632z65bjsfv8ljrq")
        (crate-source "os_pipe" "1.2.3" "0rqrvm7fdp790b4ks3kcdzsgkz2528xrn3vxc9l4nf1inj2ax3vx")
        (crate-source "parking" "2.2.1" "1fnfgmzkfpjd69v4j9x737b1k8pnn054bvzcn5dm3pkgq595d3gk")
        (crate-source "parking_lot" "0.12.5" "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck")
        (crate-source "parking_lot_core" "0.9.12" "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896")
        (crate-source "percent-encoding" "2.3.2" "083jv1ai930azvawz2khv7w73xh8mnylk7i578cifndjn5y64kwv")
        (crate-source "petgraph" "0.8.3" "0mblnaqbx1y20h5y7pz6y11hk9jjk6k87lsmn7jxaq3hm67ba0c7")
        (crate-source "pin-project-lite" "0.2.17" "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8")
        (crate-source "pkg-config" "0.3.32" "0k4h3gnzs94sjb2ix6jyksacs52cf1fanpwsmlhjnwrdnp8dppby")
        (crate-source "png" "0.18.1" "0qca282xp8a6d7mikxrwji3f52mjn4vnqxz2v9iz5adj665rnxk0")
        (crate-source "polling" "3.11.0" "0622qfbxi3gb0ly2c99n3xawp878fkrd1sl83hjdhisx11cly3jx")
        (crate-source "prettyplease" "0.2.37" "0azn11i1kh0byabhsgab6kqs74zyrg69xkirzgqyhz6xmjnsi727")
        (crate-source "proc-macro2" "1.0.106" "0d09nczyaj67x4ihqr5p7gxbkz38gxhk4asc0k8q23g9n85hzl4g")
        (crate-source "pxfm" "0.1.27" "1a76ydn3wpl2dvyzplv3c6fkx4mkjc9ns60xas9l7alk4n1d71ki")
        (crate-source "quick-error" "2.0.1" "18z6r2rcjvvf8cn92xjhm2qc3jpd1ljvcbf12zv0k9p565gmb4x9")
        (crate-source "quick-xml" "0.38.4" "0772siy4d9vlq77842012c8cycs3y0szxkv62rh9sh2sqmc20v5n")
        (crate-source "quote" "1.0.44" "1r7c7hxl66vz3q9qizgjhy77pdrrypqgk4ghc7260xvvfb7ypci1")
        (crate-source "r-efi" "5.3.0" "03sbfm3g7myvzyylff6qaxk4z6fy76yv860yy66jiswc2m6b7kb9")
        (crate-source "rand" "0.10.0" "1y7g1zddjzhzwg0k1nddsfyfaq89a7igpcf7q44mqv6z2frnw9mw")
        (crate-source "rand_core" "0.10.0" "1flazfw1q1hbvadwzmaliplz0xnnjijdnbmzxnzdqplhfzb0z38c")
        (crate-source "redox_syscall" "0.5.18" "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd")
        (crate-source "regex-automata" "0.4.14" "13xf7hhn4qmgfh784llcp2kzrvljd13lb2b1ca0mwnf15w9d87bf")
        (crate-source "regex-syntax" "0.8.10" "02jx311ka0daxxc7v45ikzhcl3iydjbbb0mdrpc1xgg8v7c7v2fw")
        (crate-source "rustix" "1.1.4" "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn")
        (crate-source "scopeguard" "1.2.0" "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l")
        (crate-source "semver" "1.0.27" "1qmi3akfrnqc2hfkdgcxhld5bv961wbk8my3ascv5068mc5fnryp")
        (crate-source "serde" "1.0.228" "17mf4hhjxv5m90g42wmlbc61hdhlm6j9hwfkpcnd72rpgzm993ls")
        (crate-source "serde_core" "1.0.228" "1bb7id2xwx8izq50098s5j2sqrrvk31jbbrjqygyan6ask3qbls1")
        (crate-source "serde_derive" "1.0.228" "0y8xm7fvmr2kjcd029g9fijpndh8csv5m20g4bd76w8qschg4h6m")
        (crate-source "serde_json" "1.0.149" "11jdx4vilzrjjd1dpgy67x5lgzr0laplz30dhv75lnf5ffa07z43")
        (crate-source "sha2" "0.10.9" "10xjj843v31ghsksd9sl9y12qfc48157j1xpb8v1ml39jy0psl57")
        (crate-source "sharded-slab" "0.1.7" "1xipjr4nqsgw34k7a2cgj9zaasl2ds6jwn89886kww93d32a637l")
        (crate-source "shlex" "1.3.0" "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg")
        (crate-source "signal-hook-registry" "1.4.8" "06vc7pmnki6lmxar3z31gkyg9cw7py5x9g7px70gy2hil75nkny4")
        (crate-source "simd-adler32" "0.3.8" "18lx2gdgislabbvlgw5q3j5ssrr77v8kmkrxaanp3liimp2sc873")
        (crate-source "slab" "0.4.12" "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c")
        (crate-source "smallvec" "1.15.1" "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7")
        (crate-source "socket2" "0.6.2" "1q073zkvz96h216mfz6niqk2kjqrgqv2va6zj34qh84zv4xamx46")
        (crate-source "strsim" "0.11.1" "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x")
        (crate-source "syn" "2.0.117" "16cv7c0wbn8amxc54n4w15kxlx5ypdmla8s0gxr2l7bv7s0bhrg6")
        (crate-source "thiserror" "2.0.18" "1i7vcmw9900bvsmay7mww04ahahab7wmr8s925xc083rpjybb222")
        (crate-source "thiserror-impl" "2.0.18" "1mf1vrbbimj1g6dvhdgzjmn6q09yflz2b92zs1j9n3k7cxzyxi7b")
        (crate-source "thread_local" "1.1.9" "1191jvl8d63agnq06pcnarivf63qzgpws5xa33hgc92gjjj4c0pn")
        (crate-source "tiff" "0.10.3" "0vrkdk9cdk07rh7iifcxpn6m8zv3wz695mizhr8rb3gfgzg0b5mg")
        (crate-source "tokio" "1.49.0" "11ix3pl03s0bp71q3wddrbf8xr0cpn47d7fzr6m42r3kswy918kj")
        (crate-source "tokio-macros" "2.6.0" "19czvgliginbzyhhfbmj77wazqn2y8g27y2nirfajdlm41bphh5g")
        (crate-source "tracing" "0.1.44" "006ilqkg1lmfdh3xhg3z762izfwmxcvz0w7m4qx2qajbz9i1drv3")
        (crate-source "tracing-attributes" "0.1.31" "1np8d77shfvz0n7camx2bsf1qw0zg331lra0hxb4cdwnxjjwz43l")
        (crate-source "tracing-core" "0.1.36" "16mpbz6p8vd6j7sf925k9k8wzvm9vdfsjbynbmaxxyq6v7wwm5yv")
        (crate-source "tracing-log" "0.2.0" "1hs77z026k730ij1a9dhahzrl0s073gfa2hm5p0fbl0b80gmz1gf")
        (crate-source "tracing-subscriber" "0.3.22" "07hz575a0p1c2i4xw3gs3hkrykhndnkbfhyqdwjhvayx4ww18c1g")
        (crate-source "tree_magic_mini" "3.2.2" "19nm2hkspb8p4gxgk442b1hmbbh9l5fnf7w3nli6rfhw0s85nxmq")
        (crate-source "typenum" "1.19.0" "1fw2mpbn2vmqan56j1b3fbpcdg80mz26fm53fs16bq5xcq84hban")
        (crate-source "unicode-ident" "1.0.24" "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76")
        (crate-source "unicode-xid" "0.2.6" "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb")
        (crate-source "utf8parse" "0.2.2" "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6")
        (crate-source "valuable" "0.1.1" "0r9srp55v7g27s5bg7a2m095fzckrcdca5maih6dy9bay6fflwxs")
        (crate-source "version_check" "0.9.5" "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb")
        (crate-source "wasi" "0.11.1+wasi-snapshot-preview1" "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc")
        (crate-source "wasip2" "1.0.2+wasi-0.2.9" "1xdw7v08jpfjdg94sp4lbdgzwa587m5ifpz6fpdnkh02kwizj5wm")
        (crate-source "wasip3" "0.4.0+wasi-0.3.0-rc-2026-01-06" "19dc8p0y2mfrvgk3qw3c3240nfbylv22mvyxz84dqpgai2zzha2l")
        (crate-source "wasm-encoder" "0.244.0" "06c35kv4h42vk3k51xjz1x6hn3mqwfswycmr6ziky033zvr6a04r")
        (crate-source "wasm-metadata" "0.244.0" "02f9dhlnryd2l7zf03whlxai5sv26x4spfibjdvc3g9gd8z3a3mv")
        (crate-source "wasmparser" "0.244.0" "1zi821hrlsxfhn39nqpmgzc0wk7ax3dv6vrs5cw6kb0v5v3hgf27")
        (crate-source "wayland-backend" "0.3.12" "1yb4s5mbcis3z3gcmxq2lzgrcw2li7jsfr9ayi4gcsyrrja43rpy")
        (crate-source "wayland-client" "0.31.12" "1v1b2b2s0ld41psn3v2p3c6i590iz3r427czrf3c3dpv6yjzmrmq")
        (crate-source "wayland-protocols" "0.32.10" "1wzl7ly3ahi2y4swf8wmlqaj3gck4fpmwf6ymbfxd37wpkzskvds")
        (crate-source "wayland-protocols-wlr" "0.3.10" "1ws5fd7qs5vf3digbnn20n7mks2sdg76sy13b36k836g0bgpqng9")
        (crate-source "wayland-scanner" "0.31.8" "1qw971z9jcxdw8s371gx2anmwb95m59y38q3k11qxrk3d95yj8sl")
        (crate-source "wayland-sys" "0.31.8" "1zdxrcl8paklwir0lag1i80k6h0iq1f80d925b4p9yaymk1vyv8y")
        (crate-source "weezl" "0.1.12" "122a1dhha6cib5az4ihcqlh60ns2bi6rskdv875p94lbvj6wk2m2")
        (crate-source "windows-link" "0.2.1" "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h")
        (crate-source "windows-sys" "0.60.2" "1jrbc615ihqnhjhxplr2kw7rasrskv9wj3lr80hgfd42sbj01xgj")
        (crate-source "windows-sys" "0.61.2" "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf")
        (crate-source "windows-targets" "0.53.5" "1wv9j2gv3l6wj3gkw5j1kr6ymb5q6dfc42yvydjhv3mqa7szjia9")
        (crate-source "windows_aarch64_gnullvm" "0.53.1" "0lqvdm510mka9w26vmga7hbkmrw9glzc90l4gya5qbxlm1pl3n59")
        (crate-source "windows_aarch64_msvc" "0.53.1" "01jh2adlwx043rji888b22whx4bm8alrk3khjpik5xn20kl85mxr")
        (crate-source "windows_i686_gnu" "0.53.1" "18wkcm82ldyg4figcsidzwbg1pqd49jpm98crfz0j7nqd6h6s3ln")
        (crate-source "windows_i686_gnullvm" "0.53.1" "030qaxqc4salz6l4immfb6sykc6gmhyir9wzn2w8mxj8038mjwzs")
        (crate-source "windows_i686_msvc" "0.53.1" "1hi6scw3mn2pbdl30ji5i4y8vvspb9b66l98kkz350pig58wfyhy")
        (crate-source "windows_x86_64_gnu" "0.53.1" "16d4yiysmfdlsrghndr97y57gh3kljkwhfdbcs05m1jasz6l4f4w")
        (crate-source "windows_x86_64_gnullvm" "0.53.1" "1qbspgv4g3q0vygkg8rnql5c6z3caqv38japiynyivh75ng1gyhg")
        (crate-source "windows_x86_64_msvc" "0.53.1" "0l6npq76vlq4ksn4bwsncpr8508mk0gmznm6wnhjg95d19gzzfyn")
        (crate-source "wit-bindgen" "0.51.0" "19fazgch8sq5cvjv3ynhhfh5d5x08jq2pkw8jfb05vbcyqcr496p")
        (crate-source "wit-bindgen-core" "0.51.0" "1p2jszqsqbx8k7y8nwvxg65wqzxjm048ba5phaq8r9iy9ildwqga")
        (crate-source "wit-bindgen-rust" "0.51.0" "08bzn5fsvkb9x9wyvyx98qglknj2075xk1n7c5jxv15jykh6didp")
        (crate-source "wit-bindgen-rust-macro" "0.51.0" "0ymizapzv2id89igxsz2n587y2hlfypf6n8kyp68x976fzyrn3qc")
        (crate-source "wit-component" "0.244.0" "1clwxgsgdns3zj2fqnrjcp8y5gazwfa1k0sy5cbk0fsmx4hflrlx")
        (crate-source "wit-parser" "0.244.0" "0dm7avvdxryxd5b02l0g5h6933z1cw5z0d4wynvq2cywq55srj7c")
        (crate-source "wl-clipboard-rs" "0.9.3" "18xh5q3r9k57v3g2565vr33irldjh99p29x1ydpdk1rfldqi8rg9")
        (crate-source "x11rb" "0.13.2" "053lvnaw9ycbl791mgwly2hw27q6vqgzrb1y5kz1as52wmdsm4wr")
        (crate-source "x11rb-protocol" "0.13.2" "1g81cznbyn522b0fbis0i44wh3adad2vhsz5pzf99waf3sbc4vza")
        (crate-source "zerocopy" "0.8.40" "1r9j2mlb54q1l9pgall3mk0gg6cprhdncvbbgsgxnxmmj3jcd2d7")
        (crate-source "zerocopy-derive" "0.8.40" "0lsrhg5nvf0c40z644a014l2nrvh7xw0ff3i9744k9vif2d4hp7n")
        (crate-source "zmij" "1.0.21" "1amb5i6gz7yjb0dnmz5y669674pqmwbj44p4yfxfv2ncgvk8x15q")
        (crate-source "zune-core" "0.4.12" "0jj1ra86klzlcj9aha9als9d1dzs7pqv3azs1j3n96822wn3lhiz")
        (crate-source "zune-jpeg" "0.4.21" "04r7g6y9jp7d4c9bq23rz3gwzlr1dsl7vdk4yly35bc4jf52rki9")
    ))

(define-public tassh
  (package
    (name "tassh")
    (version "20260228-1.672569a")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/drbeefsupreme/tassh")
             (commit %tassh-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1r14hx37jz04cvjljc8vy063qy10sy8lmlaxsn2ckmxafl6qhw7y"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:install-source? #f
      #:cargo-build-flags ''("--release" "--locked")
      #:cargo-test-flags ''("--locked")
      #:phases
      #~(modify-phases %standard-phases
          ;; The generic Cargo configure phase deletes Cargo.lock.  This
          ;; package deliberately builds the exact reviewed lock graph.
          (add-after 'unpack 'save-cargo-lock
            (lambda _
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-after 'unpack 'use-packaged-binary-in-setup
            (lambda _
              ;; \`setup daemon\` must invoke the installed wrapper, not the
              ;; cargo-install location assumed by upstream.
              (substitute* "src/setup.rs"
                (("    home_dir.*cargo/bin/tassh.*")
                 "    PathBuf::from(std::env::var(\"TASSH_BINARY\").unwrap())"))))
          (delete 'package)
          (add-after 'check-for-pregenerated-files
              'restore-locked-offline-cargo-graph
            (lambda _
              (use-modules (guix build cargo-utils))
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; Directory sources need manifests before Cargo can validate
              ;; the restored lockfile.  Registry checksums do not apply to
              ;; those vendored directories.
              (generate-all-checksums "guix-vendor")
              (copy-file ".guix-Cargo.lock" "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*$") ""))))
          (delete 'install)
          (add-after 'check 'install-tassh
            (lambda* (#:key outputs #:allow-other-keys)
              ;; Keep the reviewed lockfile through the final Cargo action.
              (copy-file ".guix-Cargo.lock" "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*$") ""))
              (invoke "cargo" "install" "--offline" "--locked" "--no-track"
                      "--path" "." "--root" (assoc-ref outputs "out"))))
          (add-after 'install-tassh 'install-license-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (doc (string-append out "/share/doc/tassh"))
                     (third-party
                      (string-append doc "/third-party-licenses")))
                ;; tassh and its statically linked Rust closure both retain
                ;; their complete licensing and notice material.
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
                   "^([Ll][Ii][Cc][Ee][Nn][Ss][Ee]|[Cc][Oo][Pp][Yy]"
                   "([Ii][Nn][Gg]|[Rr][Ii][Gg][Hh][Tt])|[Nn][Oo][Tt][Ii]"
                   "[Cc][Ee]|[Uu][Nn][Ll][Ii][Cc][Ee][Nn][Ss][Ee])([-.].*)?$"))))))
          (add-after 'install-license-notices 'wrap-runtime
            (lambda _
              ;; Preserve the caller PATH after package tools: tailscale,
              ;; ssh, systemctl, and loginctl are intentionally user/host
              ;; integration commands and must remain discoverable.
              (wrap-program (string-append #$output "/bin/tassh")
                `("PATH" ":" prefix
                  (,(string-append #$xorg-server "/bin")
                   ,(string-append #$xclip "/bin")
                   ,(string-append #$wl-clipboard "/bin")
                   ,(string-append #$which "/bin")
                   ,(string-append #$procps "/bin")
                   ,(string-append #$inetutils "/bin")))
                `("LD_LIBRARY_PATH" ":" prefix
                  (,(string-append #$wayland "/lib")))
                `("TASSH_BINARY" = (,(string-append #$output "/bin/tassh")))))))))
    (native-inputs (list pkg-config))
    (inputs (append (list bash-minimal wayland xorg-server xclip wl-clipboard which procps
                          inetutils)
                    %tassh-cargo-inputs))
    (supported-systems '("x86_64-linux"))
    (synopsis "Tailscale and SSH PNG clipboard relay")
    (description
     "tassh relays PNG clipboard images between hosts over a configured
Tailscale path triggered by OpenSSH local commands.  Its per-user daemon writes
only @file{$HOME/.tassh}, always starts Xvfb for a reliable remote X11 paste
display, writes received images using xclip, and watches Wayland clipboards
with wl-paste when the original session has @env{WAYLAND_DISPLAY}.  The
@command{tassh setup daemon} command is a systemd-user convenience that mutates
the user home and invokes systemctl/loginctl; it is not a Guix service and is
not run while building.  A user-configured @command{tailscale} executable and
OpenSSH are hard integration prerequisites.  The package builds fully offline
from the fixed upstream source and locked Rust source closure, and retains the
upstream MIT license plus all locked third-party notices in
@file{share/doc/tassh/third-party-licenses}.")
    (home-page "https://github.com/drbeefsupreme/tassh")
    (license license:expat)))

;; Keep the provenance-only source snapshot separate from the installable CLI.
(define-public drbeefsupreme-tassh-source
  (package
    (inherit tassh)
    (name "drbeefsupreme-tassh-source")
    (build-system copy-build-system)
    (inputs '())
    (native-inputs '())
    (supported-systems %supported-systems)
    (arguments
     (list
      #:install-plan #~'(("." "share/drbeefsupreme/projects/tassh"))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (delete 'patch-shebangs)
          (delete 'strip)
          (delete 'delete-info-dir-file)
          (delete 'patch-dot-desktop-files)
          (delete 'make-dynamic-linker-cache)
          (delete 'install-license-files)
          (delete 'reset-gzip-timestamps)
          (delete 'compress-documentation))))
    (synopsis "Source snapshot of the drbeefsupreme tassh project")
    (description
     "This package installs an immutable source snapshot of the
drbeefsupreme/tassh repository under
@file{share/drbeefsupreme/projects/tassh}.  It preserves upstream source data
and does not provide the executable application.")
    (license license:expat)))
