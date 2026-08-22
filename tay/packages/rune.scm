;;; GNU Guix package for Rune, a scriptable terminal MUD client.

(define-module (tay packages rune)
  #:use-module (guix build-system go)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages nss))

;; Rune v0.10.1 has a compact, fully pinned Go module graph.  Keep each
;; module source as a source-only Go package so the final build is a single
;; GOPATH compilation with GO111MODULE=off.  This prevents module-proxy or
;; VCS access during a build, while retaining the exact source selected by
;; upstream's go.mod and go.sum.
(define* (go-rune-library name version url commit hash import-path license
                          #:key source-subdir unpack-path)
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
       (sha256 (base32 hash))
       ;; github.com/charmbracelet/x is a monorepo.  Source nodes for its
       ;; independent modules must merge below one GOPATH root without one
       ;; historical revision replacing another module's source directory.
       (modules '((guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-26)))
       (snippet
        (and source-subdir
             #~(begin
                 (use-modules (guix build utils)
                              (ice-9 ftw)
                              (srfi srfi-26))
                 (define (delete-all-but directory . preserve)
                   (with-directory-excursion directory
                     (let* ((pred (negate (cut member <>
                                                (cons* "." ".." preserve))))
                            (items (scandir "." pred)))
                       (for-each delete-file-recursively items))))
                 ;; Retain the upstream notice as well as the module tree.
                 (delete-all-but "." "LICENSE" #$source-subdir))))))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.25
           #:import-path import-path
           #:unpack-path (or unpack-path import-path)
           ;; These nodes are deliberately not compiled independently: their
           ;; complete, exact graph is assembled by the Rune build below.
           #:phases #~(modify-phases %standard-phases
                       (delete 'build)
                       (delete 'check))))
    (synopsis "Go module source for Rune")
    (description
     "This package provides one immutable Go module source node used to build
Rune without network access.")
    (home-page url)
    (license license)))

(define go-rune-charm-land-bubbles-v2
  (go-rune-library
   "go-rune-charm-land-bubbles-v2" "2.1.1"
   "https://github.com/charmbracelet/bubbles"
   "d2b2217d6352ce04183623d66d4266115419733c"
   "1i91gqgqpxvlwca7r633ckvni5y530vild3y75ri75vg4myr2hfb"
   "charm.land/bubbles/v2" license:expat))

(define go-rune-charm-land-bubbletea-v2
  (go-rune-library
   "go-rune-charm-land-bubbletea-v2" "2.0.8"
   "https://github.com/charmbracelet/bubbletea"
   "fc707bb7ea0161405bb6c653ec93f6a9c6a72fe1"
   "1m0mb529gn47vy3j7nm6bx832hvq7sna9q1icl0cgw4r1afs3x0q"
   "charm.land/bubbletea/v2" license:expat))

(define go-rune-charm-land-lipgloss-v2
  (go-rune-library
   "go-rune-charm-land-lipgloss-v2" "2.0.5"
   "https://github.com/charmbracelet/lipgloss"
   "5bd778d050f0a5a130e7cf041917927496dbe722"
   "1wh7z2c6z4dv918qd78in48kp16nbqfgiw71f8fvnfhwm6crdwp0"
   "charm.land/lipgloss/v2" license:expat))

(define go-rune-github-com-atotto-clipboard
  (go-rune-library
   "go-rune-github-com-atotto-clipboard" "0.1.4"
   "https://github.com/atotto/clipboard"
   "e4aee1922c628e6966acd4207c408df132dc6fb5"
   "0ycd8zkgsq9iil9svhlwvhcqwcd7vik73nf8rnyfnn10gpjx97k5"
   "github.com/atotto/clipboard" license:bsd-3))

(define go-rune-github-com-aymanbagabas-go-osc52-v2
  (go-rune-library
   "go-rune-github-com-aymanbagabas-go-osc52-v2" "2.0.1"
   "https://github.com/aymanbagabas/go-osc52"
   "ce73587a0f72cf077e55f163e71ea1b5496a133c"
   "1y4y49zys7fi5wpicpdmjqnk0mb6569zg546km02yck2349jl538"
   "github.com/aymanbagabas/go-osc52/v2" license:expat))

(define go-rune-github-com-charmbracelet-colorprofile
  (go-rune-library
   "go-rune-github-com-charmbracelet-colorprofile" "0.4.3"
   "https://github.com/charmbracelet/colorprofile"
   "d085584efb48f2ad470e96cd0f3dcb8cc68a034b"
   "1gwylpqh0cfzz3pc9xf3z95c4dw11n0pbxaq3j0krw805pfz4j18"
   "github.com/charmbracelet/colorprofile" license:expat))

(define go-rune-github-com-charmbracelet-ultraviolet
  (go-rune-library
   "go-rune-github-com-charmbracelet-ultraviolet"
   "0.0.0-20260703014108-f5a850f9c2b7"
   "https://github.com/charmbracelet/ultraviolet"
   "f5a850f9c2b7ed4def3807fe12d0b5e76d345bdc"
   "0psakkpv8vvvfsf2b9lyvlq9xcmpicky12yxdqrqn1rnmwpm4rki"
   "github.com/charmbracelet/ultraviolet" license:expat))

(define go-rune-github-com-charmbracelet-x-ansi
  (go-rune-library
   "go-rune-github-com-charmbracelet-x-ansi" "0.11.8"
   "https://github.com/charmbracelet/x"
   "00c6608f106b9c6cd8a1a77156f7901f41265e64"
   "00as6gdi03mxjcss7gdfm1x3jkq043k7ld98jplvcz8sfj6vzzfb"
   "github.com/charmbracelet/x/ansi" license:expat
   #:source-subdir "ansi" #:unpack-path "github.com/charmbracelet/x"))

(define go-rune-github-com-charmbracelet-x-term
  (go-rune-library
   "go-rune-github-com-charmbracelet-x-term" "0.2.2"
   "https://github.com/charmbracelet/x"
   "4542a189d0fbeb156bb1df8730d253f2ef443c00"
   "0sriiy8njbnwgn0ydnp3adq70ch489xi5v662c6h3zq1f6b981zy"
   "github.com/charmbracelet/x/term" license:expat
   #:source-subdir "term" #:unpack-path "github.com/charmbracelet/x"))

(define go-rune-github-com-charmbracelet-x-termios
  (go-rune-library
   "go-rune-github-com-charmbracelet-x-termios" "0.1.1"
   "https://github.com/charmbracelet/x"
   "70b8bc4d46effa6f6c6ff1430c0e010f195e394d"
   "059b9kxqlmvfif2xrj8j21ih2476n0aphg5w5ajrf974hl0fy3k1"
   "github.com/charmbracelet/x/termios" license:expat
   #:source-subdir "termios" #:unpack-path "github.com/charmbracelet/x"))

(define go-rune-github-com-charmbracelet-x-windows
  (go-rune-library
   "go-rune-github-com-charmbracelet-x-windows" "0.2.2"
   "https://github.com/charmbracelet/x"
   "83e3a29d542fe292a3bd0a965079ea16a432bcda"
   "01iba6qjgpxw2bik8331s71320vs0zr4x3fnpzkf9vhr91qkm6nv"
   "github.com/charmbracelet/x/windows" license:expat
   #:source-subdir "windows" #:unpack-path "github.com/charmbracelet/x"))

(define go-rune-github-com-clipperhouse-displaywidth
  (go-rune-library
   "go-rune-github-com-clipperhouse-displaywidth" "0.11.0"
   "https://github.com/clipperhouse/displaywidth"
   "b6da6e784d7796398607efa9883b4d9f6e7be509"
   "032f33vf5ign78l9clc3vz1kzirxgalxswm3j6l4nbf46vpp08yz"
   "github.com/clipperhouse/displaywidth" license:expat))

(define go-rune-github-com-clipperhouse-uax29-v2
  (go-rune-library
   "go-rune-github-com-clipperhouse-uax29-v2" "2.7.0"
   "https://github.com/clipperhouse/uax29"
   "b03477d1fbba89df95a6b55da0a222b2e2228610"
   "0p18s46jd4ryqp036cyv4j6ys67706kihw0fj5ym98xf1m2mdsgg"
   "github.com/clipperhouse/uax29/v2" license:expat))

(define go-rune-github-com-lucasb-eyer-go-colorful
  (go-rune-library
   "go-rune-github-com-lucasb-eyer-go-colorful" "1.4.0"
   "https://github.com/lucasb-eyer/go-colorful"
   "960803eeca7760b91ead14a54fabac75e3cfa5d8"
   "1z98jw2hi45fd8aqaap6wdh1dig7lkf9lds7sarb0c44f86cdzcb"
   "github.com/lucasb-eyer/go-colorful" license:expat))

(define go-rune-github-com-mattn-go-runewidth
  (go-rune-library
   "go-rune-github-com-mattn-go-runewidth" "0.0.27"
   "https://github.com/mattn/go-runewidth"
   "f2d8bfeff22a28e1d7157559144dcdcab0255152"
   "0rr1dlwhhj99f30xd0q0680apv5lvkgyh06n6xhgr3m39xx781sd"
   "github.com/mattn/go-runewidth" license:expat))

(define go-rune-github-com-mmcdole-lunar
  (go-rune-library
   "go-rune-github-com-mmcdole-lunar" "0.1.1"
   "https://github.com/mmcdole/lunar"
   "68bc043830e350a227af87ef5265804f555948ba"
   "11pqg2cschy0wkpykkaqzcl67py6148zf9w53hxraa2f4v09mspz"
   "github.com/mmcdole/lunar" license:expat))

(define go-rune-github-com-muesli-cancelreader
  (go-rune-library
   "go-rune-github-com-muesli-cancelreader" "0.2.2"
   "https://github.com/muesli/cancelreader"
   "d11f1e77abf7f8d69d81553ccaaf0b81163541a6"
   "0157mgpk0z45xizrgrz73swhky0d8nyk6fhwb089n1290k7yjhxq"
   "github.com/muesli/cancelreader" license:expat))

(define go-rune-github-com-rivo-uniseg
  (go-rune-library
   "go-rune-github-com-rivo-uniseg" "0.4.7"
   "https://github.com/rivo/uniseg"
   "03509a98a092b522b2ff0de13e53513d18b3b837"
   "0nlcqyvq4vhq3hqhk84h6fp0jbqkjj88kcpcl853yr7sh4sisdxc"
   "github.com/rivo/uniseg" license:expat))

(define go-rune-github-com-xo-terminfo
  (go-rune-library
   "go-rune-github-com-xo-terminfo" "0.0.0-20220910002029-abceb7e1c41e"
   "https://github.com/xo/terminfo"
   "abceb7e1c41eed2857facd9bbdaaa5ff8137d901"
   "0n3b37z76rz3l74mhrvviz66xa8dqwpvc2gb6cyzql5smbcs9y3a"
   "github.com/xo/terminfo" license:expat))

(define go-rune-golang-org-x-sync
  (go-rune-library
   "go-rune-golang-org-x-sync" "0.21.0"
   "https://go.googlesource.com/sync"
   "5071ed6a9f1617117556b66384f765c934de3698"
   "11ix8kkmd7nyarahg3b7j1yp85dgh9cikn3mlva3xbv4pmawyzns"
   "golang.org/x/sync" license:bsd-3))

(define go-rune-golang-org-x-sys
  (go-rune-library
   "go-rune-golang-org-x-sys" "0.46.0"
   "https://go.googlesource.com/sys"
   "d58dcfa8a74514c0ef0fc401259156c5e2fc9ff5"
   "1cxixrd8pr9k0xib1f1d9l6c0wi4qrcbawann70sfk350va7fbyy"
   "golang.org/x/sys" license:bsd-3))

(define-public rune
  (package
    (name "rune")
    (version "0.10.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/mmcdole/rune")
             (commit "a4a172c2d8f3f5d440dbc86e77e8849479482def")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1lkmwfk19d82c6n9vwwbrd732w6d27yxlf03w1ivcssvmmkd15pr"))))
    (build-system go-build-system)
    (arguments
     (list
      #:go go-1.25
      #:import-path "github.com/mmcdole/rune/cmd/rune"
      #:unpack-path "github.com/mmcdole/rune"
      #:phases
      #~(modify-phases %standard-phases
          ;; The release started requiring the then-unreleased 1.26.5 only
          ;; after its source had already remained Go 1.25-compatible.  Guix
          ;; supplies Go 1.25.3; normalize this directive instead of allowing
          ;; the Go tool to download another compiler.
          (add-after 'unpack 'normalize-go-version
            (lambda _
              (substitute* "src/github.com/mmcdole/rune/go.mod"
                (("go 1[.]26[.]5") "go 1.25.0"))
              (substitute* "src/github.com/mmcdole/rune/version/version.go"
                (("var Number = \"0[.]1[.]0-dev\"")
                 (string-append "var Number = \"" #$version "\"")))))
          ;; Exercise the whole application module, rather than merely the
          ;; command entry point selected for installation.
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "go" "test" "github.com/mmcdole/rune/..."))))
          (add-after 'install 'install-documentation-and-notices
            (lambda* (#:key inputs #:allow-other-keys)
              (use-modules (guix build utils)
                           (ice-9 ftw)
                           (srfi srfi-1))
              (let* ((doc (string-append #$output "/share/doc/rune"))
                     (licenses (string-append doc "/licenses"))
                     (source "src/github.com/mmcdole/rune"))
                (mkdir-p doc)
                (mkdir-p licenses)
                (for-each
                 (lambda (file)
                   (when (file-exists? (string-append source "/" file))
                     (install-file (string-append source "/" file) doc)))
                 '("LICENSE" "README.md" "docs/architecture.md"))
                ;; Keep every statically linked module's licensing and
                ;; attribution notice, including generated-code subtrees, in
                ;; a collision-safe package- and source-path-prefixed
                ;; location.  The Charmbracelet/x module snapshots retain
                ;; their root license only under share/doc, so use that as a
                ;; fallback only when the installed source tree has none.
                (for-each
                 (lambda (input)
                   (let ((label (car input))
                         (directory (cdr input)))
                     (when (string-prefix? "go-rune-" label)
                       (let* ((input-src (string-append directory "/src"))
                              (input-doc (string-append directory "/share/doc"))
                              (notice-regexp
                               "(COPYING|LICENSE|NOTICE)([-.][[:alnum:]_-]+)?$")
                              (source-notices
                               (if (file-exists? input-src)
                                   (sort (find-files input-src notice-regexp) string<?)
                                   '())))
                         (define (copy-notice file root group)
                           (let ((target
                                  (string-append licenses "/" label "/" group
                                                 (substring file (string-length root)))))
                             (mkdir-p (dirname target))
                             (copy-file file target)))
                         (for-each (lambda (file)
                                     (copy-notice file input-src "source"))
                                   source-notices)
                         (when (null? source-notices)
                           (when (file-exists? input-doc)
                             (for-each (lambda (file)
                                         (copy-notice file input-doc "share-doc"))
                                       (sort (find-files input-doc notice-regexp)
                                             string<?))))))))
                 inputs)
                ;; uniseg's generated Unicode 15.0.0 property tables refer
                ;; to the Unicode data license but upstream does not ship its
                ;; text beside those tables.  Install the referenced Unicode
                ;; License V3 verbatim so the generated data remains usable
                ;; with its required attribution offline.
                (let ((unicode-license
                       (string-append licenses "/unicode-15.0.0/LICENSE-UNICODE")))
                  (mkdir-p (dirname unicode-license))
                  (call-with-output-file unicode-license
                    (lambda (port)
                      (display
                       (string-append
                        "UNICODE LICENSE V3\n\n"
                        "COPYRIGHT AND PERMISSION NOTICE\n\n"
                        "Copyright © 1991-2023 Unicode, Inc.\n\n"
                        "NOTICE TO USER: Carefully read the "
                        "following legal agreement. BY\n"
                        "DOWNLOADING, INSTALLING, COPYING OR "
                        "OTHERWISE USING DATA FILES, AND/OR\n"
                        "SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, "
                        "AND AGREE TO BE BOUND BY, ALL OF THE\n"
                        "TERMS AND CONDITIONS OF THIS "
                        "AGREEMENT. IF YOU DO NOT AGREE, DO NOT\n"
                        "DOWNLOAD, INSTALL, COPY, DISTRIBUTE "
                        "OR USE THE DATA FILES OR SOFTWARE.\n\n"
                        "Permission is hereby granted, free of "
                        "charge, to any person obtaining a\n"
                        "copy of data files and any associated "
                        "documentation (the \"Data Files\") or\n"
                        "software and any associated "
                        "documentation (the \"Software\") to deal "
                        "in the Data Files or Software without "
                        "restriction, including without "
                        "limitation the rights to use, copy, "
                        "modify, merge, publish, distribute, "
                        "and/or sell copies of the Data Files "
                        "or Software, and to permit persons to "
                        "whom the Data Files or Software are "
                        "furnished to do so, provided that "
                        "either (a) this copyright and permission "
                        "notice appear with all copies of the "
                        "Data Files or Software, or (b) this "
                        "copyright and permission notice appear "
                        "in associated Documentation.\n\n"
                        "THE DATA FILES AND SOFTWARE ARE "
                        "PROVIDED \"AS IS\", WITHOUT WARRANTY "
                        "OF ANY KIND, EXPRESS OR IMPLIED, "
                        "INCLUDING BUT NOT LIMITED TO THE "
                        "WARRANTIES OF MERCHANTABILITY, FITNESS "
                        "FOR A PARTICULAR PURPOSE AND "
                        "NONINFRINGEMENT OF THIRD PARTY RIGHTS.\n\n"
                        "IN NO EVENT SHALL THE COPYRIGHT HOLDER "
                        "OR HOLDERS INCLUDED IN THIS NOTICE BE "
                        "LIABLE FOR ANY CLAIM, OR ANY SPECIAL "
                        "INDIRECT OR CONSEQUENTIAL DAMAGES, OR "
                        "ANY DAMAGES WHATSOEVER RESULTING FROM "
                        "LOSS OF USE, DATA OR PROFITS, WHETHER "
                        "IN AN ACTION OF CONTRACT, NEGLIGENCE "
                        "OR OTHER TORTIOUS ACTION, ARISING OUT "
                        "OF OR IN CONNECTION WITH THE USE OR "
                        "PERFORMANCE OF THE DATA FILES OR "
                        "SOFTWARE.\n\n"
                        "Except as contained in this notice, "
                        "the name of a copyright holder shall "
                        "not be used in advertising or otherwise "
                        "to promote the sale, use or other "
                        "dealings in these Data Files or Software "
                        "without prior written authorization of "
                        "the copyright holder.\n")
                       port)))))))
          ;; Go's crypto/x509 honors SSL_CERT_DIR.  Preserve a useful TLS
          ;; client out of the box without consulting mutable host paths.
          (add-after 'install 'wrap-nss-certificates
            (lambda _
              (wrap-program (string-append #$output "/bin/rune")
                `("SSL_CERT_DIR" =
                  (,(string-append #$nss-certs "/etc/ssl/certs")))))))))
    (inputs
     (list bash-minimal
           go-rune-charm-land-bubbles-v2
           go-rune-charm-land-bubbletea-v2
           go-rune-charm-land-lipgloss-v2
           go-rune-github-com-atotto-clipboard
           go-rune-github-com-aymanbagabas-go-osc52-v2
           go-rune-github-com-charmbracelet-colorprofile
           go-rune-github-com-charmbracelet-ultraviolet
           go-rune-github-com-charmbracelet-x-ansi
           go-rune-github-com-charmbracelet-x-term
           go-rune-github-com-charmbracelet-x-termios
           go-rune-github-com-charmbracelet-x-windows
           go-rune-github-com-clipperhouse-displaywidth
           go-rune-github-com-clipperhouse-uax29-v2
           go-rune-github-com-lucasb-eyer-go-colorful
           go-rune-github-com-mattn-go-runewidth
           go-rune-github-com-mmcdole-lunar
           go-rune-github-com-muesli-cancelreader
           go-rune-github-com-rivo-uniseg
           go-rune-github-com-xo-terminfo
           go-rune-golang-org-x-sync
           go-rune-golang-org-x-sys))
    (synopsis "Scriptable terminal client for MUD servers")
    (description
     "Rune is a terminal MUD client written in Go.  It supports modern Telnet
negotiation, MCCP2 compression, GMCP, TLS, worlds, logging, aliases, triggers,
timers, and a Lua scripting API.  This package uses Rune's pure-Go Lunar Lua
backend; it deliberately does not build the optional cgo LuaJIT variant.  The
complete pinned Go source graph is compiled offline, and user scripts, worlds,
logs, and durable state remain in the selected configuration directory rather
than in the immutable store.")
    (home-page "https://github.com/mmcdole/rune")
    (license license:expat)))
