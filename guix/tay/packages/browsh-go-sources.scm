;;; Immutable Go source inputs for Browsh at
;;; 499ef386d45cd1e2b5457dd04887c017f77b7e27 (interfacer/go.mod: Go 1.24.4).
;;; These 36 modules are the package-import closure of every interfacer Go file,
;;; including upstream tests and platform-tagged files.  Versions are selected
;;; by the pruned module graph, not by the incidental presence of go.sum lines.
;;; All ZIPs match the pinned go.sum h1 values; SHA256 hashes cover archive bytes.
;;; Libraries are compiled only by Browsh, using Guix's single GOPATH union.
(define-module (tay packages browsh-go-sources)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang)
  #:export (%browsh-go-inputs))

;; Proxy URLs escape uppercase letters; ZIP entries keep the original case.
(define (go-proxy-escape text)
  (string-concatenate
   (map (lambda (character)
          (if (char-upper-case? character)
              (string #\! (char-downcase character))
              (string character)))
        (string->list text))))

;; x/net/publicsuffix/table.go identifies this revision of the MPL-covered PSL.
;; Preserve its source and license alongside the generated tables in the ZIP.
(define %public-suffix-list-source
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/publicsuffix/list/63cbc63d470d7b52c35266aa96c4c98c96ec499c/public_suffix_list.dat")
    (file-name "public-suffix-list-63cbc63d.dat")
    (sha256
     (base32 "0vm9vvbrfqn3piinkwzgi3d23j05rn70iq8pixsc0dva03aqilsd"))))

(define %public-suffix-list-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/publicsuffix/list/63cbc63d470d7b52c35266aa96c4c98c96ec499c/LICENSE")
    (file-name "public-suffix-list-63cbc63d-LICENSE")
    (sha256
     (base32 "0wji1lq3xnj4b3zd0pa6747fvcnc8wharsjknym5i86nb9yi18v6"))))

;; Ginkgo's outline/import.go records this copied Go-tools source revision,
;; but its module's root LICENSE is MIT rather than the copied file's BSD text.
(define %ginkgo-go-tools-license
  (origin
    (method url-fetch)
    (uri "https://raw.githubusercontent.com/golang/tools/2b0845dc783e36ae26d683f4915a5840ef01ab0f/LICENSE")
    (file-name "ginkgo-go-tools-2b0845dc-LICENSE")
    (sha256
     (base32 "0ry0rcq20jvrh2crvah7qj77s847fi9pzbimd008phqpf5zmjdid"))))

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
               ;; Legacy modules may not contain go.mod.  Use the exact proxy
               ;; archive root instead of discovering it from arbitrary files.
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
               ;; Keep the full upstream source and notices unmodified.
               (delete 'patch-usr-bin-file)
               (delete 'patch-source-shebangs)
               (delete 'patch-shebangs)
               (delete 'strip)
               (delete 'compress-documentation)
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
    ;; The application preserves corresponding sources for MPL-covered modules.
    (properties `((retain-source? . ,retain-source?)))
    (synopsis "Pinned Go module source for Browsh")
    (description "This source-only package belongs to Browsh's offline Go
build and upstream-test import closure.  It installs the entire module source
and all root and nested copyright and license notices without compilation.")
    (home-page (string-append "https://pkg.go.dev/" import-path))
    (license license)))

(define %browsh-go-inputs
  (list
   (go-proxy-module
    "go-browsh-github-com-nytimes-gziphandler"
    "github.com/NYTimes/gziphandler" "v1.1.1"
    "0nkhrjb2gj09z46c7p7pb4888q6a3ps0sh6r9qzz32231vvxjj19"
    license:asl2.0
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-fsnotify-fsnotify"
    "github.com/fsnotify/fsnotify" "v1.7.0"
    "1cibfpgw6mz4swks1q00zzq70jgyrr04iak2gfkwgwi4aalhi3zr"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-gdamore-encoding"
    "github.com/gdamore/encoding" "v1.0.0"
    "19m2wvmj9z99v40qmr0x6cgsa8hnmsyqc7aigj6i2bgnw8r9i2k3"
    license:asl2.0
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-gdamore-tcell"
    "github.com/gdamore/tcell" "v1.4.0"
    "123v9rh9ln71pzyfq59mabgbm807fjna1n9c4swjbigz83wnyrv7"
    license:asl2.0
    (list "AUTHORS" "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-go-errors-errors"
    "github.com/go-errors/errors" "v1.5.1"
    "1h2964fx38dlfsvfrqi9ynplmb98i9pkacp3kighm4hprcpa8c4n"
    license:expat
    (list "LICENSE.MIT"))
   (go-proxy-module
    "go-browsh-github-com-google-go-cmp"
    "github.com/google/go-cmp" "v0.6.0"
    "0jma5sxf21jnc2acynrhdb33ddv8insdz4dla430h4c2qkv9nkjb"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-gorilla-websocket"
    "github.com/gorilla/websocket" "v1.5.1"
    "0lx7xm9zkvb152smkggvvm03bp8ljsl0dcmjp6ydn467pf0kw670"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-hashicorp-hcl"
    "github.com/hashicorp/hcl" "v1.0.0"
    "0ay8fvxf3barxscjb3g27nv8wyfncc722y8wjqgyicr1a4p9l52l"
    license:mpl2.0
    (list "LICENSE")
    #:retain-source? #t)
   (go-proxy-module
    "go-browsh-github-com-lucasb-eyer-go-colorful"
    "github.com/lucasb-eyer/go-colorful" "v1.2.0"
    "046s390w7ir88g29v2k6saz73j6q8yldzdkpxnxm83vzfghd1mbq"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-magiconair-properties"
    "github.com/magiconair/properties" "v1.8.7"
    "19xa692i7cjv8f2a07dwnxdzj6d8qdw48023nmgh6r70kybfaxxf"
    license:bsd-2
    (list "LICENSE.md"))
   (go-proxy-module
    "go-browsh-github-com-mattn-go-runewidth"
    "github.com/mattn/go-runewidth" "v0.0.15"
    "1c29s43iy05ajww33knwnibkgi7ii0j8walkkib5fjd1cw34yz6r"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-mitchellh-mapstructure"
    "github.com/mitchellh/mapstructure" "v1.5.0"
    "16a16zpb4x8612czry11yf9sz70a8n7p0vgvcylxnl2wnqn5p38i"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-nxadm-tail"
    "github.com/nxadm/tail" "v1.4.11"
    "0yk6nl1sfj5y0f2g304ibj4a4975k6zffhk7h1hizcx920d7nan4"
    license:expat
    (list "LICENSE" "ratelimiter/Licence"))
   (go-proxy-module
    "go-browsh-github-com-onsi-ginkgo"
    "github.com/onsi/ginkgo" "v1.16.5"
    "1idcbrr6s0vp253b6rmjkmdqs7xz67whlhb39i7km9zz18xw6gz2"
    (list license:bsd-3 license:expat)
    (list "LICENSE" "reporters/stenographer/support/go-colorable/LICENSE" "reporters/stenographer/support/go-isatty/LICENSE" "ginkgo/outline/LICENSE.go-tools")
    #:additional-sources
    (list (list "ginkgo/outline/LICENSE.go-tools"
                %ginkgo-go-tools-license)))
   (go-proxy-module
    "go-browsh-github-com-onsi-gomega"
    "github.com/onsi/gomega" "v1.30.0"
    "0y34rwzr8kg1vzabbz924w53zlfa2qb3ap096qmsial3j49jzxjy"
    license:expat
    (list "LICENSE" "matchers/support/goraph/MIT.LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-pelletier-go-toml-v2"
    "github.com/pelletier/go-toml/v2" "v2.1.0"
    "0n8wb2bs6g9sr76ni9p3f1bvy0scaqyh4lz6jhgirzbfbs0p0r0s"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-pkg-errors"
    "github.com/pkg/errors" "v0.9.1"
    "01xxy95b9w8djvr9c1b701pbscdrac7mw88k7452j5h6rn5nphyl"
    license:bsd-2
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-rivo-uniseg"
    "github.com/rivo/uniseg" "v0.4.4"
    "0m27nhv6p2vwpppcw2frvchy75xd1sgm3wx0fzravvq4660da33l"
    license:expat
    (list "LICENSE.txt"))
   (go-proxy-module
    "go-browsh-github-com-sagikazarmark-locafero"
    "github.com/sagikazarmark/locafero" "v0.4.0"
    "04mrrqf10ys0666nbs4pchgannmf98r8wp76dzwwkh19ipszhilx"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-sagikazarmark-slog-shim"
    "github.com/sagikazarmark/slog-shim" "v0.1.0"
    "1vxzg0bxn6igccdmfmnj2hs8xi7y8kh9rszmrsysx0dlky3n9dr0"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-shibukawa-configdir"
    "github.com/shibukawa/configdir" "v0.0.0-20170330084843-e180dbdc8da0"
    "1xvwv2fvpy7i735ymqqj6ay2kblvpm1d89qvba2vic9z9pb0fbnj"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-sourcegraph-conc"
    "github.com/sourcegraph/conc" "v0.3.0"
    "0xk5paqw212s9hf11pna4cc5mnfcqmjpphv1k84p1l7v2iyi9lwq"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-spf13-afero"
    "github.com/spf13/afero" "v1.11.0"
    "0729lffqjs3vyr3zjlh0ixpvayixzy77qncza15vdgxndl45kbkh"
    license:asl2.0
    (list "LICENSE.txt"))
   (go-proxy-module
    "go-browsh-github-com-spf13-cast"
    "github.com/spf13/cast" "v1.6.0"
    "1s1n0xzdp2kam4kya7npyj20pl54llgxgsqvbv6cmi0rki3qv4zf"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-spf13-pflag"
    "github.com/spf13/pflag" "v1.0.5"
    "115s0y0qh5qv71fvz0b1cz421yj0ad741q3drv6xv13a5x7p0vpw"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-spf13-viper"
    "github.com/spf13/viper" "v1.18.1"
    "0xjjkw0hiwvay4jmmp9dp2zrp3nidfkjgicgvkl72mmxl8rc24yy"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-subosito-gotenv"
    "github.com/subosito/gotenv" "v1.6.0"
    "138z1yy3izk0z225k94jkyvi6w023llz6p78az0l9rr84gfv6b8l"
    license:expat
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-github-com-ulule-limiter"
    "github.com/ulule/limiter" "v2.2.2+incompatible"
    "0mbkk2zcbmhv0bvwkmb7daly6sikdkswzzhkg7jp200frgdgd8nb"
    license:expat
    (list "AUTHORS" "LICENSE"))
   (go-proxy-module
    "go-browsh-go-uber-org-multierr"
    "go.uber.org/multierr" "v1.11.0"
    "1hz0vjyl2xm73n3vrjv1ly2g16jraa2rsrqscvpgcqffzp9baj92"
    license:expat
    (list "LICENSE.txt"))
   (go-proxy-module
    "go-browsh-golang-org-x-exp"
    "golang.org/x/exp" "v0.0.0-20231206192017-f3f8817b8deb"
    "1gnisc5r76jfqgji4yb5p9f9w5picxyh2a2wr43s92qzl5hp02j3"
    license:bsd-3
    (list "LICENSE" "PATENTS"))
   (go-proxy-module
    "go-browsh-golang-org-x-net"
    "golang.org/x/net" "v0.19.0"
    "1ipdmf2zg92laiwqglbh0lrnaa38q4prbllqq824hb5fchjja5xr"
    (list license:bsd-3 license:mpl2.0)
    (list "LICENSE" "PATENTS" "publicsuffix/LICENSE.public-suffix-list")
    #:retain-source? #t
    #:additional-sources
    (list (list "publicsuffix/data/public_suffix_list.dat"
                %public-suffix-list-source)
          (list "publicsuffix/LICENSE.public-suffix-list"
                %public-suffix-list-license)))
   (go-proxy-module
    "go-browsh-golang-org-x-sys"
    "golang.org/x/sys" "v0.15.0"
    "1z71s4869v6fmqf9iz9if11bqvrccdjvxp28rq23p73kdi0yn4l6"
    license:bsd-3
    (list "LICENSE" "PATENTS"))
   (go-proxy-module
    "go-browsh-golang-org-x-text"
    "golang.org/x/text" "v0.14.0"
    "1bzlng0rpvnay1h0ybldacypllyvqxkg04x0lxvdb770w2bli0dr"
    license:bsd-3
    (list "LICENSE" "PATENTS"))
   (go-proxy-module
    "go-browsh-gopkg-in-ini-v1"
    "gopkg.in/ini.v1" "v1.67.0"
    "1ih61g3gvfjxkkwdf1bpvdv6ks43viq7g81jb9pab1rafvy5v15x"
    license:asl2.0
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-gopkg-in-tomb-v1"
    "gopkg.in/tomb.v1" "v1.0.0-20141024135613-dd632973f1e7"
    "11i1fs9d67q19d2gnbqlv4zk25ii27xf18vlmf9ag9wbwg08v29l"
    license:bsd-3
    (list "LICENSE"))
   (go-proxy-module
    "go-browsh-gopkg-in-yaml-v3"
    "gopkg.in/yaml.v3" "v3.0.1"
    "05d0m7qk217jw99jrxc9yiwhrj91iahsw77yda7a03ihwv2gpf5a"
    (list license:asl2.0 license:expat)
    (list "LICENSE" "NOTICE"))))
