;;; Complete registry graph for rust-effects at d7fe96deb196fed0a222d0d3b796145f78420f39.
;;; Upstream has wildcard dependencies and no lockfile.  Resolve its full feature
;;; graph with Cargo 1.93 and rust-version 1.86 (MSRV fallback), then retain
;;; compatible crate versions already present in this channel (2026-10-06).
;;; Each SHA-256 was checked against the fetched registry archive; the hashes
;;; below are the lockfile digests converted to Guix base32.

(define-module (tay packages rust-effects-cargo-sources)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (tay packages auxiliary)
  #:export (rust-effects-cargo-inputs rust-effects-cargo-lock))

(define rust-effects-cargo-lock
  (local-file (search-tay-package-file "rust-effects-Cargo.lock")))

(define (crate-source name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://crates.io/api/v1/crates/"
                        name "/" version "/download"))
    (file-name (string-append "rust-" name "-" version ".tar.gz"))
    (sha256 (base32 hash))))

;; Include target-specific dependencies: Cargo resolves the entire lock graph,
;; not only the crates compiled for the host.
(define rust-effects-cargo-inputs
  (list
    (crate-source "bitflags" "2.13.1" "1nl76mpykmwmb8rq1l5vw1azdh1wvxdrnsk4sy3rdrzx01nvg25m")
    (crate-source "bytes" "1.11.1" "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y")
    (crate-source "cfg-if" "1.0.4" "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k")
    (crate-source "errno" "0.3.14" "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir")
    (crate-source "futures" "0.3.32" "0b9q86r5ar18v5xjiyqn7sb8sa32xv98qqnfz779gl7ns7lpw54b")
    (crate-source "futures-channel" "0.3.32" "07fcyzrmbmh7fh4ainilf1s7gnwvnk07phdq77jkb9fpa2ffifq7")
    (crate-source "futures-core" "0.3.32" "07bbvwjbm5g2i330nyr1kcvjapkmdqzl4r6mqv75ivvjaa0m0d3y")
    (crate-source "futures-executor" "0.3.32" "17aplz3ns74qn7a04qg7qlgsdx5iwwwkd4jvdfra6hl3h4w9rwms")
    (crate-source "futures-io" "0.3.32" "063pf5m6vfmyxj74447x8kx9q8zj6m9daamj4hvf49yrg9fs7jyf")
    (crate-source "futures-macro" "0.3.32" "0ys4b1lk7s0bsj29pv42bxsaavalch35rprp64s964p40c1bfdg8")
    (crate-source "futures-sink" "0.3.32" "14q8ml7hn5a6gyy9ri236j28kh0svqmrk4gcg0wh26rkazhm95y3")
    (crate-source "futures-task" "0.3.32" "14s3vqf8llz3kjza33vn4ixg6kwxp61xrysn716h0cwwsnri2xq3")
    (crate-source "futures-util" "0.3.32" "1mn60lw5kh32hz9isinjlpw34zx708fk5q1x0m40n6g6jq9a971q")
    (crate-source "libc" "0.2.189" "1whjfs375vlng2q6yrbzs73cvp5lm3w1n2gfqajb2vgf7zg3xbry")
    (crate-source "lock_api" "0.4.14" "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2")
    (crate-source "memchr" "2.8.3" "161xa63ipfanf8v3nb82xd5hqgydv55nzw59wyngqbz6alfaz2yg")
    (crate-source "mio" "1.2.1" "1nkggmrlnjs93w8rja4lvjj4aml1xqahgimv1h0p7d373kvhmg82")
    (crate-source "parking_lot" "0.12.5" "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck")
    (crate-source "parking_lot_core" "0.9.12" "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896")
    (crate-source "pin-project-lite" "0.2.17" "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8")
    (crate-source "proc-macro2" "1.0.107" "1nb6ly8kp65f724kj73ippc7lvydss24sm2vagk6qpklpg4pwplq")
    (crate-source "quote" "1.0.47" "00ch0yyzvv6s671ik0kcsbw8nigdaj2g3fr61kcahwx48aqlvgqz")
    (crate-source "redox_syscall" "0.5.18" "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd")
    (crate-source "scopeguard" "1.2.0" "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l")
    (crate-source "signal-hook-registry" "1.4.8" "06vc7pmnki6lmxar3z31gkyg9cw7py5x9g7px70gy2hil75nkny4")
    (crate-source "slab" "0.4.12" "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c")
    (crate-source "smallvec" "1.15.2" "143wzbqf6vgapdp2z4qpl0yvlqcn17s8cnk8m28rqly808zsdmlf")
    (crate-source "socket2" "0.6.4" "0ldyp5rhba15spwxj1n94xh7sjks1398c3vwpwkxkd1087nwzlaj")
    (crate-source "syn" "2.0.119" "15vjy620l91a3q4n4f4gzhnflmdr6pnm38v2m6cpk86i8av32a47")
    (crate-source "tokio" "1.52.3" "1zpzazypkg61sw91na1m85x5s4rsjym335fwwhwm1hcs70dz1iwg")
    (crate-source "tokio-macros" "2.7.0" "15m4f37mdafs0gg36sh0rskm1i768lb7zmp8bw67kaxr3avnqniq")
    (crate-source "unicode-ident" "1.0.24" "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76")
    (crate-source "wasi" "0.11.1+wasi-snapshot-preview1" "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc")
    (crate-source "windows-link" "0.2.1" "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h")
    (crate-source "windows-sys" "0.61.2" "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf")))
