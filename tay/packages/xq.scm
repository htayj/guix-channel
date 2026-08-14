;;; GNU Guix package for sibprogrammer/xq.
;;;
;;; The source is deliberately the already-recorded channel snapshot rather
;;; than a second fetch of upstream.  Guix 1.5's Go build system uses GOPATH
;;; mode, so the complete module graph required by this snapshot is listed as
;;; exact, source-only Go inputs below.

(define-module (tay packages xq)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages starred-s-z))

(define* (xq-go-module name version import-path repository hash
                        #:optional (module-license license:expat))
  "Return a source-only Go module package for XQ's pinned graph.

The package names intentionally start with `go-' because that is how the
Guix Go build system recognizes source inputs when constructing GOPATH.  The
modules are source-only: XQ is the package whose build and tests provide the
actual validation, while every module archive remains independently pinned.
"
  (package
    (name name)
    (version version)
    (source
     (origin
       (method git-fetch)
       (uri
        (git-reference
         (url repository)
         (commit
          (if (go-pseudo-version? version)
              (go-version->git-ref version)
              (string-append "v" version)))))
       (file-name (git-file-name name version))
       (sha256 (base32 hash))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path import-path
      #:skip-build? #t
      #:tests? #f))
    (home-page repository)
    (synopsis (string-append "pinned Go module " import-path))
    (description
     (string-append "This is the exact source of the Go module " import-path
                    " required by the pinned xq dependency graph."))
    (license module-license)))

;; These versions and hashes mirror the go.mod/go.sum in the preserved xq
;; source at e1abbb35e250246385b942d055ba800fe04887d6.  The repository
;; packages in Guix 1.5 either have different versions or, for antchfx, are
;; absent, so using them would silently change the graph.
(define xq-goquery
  (xq-go-module
   "go-xq-puerkitobio-goquery" "1.12.0" "github.com/PuerkitoBio/goquery"
   "https://github.com/PuerkitoBio/goquery"
   "1f7pbz97agsf4sh46grdssvyb36yyh1hy0609agl56c3bw4wvpkh"
   license:bsd-3))

(define xq-cascadia
  (xq-go-module
   "go-xq-andybalholm-cascadia" "1.3.3" "github.com/andybalholm/cascadia"
   "https://github.com/andybalholm/cascadia"
   "00wfdb84mwhnj6h7f4kl5il2kkpsaaankxxiar9b5pij4kx1zybx"
   license:bsd-2))

(define xq-xmlquery
  (xq-go-module
   "go-xq-antchfx-xmlquery" "1.5.1" "github.com/antchfx/xmlquery"
   "https://github.com/antchfx/xmlquery"
   "01z5lcyjq8sq8b5r5c9kzxjhp1zdzgv29q142fjfqfz3ppq5nnkz"))

(define xq-xpath
  (xq-go-module
   "go-xq-antchfx-xpath" "1.3.8" "github.com/antchfx/xpath"
   "https://github.com/antchfx/xpath"
   "12qw3lwxc06fd81ghnk3nr9vv3yzijlq5s7frfddhp837vr2hwv7"))

(define xq-color
  (xq-go-module
   "go-xq-fatih-color" "1.19.0" "github.com/fatih/color"
   "https://github.com/fatih/color"
   "0d9mgydf4f288vzmfqalilq2zfrixrvnifmi6jh2iwwxg3b2c0v2"))

(define xq-cobra
  (xq-go-module
   "go-xq-spf13-cobra" "1.10.2" "github.com/spf13/cobra"
   "https://github.com/spf13/cobra"
   "1scbqfd58kbbkpcj1rqg4dhapfwzzlp1xh5f52ijs243b1645d4x"
   license:asl2.0))

(define xq-pflag
  (xq-go-module
   "go-xq-spf13-pflag" "1.0.10" "github.com/spf13/pflag"
   "https://github.com/spf13/pflag"
   "1sjj0a8x1hshiix12y44kbz5lr1ifdcglvb5d5qyli68q46l3gx6"
   license:bsd-3))

(define xq-testify
  (xq-go-module
   "go-xq-stretchr-testify" "1.11.1" "github.com/stretchr/testify"
   "https://github.com/stretchr/testify"
   "01z104142yrnih9vq3zrhypalh1d3kmyddyapqxgzggvhsw5b6pl"))

(define xq-x-net
  (xq-go-module
   "go-xq-golang-org-x-net" "0.57.0" "golang.org/x/net"
   "https://go.googlesource.com/net"
   "13kdp5m62dlsbh862kdxqxv5mqvyis8kgg3r0h9z319qri83ral0"
   license:bsd-3))

(define xq-x-text
  (xq-go-module
   "go-xq-golang-org-x-text" "0.40.0" "golang.org/x/text"
   "https://go.googlesource.com/text"
   "0ha1bf1anwwdks9xr3f6iw48zi6nhqbryyfxbap3wddz9vkj44n2"
   license:bsd-3))

(define xq-x-sys
  (xq-go-module
   "go-xq-golang-org-x-sys" "0.47.0" "golang.org/x/sys"
   "https://go.googlesource.com/sys"
   "16jnfsdfwwnldkspgnyhi70br0y3ygl8r7wm08yd3s4dff93xpaa"
   license:bsd-3))

(define xq-spew
  (xq-go-module
   "go-xq-davecgh-go-spew" "1.1.2-0.20180830191138-d8f796af33cc"
   "github.com/davecgh/go-spew" "https://github.com/davecgh/go-spew"
   "19z27f306fpsrjdvkzd61w1bdazcdbczjyjck177g33iklinhpvx"
   license:isc))

(define xq-groupcache
  (xq-go-module
   "go-xq-golang-groupcache" "0.0.0-20210331224755-41bb18bfe9da"
   "github.com/golang/groupcache" "https://github.com/golang/groupcache"
   "07amgr8ji4mnq91qbsw2jlcmw6hqiwdf4kzfdrj8c4b05w4knszc"
   license:asl2.0))

(define xq-mousetrap
  (xq-go-module
   "go-xq-inconshreveable-mousetrap" "1.1.0"
   "github.com/inconshreveable/mousetrap"
   "https://github.com/inconshreveable/mousetrap"
   "14gjpvwgx3hmbd92jlwafgibiak2jqp25rq4q50cq89w8wgmhsax"
   license:asl2.0))

(define xq-pretty
  (xq-go-module
   "go-xq-kr-pretty" "0.3.1" "github.com/kr/pretty"
   "https://github.com/kr/pretty"
   "19d4ycy22il43s4pnr7jv1aahp87wa1p16zpis5jdiiyfgni2l8f"))

(define xq-colorable
  (xq-go-module
   "go-xq-mattn-go-colorable" "0.1.14"
   "github.com/mattn/go-colorable" "https://github.com/mattn/go-colorable"
   "0wr5aw9bw6dz7l7asdhhvfxlzlp26ndv47lmlf809bwsbplqyzap"))

(define xq-isatty
  (xq-go-module
   "go-xq-mattn-go-isatty" "0.0.20" "github.com/mattn/go-isatty"
   "https://github.com/mattn/go-isatty"
   "0g63n9wpb991qnq9mn2kvd8jk1glrp6gnd851kvwz2wmzdkggiga"))

(define xq-difflib
  (xq-go-module
   "go-xq-pmezard-go-difflib" "1.0.1-0.20181226105442-5d4384ee4fb2"
   "github.com/pmezard/go-difflib" "https://github.com/pmezard/go-difflib"
   "1pf78vgxs3mbdhhszvsrv0z4l70c7v191g7z2xzxb68xb27hw3jw"
   license:bsd-3))

(define xq-check
  (package
    (name "go-xq-gopkg-in-check-v1")
    (version "1.0.0-20190902080502-41f04d3bba15")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/go-check/check/tar.gz/41f04d3bba152ddec2103e299fed053415705330")
       (file-name "go-check-1.0.0-20190902080502-41f04d3bba15.tar.gz")
       (sha256
        (base32 "08jakgxy9vdfhx1zcpwwv9bjnvdgjwr0vzskjnvbyi7vbp1nidxd"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "gopkg.in/check.v1"
      #:skip-build? #t
      #:tests? #f))
    (home-page "https://github.com/go-check/check")
    (synopsis "pinned gopkg.in/check.v1 module")
    (description
     "This is the exact gopkg.in/check.v1 source required by the pinned xq
dependency graph.")
    (license license:bsd-2)))

(define xq-yaml
  (package
    (name "go-xq-gopkg-in-yaml-v3")
    (version "3.0.1")
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/yaml/go-yaml/tar.gz/refs/tags/v3.0.1")
       (file-name "go-yaml-3.0.1.tar.gz")
       (sha256
        (base32 "16h7592xbxfpq98m8m29607n3wvha035l0n51br1cvz5mr1ajg6c"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "gopkg.in/yaml.v3"
      #:skip-build? #t
      #:tests? #f))
    (home-page "https://github.com/yaml/go-yaml")
    (synopsis "pinned gopkg.in/yaml.v3 module")
    (description
     "This is the exact gopkg.in/yaml.v3 source required by the pinned xq
dependency graph.")
    (license (list license:expat license:asl2.0))))

(define-public xq
  (package
    (name "xq")
    (version (package-version sibprogrammer-xq-source))
    (source (package-source sibprogrammer-xq-source))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/sibprogrammer/xq"
      #:install-source? #f))
    ;; Keep every module listed by go.mod at its pinned version.  The Go
    ;; builder consumes these as GOPATH source inputs and does not contact the
    ;; network during either build or test.
    (inputs
     (list xq-goquery xq-cascadia xq-xmlquery xq-xpath xq-color xq-cobra
           xq-pflag xq-testify xq-x-net xq-x-text xq-x-sys xq-spew
           xq-groupcache xq-mousetrap xq-pretty xq-colorable xq-isatty
           xq-difflib xq-check xq-yaml))
    (synopsis "XML and HTML beautifier and content extractor")
    (description
     "Xq is a command-line XML and HTML beautifier and content extractor.  It
can format documents, select nodes using XPath or CSS selectors, and render
structured output as JSON.")
    (home-page "https://github.com/sibprogrammer/xq")
    (license license:expat)))
