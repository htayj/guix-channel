;;; FarmingRL -- unchanged browser game with a store-pinned browser launcher.

(define-module (tay packages farmingrl)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages chromium)
  #:use-module (gnu packages fonts))

(define-public farmingrl
  (let ((commit "5f4e722644d1fe266aae4a015cc366e7e1dec6f4")
        (revision "0"))
    (package
      (name "farmingrl")
      ;; The archived upstream repository has no tagged releases.
      (version (git-version "0.0.0" revision commit))
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://codeload.github.com/horaguchi/FarmingRL/tar.gz/"
               commit))
         (file-name (string-append name "-" version ".tar.gz"))
         (sha256
          (base32 "1qj8v0ph9cxnpr17gnlmpgh3i1qlzjxkagqjh6hrp6h0lr47hbbh"))))
      (build-system copy-build-system)
      (arguments
       (list
        ;; These are all five upstream files, copied without rewriting them.
        #:install-plan
        #~'(("index.html" "share/farmingrl/")
            ("game.js" "share/farmingrl/")
            ("rot.js" "share/farmingrl/")
            ("LICENSE" "share/doc/farmingrl/")
            ("README.md" "share/doc/farmingrl/"))
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'install 'install-launcher
              (lambda _
                (let* ((bin (string-append #$output "/bin"))
                       (launcher (string-append bin "/farmingrl"))
                       (fonts (string-append #$output
                                             "/share/farmingrl/fonts.conf")))
                  ;; The game's default monospace face remains available in a
                  ;; fresh profile without depending on host font discovery.
                  (call-with-output-file fonts
                    (lambda (port)
                      (format port
                              (string-append
                               "<?xml version=\"1.0\"?>\n<fontconfig>\n"
                               "  <dir>~a/share/fonts/truetype</dir>\n"
                               "  <cachedir prefix=\"xdg\">fontconfig</cachedir>\n"
                               "  <alias><family>monospace</family><prefer>"
                               "<family>DejaVu Sans Mono</family>"
                               "</prefer></alias>\n</fontconfig>\n")
                              #$font-dejavu)))
                  (mkdir-p bin)
                  (call-with-output-file launcher
                    (lambda (port)
                      (format port "#!~a~%set -eu~%umask 077~%"
                              #$(file-append bash-minimal "/bin/sh"))
                      ;; XDG base directories must be absolute; ignore relative
                      ;; settings and use the standard HOME fallback instead.
                      (display
                       (string-append
                        "case \"${XDG_DATA_HOME:-}\" in\n"
                        "  /*) data=$XDG_DATA_HOME/farmingrl ;;\n"
                        "  *) data=${HOME:?HOME must be set}/.local/share/farmingrl ;;\n"
                        "esac\n"
                        "case \"${XDG_CONFIG_HOME:-}\" in\n"
                        "  /*) config=$XDG_CONFIG_HOME/farmingrl ;;\n"
                        "  *) config=${HOME:?HOME must be set}/.config/farmingrl ;;\n"
                        "esac\n"
                        "case \"${XDG_CACHE_HOME:-}\" in\n"
                        "  /*) cache=$XDG_CACHE_HOME/farmingrl ;;\n"
                        "  *) cache=${HOME:?HOME must be set}/.cache/farmingrl ;;\n"
                        "esac\n"
                        "case $data:$config:$cache in\n"
                        "  /*:/*:/*) ;;\n"
                        "  *) echo 'farmingrl: HOME fallback must be absolute'"
                        " >&2; exit 1 ;;\n"
                        "esac\n"
                        "export XDG_DATA_HOME=\"$data\" XDG_CONFIG_HOME=\"$config\"\n"
                        "export XDG_CACHE_HOME=\"$cache\"\n")
                       port)
                      (format port
                              (string-append
                               "~a -p -- \"$data/chromium\" \"$config\""
                               " \"$cache/chromium\"~%")
                              #$(file-append coreutils-minimal "/bin/mkdir"))
                      (format port "export FONTCONFIG_FILE=~s~%" fonts)
                      (format port
                              (string-append
                               "exec ~a --user-data-dir=\"$data/chromium\""
                               " --disk-cache-dir=\"$cache/chromium\""
                               " --app=\"file://~a/share/farmingrl/index.html\""
                               " \"$@\"~%")
                              #$(file-append ungoogled-chromium "/bin/chromium")
                              #$output)))
                  (chmod launcher #o555)))))))
      (inputs (list bash-minimal coreutils-minimal ungoogled-chromium font-dejavu))
      (home-page "https://github.com/horaguchi/FarmingRL")
      (synopsis "Browser roguelike with farming and automatic combat")
      (description
       "FarmingRL is a browser roguelike in which movement, farming and
repeated battles develop the player character.  This package installs the
unchanged upstream HTML, JavaScript and bundled rot.js, and opens the local
game in a dedicated Ungoogled Chromium application window.  No server or
runtime downloads are needed.  The browser profile resides below
@file{$XDG_DATA_HOME/farmingrl}, with configuration and cache below
@file{$XDG_CONFIG_HOME/farmingrl} and @file{$XDG_CACHE_HOME/farmingrl}; unset
or relative XDG directories use the standard absolute HOME fallbacks.
Additional command-line options are passed to the pinned browser.  The full
upstream license notices and README are installed in
@file{share/doc/farmingrl}.")
      ;; LICENSE includes Koji Horaguchi's Expat notice and the complete
      ;; three-clause BSD notice for Ondrej Zara's bundled rot.js.
      (license (list license:expat license:bsd-3)))))
