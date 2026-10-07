;;; Fixed Cargo registry closure for unrs-resolver v1.12.2.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages unrs-resolver-cargo-sources)
  #:use-module (guix base16)
  #:use-module (guix base32)
  #:use-module (guix build-system cargo)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (%unrs-resolver-cargo-inputs
            %unrs-resolver-crate-licenses))

;; Each line records the crate name, exact version, and the SHA-256 checksum
;; copied verbatim from the 181 registry entries of upstream's Cargo.lock at
;; commit ccb26d205e2938b16069c64a28996b48ee97ff94 (tag v1.12.2).  Cargo
;; needs the whole locked graph to resolve the workspace offline, including
;; crates that are only selected for other targets; the x86_64-linux build of
;; unrs_resolver_napi with the allocator feature compiles 101 of them.
(define %unrs-resolver-cargo-records
  (string-append
    "adler2\t2.0.1\t320119579fcad9c21884f5c4861d16174d0e06250625266f50fe6898340abefa\n"
    "aho-corasick\t1.1.4\tddd31a130427c27518df266943a5308ed92d4b226cc639f5a8f1002816174301\n"
    "allocator-api2\t0.2.21\t683d7910e743518b0e34f1186f92494becacb047c7b6bf616c96772180fef923\n"
    "anes\t0.2.1\tdc43e46599f3d77fcf2f2ca89e4d962910b0c19c44e7b58679cbbdfd1820a662\n"
    "anyhow\t1.0.102\t7f202df86484c868dbad7eaa557ef785d5c66295e41b460ef922eca0723b842c\n"
    "approx\t0.5.1\tcab112f0a86d568ea0e627cc1d6be74a1e9cd55214684db5561995f6dad897c6\n"
    "arrayvec\t0.7.6\t7c02d123df017efcdfbd739ef81735b36c5ba83ec3c59c80a9d7ecc718f92e50\n"
    "autocfg\t1.5.0\tc08606f8c3cbf4ce6ec8e28fb0014a2c086708fe954eaa885384a6165172e7e8\n"
    "bit-set\t0.8.0\t08807e080ed7f9d5433fa9b275196cfc35414f66a0c79d864dc51a0d825231a3\n"
    "bit-vec\t0.8.0\t5e764a1d40d510daf35e07be9eb06e75770908c27d411ee6c92109c9840eaaf7\n"
    "bitflags\t2.11.0\t843867be96c8daad0d758b57df9392b6d8d271134fce549de6ce169ff98a92af\n"
    "bpaf\t0.9.24\tb2435ff2f08be8436bdcd06a3de2bd7696fd10e45eb630ecfc09af7fbfa3e69a\n"
    "byteorder\t1.5.0\t1fd0f2584146f6f2ef48085050886acf353beff7305ebd1ae69500e27c67f64b\n"
    "cast\t0.3.0\t37b2a672a2cb129a2e41c10b1224bb368f9f37a2b16b612598138befd7b37eb5\n"
    "castaway\t0.2.4\tdec551ab6e7578819132c713a93c022a05d60159dc86e7a7050223577484c55a\n"
    "cc\t1.2.59\tb7a4d3ec6524d28a329fc53654bbadc9bdd7b0431f5d65f1a56ffb28a1ee5283\n"
    "cfg-if\t1.0.4\t9330f8b2ff13f34540b44e946ef35111825727b38d33286ef986142615121801\n"
    "cfg_aliases\t0.2.1\t613afe47fcd5fac7ccf1db93babcb082c5994d996f20b8b159f2ad1658eb5724\n"
    "ciborium\t0.2.2\t42e69ffd6f0917f5c029256a24d0161db17cea3997d185db0d35926308770f0e\n"
    "ciborium-io\t0.2.2\t05afea1e0a06c9be33d539b876f1ce3692f4afea2cb41f740e7743225ed1c757\n"
    "ciborium-ll\t0.2.2\t57663b653d948a338bfb3eeba9bb2fd5fcfaecb9e199e87e1eda4d9e8b240fd9\n"
    "cmake\t0.1.58\tc0f78a02292a74a88ac736019ab962ece0bc380e3f977bf72e376c5d78ff0678\n"
    "codspeed\t4.4.1\tb684e94583e85a5ca7e1a6454a89d76a5121240f2fb67eb564129d9bafdb9db0\n"
    "colored\t2.2.0\t117725a109d387c937a1533ce01b450cbde6b88abceea8473c4d7a85853cda3c\n"
    "colored\t3.1.1\tfaf9468729b8cbcea668e36183cb69d317348c2e08e994829fb56ebfdfbaac34\n"
    "compact_str\t0.9.0\t3fdb1325a1cece981e8a296ab8f0f9b63ae357bd0784a9faaf548cc7b480707a\n"
    "concurrent_lru\t0.2.0\t7feb5cb312f774e8a24540e27206db4e890f7d488563671d24a16389cf4c2e4e\n"
    "convert_case\t0.11.0\taffbf0190ed2caf063e3def54ff444b449371d55c58e513a95ab98eca50adb49\n"
    "crc32fast\t1.5.0\t9481c1c90cbf2ac953f07c8d4a58aa3945c425b7185c9154d67a65e4230da511\n"
    "criterion2\t3.0.3\t861a56bb48e3ba7a2a38580a91577e17d90db946649f5c342fd74ba864180def\n"
    "crossbeam-deque\t0.8.6\t9dd111b7b7f7d55b72c0a6ae361660ee5853c9af73f70c3c2ef6858b950e2e51\n"
    "crossbeam-epoch\t0.9.18\t5b82ac4a3c2ca9c3460964f020e1402edd5753411d7737aa39c3714ad1b5420e\n"
    "crossbeam-utils\t0.8.21\td0a5c400df2834b80a4c3327b3aad3a4c4cd4de0629063962b03235697506a28\n"
    "crunchy\t0.2.4\t460fbee9c2c2f33933d720630a6a0bac33ba7053db5344fac858d4b8952d77d5\n"
    "ctor\t1.0.5\t378f0974ae2468eaf63aa036dbe9c926b0dc7ea64c156f2ea618bc2f75b934f0\n"
    "dirs\t6.0.0\tc3e8aa94d75141228480295a7d0e7feb620b1a5ad9f12bc40be62411e38cce4e\n"
    "dirs-sys\t0.5.0\te01a3366d27ee9890022452ee61b2b63a67e6f13f58900b651ff5665f0bb1fab\n"
    "document-features\t0.2.12\td4b8a88685455ed29a21542a33abd9cb6510b6b129abadabdcef0f4c55bc8f61\n"
    "either\t1.15.0\t48c757948c5ede0e46177b7add2e67155f70e33c07fea8284df6576da70b3719\n"
    "endian-type\t0.2.0\t869b0adbda23651a9c5c0c3d270aac9fcb52e8622a8f2b17e57802d7791962f2\n"
    "equivalent\t1.0.2\t877a4ace8713b0bcf2a4e7eec82529c029f1d0619886d18145fea96c3ffe5c0f\n"
    "errno\t0.3.14\t39cab71617ae0d63f51a36d69f866391735b51691dbda63cf6f96d042b63efeb\n"
    "fancy-regex\t0.18.0\te1e1dacd0d2082dfcf1351c4bdd566bbe89a2b263235a2b50058f1e130a47277\n"
    "fast-glob\t1.0.1\t3b9e81515b0279bf618200fd15d132e7195d2048fb46eed6f0f3c10cbc068266\n"
    "filetime\t0.2.26\tbc0505cd1b6fa6580283f6bdf70a73fcf4aba1184038c90902b92b3dd0df63ed\n"
    "find-msvc-tools\t0.1.9\t5baebc0774151f905a1a2cc41989300b1e6fbb29aff0ceffa1064fdd3088d582\n"
    "flate2\t1.1.5\tbfe33edd8e85a12a67454e37f8c75e730830d83e313556ab9ebf9ee7fbeb3bfb\n"
    "float-cmp\t0.10.0\tb09cf3155332e944990140d967ff5eceb70df778b34f77d8075db46e4704e6d8\n"
    "foldhash\t0.2.0\t77ce24cb58228fbb8aa041425bb1050850ac19177686ea6e0f41a70416f56fdb\n"
    "futures\t0.3.31\t65bc07b1a8bc7c85c5f2e110c476c7389b4554ba72af57d8445ea63a576b0876\n"
    "futures-channel\t0.3.31\t2dff15bf788c671c1934e366d07e30c1814a8ef514e1af724a602e8a2fbe1b10\n"
    "futures-core\t0.3.31\t05f29059c0c2090612e8d742178b0580d2dc940c837851ad723096f87af6663e\n"
    "futures-executor\t0.3.31\t1e28d1d997f585e54aebc3f97d39e72338912123a67330d723fdbb564d646c9f\n"
    "futures-io\t0.3.31\t9e5c1b78ca4aae1ac06c48a526a655760685149f0d465d21f37abfe57ce075c6\n"
    "futures-macro\t0.3.31\t162ee34ebcb7c64a8abebc059ce0fee27c2262618d7b60ed8faf72fef13c3650\n"
    "futures-sink\t0.3.31\te575fab7d1e0dcb8d0c7bcf9a63ee213816ab51902e6d244a95819acacf1d4f7\n"
    "futures-task\t0.3.31\tf90f7dce0722e95104fcb095585910c0977252f286e354b5e3bd38902cd99988\n"
    "futures-util\t0.3.31\t9fa08315bb612088cc391249efdc3bc77536f16c91f6cf495e6fbe85b20a4a81\n"
    "getrandom\t0.2.17\tff2abc00be7fca6ebc474524697ae276ad847ad0a6b3faa4bcb027e9a4614ad0\n"
    "glob\t0.3.3\t0cc23270f6e1808e30a928bdc84dea0b9b4136a8bc82338574f23baf47bbd280\n"
    "half\t2.7.1\t6ea2d84b969582b4b1864a92dc5d27cd2b77b622a8d79306834f1be5ba20d84b\n"
    "halfbrown\t0.4.0\t0c7ed2f2edad8a14c8186b847909a41fbb9c3eafa44f88bd891114ed5019da09\n"
    "hashbrown\t0.16.1\t841d1cc9bed7f9236f321df977030373f4a4163ae1a7dbfe1a51a2c1a51d9100\n"
    "hashbrown\t0.17.0\t4f467dd6dccf739c208452f8014c75c18bb8301b050ad1cfb27153803edb0f51\n"
    "indexmap\t2.14.0\td466e9454f08e4a911e14806c24e16fba1b4c121d1ea474396f396069cf949d9\n"
    "itoa\t1.0.18\t8f42a60cbdf9a97f5d2305f08a87dc4e09308d1276d28c869c684d7777685682\n"
    "json-strip-comments\t3.1.1\t9301b34ecbe81051a62001a2dfa56d906628efdfbc68153e0a4d5eba58181ece\n"
    "lazy_static\t1.5.0\tbbd2bcb4c963f2ddae06a2efc7e9f3591312473c50c6685e1f298068316e66fe\n"
    "libc\t0.2.184\t48f5d2a454e16a5ea0f4ced81bd44e4cfc7bd3a507b61887c99fd3538b28e4af\n"
    "libloading\t0.9.0\t754ca22de805bb5744484a5b151a9e1a8e837d5dc232c2d7d8c2e3492edc8b60\n"
    "libmimalloc-sys2\t0.1.57\t1c601df46d9245293af01d2e82529bef06fd46d7428cd079ba2ab73fe452e9fb\n"
    "libredox\t0.1.10\t416f7e718bdb06000964960ffa43b4335ad4012ae8b99060261aa4a8088d5ccb\n"
    "libz-rs-sys\t0.5.2\t840db8cf39d9ec4dd794376f38acc40d0fc65eec2a8f484f7fd375b84602becd\n"
    "linux-raw-sys\t0.12.1\t32a66949e030da00e8c7d4434b251670a91556f4144941d37452769c25d58a53\n"
    "litrs\t1.0.0\t11d3d7f243d5c5a8b9bb5d6dd2b1602c0cb0b9db1621bafc7ed66e35ff9fe092\n"
    "memchr\t2.8.0\tf8ca58f447f06ed17d5fc4043ce1b10dd205e060fb3ce5b979b8ed8e59ff3f79\n"
    "mimalloc-safe\t0.1.61\t339faed83010f7e29846491de7db305c2624384271776cb27e08c9e44ee692c0\n"
    "miniz_oxide\t0.8.9\t1fa76a2c86f704bdb222d66965fb3d63269ce38518b83cb0575fca855ebb6316\n"
    "napi\t3.9.0\tf1d395473824516f38dd1071a1a37bc57daa7be65b293ebba4ead5f7abb017a2\n"
    "napi-build\t2.3.2\tc9c366d2c8c60b86fa632df75f745509b52f9128f91a6bad4c796e44abb505e1\n"
    "napi-derive\t3.5.6\t89b3f766e04667e6da0e181e2da4f85475d5a6513b7cf6a80bea184e224a5b42\n"
    "napi-derive-backend\t5.0.4\t0d5af30503edf933ce7377cf6d4c877a62b0f1107ea05585f1b5e430e88d5baf\n"
    "napi-sys\t3.2.1\t8eb602b84d7c1edae45e50bbf1374696548f36ae179dfa667f577e384bb90c2b\n"
    "nibble_vec\t0.1.0\t77a5d83df9f36fe23f0c3648c6bbb8b0298bb5f1939c8f2704431371f4b84d43\n"
    "nix\t0.31.2\t5d6d0705320c1e6ba1d912b5e37cf18071b6c2e9b7fa8215a1e8a7651966f5d3\n"
    "nodejs-built-in-modules\t1.0.0\ta5eb86a92577833b75522336f210c49d9ebd7dd55a44d80a92e68c668a75f27c\n"
    "nohash-hasher\t0.2.0\t2bf50223579dc7cdcfb3bfcacf7069ff68243f8c363f62ffa99cf000a6b9c451\n"
    "num-traits\t0.2.19\t071dfc062690e90b734c0b2273ce72ad0ffa95f0c74596bc250dcfd960262841\n"
    "once_cell\t1.21.4\t9f7c3e4beb33f85d45ae3e3a1792185706c8e16d043238c593331cc7cd313b50\n"
    "oorandom\t11.1.5\td6790f58c7ff633d8771f42965289203411a5e5c68388703c06e14f24770b41e\n"
    "option-ext\t0.2.0\t04744f49eae99ab78e0d5c0b603ab218f515ea8cfe5a456d7629ad883a3b6e7d\n"
    "papaya\t0.2.4\t997ee03cd38c01469a7046643714f0ad28880bcb9e6679ff0666e24817ca19b7\n"
    "pathdiff\t0.2.3\tdf94ce210e5bc13cb6651479fa48d14f601d9858cfe0467f43ae157023b938d3\n"
    "percent-encoding\t2.3.2\t9b4f627cb1b25917193a259e49bdad08f671f8d9708acfd5fe0a8c1455d87220\n"
    "pico-args\t0.5.0\t5be167a7af36ee22fe3115051bc51f6e6c7054c9348e28deb4f49bd6f705a315\n"
    "pin-project-lite\t0.2.16\t3b3cff922bd51709b605d9ead9aa71031d81447142d828eb4a6eba76fe619f9b\n"
    "pin-utils\t0.1.0\t8b870d8c151b6f2fb93e84a13146138f05d02ed11c7e7c54f8826aaaf7c9f184\n"
    "pnp\t0.12.9\td021b5b4a2ea34bf137831fbbc5856e9c7ca70861f95a0f8dc51323b6e821faa\n"
    "proc-macro2\t1.0.106\t8fd00f0bb2e90d81d1044c2b32617f68fcb9fa3bb7640c23e9c748e53fb30934\n"
    "quote\t1.0.45\t41f2619966050689382d2b44f664f4bc593e129785a36d6ee376ddf37259b924\n"
    "radix_trie\t0.3.0\t3b4431027dcd37fc2a73ef740b5f233aa805897935b8bce0195e41bbf9a3289a\n"
    "rayon\t1.12.0\tfb39b166781f92d482534ef4b4b1b2568f42613b53e5b6c160e24cfbfa30926d\n"
    "rayon-core\t1.13.0\t22e18b0f0062d30d4230b2e85ff77fdfe4326feb054b9783a3460d8435c8ab91\n"
    "redox_syscall\t0.5.18\ted2bf2547551a7053d6fdfafda3f938979645c44812fbfcda098faae3f1a362d\n"
    "redox_users\t0.5.2\ta4e608c6638b9c18977b00b475ac1f28d14e84b27d8d42f70e0bf1e3dec127ac\n"
    "ref-cast\t1.0.25\tf354300ae66f76f1c85c5f84693f0ce81d747e2c3f21a45fef496d89c960bf7d\n"
    "ref-cast-impl\t1.0.25\tb7186006dcb21920990093f30e3dea63b7d6e977bf1256be20c3563a5db070da\n"
    "regex-automata\t0.4.14\t6e1dd4122fc1595e8162618945476892eefca7b88c52820e74af6262213cae8f\n"
    "regex-syntax\t0.8.8\t7a2d987857b319362043e95f5353c0535c1f58eec5336fdfcf626430af7def58\n"
    "rustc-hash\t2.1.2\t94300abf3f1ae2e2b8ffb7b58043de3d399c73fa6f4b73826402a5c457614dbe\n"
    "rustix\t1.1.4\tb6fe4565b9518b83ef4f91bb47ce29620ca828bd32cb7e408f0062e9930ba190\n"
    "rustversion\t1.0.22\tb39cdef0fa800fc44525c84ccb54a029961a8215f9619753635a9c0d2538d46d\n"
    "ryu\t1.0.20\t28d3b2b1366ec20994f1fd18c3c594f05c5dd4bc44d8bb0c1c632c8d6829481f\n"
    "same-file\t1.0.6\t93fc1dc3aaa9bfed95e02e6eadabb4baf7e3078b0bd1b4d7b6b0b68378900502\n"
    "seize\t0.5.1\t5b55fb86dfd3a2f5f76ea78310a88f96c4ea21a3031f8d212443d56123fd0521\n"
    "self_cell\t1.2.2\tb12e76d157a900eb52e81bc6e9f3069344290341720e9178cde2407113ac8d89\n"
    "semver\t1.0.27\td767eb0aabc880b29956c35734170f26ed551a859dbd361d140cdbeca61ab1e2\n"
    "serde\t1.0.228\t9a8e94ea7f378bd32cbbd37198a4a91436180c5bb472411e48b5ec2e2124ae9e\n"
    "serde_core\t1.0.228\t41d385c7d4ca58e59fc732af25c3983b67ac852c1a25000afe1175de458b67ad\n"
    "serde_derive\t1.0.228\td540f220d3187173da220f885ab66608367b6574e925011a9353e4badda91d79\n"
    "serde_json\t1.0.149\t83fc039473c5595ace860d8c4fafa220ff474b3fc6bfdb4293327f1a37e94d86\n"
    "sharded-slab\t0.1.7\tf40ca3c46823713e0d4209592e8d6e826aa57e928f09752619fc696c499637f6\n"
    "shlex\t1.3.0\t0fda2ff0d084019ba4d7c6f371c95d8fd75ce3524c3cb8fb653a3023f6323e64\n"
    "simd-adler32\t0.3.7\td66dc143e6b11c1eddc06d5c423cfc97062865baf299914ab64caa38182078fe\n"
    "simd-json\t0.17.0\t4255126f310d2ba20048db6321c81ab376f6a6735608bf11f0785c41f01f64e3\n"
    "simdutf8\t0.1.5\te3a9fe34e3e7a50316060351f37187a3f546bce95496156754b601a5fa71b76e\n"
    "slab\t0.4.11\t7a2ae44ef20feb57a68b23d846850f861394c2e02dc425a50098ae8c90267589\n"
    "smallvec\t1.15.1\t67b1b7a3b5fe4f1376887184045fcf45c69e92af734b7aaddc05fb777b6fbd03\n"
    "static_assertions\t1.1.0\ta2eb9349b6444b326872e140eb1cf5e7c522154d69e7a0ffb0fb81c06b37543f\n"
    "statrs\t0.18.0\t2a3fe7c28c6512e766b0874335db33c94ad7b8f9054228ae1c2abd47ce7d335e\n"
    "syn\t2.0.117\te665b8803e7b1d2a727f4023456bbbbe74da67099c585258af0ad9c5013b9b99\n"
    "thiserror\t2.0.18\t4288b5bcbc7920c07a1149a35cf9590a2aa808e0bc1eafaade0b80947865fbc4\n"
    "thiserror-impl\t2.0.18\tebc4ee7f67670e9b64d05fa4253e753e016c6c95ff35b89b7941d6b856dec1d5\n"
    "thread_local\t1.1.9\tf60246a4944f24f6e018aa17cdeffb7818b76356965d03b07d6a9886e8962185\n"
    "tracing\t0.1.44\t63e71662fa4b2a2c3a26f570f037eb95bb1f85397f3cd8076caed2f026a6d100\n"
    "tracing-attributes\t0.1.31\t7490cfa5ec963746568740651ac6781f701c9c5ea257c58e057f3ba8cf69e8da\n"
    "tracing-core\t0.1.36\tdb97caf9d906fbde555dd62fa95ddba9eecfd14cb388e4f491a66d74cd5fb79a\n"
    "tracing-subscriber\t0.3.23\tcb7f578e5945fb242538965c2d0b04418d38ec25c79d160cd279bf0731c8d319\n"
    "unicode-ident\t1.0.24\te6e4313cd5fcd3dad5cafa179702e2b244f760991f45397d14d4ebf38247da75\n"
    "unicode-segmentation\t1.12.0\tf6ccf251212114b54433ec949fd6a7841275f9ada20dddd2f29e9ceea4501493\n"
    "value-trait\t0.12.1\t8e80f0c733af0720a501b3905d22e2f97662d8eacfe082a75ed7ffb5ab08cb59\n"
    "vfs\t0.13.0\t69d33cbe2ac48f2a446f04c33aef4906078ffd224888df5ae60b7ed401ded771\n"
    "walkdir\t2.5.0\t29790946404f91d9c5d06f9874efddea1dc06c5efe94541a7d6863108e3a5e4b\n"
    "wasi\t0.11.1+wasi-snapshot-preview1\tccf3ec651a847eb01de73ccad15eb7d99f80485de043efb2f370cd654f4ea44b\n"
    "winapi-util\t0.1.11\tc2a7b1c03c876122aa43f3020e6c3c3ee5c05081c9a00739faf7503aeba10d22\n"
    "windows\t0.62.2\t527fadee13e0c05939a6a05d5bd6eec6cd2e3dbd648b9f8e447c6518133d8580\n"
    "windows-collections\t0.3.2\t23b2d95af1a8a14a3c7367e1ed4fc9c20e0a26e79551b1454d72583c97cc6610\n"
    "windows-core\t0.62.2\tb8e83a14d34d0623b51dce9581199302a221863196a1dde71a7663a4c2be9deb\n"
    "windows-future\t0.3.2\te1d6f90251fe18a279739e78025bd6ddc52a7e22f921070ccdc67dde84c605cb\n"
    "windows-implement\t0.60.2\t053e2e040ab57b9dc951b72c264860db7eb3b0200ba345b4e4c3b14f67855ddf\n"
    "windows-interface\t0.59.3\t3f316c4a2570ba26bbec722032c4099d8c8bc095efccdc15688708623367e358\n"
    "windows-link\t0.2.1\tf0805222e57f7521d6a62e36fa9163bc891acd422f971defe97d64e70d0a4fe5\n"
    "windows-numerics\t0.3.1\t6e2e40844ac143cdb44aead537bbf727de9b044e107a0f1220392177d15b0f26\n"
    "windows-result\t0.4.1\t7781fa89eaf60850ac3d2da7af8e5242a5ea78d1a11c49bf2910bb5a73853eb5\n"
    "windows-strings\t0.5.1\t7837d08f69c77cf6b07689544538e017c1bfcf57e34b4c0ff58e6c2cd3b37091\n"
    "windows-sys\t0.59.0\t1e38bc4d79ed67fd075bcc251a1c39b32a1776bbe92e5bef1f0bf1f8c531853b\n"
    "windows-sys\t0.60.2\tf2f500e4d28234f72040990ec9d39e3a6b950f9f22d3dba18416c35882612bcb\n"
    "windows-sys\t0.61.2\tae137229bcbd6cdf0f7b80a31df61766145077ddf49416a728b02cb3921ff3fc\n"
    "windows-targets\t0.52.6\t9b724f72796e036ab90c1021d4780d4d3d648aca59e491e6b98e725b84e99973\n"
    "windows-targets\t0.53.5\t4945f9f551b88e0d65f3db0bc25c33b8acea4d9e41163edf90dcd0b19f9069f3\n"
    "windows-threading\t0.2.1\t3949bd5b99cafdf1c7ca86b43ca564028dfe27d66958f2470940f73d86d75b37\n"
    "windows_aarch64_gnullvm\t0.52.6\t32a4622180e7a0ec044bb555404c800bc9fd9ec262ec147edd5989ccd0c02cd3\n"
    "windows_aarch64_gnullvm\t0.53.1\ta9d8416fa8b42f5c947f8482c43e7d89e73a173cead56d044f6a56104a6d1b53\n"
    "windows_aarch64_msvc\t0.52.6\t09ec2a7bb152e2252b53fa7803150007879548bc709c039df7627cabbd05d469\n"
    "windows_aarch64_msvc\t0.53.1\tb9d782e804c2f632e395708e99a94275910eb9100b2114651e04744e9b125006\n"
    "windows_i686_gnu\t0.52.6\t8e9b5ad5ab802e97eb8e295ac6720e509ee4c243f69d781394014ebfe8bbfa0b\n"
    "windows_i686_gnu\t0.53.1\t960e6da069d81e09becb0ca57a65220ddff016ff2d6af6a223cf372a506593a3\n"
    "windows_i686_gnullvm\t0.52.6\t0eee52d38c090b3caa76c563b86c3a4bd71ef1a819287c19d586d7334ae8ed66\n"
    "windows_i686_gnullvm\t0.53.1\tfa7359d10048f68ab8b09fa71c3daccfb0e9b559aed648a8f95469c27057180c\n"
    "windows_i686_msvc\t0.52.6\t240948bc05c5e7c6dabba28bf89d89ffce3e303022809e73deaefe4f6ec56c66\n"
    "windows_i686_msvc\t0.53.1\t1e7ac75179f18232fe9c285163565a57ef8d3c89254a30685b57d83a38d326c2\n"
    "windows_x86_64_gnu\t0.52.6\t147a5c80aabfbf0c7d901cb5895d1de30ef2907eb21fbbab29ca94c5b08b1a78\n"
    "windows_x86_64_gnu\t0.53.1\t9c3842cdd74a865a8066ab39c8a7a473c0778a3f29370b5fd6b4b9aa7df4a499\n"
    "windows_x86_64_gnullvm\t0.52.6\t24d5b23dc417412679681396f2b49f3de8c1473deb516bd34410872eff51ed0d\n"
    "windows_x86_64_gnullvm\t0.53.1\t0ffa179e2d07eee8ad8f57493436566c7cc30ac536a3379fdf008f47f6bb7ae1\n"
    "windows_x86_64_msvc\t0.52.6\t589f6da84c646204747d1270a2a5661ea66ed1cced2631d546fdfb155959f9ec\n"
    "windows_x86_64_msvc\t0.53.1\td6bbff5f0aada427a1e5a6da5f1f98158182f26556f345ac9e04d36d0ebed650\n"
    "zerocopy\t0.8.48\teed437bf9d6692032087e337407a86f04cd8d6a16a37199ed57949d415bd68e9\n"
    "zerocopy-derive\t0.8.48\t70e3cd084b1788766f53af483dd21f93881ff30d7320490ec3ef7526d203bad4\n"
    "zlib-rs\t0.5.2\t2f06ae92f42f5e5c42443fd094f245eb656abf56dd7cce9b8b263236565e00f2\n"
    "zmij\t1.0.21\tb8848ee67ecc8aedbaf3e4122217aff892639231befc6a1b58d29fff4c2cabaa\n"
    ))

;; Remove prebuilt objects shipped inside registry archives.  None of these
;; files is used for an x86_64-linux build, but they must not enter the
;; source closure.  libmimalloc-sys2 builds its C allocator from c_src/mimalloc
;; with CMake; the deleted mimalloc3/bin holds Windows redirect DLLs and
;; injector executables.
(define %unrs-resolver-crate-snippets
  `(("libloading@0.9.0"
     . (for-each delete-file '("tests/nagisa32.dll" "tests/nagisa64.dll")))
    ("libmimalloc-sys2@0.1.57"
     . (delete-file-recursively "c_src/mimalloc3/bin"))
    ,@(append-map
       (lambda (version)
         (map (lambda (name)
                (cons (string-append name "@" version)
                      '(delete-file-recursively "lib")))
              '("windows_aarch64_gnullvm" "windows_aarch64_msvc"
                "windows_i686_gnu" "windows_i686_gnullvm" "windows_i686_msvc"
                "windows_x86_64_gnu" "windows_x86_64_gnullvm"
                "windows_x86_64_msvc")))
       '("0.52.6" "0.53.1"))))

(define (unrs-resolver-crate-source record)
  (match (string-split record #\tab)
    ((name version checksum)
     ;; Cargo.lock checksums are hexadecimal SHA-256 digests; Guix origins
     ;; take the same digest in nix-base32 form.
     (crate-source name version
                   (bytevector->nix-base32-string
                    (base16-string->bytevector checksum))
                   #:snippet (assoc-ref %unrs-resolver-crate-snippets
                                        (string-append name "@" version))))))

(define %unrs-resolver-cargo-inputs
  (map unrs-resolver-crate-source
       (remove string-null?
               (string-split %unrs-resolver-cargo-records #\newline))))

;; License and notice files shipped by the 80 registry crates linked into the
;; x86_64-linux addon (cargo tree -e normal,no-proc-macro with the allocator
;; feature), including the C mimalloc tree compiled by libmimalloc-sys2.  An
;; empty list marks a crate published without its license text; the package
;; supplies those files from the matching upstream commit.
(define %unrs-resolver-crate-licenses
  '(("allocator-api2" "0.2.21" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("arrayvec" "0.7.6" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("bit-set" "0.8.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("bit-vec" "0.8.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("bitflags" "2.11.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("byteorder" "1.5.0" ("COPYING" "LICENSE-MIT" "UNLICENSE"))
    ("castaway" "0.2.4" ("LICENSE"))
    ("cfg-if" "1.0.4" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("compact_str" "0.9.0" ("LICENSE"))
    ("concurrent_lru" "0.2.0" ("LICENSE"))
    ("crc32fast" "1.5.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("ctor" "1.0.5" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("endian-type" "0.2.0" ("LICENSE"))
    ("equivalent" "1.0.2" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("fancy-regex" "0.18.0" ("LICENSE"))
    ("fast-glob" "1.0.1" ())
    ("flate2" "1.1.5" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("float-cmp" "0.10.0" ("LICENSE"))
    ("foldhash" "0.2.0" ("LICENSE"))
    ("futures" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-channel" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-core" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-executor" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-io" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-sink" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-task" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("futures-util" "0.3.31" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("halfbrown" "0.4.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("hashbrown" "0.16.1" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("hashbrown" "0.17.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("indexmap" "2.14.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("itoa" "1.0.18" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("json-strip-comments" "3.1.1" ("LICENSE"))
    ("lazy_static" "1.5.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("libc" "0.2.184" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("libloading" "0.9.0" ("LICENSE"))
    ("libmimalloc-sys2" "0.1.57" ("LICENSE.txt" "c_src/mimalloc/LICENSE"))
    ("libz-rs-sys" "0.5.2" ("LICENSE"))
    ("linux-raw-sys" "0.12.1" ("COPYRIGHT" "LICENSE-APACHE" "LICENSE-Apache-2.0_WITH_LLVM-exception" "LICENSE-MIT"))
    ("memchr" "2.8.0" ("COPYING" "LICENSE-MIT" "UNLICENSE"))
    ("mimalloc-safe" "0.1.61" ("LICENSE.txt"))
    ("napi" "3.9.0" ())
    ("napi-sys" "3.2.1" ())
    ("nibble_vec" "0.1.0" ("LICENSE"))
    ("nodejs-built-in-modules" "1.0.0" ())
    ("nohash-hasher" "0.2.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("num-traits" "0.2.19" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("once_cell" "1.21.4" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("papaya" "0.2.4" ("LICENSE.md"))
    ("pathdiff" "0.2.3" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("percent-encoding" "2.3.2" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("pin-project-lite" "0.2.16" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("pin-utils" "0.1.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("pnp" "0.12.9" ("LICENSE.md"))
    ("radix_trie" "0.3.0" ("LICENSE"))
    ("ref-cast" "1.0.25" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("regex-automata" "0.4.14" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("regex-syntax" "0.8.8" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("rustc-hash" "2.1.2" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("rustix" "1.1.4" ("COPYRIGHT" "LICENSE-APACHE" "LICENSE-Apache-2.0_WITH_LLVM-exception" "LICENSE-MIT"))
    ("ryu" "1.0.20" ("LICENSE-APACHE" "LICENSE-BOOST"))
    ("seize" "0.5.1" ("LICENSE"))
    ("self_cell" "1.2.2" ("LICENSE-APACHE" "LICENSE-GPLv2"))
    ("serde" "1.0.228" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("serde_core" "1.0.228" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("serde_json" "1.0.149" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("sharded-slab" "0.1.7" ("LICENSE"))
    ("simd-json" "0.17.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("simdutf8" "0.1.5" ("LICENSE-Apache" "LICENSE-MIT"))
    ("slab" "0.4.11" ("LICENSE"))
    ("smallvec" "1.15.1" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("static_assertions" "1.1.0" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("thiserror" "2.0.18" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("thread_local" "1.1.9" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("tracing" "0.1.44" ("LICENSE"))
    ("tracing-core" "0.1.36" ("LICENSE"))
    ("tracing-subscriber" "0.3.23" ("LICENSE"))
    ("value-trait" "0.12.1" ("LICENSE-APACHE" "LICENSE-MIT"))
    ("zlib-rs" "0.5.2" ("LICENSE"))
    ("zmij" "1.0.21" ("LICENSE-MIT"))))
