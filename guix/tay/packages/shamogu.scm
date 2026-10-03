;;; GNU Guix package for Shamogu's native terminal release.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages shamogu)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang))

;; The terminal graph is materialized directly in GOPATH rather than building
;; every dependency's unrelated demos/tests.  These are the exact go.mod
;; versions, including the source-only JS/SDL drivers; no SDL library is linked.
;; tcell's go-sixel/quant are only used by its build-ignored _demos/sixel.go;
;; x/text's tools/mod/sync support its unimported generators, not this game.
(define %shamogu-modules
  (map
   (lambda (row)
     (let ((path (car row)) (version (cadr row)) (hash (caddr row)))
       (list path version
             (origin
               (method url-fetch)
               (uri (string-append "https://proxy.golang.org/" path
                                   "/@v/" version ".zip"))
               (file-name (string-append "shamogu-"
                                        (string-map (lambda (c)
                                                      (if (char=? c #\/) #\- c))
                                                    path)
                                        "-" version ".zip"))
               (sha256 (base32 hash))))))
   '(("codeberg.org/anaseto/gruid" "v0.27.0" "0gw25qkvy9krrd668srmxm4ykb72639spiiv9jd3wfgifznmnv2p")
     ("codeberg.org/anaseto/gruid-js" "v0.5.0" "165xf45lydzk277w4gzw14bd073v88ggdry074nd5k52az85dcw2")
     ("codeberg.org/anaseto/gruid-sdl" "v0.10.1" "1w35yr5zrldd38b6kxs48brf7c3nqam3hc72gf49a0s474zg8vj3")
     ("codeberg.org/anaseto/gruid-tcell" "v0.5.0" "1gwgw31zl06pqyyivcibd4hg92jrxymikysynsnkkxgaglvz96mq")
     ("github.com/gdamore/tcell/v2" "v2.13.5" "054iv3i71by2vqpr7gm5xjzv3d4156jaxkiamcfgk6f1d9hmz61y")
     ("github.com/gdamore/encoding" "v1.0.1" "0cwy6x8prgqbbyfy8344xyi8lqnh00wp1991prasw1ikfhy31175")
     ("github.com/lucasb-eyer/go-colorful" "v1.3.0" "05bwch8izjdjpg8q5hgcy919v7cp9klnnvlm8cdzwbqv1p18lz4w")
     ("github.com/rivo/uniseg" "v0.4.7" "14mpxc93hmg87swy900cwiiykhdqbj9aqf0iqsf7grf11jmf95dr")
     ("golang.org/x/image" "v0.34.0" "01fqq634ism1m57b2cz6v4ylklnsfkvhs6nqr6a7vky1nywx184m")
     ("golang.org/x/sys" "v0.39.0" "06sbml178r9rvbp200n7vvm5ryv93q3c52sqaz28prww57ylwi35")
     ("golang.org/x/term" "v0.38.0" "0qvk64xm7w4dz6zmhy4y4r89ravwbdq8x7pfr4ammfwqmszcikh0")
     ("golang.org/x/text" "v0.32.0" "06zq85wprgyz4mgwz8arqnl5kd3j4giqxm5bhdd65g1pgk9p0v5w"))))

(define-public shamogu
  (package
    (name "shamogu")
    (version "1.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeberg.org/anaseto/shamogu/archive/"
             "fcd439d4d7949dfa4b9d7e513caacc0a82360384.tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0pvax5sc75cvhlv6z0xqdgzgdizs6kpcarslh2bjxh5rz84dh25f"))))
    (build-system go-build-system)
    (arguments
     (list
      #:go go-1.25
      #:import-path "codeberg.org/anaseto/shamogu"
      #:install-source? #f
      #:test-subdirs #~'("")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'unpack-pinned-modules
            (lambda _
              (setenv "GOPROXY" "off")
              (setenv "GOSUMDB" "off")
              (setenv "GOTOOLCHAIN" "local")
              (setenv "CGO_ENABLED" "0")
              (for-each
               (lambda (path version archive)
                 (invoke "unzip" "-q" archive "-d" "module-unpack")
                 (let ((dest (string-append "src/" path)))
                   (mkdir-p dest)
                   (copy-recursively
                    (string-append "module-unpack/" path "@" version) dest))
                 (delete-file-recursively "module-unpack"))
               '#$(map car %shamogu-modules)
               '#$(map cadr %shamogu-modules)
               (list #$@(map caddr %shamogu-modules)))))
          (add-after 'install 'install-documentation
            (lambda _
              (let ((doc (string-append #$output "/share/doc/shamogu"))
                    (source "src/codeberg.org/anaseto/shamogu"))
                (for-each
                 (lambda (file) (install-file (string-append source "/" file) doc))
                 '("LICENSE" "README.md" "CHANGES.md" "go.mod" "go.sum"))
                (for-each
                 (lambda (file)
                   (install-file (string-append source "/tiles/" file)
                                 (string-append doc "/tiles")))
                 '("LICENSE" "README"))
                (install-file (string-append source "/docs/shamogu.6")
                              (string-append #$output "/share/man/man6"))
                ;; Preserve every notice from the pinned source closure,
                ;; including nested gruid-sdl/sdl2/LICENSE and Go PATENTS.
                (for-each
                 (lambda (path)
                   (let ((root (string-append "src/" path)))
                     (for-each
                      (lambda (file)
                        (let ((relative (substring file (+ 1 (string-length root)))))
                          (install-file file
                                        (dirname (string-append doc "/modules/" path
                                                                "/" relative)))))
                      (find-files
                       root "^(LICENSE[^/]*|COPYING[^/]*|NOTICE[^/]*|PATENTS)$"))))
                 '#$(map car %shamogu-modules))))))))
    (native-inputs (list unzip))
    (home-page "https://anaseto.codeberg.page/games/shamogu/")
    (synopsis "Tactical terminal roguelike with totemic spirits")
    (description
     "Shamogu is a coffee-break roguelike with tactical movement, careful timing
of totemic spirit invocation and comestible consumption, and visibility and
noise stealth mechanics.  This package builds the native ASCII terminal game
from the pinned 1.5.0 release, without SDL or browser frontends.  Saves,
configuration and replays follow the upstream XDG data directory convention.")
    (license (list license:isc license:asl2.0 license:expat license:bsd-3))))
