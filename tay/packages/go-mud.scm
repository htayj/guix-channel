;;; GNU Guix package for GoMud, a UTF-8 terminal MUD client.

(define-module (tay packages go-mud)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang-xyz))

;; These three modules are not currently in the Guix package collection.  Keep
;; their complete, immutable source trees in the Go workspace rather than
;; allowing the Go command to consult a module proxy during the build.
(define (go-library name version url commit hash import-path dependencies
                    synopsis description homepage license)
  (package
    (name name)
    (version version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url url)
             (commit commit)))
       (file-name (git-file-name name version))
       (sha256 (base32 hash))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path import-path
      ;; These are immutable source nodes for GoMud's one, fully pinned
      ;; GOPATH graph.  The final package compiles the graph together; do not
      ;; compile a node against a different partial graph first.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (delete 'check))))
    (propagated-inputs dependencies)
    (synopsis synopsis)
    (description description)
    (home-page homepage)
    (license license)))

(define-public go-github-com-flw-cn-printer
  (go-library
   "go-github-com-flw-cn-printer"
   "0.0.0-20190906044932-ecdb12812e08"
   "https://github.com/flw-cn/printer"
   "ecdb12812e0837100da0934dedca3dd39039864d"
   "18iqca2bkypp468ph50awz1dhlyvjk975qmr3d4nwfq3zp0dyfah"
   "github.com/flw-cn/printer"
   '()
   "Go printer interfaces"
   "This package provides small printer and write-printer interfaces used by
Go terminal applications."
   "https://github.com/flw-cn/printer"
   license:gpl3))

;; GoMud and its pinned tview fork use the pre-uniseg API exposed by this
;; release.  The current Guix package is 0.0.16, whose API removed
;; @code{ZeroWidthJoiner}; keep the historical module source separate so the
;; complete GOPATH graph matches the upstream v0.6.6 module selection.
(define-public go-github-com-mattn-go-runewidth-0.0.4
  (go-library
   "go-github-com-mattn-go-runewidth-0.0.4"
   "0.0.4"
   "https://github.com/mattn/go-runewidth"
   "3ee7d812e62a0804a7d0a324e0249ca2db3476d3"
   "00b3ssm7wiqln3k54z2wcnxr3k3c7m1ybyhb9h8ixzbzspld0qzs"
   "github.com/mattn/go-runewidth"
   '()
   "rune-width implementation for Go"
   "This package provides the historical rune-width API required by the
pinned GoMud terminal interface."
   "https://github.com/mattn/go-runewidth"
   license:expat))

;; These sources are Go 1.13's selected production module graph for GoMud
;; v0.6.6 (resolved with its go.mod and replacement).  They are intentionally
;; source-only packages: go-build-system assembles them in one GOPATH for the
;; final, network-isolated compile.
(define go-github-com-fsnotify-fsnotify-1.4.7
  (go-library "go-github-com-fsnotify-fsnotify-1.4.7" "1.4.7"
              "https://github.com/fsnotify/fsnotify" "c2828203cd70a50dcccfb2761f8b1f8ceef9a8e9"
              "07va9crci0ijlivbb7q57d2rz9h27zgn2fsm60spjsqpdbvyrx4g" "github.com/fsnotify/fsnotify" '()
              "file-system notification library" "This package provides file-system notifications for Go." "https://github.com/fsnotify/fsnotify" license:bsd-3))
(define go-github-com-gdamore-encoding-1.0.0
  (go-library "go-github-com-gdamore-encoding-1.0.0" "1.0.0"
              "https://github.com/gdamore/encoding" "6289cdc94c00ac4aa177771c5fce7af2f96b626d"
              "1vmm5zll92i2fm4ajqx0gyx0p9j36496x5nabi3y0x7h0inv0pk9" "github.com/gdamore/encoding" '()
              "Go character encoding library" "This package provides character encodings for Go." "https://github.com/gdamore/encoding" license:asl2.0))
(define go-github-com-gdamore-tcell-1.3.0
  (go-library "go-github-com-gdamore-tcell-1.3.0" "1.3.0"
              "https://github.com/gdamore/tcell" "4d152cc2622d491e1b0a034c3211b9df28c0ba2d"
              "1csg9qkmbg4ksj5247kgqcy7bxvqgz6b98r0rv2s4c1mkc99gx2r" "github.com/gdamore/tcell" '()
              "cell-based terminal library" "This package provides portable terminal cell handling for Go." "https://github.com/gdamore/tcell" license:asl2.0))
(define go-github-com-hashicorp-hcl-1.0.0
  (go-library "go-github-com-hashicorp-hcl-1.0.0" "1.0.0"
              "https://github.com/hashicorp/hcl" "8cb6e5b959231cc1119e43259c4a608f9c51a241"
              "0q6ml0qqs0yil76mpn4mdx4lp94id8vbv575qm60jzl1ijcl5i66" "github.com/hashicorp/hcl" '()
              "HashiCorp configuration language parser" "This package provides a parser for the HashiCorp configuration language." "https://github.com/hashicorp/hcl" license:mpl2.0))
(define go-github-com-lucasb-eyer-go-colorful-1.0.2
  (go-library "go-github-com-lucasb-eyer-go-colorful-1.0.2" "1.0.2"
              "https://github.com/lucasb-eyer/go-colorful" "30298f24079860c4dee452fdef6519b362a4a026"
              "0fig06880bvk1l92j4127v4x9sar4ds7ga8959gxxghb2w70b7l2" "github.com/lucasb-eyer/go-colorful" '()
              "color manipulation library" "This package provides color manipulation routines for Go." "https://github.com/lucasb-eyer/go-colorful" license:expat))
(define go-github-com-magiconair-properties-1.8.1
  (go-library "go-github-com-magiconair-properties-1.8.1" "1.8.1"
              "https://github.com/magiconair/properties" "de8848e004dd33dc07a2947b3d76f618a7fc7ef1"
              "19zqw1x0w0crh8zc84yy82nkcc5yjz72gviaf2xjgfm5a8np7nyb" "github.com/magiconair/properties" '()
              "Java properties parser" "This package provides a Java properties parser for Go." "https://github.com/magiconair/properties" license:bsd-2))
(define go-github-com-mitchellh-mapstructure-1.1.2
  (go-library "go-github-com-mitchellh-mapstructure-1.1.2" "1.1.2"
              "https://github.com/mitchellh/mapstructure" "3536a929edddb9a5b34bd6861dc4a9647cb459fe"
              "03bpv28jz9zhn4947saqwi328ydj7f6g6pf1m2d4m5zdh5jlfkrr" "github.com/mitchellh/mapstructure" '()
              "Go map decoder" "This package decodes generic Go maps into native structures." "https://github.com/mitchellh/mapstructure" license:expat))
(define go-github-com-pelletier-go-toml-1.6.0
  (go-library "go-github-com-pelletier-go-toml-1.6.0" "1.6.0"
              "https://github.com/pelletier/go-toml" "903d9455db9ff1d7ac1ab199062eca7266dd11a3"
              "0l2830pi64fg0bdsyd5afkbw0p7879pppzdqqk3c7vjrjfmi5xbq" "github.com/pelletier/go-toml" '()
              "TOML parser for Go" "This package provides TOML support for Go." "https://github.com/pelletier/go-toml" license:expat))
(define go-github-com-rivo-uniseg-0.1.0
  (go-library "go-github-com-rivo-uniseg-0.1.0" "0.1.0"
              "https://github.com/rivo/uniseg" "f8f8f751c732fdcd5e158c13c28f8863ad80e9a5"
              "0flpc1px1l6b1lxzhdxi0mvpkkjchppvgxshxxnlmm40s76i9ww5" "github.com/rivo/uniseg" '()
              "Unicode segmentation library" "This package provides Unicode text segmentation for Go." "https://github.com/rivo/uniseg" license:expat))
(define go-github-com-spf13-afero-1.2.2
  (go-library "go-github-com-spf13-afero-1.2.2" "1.2.2"
              "https://github.com/spf13/afero" "588a75ec4f32903aa5e39a2619ba6a4631e28424"
              "0j9r65qgd58324m85lkl49vk9dgwd62g7dwvkfcm3k6i9dc555a9" "github.com/spf13/afero" '()
              "file-system abstraction library" "This package provides file-system abstractions for Go." "https://github.com/spf13/afero" license:asl2.0))
(define go-github-com-spf13-cast-1.3.1
  (go-library "go-github-com-spf13-cast-1.3.1" "1.3.1"
              "https://github.com/spf13/cast" "1ffadf551085444af981432dd0f6d1160c11ec64"
              "0lb84788glr0qzrq2ifi36rgvp96qrgywvxrr3ggq5hrbr38hgn1" "github.com/spf13/cast" '()
              "Go type conversion library" "This package provides type conversion helpers for Go." "https://github.com/spf13/cast" license:expat))
(define go-github-com-spf13-cobra-0.0.5
  (go-library "go-github-com-spf13-cobra-0.0.5" "0.0.5"
              "https://github.com/spf13/cobra" "f2b07da1e2c38d5f12845a4f607e2e1018cbb1f5"
              "0z4x8js65mhwg1gf6sa865pdxfgn45c3av9xlcc1l3xjvcnx32v2" "github.com/spf13/cobra" '()
              "Go command-line framework" "This package provides command-line applications for Go." "https://github.com/spf13/cobra" license:asl2.0))
(define go-github-com-spf13-jwalterweatherman-1.1.0
  (go-library "go-github-com-spf13-jwalterweatherman-1.1.0" "1.1.0"
              "https://github.com/spf13/jwalterweatherman" "94f6ae3ed3bceceafa716478c5fbf8d29ca601a1"
              "1ywmkwci5zyd88ijym6f30fj5c0k2yayxarkmnazf5ybljv50q7b" "github.com/spf13/jwalterweatherman" '()
              "Go logging library" "This package provides logging helpers for Go." "https://github.com/spf13/jwalterweatherman" license:expat))
(define go-github-com-spf13-pflag-1.0.5
  (go-library "go-github-com-spf13-pflag-1.0.5" "1.0.5"
              "https://github.com/spf13/pflag" "2e9d26c8c37aae03e3f9d4e90b7116f5accb7cab"
              "0gpmacngd0gpslnbkzi263f5ishigzgh6pbdv9hp092rnjl4nd31" "github.com/spf13/pflag" '()
              "POSIX-style flag library" "This package provides POSIX-style flags for Go." "https://github.com/spf13/pflag" license:bsd-3))
(define go-github-com-spf13-viper-1.6.2
  (go-library "go-github-com-spf13-viper-1.6.2" "1.6.2"
              "https://github.com/spf13/viper" "4525543ce4fe90f7970f5e2cdc300b8ffc8c0582"
              "15ahhsrq2i2l7f5zhm4lqqkkq1gw4c9iq4xs4a1d6jbsplw25f5p" "github.com/spf13/viper" '()
              "Go configuration library" "This package provides configuration support for Go." "https://github.com/spf13/viper" license:expat))
(define go-github-com-subosito-gotenv-1.2.0
  (go-library "go-github-com-subosito-gotenv-1.2.0" "1.2.0"
              "https://github.com/subosito/gotenv" "2ef7124db659d49edac6aa459693a15ae36c671a"
              "0mav91j7r4arjkpq5zcf9j74f6pww8ic53x43wy7kg3ibw31yjs5" "github.com/subosito/gotenv" '()
              "environment-file loader" "This package loads environment files for Go." "https://github.com/subosito/gotenv" license:expat))
(define go-golang-org-x-sys-20200124
  (go-library "go-golang-org-x-sys-20200124" "0.0.0-20200124204421-9fbb57f87de9"
              "https://go.googlesource.com/sys" "9fbb57f87de9ccfe3a99d4e3270ce8a926ebba4f"
              "0qaz2jjkrxzgkapmjqingdwamrgq2aiblxvzzgrcsv2qhkj0wdps" "golang.org/x/sys" '()
              "low-level system interfaces" "This package provides low-level system interfaces for Go." "https://pkg.go.dev/golang.org/x/sys" license:bsd-3))
(define go-golang-org-x-text-0.3.2
  (go-library "go-golang-org-x-text-0.3.2" "0.3.2"
              "https://go.googlesource.com/text" "342b2e1fbaa52c93f31447ad2c6abc048c63e475"
              "0flv9idw0jm5nm8lx25xqanbkqgfiym6619w575p7nrdh0riqwqh" "golang.org/x/text" '()
              "text-processing library" "This package provides text processing for Go." "https://pkg.go.dev/golang.org/x/text" license:bsd-3))
(define go-gopkg-in-ini-v1-1.51.1
  (go-library "go-gopkg-in-ini-v1-1.51.1" "1.51.1"
              "https://github.com/go-ini/ini" "94291fffe2b14f4632ec0e67c1bfecfc1287a168"
              "08rjm2vzglr6afliprjsdaa2i7dwx0dlgkpp2z8ca6ynszi14v8g" "gopkg.in/ini.v1" '()
              "INI parser for Go" "This package provides INI parsing for Go." "https://github.com/go-ini/ini" license:asl2.0))
(define go-gopkg-in-yaml-v2-2.2.8
  (go-library "go-gopkg-in-yaml-v2-2.2.8" "2.2.8"
              "https://github.com/go-yaml/yaml" "53403b58ad1b561927d19068c655246f2db79d48"
              "1inf7svydzscwv9fcjd2rm61a4xjk6jkswknybmns2n58shimapw" "gopkg.in/yaml.v2" '()
              "YAML parser for Go" "This package provides YAML support for Go." "https://github.com/go-yaml/yaml" (list license:asl2.0 license:expat)))

;; The historical pseudo-version is no longer reachable as a Git object from
;; the upstream repository.  The Go module proxy's immutable version archive
;; is therefore the authoritative available source for this selected module.
(define go-github-com-yuin-gopher-lua-20190514
  (package
    (name "go-github-com-yuin-gopher-lua-20190514")
    (version "0.0.0-20190514113301-1cd887cd7036")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://proxy.golang.org/github.com/yuin/gopher-lua/@v/v"
                           version ".zip"))
       (sha256
        (base32 "19vs5a9q0h1wmspx8carn9b2li2bzk3gbvpc6x4c8dn34rfps5gx"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/yuin/gopher-lua"
           #:phases
           #~(modify-phases %standard-phases
               ;; Module-proxy ZIP files are rooted at
               ;; github.com/yuin/gopher-lua@VERSION, unlike a usual Git
               ;; archive.  Place that one root at its GOPATH import path.
               (add-after 'unpack 'strip-module-proxy-prefix
                 (lambda _
                   (let* ((dest "src/github.com/yuin/gopher-lua")
                          (nested (string-append dest
                                                 "/yuin/gopher-lua@v"
                                                 #$version))
                          (temporary "gopher-lua-source"))
                     (copy-recursively nested temporary)
                     (delete-file-recursively dest)
                     (mkdir-p dest)
                     (copy-recursively temporary dest))))
               (delete 'build)
               (delete 'check))))
    (native-inputs (list unzip))
    (synopsis "Lua VM and compiler in Go")
    (description "This package provides the historical Lua VM and compiler
selected by GoMud v0.6.6.")
    (home-page "https://github.com/yuin/gopher-lua")
    (license license:expat)))

(define-public go-github-com-flw-cn-go-smartconfig
  (go-library
   "go-github-com-flw-cn-go-smartconfig"
   "1.1.3"
   "https://github.com/flw-cn/go-smartConfig"
   "5d1a58800b761c5924d0ae954c1a4cb652853d4c"
   "0j38k2437zjssqv8nd8a6xx8q8x8rfjqw8y2rj6h4gqys9sgrs50"
   "github.com/flw-cn/go-smartConfig"
   '()
   "zero-configuration Go configuration loader"
   "This package provides command-line and configuration-file loading for Go
programs using struct tags."
   "https://github.com/flw-cn/go-smartConfig"
   license:gpl3))

(define-public go-github-com-dzpao-tview
  (go-library
   "go-github-com-dzpao-tview"
   "0.0.0-20200122091015-7e3eb050fe6b"
   "https://github.com/dzpao/tview"
   "7e3eb050fe6bb2140b852c51f0d7aba83e08c782"
   "06bydss9jws5dmdvvqk7gc1irl4y8yvnmcy4ka9vx4v28wrgbwqj"
   "github.com/rivo/tview"
   '()
   "rich terminal widgets for Go"
   "This package provides terminal widgets and text views for Go programs.
It is the historical tview fork required by GoMud's pinned source release."
   "https://github.com/dzpao/tview"
   license:expat))

(define-public go-mud
  (package
    (name "go-mud")
    (version "0.6.6")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/mudclient/go-mud")
             ;; The release contains a gitlink to a now-unavailable optional
             ;; Lua-robot repository.  Do not recursively fetch an
             ;; unavailable repository or make the build depend on it.
             (commit "4116008fef3cc961e9e251af89ecf2769015351c")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "02gslcw1mw1a2rx97xnrkz0yfkw1avx1kxb611w20v8ma8ddsym3"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/mudclient/go-mud"
      ;; The upstream generator records the checkout, hostname, clock, and
      ;; local Go version.  Generate equivalent version data with fixed values
      ;; so repeated Guix builds have identical inputs and --version output.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'generate-version
            (lambda _
              (use-modules (guix build utils))
              (let ((file
                     "src/github.com/mudclient/go-mud/app/version.go"))
                (mkdir-p (dirname file))
                (call-with-output-file file
                  (lambda (port)
                    (display
                     (string-append
                      "// Generated by the Guix package definition.\n"
                      "package app\n\n"
                      "var Contributors = []struct {\n"
                      "\tName string\n\tLines int\n}{}\n\n"
                      "var (\n"
                      "\tAppName = \"GoMud\"\n"
                      "\tVersion = \"v" #$version "\"\n"
                      "\tBuildTime = \"1970-01-01 00:00:00 UTC\"\n"
                      "\tBuildGoVersion = \"Guix\"\n"
                      "\tBuildHost = \"reproducible\"\n"
                      ")\n")
                     port))))))
          (add-after 'install 'install-documentation
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils)
                           (ice-9 ftw)
                           (srfi srfi-1))
              (let* ((doc (string-append #$output "/share/doc/go-mud"))
                     (source
                      "src/github.com/mudclient/go-mud")
                     (licenses (string-append doc "/licenses")))
                (mkdir-p doc)
                (mkdir-p licenses)
                (for-each
                 (lambda (file)
                   (when (file-exists? (string-append source "/" file))
                     (install-file (string-append source "/" file) doc)))
                 '("LICENSE" "README.md" "config-example.json"
                   "config-example.yaml"))
                ;; Keep notices for the Go libraries statically linked into
                ;; the executable.  This scans only Go input outputs and
                ;; gives each notice a stable package-prefixed name.
                (for-each
                 (lambda (input)
                   (let* ((label (car input))
                          (directory (cdr input)))
                     (when (string-prefix? "go-" label)
                       ;; Go packages install their notices below share/doc;
                       ;; scanning that location avoids seeing the same notice
                       ;; both there and in the installed source tree.
                       (let ((input-doc (string-append directory "/share/doc")))
                         (when (file-exists? input-doc)
                           (for-each
                            (lambda (file)
                              (let ((target
                                     (string-append licenses "/" label "-"
                                                    (basename file))))
                                (install-file file target)))
                            (sort
                             (find-files input-doc
                                         "(COPYING|LICENSE)([.][[:alnum:]-]+)?$")
                             string<?)))))))
                 inputs)))))))
    (inputs
     (list go-github-com-dzpao-tview
           go-github-com-flw-cn-go-smartconfig
           go-github-com-flw-cn-printer
           go-github-com-fsnotify-fsnotify-1.4.7
           go-github-com-gdamore-encoding-1.0.0
           go-github-com-gdamore-tcell-1.3.0
           go-github-com-hashicorp-hcl-1.0.0
           go-github-com-lucasb-eyer-go-colorful-1.0.2
           go-github-com-magiconair-properties-1.8.1
           go-github-com-mattn-go-runewidth-0.0.4
           go-github-com-mitchellh-mapstructure-1.1.2
           go-github-com-pelletier-go-toml-1.6.0
           go-github-com-rivo-uniseg-0.1.0
           go-github-com-spf13-afero-1.2.2
           go-github-com-spf13-cast-1.3.1
           go-github-com-spf13-cobra-0.0.5
           go-github-com-spf13-jwalterweatherman-1.1.0
           go-github-com-spf13-pflag-1.0.5
           go-github-com-spf13-viper-1.6.2
           go-github-com-subosito-gotenv-1.2.0
           go-github-com-yuin-gopher-lua-20190514
           go-golang-org-x-sys-20200124
           go-golang-org-x-text-0.3.2
           go-gopkg-in-ini-v1-1.51.1
           go-gopkg-in-yaml-v2-2.2.8))
    (synopsis "UTF-8 terminal client for text-based MUD servers")
    (description
     "GoMud is a terminal MUD client written in Go and oriented toward
Chinese-language, UTF-8 text-based games.  It supports Telnet negotiation,
multiple Chinese character encodings, Lua scripting, and terminal widgets.
This package builds the pinned v0.6.6 source release without network access,
ships the upstream examples and license notices, and leaves profiles, logs,
maps, and Lua scripts in caller-selected directories outside the store.  It is
a terminal application rather than a graphical desktop application.")
    (home-page "https://github.com/mudclient/go-mud")
    (license license:gpl3)))
