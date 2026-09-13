;;; Exact offline Go module graph for Flag Hack's Charm client.
(define-module (tay packages flaghack-go-sources)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:export (%flaghack-charm-go-modules))

(define* (go-proxy-module name import-path version hash license)
  (package
    (name name)
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://proxy.golang.org/" import-path
                           "/@v/" version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256 (base32 hash))))
    (build-system go-build-system)
    (arguments
     (list #:import-path import-path
           #:phases
           #~(modify-phases %standard-phases
               ;; Proxy ZIPs nest the actual module below its import path.
               (add-after 'unpack 'strip-module-proxy-prefix
                 (lambda _
                   (let* ((dest (string-append "src/" #$import-path))
                          (go-mod (find-files dest "go.mod"))
                          (root (and (pair? go-mod) (dirname (car go-mod)))))
                     (when (and root (not (string=? root dest)))
                       (let ((temporary "flaghack-go-module-source"))
                         (copy-recursively root temporary)
                         (delete-file-recursively dest)
                         (mkdir-p dest)
                         (copy-recursively temporary dest))))))
               (delete 'build)
               (delete 'check))))
    (native-inputs (list unzip))
    (synopsis "Source-only Go module for Flag Hack")
    (description "This source-only Go package is an immutable member of the
offline Flag Hack Charm client build graph.")
    (home-page (string-append "https://pkg.go.dev/" import-path))
    (license license)))

(define %flaghack-charm-go-modules
  (list
   (go-proxy-module "go-flaghack-go-osc52" "github.com/aymanbagabas/go-osc52/v2" "v2.0.1" "1y17m5wpinn32ri5aq59a3cvdxdf0n6k232y38p1gwl1ahmbz7lk" license:expat)
   (go-proxy-module "go-flaghack-bubbletea" "github.com/charmbracelet/bubbletea" "v1.3.10" "05vinb0rcqlrjz2q6n76fvammw7x30rzs9ilmjq7i26i25655z4a" license:expat)
   (go-proxy-module "go-flaghack-colorprofile" "github.com/charmbracelet/colorprofile" "v0.2.3-0.20250311203215-f60798e515dc" "0bgwpws6k1cb3h3pmkf4miskhkpllhig4k262yf4zcpamg1r7w4d" license:expat)
   (go-proxy-module "go-flaghack-lipgloss" "github.com/charmbracelet/lipgloss" "v1.1.0" "06h6kgg0n901558i04ymdn7qv6zdiq0xhmvgpdaj4c0iqbc2yl92" license:expat)
   (go-proxy-module "go-flaghack-x-ansi" "github.com/charmbracelet/x/ansi" "v0.10.1" "1yc41x7ppf3ksncdbh8kjnx2v6f2rn7zm34d7jpiaknqlbnq88jp" license:expat)
   (go-proxy-module "go-flaghack-x-cellbuf" "github.com/charmbracelet/x/cellbuf" "v0.0.13-0.20250311204145-2c3ea96c31dd" "0m56zlwwvfqvpjdqfn54r7mp9z2llgidi0hr5s96wwlblryp7cxg" license:expat)
   (go-proxy-module "go-flaghack-x-term" "github.com/charmbracelet/x/term" "v0.2.1" "180l80fv7m5ncm2zh5bray3gfzg4nlgb5jazs5w6915bmhascgll" license:expat)
   (go-proxy-module "go-flaghack-go-colorful" "github.com/lucasb-eyer/go-colorful" "v1.2.0" "046s390w7ir88g29v2k6saz73j6q8yldzdkpxnxm83vzfghd1mbq" license:expat)
   (go-proxy-module "go-flaghack-go-isatty" "github.com/mattn/go-isatty" "v0.0.20" "1k5qnz87rda15ii67ajyrg7cw3hdvjbbb6sb8qbpwmsiljfgimgj" license:expat)
   (go-proxy-module "go-flaghack-go-runewidth" "github.com/mattn/go-runewidth" "v0.0.16" "1jnvrsqcrram7d1bf32dfg5nmgm36w10v9pdzdh3bvkn1j82v78p" license:expat)
   (go-proxy-module "go-flaghack-muesli-ansi" "github.com/muesli/ansi" "v0.0.0-20230316100256-276c6243b2f6" "1fcibz16zwxjbq5ljpycizab9gs2przk640mf0ydylcdj0hd9h2r" license:expat)
   (go-proxy-module "go-flaghack-cancelreader" "github.com/muesli/cancelreader" "v0.2.2" "0qbzmki7clihjfxgaidwmjm6b2mh1smcqx8ay4pv0jcaixzlwrgh" license:expat)
   (go-proxy-module "go-flaghack-termenv" "github.com/muesli/termenv" "v0.16.0" "1z60qmagxscw08b80vhrclvin057c6xz5c9k44n7xn61v7mx60ms" license:expat)
   (go-proxy-module "go-flaghack-uniseg" "github.com/rivo/uniseg" "v0.4.7" "14mpxc93hmg87swy900cwiiykhdqbj9aqf0iqsf7grf11jmf95dr" license:expat)
   (go-proxy-module "go-flaghack-terminfo" "github.com/xo/terminfo" "v0.0.0-20220910002029-abceb7e1c41e" "1kx4bwn3nxqx7dcr4f3zxil44sh4d63idzidjdg173p0j40jgx5q" license:expat)
   (go-proxy-module "go-flaghack-x-sys" "golang.org/x/sys" "v0.36.0" "1i199ddb5fmgm70rzgpal1acaxcd3gcds0127p6na4hrisjfjkl9" license:bsd-3)))
