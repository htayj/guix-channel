;;; GNU Guix package for godisc, a terminal Discworld MUD client.

(define-module (tay packages godisc)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages golang-xyz)
  #:use-module (gnu packages tmux))

;; The original godisc checkout uses github.com/stesla/gotelnet, which is no
;; longer available.  ziutek/telnet provides the same telnet-aware connection
;; type, with the modern net.Conn-compatible Dial signature.
(define-public go-github-com-ziutek-telnet
  (package
    (name "go-github-com-ziutek-telnet")
    (version "0.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ziutek/telnet")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0w0zn8yhpmhrph41dlf9pn5h1zzhgajxwbx85fk4d0m55xp0r680"))))
    (build-system go-build-system)
    (arguments
     (list
      #:tests? #f
      #:import-path "github.com/ziutek/telnet"))
    (home-page "https://github.com/ziutek/telnet")
    (synopsis "telnet protocol library for Go")
    (description
     "This package provides a telnet-aware @code{net.Conn} implementation for
Go programs.  It is used as the maintained replacement for the vanished
@code{stesla/gotelnet} library used by godisc.")
    (license license:bsd-3)))

;; The godisc checkout predates Go modules and imports the v2 API from this
;; repository.  Keep that API version pinned so the cgo wrapper is available
;; without a network fetch during the godisc build.
(define-public go-github-com-essentialkaos-go-linenoise
  (package
    (name "go-github-com-essentialkaos-go-linenoise")
    (version "2.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/essentialkaos/go-linenoise")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1i6y1ygxixhjazpl4hwgm35bmi8gr61v765pv2yyssynvpskw6kz"))))
    (build-system go-build-system)
    (arguments
     (list
      #:tests? #f
      #:import-path "github.com/essentialkaos/go-linenoise"))
    (home-page "https://github.com/essentialkaos/go-linenoise")
    (synopsis "Go bindings for the linenoise line editor")
    (description
     "This package provides Go bindings for the linenoise terminal line
editor.  It is pinned to the v2 API used by godisc.")
    (license license:bsd-2)))

(define-public godisc
  (package
    (name "godisc")
    (version "0-20180125-47a9163")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/DavidSatimeWallin/godisc")
             (commit "47a9163d588faf165f461bd15bf7d7c20bbee092")))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "1cgqvwcfqky8nx45za7m0b56cndv36q26w9qsr8sh7rchn2nj26v"))))
    (build-system go-build-system)
    (arguments
     (list
      #:tests? #f
      #:import-path "github.com/dvwallin/godisc"
      ;; Override the build system's default linker flags so the legacy GOPATH
      ;; graph cannot inject a per-build Go build ID into the executable.
      #:build-flags #~(list "-ldflags=-s -w -buildid=")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-godisc
            (lambda _
              (use-modules (guix build utils))
              (let ((source "src/github.com/dvwallin/godisc/godisc.go"))
                ;; The old import path disappeared, but the author's
                ;; successor keeps the telnet-aware connection behavior.
                (substitute* source
                  (("github.com/stesla/gotelnet")
                   "github.com/ziutek/telnet")
                  (("conn                gotelnet.Conn")
                   "conn                *telnet.Conn")
                  (("gotelnet.Dial\\(hostname\\)")
                   "telnet.Dial(\"tcp\", hostname)")
                  ;; Respect a test or user's HOME instead of the passwd
                  ;; database, and create the complete ~/.config path.
                  (("goDiscCfgDir := usr\\.HomeDir \\+ \"/\\.config/godisc\"")
                   "homeDir := os.Getenv(\"HOME\")
\tif homeDir == \"\" {
\t\thomeDir = usr.HomeDir
\t}
\tgoDiscCfgDir := os.Getenv(\"GODISC_CONFIG_DIR\")
\tif goDiscCfgDir == \"\" {
\t\tgoDiscCfgDir = homeDir + \"/.config/godisc\"
\t}")
                  (("os.Mkdir\\(goDiscCfgDir, 0770\\)")
                   "os.MkdirAll(goDiscCfgDir, 0770)")
                  ;; The HTML cache used to contact the public Discworld web
                  ;; site at every startup.  Keep it for normal use, but make
                  ;; offline operation explicit for local protocol tests.
                  (("\tcacheClubNames\\(\\)")
                   (string-append
                    "\n\tif os.Getenv(\"GODISC_SKIP_WEB_CACHE\") != \"1\" {\n"
                    "\t\tcacheClubNames()\n"
                    "\t}"))
                  ;; The bundled tmux launcher already passed host and port,
                  ;; but the upstream binary ignored them.  Add a useful
                  ;; version/help contract and honor those arguments.
                  (("func main\\(\\) \\{")
                   (string-append
                    "func main() {\n"
                    "\tif len(os.Args) > 1 && os.Args[1] == \"--version\" {\n"
                    "\t\tfmt.Println(\"godisc 0-20180125-47a9163\")\n"
                    "\t\treturn\n"
                    "\t}\n"
                    "\tif len(os.Args) > 1 && os.Args[1] == \"--help\" {\n"
                    "\t\tfmt.Println(\"usage: godisc [HOST PORT]\")\n"
                    "\t\treturn\n"
                    "\t}\n"
                    "\tif len(os.Args) >= 3 {\n"
                    "\t\tport, parseErr := strconv.Atoi(os.Args[2])\n"
                    "\t\tif parseErr != nil {\n"
                    "\t\t\tlog.Fatal(parseErr)\n"
                    "\t\t}\n"
                    "\t\tconnections = []Connection{{Host: os.Args[1], "
                    "Port: port}}\n"
                    "\t}\n"))
                  ;; Permit a noninteractive smoke invocation without
                  ;; changing the normal linenoise input loop.
                  (("go readKeyboardInput\\(conn\\)")
                   "\tif os.Getenv(\"GODISC_NONINTERACTIVE\") != \"1\" {
\t\tgo readKeyboardInput(conn)
\t}") ))))
          (add-after 'install 'install-tmux-launcher
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (source (string-append
                              out "/src/github.com/dvwallin/godisc/"
                              "launch-godisc.sh"))
                     (launcher (string-append out "/bin/godisc-tmux"))
                     (bash (assoc-ref inputs "bash-minimal"))
                     (tmux (assoc-ref inputs "tmux"))
                     (coreutils (assoc-ref inputs "coreutils")))
                (copy-file source launcher)
                (substitute* launcher
                  (("#!/bin/bash")
                   (string-append "#!" bash "/bin/bash"))
                  (("SESSION=[$]USER")
                   "SESSION=${GODISC_TMUX_SESSION:-${USER:-godisc}}")
                  (("CONFDIR=\"/home/[$]SESSION/\\.config/godisc\"")
                   (string-append
                    "CONFDIR=\"${GODISC_CONFIG_DIR:-${HOME:-/tmp}/"
                    ".config/godisc}\""))
                  (("mkdir [$]CONFDIR")
                   "mkdir -p \"$CONFDIR\"")
                  (("tail -f .*tellChat\\.log")
                   "tail -f \\\"$CONFDIR/tellChat.log\\\"")
                  (("tail -f .*xp\\.log")
                   "tail -f \\\"$CONFDIR/xp.log\\\"")
                  (("/usr/local/bin/godisc discworld\\.starturtle\\.net 4242")
                   (string-append
                    "godisc ${GODISC_HOST:-discworld.starturtle.net} "
                    "${GODISC_PORT:-4242}")))
                (chmod launcher #o555)
                (wrap-program launcher
                  `("PATH" ":" prefix
                    (,(string-append out "/bin")
                     ,(string-append tmux "/bin")
                     ,(string-append coreutils "/bin"))))))))))
    (inputs
     (list go-github-com-anaskhan96-soup
           go-github-com-essentialkaos-go-linenoise
           go-github-com-mgutz-ansi
           go-github-com-patrickmn-go-cache
           go-github-com-ziutek-telnet
           bash-minimal
           coreutils
           tmux))
    (synopsis "terminal Discworld MUD client")
    (description
     "godisc is a terminal client for the Discworld MUD written in Go.  It
provides a telnet connection, command aliases, highlighted output, chat and
experience logs, and an optional tmux-oriented launcher.  Mutable profiles
and logs are kept below the user's @file{~/.config/godisc} directory; the
launcher can be directed to a local endpoint with @env{GODISC_HOST} and
@env{GODISC_PORT}.  The source snapshot is pinned to the upstream commit
recorded in this package and the default upstream endpoints are unchanged.")
    (home-page "https://github.com/DavidSatimeWallin/godisc")
    (license license:expat)))
