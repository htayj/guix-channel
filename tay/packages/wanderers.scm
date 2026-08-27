;;; GNU Guix package for a-nikolaev/wanderers.

(define-module (tay packages wanderers)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages sdl))

;; No upstream release tags exist.  This is the canonical master commit from
;; 2019-01-05, fetched as a fixed codeload archive rather than a moving branch.
(define %wanderers-commit
  "054c1cdc6dd833d8938357e6d898def510531d67")

(define %wanderers-version
  "0-054c1cd")

(define %wanderers-source
  (origin
    (method url-fetch)
    (uri (string-append "https://codeload.github.com/a-nikolaev/wanderers/tar.gz/"
                        %wanderers-commit))
    (file-name (string-append "wanderers-" %wanderers-version ".tar.gz"))
    ;; SHA-256: 00b3ae2413bf2f052100977510a6605a64ac44a1384823b46189043804ee3b72
    (sha256
     (base32 "0wivxq23h149c6s26j1ql52aqr2sc2k10xcp00hhabxz2cjaxcq0"))))

(define-public wanderers
  (package
    (name "wanderers")
    (version %wanderers-version)
    (source %wanderers-source)
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;the upstream tree has no test target
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'build
            (lambda _
              ;; The bundled OCamlMakefile owns this native target; no opam,
              ;; dune, findlib, camlp4, generated parser, or network fetch is
              ;; involved.
              (invoke "make" "-f" "makefile.inc" "nc"
                      "CC=cc-for-target"
                      (string-append "CFLAGS=-I" #$sdl12-compat "/include")
                      (string-append "LDFLAGS=-L" #$sdl12-compat "/lib"))))
          (replace 'install
            (lambda _
              (let* ((libexec (string-append #$output "/libexec"))
                     (documentation (string-append #$output "/share/doc/wanderers"))
                     (data (string-append #$output "/share/wanderers/data"))
                     (program (string-append libexec "/wanderers"))
                     (wrapper (string-append #$output "/bin/wanderers")))
                (mkdir-p libexec)
                (install-file "wanderers" libexec)
                (mkdir-p data)
                (copy-recursively "data" data)
                ;; Preserve the game license, the upstream build file, and the
                ;; bundled binding sources which carry their own notices.
                (mkdir-p documentation)
                (for-each (lambda (file) (install-file file documentation))
                          '("COPYING" "README.markdown" "OCamlMakefile"))
                (copy-recursively "lib" (string-append documentation "/lib"))
                (mkdir-p (dirname wrapper))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%~
state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/wanderers\"~%
~a -p \"$state\"~%
if test ! -e \"$state/data\" && test ! -L \"$state/data\"; then~%
  ~a -s ~s \"$state/data\"~%
fi~%
cd \"$state\"~%
export LD_LIBRARY_PATH=~s\"${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"~%
exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh")
                            #$(file-append coreutils "/bin/mkdir")
                            #$(file-append coreutils "/bin/ln")
                            data
                            (string-append #$sdl12-compat "/lib:"
                                           #$mesa "/lib:")
                            program)))
                (chmod wrapper #o555)))))))
    ;; OCaml 4.07 supplies ocamlopt and the graphics, unix, str, and bigarray
    ;; libraries used directly by the upstream makefile.
    (native-inputs (list ocaml-4.07))
    ;; SDL 1.2 compatibility headers/libraries are required by sdl_stub.c;
    ;; GLCaml dynamically opens libGL.so.1 at runtime.  Coreutils and Bash are
    ;; explicit runtime dependencies of the store-safe launcher.
    (inputs (list bash-minimal coreutils mesa sdl12-compat))
    (home-page "https://github.com/a-nikolaev/wanderers")
    (synopsis "Open-world adventure and dungeon-crawling game")
    (description
     "Wanderers is an open-world adventure and dungeon-crawling game.  The
installed launcher exposes the immutable packaged game data in a per-user XDG
data directory and starts the game there, so saved games never write to the
Guix store.  It is built from its fixed upstream source without downloads at
build or runtime.")
    ;; The game and its assets are GPL-3.0-or-later.  GLCaml is BSD-2-Clause,
    ;; the bundled SDL binding is LGPL-2.0-only, and OCamlMakefile is LGPL-2.1.
    (license (list license:gpl3+ license:bsd-2 license:lgpl2.0 license:lgpl2.1))))
