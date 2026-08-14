;;; GNU Guix package for the redistributable Computus simulation core.
;;;
;;; SPDX-License-Identifier: GPL-3.0-only

(define-module (tay packages computus)
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:))

(define %computus-commit
  "edd0c377b02bbfb3d4726d7df668761cb35accb9")

(define (computus-crate-source name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://crates.io/api/v1/crates/"
                        name "/" version "/download"))
    (file-name (string-append name "-" version ".crate"))
    (sha256 (base32 hash))))

(define computus-cargo-inputs
  (list
    (computus-crate-source "async-trait" "0.1.91" "1v3cm8mzg66037wm392p1vsdx0lq8bid6y2ivr7z03lpfx0xqdmf")
    (computus-crate-source "autocfg" "1.5.1" "0lqasy5i30flcgih1b50kvsk6z32g09r1q4ql7q81pj6228jy0zj")
    (computus-crate-source "bumpalo" "3.20.3" "0jc6va3nwcqikm7chnpdv1s87my3gs2j7g1sc7g3k91brg3arxbj")
    (computus-crate-source "cast" "0.3.0" "1dbyngbyz2qkk0jn2sxil8vrz3rnpcj142y184p9l4nbl9radcip")
    (computus-crate-source "cc" "1.4.0" "1fc26n76n7gr37m2q0xw5l8jpn4sd33hvyppmwhv6v4fcyxq3pas")
    (computus-crate-source "cfg-if" "1.0.4" "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k")
    (computus-crate-source "console_error_panic_hook" "0.1.7" "1g5v8s0ndycc10mdn6igy914k645pgpcl8vjpz6nvxkhyirynsm0")
    (computus-crate-source "find-msvc-tools" "0.1.9" "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv")
    (computus-crate-source "futures-core" "0.3.33" "1iqdbvcdlplfr2g43h7xrfkv2sg5p1a26x8acz1xgxl07i3hrm9c")
    (computus-crate-source "futures-task" "0.3.33" "02f1y1yvjg1cv998zkgl1706pi9y4fyc9045l1hlmyqyhclfscdj")
    (computus-crate-source "futures-util" "0.3.33" "1anyg40j5www5l22r2jbn1birsafz4q1w9qmcjk4vqzwasi90ym7")
    (computus-crate-source "getrandom" "0.2.17" "1l2ac6jfj9xhpjjgmcx6s1x89bbnw9x6j9258yy6xjkzpq0bqapz")
    (computus-crate-source "itoa" "1.0.18" "10jnd1vpfkb8kj38rlkn2a6k02afvj3qmw054dfpzagrpl6achlg")
    (computus-crate-source "js-sys" "0.3.103" "00lib0b6hqmw56r2hjp7xrv730qacslirbkdlhvmi39zvgy4pd2k")
    (computus-crate-source "libc" "0.2.189" "1whjfs375vlng2q6yrbzs73cvp5lm3w1n2gfqajb2vgf7zg3xbry")
    (computus-crate-source "libm" "0.2.16" "10brh0a3qjmbzkr5mf5xqi887nhs5y9layvnki89ykz9xb1wxlmn")
    (computus-crate-source "memchr" "2.8.3" "161xa63ipfanf8v3nb82xd5hqgydv55nzw59wyngqbz6alfaz2yg")
    (computus-crate-source "minicov" "0.3.8" "0kg2bajhhzwafpvhqpvfaddrwy6z0ggvqlirdpb0b5jnj6jbcsa8")
    (computus-crate-source "nu-ansi-term" "0.50.3" "1ra088d885lbd21q1bxgpqdlk1zlndblmarn948jz2a40xsbjmvr")
    (computus-crate-source "num-traits" "0.2.19" "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787")
    (computus-crate-source "once_cell" "1.21.4" "0l1v676wf71kjg2khch4dphwh1jp3291ffiymr2mvy1kxd5kwz4z")
    (computus-crate-source "oorandom" "11.1.5" "07mlf13z453fq01qff38big1lh83j8l6aaglf63ksqzzqxc0yyfn")
    (computus-crate-source "pin-project-lite" "0.2.17" "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8")
    (computus-crate-source "ppv-lite86" "0.2.21" "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5")
    (computus-crate-source "proc-macro2" "1.0.107" "1nb6ly8kp65f724kj73ippc7lvydss24sm2vagk6qpklpg4pwplq")
    (computus-crate-source "quote" "1.0.47" "00ch0yyzvv6s671ik0kcsbw8nigdaj2g3fr61kcahwx48aqlvgqz")
    (computus-crate-source "rand" "0.8.7" "06iaf16fr0z8zly7anmn8ky0p80xnx9yv0gdcm30fwn9vqmigxi2")
    (computus-crate-source "rand_chacha" "0.3.1" "123x2adin558xbhvqb8w4f6syjsdkmqff8cxwhmjacpsl1ihmhg6")
    (computus-crate-source "rand_core" "0.6.4" "0b4j2v4cb5krak1pv6kakv4sz6xcwbrmy2zckc32hsigbrwy82zc")
    (computus-crate-source "rand_xoshiro" "0.6.0" "1ajsic84rzwz5qr0mzlay8vi17swqi684bqvwqyiim3flfrcv5vg")
    (computus-crate-source "rustversion" "1.0.23" "07z2a843fs80fawwflj9jwn49k9b0bd0dhhbvy0ar69vaxd72m6g")
    (computus-crate-source "same-file" "1.0.6" "00h5j1w87dmhnvbv9l8bic3y7xxsnjmssvifw2ayvgx9mb1ivz4k")
    (computus-crate-source "serde" "1.0.229" "1fp04fq4a79bpm61xz1zy0pbz4kpc7d771zii1k3inmszq55jj21")
    (computus-crate-source "serde-wasm-bindgen" "0.6.5" "0sz1l4v8059hiizf5z7r2spm6ws6sqcrs4qgqwww3p7dy1ly20l3")
    (computus-crate-source "serde_core" "1.0.229" "0j1ajiha76h3nmd976il9li6975k121xa7jb39ws8n0yqp4s5p37")
    (computus-crate-source "serde_derive" "1.0.229" "0j4k63i7h1bikxwz2c89ig0hrwbnl9mz1czn85xx99x5cc9dg9g7")
    (computus-crate-source "serde_json" "1.0.151" "051zww7lvpw147vvwss1ng6w587qyrkzg75fvj08q2dfrmgbahf8")
    (computus-crate-source "shlex" "2.0.1" "1fjsll1cd7d2bcpdij9kd6w62rpbc7qqzvydvs021vsmr1cxvypq")
    (computus-crate-source "slab" "0.4.12" "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c")
    (computus-crate-source "syn" "2.0.119" "15vjy620l91a3q4n4f4gzhnflmdr6pnm38v2m6cpk86i8av32a47")
    (computus-crate-source "syn" "3.0.3" "18srnql3cd39j9q6hf1az02p67rlr1rf6njx9zx4vxj9i3jvmsak")
    (computus-crate-source "unicode-ident" "1.0.24" "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76")
    (computus-crate-source "walkdir" "2.5.0" "0jsy7a710qv8gld5957ybrnc07gavppp963gs32xk4ag8130jy99")
    (computus-crate-source "wasi" "0.11.1+wasi-snapshot-preview1" "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc")
    (computus-crate-source "wasm-bindgen" "0.2.126" "197rma4qg1kb8l4bl7857pgszzval8s1w740g9myyjh92467q1jb")
    (computus-crate-source "wasm-bindgen-futures" "0.4.76" "0799v92cpaprapnmpaflc51sdnz362q2fsjdqnwiq8ij1wsg2bf6")
    (computus-crate-source "wasm-bindgen-macro" "0.2.126" "1cda6wl5zyiy7777cfgrix7fhpaqba55l5zpqj4zig7ng7jyaz0n")
    (computus-crate-source "wasm-bindgen-macro-support" "0.2.126" "03iq412frl2py55skwb3ya08xha0cf6q22zr5kqlwbr675w7r6gk")
    (computus-crate-source "wasm-bindgen-shared" "0.2.126" "097a3kbjls447s1lwr41l21x5crrh5vq3h6zsxccz7slrjq4q6yw")
    (computus-crate-source "wasm-bindgen-test" "0.3.76" "1x4n18qxi8v0ys4jqcwg87jp8klajif4zy8lsgw5si3lm1f5a39a")
    (computus-crate-source "wasm-bindgen-test-macro" "0.3.76" "0861xmm6myaafcizqnwrz9wr8119nn0f5azliigfmg4mbdaniswl")
    (computus-crate-source "wasm-bindgen-test-shared" "0.2.126" "085r0i8qjfccc6sgsjp44v2bavgmrmfdi3jqd34ncf473q15c7f3")
    (computus-crate-source "winapi-util" "0.1.11" "08hdl7mkll7pz8whg869h58c1r9y7in0w0pk8fm24qc77k0b39y2")
    (computus-crate-source "windows-link" "0.2.1" "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h")
    (computus-crate-source "windows-sys" "0.61.2" "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf")
    (computus-crate-source "zerocopy" "0.8.55" "1swncvj53zi9yr08b9ddhfrcmlrmh6ijxzxcr3p6w3qlgg6hb8dm")
    (computus-crate-source "zerocopy-derive" "0.8.55" "1sr8w9zc62lxmw7v6n89nxvqlki48b0nyfpyri6dd367f3xpds8g")
    (computus-crate-source "zmij" "1.0.23" "06zwri21nnrl34rwinmvbciap8yk1mrl8qfg9pff7lgspc56sri9")))

(define-public rust-computus
  (package
    (name "rust-computus")
    (version "0.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/htayj/computus")
             (commit %computus-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0y10qc8ayildfzacp09w6gqbqqvcfl7g8g4yc7gwh41ssi77cra8"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:cargo-package-crates ''("core")
      #:phases
      #~(modify-phases %standard-phases
          ;; The source tree's generated art is explicitly outside the GPL.
          ;; It is removed before Cargo can package the core crate, so neither
          ;; the installed cargo source nor the package output includes it.
          (add-after 'unpack 'enter-redistributable-core
            (lambda _
              ;; cargo-build-system removes a lock file in its current
              ;; directory.  The actual crate is nested below the workspace,
              ;; so remove this parent lock before entering it as well.
              (delete-file "Cargo.lock")
              (delete-file-recursively "assets")
              (chdir "core")
              ;; Cargo otherwise uses the parent workspace's target directory,
              ;; while cargo-build-system packages from the current crate.
              (setenv "CARGO_TARGET_DIR"
                      (string-append (getcwd) "/target"))))
          (add-after 'install 'install-license
            (lambda _
              (install-file "../LICENSE"
                            (string-append #$output
                                           "/share/doc/rust-computus")))))))
    ;; Cargo resolves exclusively from these commit-locked crate archives;
    ;; cargo-build-system configures Cargo with --offline for build and test.
    (inputs computus-cargo-inputs)
    (synopsis "Deterministic inn-management simulation core")
    (description
     "Computus is the deterministic Rust simulation core of a medieval inn
management game.  It provides the day clock, candle, inventory, ledger,
staff, guild, economy, save state, and seeded random-number simulation that
the browser front end uses through WebAssembly bindings.")
    (home-page "https://github.com/htayj/computus")
    (license license:gpl3)))
