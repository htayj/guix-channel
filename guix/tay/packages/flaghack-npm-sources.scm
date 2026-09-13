;; Generated from the production dependency graph resolved by pnpm 9.10.0.
(define-module (tay packages flaghack-npm-sources)
  #:use-module (guix download)
  #:use-module (guix base32)
  #:use-module (guix packages)
  #:export (%flaghack-npm-sources))

(define %flaghack-npm-sources
  (list
   (cons "@effect/cluster"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/cluster/-/cluster-0.30.2.tgz")
                 (file-name "flaghack-scoped-effect-cluster.tgz")
                 (sha256 (base32 "063phd2f3azphg79frd5fq194cimlqsmv55lx3kpnvyvdx2n0jfz"))))
   (cons "@effect/experimental"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/experimental/-/experimental-0.44.14.tgz")
                 (file-name "flaghack-scoped-effect-experimental.tgz")
                 (sha256 (base32 "15klqnsrdavlbf9vx54za5hrkwrljrsvkax4n319v44d99xbl9p0"))))
   (cons "@effect/platform-node-shared"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/platform-node-shared/-/platform-node-shared-0.40.5.tgz")
                 (file-name "flaghack-scoped-effect-platform-node-shared.tgz")
                 (sha256 (base32 "16v0nvvk1wbryrx22al37ny476sl4ymskf3n0y9qg70n5j76xx3v"))))
   (cons "@effect/platform-node"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/platform-node/-/platform-node-0.86.4.tgz")
                 (file-name "flaghack-scoped-effect-platform-node.tgz")
                 (sha256 (base32 "0y92ibrdvnz2r0ycbsw8vb932snkxr8didyi4v5p7jp7lrwfy5a8"))))
   (cons "@effect/platform"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/platform/-/platform-0.85.2.tgz")
                 (file-name "flaghack-scoped-effect-platform.tgz")
                 (sha256 (base32 "1iq746y7zz0jnzjzq73shcgahq9v97d28cmr6zj0jcrkp08dcrf8"))))
   (cons "@effect/rpc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/rpc/-/rpc-0.56.2.tgz")
                 (file-name "flaghack-scoped-effect-rpc.tgz")
                 (sha256 (base32 "1xpw6d7qg48mr2n3kspzics1h6nz8cm81s7ggv6pmwy3fmfhsj2p"))))
   (cons "@effect/sql"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@effect/sql/-/sql-0.51.1.tgz")
                 (file-name "flaghack-scoped-effect-sql.tgz")
                 (sha256 (base32 "1n7mzp9v59g14p9sm3qvlx9n5ks8m1isjfga5kbzm9fgp54x5zmk"))))
   (cons "@esbuild/linux-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@esbuild/linux-x64/-/linux-x64-0.25.5.tgz")
                 (file-name "flaghack-scoped-esbuild-linux-x64.tgz")
                 (sha256 (base32 "06nry8zzgzy5xszvh95pmnsxbpv63zqbpwx36bb7lvvw33c2iacm"))))
   (cons "@msgpackr-extract/msgpackr-extract-darwin-arm64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-darwin-arm64/-/msgpackr-extract-darwin-arm64-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-darwin-arm64.tgz")
                 (sha256 (base32 "17wl833vc9503qlfxi65rsrx0kdl4jcy8hbsarwqr9gy2xz9j748"))))
   (cons "@msgpackr-extract/msgpackr-extract-darwin-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-darwin-x64/-/msgpackr-extract-darwin-x64-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-darwin-x64.tgz")
                 (sha256 (base32 "1rrci723pszhvcy1f3pm7lj04936vdfaawry3j2vyycmgcphyfp7"))))
   (cons "@msgpackr-extract/msgpackr-extract-linux-arm"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-linux-arm/-/msgpackr-extract-linux-arm-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-linux-arm.tgz")
                 (sha256 (base32 "1v977d1gdc1vzsjcjgarzkyxgf3c7dbxcyp7n488df0mp9ay6c0q"))))
   (cons "@msgpackr-extract/msgpackr-extract-linux-arm64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-linux-arm64/-/msgpackr-extract-linux-arm64-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-linux-arm64.tgz")
                 (sha256 (base32 "0ym6br2qzb0xmp5gip01xhksza3l68fr0w75hsp042f4jkq3p56y"))))
   (cons "@msgpackr-extract/msgpackr-extract-linux-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-linux-x64/-/msgpackr-extract-linux-x64-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-linux-x64.tgz")
                 (sha256 (base32 "1wqlhpkxkvcfpaqpm8myfq23w0s1siyhg302mrw8b46x7s5fyr0l"))))
   (cons "@msgpackr-extract/msgpackr-extract-win32-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@msgpackr-extract/msgpackr-extract-win32-x64/-/msgpackr-extract-win32-x64-3.0.3.tgz")
                 (file-name "flaghack-scoped-msgpackr-extract-msgpackr-extract-win32-x64.tgz")
                 (sha256 (base32 "1hwd2c2khxa1jjhyvnkws7m8p90c0g6ap72v8pijzscylm3ayv89"))))
   (cons "@parcel/watcher-android-arm64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-android-arm64/-/watcher-android-arm64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-android-arm64.tgz")
                 (sha256 (base32 "1j2c9pwxj3fwamcy2q3r38blm1cdn2jchbbv6xa14ggqgd6rnarh"))))
   (cons "@parcel/watcher-darwin-arm64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-darwin-arm64/-/watcher-darwin-arm64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-darwin-arm64.tgz")
                 (sha256 (base32 "0n7d7nvh0kr1injh86drqpch1b6w91s4br9a9f83dh6b7ar8bc44"))))
   (cons "@parcel/watcher-darwin-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-darwin-x64/-/watcher-darwin-x64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-darwin-x64.tgz")
                 (sha256 (base32 "1ixnm6fscs9x3x6d898dq77bx0j3syvh5294jnksdjgjabslyjaz"))))
   (cons "@parcel/watcher-freebsd-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-freebsd-x64/-/watcher-freebsd-x64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-freebsd-x64.tgz")
                 (sha256 (base32 "1mlm2gfhpaxpnib4khcz838c8q9fx1c3saxvbdsz5jar96x0wszd"))))
   (cons "@parcel/watcher-linux-arm-glibc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-arm-glibc/-/watcher-linux-arm-glibc-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-arm-glibc.tgz")
                 (sha256 (base32 "09s17gnd4890mckbx80nfp04vb011j8vb8zqjknh2bgr4ii6lbm6"))))
   (cons "@parcel/watcher-linux-arm-musl"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-arm-musl/-/watcher-linux-arm-musl-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-arm-musl.tgz")
                 (sha256 (base32 "1x3fr5iwih3n6g2yyjcfbn8ixgzzgjapc4dngbflb6cff7ay71vy"))))
   (cons "@parcel/watcher-linux-arm64-glibc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-arm64-glibc/-/watcher-linux-arm64-glibc-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-arm64-glibc.tgz")
                 (sha256 (base32 "0xd0x68pzjv6gh3rhj9yf5frfwan1f1v4k7xlxlbk4zb52anfkhl"))))
   (cons "@parcel/watcher-linux-arm64-musl"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-arm64-musl/-/watcher-linux-arm64-musl-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-arm64-musl.tgz")
                 (sha256 (base32 "1qnmnbx51f181sjng1x6lpiwwk8q3nv5xyqzbhm4r4zq8z0zcwrz"))))
   (cons "@parcel/watcher-linux-x64-glibc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-x64-glibc/-/watcher-linux-x64-glibc-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-x64-glibc.tgz")
                 (sha256 (base32 "182h7l8rqrcf5xw2ipmhr171h5isa4jbky83yvk7dcg305ysvnfr"))))
   (cons "@parcel/watcher-linux-x64-musl"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-linux-x64-musl/-/watcher-linux-x64-musl-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-linux-x64-musl.tgz")
                 (sha256 (base32 "0dchx1nmzg9mb1zksbblrjw1zi2br0vlr1ix8yfbh83b3vpyvxpp"))))
   (cons "@parcel/watcher-win32-arm64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-win32-arm64/-/watcher-win32-arm64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-win32-arm64.tgz")
                 (sha256 (base32 "15hn644vr3pfy6l0fwc3i4gfx2a9d2ffxfxkbyhbsglq53q006l3"))))
   (cons "@parcel/watcher-win32-ia32"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-win32-ia32/-/watcher-win32-ia32-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-win32-ia32.tgz")
                 (sha256 (base32 "031qav49211ia32ndkabwdf8p6yswil7d5dvhd3c4g0jgvnkzqq7"))))
   (cons "@parcel/watcher-win32-x64"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher-win32-x64/-/watcher-win32-x64-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher-win32-x64.tgz")
                 (sha256 (base32 "0ryvgdb709v1pskcwbmcdlhxc3dkvrybjsw033jp66j9jpyn8mih"))))
   (cons "@parcel/watcher"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@parcel/watcher/-/watcher-2.5.1.tgz")
                 (file-name "flaghack-scoped-parcel-watcher.tgz")
                 (sha256 (base32 "0hcd12q7xv3iadxfn1kplpr9ifan6navxxvbk8y1b1x2fxannymz"))))
   (cons "@standard-schema/spec"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/@standard-schema/spec/-/spec-1.0.0.tgz")
                 (file-name "flaghack-scoped-standard-schema-spec.tgz")
                 (sha256 (base32 "0i3w1rav4vknsz0cghqbicpc75qdhdm74jgs4q9dk9ijwjbs1s6f"))))
   (cons "braces"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/braces/-/braces-3.0.3.tgz")
                 (file-name "flaghack-braces.tgz")
                 (sha256 (base32 "1z2g963jjb92ky7xmcj53lhgyc709vgsf98lidbb8h465j38xl8w"))))
   (cons "detect-libc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/detect-libc/-/detect-libc-1.0.3.tgz")
                 (file-name "flaghack-detect-libc.tgz")
                 (sha256 (base32 "12r1f4mi84lcsqs2p86wx2f7282dgqaqwcckfs3nzcswp2cg4aks"))))
   (cons "detect-libc"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/detect-libc/-/detect-libc-2.0.4.tgz")
                 (file-name "flaghack-detect-libc.tgz")
                 (sha256 (base32 "0cng35pyhw54gddk865hxshwg7c4mnssd3p11k1pqvf0kn2rbcz2"))))
   (cons "effect"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/effect/-/effect-3.16.8.tgz")
                 (file-name "flaghack-effect.tgz")
                 (sha256 (base32 "1zcb1d69r47gz73gz80a9z7kx90r769dnwyjs4q76mpi886pdv44"))))
   (cons "esbuild"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/esbuild/-/esbuild-0.25.5.tgz")
                 (file-name "flaghack-esbuild.tgz")
                 (sha256 (base32 "1c98xk88jxw7ji9666ql2jxhn7rwmvzxzfaz72imvnxv90w4cwkv"))))
   (cons "fast-check"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/fast-check/-/fast-check-3.23.2.tgz")
                 (file-name "flaghack-fast-check.tgz")
                 (sha256 (base32 "0ij66f4g9rad48dkn3zgld29sq0xl80l1iigjvcnp1849s2rmp70"))))
   (cons "fill-range"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/fill-range/-/fill-range-7.1.1.tgz")
                 (file-name "flaghack-fill-range.tgz")
                 (sha256 (base32 "0g2r4zadicii5gfp9x5g0mimkyfqyvi8a9xnyqy6j7fb8qs3lv0s"))))
   (cons "find-my-way-ts"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/find-my-way-ts/-/find-my-way-ts-0.1.6.tgz")
                 (file-name "flaghack-find-my-way-ts.tgz")
                 (sha256 (base32 "0q5kc50v3b0d7ln8c7klcmb5f0fw36mdswklkww7w6r6qscg58zd"))))
   (cons "get-tsconfig"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/get-tsconfig/-/get-tsconfig-4.10.1.tgz")
                 (file-name "flaghack-get-tsconfig.tgz")
                 (sha256 (base32 "1167xlhd8yvj25ma4fjb70hvv5diy6gig5nlg0ab5zpkrl32bzw8"))))
   (cons "immutable"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/immutable/-/immutable-4.3.7.tgz")
                 (file-name "flaghack-immutable.tgz")
                 (sha256 (base32 "0qda6vcfrkgyj5fijs6nikgzfbikpcq7zs2axwvz1z8w3kfrzy6y"))))
   (cons "is-extglob"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/is-extglob/-/is-extglob-2.1.1.tgz")
                 (file-name "flaghack-is-extglob.tgz")
                 (sha256 (base32 "06dwa2xzjx6az40wlvwj11vican2w46710b9170jzmka2j344pcc"))))
   (cons "is-glob"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/is-glob/-/is-glob-4.0.3.tgz")
                 (file-name "flaghack-is-glob.tgz")
                 (sha256 (base32 "1imyq6pjl716cjc1ypmmnn0574rh28av3pq50mpqzd9v37xm7r1z"))))
   (cons "is-number"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz")
                 (file-name "flaghack-is-number.tgz")
                 (sha256 (base32 "07nmmpplsj1gxzng6fxhnnyfkif9fvhvxa89d5lrgkwqf42w2xbv"))))
   (cons "micromatch"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/micromatch/-/micromatch-4.0.8.tgz")
                 (file-name "flaghack-micromatch.tgz")
                 (sha256 (base32 "0imwf6rb3y6z95n14ay4d5gzr34rf8zya6ab09gwjfzz1br0b3f7"))))
   (cons "mime"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/mime/-/mime-3.0.0.tgz")
                 (file-name "flaghack-mime.tgz")
                 (sha256 (base32 "0m3zkx15qf4qxxch3ilgssglhm6djkbx12asd85zyflds1kdhd0n"))))
   (cons "msgpackr-extract"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/msgpackr-extract/-/msgpackr-extract-3.0.3.tgz")
                 (file-name "flaghack-msgpackr-extract.tgz")
                 (sha256 (base32 "1k6qx2a8km4kvn6vkv88rmiz9zz3fgfdrxd8cgj3jd8078rfc9mc"))))
   (cons "msgpackr"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/msgpackr/-/msgpackr-1.11.12.tgz")
                 (file-name "flaghack-msgpackr.tgz")
                 (sha256 (base32 "1ywhcm7v1xljlnh7hz73l3ws8l2y8qgqbfjlffchrnyz36ydzr7q"))))
   (cons "multipasta"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/multipasta/-/multipasta-0.2.7.tgz")
                 (file-name "flaghack-multipasta.tgz")
                 (sha256 (base32 "0n5x58lxi47h631bik3s845iq1q1d9lg11lxy5lmg555y5fbxpzc"))))
   (cons "node-addon-api"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/node-addon-api/-/node-addon-api-7.1.1.tgz")
                 (file-name "flaghack-node-addon-api.tgz")
                 (sha256 (base32 "10hzqyn8vxz16gmh4hwdxzw3kn83krkypc0wgb8hqz4pbb8ma15i"))))
   (cons "node-gyp-build-optional-packages"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/node-gyp-build-optional-packages/-/node-gyp-build-optional-packages-5.2.2.tgz")
                 (file-name "flaghack-node-gyp-build-optional-packages.tgz")
                 (sha256 (base32 "07vjz5xzzgsa19f4wbcyqkj6cbrk4vam7fj7sm18fk6c60zgsblv"))))
   (cons "picomatch"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/picomatch/-/picomatch-2.3.1.tgz")
                 (file-name "flaghack-picomatch.tgz")
                 (sha256 (base32 "07y1h9gbbdyjdpwb461x7dai0yg7hcyijxrcnpbr1h37r2gfw50v"))))
   (cons "pure-rand"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/pure-rand/-/pure-rand-6.1.0.tgz")
                 (file-name "flaghack-pure-rand.tgz")
                 (sha256 (base32 "1mvgy3vn7y8khfna4fqlb8l18d4i86cs4qrvg45mjrgkp3wmz7nb"))))
   (cons "resolve-pkg-maps"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/resolve-pkg-maps/-/resolve-pkg-maps-1.0.0.tgz")
                 (file-name "flaghack-resolve-pkg-maps.tgz")
                 (sha256 (base32 "0xnzn1fl08qp7s8n886hd7zrbd3pjnz2jw86cvjdc7ab0nvvsz2a"))))
   (cons "to-regex-range"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/to-regex-range/-/to-regex-range-5.0.1.tgz")
                 (file-name "flaghack-to-regex-range.tgz")
                 (sha256 (base32 "1ms2bgz2paqfpjv1xpwx67i3dns5j9gn99il6cx5r4qaq9g2afm6"))))
   (cons "tsx"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/tsx/-/tsx-4.20.3.tgz")
                 (file-name "flaghack-tsx.tgz")
                 (sha256 (base32 "133l34gaidjv79wj0l466rmx5h4dlz20g953bx6m2ngpl29vwx4j"))))
   (cons "undici"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/undici/-/undici-7.10.0.tgz")
                 (file-name "flaghack-undici.tgz")
                 (sha256 (base32 "1c5y21wc0idlgc1kxm6mcn053gz28h1n6ifpmcal5r25swd4nkiv"))))
   (cons "uuid"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/uuid/-/uuid-11.1.0.tgz")
                 (file-name "flaghack-uuid.tgz")
                 (sha256 (base32 "1iqx9a8p2ns0964h8mqcnqq0y7lzslxlangjfal4km6mc6k1687c"))))
   (cons "ws"
         (origin (method url-fetch) (uri "https://registry.npmjs.org/ws/-/ws-8.18.2.tgz")
                 (file-name "flaghack-ws.tgz")
                 (sha256 (base32 "0cgdgrvn0clx61j5llns5b7p83d75z7r5v1rg52r7bfxwza7n2xr"))))
   ))
