;;; Immutable offline module source closure for ludviglundgren/qbittorrent-cli.
;;; Versions are the complete 67-module graph from upstream v2.3.0's go.mod.
;;; ZIP hashes cover the actual proxy.golang.org archive bytes, not Go's h1
;;; normalized module digest.  Libraries are compiled only by the CLI package.
(define-module (tay packages ludviglundgren-qbittorrent-cli-go-sources)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang)
  #:export (%ludviglundgren-qbittorrent-cli-go-modules))

;; Proxy URLs escape uppercase letters as ! followed by the lowercase letter.
;; Archive entries, however, use the original, case-sensitive module path.
(define (go-proxy-escape text)
  (string-concatenate
   (map (lambda (character)
          (if (char-upper-case? character)
              (string #\! (char-downcase character))
              (string character)))
        (string->list text))))

;; publicsuffix/table.go names this exact upstream data revision.  The Go
;; module ships only its generated binary tables, not the MPL source or text.
(define %public-suffix-list-source
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/publicsuffix/list/d6c92f1bbb7433e5db7b8405c25d4035fb8ff376/public_suffix_list.dat")
    (file-name "public-suffix-list-d6c92f1.dat")
    (sha256
     (base32 "1gp79v8x2v57lqrl2lhixvr4n0idxbwpclvs28mr133y2n0q4qx5"))))

(define %public-suffix-list-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/publicsuffix/list/d6c92f1bbb7433e5db7b8405c25d4035fb8ff376/LICENSE")
    (file-name "public-suffix-list-d6c92f1-LICENSE")
    (sha256
     (base32 "0wji1lq3xnj4b3zd0pa6747fvcnc8wharsjknym5i86nb9yi18v6"))))

(define* (go-proxy-module name import-path version hash license notice-paths
                          #:key (retain-source? #f) (additional-sources '()))
  (package
    (name name)
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://proxy.golang.org/"
                           (go-proxy-escape import-path) "/@v/"
                           (go-proxy-escape version) ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256 (base32 hash))))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.25
           #:import-path import-path
           #:install-source? #t
           #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               ;; Do not infer the module root from go.mod: several legacy
               ;; modules have no such file, and modules can nest other roots.
               (replace 'unpack
                 (lambda* (#:key source #:allow-other-keys)
                   (let* ((scratch "module-proxy-archive")
                          (root (string-append scratch "/" #$import-path
                                               "@" #$version))
                          (destination (string-append "src/" #$import-path)))
                     (mkdir-p scratch)
                     (invoke "unzip" "-q" source "-d" scratch)
                     (mkdir-p destination)
                     (copy-recursively root destination #:keep-mtime? #t)
                     (for-each
                      (lambda (entry)
                        (let ((target (string-append destination "/" (car entry))))
                          (mkdir-p (dirname target))
                          (copy-file (cadr entry) target)))
                      '#$additional-sources)
                     (delete-file-recursively scratch))))
               (delete 'build)
               (delete 'check)
               ;; These are source archives, not executable packages.  Keep
               ;; source and embedded notices byte-for-byte as distributed.
               (delete 'patch-usr-bin-file)
               (delete 'patch-source-shebangs)
               (delete 'patch-shebangs)
               (delete 'strip)
               ;; Preserve nested paths, including REUSE LICENSES directories,
               ;; *.license sidecars, GO_LICENSE and source-carried notices.
               (replace 'install-license-files
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((source-root (string-append "src/" #$import-path))
                         (doc (string-append (assoc-ref outputs "out")
                                             "/share/doc/" #$name)))
                     (for-each
                      (lambda (relative)
                        (let ((target (string-append doc "/" relative)))
                          (mkdir-p (dirname target))
                          (copy-file (string-append source-root "/" relative)
                                     target)))
                      '#$notice-paths)))))))
    (native-inputs (list unzip))
    ;; The CLI embeds the complete source of each MPL-covered module, not just
    ;; the compiled subpackages.  All nodes retain their full GOPATH source.
    (properties `((retain-source? . ,retain-source?)))
    (synopsis "Pinned Go module source for qBittorrent CLI")
    (description "This source-only package is a pinned member of the offline
Go module graph for ludviglundgren's qBittorrent CLI.  It installs the full
module source together with root and nested copyright and license notices.")
    (home-page (string-append "https://pkg.go.dev/" import-path))
    (license license)))

(define %ludviglundgren-qbittorrent-cli-go-modules
  (list
   (go-proxy-module
    "go-qbt-github-com-anacrolix-torrent"
    "github.com/anacrolix/torrent" "v1.61.0"
    "1vz0gmq7c6g3r33501rqwqch1iil3cgc9kr1z3jg742xd08khfaq"
    (list license:mpl2.0 license:expat license:bsd-3)
    (list
     "LICENSE"
     "webtorrent/LICENSE"
     "metainfo/piece-length.go") #:retain-source? #t)
   (go-proxy-module
    "go-qbt-github-com-autobrr-go-qbittorrent"
    "github.com/autobrr/go-qbittorrent" "v1.16.0"
    "1n31dq916w3fqch9d1ffwc3h99yb92c253px75si9h9dv3jnqaql"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-blang-semver"
    "github.com/blang/semver" "v3.5.1+incompatible"
    "0g5dfyb3xgcpbxvqm26pxrcj000sldvm86v4rzvr6nw3rycj60wd"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-dustin-go-humanize"
    "github.com/dustin/go-humanize" "v1.0.1"
    "0ipsg53djjj8j0d1lgnyfr4x0zbf025rhc1zv39y5968hkm0951i"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-magiconair-properties"
    "github.com/magiconair/properties" "v1.8.10"
    "1fzpry085zzrg1jg1cv1j5xjxvr1zwa6pr9ixc9qbqy05l8f8k1w"
    license:bsd-2
    (list
     "LICENSE.md"))
   (go-proxy-module
    "go-qbt-github-com-mholt-archives"
    "github.com/mholt/archives" "v0.1.5"
    "0m4jfwz4r2pvy0clapsizd8jd17n00gz1p7hkhj6xa4d1lrfajv3"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-mitchellh-go-homedir"
    "github.com/mitchellh/go-homedir" "v1.1.0"
    "1171mp036q6vl3xmp3qb2hn2v672bql0qmik2jvnnxvyzihw7zpz"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-pkg-errors"
    "github.com/pkg/errors" "v0.9.1"
    "01xxy95b9w8djvr9c1b701pbscdrac7mw88k7452j5h6rn5nphyl"
    license:bsd-2
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-rhysd-go-github-selfupdate"
    "github.com/rhysd/go-github-selfupdate" "v1.2.3"
    "1yhdkzx46q9160wn2pg4s3awdi3y4dj2p0124wd6h5kqcf589sd3"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-spf13-cobra"
    "github.com/spf13/cobra" "v1.10.2"
    "0bc74rggynmiipb619dqqdrin3pp5x2h91n9abg0y7k3rmpsw2m0"
    license:asl2.0
    (list
     "LICENSE.txt"))
   (go-proxy-module
    "go-qbt-github-com-spf13-viper"
    "github.com/spf13/viper" "v1.21.0"
    "17i4gg6dmwrwaibwxv61s6q56c0rcxnxxzhdkz22fh5pvg6f95j0"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-zeebo-bencode"
    "github.com/zeebo/bencode" "v1.0.0"
    "03c9g0ajrppmnn78nfdrjkhzcb8b580hpiiffgns2p61s3kaq38r"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-golang-org-x-net"
    "golang.org/x/net" "v0.55.0"
    "0q9fni7acw52fyxw3yah8xnwkhwvypc24lfbldhdw0ksigarrhi1"
    (list license:bsd-3 license:mpl2.0)
    (list
     "LICENSE"
     "PATENTS"
     "publicsuffix/public_suffix_list.dat"
     "publicsuffix/LICENSE-MPL-2.0")
    #:retain-source? #t
    #:additional-sources
    (list (list "publicsuffix/public_suffix_list.dat"
                %public-suffix-list-source)
          (list "publicsuffix/LICENSE-MPL-2.0"
                %public-suffix-list-license)))
   (go-proxy-module
    "go-qbt-github-com-masterminds-semver"
    "github.com/Masterminds/semver" "v1.5.0"
    "00kj3bsik8x0yfyv9q9rlylrpaqgsmg9wwfm0nrgy5awd55bbxhm"
    license:expat
    (list
     "LICENSE.txt"))
   (go-proxy-module
    "go-qbt-github-com-starry-s-zip"
    "github.com/STARRY-S/zip" "v0.2.3"
    "0sx7cca19qrb16f7jka8z0lp0555pz3z17ihpralnvfw9k1zaykv"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-anacrolix-generics"
    "github.com/anacrolix/generics" "v0.1.1-0.20251125230353-15d98d46693b"
    "1s7d8sqw9810ip0dl655x2yxvavhh5z60w8ydbdgjhn0baz7c53b"
    (list license:mpl2.0 license:bsd-3)
    (list
     "LICENSE"
     "list/LICENSE") #:retain-source? #t)
   (go-proxy-module
    "go-qbt-github-com-anacrolix-missinggo"
    "github.com/anacrolix/missinggo" "v1.3.0"
    "1wbn40s2f4czcjfwns0vzw89cxnzdnavm3nsza1bqxnb47mcla0h"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-anacrolix-missinggo-v2"
    "github.com/anacrolix/missinggo/v2" "v2.10.0"
    "0nlk95zb5xj0jz9hjvwk3mc2b35dq0s49szjh3fjpxwg0iv59p3v"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-andybalholm-brotli"
    "github.com/andybalholm/brotli" "v1.2.0"
    "0dmadmdl68vn0a5dma6ahhl67vhzzp63hy0hskp94qirvbb7vi74"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-avast-retry-go"
    "github.com/avast/retry-go" "v3.0.0+incompatible"
    "0i59lk3fmvvaa7fwar2vcj2f22cmx08b5z2nnlsra48cba025ygy"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-bodgit-plumbing"
    "github.com/bodgit/plumbing" "v1.3.0"
    "12d0argbqnka422q34n9pn5b407vyq1a093ci9wp5ffniz4hvj0m"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-bodgit-sevenzip"
    "github.com/bodgit/sevenzip" "v1.6.1"
    "0ljcrkjfy5ihw0drnxvjyms4vzsmwhc1i6s6zxl6ycimqjdwrmvq"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-bodgit-windows"
    "github.com/bodgit/windows" "v1.0.1"
    "0mp935pv5075xf1qz8xfdgcamp1wvp7v41cwn5ix8brphz3g3rfb"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-cpuguy83-go-md2man-v2"
    "github.com/cpuguy83/go-md2man/v2" "v2.0.6"
    "0467ly7ykjr222kbbx0zmb601s5r6hnv7hnjd65x5kwbwcb961dq"
    license:expat
    (list
     "LICENSE.md"))
   (go-proxy-module
    "go-qbt-github-com-dsnet-compress"
    "github.com/dsnet/compress" "v0.0.2-0.20230904184137-39efe44ab707"
    "0hzfi6vf9hl1cq2flqhincag3jic138j5mp6d4xncajvkh112qdw"
    (list license:bsd-3 license:expat)
    (list
     "LICENSE.md"
     "bzip2/internal/sais/sais_byte.go"
     "bzip2/internal/sais/sais_gen.go"
     "bzip2/internal/sais/sais_int.go"))
   (go-proxy-module
    "go-qbt-github-com-fsnotify-fsnotify"
    "github.com/fsnotify/fsnotify" "v1.9.0"
    "0vklmc6q5xmvxzm8566lyj4dwmrzxkaj2csfa2mbg49mn8j4irll"
    license:bsd-3
    (list
     "LICENSE"
     "internal/ztest/diff.go"))
   (go-proxy-module
    "go-qbt-github-com-go-viper-mapstructure-v2"
    "github.com/go-viper/mapstructure/v2" "v2.4.0"
    "0si9rbf808n0hayblakfxqd82wg87gfih4yrr6wb397c6j73kq1k"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-google-go-github-v30"
    "github.com/google/go-github/v30" "v30.1.0"
    "0g9a3a348rdf5hc3x1nfsadlq0vrvhrjzs3np1z8yskqaqfv1k1l"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-google-go-querystring"
    "github.com/google/go-querystring" "v1.1.0"
    "0aypdmjkk1wficihwbyrw5aad4jp6970flc7j9vn2bk0yl0zram6"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-hashicorp-golang-lru-v2"
    "github.com/hashicorp/golang-lru/v2" "v2.0.7"
    "0c6c39b9a3x6fzj3f0fsfhabafy0pxal5qgs1r3cvg3h77qjzf9f"
    (list license:mpl2.0 license:bsd-3)
    (list
     "LICENSE"
     "simplelru/LICENSE_list"
     "2q.go"
     "2q_test.go"
     "doc.go"
     "expirable/expirable_lru.go"
     "expirable/expirable_lru_test.go"
     "lru.go"
     "lru_test.go"
     "simplelru/lru.go"
     "simplelru/lru_interface.go"
     "simplelru/lru_test.go"
     "testing_test.go") #:retain-source? #t)
   (go-proxy-module
    "go-qbt-github-com-huandu-xstrings"
    "github.com/huandu/xstrings" "v1.5.0"
    "18m6mkx4nh6ma3wapwzdnqhbig6fvzcvi32r1vyv2dawgs4hxgbl"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-inconshreveable-go-update"
    "github.com/inconshreveable/go-update" "v0.0.0-20160112193335-8152e7eb6ccf"
    "0y5nhjl51081bf1jh1zyk336slsamwfs6hnv5sdhbig797xmdy5d"
    (list license:asl2.0 license:expat license:bsd-3)
    (list
     "LICENSE"
     "internal/binarydist/License"
     "internal/osext/LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-inconshreveable-mousetrap"
    "github.com/inconshreveable/mousetrap" "v1.1.0"
    "0hyjis96fmc14i12a9jhr1xxkpyc23qkwrg7rw4b2zadcbg78rjj"
    license:asl2.0
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-klauspost-compress"
    "github.com/klauspost/compress" "v1.18.0"
    "01b9y1z2w2ypbklisvwflfr5xgsafnz8bncrh5sj22l2pi69wry4"
    (list license:asl2.0 license:expat license:bsd-3)
    (list
     "LICENSE"
     "gzhttp/LICENSE"
     "internal/lz4ref/LICENSE"
     "internal/snapref/LICENSE"
     "s2/LICENSE"
     "s2/cmd/internal/filepathx/LICENSE"
     "s2/cmd/internal/readahead/LICENSE"
     "snappy/LICENSE"
     "snappy/xerial/LICENSE"
     "zstd/internal/xxhash/LICENSE.txt"))
   (go-proxy-module
    "go-qbt-github-com-klauspost-cpuid-v2"
    "github.com/klauspost/cpuid/v2" "v2.2.10"
    "1zwdw0g0if3yyr5ibv8pkis6nlbwf14jvdsiqmylgvrcl9gnd2fv"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-klauspost-pgzip"
    "github.com/klauspost/pgzip" "v1.2.6"
    "116s1m9vghw5ryi2jdkvxbdd2pkwnlhwk95366ks3p127glhiica"
    (list license:expat license:bsd-3)
    (list
     "LICENSE"
     "GO_LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-mikelolasagasti-xz"
    "github.com/mikelolasagasti/xz" "v1.0.1"
    "1md8imizi766hncwk1z7ix1jkmir2w9xxf5wjdkrsfl2znajjrx4"
    (list license:bsd-0 license:public-domain)
    (list
     "LICENSE"
     "README.md"
     "dec_bcj.go"
     "dec_delta.go"
     "dec_lzma2.go"
     "dec_stream.go"
     "dec_util.go"
     "dec_xz.go"
     "example_test.go"
     "reader.go"
     "reader_test.go"))
   (go-proxy-module
    "go-qbt-github-com-minio-minlz"
    "github.com/minio/minlz" "v1.0.1"
    "1r4f01hvxf0p7dw1408dj8bhxj3884a50n41fdxr7f1yg8pdv7ma"
    (list license:asl2.0 license:expat license:bsd-2 license:bsd-3)
    (list
     "LICENSE"
     "cmd/internal/filepathx/LICENSE"
     "cmd/internal/readahead/LICENSE"
     "cmd/internal/shttp/LICENSE"
     "internal/lz4ref/LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-minio-sha256-simd"
    "github.com/minio/sha256-simd" "v1.0.1"
    "0p327i945harrnmixjkbw0kcg3xdh00idjy0hq1gmdrq0j7mv078"
    (list license:asl2.0 license:bsd-3)
    (list
     "LICENSE"
     "sha256_test.go"))
   (go-proxy-module
    "go-qbt-github-com-mr-tron-base58"
    "github.com/mr-tron/base58" "v1.2.0"
    "0zx2f32nfva8wlgfwlh5r6c687im6pxql3y40m71kff3avhpwr1n"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-multiformats-go-multihash"
    "github.com/multiformats/go-multihash" "v0.2.3"
    "02w6x0h8m1mvnwilig4vhyxnr5ckwfar3g0pgs1b2ahvb0a0wp22"
    license:expat
    (list
     "LICENSE"
     "multihash/LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-multiformats-go-varint"
    "github.com/multiformats/go-varint" "v0.0.7"
    "1565ys66slj3wvr6lrw0cbb4ryp1mhmdibkvf9dwyh47hjq66bf2"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-nwaples-rardecode-v2"
    "github.com/nwaples/rardecode/v2" "v2.2.0"
    "13n6bbc8h4fxgylk72idkpw8r9gifhvb3qsjg2gfs655rqlqgq1s"
    license:bsd-2
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-onsi-gomega"
    "github.com/onsi/gomega" "v1.37.0"
    "16j3mndvdyg70wis4xpvgqmjpanif7bgc5gl25h4l67q6rhcw70d"
    license:expat
    (list
     "LICENSE"
     "matchers/support/goraph/MIT.LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-pelletier-go-toml-v2"
    "github.com/pelletier/go-toml/v2" "v2.2.4"
    "1w4593wk4i534859han7ajarr2rh3zhg3q5z96zg6xshp3kjn5l2"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-pierrec-lz4-v4"
    "github.com/pierrec/lz4/v4" "v4.1.22"
    "1qh4haadb16ssks2ai6iwngjwgn04b0z27pydm72jjadq2c9kzl3"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-russross-blackfriday-v2"
    "github.com/russross/blackfriday/v2" "v2.1.0"
    "1bn60iq1s21hnsr73wzbabsn8xc110r20b0zn0wcwlx0b06palkq"
    license:bsd-2
    (list
     "LICENSE.txt"))
   (go-proxy-module
    "go-qbt-github-com-sagikazarmark-locafero"
    "github.com/sagikazarmark/locafero" "v0.11.0"
    "19gn74lyirzli0qkrwb99lfhndflmja4ssa7pyp3rxk7jpgrnakc"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-sorairolake-lzip-go"
    "github.com/sorairolake/lzip-go" "v0.3.8"
    "0cnavhw668pj4fq90gmnzvhkrfz0p7jv5bal08ab4blm43zgpypd"
    (list license:asl2.0 license:expat license:cc-by4.0 license:bsd-2 license:cc0)
    (list
     "LICENSE-APACHE"
     "LICENSE-MIT"
     ".github/pull_request_template.md.license"
     "LICENSES/Apache-2.0.txt"
     "LICENSES/BSD-2-Clause.txt"
     "LICENSES/CC-BY-4.0.txt"
     "LICENSES/CC0-1.0.txt"
     "LICENSES/MIT.txt"
     "cmd/glzip/testdata/foo.txt.license"
     "go.sum.license"
     "testdata/em.lz.license"
     "testdata/fox.lz.license"
     "testdata/fox_bcrc.lz.license"
     "testdata/fox_bm.lz.license"
     "testdata/fox_crc0.lz.license"
     "testdata/fox_das46.lz.license"
     "testdata/fox_de20.lz.license"
     "testdata/fox_mes81.lz.license"
     "testdata/fox_nz.lz.license"
     "testdata/fox_s11.lz.license"
     "testdata/fox_v2.lz.license"
     "testdata/test.txt.license"
     "testdata/test.txt.lz.license"
     "testdata/test_em.txt.lz.license"
     "CODE_OF_CONDUCT.md"
     "README.md"
     "cmd/glzip/cli.go"
     "cmd/glzip/compress.go"
     "cmd/glzip/doc.go"
     "cmd/glzip/main.go"
     "cmd/glzip/main_test.go"
     "cmd/glzip/uncompress.go"
     "error.go"
     "error_test.go"
     "example_test.go"
     "export_test.go"
     "lzip.go"
     "lzip_test.go"
     "reader.go"
     "reader_test.go"
     "writer.go"
     "writer_test.go"))
   (go-proxy-module
    "go-qbt-github-com-sourcegraph-conc"
    "github.com/sourcegraph/conc" "v0.3.1-0.20240121214520-5f936abd7ae8"
    "04wl1chacv1g9hns8j49ri3mmf0x1dwnsrvxlyaak2zphpi6zdbd"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-spaolacci-murmur3"
    "github.com/spaolacci/murmur3" "v1.1.0"
    "1g0pdbp1jlnl8h2k0ibinhqqdm06p6l7imhzncihiiwcm2nl7gb0"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-spf13-afero"
    "github.com/spf13/afero" "v1.15.0"
    "07vfpq0h4mqxgxymv1zfxx39zmdjgdq7c0hc7z1a3skyx2y0nfnh"
    license:asl2.0
    (list
     "LICENSE.txt"))
   (go-proxy-module
    "go-qbt-github-com-spf13-cast"
    "github.com/spf13/cast" "v1.10.0"
    "1knxsxm58vvilk04bqk6nzrf2k3vvwpnp7x6qa0akbbrk5zs4yvw"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-spf13-pflag"
    "github.com/spf13/pflag" "v1.0.10"
    "1jp45p8yshysqsh4zvzf2xc3v9bzvwdyxpsccdn7va6ssg4vhim2"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-subosito-gotenv"
    "github.com/subosito/gotenv" "v1.6.0"
    "138z1yy3izk0z225k94jkyvi6w023llz6p78az0l9rr84gfv6b8l"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-tcnksm-go-gitconfig"
    "github.com/tcnksm/go-gitconfig" "v0.1.2"
    "09fz0yb52z6m3rghwq81yzfjj24i1f70qqrpch7h54xbaqngj86m"
    license:expat
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-github-com-ulikunitz-xz"
    "github.com/ulikunitz/xz" "v0.5.15"
    "04pxb5chbki3ipqdz7bnsnchrbx0bqa2p3yj7809mjf6mgwk066a"
    (list license:bsd-2 license:bsd-3)
    (list
     "LICENSE"
     "cmd/xb/copyright.go"
     "cmd/gxz/licenses.go"))
   (go-proxy-module
    "go-qbt-go-yaml-in-yaml-v3"
    "go.yaml.in/yaml/v3" "v3.0.4"
    "0cggsbc3l5p5zhk2qkjky42j1fl9dbyni1vw8ra9k7madvjxl5q3"
    (list license:asl2.0 license:expat)
    (list
     "LICENSE"
     "NOTICE"
     "apic.go"
     "emitterc.go"
     "parserc.go"
     "readerc.go"
     "scannerc.go"
     "writerc.go"
     "yamlh.go"
     "yamlprivateh.go"))
   (go-proxy-module
    "go-qbt-go4-org"
    "go4.org" "v0.0.0-20230225012048-214862532bf5"
    "0gihvkrfp7x8jm7kc7rkk0z6rv3a586l0q9dyn0wvb15ph0sfxvs"
    license:asl2.0
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-golang-org-x-crypto"
    "golang.org/x/crypto" "v0.51.0"
    "0sis9ya2lb6707rssk2ni3chvi9lwxy43y7ckyzzrfxblsw672m2"
    license:bsd-3
    (list
     "LICENSE"
     "PATENTS"
     "twofish/twofish.go"))
   (go-proxy-module
    "go-qbt-golang-org-x-exp"
    "golang.org/x/exp" "v0.0.0-20251113190631-e25ba8c21ef6"
    "1kgxkjv0sw2b7jh9r1dm7c8qi3m0lppx3z2vxga9ra2qmi9ikh1f"
    license:bsd-3
    (list
     "LICENSE"
     "PATENTS"
     "shootout/binary-tree-freelist.go"
     "shootout/binary-tree.c"
     "shootout/binary-tree.go"
     "shootout/chameneosredux.c"
     "shootout/chameneosredux.go"
     "shootout/fannkuch-parallel.go"
     "shootout/fannkuch.c"
     "shootout/fannkuch.go"
     "shootout/fasta.c"
     "shootout/fasta.go"
     "shootout/k-nucleotide-parallel.go"
     "shootout/k-nucleotide.c"
     "shootout/k-nucleotide.go"
     "shootout/mandelbrot.c"
     "shootout/mandelbrot.go"
     "shootout/meteor-contest.c"
     "shootout/meteor-contest.go"
     "shootout/nbody.c"
     "shootout/nbody.go"
     "shootout/pidigits.c"
     "shootout/pidigits.go"
     "shootout/regex-dna-parallel.go"
     "shootout/regex-dna.c"
     "shootout/regex-dna.go"
     "shootout/reverse-complement.c"
     "shootout/reverse-complement.go"
     "shootout/spectral-norm-parallel.go"
     "shootout/spectral-norm.c"
     "shootout/spectral-norm.go"
     "shootout/threadring.c"
     "shootout/threadring.go"))
   (go-proxy-module
    "go-qbt-golang-org-x-oauth2"
    "golang.org/x/oauth2" "v0.36.0"
    "0125609jl02n262lx0jihk5qrs6il4vx136p174ayp9y23znbgqm"
    license:bsd-3
    (list
     "LICENSE"))
   (go-proxy-module
    "go-qbt-golang-org-x-sync"
    "golang.org/x/sync" "v0.20.0"
    "0xfkrcihgqiz41f3128c6r09ppxmrc8vyjwxvg5gvxh0i3bd8ybi"
    license:bsd-3
    (list
     "LICENSE"
     "PATENTS"))
   (go-proxy-module
    "go-qbt-golang-org-x-sys"
    "golang.org/x/sys" "v0.45.0"
    "0slynm9ndv9kz1zdknwyr10za7rq64hi446qibjdnkjv0j41q775"
    license:bsd-3
    (list
     "LICENSE"
     "PATENTS"))
   (go-proxy-module
    "go-qbt-golang-org-x-text"
    "golang.org/x/text" "v0.37.0"
    "10m92a9zqgp3w2rdzrbj1q3g9nxmrs27c57ij4mn1armg30pbm5q"
    license:bsd-3
    (list
     "LICENSE"
     "PATENTS"))
   (go-proxy-module
    "go-qbt-gopkg-in-check-v1"
    "gopkg.in/check.v1" "v1.0.0-20201130134442-10cb98267c6c"
    "03kicaqd59lxg24mas3jdda3zydqy7z4bcyx1n2w5b2xbi76hmgm"
    (list license:bsd-2 license:bsd-3)
    (list
     "LICENSE"
     "benchmark.go"))
   (go-proxy-module
    "go-qbt-lukechampine-com-blake3"
    "lukechampine.com/blake3" "v1.4.0"
    "181x44g07aij2hzjd7in7kq9043x993vccdd9vrsdbd6f1zkzh0k"
    license:expat
    (list
     "LICENSE"))))
