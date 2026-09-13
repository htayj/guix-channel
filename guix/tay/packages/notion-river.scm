;;; GNU Guix package for Marenz/notion-river.
;;;
;;; The source and every crate archive below are pinned to the reviewed
;;; e79dea34c3f32987c42e338db6a5c341bce0af23 Cargo.lock graph.  The River
;;; submodule is intentionally not fetched: notion-river uses only the
;;; checked-in protocol XML files and invokes a separately supplied River at
;;; runtime.

(define-module (tay packages notion-river)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages xdisorg))

(define %notion-river-commit
  "e79dea34c3f32987c42e338db6a5c341bce0af23")

(define (crate-source name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://crates.io/api/v1/crates/"
                        name "/" version "/download"))
    (file-name (string-append "rust-" name "-" version ".crate"))
    (sha256 (base32 hash))))

(define %notion-river-cargo-inputs-1
  (list
    (crate-source "aho-corasick" "1.1.5" "1fhjkp2nbs7gg4y1b68hpc8028rpax8aiscfh9b60q78m4pn90n9")
    (crate-source "anstream" "1.0.0" "13d2bj0xfg012s4rmq44zc8zgy1q8k9yp7yhvfnarscnmwpj2jl2")
    (crate-source "anstyle" "1.0.14" "0030szmgj51fxkic1hpakxxgappxzwm6m154a3gfml83lq63l2wl")
    (crate-source "anstyle-parse" "1.0.0" "03hkv2690s0crssbnmfkr76kw1k7ah2i6s5amdy9yca2n8w7zkjj")
    (crate-source "anstyle-query" "1.1.5" "1p6shfpnbghs6jsa0vnqd8bb8gd7pjd0jr7w0j8jikakzmr8zi20")
    (crate-source "anstyle-wincon" "3.0.11" "0zblannm70sk3xny337mz7c6d8q8i24vhbqi42ld8v7q1wjnl7i9")
    (crate-source "bitflags" "1.3.2" "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy")
    (crate-source "bitflags" "2.13.1" "1nl76mpykmwmb8rq1l5vw1azdh1wvxdrnsk4sy3rdrzx01nvg25m")
    (crate-source "cairo-rs" "0.22.0" "15fb1m9vlsni37g9qwqgmag7s69f3bplylm0v567901lg6mdkj2w")
    (crate-source "cairo-sys-rs" "0.22.0" "0m3dnyax3l8nwypc2lzzd41bbfrjxykbd39bw2p5yzq42dbrid7q")
    (crate-source "cc" "1.4.0" "1fc26n76n7gr37m2q0xw5l8jpn4sd33hvyppmwhv6v4fcyxq3pas")
    (crate-source "cfg-expr" "0.20.8" "0z4r6l4936g1c1s27ryvjdy5pjij6sfvs3myk3hji9dgpi13asgv")
    (crate-source "cfg-if" "1.0.4" "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k")
    (crate-source "colorchoice" "1.0.5" "0w75k89hw39p0mnnhlrwr23q50rza1yjki44qvh2mgrnj065a1qx")))

(define %notion-river-cargo-inputs-2
  (list
    (crate-source "defmt" "1.1.1" "1lc8xlfj700xqjmvp7n9hhc1czgpaqkq960iqw6d5fwk9zz3p5g2")
    (crate-source "defmt-macros" "1.1.1" "1s2zkcbaj1l306ph1n1gsfm6vzc2sah4acl1qc6pw4x2ghpcgnds")
    (crate-source "defmt-parser" "1.0.0" "0gpfky9sssil5qfaix5wxcwiqk7snszhl5gq3vcwkrxjncs07mhh")
    (crate-source "dirs" "6.0.0" "0knfikii29761g22pwfrb8d0nqpbgw77sni9h2224haisyaams63")
    (crate-source "dirs-sys" "0.5.0" "1aqzpgq6ampza6v012gm2dppx9k35cdycbj54808ksbys9k366p0")
    (crate-source "downcast-rs" "1.2.1" "1lmrq383d1yszp7mg5i7i56b17x2lnn3kb91jwsq0zykvg2jbcvm")
    (crate-source "env_filter" "2.0.0" "05s267np8pphhpxzrzl4j956gjj87f4ik6yas7l1x6kr0cd2f3ch")
    (crate-source "env_logger" "0.11.11" "1xnkbhnlwf45a6val2340bi7avi7fwgbm2g2kbf9g9vmgb91nryy")
    (crate-source "equivalent" "1.0.2" "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7")
    (crate-source "errno" "0.3.14" "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir")
    (crate-source "find-msvc-tools" "0.1.9" "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv")
    (crate-source "freetype-rs" "0.38.0" "1d09d1rfn9g56dqx4qhc328386s494c387rlhmsxv43cwmnqs8kd")
    (crate-source "freetype-sys" "0.23.0" "1bh8qf0849lf40iw7pc5fj3pzx74ww63kp2c9g351f6a8g73gdga")
    (crate-source "futures-channel" "0.3.33" "1bn5hlhfkl1sgypmiachaqcgwmr6wmjal7dyhfyb1zkazvs90996")))

(define %notion-river-cargo-inputs-3
  (list
    (crate-source "futures-core" "0.3.33" "1iqdbvcdlplfr2g43h7xrfkv2sg5p1a26x8acz1xgxl07i3hrm9c")
    (crate-source "futures-executor" "0.3.33" "0n3lpkmcfrsnh40i4armn040gnqbpd257hz5qs46zipjr6f8fm37")
    (crate-source "futures-io" "0.3.33" "0yjx13qdm9b2p4w00ddw85k6yccnnmqrlrrz8yfmi5jg7jmfqxs5")
    (crate-source "futures-macro" "0.3.33" "02xiyd5y1nk9b805aympj4wq2czgvxnhcml9w9xkc665d3g3qv9d")
    (crate-source "futures-task" "0.3.33" "02f1y1yvjg1cv998zkgl1706pi9y4fyc9045l1hlmyqyhclfscdj")
    (crate-source "futures-util" "0.3.33" "1anyg40j5www5l22r2jbn1birsafz4q1w9qmcjk4vqzwasi90ym7")
    (crate-source "getrandom" "0.2.17" "1l2ac6jfj9xhpjjgmcx6s1x89bbnw9x6j9258yy6xjkzpq0bqapz")
    (crate-source "gio" "0.22.8" "1vcxfs28jrhkvck57x3qgl5ckf4p41s5mpiv86wjdhq9k5k1yglb")
    (crate-source "gio-sys" "0.22.8" "1mdhnh532ridfi6hv8mar34hwf6ywzjf1c84c68xl5ndlxyxqgrm")
    (crate-source "glib" "0.22.8" "0041i04ba9r8sicbvpff7gdg8wr8x2s54khfjqdzr08qplagbg6x")
    (crate-source "glib-macros" "0.22.6" "06bgdnz54l50vxkcp8iraab1v1x3v7l5g5s2k0l19iq7jx4j6vah")
    (crate-source "glib-sys" "0.22.8" "0cr2jp2z0g3k9iap56zccbacc9bqxanh8qrchx8nhrwzkx2nf283")
    (crate-source "gobject-sys" "0.22.6" "0b57dwgs2yp56892kp990bxxhmvsr69c2n8k8v7pjyl8kf2n3a12")
    (crate-source "hashbrown" "0.17.1" "0jmqz7i4yl6cm7rbn0i2ffkfrmwi6xkmzkaldr2v8bcsx2v0jngd")))

(define %notion-river-cargo-inputs-4
  (list
    (crate-source "heck" "0.5.0" "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113")
    (crate-source "indexmap" "2.14.0" "1na9z6f0d5pkjr1lgsni470v98gv2r7c41j8w48skr089x2yjrnl")
    (crate-source "is_terminal_polyfill" "1.70.2" "15anlc47sbz0jfs9q8fhwf0h3vs2w4imc030shdnq54sny5i7jx6")
    (crate-source "itoa" "1.0.18" "10jnd1vpfkb8kj38rlkn2a6k02afvj3qmw054dfpzagrpl6achlg")
    (crate-source "jiff" "0.2.35" "1k1d1n8k46192xz6ph8km43lcg68ql65phzmhm49mbq7pn1p32v6")
    (crate-source "jiff-core" "0.1.0" "02axx56pkh2w4bw5rp94qlvcpwzd3n2w2025fnikvrgg762aiv3z")
    (crate-source "jiff-static" "0.2.35" "014jli8v46c8hzkndmvdfvq4la6a6y9icmnh3k735yqwlarxqs9s")
    (crate-source "libc" "0.2.189" "1whjfs375vlng2q6yrbzs73cvp5lm3w1n2gfqajb2vgf7zg3xbry")
    (crate-source "libredox" "0.1.19" "1yl5s2g4s072829l4sis97shg98dlk5qhr6mylmhp8b4cw2sa9i0")
    (crate-source "libz-sys" "1.1.29" "1n98kqya7a7a0cxf5n5z3g13rj7a1vqxynk2xc7bja1qfxbrdg45")
    (crate-source "linux-raw-sys" "0.12.1" "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij")
    (crate-source "log" "0.4.33" "1bd9dmk22pxgnf0h0slba6rz99zb0a0b2mdhpk8p92bp26ycbvhc")
    (crate-source "memchr" "2.8.3" "161xa63ipfanf8v3nb82xd5hqgydv55nzw59wyngqbz6alfaz2yg")
    (crate-source "memmap2" "0.9.11" "1h4qnzgarnn488ljjpg9ns5y4bw0sq0xv0fj0iqywagjnz8rw8fi")))

(define %notion-river-cargo-inputs-5
  (list
    (crate-source "once_cell_polyfill" "1.70.2" "1zmla628f0sk3fhjdjqzgxhalr2xrfna958s632z65bjsfv8ljrq")
    (crate-source "option-ext" "0.2.0" "0zbf7cx8ib99frnlanpyikm1bx8qn8x602sw1n7bg6p9x94lyx04")
    (crate-source "pango" "0.22.8" "0v1ix8skv2c53p17rlixrw1s055sp96k9xa6n07mvbg21n6hv02x")
    (crate-source "pango-sys" "0.22.0" "1mnm14vf7xcrag51qjfqy400kh3rqs1rgi897vqfs3x91ji13ldv")
    (crate-source "pangocairo" "0.22.8" "1as3nm3qplwrn9g1wmv7flnzmr682w22w5zp9y0qf57mj3v2x2kk")
    (crate-source "pangocairo-sys" "0.22.0" "0zy7qd8r9xnv59gipi4g2awnmzj2bfpzn6mvi9b9wfrpd0sbfp6r")
    (crate-source "pin-project-lite" "0.2.17" "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8")
    (crate-source "pkg-config" "0.3.33" "17jnqmcbxsnwhg9gjf0nh6dj5k0x3hgwi3mb9krjnmfa9v435w8r")
    (crate-source "portable-atomic" "1.14.0" "1hyfma9n2cs2ibazpfwrbv61zwg7cv86g0pr5yjkg07qgr4xa81x")
    (crate-source "portable-atomic-util" "0.2.7" "0616j0fhy6y71hyxg3n86f6hng0fmsc269s3wp4gl8ww4p8hd8f2")
    (crate-source "proc-macro2" "1.0.107" "1nb6ly8kp65f724kj73ippc7lvydss24sm2vagk6qpklpg4pwplq")
    (crate-source "quick-xml" "0.41.0" "1h9y8zry34r3mxfd5vqfj50vvvzvri4kzbx5d657jkqjalg4aq76")
    (crate-source "quote" "1.0.47" "00ch0yyzvv6s671ik0kcsbw8nigdaj2g3fr61kcahwx48aqlvgqz")
    (crate-source "redox_users" "0.5.2" "1b17q7gf7w8b1vvl53bxna24xl983yn7bd00gfbii74bcg30irm4")))

(define %notion-river-cargo-inputs-6
  (list
    (crate-source "regex" "1.13.1" "1391a0a4100ik8cp7l577p3ip3haqq03rd9c5vdr7vcfdixj687h")
    (crate-source "regex-automata" "0.4.18" "1cml0rm0ssqfkibh9nh3gy4b6hbsbicj1rihpwf2a4v4nawm71dd")
    (crate-source "regex-syntax" "0.8.11" "1m25h5q2wp976fb9gc3dsc9l99svcvd5cri8lncb51c46ydgzxnn")
    (crate-source "rustix" "1.1.4" "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn")
    (crate-source "serde" "1.0.229" "1fp04fq4a79bpm61xz1zy0pbz4kpc7d771zii1k3inmszq55jj21")
    (crate-source "serde_core" "1.0.229" "0j1ajiha76h3nmd976il9li6975k121xa7jb39ws8n0yqp4s5p37")
    (crate-source "serde_derive" "1.0.229" "0j4k63i7h1bikxwz2c89ig0hrwbnl9mz1czn85xx99x5cc9dg9g7")
    (crate-source "serde_json" "1.0.151" "051zww7lvpw147vvwss1ng6w587qyrkzg75fvj08q2dfrmgbahf8")
    (crate-source "serde_spanned" "1.1.1" "09jzk7i6wihn3d8i3wi4j4n98ghi93c3b8m8k64nxq0ijn3vaqk6")
    (crate-source "shlex" "2.0.1" "1fjsll1cd7d2bcpdij9kd6w62rpbc7qqzvydvs021vsmr1cxvypq")
    (crate-source "slab" "0.4.12" "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c")
    (crate-source "smallvec" "1.15.2" "143wzbqf6vgapdp2z4qpl0yvlqcn17s8cnk8m28rqly808zsdmlf")
    (crate-source "syn" "2.0.119" "15vjy620l91a3q4n4f4gzhnflmdr6pnm38v2m6cpk86i8av32a47")
    (crate-source "syn" "3.0.3" "18srnql3cd39j9q6hf1az02p67rlr1rf6njx9zx4vxj9i3jvmsak")))

(define %notion-river-cargo-inputs-7
  (list
    (crate-source "system-deps" "7.0.8" "1rwnfw9dm6ck65a7lfjfpn2c91gwj88brz2i09z3fdbknvz3asir")
    (crate-source "target-lexicon" "0.13.5" "1jm6lmf9hsn7ri2d6v9gg6fy24lylhskh6pbxh71f82wdxd97dmd")
    (crate-source "thiserror" "2.0.19" "1ngwxsjsa64v1n7vb90h2b0i3fqk1piwaf0z6fqdacqfhjc3b909")
    (crate-source "thiserror-impl" "2.0.19" "1ka10pqy1g8zy5al9m8yadg30jp8hx0q80j8awmd8131yw6gxjs3")
    (crate-source "toml" "1.1.4+spec-1.1.0" "1xanf3v10j8hdjz37mkhg80w92cw25kxwndhcp4w5pxw9czydb1s")
    (crate-source "toml_datetime" "1.1.1+spec-1.1.0" "1mws2mkkf46l7inn77azhm0vdwxngv9vsbhbl0ah33p2c9gzcr9i")
    (crate-source "toml_parser" "1.1.3+spec-1.1.0" "0mjdvihdkmjd4ykh574xgii71hpxw7ns7h4n4bisqpxrz4faqf0x")
    (crate-source "toml_writer" "1.1.2+spec-1.1.0" "1lk6pqf9mac3v1x6282n6a66qx5b18c8f4a23bsd0nk658x3amkx")
    (crate-source "unicode-ident" "1.0.24" "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76")
    (crate-source "utf8parse" "0.2.2" "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6")
    (crate-source "vcpkg" "0.2.15" "09i4nf5y8lig6xgj3f7fyrvzd3nlaw4znrihw8psidvv5yk4xkdc")
    (crate-source "version-compare" "0.2.1" "03nziqxwnxlizl42cwsx33vi5xd2cf2jnszhh9rzay7g6xl8bhh3")
    (crate-source "wasi" "0.11.1+wasi-snapshot-preview1" "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc")
    (crate-source "wayland-backend" "0.3.16" "1f2l7zw10cwid6444w86szvr08wvgkhi6a31k64nz2y5s40wyv01")))

(define %notion-river-cargo-inputs-8
  (list
    (crate-source "wayland-client" "0.31.15" "0ww0d0r6rn2h0sn8ma1f7zvxj40l6930p07j044nvmqshq7nmhz3")
    (crate-source "wayland-scanner" "0.31.11" "1h0al3271l2w124sxlh77s1kmjg0z24ns2mk1vbnfars3d3313ik")
    (crate-source "wayland-sys" "0.31.11" "1gp3hlkxx13i55lyyi794vnw9a780z3skx0xhj71zr69xwzv5snq")
    (crate-source "windows-link" "0.2.1" "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h")
    (crate-source "windows-sys" "0.61.2" "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf")
    (crate-source "winnow" "1.0.4" "10fzxipa7lx16172p3aca9j60hzbqgjki2f95kqksd5qywcp7f93")
    (crate-source "xkbcommon" "0.9.0" "0bd0qkapxsvblfw42x6ryhi50d63v55g40awf2alx8b0h3s79ad7")
    (crate-source "xkeysym" "0.2.1" "0mksx670cszyd7jln6s7dhkw11hdfv7blwwr3isq98k22ljh1k5r")
    (crate-source "zmij" "1.0.23" "06zwri21nnrl34rwinmvbciap8yk1mrl8qfg9pff7lgspc56sri9")))

(define %notion-river-cargo-inputs
  (append %notion-river-cargo-inputs-1
          %notion-river-cargo-inputs-2
          %notion-river-cargo-inputs-3
          %notion-river-cargo-inputs-4
          %notion-river-cargo-inputs-5
          %notion-river-cargo-inputs-6
          %notion-river-cargo-inputs-7
          %notion-river-cargo-inputs-8))

(define-public notion-river
  (package
    (name "notion-river")
    ;; v0.6.0 is the nearest tag; this fixed commit is fourteen commits later.
    ;; Cargo.toml intentionally remains at the upstream program version 0.5.3.
    (version "0.6.0-14.ge79dea3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/Marenz/notion-river/"
                           "tar.gz/" %notion-river-commit))
       (file-name (string-append name "-" %notion-river-commit ".tar.gz"))
       (sha256
        (base32
         "1lllgc5nf5gz0qhgqiga17rlxrw73jjq4ba09d7k8lirjps1dyin"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:rust rust-1.93
      #:install-source? #f
      #:cargo-build-flags ''("--release" "--locked")
      #:cargo-test-flags ''("--locked")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'preserve-reviewed-cargo-lock
            (lambda _
              ;; cargo-build-system makes a source replacement for the
              ;; complete input graph.  Preserve the reviewed lockfile until
              ;; that replacement's checksum manifests have been generated.
              (copy-file "Cargo.lock" ".guix-Cargo.lock")))
          (add-after 'check-for-pregenerated-files
              'restore-locked-offline-cargo-graph
            (lambda _
              (use-modules (guix build cargo-utils))
              (setenv "CARGO_NET_OFFLINE" "true")
              ;; The build system has already placed only the declared crate
              ;; archives in guix-vendor.  Cargo requires vendor checksum
              ;; manifests; registry checksums are removed only because these
              ;; sources are now local replacements, not downloads.
              (generate-all-checksums "guix-vendor")
              (copy-file ".guix-Cargo.lock" "Cargo.lock")
              (substitute* "Cargo.lock"
                (("^checksum = .*$") ""))
              ;; Upstream's tests create IPC fixtures.  Keep all such state
              ;; private to the build directory rather than a builder's home.
              (mkdir-p ".guix-xdg-runtime")
              (chmod ".guix-xdg-runtime" #o700)
              (mkdir-p ".guix-xdg-config")
              (setenv "XDG_RUNTIME_DIR"
                      (string-append (getcwd) "/.guix-xdg-runtime"))
              (setenv "XDG_CONFIG_HOME"
                      (string-append (getcwd) "/.guix-xdg-config"))))
          (add-after 'unpack 'patch-session-integration
            (lambda _
              ;; Keep the River executable outside this package: a user must
              ;; supply a compatible River 0.4.x+ on PATH.
              (substitute* "notion-river-session"
                (("\\$HOME/\\.config/river/init")
                 "${XDG_CONFIG_HOME:-$HOME/.config}/river/init"))
              (substitute* "notion-river.desktop"
                (("/usr/bin/notion-river-session")
                 (string-append #$output "/bin/notion-river-session")))
              (substitute* "config-examples/river-init"
                (("/usr/share/notion-river/examples")
                 (string-append #$output
                                "/share/notion-river/examples")))))
          (delete 'install)
          (add-after 'check 'install-notion-river
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (share (string-append out "/share/notion-river"))
                     (examples (string-append share "/examples"))
                     (sessions (string-append out "/share/wayland-sessions"))
                     (completions
                      (string-append out
                                     "/share/fish/vendor_completions.d")))
                (mkdir-p bin)
                (for-each
                 (lambda (program)
                   (install-file (string-append "target/release/" program)
                                 bin))
                 '("notion-river" "notion-ctl"))
                (install-file "notion-river-session" bin)
                (mkdir-p examples)
                (copy-recursively "config-examples" examples)
                (copy-file "config.example.toml"
                           (string-append examples "/config.toml"))
                (mkdir-p sessions)
                (install-file "notion-river.desktop" sessions)
                (mkdir-p completions)
                (install-file "completions/notion-ctl.fish" completions))))
          (add-after 'install-notion-river 'install-license-notices
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (doc (string-append out "/share/doc/notion-river"))
                     (protocol-doc (string-append doc "/protocol"))
                     (third-party (string-append doc "/third-party-licenses")))
                ;; The MIT application license covers the shipped examples.
                ;; Retain all protocol notices and the locked Rust components'
                ;; license texts because both are compiled into the binaries.
                (mkdir-p doc)
                (install-file "LICENSE" doc)
                (install-file "README.md" doc)
                (mkdir-p protocol-doc)
                (for-each (lambda (file) (install-file file protocol-doc))
                          (find-files "protocol" "\\.xml$"))
                (for-each
                 (lambda (file)
                   (let ((destination
                          (string-append third-party "/"
                                         (basename (dirname file)))))
                     (mkdir-p destination)
                     (install-file file destination)))
                 (find-files "guix-vendor"
                             "^(LICENSE|COPYING|NOTICE|UNLICENSE)([-.].*)?$"))))))))
    (native-inputs (list pkg-config))
    ;; System libraries used by cairo-rs, pango, freetype-rs, xkbcommon, and
    ;; Wayland.  River/wlroots/Zig are deliberately absent: River is a
    ;; separate runtime compositor and its submodule is not a build input.
    (inputs
     (append (list bash-minimal cairo pango freetype libxkbcommon wayland)
             %notion-river-cargo-inputs))
    (synopsis "Static tiling window manager for the River compositor")
    (description
     "Notion River is a Notion/Ion3-style static tiling window manager for
the River Wayland compositor.  It provides persistent frame layouts, tabbed
windows, configuration under @file{$XDG_CONFIG_HOME/notion-river}, and the
@command{notion-ctl} JSON IPC client.  This package builds the exact reviewed
source commit and its complete Cargo.lock registry graph offline.  It installs
session integration, examples, protocol notices, and third-party Rust license
texts while leaving River itself to the user's PATH; no River submodule, Zig,
or wlroots source is fetched or built.")
    (home-page "https://github.com/Marenz/notion-river")
    (license license:expat)))
