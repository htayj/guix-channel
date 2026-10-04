;;; Lispy Rogue -- source-built Autumn Lisp Game Jam 2024 entry.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages lispy-rogue)
  #:use-module (guix build-system asdf)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages lispy-rogue-dependencies)
  #:use-module (tay packages starred-i-m))

(define-public lispy-rogue
  (package
    (name "lispy-rogue")
    (version "0.0.2")
    ;; Keep the immutable source ledger as the single target origin.
    (source (package-source lockie-lispy-rogue-source))
    (build-system asdf-build-system/sbcl)
    (arguments
     (list
      #:asd-systems ''("lispy-rogue")
      #:tests? #f                       ; No upstream test system.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'remove-upstream-packaging
            (lambda _
              ;; Exclude the icon and installer artwork, and do not invoke the
              ;; Quicklisp/download-based upstream packaging script.
              (delete-file-recursively "package")
              (delete-file-recursively ".github")
              (delete-file "package.sh")))
          ;; Loading the compiled FASLs avoids snapshotting SBCL's live build
          ;; process (foreign addresses, scratch paths and dynamic runtime
          ;; state), which made the deploy image fail Guix's --check rebuild.
          ;; The launcher still enters through deploy's ordinary boot/quit
          ;; hooks and the unmodified upstream native game entry point.
          (add-after 'create-asdf-configuration 'install-launcher
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (launcher (string-append bin "/lispy-rogue"))
                     (entry (string-append libexec "/lispy-rogue.lisp")))
                (mkdir-p bin)
                (mkdir-p libexec)
                (copy-recursively "Resources" (string-append out "/Resources"))
                (call-with-output-file entry
                  (lambda (port)
                    (display "(require :asdf)\n" port)
                    ;; Store fragments describe the entire compiled closure;
                    ;; user registries must not shadow it or trigger rebuilds.
                    (format port
                            (string-append
                             "(asdf:initialize-source-registry "
                             "'(:source-registry (:include ~s) "
                             ":ignore-inherited-configuration))~%")
                            (string-append
                             out "/etc/xdg/common-lisp/source-registry.conf.d/"))
                    (format port
                            (string-append
                             "(asdf:initialize-output-translations "
                             "'(:output-translations (:include ~s) "
                             ":ignore-inherited-configuration))~%")
                            (string-append
                             out "/etc/xdg/common-lisp/"
                             "asdf-output-translations.conf.d/"))
                    (display "(asdf:load-system :lispy-rogue)\n" port)
                    ;; Use the launcher's real store path for the upstream
                    ;; Resources-relative-to-bin boot hook, not SBCL's path.
                    (format port
                            (string-append
                             "(setf sb-ext:*posix-argv* "
                             "(cons ~s (cdr sb-ext:*posix-argv*)))~%")
                            launcher)
                    (display
                     (string-append
                      "(setf deploy:*build-time* nil "
                      "deploy:*source-checksum* nil)\n"
                      "(deploy::call-entry-prepared #'lispy-rogue:main)\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a\nset -eu\n"
                            #$(file-append bash-minimal "/bin/sh"))
                    (format port
                            (string-append
                             "export LD_LIBRARY_PATH=~s"
                             "${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\n")
                            (string-append #$allegro "/lib:"
                                           #$sbcl-cl-liballegro-nuklear "/lib"))
                    (format port
                            (string-append
                             "exec ~a --noinform --no-userinit --no-sysinit"
                             " --script ~s \"$@\"\n")
                            #$(file-append sbcl "/bin/sbcl") entry)))
                (chmod launcher #o555))))
          (add-after 'install-launcher 'install-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/lispy-rogue")))
                (install-file "LICENSE" doc)
                (copy-file #$(local-file
                              (search-tay-package-file
                               "lispy-rogue-notices.txt"))
                           (string-append doc "/ASSET-NOTICES"))
                (copy-file #$(local-file
                              (search-tay-package-file
                               "lispy-rogue-Fantasque-OFL-1.1.txt"))
                           (string-append doc "/Fantasque-OFL-1.1.txt"))
                (copy-file #$(local-file
                              (search-tay-package-file
                               "lispy-rogue-Inconsolata-OFL-1.1.txt"))
                           (string-append doc "/Inconsolata-OFL-1.1.txt"))))))))
    (inputs
     (list allegro bash-minimal sbcl
           sbcl-alexandria sbcl-cl-astar sbcl-cl-fast-ecs
           sbcl-cl-liballegro-compatible sbcl-cl-liballegro-nuklear sbcl-cl-ppcre
           sbcl-cl-tiled sbcl-deploy sbcl-float-features sbcl-livesupport))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/lockie/lispy-rogue")
    (synopsis "Allegro roguelike written in Common Lisp")
    (description
     "Lispy Rogue is a graphical turn-based dungeon crawler created for the
Autumn Lisp Game Jam 2024.  Explore randomly generated dungeon floors, fight
monsters, collect equipment and descend to level eleven.  This package builds
the original Common Lisp game and its Allegro/Nuklear interface from source,
with bundled CC0 tiles and ambience and OFL fonts.  It preserves the upstream
controls and graphical help, inventory and combat interface.")
    (license (list license:expat license:cc0 license:silofl1.1))))
