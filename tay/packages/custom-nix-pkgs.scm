;;; Preserve the Nix expressions from htayj/custom-nix-pkgs.

(define-module (tay packages custom-nix-pkgs)
  #:use-module (gnu packages bash)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (tay packages projects))

(define-public custom-nix-pkgs
  (package
    (name "custom-nix-pkgs")
    ;; Keep this package tied to the same immutable source snapshot as the
    ;; channel's corresponding source-preservation package.
    (version (package-version htayj-custom-nix-pkgs-source))
    (source (package-source htayj-custom-nix-pkgs-source))
    (build-system copy-build-system)
    (arguments
     (list
      ;; The repository is a collection of Nix expressions and lock metadata,
      ;; not a Guix-native application.  Install the complete snapshot as
      ;; data, without rewriting its source files or trying to evaluate them.
      #:install-plan
      #~'(("." "share/htayj/projects/custom-nix-pkgs/"))
      #:phases
      #~(modify-phases %standard-phases
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
          (delete 'compress-documentation)
          (add-after 'install 'install-snapshot-checker
            (lambda _
              (let ((program
                     (string-append #$output
                                    "/bin/custom-nix-pkgs-validate")))
                (mkdir-p (dirname program))
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/bash~%" #$bash-minimal)
                    (display
                     (string-append
                      "set -eu\n"
                      "snapshot=\"${BASH_SOURCE[0]%/*}/../share/htayj/"
                      "projects/custom-nix-pkgs\"\n"
                      "expected=(\n"
                      "  default.nix\n"
                      "  dectalk.nix\n"
                      "  flake.lock\n"
                      "  flake.nix\n"
                      "  fluxengine_upstream.nix\n"
                      "  greaseweazle.nix\n"
                      "  hxcfloppy.nix\n"
                      "  pc98ripper.nix\n"
                      "  xlax.nix\n"
                      ")\n"
                      "case \"${1:---check}\" in\n"
                      "  --list) printf '%s\\n' \"${expected[@]}\"; exit 0 ;;\n"
                      "  --check) ;;\n"
                      "  *) echo 'usage: custom-nix-pkgs-validate ' >&2\n"
                      "     echo '[--check|--list]' >&2; exit 2 ;;\n"
                      "esac\n"
                      "for file in \"${expected[@]}\"; do\n"
                      "  test -f \"$snapshot/$file\" || {\n"
                      "    echo \"missing installed definition: $file\" >&2\n"
                      "    exit 1\n"
                      "  }\n"
                      "done\n"
                      "contains() {\n"
                      "  case \"$1\" in\n"
                      "    *\"$2\"*) return 0 ;;\n"
                      "    *) return 1 ;;\n"
                      "  esac\n"
                      "}\n"
                      "flake=\"$(<\"$snapshot/flake.nix\")\"\n"
                      "markers=(\n"
                      "  'packages.x86_64-linux'\n"
                      "  'dectalk = callPackage ./dectalk.nix'\n"
                      "  'hxcfloppy = callPackage ./hxcfloppy.nix'\n"
                      "  'pc98ripper = callPackage ./pc98ripper.nix'\n"
                      "  'fluxengine = callPackage ./fluxengine_upstream.nix'\n"
                      "  'xlax = callPackage ./xlax.nix'\n"
                      ")\n"
                      "for marker in \"${markers[@]}\"; do\n"
                      "  contains \"$flake\" \"$marker\" || {\n"
                      "    echo \"flake.nix is missing package marker: \" >&2\n"
                      "    echo \"$marker\" >&2\n"
                      "    exit 1\n"
                      "  }\n"
                      "done\n"
                      "lock=\"$(<\"$snapshot/flake.lock\")\"\n"
                      "for marker in 'nixpkgs' 'narHash' 'rev'; do\n"
                      "  contains \"$lock\" \"$marker\" || {\n"
                      "    echo \"flake.lock lacks pinned metadata: \" >&2\n"
                      "    echo \"$marker\" >&2\n"
                      "    exit 1\n"
                      "  }\n"
                      "done\n"
                      "echo \"custom-nix-pkgs snapshot is complete: \"\n"
                      "echo \"${#expected[@]} Nix files\"\n")
                     port)))
                (chmod program #o555)))))))
    (inputs (list bash-minimal))
    (synopsis "Preserved Nix package definitions and lock metadata")
    (description
     "This package preserves the complete immutable source snapshot of the
custom-nix-pkgs repository, including its Nix package definitions, legacy
default expression, flake, and lock file.  It installs those files as data
under @file{share/htayj/projects/custom-nix-pkgs}; it does not translate the
Nix expressions into Guix packages or claim that they evaluate with Guix.  The
@command{custom-nix-pkgs-validate} helper performs an offline integrity check
of the installed file set and pinned flake metadata, and accepts @option{--list}
to enumerate the preserved Nix files.  The upstream repository has no explicit
license, so redistribution remains subject to a separate rights review.")
    (home-page "https://github.com/htayj/custom-nix-pkgs")
    (license (package-license htayj-custom-nix-pkgs-source))))
