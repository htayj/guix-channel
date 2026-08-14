;;; Public project source snapshots published by htayj.

(define-module (tay packages projects)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:export (%public-project-source-packages))

(define %no-permission-license
  (license:non-copyleft "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define* (make-project-source repo
                              package-name
                              version
                              commit
                              hash
                              synopsis
                              project-license
                              #:key (recursive? #f))
  (let ((destination (string-append "share/htayj/projects/" repo)))
    (package
      (name package-name)
      (version version)
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url (string-append "https://github.com/htayj/" repo))
               (commit commit)
               (recursive? recursive?)))
         (file-name (git-file-name package-name version))
         (sha256
          (base32 hash))))
      (build-system copy-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            ;; Preserve the repository bytes.  These normal application
            ;; phases would otherwise rewrite source scripts or artifacts.
            (delete 'patch-usr-bin-file)
            (delete 'patch-source-shebangs)
            (delete 'patch-generated-file-shebangs)
            (delete 'patch-shebangs)
            (delete 'strip)
            (delete 'delete-info-dir-file)
            (delete 'patch-dot-desktop-files)
            (delete 'make-dynamic-linker-cache)
            (delete 'install-license-files)
            (delete 'reset-gzip-timestamps)
            (delete 'compress-documentation))
        #:install-plan
        #~(list (list "."
                      #$destination))))
      (synopsis (string-append (string-upcase (substring synopsis 0 1))
                               (substring synopsis 1)))
      (description (string-append
                    "This package installs an immutable source snapshot of the "
                    repo
                    " public project under @file{"
                    destination
                    "}.  It is intended for "
                    "development, preservation, and use by downstream Guix packages."))
      (home-page (string-append "https://github.com/htayj/" repo))
      (license (or project-license %no-permission-license)))))

(define-public htayj-aptitude-custom-aliases-source
  (make-project-source "aptitude-custom-aliases"
                       "htayj-aptitude-custom-aliases-source"
                       "20160824-1.c61c64e"
                       "c61c64ef132d3b75fee306e1872ff32d09c4f0f2"
                       "0r4sgqxmxsj2m3s3fyqfgmlq63d58nc8fvmdlizr00g1k7alc4wa"
                       "source snapshot of the Aptitude aliases project"
                       #f))

(define-public htayj-bell-museum-source
  (make-project-source "bell-museum"
                       "htayj-bell-museum-source"
                       "20260726-1.15f0093"
                       "15f0093f4a9808580b09d8d77c018d57961ee635"
                       "102j7nmnwwxv70l499lp2cq3a9ljy99pk0fy6p05ylm6dssvivkw"
                       "source snapshot of the Bell museum project"
                       license:expat))

(define-public htayj-cadr-fonts-source
  (make-project-source "CADR-fonts"
                       "htayj-cadr-fonts-source"
                       "20260721-1.97722fa"
                       "97722fa9fc687a3f72e4583acf64dd1721840ec7"
                       "1wqbhaggf2wa294yvyckhapa6m6ba5ca35ghflygfmvyjnbl1avj"
                       "source snapshot of the CADR Fonts project"
                       license:bsd-3))

(define-public htayj-computer-builder-source
  (make-project-source "computer-builder"
                       "htayj-computer-builder-source"
                       "20260514-1.3f7e89d"
                       "3f7e89d9e6ecdffa7fa11ab2231b2bfbbe38b8fa"
                       "1sm4p5h8dhd2vxh53miw1jv0xwg5f97f9l35vahmwjaxzni2yi2m"
                       "source snapshot of the computer builder project"
                       license:agpl3+))

(define-public htayj-computus-source
  (make-project-source "computus"
                       "htayj-computus-source"
                       "20260726-1.edd0c37"
                       "edd0c377b02bbfb3d4726d7df668761cb35accb9"
                       "0y10qc8ayildfzacp09w6gqbqqvcfl7g8g4yc7gwh41ssi77cra8"
                       "source snapshot of the Computus project"
                       #f))

(define-public htayj-custom-nix-pkgs-source
  (make-project-source "custom-nix-pkgs"
                       "htayj-custom-nix-pkgs-source"
                       "20260102-1.f1a6694"
                       "f1a6694c5ecf7aec0bf30b244077d23f1bb37223"
                       "0w01d948wpr6b687g51rskvkqzx6ijj5qk1vf3ik08ramsk9nyjg"
                       "source snapshot of the custom Nix packages project"
                       #f))

(define-public htayj-databases-team75-source
  (make-project-source "Databases-Team75"
                       "htayj-databases-team75-source"
                       "20170423-1.8b8c624"
                       "8b8c6247c7f021ef880936197358fadc8d96f209"
                       "064wqwv6grh46ymjw4nn2akh20in5jqay44f5mscwv51dwy3ll7z"
                       "source snapshot of the Databases Team75 project"
                       #f))

(define-public htayj-dec-fonts-source
  (make-project-source "DEC-Fonts"
                       "htayj-dec-fonts-source"
                       "20260722-1.fcacbba"
                       "fcacbba6cb93eeab2bcc7073897ac65af4736d40"
                       "0h5azqpyapv5vkgbxll3k2ld3jnkk3n91wr7zpnhmii8xr4f2a5r"
                       "source snapshot of the DEC Fonts project"
                       license:expat))

(define-public htayj-doom-emacs-d-source
  (make-project-source "doom_emacs.d"
                       "htayj-doom-emacs-d-source"
                       "20250329-1.4ab43eb"
                       "4ab43eb5e23840498f0fa7656bee82b908e40b25"
                       "1yxga00h312sq25870wjq14pxn28wd90sa16wmxbmk7vj6jqlr8p"
                       "source snapshot of the Doom Emacs configuration"
                       #f))

(define-public htayj-dorxng-mcp-source
  (make-project-source "dorxng-mcp"
                       "htayj-dorxng-mcp-source"
                       "20260509-1.59b8106"
                       "59b810609f5bccadf6c9eedc8d6b1ded1dc6cea1"
                       "115qmvda9dihd0mvvwj72j181xa8sch3s0bhlxx1a5scllvcff0g"
                       "source snapshot of the DorXNG MCP server"
                       license:expat))

(define-public htayj-dotfiles-source
  (make-project-source "dotfiles"
                       "htayj-dotfiles-source"
                       "20191104-1.5f668c2"
                       "5f668c284100b398a38a55e6573e091de498eac7"
                       "18cfmqsgbhbm3zdzgazqzldra3ciddnz5kvm543vv75wdy1ixmkc"
                       "source snapshot of the dotfiles project"
                       #f))

(define-public htayj-flaghack-source
  (make-project-source "flaghack"
                       "htayj-flaghack-source"
                       "20260713-1.772c47e"
                       "772c47e77c952eaa96c627079683768533c0ce93"
                       "12sgj8xdjx3b9vay1x9lfh8bmry66yil9ynwcwj7z7agl5fbfqmr"
                       "source snapshot of the FlagHack project"
                       license:agpl3+))

(define-public htayj-genera-fonts-source
  (make-project-source "genera-fonts"
                       "htayj-genera-fonts-source"
                       "20260722-1.892fa05"
                       "892fa057622389b43cdd8f725dc5a2384ab656f8"
                       "0cvc8hr9x9ys7xj09j8r4alr1n1mlxh985g12j69xldj0yz4pw87"
                       "source snapshot of the Genera Fonts project"
                       #f))

(define-public htayj-gimp-stipple-script-source
  (make-project-source "gimp-stipple-script"
                       "htayj-gimp-stipple-script-source"
                       "20240811-1.2a1a14c"
                       "2a1a14c8a3ee266537ebf964ca7a48207e5e573e"
                       "1aw1cy13icbpjjw9i3i1w3p19pwvalz61f49xb2cacymk85zydzy"
                       "source snapshot of the GIMP stipple script"
                       #f))

(define-public htayj-gmatr-source
  (make-project-source "gmatr"
                       "htayj-gmatr-source"
                       "20191227-1.b9118c8"
                       "b9118c848aa788ac48ee845388ca77e2889895a1"
                       "08yx36k4a4gg1kv6ka98yy95wkkbip2rdiyrdshjzrg02wqhhjp3"
                       "source snapshot of the archived gmatr project"
                       #f))

(define-public htayj-gramps-effect-mcp-source
  (make-project-source "gramps-effect-mcp"
                       "htayj-gramps-effect-mcp-source"
                       "20260811-1.8aea9a9"
                       "8aea9a9b78d34befc3ec149a1dfd827273592c64"
                       "1jmrxrj0spcnsdj2nznmd79mkkphqii744q8zh7gva57znsg0yks"
                       "source snapshot of the Gramps Effect MCP server"
                       #f))

(define-public htayj-profile-source
  (make-project-source "htayj"
                       "htayj-profile-source"
                       "20260621-1.3029f77"
                       "3029f77c96ce9ceb86deb808ee1b7e91ffe0bd31"
                       "04psbg2wjqlkj72bsf918643qmsjjf0lvp3zll5d27cv6f4md2jf"
                       "source snapshot of the htayj profile project"
                       #f))

(define-public htayj-hyprland-dot-source
  (make-project-source "hyprland-dot"
                       "htayj-hyprland-dot-source"
                       "20250216-1.409e78a"
                       "409e78ae9b243ad7ced43871e18564e03a4df82e"
                       "00gw79v7p92rysywh7y329qzj496g9v3lkm1bgl5wxf523wmwy15"
                       "source snapshot of the Hyprland configuration"
                       #f))

(define-public htayj-ivory-key-source
  (make-project-source "ivory-key"
                       "htayj-ivory-key-source"
                       "20260814-1.fbe557a"
                       "fbe557a9786ef4cf1a185f96913c3bd51d1c0231"
                       "0pk5a4wm9n3rb9kvsb8c6kvr9axyv0iprb15dxj1v23m3dcqzahf"
                       "source snapshot of the Ivory Key project"
                       license:gpl3))

(define-public htayj-lisp-machine-container-museum-source
  (make-project-source "lisp-machine-container-museum"
                       "htayj-lisp-machine-container-museum-source"
                       "20260811-1.d5dba46"
                       "d5dba4610bdaebd5cb3fd30f6f3183216fa7e8f8"
                       "0pj8xgiapl1xkmjgnccsnb1v70swwm8gfxa1f2plp0srd6nr3f9k"
                       "source snapshot of the Lisp machine container museum"
                       #f))

(define-public htayj-manna-cadet-source
  (make-project-source "manna-cadet"
                       "htayj-manna-cadet-source"
                       "20260809-1.e5f7e81"
                       "e5f7e81cdb6e30a7735cdcab622ede29007e379b"
                       "01iszhj84pmhz3iyfii4plqyap24p816lm9xhihkyfvbd3h2j33m"
                       "source snapshot of the Manna Cadet project"
                       license:expat))

(define-public htayj-moby-mcp-source
  (make-project-source "moby-mcp"
                       "htayj-moby-mcp-source"
                       "20260509-1.e3c2e1c"
                       "e3c2e1c075fb4b9240de713a3968e126839329fb"
                       "05b4gbb3hsnvlaagyhh08vbdb46fm86sbrdqgflaknk3glh6dm5f"
                       "source snapshot of the MobyGames MCP server"
                       license:agpl3))

(define-public htayj-nix-source
  (make-project-source "nix"
                       "htayj-nix-source"
                       "20251029-1.2782251"
                       "2782251c74133cb331446f4b10a1f31054715278"
                       "0hfc3yg71szsl6l8y756zdqmfsjc2kdi0washkdq9nvm2f3pffyh"
                       "source snapshot of the Nix configuration project"
                       #f))

(define-public htayj-os-directory-source
  (make-project-source "os-directory"
                       "htayj-os-directory-source"
                       "20260729-1.cb5228c"
                       "cb5228ce43f18b83f3dfa767f04d2d69e5bbe887"
                       "1psirqml25r5bgc0jb5ww178zgfm5z9d0pdhkxgqv62z5m54cm56"
                       "source snapshot of the OS directory project"
                       #f))

(define-public htayj-qbcl-source
  (make-project-source "qbcl"
                       "htayj-qbcl-source"
                       "20260323-1.167edfe"
                       "167edfecf9fb6371078689a386ebcb4aa482c0dd"
                       "03cg57yndql0kab0v7nk6s2y34rv6lk87q0hh2mvy6a20gh1vn9f"
                       "source snapshot of the QBCL project"
                       license:gpl2+))

(define-public htayj-rplaca-source
  (make-project-source "rplaca"
                       "htayj-rplaca-source"
                       "20260729-1.7cffbb8"
                       "7cffbb8cbd626bbea0834d5d4bf63adc1344cc6c"
                       "0hw8mkk6317yl5vvqgia6zcx5sm5y5clxbj8yi2f5bpk3x7226wg"
                       "source snapshot of the RPLACA project"
                       license:agpl3))

(define-public htayj-slophack-source
  (make-project-source "slophack"
                       "htayj-slophack-source"
                       "20260303-1.0c949f2"
                       "0c949f20550a3866c6d6da6789c7e0f85492fa9f"
                       "1c64bw7wpgqp8ml8d2wvx2rsp9zmjbnpsh294rg1i3gb069d0y4p"
                       "source snapshot of the archived SlopHack project"
                       license:agpl3+))

(define-public htayj-sockets-programming-homework-source
  (make-project-source "Sockets-Programming-Homework"
                       "htayj-sockets-programming-homework-source"
                       "20170509-1.5002ac8"
                       "5002ac88af1a8bb516c018798ec5b19ce3c73570"
                       "0sm3xjc9r7r1jvslqgg573k4hqsp4i8z8yimq6mfbc4zkm1aphg0"
                       "source snapshot of the sockets programming project"
                       #f))

(define-public htayj-src-source
  (make-project-source "src"
                       "htayj-src-source"
                       "20260813-1.1ecae4d"
                       "1ecae4ddfa96cb4359b70214c6c10b758cd75490"
                       "0wmvssb4cbw6a1f3wdzr8wd0gasw0gcyccazcdc0jzpzb8xpbi12"
                       "source snapshot of the system configuration monorepo"
                       #f))

(define-public htayj-stumpwm-config-source
  (make-project-source "stumpwm-config"
                       "htayj-stumpwm-config-source"
                       "20260116-1.178a973"
                       "178a973265f37a500bd4e9d9d689f56a33e299f4"
                       "1a1as0nbjrbhj75qb4315mdkj43h6djzmh4v04qivpclq9xp4y31"
                       "source snapshot of the StumpWM configuration"
                       #f))

(define-public htayj-subgenius-fortunes-source
  (make-project-source "SubgeniusFortunes"
                       "htayj-subgenius-fortunes-source"
                       "20171014-1.e86e87e"
                       "e86e87e8780853036c91ff29703c43b123ecf1a3"
                       "1gbqrv9k4xjzk9v0qks5a0dngx14z74czr9z9yd9n9ajh961505s"
                       "source snapshot of the SubGenius fortunes project"
                       #f))

(define-public htayj-sublime-lc2200-source
  (make-project-source "Sublime-LC2200"
                       "htayj-sublime-lc2200-source"
                       "20160227-1.9e7d3d6"
                       "9e7d3d66568cb2d6e22b64a3020a4ed0f5d129dd"
                       "13rnkl0a6m8rkjnpay0j9f8dysbx6gkglz6vg6xhgmcnarbp0xi6"
                       "source snapshot of the Sublime LC2200 project"
                       #f))

(define-public htayj-taydemacs-source
  (make-project-source "Taydemacs"
                       "htayj-taydemacs-source"
                       "20200507-1.0498d94"
                       "0498d94999289c0cec1f03f9cdefc24581f3585a"
                       "11cji7wjl5i7f3srxayv0wijpg1lyw78b3shm5qqsvs9szghhw1v"
                       "source snapshot of the Taydemacs project"
                       #f))

(define-public htayj-vexillomancy-matrix-custom-source
  (make-project-source "vexillomancy-matrix-custom"
   "htayj-vexillomancy-matrix-custom-source"
   "20240710-1.318337f"
   "318337f329c7631eea0a1f1552221ab2adc7f379"
   "05n2m5wdjarkh3sibybdr0x5lkvskrv73m0g8pqrpngf7ac2cn56"
   "source snapshot of the Vexillomancy Matrix customizations"
   #f))

(define-public htayj-waybar-dot-source
  (make-project-source "waybar-dot"
                       "htayj-waybar-dot-source"
                       "20250216-1.98d676e"
                       "98d676e63573ca72fbaca78c226fd20f9ffff83b"
                       "1rjsf0xh0g3sjdv4s3iaka4a38chw06jj9vvq1hkks983mjcj4qg"
                       "source snapshot of the Waybar configuration"
                       #f))

(define-public htayj-www-vexillomancy-org-source
  (make-project-source "www-vexillomancy-org"
                       "htayj-www-vexillomancy-org-source"
                       "20240722-1.973787c"
                       "973787ce0a8b8f0e8e20920ec9d853dce3c62168"
                       "051snz6djj8h3w1bny9sspmgsnxcm01w1zmrwxl2wjc2wzsaxg80"
                       "source snapshot of the Vexillomancy website"
                       license:agpl3))

(define-public htayj-yaourt-custom-aliases-source
  (make-project-source "yaourt-custom-aliases"
                       "htayj-yaourt-custom-aliases-source"
                       "20170902-1.6ff7119"
                       "6ff71192d50db5d6fb9f1e4882e9b021775e0e40"
                       "1j03ch08m7bmz21spkcn4qriwkii5pc5zghlfa3pjgy6svlgw0gb"
                       "source snapshot of the Yaourt aliases project"
                       #f))

(define %public-project-source-packages
  (list htayj-aptitude-custom-aliases-source
        htayj-bell-museum-source
        htayj-cadr-fonts-source
        htayj-computer-builder-source
        htayj-computus-source
        htayj-custom-nix-pkgs-source
        htayj-databases-team75-source
        htayj-dec-fonts-source
        htayj-doom-emacs-d-source
        htayj-dorxng-mcp-source
        htayj-dotfiles-source
        htayj-flaghack-source
        htayj-genera-fonts-source
        htayj-gimp-stipple-script-source
        htayj-gmatr-source
        htayj-gramps-effect-mcp-source
        htayj-profile-source
        htayj-hyprland-dot-source
        htayj-ivory-key-source
        htayj-lisp-machine-container-museum-source
        htayj-manna-cadet-source
        htayj-moby-mcp-source
        htayj-nix-source
        htayj-os-directory-source
        htayj-qbcl-source
        htayj-rplaca-source
        htayj-slophack-source
        htayj-sockets-programming-homework-source
        htayj-src-source
        htayj-stumpwm-config-source
        htayj-subgenius-fortunes-source
        htayj-sublime-lc2200-source
        htayj-taydemacs-source
        htayj-vexillomancy-matrix-custom-source
        htayj-waybar-dot-source
        htayj-www-vexillomancy-org-source
        htayj-yaourt-custom-aliases-source))
